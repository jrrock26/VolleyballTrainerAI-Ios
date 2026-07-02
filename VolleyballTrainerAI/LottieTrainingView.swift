import SwiftUI
import Lottie

// MARK: - Lottie-Enabled Training Block Row
struct LottieTrainingBlockRow: View {
    let block: TrainingBlock
    let compact: Bool
    @State private var animationView: LottieAnimationView?
    
    var body: some View {
        HStack(spacing: 10) {
            // Lottie Animation Container
            LottieAnimationContainer(
                animationName: block.lottieAnimationName,
                loopMode: .loop,
                frameRate: 30
            )
            .frame(width: compact ? 44 : 56, height: compact ? 44 : 56)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(block.name)
                    .font(compact ? .subheadline.bold() : .headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(block.durationMinutes) min • \(block.category.rawValue) • \(block.intensity.rawValue.uppercased())")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
}

// MARK: - Lottie Animation Container View
struct LottieAnimationContainer: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let frameRate: Int
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let fallbackImageName = animationName.hasSuffix("_lottie") ? String(animationName.dropLast(6)) : animationName
        guard let animation = LottieAnimation.named(animationName) else {
            // Fallback to static image if Lottie not found
            let fallback = UIImageView(image: UIImage(named: fallbackImageName))
            fallback.contentMode = .scaleAspectFit
            view.addSubview(fallback)
            fallback.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                fallback.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                fallback.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                fallback.topAnchor.constraint(equalTo: view.topAnchor),
                fallback.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            return view
        }
        
        let animationView = LottieAnimationView(animation: animation)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.animationSpeed = 1.0
        animationView.play()
        
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        context.coordinator.animationView = animationView
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Animation continues playing automatically
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        weak var animationView: LottieAnimationView?
    }
}

// MARK: - Lottie Detail View
struct LottieTrainingBlockDetailView: View {
    let block: TrainingBlock
    @Environment(\.dismiss) private var dismiss
    @State private var animationView: LottieAnimationView?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Large Lottie Animation
                LottieAnimationContainer(
                    animationName: block.lottieAnimationName,
                    loopMode: .loop,
                    frameRate: 30
                )
                .frame(height: 240)
                .cornerRadius(16)
                
                Text(block.name)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                HStack {
                    Label("\(block.durationMinutes) min", systemImage: "clock")
                    Text("•")
                    Label(block.category.rawValue, systemImage: block.category.icon)
                    Text("•")
                    Label(block.intensity.rawValue.uppercased(), systemImage: "flame")
                }
                .font(.caption)
                .foregroundColor(.gray)
                
                Text("Instructions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(Array(block.instructions.enumerated()), id: \.offset) { i, line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(i + 1).")
                            .font(.caption.bold())
                            .foregroundColor(.pink)
                        Text(line)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                }
                
                Button("Close") { dismiss() }
                    .buttonStyle(TrainingButtonStyle(color: Color(red: 1.0, green: 0.08, blue: 0.58), foreground: .white))
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
}