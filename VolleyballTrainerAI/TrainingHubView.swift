import SwiftUI
import SwiftData
import AudioToolbox

// MARK: - Enums
enum TrainingCategory: String, Codable, CaseIterable, Identifiable {
    case warmup = "Warmup"
    case stretching = "Stretching"
    case agility = "Agility"
    case plyometrics = "Plyometrics"
    case volleyball = "Volleyball Skills"
    case strength = "Strength"
    case waterBreak = "Water Break"

    var id: String { rawValue }
    var color: Color {
        switch self {
        case .warmup, .stretching: return .green
        case .agility: return .cyan
        case .plyometrics: return .orange
        case .volleyball: return .yellow
        case .strength: return .purple
        case .waterBreak: return Color(red: 1.0, green: 0.08, blue: 0.58)
        }
    }
    var icon: String {
        switch self {
        case .warmup: return "flame.fill"
        case .stretching: return "figure.flexibility"
        case .agility: return "figure.run"
        case .plyometrics: return "figure.jump"
        case .volleyball: return "volleyball.fill"
        case .strength: return "dumbbell.fill"
        case .waterBreak: return "drop.fill"
        }
    }
}

enum TrainingIntensity: String, Codable { case low, medium, high
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

enum TrainingMode: String, Codable, CaseIterable, Identifiable {
    case aiGenerated = "AI Generated"
    case selectCategory = "Select Category"
    case buildYourOwn = "Build Your Own"
    var id: String { rawValue }
}

// MARK: - Models
struct TrainingBlock: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let category: TrainingCategory
    let durationMinutes: Int
    let intensity: TrainingIntensity
    let imageName: String
    let focusTags: [String]
    let instructions: [String]

    init(id: UUID = UUID(), name: String, category: TrainingCategory, durationMinutes: Int, intensity: TrainingIntensity, imageName: String, focusTags: [String], instructions: [String]) {
        self.id = id; self.name = name; self.category = category; self.durationMinutes = durationMinutes; self.intensity = intensity; self.imageName = imageName; self.focusTags = focusTags; self.instructions = instructions
    }

    static func waterBreak(minutes: Int = 2) -> TrainingBlock {
        TrainingBlock(name: "Water Break", category: .waterBreak, durationMinutes: minutes, intensity: .low, imageName: "icon", focusTags: ["recovery"], instructions: [
            "Hydrate with water or electrolytes.",
            "Control your breathing — slow, deep inhales.",
            "Re-enter your next block with intent and focus."
        ])
    }
}

struct TrainingPlan: Identifiable, Hashable {
    let id: UUID; var name: String; var focus: String; var createdAt: Date; var blocks: [TrainingBlock]
    var totalMinutes: Int { blocks.reduce(0) { $0 + $1.durationMinutes } }
}

@Model final class SavedTrainingPlan {
    var id: UUID; var name: String; var focus: String; var createdAt: Date; var totalMinutes: Int; var blocksJSON: String
    init(name: String, focus: String, blocks: [TrainingBlock]) {
        self.id = UUID(); self.name = name; self.focus = focus; self.createdAt = Date()
        self.totalMinutes = blocks.reduce(0) { $0 + $1.durationMinutes }
        let data = (try? JSONEncoder().encode(blocks)) ?? Data()
        self.blocksJSON = String(data: data, encoding: .utf8) ?? "[]"
    }
    var blocks: [TrainingBlock] {
        guard let data = blocksJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([TrainingBlock].self, from: data)) ?? []
    }
}

// MARK: - World-Class Training Library
enum VolleyballTrainingLibrary {

