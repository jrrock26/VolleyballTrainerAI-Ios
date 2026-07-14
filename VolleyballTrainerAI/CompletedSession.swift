import Foundation

// MARK: - Completed Session Data Model
struct CompletedBlock: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String
    let durationMinutes: Int
    let completedAt: Date
}

enum SessionType: String, Codable {
    case training
    case practice
}

struct CompletedSession: Codable, Identifiable {
    let id: UUID
    let type: SessionType
    let name: String
    let focus: String
    let completedDate: Date
    let totalMinutes: Int
    let blocks: [CompletedBlock]
    let categories: [String]
    
    var weekIdentifier: String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: completedDate)
        let year = calendar.component(.yearForWeekOfYear, from: completedDate)
        return "\(year)-W\(String(format: "%02d", weekOfYear))"
    }
    
    var dayIdentifier: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: completedDate)
    }
}

// MARK: - Persistence Manager
struct SessionHistoryManager {
    private static let storageKey = "completedSessions"
    
    static func loadSessions() -> [CompletedSession] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([CompletedSession].self, from: data)) ?? []
    }
    
    static func saveSession(_ session: CompletedSession) {
        var sessions = loadSessions()
        sessions.append(session)
        persistSessions(sessions)
    }
    
    static func deleteSession(_ session: CompletedSession) {
        var sessions = loadSessions()
        sessions.removeAll { $0.id == session.id }
        persistSessions(sessions)
    }
    
    static func deleteAll() {
        persistSessions([])
    }
    
    private static func persistSessions(_ sessions: [CompletedSession]) {
        let data = (try? JSONEncoder().encode(sessions)) ?? Data()
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    // MARK: - Weekly Summary Helpers
    static func weeklySummaries(from sessions: [CompletedSession]) -> [WeekSummary] {
        let grouped = Dictionary(grouping: sessions) { $0.weekIdentifier }
        return grouped.map { (weekId, weekSessions) in
            let totalMinutes = weekSessions.reduce(0) { $0 + $1.totalMinutes }
            var allCategories: [String: Int] = [:]
            for session in weekSessions {
                for cat in session.categories {
                    allCategories[cat, default: 0] += 1
                }
            }
            let totalPractices = weekSessions.filter { $0.type == .practice }.count
            let totalTrainings = weekSessions.filter { $0.type == .training }.count
            let days = Set(weekSessions.map { $0.dayIdentifier }).count
            
            return WeekSummary(
                weekIdentifier: weekId,
                totalSessions: weekSessions.count,
                totalMinutes: totalMinutes,
                totalPractices: totalPractices,
                totalTrainings: totalTrainings,
                uniqueDays: days,
                categories: allCategories,
                sessions: weekSessions.sorted { $0.completedDate > $1.completedDate }
            )
        }
        .sorted { $0.weekIdentifier > $1.weekIdentifier }
    }
    
    static func allCategories(from sessions: [CompletedSession]) -> [String] {
        Array(Set(sessions.flatMap { $0.categories })).sorted()
    }
}

struct WeekSummary: Identifiable {
    let id: String { weekIdentifier }
    let weekIdentifier: String
    let totalSessions: Int
    let totalMinutes: Int
    let totalPractices: Int
    let totalTrainings: Int
    let uniqueDays: Int
    let categories: [String: Int]
    let sessions: [CompletedSession]
    
    var weekLabel: String {
        // Parse week identifier "2026-W14" to a readable date range
        let parts = weekIdentifier.split(separator: "-")
        guard parts.count == 2 else { return weekIdentifier }
        let yearPart = String(parts[0])
        let weekPart = parts[1].replacingOccurrences(of: "W", with: "")
        guard let year = Int(yearPart), let week = Int(weekPart) else { return weekIdentifier }
        
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let components = DateComponents(weekOfYear: week, yearForWeekOfYear: year)
        guard let startOfWeek = calendar.date(from: components) else { return weekIdentifier }
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else { return weekIdentifier }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startStr = formatter.string(from: startOfWeek)
        let endStr = formatter.string(from: endOfWeek)
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        let yearStr = yearFormatter.string(from: startOfWeek)
        
        return "\(startStr) – \(endStr), \(yearStr)"
    }
}