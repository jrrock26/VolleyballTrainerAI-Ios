import Foundation
import CoreGraphics

// MARK: - Trajectory Predictor

/// Fits a quadratic regression curve over 10–15 frames of ball
/// position data, predicts the landing zone using the fitted
/// trajectory, and normalizes coordinates to court dimensions.
final class TrajectoryPredictor: ObservableObject {

    // MARK: - Published Output

    /// Predicted landing position in court-normalized coordinates (0–1).
    @Published private(set) var predictedLandingZone: CGPoint = .zero

    /// Predicted landing position in meters relative to the net.
    @Published private(set) var predictedLandingMeters: CGPoint = .zero

    /// The coefficients [a, b, c] of the quadratic fit y = ax² + bx + c.
    @Published private(set) var trajectoryCoefficients: (a: Double, b: Double, c: Double)?

    /// R² goodness-of-fit for the quadratic regression (0–1).
    @Published private(set) var fitQuality: Double = 0.0

    /// Confidence in the trajectory prediction (0–1).
    @Published private(set) var confidence: Double = 0.0

    /// Whether enough data has been collected for a reliable prediction.
    @Published private(set) var hasPrediction: Bool = false

    /// Estimated time to landing in seconds.
    @Published private(set) var estimatedTimeToLanding: Double = 0.0

    // MARK: - Court Dimensions

    /// Standard volleyball court dimensions in meters.
    struct CourtDimensions {
        /// Total court length (18m).
        static let length: Double = 18.0
        /// Total court width (9m).
        static let width: Double = 9.0
        /// Distance from net to attack line (3m).
        static let attackLineDistance: Double = 3.0
        /// Distance from net to baseline (9m per side).
        static let halfCourtLength: Double = 9.0
        /// Net height in meters (men's standard: 2.43m, women's: 2.24m).
        static let netHeightMen: Double = 2.43
        static let netHeightWomen: Double = 2.24
    }

    // MARK: - Configuration

    /// Number of frames to use for trajectory fitting (10–15).
    let trajectoryFrameCount: Int = 12

    /// Minimum frames required before fitting.
    let minFramesForFit: Int = 6

    private let calibration: CalibrationManager

    // MARK: - Internal State

    /// Ball tracking frames with timestamps.
    struct TrajectoryFrame {
        let positionMeters: CGPoint  // calibrated meters
        let timestamp: TimeInterval
        let pixelPosition: CGPoint   // raw pixel coordinates
    }

    private var frameBuffer: RingBuffer<TrajectoryFrame>

    /// All collected points for the current trajectory.
    private var allTrajectoryPoints: [TrajectoryFrame] = []

    /// Pixels-per-meter for normalization.
    private var pixelsPerMeter: Double = 1000.0

    /// Court origin reference (net center at origin for calculations).
    private var courtOriginOffset: CGPoint = .zero

    // MARK: - Gravity constant

    private let gravityMPS2: Double = 9.81

    // MARK: - Init

    init(calibration: CalibrationManager) {
        self.calibration = calibration
        self.frameBuffer = RingBuffer(capacity: trajectoryFrameCount + 5)
    }

    // MARK: - Frame Processing

    /// Ingest a new ball position frame.
    /// - Parameters:
    ///   - pixelPosition: Ball center in pixel coordinates.
    ///   - timestamp: Capture timestamp.
    func processFrame(pixelPosition: CGPoint, timestamp: TimeInterval) {
        // Convert to meters
        let metersX = calibration.pixelsToMeters(pixelPosition.x)
        let metersY = calibration.pixelsToMeters(pixelPosition.y)

        let frame = TrajectoryFrame(
            positionMeters: CGPoint(x: metersX, y: metersY),
            timestamp: timestamp,
            pixelPosition: pixelPosition
        )

        frameBuffer.push(frame)
        allTrajectoryPoints.append(frame)

        // Trim old points beyond double the window
        if allTrajectoryPoints.count > trajectoryFrameCount * 3 {
            allTrajectoryPoints = Array(allTrajectoryPoints.suffix(trajectoryFrameCount * 2))
        }

        pixelsPerMeter = calibration.pixelsPerMeter

        guard frameBuffer.count >= minFramesForFit else { return }

        fitTrajectory()
    }

    // MARK: - Quadratic Regression

