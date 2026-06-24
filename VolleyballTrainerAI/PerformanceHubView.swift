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

                    VStack(spacing: 0) {

                        Spacer()
                            .frame(height: geo.size.height * 0.45)

                        HStack(spacing: 8) {
                            CourtButton(imageName: "recordhit", title: "Record Hit") {
                                showLiveTracker = true
                            }

                            CourtButton(imageName: "savedhits", title: "Saved Hits") {
                                navigateTo = "SavedHits"
                            }
                        }

                        Spacer()
                            .frame(height: geo.size.height * 0.02)

                        HStack(spacing: 8) {
                            CourtButton(imageName: "trends", title: "Charts") {
                                navigateTo = "Charts"
                            }
                            CourtButton(imageName: "personalbests", title: "Lifetime Hits") {
                                navigateTo = "Lifetime"
                            }
                        }

                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 12)
                }

                .navigationDestination(isPresented: Binding(
                    get: { navigateTo == "SavedHits" },
                    set: { if !$0 { navigateTo = nil } }
                )) {
                    SavedHitsListView()
                }
                .navigationDestination(isPresented: Binding(
                    get: { navigateTo == "Charts" },
                    set: { if !$0 { navigateTo = nil } }
                )) {
                    ChartsView()
                }
                .navigationDestination(isPresented: Binding(
                    get: { navigateTo == "Lifetime" },
                    set: { if !$0 { navigateTo = nil } }
                )) {
                    LifetimeStatsView()
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