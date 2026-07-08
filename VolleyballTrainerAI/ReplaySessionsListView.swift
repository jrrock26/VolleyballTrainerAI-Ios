import SwiftUI
import SwiftData

struct ReplaySessionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var allHits: [VolleyballHit]
    @State private var selectedSession: IdentifiableSession? = nil
    @State private var showDeleteAlert = false
    @State private var sessionToDelete: IdentifiableSession? = nil

    private var sessions: [(sessionID: UUID, date: Date, hits: [VolleyballHit])] {
        let groups = Dictionary(grouping: allHits) { hit in
            Calendar.current.startOfDay(for: hit.timestamp)
        }
        return groups.map { date, hits in
            let sessionID = hits.first?.sessionID ?? UUID()
            return (sessionID: sessionID, date: date, hits: hits.sorted { $0.timestamp > $1.timestamp })
        }.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Replay Sessions")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Text("\(allHits.count) total hits across \(sessions.count) sessions")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top)

                if sessions.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "video.badge.checkmark")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                        Text("No sessions recorded yet.")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(sessions) { session in
                            Button(action: {
                                selectedSession = IdentifiableSession(id: session.sessionID)
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(formatSessionDate(session.date))
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            Text("\(session.hits.count) hit\(session.hits.count == 1 ? "" : "s")")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        if let avgScore = session.hits.map(\.overallScore).average() {
                                            Text(String(format: "%.0f avg", avgScore))
                                                .font(.caption)
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    if let bestHit = session.hits.max(by: { $0.ballSpeedMPH < $1.ballSpeedMPH }) {
                                        Text("Best: \(String(format: "%.1f mph", bestHit.ballSpeedMPH)) • \(bestHit.hitType)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 8)
                                .listRowBackground(Color(red: 0.14, green: 0.14, blue: 0.16))
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive, action: {
                                    sessionToDelete = IdentifiableSession(id: session.sessionID)
                                    showDeleteAlert = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .fullScreenCover(item: $selectedSession) { sessionWrapper in
            let sessionHits = allHits.filter { $0.sessionID == sessionWrapper.id }
            ReplaySummaryView(sessionHits: sessionHits)
        }
        .alert("Delete this session?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    deleteSession(sessionID: session.id)
                }
            }
        } message: {
            if let session = sessionToDelete, let hits = sessions.first(where: { $0.sessionID == session.id }) {
                Text("This will permanently remove \(hits.hits.count) hit(s) from this session.")
            }
        }
        .navigationTitle("Replay Sessions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteSession(sessionID: UUID) {
        let hitsToDelete = allHits.filter { $0.sessionID == sessionID }
        for hit in hitsToDelete {
            modelContext.delete(hit)
        }
        try? modelContext.save()
    }

    private func formatSessionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

struct IdentifiableSession: Identifiable {
    let id: UUID
}

extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}