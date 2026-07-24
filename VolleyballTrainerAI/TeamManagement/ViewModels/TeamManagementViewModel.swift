import SwiftUI
import SwiftData
import Foundation
import Combine

// MARK: - Team Management ViewModel

@MainActor
final class TeamManagementViewModel: ObservableObject {

    // MARK: - Published State

    @Published var teams: [TeamModel] = []
    @Published var selectedTeam: TeamModel?
    @Published var selectedMember: TeamMember?
    @Published var isEditingTeam = false
    @Published var isEditingMember = false
    @Published var isCreatingTeam = false
    @Published var isCreatingMember = false
    @Published var searchText = ""
    @Published var selectedTab: TeamTab = .team
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Sub-view states
    @Published var showLiveScoring = false
    @Published var showCreateMatch = false
    @Published var showCreateEvent = false
    @Published var showCreatePaperwork = false
    @Published var selectedMatch: MatchModel?
    @Published var selectedEvent: CalendarEvent?

    // Live scoring engine
    let scoringEngine = LiveScoringEngine()

    // Sync state
    @Published var isOffline = false
    @Published var lastSync: Date?

    // MARK: - Data Operations

    func fetchTeams(context: ModelContext) {
        let descriptor = FetchDescriptor<TeamModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            teams = try context.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load teams: \(error.localizedDescription)"
        }
    }

    func createTeam(_ team: TeamModel, context: ModelContext) {
        context.insert(team)
        save(context)
        fetchTeams(context: context)
    }

    func updateTeam(_ team: TeamModel, context: ModelContext) {
        save(context)
        fetchTeams(context: context)
    }

    func deleteTeam(_ team: TeamModel, context: ModelContext) {
        context.delete(team)
        save(context)
        if selectedTeam?.id == team.id { selectedTeam = nil }
        fetchTeams(context: context)
    }

    func archiveTeam(_ team: TeamModel, context: ModelContext) {
        team.isArchived = true
        save(context)
        fetchTeams(context: context)
    }

    // MARK: - Member Operations

    func addMember(_ member: TeamMember, to team: TeamModel, context: ModelContext) {
        member.team = team
        context.insert(member)
        save(context)
    }

    func removeMember(_ member: TeamMember, context: ModelContext) {
        member.isArchived = true
        save(context)
    }

    func updateMember(_ member: TeamMember, context: ModelContext) {
        save(context)
    }

    // MARK: - Match Operations

    func createMatch(_ match: MatchModel, for team: TeamModel, context: ModelContext) {
        match.team = team
        context.insert(match)
        save(context)
    }

    func deleteMatch(_ match: MatchModel, context: ModelContext) {
        context.delete(match)
        save(context)
    }

    // MARK: - Event Operations

    func createEvent(_ event: CalendarEvent, for team: TeamModel, context: ModelContext) {
        event.team = team
        context.insert(event)
        save(context)
    }

    // MARK: - Paperwork Operations

    func createPaperwork(_ paperwork: PaperworkRequirement, for team: TeamModel, context: ModelContext) {
        paperwork.team = team
        context.insert(paperwork)
        save(context)
    }

    func verifySubmission(_ submission: PaperworkSubmission, verifiedByName: String, context: ModelContext) {
        submission.status = .verified
        submission.verifiedAt = Date()
        submission.verifiedByName = verifiedByName
        save(context)
    }

    func rejectSubmission(_ submission: PaperworkSubmission, reason: String, context: ModelContext) {
        submission.status = .rejected
        submission.rejectionReason = reason
        save(context)
    }

    // MARK: - Chat Operations

    func createChatRoom(_ room: ChatRoom, for team: TeamModel, context: ModelContext) {
        room.team = team
        context.insert(room)
        save(context)
    }

    func sendMessage(_ message: ChatMessage, to room: ChatRoom, context: ModelContext) {
        message.room = room
        context.insert(message)
        room.lastMessagePreview = message.content
        room.lastMessageTimestamp = Date()
        save(context)
    }

    // MARK: - Attendance

    func markAttendance(member: TeamMember, event: CalendarEvent, isPresent: Bool,
                        isLate: Bool = false, isExcused: Bool = false, context: ModelContext) {
        let record = AttendanceRecord(
            date: event.startDate, eventType: event.eventType,
            isPresent: isPresent, isLate: isLate, isExcused: isExcused, eventID: event.id
        )
        record.member = member
        context.insert(record)
        save(context)
    }

    func recordRSVP(event: CalendarEvent, memberID: UUID, memberName: String,
                    status: RSVPStatus, context: ModelContext) {
        let response = RSVPResponse(memberID: memberID, memberName: memberName, status: status)
        response.event = event
        context.insert(response)
        save(context)
    }

    // MARK: - Live Scoring Persistence

    func saveMatchResults(from engine: LiveScoringEngine, match: MatchModel,
                          homeTeamID: UUID, awayTeamName: String, context: ModelContext) {
        match.homeSetsWon = engine.homeSetsWon
        match.awaySetsWon = engine.awaySetsWon
        match.winner = engine.matchWinner
        match.isCompleted = true
        match.isLive = false

        for setResult in engine.setHistory {
            let set = SetModel(setNumber: setResult.setNumber, homeScore: setResult.homeScore, awayScore: setResult.awayScore)
            set.isCompleted = true
            set.winner = setResult.winner
            set.match = match
            context.insert(set)
        }

        for entry in engine.playByPlayLog {
            let event = PlayEvent(setNumber: entry.setNumber, eventType: entry.eventType,
                                  description: entry.description, scoringTeam: entry.scoringTeam,
                                  playerID: entry.playerID, playerName: entry.playerName,
                                  homeScore: entry.homeScoreAfter, awayScore: entry.awayScoreAfter)
            event.match = match
            context.insert(event)
        }

        for (playerID, stats) in engine.homePlayerStats {
            let playerStats = PlayerMatchStats(matchID: match.id, playerID: playerID)
            playerStats.kills = stats.kills; playerStats.attackAttempts = stats.attackAttempts
            playerStats.attackErrors = stats.attackErrors; playerStats.aces = stats.aces
            playerStats.serveAttempts = stats.serveAttempts; playerStats.serveErrors = stats.serveErrors
            playerStats.soloBlocks = stats.soloBlocks; playerStats.blockAssists = stats.blockAssists
            playerStats.digs = stats.digs; playerStats.assists = stats.assists
            playerStats.pointsScored = stats.pointsScored
            playerStats.match = match
            context.insert(playerStats)
        }

        save(context)
    }

    // MARK: - Helpers

    private func save(_ context: ModelContext) {
        do { try context.save() }
        catch { errorMessage = "Failed to save: \(error.localizedDescription)" }
    }

    func filteredMembers(team: TeamModel) -> [TeamMember] {
        let members = team.activeMembers
        if searchText.isEmpty { return members }
        return members.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            String($0.jerseyNumber).contains(searchText) ||
            $0.position.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Tab Enum

enum TeamTab: String, CaseIterable {
    case team = "Team"
    case roster = "Roster"
    case matches = "Matches"
    case stats = "Stats"
    case schedule = "Schedule"
    case chat = "Chat"
    case paperwork = "Paperwork"

    var iconName: String {
        switch self {
        case .team: return "person.3.fill"
        case .roster: return "list.clipboard"
        case .matches: return "trophy.fill"
        case .stats: return "chart.bar.fill"
        case .schedule: return "calendar"
        case .chat: return "bubble.left.and.bubble.right"
        case .paperwork: return "doc.text"
        }
    }
}

// MARK: - Neon Glass Style Config

struct NeonGlassStyle {
    static let glassBackground = Color.black.opacity(0.55)
    static let glassBorder = Color.pink.opacity(0.5)
    static let neonPink = Color(red: 1.0, green: 0.18, blue: 0.45)
    static let neonBlue = Color(red: 0.04, green: 0.52, blue: 1.0)
    static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.4)
    static let neonOrange = Color(red: 1.0, green: 0.6, blue: 0.0)

    static func neonGradient(startColor: Color = .pink, endColor: Color = .blue) -> LinearGradient {
        LinearGradient(gradient: Gradient(colors: [startColor.opacity(0.9), endColor.opacity(0.7)]),
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func glassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(RoundedRectangle(cornerRadius: 16).fill(glassBackground)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(neonGradient(), lineWidth: 1.5)))
    }
}