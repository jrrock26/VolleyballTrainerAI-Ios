import SwiftUI
import SwiftData
import AudioToolbox
import AVFoundation

// MARK: - Practice Models
enum PracticeCategory: String, Codable, CaseIterable, Identifiable {
    case warmup = "Warmup"
    case ballControl = "Ball Control"
    case setting = "Setting"
    case hitting = "Hitting"
    case blocking = "Blocking"
    case defense = "Defense"
    case serveReceive = "Serve Receive"
    case serving = "Serving"
    case teamSystems = "Team Systems"
    case games = "Games"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .warmup: return "flame.fill"
        case .ballControl: return "pencil.circle.fill"
        case .setting: return "hand.point.up.fill"
        case .hitting: return "target"
        case .blocking: return "shield.fill"
        case .defense: return "ant.fill"
        case .serveReceive: return "arrow.up.and.down.and.arrow.left.and.right"
        case .serving: return "arrow.right.circle.fill"
        case .teamSystems: return "person.3.fill"
        case .games: return "gamecontroller.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .warmup: return .green
        case .ballControl: return .cyan
        case .setting: return .purple
        case .hitting: return .red
        case .blocking: return .orange
        case .defense: return .blue
        case .serveReceive: return .yellow
        case .serving: return .pink
        case .teamSystems: return .indigo
        case .games: return .mint
        }
    }
}

struct PracticeBlock: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let name: String
    let category: PracticeCategory
    let durationMinutes: Int
    let type: String // "individual", "team", "both"
    let difficulty: String // "beginner", "intermediate", "advanced"
    let imageName: String
    let instructions: [String]
    let steps: [String]
    
    init(id: UUID = UUID(), name: String, category: PracticeCategory, durationMinutes: Int, type: String, difficulty: String, imageName: String = "practice_icon", instructions: [String], steps: [String]) {
        self.id = id
        self.name = name
        self.category = category
        self.durationMinutes = durationMinutes
        self.type = type
        self.difficulty = difficulty
        self.imageName = imageName
        self.instructions = instructions
        self.steps = steps
    }
}

struct PracticePlan: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var focus: String
    var createdAt: Date
    var blocks: [PracticeBlock]
    
    var totalMinutes: Int { blocks.reduce(0) { $0 + $1.durationMinutes } }
    
    init(id: UUID = UUID(), name: String, focus: String, createdAt: Date = Date(), blocks: [PracticeBlock]) {
        self.id = id
        self.name = name
        self.focus = focus
        self.createdAt = createdAt
        self.blocks = blocks
    }
}

// MARK: - Practice Library
enum VolleyballPracticeLibrary {
    static let stretches: [PracticeBlock] = [
        PracticeBlock(name: "Dynamic Full Body Stretch Flow", category: .warmup, durationMinutes: 4, type: "both", difficulty: "beginner", imageName: "dynamic_full_body_stretch_flow", instructions: [
            "Move through continuous dynamic stretches to prepare muscles and joints.",
            "Focus on controlled movements, not bouncing or forcing stretches.",
            "Breathe deeply and move through full ranges of motion.",
            "Keep core engaged and posture tall throughout."
        ], steps: [
            "Perform arm circles forward and backward for 30 seconds.",
            "Walk forward with knee hugs for 30 seconds.",
            "Perform walking lunges with torso rotation for 30 seconds.",
            "Complete leg swings forward and lateral for 30 seconds each."
        ]),
        PracticeBlock(name: "Hip and Shoulder Mobility", category: .warmup, durationMinutes: 4, type: "both", difficulty: "beginner", imageName: "hip_and_shoulder_mobility", instructions: [
            "Target the hips and shoulders — key areas for volleyball performance.",
            "Focus on controlled, deliberate movements.",
            "Do not force any stretch beyond comfortable range.",
            "Maintain steady breathing through each stretch."
        ], steps: [
            "Perform hip circles: 10 in each direction.",
            "Complete deep lunge with rotation: 5 per side.",
            "Do shoulder pass-throughs with a stick or band: 10 reps.",
            "Finish with cat-cow spinal mobility: 8 slow cycles."
        ]),
        PracticeBlock(name: "Lower Body Activation", category: .warmup, durationMinutes: 4, type: "individual", difficulty: "beginner", imageName: "lower_body_activation", instructions: [
            "Activate the legs and hips for explosive movement.",
            "Focus on proper form and controlled tempo.",
            "Feel the muscles engage with each movement.",
            "Keep the core braced throughout the sequence."
        ], steps: [
            "Perform bodyweight squats: 10 slow reps with 2-second hold at bottom.",
            "Complete walking hamstring sweeps: 8 per leg.",
            "Do lateral lunges: 8 per side.",
            "Finish with standing quad stretches: 20 seconds each leg."
        ]),
        PracticeBlock(name: "Upper Body Stretch Series", category: .warmup, durationMinutes: 3, type: "individual", difficulty: "beginner", imageName: "upper_body_stretch_series", instructions: [
            "Prepare the shoulders, arms, and upper back for hitting and serving.",
            "Keep movements slow and controlled.",
            "Focus on full range of motion.",
            "Do not rush through the stretches."
        ], steps: [
            "Cross-body shoulder stretch: 20 seconds each arm.",
            "Triceps stretch overhead: 15 seconds each arm.",
            "Open-book thoracic rotations: 5 per side.",
            "Finish with wrist and forearm flexor stretch: 15 seconds each side."
        ])
    ]
    
