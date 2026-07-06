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

                        Spacer()
                            .frame(height: geo.size.height * 0.45)

                    HStack(spacing: 8) {
                        CourtPushButton(title: "Play Hub", icon: "play.circle") {
                            navigateTo = "PlayHub"
                        }
                        CourtPushButton(title: "Practice Hub", icon: "figure.run") {
                            navigateTo = "PracticeHub"
                        }
                    }

                    HStack(spacing: 8) {
                        CourtPushButton(title: "Player Profile", icon: "person.circle") {
                            navigateTo = "PlayerProfile"
                        }
                    }

                        Spacer()
                            .frame(height: geo.size.height * 0.02)

                        HStack(spacing: 8) {
                            CourtPushButton(title: "Training Hub", icon: "dumbbell") {
                                navigateTo = "TrainingHub"
                            }
                            CourtPushButton(title: "Performance Hub", icon: "chart.line.uptrend.xyaxis") {
                                navigateTo = "PerformanceHub"
                            }
                        }

                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 12)
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { navigateTo == "PlayHub" },
                set: { if !$0 { navigateTo = nil } }
            )) {
                PlayHubView()
            }
            .navigationDestination(isPresented: Binding(
                get: { navigateTo == "PracticeHub" },
                set: { if !$0 { navigateTo = nil } }
            )) {
                PracticeHubView()
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
            .navigationDestination(isPresented: Binding(
                get: { navigateTo == "PlayerProfile" },
                set: { if !$0 { navigateTo = nil } }
            )) {
                PlayerProfileView()
            }
        }
    }
}

#Preview {
    HomeScreen()
}