import Foundation
import SwiftData

@Model
final class SavedReplay {
    var id: UUID
    var title: String
    var videoURLString: String
    var createdAt: Date
    var sessionDate: Date
    var hitType: String
    var ballSpeedMPH: Double
    var overallScore: Double
    var jumpHeightInches: Double
    var armAngleDegrees: Double
    var ballAngleDegrees: Double
    var ballDistanceFeet: Double
    var coachFeedback: String

    // Advanced biomechanical metrics
    var contactHeightInches: Double = 0.0
    var handSpeedMPH: Double = 0.0
    var hipShoulderSeparation: Double = 0.0

    init(
        title: String,
        videoURLString: String,
        sessionDate: Date,
        hitType: String,
        ballSpeedMPH: Double,
        overallScore: Double,
        jumpHeightInches: Double = 0,
        armAngleDegrees: Double = 0,
        ballAngleDegrees: Double = 0,
        ballDistanceFeet: Double = 0,
        coachFeedback: String = "",
        contactHeightInches: Double = 0.0,
        handSpeedMPH: Double = 0.0,
        hipShoulderSeparation: Double = 0.0
    ) {
        self.id = UUID()
        self.title = title
        self.videoURLString = videoURLString
        self.createdAt = Date()
        self.sessionDate = sessionDate
        self.hitType = hitType
        self.ballSpeedMPH = ballSpeedMPH
        self.overallScore = overallScore
        self.jumpHeightInches = jumpHeightInches
        self.armAngleDegrees = armAngleDegrees
        self.ballAngleDegrees = ballAngleDegrees
        self.ballDistanceFeet = ballDistanceFeet
        self.coachFeedback = coachFeedback
        self.contactHeightInches = contactHeightInches
        self.handSpeedMPH = handSpeedMPH
        self.hipShoulderSeparation = hipShoulderSeparation
    }
}