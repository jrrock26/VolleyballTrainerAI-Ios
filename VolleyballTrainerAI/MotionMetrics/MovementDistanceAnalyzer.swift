import Foundation
import CoreGraphics

// MARK: - Movement Distance Analyzer

/// Tracks center-of-mass movement instead of feet, applies
/// gyroscope‑based orientation correction, converts pixel
/// movement to meters using calibration, and smooths paths
/// with Kalman filtering.
final class MovementDistanceAnalyzer: ObservableObject {

    // MARK: - Published Output

    /// Total accumulated movement distance in meters since last reset.
    @Published private(set) var totalDistanceMeters: Double = 0.0

    /// Current instantaneous speed in meters per second.
    @Published private(set) var currentSpeedMPS: Double = 0.0

    /// Smoothed center-of-mass position.
    @Published private(set) var smoothedPosition: CGPoint = .zero

    /// Confidence in the movement tracking (0–1).
    @Published private(set) var confidence: Double = 0.0

    // MARK: - Configuration

    private let calibration: CalibrationManager
    private let sensorFusion: SensorFusionManager

    // MARK: - Internal State

    /// Kalman filter for 2D center-of-mass position.
    private var positionFilter: KalmanFilter2D

    /// Ring buffer for COM positions with timestamps.
    struct COMPosition {
        let position: CGPoint   // pixel coordinates
        let timestamp: TimeInterval
        let hipCenter: CGPoint  // midpoint of hips (unfiltered)
        let shoulderCenter: CGPoint // midpoint of shoulders (unfiltered)
    }

    private var positionBuffer: RingBuffer<COMPosition>

    /// Accumulated distance.
    private var accumulatedDistance: Double = 0.0

    /// Last processed position (pixels) for incremental distance.
    private var lastProcessedPosition: CGPoint?

    /// History for speed smoothing.
    private var speedHistory: RingBuffer<Double> = RingBuffer(capacity: 8)

    /// Orientation correction state.
    private var orientationAngleRadians: Double = 0.0

    // MARK: - COM Computation

    /// Weights for center-of-mass approximation from pose joints.
    /// Based on standard anthropometric segment weights.
    private let comWeights: [Double] = [
        0.50,  // hips midpoint
        0.25,  // shoulders midpoint
        0.15,  // neck / head
        0.10,  // knees midpoint (lower body stabilization)
    ]

    // MARK: - Init

    init(calibration: CalibrationManager, sensorFusion: SensorFusionManager) {
        self.calibration = calibration
        self.sensorFusion = sensorFusion

        self.positionFilter = KalmanFilter2D(
            initialPosition: .zero,
            initialVelocity: .zero,
            processNoise: 0.03,
            measurementNoise: 0.4
        )

        self.positionBuffer = RingBuffer(capacity: 15)
    }

    // MARK: - Frame Processing

    /// Process a new frame with pose joint positions.
    /// - Parameters:
    ///   - hipLeft: Left hip pixel position.
    ///   - hipRight: Right hip pixel position.
    ///   - shoulderLeft: Left shoulder pixel position.
    ///   - shoulderRight: Right shoulder pixel position.
    ///   - neck: Neck pixel position (optional).
    ///   - kneeLeft: Left knee pixel position (optional).
    ///   - kneeRight: Right knee pixel position (optional).
    ///   - timestamp: Frame timestamp.
    func processFrame(
        hipLeft: CGPoint?,
        hipRight: CGPoint?,
        shoulderLeft: CGPoint?,
        shoulderRight: CGPoint?,
        neck: CGPoint? = nil,
        kneeLeft: CGPoint? = nil,
        kneeRight: CGPoint? = nil,
        timestamp: TimeInterval
    ) {
        // Step 1: Compute center-of-mass
        guard let com = computeCenterOfMass(
            hipLeft: hipLeft,
            hipRight: hipRight,
            shoulderLeft: shoulderLeft,
            shoulderRight: shoulderRight,
            neck: neck,
            kneeLeft: kneeLeft,
            kneeRight: kneeRight
        ) else {
            confidence = 0.0
            return
        }

        // Step 2: Gyroscope-based orientation correction
        let correctedPosition = applyOrientationCorrection(com)

        // Step 3: Kalman filter the position
        let filteredPosition = positionFilter.filter(
            measurement: correctedPosition,
            dt: 1.0 / 30.0
        )

        // Step 4: Compute incremental distance
        if let lastPos = lastProcessedPosition {
            let pixelDx = filteredPosition.x - lastPos.x
            let pixelDy = filteredPosition.y - lastPos.y
            let pixelDist = sqrt(pixelDx * pixelDx + pixelDy * pixelDy)

            let meterDist = calibration.pixelsToMeters(pixelDist)

            // Avoid accumulating unreasonable jumps
            if meterDist < 2.0 {
                accumulatedDistance += meterDist

                // Compute instantaneous speed
                let dt = max(1.0 / 60.0, 1.0 / 30.0) // fallback 30fps if no timestamp diff
                let speed = meterDist / dt
                speedHistory.push(speed)

                let smoothedSpeed = SmoothingUtils.robustMovingAverage(
                    Array(speedHistory.elements),
                    window: 5
                )

                currentSpeedMPS = max(0, min(smoothedSpeed, 12.0))
            }
        }

        lastProcessedPosition = filteredPosition

        // Step 5: Fuse gyroscope orientation for additional correction
        let fusedOrientation = sensorFusion.fuseOrientation(
            poseBodyAngleDegrees: nil,
            poseConfidence: 0.5,
            dt: 1.0 / 30.0
        )
        orientationAngleRadians = fusedOrientation * .pi / 180.0

        // Step 6: Store in buffer
        let comEntry = COMPosition(
            position: filteredPosition,
            timestamp: timestamp,
            hipCenter: midpoint(hipLeft, hipRight) ?? .zero,
            shoulderCenter: midpoint(shoulderLeft, shoulderRight) ?? .zero
        )
        positionBuffer.push(comEntry)

        // Step 7: Confidence estimation
        let jointCount = [hipLeft, hipRight, shoulderLeft, shoulderRight]
            .compactMap { $0 }
            .count
        let jointCoverage = Double(jointCount) / 4.0

        let speedVariance: Double
        let speeds = speedHistory.elements
        if speeds.count >= 2 {
            let avgSpeed = speeds.reduce(0, +) / Double(speeds.count)
            speedVariance = speeds.reduce(0) { $0 + pow($1 - avgSpeed, 2) } / Double(speeds.count)
        } else {
            speedVariance = 0
        }
        let consistencyScore = exp(-speedVariance / 0.5)

        DispatchQueue.main.async { [weak self] in
            self?.totalDistanceMeters = self?.accumulatedDistance ?? 0
            self?.smoothedPosition = filteredPosition
            self?.confidence = jointCoverage * 0.6 + consistencyScore * 0.4
        }
    }

