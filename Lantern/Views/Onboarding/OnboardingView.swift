import SwiftUI
import SwiftData

/// First run. Three screens, no account, nothing uploaded.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var households: [Household]
    @State private var step = 0

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 0: welcome
                case 1: people
                default: finish
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if step > 0 {
                    ToolbarItem(placement: .topBarLeading) { Button("Back") { step -= 1 } }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(step == 2 ? "Done" : "Next") { if step == 2 { dismiss() } else { step += 1 } }
                        .fontWeight(.semibold)
                }
            }
        }
        .interactiveDismissDisabled()
        .task { if households.isEmpty { SeedData.ensureDefaults(in: context) } }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Image(systemName: "lightbulb.max.fill").font(.system(size: 44)).foregroundStyle(Color.accentColor)
            Text("Lantern").font(.largeTitle.weight(.bold))
            Text("Ready for when you need it most.").font(.title3).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 12) {
                Label("Keep track of the food, water, medicine and gear you set aside.", systemImage: "shippingbox")
                Label("Know what to use before it goes to waste.", systemImage: "calendar")
                Label("See how many days your people are covered for.", systemImage: "person.2")
                Label("Everything stays on this phone. No account, no cloud.", systemImage: "lock")
            }
            .font(.subheadline)
            Spacer()
            Text("Two minutes to set up. Start with who lives here.").font(.footnote).foregroundStyle(.secondary)
        }
        .padding(24)
    }

    @ViewBuilder
    private var people: some View {
        if let h = households.first {
            HouseholdView(household: h, showTarget: true)
                .navigationTitle("Who's here")
        } else {
            ProgressView()
        }
    }

    private var finish: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.circle.fill").font(.system(size: 44)).foregroundStyle(.green)
            Text("You're set.").font(.largeTitle.weight(.bold))
            Text("Next, add what you already have. The fastest way is the scanner: point it at a can so the barcode and the printed date are both in view.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                Label("Scan a barcode from the Home tab", systemImage: "barcode.viewfinder")
                Label("Or add a starter pack under Supplies", systemImage: "list.bullet.rectangle")
                Label("Add the generator, alarms and extinguisher under Equipment", systemImage: "wrench.and.screwdriver")
            }
            .font(.subheadline)
            Spacer()
        }
        .padding(24)
    }
}
