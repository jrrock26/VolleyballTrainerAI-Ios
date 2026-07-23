import Foundation
import CoreGraphics

// MARK: - Calibration Manager

/// Manages pixel-to-meter calibration for the volleyball motion-metrics system.
/// Supports per-device calibration using a known reference distance.
final class CalibrationManager: ObservableObject {

    // MARK: - Calibration Data

    /// Store calibration values keyed by device identifier.
    private struct CalibrationData: Codable {
        var pixelsPerMeter: Double
        var calibrationDate: Date
        var referenceDistanceMeters: Double
        var cameraFocalLength: Double?
    }

    private var deviceCalibrations: [String: CalibrationData] = [:]

    /// The current device's calibration value (pixels per meter).
    @Published private(set) var pixelsPerMeter: Double = 1000.0

    /// Whether the device has been calibrated.
    @Published private(set) var isCalibrated: Bool = false

    /// Confidence of the current calibration (0–1).
    @Published private(set) var calibrationConfidence: Double = 0.0

    /// The last calibration date.
    @Published private(set) var lastCalibrationDate: Date?

    // MARK: - Storage

    private let defaultsKey = "com.volleyballtrainerai.calibration"
    private let currentDeviceID: String

    // MARK: - Init

    init() {
        // Use a device-identifier from the environment,
        // falling back to a generated UUID stored in defaults.
        let suiteID = "com.volleyballtrainerai.calibration"
        let defaults = UserDefaults(suiteName: suiteID) ?? .standard
        let deviceIDKey = "calibration_device_identifier"
        if let existing = defaults.string(forKey: deviceIDKey) {
            self.currentDeviceID = existing
        } else {
            let newID = UUID().uuidString
            defaults.set(newID, forKey: deviceIDKey)
            self.currentDeviceID = newID
        }
        loadCalibrations()
    }

    // MARK: - Public API

    /// Begin calibration: user places the phone at a known distance from a reference object.
    /// The system measures the reference object's apparent size in pixels and computes scale.
    /// - Parameters:
    ///   - referenceObjectSizeMeters: Known physical size of the reference object (e.g., a volleyball = 0.21 m diameter).
    ///   - referenceObjectSizePixels: Observed pixel width/height of the reference object in the camera frame.
    ///   - knownDistanceMeters: The measured distance from the camera to the reference object plane.
    func calibrate(
        referenceObjectSizeMeters: Double,
        referenceObjectSizePixels: Double,
        knownDistanceMeters: Double
    ) {
        guard referenceObjectSizePixels > 0,
              knownDistanceMeters > 0,
              referenceObjectSizeMeters > 0 else {
            calibrationConfidence = 0.0
            return
        }

        // Compute pixels per meter using similar triangles:
        // pixelsPerMeter = (referencePixels / referenceSize) * knownDistance
        let objectScale = referenceObjectSizePixels / referenceObjectSizeMeters
        let computedPPM = objectScale * knownDistanceMeters

        // Clamp to physically plausible range (sanity check)
        let clampedPPM = max(100, min(computedPPM, 50000))

        let data = CalibrationData(
            pixelsPerMeter: clampedPPM,
            calibrationDate: Date(),
            referenceDistanceMeters: knownDistanceMeters,
            cameraFocalLength: nil
        )

        deviceCalibrations[currentDeviceID] = data
        pixelsPerMeter = clampedPPM
        isCalibrated = true
        calibrationConfidence = 0.9
        lastCalibrationDate = data.calibrationDate

        saveCalibrations()
    }

