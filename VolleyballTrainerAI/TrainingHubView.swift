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
        // ------ VOL 1: HITTING / ATTACK ------
        TrainingBlock(name: "Hitting Arm Swing Mechanics", category: .volleyball, durationMinutes: 10, intensity: .medium, imageName: "hitting_arm_swing", focusTags: ["armSwing", "armExtension", "tempo"], instructions: [
            "Load your hitting elbow behind your ear at takeoff.",
            "Contact the ball in front of your body at full reach.",
            "Freeze the finish position and check shoulder-to-wrist alignment."
        ]),
        TrainingBlock(name: "Approach Angle Reps", category: .volleyball, durationMinutes: 9, intensity: .medium, imageName: "hitting_approach_angle", focusTags: ["approach", "timing", "armSwing"], instructions: [
            "Mark your start position and target contact zone.",
            "Use a controlled 3-step approach — left, right-left — with explosive arm drive.",
            "Plant your hips open and attack through the ball into the target."
        ]),
        TrainingBlock(name: "Max Jump Touches", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "hitting_max_jump", focusTags: ["jump", "explosiveness", "vertical"], instructions: [
            "Take a 3-step approach and jump as high as possible toward a safe wall target.",
            "Swing arms aggressively into the takeoff and reach with both hands.",
            "Land softly and reset fully before the next rep — quality over quantity."
        ]),
        TrainingBlock(name: "Hitting High Ball", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_high_ball", focusTags: ["highBall", "contact", "timing"], instructions: [
            "Have a partner toss a high ball or use a ball machine.",
            "Delay the start of your approach until the ball begins to descend.",
            "Contact the ball above your forehead with full wrist snap."
        ]),
        TrainingBlock(name: "Cross Court Target Hits", category: .volleyball, durationMinutes: 10, intensity: .medium, imageName: "hitting_cross_court", focusTags: ["accuracy", "vision", "armSwing"], instructions: [
            "Set up a target in the cross-court zone (1-2 feet inside the line).",
            "Open your shoulders, contact high, and finish with your thumb down.",
            "Track makes vs misses and adjust your approach angle accordingly."
        ]),
        TrainingBlock(name: "Line Shot Accuracy", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_line_shot", focusTags: ["line", "accuracy", "contact"], instructions: [
            "Aim the ball down the line — 1-2 feet inside the sideline.",
            "Keep the ball in front and reach for the top of the ball.",
            "Land balanced and reset to the same starting spot each rep."
        ]),
        TrainingBlock(name: "Hitting Roll Shot", category: .volleyball, durationMinutes: 8, intensity: .low, imageName: "hitting_roll_shot", focusTags: ["touch", "placement", "finesse"], instructions: [
            "Approach with the same tempo as a power swing but reduce arm speed.",
            "Open your hand and roll your fingers over the top of the ball.",
            "Land under control — the roll shot is about placement, not power."
        ]),
        TrainingBlock(name: "Tool the Block Drill", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "hitting_tool_block", focusTags: ["tool", "power", "vision"], instructions: [
            "Set up a blocker or a block target (pads / cones).",
            "Attack aggressively, aiming to hit the top of the blocker's hands.",
            "Use the block to deflect the ball out of bounds — develop block vision."
        ]),
        TrainingBlock(name: "Transition Hitting", category: .volleyball, durationMinutes: 10, intensity: .high, imageName: "hitting_transition", focusTags: ["transition", "decision", "speed"], instructions: [
            "Simulate a defensive-to-offensive transition: start in a base defensive position.",
            "React to a cue (coach toss / hit), then transition into an attack approach.",
            "Make a split-second decision on shot location based on the block."
        ]),
        TrainingBlock(name: "Game Simulation Hitting", category: .volleyball, durationMinutes: 12, intensity: .high, imageName: "hitting_game_sim", focusTags: ["gameSpeed", "readBlock", "decision"], instructions: [
            "Full-court 6-on-6 or 3-on-3 scrimmage focusing on offensive execution.",
            "For each transition, call out your attack choice (line / cross / tool).",
            "Debrief with a teammate after each rally — what worked, what to adjust."
        ]),
        TrainingBlock(name: "Wall Spike Reps", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_wall_spike", focusTags: ["armSwing", "powerTransfer", "contact"], instructions: [
            "Stand 6-8 feet from a solid wall. Toss the ball up and spike into the wall.",
            "Focus on high elbow, full extension, and wrist snap at contact.",
            "Catch the rebound and repeat — 5 sets of 10 quality reps."
        ]),

        // ------ VOL 2: SETTING ------
        TrainingBlock(name: "Setting Hand Position", category: .volleyball, durationMinutes: 6, intensity: .low, imageName: "setting", focusTags: ["hands", "placement", "touch"], instructions: [
            "Form a diamond with your thumbs and index fingers above your forehead.",
            "Push through the ball using legs, not just arms — extend fully.",
            "Release with backspin and repeat 30 quality reps."
        ]),
        TrainingBlock(name: "Setting Footwork + Accuracy", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "setting", focusTags: ["footwork", "accuracy", "hands"], instructions: [
            "Start at center court: shuffle to a target location, set to a specific spot.",
            "Alternate between forward sets, back sets, and jump sets.",
            "Track how many of 20 sets hit the target zone."
        ]),
        TrainingBlock(name: "Quick Set Repetition", category: .volleyball, durationMinutes: 6, intensity: .medium, imageName: "setting", focusTags: ["quickness", "hands", "rhythm"], instructions: [
            "Receive a rapid series of tossed balls (every 3-4 seconds).",
            "Focus on fast hand preparation, soft touch, and accurate release.",
            "Complete 3 rounds of 15 quick sets without a miss."
        ]),

        // ------ VOL 3: SERVE / SERVE-RECEIVE ------
        TrainingBlock(name: "Serve Toss + Contact", category: .volleyball, durationMinutes: 6, intensity: .low, imageName: "serving", focusTags: ["toss", "contact", "consistency"], instructions: [
            "Practice your serve toss in a mirror — consistent height and placement.",
            "Contact the ball at your peak reach with a firm, flat hand.",
            "Hit 10 float serves, then 10 topspin serves."
        ]),
        TrainingBlock(name: "Serve Placement Targets", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "serving", focusTags: ["accuracy", "placement", "vision"], instructions: [
            "Place a target in Zone 1 (deep right), Zone 5 (deep left), and Zone 6 (deep middle).",
            "Serve 5 balls to each zone, aiming to hit the target area.",
            "Challenge yourself: call out the zone before each serve."
        ]),
        TrainingBlock(name: "Serve Receive Platform", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "serveReceive", focusTags: ["platform", "footwork", "control"], instructions: [
            "Have a partner serve from the baseline — start in a ready position.",
            "Present a flat, angled platform to the target (center court).",
            "Move through the ball, do not reach — 30 quality passes."
        ]),
        TrainingBlock(name: "Serve Receive Under Pressure", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "serveReceive", focusTags: ["pressure", "platform", "reaction"], instructions: [
            "Partner serves to random zones — you must read, move, and pass.",
            "Focus on a low, athletic stance and split-step before the serve.",
            "Target: 8 out of 10 passes land within 3 feet of the setter target."
        ]),

        // ------ VOL 4: DEFENSE ------
        TrainingBlock(name: "Defensive Platform Basics", category: .volleyball, durationMinutes: 6, intensity: .low, imageName: "defense", focusTags: ["platform", "bodyPosition", "control"], instructions: [
            "Get in a low defensive stance — feet shoulder-width, weight on the balls of your feet.",
            "Present your platform at 45 degrees — absorb the ball, do not swing.",
            "Shuffle laterally to a coach-tossed ball and pass to target."
        ]),
        TrainingBlock(name: "Defensive Digging Reads", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "defense", focusTags: ["read", "reaction", "dig"], instructions: [
            "Partner or coach attacks from a box — start in base defense.",
            "Read the attacker's shoulder line and arm speed to anticipate shot location.",
            "Dig the ball up to a target zone — 4 sets of 6 attacks."
        ]),
        TrainingBlock(name: "Roll and Pancake Saves", category: .volleyball, durationMinutes: 6, intensity: .high, imageName: "defense", focusTags: ["hustle", "save", "reaction"], instructions: [
            "Coach tosses balls just out of reach — execute a controlled roll to save.",
            "Practice the pancake: dive flat, slide the back of your hand under the ball.",
            "Get up quickly and reset to your base position."
        ]),

        // ------ VOL 5: BLOCKING ------
        TrainingBlock(name: "Block Footwork + Seal", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "blocking", focusTags: ["footwork", "seal", "penetrate"], instructions: [
            "Start at the net in a ready blocking position.",
            "Shuffle step to the contact point — keep your hands up and active.",
            "Penetrate over the net with your hands, sealing the seam."
        ]),
        TrainingBlock(name: "Read Block vs Outside Hitter", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "blocking", focusTags: ["readHitter", "timing", "angle"], instructions: [
            "Face an outside hitter (live or simulated).",
            "Read their approach angle and arm swing to decide block position.",
            "Close the block with your partner — no seam, no split."
        ]),

        // ------ AGILITY ------
        TrainingBlock(name: "Ladder Quick Footwork", category: .agility, durationMinutes: 8, intensity: .medium, imageName: "agility_ladder", focusTags: ["agility", "footwork", "quickness"], instructions: [
            "Set up an agility ladder — 2 feet in each box, staying on the balls of your feet.",
            "Progress through: lateral steps, Icky shuffle, in-in-out pattern.",
            "Increase speed only when the rhythm is clean — 3 sets of each pattern."
        ]),
        TrainingBlock(name: "Lateral Slide Defense", category: .agility, durationMinutes: 8, intensity: .medium, imageName: "agility_lateral_slides", focusTags: ["defense", "agility", "lateral"], instructions: [
            "Stay low in a defensive posture the entire drill.",
            "Push from the inside edge of your foot — keep feet shoulder-width.",
            "No crossing your feet unless a directional cue is given."
        ]),
        TrainingBlock(name: "5-10-5 Change of Direction", category: .agility, durationMinutes: 9, intensity: .high, imageName: "agility_5_10_5", focusTags: ["agility", "reaction", "explosiveness"], instructions: [
            "Sprint 5 yards to the right, plant the outside foot, sprint 10 yards left.",
            "Plant foot under your hip — do not lean before the cut.",
            "Explode out of each cut — 4-6 reps with full recovery."
        ]),
        TrainingBlock(name: "Reaction Shuffle + Dig", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_reaction_shuffle", focusTags: ["reaction", "defense", "coordination"], instructions: [
            "Partner points left/right/short/deep — you react and shuffle hard.",
            "Return to base after every cue before the next direction.",
            "Add a ball dig at the end of each shuffle to combine agility with defense."
        ]),
        TrainingBlock(name: "T-Drill Agility", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_t_drill", focusTags: ["agility", "footwork", "changeOfDirection"], instructions: [
            "Set up cones in a T-shape: start at the base, sprint forward to the T junction.",
            "Shuffle left to touch the cone, shuffle right to the far cone, shuffle back to center.",
            "Backpedal to the start — 4 reps, rest 60 seconds."
        ]),
        TrainingBlock(name: "Short-Long Recovery Drill", category: .agility, durationMinutes: 6, intensity: .high, imageName: "agility_short_long", focusTags: ["endurance", "agility", "explosiveness"], instructions: [
            "Sprint 5 yards (short), immediately backpedal to start, then sprint 15 yards (long).",
            "Focus on explosive acceleration and controlled deceleration.",
            "Complete 5 sets with 30 seconds rest between sets."
        ]),

        // ------ PLYOMETRICS ------
        TrainingBlock(name: "Box Jump Power", category: .plyometrics, durationMinutes: 8, intensity: .high, imageName: "plyo_box_jumps", focusTags: ["jump", "plyo", "explosiveness"], instructions: [
            "Use a safe box height (12-24 inches depending on ability).",
            "Step off the box, immediately jump vertically as high as possible.",
            "Land softly — stick the landing for 2 seconds before resetting."
        ]),
        TrainingBlock(name: "Depth Drop + Vertical", category: .plyometrics, durationMinutes: 8, intensity: .high, imageName: "plyo_depth_jump_vertical", focusTags: ["reactive", "vertical", "explosiveness"], instructions: [
            "Step off a 12-18 inch box — upon landing, explode into a max vertical jump.",
            "Minimize ground contact time — think 'hot plate' under your feet.",
            "3 sets of 5 reps with 90 seconds rest between sets."
        ]),
        TrainingBlock(name: "Lateral Bounds (Skater Hops)", category: .plyometrics, durationMinutes: 7, intensity: .medium, imageName: "plyo_lateral_bounds", focusTags: ["agility", "lateral", "explosiveness"], instructions: [
            "Stand on one leg — bound laterally as far as possible, landing on the opposite leg.",
            "Stick the landing for 1 second before exploding back the other direction.",
            "Keep your chest up and hips loaded — 3 sets of 6 per side."
        ]),
        TrainingBlock(name: "Split Jumps", category: .plyometrics, durationMinutes: 6, intensity: .medium, imageName: "plyo_split_jumps", focusTags: ["split", "rhythm", "groundContact"], instructions: [
            "Start in a lunge position — jump and switch legs in the air.",
            "Land softly with both knees bent — minimize ground contact time.",
            "4 sets of 8 (each leg) with 45 seconds rest."
        ]),
        TrainingBlock(name: "Broad Jump + Stick", category: .plyometrics, durationMinutes: 6, intensity: .high, imageName: "plyo_broad_jump", focusTags: ["explosiveness", "deceleration", "power"], instructions: [
            "Stand with feet shoulder-width — squat, load hips, explode horizontally.",
            "Land with both feet simultaneously and stick the landing for 2 seconds.",
            "Measure your distance and try to beat your previous mark — 4 sets of 3."
        ]),
        TrainingBlock(name: "Pogo Hops", category: .plyometrics, durationMinutes: 5, intensity: .medium, imageName: "plyo_pogo", focusTags: ["ankleStiffness", "rhythm", "groundContact"], instructions: [
            "Keep your legs straight — bounce off the balls of your feet like a pogo stick.",
            "Minimize ground contact — the goal is quick, reactive rebounds.",
            "3 sets of 15 seconds, rest 30 seconds."
        ]),

        // ------ STRENGTH ------
        TrainingBlock(name: "Core Stability Holds", category: .strength, durationMinutes: 7, intensity: .medium, imageName: "core_stability", focusTags: ["core", "stability", "powerTransfer"], instructions: [
            "Front plank: 30 seconds — keep a straight line from head to heels.",
            "Side plank: 20 seconds each side — stack your feet and lift hips.",
            "Dead bugs: 10 reps each side — slow, controlled, press lower back into the floor."
        ]),
        TrainingBlock(name: "Glute + Hamstring Activation", category: .strength, durationMinutes: 6, intensity: .low, imageName: "core_stability", focusTags: ["glute", "hamstring", "mobility"], instructions: [
            "Glute bridges: 15 reps — squeeze at the top for 2 seconds.",
            "Single-leg Romanian deadlifts: 8 reps per leg — slow tempo.",
            "Walking lunges: 10 reps per leg — keep your front shin vertical."
        ]),
        TrainingBlock(name: "Rotator Cuff + Shoulder Stability", category: .strength, durationMinutes: 6, intensity: .low, imageName: "stretch_shoulder_prep", focusTags: ["shoulder", "stability", "injuryPrevention"], instructions: [
            "External rotation with band: 12 reps per arm.",
            "Y-T-W-L raises: 8 reps each letter — slow and controlled.",
            "Finish with scapular push-ups: 10 reps."
        ])
    ]

    /// All blocks for the custom drill builder
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

        // Fill remaining time
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
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.5))
            .cornerRadius(16)
    }
}

