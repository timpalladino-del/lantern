import SwiftUI
import SwiftData

struct KitDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var kit: Kit
    @Query(sort: \SupplyItem.name) private var allItems: [SupplyItem]
    private var allItemCount: Int { allItems.count }
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]
    @State private var showPicker = false
    @State private var paywall: PaywallReason?
    @State private var showAdd = false
    @State private var checkedCount = 0
    private let library = KitLibrary.shared

    private var template: KitTemplate? { library.template(kit.templateKey) }
    private var missing: [StarterPackItem] { template.map { KitLibrary.missing(from: $0, in: kit) } ?? [] }
    private var packed: [SupplyItem] { kit.items.sorted { $0.name < $1.name } }

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: kit.kind.symbol).font(.title2).foregroundStyle(Color.ink).frame(width: 36)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(kit.kind.title).font(.subheadline.weight(.semibold))
                        Text(kit.lastCheckedAt.map { "Checked \($0.formatted(.relative(presentation: .named)))" } ?? "Never checked")
                            .font(.caption).foregroundStyle(kit.checkIsDue ? Color.ember : Color.secondary)
                    }
                    Spacer()
                    Button {
                        kit.lastCheckedAt = Date()
                        for item in kit.items { item.lastCheckedAt = Date() }
                        checkedCount += 1
                        try? context.save()
                    } label: { Label("Checked", systemImage: "checkmark.circle") }
                    .buttonStyle(.bordered)
                }
                TextField("Where it lives (e.g. hall closet, trunk)", text: $kit.notes)
            }

            Section {
                if packed.isEmpty {
                    Text("Nothing packed yet.").foregroundStyle(.secondary)
                }
                ForEach(packed) { item in
                    NavigationLink { ItemDetailView(item: item) } label: { ItemRow(item: item) }
                        .swipeActions(edge: .trailing) {
                            Button { item.kit = nil; try? context.save() } label: { Label("Take out", systemImage: "arrow.up.bin") }.tint(.gray)
                        }
                }
                Button { showPicker = true } label: { Label("Pack something you already have", systemImage: "shippingbox") }
                Button { showAdd = true } label: { Label("Add a new item to the kit", systemImage: "plus") }
            } header: { Text("Packed (\(packed.count))") }

            if !missing.isEmpty {
                Section {
                    ForEach(missing, id: \.self) { line in
                        Button {
                            guard PlanStore.shared.canAddItem(currentCount: allItemCount) else { paywall = .itemLimit; return }
                            context.insert(SeedData.makeItem(from: line, location: locations.first { $0.name == kit.notes }, kit: kit))
                            try? context.save()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle").foregroundStyle(Color.ink)
                                Text(line.name).foregroundStyle(.primary)
                                Spacer()
                                Text("\(Int(line.quantity)) \(line.unit)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: { Text("Still missing from the \(template?.name ?? "list")") } footer: {
                    Text("Tap to add one with today's date. Edit the quantity afterwards to match what you packed.")
                }
            }
        }
        .navigationTitle(kit.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $paywall) { PaywallView(reason: $0).tint(Color.ink) }
        .sheet(isPresented: $showPicker) { KitPickItemsView(kit: kit) }
        .sheet(isPresented: $showAdd) {
            ItemEditView(draft: ItemDraft(location: locations.first { $0.name == kit.notes })) { item in item.kit = kit; try? context.save() }
        }
        .sensoryFeedback(.success, trigger: checkedCount)
    }
}

/// Choose existing supplies to move into the kit.
struct KitPickItemsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let kit: Kit
    @Query(sort: \SupplyItem.name) private var items: [SupplyItem]
    @State private var query = ""
    @State private var chosen: Set<UUID> = []

    private var candidates: [SupplyItem] {
        let base = items.filter { $0.kit == nil && $0.quantity > 0 }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty ? base : base.filter { $0.name.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            List(candidates) { item in
                Button {
                    if chosen.contains(item.uuid) { chosen.remove(item.uuid) } else { chosen.insert(item.uuid) }
                } label: {
                    HStack {
                        ItemRow(item: item)
                        Spacer()
                        Image(systemName: chosen.contains(item.uuid) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(chosen.contains(item.uuid) ? Color.ink : Color.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }
            .searchable(text: $query)
            .navigationTitle("Pack from supplies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pack \(chosen.count)") {
                        for item in items where chosen.contains(item.uuid) { item.kit = kit }
                        try? context.save()
                        dismiss()
                    }.disabled(chosen.isEmpty)
                }
            }
        }
    }
}
