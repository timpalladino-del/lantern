import SwiftUI
import CoreLocation
import UIKit

/// Saves a point for a place: a storage spot off the property, a meeting place, a cache.
/// "Use my location" takes one fix; "Type them in" accepts "lat, lon" or a pasted Maps link.
struct CoordinateSection: View {
    let title: String
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    var onChange: () -> Void = {}

    @State private var fix = LocationFix()
    @State private var typing = false
    @State private var typed = ""
    @State private var parseFailed = false
    @State private var copied = false

    private var point: GeoPoint? {
        guard let la = latitude, let lo = longitude else { return nil }
        let p = GeoPoint(latitude: la, longitude: lo)
        return p.isValid ? p : nil
    }

    var body: some View {
        Section {
            if let p = point {
                VStack(alignment: .leading, spacing: 4) {
                    Label(p.text, systemImage: "mappin.and.ellipse").font(.subheadline.weight(.medium)).monospacedDigit()
                    Text(p.dms).font(.caption).foregroundStyle(.secondary)
                    if let here = fix.current {
                        Text(GeoPoint.distanceText(p.distance(to: GeoPoint(latitude: here.coordinate.latitude, longitude: here.coordinate.longitude))))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 10) {
                    Link(destination: p.mapsURL) { Label("Open in Maps", systemImage: "map") }
                        .buttonStyle(.bordered)
                    Link(destination: p.directionsURL) { Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond") }
                        .buttonStyle(.bordered)
                    Button {
                        UIPasteboard.general.string = p.text; copied = true
                    } label: { Image(systemName: copied ? "checkmark" : "doc.on.doc").frame(minWidth: 28) }
                        .buttonStyle(.bordered)
                        .accessibilityLabel(copied ? "Copied" : "Copy coordinates")
                }
                .font(.subheadline)
                Button("Clear coordinates", role: .destructive) { latitude = nil; longitude = nil; typed = ""; onChange() }
            } else {
                Text("Not set").foregroundStyle(.secondary)
            }
            Button {
                fix.request { loc in
                    latitude = loc.coordinate.latitude
                    longitude = loc.coordinate.longitude
                    typed = ""
                    onChange()
                }
            } label: {
                HStack {
                    Label(point == nil ? "Use my location" : "Update to my location", systemImage: "location.fill")
                    if fix.isWorking { Spacer(); ProgressView() }
                }
            }
            .disabled(fix.isWorking)
            if fix.denied {
                Text("Location is off for Lantern. Turn it on in Settings, or type the coordinates in.").font(.caption).foregroundStyle(Color.ember)
            }
            if let e = fix.error { Text(e).font(.caption).foregroundStyle(Color.ember) }
            DisclosureGroup("Type them in", isExpanded: $typing) {
                TextField("28.5383, -81.3792 or a Maps link", text: $typed)
                    .keyboardType(.numbersAndPunctuation).autocorrectionDisabled().textInputAutocapitalization(.never)
                    .onSubmit(apply)
                Button("Save coordinates", action: apply).disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
                if parseFailed { Text("Couldn't read that. Use latitude, then longitude, in degrees.").font(.caption).foregroundStyle(Color.ember) }
            }
        } header: { Text(title) } footer: {
            Text("For a spot you would describe to a rescuer or a relative: a cache in the woods, a cabin, a storage unit, the meeting place. Stored only on this phone.")
        }
    }

    private func apply() {
        if let p = GeoPoint.parse(typed) {
            latitude = p.latitude; longitude = p.longitude; parseFailed = false; typing = false; onChange()
        } else {
            parseFailed = true
        }
    }
}
