import Foundation
import CoreGraphics

// MARK: - Serve Speed Analyzer

/// Detects the serve contact frame, computes ball velocity using
/// a 7‑frame window after contact, applies pixel‑to‑meter
/// conversion and smoothing.
final class ServeSpeedAnalyzer: ObservableObject {

    // MARK: - Published Output

    /// Final serve speed in meters per second.
    @Published private(set) var serveSpeedMPS: Double = 0.0

    /// Serve speed in miles per hour.
    @Published private(set) var serveSpeedMPH: Double = 0.0

    /// Peak velocity observed in the tracking window (m/s).
    @Published private(set) var peakSpeedMPS: Double = 0.0

    /// Overall confidence in the serve speed estimate (0–1).
    @Published private(set) var confidence: Double = 0.0

    /// Whether a serve has been detected.
    @Published private(set) var serveDetected: Bool = false

    /// Launch angle of the serve in degrees.
    @Published private(set) var launchAngleDegrees: Double = 0.0

    // MARK: - Configuration

    /// Number of frames after contact to use for velocity estimation.
    let postContactWindowSize: Int = 7

    /// Minimum frames required before computing speed.
    let minFramesForComputation: Int = 3

    private let calibration: CalibrationManager

    // MARK: - Internal State

    /// Ball tracking frames post-contact.
    struct ServeBallFrame {
        let position: CGPoint       // pixel coordinates
        let timestamp: TimeInterval
        let boundingBox: CGRect     // normalized 0–1
    }

    private var ballFrameBuffer: RingBuffer<ServeBallFrame>

    /// Contact frame reference.
    private var contactTimestamp: TimeInterval?
    private var contactPosition: CGPoint?

    /// Speed estimates from each valid pair of frames.
    private var speedEstimates: [Double] = []

    /// Kalman filter for smoothing.
    private var speedKalman: KalmanFilter1D

    /// EMA smoothing state.
    private var previousSmoothedSpeed: Double = 0.0

    // MARK: - Init

    init(calibration: CalibrationManager) {
        self.calibration = calibration
        self.ballFrameBuffer = RingBuffer(capacity: postContactWindowSize + 3)

        self.speedKalman = KalmanFilter1D(
            initialPosition: 0,
            initialVelocity: 0,
            processNoise: 0.1,
            measurementNoise: 0.5
        )
    }

    // MARK: - Frame Processing

    /// Ingest a ball detection frame.
    func processBallFrame(
        position: CGPoint,
        timestamp: TimeInterval,
        boundingBox: CGRect
    ) {
        let frame = ServeBallFrame(
            position: position,
            timestamp: timestamp,
            boundingBox: boundingBox
        )
        ballFrameBuffer.push(frame)

        guard serveDetected else { return }

        // Use exactly the 7-frame window after contact
        let frames = ballFrameBuffer.elements
        let windowed = Array(frames.suffix(postContactWindowSize))

        guard windowed.count >= minFramesForComputation else { return }

        computeServeSpeed(windowed: windowed)
    }

    // MARK: - Contact Detection

    /// Mark the serve contact event at a specific timestamp and position.
    /// This can be triggered by pose‑based wrist direction change detection,
    /// audio peak, or manual trigger.
    func markServeContact(
        timestamp: TimeInterval,
        ballPosition: CGPoint,
        boundingBox: CGRect = .zero
    ) {
        serveDetected = true
        contactTimestamp = timestamp
        contactPosition = ballPosition

        // Clear residual pre-contact frames
        ballFrameBuffer.clear()

        let frame = ServeBallFrame(
            position: ballPosition,
            timestamp: timestamp,
            boundingBox: boundingBox
        )
        ballFrameBuffer.push(frame)

        speedEstimates.removeAll()
        previousSmoothedSpeed = 0.0
    }

    /// Auto-detect serve contact from ball motion onset.
    /// Look for the ball transitioning from stationary/near‑stationary
    /// to rapid motion (typical of a serve toss → hit transition).
    func detectServeContactFromMotion() {
        let frames = ballFrameBuffer.elements
        guard frames.count >= 4 else { return }

        // Compare recent velocity over short window vs longer window
        let recent = Array(frames.suffix(3))
        guard let rFirst = recent.first, let rLast = recent.last else { return }

        let rDt = rLast.timestamp - rFirst.timestamp
        guard rDt > 0.01 else { return }

        let rDx = rLast.position.x - rFirst.position.x
        let rDy = rLast.position.y - rFirst.position.y
        let recentSpeed = sqrt(rDx * rDx + rDy * rDy) / rDt

        // Ball must show significant acceleration
        let pixelThreshold: Double = 400  // pixels/sec
        if recentSpeed > pixelThreshold && !serveDetected {
            markServeContact(
                timestamp: rFirst.timestamp,
                ballPosition: rFirst.position
            )
        }
    }

    // MARK: - Speed Computation

