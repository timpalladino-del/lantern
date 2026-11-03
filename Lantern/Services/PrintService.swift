import Foundation
import UIKit

/// Letter-size PDFs for the binder and the fridge door.
enum PrintService {
    struct Section {
        let heading: String
        let lines: [String]
    }

    static func makePDF(title: String, subtitle: String, sections: [Section], filename: String) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 54
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let subFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let headFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                var y = margin
                func draw(_ text: String, font: UIFont, color: UIColor = .black, spacingAfter: CGFloat = 6) {
                    let para = NSMutableParagraphStyle()
                    para.lineBreakMode = .byWordWrapping
                    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: para]
                    let width = pageRect.width - 2 * margin
                    let bounds = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                                 options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                                 attributes: attrs, context: nil)
                    if y + bounds.height > pageRect.height - margin {
                        ctx.beginPage()
                        y = margin
                    }
                    (text as NSString).draw(in: CGRect(x: margin, y: y, width: width, height: bounds.height), withAttributes: attrs)
                    y += bounds.height + spacingAfter
                }
                draw(title, font: titleFont, spacingAfter: 2)
                draw(subtitle, font: subFont, color: .darkGray, spacingAfter: 18)
                for s in sections {
                    draw(s.heading, font: headFont, spacingAfter: 4)
                    for line in s.lines where !line.isEmpty { draw(line, font: bodyFont, spacingAfter: 3) }
                    y += 10
                }
                draw("Printed from Lantern on \(Date().formatted(date: .long, time: .omitted)). Keep a copy on the fridge and one in the go-bag.", font: subFont, color: .gray)
            }
            return url
        } catch {
            return nil
        }
    }
}
