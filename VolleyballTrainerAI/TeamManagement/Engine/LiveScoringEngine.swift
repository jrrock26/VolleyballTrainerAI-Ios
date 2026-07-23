import SwiftUI
import SwiftData
import Foundation
import Combine

// MARK: - Live Scoring Engine

@MainActor
final class LiveScoringEngine: ObservableObject {
    // Published state
    @Published var homeScore: Int = 0
    @Published var awayScore: Int = 0
    @Published var currentSet: Int = 1
    @Published var homeSetsWon: Int = 0
    @Published var awaySetsWon: Int = 0
    @Published var isMatchOver: Bool = false
    @Published var matchWinner: String = ""
    @Published var isServing: String = "home"  // "home" or "away"
    @Published var servingPlayerID: UUID?
    @Published var playByPlayLog: [PlayByPlayEntry] = []
    @Published var setHistory: [SetResult] = []
    @Published var homeTimeouts: Int = 2
    @Published var awayTimeouts: Int = 2
    @Published var maxTimeouts: Int = 2
    @Published var isTimeoutActive: Bool = false
    @Published var currentRotation: Int = 1
    @Published var homeRotations: [RotationState] = []
    @Published var awayRotations: [RotationState] = []
    @Published var substitutionCount: (home: Int, away: Int) = (0, 0)
    @Published var maxSubstitutions: Int = 12
    @Published var homeServeStreak: Int = 0
    @Published var awayServeStreak: Int = 0
    @Published var matchStartTime: Date?
    @Published var matchElapsed: TimeInterval = 0
    
    // Per-player stat tracking (in-memory during live scoring)
    @Published var homePlayerStats: [UUID: LivePlayerStats] = [:]
    @Published var awayPlayerStats: [UUID: LivePlayerStats] = [:]
    
    // Court heatmap zones
    @Published var heatmapZones: [String: HeatmapZone] = [:]
    
    // Players on court
    @Published var homeCourtPlayers: [UUID] = []
    @Published var awayCourtPlayers: [UUID] = []
    
    // Sync state
    @Published var isSyncing: Bool = false
    @Published var lastSyncTimestamp: Date?
    @Published var isOfflineMode: Bool = false
    
    private var matchTimer: Timer?
    private var timeoutTimer: Timer?
    private var syncTimer: Timer?
    
    // Winning score thresholds
    private let regularSetWinScore = 25
    private let decidingSetWinScore = 15
    private let minPointDiff = 2
    
    init() {
        setupHeatmapZones()
        resetMatch()
    }
    
    // MARK: - Heatmap Setup
    
    private func setupHeatmapZones() {
        let zones = [
            ("Z1", "Left Back"), ("Z2", "Middle Back"), ("Z3", "Right Back"),
            ("Z4", "Left Middle"), ("Z5", "Center Middle"), ("Z6", "Right Middle"),
            ("Z7", "Left Front"), ("Z8", "Center Front"), ("Z9", "Right Front"),
            ("Z10", "Left Line"), ("Z11", "Right Line"), ("Z12", "Deep Center"),
            ("Z13", "Short Left"), ("Z14", "Short Middle"), ("Z15", "Short Right")
        ]
        heatmapZones = Dictionary(uniqueKeysWithValues: zones.map { ($0.0, HeatmapZone(zoneID: $0.0, label: $0.1)) })
    }
    
    // MARK: - Match Control
    
    func startMatch() {
        matchStartTime = Date()
        isMatchOver = false
        matchWinner = ""
        homeSetsWon = 0
        awaySetsWon = 0
        currentSet = 1
        homeScore = 0
        awayScore = 0
        isServing = "home"
        homeTimeouts = maxTimeouts
        awayTimeouts = maxTimeouts
        playByPlayLog = []
        setHistory = []
        homePlayerStats = [:]
        awayPlayerStats = [:]
        homeServeStreak = 0
        awayServeStreak = 0
        substitutionCount = (0, 0)
        
        for key in heatmapZones.keys {
            heatmapZones[key]?.hitCount = 0
            heatmapZones[key]?.killCount = 0
            heatmapZones[key]?.errorCount = 0
        }
        
        startMatchTimer()
        startSyncTimer()
    }
    
