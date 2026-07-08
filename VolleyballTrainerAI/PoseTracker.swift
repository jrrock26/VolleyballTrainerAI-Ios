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
    private var bodyScaleNorm: Double? = nil
    private var assumedTorsoInches: Double {
        let height = ProfileManager.shared.profile.heightInches
        if height > 0 {
            // Torso (shoulder-to-hip) is approximately 28.8% of total height
            return height * 0.288
        }
        return 22.0 // default fallback
    }

    private var smoothedJoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private var jointMissingFrames: [VNHumanBodyPoseObservation.JointName: Int] = [:]
    private let jointSmoothingAlpha: CGFloat = 0.75
    private let jointHoldFrames = 4

    private var lastFrameTime = Date()
    private var isHitCaptured = false
    private var lastWristYBySide: [Bool: CGFloat] = [:]
    private var lastWristPointBySide: [Bool: CGPoint] = [:]
    private var ascendingBySide: [Bool: Bool] = [:]
    private var peakSwingVelocityNormPerSecond: Double = 0.0

    // Ball Physics Trackers
    private var lastBallPositionPixels: CGPoint = .zero
    private var lastBallPositionNorm: CGPoint = .zero
    private var initialBallContactTime: Date? = nil
    private var lastBallTime: Date? = nil
    private var ballTrajectoryPoints: [CGPoint] = []
    private var recentBallSpeedSamples: [Double] = []
    private let ballSpeedSampleLimit: Int = 6
    private let assumedBallDiameterPixels: Double = 28.0

    @Published var computedBallSpeedMPH: Double = 0.0
    @Published var computedLaunchAngleDegrees: Double = 0.0
    @Published var computedFlightDistanceFeet: Double = 0.0
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
            self.lastWristPointBySide.removeAll()
            self.ascendingBySide.removeAll()
            self.peakSwingVelocityNormPerSecond = 0.0
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
            self.lastBallPositionPixels = .zero
            self.lastBallPositionNorm = .zero
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

    private func averageHipY(leftHip: VNRecognizedPoint, rightHip: VNRecognizedPoint, threshold: Float) -> Double? {
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

    func cgOrientationFrom(_ videoOrientation: AVCaptureVideoOrientation, cameraPosition: AVCaptureDevice.Position) -> CGImagePropertyOrientation {
        switch videoOrientation {
        case .portrait:
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

        let useRightArm: Bool
        if let r = rightWrist, let l = leftWrist {
            useRightArm = r.confidence >= l.confidence
        } else {
            useRightArm = rightWrist != nil
        }

        let shoulder = useRightArm ? (try? observation.recognizedPoint(.rightShoulder)) : (try? observation.recognizedPoint(.leftShoulder))
        let elbow = useRightArm ? (try? observation.recognizedPoint(.rightElbow)) : (try? observation.recognizedPoint(.leftElbow))
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

            for isRight in [true, false] {
                guard let armWrist = isRight ? rightWrist : leftWrist,
                      let armShoulder = isRight ? (try? observation.recognizedPoint(.rightShoulder)) : (try? observation.recognizedPoint(.leftShoulder)),
                      armWrist.confidence > confidenceThreshold,
                      armShoulder.confidence > confidenceThreshold else { continue }

                let currentWristY = armWrist.location.y
                let currentWristPoint = armWrist.location

                if timeDelta > 0, let lastY = self.lastWristYBySide[isRight] {
                    let yDelta = currentWristY - lastY
                    let instantaneousVelocity = abs(yDelta) / timeDelta
                    let fullSwingVelocity: Double

                    if let lastPoint = self.lastWristPointBySide[isRight] {
                        let dx = Double(currentWristPoint.x - lastPoint.x)
                        let dy = Double(currentWristPoint.y - lastPoint.y)
                        fullSwingVelocity = sqrt(dx * dx + dy * dy) / timeDelta
                    } else {
                        fullSwingVelocity = instantaneousVelocity
                    }

                    if fullSwingVelocity.isFinite {
                        self.peakSwingVelocityNormPerSecond = max(
                            self.peakSwingVelocityNormPerSecond,
                            fullSwingVelocity
                        )
                    }

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
                        let capturedSwingVelocity = max(
                            self.peakSwingVelocityNormPerSecond,
                            fullSwingVelocity,
                            instantaneousVelocity
                        )

                        self.applyFallbackPerformanceMetricsIfNeeded(
                            hitType: type,
                            jumpHeight: capturedJump,
                            armAngle: capturedAngle,
                            swingVelocityNormPerSecond: capturedSwingVelocity,
                            force: true
                        )

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.applyFallbackPerformanceMetricsIfNeeded(
                                hitType: type,
                                jumpHeight: capturedJump,
                                armAngle: capturedAngle,
                                swingVelocityNormPerSecond: capturedSwingVelocity,
                                force: false
                            )

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
                self.lastWristPointBySide[isRight] = currentWristPoint
                if self.isHitCaptured { break }
            }
        }
    }

    private func applyFallbackPerformanceMetricsIfNeeded(
        hitType: String,
        jumpHeight: Double,
        armAngle: Double,
        swingVelocityNormPerSecond: Double,
        force: Bool
    ) {
        guard swingVelocityNormPerSecond.isFinite, swingVelocityNormPerSecond > 0 else { return }

        let needsSpeed = force || computedBallSpeedMPH < 1.0
        let needsDistance = force || computedFlightDistanceFeet < 1.0
        let needsLaunch = force || abs(computedLaunchAngleDegrees) < 0.1

        guard needsSpeed || needsDistance || needsLaunch else { return }

        let clampedSwing = max(0.6, min(swingVelocityNormPerSecond, 8.5))
        let armQuality = max(0.75, min(1.15, armAngle / 160.0))
        let jumpBonus = hitType == "Spike" ? min(jumpHeight * 0.22, 7.0) : 0.0

        let estimatedSpeed: Double
        if hitType == "Serve" {
            estimatedSpeed = max(18.0, min(72.0, 20.0 + clampedSwing * 6.2 * armQuality))
        } else {
            estimatedSpeed = max(16.0, min(68.0, 17.0 + clampedSwing * 5.4 * armQuality + jumpBonus))
        }

        let estimatedLaunch = hitType == "Serve"
            ? max(6.0, min(24.0, 10.0 + clampedSwing * 1.3))
            : max(8.0, min(22.0, 11.0 + jumpHeight * 0.18))

        let estimatedDistance: Double
        if hitType == "Serve" {
            estimatedDistance = max(24.0, min(80.0, estimatedSpeed * 0.92 + estimatedLaunch * 0.65))
        } else {
            estimatedDistance = max(12.0, min(62.0, estimatedSpeed * 0.62 + jumpHeight * 0.35 + estimatedLaunch * 0.45))
        }

        if needsSpeed {
            computedBallSpeedMPH = max(computedBallSpeedMPH, estimatedSpeed)
        }
        if needsLaunch {
            computedLaunchAngleDegrees = estimatedLaunch
        }
        if needsDistance {
            computedFlightDistanceFeet = max(computedFlightDistanceFeet, estimatedDistance)
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
                if maxC > 90 && range > 35 {
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
            let centerXPixels = CGFloat(matchXSum) / CGFloat(matchCount)
            let centerYPixels = CGFloat(matchYSum) / CGFloat(matchCount)
            let currentBallPositionPixels = CGPoint(x: centerXPixels, y: centerYPixels)
            let currentBallPositionNorm = CGPoint(
                x: centerXPixels / CGFloat(width),
                y: centerYPixels / CGFloat(height)
            )

            let boxW = CGFloat(maxX - minX) / CGFloat(width)
            let boxH = CGFloat(maxY - minY) / CGFloat(height)
            let aspect = boxW / max(boxH, 0.001)
            let boxArea = CGFloat(maxX - minX) * CGFloat(maxY - minY)
            let density = CGFloat(matchCount) / max(boxArea, 1.0)

            let inPlayerZone = currentBallPositionNorm.y > 0.28 && currentBallPositionNorm.y < 0.92

            if aspect > 0.45 && aspect < 2.2 && density > 0.15 && boxW > 0.006 && boxW < 0.22 && boxH > 0.006 && boxH < 0.22 && inPlayerZone {
                DispatchQueue.main.async {
                    let drawW = CGFloat(maxX - minX) / CGFloat(width)
                    let drawH = CGFloat(maxY - minY) / CGFloat(height)
                    let paddedW = max(0.04, drawW * 1.15)
                    let paddedH = max(0.04, drawH * 1.15)

                    self.ballBoundingBoxRect = CGRect(
                        x: currentBallPositionNorm.x - (paddedW / 2),
                        y: 1.0 - currentBallPositionNorm.y - (paddedH / 2),
                        width: paddedW,
                        height: paddedH
                    )

                    if let contactTime = self.initialBallContactTime,
                       !self.lastBallPositionPixels.equalTo(.zero) {
                        let timeElapsed = Date().timeIntervalSince(contactTime)
                        if timeElapsed > 0 && timeElapsed < 1.2 {
                            let dx = currentBallPositionPixels.x - self.lastBallPositionPixels.x
                            let dy = currentBallPositionPixels.y - self.lastBallPositionPixels.y
                            let pixelDistance = sqrt(dx * dx + dy * dy)

                            let pixelsPerFoot = max(self.assumedBallDiameterPixels / 0.23, 16.0)
                            let feetTraveled = pixelDistance / pixelsPerFoot

                            let now = Date()
                            let dt = self.lastBallTime.map { now.timeIntervalSince($0) } ?? 0.033
                            let clampedDt = max(0.005, min(dt, 0.15))

                            let feetPerSecond = feetTraveled / clampedDt
                            let velocityMPH = min(max(feetPerSecond * 3600.0 / 5280.0, 0), 160)

                            if velocityMPH >= 0.8 && velocityMPH <= 160 {
                                self.recentBallSpeedSamples.append(velocityMPH)
                                if self.recentBallSpeedSamples.count > self.ballSpeedSampleLimit {
                                    self.recentBallSpeedSamples.removeFirst()
                                }
                                let smoothed = self.recentBallSpeedSamples.reduce(0, +) / Double(self.recentBallSpeedSamples.count)
                                self.computedBallSpeedMPH = smoothed
                            } else if velocityMPH > 160 {
                                self.computedBallSpeedMPH = 160
                            } else if velocityMPH >= 0.1 {
                                self.computedBallSpeedMPH = velocityMPH
                            }

                            if pixelDistance > 1.0 {
                                let launchAngle = atan2(-dy, abs(dx)) * 180.0 / .pi
                                self.computedLaunchAngleDegrees = max(-15.0, min(75.0, launchAngle))
                            }

                            if self.computedBallSpeedMPH > 0 {
                                let rad = self.computedLaunchAngleDegrees * .pi / 180.0
                                let physicsDistance = abs((pow(self.computedBallSpeedMPH * 1.46667, 2) * sin(2 * rad)) / 32.2)
                                let trackedDistance = hypot(
                                    currentBallPositionPixels.x - self.lastBallPositionPixels.x,
                                    currentBallPositionPixels.y - self.lastBallPositionPixels.y
                                ) / pixelsPerFoot
                                var distance = max(self.computedFlightDistanceFeet, physicsDistance, trackedDistance)
                                if distance < 3.0 { distance = 3.0 + trackedDistance * 5.0 }
                                if distance > 90.0 { distance = 90.0 }
                                self.computedFlightDistanceFeet = distance
                            }
                        }
                    }

                    self.lastBallPositionPixels = currentBallPositionPixels
                    self.lastBallPositionNorm = currentBallPositionNorm
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