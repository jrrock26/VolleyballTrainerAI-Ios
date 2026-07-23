import SwiftUI
import SwiftData
import Foundation

// MARK: - Stats Engine

final class StatsEngine {
    
    // MARK: - Player Stats Calculations
    
    static func computePlayerEfficiency(attacks: Int, kills: Int, errors: Int) -> Double {
        guard attacks > 0 else { return 0 }
        return Double(kills - errors) / Double(attacks)
    }
    
    static func computeHittingPercentage(kills: Int, errors: Int, attempts: Int) -> Double {
        guard attempts > 0 else { return 0 }
        return Double(kills - errors) / Double(attempts)
    }
    
    static func computePassingRating(threePasses: Int, twoPasses: Int, onePasses: Int, errors: Int) -> Double {
        let total = threePasses + twoPasses + onePasses + errors
        guard total > 0 else { return 0 }
        return Double(threePasses * 3 + twoPasses * 2 + onePasses * 1) / Double(total)
    }
    
    static func computeServeRating(aces: Int, errors: Int, attempts: Int, points: Int = 0) -> Double {
        guard attempts > 0 else { return 0 }
        return Double(aces - errors + points) / Double(attempts)
    }
    
    // MARK: - Aggregation
    
    static func aggregatePlayerStats(_ stats: [PlayerMatchStats]) -> AggregatedPlayerStats {
        var agg = AggregatedPlayerStats()
        for s in stats {
            agg.kills += s.kills
            agg.attackAttempts += s.attackAttempts
            agg.attackErrors += s.attackErrors
            agg.aces += s.aces
            agg.serveAttempts += s.serveAttempts
            agg.serveErrors += s.serveErrors
            agg.soloBlocks += s.soloBlocks
            agg.blockAssists += s.blockAssists
            agg.blockErrors += s.blockErrors
            agg.digs += s.digs
            agg.digErrors += s.digErrors
            agg.assists += s.assists
            agg.settingErrors += s.settingErrors
            agg.passes += s.passes
            agg.passErrors += s.passErrors
            agg.perfectPasses += s.perfectPasses
            agg.pointsScored += s.pointsScored
            agg.serviceReceptions += s.serviceReceptions
            agg.receptionErrors += s.receptionErrors
        }
        return agg
    }
    
    static func aggregateTeamStats(matches: [MatchModel], teamName: String) -> TeamStatsSummary {
        var summary = TeamStatsSummary(teamName: teamName)
        for match in matches {
            if match.winner == "home" && match.homeTeamName == teamName {
                summary.wins += 1
            } else if match.winner == "away" && match.awayTeamName == teamName {
                summary.wins += 1
            } else if match.isCompleted && !match.winner.isEmpty {
                summary.losses += 1
            }
            
            summary.setsWon += match.homeSetsWon
            summary.setsLost += match.awaySetsWon
            
            for set in (match.sets ?? []) {
                summary.totalPointsScored += set.homeScore
                summary.totalPointsAllowed += set.awayScore
            }
        }
        return summary
    }
    
    // MARK: - Advanced Analytics
    
    static func computeClutchPerformance(stats: [PlayerMatchStats], clutchThreshold: Int = 20) -> Double {
        // Analyze performance in high-pressure situations (set point, match point, etc.)
        // Simplified: looking at overall efficiency weighted by point contribution
        let filteredStats = stats.filter { $0.pointsScored >= clutchThreshold }
        guard !filteredStats.isEmpty else { return 0 }
        
        let totalEff = filteredStats.reduce(0.0) { $0 + $1.attackEfficiency }
        return totalEff / Double(filteredStats.count)
    }
    
