import Foundation
import CoreGraphics
import Vision
import AVFoundation
import Combine

// MARK: - Motion Metrics Engine (Integration Coordinator)

/// Central coordinator that integrates all motion‑metric modules
/// and bridges them into the existing PoseTracker → LiveAIView → VolleyballHit pipeline.
///
/// Usage alongside PoseTracker:
/// ```
/// let metricsEngine = MotionMetricsEngine()
/// metricsEngine.attach(to: poseTracker)
/// // In LiveAIView, bind to metricsEngine.ballSpeedMPH, .jumpHeightInches, etc.
/// ```
final class MotionMetricsEngine: ObservableObject {

    // MARK: - Sub-Modules

    let calibration = CalibrationManager()
    let sensorFusion = SensorFusionManager()
    lazy var ballSpeedTracker = BallSpeedTracker(calibration: calibration)
    lazy var jumpHeightAnalyzer = JumpHeightAnalyzer(calibration: calibration, sensorFusion: sensorFusion)
    lazy var movementAnalyzer = MovementDistanceAnalyzer(calibration: calibration, sensorFusion: sensorFusion)
    lazy var spikeSpeedAnalyzer = SpikeSpeedAnalyzer(calibration: calibration)
    lazy var serveSpeedAnalyzer = ServeSpeedAnalyzer(calibration: calibration)
    lazy var trajectoryPredictor = TrajectoryPredictor(calibration: calibration)

    // MARK: - Published Enhanced Metrics

    /// Ball speed (MPH) — enhanced via multi-frame Kalman + motion-blur correction.
    @Published var ballSpeedMPH: Double = 0.0

    /// Ball speed confidence (0–1).
    @Published var ballSpeedConfidence: Double = 0.0

    /// Jump height (inches) — fused pose + gravity + accelerometer.
    @Published var jumpHeightInches: Double = 0.0

    /// Jump height confidence (0–1).
    @Published var jumpHeightConfidence: Double = 0.0

    /// Spike speed (MPH) — hand velocity + ball velocity fusion.
    @Published var spikeSpeedMPH: Double = 0.0

    /// Spike speed confidence (0–1).
    @Published var spikeSpeedConfidence: Double = 0.0

    /// Serve speed (MPH) — 7‑frame post-contact window.
    @Published var serveSpeedMPH: Double = 0.0

    /// Serve speed confidence (0–1).
    @Published var serveSpeedConfidence: Double = 0.0

    /// Total movement distance (meters) — COM‑based with gyro correction.
    @Published var movementDistanceMeters: Double = 0.0

    /// Movement distance confidence (0–1).
    @Published var movementConfidence: Double = 0.0

    /// Launch angle (degrees) — from trajectory predictor.
    @Published var launchAngleDegrees: Double = 0.0

    /// Flight distance (feet).
    @Published var flightDistanceFeet: Double = 0.0

    /// Predicted landing zone (court‑normalized 0–1).
    @Published var predictedLandingZone: CGPoint = .zero

    /// Trajectory fit quality R² (0–1).
    @Published var trajectoryFitQuality: Double = 0.0

    /// Whether calibration is locked in.
    @Published var isCalibrated: Bool = false

    /// Overall session metrics summary for UI display.
    @Published var sessionSummary: String = ""

    // MARK: - Internal State

    private var lastFrameTimestamp: TimeInterval?
    private var frameCount: Int = 0

    /// Whether the engine is actively processing frames.
    private(set) var isActive: Bool = false

    /// The attached PoseTracker (weak to avoid retain cycle).
    private weak var poseTracker: PoseTracker?

    /// Pose joint cache for COM computation.
    private var cachedHipLeft: CGPoint?
    private var cachedHipRight: CGPoint?
    private var cachedShoulderLeft: CGPoint?
    private var cachedShoulderRight: CGPoint?
    private var cachedNeck: CGPoint?
    private var cachedKneeLeft: CGPoint?
    private var cachedKneeRight: CGPoint?
    private var cachedPelvisY: Double?

    // MARK: - Init

    private var cancellables = Set<AnyCancellable>()

    init() {
        observeCalibration()
    }

