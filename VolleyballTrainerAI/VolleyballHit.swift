import Foundation
import SwiftData

@Model
final class VolleyballHit {
    var id: UUID
    var sessionID: UUID // NEW: Groups separate hits into a single cohesive training session block
    var timestamp: Date
    var hitType: String = "Spike"
    var jumpHeightInches: Double = 0.0
    var armAngleDegrees: Double = 0.0
    var ballSpeedMPH: Double = 0.0
    var ballAngleDegrees: Double = 0.0
    var ballDistanceFeet: Double = 0.0
    var overallScore: Double = 0.0
    var coachFeedback: String = ""
    var videoLocalURLString: String = ""
    
    init(sessionID: UUID, hitType: String, jumpHeightInches: Double, armAngleDegrees: Double, ballSpeedMPH: Double, ballAngleDegrees: Double = 0.0, ballDistanceFeet: Double = 0.0, videoLocalURLString: String = "") {
        self.id = UUID()
        self.sessionID = sessionID
        self.timestamp = Date()
        self.hitType = hitType
        self.jumpHeightInches = jumpHeightInches
        self.armAngleDegrees = armAngleDegrees
        self.ballSpeedMPH = ballSpeedMPH
        self.ballAngleDegrees = ballAngleDegrees
        self.ballDistanceFeet = ballDistanceFeet
        self.videoLocalURLString = videoLocalURLString
        
        let baseSpeedScore = ballSpeedMPH * 1.5
        let baseAngleScore = (180.0 - abs(160.0 - armAngleDegrees)) * 0.4
        let baseJumpScore = hitType == "Spike" ? (jumpHeightInches * 2.0) : 0.0
        self.overallScore = max(10.0, min(100.0, baseSpeedScore + baseAngleScore + baseJumpScore))
        
        if hitType == "Spike" {
            if armAngleDegrees < 145.0 {
                self.coachFeedback = "Drop your elbow down. Extend your arm higher at apex contact to snap down into the court."
            } else if jumpHeightInches < 15.0 {
                self.coachFeedback = "Good contact angle. Focus on explosive penultimate stride steps to elevate your jump apex."
            } else {
                self.coachFeedback = "Perfect high-point extension! Excellent snap and solid vertical load profile."
            }
        } else {
            if armAngleDegrees < 150.0 {
                self.coachFeedback = "Toss the ball higher and slightly more out in front of your hitting shoulder."
            } else {
                self.coachFeedback = "Solid linear power line. Consistent torque through your contact pathway."
            }
        }
    }
}