    private func computeServeSpeed(windowed: [ServeBallFrame]) {
        guard windowed.count >= 2,
              let first = windowed.first,
              let last = windowed.last else { return }

        // Step 1: Pixel displacement over the window
        let dx = last.position.x - first.position.x
        let dy = last.position.y - first.position.y
        let pixelDistance = sqrt(dx * dx + dy * dy)

        let totalDt = last.timestamp - first.timestamp
        guard totalDt > 0.02 else { return }

        // Step 2: Motion‑blur detection for confidence weighting
        let blurScore = SmoothingUtils.motionBlurScore(
            boxWidth: Double(last.boundingBox.width),
            boxHeight: Double(last.boundingBox.height),
            previousWidth: Double(first.boundingBox.width),
            previousHeight: Double(first.boundingBox.height),
            velocityMagnitude: pixelDistance / totalDt
        )

        // Step 3: Pixel-to-meter conversion
        let metersDistance = calibration.pixelsToMeters(pixelDistance)
        let rawSpeedMPS = metersDistance / totalDt

        // Step 4: Compute launch angle
        if pixelDistance > 1.0 {
            // Angle from horizontal; negative dy = ball moving upward
            let angle = atan2(-dy, abs(dx)) * 180.0 / .pi
            launchAngleDegrees = max(-10.0, min(45.0, angle))
        }

        // Step 5: Track peak speed
        if rawSpeedMPS > peakSpeedMPS {
            peakSpeedMPS = rawSpeedMPS
        }

        // Step 6: Collect speed estimates from sub‑windows (robustness)
        collectSpeedEstimates(windowed: windowed)

        // Step 7: Final fusion of estimates
        let estimates = speedEstimates
        let fusedSpeed: Double
        if estimates.count >= 2 {
            fusedSpeed = SmoothingUtils.robustMovingAverage(estimates, window: min(5, estimates.count))
        } else {
            fusedSpeed = rawSpeedMPS
        }

        // Step 8: Kalman filtering
        let kalmanDt = max(totalDt, 0.016)
        let filteredSpeed = speedKalman.filter(measurement: fusedSpeed, dt: kalmanDt)

        // Step 9: Temporal EMA smoothing
        let smoothedSpeed = SmoothingUtils.exponentialMovingAverage(
            current: filteredSpeed,
            previous: previousSmoothedSpeed,
            alpha: 0.35
        )
        previousSmoothedSpeed = smoothedSpeed

        // Step 10: Clamp to serve speed bounds
        // Top serves: ~130 km/h ≈ 36 m/s
        let clampedSpeed = max(5.0, min(smoothedSpeed, 38.0))

        // Step 11: Confidence estimation
        let frameCompleteness = Double(windowed.count) / Double(postContactWindowSize)
        let detectionScore = max(0.0, min(1.0, 1.0 - blurScore * 0.6))
        let estimateConsistency: Double
        if estimates.count >= 2 {
            let avg = estimates.reduce(0, +) / Double(estimates.count)
            let variance = estimates.reduce(0) { $0 + pow($1 - avg, 2) } / Double(estimates.count)
            estimateConsistency = exp(-variance / max(1.0, avg * avg * 0.02))
        } else {
            estimateConsistency = 0.5
        }

        let overallConf = frameCompleteness * 0.35
            + detectionScore * 0.35
            + estimateConsistency * 0.30

        let mpsToMPH = 2.23694

        DispatchQueue.main.async { [weak self] in
            self?.serveSpeedMPS = clampedSpeed
            self?.serveSpeedMPH = clampedSpeed * mpsToMPH
            self?.confidence = overallConf
        }
    }

    /// Collect speed estimates from overlapping sub‑windows within the main window
    /// to improve robustness against outlier frames.
    private func collectSpeedEstimates(windowed: [ServeBallFrame]) {
        guard windowed.count >= 3 else { return }

        // Sliding sub‑windows of size 3 within the main window
        for i in 0...(windowed.count - 3) {
            let subFirst = windowed[i]
            let subLast = windowed[i + 2]
            let sDt = subLast.timestamp - subFirst.timestamp
            guard sDt > 0.01 else { continue }

            let sDx = subLast.position.x - subFirst.position.x
            let sDy = subLast.position.y - subFirst.position.y
            let sDist = sqrt(sDx * sDx + sDy * sDy)

            let sMeters = calibration.pixelsToMeters(sDist)
            let sSpeed = sMeters / sDt

            speedEstimates.append(sSpeed)
        }

        // Keep only most recent 10 estimates
        if speedEstimates.count > 10 {
            speedEstimates = Array(speedEstimates.suffix(10))
        }
    }

    // MARK: - Convenience

    /// Get current serve speed in MPH.
    var currentServeSpeedMPH: Double { serveSpeedMPH }

    /// Get current serve speed in MPS.
    var currentServeSpeedMPS: Double { serveSpeedMPS }

    /// Reset all internal state for a new serve.
    func reset() {
        ballFrameBuffer.clear()
        speedEstimates.removeAll()
        speedKalman.reset()
        previousSmoothedSpeed = 0.0
        contactTimestamp = nil
        contactPosition = nil
        serveSpeedMPS = 0.0
        serveSpeedMPH = 0.0
        peakSpeedMPS = 0.0
        confidence = 0.0
        launchAngleDegrees = 0.0
        serveDetected = false
    }
}