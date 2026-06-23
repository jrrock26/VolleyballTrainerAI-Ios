import Foundation
import Vision
import AVFoundation
import CoreGraphics
import UIKit

class PoseTracker: NSObject, ObservableObject {
    // Metric Fields
    @Published var jumpHeight: Double = 0.0
    @Published var armExtensionAngle: Double = 0.0
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    // Visible video rect inside the container (for overlay alignment)
    @Published var videoRect: CGRect = .zero

    // Current video orientation (driven by capture/playback)
    @Published var currentVideoOrientation: AVCaptureVideoOrientation = .portrait

    // Real-time joint coordinates mapped out for drawing overlay lines (normalized 0–1, y flipped)
    @Published var jointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

    // Ball Bounding Box rect container coordinates (normalized 0–1, y flipped)
    @Published var ballBoundingBoxRect: CGRect? = nil

    private var sequenceHandler = VNSequenceRequestHandler()
    private var hipBaselineY: Double? = nil
    private var highestJumpPixels: Double = 0.0
    private var baselineFrameCount = 0
    private var isBaselineLocked = false
    private let baselineFramesNeeded = 25
    // Player's shoulder-to-hip span (normalized) captured at baseline, used to
    // scale jump height by body size in frame instead of a fixed multiplier.
    private var bodyScaleNorm: Double? = nil
    private let assumedTorsoInches: Double = 22.0

    private var smoothedJoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private var jointMissingFrames: [VNHumanBodyPoseObservation.JointName: Int] = [:]
    private let jointSmoothingAlpha: CGFloat = 0.5
    private let jointHoldFrames = 8

    private var lastFrameTime = Date()
    private var isHitCaptured = false
    // Swing state tracked per arm (key: isRightArm) so either arm can register a hit
    private var lastWristYBySide: [Bool: CGFloat] = [:]
    private var ascendingBySide: [Bool: Bool] = [:]

    // Ball Physics Trackers
    private var lastBallPosition: CGPoint = .zero
    private var initialBallContactTime: Date? = nil
    private var lastBallTime: Date? = nil
    private var ballTrajectoryPoints: [CGPoint] = []
    private var recentBallSpeedSamples: [Double] = []
    private let ballSpeedSampleLimit: Int = 6

    // Calculations for Final Payload Metrics Output
    var computedBallSpeedMPH: Double = 0.0
    var computedLaunchAngleDegrees: Double = 0.0
    var computedFlightDistanceFeet: Double = 0.0

    var onSingleHitExtracted: ((Double, Double, Double, Double, Double) -> Void)?

    private let overlayJoints: [VNHumanBodyPoseObservation.JointName] = [
        .rightWrist, .rightElbow, .rightShoulder, .leftShoulder,
        .rightHip, .leftHip, .rightKnee, .leftKnee,
        .rightAnkle, .leftAnkle, .neck, .leftElbow, .leftWrist
    ]

    func resetTrackingTokens() {
        DispatchQueue.main.async {
            self.jumpHeight = 0.0
            self.armExtensionAngle = 0.0
            self.highestJumpPixels = 0.0
            self.hipBaselineY = nil
            self.bodyScaleNorm = nil
            self.baselineFrameCount = 0
            self.isBaselineLocked = false
            self.lastWristYBySide.removeAll()
            self.ascendingBySide.removeAll()
            self.isHitCaptured = false
            self.jointPoints.removeAll()
            self.smoothedJoints.removeAll()
            self.jointMissingFrames.removeAll()
            self.ballBoundingBoxRect = nil
            self.ballTrajectoryPoints.removeAll()
            self.recentBallSpeedSamples.removeAll()
            self.computedBallSpeedMPH = 0.0
            self.computedLaunchAngleDegrees = 0.0
            self.computedFlightDistanceFeet = 0.0
            self.initialBallContactTime = nil
            self.lastBallTime = nil
        }
    }