    /// Fit a quadratic curve y = ax² + bx + c to the trajectory points.
    /// Uses the most recent `trajectoryFrameCount` frames.
    private func fitTrajectory() {
        let frames = Array(frameBuffer.elements.suffix(trajectoryFrameCount))
        guard frames.count >= minFramesForFit else { return }

        // Extract x (horizontal distance from net) and y (height)
        // Assume X-axis is along the court length, Y-axis is vertical height.
        let n = Double(frames.count)

        // Build sums for least-squares quadratic regression
        var sumX: Double = 0
        var sumX2: Double = 0
        var sumX3: Double = 0
        var sumX4: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumX2Y: Double = 0

        // Use X position as the independent variable
        for frame in frames {
            let x = frame.positionMeters.x
            let y = frame.positionMeters.y

            let x2 = x * x
            let x3 = x2 * x
            let x4 = x3 * x

            sumX += x
            sumX2 += x2
            sumX3 += x3
            sumX4 += x4
            sumY += y
            sumXY += x * y
            sumX2Y += x2 * y
        }

        // Solve the normal equations for [a, b, c] in y = ax² + bx + c
        // | n    sumX  sumX2 | | c |   | sumY   |
        // | sumX sumX2 sumX3 | | b | = | sumXY  |
        // | sumX2 sumX3 sumX4 | | a |   | sumX2Y |

        let det = n * (sumX2 * sumX4 - sumX3 * sumX3)
                - sumX * (sumX * sumX4 - sumX3 * sumX2)
                + sumX2 * (sumX * sumX3 - sumX2 * sumX2)

        guard abs(det) > 1e-10 else { return }

        // Cramer's rule
        let c = (sumY * (sumX2 * sumX4 - sumX3 * sumX3)
                - sumX * (sumXY * sumX4 - sumX3 * sumX2Y)
                + sumX2 * (sumXY * sumX3 - sumX2 * sumX2Y)) / det

        let b = (n * (sumXY * sumX4 - sumX3 * sumX2Y)
                - sumY * (sumX * sumX4 - sumX2 * sumX3)
                + sumX2 * (sumX * sumX2Y - sumX2 * sumXY)) / det

        let a = (n * (sumX2 * sumX2Y - sumX3 * sumXY)
                - sumX * (sumX * sumX2Y - sumX2 * sumXY)
                + sumY * (sumX * sumX3 - sumX2 * sumX2)) / det

        trajectoryCoefficients = (a, b, c)

        // Compute R² (goodness of fit)
        let meanY = sumY / n
        var ssTotal: Double = 0
        var ssResidual: Double = 0

        for frame in frames {
            let x = frame.positionMeters.x
            let y = frame.positionMeters.y
            let predicted = a * x * x + b * x + c
            ssTotal += (y - meanY) * (y - meanY)
            ssResidual += (y - predicted) * (y - predicted)
        }

        let rSquared = ssTotal > 1e-10 ? 1.0 - (ssResidual / ssTotal) : 0.0
        fitQuality = max(0.0, min(rSquared, 1.0))

        // Predict landing zone
        predictLandingZone(a: a, b: b, c: c, lastFrame: frames.last!)

        // Confidence
        let frameConf = Double(frames.count) / Double(trajectoryFrameCount)
        let qualityConf = fitQuality
        confidence = frameConf * 0.4 + qualityConf * 0.6
    }

    // MARK: - Landing Zone Prediction

    /// Solve for the X position where Y = 0 (ground level) using the quadratic trajectory.
    private func predictLandingZone(a: Double, b: Double, c: Double, lastFrame: TrajectoryFrame) {
        guard abs(a) > 1e-10 else {
            // Linear fallback: y = bx + c → x = -c / b
            let linearX = b != 0 ? -c / b : lastFrame.positionMeters.x
            let landingPoint = CGPoint(x: linearX, y: 0)
            updateLandingPrediction(landingPoint, lastFrame: lastFrame)
            return
        }

        // Solve ax² + bx + c = 0 for x (where y = 0 = ground)
        let discriminant = b * b - 4.0 * a * c

        // The ball only falls downward, so take the root that is beyond the current X.
        let lastX = lastFrame.positionMeters.x

        if discriminant >= 0 {
            let sqrtDisc = sqrt(discriminant)
            let root1 = (-b + sqrtDisc) / (2.0 * a)
            let root2 = (-b - sqrtDisc) / (2.0 * a)

            // Choose the root that is in front of the ball's current position
            // For spikes/serves, the ball moves forward (increasing X)
            let landingX: Double
            if root1 > lastX && root2 > lastX {
                landingX = min(root1, root2)
            } else if root1 > lastX {
                landingX = root1
            } else if root2 > lastX {
                landingX = root2
            } else {
                // Neither root is ahead; use the max as fallback
                landingX = max(root1, root2)
            }

            let landingPoint = CGPoint(x: landingX, y: 0)
            updateLandingPrediction(landingPoint, lastFrame: lastFrame)
        } else {
            // No real roots; the trajectory doesn't intersect ground
            // Estimate from vertex + gravity time
            let vertexX = -b / (2.0 * a)
            let apexHeight = a * vertexX * vertexX + b * vertexX + c

            if apexHeight > 0 {
                // Time to fall from apex
                let fallTime = sqrt(2.0 * apexHeight / gravityMPS2)
                // Assume horizontal velocity is roughly constant
                let dx = lastFrame.positionMeters.x - (frames().count >= 2 ? frames()[frames().count - 2].positionMeters.x : lastFrame.positionMeters.x)
                let dt = lastFrame.timestamp - (frames().count >= 2 ? frames()[frames().count - 2].timestamp : (lastFrame.timestamp - 0.033))
                let vx = dt > 0.001 ? dx / dt : 5.0
                let estimatedLandingX = lastFrame.positionMeters.x + vx * fallTime

                let landingPoint = CGPoint(x: estimatedLandingX, y: 0)
                updateLandingPrediction(landingPoint, lastFrame: lastFrame)
            }
        }
    }

