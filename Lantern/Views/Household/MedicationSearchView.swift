import SwiftUI

/// Pick a medication from the built-in list. Searches generic, brand and purpose, tolerates misspellings.
struct MedicationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    let onPick: (MedicationEntry) -> Void
    @State private var query = ""
    private let library = MedicationLibrary.shared

    private var results: [MedicationEntry] { library.search(query) }

    var body: some View {
        NavigationStack {
            List {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    ForEach(results) { e in
                        Button { onPick(e); dismiss() } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(e.generic).foregroundStyle(.primary)
                                    if e.critical { Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Color.ember).font(.caption) }
                                }
                                Text([e.brands.prefix(3).joined(separator: ", "), e.purpose].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Name, brand or what it's for")
            .navigationTitle("Find a medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
