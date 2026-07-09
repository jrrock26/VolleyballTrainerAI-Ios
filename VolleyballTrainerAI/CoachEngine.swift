import Foundation
import SwiftData
import CoreGraphics

// MARK: - Athlete Level & Adaptive Targets

enum AthleteLevel: String, Codable, CaseIterable {
    case beginner      = "Beginner"
    case intermediate  = "Intermediate"
    case advanced      = "Advanced"
    case elite         = "Elite"

    var targetArmAngleSpike: Double   { switch self {
        case .beginner: return 145; case .intermediate: return 155
        case .advanced: return 162; case .elite: return 168 }}
    var targetJumpHeightInches: Double { switch self {
        case .beginner: return 10; case .intermediate: return 14
        case .advanced: return 18; case .elite: return 22 }}
    var targetBallSpeedMPH: Double    { switch self {
        case .beginner: return 22; case .intermediate: return 30
        case .advanced: return 38; case .elite: return 48 }}
    var targetServeSpeedMPH: Double   { switch self {
        case .beginner: return 28; case .intermediate: return 38
        case .advanced: return 48; case .elite: return 58 }}
    var maxDrillsPerSession: Int      { switch self {
        case .beginner: return 3; case .intermediate: return 5
        case .advanced: return 7; case .elite: return 10 }}

    static func infer(from profile: AthleteProfile) -> AthleteLevel {
        let score = profile.overallPerformanceScore
        switch score {
        case 0..<35: return .beginner
        case 35..<55: return .intermediate
        case 55..<75: return .advanced
        default: return .elite
        }
    }

    /// Estimates a level directly from a single rep's raw metrics so feedback
    /// is always rich even when no persistent profile exists yet.
    static func estimate(from hitType: String, ballSpeed: Double, jumpHeight: Double, armAngle: Double) -> AthleteLevel {
        let power = ballSpeed + jumpHeight * 1.2 + max(0, armAngle - 130) * 0.3
        switch power {
        case 0..<45:   return .beginner
        case 45..<65:  return .intermediate
        case 65..<90:  return .advanced
        default:       return .elite
        }
    }
}

// MARK: - Drill Library

struct Drill: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    let category: String
    let description: String
    let difficulty: AthleteLevel
    let reps: String
    let sets: String
    let restSeconds: Int
    let focuses: [String]
    let progressionHint: String?

    static let library: [Drill] = [
        Drill(name: "Wall Shadow Drill", category: "Arm Action", description: "Stand 3 ft from a wall. Slow-motion arm swing. Elbow brushes past ear before contact.", difficulty: .beginner, reps: "15", sets: "3", restSeconds: 45, focuses: ["armExtension","timing"], progressionHint: "Add a 1 lb towel at the wrist to feel the whip."),
        Drill(name: "Toss-and-Reach", category: "Arm Action", description: "Toss 2 ft above max reach; jump and catch at apex with full extension.", difficulty: .beginner, reps: "10", sets: "4", restSeconds: 60, focuses: ["armExtension","verticalJump"], progressionHint: "Increase toss height 1 inch per week."),
        Drill(name: "3-Step Approach Without Ball", category: "Approach & Jump", description: "Mark start. 3-step rhythm (Right-Left for righties), heel-toe plant, big arm swing.", difficulty: .beginner, reps: "12", sets: "4", restSeconds: 60, focuses: ["approachTiming","armSwing"], progressionHint: "Add approach jump to a 12-in box."),
        Drill(name: "Arm Swing Jumps", category: "Approach & Jump", description: "Stand in place. Jump as high as possible using ONLY your arm swing — no leg countermovement.", difficulty: .intermediate, reps: "10", sets: "3", restSeconds: 45, focuses: ["armSwing","verticalJump"], progressionHint: "Hold a light medicine ball to increase load."),
        Drill(name: "Box Jump Transitions", category: "Approach & Jump", description: "Step off a 12-in box, immediately convert into your 3-step approach and jump.", difficulty: .intermediate, reps: "8", sets: "4", restSeconds: 75, focuses: ["approachTiming","explosiveness"], progressionHint: "Increase box height to 24 in when comfortable."),
        Drill(name: "Towel Snap Drill", category: "Power Transfer", description: "Hold a towel corner. Full arm swing aiming for the loudest snap possible at contact.", difficulty: .beginner, reps: "15", sets: "3", restSeconds: 45, focuses: ["wristSnap","armSpeed"], progressionHint: "Use a heavier hand towel or multiple layers."),
        Drill(name: "Sit-and-Snap", category: "Power Transfer", description: "Sit on the ground. Partner tosses to your hitting hand. Wrist-only snap generating heavy topspin.", difficulty: .intermediate, reps: "20", sets: "3", restSeconds: 60, focuses: ["wristSnap","contactPoint"], progressionHint: "Progress to kneeling then standing to add body load."),
        Drill(name: "Downward Contact Drill", category: "Angle of Attack", description: "Stand 3 ft from a high wall. Toss 1 ft above max reach, jump and spike into the ground so it bounces up and hits the wall.", difficulty: .intermediate, reps: "10", sets: "3", restSeconds: 60, focuses: ["contactHand","launchAngle"], progressionHint: "Move target 12 inches further from the wall each week."),
        Drill(name: "Toss-Under-Cone", category: "Toss & Reach", description: "Place a cone 18 in above your reach. Toss so it barely grazes the cone top before contact.", difficulty: .beginner, reps: "20", sets: "3", restSeconds: 45, focuses: ["tossConsistency","armExtension"], progressionHint: "Raise cone 2 inches when you hit 80% success for a session."),
        Drill(name: "Medicine Ball Rotational Toss", category: "Power Generation", description: "6–8 lb med ball, face sideways, rotate through core and toss into wall.", difficulty: .intermediate, reps: "12", sets: "4", restSeconds: 60, focuses: ["coreRotation","servePower"], progressionHint: "Add a 2-step hop before the toss to mimic jump serve load."),
        Drill(name: "Light Ball Speed Drill", category: "Power Generation", description: "Use a beach ball or very light ball. Serve as hard as possible — forces a loose, whippy arm.", difficulty: .beginner, reps: "15", sets: "3", restSeconds: 45, focuses: ["armSpeed","serveTechnique"], progressionHint: "Switch to a normal volleyball as speed improves."),
        Drill(name: "Target Serve Zone Drill", category: "Serve Depth", description: "Place a cone or towel in the back third. Serve ONLY to that zone to force flatter, faster trajectory.", difficulty: .intermediate, reps: "15", sets: "3", restSeconds: 60, focuses: ["serveAccuracy","launchAngle"], progressionHint: "Target smaller zones (e.g., just behind the 10-ft line)."),
        Drill(name: "Contact-Point Timing Drill", category: "Contact Timing", description: "Tape a height mark on a wall at your full-reach contact point. Strike a tossed ball exactly as it reaches that mark so contact always happens at full extension.", difficulty: .intermediate, reps: "12", sets: "4", restSeconds: 50, focuses: ["contactPoint","timing"], progressionHint: "Lower the mark 2 inches only after 10 clean reps in a row."),
        Drill(name: "Deep Corner Targeting Drill", category: "Shot Placement", description: "Lay two cones in the back-left and back-right corners. Alternate spikes aiming to land inside each cone to build angle control and court awareness.", difficulty: .intermediate, reps: "10", sets: "4", restSeconds: 55, focuses: ["placement","launchAngle"], progressionHint: "Shrink the target cones once accuracy exceeds 70%."),
        Drill(name: "Wrist-Lag Snap Drill", category: "Power Transfer", description: "Hold a weighted wristband. Practice 'lagging' the wrist behind the forearm until the last 6 inches of the swing, then whip it over the top of the ball.", difficulty: .advanced, reps: "20", sets: "3", restSeconds: 40, focuses: ["wristSnap","armSpeed"], progressionHint: "Remove the band and feel the same late snap with a live ball.")
    ]

    static func recommended(for focusArea: String, level: AthleteLevel) -> Drill {
        let exact = library
            .filter { $0.difficulty == level && $0.focuses.contains(focusArea) }
            .sorted { $0.name < $1.name }
        if let best = exact.first { return best }

        let fallback = library
            .filter { $0.focuses.contains(focusArea) }
            .sorted { $0.name < $1.name }
        if let best = fallback.first { return best }

        return Drill(name: "Shadow Reps", category: focusArea, description: "Slow-motion reps focusing on the target position.", difficulty: level, reps: "10", sets: "3", restSeconds: 45, focuses: [focusArea], progressionHint: nil)
    }

    static func progressionChains(for level: AthleteLevel) -> [Drill] {
        library.filter { $0.difficulty == level }
    }
}

