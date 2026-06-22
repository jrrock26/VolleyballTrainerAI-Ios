import Foundation

struct CoreFeedbackEngine {
    static func evaluate(type: String, angle: Double, jump: Double, score: Int) -> String {
        if type == "Spike" {
            if score >= 85 {
                return "Elite contact! Perfect high-apex body lock, explosive core rotational transfer, and an open arm down-snap."
            } else if angle < 150.0 {
                return "Your hitting elbow dropped early during backswing contraction. Drive your arm fully vertical to clear the net tape cleanly."
            } else if jump < 16.0 {
                return "Good contact mechanics. You are losing downward snap advantages by jumping flat-footed. Extend your final block stride step."
            } else {
                return "Form parameters stable. Focus on snapping your palm squarely over the center axis of the ball to force deeper downward bounce angles."
            }
        } else { // Serve
            if score >= 85 {
                return "Excellent flat line drive velocity! Balanced follow-through keeping the trail leg grounded until acceleration phase."
            } else if angle < 155.0 {
                return "Toss coordinates drifting too low. Make contact at full arm extension to optimize linear velocity."
            } else {
                return "Torque distribution tracking light. Drive through your core to prevent pushing the serve short into the middle net lines."
            }
        }
    }
}

