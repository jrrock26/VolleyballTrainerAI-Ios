import SwiftUI
import SwiftData

struct PerformanceHubView: View {
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var allHits: [VolleyballHit]
    @State private var showLiveTracker = false
    @State private var navigateTo: String? = nil

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

                    VStack(spacing: 12) {

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
                                        .fill(Color.black.opacity(0.6))
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.pink.opacity(0.6), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            Spacer()
                        }
                        .padding(.top, geo.size.height * 0.38)

                        CourtPushButton(title: "Record Hit", icon: "record.circle") {
                            showLiveTracker = true
                        }

                        CourtPushButton(title: "Saved Hits", icon: "list.bullet") {
                            navigateTo = "SavedHits"
                        }

                        CourtPushButton(title: "Charts", icon: "chart.line.uptrend.xyaxis") {
                            navigateTo = "Charts"
                        }

                        CourtPushButton(title: "Lifetime Hits", icon: "rosette") {
                            navigateTo = "Lifetime"
                        }

                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showLiveTracker) {
            LiveAIView()
        }
        .onAppear {
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