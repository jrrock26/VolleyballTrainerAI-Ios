import SwiftUI
import SwiftData

struct PerformanceHubView: View {
    @Query(sort: \VolleyballHit.timestamp, order: .reverse) private var allHits: [VolleyballHit]
    @State private var showLiveTracker = false
    @State private var navigateTo: String? = nil

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()

                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .padding(.top)
                        .padding(.bottom, 12)
                        .padding(.horizontal, 4)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {

                        // TOP ROW
                        Spacer()
                            .frame(height: geo.size.height * 0.45)

                        HStack(spacing: 8) {
                            GlowButton(imageName: "recordhit") {
                                showLiveTracker = true
                            }
                            GlowButton(imageName: "savedhits") {
                                navigateTo = "SavedHits"
                            }
                        }

                        Spacer()
                            .frame(height: geo.size.height * 0.02)

                        HStack(spacing: 8) {
                            GlowButton(imageName: "trends") {
                                navigateTo = "Charts"
                            }
                            GlowButton(imageName: "personalbests") {
                                navigateTo = "Lifetime"
                            }
                        }

                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 12)
                }

                // Navigation
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
        .navigationTitle("Performance Hub")
        .navigationBarTitleDisplayMode(.inline)
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