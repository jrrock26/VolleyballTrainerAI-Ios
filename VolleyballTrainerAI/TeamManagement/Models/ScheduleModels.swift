import SwiftUI
import SwiftData
import Foundation

// MARK: - Calendar Event

@Model
final class CalendarEvent {
    var id: UUID
    var title: String
    var eventTypeRaw: String
    var startDate: Date
    var endDate: Date
    var location: String
    var address: String
    var notes: String
    var isAllDay: Bool
    var isRecurring: Bool
    var recurrenceRule: String  // RFC 5545
    var requiresRSVP: Bool
    var rsvpDeadline: Date?
    var notificationMinutesBefore: Int  // 0 = at event time
    var syncWithAppleCalendar: Bool
    var syncWithGoogleCalendar: Bool
    var appleCalendarEventID: String
    var googleCalendarEventID: String
    var createdByID: UUID?
    var createdAt: Date
    var isCancelled: Bool
    
    var team: TeamModel?
    var match: MatchModel?
    
    @Relationship(deleteRule: .cascade) var rsvpResponses: [RSVPResponse]? = []
    @Relationship(deleteRule: .cascade) var travelDetails: [TravelDetail]? = []
    
    var eventType: EventType {
        get { EventType(rawValue: eventTypeRaw) ?? .other }
        set { eventTypeRaw = newValue.rawValue }
    }
    
    init(title: String, eventType: EventType = .practice, startDate: Date = Date(),
         endDate: Date? = nil, location: String = "", address: String = "", notes: String = "",
         requiresRSVP: Bool = false, notificationMinutesBefore: Int = 30, createdByID: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.eventTypeRaw = eventType.rawValue
        self.startDate = startDate
        self.endDate = endDate ?? startDate.addingTimeInterval(7200)
        self.location = location
        self.address = address
        self.notes = notes
        self.isAllDay = false
        self.isRecurring = false
        self.recurrenceRule = ""
        self.requiresRSVP = requiresRSVP
        self.rsvpDeadline = nil
        self.notificationMinutesBefore = notificationMinutesBefore
        self.syncWithAppleCalendar = true
        self.syncWithGoogleCalendar = false
        self.appleCalendarEventID = ""
        self.googleCalendarEventID = ""
        self.createdByID = createdByID
        self.createdAt = Date()
        self.isCancelled = false
    }
    
    var durationFormatted: String {
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedDateRange: String {
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d"
        let dateStr = df.string(from: startDate)
        df.dateFormat = "h:mm a"
        let startStr = df.string(from: startDate)
        let endStr = df.string(from: endDate)
        return "\(dateStr) • \(startStr) - \(endStr)"
    }
}

// MARK: - RSVP Response

@Model
final class RSVPResponse {
    var id: UUID
    var memberID: UUID?
    var memberName: String
    var statusRaw: String
    var respondedAt: Date
    var note: String
    
    var event: CalendarEvent?
    
    var status: RSVPStatus {
        get { RSVPStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
    
    init(memberID: UUID? = nil, memberName: String = "", status: RSVPStatus = .pending, note: String = "") {
        self.id = UUID()
        self.memberID = memberID
        self.memberName = memberName
        self.statusRaw = status.rawValue
        self.respondedAt = Date()
        self.note = note
    }
}

// MARK: - Travel Detail

@Model
final class TravelDetail {
    var id: UUID
    var type: String  // "flight", "bus", "hotel", "meal", "other"
    var title: String
    var confirmationNumber: String
    var departureDate: Date?
    var arrivalDate: Date?
    var provider: String
    var location: String
    var notes: String
    var cost: Double
    
    var event: CalendarEvent?
    
    init(type: String = "other", title: String = "", confirmationNumber: String = "",
         provider: String = "", location: String = "", notes: String = "", cost: Double = 0) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.confirmationNumber = confirmationNumber
        self.departureDate = nil
        self.arrivalDate = nil
        self.provider = provider
        self.location = location
        self.notes = notes
        self.cost = cost
    }
}

// MARK: - Attendance Record

@Model
final class AttendanceRecord {
    var id: UUID
    var date: Date
    var eventTypeRaw: String
    var isPresent: Bool
    var isLate: Bool
    var minutesLate: Int
    var isExcused: Bool
    var notes: String
    var eventID: UUID?
    
    var member: TeamMember?
    
    var eventType: EventType {
        get { EventType(rawValue: eventTypeRaw) ?? .practice }
        set { eventTypeRaw = newValue.rawValue }
    }
    
    init(date: Date = Date(), eventType: EventType = .practice, isPresent: Bool = true,
         isLate: Bool = false, minutesLate: Int = 0, isExcused: Bool = false, notes: String = "",
         eventID: UUID? = nil) {
        self.id = UUID()
        self.date = date
        self.eventTypeRaw = eventType.rawValue
        self.isPresent = isPresent
        self.isLate = isLate
        self.minutesLate = minutesLate
        self.isExcused = isExcused
        self.notes = notes
        self.eventID = eventID
    }
    
    var statusDisplay: String {
        if isPresent && isLate { return "Late" }
        if isPresent { return "Present" }
        if isExcused { return "Excused" }
        return "Absent"
    }
    
    var statusColor: Color {
        if isPresent && !isLate { return .green }
        if isPresent && isLate { return .orange }
        if isExcused { return .yellow }
        return .red
    }
}