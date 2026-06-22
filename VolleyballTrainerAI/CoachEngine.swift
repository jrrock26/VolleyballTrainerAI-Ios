struct CoachEngine {

    static func generateFeedback(
        hitType: String,
        armAngle: Double,
        jumpHeight: Double,
        ballSpeed: Double,
        launchAngle: Double,
        distance: Double
    ) -> String {

        var feedback: [String] = []

        // Arm mechanics
        if armAngle < 145 {
            feedback.append("Extend your arm higher at contact for a stronger downward snap.")
        } else if armAngle < 160 {
            feedback.append("Good extension — try to reach fully at the top of your jump.")
        } else {
            feedback.append("Excellent high-point extension.")
        }

        // Jump mechanics (spike only)
        if hitType == "Spike" {
            if jumpHeight < 10 {
                feedback.append("Increase your penultimate step speed to generate more vertical lift.")
            } else if jumpHeight < 18 {
                feedback.append("Solid jump — focus on loading your hips deeper before takeoff.")
            } else {
                feedback.append("Great vertical load and explosive jump.")
            }
        }

        // Ball speed
        if ballSpeed < 25 {
            feedback.append("Accelerate your arm swing through contact to increase ball speed.")
        } else if ballSpeed < 35 {
            feedback.append("Good power — focus on clean contact for more velocity.")
        } else {
            feedback.append("Strong ball speed — excellent power transfer.")
        }

        // Launch angle
        if hitType == "Spike" {
            if launchAngle > -5 {
                feedback.append("Snap your wrist more to drive the ball downward into the court.")
            }
        } else {
            if launchAngle < 10 {
                feedback.append("Lift your toss slightly higher to create a better upward contact path.")
            }
        }

        return feedback.joined(separator: " ")
    }
}