    static let warmups: [PracticeBlock] = [
        PracticeBlock(name: "Dynamic Full-Body Warm-Up", category: .warmup, durationMinutes: 5, type: "both", difficulty: "beginner", imageName: "dynamic_full_body_warmup", instructions: [
            "Use continuous movement to gradually elevate heart rate.",
            "Focus on smooth, controlled motions rather than speed.",
            "Keep posture tall with core engaged throughout the sequence.",
            "Move through full ranges of motion without forcing stretches.",
            "Prepare joints and muscles for volleyball-specific actions."
        ], steps: [
            "Jog lightly around the court for 60 seconds.",
            "Add high knees down and back once.",
            "Add butt kicks down and back once.",
            "Finish with lateral shuffles and backpedal to center."
        ]),
        PracticeBlock(name: "Ball-Handling Warm-Up Toss", category: .warmup, durationMinutes: 4, type: "individual", difficulty: "beginner", imageName: "ball_handling_warmup_toss", instructions: [
            "Use a single ball to activate hands and coordination.",
            "Keep eyes on the ball and maintain athletic posture.",
            "Focus on clean, controlled contacts rather than power.",
            "Stay light on your feet and ready to move."
        ], steps: [
            "Toss the ball straight up and catch with both hands 10 times.",
            "Toss and catch with right hand only 10 times.",
            "Toss and catch with left hand only 10 times.",
            "Add light footwork while continuing the toss pattern."
        ]),
        PracticeBlock(name: "Shadow Footwork Warm-Up", category: .warmup, durationMinutes: 4, type: "both", difficulty: "beginner", imageName: "shadow_footwork_warmup", instructions: [
            "Rehearse volleyball-specific footwork patterns without the ball.",
            "Emphasize balance, posture, and rhythm over speed.",
            "Keep hips low and chest up during all movements.",
            "Use arms naturally to support balance and power."
        ], steps: [
            "Perform approach footwork (3-step or 4-step) without jumping.",
            "Shadow defensive shuffles left and right.",
            "Add short sprints forward and backpedals.",
            "Repeat sequence 2-3 times with increasing intensity."
        ]),
        PracticeBlock(name: "Partner Mirror Movement", category: .warmup, durationMinutes: 5, type: "team", difficulty: "intermediate", imageName: "partner_mirror_movement", instructions: [
            "Work in pairs to mirror each other's movements.",
            "Focus on quick reactions and controlled footwork.",
            "Maintain low, athletic posture throughout the drill.",
            "Communicate and stay engaged with your partner."
        ], steps: [
            "Partners face each other about 8-10 feet apart.",
            "One partner leads lateral, forward, and backward movements.",
            "The other partner mirrors the movement exactly.",
            "Switch leader and repeat for multiple rounds."
        ]),
        PracticeBlock(name: "Triangle Movement Warm-Up", category: .warmup, durationMinutes: 5, type: "both", difficulty: "intermediate", imageName: "triangle_movement_warmup", instructions: [
            "Use three cones or markers to form a triangle.",
            "Emphasize quick changes of direction and body control.",
            "Stay low and push off the outside foot when cutting.",
            "Maintain consistent tempo and clean footwork."
        ], steps: [
            "Place three cones in a triangle about 8-10 feet apart.",
            "Start at one cone and sprint to the second.",
            "Shuffle to the third cone, then backpedal to the first.",
            "Repeat pattern clockwise, then counterclockwise."
        ]),
        PracticeBlock(name: "Ball Control Warm-Up Line", category: .warmup, durationMinutes: 5, type: "team", difficulty: "beginner", imageName: "ball_control_warmup_line", instructions: [
            "Use simple passing to warm up arms and platforms.",
            "Focus on clean contact and accurate ball flight.",
            "Keep knees bent and shoulders forward.",
            "Communicate target and tempo with your partner."
        ], steps: [
            "Form two lines facing each other about 10-12 feet apart.",
            "Pass back and forth using forearm passing only.",
            "After each pass, players take a small shuffle step.",
            "Rotate players down the line after a set number of reps."
        ]),
        PracticeBlock(name: "Serve Receive Shuffle Warm-Up", category: .warmup, durationMinutes: 5, type: "both", difficulty: "intermediate", imageName: "serve_receive_shuffle_warmup", instructions: [
            "Simulate serve-receive movement without full-speed serves.",
            "Focus on reading the toss and moving early.",
            "Stay low and balanced while shuffling to the ball.",
            "Finish each rep with a stable passing platform."
        ], steps: [
            "Coach or partner tosses balls to different zones.",
            "Player shuffles to the ball and sets platform early.",
            "Catch or lightly pass the ball back to the tosser.",
            "Repeat from multiple starting positions across the back row."
        ]),
        PracticeBlock(name: "Core Activation Circuit", category: .warmup, durationMinutes: 4, type: "individual", difficulty: "intermediate", imageName: "core_activation_circuit", instructions: [
            "Activate core muscles to support explosive movements.",
            "Focus on quality of movement over speed.",
            "Maintain controlled breathing throughout the circuit.",
            "Avoid arching the lower back during core exercises."
        ], steps: [
            "Perform 20 seconds of plank hold.",
            "Perform 20 seconds of side plank on each side.",
            "Perform 20 seconds of dead bug or hollow hold.",
            "Rest briefly and repeat the circuit 2-3 times."
        ]),
        PracticeBlock(name: "Shoulder Prep with Band", category: .warmup, durationMinutes: 4, type: "individual", difficulty: "intermediate", imageName: "shoulder_prep_band", instructions: [
            "Use light resistance to warm up the shoulders safely.",
            "Focus on controlled range of motion and posture.",
            "Keep movements smooth and avoid jerking the band.",
            "Engage scapular muscles to support the shoulder joint."
        ], steps: [
            "Perform band pull-aparts for 10-12 reps.",
            "Perform external rotations on each arm for 10-12 reps.",
            "Perform overhead band presses for 10-12 reps.",
            "Repeat sequence 2-3 times with light resistance."
        ]),
        PracticeBlock(name: "Jump Prep and Landing Mechanics", category: .warmup, durationMinutes: 5, type: "both", difficulty: "intermediate", imageName: "jump_prep_landing_mechanics", instructions: [
            "Prepare lower body for repeated jumping.",
            "Emphasize soft, controlled landings.",
            "Keep knees tracking over toes during takeoff and landing.",
            "Maintain upright chest and engaged core."
        ], steps: [
            "Perform 5-8 small squat jumps focusing on soft landings.",
            "Add lateral jumps side to side with controlled landings.",
            "Add forward and backward jumps with balance on landing.",
            "Finish with 3-5 full-height jumps at game-speed intensity."
        ])
    ]
    
    static let ballControlDrills: [PracticeBlock] = [
        PracticeBlock(name: "Triangle Pepper", category: .ballControl, durationMinutes: 5, type: "team", difficulty: "intermediate", imageName: "triangle_pepper", instructions: [
            "Three players form a triangle and keep the ball in play.",
            "Use controlled touches: pass, set, or controlled hit.",
            "Maintain spacing and communicate each contact.",
            "Focus on clean ball control and predictable flight."
        ], steps: [
            "Form a triangle 8-10 feet apart.",
            "Player A passes to B, B sets to C, C passes to A.",
            "Rotate roles every 60 seconds.",
            "Increase tempo as control improves."
        ]),
        PracticeBlock(name: "Chaos Pepper", category: .ballControl, durationMinutes: 5, type: "team", difficulty: "advanced", imageName: "chaos_pepper", instructions: [
            "Players pepper while constantly moving to new spots.",
            "Forces communication and quick adjustments.",
            "Emphasize reading ball flight and reacting early.",
            "Keep touches controlled despite movement."
        ], steps: [
            "Start peppering in pairs.",
            "After each touch, players move 2-3 steps in any direction.",
            "Add random directional calls from coach.",
            "Finish with full-speed movement pepper."
        ]),
        PracticeBlock(name: "Over-the-Net Pepper", category: .ballControl, durationMinutes: 5, type: "team", difficulty: "intermediate", imageName: "over_the_net_pepper", instructions: [
            "Pepper across the net using pass-set-hit rhythm.",
            "Focus on controlled roll shots and high sets.",
            "Maintain consistent tempo and communication.",
            "Keep the ball off the floor as long as possible."
        ], steps: [
            "Pair up across the net.",
            "Start with pass-set-roll shot.",
            "Increase tempo as control improves.",
            "Finish with controlled swings if appropriate."
        ]),
        PracticeBlock(name: "3-Touch Pepper", category: .ballControl, durationMinutes: 4, type: "team", difficulty: "beginner", imageName: "3_touch_pepper", instructions: [
            "Players must use all three touches before sending the ball back.",
            "Encourages controlled passing and setting.",
            "Focus on predictable ball flight and clean contact."
        ], steps: [
            "Partner A passes to themselves, sets to themselves, then hits to B.",
            "Partner B repeats the sequence.",
            "Keep the ball in play as long as possible.",
            "Increase tempo gradually."
        ]),
        PracticeBlock(name: "Continuous Pepper to Target", category: .ballControl, durationMinutes: 5, type: "team", difficulty: "intermediate", imageName: "continuous_pepper_target", instructions: [
            "Players pepper while aiming for a designated target zone.",
            "Improves directional control and accuracy.",
            "Focus on platform angle and body alignment."
        ], steps: [
            "Place a target zone on the court.",
            "Players pepper while directing final contact to the target.",
            "Rotate players after each successful sequence.",
            "Increase distance or difficulty as needed."
        ]),
        PracticeBlock(name: "Movement Pepper", category: .ballControl, durationMinutes: 5, type: "team", difficulty: "intermediate", imageName: "movement_pepper", instructions: [
            "Players pepper while moving laterally or forward/backward.",
            "Simulates game-speed adjustments.",
            "Focus on staying balanced while moving."
        ], steps: [
            "Players pepper while shuffling left and right.",
            "Add forward/backward movement.",
            "Add coach-called direction changes.",
            "Finish with full-speed movement pepper."
        ]),
        PracticeBlock(name: "Wall Passing Series", category: .ballControl, durationMinutes: 4, type: "individual", difficulty: "beginner", imageName: "wall_passing_series", instructions: [
            "Use a wall to develop consistent passing technique.",
            "Focus on platform angle and clean contact.",
            "Keep feet active and posture stable."
        ], steps: [
            "Pass against the wall for 20 reps.",
            "Add alternating left/right platform angles.",
            "Add movement between reps.",
            "Finish with rapid-fire passing for 30 seconds."
        ]),
        PracticeBlock(name: "Partner Short/Deep Pepper", category: .ballControl, durationMinutes: 5, type: "team", difficulty: "intermediate", imageName: "partner_short_deep_pepper", instructions: [
            "Partners alternate between short and deep contacts.",
            "Improves reading and footwork adjustments.",
            "Focus on early movement and stable platform."
        ], steps: [
            "Partner A sends a short ball, B passes.",
            "Partner B sends a deep ball, A passes.",
            "Continue alternating short/deep.",
            "Increase tempo as control improves."
        ]),
        PracticeBlock(name: "Two-Ball Pepper", category: .ballControl, durationMinutes: 4, type: "team", difficulty: "advanced", imageName: "two_ball_pepper", instructions: [
            "Two balls are in play simultaneously.",
            "Forces fast decision-making and communication.",
            "Players must stay calm under pressure."
        ], steps: [
            "Start peppering with one ball.",
            "Introduce a second ball after 10 seconds.",
            "Keep both balls alive as long as possible.",
            "Reset and repeat multiple rounds."
        ]),
        PracticeBlock(name: "Target Passing Competition", category: .ballControl, durationMinutes: 5, type: "team", difficulty: "intermediate", imageName: "target_passing_competition", instructions: [
            "Players pass to a designated target zone.",
            "Encourages accuracy and consistency.",
            "Add scoring to increase competitiveness."
        ], steps: [
            "Set up a target zone with cones.",
            "Players take turns passing to the target.",
            "Award points for accuracy.",
            "Play to a set score or time limit."
        ])
    ]
    
