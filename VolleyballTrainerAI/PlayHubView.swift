import SwiftUI

struct PlayHubView: View {
    @Environment(\.dismiss) private var dismiss

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
                            CourtButton(imageName: "playdesigner", title: "Design Plays") { }
                            CourtButton(imageName: "formations", title: "Rotations") { }
                        }

                        Spacer()
                            .frame(height: geo.size.height * 0.02)

                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 12)
                }
            }
        }
        .navigationBarHidden(true)
    }
}