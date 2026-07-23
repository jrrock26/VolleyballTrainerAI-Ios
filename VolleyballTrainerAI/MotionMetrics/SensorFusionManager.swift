import Foundation
import CoreMotion

// MARK: - Sensor Fusion Manager

/// Fuses pose-model data with device accelerometer/gyroscope readings
/// to produce more accurate motion metrics through complementary filtering.
final class SensorFusionManager: ObservableObject {

    // MARK: - Sensor Data Types

    /// Represents a fused measurement combining vision and IMU data.
    struct FusedReading {
        let timestamp: TimeInterval
        let verticalAcceleration: Double  // m/s²
        let rotationRate: CGPoint        // rad/s (x=pitch, y=roll, z=yaw)
        let poseVerticalDisplacement: Double?  // meters from pose model
        let poseConfidence: Double       // 0–1
    }

    // MARK: - Motion Manager

    private let motionManager = CMMotionManager()
    private var accelBuffer: RingBuffer<Double> = RingBuffer(capacity: 10)
    private var gyroBuffer: RingBuffer<CGPoint> = RingBuffer(capacity: 10)
    private var poseDisplacementBuffer: RingBuffer<Double> = RingBuffer(capacity: 10)

    @Published private(set) var isActive: Bool = false
    @Published private(set) var fusedJumpVelocity: Double = 0.0
    @Published private(set) var fusedOrientationDelta: CGPoint = .zero

    // Complementary filter weights (vision + IMU)
    var visionWeight: Double = 0.7
    var imuWeight: Double = 0.3

    private var sensorUpdateInterval: TimeInterval = 1.0 / 60.0  // 60 Hz

    // MARK: - Init

    init() {
        // Sensor readiness check
    }

    // MARK: - Start / Stop

    func startSensors() {
        guard motionManager.isDeviceMotionAvailable else {
            print("[SensorFusionManager] Device motion not available")
            return
        }

        motionManager.deviceMotionUpdateInterval = sensorUpdateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            self.processMotionUpdate(motion)
        }

