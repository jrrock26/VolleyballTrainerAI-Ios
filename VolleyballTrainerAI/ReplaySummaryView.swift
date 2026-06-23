import SwiftUI
import AVKit
import Vision

enum PortraitOrientation {
    static func lock() {
        AppDelegate.orientationLock = .portrait
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
    }
}

struct ReplaySummaryView: View {
    let sessionHits: [VolleyballHit]

    @StateObject private var tracker = PoseTracker()
    @State private var selectedHitIndex: Int = 0
    @State private var slowMotionEnabled = true
    @State private var player = AVPlayer()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            let videoHeight = max(280, min(geo.size.height * 0.48, geo.size.width * 1.45))
            let containerWidth = geo.size.width - 24

            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.1)
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    HStack {
                        Text("Session Review")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(sessionHits.count) hits")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if sessionHits.isEmpty {
                        Spacer()
                        Text("No hits detected during this session.")
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        let currentHit = sessionHits[selectedHitIndex]

                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black)
                                .frame(width: containerWidth, height: videoHeight)
                                .clipped()

                            if !currentHit.videoLocalURLString.isEmpty {
                                let videoURL = URL(fileURLWithPath: currentHit.videoLocalURLString)

                                AVPlayerVideoWithOverlayView(
                                    player: player,
                                    tracker: tracker,
                                    videoURL: videoURL,
                                    hitType: currentHit.hitType,
                                    slowMotionEnabled: slowMotionEnabled,
                                    containerSize: CGSize(width: containerWidth, height: videoHeight)
                                )
                                .frame(width: containerWidth, height: videoHeight)
                                .cornerRadius(12)
                                .clipped()

                                SkeletonOverlayView(
                                    jointPoints: tracker.jointPoints,
                                    videoRect: tracker.videoRect
                                )
                                .frame(width: tracker.videoRect.width, height: tracker.videoRect.height)
                                .position(x: tracker.videoRect.midX, y: tracker.videoRect.midY)
                                .scaleEffect(0.85)
                                .offset(x: 10, y: -10)
                                .clipped()
                                .allowsHitTesting(false)

                                if let ballRect = tracker.ballBoundingBoxRect {
                                    let scaleX = tracker.videoRect.width
                                    let scaleY = tracker.videoRect.height
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.orange, lineWidth: 3)
                                        .frame(
                                            width: max(12, ballRect.width * scaleX),
                                            height: max(12, ballRect.height * scaleY)
                                        )
                                        .position(
                                            x: tracker.videoRect.origin.x + ballRect.midX * scaleX,
                                            y: tracker.videoRect.origin.y + ballRect.midY * scaleY
                                        )
                                        .shadow(color: .orange, radius: 4)
                                        .allowsHitTesting(false)
                                }
                            } else {
                                Text("No clip file found for this hit")
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: containerWidth, height: videoHeight)
                        .padding(.horizontal, 12)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<sessionHits.count, id: \.self) { index in
                                    Button(action: {
                                        selectedHitIndex = index
                                        tracker.resetTrackingTokens()
                                    }) {
                                        VStack(spacing: 2) {
                                            Text("HIT #\(index + 1)")
                                                .font(.system(size: 11, weight: .bold))
                                            Text(sessionHits[index].hitType.uppercased())
                                                .font(.system(size: 8))
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(
                                            selectedHitIndex == index
                                            ? Color.yellow
                                            : Color(red: 0.16, green: 0.16, blue: 0.18)
                                        )
                                        .foregroundColor(
                                            selectedHitIndex == index ? .black : .white
                                        )
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                        }

                        HStack(spacing: 6) {
                            Text("Slow Mo 0.5x")
                                .font(.caption)
                                .foregroundColor(.white)
                            Toggle("", isOn: $slowMotionEnabled)
                                .labelsHidden()
                                .scaleEffect(0.85)
                        }
                        .padding(.horizontal, 16)

                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                SummaryMetricBox(
                                    title: "Ball Speed",
                                    val: String(format: "%.1f MPH", currentHit.ballSpeedMPH),
                                    color: .orange
                                )
                                SummaryMetricBox(
                                    title: "Jump",
                                    val: currentHit.hitType == "Spike"
                                        ? String(format: "%.1f In", currentHit.jumpHeightInches)
                                        : "0.0 In",
                                    color: .green
                                )
                                SummaryMetricBox(
                                    title: "Score",
                                    val: String(format: "%.0f Pts", currentHit.overallScore),
                                    color: .yellow
                                )
                            }
                            HStack(spacing: 6) {
                                SummaryMetricBox(
                                    title: "Launch",
                                    val: String(format: "%.1f°", currentHit.ballAngleDegrees),
                                    color: .cyan
                                )
                                SummaryMetricBox(
                                    title: "Distance",
                                    val: String(format: "%.1f Ft", currentHit.ballDistanceFeet),
                                    color: .purple
                                )
                                SummaryMetricBox(
                                    title: "Arm",
                                    val: String(format: "%.0f°", currentHit.armAngleDegrees),
                                    color: .blue
                                )
                            }
                        }
                        .padding(.horizontal, 12)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .padding(.top, 2)
                                Text(currentHit.coachFeedback)
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )

                            HStack(spacing: 8) {
                                Button("Saved Analytics Vault") {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("NavigateToScreen"),
                                            object: "SavedAnalytics"
                                        )
                                    }
                                }
                                .font(.caption.bold())
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.yellow)
                                .cornerRadius(8)

                                Button("Close") {
                                    player.pause()
                                    dismiss()
                                }
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
        }
        .onAppear {
            PortraitOrientation.lock()
        }
    }
}