// MARK: - Session Intelligence

struct SessionIntelligence {
    let sessionID: UUID
    let hitCount: Int
    let fatigueDetected: Bool
    let peakWindowStartIndex: Int?
    let peakWindowEndIndex: Int?
    let trendDirection: TrendDirection
    let consistencyScore: Double
    let dominantFaultCategory: String?
    let recoveryRecommendation: String?

    enum TrendDirection: String {
        case improving = "improving"
        case declining  = "declining"
        case stable     = "stable"
        case volatile   = "volatile"
    }
}

// MARK: - Skill Level & Position

enum SkillLevel: String, Codable, CaseIterable {
    case jrHigh = "Jr. High"
    case varsity = "Varsity"
    case collegiate = "Collegiate"
    case coach = "Coach"

    var mappedAthleteLevel: AthleteLevel {
        switch self {
        case .jrHigh: return .beginner
        case .varsity: return .intermediate
        case .collegiate: return .advanced
        case .coach: return .elite
        }
    }
}

enum PlayerPosition: String, Codable, CaseIterable {
    case all = "All"
    case outsideHitter = "Outside Hitter"
    case middleBlocker = "Middle Blocker"
    case oppositeHitter = "Opposite Hitter"
    case setter = "Setter"
    case libero = "Libero"
    case defensiveSpecialist = "Defensive Specialist"
}

// MARK: - Enhanced Athlete Profile

struct HitMetricSnapshot: Codable, Equatable {
    var speed: Double
    var angle: Double
    var jump: Double
    var launch: Double
    var score: Double
}

struct AthleteProfile: Codable, Equatable {
    var id: UUID = UUID()
    var athleteName: String = ""
    var athleteLevel: AthleteLevel = .beginner

    // Core cumulative stats
    var totalHits: Int = 0
    var totalSessions: Int = 0
    var overallPerformanceScore: Double = 0
    var lifetimeBestScore: Double = 0
    var lifetimeBestArmAngle: Double = 0
    var lifetimeBestJumpHeight: Double = 0
    var lifetimeBestBallSpeed: Double = 0

    // Session rolling window
    var recentHitMetrics: [HitMetricSnapshot] = []
    var lastSessionStart: Date?
    private let maxWindowSize: Int = 20

    // Adaptive gate for next target (driven by session performance)
    var nextTargetArmAngle: Double = 145.0
    var nextTargetJumpHeight: Double = 10.0
    var nextTargetBallSpeed: Double = 22.0

    // Personalization
    var weakAreas: [String] = []
    var strongAreas: [String] = []
    var fatigueThreshold: Double = 0.30
    var heightInches: Double = 0 // 0 means not set
    var skillLevel: SkillLevel = .jrHigh
    var position: PlayerPosition = .all

    mutating func incorporate(hit: VolleyballHit, sessionID: UUID) {
        totalHits += 1
        let score = hit.overallScore
        overallPerformanceScore = overallPerformanceScore * 0.90 + score * 0.10

        if score > lifetimeBestScore {
            lifetimeBestScore = score
            lifetimeBestArmAngle = hit.armAngleDegrees
            lifetimeBestJumpHeight = hit.jumpHeightInches
            lifetimeBestBallSpeed = hit.ballSpeedMPH
        }

        recentHitMetrics.append(HitMetricSnapshot(
            speed: hit.ballSpeedMPH,
            angle: hit.armAngleDegrees,
            jump: hit.jumpHeightInches,
            launch: hit.ballAngleDegrees,
            score: score
        ))
        if recentHitMetrics.count > maxWindowSize { recentHitMetrics.removeFirst() }

        recalculateTargets()
        recalculateAreas()
    }