    func processFrame(sampleBuffer: CMSampleBuffer, hitType: String) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processRawPixelBuffer(pixelBuffer, hitType: hitType)
    }

    func processRawPixelBuffer(_ pixelBuffer: CVPixelBuffer, hitType: String) {
        let poseRequest = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNHumanBodyPoseObservation],
                  !results.isEmpty else { return }

            let primaryHitter = results.max { obs1, obs2 in
                self.bodyBoundingArea(for: obs1) < self.bodyBoundingArea(for: obs2)
            }

            if let hitter = primaryHitter {
                self.analyzePlayerPose(hitter, type: hitType)
            }
        }

        // Tell Vision the frame is upright so skeleton and hit detection match
        let orientation = cgOrientationFrom(currentVideoOrientation, cameraPosition: cameraPosition)

        try? sequenceHandler.perform(
            [poseRequest],
            on: pixelBuffer,
            orientation: orientation
        )

        extractBallBoundingBox(in: pixelBuffer)
    }

    private func bodyBoundingArea(for observation: VNHumanBodyPoseObservation) -> CGFloat {
        var minX: CGFloat = 1.0
        var maxX: CGFloat = 0.0
        var minY: CGFloat = 1.0
        var maxY: CGFloat = 0.0
        var count = 0

        for joint in overlayJoints {
            if let pt = try? observation.recognizedPoint(joint), pt.confidence > 0.08 {
                minX = min(minX, pt.location.x)
                maxX = max(maxX, pt.location.x)
                minY = min(minY, pt.location.y)
                maxY = max(maxY, pt.location.y)
                count += 1
            }
        }

        guard count >= 4 else { return 0 }
        return (maxX - minX) * (maxY - minY)
    }

    private func averageHipY(
        leftHip: VNRecognizedPoint,
        rightHip: VNRecognizedPoint,
        threshold: Float
    ) -> Double? {
        var sum: Double = 0
        var count = 0

        if leftHip.confidence > threshold {
            sum += Double(leftHip.location.y)
            count += 1
        }
        if rightHip.confidence > threshold {
            sum += Double(rightHip.location.y)
            count += 1
        }

        guard count > 0 else { return nil }
        return sum / Double(count)
    }

    func cgOrientationFrom(
        _ videoOrientation: AVCaptureVideoOrientation,
        cameraPosition: AVCaptureDevice.Position
    ) -> CGImagePropertyOrientation {
        switch videoOrientation {
        case .portrait:
            // Capture connection already delivers upright portrait frames.
            return cameraPosition == .front ? .upMirrored : .up
        case .portraitUpsideDown:
            return cameraPosition == .front ? .rightMirrored : .left
        case .landscapeLeft:
            return cameraPosition == .front ? .downMirrored : .up
        case .landscapeRight:
            return cameraPosition == .front ? .upMirrored : .down
        @unknown default:
            return cameraPosition == .front ? .leftMirrored : .right
        }
    }

}

