import SwiftUI
import SwiftData

/// A readiness gap with one button that adds it to the shopping list. The list itself is the record,
/// so the button stays "On the shopping list" across screens and relaunches.
struct GapRow: View {
    let gap: ReadinessGap
    @Environment(\.modelContext) private var context
    @Query private var shopping: [ShoppingItem]

    private var alreadyListed: Bool {
        shopping.contains { $0.reason == "Readiness gap" && $0.name == gap.shoppingName }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(gap.title).font(.subheadline.weight(.medium))
            Text(gap.detail).font(.caption).foregroundStyle(.secondary)
            Button(alreadyListed ? "On the shopping list" : "Add to shopping list") {
                context.insert(ShoppingItem(name: gap.shoppingName, quantity: gap.shoppingQuantity, unit: gap.shoppingUnit, reason: "Readiness gap"))
                try? context.save()
            }
            .buttonStyle(.bordered).controlSize(.small)
            .disabled(alreadyListed)
        }
    }
}
