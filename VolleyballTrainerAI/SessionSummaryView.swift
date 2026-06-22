import SwiftUI
import SwiftData

struct SessionSummaryView: View {
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var allHits: [VolleyballHit]
    @State private var selectedSessionHits: [VolleyballHit]? = nil
    
    // Group items dynamically using clean operational calendar dates
    private var groupedSessions: [(date: Date, hits: [VolleyballHit])] {
        let dictionary = Dictionary(grouping: allHits) { hit in
            Calendar.current.startOfDay(for: hit.timestamp)
        }
        return dictionary.map { (date: $0.key, hits: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Saved Analytics Vault")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Text("\(allHits.count) Total Extracted Tracking Rows Verified")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top)
                
                if allHits.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                        Text("No training sessions on record yet.")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(groupedSessions, id: \.date) { session in
                            Section(header: Text(formatSessionDate(session.date)).foregroundColor(.yellow).bold()) {
                                Button(action: {
                                    self.selectedSessionHits = session.hits
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("\(session.hits.first?.hitType ?? "Volleyball") Training Session")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("\(session.hits.count) Automated Hits Evaluated • Avg Score: \(String(format: "%.0f Pts", session.hits.map { $0.overallScore }.reduce(0, +) / Double(session.hits.count)))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .listRowBackground(Color(red: 0.14, green: 0.14, blue: 0.16))
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedSessionHits != nil ? IdentifiableSession(hits: selectedSessionHits!) : nil },
            set: { selectedSessionHits = $0?.hits }
        )) { sessionWrapper in
            ReplaySummaryView(sessionHits: sessionWrapper.hits)
        }
    }
    
    private func formatSessionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct IdentifiableSession: Identifiable {
    let id = UUID()
    let hits: [VolleyballHit]
}

