import Foundation

// MARK: - Jump Height Analyzer

/// Computes jump height using pelvis vertical displacement,
/// gravity‑based physics correction from airtime,
/// sensor‑fused accelerometer peaks, and temporal averaging.
final class JumpHeightAnalyzer: ObservableObject {

    // MARK: - Published Output

    /// Estimated jump height in meters.
    @Published private(set) var jumpHeightMeters: Double = 0.0

    /// Jump height in inches (convenient for display).
    @Published private(set) var jumpHeightInches: Double = 0.0

    /// Confidence in the current jump height estimate (0–1).
    @Published private(set) var confidence: Double = 0.0

    /// Whether a jump is currently in progress (athlete airborne).
    @Published private(set) var isAirborne: Bool = false

    // MARK: - Configuration

    private let calibration: CalibrationManager
    private let sensorFusion: SensorFusionManager

    /// Minimum vertical displacement to register a jump (meters).
    let minimumJumpThresholdM: Double = 0.05

    /// Frames needed to establish a standing baseline.
    let baselineFramesRequired: Int = 20

    // MARK: - Internal State

    /// Pelvis Y baseline for the standing reference.
    private var pelvisBaselineY: Double?

    /// Highest observed pelvis displacement above baseline.
    private var peakDisplacementPixels: Double = 0.0

    /// Ring buffer of recent pelvis displacements for temporal averaging.
    private var displacementHistory: RingBuffer<Double> = RingBuffer(capacity: 10)

    /// Ring buffer of recent jump heights for smoothing.
    private var jumpHeightHistory: RingBuffer<Double> = RingBuffer(capacity: 5)

    /// Kalman filter for vertical position smoothing.
    private var kalmanFilter: KalmanFilter1D

    /// Frame counter for baseline establishment.
    private var baselineFrameCount: Int = 0
    private var isBaselineLocked: Bool = false

    /// Airborne detection state.
    private var airtimeStart: TimeInterval?
    private var detectedAirtimeSeconds: Double = 0.0

    // MARK: - Gravity-based correction constants

    private let gravityMPS2: Double = 9.81

    // MARK: - Init

    init(calibration: CalibrationManager, sensorFusion: SensorFusionManager) {
        self.calibration = calibration
        self.sensorFusion = sensorFusion

        self.kalmanFilter = KalmanFilter1D(
            initialPosition: 0,
            initialVelocity: 0,
            processNoise: 0.05,
            measurementNoise: 0.3
        )
    }

    // MARK: - Frame Processing

