import SwiftUI
import SwiftData
import Foundation

// MARK: - Enums

enum PlayLevel: String, Codable, CaseIterable {
    case youth = "Youth"
    case middleSchool = "Middle School"
    case highSchool = "High School"
    case club = "Club"
    case travel = "Travel"
    case college = "College"
    case professional = "Professional"
    
    var iconName: String {
        switch self {
        case .youth: return "figure.child"
        case .middleSchool: return "building.columns"
        case .highSchool: return "flag.checkered"
        case .club: return "star.circle"
        case .travel: return "airplane"
        case .college: return "graduationcap"
        case .professional: return "trophy"
        }
    }
}

enum UserRole: String, Codable, CaseIterable {
    case headCoach = "Head Coach"
    case assistantCoach = "Assistant Coach"
    case trainer = "Trainer"
    case statistician = "Statistician"
    case player = "Player"
    case parent = "Parent"
    case staff = "Staff"
    
    var permissions: [Permission] {
        switch self {
        case .headCoach, .assistantCoach:
            return Permission.allCases
        case .trainer:
            return [.viewRoster, .viewSchedule, .sendMessages, .viewStats]
        case .statistician:
            return [.liveScoring, .viewStats, .viewSchedule]
        case .player:
            return [.viewRoster, .viewSchedule, .viewOwnStats, .teamChat, .viewPaperwork]
        case .parent:
            return [.viewSchedule, .parentBoard, .viewOwnPlayer, .messaging]
        case .staff:
            return [.viewSchedule, .viewRoster]
        }
    }
}

enum Permission: String, Codable, CaseIterable {
    case createTeam = "Create Team"
    case editTeam = "Edit Team"
    case deleteTeam = "Delete Team"
    case inviteMembers = "Invite Members"
    case manageRoles = "Manage Roles"
    case viewRoster = "View Roster"
    case editRoster = "Edit Roster"
    case liveScoring = "Live Scoring"
    case viewStats = "View Stats"
    case editStats = "Edit Stats"
    case viewSchedule = "View Schedule"
    case editSchedule = "Edit Schedule"
    case sendMessages = "Send Messages"
    case teamChat = "Team Chat"
    case parentBoard = "Parent Board"
    case viewPaperwork = "View Paperwork"
    case managePaperwork = "Manage Paperwork"
    case viewOwnStats = "View Own Stats"
    case viewOwnPlayer = "View Own Player"
    case messaging = "Messaging"
}

enum MatchType: String, Codable, CaseIterable {
    case regular = "Regular Season"
    case tournament = "Tournament"
    case scrimmage = "Scrimmage"
    case playoff = "Playoff"
    case championship = "Championship"
}

enum EventType: String, Codable, CaseIterable {
    case practice = "Practice"
    case matchDay = "Match"
    case tournament = "Tournament"
    case openGym = "Open Gym"
    case weightRoom = "Weight Room"
    case teamMeeting = "Team Meeting"
    case travel = "Travel"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .practice: return "figure.volleyball"
        case .matchDay: return "trophy"
        case .tournament: return "flag.2.crossed"
        case .openGym: return "figure.run"
        case .weightRoom: return "dumbbell"
        case .teamMeeting: return "person.3"
        case .travel: return "airplane.departure"
        case .other: return "calendar"
        }
    }
}

enum RSVPStatus: String, Codable {
    case attending = "Attending"
    case maybe = "Maybe"
    case declined = "Declined"
    case pending = "Pending"
}

enum PlayerPosition: String, Codable, CaseIterable {
    case all = "All"
    case setter = "Setter"
    case outsideHitter = "Outside Hitter"
    case middleBlocker = "Middle Blocker"
    case oppositeHitter = "Opposite Hitter"
    case opposite = "Opposite"
    case libero = "Libero"
    case defensiveSpecialist = "Defensive Specialist"
    case servingSpecialist = "Serving Specialist"
    case setterRightSide = "Setter/Right Side"
    case unknown = "Unassigned"
}

enum PaperworkType: String, Codable, CaseIterable {
    case waiver = "Waiver"
    case physical = "Physical"
    case concussion = "Concussion Form"
    case travelForm = "Travel Form"
    case dues = "Dues"
    case uniform = "Uniform Agreement"
    case medicalRelease = "Medical Release"
    case codeOfConduct = "Code of Conduct"
    case custom = "Custom"
}

enum PaperworkStatus: String, Codable {
    case notSubmitted = "Not Submitted"
    case submitted = "Submitted"
    case verified = "Verified"
    case rejected = "Rejected"
    case expired = "Expired"
}

// MARK: - Team Model

@Model
final class TeamModel {
    var id: UUID
    var name: String
    var shortName: String
    var levelRaw: String
    var logoData: Data?
    var season: String
    var seasonStart: Date
    var seasonEnd: Date
    var joinCode: String
    var createdAt: Date
    var isArchived: Bool
    var organizationName: String
    var homeCourt: String
    var primaryColor: String
    var secondaryColor: String
    
