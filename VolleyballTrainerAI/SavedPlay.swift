import SwiftUI

struct SavedPlay: Identifiable, Codable {
    let id: UUID
    var name: String
    var createdAt: Date
    let positions: [[CGPoint]]  // 5 formations of 6 positions each
    let roles: [String]
    let labels: [String?]
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), positions: [[CGPoint]], roles: [String], labels: [String?]) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.positions = positions
        self.roles = roles
        self.labels = labels
    }
}
