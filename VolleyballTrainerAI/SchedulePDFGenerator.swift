import SwiftUI
import UIKit

/// Shared block info used to render a schedule for both practices and training plans.
struct ScheduleBlockInfo {
    let name: String
    let durationMinutes: Int
    let categoryName: String
    let color: UIColor
    let isWaterBreak: Bool
}

/// Identifiable wrapper used with .sheet(item:) to atomically pass data to the
/// preview sheet, preventing the "blank on first open" issue.
struct SchedulePreviewData: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let blocks: [ScheduleBlockInfo]
}

/// A native SwiftUI representation of the schedule. Uses flexible width for the
/// in-app preview, and can be rendered into an export image at a fixed size.
struct ScheduleExportView: View {
    let title: String
    let subtitle: String
    let blocks: [ScheduleBlockInfo]

    private static let pink = Color(red: 1.0, green: 0.08, blue: 0.58)
    private static let darkBg = Color(red: 0.07, green: 0.07, blue: 0.09)
    private static let cardBg = Color(red: 0.14, green: 0.14, blue: 0.16)

    /// When non-nil, the view is laid out at this fixed width (used for image export).
    var exportWidth: CGFloat? = nil

    var body: some View {
        let total = blocks.reduce(0) { $0 + $1.durationMinutes }
        let nonWB = blocks.filter { !$0.isWaterBreak }
        let cats = Dictionary(grouping: nonWB, by: { $0.categoryName })
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value.count) (\($0.value.reduce(0) { $0 + $1.durationMinutes }) min)" }
            .joined(separator: "    •    ")

        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)

            Text("Total Time: \(total) min   |   \(nonWB.count) blocks")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ScheduleExportView.pink)

            if !cats.isEmpty {
                Text(cats)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().background(Color.gray.opacity(0.4))

            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                if block.isWaterBreak {
                    Text("💧  WATER BREAK — \(block.durationMinutes) MIN")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ScheduleExportView.pink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(ScheduleExportView.pink.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(ScheduleExportView.pink, lineWidth: 1.5))
                } else {
                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(block.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text(block.categoryName)
                                .font(.system(size: 10))
                                .foregroundColor(Color(block.color))
                        }
                        Spacer(minLength: 8)
                        Text("\(block.durationMinutes) min")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    .padding(8)
                    .background(ScheduleExportView.cardBg)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(block.color).opacity(0.6), lineWidth: 1))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: exportWidth, alignment: .topLeading)
        .background(ScheduleExportView.darkBg)
    }
}

/// Renders the schedule into a UIImage for export (Share sheet / Photos).
@MainActor
extension ScheduleExportView {
    static func renderImage(title: String, subtitle: String, blocks: [ScheduleBlockInfo]) -> UIImage {
        let view = ScheduleExportView(title: title, subtitle: subtitle, blocks: blocks, exportWidth: 612)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        renderer.isOpaque = true  // dark background is solid, no alpha channel needed
        return renderer.uiImage ?? UIImage()
    }
}

/// An in-app preview of the schedule (responsive width). The Share button
/// uses a pre-rendered image to avoid UI freezes.
struct SchedulePreview: View {
    let title: String
    let subtitle: String
    let blocks: [ScheduleBlockInfo]

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                ScheduleExportView(title: title, subtitle: subtitle, blocks: blocks)
                    .cornerRadius(12)
                    .padding(8)
            }
            .background(Color(red: 0.07, green: 0.07, blue: 0.09).ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: shareTapped) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(shareImage == nil)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ActivityView(activityItems: [image])
                }
            }
            .task {
                // Pre-render the image off the critical path so it's ready when
                // the user taps share.  This also prevents the first-open blank
                // issue by giving the layout a moment to settle.
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                let img = await MainActor.run {
                    ScheduleExportView.renderImage(title: title, subtitle: subtitle, blocks: blocks)
                }
                // Only use the image if it has actual content
                if img.size.width > 0 && img.size.height > 0 {
                    shareImage = img
                }
            }
        }
    }

    private func shareTapped() {
        // If pre-rendered image is ready, present the share sheet immediately.
        // Otherwise render synchronously (fallback).
        if shareImage == nil {
            Task { @MainActor in
                let img = ScheduleExportView.renderImage(title: title, subtitle: subtitle, blocks: blocks)
                if img.size.width > 0 && img.size.height > 0 {
                    shareImage = img
                }
                showShareSheet = true
            }
        } else {
            showShareSheet = true
        }
    }
}