    static let settingDrills: [PracticeBlock] = [
        PracticeBlock(name: "Setter Triangle Footwork", category: .setting, durationMinutes: 5, type: "individual", difficulty: "intermediate", imageName: "setter_triangle_footwork", instructions: [
            "Setter moves between three points forming a triangle.",
            "Emphasizes quick, efficient footwork to get under the ball.",
            "Focus on staying square to the target before setting.",
            "Keep hands shaped early and ready for contact."
        ], steps: [
            "Place three cones in a triangle.",
            "Move to each cone in sequence using setter footwork.",
            "Square to an imaginary target at each stop.",
            "Repeat clockwise and counterclockwise."
        ]),
        PracticeBlock(name: "Wall Setting Series", category: .setting, durationMinutes: 4, type: "individual", difficulty: "beginner", imageName: "wall_setting_series", instructions: [
            "Use a wall to develop consistent hand contact.",
            "Focus on soft touch and minimal spin.",
            "Keep elbows out and hands shaped early."
        ], steps: [
            "Stand 5-7 feet from a wall.",
            "Set repeatedly against the wall for 20-30 reps.",
            "Add movement left and right between reps.",
            "Finish with rapid-fire setting for 20 seconds."
        ]),
        PracticeBlock(name: "Jump Setting Rhythm Drill", category: .setting, durationMinutes: 5, type: "individual", difficulty: "advanced", imageName: "jump_setting_rhythm", instructions: [
            "Develop timing and rhythm for jump setting.",
            "Focus on consistent takeoff and landing mechanics.",
            "Keep hands high and ready before leaving the ground."
        ], steps: [
            "Start with stationary jump sets.",
            "Add a small approach into the jump.",
            "Add movement to the left and right.",
            "Finish with full-speed jump setting reps."
        ]),
        PracticeBlock(name: "Out-of-System Chase Drill", category: .setting, durationMinutes: 5, type: "team", difficulty: "advanced", imageName: "out_of_system_chase", instructions: [
            "Setter chases down off-target passes.",
            "Focus on footwork efficiency and balance.",
            "Deliver a hittable ball even from poor positions."
        ], steps: [
            "Coach tosses balls off-center.",
            "Setter chases and squares to target.",
            "Deliver a high, controlled set.",
            "Repeat from multiple court zones."
        ]),
        PracticeBlock(name: "Setter Decision-Making Drill", category: .setting, durationMinutes: 5, type: "team", difficulty: "advanced", imageName: "setter_decision_making", instructions: [
            "Setter reads blockers and chooses best attacking option.",
            "Emphasizes quick decisions under pressure.",
            "Focus on deception and tempo control."
        ], steps: [
            "Coach calls out blocker positions.",
            "Setter reads the defense and selects the best set.",
            "Add live hitters for realistic decision-making.",
            "Increase speed and complexity over time."
        ])
    ]
    
    static let hittingDrills: [PracticeBlock] = [
        PracticeBlock(name: "Hitting Arm Swing Mechanics", category: .hitting, durationMinutes: 10, type: "individual", difficulty: "intermediate", imageName: "hitting_arm_swing", instructions: [
            "Load your hitting elbow behind your ear at takeoff.",
            "Contact the ball in front of your body at full reach.",
            "Freeze the finish position and check shoulder-to-wrist alignment."
        ], steps: [
            "Perform 10 slow-motion arm swings focusing on elbow position.",
            "Add approach footwork without jumping.",
            "Add jump and swing without ball contact.",
            "Finish with full-speed swings into target."
        ]),
        PracticeBlock(name: "Approach Angle Reps", category: .hitting, durationMinutes: 9, type: "individual", difficulty: "intermediate", imageName: "hitting_approach_angle", instructions: [
            "Mark your start position and target contact zone.",
            "Use a controlled 3-step approach with explosive arm drive.",
            "Plant your hips open and attack through the ball into the target."
        ], steps: [
            "Mark start position 10-12 feet from net.",
            "Practice approach timing without jump.",
            "Add jump and reach for target.",
            "Complete 15-20 reps with full rest between sets."
        ]),
        PracticeBlock(name: "Max Jump Touches", category: .hitting, durationMinutes: 8, type: "individual", difficulty: "advanced", imageName: "hitting_max_jump", instructions: [
            "Take a 3-step approach and jump as high as possible.",
            "Swing arms aggressively into takeoff and reach with both hands.",
            "Land softly and reset fully before next rep."
        ], steps: [
            "Stand under target 8-10 feet from net.",
            "Perform 3-step approach with max effort jump.",
            "Contact target at peak height.",
            "Complete 8-10 reps with 2 minutes rest between sets."
        ]),
        PracticeBlock(name: "Hitting High Ball", category: .hitting, durationMinutes: 8, type: "individual", difficulty: "intermediate", imageName: "hitting_high_ball", instructions: [
            "Have a partner toss a high ball or use a ball machine.",
            "Delay start of approach until ball begins to descend.",
            "Contact the ball above forehead with full wrist snap."
        ], steps: [
            "Partner tosses ball 2-3 feet above antenna.",
            "Wait for ball to reach peak before starting approach.",
            "Attack ball at highest contact point.",
            "Complete 12-15 reps."
        ]),
        PracticeBlock(name: "Cross Court Target Hits", category: .hitting, durationMinutes: 10, type: "individual", difficulty: "intermediate", imageName: "hitting_cross_court", instructions: [
            "Set up target in cross-court zone 1-2 feet inside line.",
            "Open shoulders, contact high, finish with thumb down.",
            "Track makes vs misses and adjust approach angle."
        ], steps: [
            "Place target cone in cross-court deep corner.",
            "Approach and hit to target 15 times.",
            "Count successful hits.",
            "Adjust approach angle based on results."
        ]),
        PracticeBlock(name: "Line Shot Accuracy", category: .hitting, durationMinutes: 8, type: "individual", difficulty: "intermediate", imageName: "hitting_line_shot", instructions: [
            "Aim ball down the line 1-2 feet inside sideline.",
            "Keep ball in front and reach for top of ball.",
            "Land balanced and reset to same starting spot."
        ], steps: [
            "Set target cone on sideline.",
            "Hit 15 line shots aiming for target.",
            "Focus on clean contact and angle.",
            "Track accuracy percentage."
        ]),
        PracticeBlock(name: "Tool the Block Drill", category: .hitting, durationMinutes: 8, type: "individual", difficulty: "advanced", imageName: "hitting_tool_block", instructions: [
            "Set up blocker or block target (pads/cones).",
            "Attack aggressively aiming for top of blocker's hands.",
            "Use block to deflect ball out of bounds."
        ], steps: [
            "Place blocking target at net.",
            "Approach and swing at top of block.",
            "Aim to contact top of hands/pad.",
            "Complete 10-12 reps."
        ]),
        PracticeBlock(name: "Transition Hitting", category: .hitting, durationMinutes: 10, type: "team", difficulty: "advanced", imageName: "hitting_transition", instructions: [
            "Simulate defensive-to-offensive transition.",
            "React to cue then transition into attack approach.",
            "Make split-second decision on shot location."
        ], steps: [
            "Start in base defensive position.",
            "Coach signals transition.",
            "Move to attack position and approach.",
            "Complete 8-10 transition reps."
        ])
    ]
    
