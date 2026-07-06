import SwiftUI

struct CourtPushButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {

                // --- SPORTY ICON ---
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.pink)
                        .shadow(color: .pink.opacity(0.5), radius: 3)
                }

                // --- NEW SPORTY FONT (compact + athletic) ---
                Text(title.uppercased())
                    .font(.custom("Rajdhani-SemiBold", size: 17))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .blue.opacity(0.45), radius: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)      // smaller
            .padding(.horizontal, 6)     // narrower
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .pink.opacity(0.9),
                                        .blue.opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.pink.opacity(isPressed ? 1.0 : 0.4),
                            lineWidth: isPressed ? 2 : 1)
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Backward compatibility
struct CourtButton: View {
    let imageName: String
    let title: String
    let action: () -> Void

    var body: some View {
        CourtPushButton(title: title, icon: nil, action: action)
    }
}