    mutating func markSessionComplete() {
        totalSessions += 1
        lastSessionStart = nil
    }

    mutating func recalculateTargets() {
        guard recentHitMetrics.count >= 3 else { return }
        let last = recentHitMetrics.suffix(5)
        let avg = last.map { $0.score }.reduce(0, +) / Double(last.count)

        if avg > 70 {
            nextTargetArmAngle   += 2.5
            nextTargetJumpHeight += 1.5
            nextTargetBallSpeed  += 3.0
        } else if avg < 45 {
            nextTargetArmAngle   = max(130, nextTargetArmAngle   - 1.0)
            nextTargetJumpHeight = max(6,  nextTargetJumpHeight - 0.8)
            nextTargetBallSpeed  = max(12, nextTargetBallSpeed  - 1.5)
        }

        athleteLevel = AthleteLevel.infer(from: self)
    }

    mutating func recalculateAreas() {
        guard recentHitMetrics.count >= 5 else { return }
        let last10 = recentHitMetrics.suffix(10)

        let avgAngle = last10.map { $0.angle }.reduce(0, +) / Double(last10.count)
        let avgJump  = last10.map { $0.jump }.reduce(0, +)  / Double(last10.count)
        let avgSpeed = last10.map { $0.speed }.reduce(0, +) / Double(last10.count)

        weakAreas = []
        strongAreas = []

        switch athleteLevel {
        case .beginner, .intermediate:
            if avgAngle < 140 { weakAreas.append("armExtension") }
            else if avgAngle > 155 { strongAreas.append("armExtension") }

            if avgJump < 12 { weakAreas.append("verticalJump") }
            else { strongAreas.append("verticalJump") }

            if avgSpeed < 25 { weakAreas.append("powerTransfer") }
            else { strongAreas.append("powerTransfer") }
        case .advanced, .elite:
            if avgAngle < 160 { weakAreas.append("armExtension") }
            if avgJump < 18 { weakAreas.append("explosiveness") }
            if avgSpeed < 40 { weakAreas.append("wristSnap") }
            if !weakAreas.isEmpty { strongAreas.append("elitePowerChain") }
        }
    }

    var sessionConsistency: Double {
        guard recentHitMetrics.count >= 3 else { return 1.0 }
        let scores = recentHitMetrics.map(\.score)
        let mean = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.map { pow($0 - mean, 2) }.reduce(0, +) / Double(scores.count)
        let raw = 1.0 - min(0.8, variance / 600.0)
        return max(0.2, raw)
    }

    var recentFormScore: Double {
        guard !recentHitMetrics.isEmpty else { return 0 }
        let last5 = recentHitMetrics.suffix(5).map { $0.score }
        return last5.reduce(0, +) / Double(last5.count)
    }
}

// MARK: - Biomechanical Faults & Diagnostics

struct BiomechanicalFault: Identifiable, Equatable {
    let id = UUID()
    let category: String
    let phase: MovementPhase
    let severity: FaultSeverity
    let observation: String      // What the data shows
    let whyItMatters: String     // Consequence for performance
    let rootCause: String        // Biomechanical reason
    let fixSteps: [String]       // Ordered, actionable corrections
    let drill: Drill
    let drillContext: String
    let microCue: String         // one sentence real-time cue
    let confidence: Double       // 0–1 based on tracking certainty

    enum FaultSeverity: Int, Codable { case low = 1, medium = 2, high = 3, critical = 4 }

    var severityLabel: String {
        switch severity {
        case .low: return "Minor"
        case .medium: return "Moderate"
        case .high: return "Significant"
        case .critical: return "Critical"
        }
    }
}

enum MovementPhase: String {
    case approach       = "Approach"
    case lastStride     = "Last Stride"
    case armDraw        = "Arm Draw"
    case blockJump      = "Block Jump"
    case contact        = "Contact"
    case followThrough  = "Follow-Through"
    case toss           = "Toss"
    case trophyPose     = "Trophy Pose"
    case serveSwing     = "Serve Swing"
    case serveContact   = "Serve Contact"
}

// MARK: - Biomechanical Analyzers

struct DetectSpike {

