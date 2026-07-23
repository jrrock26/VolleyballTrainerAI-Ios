import SwiftUI
import SwiftData
import Foundation

// MARK: - Chat Room

@Model
final class ChatRoom {
    var id: UUID
    var name: String
    var roomType: String  // "coaches", "team", "parents", "custom"
    var createdAt: Date
    var isCoachOnlyPosting: Bool
    var lastMessagePreview: String
    var lastMessageTimestamp: Date
    var unreadCount: Int
    
    var team: TeamModel?
    
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage]? = []
    @Relationship(deleteRule: .cascade) var members: [ChatRoomMember]? = []
    
    init(name: String, roomType: String = "team", isCoachOnlyPosting: Bool = false) {
        self.id = UUID()
        self.name = name
        self.roomType = roomType
        self.createdAt = Date()
        self.isCoachOnlyPosting = isCoachOnlyPosting
        self.lastMessagePreview = ""
        self.lastMessageTimestamp = Date()
        self.unreadCount = 0
    }
}

// MARK: - Chat Room Member

@Model
final class ChatRoomMember {
    var id: UUID
    var memberID: UUID
    var memberName: String
    var memberRole: String
    var lastReadTimestamp: Date
    var isMuted: Bool
    var isActive: Bool
    
    var room: ChatRoom?
    
    init(memberID: UUID, memberName: String, memberRole: String = "player") {
        self.id = UUID()
        self.memberID = memberID
        self.memberName = memberName
        self.memberRole = memberRole
        self.lastReadTimestamp = Date()
        self.isMuted = false
        self.isActive = true
    }
}

// MARK: - Chat Message

@Model
final class ChatMessage {
    var id: UUID
    var senderID: UUID
    var senderName: String
    var senderRole: String
    var content: String
    var timestamp: Date
    var isEdited: Bool
    var editedAt: Date?
    var isDeleted: Bool
    var isSystemMessage: Bool  // System notifications like "Coach started a game"
    var mediaType: String  // "text", "image", "video", "file"
    var mediaData: Data?
    var mediaFileName: String
    var parentMessageID: UUID?  // For threaded replies
    
    var room: ChatRoom?
    @Relationship(deleteRule: .cascade) var readReceipts: [MessageReadReceipt]? = []
    @Relationship(deleteRule: .cascade) var reactions: [MessageReaction]? = []
    
    init(senderID: UUID, senderName: String, senderRole: String = "player",
         content: String, mediaType: String = "text", mediaData: Data? = nil,
         mediaFileName: String = "", parentMessageID: UUID? = nil, isSystemMessage: Bool = false) {
        self.id = UUID()
        self.senderID = senderID
        self.senderName = senderName
        self.senderRole = senderRole
        self.content = content
        self.timestamp = Date()
        self.isEdited = false
        self.editedAt = nil
        self.isDeleted = false
        self.isSystemMessage = isSystemMessage
        self.mediaType = mediaType
        self.mediaData = mediaData
        self.mediaFileName = mediaFileName
        self.parentMessageID = parentMessageID
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: timestamp)
    }
    
    var isCoachMessage: Bool {
        senderRole.lowercased().contains("coach")
    }
}

// MARK: - Message Read Receipt

@Model
final class MessageReadReceipt {
    var id: UUID
    var memberID: UUID
    var memberName: String
    var readAt: Date
    
    var message: ChatMessage?
    
    init(memberID: UUID, memberName: String) {
        self.id = UUID()
        self.memberID = memberID
        self.memberName = memberName
        self.readAt = Date()
    }
}

// MARK: - Message Reaction

@Model
final class MessageReaction {
    var id: UUID
    var memberID: UUID
    var memberName: String
    var emoji: String
    var createdAt: Date
    
    var message: ChatMessage?
    
    init(memberID: UUID, memberName: String, emoji: String) {
        self.id = UUID()
        self.memberID = memberID
        self.memberName = memberName
        self.emoji = emoji
        self.createdAt = Date()
    }
}

// MARK: - Notification Template

@Model
final class NotificationTemplate {
    var id: UUID
    var name: String
    var templateType: String  // "practice_reminder", "match_announcement", "travel_update", "emergency", "custom"
    var subject: String
    var bodyTemplate: String
    var createdAt: Date
    var lastUsed: Date?
    
    init(name: String, templateType: String, subject: String, bodyTemplate: String) {
        self.id = UUID()
        self.name = name
        self.templateType = templateType
        self.subject = subject
        self.bodyTemplate = bodyTemplate
        self.createdAt = Date()
    }
    
    func renderBody(teamName: String, eventTitle: String, eventDate: String,
                    location: String, additionalNotes: String) -> String {
        var result = bodyTemplate
        result = result.replacingOccurrences(of: "{teamName}", with: teamName)
        result = result.replacingOccurrences(of: "{eventTitle}", with: eventTitle)
        result = result.replacingOccurrences(of: "{eventDate}", with: eventDate)
        result = result.replacingOccurrences(of: "{location}", with: location)
        result = result.replacingOccurrences(of: "{notes}", with: additionalNotes)
        return result
    }
}

// MARK: - Sent Notification Log

@Model
final class NotificationLog {
    var id: UUID
    var templateID: UUID?
    var sentAt: Date
    var channel: String  // "in_app", "email", "sms"
    var recipientCount: Int
    var subject: String
    var body: String
    var sentByID: UUID
    var recipientGroup: String  // "all_players", "all_coaches", "all_parents", "custom"
    
    init(templateID: UUID? = nil, channel: String = "in_app", recipientCount: Int = 0,
         subject: String = "", body: String = "", sentByID: UUID = UUID(),
         recipientGroup: String = "all_players") {
        self.id = UUID()
        self.templateID = templateID
        self.sentAt = Date()
        self.channel = channel
        self.recipientCount = recipientCount
        self.subject = subject
        self.body = body
        self.sentByID = sentByID
        self.recipientGroup = recipientGroup
    }
}