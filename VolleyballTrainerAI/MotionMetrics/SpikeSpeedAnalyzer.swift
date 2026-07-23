import Foundation
import CoreGraphics

// MARK: - Spike Speed Analyzer

/// Detects hand‑ball contact frame, computes hand velocity at impact,
/// fuses hand velocity with ball velocity for final spike speed,
/// using multi‑frame pre‑impact and post‑impact windows.
final class SpikeSpeedAnalyzer: ObservableObject {

    // MARK: - Published Output

    /// Final spike speed in meters per second.
    @Published private(set) var spikeSpeedMPS: Double = 0.0

    /// Spike speed in miles per hour.
    @Published private(set) var spikeSpeedMPH: Double = 0.0

    /// Hand speed at moment of contact (m/s).
    @Published private(set) var handSpeedAtContactMPS: Double = 0.0

    /// Ball velocity immediately after contact (m/s).
    @Published private(set) var ballSpeedPostContactMPS: Double = 0.0

    /// Overall confidence in the spike speed estimate (0–1).
    @Published private(set) var confidence: Double = 0.0

    /// Whether a contact event has been detected in the current sequence.
    @Published private(set) var contactDetected: Bool = false

    // MARK: - Configuration

    /// Frames to analyze before the contact event.
    let preImpactWindowSize: Int = 5

    /// Frames to analyze after the contact event.
    let postImpactWindowSize: Int = 7

    /// Minimum wrist velocity (pixels/sec) to consider a contact event.
    let contactVelocityThreshold: Double = 800.0

    private let calibration: CalibrationManager

    // MARK: - Internal State

    /// Hand position (wrist centroid) history.
    struct HandFrame {
        let position: CGPoint      // pixel coordinates
        let timestamp: TimeInterval
        let wristLeft: CGPoint?    // for two-handed analysis
        let wristRight: CGPoint?
    }

    private var handFrameBuffer: RingBuffer<HandFrame>

    /// Ball position history.
    struct BallFrame {
        let position: CGPoint
        let timestamp: TimeInterval
    }

    private var ballFrameBuffer: RingBuffer<BallFrame>

    /// Pre-impact hand velocity samples.
    private var preImpactHandVelocities: [Double] = []

    /// Post-impact ball velocity samples.
    private var postImpactBallVelocities: [Double] = []

    /// Contact timestamp.
    private var contactTimestamp: TimeInterval?

    /// Contact position.
    private var contactPosition: CGPoint?

    /// Kalman filter for final spike speed.
    private var speedKalman: KalmanFilter1D

    /// History for final smoothing.
    private var spikeSpeedHistory: RingBuffer<Double> = RingBuffer(capacity: 5)

    // MARK: - Init

    init(calibration: CalibrationManager) {
        self.calibration = calibration
        self.handFrameBuffer = RingBuffer(capacity: preImpactWindowSize + 3)
        self.ballFrameBuffer = RingBuffer(capacity: postImpactWindowSize + 3)

        self.speedKalman = KalmanFilter1D(
            initialPosition: 0,
            initialVelocity: 0,
            processNoise: 0.2,
            measurementNoise: 0.6
        )
    }

    // MARK: - Frame Processing

    /// Ingest a hand tracking frame.
    func processHandFrame(
        wristPosition: CGPoint,
        timestamp: TimeInterval,
        wristLeft: CGPoint? = nil,
        wristRight: CGPoint? = nil
    ) {
        let frame = HandFrame(
            position: wristPosition,
            timestamp: timestamp,
            wristLeft: wristLeft,
            wristRight: wristRight
        )
        handFrameBuffer.push(frame)

        // Detect contact event
        detectContact()
    }

    /// Ingest a ball tracking frame (post-contact).
    func processBallFrame(position: CGPoint, timestamp: TimeInterval) {
        guard contactDetected else { return }

        let frame = BallFrame(position: position, timestamp: timestamp)
        ballFrameBuffer.push(frame)

        computePostContactBallVelocity()
    }