    /// Refine calibration iteratively using multiple measurements.
    /// Each observation is weighted by recency.
    func refineCalibration(
        measuredPixels: Double,
        knownDistanceMeters: Double,
        knownObjectSizeMeters: Double
    ) {
        guard measuredPixels > 0, knownDistanceMeters > 0, knownObjectSizeMeters > 0 else { return }

        let newPPM = (measuredPixels / knownObjectSizeMeters) * knownDistanceMeters
        let clampedNew = max(100, min(newPPM, 50000))

        // Exponential moving average blend with existing calibration
        if let existing = deviceCalibrations[currentDeviceID] {
            let alpha = 0.3
            let refined = alpha * clampedNew + (1 - alpha) * existing.pixelsPerMeter

            let data = CalibrationData(
                pixelsPerMeter: refined,
                calibrationDate: Date(),
                referenceDistanceMeters: knownDistanceMeters,
                cameraFocalLength: existing.cameraFocalLength
            )

            deviceCalibrations[currentDeviceID] = data
            pixelsPerMeter = refined
            calibrationConfidence = min(1.0, calibrationConfidence + 0.05)
            lastCalibrationDate = data.calibrationDate

            saveCalibrations()
        } else {
            calibrate(
                referenceObjectSizeMeters: knownObjectSizeMeters,
                referenceObjectSizePixels: measuredPixels,
                knownDistanceMeters: knownDistanceMeters
            )
        }
    }

    /// Compute pixels-per-meter from the athlete's known body proportions.
    /// Uses profile height and an observed full-body or torso pixel span.
    /// Returns a calibration scale (inches per normalized unit), like in PoseTracker.
    func calibrateFromAthlete(
        athleteHeightInches: Double,
        observedSegmentPixels: Double,
        observedSegmentNorm: Double
    ) -> Double? {
        guard athleteHeightInches > 0,
              observedSegmentPixels > 0,
              observedSegmentNorm > 0 else { return nil }

        // Convert to metric for internal consistency
        let heightMeters = athleteHeightInches * 0.0254

        // Pixels per meter = pixels / (norm * height)
        let ppm = observedSegmentPixels / (observedSegmentNorm * heightMeters)

        guard ppm > 50 && ppm < 60000 else { return nil }

        let data = CalibrationData(
            pixelsPerMeter: ppm,
            calibrationDate: Date(),
            referenceDistanceMeters: heightMeters,
            cameraFocalLength: nil
        )

        deviceCalibrations[currentDeviceID] = data
        pixelsPerMeter = ppm
        isCalibrated = true
        calibrationConfidence = 0.7
        lastCalibrationDate = data.calibrationDate

        saveCalibrations()
        return ppm
    }

    /// Convert a pixel distance to meters using the current calibration.
    func pixelsToMeters(_ pixels: Double) -> Double {
        guard pixelsPerMeter > 0 else { return 0 }
        return pixels / pixelsPerMeter
    }

    /// Convert a pixel position delta to meters.
    func pixelDeltaToMeters(_ dx: Double, _ dy: Double) -> (dxM: Double, dyM: Double) {
        guard pixelsPerMeter > 0 else { return (0, 0) }
        return (dx / pixelsPerMeter, dy / pixelsPerMeter)
    }

    /// Convert meters to pixels using the current calibration.
    func metersToPixels(_ meters: Double) -> Double {
        return meters * pixelsPerMeter
    }

    /// Reset calibration to default (uncalibrated).
    func reset() {
        deviceCalibrations.removeValue(forKey: currentDeviceID)
        pixelsPerMeter = 1000.0
        isCalibrated = false
        calibrationConfidence = 0.0
        lastCalibrationDate = nil
        saveCalibrations()
    }

    // MARK: - Persistence

    private func saveCalibrations() {
        let defaults = UserDefaults(suiteName: "com.volleyballtrainerai.calibration") ?? .standard
        if let encoded = try? JSONEncoder().encode(deviceCalibrations) {
            defaults.set(encoded, forKey: defaultsKey)
        }
    }

    private func loadCalibrations() {
        let defaults = UserDefaults(suiteName: "com.volleyballtrainerai.calibration") ?? .standard
        guard let data = defaults.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([String: CalibrationData].self, from: data) else {
            return
        }
        deviceCalibrations = decoded

        if let deviceData = deviceCalibrations[currentDeviceID] {
            pixelsPerMeter = deviceData.pixelsPerMeter
            isCalibrated = true
            calibrationConfidence = 0.8
            lastCalibrationDate = deviceData.calibrationDate
        }
    }

    /// Export calibration values so other modules can rely on a validated scale.
    var scaleFactor: Double {
        guard isCalibrated, pixelsPerMeter > 0 else {
            return 1.0 / 1000.0  // default fallback: meters per pixel
        }
        return 1.0 / pixelsPerMeter  // meters per pixel
    }
}