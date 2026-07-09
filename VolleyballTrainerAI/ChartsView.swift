import SwiftUI
import SwiftData
import Charts

struct ChartsView: View {
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var allHits: [VolleyballHit]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedHitType: String = "All"
    @State private var hasLoaded = false

    private var availableHitTypes: [String] {
        let types = Array(Set(allHits.map(\.hitType))).sorted()
        return types
    }

    private var filteredHits: [VolleyballHit] {
        if selectedHitType == "All" {
            return Array(allHits.reversed())
        }
        return allHits.reversed().filter { $0.hitType == selectedHitType }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.3)

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.pink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.55))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.pink.opacity(0.6), lineWidth: 1)
                                )
                        )
                    }
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.leading, 20)

                // Glowing segmented tabs
                HStack(spacing: 10) {
                    ForEach(["All", "Spike", "Serve"], id: \.self) { type in
                        Button(action: { selectedHitType = type }) {
                            Text(type)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(selectedHitType == type ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedHitType == type ? Color(hex: "#2b6cb0") : Color.black.opacity(0.3))
                                        .shadow(color: selectedHitType == type ? Color(hex: "#2b6cb0") : .clear, radius: 6)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedHitType == type ? Color(hex: "#ff69b4") : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 40)

                if allHits.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                        Text("No data to chart yet.")
                            .foregroundColor(.gray)
                        Text("Record some hits to see your trends.")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("PERFORMANCE CHARTS")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3)
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
                            let jumpHeightHits = selectedHitType == "All" ? filteredHits.filter { $0.hitType == "Spike" } : filteredHits
                            if selectedHitType == "Spike" || (!jumpHeightHits.isEmpty && selectedHitType == "All") {
                                ChartCard(
                                    title: "Jump Height (in)",
                                    value: { _, hit in hit.jumpHeightInches },
                                    color: .green,
                                    hits: jumpHeightHits,
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

                            ChartCard(
                                title: "Contact Height (in)",
                                value: { _, hit in hit.contactHeightInches },
                                color: .pink,
                                hits: filteredHits,
                                showAvg: true,
                                format: { String(format: "%.1f in", $0) }
                            )

                            ChartCard(
                                title: "Hand Speed (mph)",
                                value: { _, hit in hit.handSpeedMPH },
                                color: .red,
                                hits: filteredHits,
                                showAvg: true,
                                format: { String(format: "%.1f mph", $0) }
                            )

                            ChartCard(
                                title: "Hip-Shoulder Sep (°)",
                                value: { _, hit in hit.hipShoulderSeparation },
                                color: .mint,
                                hits: filteredHits,
                                showAvg: true,
                                format: { String(format: "%.0f°", $0) }
                            )
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .navigationBarHidden(true)
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
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if let avg = avgValue {
                    Text("Avg: \(format(avg))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
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
                            .cornerRadius(4)
                        } else {
                            LineMark(
                                x: .value("Hit #", index + 1),
                                y: .value("Value", val)
                            )
                            .interpolationMethod(.monotone)
                            .foregroundStyle(color)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                            .shadow(color: color.opacity(0.6), radius: 4)

                            PointMark(
                                x: .value("Hit #", index + 1),
                                y: .value("Value", val)
                            )
                            .foregroundStyle(color)
                            .symbolSize(40)
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
                .background(Color.black.opacity(0.45))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color.black.opacity(0.55))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