    func resetMatch() {
        matchTimer?.invalidate()
        syncTimer?.invalidate()
        timeoutTimer?.invalidate()
        matchStartTime = nil
        matchElapsed = 0
        homeScore = 0
        awayScore = 0
        currentSet = 1
        homeSetsWon = 0
        awaySetsWon = 0
        isMatchOver = false
        matchWinner = ""
        isServing = "home"
        servingPlayerID = nil
        playByPlayLog = []
        setHistory = []
        homeTimeouts = maxTimeouts
        awayTimeouts = maxTimeouts
        isTimeoutActive = false
        currentRotation = 1
        homeServeStreak = 0
        awayServeStreak = 0
        substitutionCount = (0, 0)
    }
    
    private func startMatchTimer() {
        matchTimer?.invalidate()
        matchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            MainActor.assumeIsolated {
                if let start = self.matchStartTime {
                    self.matchElapsed = Date().timeIntervalSince(start)
                }
            }
        }
    }
    
    private func startSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            MainActor.assumeIsolated {
                self.syncState()
            }
        }
    }
    
    // MARK: - Scoring
    
    func awardPoint(to team: String, playerID: UUID, eventType: String = "attack") {
        guard !isMatchOver, !isTimeoutActive else { return }
        
        if team == "home" {
            homeScore += 1
            homeServeStreak += 1
            awayServeStreak = 0
        } else {
            awayScore += 1
            awayServeStreak += 1
            homeServeStreak = 0
        }
        
        let entry = PlayByPlayEntry(
            id: UUID(),
            timestamp: Date(),
            setNumber: currentSet,
            eventType: eventType,
            description: "\(team == "home" ? "Home" : "Away") scores! (\(homeScore)-\(awayScore))",
            scoringTeam: team,
            playerID: playerID,
            homeScoreAfter: homeScore,
            awayScoreAfter: awayScore
        )
        playByPlayLog.append(entry)
        
        // Update player stats
        updatePlayerStats(team: team, playerID: playerID, statType: "points")
        
        // Check set winner
        checkSetWinner()
    }
    
    func recordPlay(eventType: String, description: String, scoringTeam: String,
                    playerID: UUID, playerName: String = "", zoneID: String? = nil) {
        guard !isMatchOver, !isTimeoutActive else { return }
        
        let entry = PlayByPlayEntry(
            id: UUID(),
            timestamp: Date(),
            setNumber: currentSet,
            eventType: eventType,
            description: description,
            scoringTeam: scoringTeam,
            playerID: playerID,
            playerName: playerName,
            homeScoreAfter: homeScore,
            awayScoreAfter: awayScore,
            zoneID: zoneID
        )
        playByPlayLog.append(entry)
        
        // Track stat type
        updatePlayerStats(team: scoringTeam, playerID: playerID, statType: eventType)
        
        // Update heatmap
        if let zone = zoneID {
            recordHeatmapHit(zoneID: zone, wasKill: eventType == "attack" && scoringTeam == "home" || eventType == "attack" && scoringTeam == "away")
        }
    }
    
    func awardAce(team: String, playerID: UUID) {
        awardPoint(to: team, playerID: playerID, eventType: "ace")
        updatePlayerStats(team: team, playerID: playerID, statType: "ace")
    }
    
    func recordError(team: String, playerID: UUID, errorType: String = "attack_error") {
        // Opposing team gets the point
        let scoringTeam = team == "home" ? "away" : "home"
        awardPoint(to: scoringTeam, playerID: UUID(), eventType: errorType)
        
        let entry = PlayByPlayEntry(
            id: UUID(),
            timestamp: Date(),
            setNumber: currentSet,
            eventType: errorType,
            description: "\(team == "home" ? "Home" : "Away") error! Point \(scoringTeam == "home" ? "Home" : "Away") (\(homeScore)-\(awayScore))",
            scoringTeam: scoringTeam,
            playerID: playerID,
            homeScoreAfter: homeScore,
            awayScoreAfter: awayScore
        )
        playByPlayLog.append(entry)
        
        updatePlayerStats(team: team, playerID: playerID, statType: errorType)
    }
    
    func undoLastPoint() {
        guard let lastEntry = playByPlayLog.popLast() else { return }
        
        if lastEntry.scoringTeam == "home" {
            homeScore = max(0, homeScore - 1)
            homeServeStreak = max(0, homeServeStreak - 1)
        } else {
            awayScore = max(0, awayScore - 1)
            awayServeStreak = max(0, awayServeStreak - 1)
        }
    }
    
    // MARK: - Set/Set Winner Detection
    
    private func checkSetWinner() {
        let winScore = currentSet == 5 ? decidingSetWinScore : regularSetWinScore
        
        if homeScore >= winScore && (homeScore - awayScore) >= minPointDiff {
            // Home wins set
            homeSetsWon += 1
            let setResult = SetResult(
                setNumber: currentSet,
                homeScore: homeScore,
                awayScore: awayScore,
                winner: "home"
            )
            setHistory.append(setResult)
            startNewSet()
            checkMatchWinner()
        } else if awayScore >= winScore && (awayScore - homeScore) >= minPointDiff {
            // Away wins set
            awaySetsWon += 1
            let setResult = SetResult(
                setNumber: currentSet,
                homeScore: homeScore,
                awayScore: awayScore,
                winner: "away"
            )
            setHistory.append(setResult)
            startNewSet()
            checkMatchWinner()
        }
    }
    
    private func startNewSet() {
        homeScore = 0
        awayScore = 0
        currentSet += 1
        isServing = (currentSet % 2 == 1) ? "home" : "away"
        homeTimeouts = maxTimeouts
        awayTimeouts = maxTimeouts
        homeServeStreak = 0
        awayServeStreak = 0
        currentRotation = 1
    }
    
    private func checkMatchWinner() {
        // Best of 5: first to 3 sets
        if homeSetsWon >= 3 {
            isMatchOver = true
            matchWinner = "home"
            matchTimer?.invalidate()
            syncTimer?.invalidate()
        } else if awaySetsWon >= 3 {
            isMatchOver = true
            matchWinner = "away"
            matchTimer?.invalidate()
            syncTimer?.invalidate()
        }
    }
    
    // MARK: - Timeouts
    
    func callTimeout(for team: String) {
        guard !isTimeoutActive else { return }
        
        if team == "home" && homeTimeouts > 0 {
            homeTimeouts -= 1
        } else if team == "away" && awayTimeouts > 0 {
            awayTimeouts -= 1
        } else {
            return
        }
        
        isTimeoutActive = true
        
        let entry = PlayByPlayEntry(
            id: UUID(),
            timestamp: Date(),
            setNumber: currentSet,
            eventType: "timeout",
            description: "\(team == "home" ? "Home" : "Away") timeout (30s)",
            scoringTeam: team,
            playerID: nil,
            homeScoreAfter: homeScore,
            awayScoreAfter: awayScore
        )
        playByPlayLog.append(entry)
        
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            MainActor.assumeIsolated {
                self.isTimeoutActive = false
            }
        }
    }
    
    func endTimeoutEarly() {
        timeoutTimer?.invalidate()
        isTimeoutActive = false
    }
    
    // MARK: - Substitutions
    
    func recordSubstitution(team: String, playerIn: UUID, playerOut: UUID) {
        if team == "home" {
            substitutionCount.home += 1
        } else {
            substitutionCount.away += 1
        }
        
        let entry = PlayByPlayEntry(
            id: UUID(),
            timestamp: Date(),
            setNumber: currentSet,
            eventType: "substitution",
            description: "\(team == "home" ? "Home" : "Away") substitution",
            scoringTeam: team,
            playerID: playerIn,
            homeScoreAfter: homeScore,
            awayScoreAfter: awayScore
        )
        playByPlayLog.append(entry)
    }
    
    // MARK: - Player Stats Tracking
    
    private func updatePlayerStats(team: String, playerID: UUID, statType: String) {
        var stats = team == "home" ? (homePlayerStats[playerID] ?? LivePlayerStats()) :
                                     (awayPlayerStats[playerID] ?? LivePlayerStats())
        
        switch statType {
        case "attack", "kill":
            stats.kills += 1
            stats.attackAttempts += 1
        case "ace":
            stats.aces += 1
            stats.serveAttempts += 1
        case "block":
            stats.soloBlocks += 1
        case "block_assist":
            stats.blockAssists += 1
        case "dig":
            stats.digs += 1
        case "assist", "set":
            stats.assists += 1
        case "attack_error":
            stats.attackErrors += 1
            stats.attackAttempts += 1
        case "serve_error":
            stats.serveErrors += 1
            stats.serveAttempts += 1
        case "block_error":
            stats.blockErrors += 1
        case "receive_error":
            stats.receptionErrors += 1
        case "points":
            stats.pointsScored += 1
        default:
            break
        }
        
        if team == "home" {
            homePlayerStats[playerID] = stats
        } else {
            awayPlayerStats[playerID] = stats
        }
    }
    
    func recordServe(team: String, playerID: UUID, isAce: Bool = false, isError: Bool = false) {
        var stats = team == "home" ? (homePlayerStats[playerID] ?? LivePlayerStats()) :
                                     (awayPlayerStats[playerID] ?? LivePlayerStats())
        stats.serveAttempts += 1
        if isAce { stats.aces += 1 }
        if isError { stats.serveErrors += 1 }
        
        if team == "home" { homePlayerStats[playerID] = stats }
        else { awayPlayerStats[playerID] = stats }
    }
    
    func recordAttack(team: String, playerID: UUID, isKill: Bool = false, isError: Bool = false) {
        var stats = team == "home" ? (homePlayerStats[playerID] ?? LivePlayerStats()) :
                                     (awayPlayerStats[playerID] ?? LivePlayerStats())
        stats.attackAttempts += 1
        if isKill { stats.kills += 1 }
        if isError { stats.attackErrors += 1 }
        
        if team == "home" { homePlayerStats[playerID] = stats }
        else { awayPlayerStats[playerID] = stats }
    }
    
    // MARK: - Heatmap
    
    func recordHeatmapHit(zoneID: String, wasKill: Bool) {
        heatmapZones[zoneID]?.hitCount += 1
        if wasKill {
            heatmapZones[zoneID]?.killCount += 1
        } else {
            heatmapZones[zoneID]?.errorCount += 1
        }
    }
    
    // MARK: - Rotation
    
    func advanceRotation(team: String) {
        if team == "home" {
            currentRotation = currentRotation % 6 + 1
        }
    }
    
    // MARK: - Side Switching
    
    func switchSides() {
        // After each set, teams switch sides
        isServing = isServing == "home" ? "away" : "home"
    }
    
    // MARK: - Sync
    
    private func syncState() {
        isSyncing = true
        // In a production system, this would sync to a cloud backend
        // For now, we update the local timestamp
        lastSyncTimestamp = Date()
        isSyncing = false
    }
    
    func enableOfflineMode() {
        isOfflineMode = true
        syncTimer?.invalidate()
    }
    
    func disableOfflineMode() {
        isOfflineMode = false
        startSyncTimer()
    }
    
    // MARK: - Match Summary
    
    func generateMatchSummary(homeTeamName: String, awayTeamName: String) -> String {
        var summary = "Match Summary\n"
        summary += "\(homeTeamName) \(homeSetsWon) - \(awaySetsWon) \(awayTeamName)\n\n"
        
        for set in setHistory {
            summary += "Set \(set.setNumber): \(set.homeScore)-\(set.awayScore)\n"
        }
        
        summary += "\nHome Stats:\n"
        for (_, stats) in homePlayerStats {
            summary += "K:\(stats.kills) A:\(stats.assists) D:\(stats.digs) B:\(stats.soloBlocks + stats.blockAssists)\n"
        }
        
        return summary
    }
}

