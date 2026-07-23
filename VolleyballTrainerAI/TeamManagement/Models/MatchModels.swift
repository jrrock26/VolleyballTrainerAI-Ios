import SwiftUI
import SwiftData
import Foundation

// MARK: - Match Model

@Model
final class MatchModel {
    var id: UUID
    var opponentName: String
    var opponentLogoData: Data?
    var matchTypeRaw: String
    var location: String
    var address: String
    var matchDate: Date
    var isHomeGame: Bool
    var isCompleted: Bool
    var isLive: Bool
    var homeTeamName: String
    var awayTeamName: String
    var notes: String
    var tournamentName: String
    var bracketPosition: String
    
    // Aggregate result
    var homeSetsWon: Int
    var awaySetsWon: Int
    var winner: String  // "home", "away", ""
    
    var team: TeamModel?
    
    @Relationship(deleteRule: .cascade) var sets: [SetModel]? = []
    @Relationship(deleteRule: .cascade) var playByPlayEvents: [PlayEvent]? = []
    @Relationship(deleteRule: .cascade) var playerStats: [PlayerMatchStats]? = []
    
    var matchType: MatchType {
        get { MatchType(rawValue: matchTypeRaw) ?? .regular }
        set { matchTypeRaw = newValue.rawValue }
    }
    
    init(opponentName: String = "", matchType: MatchType = .regular, location: String = "",
         address: String = "", matchDate: Date = Date(), isHomeGame: Bool = true,
         homeTeamName: String = "", awayTeamName: String = "", notes: String = "",
         tournamentName: String = "") {
        self.id = UUID()
        self.opponentName = opponentName
        self.matchTypeRaw = matchType.rawValue
        self.location = location
        self.address = address
        self.matchDate = matchDate
        self.isHomeGame = isHomeGame
        self.isCompleted = false
        self.isLive = false
        self.homeTeamName = homeTeamName
        self.awayTeamName = awayTeamName
        self.notes = notes
        self.tournamentName = tournamentName
        self.bracketPosition = ""
        self.homeSetsWon = 0
        self.awaySetsWon = 0
        self.winner = ""
    }
    
    var displayTitle: String {
        if isHomeGame {
            return "\(homeTeamName) vs \(awayTeamName.isEmpty ? opponentName : awayTeamName)"
        } else {
            return "\(awayTeamName.isEmpty ? opponentName : awayTeamName) @ \(homeTeamName)"
        }
    }
    
    var scoreDisplay: String {
        guard isCompleted || isLive else { return "vs" }
        return "\(homeSetsWon)-\(awaySetsWon)"
    }
}

// MARK: - Set Model

@Model
final class SetModel {
    var id: UUID
    var setNumber: Int
    var homeScore: Int
    var awayScore: Int
    var isCompleted: Bool
    var winner: String  // "home", "away", ""
    var durationSeconds: Int
    
    var match: MatchModel?
    @Relationship(deleteRule: .cascade) var rotationRecords: [RotationRecord]? = []
    
    init(setNumber: Int, homeScore: Int = 0, awayScore: Int = 0) {
        self.id = UUID()
        self.setNumber = setNumber
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.isCompleted = false
        self.winner = ""
        self.durationSeconds = 0
    }
    
    var isTied: Bool { homeScore == awayScore }
    var totalPoints: Int { homeScore + awayScore }
}

// MARK: - Play Event (Play-by-Play)

@Model
final class PlayEvent {
    var id: UUID
    var timestamp: Date
    var setNumber: Int
    var eventType: String  // "serve", "attack", "block", "dig", "set", "ace", "error", "substitution", "timeout", "point"
    var descriptionText: String
    var scoringTeam: String  // "home", "away"
    var playerID: UUID?
    var playerName: String
    var homeScoreAfter: Int
    var awayScoreAfter: Int
    
    var match: MatchModel?
    
    init(setNumber: Int, eventType: String, description: String, scoringTeam: String,
         playerID: UUID? = nil, playerName: String = "", homeScore: Int = 0, awayScore: Int = 0) {
        self.id = UUID()
        self.timestamp = Date()
        self.setNumber = setNumber
        self.eventType = eventType
        self.descriptionText = description
        self.scoringTeam = scoringTeam
        self.playerID = playerID
        self.playerName = playerName
        self.homeScoreAfter = homeScore
        self.awayScoreAfter = awayScore
    }
}

