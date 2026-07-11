import SwiftUI
import UIKit
import PDFKit

/// Shared block info used to render a schedule PDF for both practices and training plans.
struct ScheduleBlockInfo {
    let name: String
    let durationMinutes: Int
    let categoryName: String
    let color: UIColor
    let isWaterBreak: Bool
}

/// Generates a nicely formatted PDF schedule with a logo watermark, pink-outlined
/// water breaks, a category summary, and total time.
struct SchedulePDFGenerator {

    static let pink = UIColor(red: 1.0, green: 0.08, blue: 0.58, alpha: 1.0)
    static let darkBg = UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1.0)
    static let cardBg = UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)

    static func generate(
        title: String,
        subtitle: String,
        blocks: [ScheduleBlockInfo]
    ) -> Data {
        let pageWidth: CGFloat = 612  // US Letter
        let margin: CGFloat = 40
        let contentWidth = pageWidth - margin * 2

        let estimated = estimatedHeight(blocks: blocks)
        let pageHeight: CGFloat = max(792, estimated + 120)

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        UIGraphicsBeginPDFPage()

        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            return Data()
        }

        // Push UIKit context so NSString.draw works
        UIGraphicsPushContext(context)

        drawBackground(rect: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        var y: CGFloat = margin

        // Title
        y = drawText(text: title, rect: CGRect(x: margin, y: y, width: contentWidth, height: 30),
                     font: .boldSystemFont(ofSize: 22), color: .white, alignment: .left)
        y += 4
        y = drawText(text: subtitle, rect: CGRect(x: margin, y: y, width: contentWidth, height: 18),
                     font: .systemFont(ofSize: 12), color: UIColor.lightGray, alignment: .left)
        y += 14

        // Summary box
        let totalMinutes = blocks.reduce(0) { $0 + $1.durationMinutes }
        let categories = Dictionary(grouping: blocks.filter { !$0.isWaterBreak }, by: { $0.categoryName })
        let summaryLines = categories.map { "\($0.key): \($0.value.count) (\($0.value.reduce(0) { $0 + $1.durationMinutes }) min)" }
            .sorted()

        let summaryTitle = "Total Time: \(totalMinutes) min   |   \(blocks.filter { !$0.isWaterBreak }.count) blocks"
        y = drawText(text: summaryTitle, rect: CGRect(x: margin, y: y, width: contentWidth, height: 20),
                     font: .boldSystemFont(ofSize: 13), color: pink, alignment: .left)
        y += 6

        let summaryText = summaryLines.joined(separator: "    •    ")
        y = drawWrappedText(text: summaryText.isEmpty ? "Mixed" : summaryText,
                            rect: CGRect(x: margin, y: y, width: contentWidth, height: 60),
                            font: .systemFont(ofSize: 11), color: .white, alignment: .left)
        y += 10

        // Divider
        context.setStrokeColor(UIColor.gray.withAlphaComponent(0.4).cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: margin + contentWidth, y: y))
        context.strokePath()
        y += 14

        // Blocks
        for block in blocks {
            let rowHeight: CGFloat = block.isWaterBreak ? 34 : 52
            let innerRect = CGRect(x: margin, y: y, width: contentWidth, height: rowHeight)

            if block.isWaterBreak {
                // Pink outlined water break
                context.setFillColor(pink.withAlphaComponent(0.12).cgColor)
                roundedRect(rect: innerRect, radius: 8, fill: true)
                context.setStrokeColor(pink.cgColor)
                context.setLineWidth(1.5)
                roundedRect(rect: innerRect, radius: 8, fill: false)

                let label = "💧  WATER BREAK — \(block.durationMinutes) MIN"
                drawText(text: label,
                         rect: CGRect(x: margin + 10, y: y + (rowHeight - 16) / 2, width: contentWidth - 20, height: 16),
                         font: .boldSystemFont(ofSize: 13), color: pink, alignment: .left)
            } else {
                context.setFillColor(cardBg.cgColor)
                roundedRect(rect: innerRect, radius: 8, fill: true)
                context.setStrokeColor(block.color.withAlphaComponent(0.6).cgColor)
                context.setLineWidth(1)
                roundedRect(rect: innerRect, radius: 8, fill: false)

                drawText(text: block.name,
                         rect: CGRect(x: margin + 10, y: y + 8, width: contentWidth - 110, height: 20),
                         font: .boldSystemFont(ofSize: 13), color: .white, alignment: .left)
                drawText(text: "\(block.categoryName)",
                         rect: CGRect(x: margin + 10, y: y + 30, width: contentWidth - 110, height: 14),
                         font: .systemFont(ofSize: 10), color: block.color, alignment: .left)
                drawText(text: "\(block.durationMinutes) min",
                         rect: CGRect(x: margin + contentWidth - 90, y: y + (rowHeight - 16) / 2, width: 80, height: 16),
                         font: .boldSystemFont(ofSize: 13), color: UIColor.lightGray, alignment: .right)
            }

            y += rowHeight + 8
        }

        // Watermark logo (drawn last, faint)
        drawWatermark(pageRect: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        UIGraphicsPopContext()
        UIGraphicsEndPDFContext()

        return pdfData as Data
    }

    // MARK: - Drawing Helpers

    private static func drawBackground(rect: CGRect) {
        darkBg.setFill()
        UIRectFill(rect)
    }

    private static func drawWatermark(pageRect: CGRect) {
        guard let logo = UIImage(named: "AppIcon") ?? UIImage(named: "icon") else { return }
        let size = min(pageRect.width, pageRect.height) * 0.55
        let x = (pageRect.width - size) / 2
        let y = (pageRect.height - size) / 2
        logo.draw(in: CGRect(x: x, y: y, width: size, height: size), blendMode: .normal, alpha: 0.08)
    }

    private static func estimatedHeight(blocks: [ScheduleBlockInfo]) -> CGFloat {
        let base: CGFloat = 200
        let rows = blocks.reduce(CGFloat(0)) { $0 + ($1.isWaterBreak ? 42 : 60) }
        return base + rows
    }

    private static func roundedRect(rect: CGRect, radius: CGFloat, fill: Bool) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        if fill { path.fill() } else { path.stroke() }
    }

    @discardableResult
    private static func drawText(text: String, rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        (text as NSString).draw(in: rect, withAttributes: attrs)
        return rect.origin.y + rect.height
    }

    private static func drawWrappedText(text: String, rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        (text as NSString).draw(in: rect, withAttributes: attrs)
        return rect.origin.y + rect.height
    }
}