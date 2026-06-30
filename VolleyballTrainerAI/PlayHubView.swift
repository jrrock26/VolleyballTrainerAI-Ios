import SwiftUI

struct PlayHubView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPlayDesigner = false
    @State private var showRotations = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()

                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    VStack(spacing: 12) {

                        // Back button
                        HStack {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.pink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black.opacity(0.6))
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.pink.opacity(0.6), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            Spacer()
                        }
                        .padding(.top, geo.size.height * 0.38)

                        NavigationLink(destination: PlayDesignerView(), isActive: $showPlayDesigner) {
                            EmptyView()
                        }
                        .navigationBarHidden(true)

                        NavigationLink(destination: RotationsView(), isActive: $showRotations) {
                            EmptyView()
                        }
                        .navigationBarHidden(true)

                        CourtPushButton(title: "Design Plays", icon: "pencil.circle") {
                            showPlayDesigner = true
                        }

                        CourtPushButton(title: "Rotations", icon: "arrow.3.trianglepath") {
                            showRotations = true
                        }

                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
