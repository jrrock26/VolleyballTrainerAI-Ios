import SwiftUI
import SwiftData

struct PerformanceHubView: View {
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var allHits: [VolleyballHit]

    @State private var showLiveTracker = false
    @State private var showCharts = false
    @State private var showSavedHits = false
    @State private var showLifetimeStats = false
    @State private var showSavedReplays = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()

                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    VStack(spacing: 0) {

                        // --- FIXED TOP-LEFT BACK BUTTON ---
                        HStack {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.system(size: 18, weight: .semibold, design: .rounded))   // ← original font restored
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

                        // --- BUTTONS POSITIONED LIKE HOMESCREEN (SHIFTED DOWN 3/4 BUTTON HEIGHT) ---
                        Spacer()
                            .frame(height: geo.size.height * 0.33 + 60)

                        VStack(spacing: 20) {

                            CourtPushButton(title: "Record Hit", icon: "record.circle") {
                                showLiveTracker = true
                            }
                            .frame(width: geo.size.width * 0.50, height: 60)
                            .font(.custom("Orbitron-Regular", size: 22))
                            .multilineTextAlignment(.center)

                            CourtPushButton(title: "Saved Replays", icon: "video.badge.plus") {
                                showSavedReplays = true
                            }
                            .frame(width: geo.size.width * 0.50, height: 60)
                            .font(.custom("Orbitron-Regular", size: 20))
                            .multilineTextAlignment(.center)

                            CourtPushButton(title: "Saved Hits", icon: "list.bullet") {
                                showSavedHits = true
                            }
                            .frame(width: geo.size.width * 0.50, height: 60)
                            .font(.custom("Orbitron-Regular", size: 22))
                            .multilineTextAlignment(.center)

                            CourtPushButton(title: "Charts", icon: "chart.line.uptrend.xyaxis") {
                                showCharts = true
                            }
                            .frame(width: geo.size.width * 0.50, height: 60)
                            .font(.custom("Orbitron-Regular", size: 22))
                            .multilineTextAlignment(.center)

                            CourtPushButton(title: "Lifetime Hits", icon: "rosette") {
                                showLifetimeStats = true
                            }
                            .frame(width: geo.size.width * 0.50, height: 60)
                            .font(.custom("Orbitron-Regular", size: 22))
                            .multilineTextAlignment(.center)
                        }

                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .navigationBarHidden(true)

        .fullScreenCover(isPresented: $showLiveTracker) { LiveAIView() }
        .navigationDestination(isPresented: $showSavedHits) { SavedHitsListView() }
        .navigationDestination(isPresented: $showCharts) { ChartsView() }
        .navigationDestination(isPresented: $showLifetimeStats) { LifetimeStatsView() }
        .navigationDestination(isPresented: $showSavedReplays) { SavedReplaysListView() }
    }
}

