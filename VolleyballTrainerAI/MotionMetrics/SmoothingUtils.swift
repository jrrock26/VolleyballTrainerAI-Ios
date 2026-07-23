import Foundation

// MARK: - Smoothing Utilities

/// Provides temporal smoothing over N-frame windows, confidence scoring,
/// and motion-blur detection for measurement validation.
enum SmoothingUtils {

    // MARK: - Temporal Moving Average

    /// Compute the moving average of the last N values, removing outliers
    /// beyond `maxDeviation` standard deviations before averaging.
    static func movingAverage<T: BinaryFloatingPoint>(_ values: [T], window: Int = 5) -> T {
        guard !values.isEmpty else { return T.zero }
        let windowValues = values.suffix(min(window, values.count))
        guard let first = windowValues.first else { return T.zero }
        return windowValues.reduce(T.zero, +) / T(windowValues.count)
    }

    /// Moving average with outlier rejection (values beyond ±2σ excluded).
    static func robustMovingAverage<T: BinaryFloatingPoint>(_ values: [T], window: Int = 5) -> T {
        guard !values.isEmpty else { return T.zero }
        let windowValues = values.suffix(min(window, values.count))
        guard let first = windowValues.first else { return T.zero }

        let count = T(windowValues.count)
        let mean = windowValues.reduce(T.zero, +) / count

        // Compute standard deviation
        let variance = windowValues.reduce(T.zero) { acc, v in
            let diff = v - mean
            return acc + diff * diff
        } / count
        let stdDev = sqrt(Double(variance))

        // Reject outliers beyond 2σ
        let filtered = windowValues.filter { v in
            abs(Double(v - mean)) <= 2.0 * stdDev
        }

        guard !filtered.isEmpty else { return mean }
        return filtered.reduce(T.zero, +) / T(filtered.count)
    }

    // MARK: - Exponential Moving Average (EMA)

    /// Exponential moving average with smoothing factor alpha (0–1).
    /// Higher alpha gives more weight to recent values.
    static func exponentialMovingAverage(current: Double, previous: Double, alpha: Double = 0.3) -> Double {
        return alpha * current + (1.0 - alpha) * previous
    }

    // MARK: - Confidence Scoring

    /// Compute confidence in a measurement based on:
    /// - Detection quality (0–1 score from the tracker)
    /// - Temporal consistency (how much it deviates from recent history)
    /// - Signal-to-noise estimate (variance within the window)
    static func computeConfidence(
        detectionScore: Double,
        recentValues: [Double],
        currentValue: Double,
        varianceThreshold: Double = 0.25
    ) -> Double {
        // Base confidence from detection quality
        var confidence = max(0.0, min(detectionScore, 1.0))

        // Temporal consistency penalty
        if recentValues.count >= 3 {
            let recentAvg = recentValues.suffix(5).reduce(0, +) / Double(min(5, recentValues.count))
            let deviation = abs(currentValue - recentAvg)
            let maxAllowed = max(recentAvg * 0.5, 1.0)
            if deviation > maxAllowed {
                let penalty = min(0.5, (deviation - maxAllowed) / (maxAllowed * 2))
                confidence -= penalty
            }
        }

        // Variance penalty (high variance = lower confidence)
        if recentValues.count >= 3 {
            let recentSlice = Array(recentValues.suffix(min(5, recentValues.count)))
            let avg = recentSlice.reduce(0, +) / Double(recentSlice.count)
            let variance = recentSlice.reduce(0) { $0 + pow($1 - avg, 2) } / Double(recentSlice.count)
            let normalizedVar = min(variance / max(varianceThreshold, 0.0001), 1.0)
            confidence *= (1.0 - normalizedVar * 0.3)
        }

        return max(0.0, min(confidence, 1.0))
    }

    // MARK: - Motion Blur Detection

