import SwiftUI
import SwiftData
import VisionKit
import Vision
import AVFoundation

/// Camera wrapper. Barcodes and printed text, on-device, nothing recorded.
struct DataScannerRepresentable: UIViewControllerRepresentable {
    var onBarcode: (String) -> Void
    var onText: (String) -> Void
    /// Fraction of the view's height, from the top, that the scanner reads. The card below is ignored.
    var activeHeightFraction: CGFloat = 0.6

    static var isSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let types: Set<DataScannerViewController.RecognizedDataType> = [
            .barcode(symbologies: [.ean13, .ean8, .upce, .code128, .code39, .qr, .dataMatrix, .itf14]),
            .text()
        ]
        let vc = DataScannerViewController(
            recognizedDataTypes: types,
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {
        context.coordinator.parent = self
        let b = vc.view.bounds
        if b.width > 0 { vc.regionOfInterest = CGRect(x: 0, y: 0, width: b.width, height: b.height * activeHeightFraction) }
        if !vc.isScanning { try? vc.startScanning() }
    }

    static func dismantleUIViewController(_ vc: DataScannerViewController, coordinator: Coordinator) {
        vc.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: DataScannerRepresentable
        init(parent: DataScannerRepresentable) { self.parent = parent }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            handle(addedItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            handle(updatedItems)
        }

        private func handle(_ items: [RecognizedItem]) {
            for item in items {
                switch item {
                case .barcode(let barcode):
                    if let value = barcode.payloadStringValue { parent.onBarcode(value) }
                case .text(let text):
                    parent.onText(text.transcript)
                @unknown default:
                    break
                }
            }
        }
    }
}

/// The camera torch for reading a label in a dark pantry. Separate from the SOS strobe.
@MainActor
@Observable
final class CameraTorch {
    private(set) var isOn = false
    var isAvailable: Bool { AVCaptureDevice.default(for: .video)?.hasTorch ?? false }

    func toggle() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = isOn ? .off : .on
            device.unlockForConfiguration()
            isOn.toggle()
        } catch {}
    }

    func off() {
        guard isOn, let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = .off
        device.unlockForConfiguration()
        isOn = false
    }
}

