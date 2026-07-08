import SwiftUI
import SwiftData

struct LifetimeStatsView: View {
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var allHits: [VolleyballHit]
    @State private var selectedHitReplay: IdentifiableHitSession? = nil

    private var totalHits: Int { allHits.count }
    private var avgBallSpeed: Double {
        guard !allHits.isEmpty else { return 0 }
        return allHits.reduce(0) { $0 + $1.ballSpeedMPH } / Double(allHits.count)
    }
    private var avgJumpHeight: Double {
        guard !allHits.isEmpty else { return 0 }
        return allHits.reduce(0) { $0 + $1.jumpHeightInches } / Double(allHits.count)
    }
    private var avgScore: Double {
        guard !allHits.isEmpty else { return 0 }
        return allHits.reduce(0) { $0 + $1.overallScore } / Double(allHits.count)
    }
    private var avgDistance: Double {
        guard !allHits.isEmpty else { return 0 }
        return allHits.reduce(0) { $0 + $1.ballDistanceFeet } / Double(allHits.count)
    }
    private var avgArmAngle: Double {
        guard !allHits.isEmpty else { return 0 }
        return allHits.reduce(0) { $0 + $1.armAngleDegrees } / Double(allHits.count)
    }
    private var avgLaunchAngle: Double {
        guard !allHits.isEmpty else { return 0 }
        return allHits.reduce(0) { $0 + $1.ballAngleDegrees } / Double(allHits.count)
    }

    private var bestBallSpeed: VolleyballHit? { allHits.max(by: { $0.ballSpeedMPH < $1.ballSpeedMPH }) }
    private var bestJumpHeight: VolleyballHit? { allHits.max(by: { $0.jumpHeightInches < $1.jumpHeightInches }) }
    private var bestScore: VolleyballHit? { allHits.max(by: { $0.overallScore < $1.overallScore }) }
    private var bestDistance: VolleyballHit? { allHits.max(by: { $0.ballDistanceFeet < $1.ballDistanceFeet }) }

    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.3)

            ScrollView {
                VStack(spacing: 16) {
                    // Back button
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
                    
                    // Header
                    VStack(spacing: 6) {
                        Text("Lifetime Performance Overview")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        Text("\(totalHits) total hits recorded")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)

                    if allHits.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "trophy")
                                .font(.system(size: 44))
                                .foregroundColor(.gray)
                            Text("No hits on record yet.")
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                    } else {
                        // Averages section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Averages")
                                .font(.headline)
                                .foregroundColor(.yellow)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                StatBox(title: "Ball Speed", value: String(format: "%.1f mph", avgBallSpeed), color: .orange)
                                StatBox(title: "Jump Height", value: String(format: "%.1f in", avgJumpHeight), color: .green)
                                StatBox(title: "Score", value: String(format: "%.0f pts", avgScore), color: .yellow)
                                StatBox(title: "Distance", value: String(format: "%.1f ft", avgDistance), color: .purple)
                                StatBox(title: "Arm Angle", value: String(format: "%.0f°", avgArmAngle), color: .blue)
                                StatBox(title: "Launch Angle", value: String(format: "%.1f°", avgLaunchAngle), color: .cyan)
                            }
                            .padding(.horizontal)
                        }

                        // Personal Bests section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personal Bests")
                                .font(.headline)
                                .foregroundColor(Color(red: 1.0, green: 0.08, blue: 0.58))
                                .padding(.horizontal)

                            VStack(spacing: 10) {
                                BestRow(label: "Fastest Spike", value: bestBallSpeed.map { String(format: "%.1f mph", $0.ballSpeedMPH) } ?? "—", color: .orange)
                                BestRow(label: "Highest Jump", value: bestJumpHeight.map { String(format: "%.1f in", $0.jumpHeightInches) } ?? "—", color: .green)
                                BestRow(label: "Best Score", value: bestScore.map { String(format: "%.0f pts", $0.overallScore) } ?? "—", color: .yellow)
                                BestRow(label: "Longest Hit", value: bestDistance.map { String(format: "%.1f ft", $0.ballDistanceFeet) } ?? "—", color: .purple)
                            }
                            .padding(.horizontal)
                        }

                        // Recent hits mini-list
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Hits")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            ForEach(allHits.prefix(10)) { hit in
                                Button(action: {
                                    selectedHitReplay = IdentifiableHitSession(id: hit.id, hits: [hit])
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(hit.hitType) • \(String(format: "%.1f mph", hit.ballSpeedMPH))")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            Text(hit.timestamp, style: .date)
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Text(String(format: "%.0f", hit.overallScore))
                                            .font(.headline)
                                            .foregroundColor(.yellow)
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(12)
                                    .background(Color(red: 0.14, green: 0.14, blue: 0.16))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Lifetime Stats")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedHitReplay) { sessionWrapper in
            ReplaySummaryView(sessionHits: sessionWrapper.hits)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(red: 0.14, green: 0.14, blue: 0.16))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct BestRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
        .padding(14)
        .background(Color(red: 0.14, green: 0.14, blue: 0.16))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}