private extension View {
    func blendedCard() -> some View {
        modifier(BlendedCard())
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
                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

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
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.black.opacity(0.4))
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.pink.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.top, 16)

                            header
                            modePicker
                            durationControl
                            modeContent
                            actionButtons
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(item: $generatedPlan) { plan in
                    TrainingScheduleView(plan: plan)
                }
                .sheet(isPresented: $showingSaved) {
                    SavedTrainingsView()
                }
                .sheet(isPresented: $showingCustomBuilder) {
                    CustomDrillBuilderView(selectedDrills: $customDrills)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Training Hub")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Generate workouts from AI coach feedback, category focus, or build your own custom routine.")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            ForEach(TrainingGenerationMode.allCases) { m in
                Text(m.rawValue).foregroundColor(.pink).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.5))
        .cornerRadius(16)
    }

    private var durationControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration: \(durationMinutes) min")
                .font(.caption.bold())
                .foregroundColor(.white)
            Slider(value: Binding(
                get: { Double(durationMinutes) },
                set: { durationMinutes = Int($0) }
            ), in: 30...120, step: 15)
            .tint(.cyan)
        }
        .blendedCard()
    }

    @ViewBuilder
    private var modeContent: some View {
        switch mode {
        case .aiCoach: aiCoachCard
        case .userGenerated: userGeneratedCard
        case .customBuilt: customBuiltCard
        }
    }

    private var aiCoachCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coach Recommendation")
                .font(.headline)
                .foregroundColor(.pink)
            Text(coachFocus.capitalized)
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Based on your most recent hit feedback. Adjust duration above and generate a plan.")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .blendedCard()
    }

    private var userGeneratedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Categories")
                .font(.headline)
                .foregroundColor(.pink)

            let allCategories = TrainingCategory.allCases.filter { $0 != .waterBreak }
            Button(action: {
                if selectedCategories.count == allCategories.count {
                    selectedCategories = []
                } else {
                    selectedCategories = Set(allCategories)
                }
            }) {
                Text(selectedCategories.count == allCategories.count ? "Deselect All" : "Select All")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.3))
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allCategories) { cat in
                        let isSelected = selectedCategories.contains(cat)
                        Button(action: {
                            if isSelected { selectedCategories.remove(cat) }
                            else { selectedCategories.insert(cat) }
                        }) {
                            Text(cat.rawValue)
                                .font(.caption.bold())
                                .foregroundColor(isSelected ? .black : cat.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isSelected ? cat.color : Color.clear)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(cat.color.opacity(0.6), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .blendedCard()
    }

    private var customBuiltCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Custom Drill Builder")
                .font(.headline)
                .foregroundColor(.pink)
            if customDrills.isEmpty {
                Text("No drills selected yet. Tap the button below to pick drills by category.")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                Text("\(customDrills.count) drills selected • \(customDrills.reduce(0) { $0 + $1.durationMinutes }) min total")
                    .font(.caption)
                    .foregroundColor(.cyan)
                ScrollView {
                    ForEach(customDrills) { drill in
                        HStack {
                            Text(drill.name).font(.caption).foregroundColor(.white)
                            Spacer()
                            Text("\(drill.durationMinutes) min").font(.caption2).foregroundColor(.gray)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                    }
                }
                .frame(maxHeight: 120)
            }
            Button(action: { showingCustomBuilder = true }) {
                Text(customDrills.isEmpty ? "Select Drills" : "Edit Drills")
                    .font(.caption.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .blendedCard()
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

// MARK: - Custom Drill Builder
struct CustomDrillBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDrills: [TrainingBlock]
    @State private var selectedCategories: Set<TrainingCategory> = []

    private var allCategories: [TrainingCategory] { TrainingCategory.allCases.filter { $0 != .waterBreak } }
    private var availableDrills: [TrainingBlock] {
        let cats = selectedCategories.isEmpty ? allCategories : Array(selectedCategories)
        return VolleyballTrainingLibrary.allLibraryDrills.filter { cats.contains($0.category) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()
                VStack(spacing: 12) {
                    categoryFilter
                    drillGrid
                    selectedSummary
                }
                .padding()
            }
            .navigationTitle("Pick Drills")
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
                        .background(selectedCategories.isEmpty ? Color.cyan : Color.clear)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.6), lineWidth: 1.5))
                }.buttonStyle(PlainButtonStyle())
                ForEach(allCategories) { cat in
                    let isSelected = selectedCategories.contains(cat)
                    Button(action: {
                        if isSelected { selectedCategories.remove(cat) } else { selectedCategories.insert(cat) }
                    }) {
                        Text(cat.rawValue).font(.caption.bold())
                            .foregroundColor(isSelected ? .black : cat.color)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(isSelected ? cat.color : Color.clear)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(cat.color.opacity(0.6), lineWidth: 1.5))
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var drillGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(availableDrills) { drill in
                    let isSelected = selectedDrills.contains(drill)
                    Button(action: {
                        if isSelected { selectedDrills.removeAll { $0.id == drill.id } }
                        else { selectedDrills.append(drill) }
                    }) {
                        VStack(spacing: 6) {
                            Image(drill.imageName)
                                .resizable().scaledToFit().frame(height: 50).cornerRadius(8)
                            Text(drill.name).font(.caption2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
                            Text("\(drill.durationMinutes) min").font(.caption2).foregroundColor(.gray)
                        }
                        .padding(10).frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? drill.category.color.opacity(0.25) : Color(red: 0.14, green: 0.14, blue: 0.16)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(drill.category.color.opacity(isSelected ? 0.8 : 0.3), lineWidth: isSelected ? 2 : 1))
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var selectedSummary: some View {
        HStack { Text("\(selectedDrills.count) drills selected").font(.caption).foregroundColor(.gray); Spacer() }.padding(.horizontal)
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

    private var shareText: String {
        ([plan.name, "Total: \(plan.totalMinutes) min", "Focus: \(plan.focus)"] + plan.blocks.map { "• \($0.name) - \($0.durationMinutes) min" }).joined(separator: "\n")
    }

    private func resetTimersIfNeeded() {
        guard timers.isEmpty else { return }
        for block in plan.blocks where block.category != .waterBreak { timers[block.id] = block.durationMinutes * 60 }
    }

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
        try? modelContext.save(); saveName = ""
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
                List {
                    ForEach(savedPlans) { saved in
                        Button { selectedPlan = TrainingPlan(id: saved.id, name: saved.name, focus: saved.focus, createdAt: saved.createdAt, blocks: saved.blocks) }
                        label: { VStack(alignment: .leading, spacing: 4) {
                            Text(saved.name).foregroundColor(.white).font(.headline)
                            Text("\(saved.totalMinutes) min • \(saved.focus.capitalized)").foregroundColor(.gray).font(.caption)
                        }}
                        .listRowBackground(Color(red: 0.14, green: 0.14, blue: 0.16))
                        .swipeActions { Button("Delete", role: .destructive) { modelContext.delete(saved); try? modelContext.save() } }
                    }
                }.scrollContentBackground(.hidden)
            }
            .navigationTitle("Saved Trainings").toolbar { Button("Done") { dismiss() } }
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