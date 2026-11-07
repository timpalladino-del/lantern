import Foundation
import CoreLocation
import Observation

/// One position, taken only when the user taps "Use my location". Nothing runs in the background and
/// nothing leaves the phone. The permission string in Info.plist explains this.
@MainActor
@Observable
final class LocationFix: NSObject, CLLocationManagerDelegate {
    private(set) var isWorking = false
    private(set) var current: CLLocation?
    private(set) var denied = false
    private(set) var error: String?
    private let manager = CLLocationManager()
    private var onFix: ((CLLocation) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func request(_ completion: @escaping (CLLocation) -> Void) {
        onFix = completion
        error = nil
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            denied = true
            return
        }
        isWorking = true
        manager.requestLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.current = loc
            self.isWorking = false
            self.onFix?(loc)
            self.onFix = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isWorking = false
            self.error = "Couldn't get a position. Try near a window or outside."
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.denied = status == .denied || status == .restricted
            if (status == .authorizedWhenInUse || status == .authorizedAlways), self.onFix != nil, !self.isWorking {
                self.isWorking = true
                manager.requestLocation()
            }
        }
    }
}

/// A saved point: latitude and longitude in degrees. Formatting and parsing live here so the
/// coordinate section and the printed plan agree.
struct GeoPoint: Equatable {
    var latitude: Double
    var longitude: Double

    var isValid: Bool { (-90...90).contains(latitude) && (-180...180).contains(longitude) && !(latitude == 0 && longitude == 0) }

    /// "28.5383, -81.3792"
    var text: String { String(format: "%.5f, %.5f", latitude, longitude) }

    /// "28°32'18\" N, 81°22'45\" W", the form on a paper map or a rescue call.
    var dms: String {
        func part(_ v: Double, _ pos: String, _ neg: String) -> String {
            let a = abs(v); let d = Int(a); let m = Int((a - Double(d)) * 60); let s = Int(((a - Double(d)) * 60 - Double(m)) * 60)
            return "\(d)°\(m)'\(s)\" \(v >= 0 ? pos : neg)"
        }
        return part(latitude, "N", "S") + ", " + part(longitude, "E", "W")
    }

    var mapsURL: URL { URL(string: "https://maps.apple.com/?ll=\(latitude),\(longitude)&q=\(latitude),\(longitude)")! }
    var directionsURL: URL { URL(string: "https://maps.apple.com/?daddr=\(latitude),\(longitude)")! }

    /// Accepts "28.5383, -81.3792", "28.5383 -81.3792", or a pasted Apple or Google Maps link with ll= or @lat,lon.
    static func parse(_ raw: String) -> GeoPoint? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"(-?\d{1,3}(?:\.\d+)?)\s*[, ]\s*(-?\d{1,3}(?:\.\d+)?)"#
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              let r1 = Range(m.range(at: 1), in: s), let r2 = Range(m.range(at: 2), in: s),
              let lat = Double(s[r1]), let lon = Double(s[r2]) else { return nil }
        let p = GeoPoint(latitude: lat, longitude: lon)
        return p.isValid ? p : nil
    }

    func distance(to other: GeoPoint) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude).distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }

    /// "120 ft away" or "3.2 mi away".
    static func distanceText(_ meters: CLLocationDistance) -> String {
        let feet = meters * 3.28084
        if feet < 1000 { return "\(Int(feet.rounded())) ft away" }
        return String(format: "%.1f mi away", feet / 5280)
    }
}