    static let blockingDrills: [PracticeBlock] = [
        PracticeBlock(name: "Block Footwork + Seal", category: .blocking, durationMinutes: 8, type: "individual", difficulty: "intermediate", imageName: "block_footwork_seal", instructions: [
            "Start at net in ready blocking position.",
            "Shuffle step to contact point, keep hands up.",
            "Penetrate over net with hands, sealing seam."
        ], steps: [
            "Start in middle blocker position.",
            "Shuffle left to point of attack.",
            "Jump and press hands over net.",
            "Repeat 10 times each direction."
        ]),
        PracticeBlock(name: "Read Block vs Outside Hitter", category: .blocking, durationMinutes: 8, type: "team", difficulty: "advanced", imageName: "read_block_outside_hitter", instructions: [
            "Face outside hitter, read approach angle.",
            "Close block with partner, no seam.",
            "Time jump with hitter's approach."
        ], steps: [
            "Partner acts as outside hitter.",
            "Read approach and adjust position.",
            "Close block with partner.",
            "Complete 15-20 reps."
        ]),
        PracticeBlock(name: "Adjustable Block", category: .blocking, durationMinutes: 8, type: "individual", difficulty: "advanced", imageName: "adjustable_block", instructions: [
            "Start in middle block position.",
            "Shuffle to pin based on coach signal.",
            "Press and read hitter's shoulder for direction."
        ], steps: [
            "Coach calls 'left' or 'right'.",
            "Shuffle to indicated pin.",
            "Jump and press at net.",
            "Complete 12 reps each direction."
        ]),
        PracticeBlock(name: "Block + Recover to Defense", category: .blocking, durationMinutes: 8, type: "team", difficulty: "advanced", imageName: "block_recover_defense", instructions: [
            "Jump block at net then land into defensive stance.",
            "Coach attacks after block.",
            "Dig ball to setter."
        ], steps: [
            "Perform blocking jump.",
            "Land and immediately drop to defense.",
            "React to coach's attack.",
            "Complete 10-12 transition reps."
        ]),
        PracticeBlock(name: "Double-Block Timing", category: .blocking, durationMinutes: 8, type: "team", difficulty: "advanced", imageName: "double_block_timing", instructions: [
            "Set up with blocking partner and outside hitter.",
            "Block call before set arrives.",
            "Both blockers jump at same time."
        ], steps: [
            "Practice verbal calls: 'Together' or 'Stay'.",
            "Approach and block with partner.",
            "Focus on simultaneous jump timing.",
            "Complete 15 reps."
        ])
    ]
    
    static let defenseDrills: [PracticeBlock] = [
        PracticeBlock(name: "Defensive Platform Basics", category: .defense, durationMinutes: 6, type: "individual", difficulty: "beginner", imageName: "defensive_platform_basics", instructions: [
            "Get in low defensive stance, feet shoulder-width.",
            "Present platform at 45 degrees.",
            "Absorb the ball, do not swing."
        ], steps: [
            "Start in base defensive position.",
            "Coach tosses ball to forearms.",
            "Pass to target 10 feet in front.",
            "Complete 20 reps."
        ]),
        PracticeBlock(name: "Defensive Digging Reads", category: .defense, durationMinutes: 8, type: "team", difficulty: "advanced", imageName: "defensive_digging_reads", instructions: [
            "Start in base defense.",
            "Read attacker's shoulder line and arm speed.",
            "Dig ball up to target zone."
        ], steps: [
            "Coach attacks from box.",
            "Read and react to attack.",
            "Dig to designated target.",
            "Complete 4 sets of 6 attacks."
        ]),
        PracticeBlock(name: "Roll and Pancake Saves", category: .defense, durationMinutes: 6, type: "individual", difficulty: "advanced", imageName: "roll_and_pancake_saves", instructions: [
            "Coach tosses balls just out of reach.",
            "Execute controlled roll to save.",
            "Practice pancake: dive flat and slide hand under ball."
        ], steps: [
            "Start in defensive position.",
            "Coach tosses ball 2-3 feet to side.",
            "Execute roll dive to save ball.",
            "Practice pancake on hard-driven balls."
        ]),
        PracticeBlock(name: "Defense from Deep Court", category: .defense, durationMinutes: 8, type: "individual", difficulty: "advanced", imageName: "defense_from_deep_court", instructions: [
            "Start on baseline.",
            "Read trajectory early, take drop step.",
            "Dig ball high to center court."
        ], steps: [
            "Position on baseline.",
            "Coach attacks deep ball.",
            "Read and pursue ball.",
            "Complete 8-10 reps."
        ]),
        PracticeBlock(name: "Tip Defense Read", category: .defense, durationMinutes: 6, type: "individual", difficulty: "intermediate", imageName: "tip_defense_read", instructions: [
            "Partner approaches but tips ball over net.",
            "Read open palm signal, step in immediately.",
            "Dig tip high to setter."
        ], steps: [
            "Partner shows approach motion.",
            "Read hand signal for tip.",
            "Step in and play ball.",
            "Complete 15-20 reps."
        ]),
        PracticeBlock(name: "Pepper Progression", category: .defense, durationMinutes: 10, type: "team", difficulty: "intermediate", imageName: "pepper_progression_defense", instructions: [
            "Standard pepper: dig, set, hit in continuous loop.",
            "Add movement between contacts.",
            "Focus on quality over quantity."
        ], steps: [
            "Partner A digs, B sets, A hits.",
            "Add 2-3 step shuffle between contacts.",
            "Increase tempo progressively.",
            "Goal: 50 consecutive touches without miss."
        ])
    ]
    
    static let serveReceiveDrills: [PracticeBlock] = [
        PracticeBlock(name: "Serve Receive Platform", category: .serveReceive, durationMinutes: 8, type: "team", difficulty: "intermediate", imageName: "serve_receive_platform", instructions: [
            "Start in ready position, present flat angled platform.",
            "Move through ball, do not reach.",
            "Complete 30 quality passes."
        ], steps: [
            "Start in base position.",
            "Coach serves to zone 1.",
            "Pass to target at setter position.",
            "Rotate through all back-row positions."
        ]),
        PracticeBlock(name: "Serve Receive Under Pressure", category: .serveReceive, durationMinutes: 8, type: "team", difficulty: "advanced", imageName: "serve_receive_pressure", instructions: [
            "Partner serves to random zones, must read and move.",
            "Focus on low athletic stance and split-step.",
            "Target: 8/10 passes within 3 feet of setter target."
        ], steps: [
            "Coach serves to random zones.",
            "Player splits and moves to ball.",
            "Pass to designated target.",
            "Track accuracy over 10 serves."
        ]),
        PracticeBlock(name: "Short Serve Recovery", category: .serveReceive, durationMinutes: 6, type: "team", difficulty: "advanced", imageName: "short_serve_recovery", instructions: [
            "Partner serves short (drop) balls over net into Zones 2 or 3.",
            "Explode forward from base position.",
            "Pass high to setter."
        ], steps: [
            "Start in base position.",
            "Coach serves short ball.",
            "Explode forward and play ball.",
            "Complete 15-20 short serve reps."
        ]),
        PracticeBlock(name: "Serve Receive + Attack Transition", category: .serveReceive, durationMinutes: 10, type: "team", difficulty: "advanced", imageName: "serve_receive_attack_transition", instructions: [
            "Receive serve, pass to setter, then transition to attack.",
            "Sequence must be seamless: pass to setter to hit.",
            "Complete 8-10 repetitions."
        ], steps: [
            "Receive serve and pass.",
            "Watch setter delivery.",
            "Transition into attack approach.",
            "Complete 8-10 full sequences."
        ]),
        PracticeBlock(name: "Two-Person Passing Triangle", category: .serveReceive, durationMinutes: 6, type: "team", difficulty: "beginner", imageName: "two_person_passing_triangle", instructions: [
            "Two passers in base positions.",
            "Coach tosses to alternating zones.",
            "Move before ball crosses net."
        ], steps: [
            "Passer A and B in base positions.",
            "Coach tosses to zone 1 then zone 6.",
            "Passers shuffle to ball.",
            "Complete 20-25 reps."
        ])
    ]
    
    static let servingDrills: [PracticeBlock] = [
        PracticeBlock(name: "Serve Float + Topspin Mix", category: .serving, durationMinutes: 8, type: "individual", difficulty: "intermediate", imageName: "serve_float_topspin_mix", instructions: [
            "Alternate between float serves and topspin serves.",
            "Float: contact with flat rigid hand, no follow-through spin.",
            "Topspin: snap wrist at contact, follow through low."
        ], steps: [
            "Serve 5 float serves focusing on no spin.",
            "Serve 5 topspin serves with wrist snap.",
            "Alternate pattern for 20 total serves.",
            "Track success rate."
        ]),
        PracticeBlock(name: "Jump Serve Approach", category: .serving, durationMinutes: 8, type: "individual", difficulty: "advanced", imageName: "jump_serve_approach", instructions: [
            "Start 10-12 feet behind baseline.",
            "Toss high and 3 feet in front.",
            "3-step approach, jump and contact at peak."
        ], steps: [
            "Mark starting position.",
            "Practice toss consistency (10 tosses).",
            "Add approach without contact.",
            "Complete 15-20 jump serves."
        ]),
        PracticeBlock(name: "Serve Accuracy Zones", category: .serving, durationMinutes: 8, type: "individual", difficulty: "intermediate", imageName: "serve_accuracy_zones", instructions: [
            "Aim for designated zones on court.",
            "Focus on consistent toss and contact point.",
            "Track accuracy percentage."
        ], steps: [
            "Mark zones 1, 6, and 5 on opponent's side.",
            "Serve 5 balls to each zone.",
            "Track successful serves.",
            "Increase difficulty by adding movement."
        ]),
        PracticeBlock(name: "Pressure Serving Game", category: .serving, durationMinutes: 8, type: "team", difficulty: "intermediate", imageName: "pressure_serving_game", instructions: [
            "Teams compete in serving pressure situations.",
            "Simulates match scoring pressure.",
            "Track serving percentage under pressure."
        ], steps: [
            "Divide into teams.",
            "Serve to specific zones.",
            "Track makes and misses.",
            "Play to set score."
        ])
    ]
    