    @Relationship(deleteRule: .cascade) var members: [TeamMember]? = []
    @Relationship(deleteRule: .cascade) var seasons: [TeamSeason]? = []
    @Relationship(deleteRule: .cascade) var matches: [MatchModel]? = []
    @Relationship(deleteRule: .cascade) var events: [CalendarEvent]? = []
    @Relationship(deleteRule: .cascade) var paperworks: [PaperworkRequirement]? = []
    @Relationship(deleteRule: .cascade) var chatRooms: [ChatRoom]? = []
    
    var level: PlayLevel {
        get { PlayLevel(rawValue: levelRaw) ?? .club }
        set { levelRaw = newValue.rawValue }
    }
    
    init(name: String, shortName: String = "", level: PlayLevel = .club, season: String = "2026", 
         seasonStart: Date = Date(), seasonEnd: Date = Date().addingTimeInterval(86400 * 180),
         organizationName: String = "", homeCourt: String = "", primaryColor: String = "#FF2D55", 
         secondaryColor: String = "#0A84FF") {
        self.id = UUID()
        self.name = name
        self.shortName = shortName.isEmpty ? String(name.prefix(4)).uppercased() : shortName
        self.levelRaw = level.rawValue
        self.logoData = nil
        self.season = season
        self.seasonStart = seasonStart
        self.seasonEnd = seasonEnd
        self.joinCode = TeamModel.generateJoinCode()
        self.createdAt = Date()
        self.isArchived = false
        self.organizationName = organizationName
        self.homeCourt = homeCourt
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
    
    static func generateJoinCode() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
    
    var activeMembers: [TeamMember] {
        (members ?? []).filter { !$0.isArchived }
    }
    
    var coaches: [TeamMember] {
        activeMembers.filter { $0.role.permissions.contains(.editRoster) }
    }
    
    var players: [TeamMember] {
        activeMembers.filter { $0.role == .player }
    }
    
    var activeSeason: TeamSeason? {
        seasons?.first(where: { $0.isActive })
    }
}

// MARK: - TeamMember Model

@Model
final class TeamMember {
    var id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var roleRaw: String
    var coachRoleRaw: String?
    var photoData: Data?
    var jerseyNumber: Int
    var positionRaw: String
    var rating: Double
    var isActive: Bool
    var isArchived: Bool
    var joinedAt: Date
    var emergencyContact: String
    var emergencyPhone: String
    
    // Player-specific
    var heightFeet: Int
    var heightInches: Int
    var weight: Double
    var medicalNotes: String
    var skillMetricsJSON: String
    var eligibilityNotes: String
    var isEligible: Bool
    
    // Parent link
    var linkedParentIDs: [String]
    
    var team: TeamModel?
    
    @Relationship(deleteRule: .cascade) var attendanceRecords: [AttendanceRecord]? = []
    @Relationship(deleteRule: .cascade) var playerStats: [PlayerMatchStats]? = []
    @Relationship(deleteRule: .cascade) var paperworkSubmissions: [PaperworkSubmission]? = []
    
    var role: UserRole {
        get { UserRole(rawValue: roleRaw) ?? .player }
        set { roleRaw = newValue.rawValue }
    }
    
    var coachRole: UserRole? {
        get { coachRoleRaw.map { UserRole(rawValue: $0) ?? .assistantCoach } }
        set { coachRoleRaw = newValue?.rawValue }
    }
    
    var position: PlayerPosition {
        get { PlayerPosition(rawValue: positionRaw) ?? .unknown }
        set { positionRaw = newValue.rawValue }
    }
    
    var fullName: String { "\(firstName) \(lastName)" }
    
    var displayHeight: String { "\(heightFeet)'\(heightInches)\"" }
    
    init(firstName: String, lastName: String, email: String = "", phone: String = "", 
         role: UserRole = .player, jerseyNumber: Int = 0, position: PlayerPosition = .unknown,
         heightFeet: Int = 0, heightInches: Int = 0, weight: Double = 0) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.roleRaw = role.rawValue
        self.coachRoleRaw = role == .headCoach || role == .assistantCoach ? role.rawValue : nil
        self.jerseyNumber = jerseyNumber
        self.positionRaw = position.rawValue
        self.rating = 0.0
        self.isActive = true
        self.isArchived = false
        self.joinedAt = Date()
        self.emergencyContact = ""
        self.emergencyPhone = ""
        self.heightFeet = heightFeet
        self.heightInches = heightInches
        self.weight = weight
        self.medicalNotes = ""
        self.skillMetricsJSON = "{}"
        self.eligibilityNotes = ""
        self.isEligible = true
        self.linkedParentIDs = []
    }
}

// MARK: - TeamSeason Model

@Model
final class TeamSeason {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var isActive: Bool
    var winCount: Int
    var lossCount: Int
    var setWins: Int
    var setLosses: Int
    var totalPointsScored: Int
    var totalPointsAllowed: Int
    
    var team: TeamModel?
    
    init(name: String = "2026", startDate: Date = Date(), endDate: Date = Date().addingTimeInterval(86400 * 180)) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = true
        self.winCount = 0
        self.lossCount = 0
        self.setWins = 0
        self.setLosses = 0
        self.totalPointsScored = 0
        self.totalPointsAllowed = 0
    }
    
    var recordString: String { "\(winCount)-\(lossCount)" }
    var setRecordString: String { "\(setWins)-\(setLosses)" }
    var pointDifferential: Int { totalPointsScored - totalPointsAllowed }
}