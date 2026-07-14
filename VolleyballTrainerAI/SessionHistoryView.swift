import SwiftUI
import AVFoundation

// MARK: - Session History View
struct SessionHistoryView: View {
    @State private var sessions: [CompletedSession] = []
    @State private var selectedWeek: WeekSummary?
    @State private var showDeleteAllAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image("background").resizable().scaledToFill().ignoresSafeArea().opacity(0.3)
                
                VStack(spacing: 12) {
                    // Back button
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left"); Text("Back")
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.pink)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.4))
                                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.pink.opacity(0.5), lineWidth: 1)))
                        }.buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.top, 50)
                    .padding(.horizontal, 24)
                    
                    // Header
                    Text("Session History")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    if sessions.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No completed sessions yet.")
                                .foregroundColor(.gray)
                                .font(.headline)
                            Text("Complete a training or practice session to see it here.")
                                .foregroundColor(.gray.opacity(0.7))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Overall Stats Card
                                overallStatsCard
                                
                                // Weekly Summaries
                                let summaries = SessionHistoryManager.weeklySummaries(from: sessions)
                                ForEach(summaries) { summary in
                                    WeekSummaryCard(summary: summary)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { sessions = SessionHistoryManager.loadSessions() }
            .alert("Delete All History?", isPresented: $showDeleteAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    SessionHistoryManager.deleteAll()
                    sessions = []
                }
            } message: {
                Text("This will permanently remove all \(sessions.count) completed sessions.")
            }
        }
    }
    
    private var overallStatsCard: some View {
        VStack(spacing: 12) {
            Text("Overall Progress")
                .font(.headline)
                .foregroundColor(.pink)
            
            HStack(spacing: 20) {
                statItem(value: "\(sessions.count)", label: "Sessions", color: .cyan)
                statItem(value: "\(sessions.filter { $0.type == .practice }.count)", label: "Practices", color: .purple)
                statItem(value: "\(sessions.filter { $0.type == .training }.count)", label: "Trainings", color: .orange)
                statItem(value: "\(totalMinutes)", label: "Minutes", color: .green)
            }
            
            if !sessions.isEmpty {
                Button(role: .destructive) {
                    showDeleteAllAlert = true
                } label: {
                    Text("Delete All History")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.5))
        .cornerRadius(16)
    }
    
    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.totalMinutes }
    }
    
    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Week Summary Card
struct WeekSummaryCard: View {
    let summary: WeekSummary
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Week Header
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.weekLabel)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(summary.totalSessions) sessions • \(summary.totalMinutes) min • \(summary.uniqueDays) day\(summary.uniqueDays != 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.pink)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                // Category breakdown
                if !summary.categories.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Categories Worked")
                            .font(.caption.bold())
                            .foregroundColor(.pink)
                        
                        let sortedCats = summary.categories.sorted { $0.value > $1.value }
                        ForEach(sortedCats, id: \.key) { cat, count in
                            HStack {
                                Text(cat)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(count)x")
                                    .font(.caption.bold())
                                    .foregroundColor(.cyan)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Session list
                VStack(spacing: 8) {
                    ForEach(summary.sessions) { session in
                        HStack(spacing: 10) {
                            // Type icon
                            Image(systemName: session.type == .training ? "dumbbell.fill" : "figure.run")
                                .font(.caption)
                                .foregroundColor(session.type == .training ? .orange : .purple)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Text("\(session.totalMinutes) min • \(session.focus.capitalized)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text(session.completedDate, style: .date)
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .cornerRadius(16)
    }
}

// MARK: - Alarm Sound Helper
struct AlarmHelper {
    static func playAlarm() {
        // Play a more noticeable alarm sound
        AudioServicesPlaySystemSound(1005) // Sound ID for a louder alert
        // Also vibrate
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}