    static let teamSystemDrills: [PracticeBlock] = [
        PracticeBlock(name: "6v6 System Scrimmage", category: .teamSystems, durationMinutes: 15, type: "team", difficulty: "intermediate", imageName: "6v6_system_scrimmage", instructions: [
            "Full 6v6 scrimmage focusing on system execution.",
            "Emphasize serve-receive, transition, and side-out.",
            "Encourage communication on every play."
        ], steps: [
            "Rotate through all positions.",
            "Coach calls out situations to work on.",
            "Stop play to correct system errors.",
            "Play continuous rally scoring."
        ]),
        PracticeBlock(name: "Serve Receive System", category: .teamSystems, durationMinutes: 10, type: "team", difficulty: "intermediate", imageName: "serve_receive_system", instructions: [
            "Practice serve-receive formations and responsibilities.",
            "Focus on communication and coverage.",
            "Simulate game-speed serves."
        ], steps: [
            "Set up in receive formation.",
            "Coach serves to various zones.",
            "Pass to target and transition.",
            "Rotate through all formations."
        ]),
        PracticeBlock(name: "Transition Offense Drill", category: .teamSystems, durationMinutes: 10, type: "team", difficulty: "advanced", imageName: "transition_offense_drill", instructions: [
            "Practice transition from defense to offense.",
            "Emphasize quick setters and hitter coverage.",
            "Focus on out-of-system play."
        ], steps: [
            "Defense makes dig.",
            "Setter transitions to setter position.",
            "Hitters run approaches.",
            "Complete 12-15 transitions."
        ]),
        PracticeBlock(name: "Coverage System Drill", category: .teamSystems, durationMinutes: 8, type: "team", difficulty: "advanced", imageName: "coverage_system_drill", instructions: [
            "Train hitters and defenders to cover attacks.",
            "Focus on positioning around hitter.",
            "Develop coverage responsibility awareness."
        ], steps: [
            "Hitter performs controlled swings.",
            "Teammates position in coverage zones.",
            "React to blocked or deflected balls.",
            "Rotate hitters and coverage roles."
        ]),
        PracticeBlock(name: "Offense vs Defense System", category: .teamSystems, durationMinutes: 10, type: "team", difficulty: "advanced", imageName: "offense_vs_defense_system", instructions: [
            "One side runs structured offense, other runs defense.",
            "Focus on reading, communication, and discipline.",
            "Simulates real match tactical execution."
        ], steps: [
            "Offense runs designated play.",
            "Defense rotates into correct formation.",
            "Play out rally to completion.",
            "Switch roles after several reps."
        ])
    ]
    
    static let gameDrills: [PracticeBlock] = [
        PracticeBlock(name: "Queen of the Court", category: .games, durationMinutes: 10, type: "team", difficulty: "beginner", imageName: "queen_of_the_court", instructions: [
            "Fast-paced competitive mini-game.",
            "Winning team moves up, losing team rotates down.",
            "Encourages aggressive but controlled play."
        ], steps: [
            "Divide players into small teams.",
            "Play short rallies (1-3 points).",
            "Winners move to queen court.",
            "Rotate continuously for 10 minutes."
        ]),
        PracticeBlock(name: "Speedball Rally Game", category: .games, durationMinutes: 10, type: "team", difficulty: "intermediate", imageName: "speedball_rally_game", instructions: [
            "Continuous rallies with rapid restarts.",
            "Forces quick transitions and communication.",
            "Improves conditioning and focus."
        ], steps: [
            "Coach initiates rally.",
            "As soon as rally ends, new ball entered.",
            "Teams must reset instantly.",
            "Play for timed intervals."
        ]),
        PracticeBlock(name: "Serve-to-Score Game", category: .games, durationMinutes: 8, type: "team", difficulty: "beginner", imageName: "serve_to_score_game", instructions: [
            "Teams can only score points on their serve.",
            "Encourages aggressive but consistent serving.",
            "Simulates real match pressure."
        ], steps: [
            "Team serves to start rally.",
            "If serving team wins rally, they score.",
            "If not, serve switches.",
            "Play to 15 or timed limit."
        ]),
        PracticeBlock(name: "Bonus Ball Game", category: .games, durationMinutes: 10, type: "team", difficulty: "intermediate", imageName: "bonus_ball_game", instructions: [
            "Certain balls are worth extra points.",
            "Forces teams to strategize and communicate.",
            "Adds fun competitive pressure."
        ], steps: [
            "Coach designates bonus balls.",
            "Winning bonus rally = 2 points.",
            "Normal rally = 1 point.",
            "Play to set score."
        ]),
        PracticeBlock(name: "Chaos Ball Game", category: .games, durationMinutes: 10, type: "team", difficulty: "advanced", imageName: "chaos_ball_game", instructions: [
            "Coach introduces random balls mid-rally.",
            "Forces players to react and communicate.",
            "Simulates unpredictable match situations."
        ], steps: [
            "Start normal rally.",
            "Coach tosses extra balls randomly.",
            "Teams must decide which ball to play.",
            "Play continues until one ball is dead."
        ]),
        PracticeBlock(name: "Mini-Court 2v2", category: .games, durationMinutes: 8, type: "team", difficulty: "beginner", imageName: "mini_court_2v2", instructions: [
            "Small-court game emphasizing ball control.",
            "Players must cover more space.",
            "Encourages creativity and smart shots."
        ], steps: [
            "Shrink court to half width.",
            "Play 2v2 rally scoring.",
            "Rotate teams every few minutes.",
            "Increase pace as players adjust."
        ]),
        PracticeBlock(name: "4v4 Transition Game", category: .games, durationMinutes: 10, type: "team", difficulty: "intermediate", imageName: "4v4_transition_game", instructions: [
            "Smaller teams force more touches per player.",
            "Emphasizes transition offense and defense.",
            "Improves communication and spacing."
        ], steps: [
            "Play 4v4 on full court.",
            "Focus on transition after each contact.",
            "Rotate players frequently.",
            "Play timed rounds."
        ]),
        PracticeBlock(name: "Serve-Receive Battle", category: .games, durationMinutes: 10, type: "team", difficulty: "intermediate", imageName: "serve_receive_battle", instructions: [
            "Teams compete to win serve-receive rallies.",
            "Focus on passing accuracy and first-ball contact.",
            "Simulates real match serve pressure."
        ], steps: [
            "Team A serves to Team B.",
            "If Team B wins rally, they earn point.",
            "If not, no point awarded.",
            "Switch roles after each round."
        ])
    ]
    
    static var allDrills: [PracticeBlock] {
        warmups + ballControlDrills + settingDrills + hittingDrills + blockingDrills + defenseDrills + serveReceiveDrills + servingDrills + teamSystemDrills + gameDrills
    }
    
    static func drills(for category: PracticeCategory) -> [PracticeBlock] {
        switch category {
        case .warmup: return warmups
        case .ballControl: return ballControlDrills
        case .setting: return settingDrills
        case .hitting: return hittingDrills
        case .blocking: return blockingDrills
        case .defense: return defenseDrills
        case .serveReceive: return serveReceiveDrills
        case .serving: return servingDrills
        case .teamSystems: return teamSystemDrills
        case .games: return gameDrills
        }
    }
    