    static func detect(
        armAngle: Double,
        jumpHeight: Double,
        ballSpeed: Double,
        launchAngle: Double,
        distance: Double,
        profile: AthleteProfile
    ) -> [BiomechanicalFault] {

        var faults: [BiomechanicalFault] = []
        let targetAngle = profile.nextTargetArmAngle
        let targetJump  = profile.nextTargetJumpHeight
        let targetSpeed = profile.nextTargetBallSpeed

        // MARK: Arm extension at contact
        if armAngle < targetAngle - 20 {
            faults.append(BiomechanicalFault(
                category: "Arm Action", phase: .contact, severity: .critical,
                observation: "Your arm reached only \(Int(armAngle))° of extension versus a \(Int(targetAngle))° target — you're contacting well below the high point.",
                whyItMatters: "Every degree of lost extension lowers your contact height. Blockers read a lower ball easily, and you sacrifice the steep downward window that makes spikes unreturnable.",
                rootCause: "The hitting shoulder rotates open too early, pulling the elbow forward and down before the arm fully stretches overhead.",
                fixSteps: [
                    "On your draw, picture pulling the elbow straight UP to the sky, thumb near your ear — not back behind you.",
                    "Delay shoulder rotation until the hand is at its highest point.",
                    "Jump a half-count later so your arm reaches full stretch exactly at apex.",
                    "Practice 3×15 Wall Shadow reps feeling the elbow brush the wall before contact."
                ],
                drill: Drill.recommended(for: "armExtension", level: profile.athleteLevel),
                drillContext: "Emphasize vertical reach BEFORE any horizontal rotation.",
                microCue: "Reach UP first, swing LATER.",
                confidence: 0.92
            ))
        } else if armAngle < targetAngle - 5 {
            faults.append(BiomechanicalFault(
                category: "Arm Action", phase: .contact, severity: .medium,
                observation: "Arm extension is \(Int(targetAngle - armAngle))° short of your \(Int(targetAngle))° target — close, but leaving power on the table.",
                whyItMatters: "A slightly low contact point flattens your possible trajectory and costs 2–4 mph of downward drive.",
                rootCause: "A late elbow drop or insufficient upward arm-drive momentum before rotation.",
                fixSteps: [
                    "Focus on 'elbow to ear' before the hand opens.",
                    "Add a small pause at the top of your draw to reinforce the high position.",
                    "Drill with a cone 2 ft above your reach and contact at its height."
                ],
                drill: Drill.recommended(for: "armExtension", level: profile.athleteLevel),
                drillContext: "Feel the elbow brush past your ear before the hand opens.",
                microCue: "Elbow to ear, then open.",
                confidence: 0.88
            ))
        }

        // MARK: Wrist snap / power transfer when arm is good
        if armAngle >= targetAngle - 5 && ballSpeed < targetSpeed * 0.75 {
            faults.append(BiomechanicalFault(
                category: "Power Transfer", phase: .contact, severity: .medium,
                observation: "Arm extension looks right, but ball speed (\(Int(ballSpeed)) mph) is well under your \(Int(targetSpeed)) mph target — the wrist isn't converting arm speed into the ball.",
                whyItMatters: "A flat, paddle-like hand 'pushes' the ball instead of whipping it, bleeding 30–40% of available power.",
                rootCause: "The hand contacts as a rigid plate; fingers don't wrap and snap over the top-back of the ball.",
                fixSteps: [
                    "At contact, imagine slapping the top of the ball and your fingers following through DOWN past your opposite hip.",
                    "Keep the wrist relaxed until the last 6 inches, then whip it.",
                    "Use the Towel Snap Drill to train a loud, fast snap."
                ],
                drill: Drill.recommended(for: "wristSnap", level: profile.athleteLevel),
                drillContext: "Open hand, relax wrist, snap through the top of the ball.",
                microCue: "Pull the ball down, don't push it.",
                confidence: 0.85
            ))
        }

        // MARK: Jump / approach
        if jumpHeight < targetJump - 4 {
            faults.append(BiomechanicalFault(
                category: "Approach & Jump", phase: .blockJump, severity: .critical,
                observation: "Jump height is \(String(format: "%.1f", jumpHeight)) in versus a \(String(format: "%.1f", targetJump)) in target — your attack angle is severely compromised.",
                whyItMatters: "Lower jumps mean a lower contact point. You're forced to hit flatter, giving blockers and diggers an easy read.",
                rootCause: "The penultimate step is too vertical and the hips never load back-and-down, so you can't convert horizontal speed into vertical lift.",
                fixSteps: [
                    "On the second-to-last step, sit BACK and DOWN like lowering into a chair.",
                    "Swing both arms back, then drive them aggressively forward/up as you plant.",
                    "Plant with a heel-toe roll and let the plant foot's stopping force launch you up.",
                    "Add Box Jump Transitions to wire the approach-to-jump conversion."
                ],
                drill: Drill.recommended(for: "verticalJump", level: profile.athleteLevel),
                drillContext: "Sit back on the penultimate step like sitting into a chair.",
                microCue: "Load hips, explode up.",
                confidence: 0.90
            ))
        } else if jumpHeight < targetJump {
            faults.append(BiomechanicalFault(
                category: "Approach & Jump", phase: .blockJump, severity: .low,
                observation: "Vertical is \(String(format: "%.1f", jumpHeight)) in — within range but a 2–3 in gain would open more attacking angles.",
                whyItMatters: "Small jump gains create valuable air space that forces blockers to commit earlier.",
                rootCause: "Slight mismatch between arm-swing timing and the plant moment.",
                fixSteps: [
                    "Count your approach out loud: 'down-up' syncing arms down on the penultimate step, arms up on plant.",
                    "Film from the side to check arm-plant sync."
                ],
                drill: Drill.recommended(for: "approachTiming", level: profile.athleteLevel),
                drillContext: "Match arm swing peak to plant moment exactly.",
                microCue: "Arms down, plant, arms up, jump.",
                confidence: 0.78
            ))
        }

        // MARK: Trajectory / launch angle
        if launchAngle >= 0 {
            faults.append(BiomechanicalFault(
                category: "Angle of Attack", phase: .contact, severity: .critical,
                observation: "Ball left at +\(Int(launchAngle))° — it's going UP, not down. A spike must always drive into the court.",
                whyItMatters: "An upward spike sails long or into the block. It's the single most common reason a swing gets stuffed or goes out.",
                rootCause: "Contact point is too low on the ball; the palm pushes the underside instead of topping it.",
                fixSteps: [
                    "Contact the TOP-BACK quadrant of the ball with your wrist leading over it.",
                    "Think 'highlight the ball' — hand on top, fingers pointing down after contact.",
                    "Use the Downward Contact Drill against a wall to feel the downward whip."
                ],
                drill: Drill.recommended(for: "contactHand", level: profile.athleteLevel),
                drillContext: "Contact the top-back quadrant with wrist leading.",
                microCue: "Hit the top — not the bottom.",
                confidence: 0.95
            ))
        } else if launchAngle > -6 {
            faults.append(BiomechanicalFault(
                category: "Angle of Attack", phase: .followThrough, severity: .medium,
                observation: "Downward angle is shallow (\(String(format: "%.1f", launchAngle))°). Blockers feast on a flat trajectory.",
                whyItMatters: "A shallow angle is easy to read and dig; steeper angles disappear below the blocker's hands.",
                rootCause: "The wrist isn't snapping OVER the ball; the hand finishes forward rather than downward.",
                fixSteps: [
                    "After contact, drive your palm down toward the floor as if pressing a button.",
                    "Imagine 'breaking' the ball over the net like a topspin tennis serve.",
                    "Rep the Downward Contact Drill aiming for -10° or steeper."
                ],
                drill: Drill.recommended(for: "launchAngle", level: profile.athleteLevel),
                drillContext: "Break the ball over the net like a tennis topspin serve.",
                microCue: "Snap your palm down NOW.",
                confidence: 0.87
            ))
        }

        // MARK: Speed vs arm-angle efficiency
        if ballSpeed < targetSpeed * 0.6 && armAngle >= targetAngle - 5 {
            faults.append(BiomechanicalFault(
                category: "Power Transfer", phase: .contact, severity: .medium,
                observation: "Arm extension is correct yet speed is only \(Int(ballSpeed)) mph (target \(Int(targetSpeed))). Power is leaking somewhere in the chain.",
                whyItMatters: "You're doing the shape right but not transferring force — the ball comes off soft.",
                rootCause: "Gripping the ball too tightly or bracing the wrist decelerates the arm right before contact.",
                fixSteps: [
                    "Soften the hand at the top of the swing — a tight grip acts like a brake.",
                    "Let the hand be a 'lash', not a 'baton'.",
                    "Use Arm Swing Jumps to feel arm-only speed."
                ],
                drill: Drill.recommended(for: "armSpeed", level: profile.athleteLevel),
                drillContext: "Loosen grip; let the hand be a lash, not a baton.",
                microCue: "Soft hand at the top.",
                confidence: 0.76
            ))
        }

        // MARK: Shot placement / distance
        if distance > 0 && distance < 18 {
            faults.append(BiomechanicalFault(
                category: "Shot Placement", phase: .followThrough, severity: .low,
                observation: "Landing point is \(String(format: "%.1f", distance)) ft from the net — a short tip that a middle blocker digs easily.",
                whyItMatters: "Short landings let the defense transition and reset instead of being scored on.",
                rootCause: "Contact happens slightly behind the body so the ball is pushed, not driven deep.",
                fixSteps: [
                    "Aim the follow-through at the back-third seam, not straight down.",
                    "Use the Deep Corner Targeting Drill to build depth control."
                ],
                drill: Drill.recommended(for: "placement", level: profile.athleteLevel),
                drillContext: "Drive the ball to the deep corners to stretch the defense.",
                microCue: "Follow through to the back corner.",
                confidence: 0.74
            ))
        }

        return faults.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }
}

