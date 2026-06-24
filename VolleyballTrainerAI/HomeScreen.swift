import SwiftUI

struct HomeScreen: View {
    @State private var navigateTo: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
                    .clipped()

                VStack {
                    Spacer()
                        .frame(height: UIScreen.main.bounds.height * 0.72)

                    VStack(spacing: 6) {
                        // ROW 1 — Play Hub + Practice Hub (placeholders, no action)
                        HStack(spacing: 6) {
                            GlowButton(imageName: "playhub") {
                                // No action - placeholder
                            }
                            GlowButton(imageName: "practicehub") {
                                // No action - placeholder
                            }
                        }

                        // ROW 2 — Training Hub + Performance Hub (working navigation)
                        HStack(spacing: 6) {
                            GlowButton(imageName: "traininghub") {
                                navigateTo = "TrainingHub"
                            }
                            GlowButton(imageName: "performancehub") {
                                navigateTo = "PerformanceHub"
                            }
                        }
                    }
                    .padding(.horizontal, 12)

                    Spacer()
                        .frame(height: UIScreen.main.bounds.height * 0.05)
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