    private func updateLandingPrediction(_ point: CGPoint, lastFrame: TrajectoryFrame) {
        // Normalize to court coordinates
        let normalizedPoint = normalizeToCourt(point)

        // Estimate time to landing based on current speed and distance
        let dx = point.x - lastFrame.positionMeters.x
        let dy = point.y - lastFrame.positionMeters.y
        let dist = sqrt(dx * dx + dy * dy)

        // Average horizontal velocity from recent frames
        let recentFrames = Array(frameBuffer.elements.suffix(min(5, frameBuffer.count)))
        var avgVx: Double = 5.0
        if recentFrames.count >= 2 {
            let first = recentFrames.first!
            let last = recentFrames.last!
            let totalDt = last.timestamp - first.timestamp
            if totalDt > 0.001 {
                avgVx = (last.positionMeters.x - first.positionMeters.x) / totalDt
            }
        }

        estimatedTimeToLanding = avgVx > 0.1 ? dist / avgVx : 0.5

        DispatchQueue.main.async { [weak self] in
            self?.predictedLandingZone = normalizedPoint
            self?.predictedLandingMeters = point
            self?.hasPrediction = true
        }
    }

    // MARK: - Court Normalization

    /// Normalize landing position to court dimensions (0–1 range).
    /// (0, 0) = top-left corner of far court, (1, 1) = bottom-right of near court.
    func normalizeToCourt(_ positionMeters: CGPoint) -> CGPoint {
        // Map from meter coordinates to normalized 0–1
        // X: 0 = left sideline, 1 = right sideline
        // Y: 0 = far baseline, 1 = near baseline
        let normalizedX = (positionMeters.x + CourtDimensions.width / 2.0) / CourtDimensions.width
        let normalizedY = positionMeters.y / CourtDimensions.length

        return CGPoint(
            x: max(0, min(normalizedX, 1)),
            y: max(0, min(normalizedY, 1))
        )
    }

    /// Determine if the predicted landing is in-bounds.
    func isLandingInBounds() -> Bool {
        let zone = predictedLandingZone
        return zone.x >= 0 && zone.x <= 1 && zone.y >= 0 && zone.y <= 1
    }

    /// Determine which zone the ball will land in (e.g., "Zone 1", "Deep Corner").
    func landingZoneLabel() -> String {
        let zone = predictedLandingZone
        guard isLandingInBounds() else { return "Out of Bounds" }

        // Divide court into 6 zones (2 rows × 3 columns)
        if zone.y < 0.5 {
            // Front court
            if zone.x < 0.33 { return "Zone 4 (Front Left)" }
            else if zone.x < 0.67 { return "Zone 3 (Front Middle)" }
            else { return "Zone 2 (Front Right)" }
        } else {
            // Back court
            if zone.x < 0.33 { return "Zone 5 (Back Left)" }
            else if zone.x < 0.67 { return "Zone 6 (Back Middle)" }
            else { return "Zone 1 (Back Right)" }
        }
    }

    // MARK: - Helpers

    private func frames() -> [TrajectoryFrame] {
        return frameBuffer.elements
    }

    /// Get the full trajectory as an array of CGPoints in meters.
    func trajectoryPathMeters() -> [CGPoint] {
        return allTrajectoryPoints.map { $0.positionMeters }
    }

    /// Get the fitted curve as a set of sampled points for visualization.
    func fittedCurvePoints(sampleCount: Int = 50) -> [CGPoint]? {
        guard let (a, b, c) = trajectoryCoefficients,
              let first = allTrajectoryPoints.first,
              let last = allTrajectoryPoints.last else { return nil }

        let xMin = first.positionMeters.x
        let xMax = max(last.positionMeters.x, predictedLandingMeters.x)

        guard xMax > xMin else { return nil }

        var points: [CGPoint] = []
        let step = (xMax - xMin) / Double(sampleCount)

        for i in 0...sampleCount {
            let x = xMin + step * Double(i)
            let y = a * x * x + b * x + c
            points.append(CGPoint(x: x, y: y))
        }

        return points
    }

    /// Reset all internal state.
    func reset() {
        frameBuffer.clear()
        allTrajectoryPoints.removeAll()
        trajectoryCoefficients = nil
        fitQuality = 0.0
        confidence = 0.0
        hasPrediction = false
        predictedLandingZone = .zero
        predictedLandingMeters = .zero
        estimatedTimeToLanding = 0.0
        pixelsPerMeter = calibration.pixelsPerMeter
    }
}