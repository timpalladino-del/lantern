import SwiftUI
import SwiftData

struct SuppliesListView: View {
    enum SortMode: String, CaseIterable, Identifiable {
        case date = "By date", name = "By name", location = "By location"
        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var context
    @Query(sort: \SupplyItem.name) private var items: [SupplyItem]
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]
    @Query(sort: \Kit.sortOrder) private var kits: [Kit]

    @State private var searchText = ""
    @State private var category: SupplyCategory?
    @State private var sortMode: SortMode = .date
    @State private var showScanner = false
    @State private var showAdd = false
    @State private var showPacks = false
    @State private var showShopping = false
    @State private var showOut = true
    @State private var usedCount = 0
    @State private var editMode: EditMode = .inactive
    @State private var selection: Set<PersistentIdentifier> = []
    @State private var confirmDelete = false

    private var now: Date { Date() }

    private var filtered: [SupplyItem] {
        var list = items
        if let category { list = list.filter { $0.category == category } }
        if !showOut { list = list.filter { $0.quantity > 0 } }
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter { $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) || ($0.location?.name.lowercased().contains(q) ?? false) }
        }
        switch sortMode {
        case .name:
            return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .date, .location:
            return list.sorted { a, b in
                let sa = a.status(on: now), sb = b.status(on: now)
                if sa.sortRank != sb.sortRank { return sa.sortRank < sb.sortRank }
                let da = a.daysUntilExpiration(from: now) ?? Int.max
                let db = b.daysUntilExpiration(from: now) ?? Int.max
                if da != db { return da < db }
                return a.name < b.name
            }
        }
    }

    private var groupedByLocation: [(String, [SupplyItem])] {
        let groups = Dictionary(grouping: filtered) { $0.location?.name ?? "No location" }
        let order = locations.map(\.name) + ["No location"]
        return order.compactMap { name in
            guard let g = groups[name], !g.isEmpty else { return nil }
            return (name, g)
        }
    }

    var body: some View {
        SplitContainer {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Supplies")
            .searchable(text: $searchText, prompt: "Search supplies")
            .environment(\.editMode, $editMode)
            .safeAreaInset(edge: .bottom) {
                if editMode.isEditing { actionBar }
            }
            .toolbar {
                if editMode.isEditing {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(selection.count == filtered.count ? "Deselect all" : "Select all") {
                            if selection.count == filtered.count { selection.removeAll() } else { selection = Set(filtered.map(\.persistentModelID)) }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { withAnimation { editMode = .inactive; selection.removeAll() } }.fontWeight(.semibold)
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !editMode.isEditing {
                    Button { showScanner = true } label: { Image(systemName: "barcode.viewfinder") }
                        .accessibilityLabel("Scan a barcode")
                    Menu {
                        Button { withAnimation { editMode = .active } } label: { Label("Select items", systemImage: "checkmark.circle") }
                        Button { showAdd = true } label: { Label("Add by hand", systemImage: "plus") }
                        Button { showPacks = true } label: { Label("Add a starter pack", systemImage: "list.bullet.rectangle") }
                        NavigationLink { KitsView() } label: { Label("Kits and go-bags", systemImage: "backpack") }
                        Button { showShopping = true } label: { Label("Shopping list", systemImage: "cart") }
                        Divider()
                        Picker("Sort", selection: $sortMode) {
                            ForEach(SortMode.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Toggle("Show used-up items", isOn: $showOut)
                    } label: { Image(systemName: "ellipsis.circle") }
                    .accessibilityLabel("More options")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !editMode.isEditing {
                    Menu {
                        Button("All categories") { category = nil }
                        ForEach(SupplyCategory.allCases) { c in
                            Button { category = c } label: { Label(c.title, systemImage: c.symbol) }
                        }
                    } label: {
                        Label(category?.title ?? "All", systemImage: category?.symbol ?? "line.3.horizontal.decrease.circle")
                    }
                    }
                }
            }
            .confirmationDialog("Delete \(selection.count) item\(selection.count == 1 ? "" : "s")?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteSelected() }
            } message: {
                Text("They come off readiness and the shopping list is not touched.")
            }
            .sheet(isPresented: $showScanner) { ScanSheet() }
            .sheet(isPresented: $showAdd) { ItemEditView() }
            .sheet(isPresented: $showPacks) { StarterPackPickerView() }
            .sheet(isPresented: $showShopping) { ShoppingListView() }
            .sensoryFeedback(.impact(weight: .light), trigger: usedCount)
            .onAppear {
                #if DEBUG
                let args = ProcessInfo.processInfo.arguments
                if let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count, args[i + 1] == "select", !editMode.isEditing {
                    editMode = .active
                    selection = Set(filtered.prefix(3).map(\.persistentModelID))
                }
                #endif
            }
        } detail: {
            DetailPlaceholder(symbol: "shippingbox", title: "Pick an item", text: "Its dates, nutrition and where it lives open here. Swipe a row to use one or mark it checked.")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nothing here yet", systemImage: "shippingbox")
        } description: {
            Text("Scan a barcode, add an item by hand, or start from a ready-made list.")
        } actions: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { emptyActions }
                VStack(spacing: 10) { emptyActions }
            }
        }
    }

    @ViewBuilder
    private var emptyActions: some View {
        Button { showScanner = true } label: { Label("Scan", systemImage: "barcode.viewfinder") }
            .buttonStyle(.borderedProminent)
        Button { showPacks = true } label: { Label("Starter pack", systemImage: "list.bullet.rectangle") }
            .buttonStyle(.bordered)
        NavigationLink { KitsView() } label: { Label("Go-bag", systemImage: "backpack") }
            .buttonStyle(.bordered)
    }

    private var list: some View {
        List(selection: $selection) {
            if !kits.isEmpty, !editMode.isEditing {
                Section {
                    ForEach(kits.prefix(3), id: \.uuid) { kit in
                        NavigationLink { KitDetailView(kit: kit) } label: { KitRow(kit: kit) }
                    }
                    if kits.count > 3 {
                        NavigationLink { KitsView() } label: { Text("All \(kits.count) kits") }
                    }
                } header: { Text("Kits") }
            }
            if sortMode == .location {
                ForEach(groupedByLocation, id: \.0) { name, group in
                    Section(name) {
                        ForEach(group) { item in row(item) }
                    }
                }
            } else {
                ForEach(filtered) { item in row(item) }
            }
        }
    }

    /// Sits above the tab bar while selecting. Everything a selection can become, in one row.
    private var actionBar: some View {
        VStack(spacing: 6) {
            Text(selection.isEmpty ? "Tap items to select them" : "\(selection.count) selected")
                .font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Menu {
                    ForEach(SupplyCategory.allCases) { c in
                        Button { setCategory(selected(), to: c) } label: { Label(c.title, systemImage: c.symbol) }
                    }
                } label: { Label("Category", systemImage: "tag") }
                Menu {
                    ForEach(locations) { loc in
                        Button { move(selected(), to: loc) } label: { Label(loc.name, systemImage: loc.symbol) }
                    }
                    Button { move(selected(), to: nil) } label: { Label("No location", systemImage: "questionmark.square.dashed") }
                } label: { Label("Move", systemImage: "folder") }
                if !kits.isEmpty {
                    Menu {
                        ForEach(kits, id: \.uuid) { kit in
                            Button { pack(selected(), into: kit) } label: { Label(kit.name, systemImage: kit.kind.symbol) }
                        }
                        Button { pack(selected(), into: nil) } label: { Label("Not in a kit", systemImage: "minus.circle") }
                    } label: { Label("Kit", systemImage: "backpack") }
                }
                Spacer(minLength: 0)
                Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: "trash") }
                    .tint(.red)
            }
            .tint(Color(uiColor: .label))
            .labelStyle(.titleAndIcon)
            .font(.subheadline.weight(.medium))
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(selection.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private func setCategory(_ list: [SupplyItem], to category: SupplyCategory) {
        for item in list { item.category = category; item.touch() }
        try? context.save()
        withAnimation { editMode = .inactive; selection.removeAll() }
    }

    private func pack(_ list: [SupplyItem], into kit: Kit?) {
        for item in list { item.kit = kit; item.touch() }
        try? context.save()
        withAnimation { editMode = .inactive; selection.removeAll() }
    }

    private func selected() -> [SupplyItem] { items.filter { selection.contains($0.persistentModelID) } }

    private func move(_ list: [SupplyItem], to location: StorageLocation?) {
        for item in list { item.location = location; item.touch() }
        try? context.save()
        withAnimation { editMode = .inactive; selection.removeAll() }
    }

    private func deleteSelected() {
        for item in selected() { context.delete(item) }
        try? context.save()
        withAnimation { editMode = .inactive; selection.removeAll() }
    }

    private func row(_ item: SupplyItem) -> some View {
        NavigationLink { ItemDetailView(item: item) } label: { ItemRow(item: item) }
            .tag(item.persistentModelID)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button { useOne(item) } label: { Label("Used 1", systemImage: "minus.circle") }
                    .tint(Color.ink)
                Button(role: .destructive) { context.delete(item); try? context.save() } label: { Label("Delete", systemImage: "trash") }
            }
            .swipeActions(edge: .leading) {
                Button { checked(item) } label: { Label("Checked", systemImage: "checkmark.circle") }
                    .tint(Color.moss)
            }
    }

    private func useOne(_ item: SupplyItem) {
        item.quantity = max(0, item.quantity - 1)
        item.touch()
        usedCount += 1
        if item.quantity == 0 {
            context.insert(ShoppingItem(name: item.name, quantity: 1, unit: item.unit, reason: "Used up"))
        }
        try? context.save()
    }

    /// "I looked at it, it's fine." Food past its best-by gets a 90-day quiet period. Medicine does not.
    private func checked(_ item: SupplyItem) {
        item.lastCheckedAt = Date()
        if case .past = item.status(), item.category.usesSoftDateLanguage {
            item.snoozedUntil = Calendar.current.date(byAdding: .day, value: 90, to: Date())
        }
        item.touch()
        try? context.save()
    }
}
