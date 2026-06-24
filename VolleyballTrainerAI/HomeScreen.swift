import SwiftUI

struct HomeScreen: View {
    @State private var navigateTo: String? = nil

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()

                    Image("background")
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                        .frame(width: geo.size.width, height: geo.size.height)

                    VStack {
                        Spacer()
                            .frame(height: geo.size.height * 0.42)

                        VStack(spacing: 12) {
                            // ROW 1 — Play Hub + Practice Hub (placeholders, no action)
                            HStack(spacing: 12) {
                                GlowButton(imageName: "playhub") {
                                    // No action - placeholder
                                }
                                GlowButton(imageName: "practicehub") {
                                    // No action - placeholder
                                }
                            }

                            // ROW 2 — Training Hub + Performance Hub (working navigation)
                            HStack(spacing: 12) {
                                GlowButton(imageName: "traininghub") {
                                    navigateTo = "TrainingHub"
                                }
                                GlowButton(imageName: "performancehub") {
                                    navigateTo = "PerformanceHub"
                                }
                            }
                        }
                        .padding(.horizontal, 8)

                        Spacer()
                    }
                }
                .navigationDestination(isPresented: Binding(
                    get: { navigateTo == "TrainingHub" },
                    set: { if !$0 { navigateTo = nil } }
                )) {
                    TrainingHubView()
                }
                .navigationDestination(isPresented: Binding(
                    get: { navigateTo == "PerformanceHub" },
                    set: { if !$0 { navigateTo = nil } }
                )) {
                    PerformanceHubView()
                }
            }
        }
    }
}