    /// Process a new frame with pelvis Y coordinate (pixels or normalized).
    /// - Parameters:
    ///   - pelvisY: Pelvis Y position in pixel coordinates.
    ///   - timestamp: Frame capture timestamp.
    ///   - isFrontCamera: Whether the front camera is active (affects coordinate orientation).
    func processFrame(pelvisY: Double, timestamp: TimeInterval, isFrontCamera: Bool = false) {
        // Step 1: Establish baseline
        if !isBaselineLocked {
            baselineFrameCount += 1
            if let existing = pelvisBaselineY {
                pelvisBaselineY = existing * 0.85 + pelvisY * 0.15
            } else {
                pelvisBaselineY = pelvisY
            }
            if baselineFrameCount >= baselineFramesRequired {
                isBaselineLocked = true
            }
            return
        }

        guard let baseline = pelvisBaselineY else { return }

        // Step 2: Compute vertical displacement in pixels
        // Pose coordinate system: Y increases upward; pelvis above baseline = positive delta
        let pixelDisplacement = pelvisY - baseline

        // Step 3: Convert to meters using calibration
        let metersDisplacement = calibration.pixelsToMeters(pixelDisplacement)

        // Step 4: Kalman filter the displacement for noise reduction
        let filteredDisplacement = kalmanFilter.filter(measurement: metersDisplacement, dt: 1.0 / 30.0)

        // Step 5: Track peak displacement
        if filteredDisplacement > peakDisplacementPixels {
            peakDisplacementPixels = filteredDisplacement
        }

        // Step 6: Temporal averaging over recent displacements
        displacementHistory.push(filteredDisplacement)
        let averagedDisplacement: Double
        if displacementHistory.count >= 3 {
            averagedDisplacement = SmoothingUtils.robustMovingAverage(
                Array(displacementHistory.elements),
                window: 5
            )
        } else {
            averagedDisplacement = filteredDisplacement
        }

        // Step 7: Airborne detection
        let airborneThreshold = max(minimumJumpThresholdM, 0.03)
        if averagedDisplacement > airborneThreshold && !isAirborne {
            isAirborne = true
            airtimeStart = timestamp
        } else if averagedDisplacement <= airborneThreshold && isAirborne {
            isAirborne = false
            if let start = airtimeStart {
                detectedAirtimeSeconds = timestamp - start
                airtimeStart = nil
            }
        }

        // Step 8: Compute jump height
        // Primary method: peak vertical displacement
        let poseBasedHeight = max(0, peakDisplacementPixels)

        // Secondary method: gravity-corrected via airtime
        let gravityBasedHeight = SmoothingUtils.gravityCorrectedHeight(
            airtimeSeconds: detectedAirtimeSeconds
        )

        // Step 9: Sensor fusion — blend with accelerometer
        let fusedResult = sensorFusion.fuseVerticalMotion(
            poseDisplacementMeters: averagedDisplacement,
            poseConfidence: computeDisplacementConfidence(averagedDisplacement),
            dt: 1.0 / 30.0
        )

        let accelBasedHeight = SmoothingUtils.heightFromVelocity(
            verticalVelocityMPS: abs(fusedResult.velocity)
        )

        // Step 10: Weighted fusion of all sources
        let poseWeight = 0.6
        let gravityWeight = 0.2
        let accelWeight = 0.2

        var finalHeight = poseBasedHeight * poseWeight
            + gravityBasedHeight * gravityWeight
            + accelBasedHeight * accelWeight

        // Apply physiological limits
        finalHeight = max(0, min(finalHeight, 1.2)) // ~47 inches max for elite

        // Step 11: Smooth with history
        jumpHeightHistory.push(finalHeight)
        let smoothedHeight = SmoothingUtils.robustMovingAverage(
            Array(jumpHeightHistory.elements),
            window: 5
        )

        // Step 12: Confidence computation
        let displacementConf = computeDisplacementConfidence(averagedDisplacement)
        let gravConf = detectedAirtimeSeconds > 0.1 ? 0.8 : 0.3
        let overallConf = displacementConf * 0.5 + gravConf * 0.3 + 0.2

        DispatchQueue.main.async { [weak self] in
            self?.jumpHeightMeters = smoothedHeight
            self?.jumpHeightInches = smoothedHeight * 39.3701
            self?.confidence = overallConf
        }
    }

    /// Mark that the athlete has landed, finalizing the current jump.
    func markLanding() {
        guard isAirborne, let start = airtimeStart else { return }

        let now = Date().timeIntervalSince1970
        detectedAirtimeSeconds = now - start
        isAirborne = false
        airtimeStart = nil
    }

    /// Manually set airtime for gravity correction.
    func setAirtime(seconds: Double) {
        detectedAirtimeSeconds = seconds
    }

    // MARK: - Private Helpers

    private func computeDisplacementConfidence(_ displacement: Double) -> Double {
        if displacement < minimumJumpThresholdM { return 0.1 }

        let elements = displacementHistory.elements
        guard elements.count >= 3 else { return 0.3 }

        let avg = elements.reduce(0, +) / Double(elements.count)
        let variance = elements.reduce(0) { $0 + pow($1 - avg, 2) } / Double(elements.count)
        let normalizedVar = min(variance / 0.01, 1.0)

        // High consistency = high confidence
        let consistency = 1.0 - normalizedVar

        // Baseline lock bonus
        let baselineBonus = isBaselineLocked ? 0.3 : 0.0

        return min(1.0, consistency * 0.6 + baselineBonus + 0.1)
    }

    /// Get the current peak jump height (since last reset).
    var peakJumpHeightMeters: Double {
        max(0, peakDisplacementPixels)
    }

    /// Reset all internal state for a new session.
    func reset() {
        pelvisBaselineY = nil
        peakDisplacementPixels = 0.0
        displacementHistory.clear()
        jumpHeightHistory.clear()
        kalmanFilter.reset()
        baselineFrameCount = 0
        isBaselineLocked = false
        detectedAirtimeSeconds = 0.0
        airtimeStart = nil
        isAirborne = false
        jumpHeightMeters = 0.0
        jumpHeightInches = 0.0
        confidence = 0.0
    }
}