struct DetectServe {

    static func detect(
        armAngle: Double,
        ballSpeed: Double,
        launchAngle: Double,
        distance: Double,
        profile: AthleteProfile
    ) -> [BiomechanicalFault] {

        var faults: [BiomechanicalFault] = []
        let targetAngle = profile.nextTargetArmAngle
        let targetSpeed: Double = profile.athleteLevel == .beginner ? 25
                          : profile.athleteLevel == .intermediate ? 35
                          : profile.athleteLevel == .advanced ? 45 : 55

        // MARK: Arm extension / toss
        if armAngle < targetAngle - 15 {
            faults.append(BiomechanicalFault(
                category: "Toss & Reach", phase: .trophyPose, severity: .critical,
                observation: "Contact point is \(Int(targetAngle - armAngle))° below your \(Int(targetAngle))° target — the toss is too low or drifting.",
                whyItMatters: "A low contact point kills serve velocity and forces an upward, net-hazard trajectory.",
                rootCause: "The toss is landing behind or to the side of the contact shoulder instead of 1 ft in front and 2 ft above reach.",
                fixSteps: [
                    "Toss the ball so it peaks 1 ft IN FRONT of and 2 ft ABOVE your max reach.",
                    "Keep your tossing arm extended and release late for a consistent drop.",
                    "Use Toss-Under-Cone to groove the height."
                ],
                drill: Drill.recommended(for: "tossConsistency", level: profile.athleteLevel),
                drillContext: "Toss must peak 1 ft in front and 2 ft above your reach.",
                microCue: "Toss UP and FRONT.",
                confidence: 0.93
            ))
        } else if armAngle < targetAngle - 3 {
            faults.append(BiomechanicalFault(
                category: "Toss & Reach", phase: .trophyPose, severity: .low,
                observation: "Extension is good at \(Int(armAngle))°, just shy of the \(Int(targetAngle))° ideal.",
                whyItMatters: "A slightly low contact point costs a few mph and net margin.",
                rootCause: "Small toss-location variance is now the limiting factor.",
                fixSteps: [
                    "Toss to the same landing spot every rep — mark it with tape.",
                    "Reach a touch higher before swinging."
                ],
                drill: Drill.recommended(for: "tossConsistency", level: profile.athleteLevel),
                drillContext: "Toss to the same landing spot every time.",
                microCue: "",
                confidence: 0.80
            ))
        }

        // MARK: Speed / power
        if ballSpeed < targetSpeed * 0.6 {
            faults.append(BiomechanicalFault(
                category: "Power Generation", phase: .serveContact, severity: .critical,
                observation: "Serve velocity is \(Int(ballSpeed)) mph versus a \(Int(targetSpeed)) mph target — leg-to-core transfer is underdeveloped.",
                whyItMatters: "Soft serves are passed cleanly and attacked against you. Power starts from the ground, not the arm.",
                rootCause: "Rotation stops at the shoulder; the hips don't lead the torso, so the core never fires.",
                fixSteps: [
                    "Load the back hip and rotate hip-to-shoulder separation INTO contact.",
                    "Let the non-hitting arm pull down and across to drive rotation.",
                    "Use Medicine Ball Rotational Toss to build the core sequence."
                ],
                drill: Drill.recommended(for: "coreRotation", level: profile.athleteLevel),
                drillContext: "Load back hip, rotate hip-to-shoulder separation at contact.",
                microCue: "Hips first, arm last.",
                confidence: 0.90
            ))
        } else if ballSpeed < targetSpeed {
            faults.append(BiomechanicalFault(
                category: "Power Generation", phase: .serveContact, severity: .low,
                observation: "Moderate speed at \(Int(ballSpeed)) mph. A looser wrist snap adds 3–5 mph instantly.",
                whyItMatters: "Even small velocity gains make the pass harder and the seam tougher to read.",
                rootCause: "The arm is rigid through contact and decelerates before the snap.",
                fixSteps: [
                    "Accelerate almost to the point of losing the ball — then rip it.",
                    "Let the wrist 'lag' behind, then whip over the top."
                ],
                drill: Drill.recommended(for: "armSpeed", level: profile.athleteLevel),
                drillContext: "Accelerate almost to the point of losing the ball — let it rip.",
                microCue: "Whip through the ball.",
                confidence: 0.82
            ))
        }

        // MARK: Trajectory
        if launchAngle < 5 {
            faults.append(BiomechanicalFault(
                category: "Trajectory", phase: .serveContact, severity: .medium,
                observation: "Launch angle \(String(format: "%.1f", launchAngle))° is very flat — net margin is razor thin.",
                whyItMatters: "A flat serve either clips the net or sits up for an easy pass.",
                rootCause: "Contact is too low on the body; you're brow-beating the ball downward.",
                fixSteps: [
                    "Raise the toss 6–10 inches and contact with a higher elbow.",
                    "Strike the ball's equator, not its top.",
                    "Use Target Serve Zone Drill with a slightly higher contact point."
                ],
                drill: Drill.recommended(for: "launchAngle", level: profile.athleteLevel),
                drillContext: "Raise toss 6–10 inches and contact with a higher elbow.",
                microCue: "Get above the ball.",
                confidence: 0.88
            ))
        } else if launchAngle > 25 {
            faults.append(BiomechanicalFault(
                category: "Trajectory", phase: .serveSwing, severity: .medium,
                observation: "High launch \(String(format: "%.1f", launchAngle))° gives the passer a slow, attackable ball.",
                whyItMatters: "Lobbed serves are the easiest in the game to pass and run a offense against.",
                rootCause: "The swing path is underneath and lifting, not driving through the equator.",
                fixSteps: [
                    "Drive the hand AT the target, following through in a flat direction.",
                    "Think 'throw your hand through the ball to the passer's chest'."
                ],
                drill: Drill.recommended(for: "launchAngle", level: profile.athleteLevel),
                drillContext: "Drive the hand AT the target; follow-through leads in flat direction.",
                microCue: "Hit through, not up.",
                confidence: 0.86
            ))
        }

        // MARK: Depth
        if distance > 0 && distance < 20 {
            faults.append(BiomechanicalFault(
                category: "Serve Depth", phase: .serveContact, severity: .medium,
                observation: "Serve landed \(String(format: "%.1f", distance)) ft from the net — no-man's land, an easy transition pass.",
                whyItMatters: "Short serves let the opponent's best passer handle the ball in rhythm.",
                rootCause: "Shoulder rotation stops at contact; there's no balanced cross-body finish to drive depth.",
                fixSteps: [
                    "Finish with the hitting arm crossing your opposite hip.",
                    "Transfer weight forward onto the front foot through contact.",
                    "Use Target Serve Zone Drill aiming for the deep 3 ft."
                ],
                drill: Drill.recommended(for: "serveAccuracy", level: profile.athleteLevel),
                drillContext: "Finish with the hitting arm crossing your opposite hip.",
                microCue: "Finish across the body.",
                confidence: 0.84
            ))
        }

        return faults.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }
}