    static func generatePlayerReportCard(name: String, stats: AggregatedPlayerStats,
                                          position: PlayerPosition) -> PlayerReportCard {
        var grades: [String: String] = [:]
        var commentary: [String] = []
        
        // Attack
        let hitPct = stats.hittingPercentage
        switch hitPct {
        case ..<0.1: grades["Attack"] = "C"; commentary.append("Attack efficiency needs work.")
        case 0.1..<0.25: grades["Attack"] = "B"; commentary.append("Solid attacking, room for improvement.")
        case 0.25..<0.35: grades["Attack"] = "A-"; commentary.append("Strong attacking performance.")
        default: grades["Attack"] = "A"; commentary.append("Elite-level attacking efficiency!")
        }
        
        // Serve
        let serveEff = stats.serveEfficiency
        switch serveEff {
        case ..<0: grades["Serve"] = "C"; commentary.append("Reduce service errors.")
        case 0..<0.1: grades["Serve"] = "B"; commentary.append("Consistent serving.")
        default: grades["Serve"] = "A"; commentary.append("Aggressive and effective serving!")
        }
        
        // Defense (digs)
        if stats.digs > 50 { grades["Defense"] = "A"; commentary.append("Outstanding defensive coverage.") }
        else if stats.digs > 25 { grades["Defense"] = "B"; commentary.append("Good defensive positioning.") }
        else if stats.digs > 10 { grades["Defense"] = "C"; commentary.append("Continue working on defensive reads.") }
        
        // Passing
        let passRating = stats.passingRating
        switch passRating {
        case ..<1.5: grades["Passing"] = "C"
        case 1.5..<2.2: grades["Passing"] = "B"
        default: grades["Passing"] = "A"
        }
        
        // Blocking
        let totalBlocks = stats.soloBlocks + stats.blockAssists
        if position == .middleBlocker || position == .opposite {
            if totalBlocks > 30 { grades["Blocking"] = "A" }
            else if totalBlocks > 15 { grades["Blocking"] = "B" }
            else { grades["Blocking"] = "C"; commentary.append("Focus on block timing and positioning.") }
        }
        
        var overallGrade = "B"
        let gradeValues: [String: Double] = ["A": 4.0, "A-": 3.7, "B": 3.0, "C": 2.0]
        let total = grades.values.reduce(0.0) { $0 + (gradeValues[$1] ?? 0) }
        let avg = grades.isEmpty ? 3.0 : total / Double(grades.count)
        if avg >= 3.5 { overallGrade = "A" }
        else if avg >= 3.0 { overallGrade = "B" }
        else { overallGrade = "C" }
        
        return PlayerReportCard(
            playerName: name,
            position: position.rawValue,
            overallGrade: overallGrade,
            categoryGrades: grades,
            commentary: commentary,
            stats: stats
        )
    }
    
    // MARK: - Live Player Score
    
    static func computeLivePlayerScore(stats: LivePlayerStats) -> Double {
        var score = 0.0
        score += Double(stats.kills) * 2.0
        score += Double(stats.aces) * 2.0
        score += Double(stats.soloBlocks) * 2.5
        score += Double(stats.blockAssists) * 1.0
        score += Double(stats.digs) * 1.0
        score += Double(stats.assists) * 0.5
        score -= Double(stats.attackErrors) * 1.5
        score -= Double(stats.serveErrors) * 1.5
        score -= Double(stats.receptionErrors) * 1.0
        return max(0, score)
    }
}

// MARK: - Supporting Types

struct AggregatedPlayerStats {
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
    var digErrors: Int = 0
    var assists: Int = 0
    var settingErrors: Int = 0
    var passes: Int = 0
    var passErrors: Int = 0
    var perfectPasses: Int = 0
    var pointsScored: Int = 0
    var serviceReceptions: Int = 0
    var receptionErrors: Int = 0
    
    var hittingPercentage: Double {
        guard attackAttempts > 0 else { return 0 }
        return Double(kills - attackErrors) / Double(attackAttempts)
    }
    
    var serveEfficiency: Double {
        guard serveAttempts > 0 else { return 0 }
        return Double(aces - serveErrors) / Double(serveAttempts)
    }
    
    var passingRating: Double {
        guard passes > 0 else { return 0 }
        return Double(perfectPasses * 3 + max(0, passes - perfectPasses - passErrors) * 2) / Double(passes)
    }
    
    var totalBlocks: Int { soloBlocks + blockAssists }
    
    var totalPoints: Int { kills + aces + soloBlocks }
}

struct TeamStatsSummary {
    var teamName: String
    var wins: Int = 0
    var losses: Int = 0
    var setsWon: Int = 0
    var setsLost: Int = 0
    var totalPointsScored: Int = 0
    var totalPointsAllowed: Int = 0
    
    var winPercentage: Double {
        guard wins + losses > 0 else { return 0 }
        return Double(wins) / Double(wins + losses)
    }
    
    var pointDifferential: Int { totalPointsScored - totalPointsAllowed }
    
    var recordString: String { "\(wins)-\(losses)" }
}

struct PlayerReportCard {
    let playerName: String
    let position: String
    let overallGrade: String
    let categoryGrades: [String: String]
    let commentary: [String]
    let stats: AggregatedPlayerStats
    
    var formattedGrades: String {
        categoryGrades.map { "\($0.key): \($0.value)" }.joined(separator: " | ")
    }
}