    // MARK: - COM Computation

    /// Compute weighted center-of-mass position from available pose joints.
    private func computeCenterOfMass(
        hipLeft: CGPoint?,
        hipRight: CGPoint?,
        shoulderLeft: CGPoint?,
        shoulderRight: CGPoint?,
        neck: CGPoint?,
        kneeLeft: CGPoint?,
        kneeRight: CGPoint?
    ) -> CGPoint? {
        var weightedX: Double = 0
        var weightedY: Double = 0
        var totalWeight: Double = 0

        // Hip center (weight 0.50)
        if let hl = hipLeft, let hr = hipRight {
            let hipCenter = CGPoint(x: (hl.x + hr.x) / 2, y: (hl.y + hr.y) / 2)
            weightedX += Double(hipCenter.x) * comWeights[0]
            weightedY += Double(hipCenter.y) * comWeights[0]
            totalWeight += comWeights[0]
        }

        // Shoulder center (weight 0.25)
        if let sl = shoulderLeft, let sr = shoulderRight {
            let shCenter = CGPoint(x: (sl.x + sr.x) / 2, y: (sl.y + sr.y) / 2)
            weightedX += Double(shCenter.x) * comWeights[1]
            weightedY += Double(shCenter.y) * comWeights[1]
            totalWeight += comWeights[1]
        }

        // Neck (weight 0.15)
        if let n = neck {
            weightedX += Double(n.x) * comWeights[2]
            weightedY += Double(n.y) * comWeights[2]
            totalWeight += comWeights[2]
        }

        // Knee center (weight 0.10)
        if let kl = kneeLeft, let kr = kneeRight {
            let kneeCenter = CGPoint(x: (kl.x + kr.x) / 2, y: (kl.y + kr.y) / 2)
            weightedX += Double(kneeCenter.x) * comWeights[3]
            weightedY += Double(kneeCenter.y) * comWeights[3]
            totalWeight += comWeights[3]
        }

        guard totalWeight > 0 else { return nil }

        // Normalize by the sum of applied weights
        return CGPoint(
            x: weightedX / totalWeight,
            y: weightedY / totalWeight
        )
    }

    // MARK: - Orientation Correction

    /// Apply gyroscope-based orientation correction to the COM position.
    /// Rotates the movement vector to correct for device/camera tilt.
    private func applyOrientationCorrection(_ position: CGPoint) -> CGPoint {
        guard abs(orientationAngleRadians) > 0.001 else { return position }

        let cosAngle = cos(-orientationAngleRadians)
        let sinAngle = sin(-orientationAngleRadians)

        return CGPoint(
            x: position.x * cosAngle - position.y * sinAngle,
            y: position.x * sinAngle + position.y * cosAngle
        )
    }

    // MARK: - Helpers

    private func midpoint(_ a: CGPoint?, _ b: CGPoint?) -> CGPoint? {
        guard let a = a, let b = b else { return nil }
        return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    // MARK: - Path Smoothing

    /// Return the smoothed movement path as an array of positions in meters.
    func smoothedPathMeters() -> [CGPoint] {
        return positionBuffer.elements.map { entry in
            let metersX = calibration.pixelsToMeters(entry.position.x)
            let metersY = calibration.pixelsToMeters(entry.position.y)
            return CGPoint(x: metersX, y: metersY)
        }
    }

    /// Get the total covered court area (bounding box of movement) in square meters.
    func movementAreaMetersSquared() -> Double {
        let path = smoothedPathMeters()
        guard path.count >= 2 else { return 0 }

        let minX = path.map(\.x).min() ?? 0
        let maxX = path.map(\.x).max() ?? 0
        let minY = path.map(\.y).min() ?? 0
        let maxY = path.map(\.y).max() ?? 0

        return (maxX - minX) * (maxY - minY)
    }

    /// Reset all accumulated state.
    func reset() {
        accumulatedDistance = 0.0
        currentSpeedMPS = 0.0
        positionFilter.reset()
        positionBuffer.clear()
        speedHistory.clear()
        lastProcessedPosition = nil
        orientationAngleRadians = 0.0
        totalDistanceMeters = 0.0
        smoothedPosition = .zero
        confidence = 0.0
    }
}