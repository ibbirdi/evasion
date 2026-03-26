import XCTest

@MainActor
final class OasisNativePremiumFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLockedPresetShowsInlineUpsellBeforePaywall() throws {
        let app = makeApp()
        app.launch()

        let presetsButton = button(in: app, id: "home.header.presets")
        waitForHittable(presetsButton)
        presetsButton.tap()

        let presetsPanel = app.otherElements["panel.presets.container"]
        waitForExistence(of: presetsPanel)

        let lockedPreset = app.buttons["presets.row.preset_default_storm"]
        waitForExistence(of: lockedPreset)
        lockedPreset.tap()

        let inlineUpsell = app.otherElements["premium.inline.preset"]
        waitForExistence(of: inlineUpsell)
        XCTAssertFalse(app.buttons["premium.paywall.close"].exists)

        let primaryCTA = app.buttons["premium.inline.primary"]
        waitForHittable(primaryCTA)
        primaryCTA.tap()

        waitForPaywall(in: app)
    }

    func testLockedBinauralTrackKeepsPanelOpen() throws {
        let app = makeApp()
        app.launch()

        let binauralButton = button(in: app, id: "home.header.binaural")
        waitForHittable(binauralButton)
        binauralButton.tap()

        let panel = app.otherElements["panel.binaural.container"]
        waitForExistence(of: panel)

        let thetaTrack = app.buttons["binaural.track.theta"]
        waitForExistence(of: thetaTrack)
        thetaTrack.tap()

        XCTAssertTrue(panel.exists)
        waitForExistence(of: app.otherElements["premium.inline.binaural"])
        XCTAssertFalse(app.buttons["premium.paywall.close"].exists)
    }

    func testTimerChipShowsUnlockPanelBeforePaywall() throws {
        let app = makeApp()
        app.launch()

        let timerButton = button(in: app, id: "home.header.timer")
        waitForHittable(timerButton)
        timerButton.tap()

        let unlockPanel = app.otherElements["panel.timer.unlock"]
        waitForExistence(of: unlockPanel)

        let durationButton = app.buttons["timer.unlock.option.30"]
        waitForExistence(of: durationButton)
        durationButton.tap()

        waitForPaywall(in: app)
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-ui_testing",
            "-OASISPremiumOverride", "free",
            "-OASISResetState", "YES"
        ]
        return app
    }

    private func button(in app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .button).matching(identifier: id).firstMatch
    }

    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 8) {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Element not hittable: \(element)")
    }

    private func waitForExistence(of element: XCUIElement, timeout: TimeInterval = 8) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element not found: \(element)")
    }

    private func waitForPaywall(in app: XCUIApplication, timeout: TimeInterval = 8) {
        waitForExistence(of: app.buttons["premium.paywall.close"], timeout: timeout)
    }
}
