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

enum VolleyballTrainingLibrary {
    static let warmups: [TrainingBlock] = [
        TrainingBlock(name: "Court Run + Dynamic Prep", category: .warmup, durationMinutes: 4, intensity: .low, imageName: "stretch_court_run", focusTags: ["warmup", "movement"], instructions: ["Jog court lines at 60% speed.", "Add backpedal, side shuffle, and carioca.", "Stay tall and breathe through the nose."]),
        TrainingBlock(name: "Shoulder Prep Flow", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_shoulder_prep", focusTags: ["armSwing", "shoulder", "armExtension"], instructions: ["Arm circles forward and backward.", "Cross-body shoulder stretch.", "Finish with slow shadow swings."]),
        TrainingBlock(name: "Hip + Ankle Activation", category: .stretching, durationMinutes: 4, intensity: .low, imageName: "stretch_hip_mobility", focusTags: ["jump", "approach", "mobility"], instructions: ["World's greatest stretch each side.", "Ankle rocks over toes.", "Bodyweight squat with pause."]),
        TrainingBlock(name: "Pre-Jump Leg Prep", category: .warmup, durationMinutes: 3, intensity: .low, imageName: "stretch_prejump", focusTags: ["plyo", "jump"], instructions: ["Pogo hops low and quick.", "Two-step approach footwork without jump.", "Stick two soft landings."])
    ]

    static let drills: [TrainingBlock] = [
        TrainingBlock(name: "Arm Swing Wall Spike", category: .volleyball, durationMinutes: 8, intensity: .medium, imageName: "hitting_wall_spike", focusTags: ["armSwing", "armExtension", "powerTransfer"], instructions: ["Stand 6-8 ft from wall.", "Toss, reach high, snap through the ball.", "Keep elbow high and finish across body."]),
        TrainingBlock(name: "Hitting Arm Swing Mechanics", category: .volleyball, durationMinutes: 10, intensity: .medium, imageName: "hitting_arm_swing", focusTags: ["armSwing", "armExtension"], instructions: ["Load elbow behind ear.", "Contact in front at full reach.", "Freeze finish and check shoulder-to-wrist line."]),
        TrainingBlock(name: "Approach Angle Reps", category: .volleyball, durationMinutes: 9, intensity: .medium, imageName: "hitting_approach_angle", focusTags: ["approach", "timing", "armSwing"], instructions: ["Mark start and target contact zone.", "Use a controlled 3-step approach.", "Plant hips open and attack through the target."]),
        TrainingBlock(name: "Max Jump Touches", category: .volleyball, durationMinutes: 8, intensity: .high, imageName: "hitting_max_jump", focusTags: ["jump", "explosiveness"], instructions: ["Approach jump to a safe wall target.", "Swing arms aggressively into takeoff.", "Land quietly and reset fully."]),
        TrainingBlock(name: "Box Jump Power", category: .plyometrics, durationMinutes: 8, intensity: .high, imageName: "plyo_box_jumps", focusTags: ["jump", "plyo", "explosiveness"], instructions: ["Use a safe box height.", "Jump, stick landing, step down.", "Quality reps only - no sloppy landings."]),
        TrainingBlock(name: "Approach Jump Plyos", category: .plyometrics, durationMinutes: 9, intensity: .high, imageName: "plyo_approach_jump", focusTags: ["approach", "jump", "timing"], instructions: ["Three-step approach into vertical jump.", "Reach both hands high at peak.", "Reset after each rep."]),
        TrainingBlock(name: "Depth Drop Landing Control", category: .plyometrics, durationMinutes: 7, intensity: .medium, imageName: "plyo_depth_drop", focusTags: ["landing", "kneeControl", "jump"], instructions: ["Step off a low box.", "Land knees over toes.", "Hold athletic stance for two seconds."]),
        TrainingBlock(name: "Lateral Bounds", category: .plyometrics, durationMinutes: 7, intensity: .medium, imageName: "plyo_lateral_bounds", focusTags: ["agility", "defense", "lateral"], instructions: ["Bound side to side with control.", "Stick outside-leg landing.", "Keep chest up and hips loaded."]),
        TrainingBlock(name: "Ladder Quick Feet", category: .agility, durationMinutes: 8, intensity: .medium, imageName: "agility_ladder", focusTags: ["agility", "footwork"], instructions: ["Two feet in each box.", "Stay on balls of feet.", "Add speed only when rhythm is clean."]),
        TrainingBlock(name: "Lateral Slide Defense", category: .agility, durationMinutes: 8, intensity: .medium, imageName: "agility_lateral_slides", focusTags: ["defense", "agility", "lateral"], instructions: ["Stay low in defensive posture.", "Push from inside edge of foot.", "No feet crossing unless cued."]),
        TrainingBlock(name: "5-10-5 Change of Direction", category: .agility, durationMinutes: 9, intensity: .high, imageName: "agility_5_10_5", focusTags: ["agility", "reaction", "defense"], instructions: ["Sprint five yards, change direction.", "Plant outside foot under hip.", "Explode out of each cut."]),
        TrainingBlock(name: "Reaction Shuffle", category: .agility, durationMinutes: 8, intensity: .high, imageName: "agility_reaction_shuffle", focusTags: ["reaction", "defense", "agility"], instructions: ["Partner points left/right/short/deep.", "React and shuffle hard.", "Return to base after every cue."]),
        TrainingBlock(name: "Timing Toss + Hit", category: .volleyball, durationMinutes: 10, intensity: .medium, imageName: "hitting_timing", focusTags: ["timing", "approach", "contact"], instructions: ["Toss or partner toss high ball.", "Delay approach until ball descends.", "Contact at peak reach."]),
        TrainingBlock(name: "Cross Court Target Hits", category: .volleyball, durationMinutes: 10, intensity: .medium, imageName: "hitting_cross_court", focusTags: ["accuracy", "armSwing", "vision"], instructions: ["Set a cross-court target.", "Open shoulders, finish thumb down.", "Track makes vs misses."]),
        TrainingBlock(name: "Core Stability Holds", category: .strength, durationMinutes: 7, intensity: .medium, imageName: "core_stability", focusTags: ["core", "powerTransfer", "stability"], instructions: ["Front plank 30 seconds.", "Side plank each side.", "Dead bug reps slow and controlled."])
    ]

    /// All blocks that can be used for a custom drill builder
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

        // Fill remaining with shorter drills if time allows
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
            .background(Color.black.opacity(0.35))
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
                var blocks = VolleyballTrainingLibrary.insertWaterBreaks(in: customDrills)
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
                            Spacer(minLength: 60)

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
                Text(m.rawValue).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.35))
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
                .foregroundColor(.yellow)
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
                .foregroundColor(.cyan)

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
                .foregroundColor(.purple)
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
            Button("Generate Plan") {
                generatePlan()
            }
            .buttonStyle(TrainingButtonStyle(color: .cyan, foreground: .black))
            .disabled(mode == .customBuilt && customDrills.isEmpty)

            Button("Saved Trainings (\(savedPlans.count))") {
                showingSaved = true
            }
            .buttonStyle(TrainingButtonStyle(color: .purple, foreground: .white))
        }
    }
}

