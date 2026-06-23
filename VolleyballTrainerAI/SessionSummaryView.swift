import SwiftUI
import SwiftData
import Charts

struct SessionSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var allHits: [VolleyballHit]
    @State private var selectedHitReplay: [VolleyballHit]? = nil
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
                    charts(for: allHits)
                        .padding(.vertical, 8)
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
                                            replaySingle(hit)
                                        }) {
                                            Image(systemName: "play.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.green)
                                        }
                                        Button(action: {
                                            delete(hit)
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .listRowBackground(Color(red: 0.14, green: 0.14, blue: 0.16))
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
        .fullScreenCover(item: Binding(
            get: { selectedHitReplay != nil ? IdentifiableHitSession(hits: selectedHitReplay!) : nil },
            set: { selectedHitReplay = $0?.hits }
        )) { sessionWrapper in
            ReplaySummaryView(sessionHits: sessionWrapper.hits)
        }
        .alert("Delete all saved hits?", isPresented: $showDeleteAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                deleteAll()
            }
        } message: {
            Text("This will permanently remove all \(allHits.count) saved hits.")
        }
    }

    private func replaySingle(_ hit: VolleyballHit) {
        selectedHitReplay = [hit]
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

private struct SessionCharts: View {
    let hits: [VolleyballHit]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 24) {
                lineChart(title: "Overall Score Trend", values: hits.enumerated().map { ($0, $1.overallScore) }, color: .yellow)
                lineChart(title: "Ball Speed (mph)", values: hits.enumerated().map { ($0, $1.ballSpeedMPH) }, color: .orange)
                lineChart(title: "Jump Height (in)", values: hits.enumerated().map { ($0, $1.jumpHeightInches) }, color: .green)
                lineChart(title: "Arm Angle (°)", values: hits.enumerated().map { ($0, $1.armAngleDegrees) }, color: .blue)
                barChart(title: "Launch Angle (°)", values: hits.enumerated().map { ($0, $1.ballAngleDegrees) }, color: .cyan)
                barChart(title: "Distance (ft)", values: hits.enumerated().map { ($0, $1.ballDistanceFeet) }, color: .purple)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 220)
    }

    @ViewBuilder
    private func lineChart(title: String, values: [(Int, Double)], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundColor(.gray)
            if values.isEmpty {
                Spacer()
                Text("No data").font(.caption2).foregroundColor(.gray)
                Spacer()
            } else {
                Chart {
                    ForEach(values, id: \.0) { index, value in
                        LineMark(x: .value("Hit #", index + 1), y: .value("Value", value))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(color)
                        PointMark(x: .value("Hit #", index + 1), y: .value("Value", value))
                            .foregroundStyle(color)
                    }
                    if let avg = average(values.map(\.1)) {
                        RuleMark(y: .value("Avg", avg))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 140)
                .background(Color(red: 0.14, green: 0.14, blue: 0.16))
                .cornerRadius(8)
            }
        }
        .frame(width: 220)
    }

    @ViewBuilder
    private func barChart(title: String, values: [(Int, Double)], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundColor(.gray)
            if values.isEmpty {
                Spacer()
                Text("No data").font(.caption2).foregroundColor(.gray)
                Spacer()
            } else {
                Chart {
                    ForEach(values, id: \.0) { index, value in
                        BarMark(x: .value("Hit #", index + 1), y: .value("Value", value))
                            .foregroundStyle(color)
                    }
                    if let avg = average(values.map(\.1)) {
                        RuleMark(y: .value("Avg", avg))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 140)
                .background(Color(red: 0.14, green: 0.14, blue: 0.16))
                .cornerRadius(8)
            }
        }
        .frame(width: 220)
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

extension SessionSummaryView {
    private func charts(for hits: [VolleyballHit]) -> some View {
        SessionCharts(hits: hits)
    }
}

struct IdentifiableHitSession: Identifiable {
    let id = UUID()
    let hits: [VolleyballHit]
}

