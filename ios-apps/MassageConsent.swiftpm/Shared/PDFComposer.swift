// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import PDFKit
import SwiftUI
import UIKit

/// Builds a simple multi-page, bilingual PDF record of a completed form.
final class PDFComposer {
    struct SignatureBox {
        var title: String
        var image: UIImage?
        var name: String
        var date: String
    }

    private enum Block {
        case text(NSAttributedString, spaceAfter: CGFloat)
        case rule
        case space(CGFloat)
        case signatures([SignatureBox])
    }

    private let pageSize = CGSize(width: 612, height: 792) // US Letter
    private let margin: CGFloat = 50
    private let footer: String
    private var blocks: [Block] = []

    private var contentWidth: CGFloat { pageSize.width - margin * 2 }

    private let bodyFont = UIFont.systemFont(ofSize: 10.5)
    private let englishFont = UIFont.italicSystemFont(ofSize: 9.5)

    init(footer: String) {
        self.footer = footer
    }

    // MARK: - Building

    func title(_ text: String) {
        append(text, font: .systemFont(ofSize: 22, weight: .bold), alignment: .center, after: 4)
    }

    func subtitle(_ text: String) {
        append(text, font: .systemFont(ofSize: 12, weight: .medium), color: .darkGray, alignment: .center, after: 4)
    }

    func heading(_ number: Int, _ l: L) {
        blocks.append(.space(8))
        append("\(number). \(l.both)", font: .systemFont(ofSize: 13, weight: .semibold), after: 6)
    }