    static func generatePractice(categories: [PracticeCategory], targetMinutes: Int = 45) -> PracticePlan {
        let categorySet = Set(categories)
        var planBlocks: [PracticeBlock] = []
        
        // Always start with 1 stretching exercise, then 1 warmup
        if !stretches.isEmpty {
            planBlocks.append(stretches.randomElement()!)
        }
        let warmupDrills = warmups.filter { $0.category == .warmup }
        if !warmupDrills.isEmpty {
            planBlocks.append(warmupDrills.randomElement()!)
        }
        
        // Add drills from selected categories
        var activeMinutes = planBlocks.reduce(0) { $0 + $1.durationMinutes }
        
        if !categorySet.isEmpty {
            for category in categorySet {
                let categoryDrills = drills(for: category)
                let count = min(3, categoryDrills.count)
                let selected = Array(categoryDrills.shuffled().prefix(count))
                
                for drill in selected {
                    guard activeMinutes + drill.durationMinutes <= targetMinutes else { continue }
                    planBlocks.append(drill)
                    activeMinutes += drill.durationMinutes
                }
            }
        } else {
            // If no categories selected, add variety from all
            let allCategories = PracticeCategory.allCases.filter { $0 != .warmup && $0 != .games }
            for category in allCategories.shuffled().prefix(4) {
                let categoryDrills = drills(for: category)
                if let drill = categoryDrills.first {
                    guard activeMinutes + drill.durationMinutes <= targetMinutes else { continue }
                    planBlocks.append(drill)
                    activeMinutes += drill.durationMinutes
                }
            }
        }
        
        // Fill remaining time if needed
        if activeMinutes < targetMinutes - 5 {
            let remainingCategories = PracticeCategory.allCases.filter { $0 != .warmup }
            for category in remainingCategories.shuffled() {
                let categoryDrills = drills(for: category)
                for drill in categoryDrills.shuffled() {
                    guard activeMinutes + drill.durationMinutes <= targetMinutes else { continue }
                    planBlocks.append(drill)
                    activeMinutes += drill.durationMinutes
                    if activeMinutes >= targetMinutes - 5 { break }
                }
            }
        }
        
        // Insert water breaks
        planBlocks = insertWaterBreaks(in: planBlocks)
        
        let focusName = categories.map { $0.rawValue }.joined(separator: ", ")
        return PracticePlan(name: "Team Practice: \(focusName.isEmpty ? "Mixed Skills" : focusName)", focus: focusName.isEmpty ? "balanced" : focusName.lowercased(), blocks: planBlocks)
    }
    
    static func insertWaterBreaks(in blocks: [PracticeBlock]) -> [PracticeBlock] {
        var result: [PracticeBlock] = []
        var minutesSinceBreak = 0
        
        for (index, block) in blocks.enumerated() {
            result.append(block)
            minutesSinceBreak += block.durationMinutes
            let hasWorkoutRemaining = index < blocks.count - 1
            if hasWorkoutRemaining && minutesSinceBreak >= 15 {
                let waterBreak = PracticeBlock(
                    name: "Water Break",
                    category: .warmup,
                    durationMinutes: 2,
                    type: "both",
                    difficulty: "beginner",
                    imageName: "warmup",
                    instructions: [
                        "Drink water or electrolytes.",
                        "Walk slowly and control your breathing.",
                        "Restart only when your legs feel responsive."
                    ],
                    steps: [
                        "Hydrate with water or sports drink.",
                        "Walk around to keep muscles loose.",
                        "Check in with teammates.",
                        "Resume when ready."
                    ]
                )
                result.append(waterBreak)
                minutesSinceBreak = 0
            }
        }
        
        if result.last?.name == "Water Break" {
            result.removeLast()
        }
        
        return result
    }
}

// MARK: - UserDefaults helpers for saved practices
private let savedPracticesKey = "savedPractices"

private func loadSavedPractices() -> [PracticePlan] {
    guard let data = UserDefaults.standard.data(forKey: savedPracticesKey) else { return [] }
    return (try? JSONDecoder().decode([PracticePlan].self, from: data)) ?? []
}

private func persistSavedPractices(_ plans: [PracticePlan]) {
    let data = (try? JSONEncoder().encode(plans)) ?? Data()
    UserDefaults.standard.set(data, forKey: savedPracticesKey)
}

// MARK: - Blended card modifier
private struct BlendedCard: ViewModifier {
    func body(content: Content) -> some View {
        content.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.black.opacity(0.5)).cornerRadius(16)
    }
}
private extension View { func blendedCard() -> some View { modifier(BlendedCard()) } }

// MARK: - Segmented Picker
private struct SegmentedPicker: View {
    @Binding var selection: Int
    let options: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button(action: { selection = index }) {
                    Text(option)
                        .font(.caption.bold())
                        .foregroundColor(selection == index ? .pink : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == index ? Color.black.opacity(0.3) : Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                if index < options.count - 1 {
                    Divider().background(Color.white.opacity(0.15)).frame(height: 20)
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pink.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Practice Hub View
struct PracticeHubView: View {
    @State private var generatedPractice: PracticePlan?
    @State private var showingSaved = false
    @State private var showingDrillBuilder = false
    @State private var practiceMode: Int = 0 // 0: Auto Generate, 1: Custom Build
    @State private var selectedCategories: Set<PracticeCategory> = []
    @State private var customDrills: [PracticeBlock] = []
    @State private var durationMinutes: Int = 60
    @State private var savedPractices: [PracticePlan] = []
    @Environment(\.dismiss) private var dismiss
    
    private var modeOptions = ["Auto Generate", "Custom Build"]
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image("background").resizable().scaledToFill().ignoresSafeArea().opacity(0.3)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer(minLength: 80)
                            
                            HStack {
                                Button(action: { dismiss() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.pink)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.4))
                                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.pink.opacity(0.5), lineWidth: 1)))
                                }.buttonStyle(PlainButtonStyle())
                                Spacer()
                            }.padding(.top, 50)

                            Text("Build a practice for your team. Select focus categories for the system to generate a plan, or custom build your own session.")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Spacer(minLength: 20)
                            
                            SegmentedPicker(selection: $practiceMode, options: modeOptions)
                            
                            durationControl
                            
                            if practiceMode == 0 {
                                categorySelectionCard
                            } else {
                                customBuilderCard
                            }
                            
                            HStack(spacing: 10) {
                                Button("Generate Practice") { generatePractice() }
                                    .buttonStyle(PracticeButtonStyle(color: .cyan, foreground: .black))
                                    .disabled(practiceMode == 1 && customDrills.isEmpty)
                                
                                Button("Saved Practices (\(savedPractices.count))") { showingSaved = true }
                                    .buttonStyle(PracticeButtonStyle(color: .purple, foreground: .white))
                            }
                        }.padding(.horizontal, 24)
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(item: $generatedPractice) { practice in
                    PracticeRunView(practice: practice, onSave: addSavedPractice)
                }
                .sheet(isPresented: $showingSaved) {
                    SavedPracticesView(savedPractices: $savedPractices, selectedPractice: $generatedPractice)
                }
                .sheet(isPresented: $showingDrillBuilder) {
                    DrillLibraryView(selectedDrills: $customDrills, targetMinutes: durationMinutes)
                }
            }
            .onAppear { savedPractices = loadSavedPractices() }
        }
    }
    
    private var durationControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration: \(durationMinutes) min").font(.caption.bold()).foregroundColor(.white)
            Slider(value: Binding(get: { Double(durationMinutes) }, set: { durationMinutes = Int($0) }), in: 30...120, step: 15).tint(.cyan)
        }.blendedCard()
    }
    
    private var categorySelectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Categories").font(.headline).foregroundColor(.pink)
            
            Button(action: {
                if selectedCategories.count == PracticeCategory.allCases.filter({ $0 != .games }).count {
                    selectedCategories.removeAll()
                } else {
                    selectedCategories = Set(PracticeCategory.allCases.filter { $0 != .games })
                }
            }) {
                Text(selectedCategories.count == PracticeCategory.allCases.filter({ $0 != .games }).count ? "Deselect All" : "Select All")
                    .font(.caption.bold()).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.3)).cornerRadius(10)
            }.buttonStyle(PlainButtonStyle())
            
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(PracticeCategory.allCases.filter { $0 != .games }) { cat in
                        let isSelected = selectedCategories.contains(cat)
                        Button(action: { 
                            if isSelected { selectedCategories.remove(cat) } 
                            else { selectedCategories.insert(cat) } 
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon).font(.caption)
                                Text(cat.rawValue).font(.caption.bold())
                            }
                            .foregroundColor(isSelected ? .black : cat.color)
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .background(isSelected ? cat.color : Color.clear).cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(cat.color.opacity(0.6), lineWidth: 1.5))
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }.blendedCard()
    }
    
    private var customBuilderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Custom Drill Builder").font(.headline).foregroundColor(.pink)
            
            if customDrills.isEmpty {
                Text("No drills selected yet. Tap the button below to browse the drill library.")
                    .font(.caption).foregroundColor(.gray)
            } else {
                Text("\(customDrills.count) drills selected • \(customDrills.reduce(0) { $0 + $1.durationMinutes }) min total")
                    .font(.caption).foregroundColor(.cyan)
                
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(customDrills) { drill in
                            HStack {
                                Image(systemName: drill.category.icon).foregroundColor(drill.category.color).font(.caption)
                                Text(drill.name).font(.caption).foregroundColor(.white)
                                Spacer()
                                Text("\(drill.durationMinutes) min").font(.caption2).foregroundColor(.gray)
                                Button(action: { customDrills.removeAll { $0.id == drill.id } }) {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.red).font(.caption)
                                }.buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.white.opacity(0.08)).cornerRadius(6)
                        }
                    }
                }
                .frame(maxHeight: 120)
            }
            
            Button(action: { showingDrillBuilder = true }) {
                Text(customDrills.isEmpty ? "Browse Drill Library" : "Edit Drills")
                    .font(.caption.bold()).foregroundColor(.black).padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.purple).cornerRadius(10)
            }.buttonStyle(PlainButtonStyle())
        }.blendedCard()
    }
    
    private func generatePractice() {
        if practiceMode == 0 {
            generatedPractice = VolleyballPracticeLibrary.generatePractice(categories: Array(selectedCategories), targetMinutes: durationMinutes)
        } else {
            let totalMinutes = customDrills.reduce(0) { $0 + $1.durationMinutes }
            generatedPractice = PracticePlan(name: "Custom Practice", focus: "custom", blocks: customDrills)
        }
    }
    
    private func addSavedPractice(_ practice: PracticePlan) {
        savedPractices.append(practice)
        persistSavedPractices(savedPractices)
    }
}

