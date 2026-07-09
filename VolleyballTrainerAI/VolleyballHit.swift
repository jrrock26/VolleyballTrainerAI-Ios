import Foundation
import SwiftData

@Model
final class VolleyballHit {
    var id: UUID
    var sessionID: UUID
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

    // Advanced biomechanical metrics
    var contactHeightInches: Double = 0.0
    var handSpeedMPH: Double = 0.0
    var hipShoulderSeparation: Double = 0.0

    init(sessionID: UUID, hitType: String, jumpHeightInches: Double, armAngleDegrees: Double, ballSpeedMPH: Double, ballAngleDegrees: Double = 0.0, ballDistanceFeet: Double = 0.0, videoLocalURLString: String = "", contactHeightInches: Double = 0.0, handSpeedMPH: Double = 0.0, hipShoulderSeparation: Double = 0.0) {
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
        self.contactHeightInches = contactHeightInches
        self.handSpeedMPH = handSpeedMPH
        self.hipShoulderSeparation = hipShoulderSeparation

        self.overallScore = CoachEngine.computeScore(
            hitType: hitType,
            armAngle: armAngleDegrees,
            jumpHeight: jumpHeightInches,
            ballSpeed: ballSpeedMPH,
            launchAngle: ballAngleDegrees,
            distance: ballDistanceFeet
        )

        self.coachFeedback = CoachEngine.generateFeedback(
            hitType: hitType,
            armAngle: armAngleDegrees,
            jumpHeight: jumpHeightInches,
            ballSpeed: ballSpeedMPH,
            launchAngle: ballAngleDegrees,
            distance: ballDistanceFeet,
            contactHeight: contactHeightInches,
            handSpeed: handSpeedMPH,
            hipShoulderSep: hipShoulderSeparation
        )
    }

    /// Alternate initializer for profile-aware feedback generation
    init(sessionID: UUID, hitType: String, jumpHeightInches: Double, armAngleDegrees: Double, ballSpeedMPH: Double, ballAngleDegrees: Double = 0.0, ballDistanceFeet: Double = 0.0, videoLocalURLString: String = "", contactHeightInches: Double = 0.0, handSpeedMPH: Double = 0.0, hipShoulderSeparation: Double = 0.0, profile: AthleteProfile, sessionHits: [VolleyballHit]) {
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
        self.contactHeightInches = contactHeightInches
        self.handSpeedMPH = handSpeedMPH
        self.hipShoulderSeparation = hipShoulderSeparation

        self.overallScore = CoachEngine.computeScore(
            hitType: hitType,
            armAngle: armAngleDegrees,
            jumpHeight: jumpHeightInches,
            ballSpeed: ballSpeedMPH,
            launchAngle: ballAngleDegrees,
            distance: ballDistanceFeet
        )

        self.coachFeedback = CoachEngine.generateFeedback(
            hitType: hitType,
            armAngle: armAngleDegrees,
            jumpHeight: jumpHeightInches,
            ballSpeed: ballSpeedMPH,
            launchAngle: ballAngleDegrees,
            distance: ballDistanceFeet,
            contactHeight: contactHeightInches,
            handSpeed: handSpeedMPH,
            hipShoulderSep: hipShoulderSeparation,
            profile: profile,
            sessionHits: sessionHits
        )
    }
}