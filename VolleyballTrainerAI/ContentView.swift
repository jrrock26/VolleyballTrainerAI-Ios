import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var storedHits: [VolleyballHit]
    @State private var showCameraSheet = false
    @State private var showAnalytics = false

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("VolleyballTrainerAI")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("On-Device Computer Vision")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.yellow)
                }
                .padding(.top, 20)

                HStack(spacing: 16) {
                    Button(action: { showAnalytics = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.cyan)
                            Text("Analytics")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                        )
                    }

                    Button(action: { showCameraSheet = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.yellow)
                            Text("Live Tracker")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    HStack {
                        Text("Recent Activity (\(storedHits.count))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                    }

                    ScrollView {
                        VStack(spacing: 10) {
                            if storedHits.isEmpty {
                                Text("No analytics captured yet. Tap Live Tracker to begin.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                            } else {
                                ForEach(storedHits) { hit in
                                    HistoryRow(
                                        date: formatDate(hit.timestamp),
                                        metric: String(format: "%.1f MPH %@", hit.ballSpeedMPH, hit.hitType),
                                        status: String(format: "%.1f in", hit.jumpHeightInches),
                                        isSuccess: hit.ballSpeedMPH > 38.0
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showCameraSheet) {
            LiveAIView()
        }
        .sheet(isPresented: $showAnalytics) {
            SessionSummaryView()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

struct HistoryRow: View {
    let date: String
    let metric: String
    let status: String
    let isSuccess: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(metric)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(status)
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSuccess ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .foregroundColor(isSuccess ? .green : .red)
                .cornerRadius(6)
        }
        .padding()
        .background(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.6))
        .cornerRadius(10)
    }
}