// MARK: - Practice Run View
struct PracticeRunView: View {
    let practice: PracticePlan
    let onSave: (PracticePlan) -> Void
    @State private var selectedBlock: PracticeBlock?
    @State private var saveName = ""
    @State private var lastSavedName: String?
    @State private var showSaveConfirm = false
    @State private var timers: [UUID: Int] = [:]
    @State private var running: Set<UUID> = []
    @State private var completedBlocks: Set<UUID> = []
    @State private var allBlocksCompleted = false
    @State private var currentBlockIndex: Int = 0
    @State private var previewData: SchedulePreviewData?
    @State private var showHistory = false
    @State private var sessionId: UUID = UUID()
    @State private var savedCompletedBlocks: [CompletedBlock] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()
            mainContent
        }
        .navigationTitle("Practice Session").navigationBarTitleDisplayMode(.inline)
        .onAppear { resetTimers() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in tickTimers() }
        .sheet(item: $selectedBlock) { block in PracticeBlockDetailView(block: block) }
        .overlay(saveConfirmationOverlay)
    }
    
    @ViewBuilder private var mainContent: some View {
        VStack(spacing: 12) {
            summary
            blocksList
            actionButtons
        }
    }
    
    @ViewBuilder private var blocksList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(Array(practice.blocks.enumerated()), id: \.element.id) { index, block in
                    if block.name == "Water Break" {
                        waterBreakRow(block)
                    } else {
                        blockRow(block)
                    }
                }
            }.padding(.horizontal)
        }
    }
    
    private func blockRow(_ block: PracticeBlock) -> some View {
        let isCompleted = completedBlocks.contains(block.id)
        return PracticeScheduleRow(block: block, seconds: timers[block.id] ?? block.durationMinutes * 60,
            isRunning: running.contains(block.id),
            onTap: { selectedBlock = block },
            onPlay: { running.insert(block.id) },
            onPause: { running.remove(block.id) },
            onReset: {
                timers[block.id] = block.durationMinutes * 60
                running.remove(block.id)
                completedBlocks.remove(block.id)
            },
            isCompleted: isCompleted)
    }
    
    @ViewBuilder private var actionButtons: some View {
        HStack(spacing: 10) {
            Button("Save") { showSaveSheet() }.buttonStyle(PracticeButtonStyle(color: .cyan, foreground: .black))
            Button("Export Schedule") { exportPDF() }.buttonStyle(PracticeButtonStyle(color: .yellow, foreground: .black))
            Button("History") { showHistory = true }
                .buttonStyle(PracticeButtonStyle(color: .pink, foreground: .white))
        }.padding(.horizontal).padding(.bottom, 8)
        .sheet(item: $previewData) { data in
            SchedulePreview(title: data.title, subtitle: data.subtitle, blocks: data.blocks)
        }
        .sheet(isPresented: $showHistory) {
            SessionHistoryView()
        }
    }
    
    @ViewBuilder private var saveConfirmationOverlay: some View {
        if showSaveConfirm, let name = lastSavedName {
            VStack { Spacer(); Text("✓ Saved: \(name)").font(.caption.bold()).foregroundColor(.green).padding().background(.black.opacity(0.8)).cornerRadius(12).padding(.bottom, 60) }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showSaveConfirm)
        }
    }
    
    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(practice.name).font(.title3.bold()).foregroundColor(.white)
            Text("\(practice.blocks.count) blocks • \(practice.totalMinutes) min • Focus: \(practice.focus.capitalized)").font(.caption).foregroundColor(.gray)
        }.frame(maxWidth: .infinity, alignment: .leading).padding().background(Color.blue.opacity(0.16)).cornerRadius(14).padding(.horizontal)
    }
    
    private func waterBreakRow(_ block: PracticeBlock) -> some View {
        Text("WATER BREAK - \(block.durationMinutes) MIN")
            .font(.headline)
            .foregroundColor(Color(red: 1.0, green: 0.08, blue: 0.58))
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(red: 1.0, green: 0.08, blue: 0.58).opacity(0.16))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 1.0, green: 0.08, blue: 0.58), lineWidth: 1))
    }
    
    private func resetTimers() {
        timers.removeAll()
        for block in practice.blocks where block.name != "Water Break" {
            timers[block.id] = block.durationMinutes * 60
        }
    }
    
    private func tickTimers() {
        for id in running {
            guard let value = timers[id], value > 0 else { continue }
            timers[id] = value - 1
            if value - 1 == 0 {
                running.remove(id)
                completedBlocks.insert(id)
                AlarmHelper.playAlarm()
                if let currentIndex = practice.blocks.firstIndex(where: { $0.id == id }),
                   currentIndex < practice.blocks.count - 1 {
                    currentBlockIndex = currentIndex + 1
                }
                saveCompletedBlock(id)
                checkAllComplete()
            }
        }
    }
    
    private func saveCompletedBlock(_ blockId: UUID) {
        guard let block = practice.blocks.first(where: { $0.id == blockId }), block.name != "Water Break" else { return }
        let completedBlock = CompletedBlock(id: block.id, name: block.name, category: block.category.rawValue, durationMinutes: block.durationMinutes, completedAt: Date())
        savedCompletedBlocks.append(completedBlock)
        let allCategories = Array(Set(savedCompletedBlocks.map { $0.category }))
        let totalSoFar = savedCompletedBlocks.reduce(0) { $0 + $1.durationMinutes }
        let session = CompletedSession(
            id: sessionId,
            type: .practice,
            name: practice.name,
            focus: practice.focus,
            completedDate: Date(),
            totalMinutes: totalSoFar,
            blocks: savedCompletedBlocks,
            categories: allCategories
        )
        var allSessions = SessionHistoryManager.loadSessions()
        allSessions.removeAll { $0.id == sessionId }
        allSessions.append(session)
        SessionHistoryManager.persistSessions(allSessions)
    }
    
    private func checkAllComplete() {
        let nonWaterBlocks = practice.blocks.filter { $0.name != "Water Break" }
        let allDone = nonWaterBlocks.allSatisfy { completedBlocks.contains($0.id) }
        if allDone && !allBlocksCompleted {
            allBlocksCompleted = true
        }
    }
    
    private func showSaveSheet() {
        saveName = practice.name
        lastSavedName = nil
        showSaveConfirm = false
        let plan = PracticePlan(id: UUID(), name: saveName, focus: practice.focus, createdAt: Date(), blocks: practice.blocks)
        onSave(plan)
        lastSavedName = saveName
        showSaveConfirm = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSaveConfirm = false }
    }

    private func exportPDF() {
        let blocks: [ScheduleBlockInfo] = practice.blocks.map { pb in
            let isWB = pb.name == "Water Break"
            return ScheduleBlockInfo(
                name: pb.name,
                durationMinutes: pb.durationMinutes,
                categoryName: isWB ? "Water Break" : pb.category.rawValue,
                color: UIColor(pb.category.color),
                isWaterBreak: isWB
            )
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let subtitle = "Practice Plan • Focus: \(practice.focus.capitalized) • Generated \(formatter.string(from: practice.createdAt))"
        previewData = SchedulePreviewData(title: practice.name, subtitle: subtitle, blocks: blocks)
    }
}

