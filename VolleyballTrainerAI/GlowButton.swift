import SwiftUI

struct GlowButton: View {
    let imageName: String
    let action: () -> Void

    @State private var isPressed = false

    init(imageName: String, action: @escaping () -> Void) {
        self.imageName = imageName
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(imageName)
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
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
        }
        .frame(maxWidth: .infinity, maxHeight: 160)
        .aspectRatio(1.0, contentMode: .fit)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

