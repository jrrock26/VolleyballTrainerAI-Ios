import SwiftUI
import SwiftData
import Foundation
import Combine

// MARK: - Live Scoring Engine (GameChanger-Style)

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
    @Published var isServing: String = "home"
    @Published var servingPlayerID: UUID?
    @Published var playByPlayLog: [PlayByPlayEntry] = []
    @Published var setHistory: [SetResult] = []
    @Published var homeTimeouts: Int = 2
    @Published var awayTimeouts: Int = 2
    @Published var maxTimeouts: Int = 2
    @Published var isTimeoutActive: Bool = false
    @Published var currentRotation: Int = 1
    @Published var homeRotationIndex: Int = 1
    @Published var awayRotationIndex: Int = 1
    @Published var homeServeStreak: Int = 0
    @Published var awayServeStreak: Int = 0
    @Published var matchStartTime: Date?
    @Published var matchElapsed: TimeInterval = 0

    // Per-player stat tracking
    @Published var homePlayerStats: [UUID: LivePlayerStats] = [:]
    @Published var awayPlayerStats: [UUID: LivePlayerStats] = [:]

    // Court heatmap zones
    @Published var heatmapZones: [String: HeatmapZone] = [:]

    // Court player positions (6 on-court positions)
    @Published var homeCourtPositions: [String: CourtPlayer] = [:]
    @Published var awayCourtPositions: [String: CourtPlayer] = [:]

    // Available players for substitution
    @Published var homeBenchPlayers: [UUID] = []
    @Published var awayBenchPlayers: [UUID] = []

    // Player name lookup
    var playerNames: [UUID: String] = [:]

    // Sync state
    @Published var isSyncing: Bool = false
    @Published var lastSyncTimestamp: Date?
    @Published var isOfflineMode: Bool = false

    private var matchTimer: Timer?
    private var timeoutTimer: Timer?
    private var syncTimer: Timer?

    private let regularSetWinScore = 25
    private let decidingSetWinScore = 15
    private let minPointDiff = 2

    init() {
        setupHeatmapZones()
        setupCourtPositions()
        resetMatch()
    }

    // MARK: - Heatmap Setup

    private func setupHeatmapZones() {
        let zones = [
            ("Z1", "Zone 1"), ("Z2", "Zone 2"), ("Z3", "Zone 3"),
            ("Z4", "Zone 4"), ("Z5", "Zone 5"), ("Z6", "Zone 6"),
            ("Z7", "Short Left"), ("Z8", "Short Center"), ("Z9", "Short Right"),
            ("Z10", "Deep Left"), ("Z11", "Deep Center"), ("Z12", "Deep Right"),
            ("Z13", "Left Line"), ("Z14", "Center"), ("Z15", "Right Line")
        ]
        heatmapZones = Dictionary(uniqueKeysWithValues: zones.map { ($0.0, HeatmapZone(zoneID: $0.0, label: $0.1)) })
    }

    private func setupCourtPositions() {
        let positions = ["P1", "P2", "P3", "P4", "P5", "P6"]
        for pos in positions {
            homeCourtPositions[pos] = CourtPlayer(positionID: pos, side: "home")
            awayCourtPositions[pos] = CourtPlayer(positionID: pos, side: "away")
        }
    }

    // MARK: - Court Player Management

    func assignPlayerToPosition(playerID: UUID, playerName: String, positionID: String, side: String) {
        let player = CourtPlayer(positionID: positionID, playerID: playerID, playerName: playerName, side: side)
        if side == "home" {
            homeCourtPositions[positionID] = player
            if !playerNames.keys.contains(playerID) { playerNames[playerID] = playerName }
        } else {
            awayCourtPositions[positionID] = player
            if !playerNames.keys.contains(playerID) { playerNames[playerID] = playerName }
        }
    }

    func removePlayerFromPosition(positionID: String, side: String) {
        if side == "home" {
            homeCourtPositions[positionID] = CourtPlayer(positionID: positionID, side: "home")
        } else {
            awayCourtPositions[positionID] = CourtPlayer(positionID: positionID, side: "away")
        }
    }

    func setServer(playerID: UUID, side: String) {
        servingPlayerID = playerID
        isServing = side
    }

    // MARK: - Rotation Management

    func advanceRotation(for side: String) {
        if side == "home" {
            homeRotationIndex = (homeRotationIndex % 6) + 1
            rotateCourtPositions(side: "home")
        } else {
            awayRotationIndex = (awayRotationIndex % 6) + 1
            rotateCourtPositions(side: "away")
        }
        currentRotation = (currentRotation % 6) + 1
    }

    private func rotateCourtPositions(side: String) {
        let positions = side == "home" ? homeCourtPositions : awayCourtPositions
        guard positions.count == 6 else { return }

        let order = ["P1", "P6", "P5", "P4", "P3", "P2"]
        var players: [CourtPlayer] = order.compactMap { positions[$0] }
        guard players.count == 6 else { return }

        let rotated = [players[5]] + Array(players[0..<5])

        var updated: [String: CourtPlayer] = [:]
        for (i, player) in rotated.enumerated() {
            var p = player
            p.positionID = order[i]
            updated[order[i]] = p
        }

        if side == "home" {
            homeCourtPositions = updated
        } else {
            awayCourtPositions = updated
        }
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
        homeRotationIndex = 1
        awayRotationIndex = 1

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
        homeRotationIndex = 1
        awayRotationIndex = 1
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

    func awardPoint(to team: String, playerID: UUID, eventType: String = "attack", zoneID: String? = nil, playerName: String = "") {
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
            description: "\(team == "home" ? "Home" : "Away") \(eventType)! (\(homeScore)-\(awayScore))",
            scoringTeam: team,
            playerID: playerID,
            playerName: playerName,
            homeScoreAfter: homeScore,
            awayScoreAfter: awayScore,
            zoneID: zoneID
        )
        playByPlayLog.append(entry)

        updatePlayerStats(team: team, playerID: playerID, statType: "points")

        if let zone = zoneID {
            recordHeatmapHit(zoneID: zone, wasKill: true, scoringTeam: team)
        }

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

        updatePlayerStats(team: scoringTeam, playerID: playerID, statType: eventType)

        if let zone = zoneID {
            recordHeatmapHit(zoneID: zone, wasKill: eventType == "attack" || eventType == "kill", scoringTeam: scoringTeam)
        }
    }

    func awardAce(team: String, playerID: UUID, playerName: String = "", zoneID: String? = nil) {
        awardPoint(to: team, playerID: playerID, eventType: "ace", zoneID: zoneID, playerName: playerName)
        updatePlayerStats(team: team, playerID: playerID, statType: "ace")
    }

    func recordError(team: String, playerID: UUID, playerName: String = "", errorType: String = "attack_error") {
        let scoringTeam = team == "home" ? "away" : "home"
        awardPoint(to: scoringTeam, playerID: UUID(), eventType: errorType)

        let entry = PlayByPlayEntry(
            id: UUID(),
            timestamp: Date(),
            setNumber: currentSet,
            eventType: errorType,
            description: "\(team == "home" ? "Home" : "Away") error! Point \(scoringTeam == "home" ? "Home" : "Away")",
            scoringTeam: scoringTeam,
            playerID: playerID,
            playerName: playerName,
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

    // MARK: - Set/Match Winner

    private func checkSetWinner() {
        let winScore = currentSet == 5 ? decidingSetWinScore : regularSetWinScore

        if homeScore >= winScore && (homeScore - awayScore) >= minPointDiff {
            homeSetsWon += 1
            setHistory.append(SetResult(setNumber: currentSet, homeScore: homeScore, awayScore: awayScore, winner: "home"))
            startNewSet()
            checkMatchWinner()
        } else if awayScore >= winScore && (awayScore - homeScore) >= minPointDiff {
            awaySetsWon += 1
            setHistory.append(SetResult(setNumber: currentSet, homeScore: homeScore, awayScore: awayScore, winner: "away"))
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
            id: UUID(), timestamp: Date(), setNumber: currentSet,
            eventType: "timeout",
            description: "\(team == "home" ? "Home" : "Away") timeout",
            scoringTeam: team, playerID: nil,
            homeScoreAfter: homeScore, awayScoreAfter: awayScore
        )
        playByPlayLog.append(entry)

        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            MainActor.assumeIsolated { self.isTimeoutActive = false }
        }
    }

    func endTimeoutEarly() {
        timeoutTimer?.invalidate()
        isTimeoutActive = false
    }

    // MARK: - Substitutions

    func recordSubstitution(team: String, playerIn: UUID, playerInName: String, playerOut: UUID, playerOutName: String) {
        let entry = PlayByPlayEntry(
            id: UUID(), timestamp: Date(), setNumber: currentSet,
            eventType: "substitution",
            description: "\(playerInName) subs in for \(playerOutName)",
            scoringTeam: team, playerID: playerIn,
            homeScoreAfter: homeScore, awayScoreAfter: awayScore
        )
        playByPlayLog.append(entry)
    }

    // MARK: - Player Stats

    private func updatePlayerStats(team: String, playerID: UUID, statType: String) {
        var stats = team == "home" ? (homePlayerStats[playerID] ?? LivePlayerStats()) :
                                      (awayPlayerStats[playerID] ?? LivePlayerStats())

        switch statType {
        case "attack", "kill": stats.kills += 1; stats.attackAttempts += 1
        case "ace": stats.aces += 1; stats.serveAttempts += 1
        case "block": stats.soloBlocks += 1
        case "block_assist": stats.blockAssists += 1
        case "dig": stats.digs += 1
        case "assist", "set": stats.assists += 1
        case "attack_error": stats.attackErrors += 1; stats.attackAttempts += 1
        case "serve_error": stats.serveErrors += 1; stats.serveAttempts += 1
        case "block_error": stats.blockErrors += 1
        case "receive_error": stats.receptionErrors += 1
        case "points": stats.pointsScored += 1
        default: break
        }

        if team == "home" { homePlayerStats[playerID] = stats }
        else { awayPlayerStats[playerID] = stats }
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

    func recordAttack(team: String, playerID: UUID, isKill: Bool = false, isError: Bool = false, zoneID: String? = nil) {
        var stats = team == "home" ? (homePlayerStats[playerID] ?? LivePlayerStats()) :
                                      (awayPlayerStats[playerID] ?? LivePlayerStats())
        stats.attackAttempts += 1
        if isKill { stats.kills += 1 }
        if isError { stats.attackErrors += 1 }
        if team == "home" { homePlayerStats[playerID] = stats }
        else { awayPlayerStats[playerID] = stats }

        if let zone = zoneID {
            recordHeatmapHit(zoneID: zone, wasKill: isKill, scoringTeam: team)
        }
    }

    // MARK: - Heatmap

    func recordHeatmapHit(zoneID: String, wasKill: Bool, scoringTeam: String) {
        heatmapZones[zoneID]?.hitCount += 1
        if wasKill { heatmapZones[zoneID]?.killCount += 1 }
        else { heatmapZones[zoneID]?.errorCount += 1 }
    }

    // MARK: - Side Switching

    func switchSides() {
        isServing = isServing == "home" ? "away" : "home"
    }

    // MARK: - Sync

    private func syncState() {
        isSyncing = true
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
        var summary = "Match Summary\n\(homeTeamName) \(homeSetsWon) - \(awaySetsWon) \(awayTeamName)\n\n"
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

// MARK: - Court Player

struct CourtPlayer {
    var positionID: String
    var playerID: UUID?
    var playerName: String
    var side: String

    init(positionID: String, playerID: UUID? = nil, playerName: String = "", side: String = "home") {
        self.positionID = positionID
        self.playerID = playerID
        self.playerName = playerName
        self.side = side
    }

    var isEmpty: Bool { playerID == nil }

    var displayName: String { playerName.isEmpty ? "Empty" : playerName }
}

// MARK: - Play By Play Entry

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

// MARK: - Set Result

struct SetResult: Identifiable {
    let id: UUID = UUID()
    let setNumber: Int
    let homeScore: Int
    let awayScore: Int
    let winner: String
}

// MARK: - Live Player Stats

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

    var totalBlocks: Int { soloBlocks + blockAssists }
}

// MARK: - Rotation State

struct RotationState: Identifiable {
    let id: UUID = UUID()
    var position: Int
    var playerID: UUID?
    var playerName: String
    var isServer: Bool
}