struct PracticeScheduleRow: View {
    let block: PracticeBlock; let seconds: Int; let isRunning: Bool
    let onTap: () -> Void; let onPlay: () -> Void; let onPause: () -> Void; let onReset: () -> Void
    var isCompleted: Bool = false
    var body: some View {
        HStack(spacing: 10) {
            Button(action: onTap) { PracticeBlockRow(block: block, compact: false) }.buttonStyle(.plain)
            Spacer(minLength: 4)
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            } else {
                VStack(spacing: 4) {
                    Text(format(seconds)).font(.headline.monospacedDigit()).foregroundColor(Color(red: 1.0, green: 0.08, blue: 0.58))
                    HStack(spacing: 8) {
                        Button("Play", action: onPlay).disabled(isRunning)
                        Button("Pause", action: onPause).disabled(!isRunning)
                        Button("Reset", action: onReset)
                    }
                    .font(.caption.bold()).foregroundColor(.white)
                }
            }
        }.padding(10).background(Color.white.opacity(0.08)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(
            isCompleted ? Color.green : block.category.color.opacity(isRunning ? 1 : 0.45),
            lineWidth: isCompleted ? 2 : 1))
    }
    private func format(_ seconds: Int) -> String { "\(seconds / 60):\(String(format: "%02d", seconds % 60))" }
}

struct PracticeBlockRow: View {
    let block: PracticeBlock; let compact: Bool
    var body: some View {
        HStack(spacing: 10) {
            Image(block.imageName).resizable().scaledToFit().frame(width: compact ? 44 : 56, height: compact ? 44 : 56).cornerRadius(8)
            VStack(alignment: .leading, spacing: 3) {
                Text(block.name).font(compact ? .subheadline.bold() : .headline).foregroundColor(.white)
                Text("\(block.durationMinutes) min • \(block.category.rawValue) • \(block.difficulty.capitalized)").font(.caption).foregroundColor(.gray)
            }; Spacer()
        }
    }
}

struct PracticeBlockDetailView: View {
    let block: PracticeBlock
    @Environment(\.dismiss) private var dismiss
    @State private var showImageZoom = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Image(block.imageName).resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: 240).background(Color.black.opacity(0.08)).cornerRadius(16)
                    .onTapGesture { showImageZoom = true }
                Text(block.name).font(.title2.bold())
                HStack(spacing: 12) {
                    Text("\(block.durationMinutes) min").foregroundColor(.cyan)
                    Text("•").foregroundColor(.gray)
                    Text(block.category.rawValue).foregroundColor(block.category.color)
                    Text("•").foregroundColor(.gray)
                    Text(block.difficulty.capitalized).foregroundColor(.yellow)
                }
                Text("Instructions").font(.headline).foregroundColor(.pink)
                ForEach(block.instructions, id: \.self) { line in Text("• \(line)").frame(maxWidth: .infinity, alignment: .leading) }
                Text("Steps").font(.headline).foregroundColor(.pink)
                ForEach(Array(block.steps.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)").frame(maxWidth: .infinity, alignment: .leading)
                }
                Button("Close") { dismiss() }.buttonStyle(PracticeButtonStyle(color: Color(red: 1.0, green: 0.08, blue: 0.58), foreground: .white))
            }.padding()
        }
        .fullScreenCover(isPresented: $showImageZoom) {
            ZoomableImageView(imageName: block.imageName)
        }
    }
}

// MARK: - Drill Library View
struct DrillLibraryView: View {
    @Binding var selectedDrills: [PracticeBlock]
    let targetMinutes: Int
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: PracticeCategory? = nil
    
    private var filteredDrills: [PracticeBlock] {
        if let category = selectedCategory {
            return VolleyballPracticeLibrary.drills(for: category)
        }
        return VolleyballPracticeLibrary.allDrills
    }
    
    private var selectedMinutes: Int { selectedDrills.reduce(0) { $0 + $1.durationMinutes } }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()
                VStack(spacing: 12) {
                    HStack {
                        Text("Drill Library").font(.title2.bold()).foregroundColor(.pink)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    HStack {
                        Image(systemName: "clock.fill").foregroundColor(.cyan).font(.caption)
                        Text("\(selectedMinutes) min selected of \(targetMinutes) min target")
                            .font(.caption.bold()).foregroundColor(.white)
                        Spacer()
                    }
                    .padding().background(Color.black.opacity(0.4)).cornerRadius(12)
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button(action: { selectedCategory = nil }) {
                                Text("All").font(.caption.bold())
                                    .foregroundColor(selectedCategory == nil ? .black : .white)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(selectedCategory == nil ? Color.cyan : Color.clear).cornerRadius(20)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.6), lineWidth: 1.5))
                            }.buttonStyle(PlainButtonStyle())
                            
                            ForEach(PracticeCategory.allCases.filter { $0 != .games }) { cat in
                                let isSelected = selectedCategory == cat
                                Button(action: { selectedCategory = isSelected ? nil : cat }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: cat.icon).font(.caption2)
                                        Text(cat.rawValue).font(.caption.bold())
                                    }
                                    .foregroundColor(isSelected ? .black : cat.color)
                                    .padding(.horizontal, 10).padding(.vertical, 8)
                                    .background(isSelected ? cat.color : Color.clear).cornerRadius(20)
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(cat.color.opacity(0.6), lineWidth: 1.5))
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredDrills) { drill in
                                let isSelected = selectedDrills.contains { $0.id == drill.id }
                                DrillCard(drill: drill, isSelected: isSelected) {
                                    if isSelected {
                                        selectedDrills.removeAll { $0.id == drill.id }
                                    } else {
                                        selectedDrills.append(drill)
                                    }
                                }
                            }
                        }.padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

struct DrillCard: View {
    let drill: PracticeBlock
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: drill.category.icon).foregroundColor(drill.category.color)
                    Text(drill.name).font(.subheadline.bold()).foregroundColor(.white)
                    Spacer()
                    Text("\(drill.durationMinutes) min").font(.caption2).foregroundColor(.gray)
                }
                HStack(spacing: 8) {
                    Text(drill.difficulty.capitalized).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(Color.yellow.opacity(0.3)).cornerRadius(4)
                    Text(drill.type.capitalized).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(Color.blue.opacity(0.3)).cornerRadius(4)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? drill.category.color.opacity(0.25) : Color(red: 0.14, green: 0.14, blue: 0.16)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(drill.category.color.opacity(isSelected ? 0.8 : 0.3), lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Saved Practices View
struct SavedPracticesView: View {
    @Binding var savedPractices: [PracticePlan]
    @Binding var selectedPractice: PracticePlan?
    @Environment(\.dismiss) private var dismiss
    @State private var renameTarget: PracticePlan?
    @State private var renameName: String = ""
    @State private var showingRenameAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().opacity(0.3)
                VStack(spacing: 12) {
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left"); Text("Back")
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.pink)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.4))
                                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.pink.opacity(0.5), lineWidth: 1)))
                        }.buttonStyle(PlainButtonStyle())
                        Spacer()
                    }.padding(.top, 40)
                    Text("Saved Practices (\(savedPractices.count))").font(.title2.bold()).foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(savedPractices) { practice in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .top, spacing: 10) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(practice.name).foregroundColor(.white).font(.headline)
                                            Text("\(practice.totalMinutes) min • \(practice.focus.capitalized)").foregroundColor(.gray).font(.caption)
                                            Text("\(practice.blocks.count) drills • Saved: \(practice.createdAt, style: .date)").font(.caption2).foregroundColor(.gray.opacity(0.6))
                                        }
                                        Spacer()
                                    }
                                    HStack(spacing: 12) {
                                        Spacer()
                                        Button("Rename") {
                                            renameTarget = practice
                                            renameName = practice.name
                                            showingRenameAlert = true
                                        }.font(.caption.bold()).foregroundColor(.cyan).buttonStyle(PlainButtonStyle())
                                        Button("Delete", role: .destructive) {
                                            if let idx = savedPractices.firstIndex(where: { $0.id == practice.id }) {
                                                savedPractices.remove(at: idx)
                                                persistSavedPractices(savedPractices)
                                            }
                                        }.font(.caption.bold()).foregroundColor(.red).buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.4)))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPractice = practice
                                }
                            }
                        }.padding(.horizontal, 16)
                    }.frame(maxHeight: 520)
                }.padding(.horizontal, 24)
            }
            .navigationBarHidden(true)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .alert("Rename Practice", isPresented: $showingRenameAlert) {
                TextField("Name", text: $renameName)
                Button("Cancel", role: .cancel) { renameTarget = nil }
                Button("Save") {
                    if let target = renameTarget, let idx = savedPractices.firstIndex(where: { $0.id == target.id }) {
                        savedPractices[idx] = PracticePlan(id: target.id, name: renameName, focus: target.focus, createdAt: target.createdAt, blocks: target.blocks)
                        persistSavedPractices(savedPractices)
                    }
                    renameTarget = nil
                }
            }
        }
    }
}

// MARK: - Practice Button Style
struct PracticeButtonStyle: ButtonStyle {
    let color: Color
    let foreground: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold()).foregroundColor(foreground)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1.0)).cornerRadius(10)
    }
}