    static let warmups: [TrainingBlock] = [
        TrainingBlock(name: "Court Run + Dynamic Prep", category: .warmup, durationMinutes: 4, intensity: .low, imageName: "stretch_court_run", focusTags: ["warmup", "movement"], instructions: [
            "Begin with a light jog along the court perimeter, accelerating gradually to 60 % of max speed.",
            "Integrate dynamic movements: high knees, butt kicks, carioca, and walking lunges — 15 yards each.",
            "Maintain upright posture, controlled breathing, and active arm drive throughout the sequence."
        ]),
        TrainingBlock(name: "Shoulder Prep Flow", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_shoulder_prep", focusTags: ["armSwing", "shoulder", "armExtension"], instructions: [
            "Perform arm circles (forward & backward), 10 reps each direction, gradually increasing range of motion.",
            "Cross-body shoulder stretch — pull the elbow across your chest and hold for 15 seconds per side.",
            "Complete 10 slow, deliberate shadow swings, focusing on high elbow position and full arm extension."
        ]),
        TrainingBlock(name: "Hip + Ankle Activation", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_hip_mobility", focusTags: ["jump", "approach", "mobility"], instructions: [
            "World's greatest stretch: lunge forward, drop the back knee, rotate the torso open — 5 breaths per side.",
            "Ankle rocks: sit back on your heels, lift toes, then rock forward onto the balls of your feet — 12 reps.",
            "Body-weight squat with a 3-second pause at the bottom, keeping knees tracking over toes."
        ]),
        TrainingBlock(name: "Pre-Jump Leg Prep", category: .warmup, durationMinutes: 3, intensity: .low, imageName: "stretch_prejump", focusTags: ["plyo", "jump"], instructions: [
            "Low pogo hops — keep ankles stiff, rebound off the floor as quickly as possible for 30 seconds.",
            "Two-step approach footwork without jumping — accelerate, plant, and close the block 6 times.",
            "Finish with two soft landings from a low box (6-12 inches), holding the landing position for 2 seconds each."
        ])
    ]

    static let volleyballDrills: [TrainingBlock] = [
        TrainingBlock(name: "Arm Swing Wall Spike", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_wall_spike", focusTags: ["armSwing", "armExtension", "powerTransfer"], instructions: [
            "Stand 6-8 feet from a solid wall with a ball in your hitting hand.",
            "Toss the ball slightly in front of your hitting shoulder, reach high, and snap through the ball with a fully extended arm.",
            "Finish across your body with your thumb pointing down — repeat 15 reps, then switch sides."
        ]),
        TrainingBlock(name: "Hitting Arm Swing Mechanics", category: .volleyball, durationMinutes: 10, intensity: .medium, imageName: "hitting_arm_swing", focusTags: ["armSwing", "armExtension"], instructions: [
            "Assume the loaded position: hitting elbow drawn back behind the ear, shoulders perpendicular to the net.",
            "Initiate the swing by rotating the hips and core, leading with the elbow before the hand.",
            "Contact the ball at full arm extension in front of the body — freeze the follow-through and verify the shoulder-to-wrist line."
        ]),
        TrainingBlock(name: "Approach Angle Reps", category: .volleyball, durationMinutes: 9, intensity: .medium, imageName: "hitting_approach_angle", focusTags: ["approach", "timing", "armSwing"], instructions: [
            "Mark a starting point 10 feet from the net and a target contact zone near the antenna.",
            "Execute a controlled 3-step approach (left-right-left for right-handers), accelerating into the final two steps.",
            "Open the hips on the plant step and attack through the ball at the highest reachable point."
        ]),
        TrainingBlock(name: "Max Jump Touches", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "hitting_max_jump", focusTags: ["jump", "explosiveness"], instructions: [
            "Perform an approach jump to a safe wall target placed at your maximum reach plus 4 inches.",
            "Swing both arms aggressively into the takeoff, generating maximum vertical displacement.",
            "Land softly and quietly with knees bent, absorbing the impact — reset fully before the next rep."
        ]),
        TrainingBlock(name: "Approach Rhythm + Timing", category: .volleyball, durationMinutes: 10, intensity: .medium, imageName: "hitting_timing", focusTags: ["timing", "approach", "contact"], instructions: [
            "Have a partner toss a high ball from the setter position — start your approach as the ball reaches its apex.",
            "Delay your first step slightly so the final two steps coincide with the ball's descent.",
            "Contact the ball at peak reach — aim for 10 consecutive quality contacts before switching."
        ]),
        TrainingBlock(name: "Cross-Court Target Hits", category: .volleyball, durationMinutes: 10, intensity: .medium, imageName: "hitting_cross_court", focusTags: ["accuracy", "armSwing", "vision"], instructions: [
            "Place a target (cone or mat) in the deep cross-court zone, 3 feet inside the sideline.",
            "Open your hitting shoulder toward the target and finish with a thumb-down motion across your body.",
            "Track makes vs. misses — maintain at least a 70 % accuracy rate before progressing."
        ]),
        TrainingBlock(name: "Line Shot Precision", category: .volleyball, durationMinutes: 9, intensity: .medium, imageName: "hitting_line_shot", focusTags: ["accuracy", "vision", "armSwing"], instructions: [
            "Set a target in the deep line zone, 2 feet inside the sideline and 5 feet from the end line.",
            "Approach with a slightly closed shoulder angle, contacting the ball on the outside seam for directional control.",
            "Snap the wrist firmly to drive the ball down the line — repeat until you hit the target zone 8 out of 10 times."
        ]),
        TrainingBlock(name: "High Ball Adjustments", category: .volleyball, durationMinutes: 9, intensity: .medium, imageName: "hitting_high_ball", focusTags: ["timing", "approach", "jump"], instructions: [
            "Receive a high, deep set (15-18 feet above the net). Track the ball trajectory from the moment it leaves the setter's hands.",
            "Widen your approach and delay your jump — wait until the ball has begun its descent before initiating the final two steps.",
            "Contact with a full arm extension and a high wrist snap — aim for deep middle of the court."
        ]),
        TrainingBlock(name: "Quick Set Connection", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "hitting_quick_set", focusTags: ["timing", "approach", "reaction"], instructions: [
            "With a setter, work on a 1- or 3-tempo quick set. The hitter must be in the air before the setter releases the ball.",
            "Focus on a tight, explosive two-step approach and a fast arm swing — the entire sequence should take under 1.5 seconds.",
            "Communicate with the setter after each rep — adjust tempo and location based on feedback."
        ]),
        TrainingBlock(name: "Back Row Attack", category: .volleyball, durationMinutes: 9, intensity: .medium, imageName: "hitting_back_row", focusTags: ["approach", "power", "jump"], instructions: [
            "Start behind the 10-foot (3-meter) line. Take a full three-step approach, jumping from behind the attack line.",
            "Contact the ball at its highest point, keeping your shoulders slightly open to the target.",
            "Drive through the ball with hip rotation — land and immediately transition back to base defense."
        ]),
        TrainingBlock(name: "Block Vision & Read", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_block_vision", focusTags: ["blocking", "vision", "reaction"], instructions: [
            "Stand in a ready position at the net with hands at shoulder height. Watch the hitter's approach angle and shoulder line.",
            "Jump slightly after the hitter leaves the floor — penetrate the hands across the net at the last moment.",
            "Aim to close the block to the hitter's strongest hitting angle — communicate with your court defender pre-play."
        ]),
        TrainingBlock(name: "Read & React Blocking", category: .volleyball, durationMinutes: 9, intensity: .high, imageName: "hitting_read_block", focusTags: ["blocking", "vision", "reaction"], instructions: [
            "Start at the net with a partner simulating different attack approaches (cross, line, quick).",
            "Read the hitter's body language — shoulder angle, arm speed, and approach trajectory determine your block position.",
            "Lock out your arms on the block and keep your thumbs angled inward to deflect balls back into the court."
        ]),
        TrainingBlock(name: "Roll Shot & Tip Control", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_roll_shot", focusTags: ["contact", "accuracy", "vision"], instructions: [
            "Stand 6 feet from the net. Toss the ball high and approach with controlled speed — do not overswing.",
            "Instead of a full arm swing, roll your hand over the top of the ball with a soft wrist snap, creating topspin.",
            "Aim the shot to land in the deep corners — alternate between deep cross and deep line for 10 reps each."
        ]),
        TrainingBlock(name: "Slide Attack Timing", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_slide", focusTags: ["approach", "timing", "jump"], instructions: [
            "Start wide at the 10-foot line on the left side (for right-handers). Take a two-step slide approach (right-left).",
            "The setter delivers a back-set to the right antenna — jump off both feet and reach for the ball, hitting with a sweeping arm motion.",
            "Aim for the deep right corner — land, pivot, and transition immediately to a ready position."
        ]),
        TrainingBlock(name: "Tip & Tool Block", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_tool_block", focusTags: ["contact", "vision", "accuracy"], instructions: [
            "Approach as if for a full swing, but at the last moment pull back and place a soft tip over or around the block.",
            "Aim for the deep corners or the antenna — the goal is to make the ball land softly in open court space.",
            "Practice varying the height and angle of your tip so the defense cannot read your intent."
        ]),
        TrainingBlock(name: "Transition Attack", category: .volleyball, durationMinutes: 9, intensity: .high, imageName: "hitting_transition", focusTags: ["transition", "reaction", "agility"], instructions: [
            "Start in a defensive base position. On a partner's command, react to a simulated dig and immediately transition to an approach.",
            "Find the setter early — use a three-step approach with your eyes tracking the ball the entire time.",
            "Attack with intent, then immediately decelerate and return to a ready defensive stance."
        ]),
        TrainingBlock(name: "Game-Situation Hitting", category: .volleyball, durationMinutes: 12, intensity: .high, imageName: "hitting_game_sim", focusTags: ["gameSim", "transition", "power"], instructions: [
            "Simulate a live rally: free ball → set → hit. Your partner or coach initiates with a forearm pass from the back court.",
            "Read the set early, adjust your approach speed, and execute a high-velocity attack to a specified zone.",
            "After each hit, immediately transition to a blocking position at the net — repeat for 12 continuous rallies."
        ]),
        TrainingBlock(name: "Target Corners Accuracy", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_target_corners", focusTags: ["accuracy", "vision", "contact"], instructions: [
            "Place cones or markers in both deep corners of the court (zones 1 and 5).",
            "Alternate attacks between the two deep corners — focus on adjusting your shoulder angle to change direction.",
            "Track your accuracy: aim for 80 % of balls landing within 3 feet of the target."
        ]),
        TrainingBlock(name: "Wall Spike + Arm Extension", category: .volleyball, durationMinutes: 7, intensity: .medium, imageName: "hitting_wall_spike", focusTags: ["armSwing", "armExtension", "powerTransfer"], instructions: [
            "Stand 8 feet from a wall, ball in hand. Perform a self-toss and spike into the wall from a standing position.",
            "Focus on contacting the ball at the highest point of your reach — the arm should be fully extended at contact.",
            "Catch the rebound and repeat — complete 3 sets of 12 reps, emphasizing snap and follow-through."
        ]),
        TrainingBlock(name: "Approach + Plant Mechanics", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_approach", focusTags: ["approach", "timing", "jump"], instructions: [
            "Mark a starting point at the 15-foot line. Perform a three-step approach with an explosive plant.",
            "Focus on a heel-to-toe plant on the final step — the left foot should be slightly turned out for a strong block.",
            "Jump vertically, not forward — aim to reach the same peak height on every rep."
        ]),
        TrainingBlock(name: "Approach Rhythm Control", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_approach_rhythm", focusTags: ["approach", "timing", "rhythm"], instructions: [
            "Mark three progressive cones at 15, 10, and 5 feet from the net. Step over each cone during your approach.",
            "The first step is a slow directional step, the second builds speed, and the final two steps are explosive.",
            "Perform 10 approaches without a ball, then 10 with a toss — maintain consistent footwork timing."
        ]),
        TrainingBlock(name: "Game Tempo Hitting", category: .volleyball, durationMinutes: 10, intensity: .high, imageName: "hitting_game_sim", focusTags: ["gameSim", "power", "transition"], instructions: [
            "Simulate game pace: receive a pass, transition to approach, and execute an attack — all within 4 seconds.",
            "Your partner feeds balls at random intervals to simulate live rally conditions.",
            "Execute 20 attacks at game speed — no walking or slow transitions between reps."
        ]),
    ]

    static let agilityDrills: [TrainingBlock] = [
        TrainingBlock(name: "5-10-5 Change of Direction", category: .agility, durationMinutes: 9, intensity: .high, imageName: "agility_5_10_5", focusTags: ["agility", "reaction", "defense"], instructions: [
            "Set three cones five yards apart in a straight line (5-10-5 pro agility layout).",
            "Start straddling the middle cone. Sprint five yards to the right, plant the outside foot under the hip, and explode left.",
            "Sprint through the far cone — complete 5 reps each direction with a 30-second rest between sets."
        ]),
        TrainingBlock(name: "Ladder Quick Feet", category: .agility, durationMinutes: 8, intensity: .medium, imageName: "agility_ladder", focusTags: ["agility", "footwork"], instructions: [
            "Stand at the base of an agility ladder (18-inch rungs). Step both feet into each box as quickly as possible.",
            "Stay on the balls of your feet — minimize ground contact time with each foot strike.",
            "Progress to one-foot patterns, lateral shuffles, and Icky Shuffle footwork — 3 passes per pattern."
        ]),
        TrainingBlock(name: "Lateral Slide Defense", category: .agility, durationMinutes: 8, intensity: .medium, imageName: "agility_lateral_slides", focusTags: ["defense", "agility", "lateral"], instructions: [
            "Assume a defensive ready position — feet wider than shoulders, hips low, hands out wide.",
            "Push off the inside edge of the outside foot to initiate a powerful lateral slide.",
            "Slide 15 feet, touch the line, and explode back in the opposite direction — complete 10 reps each way."
        ]),
        TrainingBlock(name: "Reaction Shuffle", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_reaction_shuffle", focusTags: ["reaction", "defense", "agility"], instructions: [
            "Stand in an athletic stance facing a partner or coach. React to directional cues (left, right, short, deep).",
            "Shuffle hard in the indicated direction for 3 steps, then burst back to center.",
            "Goal: react within 0.3 seconds of the cue — complete 20 reactive reps without breaks."
        ]),
        TrainingBlock(name: "4-Corner Agility", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_4_corner", focusTags: ["agility", "changeOfDirection", "speed"], instructions: [
            "Set four cones in a 10x10-yard square. Start at cone 1, sprint to cone 2, shuffle to cone 3, backpedal to cone 4.",
            "Change direction at each cone with a sharp plant step — do not round the corners.",
            "Complete 5 full circuits clockwise, 5 counter-clockwise — rest 60 seconds between sets."
        ]),
        TrainingBlock(name: "Ball Drop Reaction", category: .agility, durationMinutes: 7, intensity: .high, imageName: "agility_ball_drop", focusTags: ["reaction", "speed", "agility"], instructions: [
            "Stand 5 yards away from a partner who holds a volleyball at shoulder height.",
            "When the partner drops the ball, react and sprint to catch it before the second bounce.",
            "Start from different stances (facing away, lying prone, shuffle stance) — complete 10 catches."
        ]),
        TrainingBlock(name: "Baseline-Net Sprint", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_baseline_net", focusTags: ["speed", "agility", "endurance"], instructions: [
            "Start at the baseline. On the whistle, sprint to the net (9 meters), touch the net with your hand, and backpedal to the baseline.",
            "Repeat for 6 reps — each rep should be completed in under 4 seconds.",
            "Rest 45 seconds between reps. Focus on quick directional transitions at each line."
        ]),
        TrainingBlock(name: "Box Shuffle Pattern", category: .agility, durationMinutes: 8, intensity: .medium, imageName: "agility_box_shuffle", focusTags: ["agility", "footwork", "lateral"], instructions: [
            "Place four cones in a 5x5-yard square. Start at the front-left cone.",
            "Shuffle right to front-right cone, backpedal to back-right, shuffle left to back-left, sprint forward to start.",
            "Complete 5 circuits clockwise, then 5 counter-clockwise — keep your chest up and eyes forward."
        ]),
        TrainingBlock(name: "Color Cone Reaction", category: .agility, durationMinutes: 7, intensity: .high, imageName: "agility_color_cone", focusTags: ["reaction", "agility", "cognition"], instructions: [
            "Place 3-4 different colored cones in a semicircle 8 feet from center. A partner calls a color at random.",
            "React and sprint to touch the called cone, then immediately return to center.",
            "Complete 20 calls — rest 30 seconds — then repeat with the partner calling faster."
        ]),
        TrainingBlock(name: "Combo Agility Circuit", category: .agility, durationMinutes: 10, intensity: .high, imageName: "agility_combo", focusTags: ["agility", "speed", "endurance"], instructions: [
            "Set up a 20-yard circuit: ladder quick feet (5 yards), cone zigzag (10 yards), broad jump finish (5 yards).",
            "Move through the circuit at 90 % effort — every transition should be explosive.",
            "Complete 4 circuits with 90 seconds rest between each. Time each circuit and track improvement."
        ]),
        TrainingBlock(name: "Court Perimeter Run", category: .agility, durationMinutes: 8, intensity: .medium, imageName: "agility_court_perimeter", focusTags: ["endurance", "agility", "speed"], instructions: [
            "Starting at the baseline, sprint the sideline to the net, shuffle across the net, backpedal the far sideline, and sprint the baseline.",
            "Maintain proper form through every directional change — no rounding the corners.",
            "Complete 3 full laps. Rest 60 seconds between laps. Beat your previous time on each lap."
        ]),
        TrainingBlock(name: "Crossover Step Defense", category: .agility, durationMinutes: 7, intensity: .medium, imageName: "agility_crossover", focusTags: ["defense", "agility", "footwork"], instructions: [
            "Start in a low defensive stance. On a directional cue, take a crossover step and drive 3 steps in that direction.",
            "Plant the outside foot and immediately change direction — do not let your feet cross on the plant.",
            "Complete 5 sets of 8 reps (4 each direction) — focus on keeping the hips low and the chest up."
        ]),
        TrainingBlock(name: "Figure-8 Agility", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_figure8", focusTags: ["agility", "changeOfDirection", "speed"], instructions: [
            "Set two cones 8 yards apart. Sprint around the outside of both cones in a figure-8 pattern.",
            "Lean into each turn, keeping the inside shoulder low and the outside arm driving.",
            "Complete 8 figure-8 circuits — rest 45 seconds — repeat for 3 total sets."
        ]),
        TrainingBlock(name: "Hopscotch Agility", category: .agility, durationMinutes: 7, intensity: .medium, imageName: "agility_hopscotch", focusTags: ["agility", "footwork", "coordination"], instructions: [
            "Use chalk or tape to mark a hopscotch pattern (single, double, single, double, single).",
            "Hop through the pattern on one foot for singles and two feet for doubles — maintain a steady rhythm.",
            "Complete 3 passes each leg, then 3 passes with alternating feet for each single box."
        ]),
        TrainingBlock(name: "Icky Shuffle Footwork", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_icky_shuffle", focusTags: ["agility", "footwork", "coordination"], instructions: [
            "Move laterally through a ladder or marked boxes using the Icky pattern: in-in-out (both feet step in then out).",
            "Stay low and keep the feet active — maintain a light, quick bounce between each movement.",
            "Perform 3 passes each direction — increase speed only when the pattern is clean and error-free."
        ]),
        TrainingBlock(name: "Lateral Ladder Speed", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_ladder_lateral", focusTags: ["agility", "footwork", "lateral"], instructions: [
            "Stand to the left of an agility ladder. Step laterally into each rung with both feet (in-in pattern).",
            "Keep the shoulders square and the hips low — minimize vertical bounce.",
            "Complete 4 passes to the right, 4 to the left — rest 30 seconds between sets."
        ]),
        TrainingBlock(name: "Net-to-Sideline Shuffle", category: .agility, durationMinutes: 7, intensity: .medium, imageName: "agility_net_sideline", focusTags: ["defense", "agility", "lateral"], instructions: [
            "Start at the net facing forward. Shuffle sideways to the nearest sideline, touch, and shuffle back.",
            "Keep your eyes on an imaginary hitter — do not rotate your hips away from the net.",
            "Complete 8 reps (4 each direction) — rest 30 seconds — repeat for 3 sets."
        ]),
        TrainingBlock(name: "Short-Long Acceleration", category: .agility, durationMinutes: 7, intensity: .high, imageName: "agility_short_long", focusTags: ["speed", "acceleration", "agility"], instructions: [
            "Mark two cones 3 yards apart (short) and two cones 10 yards apart (long).",
            "Sprint the short distance at 100 % effort, decelerate for 3 steps, then immediately sprint the long distance.",
            "Rest 30 seconds between reps. Complete 6 reps — focus on acceleration mechanics and clean deceleration."
        ]),
        TrainingBlock(name: "Single-Leg Hop Series", category: .agility, durationMinutes: 7, intensity: .medium, imageName: "agility_single_leg_hops", focusTags: ["agility", "coordination", "strength"], instructions: [
            "Mark a line on the floor. Hop forward over the line and back on one leg for 30 seconds.",
            "Switch legs and repeat. Keep the landing soft and quiet — the non-planted leg should not touch the ground.",
            "Perform 3 sets per leg — this develops ankle stability and reactive foot placement."
        ]),
        TrainingBlock(name: "T-Drill Agility", category: .agility, durationMinutes: 9, intensity: .high, imageName: "agility_t_drill", focusTags: ["agility", "changeOfDirection", "speed"], instructions: [
            "Set four cones in a T-shape: one at the start, two 5 yards left and right, and one 10 yards forward.",
            "Sprint forward to the top cone, shuffle left to touch the cone, shuffle right to the far cone, shuffle back to center, backpedal to start.",
            "Complete 5 reps each direction — rest 60 seconds between sets. Track your fastest time."
        ]),
        TrainingBlock(name: "Zigzag Shuttle", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_zigzag", focusTags: ["agility", "changeOfDirection", "speed"], instructions: [
            "Set 5 cones in a zigzag pattern, 3 yards apart at 45-degree angles.",
            "Sprint from cone to cone, planting and cutting sharply at each cone — keep your hips low through the cuts.",
            "Complete 4 full zigzags. Rest 45 seconds. Repeat for 3 sets."
        ]),
    ]

    static let plyoDrills: [TrainingBlock] = [
        TrainingBlock(name: "Box Jump Power", category: .plyometrics, durationMinutes: 8, intensity: .high, imageName: "plyo_box_jumps", focusTags: ["jump", "plyo", "explosiveness"], instructions: [
            "Select a box height that challenges you but allows perfect form (12-24 inches).",
            "Stand at arm's length from the box. Dip, swing arms, and explode onto the box — land softly with both feet.",
            "Step down and reset. Complete 3 sets of 8 reps — quality reps only."
        ]),
        TrainingBlock(name: "Approach Jump Plyos", category: .plyometrics, durationMinutes: 9, intensity: .high, imageName: "plyo_approach_jump", focusTags: ["approach", "jump", "timing"], instructions: [
            "Perform a three-step approach into a maximal vertical jump — reach both hands high at the peak.",
            "Land softly with knees bent, absorbing the impact through the full range of motion.",
            "Reset fully between reps. Complete 4 sets of 6 reps — rest 60 seconds between sets."
        ]),
        TrainingBlock(name: "Depth Drop Landing Control", category: .plyometrics, durationMinutes: 7, intensity: .medium, imageName: "plyo_depth_drop", focusTags: ["landing", "kneeControl", "jump"], instructions: [
            "Step off a low box (12-18 inches). Do not jump — simply step off and drop.",
            "Land with both feet simultaneously — knees over toes, hips back, chest up.",
            "Hold the landing position for 2 seconds before resetting. Complete 3 sets of 8 reps."
        ]),
        TrainingBlock(name: "Lateral Bounds", category: .plyometrics, durationMinutes: 7, intensity: .medium, imageName: "plyo_lateral_bounds", focusTags: ["agility", "defense", "lateral"], instructions: [
            "Stand on your right leg. Bound laterally to the left, landing on the left leg with control.",
            "Stick the landing for 1 second, then immediately explode back to the right.",
            "Complete 3 sets of 10 bounds per side — focus on distance and stability."
        ]),
        TrainingBlock(name: "Ankle Stiffness Pogos", category: .plyometrics, durationMinutes: 6, intensity: .medium, imageName: "plyo_ankle_stiffness", focusTags: ["plyo", "jump", "explosiveness"], instructions: [
            "Stand with feet shoulder-width apart. Hop in place using only your ankles — keep knees relatively straight.",
            "Minimize ground contact time — rebound off the floor as quickly as possible like a pogo stick.",
            "Perform 3 sets of 30 seconds. Rest 30 seconds between sets."
        ]),
        TrainingBlock(name: "Lateral Box Explosions", category: .plyometrics, durationMinutes: 8, intensity: .high, imageName: "plyo_box_lateral", focusTags: ["plyo", "lateral", "explosiveness"], instructions: [
            "Stand to the left of a low box (12-18 inches). Jump laterally onto the box, landing softly with both feet.",
            "Step off to the right, then immediately jump back onto the box from the right side.",
            "Complete 3 sets of 10 total jumps (5 each side). Focus on a quick, explosive takeoff."
        ]),
        TrainingBlock(name: "Broad Jump Series", category: .plyometrics, durationMinutes: 7, intensity: .high, imageName: "plyo_broad_jump", focusTags: ["plyo", "power", "explosiveness"], instructions: [
            "Stand with feet shoulder-width apart. Dip into a quarter squat, drive your arms forward, and jump as far forward as possible.",
            "Land softly and hold the landing for 2 seconds — do not let your knees collapse inward.",
            "Measure your best jump. Complete 4 sets of 5 reps — rest 90 seconds between sets."
        ]),
        TrainingBlock(name: "Vertical Depth Jump", category: .plyometrics, durationMinutes: 8, intensity: .high, imageName: "plyo_depth_jump_vertical", focusTags: ["plyo", "jump", "explosiveness"], instructions: [
            "Step off a box (18-24 inches). Upon landing, immediately explode upward into a maximal vertical jump.",
            "Reach both hands overhead at the peak — the transition from landing to jumping should be instantaneous.",
            "Complete 4 sets of 5 reps. Rest 90 seconds between sets."
        ]),
        TrainingBlock(name: "Lateral Depth Bound", category: .plyometrics, durationMinutes: 7, intensity: .high, imageName: "plyo_depth_lateral", focusTags: ["plyo", "lateral", "explosiveness"], instructions: [
            "Step off a low box to the side. Upon landing, immediately explode laterally into a broad bound.",
            "Stick the landing on the outside leg and hold for 2 seconds.",
            "Complete 3 sets of 6 reps per side — focus on reactive strength and landing control."
        ]),
        TrainingBlock(name: "Diagonal Bounds", category: .plyometrics, durationMinutes: 7, intensity: .medium, imageName: "plyo_diagonal_bounds", focusTags: ["plyo", "agility", "power"], instructions: [
            "Stand on your right leg. Bound forward and to the left at a 45-degree angle, landing on your left leg.",
            "Immediately bound forward and to the right, landing on your right leg — maintain a rhythmic flow.",
            "Complete 3 sets of 8 bounds per direction — focus on distance and balance."
        ]),
        TrainingBlock(name: "Hurdle Hop Series", category: .plyometrics, durationMinutes: 8, intensity: .high, imageName: "plyo_hurdle_hops", focusTags: ["plyo", "jump", "explosiveness"], instructions: [
            "Set up 5 low hurdles (6-12 inches) in a straight line, 2 feet apart.",
            "Jump over each hurdle with both feet together — minimize ground contact between each jump.",
            "Complete 4 sets of 5 jumps. Rest 60 seconds between sets."
        ]),
        TrainingBlock(name: "Lateral Hurdle Hops", category: .plyometrics, durationMinutes: 7, intensity: .high, imageName: "plyo_hurdle_lateral", focusTags: ["plyo", "lateral", "explosiveness"], instructions: [
            "Place a single low hurdle (6-12 inches) on the floor. Stand to its left.",
            "Hop laterally over the hurdle and back — both feet together — as quickly as possible.",
            "Complete 3 sets of 15 seconds. Rest 30 seconds between sets."
        ]),
        TrainingBlock(name: "Jump Matrix Pattern", category: .plyometrics, durationMinutes: 9, intensity: .high, imageName: "plyo_jump_matrix", focusTags: ["plyo", "agility", "coordination"], instructions: [
            "Mark a 2x2 grid on the floor (4 squares, each 18x18 inches). Start in the bottom-left square.",
            "Jump through the grid in a set pattern: forward, right, backward, left, forward — complete the full pattern.",
            "Complete 5 full patterns. Rest 60 seconds. Repeat for 3 sets."
        ]),
        TrainingBlock(name: "Line Lateral Hops", category: .plyometrics, durationMinutes: 6, intensity: .medium, imageName: "plyo_lateral_line", focusTags: ["plyo", "lateral", "agility"], instructions: [
            "Stand to the left of a line on the floor. Hop laterally over the line and back as quickly as possible.",
            "Use both feet together and keep the hops low — focus on speed of rebound, not height.",
            "Complete 3 sets of 20 seconds. Rest 30 seconds between sets."
        ]),
        TrainingBlock(name: "Pogo Stick Jumps", category: .plyometrics, durationMinutes: 6, intensity: .medium, imageName: "plyo_pogo", focusTags: ["plyo", "jump", "explosiveness"], instructions: [
            "Stand with feet together and knees slightly bent. Hop in place using a stiff ankle action.",
            "Keep the knees relatively straight — the power should come from the ankles and calves.",
            "Perform 3 sets of 30 seconds. Rest 30 seconds between sets."
        ]),
        TrainingBlock(name: "Rebound Plyos", category: .plyometrics, durationMinutes: 7, intensity: .high, imageName: "plyo_rebound", focusTags: ["plyo", "reaction", "explosiveness"], instructions: [
            "Stand facing a wall or partner. Receive a chest-pass ball, catch it, and immediately jump vertically.",
            "At the peak of the jump, release the ball back to the passer — land and reset.",
            "Complete 4 sets of 8 reps — focus on the instant transition from landing to jumping."
        ]),
        TrainingBlock(name: "Single-Leg Forward Hops", category: .plyometrics, durationMinutes: 7, intensity: .medium, imageName: "plyo_single_leg_forward", focusTags: ["plyo", "strength", "coordination"], instructions: [
            "Stand on your right leg. Hop forward 12-18 inches, landing on the same leg.",
            "Hold the landing for 2 seconds, then hop again — complete 8 hops, then switch legs.",
            "Perform 3 sets per leg. Keep the landing soft and controlled."
        ]),
        TrainingBlock(name: "Split Jump Switch", category: .plyometrics, durationMinutes: 7, intensity: .high, imageName: "plyo_split_jumps", focusTags: ["plyo", "power", "coordination"], instructions: [
            "Start in a lunge position with your right leg forward. Jump up and switch legs mid-air.",
            "Land softly with the left leg forward — immediately explode into the next jump.",
            "Complete 3 sets of 12 switches. Rest 45 seconds between sets."
        ]),
        TrainingBlock(name: "Squat Jump Power", category: .plyometrics, durationMinutes: 7, intensity: .high, imageName: "plyo_squat_jumps", focusTags: ["plyo", "power", "jump"], instructions: [
            "Stand with feet shoulder-width apart. Lower into a full squat (thighs parallel to the floor).",
            "Explode upward as high as possible, driving your arms overhead — land softly and immediately descend into the next squat.",
            "Complete 3 sets of 10 reps. Rest 60 seconds between sets."
        ]),
        TrainingBlock(name: "Tuck Jump Series", category: .plyometrics, durationMinutes: 7, intensity: .high, imageName: "plyo_tuck_jumps", focusTags: ["plyo", "power", "explosiveness"], instructions: [
            "Stand with feet shoulder-width apart. Jump up and drive your knees toward your chest mid-air.",
            "Extend your legs before landing — land softly with knees bent.",
            "Complete 3 sets of 8 reps. Rest 60 seconds between sets."
        ]),
        TrainingBlock(name: "Vertical Reach Max", category: .plyometrics, durationMinutes: 7, intensity: .medium, imageName: "plyo_vertical_reach", focusTags: ["plyo", "jump", "explosiveness"], instructions: [
            "Stand sideways to a wall with chalk on your fingertips. Mark your standing reach height.",
            "Jump as high as possible and touch the wall at the peak of your jump — measure the difference.",
            "Complete 5 max-effort jumps. Rest 30 seconds between each jump."
        ]),
    ]

    static let stretchDrills: [TrainingBlock] = [
        TrainingBlock(name: "Ankle Activation Circuit", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_ankle_activation", focusTags: ["mobility", "ankle", "activation"], instructions: [
            "Sit back on your heels with toes curled under — hold for 20 seconds.",
            "Rock forward onto the balls of your feet, lifting your heels — 15 slow, controlled reps.",
            "Finish with ankle circles: 10 each direction, per ankle."
        ]),
        TrainingBlock(name: "Balance & Stabilization", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_balance", focusTags: ["balance", "core", "stability"], instructions: [
            "Stand on your right leg — hold for 30 seconds without touching anything for support.",
            "Progress to single-leg stance with eyes closed — 20 seconds per leg.",
            "Finish with single-leg Romanian deadlifts: 8 slow reps per leg."
        ]),
        TrainingBlock(name: "Full Body Flow", category: .stretching, durationMinutes: 5, intensity: .low, imageName: "stretch_full_body", focusTags: ["mobility", "flexibility", "recovery"], instructions: [
            "Start in a downward dog — walk your feet to your hands and slowly roll up to standing.",
            "Reach overhead, then fold forward — walk your hands out to a plank, hold 10 seconds.",
            "Repeat the flow 5 times, moving slowly and breathing deeply through each transition."
        ]),
        TrainingBlock(name: "Dynamic Hamstring Prep", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_hamstring_dynamic", focusTags: ["flexibility", "hamstring", "mobility"], instructions: [
            "Walk forward with straight-leg kicks — kick your right hand with your left foot, alternating.",
            "Perform walking lunges with a torso twist — 10 reps per side.",
            "Finish with leg swings: 10 forward-back and 10 side-to-side per leg."
        ]),
        TrainingBlock(name: "Leg Prep Activation", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_leg_prep", focusTags: ["activation", "legs", "mobility"], instructions: [
            "Perform body-weight squats with a 3-second pause at the bottom — 12 reps.",
            "Walking lunges with a knee drive — 10 reps per leg.",
            "Finish with lateral lunges — 8 reps per side, holding the deep position for 2 seconds."
        ]),
        TrainingBlock(name: "T-Spine Mobility", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_tspine", focusTags: ["mobility", "spine", "shoulder"], instructions: [
            "Start on hands and knees. Place one hand behind your head and rotate your elbow toward the ceiling.",
            "Return and repeat — 10 reps per side, moving through a full range of motion.",
            "Finish with cat-cow stretches: 10 slow, deliberate cycles."
        ]),
        TrainingBlock(name: "Volleyball Flow Sequence", category: .stretching, durationMinutes: 5, intensity: .low, imageName: "stretch_vb_flow", focusTags: ["mobility", "flexibility", "activation"], instructions: [
            "Combine shoulder circles (10 forward, 10 back), hip circles (10 each direction), and ankle rotations.",
            "Transition into spiderman lunges with an overhead reach — 8 reps per side.",
            "Finish with a deep squat hold for 30 seconds, keeping the chest up and heels down."
        ]),
    ]

    static let strengthDrills: [TrainingBlock] = [
        TrainingBlock(name: "Core Stability Holds", category: .strength, durationMinutes: 7, intensity: .medium, imageName: "core_stability", focusTags: ["core", "powerTransfer", "stability"], instructions: [
            "Front plank: 45 seconds — keep your body in a straight line, engage glutes and core.",
            "Side plank: 30 seconds each side — stack your feet and reach the top arm toward the ceiling.",
            "Dead bug: 10 slow reps per side — press your lower back into the floor throughout the movement."
        ]),
        TrainingBlock(name: "Glute Bridge Progression", category: .strength, durationMinutes: 6, intensity: .medium, imageName: "core_stability", focusTags: ["strength", "glutes", "core"], instructions: [
            "Lie on your back with knees bent. Drive through your heels to lift your hips toward the ceiling.",
            "Hold the bridge for 2 seconds at the top — squeeze your glutes hard.",
            "Progress to single-leg bridges: 8 reps per leg. Complete 3 sets."
        ]),
        TrainingBlock(name: "Medicine Ball Rotational Core", category: .strength, durationMinutes: 7, intensity: .medium, imageName: "core_stability", focusTags: ["core", "power", "rotation"], instructions: [
            "Stand with feet shoulder-width apart holding a medicine ball (or light dumbbell) at chest height.",
            "Rotate your torso to the right, then explosively rotate to the left — keep hips facing forward.",
            "Complete 3 sets of 12 reps each direction. Rest 30 seconds between sets."
        ]),
    ]

    static var allDrills: [TrainingBlock] { volleyballDrills + agilityDrills + plyoDrills + stretchDrills + strengthDrills }

    static func recommendationFocus(from hits: [VolleyballHit]) -> String {
        guard let hit = hits.first else { return "balanced volleyball performance" }
        let feedback = hit.coachFeedback.lowercased()
        if feedback.contains("arm") || feedback.contains("extension") || feedback.contains("swing") { return "arm swing angle" }
        if feedback.contains("jump") || feedback.contains("explosive") { return "vertical jump explosiveness" }
        if feedback.contains("speed") || feedback.contains("power") { return "power transfer" }
        if feedback.contains("angle") || feedback.contains("launch") { return "contact and launch angle" }
        if hit.armAngleDegrees < 145 { return "arm swing angle" }
        if hit.jumpHeightInches < 12 && hit.hitType == "Spike" { return "vertical jump explosiveness" }
        if hit.ballSpeedMPH < 30 { return "power transfer" }
        return "balanced volleyball performance"
    }

    static func generatePlan(focus: String, targetMinutes: Int = 45) -> TrainingPlan {
        let normalized = focus.lowercased()
        let tags: [String]
        if normalized.contains("arm") || normalized.contains("swing") { tags = ["armSwing", "armExtension", "powerTransfer"] }
        else if normalized.contains("jump") || normalized.contains("explosive") { tags = ["jump", "plyo", "explosiveness"] }
        else if normalized.contains("agility") || normalized.contains("defense") { tags = ["agility", "defense", "reaction"] }
        else if normalized.contains("angle") || normalized.contains("contact") { tags = ["contact", "timing", "accuracy"] }
        else { tags = ["armSwing", "jump", "agility", "timing"] }

        let warmupBlocks = Array(warmups.prefix(3))
        var candidates = allDrills.filter { block in !Set(block.focusTags).isDisjoint(with: Set(tags)) }
        if candidates.count < 5 { candidates += allDrills.filter { !candidates.contains($0) } }

        let scale = Double(targetMinutes) / 45.0
        let scaledWarmups = warmupBlocks.map { scaled($0, scale: scale) }
        let scaledCandidates = candidates.map { scaled($0, scale: scale) }

        var planBlocks = scaledWarmups
        var activeMinutes = planBlocks.reduce(0) { $0 + $1.durationMinutes }
        for block in scaledCandidates {
            guard activeMinutes + block.durationMinutes <= targetMinutes else { continue }
            planBlocks.append(block)
            activeMinutes += block.durationMinutes
        }
        planBlocks = insertWaterBreaks(in: planBlocks)
        return TrainingPlan(id: UUID(), name: "Coach Plan: \(focus.capitalized)", focus: focus, createdAt: Date(), blocks: planBlocks)
    }

    static func generateCategoryPlan(category: TrainingCategory, targetMinutes: Int = 45) -> TrainingPlan {
        let scale = Double(targetMinutes) / 45.0
        let warmupBlocks = Array(warmups.prefix(3)).map { scaled($0, scale: scale) }
        let catDrills = allDrills.filter { $0.category == category }.sorted { $0.durationMinutes > $1.durationMinutes }
        var planBlocks = warmupBlocks
        var activeMinutes = planBlocks.reduce(0) { $0 + $1.durationMinutes }
        for block in catDrills {
            let sb = scaled(block, scale: scale)
            guard activeMinutes + sb.durationMinutes <= targetMinutes else { continue }
            planBlocks.append(sb); activeMinutes += sb.durationMinutes
        }
        planBlocks = insertWaterBreaks(in: planBlocks)
        return TrainingPlan(id: UUID(), name: "Category Plan: \(category.rawValue)", focus: category.rawValue, createdAt: Date(), blocks: planBlocks)
    }

    static func generateMultiCategoryPlan(categories: [TrainingCategory], targetMinutes: Int = 45) -> TrainingPlan {
        let scale = Double(targetMinutes) / 45.0
        let warmupBlocks = Array(warmups.prefix(3)).map { scaled($0, scale: scale) }
        let catSet = Set(categories)
        let multiDrills = allDrills.filter { catSet.contains($0.category) }.sorted { $0.durationMinutes > $1.durationMinutes }
        var planBlocks = warmupBlocks
        var activeMinutes = planBlocks.reduce(0) { $0 + $1.durationMinutes }
        for block in multiDrills {
            let sb = scaled(block, scale: scale)
            guard activeMinutes + sb.durationMinutes <= targetMinutes else { continue }
            planBlocks.append(sb); activeMinutes += sb.durationMinutes
        }
        planBlocks = insertWaterBreaks(in: planBlocks)
        return TrainingPlan(id: UUID(), name: "Multi-Category Plan", focus: categories.map { $0.rawValue }.joined(separator: " + "), createdAt: Date(), blocks: planBlocks)
    }

    private static func scaled(_ block: TrainingBlock, scale: Double) -> TrainingBlock {
        let newMinutes = max(2, Int(Double(block.durationMinutes) * scale))
        return TrainingBlock(id: block.id, name: block.name, category: block.category, durationMinutes: newMinutes, intensity: block.intensity, imageName: block.imageName, focusTags: block.focusTags, instructions: block.instructions)
    }

    private static func insertWaterBreaks(in blocks: [TrainingBlock]) -> [TrainingBlock] {
        var result: [TrainingBlock] = []
        var minutesSinceBreak = 0
        for (i, block) in blocks.enumerated() {
            result.append(block); minutesSinceBreak += block.durationMinutes
            if i < blocks.count - 1 && minutesSinceBreak >= 12 { result.append(.waterBreak()); minutesSinceBreak = 0 }
        }
        if result.last?.category == .waterBreak { result.removeLast() }
        return result
    }
}

