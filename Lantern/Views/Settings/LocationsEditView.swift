import SwiftUI
import SwiftData
import UIKit

/// Every place supplies live. Tap one to edit it, add notes, a photo, an address or coordinates.
struct LocationsEditView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]
    @State private var editing: StorageLocation?
    @State private var adding = false
    @State private var addingTo: StorageLocation?

    private var atHome: [StorageLocation] { locations.filter { !$0.isAwayFromHome } }
    private var away: [StorageLocation] { locations.filter(\.isAwayFromHome) }

    var body: some View {
        List {
            if locations.isEmpty {
                ContentUnavailableView {
                    Label("No locations yet", systemImage: "mappin.and.ellipse")
                } description: {
                    Text("Add the pantry, the garage shelf, the car, the go-bag. A supply you cannot walk to is not useful.")
                } actions: {
                    Button { adding = true } label: { Label("Add a location", systemImage: "plus") }.buttonStyle(.borderedProminent)
                }
            }
            if !atHome.isEmpty {
                Section("In the house") { ForEach(atHome, id: \.uuid) { row($0) }.onMove(perform: move) }
            }
            if !away.isEmpty {
                Section {
                    ForEach(away, id: \.uuid) { row($0) }.onMove(perform: move)
                } header: { Text("Away from home") } footer: {
                    Text("Places with an address or coordinates. Open in Maps from the location.")
                }
            }
        }
        .navigationTitle("Locations")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add a location")
            }
            ToolbarItem(placement: .topBarLeading) { EditButton() }
        }
        .sheet(item: $editing) { loc in LocationEditView(location: loc) }
        .sheet(isPresented: $adding) { LocationEditView() }
        .sheet(item: $addingTo) { loc in ItemEditView(draft: ItemDraft(location: loc)) }
    }

    private func row(_ loc: StorageLocation) -> some View {
        Button { editing = loc } label: {
            HStack(spacing: 12) {
                if let data = loc.photo, let img = UIImage(data: data) {
                    Image(uiImage: img).resizable().scaledToFill().frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: loc.symbol).frame(width: 40, height: 40).foregroundStyle(Color.ink)
                        .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.name).foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        Text("\(loc.items.count) \(loc.items.count == 1 ? "item" : "items")")
                        if !loc.notes.isEmpty { Text("·"); Text(loc.notes).lineLimit(1) }
                        if loc.point != nil { Text("·"); Image(systemName: "mappin.and.ellipse") }
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .swipeActions(edge: .trailing) {
            Button { addingTo = loc } label: { Label("Add supply", systemImage: "plus") }.tint(Color.ink)
        }
    }

    private func move(from: IndexSet, to: Int) {
        var list = locations
        list.move(fromOffsets: from, toOffset: to)
        for (i, l) in list.enumerated() { l.sortOrder = i }
        try? context.save()
    }
}
