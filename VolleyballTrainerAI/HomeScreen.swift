import SwiftUI

struct HomeScreen: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack {
                    Spacer().frame(height: geo.size.height * 0.72)

                    VStack(spacing: 6) {
                        // ROW 1 — Play Hub + Practice Hub
                        HStack(spacing: 6) {
                            GlowButton(imageName: "playhub") {
                                navigate(to: "PlayHub")
                            }
                            GlowButton(imageName: "practicehub") {
                                navigate(to: "PracticeHub")
                            }
                        }

                        // ROW 2 — Training Hub + Performance Hub
                        HStack(spacing: 6) {
                            GlowButton(imageName: "traininghub") {
                                navigate(to: "TrainingHub")
                            }
                            GlowButton(imageName: "performancehub") {
                                navigate(to: "PerformanceHub")
                            }
                        }
                    }
                    .padding(.horizontal, 12)

                    Spacer().frame(height: geo.size.height * 0.05)
                }
            }
        }
    }

    private func navigate(to screen: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToScreen"),
            object: screen
        )
    }
}

