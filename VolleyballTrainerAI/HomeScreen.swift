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
                        .scaledToFill()
                        .ignoresSafeArea()

                    VStack(spacing: 0) {

                        // TOP ROW LOCKED
                        Spacer()
                            .frame(height: geo.size.height * 0.30)

                        HStack(spacing: 8) {
                            GlowButton(imageName: "playhub") { }
                            GlowButton(imageName: "practicehub") { }
                        }

                        // THIS WILL NOW WORK
                        Spacer()
                            .frame(height: geo.size.height * 0.02)

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
                    // ⭐ THIS IS THE FIX ⭐
                    .frame(maxHeight: .infinity, alignment: .top)
                    // ---------------------
                    .padding(.horizontal, 12)
                }

                // Navigation
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

