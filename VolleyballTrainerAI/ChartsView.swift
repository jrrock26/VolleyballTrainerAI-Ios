import SwiftUI
import SwiftData
import Charts

struct ChartsView: View {
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var allHits: [VolleyballHit]
    
    @State private var selectedHitType: String = "All"

    private var filteredHits: [VolleyballHit] {
        if selectedHitType == "All" {
            return Array(allHits.reversed())
        }
        return allHits.reversed().filter { $0.hitType == selectedHitType }
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09)
                .ignoresSafeArea()

            if allHits.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 44))
                        .foregroundColor(.gray)
                    Text("No data to chart yet.")
                        .foregroundColor(.gray)
                    Text("Record some hits to see your trends.")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
            } else {
                VStack(spacing: 0) {
                    // Filter picker
                    Picker("Hit Type", selection: $selectedHitType) {
                        Text("All").tag("All")
                        Text("Spike").tag("Spike")
                        Text("Serve").tag("Serve")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if filteredHits.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "chart.line.downtrend.xyaxis")
                                .font(.system(size: 44))
                                .foregroundColor(.gray)
                            Text("No \(selectedHitType == "All" ? "" : selectedHitType) data to chart.")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                Text("Performance Charts")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                ChartCard(
                                    title: "Overall Score Trend",
                                    value: { index, hit in hit.overallScore },
                                    color: .yellow,
                                    hits: filteredHits,
                                    showAvg: true,
                                    format: { String(format: "%.0f pts", $0) }
                                )

                                ChartCard(
                                    title: "Ball Speed (mph)",
                                    value: { _, hit in hit.ballSpeedMPH },
                                    color: .orange,
                                    hits: filteredHits,
                                    showAvg: true,
                                    format: { String(format: "%.1f mph", $0) }
                                )

                                // Only show Jump Height for Spike (serves don't have meaningful jump)
                                if selectedHitType == "All" || selectedHitType == "Spike" {
                                    ChartCard(
                                        title: "Jump Height (in)",
                                        value: { _, hit in hit.jumpHeightInches },
                                        color: .green,
                                        hits: filteredHits,
                                        showAvg: true,
                                        format: { String(format: "%.1f in", $0) }
                                    )
                                }

                                ChartCard(
                                    title: "Distance (ft)",
                                    value: { _, hit in hit.ballDistanceFeet },
                                    color: .purple,
                                    hits: filteredHits,
                                    showAvg: true,
                                    format: { String(format: "%.1f ft", $0) }
                                )

                                ChartCard(
                                    title: "Arm Angle (°)",
                                    value: { _, hit in hit.armAngleDegrees },
                                    color: .blue,
                                    hits: filteredHits,
                                    showAvg: true,
                                    format: { String(format: "%.0f°", $0) }
                                )

                                ChartCard(
                                    title: "Launch Angle (°)",
                                    value: { _, hit in hit.ballAngleDegrees },
                                    color: .cyan,
                                    hits: filteredHits,
                                    useBar: true,
                                    showAvg: true,
                                    format: { String(format: "%.1f°", $0) }
                                )
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
        }
        .navigationTitle("Charts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}

// MARK: - Chart Card Component

struct ChartCard: View {
    let title: String
    let value: (Int, VolleyballHit) -> Double
    let color: Color
    let hits: [VolleyballHit]
    var useBar: Bool = false
    var showAvg: Bool = false
    var format: (Double) -> String = { String(format: "%.1f", $0) }

    private var values: [(Int, Double)] {
        hits.enumerated().map { ($0.offset, $0.element) }.map { ($0.0, value($0.0, $0.1)) }
    }

    private var avgValue: Double? {
        let vals = values.map(\.1)
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if let avg = avgValue {
                    Text("Avg: \(format(avg))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            if values.isEmpty {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(height: 180)
            } else {
                Chart {
                    ForEach(values, id: \.0) { index, val in
                        if useBar {
                            BarMark(
                                x: .value("Hit #", index + 1),
                                y: .value("Value", val)
                            )
                            .foregroundStyle(color)
                        } else {
                            LineMark(
                                x: .value("Hit #", index + 1),
                                y: .value("Value", val)
                            )
                            .interpolationMethod(.monotone)
                            .foregroundStyle(color)

                            PointMark(
                                x: .value("Hit #", index + 1),
                                y: .value("Value", val)
                            )
                            .foregroundStyle(color)
                        }
                    }

                    if let avg = avgValue, showAvg {
                        RuleMark(y: .value("Avg", avg))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(red: 0.14, green: 0.14, blue: 0.16))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}