        isActive = true
    }

    func stopSensors() {
        motionManager.stopDeviceMotionUpdates()
        isActive = false
    }

    // MARK: - Motion Processing

    private func processMotionUpdate(_ motion: CMDeviceMotion) {
        let timestamp = Date().timeIntervalSince1970

        // Extract vertical acceleration in world frame (gravity removed)
        let userAccel = motion.userAcceleration
        let gravity = motion.gravity

        // Vertical component: dot product of user acceleration with gravity direction
        let gravNorm = sqrt(gravity.x * gravity.x + gravity.y * gravity.y + gravity.z * gravity.z)
        guard gravNorm > 0.01 else { return }

        let gravDirX = gravity.x / gravNorm
        let gravDirY = gravity.y / gravNorm
        let gravDirZ = gravity.z / gravNorm

        let verticalAccel = userAccel.x * gravDirX + userAccel.y * gravDirY + userAccel.z * gravDirZ

        // Rotation rate
        let rotation = CGPoint(
            x: motion.rotationRate.x,  // pitch rate
            y: motion.rotationRate.y   // roll rate
        )

        accelBuffer.push(verticalAccel)
        gyroBuffer.push(rotation)
    }

    // MARK: - Fusion Methods

    /// Fuse pose-model vertical displacement with accelerometer data
    /// to compute a refined vertical velocity and jump height.
    /// Uses complementary filtering: low-pass on accelerometer, high-pass on pose.
    func fuseVerticalMotion(
        poseDisplacementMeters: Double?,
        poseConfidence: Double,
        dt: TimeInterval
    ) -> (velocity: Double, displacement: Double) {

        // Get smoothed accelerometer reading
        let accelElements = accelBuffer.elements
        let smoothedAccel: Double
        if !accelElements.isEmpty {
            smoothedAccel = SmoothingUtils.robustMovingAverage(accelElements, window: 5)
        } else {
            smoothedAccel = 0
        }

        // Integrate acceleration to get velocity (IMU path)
        fusedJumpVelocity += smoothedAccel * dt

        // If pose data is available, blend IMU velocity with pose-derived velocity
        var poseVelocity: Double = 0
        if let displacement = poseDisplacementMeters {
            poseDisplacementBuffer.push(displacement)
            let dispElements = poseDisplacementBuffer.elements
            if dispElements.count >= 2 {
                let first = dispElements.first!
                let last = dispElements.last!
                let totalDt = dt * Double(dispElements.count)
                if totalDt > 0.001 {
                    poseVelocity = (last - first) / totalDt
                }
            }
        }

        // Complementary filter blend
        let alpha = visionWeight * poseConfidence
        let beta = imuWeight

        let blendedVelocity: Double
        if poseDisplacementMeters != nil && poseConfidence > 0.3 {
            blendedVelocity = alpha * poseVelocity + beta * fusedJumpVelocity
        } else {
            blendedVelocity = fusedJumpVelocity
        }

        // Integrate blended velocity for displacement
        fusedJumpVelocity = blendedVelocity
        let integratedDisp = fusedJumpVelocity * dt

        return (velocity: blendedVelocity, displacement: integratedDisp)
    }

    /// Fuse gyroscope rotation with pose-model joint angles to correct orientation.
    func fuseOrientation(
        poseBodyAngleDegrees: Double?,
        poseConfidence: Double,
        dt: TimeInterval
    ) -> Double {
        // Integrate gyro for cumulative rotation
        let gyroElements = gyroBuffer.elements
        let avgGyro: CGPoint
        if !gyroElements.isEmpty {
            let sumX = gyroElements.reduce(0) { $0 + $1.x }
            let sumY = gyroElements.reduce(0) { $0 + $1.y }
            avgGyro = CGPoint(x: sumX / Double(gyroElements.count), y: sumY / Double(gyroElements.count))
        } else {
            avgGyro = .zero
        }

        // Use primarily the z-axis (yaw) rotation for body orientation
        fusedOrientationDelta.x += avgGyro.x * dt
        fusedOrientationDelta.y += avgGyro.y * dt

        // Blend with pose if available
        if let poseAngle = poseBodyAngleDegrees, poseConfidence > 0.3 {
            let gyroAngleDeg = fusedOrientationDelta.y * 180.0 / .pi
            let alpha = visionWeight * poseConfidence
            let fused = alpha * poseAngle + (1 - alpha) * gyroAngleDeg
            fusedOrientationDelta.y = fused * .pi / 180.0
        }

        return Double(fusedOrientationDelta.y) * 180.0 / .pi
    }

    /// Get the peak vertical velocity observed in the recent window.
    func peakVerticalVelocity() -> Double {
        return abs(fusedJumpVelocity)
    }

    /// Compute airtime from accelerometer: detect takeoff and landing events.
    /// Returns estimated airtime in seconds.
    func detectAirtimeFromAccel() -> Double? {
        let accelValues = accelBuffer.elements
        guard accelValues.count >= 6 else { return nil }

        // Look for free-fall signature: acceleration magnitude near 0 for >3 frames
        var consecutiveFreefall = 0
        var airtimeStart: TimeInterval?
        var airtimeEnd: TimeInterval?

        for (i, accel) in accelValues.enumerated() {
            if abs(accel) < 1.5 {
                consecutiveFreefall += 1
                if consecutiveFreefall == 3 {
                    airtimeStart = 0  // relative; we just need the count
                }
            } else {
                if consecutiveFreefall >= 3, airtimeStart != nil {
                    airtimeEnd = 0
                    break
                }
                consecutiveFreefall = 0
            }
        }

        guard airtimeStart != nil, airtimeEnd != nil else { return nil }

        // Estimate based on frame count * interval
        let frameCount = consecutiveFreefall
        return Double(frameCount) * sensorUpdateInterval
    }

    /// Reset all internal buffers and state.
    func reset() {
        accelBuffer.clear()
        gyroBuffer.clear()
        poseDisplacementBuffer.clear()
        fusedJumpVelocity = 0.0
        fusedOrientationDelta = .zero
    }
}