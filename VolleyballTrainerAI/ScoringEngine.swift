import Foundation

struct ScoringEngine {
    static func compute(type: String, speed: Double, jump: Double, angle: Double, launchAngle: Double) -> Int {
        var runningScore = 0.0
        
        if type == "Spike" {
            // Spikes prioritize raw downward launch profiles and ball speed velocity
            let speedComponent = (min(speed, 50.0) / 50.0) * 35.0 // 35 Points Max for speed
            let jumpComponent = (min(jump, 36.0) / 36.0) * 35.0   // 35 Points Max for jump elevation
            let extensionComponent = (min(angle, 180.0) / 180.0) * 20.0 // 20 Points for arm length
            let downwardAngleComponent = launchAngle < 0 ? 10.0 : 0.0 // 10 Bonus points for direct sharp downward snap
            runningScore = speedComponent + jumpComponent + extensionComponent + downwardAngleComponent
        } else {
            // Serves prioritize uniform power and continuous linear flat launch mechanics
            let speedComponent = (min(speed, 45.0) / 45.0) * 45.0 // 45 Points Max for serve power
            let extensionComponent = (min(angle, 180.0) / 180.0) * 35.0 // 35 Points for tall high impact contact
            let flatLaunchComponent = (abs(launchAngle) < 15.0) ? 20.0 : (max(0, 20.0 - abs(launchAngle))) // 20 Points for optimal direct horizontal clearing lines
            runningScore = speedComponent + extensionComponent + flatLaunchComponent
        }
        
        return Int(clamp(runningScore, min: 0.0, max: 100.0))
    }
    
    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }
}

