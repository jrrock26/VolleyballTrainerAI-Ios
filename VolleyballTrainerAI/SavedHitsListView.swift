import SwiftUI
import SwiftData

struct SavedHitsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var allHits: [VolleyballHit]
    @State private var showDeleteAllAlert = false

    private var groupedSessions: [(date: Date, hits: [VolleyballHit])] {
        let dictionary = Dictionary(grouping: allHits) { hit in
            Calendar.current.startOfDay(for: hit.timestamp)
        }
        return dictionary.map { (date: $0.key, hits: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.3)

            VStack(spacing: 16) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.pink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.pink.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.top, 16)

                VStack(spacing: 4) {
                    Text("Saved Hits")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Text("\(allHits.count) total hits recorded • Auto-deletes after 40 days")
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
                        Text("No saved hits yet.")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(groupedSessions, id: \.date) { session in
                            Section(header: Text(formatSessionDate(session.date)).foregroundColor(.yellow).bold()) {
                                ForEach(session.hits) { hit in
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(hit.hitType) • \(String(format: "%.0f mph", hit.ballSpeedMPH))")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            Text("Score \(String(format: "%.0f", hit.overallScore)) • \(formattedTime(hit.timestamp))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Button(action: {
                                            delete(hit)
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .background(Color(red: 0.14, green: 0.14, blue: 0.16))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(role: .destructive, action: {
                                showDeleteAllAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Delete All")
                                }
                            }
                        }
                    }
                }
            }
        }
        .alert("Delete all saved hits?", isPresented: $showDeleteAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                deleteAll()
            }
        } message: {
            Text("This will permanently remove all \(allHits.count) saved hits.")
        }
        .navigationBarHidden(true)
        .onAppear {
            purgeOldHits()
        }
    }

    private func delete(_ hit: VolleyballHit) {
        modelContext.delete(hit)
        try? modelContext.save()
    }

    private func deleteAll() {
        for hit in allHits {
            modelContext.delete(hit)
        }
        try? modelContext.save()
    }

    private func purgeOldHits() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -40, to: Date()) ?? Date()
        let oldHits = allHits.filter { $0.timestamp < cutoff }
        for hit in oldHits {
            modelContext.delete(hit)
        }
        if !oldHits.isEmpty {
            try? modelContext.save()
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formatSessionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}