// MARK: - TrainingHubView
struct TrainingHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var hits: [VolleyballHit]
    @Query(sort: \SavedTrainingPlan.createdAt, order: .reverse) private var savedPlans: [SavedTrainingPlan]
    @State private var customFocus = ""
    @State private var selectedDuration: Double = 45
    @State private var trainingMode: TrainingMode = .aiGenerated
    @State private var selectedCategory: TrainingCategory? = nil
    @State private var selectedCategories: Set<TrainingCategory> = []
    @State private var generatedPlan: TrainingPlan?
    @State private var showingSaved = false
    @Environment(\.dismiss) private var dismiss

    private var coachFocus: String { VolleyballTrainingLibrary.recommendationFocus(from: hits) }

    private func generateTraining() {
        let target = Int(selectedDuration)
        switch trainingMode {
        case .aiGenerated:
            let focus = customFocus.trimmingCharacters(in: .whitespacesAndNewlines)
            generatedPlan = VolleyballTrainingLibrary.generatePlan(focus: focus.isEmpty ? "balanced volleyball performance" : focus, targetMinutes: target)
        case .selectCategory:
            guard let category = selectedCategory else { return }
            generatedPlan = VolleyballTrainingLibrary.generateCategoryPlan(category: category, targetMinutes: target)
        case .buildYourOwn:
            guard !selectedCategories.isEmpty else { return }
            generatedPlan = VolleyballTrainingLibrary.generateMultiCategoryPlan(categories: Array(selectedCategories), targetMinutes: target)
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image("background").resizable().scaledToFill().ignoresSafeArea().opacity(0.4)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Button(action: { dismiss() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold))
                                        Text("Back").fontWeight(.semibold)
                                    }.font(.system(size: 16, design: .rounded)).foregroundColor(.pink)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.pink.opacity(0.5), lineWidth: 1))
                                }.buttonStyle(PlainButtonStyle())
                                Spacer()
                            }.padding(.top, 8)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("🏐 Training Generator").font(.title.bold()).foregroundColor(.white)
                                Text("Build world-class workouts from AI coach feedback.").font(.subheadline).foregroundColor(.white.opacity(0.7))
                                Text("Every workout starts with 3 warmup blocks and auto-inserts water breaks every 10-15 minutes.").font(.caption).foregroundColor(.white.opacity(0.5))
                            }

                            GlassCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack { Image(systemName: "sparkles").foregroundColor(.yellow); Text("Coach Recommendation").font(.headline).foregroundColor(.yellow) }
                                    Text(coachFocus.capitalized).font(.title3.bold()).foregroundColor(.white)
                                    Text("Based on your latest recorded hit feedback").font(.caption).foregroundColor(.white.opacity(0.5))
                                    Button(action: { generatedPlan = VolleyballTrainingLibrary.generatePlan(focus: coachFocus, targetMinutes: Int(selectedDuration)) }) {
                                        HStack { Image(systemName: "wand.and.stars"); Text("Generate Coach Plan") }
                                            .font(.subheadline.bold()).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.yellow).cornerRadius(12)
                                    }.buttonStyle(PlainButtonStyle())
                                }
                            }

                            GlassCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack { Image(systemName: "gearshape.2.fill").foregroundColor(.cyan); Text("Custom Training Generator").font(.headline).foregroundColor(.cyan) }

                                    Picker("Training Mode", selection: $trainingMode) { ForEach(TrainingMode.allCases) { mode in Text(mode.rawValue).tag(mode) } }
                                        .pickerStyle(.segmented)

                                    VStack(spacing: 6) {
                                        HStack {
                                            Image(systemName: "clock.fill").foregroundColor(.pink)
                                            Text("Session Duration").font(.subheadline.bold()).foregroundColor(.white)
                                            Spacer()
                                            Text("\(Int(selectedDuration)) min").font(.title3.bold().monospacedDigit()).foregroundColor(.pink)
                                        }
                                        Slider(value: $selectedDuration, in: 15...180, step: 5).accentColor(.pink)
                                        HStack { Text("15 min").font(.caption2).foregroundColor(.gray); Spacer(); Text("180 min").font(.caption2).foregroundColor(.gray) }
                                    }

                                    if trainingMode == .aiGenerated {
                                        HStack {
                                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                                            TextField("Focus, e.g. agility, arm swing, jumping", text: $customFocus).textFieldStyle(.plain).foregroundColor(.white)
                                        }.padding(12).background(Color.white.opacity(0.08)).cornerRadius(10)
                                    } else if trainingMode == .selectCategory {
                                        Menu {
                                            ForEach(TrainingCategory.allCases.filter { $0 != .waterBreak }) { cat in
                                                Button(action: { selectedCategory = cat }) {
                                                    HStack { Image(systemName: cat.icon); Text(cat.rawValue); if selectedCategory == cat { Image(systemName: "checkmark") } }
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: selectedCategory?.icon ?? "folder").foregroundColor(selectedCategory?.color ?? .gray)
                                                Text(selectedCategory?.rawValue ?? "Choose Category").foregroundColor(selectedCategory == nil ? .gray : .white)
                                                Spacer(); Image(systemName: "chevron.down").foregroundColor(.gray)
                                            }.padding(12).background(Color.white.opacity(0.08)).cornerRadius(10)
                                        }
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(TrainingCategory.allCases.filter { $0 != .waterBreak }) { cat in
                                                    let sel = selectedCategories.contains(cat)
                                                    Button(action: { if sel { selectedCategories.remove(cat) } else { selectedCategories.insert(cat) } }) {
                                                        HStack(spacing: 4) { Image(systemName: cat.icon); Text(cat.rawValue) }
                                                            .font(.caption.bold()).foregroundColor(sel ? .black : cat.color)
                                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                                            .background(sel ? cat.color : Color.clear).cornerRadius(20)
                                                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(cat.color.opacity(0.6), lineWidth: 1.5))
                                                    }.buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                        }
                                    }

                                    HStack(spacing: 12) {
                                        Button(action: generateTraining) {
                                            HStack { Image(systemName: "play.fill"); Text("Generate Training") }
                                                .font(.subheadline.bold()).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.cyan).cornerRadius(12)
                                        }.buttonStyle(PlainButtonStyle())
                                        Button(action: { showingSaved = true }) {
                                            HStack { Image(systemName: "list.bullet.rectangle"); Text("Saved (\(savedPlans.count))") }
                                                .font(.subheadline.bold()).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.purple.opacity(0.7)).cornerRadius(12)
                                        }.buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }

                            GlassCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(VolleyballTrainingLibrary.allDrills.count) Drills Available").font(.caption.bold()).foregroundColor(.white)
                                        Text("Across 5 training categories with unique instructional images").font(.caption2).foregroundColor(.gray)
                                    }
                                    Spacer(); Text("🏐").font(.title2)
                                }
                            }
                        }.padding(.horizontal, 20).padding(.bottom, 40)
                    }
                }.navigationBarHidden(true)
                    .navigationDestination(item: $generatedPlan) { plan in TrainingScheduleView(plan: plan) }
                    .sheet(isPresented: $showingSaved) { SavedTrainingsView() }
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Training Schedule View
struct TrainingScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    let plan: TrainingPlan
    @State private var selectedBlock: TrainingBlock?
    @State private var saveName = ""
    @State private var showSaveName = false
    @State private var timers: [UUID: Int] = [:]
    @State private var running: Set<UUID> = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("background").resizable().scaledToFill().ignoresSafeArea().opacity(0.3)
            VStack(spacing: 12) {
                summary
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(plan.blocks) { block in
                            if block.category == .waterBreak { waterBreakRow(block) }
                            else {
                                TrainingScheduleRow(block: block, seconds: timers[block.id] ?? block.durationMinutes * 60, isRunning: running.contains(block.id), onTap: { selectedBlock = block }, onPlay: { running.insert(block.id) }, onPause: { running.remove(block.id) }, onReset: { timers[block.id] = block.durationMinutes * 60; running.remove(block.id) })
                            }
                        }
                    }.padding(.horizontal)
                }
                HStack {
                    Button("Save") { showSaveName = true }.buttonStyle(TrainingButtonStyle(color: .cyan, foreground: .black))
                    Button("PDF") { }.buttonStyle(TrainingButtonStyle(color: Color(red: 1.0, green: 0.08, blue: 0.58), foreground: .white)).disabled(true)
                    ShareLink(item: shareText) { Text("Share") }.buttonStyle(TrainingButtonStyle(color: .yellow, foreground: .black))
                }.padding(.horizontal).padding(.bottom, 8)
            }
        }.navigationTitle("Training Schedule").navigationBarTitleDisplayMode(.inline)
            .onAppear { resetTimersIfNeeded() }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in tickTimers() }
            .sheet(item: $selectedBlock) { block in TrainingBlockDetailView(block: block) }
            .alert("Name Your Training", isPresented: $showSaveName) {
                TextField("Training name", text: $saveName)
                Button("Cancel", role: .cancel) { saveName = "" }
                Button("Save") { saveTraining() }
            }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plan.name).font(.title3.bold()).foregroundColor(.white)
            Text("\(plan.blocks.count) blocks • \(plan.totalMinutes) min • Focus: \(plan.focus.capitalized)").font(.caption).foregroundColor(.gray)
        }.frame(maxWidth: .infinity, alignment: .leading).padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14)).padding(.horizontal)
    }

    private func waterBreakRow(_ block: TrainingBlock) -> some View {
        HStack {
            Image(systemName: "drop.fill").foregroundColor(Color(red: 1.0, green: 0.08, blue: 0.58))
            Text("WATER BREAK — \(block.durationMinutes) MIN").font(.headline).foregroundColor(Color(red: 1.0, green: 0.08, blue: 0.58))
        }.frame(maxWidth: .infinity).padding()
            .background(Color(red: 1.0, green: 0.08, blue: 0.58).opacity(0.12)).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 1.0, green: 0.08, blue: 0.58), lineWidth: 1))
    }

    private var shareText: String { ([plan.name, "Total: \(plan.totalMinutes) min", "Focus: \(plan.focus)"] + plan.blocks.map { "• \($0.name) — \($0.durationMinutes) min" }).joined(separator: "\n") }

    private func resetTimersIfNeeded() { guard timers.isEmpty else { return }; for b in plan.blocks where b.category != .waterBreak { timers[b.id] = b.durationMinutes * 60 } }

    private func tickTimers() {
        for id in running { guard let v = timers[id], v > 0 else { continue }; timers[id] = v - 1; if v - 1 == 0 { running.remove(id); AudioServicesPlaySystemSound(1519) } }
    }

    private func saveTraining() {
        let name = saveName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? plan.name : saveName
        modelContext.insert(SavedTrainingPlan(name: name, focus: plan.focus, blocks: plan.blocks))
        try? modelContext.save(); saveName = ""
    }
}