    func field(_ label: L, _ value: String) {
        let s = NSMutableAttributedString(
            string: label.both + ": ",
            attributes: [.font: UIFont.systemFont(ofSize: 10.5, weight: .semibold), .foregroundColor: UIColor.darkGray]
        )
        s.append(NSAttributedString(
            string: value.trimmed.isEmpty ? "—" : value,
            attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.black]
        ))
        blocks.append(.text(s, spaceAfter: 5))
    }

    /// Vietnamese line with the English translation below it.
    func bilingual(_ l: L, prefix: String? = nil) {
        let indent: CGFloat = prefix == nil ? 0 : 18
        let para = NSMutableParagraphStyle()
        para.headIndent = indent
        para.tabStops = [NSTextTab(textAlignment: .left, location: indent)]
        para.lineSpacing = 1.5
        let tab = prefix == nil ? "" : "\t"

        let s = NSMutableAttributedString()
        if let prefix {
            s.append(NSAttributedString(string: prefix + "\t", attributes: [.font: bodyFont, .paragraphStyle: para]))
        }
        s.append(NSAttributedString(
            string: l.vi,
            attributes: [.font: bodyFont, .foregroundColor: UIColor.black, .paragraphStyle: para]
        ))
        if l.en != l.vi {
            s.append(NSAttributedString(
                string: "\n" + tab + l.en,
                attributes: [.font: englishFont, .foregroundColor: UIColor.darkGray, .paragraphStyle: para]
            ))
        }
        blocks.append(.text(s, spaceAfter: 5))
    }

    func bullet(_ l: L) { bilingual(l, prefix: "•") }

    func check(_ checked: Bool, _ l: L) { bilingual(l, prefix: checked ? "☑" : "☐") }

    func alert(_ text: String) {
        append("⚠︎ " + text, font: .systemFont(ofSize: 10.5, weight: .semibold), color: .systemRed, after: 6)
    }

    func rule() { blocks.append(.rule) }

    func space(_ height: CGFloat) { blocks.append(.space(height)) }

    func signatures(_ boxes: [SignatureBox]) { blocks.append(.signatures(boxes)) }

    private func append(
        _ text: String,
        font: UIFont,
        color: UIColor = .black,
        alignment: NSTextAlignment = .left,
        after: CGFloat
    ) {
        let para = NSMutableParagraphStyle()
        para.alignment = alignment
        blocks.append(.text(
            NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: para]),
            spaceAfter: after
        ))
    }

    // MARK: - Rendering

    func render() -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        return renderer.pdfData { context in
            var page = 0
            var y: CGFloat = 0

            func newPage() {
                context.beginPage()
                page += 1
                y = margin
                let footerText = NSAttributedString(
                    string: "\(footer)   ·   \(page)",
                    attributes: [.font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.gray]
                )
                footerText.draw(at: CGPoint(x: margin, y: pageSize.height - margin / 2 - 8))
            }

            func ensureRoom(_ height: CGFloat) {
                if y + height > pageSize.height - margin { newPage() }
            }

            newPage()

            for block in blocks {
                switch block {
                case let .text(string, after):
                    let height = ceil(string.boundingRect(
                        with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        context: nil
                    ).height)
                    ensureRoom(height)
                    string.draw(
                        with: CGRect(x: margin, y: y, width: contentWidth, height: height),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        context: nil
                    )
                    y += height + after

                case let .space(height):
                    y += height

                case .rule:
                    ensureRoom(12)
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: margin, y: y + 4))
                    path.addLine(to: CGPoint(x: pageSize.width - margin, y: y + 4))
                    path.lineWidth = 0.5
                    UIColor.lightGray.setStroke()
                    path.stroke()
                    y += 12

                case let .signatures(boxes):
                    guard !boxes.isEmpty else { break }
                    let boxHeight: CGFloat = 140
                    ensureRoom(boxHeight)
                    let gap: CGFloat = 30
                    let width = (contentWidth - gap * CGFloat(boxes.count - 1)) / CGFloat(boxes.count)
                    let labelAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.darkGray,
                    ]
                    let valueAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.black,
                    ]
                    for (index, box) in boxes.enumerated() {
                        let x = margin + CGFloat(index) * (width + gap)
                        NSAttributedString(string: box.title, attributes: labelAttributes)
                            .draw(with: CGRect(x: x, y: y, width: width, height: 28),
                                  options: [.usesLineFragmentOrigin], context: nil)
                        let imageArea = CGRect(x: x, y: y + 28, width: width, height: 70)
                        if let image = box.image {
                            image.draw(in: aspectFit(image.size, in: imageArea))
                        }
                        let line = UIBezierPath()
                        line.move(to: CGPoint(x: x, y: imageArea.maxY + 2))
                        line.addLine(to: CGPoint(x: x + width, y: imageArea.maxY + 2))
                        line.lineWidth = 0.75
                        UIColor.gray.setStroke()
                        line.stroke()
                        NSAttributedString(string: box.name, attributes: valueAttributes)
                            .draw(at: CGPoint(x: x, y: imageArea.maxY + 6))
                        NSAttributedString(string: "Ngày / Date: \(box.date)", attributes: valueAttributes)
                            .draw(at: CGPoint(x: x, y: imageArea.maxY + 20))
                    }
                    y += boxHeight
                }
            }
        }
    }

    /// Fits the image inside `rect`, anchored bottom-left so it sits on the signature line.
    private func aspectFit(_ size: CGSize, in rect: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return rect }
        let scale = min(rect.width / size.width, rect.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(x: rect.minX, y: rect.maxY - fitted.height, width: fitted.width, height: fitted.height)
    }
}

extension Optional where Wrapped == Data {
    var image: UIImage? { flatMap { UIImage(data: $0) } }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.backgroundColor = .secondarySystemBackground
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if view.document?.documentURL != url {
            view.document = PDFDocument(url: url)
        }
    }
}

enum Printer {
    static func printFile(at url: URL, jobName: String) {
        let info = UIPrintInfo(dictionary: nil)
        info.jobName = jobName
        info.outputType = .general
        let controller = UIPrintInteractionController.shared
        controller.printInfo = info
        controller.printingItem = url
        _ = controller.present(animated: true, completionHandler: nil)
    }
}
