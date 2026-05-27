import XCTest

@MainActor
final class OasisNativePremiumFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLockedPresetShowsInlineUpsellBeforePaywall() throws {
        let app = makeApp()
        app.launch()

        let presetsButton = button(in: app, id: "home.bottom.presets")
        waitForHittable(presetsButton)
        presetsButton.tap()

        let presetsPanel = app.otherElements["panel.presets.container"]
        waitForExistence(of: presetsPanel)

        let lockedPreset = app.buttons["presets.row.button.preset_default_storm"]
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

    func testGuidedRoutineStartsLocalizedMixAndKeepsMixerClean() throws {
        let app = makeComposerApp()
        app.launch()

        let composeButton = button(in: app, id: "home.bottom.compose")
        waitForHittable(composeButton)
        composeButton.tap()

        let panel = app.otherElements["panel.compose.container"]
        waitForExistence(of: panel)
        waitForExistence(of: app.staticTexts["Routines"])
        waitForExistence(of: app.staticTexts["Choisissez un besoin, voyez le mix, puis lancez-le."])
        waitForExistence(of: app.staticTexts["Sieste courte"])
        waitForExistence(of: app.staticTexts["Ce qui va se passer"])
        waitForExistence(of: app.staticTexts["Oasis combine ces couches et lance une routine claire."])
        waitForExistence(of: app.staticTexts["Décor sonore"])
        waitForExistence(of: app.staticTexts["Bruit de fond"])
        waitForExistence(of: app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Fin douce")).firstMatch)

        let startRoutine = app.buttons["compose.routine.start"]
        waitForHittable(startRoutine)
        startRoutine.tap()

        waitForNonExistence(of: panel)
        XCTAssertEqual(button(in: app, id: "home.bottom.playback").label, "Pause")
        let routineStatus = element(in: app, id: "home.routine.status")
        waitForExistence(of: routineStatus)
        XCTAssertTrue(routineStatus.label.contains("Routine active"))
        waitForExistence(of: button(in: app, id: "home.routine.stop"))
        waitForExistence(of: element(in: app, id: "home.routine.rest-cue"))
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

    func testGuidedRoutineCanBeReplacedInTwoTaps() throws {
        let app = makeComposerApp()
        app.launch()

        let composeButton = button(in: app, id: "home.bottom.compose")
        waitForHittable(composeButton)
        composeButton.tap()

        let resetRoutine = app.buttons["compose.guided.reset"]
        waitForHittable(resetRoutine)
        resetRoutine.tap()

        let startRoutine = app.buttons["compose.routine.start"]
        waitForHittable(startRoutine)
        startRoutine.tap()

        waitForNonExistence(of: app.otherElements["panel.compose.container"])
        XCTAssertEqual(button(in: app, id: "home.bottom.playback").label, "Pause")

        let routineStatus = element(in: app, id: "home.routine.status")
        tapElementReliably(routineStatus)

        let reopenedPanel = app.otherElements["panel.compose.container"]
        waitForExistence(of: reopenedPanel)
        waitForExistence(of: startRoutine)
        XCTAssertTrue(
            startRoutine.label.contains("Stopper la routine"),
            "Expected stop routine CTA, got: \(startRoutine.label)"
        )

        let napRoutine = app.buttons["compose.guided.nap"]
        waitForHittable(napRoutine)
        napRoutine.tap()

        waitForHittable(startRoutine)
        XCTAssertTrue(
            startRoutine.label.contains("Remplacer la routine"),
            "Expected replace routine CTA, got: \(startRoutine.label)"
        )
        startRoutine.tap()

        waitForNonExistence(of: app.otherElements["panel.compose.container"])
        XCTAssertEqual(button(in: app, id: "home.bottom.playback").label, "Pause")
        waitForNonExistence(of: app.buttons["home.active.scene"], timeout: 3)
    }

    func testPremiumGuidedRoutineShowsUpsellForFreeUsers() throws {
        let app = makeComposerApp()
        app.launch()

        let composeButton = button(in: app, id: "home.bottom.compose")
        waitForHittable(composeButton)
        composeButton.tap()

        let deepSleepRoutine = app.buttons["compose.guided.deepSleep"]
        waitForHittable(deepSleepRoutine)
        deepSleepRoutine.tap()

        let startRoutine = app.buttons["compose.routine.start"]
        waitForHittable(startRoutine)
        XCTAssertTrue(
            startRoutine.label.contains("Premium"),
            "Expected premium CTA, got: \(startRoutine.label)"
        )
        startRoutine.tap()

        waitForExistence(of: app.otherElements["premium.inline.composer"])
        XCTAssertTrue(app.otherElements["panel.compose.container"].exists)
        XCTAssertFalse(app.buttons["premium.paywall.close"].exists)
    }

    func testPremiumGuidedRoutineSummarizesExtraLayers() throws {
        let app = makePremiumComposerApp()
        app.launch()

        let composeButton = button(in: app, id: "home.bottom.compose")
        waitForHittable(composeButton)
        composeButton.tap()

        waitForExistence(of: app.otherElements["panel.compose.container"])
        let deepSleepRoutine = app.buttons["compose.guided.deepSleep"]
        waitForHittable(deepSleepRoutine)
        deepSleepRoutine.tap()
        waitForExistence(of: app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "+2")).firstMatch)

        let startRoutine = app.buttons["compose.routine.start"]
        waitForHittable(startRoutine)
        startRoutine.tap()

        waitForNonExistence(of: app.otherElements["panel.compose.container"])
        waitForExistence(of: element(in: app, id: "home.routine.status"))
        waitForExistence(of: element(in: app, id: "home.routine.supporting-layers"))
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
