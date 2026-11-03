import SwiftUI

/// Wraps a URL so it can drive `.sheet(item:)`.
struct ShareableFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct FileShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    let file: ShareableFile
    var title: String = "Ready to print or save"

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.richtext").font(.system(size: 40)).foregroundStyle(.secondary)
                Text(file.url.lastPathComponent).font(.headline)
                Text(title).font(.subheadline).foregroundStyle(.secondary)
                ShareLink(item: file.url) { Label("Share, print or save", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium])
    }
}