    // MARK: - Contact Detection

    private func detectContact() {
        let frames = handFrameBuffer.elements
        guard frames.count >= 3 else { return }

        let last = frames[frames.count - 1]
        let secondLast = frames[frames.count - 2]
        let thirdLast = frames[frames.count - 3]

        let dt = last.timestamp - secondLast.timestamp
        guard dt > 0.001 else { return }

        // Compute hand velocity
        let dx = last.position.x - secondLast.position.x
        let dy = last.position.y - secondLast.position.y
        let handVelocity = sqrt(dx * dx + dy * dy) / dt

        // Compute prior velocity
        let pdt = secondLast.timestamp - thirdLast.timestamp
        guard pdt > 0.001 else { return }
        let pdx = secondLast.position.x - thirdLast.position.x
        let pdy = secondLast.position.y - thirdLast.position.y
        let priorVelocity = sqrt(pdx * pdx + pdy * pdy) / pdt

        // Contact detection: rapid deceleration after high velocity
        // In a spike, the hand reaches maximum speed just before contact,
        // then sharply decelerates upon impact.
        let velocityDrop = priorVelocity - handVelocity
        let peakVelocity = max(handVelocity, priorVelocity)

        if peakVelocity > contactVelocityThreshold && velocityDrop > 250 {
            contactDetected = true
            contactTimestamp = last.timestamp
            contactPosition = last.position

            // Capture pre-impact hand velocity from the window
            capturePreImpactVelocity(frames: frames)

            // Compute hand speed at contact
            let handSpeedPixelsPerSec = peakVelocity
            let handSpeedMPS = calibration.pixelsToMeters(handSpeedPixelsPerSec)
            handSpeedAtContactMPS = handSpeedMPS
        }
    }

    /// Extract hand velocity from the pre-impact window.
    private func capturePreImpactVelocity(frames: [HandFrame]) {
        let windowed = Array(frames.suffix(preImpactWindowSize))
        guard windowed.count >= 2,
              let first = windowed.first,
              let last = windowed.last else { return }

        let totalDt = last.timestamp - first.timestamp
        guard totalDt > 0.01 else { return }

        let dx = last.position.x - first.position.x
        let dy = last.position.y - first.position.y
        let pixelDist = sqrt(dx * dx + dy * dy)

        let speedPixelsPerSec = pixelDist / totalDt
        let speedMPS = calibration.pixelsToMeters(speedPixelsPerSec)

        preImpactHandVelocities.append(speedMPS)

        // Keep only recent samples
        if preImpactHandVelocities.count > 5 {
            preImpactHandVelocities.removeFirst()
        }
    }

    // MARK: - Post-Contact Ball Velocity

    private func computePostContactBallVelocity() {
        let frames = ballFrameBuffer.elements
        guard frames.count >= 2 else { return }

        let windowed = Array(frames.suffix(postImpactWindowSize))
        guard windowed.count >= 2,
              let first = windowed.first,
              let last = windowed.last else { return }

        let totalDt = last.timestamp - first.timestamp
        guard totalDt > 0.01 else { return }

        let dx = last.position.x - first.position.x
        let dy = last.position.y - first.position.y
        let pixelDist = sqrt(dx * dx + dy * dy)

        let speedPixelsPerSec = pixelDist / totalDt
        let speedMPS = calibration.pixelsToMeters(speedPixelsPerSec)

        ballSpeedPostContactMPS = speedMPS
        postImpactBallVelocities.append(speedMPS)

        if postImpactBallVelocities.count > 5 {
            postImpactBallVelocities.removeFirst()
        }

        computeFinalSpikeSpeed()
    }

    // MARK: - Final Speed Computation

