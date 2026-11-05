import SwiftUI
import UIKit

/// The fold on an iPhone Duo. Closed means the outer screen is in use; partially open is the
/// laptop or tent posture; fully open is the flat inner screen. Phones without a hinge stay unknown.
enum HingeStatus { case unknown, closed, partiallyOpen, fullyOpen }

@Observable
final class HingeMonitor {
    var status: HingeStatus = .unknown
    var angle: Double = 0
}

/// Invisible view that reports hinge changes into a HingeMonitor. Attach it as a background.
struct HingeObserver: UIViewRepresentable {
    let monitor: HingeMonitor

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.backgroundColor = .clear
        if #available(iOS 27.1, *) {
            let interaction = UIHingeInteraction { [monitor] _, update in
                guard let hinge = update.hinge else { monitor.status = .unknown; return }
                monitor.angle = Double(hinge.angle)
                switch hinge.status {
                case .closed: monitor.status = .closed
                case .partiallyOpen: monitor.status = .partiallyOpen
                case .fullyOpen: monitor.status = .fullyOpen
                default: monitor.status = .unknown
                }
            }
            v.addInteraction(interaction)
        }
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