struct SavedTrainingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedTrainingPlan.createdAt, order: .reverse) private var savedPlans: [SavedTrainingPlan]
    @State private var selectedPlan: TrainingPlan?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().opacity(0.3)
                List {
                    ForEach(savedPlans) { saved in
                        Button {
                            selectedPlan = TrainingPlan(id: saved.id, name: saved.name, focus: saved.focus, createdAt: saved.createdAt, blocks: saved.blocks)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(saved.name).foregroundColor(.white).font(.headline)
                                Text("\(saved.totalMinutes) min • \(saved.focus.capitalized)").foregroundColor(.gray).font(.caption)
                            }
                        }.listRowBackground(Color.white.opacity(0.06))
                            .swipeActions { Button("Delete", role: .destructive) { modelContext.delete(saved); try? modelContext.save() } }
                    }
                }.scrollContentBackground(.hidden)
            }.navigationTitle("Saved Trainings")
                .toolbar { Button("Done") { dismiss() } }
                .navigationDestination(item: $selectedPlan) { plan in TrainingScheduleView(plan: plan) }
        }
    }
}

struct TrainingScheduleRow: View {
    let block: TrainingBlock; let seconds: Int; let isRunning: Bool
    let onTap: () -> Void; let onPlay: () -> Void; let onPause: () -> Void; let onReset: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onTap) { TrainingBlockRow(block: block, compact: false) }.buttonStyle(.plain)
            VStack(spacing: 4) {
                Text(format(seconds)).font(.headline.monospacedDigit()).foregroundColor(Color(red: 1.0, green: 0.08, blue: 0.58))
                HStack(spacing: 8) {
                    Button(action: onPlay) { Image(systemName: "play.fill").font(.caption) }
                    Button(action: onPause) { Image(systemName: "pause.fill").font(.caption) }
                    Button(action: onReset) { Image(systemName: "arrow.counterclockwise").font(.caption) }
                }.foregroundColor(.white)
            }
        }.padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(block.category.color.opacity(isRunning ? 1 : 0.35), lineWidth: 1))
    }

    private func format(_ s: Int) -> String { "\(s / 60):\(String(format: "%02d", s % 60))" }
}

