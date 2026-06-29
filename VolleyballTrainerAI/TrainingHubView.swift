import SwiftUI
import SwiftData
import AudioToolbox

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
}

enum TrainingIntensity: String, Codable {
    case low, medium, high
}

enum TrainingGenerationMode: String, CaseIterable, Identifiable {
    case aiCoach = "AI Coach"
    case userGenerated = "User Generated"
    case customBuilt = "Custom Built"
    var id: String { rawValue }
}

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
            "Drink water or electrolytes.",
            "Walk slowly and control your breathing.",
            "Restart only when your legs feel responsive."
        ])
    }
}

struct TrainingPlan: Identifiable, Hashable {
    let id: UUID; var name: String; var focus: String; var createdAt: Date; var blocks: [TrainingBlock]
    var totalMinutes: Int { blocks.reduce(0) { $0 + $1.durationMinutes } }
}

@Model
final class SavedTrainingPlan {
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
            "Begin with a light jog along the court perimeter — accelerate gradually to 60 % of max speed.",
            "Integrate dynamic movements: high knees, butt kicks, carioca, and walking lunges for 15 yards each.",
            "Maintain upright posture, controlled breathing, and active arm drive throughout the sequence."
        ]),
        TrainingBlock(name: "Shoulder Prep Flow", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_shoulder_prep", focusTags: ["armSwing", "shoulder", "armExtension"], instructions: [
            "Perform arm circles (forward & backward), 10 reps each direction, gradually increasing range of motion.",
            "Cross-body shoulder stretch — pull the elbow across your chest and hold for 15 seconds per side.",
            "Complete 10 slow, deliberate shadow swings, focusing on high elbow position and full arm extension."
        ]),
        TrainingBlock(name: "Hip + Ankle Activation", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_hip_mobility", focusTags: ["jump", "approach", "mobility"], instructions: [
            "Worlds greatest stretch: lunge forward, drop the back knee, rotate the torso open — 5 breaths per side.",
            "Ankle rocks: sit back on heels, lift toes, then rock forward onto the balls of your feet — 12 reps.",
            "Body-weight squat with a 3-second pause at the bottom, keeping knees tracking over toes."
        ]),
        TrainingBlock(name: "Pre-Jump Leg Prep", category: .warmup, durationMinutes: 3, intensity: .low, imageName: "stretch_prejump", focusTags: ["plyo", "jump"], instructions: [
            "Low pogo hops — keep ankles stiff, rebound off the floor as quickly as possible for 30 seconds.",
            "Two-step approach footwork without jumping — accelerate, plant, and close the block 6 times.",
            "Finish with 5 slow, exaggerated arm swings to reinforce vertical-arm patterning."
        ])
    ]

    static let drills: [TrainingBlock] = [
        // ===== HITTING / ATTACK =====
        TrainingBlock(name: "Hitting Arm Swing Mechanics", category: .volleyball, durationMinutes: 10, intensity: .medium, imageName: "hitting_arm_swing", focusTags: ["armSwing", "armExtension", "tempo"], instructions: ["Load your hitting elbow behind your ear at takeoff.", "Contact the ball in front of your body at full reach.", "Freeze the finish position and check shoulder-to-wrist alignment."]),
        TrainingBlock(name: "Approach Angle Reps", category: .volleyball, durationMinutes: 9, intensity: .medium, imageName: "hitting_approach_angle", focusTags: ["approach", "timing", "armSwing"], instructions: ["Mark your start position and target contact zone.", "Use a controlled 3-step approach — left, right-left — with explosive arm drive.", "Plant your hips open and attack through the ball into the target."]),
        TrainingBlock(name: "Max Jump Touches", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "hitting_max_jump", focusTags: ["jump", "explosiveness", "vertical"], instructions: ["Take a 3-step approach and jump as high as possible toward a safe wall target.", "Swing arms aggressively into the takeoff and reach with both hands.", "Land softly and reset fully before the next rep — quality over quantity."]),
        TrainingBlock(name: "Hitting High Ball", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_high_ball", focusTags: ["highBall", "contact", "timing"], instructions: ["Have a partner toss a high ball or use a ball machine.", "Delay the start of your approach until the ball begins to descend.", "Contact the ball above your forehead with full wrist snap."]),
        TrainingBlock(name: "Cross Court Target Hits", category: .volleyball, durationMinutes: 10, intensity: .medium, imageName: "hitting_cross_court", focusTags: ["accuracy", "vision", "armSwing"], instructions: ["Set up a target in the cross-court zone (1-2 feet inside the line).", "Open your shoulders, contact high, and finish with your thumb down.", "Track makes vs misses and adjust your approach angle accordingly."]),
        TrainingBlock(name: "Line Shot Accuracy", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_line_shot", focusTags: ["line", "accuracy", "contact"], instructions: ["Aim the ball down the line — 1-2 feet inside the sideline.", "Keep the ball in front and reach for the top of the ball.", "Land balanced and reset to the same starting spot each rep."]),
        TrainingBlock(name: "Hitting Roll Shot", category: .volleyball, durationMinutes: 8, intensity: .low, imageName: "hitting_roll_shot", focusTags: ["touch", "placement", "finesse"], instructions: ["Approach with the same tempo as a power swing but reduce arm speed.", "Open your hand and roll your fingers over the top of the ball.", "Land under control — the roll shot is about placement, not power."]),
        TrainingBlock(name: "Tool the Block Drill", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "hitting_tool_block", focusTags: ["tool", "power", "vision"], instructions: ["Set up a blocker or a block target (pads / cones).", "Attack aggressively, aiming to hit the top of the blocker's hands.", "Use the block to deflect the ball out of bounds — develop block vision."]),
        TrainingBlock(name: "Transition Hitting", category: .volleyball, durationMinutes: 10, intensity: .high, imageName: "hitting_transition", focusTags: ["transition", "decision", "speed"], instructions: ["Simulate a defensive-to-offensive transition: start in a base defensive position.", "React to a cue (coach toss / hit), then transition into an attack approach.", "Make a split-second decision on shot location based on the block."]),
        TrainingBlock(name: "Game Simulation Hitting", category: .volleyball, durationMinutes: 12, intensity: .high, imageName: "hitting_game_sim", focusTags: ["gameSpeed", "readBlock", "decision"], instructions: ["Full-court 6-on-6 or 3-on-3 scrimmage focusing on offensive execution.", "For each transition, call out your attack choice (line / cross / tool).", "Debrief with a teammate after each rally — what worked, what to adjust."]),
        TrainingBlock(name: "Wall Spike Reps", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_wall_spike", focusTags: ["armSwing", "powerTransfer", "contact"], instructions: ["Stand 6-8 feet from a solid wall. Toss the ball up and spike into the wall.", "Focus on high elbow, full extension, and wrist snap at contact.", "Catch the rebound and repeat — 5 sets of 10 quality reps."]),
        TrainingBlock(name: "Back Row Attack", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "hitting_back_row", focusTags: ["backRow", "approach", "power"], instructions: ["Start at the 10-foot (3-meter) line — take a controlled step-close approach.", "Jump off both feet and contact the ball high, driving through the seam.", "Land balanced inside the court — back row attacks require precision over max power."]),
        TrainingBlock(name: "Slide Attack Timing", category: .volleyball, durationMinutes: 9, intensity: .medium, imageName: "hitting_slide", focusTags: ["slide", "timing", "rhythm"], instructions: ["Start wide on the right side of the court — approach on a curved path toward the setter.", "Jump off your left foot and attack the ball just behind the setter's location.", "Focus on timing the jump with the set arrival — the slide is about rhythm, not height."]),
        TrainingBlock(name: "Quick Set (First Tempo)", category: .volleyball, durationMinutes: 7, intensity: .medium, imageName: "hitting_quick_set", focusTags: ["quickSet", "timing", "tempo"], instructions: ["Communicate with your setter — you must be in the air before the ball leaves their hands.", "Attack a quick first-tempo set directly in front of the setter's forehead.", "This drill requires trust and timing — run 10 consecutive reps with your setter."]),
        TrainingBlock(name: "Block Vision Read + Hit", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "hitting_read_block", focusTags: ["readBlock", "vision", "decision"], instructions: ["Facing a live block or block simulator — read the block as you approach.", "Decide in the air: tool, roll shot deep corner, or hard-driven cross.", "Score one point for each correct read that results in a kill — 10 points to complete."]),
        TrainingBlock(name: "Serve Float + Topspin Mix", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "serving", focusTags: ["floatServe", "topspin", "consistency"], instructions: ["Alternate between float serves and topspin serves — 5 of each.", "For float: contact the ball with a flat, rigid hand — no follow-through spin.", "For topspin: snap your wrist at contact, follow through low and across your body."]),
        TrainingBlock(name: "Jump Serve Approach", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "serving", focusTags: ["jumpServe", "approach", "power"], instructions: ["Start 10-12 feet behind the baseline — toss the ball high and 3 feet in front.", "Take a 3-step approach: left, right-left — jump and contact at the peak.", "Land inside the court and immediately transition to defense."]),
        TrainingBlock(name: "Setting Hand Position", category: .volleyball, durationMinutes: 6, intensity: .low, imageName: "setting", focusTags: ["hands", "placement", "touch"], instructions: ["Form a diamond with your thumbs and index fingers above your forehead.", "Push through the ball using legs, not just arms — extend fully.", "Release with backspin and repeat 30 quality reps."]),
        TrainingBlock(name: "Setting Footwork + Accuracy", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "setting", focusTags: ["footwork", "accuracy", "hands"], instructions: ["Start at center court: shuffle to a target location, set to a specific spot.", "Alternate between forward sets, back sets, and jump sets.", "Track how many of 20 sets hit the target zone."]),
        TrainingBlock(name: "Quick Set Repetition", category: .volleyball, durationMinutes: 6, intensity: .medium, imageName: "setting", focusTags: ["quickness", "hands", "rhythm"], instructions: ["Receive a rapid series of tossed balls (every 3-4 seconds).", "Focus on fast hand preparation, soft touch, and accurate release.", "Complete 3 rounds of 15 quick sets without a miss."]),
        TrainingBlock(name: "Setter Defense Transition", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "setting", focusTags: ["setterDefense", "transition", "decision"], instructions: ["Start in setter position — coach attacks a ball toward you.", "Dig or deflect the ball to yourself, then stand and deliver a hittable set.", "This simulates the setter as a primary defender — a world-class skill."]),
        TrainingBlock(name: "Set the Long Ball (Back Row)", category: .volleyball, durationMinutes: 6, intensity: .medium, imageName: "setting", focusTags: ["backSet", "accuracy", "power"], instructions: ["Start at the net facing your target — push the ball to a back-row attacker.", "Open your hips to the target and drive through the ball with legs.", "The back-row set requires more arc and pace — land 8 of 10 in the hitting zone."]),
        TrainingBlock(name: "Setter Decision: Dump or Set", category: .volleyball, durationMinutes: 7, intensity: .high, imageName: "setting", focusTags: ["dump", "decision", "vision"], instructions: ["On a tight pass, decide in real-time: set your hitter or dump the ball over.", "When dumping, use soft hands to place the ball over the net into open space.", "Watch the opposing block — if they leave early, the dump is open."]),
        TrainingBlock(name: "Combination Set Play", category: .volleyball, durationMinutes: 10, intensity: .high, imageName: "setting", focusTags: ["combo", "rhythm", "timing"], instructions: ["Run a 2-setter offense or a setter-middle combination: quick set to middle, then back set to right side.", "Alternate between 1-ball (quick), 2-ball (high outside), and a shoot set to the pin.", "Communication is key — call out the set before the pass arrives."]),
        TrainingBlock(name: "Serve Receive Platform", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "serveReceive", focusTags: ["platform", "footwork", "control"], instructions: ["Have a partner serve from the baseline — start in a ready position.", "Present a flat, angled platform to the target (center court).", "Move through the ball, do not reach — 30 quality passes."]),
        TrainingBlock(name: "Serve Receive Under Pressure", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "serveReceive", focusTags: ["pressure", "platform", "reaction"], instructions: ["Partner serves to random zones — you must read, move, and pass.", "Focus on a low, athletic stance and split-step before the serve.", "Target: 8 out of 10 passes land within 3 feet of the setter target."]),
        TrainingBlock(name: "Short Serve Recovery", category: .volleyball, durationMinutes: 6, intensity: .high, imageName: "serveReceive", focusTags: ["shortServe", "reaction", "agility"], instructions: ["Partner serves short (drop) balls just over the net into Zone 2 or 3.", "Explode forward from your base position — pass high to your setter.", "This is the most common missed pass in volleyball — master it."]),
        TrainingBlock(name: "Serve Receive + Attack Transition", category: .volleyball, durationMinutes: 10, intensity: .high, imageName: "serveReceive", focusTags: ["transition", "receiveToAttack", "endurance"], instructions: ["Receive a serve, pass to setter, then immediately transition into an attack approach.", "The sequence must be seamless: pass → watch setter → approach → hit.", "Complete 8-10 repetitions — this builds game-ready endurance."]),
        TrainingBlock(name: "Two-Person Passing Triangle", category: .volleyball, durationMinutes: 6, intensity: .low, imageName: "serveReceive", focusTags: ["passing", "footwork", "consistency"], instructions: ["Two passers stand in base positions — coach tosses to alternating zones.", "Each passer shuffles to the ball, presents platform, and passes to target.", "Focus on moving before the ball crosses the net — early preparation."]),
        TrainingBlock(name: "Defensive Platform Basics", category: .volleyball, durationMinutes: 6, intensity: .low, imageName: "defense", focusTags: ["platform", "bodyPosition", "control"], instructions: ["Get in a low defensive stance — feet shoulder-width, weight on the balls of your feet.", "Present your platform at 45 degrees — absorb the ball, do not swing.", "Shuffle laterally to a coach-tossed ball and pass to target."]),
        TrainingBlock(name: "Defensive Digging Reads", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "defense", focusTags: ["read", "reaction", "dig"], instructions: ["Partner or coach attacks from a box — start in base defense.", "Read the attacker's shoulder line and arm speed to anticipate shot location.", "Dig the ball up to a target zone — 4 sets of 6 attacks."]),
        TrainingBlock(name: "Roll and Pancake Saves", category: .volleyball, durationMinutes: 6, intensity: .high, imageName: "defense", focusTags: ["hustle", "save", "reaction"], instructions: ["Coach tosses balls just out of reach — execute a controlled roll to save.", "Practice the pancake: dive flat, slide the back of your hand under the ball.", "Get up quickly and reset to your base position."]),
        TrainingBlock(name: "Defense from Deep Court", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "defense", focusTags: ["deepDefense", "read", "recovery"], instructions: ["Start on the baseline — coach or partner attacks a deep ball from 30 feet.", "Read the trajectory early, take a drop step, and pursue the ball.", "Dig the ball high to center court — your recovery speed determines success."]),
        TrainingBlock(name: "Two-on-Two Cover Drill", category: .volleyball, durationMinutes: 10, intensity: .high, imageName: "defense", focusTags: ["cover", "communication", "teamDefense"], instructions: ["Two defenders on one side vs two attackers on the opposite side.", "The attackers can tip, roll, or power swing — defenders must talk and move.", "Score by digging the ball up to a controlled location — first to 10 wins."]),
        TrainingBlock(name: "Tip Defense Read", category: .volleyball, durationMinutes: 6, intensity: .medium, imageName: "defense", focusTags: ["tipRead", "reaction", "agility"], instructions: ["Partner approaches but instead of hitting, they tip the ball over the net.", "Read the open palm / soft elbow — this signals a tip — step in immediately.", "Dig the tip high to your setter — do not let it drop."]),
        TrainingBlock(name: "Pepper Progression", category: .volleyball, durationMinutes: 10, intensity: .medium, imageName: "defense", focusTags: ["pepper", "control", "touch"], instructions: ["Standard pepper with a partner: dig → set → hit on a continuous loop.", "Progression 1: 50 consecutive touches without a miss.", "Progression 2: add movement — shuffle laterally between each touch."]),
        TrainingBlock(name: "Block Footwork + Seal", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "blocking", focusTags: ["footwork", "seal", "penetrate"], instructions: ["Start at the net in a ready blocking position.", "Shuffle step to the contact point — keep your hands up and active.", "Penetrate over the net with your hands, sealing the seam."]),
        TrainingBlock(name: "Read Block vs Outside Hitter", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "blocking", focusTags: ["readHitter", "timing", "angle"], instructions: ["Face an outside hitter (live or simulated).", "Read their approach angle and arm swing to decide block position.", "Close the block with your partner — no seam, no split."]),
        TrainingBlock(name: "Adjustable Block (Middle + Pin)", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "blocking", focusTags: ["adjust", "middleBlock", "read"], instructions: ["Start in a middle-block position — coach signals left or right pin.", "Shuffle to the pin and press — read the hitter's shoulder for direction.", "Improve your lateral speed: touch each pin 5 times in under 15 seconds."]),
        TrainingBlock(name: "Block + Recover to Defense", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "blocking", focusTags: ["blockToDefense", "transition", "recovery"], instructions: ["Jump block at the net, then land and immediately drop into a defensive stance.", "Coach attacks a ball after your block — dig the ball to the setter.", "This drill replicates the block → dig sequence that happens on every rally."]),
        TrainingBlock(name: "Double-Block Timing", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "blocking", focusTags: ["doubleBlock", "timing", "communication"], instructions: ["Set up with a blocking partner and an outside hitter — the hitter attacks at game speed.", "Your block call should come before the set arrives: 'Together!' or 'Stay!'", "Both blockers must jump at the same millisecond — no window between hands."]),

        // ===== AGILITY =====
        TrainingBlock(name: "Ladder Quick Footwork", category: .agility, durationMinutes: 8, intensity: .medium, imageName: "agility_ladder", focusTags: ["agility", "footwork", "quickness"], instructions: ["Set up an agility ladder — 2 feet in each box, staying on the balls of your feet.", "Progress through: lateral steps, Icky shuffle, in-in-out pattern.", "Increase speed only when the rhythm is clean — 3 sets of each pattern."]),
        TrainingBlock(name: "Lateral Slide Defense", category: .agility, durationMinutes: 8, intensity: .medium, imageName: "agility_lateral_slides", focusTags: ["defense", "agility", "lateral"], instructions: ["Stay low in a defensive posture the entire drill.", "Push from the inside edge of your foot — keep feet shoulder-width.", "No crossing your feet unless a directional cue is given."]),
        TrainingBlock(name: "5-10-5 Change of Direction", category: .agility, durationMinutes: 9, intensity: .high, imageName: "agility_5_10_5", focusTags: ["agility", "reaction", "explosiveness"], instructions: ["Sprint 5 yards to the right, plant the outside foot, sprint 10 yards left.", "Plant foot under your hip — do not lean before the cut.", "Explode out of each cut — 4-6 reps with full recovery."]),
        TrainingBlock(name: "Reaction Shuffle + Dig", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_reaction_shuffle", focusTags: ["reaction", "defense", "coordination"], instructions: ["Partner points left/right/short/deep — you react and shuffle hard.", "Return to base after every cue before the next direction.", "Add a ball dig at the end of each shuffle to combine agility with defense."]),
        TrainingBlock(name: "T-Drill Agility", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_t_drill", focusTags: ["agility", "footwork", "changeOfDirection"], instructions: ["Set up cones in a T-shape: start at the base, sprint forward to the T junction.", "Shuffle left to touch the cone, shuffle right to the far cone, shuffle back to center.", "Backpedal to the start — 4 reps, rest 60 seconds."]),
        TrainingBlock(name: "Short-Long Recovery Drill", category: .agility, durationMinutes: 6, intensity: .high, imageName: "agility_short_long", focusTags: ["endurance", "agility", "explosiveness"], instructions: ["Sprint 5 yards (short), immediately backpedal to start, then sprint 15 yards (long).", "Focus on explosive acceleration and controlled deceleration.", "Complete 5 sets with 30 seconds rest between sets."]),
        TrainingBlock(name: "Crossover Shuffle Sprint", category: .agility, durationMinutes: 6, intensity: .high, imageName: "agility_crossover", focusTags: ["crossover", "lateralSpeed", "hipOpening"], instructions: ["Start in a defensive stance — crossover step to the right for 2 steps, then shuffle for 2 steps.", "Alternate direction each set — keep your hips open and eyes forward.", "This is a volleyball-specific agility move that mimics a blocker chasing a quick set."]),
        TrainingBlock(name: "Hopscotch Agility", category: .agility, durationMinutes: 6, intensity: .medium, imageName: "agility_hopscotch", focusTags: ["coordination", "rhythm", "footwork"], instructions: ["Use a hopscotch grid (or tape on the floor) — single-leg hops alternating with two-foot landings.", "Maintain a rapid cadence — 3 sets of 30 seconds with 30 seconds rest.", "This drill improves reactive footwork and single-leg stability for landing."]),
        TrainingBlock(name: "Net-Sideline Recovery", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_net_sideline", focusTags: ["recovery", "defense", "endurance"], instructions: ["Start at the net — backpedal to the 10-foot line, sprint forward to the net, then shuffle to the sideline.", "Touch each line and reverse direction immediately.", "Complete 6 continuous rounds — your cardio and agility will improve together."]),
        TrainingBlock(name: "Box Shuffle Pattern", category: .agility, durationMinutes: 7, intensity: .medium, imageName: "agility_box_shuffle", focusTags: ["boxPattern", "changeOfDirection", "footwork"], instructions: ["Set up 4 cones in a 5x5 yard box — start at cone 1, shuffle forward to cone 2.", "Slide right to cone 3, backpedal to cone 4, shuffle left back to cone 1.", "Complete 5 full cycles in each direction."]),
        TrainingBlock(name: "Single-Leg Hops (Speed)", category: .agility, durationMinutes: 5, intensity: .medium, imageName: "agility_single_leg_hops", focusTags: ["singleLeg", "explosiveness", "ankleStiffness"], instructions: ["Stand on one leg — hop forward 10 yards, hop backward to start.", "Switch legs — minimal ground contact, like a quick rebound.", "This drill builds the ankle stiffness needed for explosive blocking and landing."]),
        TrainingBlock(name: "Ball Drop Reaction", category: .agility, durationMinutes: 6, intensity: .high, imageName: "agility_ball_drop", focusTags: ["reaction", "speed", "explosiveness"], instructions: ["Hold a ball at shoulder height and drop it — catch it before it bounces twice.", "Variation: partner drops the ball from behind you — you must turn and catch.", "This trains the split-second reactive speed required for emergency digs."]),
        TrainingBlock(name: "Icky Shuffle Ladder", category: .agility, durationMinutes: 6, intensity: .medium, imageName: "agility_icky_shuffle", focusTags: ["icky", "coordination", "footworkPattern"], instructions: ["Face the ladder at one end — pattern: in, in, out (left foot in, right foot in, both feet out).", "Repeat down the ladder, then shuffle backward to the start.", "The Icky shuffle trains the complex footwork needed for multi-directional volleyball movement."]),
        TrainingBlock(name: "Perimeter Court Sprint", category: .agility, durationMinutes: 6, intensity: .high, imageName: "agility_court_perimeter", focusTags: ["endurance", "speed", "changeOfDirection"], instructions: ["Start at the center of the baseline — sprint to the right sideline, shuffle to the net.", "Sprint across the net line, shuffle down the left sideline, backpedal to start.", "Complete 3 full laps — this is game-level conditioning."]),
        TrainingBlock(name: "Figure-8 Cone Drill", category: .agility, durationMinutes: 7, intensity: .medium, imageName: "agility_figure8", focusTags: ["figure8", "curvilinear", "footwork"], instructions: ["Set two cones 6 yards apart — weave through them in a figure-8 pattern.", "Stay low and push off the outside foot around each cone.", "This drill trains curvilinear speed — moving around blockers and defenders."]),
        TrainingBlock(name: "Hexagon Agility Test", category: .agility, durationMinutes: 6, intensity: .high, imageName: "agility_combo", focusTags: ["hexagon", "multiDirectional", "speed"], instructions: ["Draw a hexagon with 24-inch sides — stand in the center facing one direction.", "Hop over each side and back to center without turning your body.", "Complete 3 clockwise rotations and 3 counter-clockwise — stay on the balls of your feet."]),

        // ===== PLYOMETRICS =====
        TrainingBlock(name: "Box Jump Power", category: .plyometrics, durationMinutes: 8, intensity: .high, imageName: "plyo_box_jumps", focusTags: ["jump", "plyo", "explosiveness"], instructions: ["Use a safe box height (12-24 inches depending on ability).", "Step off the box, immediately jump vertically as high as possible.", "Land softly — stick the landing for 2 seconds before resetting."]),
        TrainingBlock(name: "Depth Drop + Vertical", category: .plyometrics, durationMinutes: 8, intensity: .high, imageName: "plyo_depth_jump_vertical", focusTags: ["reactive", "vertical", "explosiveness"], instructions: ["Step off a 12-18 inch box — upon landing, explode into a max vertical jump.", "Minimize ground contact time — think 'hot plate' under your feet.", "3 sets of 5 reps with 90 seconds rest between sets."]),
        TrainingBlock(name: "Lateral Bounds (Skater Hops)", category: .plyometrics, durationMinutes: 7, intensity: .medium, imageName: "plyo_lateral_bounds", focusTags: ["agility", "lateral", "explosiveness"], instructions: ["Stand on one leg — bound laterally as far as possible, landing on the opposite leg.", "Stick the landing for 1 second before exploding back the other direction.", "Keep your chest up and hips loaded — 3 sets of 6 per side."]),
        TrainingBlock(name: "Split Jumps", category: .plyometrics, durationMinutes: 6, intensity: .medium, imageName: "plyo_split_jumps", focusTags: ["split", "rhythm", "groundContact"], instructions: ["Start in a lunge position — jump and switch legs in the air.", "Land softly with both knees bent — minimize ground contact time.", "4 sets of 8 (each leg) with 45 seconds rest."]),
        TrainingBlock(name: "Broad Jump + Stick", category: .plyometrics, durationMinutes: 6, intensity: .high, imageName: "plyo_broad_jump", focusTags: ["explosiveness", "deceleration", "power"], instructions: ["Stand with feet shoulder-width — squat, load hips, explode horizontally.", "Land with both feet simultaneously and stick the landing for 2 seconds.", "Measure your distance and try to beat your previous mark — 4 sets of 3."]),
        TrainingBlock(name: "Pogo Hops", category: .plyometrics, durationMinutes: 5, intensity: .medium, imageName: "plyo_pogo", focusTags: ["ankleStiffness", "rhythm", "groundContact"], instructions: ["Keep your legs straight — bounce off the balls of your feet like a pogo stick.", "Minimize ground contact — the goal is quick, reactive rebounds.", "3 sets of 15 seconds, rest 30 seconds."]),
        TrainingBlock(name: "Single-Leg Box Jump", category: .plyometrics, durationMinutes: 6, intensity: .high, imageName: "plyo_single_leg_forward", focusTags: ["singleLeg", "stability", "explosiveness"], instructions: ["Use a lower box (6-12 inches) — stand on one leg and jump onto the box.", "Land on the same leg and hold for 2 seconds before stepping down.", "This is the highest-level plyometric for volleyball — it builds landing stability and single-leg power."]),
        TrainingBlock(name: "Hurdle Hops (Lateral)", category: .plyometrics, durationMinutes: 7, intensity: .high, imageName: "plyo_hurdle_lateral", focusTags: ["hurdle", "lateral", "explosiveness"], instructions: ["Set 3-4 low hurdles (6-12 inches) in a row — hop laterally over each one.", "Land softly and immediately spring over the next hurdle.", "Complete 3 sets of the full course in each direction."]),
        TrainingBlock(name: "Depth Lateral Drop", category: .plyometrics, durationMinutes: 7, intensity: .high, imageName: "plyo_depth_lateral", focusTags: ["lateral", "reactive", "explosiveness"], instructions: ["Stand on a low box (12 inches) sideways — step off laterally and explode sideways on landing.", "This mimics the lateral reactive step needed for blocking and defensive slides.", "3 sets of 5 reps each direction with 60 seconds rest."]),
        TrainingBlock(name: "Diagonal Bounds", category: .plyometrics, durationMinutes: 6, intensity: .high, imageName: "plyo_diagonal_bounds", focusTags: ["diagonal", "explosiveness", "coordination"], instructions: ["Start on one foot — bound forward and diagonally at a 45-degree angle.", "Land on the opposite foot and immediately bound back diagonally.", "This trains the multi-directional explosive movement required for volleyball."]),
        TrainingBlock(name: "Standing Long Jump Triple", category: .plyometrics, durationMinutes: 6, intensity: .high, imageName: "plyo_broad_jump", focusTags: ["tripleJump", "power", "endurance"], instructions: ["Perform three consecutive broad jumps from a standing start — no pause between jumps.", "The third jump should still reach 80% of your first jump distance — if not, your power endurance needs work.", "3 sets of 1 triple jump with full recovery."]),
        TrainingBlock(name: "Rebound Jumps (Low Box)", category: .plyometrics, durationMinutes: 5, intensity: .high, imageName: "plyo_rebound", focusTags: ["rebound", "groundContact", "reactive"], instructions: ["Stand on a 6-8 inch box — step off and rebound up as fast as possible.", "Focus on 0.2 second ground contact — explosive up, no pausing on the ground.", "3 sets of 8 reps — this is the gold standard for reactive jump training."]),
        TrainingBlock(name: "Tuck Jumps", category: .plyometrics, durationMinutes: 5, intensity: .high, imageName: "plyo_tuck_jumps", focusTags: ["tuckJump", "verticalPower", "explosiveness"], instructions: ["Stand with feet shoulder-width — jump as high as possible and drive both knees to your chest.", "Extend fully before landing — this trains the hip flexor explosion needed for vertical reach.", "3 sets of 6 reps with 45 seconds rest."]),
        TrainingBlock(name: "Lateral Box Push-Off", category: .plyometrics, durationMinutes: 6, intensity: .high, imageName: "plyo_box_lateral", focusTags: ["lateralBox", "pushOff", "explosiveness"], instructions: ["Stand next to a low box (12 inches) — step up laterally, push off the box, and land on the other side.", "Immediately explode into a lateral jump back over the box.", "This builds the lateral push-off power needed for blocking and shuffling."]),
        TrainingBlock(name: "Jump Matrix Pattern", category: .plyometrics, durationMinutes: 8, intensity: .high, imageName: "plyo_jump_matrix", focusTags: ["matrix", "multiDirectional", "endurance"], instructions: ["Stand in the center of a 4-cone matrix (front, back, left, right cones spaced 3 yards).", "Jump to the front cone, back to center, right cone, back to center — complete all 4 directions.", "Each direction counts as one rep — complete 10 total reps with no pausing."]),
        TrainingBlock(name: "Ankle Stiffness Hops", category: .plyometrics, durationMinutes: 5, intensity: .medium, imageName: "plyo_ankle_stiffness", focusTags: ["ankleStiffness", "rhythm", "groundContact"], instructions: ["Keep your knees as straight as possible — hop forward and backward using only ankle movement.", "The goal is 50 hops in 30 seconds — stiff ankles = faster rebounds = higher blocks.", "3 sets of 30 seconds with 30 seconds rest."]),

        // ===== STRENGTH =====
        TrainingBlock(name: "Core Stability Holds", category: .strength, durationMinutes: 7, intensity: .medium, imageName: "core_stability", focusTags: ["core", "stability", "powerTransfer"], instructions: ["Front plank: 30 seconds — keep a straight line from head to heels.", "Side plank: 20 seconds each side — stack your feet and lift hips.", "Dead bugs: 10 reps each side — slow, controlled, press lower back into the floor."]),
        TrainingBlock(name: "Glute + Hamstring Activation", category: .strength, durationMinutes: 6, intensity: .low, imageName: "core_stability", focusTags: ["glute", "hamstring", "mobility"], instructions: ["Glute bridges: 15 reps — squeeze at the top for 2 seconds.", "Single-leg Romanian deadlifts: 8 reps per leg — slow tempo.", "Walking lunges: 10 reps per leg — keep your front shin vertical."]),
        TrainingBlock(name: "Rotator Cuff + Shoulder Stability", category: .strength, durationMinutes: 6, intensity: .low, imageName: "stretch_shoulder_prep", focusTags: ["shoulder", "stability", "injuryPrevention"], instructions: ["External rotation with band: 12 reps per arm.", "Y-T-W-L raises: 8 reps each letter — slow and controlled.", "Finish with scapular push-ups: 10 reps."]),
        TrainingBlock(name: "Bulgarian Split Squats", category: .strength, durationMinutes: 8, intensity: .medium, imageName: "core_stability", focusTags: ["singleLeg", "strength", "balance"], instructions: ["Place your back foot on a bench or box — lower into a lunge with your front leg.", "Drive through your front heel to return to standing — this builds unilateral leg power for jumping.", "3 sets of 8 reps per leg with 60 seconds rest."]),
        TrainingBlock(name: "Hip Thrusters", category: .strength, durationMinutes: 6, intensity: .medium, imageName: "core_stability", focusTags: ["glute", "hipExtension", "power"], instructions: ["Sit on the floor with your upper back against a bench — place a barbell or plate across your hips.", "Drive through your heels to lift your hips as high as possible — squeeze glutes at the top.", "This is the most important strength exercise for vertical jump development."]),
        TrainingBlock(name: "Medicine Ball Rotational Toss", category: .strength, durationMinutes: 6, intensity: .medium, imageName: "core_stability", focusTags: ["rotation", "powerTransfer", "core"], instructions: ["Stand sideways to a wall — hold a medicine ball at hip height and rotate your torso away from the wall.", "Explosively rotate back and throw the ball against the wall — catch and repeat.", "This builds the rotational power needed for arm swing velocity."]),
        TrainingBlock(name: "Single-Leg Calf Raises", category: .strength, durationMinutes: 5, intensity: .low, imageName: "core_stability", focusTags: ["calf", "ankleStrength", "stability"], instructions: ["Stand on one leg on a step — lower your heel below the step level, then press up as high as possible.", "This directly strengthens the ankle and calf for explosive jumping and safe landing.", "3 sets of 15 reps per leg with minimal rest."]),
        TrainingBlock(name: "Pull-Ups / Lat Pulldowns", category: .strength, durationMinutes: 7, intensity: .medium, imageName: "core_stability", focusTags: ["back", "lat", "armSwing"], instructions: ["Perform pull-ups or lat pulldowns with a wide grip — focus on driving your elbows down.", "The lats (latissimus dorsi) are the primary muscle for arm swing power in a volleyball spike.", "3 sets of as many reps as possible with 90 seconds rest."]),
        TrainingBlock(name: "Overhead Medicine Ball Slam", category: .strength, durationMinutes: 5, intensity: .high, imageName: "core_stability", focusTags: ["slam", "explosiveness", "totalBody"], instructions: ["Hold a medicine ball overhead — slam it into the ground as hard as possible.", "Sit down into the slam to engage your legs and core — not just your arms.", "This full-body explosive movement translates directly to attack power."]),
        TrainingBlock(name: "Kettlebell Swing", category: .strength, durationMinutes: 7, intensity: .medium, imageName: "stretch_leg_prep", focusTags: ["kettlebell", "hipHinge", "power"], instructions: ["Stand with feet shoulder-width apart — hinge at your hips, not your knees.", "Drive your hips forward to swing the kettlebell to chest height — the power comes from your glutes, not your arms.", "3 sets of 15 reps — this builds the explosive hip extension needed for jumping."]),
        TrainingBlock(name: "Pistol Squat Progression", category: .strength, durationMinutes: 6, intensity: .medium, imageName: "stretch_hamstring_dynamic", focusTags: ["pistolSquat", "singleLeg", "balance"], instructions: ["Stand on one leg with the other leg extended forward — lower as far as you can control.", "Use a bench or TRX strap for assistance if needed — the goal is full range of motion.", "Single-leg strength is the #1 predictor of landing injury prevention in volleyball."]),
        TrainingBlock(name: "Farmer's Carry", category: .strength, durationMinutes: 5, intensity: .medium, imageName: "stretch_full_body", focusTags: ["grip", "stability", "endurance"], instructions: ["Hold a dumbbell (or kettlebell) in each hand — walk 30 yards with perfect posture.", "Keep your shoulders back, chest up, and core braced — do not lean to one side.", "This builds the shoulder stability needed for repetitive arm swing motion."]),
        TrainingBlock(name: "Resistance Band Lateral Walk", category: .strength, durationMinutes: 5, intensity: .low, imageName: "stretch_leg_prep", focusTags: ["lateral", "gluteActivation", "injuryPrevention"], instructions: ["Place a resistance band around your ankles — stay in a quarter-squat position.", "Take controlled lateral steps — keep tension on the band the entire time.", "This activates the gluteus medius — critical for knee stability during blocking and landing."]),

        // ===== STRETCHING / WARMUP =====
        TrainingBlock(name: "Arm Circles Dynamic", category: .stretching, durationMinutes: 3, intensity: .low, imageName: "stretch_shoulder_prep", focusTags: ["shoulder", "mobility", "warmup"], instructions: ["Stand with arms extended to your sides — make small, controlled circles forward for 15 seconds.", "Gradually increase the circle size each set — repeat backward for 15 seconds.", "This dynamic stretch improves shoulder range of motion for the arm swing."]),
        TrainingBlock(name: "Leg Swings (Forward + Lateral)", category: .stretching, durationMinutes: 3, intensity: .low, imageName: "stretch_hamstring_dynamic", focusTags: ["hamstring", "hip", "mobility"], instructions: ["Hold onto a wall or post — swing your leg forward and backward 10 times per leg.", "Then face the wall and swing your leg side to side 10 times per leg.", "This dynamic movement prepares the hamstrings and hips for explosive jumping."]),
        TrainingBlock(name: "Walking Knee Hugs", category: .stretching, durationMinutes: 3, intensity: .low, imageName: "stretch_leg_prep", focusTags: ["glute", "hipMobility", "warmup"], instructions: ["Walk forward — as you step, pull your knee into your chest and hold for 2 seconds.", "Alternate legs each step — this stretches the glutes and opens the hips.", "Perform 10 reps per leg — this is a standard college volleyball warmup movement."]),
        TrainingBlock(name: "Inchworm to Cobra", category: .stretching, durationMinutes: 3, intensity: .low, imageName: "stretch_full_body", focusTags: ["fullBody", "mobility", "core"], instructions: ["Stand tall — fold forward and walk your hands out to a push-up position.", "Lower your hips into a cobra stretch (chest up, hips down), then walk your hands back to your feet.", "This single movement stretches the hamstrings, lower back, and hip flexors."]),
        TrainingBlock(name: "Deep Lunge with Rotation", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_tspine", focusTags: ["lunge", "tspine", "mobility"], instructions: ["Step into a deep lunge with your right foot forward — place your left hand on the floor inside your foot.", "Rotate your chest open toward your right knee — reach your right hand to the ceiling.", "This is the gold standard volleyball warmup stretch — it opens the hips and thoracic spine."]),
        TrainingBlock(name: "Cat-Cow Spinal Mobility", category: .stretching, durationMinutes: 3, intensity: .low, imageName: "stretch_leg_prep", focusTags: ["spine", "mobility", "core"], instructions: ["Start on your hands and knees — alternate between arching your back (cow) and rounding your back (cat).", "Move slowly with your breath — 5 seconds per position.", "This prepares the spine for the extreme arch position required in a volleyball spike."]),
        TrainingBlock(name: "Frog Stretch", category: .stretching, durationMinutes: 3, intensity: .low, imageName: "stretch_hip_mobility", focusTags: ["hip", "groin", "mobility"], instructions: ["Start on all fours — widen your knees as far as comfortable with your feet together.", "Slowly sit back toward your heels — hold for 20 seconds, then release.", "This deep hip stretch is essential for the low defensive stance and split-step."]),
        TrainingBlock(name: "Standing Quad Stretch with Balance", category: .stretching, durationMinutes: 3, intensity: .low, imageName: "stretch_balance", focusTags: ["quad", "balance", "stability"], instructions: ["Stand on one leg — pull your opposite heel toward your glute — hold for 15 seconds.", "Challenge your balance by closing your eyes — this prepares the landing stabilizers.", "Repeat on each leg twice — this is both a stretch and a balance exercise."]),
        TrainingBlock(name: "Hamstring Sweep", category: .stretching, durationMinutes: 3, intensity: .low, imageName: "stretch_hamstring_dynamic", focusTags: ["hamstring", "dynamic", "mobility"], instructions: ["Stand with feet together — sweep your right leg across your body and up to the left.", "Alternate legs in a controlled rhythm — this is a dynamic hamstring stretch.", "The hamstring sweep mimics the leg action of a volleyball approach jump."]),
        TrainingBlock(name: "90-90 Hip Stretch", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_hip_mobility", focusTags: ["hip", "externalRotation", "mobility"], instructions: ["Sit with one leg bent 90 degrees in front of you and the other bent 90 degrees behind you.", "Sit up tall and lean slightly forward — hold for 30 seconds, then switch sides.", "This external hip rotation stretch is critical for maintaining hip health in volleyball."]),
        TrainingBlock(name: "Open-Book Thoracic Rotation", category: .stretching, durationMinutes: 3, intensity: .low, imageName: "stretch_tspine", focusTags: ["tspine", "rotation", "shoulderMobility"], instructions: ["Lie on your side with both arms extended in front of you, knees bent at 90 degrees.", "Slowly open your top arm to the opposite side — follow your hand with your eyes.", "This thoracic spine mobility directly improves your arm swing reach and power."]),
        TrainingBlock(name: "Full-Body Stretch Flow", category: .stretching, durationMinutes: 5, intensity: .low, imageName: "stretch_full_body", focusTags: ["fullBody", "recovery", "flexibility"], instructions: ["Move through a continuous flow: standing forward fold → half-lift → plank → downward dog → forward fold.", "Flow through each movement with your breath — hold each position for 3 breaths.", "This yoga-inspired flow improves overall flexibility and reduces injury risk."]),
        TrainingBlock(name: "Pre-Hop Leg Activation", category: .warmup, durationMinutes: 3, intensity: .low, imageName: "stretch_prejump", focusTags: ["legActivation", "plyo", "warmup"], instructions: ["Stand on one leg — perform 10 mini-hops (1 inch off the ground) as quickly as possible.", "Switch legs — this activates the fast-twitch fibers in your calves and ankles.", "Follow with 5 max-effort vertical jumps — this primes your nervous system for competition."]),
        TrainingBlock(name: "Dynamic Leg Prep Circuit", category: .warmup, durationMinutes: 5, intensity: .low, imageName: "stretch_vb_flow", focusTags: ["dynamicPrep", "warmup", "mobility"], instructions: ["Perform each movement for 15 yards: butt kicks, high knees, karaoke (carioca), walking lunges.", "Rest 30 seconds and repeat the circuit — this raises core temperature and activates every leg muscle.", "This is the exact warmup used by NCAA Division I volleyball teams before every practice."])
    ]

    static var allLibraryDrills: [TrainingBlock] { warmups + drills }

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

        var planBlocks = Array(warmups.prefix(3))
        var candidates = drills.filter { block in !Set(block.focusTags).isDisjoint(with: Set(tags)) }
        if candidates.count < 5 { candidates += drills.filter { !candidates.contains($0) } }

        var activeMinutes = planBlocks.reduce(0) { $0 + $1.durationMinutes }
        for block in candidates {
            guard activeMinutes + block.durationMinutes <= targetMinutes else { continue }
            planBlocks.append(block)
            activeMinutes += block.durationMinutes
        }

        if activeMinutes < targetMinutes - 3 {
            for block in candidates.shuffled() {
                guard activeMinutes + block.durationMinutes <= targetMinutes, !planBlocks.contains(block) else { continue }
                planBlocks.append(block)
                activeMinutes += block.durationMinutes
            }
        }

        planBlocks = insertWaterBreaks(in: planBlocks)
        return TrainingPlan(id: UUID(), name: "Coach Plan: \(focus.capitalized)", focus: focus, createdAt: Date(), blocks: planBlocks)
    }

    static func generatePlan(categories: [TrainingCategory], targetMinutes: Int) -> TrainingPlan {
        let categorySet = Set(categories)
        var planBlocks = Array(warmups.shuffled().prefix(3))
        var candidates = drills.filter { categorySet.contains($0.category) }
        if candidates.isEmpty { candidates = Array(drills.shuffled().prefix(5)) }

        var activeMinutes = planBlocks.reduce(0) { $0 + $1.durationMinutes }
        for block in candidates {
            guard activeMinutes + block.durationMinutes <= targetMinutes else { continue }
            planBlocks.append(block)
            activeMinutes += block.durationMinutes
        }

        if activeMinutes < targetMinutes - 3 {
            for block in candidates.shuffled() {
                guard activeMinutes + block.durationMinutes <= targetMinutes, !planBlocks.contains(block) else { continue }
                planBlocks.append(block)
                activeMinutes += block.durationMinutes
            }
        }

        planBlocks = insertWaterBreaks(in: planBlocks)
        let focusName = categories.map { $0.rawValue }.joined(separator: " + ")
        return TrainingPlan(id: UUID(), name: "User Plan: \(focusName)", focus: focusName, createdAt: Date(), blocks: planBlocks)
    }

    static func insertWaterBreaks(in blocks: [TrainingBlock]) -> [TrainingBlock] {
        var result: [TrainingBlock] = []
        var minutesSinceBreak = 0
        for (index, block) in blocks.enumerated() {
            result.append(block)
            minutesSinceBreak += block.durationMinutes
            let hasWorkoutRemaining = index < blocks.count - 1
            if hasWorkoutRemaining && minutesSinceBreak >= 12 {
                result.append(.waterBreak())
                minutesSinceBreak = 0
            }
        }
        if result.last?.category == .waterBreak { result.removeLast() }
        return result
    }
}

// MARK: - Blended card modifier
private struct BlendedCard: ViewModifier {
    func body(content: Content) -> some View {
        content.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.black.opacity(0.5)).cornerRadius(16)
    }
}
private extension View { func blendedCard() -> some View { modifier(BlendedCard()) } }

// MARK: - Custom Segmented Picker with Pink Text
private struct PinkSegmentedPicker: View {
    @Binding var selection: TrainingGenerationMode
    let options: [TrainingGenerationMode]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                Button(action: { selection = option }) {
                    Text(option.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(selection == option ? .pink : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == option ? Color.black.opacity(0.3) : Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                if option != options.last {
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

// MARK: - Training Hub View
struct TrainingHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var hits: [VolleyballHit]
    @Query(sort: \SavedTrainingPlan.createdAt, order: .reverse) private var savedPlans: [SavedTrainingPlan]
    @State private var generatedPlan: TrainingPlan?
    @State private var showingSaved = false
    @State private var mode: TrainingGenerationMode = .aiCoach
    @State private var selectedCategories: Set<TrainingCategory> = []
    @State private var customDrills: [TrainingBlock] = []
    @State private var durationMinutes: Int = 60
    @State private var showingCustomBuilder = false
    @Environment(\.dismiss) private var dismiss

    private var coachFocus: String { VolleyballTrainingLibrary.recommendationFocus(from: hits) }

    private func generatePlan() {
        switch mode {
        case .aiCoach:
            generatedPlan = VolleyballTrainingLibrary.generatePlan(focus: coachFocus, targetMinutes: durationMinutes)
        case .userGenerated:
            let cats = Array(selectedCategories)
            generatedPlan = VolleyballTrainingLibrary.generatePlan(categories: cats.isEmpty ? TrainingCategory.allCases.filter { $0 != .waterBreak } : cats, targetMinutes: durationMinutes)
        case .customBuilt:
            if !customDrills.isEmpty {
                let blocks = VolleyballTrainingLibrary.insertWaterBreaks(in: customDrills)
                generatedPlan = TrainingPlan(id: UUID(), name: "Custom Plan", focus: "Custom", createdAt: Date(), blocks: blocks)
            }
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image("background").resizable().scaledToFill().ignoresSafeArea()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer(minLength: 80)
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
                                }.buttonStyle(PlainButtonStyle()); Spacer()
                            }.padding(.top, 16)
                            header
                            Spacer(minLength: 160)
                            PinkSegmentedPicker(selection: $mode, options: TrainingGenerationMode.allCases)
                            durationControl
                            modeContent
                            actionButtons
                        }.padding(.horizontal, 24)
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(item: $generatedPlan) { plan in TrainingScheduleView(plan: plan) }
                .sheet(isPresented: $showingSaved) { SavedTrainingsView() }
                .sheet(isPresented: $showingCustomBuilder) {
                    CustomDrillBuilderView(selectedDrills: $customDrills, targetMinutes: durationMinutes)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Training Hub").font(.title2.bold()).foregroundColor(.white)
            Text("Generate workouts from AI coach feedback, category focus, or build your own custom routine.").font(.caption).foregroundColor(.gray)
        }
    }

    private var durationControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration: \(durationMinutes) min").font(.caption.bold()).foregroundColor(.white)
            Slider(value: Binding(get: { Double(durationMinutes) }, set: { durationMinutes = Int($0) }), in: 30...120, step: 15).tint(.cyan)
        }.blendedCard()
    }

    @ViewBuilder private var modeContent: some View {
        switch mode {
        case .aiCoach: aiCoachCard
        case .userGenerated: userGeneratedCard
        case .customBuilt: customBuiltCard
        }
    }

    private var aiCoachCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coach Recommendation").font(.headline).foregroundColor(.pink)
            Text(coachFocus.capitalized).font(.title3.bold()).foregroundColor(.white)
            Text("Based on your most recent hit feedback. Adjust duration above and generate a plan.").font(.caption).foregroundColor(.gray)
        }.blendedCard()
    }

    private var userGeneratedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Categories").font(.headline).foregroundColor(.pink)
            let allCategories = TrainingCategory.allCases.filter { $0 != .waterBreak }
            Button(action: {
                if selectedCategories.count == allCategories.count { selectedCategories = [] }
                else { selectedCategories = Set(allCategories) }
            }) {
                Text(selectedCategories.count == allCategories.count ? "Deselect All" : "Select All")
                    .font(.caption.bold()).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.3)).cornerRadius(10)
            }.buttonStyle(PlainButtonStyle())
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(allCategories) { cat in
                        let isSelected = selectedCategories.contains(cat)
                        Button(action: { if isSelected { selectedCategories.remove(cat) } else { selectedCategories.insert(cat) } }) {
                            Text(cat.rawValue).font(.caption.bold())
                                .foregroundColor(isSelected ? .black : cat.color)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(isSelected ? cat.color : Color.clear).cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(cat.color.opacity(0.6), lineWidth: 1.5))
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }.blendedCard()
    }

    private var customBuiltCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Custom Drill Builder").font(.headline).foregroundColor(.pink)
            if customDrills.isEmpty {
                Text("No drills selected yet. Tap the button below to pick drills by category.").font(.caption).foregroundColor(.gray)
            } else {
                Text("\(customDrills.count) drills selected • \(customDrills.reduce(0) { $0 + $1.durationMinutes }) min total")
                    .font(.caption).foregroundColor(.cyan)
                ScrollView {
                    ForEach(customDrills) { drill in
                        HStack {
                            Text(drill.name).font(.caption).foregroundColor(.white); Spacer()
                            Text("\(drill.durationMinutes) min").font(.caption2).foregroundColor(.gray)
                        }.padding(.horizontal, 8).padding(.vertical, 4).background(Color.white.opacity(0.08)).cornerRadius(6)
                    }
                }.frame(maxHeight: 120)
            }
            Button(action: { showingCustomBuilder = true }) {
                Text(customDrills.isEmpty ? "Select Drills" : "Edit Drills")
                    .font(.caption.bold()).foregroundColor(.black).padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.purple).cornerRadius(10)
            }.buttonStyle(PlainButtonStyle())
        }.blendedCard()
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button("Generate Plan") { generatePlan() }
                .buttonStyle(TrainingButtonStyle(color: .cyan, foreground: .black))
                .disabled(mode == .customBuilt && customDrills.isEmpty)
            Button("Saved Trainings (\(savedPlans.count))") { showingSaved = true }
                .buttonStyle(TrainingButtonStyle(color: .purple, foreground: .white))
        }
    }
}

