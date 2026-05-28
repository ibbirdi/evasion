import XCTest

@MainActor
final class OasisNativePremiumFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLockedSavedAmbienceShowsInlineUpsellBeforePaywall() throws {
        let app = makeApp()
        app.launch()

        let ambiencesButton = button(in: app, id: "home.bottom.compose")
        waitForHittable(ambiencesButton)
        ambiencesButton.tap()

        let ambiencesPanel = app.otherElements["panel.compose.container"]
        waitForExistence(of: ambiencesPanel)

        let lockedAmbience = app.buttons["compose.ambience.preset_default_storm"]
        waitForExistence(of: lockedAmbience)
        lockedAmbience.tap()

        let startAmbience = app.buttons["compose.ambience.start"]
        waitForHittable(startAmbience)
        startAmbience.tap()

        let inlineUpsell = app.otherElements["premium.inline.composer"]
        waitForExistence(of: inlineUpsell)
        XCTAssertFalse(app.buttons["premium.paywall.close"].exists)

        let primaryCTA = app.buttons["premium.inline.primary"]
        waitForHittable(primaryCTA)
        primaryCTA.tap()

        waitForPaywall(in: app)
    }

    func testSavingAmbienceRequiresPremiumForFreeUsers() throws {
        let app = makeApp()
        app.launch()

        let ambiencesButton = button(in: app, id: "home.bottom.compose")
        waitForHittable(ambiencesButton)
        ambiencesButton.tap()

        let ambiencesPanel = app.otherElements["panel.compose.container"]
        waitForExistence(of: ambiencesPanel)

        let saveButton = app.buttons["compose.ambience.save"]
        waitForHittable(saveButton)
        saveButton.tap()

        waitForExistence(of: app.otherElements["premium.inline.preset"])
        XCTAssertFalse(app.otherElements["compose.ambience.editor"].exists)
        XCTAssertFalse(app.buttons["premium.paywall.close"].exists)
    }

    func testLockedBinauralTrackKeepsPanelOpen() throws {
        let app = makeApp()
        app.launch()

        let binauralButton = button(in: app, id: "home.bottom.binaural")
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

    func testSavedAmbienceStartsLocalizedMixAndKeepsMixerClean() throws {
        let app = makeComposerApp()
        app.launch()

        let composeButton = button(in: app, id: "home.bottom.compose")
        waitForHittable(composeButton)
        composeButton.tap()

        let panel = app.otherElements["panel.compose.container"]
        waitForExistence(of: panel)
        waitForExistence(of: app.staticTexts["Mes ambiances"])
        waitForExistence(of: app.staticTexts["Sauvegardez, lancez et façonnez vos ambiances préférées."])
        waitForExistence(of: app.staticTexts["Brise marine"])
        waitForExistence(of: app.staticTexts["Ce qui va se passer"])
        waitForExistence(of: app.staticTexts["Oasis combine ces couches et lance une ambiance claire."])
        waitForExistence(of: app.staticTexts["Décor sonore"])
        waitForExistence(of: app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Fin douce")).firstMatch)

        let startAmbience = app.buttons["compose.ambience.start"]
        waitForHittable(startAmbience)
        startAmbience.tap()

        waitForNonExistence(of: panel)
        XCTAssertEqual(button(in: app, id: "home.bottom.playback").label, "Pause")
        let ambienceStatus = element(in: app, id: "home.ambience.status")
        waitForExistence(of: ambienceStatus)
        XCTAssertTrue(ambienceStatus.label.contains("Ambiance active"))
        waitForExistence(of: button(in: app, id: "home.ambience.stop"))
        waitForExistence(of: element(in: app, id: "home.ambience.rest-cue"))
        XCTAssertFalse(app.buttons["home.header.active-filter"].exists)
        XCTAssertFalse(app.buttons["home.bottom.compose"].exists)
        XCTAssertFalse(app.buttons["home.bottom.presets"].exists)
        XCTAssertFalse(app.buttons["home.bottom.binaural"].exists)
        waitForNonExistence(of: app.buttons["home.active.scene"], timeout: 3)
        XCTAssertFalse(app.buttons["premium.paywall.close"].exists)

        waitForExistence(of: app.staticTexts["Oiseaux"])
        waitForExistence(of: app.staticTexts["Vent"])
        waitForExistence(of: app.staticTexts["Plage"])
    }

    func testSavedAmbienceCanBeReplacedInTwoTaps() throws {
        let app = makeComposerApp()
        app.launch()

        let composeButton = button(in: app, id: "home.bottom.compose")
        waitForHittable(composeButton)
        composeButton.tap()

        let startAmbience = app.buttons["compose.ambience.start"]
        waitForHittable(startAmbience)
        startAmbience.tap()

        waitForNonExistence(of: app.otherElements["panel.compose.container"])
        XCTAssertEqual(button(in: app, id: "home.bottom.playback").label, "Pause")

        let ambienceStatus = element(in: app, id: "home.ambience.status")
        tapElementReliably(ambienceStatus)

        let reopenedPanel = app.otherElements["panel.compose.container"]
        waitForExistence(of: reopenedPanel)
        waitForExistence(of: startAmbience)
        XCTAssertTrue(
            startAmbience.label.contains("Stopper l’ambiance"),
            "Expected stop ambience CTA, got: \(startAmbience.label)"
        )

        let calmAmbience = app.buttons["compose.ambience.preset_default_calm"]
        waitForHittable(calmAmbience)
        calmAmbience.tap()

        waitForHittable(startAmbience)
        XCTAssertTrue(
            startAmbience.label.contains("Remplacer l’ambiance"),
            "Expected replace ambience CTA, got: \(startAmbience.label)"
        )
        startAmbience.tap()

        waitForNonExistence(of: app.otherElements["panel.compose.container"])
        XCTAssertEqual(button(in: app, id: "home.bottom.playback").label, "Pause")
        waitForNonExistence(of: app.buttons["home.active.scene"], timeout: 3)
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

    private func makeComposerApp(resetState: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-OASISPremiumOverride", "free",
            "-AppleLanguages", "(fr)",
            "-AppleLocale", "fr_FR"
        ]
        if resetState {
            app.launchArguments += ["-OASISResetState", "YES"]
        }
        return app
    }

    private func makePremiumComposerApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-OASISPremiumOverride", "premium",
            "-OASISResetState", "YES",
            "-AppleLanguages", "(fr)",
            "-AppleLocale", "fr_FR"
        ]
        return app
    }

    private func button(in app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .button).matching(identifier: id).firstMatch
    }

    private func element(in app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
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

    private func waitForNonExistence(of element: XCUIElement, timeout: TimeInterval = 8) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Element still exists: \(element)")
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
