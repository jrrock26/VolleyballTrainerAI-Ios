import Foundation

// MARK: - Kalman Filter Utilities

/// A simple 1D Kalman filter for smoothing noisy measurements.
/// State: position and velocity.
struct KalmanFilter1D {
    // State vector: [position, velocity]
    private var x: (position: Double, velocity: Double)
    // Covariance matrix
    private var p00: Double
    private var p01: Double
    private var p10: Double
    private var p11: Double

    let processNoise: Double
    let measurementNoise: Double

    var position: Double { x.position }
    var velocity: Double { x.velocity }

    init(initialPosition: Double = 0,
         initialVelocity: Double = 0,
         processNoise: Double = 0.01,
         measurementNoise: Double = 0.5) {
        self.x = (position: initialPosition, velocity: initialVelocity)
        self.processNoise = processNoise
        self.measurementNoise = measurementNoise
        // Initial covariance: moderate uncertainty
        self.p00 = 1.0
        self.p01 = 0.0
        self.p10 = 0.0
        self.p11 = 1.0
    }

    mutating func predict(dt: Double) {
        // State transition: position += velocity * dt
        x.position += x.velocity * dt
        // velocity stays the same (constant velocity model)

        // Covariance update: P = F*P*F^T + Q
        // F = [[1, dt], [0, 1]]
        let p00_new = p00 + dt * (p10 + p01 + dt * p11) + processNoise
        let p01_new = p01 + dt * p11
        let p10_new = p10 + dt * p11
        let p11_new = p11 + processNoise

        p00 = p00_new
        p01 = p01_new
        p10 = p10_new
        p11 = p11_new
    }

    mutating func update(measurement: Double) {
        // Kalman gain: K = P*H^T / (H*P*H^T + R)
        // H = [1, 0] (we measure position directly)
        let innovation = measurement - x.position
        let s = p00 + measurementNoise  // innovation covariance
        let k0 = p00 / s
        let k1 = p10 / s

        // State update
        x.position += k0 * innovation
        x.velocity += k1 * innovation

        // Covariance update: P = (I - K*H)*P
        let factor0 = 1.0 - k0
        let p00_new = max(factor0 * p00 - k0 * p10 * 0, 0.0001)
        let p01_new = factor0 * p01 - (k0 * p11)
        let p10_new = p10 - k1 * p00
        let p11_new = p11 - k1 * p01

        p00 = max(p00_new, 0.0001)
        p01 = p01_new
        p10 = p10_new
        p11 = max(p11_new, 0.0001)
    }

    /// Convenience: predict + update in one call
    mutating func filter(measurement: Double, dt: Double) -> Double {
        predict(dt: dt)
        update(measurement: measurement)
        return x.position
    }

    mutating func reset(initialPosition: Double = 0, initialVelocity: Double = 0) {
        self.x = (position: initialPosition, velocity: initialVelocity)
        self.p00 = 1.0
        self.p01 = 0.0
        self.p10 = 0.0
        self.p11 = 1.0
    }
}

// MARK: - 2D Kalman Filter

/// A simple 2D Kalman filter for tracking (x, y) positions with velocity.
struct KalmanFilter2D {
    private var filterX: KalmanFilter1D
    private var filterY: KalmanFilter1D

    var position: CGPoint {
        CGPoint(x: filterX.position, y: filterY.position)
    }

    var velocity: CGPoint {
        CGPoint(x: filterX.velocity, y: filterY.velocity)
    }

    init(initialPosition: CGPoint = .zero,
         initialVelocity: CGPoint = .zero,
         processNoise: Double = 0.01,
         measurementNoise: Double = 0.5) {
        self.filterX = KalmanFilter1D(
            initialPosition: Double(initialPosition.x),
            initialVelocity: Double(initialVelocity.x),
            processNoise: processNoise,
            measurementNoise: measurementNoise
        )
        self.filterY = KalmanFilter1D(
            initialPosition: Double(initialPosition.y),
            initialVelocity: Double(initialVelocity.y),
            processNoise: processNoise,
            measurementNoise: measurementNoise
        )
    }

    mutating func predict(dt: Double) {
        filterX.predict(dt: dt)
        filterY.predict(dt: dt)
    }

    mutating func update(measurement: CGPoint) {
        filterX.update(measurement: Double(measurement.x))
        filterY.update(measurement: Double(measurement.y))
    }

    mutating func filter(measurement: CGPoint, dt: Double) -> CGPoint {
        filterX.predict(dt: dt)
        filterY.predict(dt: dt)
        filterX.update(measurement: Double(measurement.x))
        filterY.update(measurement: Double(measurement.y))
        return position
    }

    mutating func reset(initialPosition: CGPoint = .zero, initialVelocity: CGPoint = .zero) {
        filterX.reset(
            initialPosition: Double(initialPosition.x),
            initialVelocity: Double(initialVelocity.x)
        )
        filterY.reset(
            initialPosition: Double(initialPosition.y),
            initialVelocity: Double(initialVelocity.y)
        )
    }
}

// MARK: - Ring Buffer for Multi-Frame Analysis

/// A fixed-capacity ring buffer that retains the last N elements.
struct RingBuffer<T> {
    private var buffer: [T]
    let capacity: Int
    private(set) var count: Int = 0
    private var writeIndex: Int = 0

    var elements: [T] {
        guard count > 0 else { return [] }
        if count < capacity {
            return Array(buffer.prefix(count))
        }
        var result = Array(buffer[writeIndex..<capacity])
        result.append(contentsOf: buffer[0..<writeIndex])
        return result
    }

    var isFull: Bool { count >= capacity }

    init(capacity: Int, defaultValue: T? = nil) {
        self.capacity = max(capacity, 1)
        if let defaultValue = defaultValue {
            self.buffer = Array(repeating: defaultValue, count: capacity)
            self.count = capacity
        } else {
            self.buffer = []
            self.buffer.reserveCapacity(capacity)
        }
    }

    mutating func push(_ element: T) {
        if count < capacity {
            buffer.append(element)
            count += 1
        } else {
            buffer[writeIndex] = element
            writeIndex = (writeIndex + 1) % capacity
        }
    }

    mutating func clear() {
        buffer.removeAll(keepingCapacity: true)
        count = 0
        writeIndex = 0
    }

    var newest: T? {
        guard count > 0 else { return nil }
        if count < capacity {
            return buffer[count - 1]
        }
        let idx = (writeIndex == 0) ? capacity - 1 : writeIndex - 1
        return buffer[idx]
    }

    var oldest: T? {
        guard count > 0 else { return nil }
        if count < capacity {
            return buffer[0]
        }
        return buffer[writeIndex]
    }
}