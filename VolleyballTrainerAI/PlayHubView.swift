import SwiftUI

struct PlayHubView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPlayDesigner = false
    @State private var showRotations = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // Background
                    Color.black.ignoresSafeArea()

                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    VStack(spacing: 0) {

                        // --- FIXED TOP-LEFT BACK BUTTON ---
                        HStack {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.system(size: 18, weight: .semibold, design: .rounded))   // ← original font restored
                                .foregroundColor(.pink)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black.opacity(0.55))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.pink.opacity(0.6), lineWidth: 1)
                                        )
                                )
                            }
                            Spacer()
                        }
                        .padding(.top, 40)
                        .padding(.leading, 20)

                        // --- BUTTONS BELOW 48% OF SCREEN ---
                        Spacer()
                            .frame(height: geo.size.height * 0.48)

                        // Hidden navigation links
                        NavigationLink(destination: PlayDesignerView(), isActive: $showPlayDesigner) {
                            EmptyView()
                        }
                        .navigationBarHidden(true)

                        NavigationLink(destination: RotationsView(), isActive: $showRotations) {
                            EmptyView()
                        }
                        .navigationBarHidden(true)

                        // --- SPORTY BUTTONS ---
                        VStack(spacing: 20) {

                            CourtPushButton(title: "Design Plays", icon: "pencil.circle") {
                                showPlayDesigner = true
                            }
                            .frame(width: geo.size.width * 0.50, height: 60)
                            .font(.custom("Orbitron-Regular", size: 22))
                            .multilineTextAlignment(.center)

                            CourtPushButton(title: "Rotations", icon: "arrow.3.trianglepath") {
                                showRotations = true
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
            .navigationBarHidden(true)
        }
    }
}