// MARK: - Session Analyzer

struct SessionAnalyzer {
    static func intelligence(profile: AthleteProfile, sessionHits: [VolleyballHit]) -> SessionIntelligence {
        guard !sessionHits.isEmpty else {
            return SessionIntelligence(sessionID: UUID(), hitCount: 0, fatigueDetected: false, peakWindowStartIndex: nil, peakWindowEndIndex: nil, trendDirection: .stable, consistencyScore: 1.0, dominantFaultCategory: nil, recoveryRecommendation: nil)
        }

        let scores = sessionHits.map(\.overallScore)
        let hitCount = sessionHits.count
        let consistency = profile.sessionConsistency

        var fatigueDetected = false
        if scores.count >= 10 {
            let firstHalf = Array(scores.prefix(scores.count / 2))
            let secondHalf = Array(scores.suffix(scores.count / 2))
            let avgFirst = firstHalf.reduce(0, +) / Double(firstHalf.count)
            let avgSecond = secondHalf.reduce(0, +) / Double(secondHalf.count)
            if (avgFirst - avgSecond) / max(avgFirst, 1) > Double(profile.fatigueThreshold) {
                fatigueDetected = true
            }
        }

        var peakStart: Int?
        var peakEnd: Int?
        var bestAvg: Double = 0
        let windowSize = min(5, scores.count)
        for i in 0...(scores.count - windowSize) {
            let window = Array(scores[i..<(i+windowSize)])
            let avg = window.reduce(0, +) / Double(windowSize)
            if avg > bestAvg {
                bestAvg = avg
                peakStart = i
                peakEnd = i + windowSize - 1
            }
        }

        let trend: SessionIntelligence.TrendDirection
        if scores.count >= 6 {
            let chunkSize = scores.count / 3
            let first = Array(scores.prefix(chunkSize))
            let last = Array(scores.suffix(chunkSize))
            let delta = (last.reduce(0,+) / Double(last.count)) - (first.reduce(0,+) / Double(first.count))
            if delta > 8 { trend = .improving }
            else if delta < -8 { trend = .declining }
            else if consistency < 0.4 { trend = .volatile }
            else { trend = .stable }
        } else {
            trend = .stable
        }

        let dominant = profile.weakAreas.first

        let recovery: String?
        if fatigueDetected {
            recovery = "Fatigue detected. Reduce volume by 40% and focus on single-phase shadow reps. Hydrate. Return fresh in 90 min or next session."
        } else if trend == .volatile {
            recovery = "Inconsistent results — pause power output and repeat a single phase 10x silently before the next live attempt."
        } else {
            recovery = nil
        }

        return SessionIntelligence(
            sessionID: UUID(),
            hitCount: hitCount,
            fatigueDetected: fatigueDetected,
            peakWindowStartIndex: peakStart,
            peakWindowEndIndex: peakEnd,
            trendDirection: trend,
            consistencyScore: consistency,
            dominantFaultCategory: dominant,
            recoveryRecommendation: recovery
        )
    }

