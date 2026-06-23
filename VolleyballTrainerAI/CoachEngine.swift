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
        Drill(name: "Target Serve Zone Drill", category: "Serve Depth", description: "Place a cone or towel in the back third. Serve ONLY to that zone to force flatter, faster trajectory.", difficulty: .intermediate, reps: "15", sets: "3", restSeconds: 60, focuses: ["serveAccuracy","launchAngle"], progressionHint: "Target smaller zones (e.g., just behind the 10-ft line).")
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
            // slight retreat for safety — coach back to fundamentals
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
            // fine-grained granularity at higher levels
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
    let observation: String
    let rootCause: String
    let drill: Drill
    let drillContext: String
    let microCue: String            // one sentence real-time cue
    let confidence: Double          // 0–1 based on tracking certainty

    enum FaultSeverity: Int, Codable { case low = 1, medium = 2, high = 3, critical = 4 }
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

        // Contact phase: arm extension
        if armAngle < targetAngle - 20 {
            faults.append(BiomechanicalFault(
                category: "Arm Action", phase: .contact, severity: .critical,
                observation: "Contact is \(Int(targetAngle - armAngle))° below target — power window is wasted.",
                rootCause: "Premature shoulder rotation pulls the elbow forward before full stretch.",
                drill: Drill.recommended(for: "armExtension", level: profile.athleteLevel),
                drillContext: "Emphasize vertical reach before horizontal rotation.",
                microCue: "Reach UP first, swing LATER.",
                confidence: 0.92
            ))
        } else if armAngle < targetAngle - 5 {
            faults.append(BiomechanicalFault(
                category: "Arm Action", phase: .contact, severity: .medium,
                observation: "Close to target arm extension, but still \(Int(targetAngle - armAngle))° short.",
                rootCause: "Late elbow drop or insufficient arm-drive momentum.",
                drill: Drill.recommended(for: "armExtension", level: profile.athleteLevel),
                drillContext: "Feel the elbow brush past your ear before the hand opens.",
                microCue: "Elbow to ear, then open.",
                confidence: 0.88
            ))
        } else {
            // good arm angle — check wrist snap at contact
            if ballSpeed < targetSpeed * 0.75 {
                faults.append(BiomechanicalFault(
                    category: "Power Transfer", phase: .contact, severity: .medium,
                    observation: "Arm is tracking but ball speed lags — wrist is likely slapping flat.",
                    rootCause: "Hand contacts as a rigid paddle; fingers do not wrap over the ball.",
                    drill: Drill.recommended(for: "wristSnap", level: profile.athleteLevel),
                    drillContext: "Open hand, relax wrist, snap through the top of the ball.",
                    microCue: "Pull the ball down, don't push it.",
                    confidence: 0.85
                ))
            }
        }

        // Jump / approach
        if jumpHeight < targetJump - 4 {
            faults.append(BiomechanicalFault(
                category: "Approach & Jump", phase: .blockJump, severity: .critical,
                observation: "Jump is \(String(format: "%.1f", targetJump - jumpHeight)) in below target — attack angle is compromised.",
                rootCause: "Penultimate step is too vertical; hips are not loading back and down.",
                drill: Drill.recommended(for: "verticalJump", level: profile.athleteLevel),
                drillContext: "Sit back on the penultimate step like sitting into a chair.",
                microCue: "Load hips, explode up.",
                confidence: 0.90
            ))
        } else if jumpHeight < targetJump {
            faults.append(BiomechanicalFault(
                category: "Approach & Jump", phase: .blockJump, severity: .low,
                observation: "Moderate vert. A 2–3 in gain closes air space for blockers.",
                rootCause: "Approach timing is slightly off arm-swing-to-plant ratio.",
                drill: Drill.recommended(for: "approachTiming", level: profile.athleteLevel),
                drillContext: "Match arm swing peak to plant moment exactly.",
                microCue: "Arms down, plant, arms up, jump.",
                confidence: 0.78
            ))
        }

        // Trajectory / launch angle
        if launchAngle >= 0 {
            faults.append(BiomechanicalFault(
                category: "Angle of Attack", phase: .contact, severity: .critical,
                observation: "Ball is launching upward at +\(Int(launchAngle))°. Should always drive down for a spike.",
                rootCause: "Contact point is too low on the ball; palm is pushing rather than topping.",
                drill: Drill.recommended(for: "contactHand", level: profile.athleteLevel),
                drillContext: "Contact the top-back quadrant with wrist leading.",
                microCue: "Hit the top — not the bottom.",
                confidence: 0.95
            ))
        } else if launchAngle > -6 {
            faults.append(BiomechanicalFault(
                category: "Angle of Attack", phase: .followThrough, severity: .medium,
                observation: "Downward angle is shallow (\(String(format: "%.1f", launchAngle))°). Blockers feast on flat angle.",
                rootCause: "Wrist is not snapping over; hand is finishing forward rather than downward.",
                drill: Drill.recommended(for: "launchAngle", level: profile.athleteLevel),
                drillContext: "Break the ball over the net like a tennis topspin serve.",
                microCue: "Snap your palm down NOW.",
                confidence: 0.87
            ))
        }

        // Speed vs arm angle trade-off (efficiency indicator)
        if ballSpeed < targetSpeed * 0.6 && armAngle > targetAngle - 5 {
            faults.append(BiomechanicalFault(
                category: "Power Transfer", phase: .contact, severity: .medium,
                observation: "Arm extension is right, but power is leaking — likely grip tension.",
                rootCause: "Gripping the ball too tightly decelerates arm speed at contact.",
                drill: Drill.recommended(for: "armSpeed", level: profile.athleteLevel),
                drillContext: "Loosen grip; let the hand be a lash, not a baton.",
                microCue: "Soft hand at the top.",
                confidence: 0.76
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

        // Arm extension / toss
        if armAngle < targetAngle - 15 {
            faults.append(BiomechanicalFault(
                category: "Toss & Reach", phase: .trophyPose, severity: .critical,
                observation: "Contact point is \(Int(targetAngle - armAngle))° below target — toss is too low.",
                rootCause: "Toss placement is drifting behind or to the side of the contact shoulder.",
                drill: Drill.recommended(for: "tossConsistency", level: profile.athleteLevel),
                drillContext: "Toss must peak 1 ft in front and 2 ft above your reach.",
                microCue: "Toss UP and FRONT.",
                confidence: 0.93
            ))
        } else if armAngle < targetAngle - 3 {
            faults.append(BiomechanicalFault(
                category: "Toss & Reach", phase: .trophyPose, severity: .low,
                observation: "Good extension, close to \(Int(armAngle))°.",
                rootCause: "Toss location variance is the next bottleneck.",
                drill: Drill.recommended(for: "tossConsistency", level: profile.athleteLevel),
                drillContext: "Toss to the same landing spot every time.",
                microCue: "",
                confidence: 0.80
            ))
        }

        // Speed
        if ballSpeed < targetSpeed * 0.6 {
            faults.append(BiomechanicalFault(
                category: "Power Generation", phase: .serveContact, severity: .critical,
                observation: "Serve velocity \(Int(ballSpeed)) mph — leg-to-core transfer is underdeveloped.",
                rootCause: "Rotation stops at the shoulder; hips do not lead the torso.",
                drill: Drill.recommended(for: "coreRotation", level: profile.athleteLevel),
                drillContext: "Load back hip, rotate hip-to-shoulder separation at contact.",
                microCue: "Hips first, arm last.",
                confidence: 0.90
            ))
        } else if ballSpeed < targetSpeed {
            faults.append(BiomechanicalFault(
                category: "Power Generation", phase: .serveContact, severity: .low,
                observation: "Moderate speed. A looser wrist snap adds 3–5 mph instantly.",
                rootCause: "Arm is rigid through contact; decelerates before snapping.",
                drill: Drill.recommended(for: "armSpeed", level: profile.athleteLevel),
                drillContext: "Accelerate almost to the point of losing the ball — let it rip.",
                microCue: "Whip through the ball.",
                confidence: 0.82
            ))
        }

        // Trajectory
        if launchAngle < 5 {
            faults.append(BiomechanicalFault(
                category: "Trajectory", phase: .serveContact, severity: .medium,
                observation: "Launch angle \(String(format: "%.1f", launchAngle))° is very flat — net margin is razor thin.",
                rootCause: "Toss contact too low on the body; brow-beating the ball down.",
                drill: Drill.recommended(for: "launchAngle", level: profile.athleteLevel),
                drillContext: "Raise toss 6–10 inches and contact with a higher elbow.",
                microCue: "Get above the ball.",
                confidence: 0.88
            ))
        } else if launchAngle > 25 {
            faults.append(BiomechanicalFault(
                category: "Trajectory", phase: .serveSwing, severity: .medium,
                observation: "High launch \(String(format: "%.1f", launchAngle))° gives the passer a beach ball.",
                rootCause: "Swing path is underneath and lifting — not driving through the equator.",
                drill: Drill.recommended(for: "launchAngle", level: profile.athleteLevel),
                drillContext: "Drive the hand AT the target; follow-through leads in flat direction.",
                microCue: "Hit through, not up.",
                confidence: 0.86
            ))
        }

        if distance < 20 {
            faults.append(BiomechanicalFault(
                category: "Serve Depth", phase: .serveContact, severity: .medium,
                observation: "Serve \(String(format: "%.1f", distance)) ft — lands in no-man's land, easy pass transition.",
                rootCause: "Shoulder rotation stops at contact; no balanced cross-body follow-through.",
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

        // Fatigue: slope of last 6 scores vs first 6 (when available)
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

        // Find peak window (5-hit rolling max avg)
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

        // Trending direction
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

        // Dominant fault category (from profile weak areas)
        let dominant = profile.weakAreas.first

        // Recovery recommendation
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
            // Emerging athlete — push the highest-impact fundamental
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
    // Public API: Keep compatibility with existing `VolleyballHit.init`
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
    // Public API: Enhanced multi-instance coaching
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

        guard let profile else {
            // Fallback to legacy feedback if no profile is passed
            return generateLegacyFeedback(
                hitType: hitType,
                armAngle: armAngle,
                jumpHeight: jumpHeight,
                ballSpeed: ballSpeed,
                launchAngle: launchAngle,
                distance: distance
            )
        }

        let faults: [BiomechanicalFault]
        if hitType == "Spike" {
            faults = DetectSpike.detect(
                armAngle: armAngle,
                jumpHeight: jumpHeight,
                ballSpeed: ballSpeed,
                launchAngle: launchAngle,
                distance: distance,
                profile: profile
            )
        } else {
            faults = DetectServe.detect(
                armAngle: armAngle,
                ballSpeed: ballSpeed,
                launchAngle: launchAngle,
                distance: distance,
                profile: profile
            )
        }

        // Filter by tracking confidence (debounce low-quality frames)
        let credibleFaults = faults.filter { $0.confidence >= 0.60 }
        if credibleFaults.isEmpty { return "Clean rep — lock this feeling in." }

        let sessionHits = sessionHits ?? []
        let intelligence = SessionAnalyzer.intelligence(profile: profile, sessionHits: sessionHits)

        return formatEnhancedFeedback(
            faults: credibleFaults,
            profile: profile,
            intelligence: intelligence,
            hitType: hitType
        )
    }

    // -------------------------------------------------------------------
    // Legacy compatibility bridge (older call sites)
    // -------------------------------------------------------------------
    private static func generateLegacyFeedback(
        hitType: String,
        armAngle: Double,
        jumpHeight: Double,
        ballSpeed: Double,
        launchAngle: Double,
        distance: Double
    ) -> String {
        let components = hitType == "Spike"
            ? analyzeSpikeLegacy(armAngle: armAngle, jumpHeight: jumpHeight, ballSpeed: ballSpeed, launchAngle: launchAngle, distance: distance)
            : analyzeServeLegacy(armAngle: armAngle, ballSpeed: ballSpeed, launchAngle: launchAngle, distance: distance)
        return formatLegacyFeedback(components: components, hitType: hitType)
    }

    private struct LegacyComponent {
        let severity: Int
        let category: String
        let observation: String
        let prescription: String
        let drill: String?
    }

    private static func analyzeSpikeLegacy(armAngle: Double, jumpHeight: Double, ballSpeed: Double, launchAngle: Double, distance: Double) -> [LegacyComponent] {
        var items: [LegacyComponent] = []
        if armAngle < 130 { items.append(LegacyComponent(severity: 3, category: "Arm Action", observation: "Your hitting elbow is dropping well below ideal contact height (\(Int(armAngle))° extension).", prescription: "Focus on an explosive 'bow-and-arrow' draw: pull your hitting elbow back and high, then drive it upward — not forward — as you initiate the swing. Contact the ball at full arm stretch above your head.", drill: "Wall Shadow Drill: Stand 3 ft from a wall, practice the arm swing slowly, ensuring your elbow brushes past your ear before ball contact."))
        } else if armAngle < 150 { items.append(LegacyComponent(severity: 2, category: "Arm Action", observation: "Arm extension at \(Int(armAngle))° is slightly below the optimal 160–175° high-point window.", prescription: "Reach higher at contact by delaying your shoulder rotation. Let your arm fully extend before snapping your wrist. Imagine reaching through a second-story window.", drill: "Toss-and-Reach: Toss a ball 2 ft above your max reach, jump and catch it at the highest point, focusing on full arm extension."))
        } else { items.append(LegacyComponent(severity: 1, category: "Arm Action", observation: "Excellent high-point extension at \(Int(armAngle))°.", prescription: "Maintain this arm drive. Now focus on wrist snap.", drill: nil)) }

        if jumpHeight < 8 { items.append(LegacyComponent(severity: 3, category: "Approach & Jump", observation: "Jump height is very low (\(String(format: "%.1f", jumpHeight)) in) — your approach needs more power generation.", prescription: "Lengthen and accelerate your last two steps. Drive both arms back then swing them forward explosively as you plant.", drill: "3-Step Approach Series: Do 3-step approaches without the ball, focusing on heel-toe plant and arm swing."))
        } else if jumpHeight < 14 { if ballSpeed > 30 { items.append(LegacyComponent(severity: 2, category: "Approach & Jump", observation: "Moderate jump (\(String(format: "%.1f", jumpHeight)) in). You're generating good arm speed despite limited vert — converting ground force into arm whip could unlock more power.", prescription: "Focus on loading your hips deeper in the penultimate step.", drill: "Box Jump Transitions: From a 12-in box, step off, immediately convert into your 3-step approach."))
        } else { items.append(LegacyComponent(severity: 2, category: "Approach & Jump", observation: "Jump height is moderate (\(String(format: "%.1f", jumpHeight)) in). Gaining 3–5 more inches would significantly improve your attack angle.", prescription: "Increase penultimate step speed and use both arms aggressively in your countermovement.", drill: "Arm Swing Jumps: Jump as high as you can using only your arm swing.")) }
        } else { items.append(LegacyComponent(severity: 1, category: "Approach & Jump", observation: "Strong vertical jump (\(String(format: "%.1f", jumpHeight)) in).", prescription: "Excellent. Now focus on timing: your arm swing should reach full extension at the apex of your jump.", drill: nil)) }

        if launchAngle >= 0 { items.append(LegacyComponent(severity: 3, category: "Angle of Attack", observation: "The ball is traveling upward (+\(String(format: "%.1f", launchAngle))°) — for a spike it should always go downward into the court.", prescription: "Contact the ball higher on its back-top hemisphere. Your hand should be on top of the ball with your fingers pointing down after contact.", drill: "Downward Contact Drill: Stand 3 ft from a high wall, toss the ball 1 ft above your max reach, jump and spike it into the ground so it bounces up and hits the wall."))
        } else if launchAngle > -8 { items.append(LegacyComponent(severity: 2, category: "Angle of Attack", observation: "Downward angle is shallow (\(String(format: "%.1f", launchAngle))°). A steeper trajectory makes blocking harder.", prescription: "Snap your wrist earlier — think of 'breaking' the ball over the net like a tennis serve.", drill: nil))
        } else { items.append(LegacyComponent(severity: 1, category: "Angle of Attack", observation: "Good downward trajectory (\(String(format: "%.1f", launchAngle))°).", prescription: "You're driving the ball into the court well. Now practice aiming.", drill: nil)) }

        return items.sorted { $0.severity > $1.severity }
    }

    private static func analyzeServeLegacy(armAngle: Double, ballSpeed: Double, launchAngle: Double, distance: Double) -> [LegacyComponent] {
        var items: [LegacyComponent] = []
        if armAngle < 135 { items.append(LegacyComponent(severity: 3, category: "Toss & Reach", observation: "Contact point is very low (\(Int(armAngle))° extension). This severely limits power and forces an upward trajectory.", prescription: "Your toss must be higher and slightly in front of your hitting shoulder.", drill: "Toss-Under-Cone: Place a cone 18 in above your reach. Toss so it barely grazes the cone top."))
        } else if armAngle < 155 { items.append(LegacyComponent(severity: 2, category: "Toss & Reach", observation: "Contact at \(Int(armAngle))° — good but still 5–15° short of ideal full extension.", prescription: "Reach higher by shifting your toss 2–3 inches more forward.", drill: nil))
        } else { items.append(LegacyComponent(severity: 1, category: "Toss & Reach", observation: "Full extension at contact (\(Int(armAngle))°).", prescription: "Your reach is excellent. Focus on consistent toss placement.", drill: nil)) }

        if ballSpeed < 25 { items.append(LegacyComponent(severity: 3, category: "Power Generation", observation: "Serve velocity is low (\(String(format: "%.1f", ballSpeed)) mph).", prescription: "Generate power by rotating your core into the shot, not just using your arm.", drill: "Medicine Ball Rotational Toss: Face sideways, rotate through your core and toss the ball against a wall."))
        } else if ballSpeed < 35 { items.append(LegacyComponent(severity: 2, category: "Power Generation", observation: "Moderate serve speed (\(String(format: "%.1f", ballSpeed)) mph).", prescription: "To add 5–8 mph, focus on a quicker arm swing by loosening your wrist.", drill: "Light Ball Speed Drill: Serve as hard as possible — if the arm is stiff, the ball won't go far."))
        } else { items.append(LegacyComponent(severity: 1, category: "Power Generation", observation: "Strong serve velocity (\(String(format: "%.1f", ballSpeed)) mph).", prescription: "Now develop a jump serve.", drill: nil)) }

        if launchAngle < 5 { items.append(LegacyComponent(severity: 2, category: "Trajectory", observation: "Launch angle is very low (\(String(format: "%.1f", launchAngle))°) — the ball may not clear the net consistently.", prescription: "Increase your contact height by adjusting your toss higher and more forward.", drill: nil))
        } else if launchAngle > 25 { items.append(LegacyComponent(severity: 2, category: "Trajectory", observation: "Launch angle is high (\(String(format: "%.1f", launchAngle))°) — the ball will hang in the air, giving the passer time.", prescription: "Drive through the ball more horizontally. Think 'throw your hand at the target'.", drill: "Target Serve: Place a cone in the back third. Serve only to that zone."))
        } else { items.append(LegacyComponent(severity: 1, category: "Trajectory", observation: "Good launch angle (\(String(format: "%.1f", launchAngle))°).", prescription: "", drill: nil)) }

        return items.sorted { $0.severity > $1.severity }
    }

    private static func formatLegacyFeedback(components: [LegacyComponent], hitType: String) -> String {
        guard !components.isEmpty else { return "Looking good! Keep training." }
        let primary = components.first!
        var parts: [String] = []
        parts.append("🎯 \(primary.observation)")
        if !primary.prescription.isEmpty { parts.append(primary.prescription) }
        if let drill = primary.drill { parts.append("💪 Drill: \(drill)") }
        if let sec = components.dropFirst().first {
            parts.append("📌 Next priority: \(sec.observation)")
            if let drill = sec.drill { parts.append("   Drill: \(drill)") }
        }
        return parts.joined(separator: "\n")
    }

    // -------------------------------------------------------------------
    // Enhanced formatter
    // -------------------------------------------------------------------
    private static func formatEnhancedFeedback(
        faults: [BiomechanicalFault],
        profile: AthleteProfile,
        intelligence: SessionIntelligence?,
        hitType: String
    ) -> String {

        let primary = faults[0]
        let secondary = faults.count > 1 ? faults[1] : nil
        var parts: [String] = []

        // Heading with level and hit type
        parts.append("\(hitType) Coaching — Level: \(profile.athleteLevel.rawValue) | Score: \(Int(profile.recentFormScore))")
        parts.append("")

        // Primary
        parts.append("🎯 \(primary.observation)")
        if !primary.microCue.isEmpty {
            parts.append("⚡ Real-time cue: \"\(primary.microCue)\"")
        }
        parts.append("")
        parts.append(primary.rootCause)
        parts.append("")
        parts.append(primary.drill.description)
        parts.append("   Sets x Reps: \(primary.drill.sets) x \(primary.drill.reps) | Rest: \(primary.drill.restSeconds)s")
        if let hint = primary.drill.progressionHint {
            parts.append("   Next step: \(hint)")
        }

        // Secondary
        if let s = secondary {
            parts.append("")
            parts.append("📌 Next: \(s.observation)")
            if !s.microCue.isEmpty { parts.append("   Cue: \"\(s.microCue)\"") }
            parts.append(s.drill.description)
            parts.append("   Sets x Reps: \(s.drill.sets) x \(s.drill.reps) | Rest: \(s.drill.restSeconds)s")
        }

        // Session intelligence
        if let intel = intelligence, intel.hitCount >= 4 {
            parts.append("")
            parts.append("📊 Session (\(intel.hitCount) hits): \(intel.trendDirection.rawValue.capitalized)")
            parts.append("Consistency: \(Int(intel.consistencyScore * 100))%")
            if let cat = intel.dominantFaultCategory { parts.append("Leading pattern to fix: \(cat)") }
            if let rec = intel.recoveryRecommendation { parts.append("🛑 \(rec)") }
            if let p1 = intel.peakWindowStartIndex, let p2 = intel.peakWindowEndIndex {
                parts.append("⭐ Peak window: hits \(p1 + 1)–\(p2 + 1)")
            }
        }

        // Session recommendation
        let sessionFocus = SessionAnalyzer.recommendedSessionFocus(profile: profile)
        if !sessionFocus.isEmpty {
            parts.append("")
            parts.append("🗂 Session priorities: \(sessionFocus.joined(separator: ", "))")
        }

        return parts.joined(separator: "\n")
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