struct TrainingBlockRow: View {
    let block: TrainingBlock; let compact: Bool
    var body: some View {
        HStack(spacing: 10) {
            Image(block.imageName).resizable().scaledToFit().frame(width: compact ? 44 : 56, height: compact ? 44 : 56).cornerRadius(8)
            VStack(alignment: .leading, spacing: 3) {
                Text(block.name).font(compact ? .subheadline.bold() : .headline).foregroundColor(.white).lineLimit(1)
                Text("\(block.durationMinutes) min • \(block.category.rawValue) • \(block.intensity.rawValue.uppercased())").font(.caption).foregroundColor(.gray)
            }
            Spacer()
        }
    }
}

struct TrainingBlockDetailView: View {
    let block: TrainingBlock; @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Image(block.imageName).resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: 240).cornerRadius(16)
                Text(block.name).font(.title2.bold()).foregroundColor(.white)
                HStack {
                    Label("\(block.durationMinutes) min", systemImage: "clock"); Text("•")
                    Label(block.category.rawValue, systemImage: block.category.icon); Text("•")
                    Label(block.intensity.rawValue.uppercased(), systemImage: "flame")
                }.font(.caption).foregroundColor(.gray)

                Text("Instructions").font(.headline).foregroundColor(.white)
                ForEach(Array(block.instructions.enumerated()), id: \.offset) { i, line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(i + 1).").font(.caption.bold()).foregroundColor(.pink)
                        Text(line).frame(maxWidth: .infinity, alignment: .leading)
                    }.font(.subheadline).foregroundColor(.white.opacity(0.85))
                }
                Button("Close") { dismiss() }.buttonStyle(TrainingButtonStyle(color: Color(red: 1.0, green: 0.08, blue: 0.58), foreground: .white))
            }.padding()
        }.background(Color.black.ignoresSafeArea())
    }
}

struct TrainingButtonStyle: ButtonStyle {
    let color: Color; let foreground: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.caption.bold()).foregroundColor(foreground)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1.0)).cornerRadius(10)
    }
}