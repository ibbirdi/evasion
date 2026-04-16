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

    func testFreeShortTimerDoesNotShowPaywall() throws {
        let app = makeApp()
        app.launch()

        let timerButton = button(in: app, id: "home.header.timer")
        waitForHittable(timerButton)
        timerButton.tap()

        tapTimerMenuOption(in: app, labels: ["30 min"])

        XCTAssertFalse(app.otherElements["panel.timer.unlock"].exists)
        XCTAssertFalse(app.buttons["premium.paywall.close"].exists)
    }

    func testPremiumLongTimerShowsUnlockPanelBeforePaywall() throws {
        let app = makeApp()
        app.launch()

        let timerButton = button(in: app, id: "home.header.timer")
        waitForHittable(timerButton)
        timerButton.tap()

        tapTimerMenuOption(in: app, labels: ["1 hr", "1 h"])

        let unlockPanel = app.otherElements["panel.timer.unlock"]
        waitForExistence(of: unlockPanel)

        let durationButton = app.buttons["timer.unlock.option.60"]
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

    private func tapTimerMenuOption(in app: XCUIApplication, labels: [String], timeout: TimeInterval = 8) {
        for label in labels {
            let option = app.buttons.matching(identifier: label).firstMatch
            if option.waitForExistence(timeout: 1) {
                tapElementReliably(option, timeout: timeout)
                return
            }
        }

        XCTFail("No timer menu option found for labels: \(labels)")
    }

    private func tapElementReliably(_ element: XCUIElement, timeout: TimeInterval = 8) {
        waitForExistence(of: element, timeout: timeout)

        if element.isHittable {
            element.tap()
            return
        }

        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
}
