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
                            if !currentHit.videoLocalURLString.isEmpty {
                                let videoURL = URL(fileURLWithPath: currentHit.videoLocalURLString)

                                AVPlayerVideoWithOverlayView(
                                    player: player,
                                    tracker: tracker,
                                    videoURL: videoURL,
                                    hitType: currentHit.hitType,
                                    slowMotionEnabled: slowMotionEnabled,
                                    containerSize: CGSize(
                                        width: geo.size.width - 24,
                                        height: videoHeight
                                    )
                                )
                                .frame(height: videoHeight)
                                .cornerRadius(12)
                                .clipped()

                                // Skeleton overlay - draws at tracker.videoRect coordinates
                                // which match the displayed video area. Frame matches the video.
                                SkeletonOverlayView(
                                    jointPoints: tracker.jointPoints,
                                    videoRect: tracker.videoRect,
                                    lineWidth: 5,
                                    jointSize: 10
                                )
                                .frame(height: videoHeight)
                                .allowsHitTesting(false)

                                if let ballRect = tracker.ballBoundingBoxRect {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.orange, lineWidth: 3)
                                        .frame(
                                            width: ballRect.width * tracker.videoRect.width,
                                            height: ballRect.height * tracker.videoRect.height
                                        )
                                        .position(
                                            x: tracker.videoRect.origin.x + ballRect.midX * tracker.videoRect.width,
                                            y: tracker.videoRect.origin.y + ballRect.midY * tracker.videoRect.height
                                        )
                                        .shadow(color: .orange, radius: 4)
                                        .allowsHitTesting(false)
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black)
                                    .frame(height: videoHeight)
                                    .overlay(
                                        Text("No clip file found for this hit")
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .frame(height: videoHeight)
                        .clipped()
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
                        .padding(.horizontal, 12)
                    }

                    Spacer(minLength: 4)

                    Button("Save and Sync Session") {
                        player.pause()
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.yellow)
                    .cornerRadius(10)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
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

        // On layout changes, recompute display videoRect based on display-oriented size.
        // This is the rect the skeleton draws into (matches the player layer's displayed area).
        if let displaySize = context.coordinator.currentDisplaySize {
            let rect = context.coordinator.computeVideoRect(
                containerSize: containerSize,
                videoSize: displaySize
            )
            DispatchQueue.main.async {
                tracker.videoRect = rect
                // Keep orientation matching raw buffers, not display
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
        /// The display-oriented size (after applying preferredTransform) – used for layout.
        var currentDisplaySize: CGSize?
        /// The raw pixel buffer size (natural size, before transform) – used for Vision framing.
        private var currentNaturalSize: CGSize = .zero
        /// The orientation of raw pixel buffers passed to Vision.
        private(set) var rawBufferOrientation: AVCaptureVideoOrientation = .portrait

        init(player: AVPlayer, tracker: PoseTracker) {
            self.player = player
            self.tracker = tracker
        }

        /// Determine the raw buffer orientation from the track's preferredTransform.
        /// copyPixelBuffer yields frames in the track's natural (un-transformed)
        /// coordinate system.  We must tell Vision that orientation so landmarks
        /// come out in the same space as the displayed (playerLayer) video.
        private func detectBufferOrientation(from track: AVAssetTrack) -> AVCaptureVideoOrientation {
            let t = track.preferredTransform
            // 90° CW  → raw buffers are landscapeLeft relative to display
            if t.a == 0 && t.b == 1 && t.c == -1 && t.d == 0 { return .landscapeLeft }
            // 90° CCW → raw buffers are landscapeRight relative to display
            if t.a == 0 && t.b == -1 && t.c == 1 && t.d == 0 { return .landscapeRight }
            // 180°    → raw buffers are portraitUpsideDown
            if t.a == -1 && t.b == 0 && t.c == 0 && t.d == -1 { return .portraitUpsideDown }
            // identity → raw buffers already match display orientation
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

                // Display size – what the player shows on screen after preferredTransform
                currentDisplaySize = CGSize(width: abs(transformed.width), height: abs(transformed.height))
                // Natural size – what the raw pixel buffers actually are
                currentNaturalSize = natural

                rawBufferOrientation = detectBufferOrientation(from: track)
            } else {
                currentDisplaySize = CGSize(width: 720, height: 1280)
                currentNaturalSize = CGSize(width: 720, height: 1280)
                rawBufferOrientation = .portrait
            }

            // Vision needs to know the orientation of the *raw pixel buffers* we send it.
            tracker.currentVideoOrientation = rawBufferOrientation

            // Vision orients the joint coordinates to upright via cgOrientationFrom, so
            // the resulting coordinates are in the display-oriented (transformed) space.
            // The videoRect must therefore use the display-oriented size to match.
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