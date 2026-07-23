import Foundation
import CoreGraphics

// MARK: - Ball Speed Tracker

/// Tracks ball position over time and computes ball speed using
/// a rolling 5–7 frame window, pixel‑to‑meter calibration,
/// motion‑blur detection, confidence weighting, and Kalman filtering.
final class BallSpeedTracker: ObservableObject {

    // MARK: - Published Output

    /// Smoothed ball speed in meters per second.
    @Published private(set) var speedMPS: Double = 0.0

    /// Ball speed in miles per hour.
    @Published private(set) var speedMPH: Double = 0.0

    /// Current confidence in the speed estimate (0–1).
    @Published private(set) var confidence: Double = 0.0

    /// Most recent velocity vector (dx, dy) in m/s.
    @Published private(set) var velocityVector: CGPoint = .zero

    // MARK: - Configuration

    /// Rolling window size for velocity estimation (5–7 frames).
    let velocityWindowSize: Int = 6

    /// Calibration manager for pixel‑to‑meter conversion.
    private let calibration: CalibrationManager

    // MARK: - Internal State

    /// Ring buffer of (position, timestamp, boundingBox) tuples.
    struct BallFrame {
        let position: CGPoint       // pixel coordinates
        let timestamp: TimeInterval
        let boundingBox: CGRect     // normalized 0–1
    }

    private var frameBuffer: RingBuffer<BallFrame>
    private var speedHistory: RingBuffer<Double> = RingBuffer(capacity: 8)
    private var kalmanFilter: KalmanFilter1D

    private var lastBoundingBox: CGRect = .zero
    private var previousSmoothedSpeed: Double = 0.0

    // MARK: - Init

    init(calibration: CalibrationManager) {
        self.calibration = calibration
        self.frameBuffer = RingBuffer(capacity: velocityWindowSize + 2)

        // Initialize Kalman filter with sport-appropriate process/measurement noise.
        // Ball can accelerate/decelerate quickly; process noise moderated.
        self.kalmanFilter = KalmanFilter1D(
            initialPosition: 0,
            initialVelocity: 0,
            processNoise: 0.15,
            measurementNoise: 0.8
        )
    }

    // MARK: - Frame Processing

    /// Ingest a new ball detection frame and update speed estimates.
    /// - Parameters:
    ///   - position: Ball center in pixel coordinates.
    ///   - timestamp: Capture timestamp (seconds).
    ///   - boundingBox: Normalized bounding box of the detection (0–1 coordinate space).
    func processFrame(position: CGPoint, timestamp: TimeInterval, boundingBox: CGRect) {
        let frame = BallFrame(
            position: position,
            timestamp: timestamp,
            boundingBox: boundingBox
        )
        frameBuffer.push(frame)

        // Need at least 2 frames for velocity
        guard frameBuffer.count >= 2 else { return }

        computeSpeed()
    }

    // MARK: - Speed Computation

    private func computeSpeed() {
        let frames = frameBuffer.elements
        guard frames.count >= 2,
              let first = frames.first,
              let last = frames.last else { return }

        // --- Step 1: Pixel displacement over the window ---
        let dx = last.position.x - first.position.x
        let dy = last.position.y - first.position.y
        let pixelDist = sqrt(dx * dx + dy * dy)

        let dt = last.timestamp - first.timestamp
        guard dt > 0.002 else { return }

        // --- Step 2: Motion-blur detection ---
        let blurScore = SmoothingUtils.motionBlurScore(
            boxWidth: Double(last.boundingBox.width),
            boxHeight: Double(last.boundingBox.height),
            previousWidth: Double(first.boundingBox.width),
            previousHeight: Double(first.boundingBox.height),
            velocityMagnitude: pixelDist / dt
        )

        // --- Step 3: Pixel-to-meter conversion ---
        let metersDist = calibration.pixelsToMeters(pixelDist)
        let rawSpeedMPS = metersDist / dt

        // --- Step 4: Confidence weighting ---
        // Detection quality based on bounding box stability
        let boxSize = last.boundingBox.width * last.boundingBox.height
        let detectionScore = min(1.0, max(0.0, boxSize * 80.0)) * (1.0 - blurScore * 0.5)

        speedHistory.push(rawSpeedMPS)
        let historyValues = speedHistory.elements

        let rawConfidence = SmoothingUtils.computeConfidence(
            detectionScore: detectionScore,
            recentValues: historyValues,
            currentValue: rawSpeedMPS
        )

        // --- Step 5: Kalman filtering ---
        let filteredSpeed = kalmanFilter.filter(measurement: rawSpeedMPS, dt: dt)

        // --- Step 6: Temporal smoothing over 3–5 frames ---
        let smoothedSpeed = SmoothingUtils.exponentialMovingAverage(
            current: filteredSpeed,
            previous: previousSmoothedSpeed,
            alpha: 0.35
        )
        previousSmoothedSpeed = smoothedSpeed

        // --- Step 7: Clamp to physiological bounds ---
        // Maximum recorded volleyball serve ~135 km/h ≈ 37.5 m/s spike ~110 km/h ≈ 30.5 m/s
        let clampedSpeed = max(0, min(smoothedSpeed, 40.0))

        // --- Step 8: Publish results ---
        let mpsToMPH = 2.23694

        DispatchQueue.main.async { [weak self] in
            self?.speedMPS = clampedSpeed
            self?.speedMPH = clampedSpeed * mpsToMPH
            self?.confidence = rawConfidence

            // Velocity vector direction
            let mag = hypot(dx, dy)
            if mag > 0 {
                self?.velocityVector = CGPoint(
                    x: (dx / mag) * clampedSpeed,
                    y: (dy / mag) * clampedSpeed
                )
            }
        }
    }

    // MARK: - Window-Based Velocity (for external use)

    /// Compute speed over a custom window size using the frame buffer.
    func computeSpeed(window: Int) -> (speedMPS: Double, confidence: Double)? {
        let frames = frameBuffer.elements
        let windowed = frames.suffix(min(window, frames.count))
        guard windowed.count >= 2,
              let first = windowed.first,
              let last = windowed.last else { return nil }

        let dx = last.position.x - first.position.x
        let dy = last.position.y - first.position.y
        let pixelDist = sqrt(dx * dx + dy * dy)
        let dt = last.timestamp - first.timestamp
        guard dt > 0.002 else { return nil }

        let metersDist = calibration.pixelsToMeters(pixelDist)
        let speed = metersDist / dt

        let conf = min(1.0, Double(windowed.count) / Double(window))
        return (speed, conf)
    }

    /// Get current filtered speed in MPH.
    var currentSpeedMPH: Double { speedMPH }

    /// Get current filtered speed in MPS.
    var currentSpeedMPS: Double { speedMPS }

    /// Reset all internal state.
    func reset() {
        frameBuffer.clear()
        speedHistory.clear()
        kalmanFilter.reset()
        previousSmoothedSpeed = 0.0
        speedMPS = 0.0
        speedMPH = 0.0
        confidence = 0.0
        velocityVector = .zero
        lastBoundingBox = .zero
    }
}