    private func computeFinalSpikeSpeed() {
        // Step 1: Get pre-impact hand velocity (primary contributor)
        let avgHandSpeed: Double
        if !preImpactHandVelocities.isEmpty {
            avgHandSpeed = SmoothingUtils.robustMovingAverage(preImpactHandVelocities, window: 5)
        } else {
            avgHandSpeed = handSpeedAtContactMPS
        }

        // Step 2: Get post-impact ball velocity (secondary)
        let avgBallSpeed: Double
        if !postImpactBallVelocities.isEmpty {
            avgBallSpeed = SmoothingUtils.robustMovingAverage(postImpactBallVelocities, window: 5)
        } else {
            avgBallSpeed = ballSpeedPostContactMPS
        }

        // Step 3: Fuse hand and ball velocity
        // In elite volleyball, spike speed is typically 1.2–1.8× hand speed at contact
        // due to the whip effect of the arm, wrist snap, and ball compression.
        let handContribution = avgHandSpeed * 1.35
        let ballContribution = avgBallSpeed * 1.0

        // Weighted fusion: hand velocity is the primary driver
        var fusedSpeed = handContribution * 0.65 + ballContribution * 0.35

        // Step 4: Physics-based correction
        // Elite male spike: ~80–110 km/h (22–30.5 m/s)
        // Elite female spike: ~70–95 km/h (19.5–26.5 m/s)
        fusedSpeed = max(5.0, min(fusedSpeed, 32.0))

        // Step 5: Kalman filtering
        let dt = contactTimestamp.map { Date().timeIntervalSince1970 - $0 } ?? 0.03
        let filtered = speedKalman.filter(measurement: fusedSpeed, dt: max(dt, 0.01))

        // Step 6: Temporal smoothing
        spikeSpeedHistory.push(filtered)
        let smoothed = SmoothingUtils.robustMovingAverage(
            Array(spikeSpeedHistory.elements),
            window: 5
        )

        // Step 7: Confidence
        let handConf = min(1.0, preImpactHandVelocities.count >= 3 ? 0.7 : 0.3)
        let ballConf = min(1.0, postImpactBallVelocities.count >= 3 ? 0.6 : 0.2)
        let overallConf = handConf * 0.6 + ballConf * 0.4

        let mpsToMPH = 2.23694

        DispatchQueue.main.async { [weak self] in
            self?.spikeSpeedMPS = smoothed
            self?.spikeSpeedMPH = smoothed * mpsToMPH
            self?.confidence = overallConf
        }
    }

    // MARK: - Manual Contact Trigger

    /// Manually trigger a contact event at the given timestamp and position.
    /// Useful for integrating with external contact detection (e.g., sound-based).
    func markContact(timestamp: TimeInterval, handPosition: CGPoint) {
        contactDetected = true
        contactTimestamp = timestamp
        contactPosition = handPosition

        // Estimate hand speed from recent frames
        let frames = handFrameBuffer.elements
        if frames.count >= 2 {
            let last = frames.last!
            let prev = frames[frames.count - 2]
            let dt = last.timestamp - prev.timestamp
            if dt > 0.001 {
                let dx = last.position.x - prev.position.x
                let dy = last.position.y - prev.position.y
                let speed = sqrt(dx * dx + dy * dy) / dt
                handSpeedAtContactMPS = calibration.pixelsToMeters(speed)
            }
        }
    }

    /// Get current spike speed in MPH for compatibility with existing systems.
    var currentSpikeSpeedMPH: Double { spikeSpeedMPH }

    /// Get current spike speed in MPS.
    var currentSpikeSpeedMPS: Double { spikeSpeedMPS }

    /// Reset all internal state.
    func reset() {
        handFrameBuffer.clear()
        ballFrameBuffer.clear()
        preImpactHandVelocities.removeAll()
        postImpactBallVelocities.removeAll()
        contactTimestamp = nil
        contactPosition = nil
        spikeSpeedHistory.clear()
        speedKalman.reset()
        spikeSpeedMPS = 0.0
        spikeSpeedMPH = 0.0
        handSpeedAtContactMPS = 0.0
        ballSpeedPostContactMPS = 0.0
        confidence = 0.0
        contactDetected = false
    }
}