import SwiftUI
import AVFoundation
import Vision
import SwiftData
import AudioToolbox

struct LiveAIView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var tracker = PoseTracker()
    @State private var sessionID = UUID()
    @State private var sessionHits: [VolleyballHit] = []
    @State private var profile = AthleteProfile()

    @State private var isSessionActive = false
    @State private var isRecordingHit = false
    @State private var countdownRemaining = 5
    @State private var isCountingDown = false
    @State private var showReplaySummary = false
    @State private var selectedEvaluationType = "Spike"
    @State private var countdownTimer: Timer? = nil
    @State private var capturedHitMetrics: (jump: Double, arm: Double, speed: Double, launch: Double, distance: Double, contactHeight: Double, handSpeed: Double, hipSep: Double)? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                CameraPreviewView(
                    tracker: tracker,
                    isRecording: isRecordingHit,
                    cameraPosition: tracker.cameraPosition,
                    hitType: selectedEvaluationType
                ) { savedFileUrl in
                    persistSingleHit(videoURL: savedFileUrl)
                }
                .ignoresSafeArea()

                SkeletonOverlayView(
                    jointPoints: tracker.jointPoints,
                    videoRect: tracker.videoRect
                )
                .ignoresSafeArea()

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
                }

                if isCountingDown {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    Text("\(countdownRemaining)")
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                        .transition(.scale)
                }

                VStack {
                    HStack {
                        Button("Close") {
                            isRecordingHit = false
                            countdownTimer?.invalidate()
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)

                        Picker("Type", selection: $selectedEvaluationType) {
                            Text("Spike").tag("Spike")
                            Text("Serve").tag("Serve")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 130)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                        .disabled(isRecordingHit || isCountingDown)

                        Spacer()

                        Button(action: {
                            tracker.cameraPosition = (tracker.cameraPosition == .back) ? .front : .back
                        }) {
                            Image(systemName: "camera.rotate.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .disabled(isRecordingHit || isCountingDown)
                    }
                    .padding()

                    if !isSessionActive {
                        Text("TAP START BELOW TO BEGIN TRAINING")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(6)
                            .padding(.top, 10)
                    } else {
                        Text("SESSION HITS CAPTURED: \(sessionHits.count)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                            .padding(8)
                            .background(Color.black.opacity(0.75))
                            .cornerRadius(6)
                            .padding(.top, 10)
                    }

                    Spacer()

                    HStack(spacing: 20) {
                        LiveBadge(
                            label: "Jump Height",
                            value: String(format: "%.1f in", tracker.jumpHeight),
                            color: .green
                        )
                        LiveBadge(
                            label: "Arm Extension",
                            value: String(format: "%.0f°", tracker.armExtensionAngle),
                            color: .blue
                        )
                        LiveBadge(
                            label: "Ball Speed",
                            value: String(format: "%.1f mph", tracker.computedBallSpeedMPH),
                            color: .orange
                        )
                        LiveBadge(
                            label: "Distance",
                            value: String(format: "%.1f ft", tracker.computedFlightDistanceFeet),
                            color: .purple
                        )
                    }
                    .padding(.bottom, 20)
                    .opacity(isRecordingHit ? 1.0 : 0.0)

                    HStack(spacing: 40) {
                        if !isSessionActive {
                            Button(action: {
                                sessionID = UUID()
                                sessionHits.removeAll()
                                isSessionActive = true
                            }) {
                                Text("Start Session")
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Color.yellow)
                                    .cornerRadius(10)
                            }
                        } else {
                            Button(action: { triggerPrepCountdownSequence() }) {
                                HStack {
                                    Image(systemName: "record.circle")
                                    Text(isRecordingHit ? "Analyzing..." : "Record Hit #\(sessionHits.count + 1)")
                                }
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .background(isRecordingHit ? Color.red : Color.gray)
                                .cornerRadius(10)
                            }
                            .disabled(isRecordingHit || isCountingDown)

                            Button(action: {
                                isSessionActive = false
                                if !sessionHits.isEmpty {
                                    showReplaySummary = true
                                } else {
                                    dismiss()
                                }
                            }) {
                                Text("End Session")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(10)
                            }
                            .disabled(isRecordingHit || isCountingDown)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            PortraitOrientation.lock()
            tracker.onSingleHitExtracted = { jump, arm, speed, launch, distance, contactHeight, handSpeed, hipSep in
                AudioServicesPlaySystemSound(1519)
                DispatchQueue.main.async {
                    self.capturedHitMetrics = (jump, arm, speed, launch, distance, contactHeight, handSpeed, hipSep)
                    self.isRecordingHit = false
                }
            }
        }
        .onChange(of: isRecordingHit) { _, recording in
            guard recording else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                if self.isRecordingHit {
                    self.isRecordingHit = false
                }
            }
        }
        .fullScreenCover(isPresented: $showReplaySummary) {
            ReplaySummaryView(sessionHits: sessionHits)
        }
    }

    private func triggerPrepCountdownSequence() {
        capturedHitMetrics = nil
        tracker.resetTrackingTokens()
        countdownRemaining = 5
        isCountingDown = true
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.countdownRemaining > 1 {
                self.countdownRemaining -= 1
            } else {
                timer.invalidate()
                self.isCountingDown = false
                self.isRecordingHit = true
            }
        }
    }

    private func persistSingleHit(videoURL: URL) {
        DispatchQueue.main.async {
            let metrics = self.capturedHitMetrics ?? (
                jump: self.tracker.jumpHeight,
                arm: self.tracker.armExtensionAngle,
                speed: self.tracker.computedBallSpeedMPH,
                launch: self.tracker.computedLaunchAngleDegrees,
                distance: self.tracker.computedFlightDistanceFeet,
                contactHeight: self.tracker.computedContactHeightInches,
                handSpeed: self.tracker.computedHandSpeedMPH,
                hipSep: self.tracker.computedHipShoulderSeparation
            )

            let hitLog = VolleyballHit(
                sessionID: self.sessionID,
                hitType: self.selectedEvaluationType,
                jumpHeightInches: metrics.jump,
                armAngleDegrees: metrics.arm,
                ballSpeedMPH: metrics.speed,
                ballAngleDegrees: metrics.launch,
                ballDistanceFeet: metrics.distance,
                videoLocalURLString: videoURL.path,
                contactHeightInches: metrics.contactHeight,
                handSpeedMPH: metrics.handSpeed,
                hipShoulderSeparation: metrics.hipSep,
                profile: self.profile,
                sessionHits: self.sessionHits
            )

            var updatedProfile = self.profile
            updatedProfile.incorporate(hit: hitLog, sessionID: self.sessionID)
            self.profile = updatedProfile

            self.modelContext.insert(hitLog)
            self.sessionHits.append(hitLog)
            self.capturedHitMetrics = nil
            try? self.modelContext.save()
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let tracker: PoseTracker
    let isRecording: Bool
    let cameraPosition: AVCaptureDevice.Position
    let hitType: String
    var onRecordingComplete: (URL) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        context.coordinator.setupSession(on: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.updateLayout(on: uiView)
        context.coordinator.updateCameraPosition(to: cameraPosition)
        context.coordinator.manageRecordingLifecycle(
            isRecording: isRecording,
            type: hitType,
            completion: onRecordingComplete
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(tracker: tracker)
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        private let tracker: PoseTracker
        private let session = AVCaptureSession()
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private var assetWriter: AVAssetWriter?
        private var assetWriterInput: AVAssetWriterInput?
        private var isWriting = false
        private var currentVideoURL: URL?
        private var startTime: CMTime?
        private var currentHitType = "Spike"

        private let writingQueue = DispatchQueue(label: "com.volleyballtrainer.writerqueue")
        private var isSessionActive = false

        init(tracker: PoseTracker) {
            self.tracker = tracker
        }

        func setupSession(on view: UIView) {
            session.sessionPreset = .hd1280x720

            guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: tracker.cameraPosition
            ),
            let input = try? AVCaptureDeviceInput(device: camera) else { return }

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(
                self,
                queue: DispatchQueue(label: "camera_processing_queue", qos: .userInteractive)
            )

            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(output) { session.addOutput(output) }

            configureConnections(for: tracker.cameraPosition, videoOutput: output)

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.frame = view.bounds
            layer.videoGravity = .resizeAspect   // WIDE VIEW FIX
            view.layer.addSublayer(layer)
            self.previewLayer = layer

            configurePreviewConnection(for: tracker.cameraPosition)
            publishVideoRect(for: layer.bounds.size)

            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }

        func updateLayout(on view: UIView) {
            guard let layer = previewLayer else { return }
            layer.frame = view.bounds
            publishVideoRect(for: view.bounds.size)
        }

        private func portraitDisplayVideoSize() -> CGSize {
            CGSize(width: 720, height: 1280)
        }

        private func publishVideoRect(for containerSize: CGSize) {
            let rect = computeVideoRect(
                containerSize: containerSize,
                videoSize: portraitDisplayVideoSize()
            )
            DispatchQueue.main.async {
                self.tracker.videoRect = rect
                self.tracker.currentVideoOrientation = .portrait
            }
        }

        private func configureConnections(
            for position: AVCaptureDevice.Position,
            videoOutput: AVCaptureVideoDataOutput
        ) {
            if let connection = videoOutput.connection(with: .video),
               connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }

        private func configurePreviewConnection(for position: AVCaptureDevice.Position) {
            guard let connection = previewLayer?.connection else { return }
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = (position == .front)
            }
        }

        func computeVideoRect(containerSize: CGSize, videoSize: CGSize) -> CGRect {
            let videoAspect = videoSize.width / videoSize.height
            let viewAspect = containerSize.width / containerSize.height

            var origin = CGPoint.zero
            var size = containerSize

            if videoAspect > viewAspect {
                let scaledHeight = containerSize.width / videoAspect
                origin.y = (containerSize.height - scaledHeight) / 2
                size.height = scaledHeight
            } else {
                let scaledWidth = containerSize.height * videoAspect
                origin.x = (containerSize.width - scaledWidth) / 2
                size.width = scaledWidth
            }

            return CGRect(origin: origin, size: size)
        }

        func updateCameraPosition(to newPosition: AVCaptureDevice.Position) {
            guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
            if currentInput.device.position == newPosition { return }

            session.beginConfiguration()
            session.removeInput(currentInput)

            guard let newCamera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: newPosition
            ),
            let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
                session.addInput(currentInput)
                session.commitConfiguration()
                return
            }

            if session.canAddInput(newInput) {
                session.addInput(newInput)
                if let output = session.outputs.first as? AVCaptureVideoDataOutput {
                    configureConnections(for: newPosition, videoOutput: output)
                }
                configurePreviewConnection(for: newPosition)
            } else {
                session.addInput(currentInput)
            }

            session.commitConfiguration()

            DispatchQueue.main.async {
                self.tracker.cameraPosition = newPosition
                if let layer = self.previewLayer {
                    self.publishVideoRect(for: layer.bounds.size)
                }
            }
        }

        func manageRecordingLifecycle(
            isRecording: Bool,
            type: String,
            completion: @escaping (URL) -> Void
        ) {
            writingQueue.async { [weak self] in
                guard let self = self else { return }
                self.currentHitType = type
                if isRecording && !self.isWriting {
                    self.startRecording()
                } else if !isRecording && self.isWriting {
                    self.stopRecording(completion: completion)
                }
            }
        }

        private func startRecording() {
            self.isSessionActive = false
            self.startTime = nil

            let tempDir = FileManager.default.temporaryDirectory
            let videoName = "hit_run_\(UUID().uuidString).mp4"
            let outputURL = tempDir.appendingPathComponent(videoName)
            self.currentVideoURL = outputURL

            try? FileManager.default.removeItem(at: outputURL)
            guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else { return }

            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 720,
                AVVideoHeightKey: 1280
            ]

            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            writerInput.expectsMediaDataInRealTime = true

            if writer.canAdd(writerInput) { writer.add(writerInput) }
            if writer.startWriting() {
                self.assetWriter = writer
                self.assetWriterInput = writerInput
                self.isWriting = true
            }
        }

        private func stopRecording(completion: @escaping (URL) -> Void) {
            self.isWriting = false
            self.isSessionActive = false
            guard let writer = assetWriter else { return }

            assetWriterInput?.markAsFinished()
            writer.finishWriting { [weak self] in
                guard let self = self, let url = self.currentVideoURL else { return }
                completion(url)
            }
        }

        func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            autoreleasepool {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }

                tracker.processFrame(sampleBuffer: sampleBuffer, hitType: self.currentHitType)
                guard isWriting else { return }

                writingQueue.async { [weak self] in
                    guard let self = self,
                          self.isWriting,
                          let writer = self.assetWriter,
                          let writerInput = self.assetWriterInput,
                          writer.status == .writing else { return }

                    if writerInput.isReadyForMoreMediaData {
                        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                        if self.startTime == nil {
                            self.startTime = timestamp
                            writer.startSession(atSourceTime: timestamp)
                            self.isSessionActive = true
                        }
                        if self.isSessionActive && writer.status == .writing {
                            writerInput.append(sampleBuffer)
                        }
                    }
                }
            }
        }
    }
}