    static func recommendedSessionFocus(profile: AthleteProfile) -> [String] {
        var focus: [String] = []
        if profile.weakAreas.isEmpty {
            if profile.athleteLevel == .beginner {
                focus = ["armExtension", "verticalJump", "powerTransfer"]
            } else {
                focus = ["wristSnap", "explosiveness", "coreRotation"]
            }
        } else {
            let count = min(profile.athleteLevel.maxDrillsPerSession, profile.weakAreas.count)
            focus = Array(profile.weakAreas.prefix(count))
        }
        return focus
    }
}

// MARK: - Public API

struct CoachEngine {

    // -------------------------------------------------------------------
    // Score computation (unchanged public API)
    // -------------------------------------------------------------------
    static func computeScore(
        hitType: String,
        armAngle: Double,
        jumpHeight: Double,
        ballSpeed: Double,
        launchAngle: Double,
        distance: Double
    ) -> Double {
        if hitType == "Spike" {
            let angleScore   = max(0, min(100, (armAngle - 100) * 1.2))
            let jumpScore    = max(0, min(100, jumpHeight * 4.5))
            let speedScore   = max(0, min(100, ballSpeed * 2.2))
            let downScore    = launchAngle < 0 ? max(0, min(30, abs(launchAngle) * 2)) : max(0, 15 - launchAngle * 0.5)
            return max(10, min(100, angleScore * 0.30 + jumpScore * 0.30 + speedScore * 0.25 + downScore * 0.15))
        } else {
            let angleScore   = max(0, min(100, (armAngle - 110) * 1.5))
            let speedScore   = max(0, min(100, ballSpeed * 2.8))
            let launchPenalty: Double
            if launchAngle < 5 { launchPenalty = 25 }
            else if launchAngle < 10 { launchPenalty = 12 }
            else if launchAngle < 25 { launchPenalty = 0 }
            else { launchPenalty = min(30, (launchAngle - 25) * 1.5) }
            return max(10, min(100, angleScore * 0.30 + speedScore * 0.50 - launchPenalty * 0.20 + 10))
        }
    }

    // -------------------------------------------------------------------
    // Build an inferred profile when none is supplied, so feedback is
    // always rich and adaptive rather than falling back to a flat style.
    // -------------------------------------------------------------------
    private static func inferredProfile(
        hitType: String,
        armAngle: Double,
        jumpHeight: Double,
        ballSpeed: Double,
        launchAngle: Double
    ) -> AthleteProfile {
        var p = AthleteProfile()
        let level = AthleteLevel.estimate(from: hitType, ballSpeed: ballSpeed, jumpHeight: jumpHeight, armAngle: armAngle)
        p.athleteLevel = level
        p.nextTargetArmAngle   = level.targetArmAngleSpike
        p.nextTargetJumpHeight = level.targetJumpHeightInches
        p.nextTargetBallSpeed  = (hitType == "Spike") ? level.targetBallSpeedMPH : level.targetServeSpeedMPH
        // Seed a small window so session intelligence + areas have something to read.
        for _ in 0..<3 {
            p.recentHitMetrics.append(HitMetricSnapshot(
                speed: ballSpeed, angle: armAngle, jump: jumpHeight,
                launch: launchAngle, score: computeScore(hitType: hitType, armAngle: armAngle, jumpHeight: jumpHeight, ballSpeed: ballSpeed, launchAngle: launchAngle, distance: 0)
            ))
        }
        return p
    }

    // -------------------------------------------------------------------
    // Unified, thorough coaching feedback
    // -------------------------------------------------------------------
    static func generateFeedback(
        hitType: String,
        armAngle: Double,
        jumpHeight: Double,
        ballSpeed: Double,
        launchAngle: Double,
        distance: Double,
        profile: AthleteProfile? = nil,
        sessionHits: [VolleyballHit]? = nil,
        confidence: Double = 1.0
    ) -> String {

        let prof: AthleteProfile
        if let profile = profile {
            prof = profile
        } else {
            prof = inferredProfile(hitType: hitType, armAngle: armAngle, jumpHeight: jumpHeight, ballSpeed: ballSpeed, launchAngle: launchAngle)
        }

        let faults: [BiomechanicalFault]
        if hitType == "Spike" {
            faults = DetectSpike.detect(
                armAngle: armAngle,
                jumpHeight: jumpHeight,
                ballSpeed: ballSpeed,
                launchAngle: launchAngle,
                distance: distance,
                profile: prof
            )
        } else {
            faults = DetectServe.detect(
                armAngle: armAngle,
                ballSpeed: ballSpeed,
                launchAngle: launchAngle,
                distance: distance,
                profile: prof
            )
        }

        // Debounce low-quality tracking frames
        let credibleFaults = faults.filter { $0.confidence >= 0.60 }
        if credibleFaults.isEmpty {
            return """
            ✅ Clean rep — every key metric is inside an effective range for your level.
            What went right: arm extension, \(hitType == "Spike" ? "downward attack angle" : "serve trajectory"), and power transfer all look efficient.
            Lock this feeling in: repeat 5 more reps at this same tempo, then film one to compare against future swings.
            """
        }

        let intel = SessionAnalyzer.intelligence(profile: prof, sessionHits: sessionHits ?? [])
        return formatEnhancedFeedback(
            faults: credibleFaults,
            profile: prof,
            intelligence: intel,
            hitType: hitType,
            metrics: (armAngle, jumpHeight, ballSpeed, launchAngle, distance)
        )
    }