extension PoseTracker {
    private func analyzePlayerPose(_ observation: VNHumanBodyPoseObservation, type: String) {
        let isFrontCamera = cameraPosition == .front
        let confidenceThreshold: Float = isFrontCamera ? 0.12 : 0.2
        let velocityThreshold: Double = isFrontCamera ? 0.8 : 1.2
        let hipThreshold: Float = isFrontCamera ? 0.10 : 0.12

        guard let leftHip = try? observation.recognizedPoint(.leftHip),
              let rightHip = try? observation.recognizedPoint(.rightHip) else { return }

        let rightWrist = try? observation.recognizedPoint(.rightWrist)
        let leftWrist = try? observation.recognizedPoint(.leftWrist)

        // Active arm = the one closest to the camera (clearer / higher-confidence wrist).
        let useRightArm: Bool
        if let r = rightWrist, let l = leftWrist {
            useRightArm = r.confidence >= l.confidence
        } else {
            useRightArm = rightWrist != nil
        }

        let shoulder = useRightArm
            ? (try? observation.recognizedPoint(.rightShoulder))
            : (try? observation.recognizedPoint(.leftShoulder))
        let elbow = useRightArm
            ? (try? observation.recognizedPoint(.rightElbow))
            : (try? observation.recognizedPoint(.leftElbow))
        let wrist = useRightArm ? rightWrist : leftWrist

        let currentHipY = averageHipY(leftHip: leftHip, rightHip: rightHip, threshold: hipThreshold)

        let now = Date()
        let timeDelta = now.timeIntervalSince(lastFrameTime)
        lastFrameTime = now

        DispatchQueue.main.async {
            self.updateSmoothedJoints(from: observation)

            if type == "Spike", let hipY = currentHipY {
                if !self.isBaselineLocked {
                    self.baselineFrameCount += 1
                    if let existing = self.hipBaselineY {
                        self.hipBaselineY = existing * 0.85 + hipY * 0.15
                    } else {
                        self.hipBaselineY = hipY
                    }

                    if let sh = shoulder, sh.confidence > confidenceThreshold {
                        let torso = Double(sh.location.y) - hipY
                        if torso > 0.01 {
                            if let existing = self.bodyScaleNorm {
                                self.bodyScaleNorm = existing * 0.85 + torso * 0.15
                            } else {
                                self.bodyScaleNorm = torso
                            }
                        }
                    }

                    if self.baselineFrameCount >= self.baselineFramesNeeded {
                        self.isBaselineLocked = true
                    }
                }

                if self.isBaselineLocked, let baseline = self.hipBaselineY {
                    let jumpDelta = hipY - baseline
                    if jumpDelta > self.highestJumpPixels && jumpDelta > 0.004 {
                        self.highestJumpPixels = jumpDelta
                        let inchesPerNorm: Double
                        if let scale = self.bodyScaleNorm, scale > 0.01 {
                            inchesPerNorm = max(40, min(140, self.assumedTorsoInches / scale))
                        } else {
                            inchesPerNorm = 90
                        }
                        var rawJump = jumpDelta * inchesPerNorm
                        rawJump = max(0, min(rawJump, 50))
                        self.jumpHeight = rawJump
                    }
                }
            } else if type != "Spike" {
                self.jumpHeight = 0.0
            }

            // Arm extension angle from the active (closest) arm.
            if let shoulder, let elbow, let wrist,
               shoulder.confidence > confidenceThreshold,
               wrist.confidence > confidenceThreshold,
               elbow.confidence > confidenceThreshold {
                self.armExtensionAngle = self.calculateAngle(
                    a: shoulder.location,
                    b: elbow.location,
                    c: wrist.location
                )
            }

            if self.isHitCaptured { return }

            // Detect the hit swing on EITHER arm so right- and left-handed swings
            // both register; each side is tracked independently.
            for isRight in [true, false] {
                guard let armWrist = isRight ? rightWrist : leftWrist,
                      let armShoulder = isRight
                        ? (try? observation.recognizedPoint(.rightShoulder))
                        : (try? observation.recognizedPoint(.leftShoulder)),
                      armWrist.confidence > confidenceThreshold,
                      armShoulder.confidence > confidenceThreshold else { continue }

                let currentWristY = armWrist.location.y

                if timeDelta > 0, let lastY = self.lastWristYBySide[isRight] {
                    let yDelta = currentWristY - lastY
                    let instantaneousVelocity = abs(yDelta) / timeDelta

                    // Arm the swing as soon as the wrist is above the shoulder so
                    // the very first downward snap registers a hit.
                    if currentWristY > armShoulder.location.y {
                        self.ascendingBySide[isRight] = true
                    }

                    if (self.ascendingBySide[isRight] ?? false)
                        && yDelta < 0
                        && instantaneousVelocity > velocityThreshold {
                        self.isHitCaptured = true
                        self.initialBallContactTime = Date()

                        let capturedJump = self.jumpHeight
                        let capturedAngle = self.armExtensionAngle

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.onSingleHitExtracted?(
                                capturedJump,
                                capturedAngle,
                                self.computedBallSpeedMPH,
                                self.computedLaunchAngleDegrees,
                                self.computedFlightDistanceFeet
                            )
                        }
                    }
                }

                self.lastWristYBySide[isRight] = currentWristY
                if self.isHitCaptured { break }
            }
        }
    }

    private func updateSmoothedJoints(from observation: VNHumanBodyPoseObservation) {
        for joint in overlayJoints {
            if let pt = try? observation.recognizedPoint(joint), pt.confidence > 0.3 {
                let flipped = CGPoint(x: pt.location.x, y: 1.0 - pt.location.y)

                if let previous = smoothedJoints[joint] {
                    smoothedJoints[joint] = CGPoint(
                        x: previous.x + jointSmoothingAlpha * (flipped.x - previous.x),
                        y: previous.y + jointSmoothingAlpha * (flipped.y - previous.y)
                    )
                } else {
                    smoothedJoints[joint] = flipped
                }

                jointMissingFrames[joint] = 0
                jointPoints[joint] = smoothedJoints[joint]
            } else {
                let missing = (jointMissingFrames[joint] ?? 0) + 1
                jointMissingFrames[joint] = missing

                if missing <= jointHoldFrames, let cached = smoothedJoints[joint] {
                    jointPoints[joint] = cached
                } else {
                    jointPoints.removeValue(forKey: joint)
                    smoothedJoints.removeValue(forKey: joint)
                }
            }
        }
    }

    private func extractBallBoundingBox(in pixelBuffer: CVPixelBuffer) {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        var matchXSum = 0
        var matchYSum = 0
        var matchCount = 0
        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0

        let step = 3
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let pixelOffset = y * bytesPerRow + x * 4
                let b = buffer[pixelOffset]
                let g = buffer[pixelOffset + 1]
                let r = buffer[pixelOffset + 2]

                let maxC = max(r, max(g, b))
                let minC = min(r, min(g, b))
                let range = maxC - minC
                // Require a vivid, reasonably bright pixel so we mostly grab the ball
                // while ignoring dull greenery, sky gradients, skin, and grays.
                if maxC > 120 && range > 55 {
                    matchXSum += x
                    matchYSum += y
                    matchCount += 1
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }

        if matchCount > 12 {
            let boxW = CGFloat(maxX - minX) / CGFloat(width)
            let boxH = CGFloat(maxY - minY) / CGFloat(height)
            let aspect = boxW / max(boxH, 0.001)
            let boxArea = CGFloat(maxX - minX) * CGFloat(maxY - minY)
            let density = CGFloat(matchCount) / max(boxArea, 1.0)

            let targetCenterX = CGFloat(matchXSum) / CGFloat(matchCount) / CGFloat(width)
            let targetCenterY = CGFloat(matchYSum) / CGFloat(matchCount) / CGFloat(height)

            // Reject blobs that are too elongated, too large, too sparse,
            // or sitting in the sky/background rather than the player area.
            let isRoundEnough = aspect > 0.55 && aspect < 1.8
            let compact = density > 0.22
            let reasonableSize = boxW > 0.010 && boxW < 0.14 && boxH > 0.010 && boxH < 0.14
            let inPlayerZone = targetCenterY > 0.28 && targetCenterY < 0.92

            if isRoundEnough && compact && reasonableSize && inPlayerZone {
                let currentBallPosition = CGPoint(x: targetCenterX, y: targetCenterY)

                DispatchQueue.main.async {
                    let drawW = CGFloat(maxX - minX) / CGFloat(width)
                    let drawH = CGFloat(maxY - minY) / CGFloat(height)
                    let paddedW = max(0.04, drawW * 1.15)
                    let paddedH = max(0.04, drawH * 1.15)

                    self.ballBoundingBoxRect = CGRect(
                        x: targetCenterX - (paddedW / 2),
                        y: 1.0 - targetCenterY - (paddedH / 2),
                        width: paddedW,
                        height: paddedH
                    )

                    if let contactTime = self.initialBallContactTime,
                       !self.lastBallPosition.equalTo(.zero) {
                        let timeElapsed = Date().timeIntervalSince(contactTime)
                        if timeElapsed > 0 && timeElapsed < 1.0 {
                            let frameTravelDistance = sqrt(
                                pow(currentBallPosition.x - self.lastBallPosition.x, 2) +
                                pow(currentBallPosition.y - self.lastBallPosition.y, 2)
                            )

                            let now = Date()
                            let dt = self.lastBallTime.map { now.timeIntervalSince($0) } ?? 0.033
                            let clampedDt = max(0.005, min(dt, 0.15))

                            let velocityNorm = frameTravelDistance / clampedDt
                            let inchesPerNorm: Double
                            if let scale = self.bodyScaleNorm, scale > 0.01 {
                                inchesPerNorm = max(35, min(155, self.assumedTorsoInches / scale))
                            } else {
                                inchesPerNorm = 95
                            }
                            let feetPerNorm = inchesPerNorm / 12.0
                            let mphPerNormPerSec = feetPerNorm * 3600.0 / 5280.0
                            var velocityMPH = velocityNorm * mphPerNormPerSec

                            if velocityMPH >= 1 && velocityMPH <= 160 {
                                self.recentBallSpeedSamples.append(velocityMPH)
                                if self.recentBallSpeedSamples.count > self.ballSpeedSampleLimit {
                                    self.recentBallSpeedSamples.removeFirst()
                                }
                                let smoothed = self.recentBallSpeedSamples.reduce(0, +) / Double(self.recentBallSpeedSamples.count)
                                self.computedBallSpeedMPH = smoothed
                            } else if velocityMPH > 160 {
                                self.computedBallSpeedMPH = 160
                            } else if velocityMPH >= 0.2 {
                                self.computedBallSpeedMPH = velocityMPH
                            }

                            let xDelta = currentBallPosition.x - self.lastBallPosition.x
                            let yDelta = currentBallPosition.y - self.lastBallPosition.y
                            if abs(xDelta) > 0.0005 {
                                self.computedLaunchAngleDegrees = atan2(yDelta, xDelta) * 180.0 / .pi
                            }

                            if self.computedBallSpeedMPH > 0 {
                                let rad = self.computedLaunchAngleDegrees * .pi / 180.0
                                // Use a release-height-aware heuristic: assume contact height
                                // is roughly torso + arm extension above ground in the frame.
                                // Since we don't have floor/world coords here, keep the
                                // projected distance but clamp it into a realistic volleyball range.
                                var distance = abs((pow(self.computedBallSpeedMPH * 1.46667, 2) * sin(2 * rad)) / 32.2)
                                if distance < 6.0 { distance = 6.0 + abs(yDelta) * 40.0 }
                                if distance > 90.0 { distance = 90.0 }
                                self.computedFlightDistanceFeet = distance
                            }
                        }
                    }

                    self.lastBallPosition = currentBallPosition
                    self.lastBallTime = Date()
                }
            } else {
                DispatchQueue.main.async {
                    self.ballBoundingBoxRect = nil
                }
            }
        } else {
            DispatchQueue.main.async {
                self.ballBoundingBoxRect = nil
            }
        }
    }

    private func calculateAngle(a: CGPoint, b: CGPoint, c: CGPoint) -> Double {
        let v1 = CGPoint(x: a.x - b.x, y: a.y - b.y)
        let v2 = CGPoint(x: c.x - b.x, y: c.y - b.y)
        let angle = atan2(v2.y, v2.x) - atan2(v1.y, v1.x)
        var degree = abs(angle * 180.0 / .pi)
        if degree > 180.0 { degree = 360.0 - degree }
        return degree
    }
}