struct SkeletonOverlayView: View {
    let jointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let videoRect: CGRect
    var lineWidth: CGFloat = 4
    var jointSize: CGFloat = 8

    /// Computed line width proportional to video display width (capped at default).
    /// Scales the skeleton thickness with the video size so it doesn't look too big
    /// on small video displays.
    private var scaledLineWidth: CGFloat {
        min(lineWidth, max(1.2, videoRect.width / 110))
    }

    /// Computed joint size proportional to video display width (capped at default).
    private var scaledJointSize: CGFloat {
        min(jointSize, max(2.5, videoRect.width / 55))
    }

    var body: some View {
        ZStack {
            Path { path in
                drawBoneLink(from: .rightShoulder, to: .rightElbow, in: &path)
                drawBoneLink(from: .rightElbow, to: .rightWrist, in: &path)
                drawBoneLink(from: .leftShoulder, to: .leftElbow, in: &path)
                drawBoneLink(from: .leftElbow, to: .leftWrist, in: &path)

                drawBoneLink(from: .leftShoulder, to: .rightShoulder, in: &path)
                drawBoneLink(from: .leftShoulder, to: .leftHip, in: &path)
                drawBoneLink(from: .rightShoulder, to: .rightHip, in: &path)
                drawBoneLink(from: .leftHip, to: .rightHip, in: &path)

                drawBoneLink(from: .rightHip, to: .rightKnee, in: &path)
                drawBoneLink(from: .rightKnee, to: .rightAnkle, in: &path)

                drawBoneLink(from: .leftHip, to: .leftKnee, in: &path)
                drawBoneLink(from: .leftKnee, to: .leftAnkle, in: &path)

                drawBoneLink(from: .neck, to: .leftShoulder, in: &path)
                drawBoneLink(from: .neck, to: .rightShoulder, in: &path)
            }
            .stroke(Color(red: 1.0, green: 0.08, blue: 0.58), lineWidth: scaledLineWidth)
            .shadow(color: Color(red: 1.0, green: 0.08, blue: 0.58), radius: scaledLineWidth * 0.6)

            ForEach(Array(jointPoints.keys), id: \.self) { joint in
                if let pt = jointPoints[joint] {
                    Circle()
                        .fill(Color.white)
                        .frame(width: scaledJointSize, height: scaledJointSize)
                        .position(mappedPoint(pt))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawBoneLink(
        from jointA: VNHumanBodyPoseObservation.JointName,
        to jointB: VNHumanBodyPoseObservation.JointName,
        in path: inout Path
    ) {
        if let ptA = jointPoints[jointA], let ptB = jointPoints[jointB] {
            let a = mappedPoint(ptA)
            let b = mappedPoint(ptB)
            path.move(to: a)
            path.addLine(to: b)
        }
    }

    private func mappedPoint(_ p: CGPoint) -> CGPoint {
        CGPoint(
            x: videoRect.origin.x + p.x * videoRect.width,
            y: videoRect.origin.y + p.y * videoRect.height
        )
    }
}

struct LiveBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
                .tracking(1.0)
            Text(value)
                .font(.headline)
                .bold()
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.75))
        .cornerRadius(10)
    }
}