    // -------------------------------------------------------------------
    // Thorough, structured formatter
    // -------------------------------------------------------------------
    private static func formatEnhancedFeedback(
        faults: [BiomechanicalFault],
        profile: AthleteProfile,
        intelligence: SessionIntelligence,
        hitType: String,
        metrics: (armAngle: Double, jumpHeight: Double, ballSpeed: Double, launchAngle: Double, distance: Double)
    ) -> String {

        let primary = faults[0]
        let rest = Array(faults.dropFirst().prefix(2)) // up to 2 secondary issues
        var parts: [String] = []

        // Header
        parts.append("🏐 \(hitType) Coaching Report")
        parts.append("Level: \(profile.athleteLevel.rawValue)  •  Score: \(Int(profile.recentFormScore))")
        parts.append("Measured: arm \(Int(metrics.armAngle))° · jump \(String(format: "%.1f", metrics.jumpHeight))″ · speed \(Int(metrics.ballSpeed)) mph · launch \(String(format: "%.1f", metrics.launchAngle))°" + (metrics.distance > 0 ? " · depth \(String(format: "%.1f", metrics.distance)) ft" : ""))
        parts.append("")

        // Primary focus block
        parts.append("🎯 PRIMARY FOCUS — \(primary.category) (\(primary.severityLabel))")
        parts.append(primary.observation)
        parts.append("Why it matters: \(primary.whyItMatters)")
        parts.append("Root cause: \(primary.rootCause)")
        parts.append("How to fix:")
        for (i, step) in primary.fixSteps.enumerated() {
            parts.append("   \(i + 1). \(step)")
        }
        if !primary.microCue.isEmpty {
            parts.append("⚡ Real-time cue: \"\(primary.microCue)\"")
        }
        parts.append("💪 Recommended drill: \(primary.drill.name)")
        parts.append("   \(primary.drill.description)")
        parts.append("   Protocol: \(primary.drill.sets) sets × \(primary.drill.reps) reps · rest \(primary.drill.restSeconds)s")
        if let hint = primary.drill.progressionHint {
            parts.append("   Progress when ready: \(hint)")
        }

        // Secondary focus blocks (condensed)
        for s in rest {
            parts.append("")
            parts.append("📌 ALSO WORKING ON — \(s.category) (\(s.severityLabel))")
            parts.append(s.observation)
            parts.append("Why: \(s.whyItMatters)")
            parts.append("Fix: \(s.fixSteps.joined(separator: " "))")
            parts.append("   Drill: \(s.drill.name) — \(s.drill.sets)×\(s.drill.reps), rest \(s.drill.restSeconds)s")
        }

        // Session intelligence
        if intelligence.hitCount >= 4 {
            parts.append("")
            parts.append("📊 SESSION PULSE (\(intelligence.hitCount) hits)")
            parts.append("Trend: \(intelligence.trendDirection.rawValue.capitalized) · Consistency: \(Int(intelligence.consistencyScore * 100))%")
            if let cat = intelligence.dominantFaultCategory { parts.append("Recurring pattern to break: \(cat)") }
            if let p1 = intelligence.peakWindowStartIndex, let p2 = intelligence.peakWindowEndIndex {
                parts.append("⭐ Peak window: hits \(p1 + 1)–\(p2 + 1) — this is your ideal rhythm, chase it.")
            }
            if let rec = intelligence.recoveryRecommendation { parts.append("🛑 \(rec)") }
        }

        // Practice plan
        let sessionFocus = SessionAnalyzer.recommendedSessionFocus(profile: profile)
        if !sessionFocus.isEmpty {
            parts.append("")
            parts.append("🗂 YOUR PRACTICE PRIORITIES")
            let labels = sessionFocus.map { focusLabel($0) }
            parts.append(labels.enumerated().map { "   \($0 + 1). \($1)" }.joined(separator: "\n"))
        }

        return parts.joined(separator: "\n")
    }

    private static func focusLabel(_ focus: String) -> String {
        switch focus {
        case "armExtension": return "Arm Extension — reach full high-point contact"
        case "verticalJump": return "Vertical Jump — load hips, explode up"
        case "powerTransfer": return "Power Transfer — wrist snap through the ball"
        case "wristSnap": return "Wrist Snap — late, fast whip over the top"
        case "explosiveness": return "Explosiveness — approach-to-jump conversion"
        case "coreRotation": return "Core Rotation — hips lead the torso"
        case "approachTiming": return "Approach Timing — sync arm swing to plant"
        case "armSpeed": return "Arm Speed — loose, whippy contact"
        case "tossConsistency": return "Toss Consistency — same height & spot"
        case "launchAngle": return "Launch Angle — drive through the equator"
        case "contactHand": return "Contact Hand — top-back quadrant"
        case "serveAccuracy": return "Serve Accuracy — cross-body finish"
        case "contactPoint": return "Contact Point — strike at full reach"
        case "placement": return "Shot Placement — deep corner targeting"
        case "elitePowerChain": return "Elite Power Chain — maintain & refine"
        default: return focus.capitalized
        }
    }
}

// MARK: - Summary Card Builder

struct SummaryCardBuilder {
    static func build(for profile: AthleteProfile, hits: [any Sendable]) -> String {
        guard !hits.isEmpty else { return "No hits recorded yet." }
        let scores = hits.compactMap { $0 as? VolleyballHit }.map(\.overallScore)
        let avg = scores.reduce(0, +) / Double(scores.count)
        let best = scores.max() ?? 0
        let worst = scores.min() ?? 0
        let latest = scores.last ?? 0

        var text = "📈 Session Summary\n"
        text += "Hits: \(hits.count) | Level: \(profile.athleteLevel.rawValue)\n"
        text += "Latest: \(Int(latest)) | Avg: \(Int(avg)) | Best: \(Int(best)) | Worst: \(Int(worst))\n"
        text += "Consistency: \(Int(profile.sessionConsistency * 100))%\n"
        if !profile.strongAreas.isEmpty { text += "Strengths: \(profile.strongAreas.joined(separator: ", "))\n" }
        if !profile.weakAreas.isEmpty { text += "Areas to sharpen: \(profile.weakAreas.prefix(3).joined(separator: ", "))\n" }
        text += "Next targets → Arm: \(Int(profile.nextTargetArmAngle))° | Jump: \(String(format: "%.1f", profile.nextTargetJumpHeight)) in | Speed: \(Int(profile.nextTargetBallSpeed)) mph"
        return text
    }
}