// MARK: - Custom Drill Builder with Target Duration
struct CustomDrillBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDrills: [TrainingBlock]
    let targetMinutes: Int
    @State private var selectedCategories: Set<TrainingCategory> = []

    private var allCategories: [TrainingCategory] { TrainingCategory.allCases.filter { $0 != .waterBreak } }
    private var availableDrills: [TrainingBlock] {
        let cats = selectedCategories.isEmpty ? allCategories : Array(selectedCategories)
        return VolleyballTrainingLibrary.allLibraryDrills.filter { cats.contains($0.category) }
    }

    private var selectedMinutes: Int { selectedDrills.reduce(0) { $0 + $1.durationMinutes } }
    private var remainingMinutes: Int { max(0, targetMinutes - selectedMinutes) }
    private var isAtCapacity: Bool { selectedMinutes >= targetMinutes }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()
                VStack(spacing: 12) {
                    // Header with cumulative time
                    HStack {
                        Text("Pick Drills")
                            .font(.title2.bold())
                            .foregroundColor(.pink)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Cumulative time bar
                    HStack {
                        Image(systemName: "clock.fill").foregroundColor(.cyan).font(.caption)
                        Text("\(selectedMinutes) min selected of \(targetMinutes) min target")
                            .font(.caption.bold()).foregroundColor(.white)
                        Spacer()
                        if isAtCapacity {
                            Text("✓ Full").font(.caption.bold()).foregroundColor(.green)
                        } else {
                            Text("\(remainingMinutes) min left").font(.caption).foregroundColor(.yellow)
                        }
                    }
                    .padding().background(Color.black.opacity(0.4)).cornerRadius(12)
                    .padding(.horizontal)

                    categoryFilter
                    drillGrid
                    selectedSummary
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { selectedCategories.removeAll() }) {
                    Text("All").font(.caption.bold())
                        .foregroundColor(selectedCategories.isEmpty ? .black : .white)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(selectedCategories.isEmpty ? Color.cyan : Color.clear).cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.6), lineWidth: 1.5))
                }.buttonStyle(PlainButtonStyle())
                ForEach(allCategories) { cat in
                    let isSelected = selectedCategories.contains(cat)
                    Button(action: { if isSelected { selectedCategories.remove(cat) } else { selectedCategories.insert(cat) } }) {
                        Text(cat.rawValue).font(.caption.bold())
                            .foregroundColor(isSelected ? .black : cat.color)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(isSelected ? cat.color : Color.clear).cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(cat.color.opacity(0.6), lineWidth: 1.5))
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }.padding(.horizontal)
    }

    private var drillGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(availableDrills) { drill in
                    let isSelected = selectedDrills.contains(drill)
                    let wouldExceed = !isSelected && selectedMinutes + drill.durationMinutes > targetMinutes
                    Button(action: {
                        if isSelected { selectedDrills.removeAll { $0.id == drill.id } }
                        else if !wouldExceed { selectedDrills.append(drill) }
                    }) {
                        VStack(spacing: 6) {
                            Image(drill.imageName).resizable().scaledToFit().frame(height: 50).cornerRadius(8)
                            Text(drill.name).font(.caption2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
                            Text("\(drill.durationMinutes) min").font(.caption2).foregroundColor(.gray)
                        }
                        .padding(10).frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? drill.category.color.opacity(0.25) : Color(red: 0.14, green: 0.14, blue: 0.16)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                            wouldExceed ? Color.gray.opacity(0.2) : drill.category.color.opacity(isSelected ? 0.8 : 0.3),
                            lineWidth: isSelected ? 2 : (wouldExceed ? 0.5 : 1)))
                        .opacity(wouldExceed ? 0.4 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(wouldExceed)
                }
            }
        }.padding(.horizontal)
    }

    private var selectedSummary: some View {
        HStack {
            Text("\(selectedDrills.count) drills selected").font(.caption).foregroundColor(.gray)
            Spacer()
        }.padding(.horizontal)
    }
}

