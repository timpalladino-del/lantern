import Foundation
import UIKit

/// Phone battery level and the advice that goes with it.
enum BatteryMonitor {
    struct Reading {
        let level: Double?      // 0...1, nil when unknown (simulator)
        let isCharging: Bool
    }

    static func read() -> Reading {
        let d = UIDevice.current
        d.isBatteryMonitoringEnabled = true
        let level = d.batteryLevel >= 0 ? Double(d.batteryLevel) : nil
        let charging = d.batteryState == .charging || d.batteryState == .full
        return Reading(level: level, isCharging: charging)
    }

    static func tips(for r: Reading) -> [String] {
        var tips: [String] = []
        if r.isCharging { return ["Charging. Fill every power bank you own while you can."] }
        guard let level = r.level else { return ["Turn on Low Power Mode. Texts use far less battery than calls."] }
        if level < 0.2 {
            tips.append("Under 20 percent. Airplane mode now; turn it off only to send a text or check for alerts.")
            tips.append("Screen brightness down. Close the camera. Do not use this phone as a flashlight.")
        } else if level < 0.5 {
            tips.append("Turn on Low Power Mode (Settings, Battery) and dim the screen.")
            tips.append("Text instead of call. Calls burn battery and fail first when towers are overloaded.")
        } else {
            tips.append("You have time. Turn on Low Power Mode anyway and charge every power bank.")
        }
        tips.append("A car can charge a phone. Run it outside, in the open, not in a garage.")
        return tips
    }
}