    /// Detect motion blur based on the rate of change of bounding-box
    /// aspect ratio and the apparent elongation of the tracked object.
    static func motionBlurScore(
        boxWidth: Double,
        boxHeight: Double,
        previousWidth: Double,
        previousHeight: Double,
        velocityMagnitude: Double
    ) -> Double {
        let aspectRatio = boxWidth / max(boxHeight, 0.0001)
        let previousAspect = previousWidth / max(previousHeight, 0.0001)

        // Aspect ratio change indicates smearing
        let aspectChange = abs(aspectRatio - previousAspect)

        // Elongation beyond expected circle (ball aspect ≈ 1.0)
        let elongation = max(0, abs(aspectRatio - 1.0) - 0.15)

        // Combine: fast movement + shape distortion = motion blur
        let blurScore = aspectChange * 0.5 + elongation * 0.3 + min(velocityMagnitude / 2000.0, 1.0) * 0.2
        return max(0.0, min(blurScore, 1.0))
    }

    // MARK: - Velocity from Position Buffer

    /// Compute velocity (Δdistance / Δtime) from a ring buffer of
    /// (position, timestamp) pairs over the specified window.
    struct TimedPosition {
        let position: CGPoint
        let timestamp: TimeInterval
    }

    static func computeVelocity(
        positions: [TimedPosition],
        window: Int = 5,
        pixelsPerMeter: Double
    ) -> (speedMPS: Double, confidence: Double) {
        let windowed = positions.suffix(min(window, positions.count))
        guard windowed.count >= 2,
              let first = windowed.first,
              let last = windowed.last else {
            return (0, 0)
        }

        let dt = last.timestamp - first.timestamp
        guard dt > 0.001 else { return (0, 0) }

        let dx = last.position.x - first.position.x
        let dy = last.position.y - first.position.y
        let pixelDistance = sqrt(dx * dx + dy * dy)
        let metersDistance = pixelDistance / pixelsPerMeter
        let speedMPS = metersDistance / dt

        // Confidence based on window size and temporal spacing
        let expectedFrames = Double(window)
        let actualFrames = Double(windowed.count)
        let frameCoverage = actualFrames / expectedFrames

        // Consistency of intermediate velocities
        var intermediateSpeeds: [Double] = []
        for i in 1..<windowed.count {
            let prev = Array(windowed)[i - 1]
            let curr = Array(windowed)[i]
            let idt = curr.timestamp - prev.timestamp
            if idt > 0.001 {
                let idx = curr.position.x - prev.position.x
                let idy = curr.position.y - prev.position.y
                let ipDist = sqrt(idx * idx + idy * idy) / pixelsPerMeter
                intermediateSpeeds.append(ipDist / idt)
            }
        }

        let interVar: Double
        if intermediateSpeeds.count >= 2 {
            let avg = intermediateSpeeds.reduce(0, +) / Double(intermediateSpeeds.count)
            interVar = intermediateSpeeds.reduce(0) { $0 + pow($1 - avg, 2) } / Double(intermediateSpeeds.count)
        } else {
            interVar = 0
        }

        let consistencyScore = exp(-interVar / max(1.0, speedMPS * speedMPS * 0.01))
        let confidence = frameCoverage * consistencyScore * 0.8 + 0.2

        return (speedMPS, max(0.0, min(confidence, 1.0)))
    }

    // MARK: - Gravity-Based Physics Correction

    /// Correct vertical displacement using airtime via the free-fall equation:
    /// h = (1/2) * g * (t/2)^2  where t = total airtime and t/2 = time from apex to ground.
    /// g = 9.81 m/s²
    static func gravityCorrectedHeight(airtimeSeconds: Double) -> Double {
        guard airtimeSeconds > 0 else { return 0 }
        let halfTime = airtimeSeconds / 2.0
        return 0.5 * 9.81 * halfTime * halfTime  // meters
    }

    /// Estimate jump height from takeoff velocity using v² = 2*g*h → h = v²/(2*g)
    static func heightFromVelocity(verticalVelocityMPS: Double) -> Double {
        guard verticalVelocityMPS > 0 else { return 0 }
        return (verticalVelocityMPS * verticalVelocityMPS) / (2.0 * 9.81)
    }
}