import SwiftUI
import SwiftData

struct ContentView: View {
    // Connects to your live SwiftData database to pull real historical data entries
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var storedHits: [VolleyballHit]
    @State private var showCameraSheet = false
    
    var body: some View {
        ZStack {
            // Sleek dark UI background
            Color(red: 0.07, green: 0.07, blue: 0.07)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Main Header Title Blocks
                VStack(spacing: 4) {
                    Text("VolleyballTrainerAI")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("On-Device Computer Vision")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.yellow)
                }
                .padding(.top, 20)
                
                // Analytics High Score Cards based on actual data
                HStack(spacing: 16) {
                    MetricCard(title: "Record Jump Height", value: String(format: "%.1f in", storedHits.map { $0.jumpHeightInches }.max() ?? 0.0), icon: "arrow.up.circle.fill", color: .green)
                    MetricCard(title: "Top Spike Angle", value: String(format: "%.0f°", storedHits.map { $0.armAngleDegrees }.max() ?? 0.0), icon: "figure.volleyball", color: .blue)
                }
                .padding(.horizontal)
                
                // Scrolling History Log List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Verified History Log (\(storedHits.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            if storedHits.isEmpty {
                                Text("No analytics captured yet. Click below to begin.")
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
                
                // Launch Live AI view trigger
                Button(action: {
                    showCameraSheet = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Launch Live Vision Tracker")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.yellow)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
        }
        // This structural modifier forces Apple to trigger your LiveAIView view port modal
        .fullScreenCover(isPresented: $showCameraSheet) {
            LiveAIView()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

// SwiftUI UI Helper Module: Metric Cards
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                Spacer()
            }
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .cornerRadius(14)
    }
}

// SwiftUI UI Helper Module: Dynamic List Row Rendering
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

