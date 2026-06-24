import SwiftUI
import SwiftData

struct PerformanceHubView: View {
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var allHits: [VolleyballHit]
    @State private var showLiveTracker = false

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Image("performancehub")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)

                Text("Performance Hub")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                VStack(spacing: 14) {
                    NavigationLink(destination: LiveAIView()) {
                        PerformanceButtonContent(
                            icon: "recordhit",
                            title: "Record Live Hit",
                            subtitle: "Capture a new hit with live tracking"
                        )
                    }

                    NavigationLink(destination: SavedHitsListView()) {
                        PerformanceButtonContent(
                            icon: "savedhits",
                            title: "Saved Hits",
                            subtitle: "\(allHits.count) hits on record"
                        )
                    }

                    NavigationLink(destination: ChartsView()) {
                        PerformanceButtonContent(
                            icon: "trends",
                            title: "Charts",
                            subtitle: "Visualize your performance trends"
                        )
                    }

                    NavigationLink(destination: LifetimeStatsView()) {
                        PerformanceButtonContent(
                            icon: "personalbests",
                            title: "Lifetime Hits",
                            subtitle: "Stats overview of every hit"
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .navigationTitle("Performance Hub")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showLiveTracker) {
            LiveAIView()
        }
        .onAppear {
            // Listen for navigation to RecordHit from notification
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NavigateToPerformanceAction"),
                object: nil,
                queue: .main
            ) { notification in
                if let action = notification.object as? String {
                    if action == "RecordHit" {
                        showLiveTracker = true
                    }
                }
            }
        }
    }
}

struct PerformanceButtonContent: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color(red: 0.14, green: 0.14, blue: 0.16))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}