import SwiftUI

/// Displays a single hit/replay's AI coach feedback in a focused, readable sheet.
struct CoachFeedbackView: View {
    let title: String
    let hitType: String
    let ballSpeedMPH: Double
    let overallScore: Double
    let jumpHeightInches: Double
    let coachFeedback: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea()

            VStack(spacing: 16) {
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
                                .fill(Color.black.opacity(0.4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.pink.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.top, 40)

                VStack(spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Text("\(hitType) • \(String(format: "%.0f mph", ballSpeedMPH)) • Score \(String(format: "%.0f", overallScore))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if jumpHeightInches > 0 {
                    Text("Jump Height: \(String(format: "%.1f in", jumpHeightInches))")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                if coachFeedback.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "lightbulb.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                        Text("No coach feedback available for this hit.")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .font(.title3)
                                .foregroundColor(.yellow)
                                .padding(.top, 4)
                            Text(coachFeedback)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
    }
}