// MARK: - Training Schedule View
struct TrainingScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    let plan: TrainingPlan
    @State private var selectedBlock: TrainingBlock?
    @State private var saveName = ""
    @State private var showSaveName = false
    @State private var lastSavedName: String?
    @State private var showSaveConfirm = false
    @State private var timers: [UUID: Int] = [:]
    @State private var running: Set<UUID> = []

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()
            VStack(spacing: 12) {
                summary
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(plan.blocks) { block in
                            if block.category == .waterBreak {
                                waterBreakRow(block)
                            } else {
                                TrainingScheduleRow(block: block, seconds: timers[block.id] ?? block.durationMinutes * 60, isRunning: running.contains(block.id),
                                    onTap: { selectedBlock = block }, onPlay: { running.insert(block.id) }, onPause: { running.remove(block.id) },
                                    onReset: { timers[block.id] = block.durationMinutes * 60; running.remove(block.id) })
                            }
                        }
                    }.padding(.horizontal)
                }
                HStack {
                    Button("Save") { showSaveName = true }.buttonStyle(TrainingButtonStyle(color: .cyan, foreground: .black))
                    ShareLink(item: shareText) { Text("Share") }.buttonStyle(TrainingButtonStyle(color: .yellow, foreground: .black))
                }.padding(.horizontal).padding(.bottom, 8)
            }
        }
        .navigationTitle("Training Schedule").navigationBarTitleDisplayMode(.inline)
        .onAppear { resetTimersIfNeeded() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in tickTimers() }
        .sheet(item: $selectedBlock) { block in TrainingBlockDetailView(block: block) }
        .alert("Name Your Training", isPresented: $showSaveName) {
            TextField("Training name", text: $saveName)
            Button("Cancel", role: .cancel) { saveName = "" }
            Button("Save") { saveTraining() }
        }
        .overlay(Group {
            if showSaveConfirm, let name = lastSavedName {
                VStack { Spacer(); Text("✓ Saved: \(name)").font(.caption.bold()).foregroundColor(.green).padding().background(.black.opacity(0.8)).cornerRadius(12).padding(.bottom, 60) }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: showSaveConfirm)
            }
        })
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plan.name).font(.title3.bold()).foregroundColor(.white)
            Text("\(plan.blocks.count) blocks • \(plan.totalMinutes) min • Focus: \(plan.focus.capitalized)").font(.caption).foregroundColor(.gray)
        }.frame(maxWidth: .infinity, alignment: .leading).padding().background(Color.blue.opacity(0.16)).cornerRadius(14).padding(.horizontal)
    }

    private func waterBreakRow(_ block: TrainingBlock) -> some View {
        Text("WATER BREAK - \(block.durationMinutes) MIN").font(.headline).foregroundColor(Color(red: 1.0, green: 0.08, blue: 0.58))
            .frame(maxWidth: .infinity).padding().background(Color(red: 1.0, green: 0.08, blue: 0.58).opacity(0.16)).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 1.0, green: 0.08, blue: 0.58), lineWidth: 1))
    }

    private var shareText: String { ([plan.name, "Total: \(plan.totalMinutes) min", "Focus: \(plan.focus)"] + plan.blocks.map { "• \($0.name) - \($0.durationMinutes) min" }).joined(separator: "\n") }

    private func resetTimersIfNeeded() { guard timers.isEmpty else { return }; for block in plan.blocks where block.category != .waterBreak { timers[block.id] = block.durationMinutes * 60 } }

    private func tickTimers() {
        for id in running {
            guard let value = timers[id], value > 0 else { continue }
            timers[id] = value - 1
            if value - 1 == 0 { running.remove(id); AudioServicesPlaySystemSound(1519) }
        }
    }

    private func saveTraining() {
        let name = saveName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? plan.name : saveName
        modelContext.insert(SavedTrainingPlan(name: name, focus: plan.focus, blocks: plan.blocks))
        do {
            try modelContext.save()
            print("Successfully saved training: \(name)")
            lastSavedName = name
            showSaveConfirm = true
            saveName = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSaveConfirm = false }
        } catch {
            print("Failed to save training: \(error.localizedDescription)")
            lastSavedName = "FAILED"
            showSaveConfirm = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSaveConfirm = false }
        }
    }
}

