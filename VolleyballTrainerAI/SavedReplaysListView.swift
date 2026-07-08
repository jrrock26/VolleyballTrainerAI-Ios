import SwiftUI
import SwiftData
import AVKit

struct SavedReplaysListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedReplay.createdAt, order: .reverse) private var savedReplays: [SavedReplay]
    @State private var selectedReplay: SavedReplay? = nil
    @State private var showDeleteAlert = false
    @State private var replayToDelete: SavedReplay? = nil
    @State private var showLimitAlert = false

    private let maxReplays = 30

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Saved Replays")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Text("\(savedReplays.count)/\(maxReplays) slots used")
                        .font(.caption)
                        .foregroundColor(savedReplays.count >= maxReplays ? .red : .gray)
                }
                .padding(.top)

                if savedReplays.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                        Text("No saved replays yet.")
                            .foregroundColor(.gray)
                        Text("Save replays from session review to view them anytime.")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(savedReplays) { replay in
                            Button(action: {
                                selectedReplay = replay
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.rectangle.fill")
                                        .font(.title2)
                                        .foregroundColor(.yellow)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(replay.title)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        HStack(spacing: 6) {
                                            Text("\(replay.hitType) • \(String(format: "%.0f mph", replay.ballSpeedMPH))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("•")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text(replay.createdAt, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Text("Score: \(String(format: "%.0f", replay.overallScore)) pts")
                                            .font(.caption2)
                                            .foregroundColor(.yellow.opacity(0.8))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 6)
                                .listRowBackground(Color(red: 0.14, green: 0.14, blue: 0.16))
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive, action: {
                                    replayToDelete = replay
                                    showDeleteAlert = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .fullScreenCover(item: $selectedReplay) { replay in
            SavedReplayPlaybackView(replay: replay)
        }
        .alert("Delete this replay?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                replayToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let replay = replayToDelete {
                    deleteReplay(replay)
                }
            }
        } message: {
            Text("This will permanently delete the saved replay video.")
        }
        .alert("Storage Full", isPresented: $showLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've reached the maximum of \(maxReplays) saved replays. Delete some to make room for more.")
        }
        .navigationTitle("Saved Replays")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteReplay(_ replay: SavedReplay) {
        // Delete the video file from disk
        if !replay.videoURLString.isEmpty {
            let url = URL(fileURLWithPath: replay.videoURLString)
            try? FileManager.default.removeItem(at: url)
        }
        modelContext.delete(replay)
        try? modelContext.save()
    }
}

struct SavedReplayPlaybackView: View {
    let replay: SavedReplay
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tracker = PoseTracker()
    @State private var player = AVPlayer()
    @State private var slowMotionEnabled = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    Button(action: {
                        player.pause()
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                            Text("Close")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                    }
                    Spacer()
                    Text(replay.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 50)

                if !replay.videoURLString.isEmpty {
                    let videoURL = URL(fileURLWithPath: replay.videoURLString)
                    if FileManager.default.fileExists(atPath: replay.videoURLString) {
                        GeometryReader { geo in
                            let containerWidth = geo.size.width
                            let videoHeight = containerWidth * (16.0 / 9.0)
                            let containerSize = CGSize(width: containerWidth, height: videoHeight)

                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black)
                                    .frame(width: containerWidth, height: videoHeight)

                                AVPlayerVideoWithOverlayView(
                                    player: player,
                                    tracker: tracker,
                                    videoURL: videoURL,
                                    hitType: replay.hitType,
                                    slowMotionEnabled: slowMotionEnabled,
                                    containerSize: containerSize
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
                            }
                            .frame(width: containerWidth, height: videoHeight)
                        }
                        .aspectRatio(9/16, contentMode: .fit)
                        .padding(.horizontal, 8)

                        // Slow motion toggle
                        HStack(spacing: 6) {
                            Text("Skeleton Overlay")
                                .font(.caption)
                                .foregroundColor(.white)
                            Toggle("", isOn: .constant(true))
                                .labelsHidden()
                                .scaleEffect(0.85)
                                .disabled(true)
                        }
                        .padding(.horizontal, 16)

                        // Playback controls
                        HStack(spacing: 24) {
                            Button(action: {
                                player.seek(to: .zero)
                                player.play()
                                player.rate = slowMotionEnabled ? 0.5 : 1.0
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            Button(action: {
                                if player.rate > 0 {
                                    player.pause()
                                } else {
                                    player.play()
                                    player.rate = slowMotionEnabled ? 0.5 : 1.0
                                }
                            }) {
                                Image(systemName: player.rate > 0 ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.yellow)
                            }
                            Button(action: {
                                player.seek(to: .zero)
                                player.play()
                                player.rate = slowMotionEnabled ? 0.5 : 1.0
                            }) {
                                Image(systemName: "backward.end.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.vertical, 12)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.yellow)
                            Text("Video file not found")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("This replay's video file may have been deleted.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "video.slash.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.gray)
                        Text("No video data")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)
                }

                // Stats section
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        SummaryMetricBox(title: "Ball Speed", val: String(format: "%.1f MPH", replay.ballSpeedMPH), color: .orange)
                        SummaryMetricBox(title: "Score", val: String(format: "%.0f Pts", replay.overallScore), color: .yellow)
                        if replay.hitType == "Spike" {
                            SummaryMetricBox(title: "Jump", val: String(format: "%.1f In", replay.jumpHeightInches), color: .green)
                        }
                    }
                    HStack(spacing: 6) {
                        SummaryMetricBox(title: "Launch", val: String(format: "%.1f°", replay.ballAngleDegrees), color: .cyan)
                        SummaryMetricBox(title: "Distance", val: String(format: "%.1f Ft", replay.ballDistanceFeet), color: .purple)
                        SummaryMetricBox(title: "Arm", val: String(format: "%.0f°", replay.armAngleDegrees), color: .blue)
                    }
                }
                .padding(.horizontal, 12)

                if !replay.coachFeedback.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .padding(.top, 2)
                        Text(replay.coachFeedback)
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

                Spacer()
            }
        }
        .onAppear {
            PortraitOrientation.lock()
        }
    }
}