// MARK: - Rotation Record

@Model
final class RotationRecord {
    var id: UUID
    var rotationNumber: Int
    var playerPositionsJSON: String  // JSON map of position -> playerID
    var homeScoreAtRotation: Int
    var awayScoreAtRotation: Int
    var isServing: Bool
    var serverID: UUID?
    
    var set: SetModel?
    
    init(rotationNumber: Int, playerPositions: [String: String], homeScore: Int, awayScore: Int,
         isServing: Bool = true, serverID: UUID? = nil) {
        self.id = UUID()
        self.rotationNumber = rotationNumber
        self.playerPositionsJSON = ""
        self.homeScoreAtRotation = homeScore
        self.awayScoreAtRotation = awayScore
        self.isServing = isServing
        self.serverID = serverID
        
        if let data = try? JSONEncoder().encode(playerPositions),
           let json = String(data: data, encoding: .utf8) {
            self.playerPositionsJSON = json
        }
    }
}

// MARK: - Player Match Stats

@Model
final class PlayerMatchStats {
    var id: UUID
    var matchID: UUID?
    var playerID: UUID?
    
    // Attack stats
    var kills: Int
    var attackAttempts: Int
    var attackErrors: Int
    
    // Serve stats
    var aces: Int
    var serveAttempts: Int
    var serveErrors: Int
    
    // Block stats
    var soloBlocks: Int
    var blockAssists: Int
    var blockErrors: Int
    
    // Defense stats
    var digs: Int
    var digErrors: Int
    
    // Setting stats
    var assists: Int
    var settingErrors: Int
    
    // Passing/Receive stats
    var passes: Int
    var passErrors: Int
    var perfectPasses: Int  // 3-point pass
    
    // Other
    var pointsScored: Int
    var serviceReceptions: Int
    var receptionErrors: Int
    
    var match: MatchModel?
    var member: TeamMember?
    
    init(matchID: UUID? = nil, playerID: UUID? = nil) {
        self.id = UUID()
        self.matchID = matchID
        self.playerID = playerID
        self.kills = 0
        self.attackAttempts = 0
        self.attackErrors = 0
        self.aces = 0
        self.serveAttempts = 0
        self.serveErrors = 0
        self.soloBlocks = 0
        self.blockAssists = 0
        self.blockErrors = 0
        self.digs = 0
        self.digErrors = 0
        self.assists = 0
        self.settingErrors = 0
        self.passes = 0
        self.passErrors = 0
        self.perfectPasses = 0
        self.pointsScored = 0
        self.serviceReceptions = 0
        self.receptionErrors = 0
    }
    
    // Computed analytics
    var attackEfficiency: Double {
        guard attackAttempts > 0 else { return 0 }
        return Double(kills - attackErrors) / Double(attackAttempts)
    }
    
    var hittingPercentage: Double {
        guard attackAttempts > 0 else { return 0 }
        return Double(kills - attackErrors - 0) / Double(attackAttempts)
    }
    
    var serveEfficiency: Double {
        guard serveAttempts > 0 else { return 0 }
        return Double(aces - serveErrors) / Double(serveAttempts)
    }
    
    var passingRating: Double {
        guard passes > 0 else { return 0 }
        return Double(perfectPasses * 3 + max(0, passes - perfectPasses - passErrors) * 2) / Double(passes)
    }
    
    var blockEffectiveness: Double {
        let totalBlocks = soloBlocks + blockAssists
        guard totalBlocks + blockErrors > 0 else { return 0 }
        return Double(soloBlocks + blockAssists) / Double(totalBlocks + blockErrors)
    }
    
    var digSuccessRate: Double {
        guard digs + digErrors > 0 else { return 0 }
        return Double(digs) / Double(digs + digErrors)
    }
}

// MARK: - Heatmap Zone

struct HeatmapZone: Codable, Identifiable {
    var id: String { zoneID }
    var zoneID: String
    var label: String
    var hitCount: Int
    var killCount: Int
    var errorCount: Int
    
    init(zoneID: String, label: String = "") {
        self.zoneID = zoneID
        self.label = label
        self.hitCount = 0
        self.killCount = 0
        self.errorCount = 0
    }
    
    var efficiency: Double {
        guard hitCount > 0 else { return 0 }
        return Double(killCount - errorCount) / Double(hitCount)
    }
}