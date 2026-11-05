import SwiftUI
import SwiftData

/// Go-bags, car kits, pet bags: containers you can pick up and leave with.
struct KitsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Kit.sortOrder) private var kits: [Kit]
    @State private var showNew = false
    @State private var paywall: PaywallReason?

    var body: some View {
        List {
            if kits.isEmpty {
                ContentUnavailableView {
                    Label("No kits yet", systemImage: "backpack")
                } description: {
                    Text("A go-bag is three days you can carry. Start from a list and pack what you already own.")
                } actions: {
                    Button { addKit() } label: { Label("Start a kit", systemImage: "plus") }.buttonStyle(.borderedProminent)
                }
            } else {
                Section {
                    ForEach(kits, id: \.uuid) { kit in
                        NavigationLink { KitDetailView(kit: kit) } label: { KitRow(kit: kit) }
                            .swipeActions {
                                Button(role: .destructive) { delete(kit) } label: { Label("Delete", systemImage: "trash") }
                            }
                    }
                    Button { addKit() } label: { Label("Add a kit", systemImage: "plus") }
                } footer: {
                    Text("Items in a kit are still supplies: they count toward readiness and get the same expiration reminders. Deleting a kit keeps its items.")
                }
            }
        }
        .navigationTitle("Kits")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNew) { KitNewView() }
        .sheet(item: $paywall) { PaywallView(reason: $0).tint(Color.ink) }
    }

    private func addKit() {
        guard PlanStore.shared.canAddKit(currentCount: kits.count) else {
            paywall = .feature("More than one kit")
            return
        }
        showNew = true
    }

    private func delete(_ kit: Kit) {
        for item in kit.items { item.kit = nil }
        context.delete(kit)
        try? context.save()
    }
}

struct KitRow: View {
    let kit: Kit
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: kit.kind.symbol).foregroundStyle(Color.ink).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(kit.name)
                Text(subtitle).font(.caption).foregroundStyle(kit.checkIsDue ? Color.ember : Color.secondary)
            }
            Spacer()
            let n = kit.attentionCount()
            if n > 0 {
                Text("\(n)").font(.caption.weight(.semibold)).padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Capsule().fill(Color.ember.opacity(0.18))).foregroundStyle(Color.ember)
                    .accessibilityLabel("\(n) \(n == 1 ? "item" : "items") to check")
            }
        }
    }
    private var subtitle: String {
        let count = kit.activeItems.count
        let items = count == 1 ? "1 item" : "\(count) items"
        if let last = kit.lastCheckedAt {
            return "\(items) · checked \(last.formatted(.relative(presentation: .named)))"
        }
        return "\(items) · never checked"
    }
}

/// Pick a template or start empty.
struct KitNewView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Kit.sortOrder) private var kits: [Kit]
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]
    @Query private var existingItems: [SupplyItem]
    @State private var selected: KitTemplate?
    @State private var name = ""
    @State private var kind: KitKind = .goBag
    @State private var location: StorageLocation?
    @State private var addAllLines = true
    private let library = KitLibrary.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(library.templates) { t in
                        Button {
                            selected = t
                            name = t.name
                            kind = t.kitKind
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: t.kitKind.symbol).foregroundStyle(Color.ink).frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.name).foregroundStyle(.primary)
                                    Text(t.summary).font(.caption).foregroundStyle(.secondary)
                                    Text("\(t.items.count) items · \(t.source)").font(.caption2).foregroundStyle(.tertiary)
                                }
                                Spacer()
                                if selected?.key == t.key { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.ink) }
                            }
                        }
                    }
                    Button {
                        selected = nil
                        if name.isEmpty || library.templates.contains(where: { $0.name == name }) { name = "" }
                    } label: {
                        HStack {
                            Image(systemName: "bag").foregroundStyle(.secondary).frame(width: 28)
                            Text("Start empty").foregroundStyle(.primary)
                            Spacer()
                            if selected == nil { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.ink) }
                        }
                    }
                } header: { Text("Start from") }

                Section("Details") {
                    TextField("Name (e.g. Hall closet go-bag)", text: $name)
                    Picker("Kind", selection: $kind) { ForEach(KitKind.allCases) { Text($0.title).tag($0) } }
                    Picker("Kept at", selection: $location) {
                        Text("Not set").tag(Optional<StorageLocation>.none)
                        ForEach(locations) { loc in Text(loc.name).tag(Optional(loc)) }
                    }
                    if selected != nil {
                        Toggle("Add every item on the list now", isOn: $addAllLines)
                    }
                }
            }
            .navigationTitle("New kit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { if selected == nil, let first = library.templates.first { selected = first; name = first.name; kind = first.kitKind } }
        }
    }

    private func create() {
        let kit = Kit(name: name.trimmingCharacters(in: .whitespaces), kind: kind, templateKey: selected?.key)
        kit.sortOrder = kits.count
        kit.notes = location?.name ?? ""
        context.insert(kit)
        if let t = selected, addAllLines {
            let room = PlanStore.shared.plan.isPaid ? Int.max : max(0, PlanStore.freeItemLimit - existingItems.count)
            for line in t.items.prefix(room) { context.insert(SeedData.makeItem(from: line, location: location, kit: kit)) }
            if t.items.count > room { PlanStore.shared.pendingPaywall = .itemLimit }
        }
        try? context.save()
        dismiss()
    }
}