struct AVPlayerVideoWithOverlayView: UIViewRepresentable {
    let player: AVPlayer
    let tracker: PoseTracker
    let videoURL: URL
    let hitType: String
    let slowMotionEnabled: Bool
    let containerSize: CGSize

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = CGRect(origin: .zero, size: containerSize)
        view.layer.addSublayer(playerLayer)

        context.coordinator.playerLayer = playerLayer
        context.coordinator.containerSize = containerSize
        context.coordinator.slowMotionEnabled = slowMotionEnabled
        context.coordinator.load(url: videoURL, hitType: hitType)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.containerSize = containerSize
        context.coordinator.slowMotionEnabled = slowMotionEnabled
        context.coordinator.playerLayer?.frame = CGRect(origin: .zero, size: containerSize)

        if let displaySize = context.coordinator.currentDisplaySize {
            let rect = context.coordinator.computeVideoRect(
                containerSize: containerSize,
                videoSize: displaySize
            )
            DispatchQueue.main.async {
                tracker.videoRect = rect
                tracker.currentVideoOrientation = context.coordinator.rawBufferOrientation
            }
        }

        if context.coordinator.loadedURL != videoURL {
            context.coordinator.load(url: videoURL, hitType: hitType)
        } else {
            player.rate = slowMotionEnabled ? 0.5 : 1.0
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(player: player, tracker: tracker)
    }

    class Coordinator: NSObject {
        var playerLayer: AVPlayerLayer?
        var containerSize: CGSize = .zero
        var slowMotionEnabled: Bool = true
        let tracker: PoseTracker
        private let player: AVPlayer
        private(set) var loadedURL: URL?
        private var timeObserverToken: Any?
        private var endObserver: NSObjectProtocol?
        var currentDisplaySize: CGSize?
        private var currentNaturalSize: CGSize = .zero
        private(set) var rawBufferOrientation: AVCaptureVideoOrientation = .portrait

        init(player: AVPlayer, tracker: PoseTracker) {
            self.player = player
            self.tracker = tracker
        }

        private func detectBufferOrientation(from track: AVAssetTrack) -> AVCaptureVideoOrientation {
            let t = track.preferredTransform
            if t.a == 0 && t.b == 1 && t.c == -1 && t.d == 0 { return .landscapeLeft }
            if t.a == 0 && t.b == -1 && t.c == 1 && t.d == 0 { return .landscapeRight }
            if t.a == -1 && t.b == 0 && t.c == 0 && t.d == -1 { return .portraitUpsideDown }
            return .portrait
        }

        func load(url: URL, hitType: String) {
            loadedURL = url

            let asset = AVAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)

            let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ])
            playerItem.add(videoOutput)
            player.replaceCurrentItem(with: playerItem)

            if let track = asset.tracks(withMediaType: .video).first {
                let natural = track.naturalSize
                let transform = track.preferredTransform
                let transformed = natural.applying(transform)

                currentDisplaySize = CGSize(width: abs(transformed.width), height: abs(transformed.height))
                currentNaturalSize = natural
                rawBufferOrientation = detectBufferOrientation(from: track)
            } else {
                currentDisplaySize = CGSize(width: 720, height: 1280)
                currentNaturalSize = CGSize(width: 720, height: 1280)
                rawBufferOrientation = .portrait
            }

            tracker.currentVideoOrientation = rawBufferOrientation

            if let displaySize = currentDisplaySize {
                let rect = computeVideoRect(
                    containerSize: containerSize,
                    videoSize: displaySize
                )
                DispatchQueue.main.async {
                    self.tracker.videoRect = rect
                }
            }

            if let endObserver = endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                self.player.seek(to: .zero)
                self.player.play()
                self.player.rate = self.slowMotionEnabled ? 0.5 : 1.0
            }

            setupTimeObserver(output: videoOutput, type: hitType)

            player.seek(to: .zero)
            player.play()
            player.rate = slowMotionEnabled ? 0.5 : 1.0
        }

        func computeVideoRect(containerSize: CGSize, videoSize: CGSize) -> CGRect {
            let videoAspect = videoSize.width / videoSize.height
            let viewAspect = containerSize.width / containerSize.height

            var origin = CGPoint.zero
            var size = containerSize

            if videoAspect > viewAspect {
                let scaledWidth = containerSize.height * videoAspect
                origin.x = (containerSize.width - scaledWidth) / 2
                size.width = scaledWidth
            } else {
                let scaledHeight = containerSize.width / videoAspect
                origin.y = (containerSize.height - scaledHeight) / 2
                size.height = scaledHeight
            }

            return CGRect(origin: origin, size: size)
        }

        func setupTimeObserver(
            output: AVPlayerItemVideoOutput,
            type: String
        ) {
            if let token = timeObserverToken {
                player.removeTimeObserver(token)
                timeObserverToken = nil
            }

            let interval = CMTime(seconds: 0.03, preferredTimescale: 600)
            timeObserverToken = player.addPeriodicTimeObserver(
                forInterval: interval,
                queue: DispatchQueue.global(qos: .userInteractive)
            ) { [weak self] time in
                guard let self = self, self.player.rate > 0 else { return }

                if output.hasNewPixelBuffer(forItemTime: time),
                   let pixelBuffer = output.copyPixelBuffer(
                       forItemTime: time,
                       itemTimeForDisplay: nil
                   ) {
                    self.tracker.processRawPixelBuffer(pixelBuffer, hitType: type)
                }
            }
        }

        deinit {
            if let token = timeObserverToken {
                player.removeTimeObserver(token)
            }
            if let endObserver = endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }
    }
}

struct SummaryMetricBox: View {
    let title: String
    let val: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.gray)
            Text(val)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(Color(red: 0.16, green: 0.16, blue: 0.18))
        .cornerRadius(8)
    }
}