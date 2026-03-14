import XCTest

@MainActor
final class OasisNativeScreenshots: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppStoreScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app, waitForAnimations: true)
        app.launchArguments += [
            "-OASISPremiumOverride", "premium",
            "-OASISResetState", "YES"
        ]
        app.launch()

        let timerButton = button(in: app, id: "home.header.timer")
        waitForHittable(timerButton)
        timerButton.tap()
        let thirtyMinutesButton = app.buttons.matching(identifier: "30 min").firstMatch
        waitForHittable(thirtyMinutesButton)
        thirtyMinutesButton.tap()

        captureShuffleState(named: "01_shuffle_a", in: app)
        captureShuffleState(named: "02_shuffle_b", in: app)
        captureShuffleState(named: "03_shuffle_c", in: app)

        let headerPresetsButton = button(in: app, id: "home.header.presets")
        waitForHittable(headerPresetsButton)
        headerPresetsButton.tap()
        let presetsPanel = panel(in: app, id: "panel.presets.container")
        waitForExistence(of: presetsPanel)
        tapFirstPreset(in: app)
        waitForExistence(of: presetsPanel)
        snapshot("04_presets", waitForLoadingIndicator: false)
        dismissSheet(panel: presetsPanel, in: app)

        let binauralButton = button(in: app, id: "home.header.binaural")
        waitForHittable(binauralButton)
        binauralButton.tap()
        let binauralPanel = panel(in: app, id: "panel.binaural.container")
        waitForExistence(of: binauralPanel)
        snapshot("05_binaural", waitForLoadingIndicator: false)
        dismissSheet(panel: binauralPanel, in: app)

        scrollToBottom(in: app)
        snapshot("06_bottom", waitForLoadingIndicator: false)
    }

    private func captureShuffleState(named name: String, in app: XCUIApplication) {
        let shuffleButton = button(in: app, id: "home.bottom.shuffle")
        waitForHittable(shuffleButton)
        shuffleButton.tap()
        snapshot(name, waitForLoadingIndicator: false)
    }

    private func scrollToBottom(in app: XCUIApplication) {
        let scrollView = app.scrollViews.matching(identifier: "home.scroll").firstMatch
        for _ in 0..<5 {
            scrollView.swipeUp()
        }
    }

    private func dismissSheet(panel: XCUIElement, in app: XCUIApplication, timeout: TimeInterval = 8) {
        waitForExistence(of: panel, timeout: timeout)

        let outsideTap = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.10))
        outsideTap.tap()

        let deadline = Date().addingTimeInterval(timeout)
        var didFallbackSwipe = false
        while Date() < deadline {
            if !panel.exists {
                return
            }
            if !didFallbackSwipe, Date() > deadline.addingTimeInterval(-timeout / 2) {
                didFallbackSwipe = true
                let start = panel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18))
                let end = panel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.92))
                start.press(forDuration: 0.05, thenDragTo: end)
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        XCTFail("Panel still visible after dismissal: \(panel)")
    }

    private func button(in app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .button).matching(identifier: id).firstMatch
    }

    private func panel(in app: XCUIApplication, id: String) -> XCUIElement {
        app.otherElements.matching(identifier: id).firstMatch
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

    private func tapFirstPreset(in app: XCUIApplication, timeout: TimeInterval = 8) {
        let presetsPanel = panel(in: app, id: "panel.presets.container")
        if presetsPanel.waitForExistence(timeout: timeout) {
            let presetButton = presetsPanel
                .descendants(matching: .button)
                .matching(identifier: "presets.row.preset_default_calm")
                .firstMatch

            if presetButton.exists {
                tapElementReliably(presetButton, timeout: 1)
                return
            }

            let coordinate = presetsPanel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.34))
            coordinate.tap()
            return
        }

        XCTFail("Presets panel not found")
    }

    private func tapElementReliably(_ element: XCUIElement, timeout: TimeInterval = 8) {
        waitForExistence(of: element, timeout: timeout)

        if element.isHittable {
            element.tap()
            return
        }

        let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
    }
}
