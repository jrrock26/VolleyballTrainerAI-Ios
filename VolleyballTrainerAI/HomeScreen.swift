import SwiftUI

struct HomeScreen: View {
    @State private var navigateTo: String? = nil

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .padding(.top)
                        .padding(.bottom, 12)
                        .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: geo.size.height * 0.40)

                        // ROW 1 — Play Hub + Practice Hub (placeholders, no action)
                        HStack(spacing: 8) {
                            GlowButton(imageName: "playhub") {
                                // No action - placeholder
                            }
                            GlowButton(imageName: "practicehub") {
                                // No action - placeholder
                            }
                        }
                        .padding(.bottom, 8)

                        // ROW 2 — Training Hub + Performance Hub (working navigation)
                        HStack(spacing: 8) {
                            GlowButton(imageName: "traininghub") {
                                navigateTo = "TrainingHub"
                            }
                            GlowButton(imageName: "performancehub") {
                                navigateTo = "PerformanceHub"
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 12)
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