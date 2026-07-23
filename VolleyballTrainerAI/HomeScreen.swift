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
                            .frame(height: geo.size.height * 0.48)

                        VStack(spacing: 22) {

                            CourtPushButton(title: "Player Profile", icon: "person.circle") {
                                navigateTo = "PlayerProfile"
                            }
                            .frame(width: geo.size.width * 0.50, height: 60)
                            .font(.custom("Orbitron-Regular", size: 22))
                            .multilineTextAlignment(.center)

                            CourtPushButton(title: "Performance Hub", icon: "chart.line.uptrend.xyaxis") {
                                navigateTo = "PerformanceHub"
                            }
                            .frame(width: geo.size.width * 0.50, height: 60)
                            .font(.custom("Orbitron-Regular", size: 22))
                            .multilineTextAlignment(.center)

                            CourtPushButton(title: "Play Hub", icon: "play.circle") {
                                navigateTo = "PlayHub"
                            }
                            .frame(width: geo.size.width * 0.50, height: 60)
                            .font(.custom("Orbitron-Regular", size: 22))
                            .multilineTextAlignment(.center)

                            CourtPushButton(title: "Practice Hub", icon: "figure.run") {
                                navigateTo = "PracticeHub"
                            }
                            .frame(width: geo.size.width * 0.50, height: 60)
                            .font(.custom("Orbitron-Regular", size: 22))
                            .multilineTextAlignment(.center)

                            CourtPushButton(title: "Training Hub", icon: "dumbbell") {
                                navigateTo = "TrainingHub"
                            }
                            .frame(width: geo.size.width * 0.50, height: 60)
                            .font(.custom("Orbitron-Regular", size: 22))
                            .multilineTextAlignment(.center)

                            CourtPushButton(title: "Team Management", icon: "person.3.fill") {
                                navigateTo = "TeamManagement"
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

            // Navigation destinations
            .navigationDestination(isPresented: Binding(get: { navigateTo == "TeamManagement" }, set: { if !$0 { navigateTo = nil } })) { TeamManagementHubView() }
            .navigationDestination(isPresented: Binding(get: { navigateTo == "PlayHub" }, set: { if !$0 { navigateTo = nil } })) { PlayHubView() }
            .navigationDestination(isPresented: Binding(get: { navigateTo == "PracticeHub" }, set: { if !$0 { navigateTo = nil } })) { PracticeHubView() }
            .navigationDestination(isPresented: Binding(get: { navigateTo == "TrainingHub" }, set: { if !$0 { navigateTo = nil } })) { TrainingHubView() }
            .navigationDestination(isPresented: Binding(get: { navigateTo == "PerformanceHub" }, set: { if !$0 { navigateTo = nil } })) { PerformanceHubView() }
            .navigationDestination(isPresented: Binding(get: { navigateTo == "PlayerProfile" }, set: { if !$0 { navigateTo = nil } })) { PlayerProfileView() }
        }
    }
}

#Preview {
    HomeScreen()
}