    private func observeCalibration() {
        calibration.$isCalibrated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isCalibrated = value
            }
            .store(in: &cancellables)
    }

    // MARK: - Attach to PoseTracker

    /// Wire the engine into an existing PoseTracker.
    /// Call this in LiveAIView.onAppear.
    func attach(to tracker: PoseTracker) {
        self.poseTracker = tracker

        // Start sensor fusion
        sensorFusion.startSensors()
        isActive = true

        // Hook into PoseTracker's hit extraction callback to capture enhanced metrics
        let originalCallback = tracker.onSingleHitExtracted
        tracker.onSingleHitExtracted = { [weak self] jump, arm, speed, launch, distance, contactHeight, handSpeed, hipSep in
            // Forward to original handler
            originalCallback?(jump, arm, speed, launch, distance, contactHeight, handSpeed, hipSep)

            // Enhance with our metrics
            self?.finalizeHitMetrics()
        }
    }

    /// Detach and stop sensor fusion.
    func detach() {
        sensorFusion.stopSensors()
        isActive = false
        poseTracker = nil
    }

    // MARK: - Frame Processing (call from PoseTracker.processRawPixelBuffer)

    /// Process a frame with raw pixel buffer and Vision pose observation.
    /// Should be called from PoseTracker.analyzePlayerPose after joint extraction.
    func processFrame(
        poseObservation: VNHumanBodyPoseObservation,
        pixelBuffer: CVPixelBuffer,
        timestamp: TimeInterval,
        ballPixelPosition: CGPoint?,
        ballBoundingBox: CGRect?,
        wristPixelPosition: CGPoint? = nil
    ) {
        guard isActive else { return }

        let dt: TimeInterval
        if let last = lastFrameTimestamp {
            dt = max(timestamp - last, 0.001)
        } else {
            dt = 1.0 / 30.0
        }
        lastFrameTimestamp = timestamp
        frameCount += 1

        let confidenceThreshold: Float = 0.2

        // Extract pose joints
        extractPoseJoints(from: poseObservation, threshold: confidenceThreshold)

        // --- Ball Speed (enhanced) ---
        if let ballPos = ballPixelPosition, let ballBox = ballBoundingBox {
            ballSpeedTracker.processFrame(
                position: ballPos,
                timestamp: timestamp,
                boundingBox: ballBox
            )
        }

        // --- Jump Height ---
        if let pelvisY = cachedPelvisY {
            jumpHeightAnalyzer.processFrame(
                pelvisY: pelvisY,
                timestamp: timestamp
            )
        }

        // --- Movement Distance ---
        movementAnalyzer.processFrame(
            hipLeft: cachedHipLeft,
            hipRight: cachedHipRight,
            shoulderLeft: cachedShoulderLeft,
            shoulderRight: cachedShoulderRight,
            neck: cachedNeck,
            kneeLeft: cachedKneeLeft,
            kneeRight: cachedKneeRight,
            timestamp: timestamp
        )

        // --- Spike Speed (hand velocity tracking every frame) ---
        if let wristPos = wristPixelPosition {
            spikeSpeedAnalyzer.processHandFrame(
                wristPosition: wristPos,
                timestamp: timestamp
            )
        }

        // --- Serve Speed (ball tracking every frame, gated by serveDetected) ---
        if let ballPos = ballPixelPosition, let ballBox = ballBoundingBox {
            serveSpeedAnalyzer.processBallFrame(
                position: ballPos,
                timestamp: timestamp,
                boundingBox: ballBox
            )
        }

        // --- Trajectory Prediction ---
        if let ballPos = ballPixelPosition {
            trajectoryPredictor.processFrame(
                pixelPosition: ballPos,
                timestamp: timestamp
            )
        }

        // --- Publish enhanced metrics ---
        publishEnhancedMetrics()
    }

    // MARK: - Pose Joint Extraction

    private func extractPoseJoints(
        from observation: VNHumanBodyPoseObservation,
        threshold: Float
    ) {
        func point(_ joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
            guard let pt = try? observation.recognizedPoint(joint),
                  pt.confidence > threshold else { return nil }
            return pt.location
        }

        cachedHipLeft = point(.leftHip)
        cachedHipRight = point(.rightHip)
        cachedShoulderLeft = point(.leftShoulder)
        cachedShoulderRight = point(.rightShoulder)
        cachedNeck = point(.neck)
        cachedKneeLeft = point(.leftKnee)
        cachedKneeRight = point(.rightKnee)

        // Compute pelvis Y (average of left and right hip)
        if let hl = cachedHipLeft, let hr = cachedHipRight {
            cachedPelvisY = Double((hl.y + hr.y) / 2.0)
        }
    }

    // MARK: - Publish Enhanced Metrics

    private func publishEnhancedMetrics() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Ball speed
            self.ballSpeedMPH = self.ballSpeedTracker.speedMPH
            self.ballSpeedConfidence = self.ballSpeedTracker.confidence

            // Jump height
            self.jumpHeightInches = self.jumpHeightAnalyzer.jumpHeightInches
            self.jumpHeightConfidence = self.jumpHeightAnalyzer.confidence

            // Spike speed
            self.spikeSpeedMPH = self.spikeSpeedAnalyzer.spikeSpeedMPH
            self.spikeSpeedConfidence = self.spikeSpeedAnalyzer.confidence

            // Serve speed
            self.serveSpeedMPH = self.serveSpeedAnalyzer.serveSpeedMPH
            self.serveSpeedConfidence = self.serveSpeedAnalyzer.confidence

            // Movement
            self.movementDistanceMeters = self.movementAnalyzer.totalDistanceMeters
            self.movementConfidence = self.movementAnalyzer.confidence

            // Trajectory
            self.launchAngleDegrees = self.serveSpeedAnalyzer.launchAngleDegrees
            self.predictedLandingZone = self.trajectoryPredictor.predictedLandingZone
            self.trajectoryFitQuality = self.trajectoryPredictor.fitQuality
        }
    }

    // MARK: - Finalize Hit Metrics

    /// Called when PoseTracker captures a hit. Uses enhanced metrics
    /// if available, falling back to PoseTracker's values.
    private func finalizeHitMetrics() {
        // Flight distance from trajectory prediction (if high‑confidence)
        if trajectoryPredictor.hasPrediction && trajectoryPredictor.confidence > 0.5 {
            let landingMeters = trajectoryPredictor.predictedLandingMeters
            let distanceFeet = landingMeters.x * 3.28084  // meters → feet
            if distanceFeet > 0 {
                flightDistanceFeet = distanceFeet
            }
        }

        // Build session summary
        updateSessionSummary()
    }

    private func updateSessionSummary() {
        let mpsToMPH = 2.23694

        var lines: [String] = []
        lines.append("📊 Enhanced Motion Metrics")
        if ballSpeedMPH > 0 {
            lines.append("Ball Speed: \(String(format: "%.1f", ballSpeedMPH)) mph (conf: \(Int(ballSpeedConfidence * 100))%)")
        }
        if jumpHeightInches > 0 {
            lines.append("Jump Height: \(String(format: "%.1f", jumpHeightInches)) in (conf: \(Int(jumpHeightConfidence * 100))%)")
        }
        if spikeSpeedMPH > 0 {
            lines.append("Spike Speed: \(String(format: "%.1f", spikeSpeedMPH)) mph")
        }
        if serveSpeedMPH > 0 {
            lines.append("Serve Speed: \(String(format: "%.1f", serveSpeedMPH)) mph")
        }
        if movementDistanceMeters > 0 {
            lines.append("Movement: \(String(format: "%.1f", movementDistanceMeters)) m")
        }
        if trajectoryPredictor.hasPrediction {
            let zone = trajectoryPredictor.landingZoneLabel()
            lines.append("Landing: \(zone) (R²: \(String(format: "%.2f", trajectoryFitQuality)))")
        }
        lines.append("Calibration: \(isCalibrated ? "✓ Locked" : "⚠ Uncalibrated")")

        sessionSummary = lines.joined(separator: "\n")
    }

    // MARK: - Calibration Helpers

    /// Calibrate using the athlete's known height from their profile.
    func calibrateWithAthlete(heightInches: Double, observedSegmentPixels: Double, observedSegmentNorm: Double) {
        _ = calibration.calibrateFromAthlete(
            athleteHeightInches: heightInches,
            observedSegmentPixels: observedSegmentPixels,
            observedSegmentNorm: observedSegmentNorm
        )
    }

    /// Calibrate using a reference object at known distance.
    func calibrateWithReference(objectSizeMeters: Double, objectSizePixels: Double, distanceMeters: Double) {
        calibration.calibrate(
            referenceObjectSizeMeters: objectSizeMeters,
            referenceObjectSizePixels: objectSizePixels,
            knownDistanceMeters: distanceMeters
        )
    }

    // MARK: - Marker Methods

    /// Mark a spike contact event (called from PoseTracker when wrist direction changes).
    func markSpikeContact(timestamp: TimeInterval, handPosition: CGPoint) {
        spikeSpeedAnalyzer.markContact(timestamp: timestamp, handPosition: handPosition)
    }

    /// Mark a serve contact event.
    func markServeContact(timestamp: TimeInterval, ballPosition: CGPoint, boundingBox: CGRect = .zero) {
        serveSpeedAnalyzer.markServeContact(
            timestamp: timestamp,
            ballPosition: ballPosition,
            boundingBox: boundingBox
        )
    }

    /// Mark athlete landing for jump height finalization.
    func markJumpLanding() {
        jumpHeightAnalyzer.markLanding()
    }

    // MARK: - Reset

    /// Reset all modules between hits or sessions.
    func resetAll() {
        ballSpeedTracker.reset()
        jumpHeightAnalyzer.reset()
        movementAnalyzer.reset()
        spikeSpeedAnalyzer.reset()
        serveSpeedAnalyzer.reset()
        trajectoryPredictor.reset()
        sensorFusion.reset()

        ballSpeedMPH = 0.0
        ballSpeedConfidence = 0.0
        jumpHeightInches = 0.0
        jumpHeightConfidence = 0.0
        spikeSpeedMPH = 0.0
        spikeSpeedConfidence = 0.0
        serveSpeedMPH = 0.0
        serveSpeedConfidence = 0.0
        movementDistanceMeters = 0.0
        movementConfidence = 0.0
        launchAngleDegrees = 0.0
        flightDistanceFeet = 0.0
        predictedLandingZone = .zero
        trajectoryFitQuality = 0.0
        sessionSummary = ""

        frameCount = 0
        lastFrameTimestamp = nil
    }

    /// Reset per‑hit state (called between individual hit recordings).
    func resetForNextHit() {
        ballSpeedTracker.reset()
        spikeSpeedAnalyzer.reset()
        serveSpeedAnalyzer.reset()
        trajectoryPredictor.reset()
        jumpHeightAnalyzer.reset()
        // Movement accumulates across the session, so don't reset it here.
    }
}