import SwiftUI
import SwiftData
import Foundation

// MARK: - Paperwork Requirement

@Model
final class PaperworkRequirement {
    var id: UUID
    var title: String
    var typeRaw: String
    var descriptionText: String
    var isRequired: Bool
    var dueDate: Date?
    var season: String
    var isActive: Bool
    var createdAt: Date
    var createdByID: UUID?
    var attachmentURL: String  // Template file if any
    var autoReminderEnabled: Bool
    var reminderDaysBefore: Int
    var requiresCoachVerification: Bool
    
    var team: TeamModel?
    
    @Relationship(deleteRule: .cascade) var submissions: [PaperworkSubmission]? = []
    
    var type: PaperworkType {
        get { PaperworkType(rawValue: typeRaw) ?? .custom }
        set { typeRaw = newValue.rawValue }
    }
    
    init(title: String, type: PaperworkType = .custom, descriptionText: String = "",
         isRequired: Bool = true, dueDate: Date? = nil, season: String = "2026",
         requiresCoachVerification: Bool = true, autoReminderEnabled: Bool = true,
         reminderDaysBefore: Int = 3) {
        self.id = UUID()
        self.title = title
        self.typeRaw = type.rawValue
        self.descriptionText = descriptionText
        self.isRequired = isRequired
        self.dueDate = dueDate
        self.season = season
        self.isActive = true
        self.createdAt = Date()
        self.attachmentURL = ""
        self.autoReminderEnabled = autoReminderEnabled
        self.reminderDaysBefore = reminderDaysBefore
        self.requiresCoachVerification = requiresCoachVerification
    }
    
    var completionRate: Double {
        guard let subs = submissions, !subs.isEmpty else { return 0 }
        let completed = subs.filter { $0.status == .verified || $0.status == .submitted }.count
        return Double(completed) / Double(subs.count)
    }
    
    var statusCounts: (submitted: Int, verified: Int, pending: Int, rejected: Int, expired: Int) {
        guard let subs = submissions else { return (0, 0, 0, 0, 0) }
        var submitted = 0, verified = 0, pending = 0, rejected = 0, expired = 0
        for s in subs {
            switch s.status {
            case .submitted: submitted += 1
            case .verified: verified += 1
            case .notSubmitted: pending += 1
            case .rejected: rejected += 1
            case .expired: expired += 1
            }
        }
        return (submitted, verified, pending, rejected, expired)
    }
}

// MARK: - Paperwork Submission

@Model
final class PaperworkSubmission {
    var id: UUID
    var memberID: UUID?
    var memberName: String
    var statusRaw: String
    var submittedAt: Date?
    var verifiedAt: Date?
    var verifiedByID: UUID?
    var verifiedByName: String
    var documentData: Data?
    var documentFileName: String
    var documentFileType: String
    var rejectionReason: String
    var expiryDate: Date?
    var notes: String
    var version: Int
    var isArchived: Bool
    
    var requirement: PaperworkRequirement?
    var member: TeamMember?
    
    var status: PaperworkStatus {
        get { PaperworkStatus(rawValue: statusRaw) ?? .notSubmitted }
        set { statusRaw = newValue.rawValue }
    }
    
    init(memberID: UUID? = nil, memberName: String = "", status: PaperworkStatus = .notSubmitted) {
        self.id = UUID()
        self.memberID = memberID
        self.memberName = memberName
        self.statusRaw = status.rawValue
        self.submittedAt = nil
        self.verifiedAt = nil
        self.verifiedByID = nil
        self.verifiedByName = ""
        self.documentData = nil
        self.documentFileName = ""
        self.documentFileType = ""
        self.rejectionReason = ""
        self.expiryDate = nil
        self.notes = ""
        self.version = 1
        self.isArchived = false
    }
    
    var isOverdue: Bool {
        guard let dueDate = requirement?.dueDate, status == .notSubmitted else { return false }
        return Date() > dueDate
    }
    
    var statusDisplay: String {
        switch status {
        case .notSubmitted: return isOverdue ? "Overdue" : "Pending"
        case .submitted: return "Submitted"
        case .verified: return "Verified"
        case .rejected: return "Rejected"
        case .expired: return "Expired"
        }
    }
    
    var statusColor: Color {
        switch status {
        case .notSubmitted: return isOverdue ? .red : .orange
        case .submitted: return .blue
        case .verified: return .green
        case .rejected: return .red
        case .expired: return .gray
        }
    }
}

// MARK: - Preset Paperwork Templates

struct PaperworkPresets {
    static let waivers: [PaperworkRequirement] = [
        PaperworkRequirement(title: "Liability Waiver", type: .waiver,
                             descriptionText: "Standard liability waiver for participation in team activities.",
                             isRequired: true),
        PaperworkRequirement(title: "Medical Release", type: .medicalRelease,
                             descriptionText: "Authorization for emergency medical treatment.",
                             isRequired: true),
        PaperworkRequirement(title: "Code of Conduct", type: .codeOfConduct,
                             descriptionText: "Team code of conduct and behavioral expectations agreement.",
                             isRequired: true),
        PaperworkRequirement(title: "Travel Consent", type: .travelForm,
                             descriptionText: "Parental consent for team travel to away games and tournaments.",
                             isRequired: true)
    ]
    
    static let medical: [PaperworkRequirement] = [
        PaperworkRequirement(title: "Annual Physical", type: .physical,
                             descriptionText: "Annual physical examination clearance from a licensed physician.",
                             isRequired: true),
        PaperworkRequirement(title: "Concussion Baseline", type: .concussion,
                             descriptionText: "Baseline concussion testing and education form.",
                             isRequired: true),
        PaperworkRequirement(title: "Medical History", type: .medicalRelease,
                             descriptionText: "Complete medical history including allergies, medications, and prior injuries.",
                             isRequired: true)
    ]
    
    static let financial: [PaperworkRequirement] = [
        PaperworkRequirement(title: "Season Dues", type: .dues,
                             descriptionText: "Team dues for the current season covering uniforms, equipment, and facility costs.",
                             isRequired: true),
        PaperworkRequirement(title: "Uniform Agreement", type: .uniform,
                             descriptionText: "Uniform issuance and return agreement with damage/loss policy.",
                             isRequired: true)
    ]
    
    static let allTemplates: [(category: String, items: [PaperworkRequirement])] = [
        ("Waivers & Agreements", waivers),
        ("Medical", medical),
        ("Financial", financial)
    ]
}