// MARK: - Custom Drill Builder
struct CustomDrillBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDrills: [TrainingBlock]
    @State private var selectedCategories: Set<TrainingCategory> = []

    private var allCategories: [TrainingCategory] {
        TrainingCategory.allCases.filter { $0 != .waterBreak }
    }

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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: { selectedCategories.removeAll() }) {
                    Text("All")
                        .font(.caption.bold())
                        .foregroundColor(selectedCategories.isEmpty ? .black : .white)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(selectedCategories.isEmpty ? Color.cyan : Color.clear)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.6), lineWidth: 1.5))
                }
                .buttonStyle(PlainButtonStyle())
                ForEach(allCategories) { cat in
                    let isSelected = selectedCategories.contains(cat)
                    Button(action: {
                        if isSelected { selectedCategories.remove(cat) } else { selectedCategories.insert(cat) }
                    }) {
                        Text(cat.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(isSelected ? .black : cat.color)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(isSelected ? cat.color : Color.clear)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(cat.color.opacity(0.6), lineWidth: 1.5))
                    }
                    .buttonStyle(PlainButtonStyle())
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
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? drill.category.color.opacity(0.25) : Color(red: 0.14, green: 0.14, blue: 0.16)))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(drill.category.color.opacity(isSelected ? 0.8 : 0.3), lineWidth: isSelected ? 2 : 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var selectedSummary: some View {
        HStack {
            Text("\(selectedDrills.count) drills selected")
                .font(.caption).foregroundColor(.gray)
            Spacer()
        }
        .padding(.horizontal)
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
                                TrainingScheduleRow(
                                    block: block,
                                    seconds: timers[block.id] ?? block.durationMinutes * 60,
                                    isRunning: running.contains(block.id),
                                    onTap: { selectedBlock = block },
                                    onPlay: { running.insert(block.id) },
                                    onPause: { running.remove(block.id) },
                                    onReset: { timers[block.id] = block.durationMinutes * 60; running.remove(block.id) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                HStack {
                    Button("Save") { showSaveName = true }
                        .buttonStyle(TrainingButtonStyle(color: .cyan, foreground: .black))
                    ShareLink(item: shareText) {
                        Text("Share")
                    }
                    .buttonStyle(TrainingButtonStyle(color: .yellow, foreground: .black))
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle("Training Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { resetTimersIfNeeded() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in tickTimers() }
        .sheet(item: $selectedBlock) { block in
            TrainingBlockDetailView(block: block)
        }
        .alert("Name Your Training", isPresented: $showSaveName) {
            TextField("Training name", text: $saveName)
            Button("Cancel", role: .cancel) { saveName = "" }
            Button("Save") { saveTraining() }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(plan.name)
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("\(plan.blocks.count) blocks • \(plan.totalMinutes) min • Focus: \(plan.focus.capitalized)")
                .font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding().background(Color.blue.opacity(0.16)).cornerRadius(14).padding(.horizontal)
    }

    private func waterBreakRow(_ block: TrainingBlock) -> some View {
        Text("WATER BREAK - \(block.durationMinutes) MIN")
            .font(.headline).foregroundColor(Color(red: 1.0, green: 0.08, blue: 0.58))
            .frame(maxWidth: .infinity).padding()
            .background(Color(red: 1.0, green: 0.08, blue: 0.58).opacity(0.16)).cornerRadius(12)
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
                        Button {
                            selectedPlan = TrainingPlan(id: saved.id, name: saved.name, focus: saved.focus, createdAt: saved.createdAt, blocks: saved.blocks)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(saved.name).foregroundColor(.white).font(.headline)
                                Text("\(saved.totalMinutes) min • \(saved.focus.capitalized)").foregroundColor(.gray).font(.caption)
                            }
                        }
                        .listRowBackground(Color(red: 0.14, green: 0.14, blue: 0.16))
                        .swipeActions { Button("Delete", role: .destructive) { modelContext.delete(saved); try? modelContext.save() } }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Saved Trainings")
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
                    Button("Play", action: onPlay); Button("Pause", action: onPause); Button("Reset", action: onReset)
                }.font(.caption.bold()).foregroundColor(.white)
            }
        }
        .padding(10).background(Color.white.opacity(0.08)).cornerRadius(12)
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