/// Scan a barcode and the printed date, pick where it goes, add it. Stays open so a whole bag of
/// groceries goes in without leaving the screen.
struct ScanSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var items: [SupplyItem]
    @Query(sort: \StorageLocation.sortOrder) private var locations: [StorageLocation]
    @AppStorage(AppSettings.onlineLookupEnabled) private var onlineLookup = true
    @AppStorage("scan.lastLocation") private var lastLocationID = ""

    @State private var barcode: String?
    @State private var productName: String?
    @State private var productBrand: String?
    @State private var productCalories: Double?
    @State private var productServings: Double?
    @State private var productNutrition: NutritionFacts?
    @State private var memory: ProductMemory?
    @State private var isLookingUp = false
    @State private var bestDate: DateLabelParser.Candidate?
    @State private var manualBarcode = ""
    @State private var showManual = false
    @State private var showEditor = false
    @State private var showNewLocation = false
    @State private var addedToExisting: String?
    @State private var addedThisSession = 0
    @State private var location: StorageLocation?
    @State private var torch = CameraTorch()
    @State private var recognitions = 0

    private let parser = DateLabelParser()

    private var existingMatches: [SupplyItem] {
        guard let barcode else { return [] }
        return items.filter { $0.barcode == barcode }
    }

    private var guide: String {
        if barcode == nil && bestDate == nil { return "Point at the barcode" }
        if barcode != nil && bestDate == nil { return "Got it. Now the printed date, if there is one" }
        if barcode == nil { return "Date read. Now the barcode" }
        return "Barcode and date read"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if DataScannerRepresentable.isSupported {
                    DataScannerRepresentable(onBarcode: handleBarcode, onText: handleText)
                        .ignoresSafeArea()
                    reticle
                } else {
                    Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                    VStack {
                        Spacer()
                        ContentUnavailableView {
                            Label("No camera here", systemImage: "camera.fill")
                        } description: {
                            Text("This device or simulator cannot scan. Type the barcode, or add the item by hand.")
                        } actions: {
                            Button { showManual = true } label: { Label("Type a barcode", systemImage: "keyboard") }.buttonStyle(.borderedProminent)
                        }
                        Spacer()
                        Spacer()
                    }
                }
                card
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if torch.isAvailable {
                        Button { torch.toggle() } label: { Image(systemName: torch.isOn ? "flashlight.on.fill" : "flashlight.off.fill") }
                            .accessibilityLabel(torch.isOn ? "Turn the light off" : "Turn the light on")
                    }
                    Button { showManual = true } label: { Image(systemName: "keyboard") }
                        .accessibilityLabel("Type a barcode")
                }
            }
            .sheet(isPresented: $showEditor) {
                ItemEditView(draft: draft) { _ in addedThisSession += 1; reset() }
            }
            .sheet(isPresented: $showNewLocation) { LocationEditView() }
            .alert("Type the barcode", isPresented: $showManual) {
                TextField("Digits under the bars", text: $manualBarcode).keyboardType(.numberPad)
                Button("Use") { handleBarcode(manualBarcode); manualBarcode = "" }
                Button("Cancel", role: .cancel) { manualBarcode = "" }
            }
            .onAppear {
                if location == nil {
                    location = locations.first { $0.uuid.uuidString == lastLocationID } ?? locations.first
                }
            }
            .onDisappear { torch.off() }
            .sensoryFeedback(.success, trigger: recognitions)
        }
    }

    /// The window the scanner reads. Dimmed outside, a bracket inside, the guide line above.
    private var reticle: some View {
        GeometryReader { geo in
            let w = geo.size.width - 48
            let h = min(w * 0.62, geo.size.height * 0.34)
            let frame = CGRect(x: 24, y: geo.size.height * 0.16, width: w, height: h)
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.35)
                    .mask(
                        Rectangle().overlay(RoundedRectangle(cornerRadius: 22).frame(width: frame.width, height: frame.height)
                            .position(x: frame.midX, y: frame.midY).blendMode(.destinationOut))
                    )
                    .allowsHitTesting(false)
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(barcode != nil ? Color.moss : Color.white.opacity(0.9), lineWidth: 3)
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                    .animation(.easeOut(duration: 0.2), value: barcode != nil)
                Label(guide, systemImage: barcode == nil ? "barcode.viewfinder" : bestDate == nil ? "calendar" : "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .position(x: geo.size.width / 2, y: frame.minY - 28)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.2), value: guide)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            // What the camera found
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: barcode == nil ? "barcode" : "shippingbox.fill")
                    .font(.title2).foregroundStyle(barcode == nil ? Color.secondary : Color.ink).frame(width: 32)
                    .symbolEffect(.bounce, value: barcode)
                VStack(alignment: .leading, spacing: 2) {
                    if let name = productName {
                        Text(name).font(.headline).lineLimit(2)
                        if let b = productBrand, !b.isEmpty { Text(b).font(.subheadline).foregroundStyle(.secondary) }
                    } else if let barcode {
                        Text(isLookingUp ? "Looking it up…" : "New to Lantern").font(.headline)
                        Text("Barcode \(barcode)").font(.subheadline).foregroundStyle(.secondary).monospacedDigit()
                    } else {
                        Text("Nothing scanned yet").font(.headline).foregroundStyle(.secondary)
                        Text(addedThisSession == 0 ? "Hold the barcode inside the frame." : "\(addedThisSession) added this session. Keep going.").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isLookingUp { ProgressView() }
            }
            if let d = bestDate {
                Label("Date \(d.date.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    .font(.subheadline).foregroundStyle(Color.moss)
                    .symbolEffect(.bounce, options: .nonRepeating)
            }
            if let added = addedToExisting {
                Label("Added 1 to \(added)", systemImage: "checkmark.circle.fill").foregroundStyle(Color.moss).font(.subheadline)
                    .symbolEffect(.bounce, options: .nonRepeating)
            }

            // Where it goes
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Put it in").font(.caption).foregroundStyle(.secondary)
                    ForEach(locations, id: \.uuid) { loc in
                        Button {
                            location = loc; lastLocationID = loc.uuid.uuidString
                        } label: {
                            Label(loc.name, systemImage: loc.symbol)
                                .font(.caption.weight(.medium)).lineLimit(1)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(location?.uuid == loc.uuid ? Color.ink : Color(uiColor: .tertiarySystemFill), in: Capsule())
                                .foregroundStyle(location?.uuid == loc.uuid ? Color(uiColor: .systemBackground) : Color.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(location?.uuid == loc.uuid ? .isSelected : [])
                    }
                    Button { showNewLocation = true } label: {
                        Label("New", systemImage: "plus").font(.caption.weight(.medium))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("New location")
                }
            }

            // Actions
            HStack(spacing: 10) {
                if let first = existingMatches.first {
                    Button {
                        first.quantity += 1
                        first.touch()
                        if first.location == nil { first.location = location }
                        if let d = bestDate?.date, first.expirationDate == nil || d > (first.expirationDate ?? d) {
                            first.expirationDate = d
                            first.dateSource = .printed
                        }
                        try? context.save()
                        addedToExisting = first.name
                        addedThisSession += 1
                        barcode = nil
                        bestDate = nil
                    } label: { Label("Add 1 to \(first.name)", systemImage: "plus.circle.fill").lineLimit(1) }
                    .buttonStyle(.borderedProminent)
                    Button { showEditor = true } label: { Label("New", systemImage: "square.and.pencil") }
                        .buttonStyle(.bordered)
                } else {
                    Button { showEditor = true } label: {
                        Label(barcode == nil && bestDate == nil ? "Add by hand" : "New item", systemImage: "square.and.pencil").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                if barcode != nil || bestDate != nil {
                    Button { reset() } label: { Image(systemName: "arrow.counterclockwise").frame(minWidth: 28) }
                        .buttonStyle(.bordered).accessibilityLabel("Rescan")
                }
            }
            .controlSize(.large)
            Text(onlineLookup ? OpenFoodFactsClient.attribution : "Online barcode lookup is off. Names come from your own history.")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22))
        .ignoresSafeArea(edges: .bottom)
    }

    private var draft: ItemDraft {
        var d = ItemDraft()
        d.barcode = barcode
        d.name = productName ?? ""
        d.brand = productBrand ?? ""
        d.caloriesPerUnit = productCalories
        d.servingsPerUnit = productServings
        d.nutrition = productNutrition
        d.location = location
        if let m = memory {
            d.category = m.category
            d.unit = m.unit
            d.shelfLifeKey = m.shelfLifeKey
            d.servingsPerUnit = m.servingsPerUnit
            d.caloriesPerUnit = m.caloriesPerUnit
            d.litersPerUnit = m.litersPerUnit
            d.nutrition = m.nutrition ?? productNutrition
        }
        if let c = bestDate {
            d.expirationDate = c.date
            d.dateSource = .printed
        }
        return d
    }

    private func reset() {
        barcode = nil
        productName = nil
        productBrand = nil
        productCalories = nil
        productServings = nil
        productNutrition = nil
        memory = nil
        bestDate = nil
        addedToExisting = nil
    }

    private func handleBarcode(_ code: String) {
        let clean = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard barcode == nil, !clean.isEmpty else { return }
        barcode = clean
        addedToExisting = nil
        recognitions += 1

        let descriptor = FetchDescriptor<ProductMemory>(predicate: #Predicate { $0.barcode == clean })
        if let m = (try? context.fetch(descriptor))?.first {
            memory = m
            productName = m.name
            productBrand = m.brand
            return
        }
        if let existing = items.first(where: { $0.barcode == clean }) {
            productName = existing.name
            productBrand = existing.brand
            return
        }
        guard onlineLookup else { return }
        isLookingUp = true
        Task {
            let info = try? await OpenFoodFactsClient.shared.lookup(barcode: clean)
            await MainActor.run {
                isLookingUp = false
                if let info, barcode == clean {
                    productName = info.name
                    productBrand = info.brand
                    productCalories = info.caloriesPerPackage
                    productServings = info.servingsPerPackage
                    productNutrition = info.nutrition
                }
            }
        }
    }

    private func handleText(_ text: String) {
        guard let candidate = parser.parse(text).first, candidate.confidence >= 0.55 else { return }
        if let current = bestDate, current.confidence >= candidate.confidence { return }
        bestDate = candidate
        recognitions += 1
    }
}
