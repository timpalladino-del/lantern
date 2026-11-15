import XCTest
import StoreKitTest

/// Drives the app through the flow App Review asked to see, at a pace a person can follow.
/// Xcode records the screen for the whole test; the video is exported from the result bundle.
final class ReviewWalkthrough: XCTestCase {
    private var app: XCUIApplication!
    private var session: SKTestSession?

    override func setUpWithError() throws {
        continueAfterFailure = true
        session = try? SKTestSession(configurationFileNamed: "Lantern")
        session?.disableDialogs = true
        session?.clearTransactions()
        app = XCUIApplication()
        // The argument domain overrides stored defaults for this launch only, so onboarding shows.
        app.launchArguments = ["-settings.hasSeenWelcome", "NO"] + (ProcessInfo.processInfo.environment["WALK_EPHEMERAL"] == "1" ? ["-ephemeral"] : [])
    }

    private func pause(_ seconds: Double) { Thread.sleep(forTimeInterval: seconds) }

    @discardableResult
    private func tap(_ element: XCUIElement, wait: Double = 8, then hold: Double = 1.0, _ what: String = "") -> Bool {
        guard element.waitForExistence(timeout: wait) else { XCTContext.runActivity(named: "MISSING: \(what) \(element)") { _ in }; return false }
        if !element.isHittable { app.swipeUp(velocity: .slow); pause(0.4) }
        element.tap()
        pause(hold)
        return true
    }

    private func button(_ label: String) -> XCUIElement { app.buttons[label].firstMatch }
    private func containing(_ text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@ AND (elementType == %d OR elementType == %d OR elementType == %d)", text,
                                                         XCUIElement.ElementType.button.rawValue, XCUIElement.ElementType.cell.rawValue, XCUIElement.ElementType.staticText.rawValue)).firstMatch
    }

    private func type(_ text: String, into field: XCUIElement, _ what: String) {
        guard field.waitForExistence(timeout: 8) else { XCTContext.runActivity(named: "MISSING field: \(what)") { _ in }; return }
        field.tap(); pause(0.4)
        field.typeText(text); pause(0.6)
    }

    func testWalkthrough() throws {
        app.launch()

        // 1. Welcome
        XCTAssertTrue(app.staticTexts["Lantern"].waitForExistence(timeout: 15))
        pause(3.0)
        tap(button("Next"), then: 1.5, "Next 1")

        // 2. Who's here: add yourself
        tap(containing("Add a person"), then: 1.2, "Add a person")
        type("Tim", into: app.textFields["Name"].firstMatch, "person name")
        tap(button("Save"), then: 2.0, "Save person")
        tap(button("Next"), then: 2.5, "Next 2")
        tap(button("Done"), then: 2.5, "Done")

        // 3. Home, then add a supply by hand (the scanner needs a camera)
        pause(1.5)
        tap(button("Add"), then: 1.2, "Quick action Add")
        type("White rice", into: app.textFields["Name"].firstMatch, "item name")
        if button("Use this").waitForExistence(timeout: 2) { button("Use this").tap(); pause(1.2) }
        tap(button("Save"), then: 2.0, "Save item")

        tap(app.tabBars.buttons["Supplies"], then: 2.5, "Supplies tab")
        tap(app.tabBars.buttons["Home"], then: 2.0, "Home tab")
        app.swipeUp(velocity: .slow); pause(2.5)
        app.swipeDown(); pause(0.5); app.swipeDown(); pause(1.2)

        // 4. Second person: this is where the plans appear
        tap(button("Add a person"), then: 1.2, "Add bubble")
        type("Maria", into: app.textFields["Name"].firstMatch, "second person name")
        tap(button("Save"), then: 3.5, "Save second person")
        if button("Not now").waitForExistence(timeout: 6) {
            pause(3.0)
            app.swipeUp(velocity: .slow); pause(3.0)
            app.swipeDown(); pause(1.5)
            button("Not now").tap(); pause(2.0)
        } else { XCTContext.runActivity(named: "MISSING: paywall") { _ in } }

        // 5. Toolkit: outage mode, light, know-how. No purchase needed.
        tap(app.tabBars.buttons["Toolkit"], then: 2.5, "Toolkit tab")
        if tap(containing("Outage mode"), then: 2.0, "Outage row") {
            tap(button("Power just went out"), wait: 4, then: 3.5, "Power just went out")
            app.swipeUp(velocity: .slow); pause(2.0)
            app.swipeDown(); pause(0.4); app.swipeDown(); pause(0.8)
            tap(button("Power is back"), wait: 4, then: 2.0, "Power is back")
            tap(app.navigationBars.buttons.firstMatch, then: 1.5, "Back from outage")
        }
        if tap(containing("SOS strobe and flashlight"), then: 2.5, "Light row") {
            tap(app.navigationBars.buttons.firstMatch, then: 1.2, "Back from light")
        }
        app.swipeUp(velocity: .slow); pause(1.0)
        if tap(containing("Know-how cards"), then: 2.5, "Know-how row") {
            tap(app.navigationBars.buttons.firstMatch, then: 1.2, "Back from know-how")
        }

        // 6. Weather alerts for a saved ZIP code
        tap(app.tabBars.buttons["Home"], then: 1.5, "Home tab again")
        tap(button("Settings"), then: 2.0, "Settings")
        tap(containing("Weather alerts"), then: 2.5, "Weather alerts row")
        tap(containing("Add a place"), then: 1.2, "Add a place")
        type("Home", into: app.textFields.element(boundBy: 0), "place name")
        type("32801", into: app.textFields["ZIP code"].firstMatch, "zip")
        tap(button("Save"), then: 6.0, "Save place")
        pause(3.0)
    }
}
