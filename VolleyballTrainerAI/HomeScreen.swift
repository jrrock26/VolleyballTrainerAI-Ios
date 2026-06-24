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
                            CourtButton(imageName: "playhub", title: "Play Hub") {
                                navigateTo = "PlayHub"
                            }
                            CourtButton(imageName: "practicehub", title: "Practice Hub") {
                                navigateTo = "PracticeHub"
                            }
                        }

                        Spacer()
                            .frame(height: geo.size.height * 0.02)

                        HStack(spacing: 8) {
                            CourtButton(imageName: "traininghub", title: "Training Hub") {
                                navigateTo = "TrainingHub"
                            }
                            CourtButton(imageName: "performancehub", title: "Performance Hub") {
                                navigateTo = "PerformanceHub"
                            }
                        }

                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 12)
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
            }
        }
    }
}