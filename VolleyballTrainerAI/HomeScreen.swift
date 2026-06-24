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
                            NavigationLink(destination: PlaceholderView(title: "Play Hub")) {
                                GlowButtonContent(imageName: "playhub")
                            }
                            NavigationLink(destination: PlaceholderView(title: "Practice Hub")) {
                                GlowButtonContent(imageName: "practicehub")
                            }
                        }

                        // ROW 2 — Training Hub + Performance Hub
                        HStack(spacing: 6) {
                            NavigationLink(destination: TrainingHubView()) {
                                GlowButtonContent(imageName: "traininghub")
                            }
                            NavigationLink(destination: PerformanceHubView()) {
                                GlowButtonContent(imageName: "performancehub")
                            }
                        }

                        // ROW 3 — Saved Analytics Vault
                        HStack(spacing: 6) {
                            NavigationLink(destination: SessionSummaryView()) {
                                GlowButtonContent(imageName: "savedpractices")
                            }
                        }
                    }
                    .padding(.horizontal, 12)

                    Spacer().frame(height: geo.size.height * 0.05)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// GlowButtonContent that handles the visual press effects
struct GlowButtonContent: View {
    let imageName: String
    @State private var isPressed = false

    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .aspectRatio(754/511, contentMode: .fit)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.12), value: isPressed)

            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.pink.opacity(0.8), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.pink.opacity(0.08))
                )
                .opacity(isPressed ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct PlaceholderView: View {
    let title: String
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.gray)
                Text("\(title) Coming Soon")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}