// MARK: - Supporting Types

struct PlayByPlayEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let setNumber: Int
    let eventType: String
    let description: String
    let scoringTeam: String
    let playerID: UUID?
    var playerName: String = ""
    let homeScoreAfter: Int
    let awayScoreAfter: Int
    var zoneID: String? = nil
    
    var formattedTime: String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df.string(from: timestamp)
    }
}

struct SetResult: Identifiable {
    let id: UUID = UUID()
    let setNumber: Int
    let homeScore: Int
    let awayScore: Int
    let winner: String
}

struct LivePlayerStats {
    var kills: Int = 0
    var attackAttempts: Int = 0
    var attackErrors: Int = 0
    var aces: Int = 0
    var serveAttempts: Int = 0
    var serveErrors: Int = 0
    var soloBlocks: Int = 0
    var blockAssists: Int = 0
    var blockErrors: Int = 0
    var digs: Int = 0
    var assists: Int = 0
    var pointsScored: Int = 0
    var receptionErrors: Int = 0
    
    var hittingPercentage: Double {
        guard attackAttempts > 0 else { return 0 }
        return Double(kills - attackErrors) / Double(attackAttempts)
    }
}

struct RotationState: Identifiable {
    let id: UUID = UUID()
    var position: Int  // 1-6
    var playerID: UUID?
    var playerName: String
    var isServer: Bool
}