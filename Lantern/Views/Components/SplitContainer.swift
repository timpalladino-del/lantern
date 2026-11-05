import SwiftUI

/// Two columns when the window is wide (the iPhone Duo open, an iPad), one column otherwise.
/// Push links in the sidebar open in the detail column; on a narrow screen they push as before.
struct SplitContainer<Sidebar: View, Detail: View>: View {
    @ViewBuilder var sidebar: () -> Sidebar
    @ViewBuilder var detail: () -> Detail

    var body: some View {
        NavigationSplitView {
            sidebar()
                // Wide enough for a supply row with its badge; the detail keeps the rest.
                .navigationSplitViewColumnWidth(min: 300, ideal: 330, max: 400)
        } detail: {
            detail()
        }
        .navigationSplitViewStyle(.balanced)
    }
}

/// What the detail column shows before anything is chosen.
struct DetailPlaceholder: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(text)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

/// Promotes a wide window to the regular width class, so split views open two columns and the
/// tab bar takes its wide form. 600 points catches the open iPhone Duo (669) and every iPad.
struct WideWindowSizeClass: ViewModifier {
    static let threshold: CGFloat = 600
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .transformEnvironment(\.horizontalSizeClass) { cls in
                    if geo.size.width >= WideWindowSizeClass.threshold { cls = .regular }
                }
        }
    }
}

extension View {
    func wideWindowSizeClass() -> some View { modifier(WideWindowSizeClass()) }
}