// MARK: - Supporting Views
struct SavedTrainingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedTrainingPlan.createdAt, order: .reverse) private var savedPlans: [SavedTrainingPlan]
    @State private var selectedPlan: TrainingPlan?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(savedPlans) { saved in
                            Button { selectedPlan = TrainingPlan(id: saved.id, name: saved.name, focus: saved.focus, createdAt: saved.createdAt, blocks: saved.blocks) }
                            label: { VStack(alignment: .leading, spacing: 6) {
                                Text(saved.name).foregroundColor(.white).font(.headline)
                                Text("\(saved.totalMinutes) min • \(saved.focus.capitalized)").foregroundColor(.gray).font(.caption)
                                Text("Saved: \(saved.createdAt, style: .date)").font(.caption2).foregroundColor(.gray.opacity(0.6))
                            }
                            .padding().frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.14, green: 0.14, blue: 0.16)))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }.padding(16)
                }
            }
            .navigationTitle("Saved Trainings (\(savedPlans.count))").toolbar { Button("Done") { dismiss() } }
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
                HStack(spacing: 8) { Button("Play", action: onPlay); Button("Pause", action: onPause); Button("Reset", action: onReset) }
                    .font(.caption.bold()).foregroundColor(.white)
            }
        }.padding(10).background(Color.white.opacity(0.08)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(block.category.color.opacity(isRunning ? 1 : 0.45), lineWidth: 1))
    }
    private func format(_ seconds: Int) -> String { "\(seconds / 60):\(String(format: "%02d", seconds % 60))" }
}

struct TrainingBlockRow: View {
    let block: TrainingBlock; let compact: Bool
    var body: some View {
        HStack(spacing: 10) {
            Image(block.imageName).resizable().scaledToFit().frame(width: compact ? 44 : 56, height: compact ? 44 : 56).cornerRadius(8)
            VStack(alignment: .leading, spacing: 3) {
                Text(block.name).font(compact ? .subheadline.bold() : .headline).foregroundColor(.white)
                Text("\(block.durationMinutes) min • \(block.category.rawValue) • \(block.intensity.rawValue.uppercased())").font(.caption).foregroundColor(.gray)
            }; Spacer()
        }
    }
}

struct TrainingBlockDetailView: View {
    let block: TrainingBlock; @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Image(block.imageName).resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: 240).background(Color.black.opacity(0.08)).cornerRadius(16)
                Text(block.name).font(.title2.bold())
                Text("\(block.durationMinutes) min • \(block.category.rawValue) • \(block.intensity.rawValue.uppercased())").foregroundColor(.secondary)
                Text("Instructions").font(.headline)
                ForEach(block.instructions, id: \.self) { line in Text("• \(line)").frame(maxWidth: .infinity, alignment: .leading) }
                Button("Close") { dismiss() }.buttonStyle(TrainingButtonStyle(color: Color(red: 1.0, green: 0.08, blue: 0.58), foreground: .white))
            }.padding()
        }
    }
}

struct TrainingButtonStyle: ButtonStyle {
    let color: Color; let foreground: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold()).foregroundColor(foreground)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1.0)).cornerRadius(10)
    }
}