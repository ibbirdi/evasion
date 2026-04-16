import XCTest

@MainActor
final class OasisNativeScreenshots: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppStoreScreenshots() throws {
        let app = launchApp(premiumOverride: "free")

        waitForHittable(button(in: app, id: "home.header.timer"))
        snapshot("01_free_sleep", waitForLoadingIndicator: false)

        openTimerMenu(in: app)
        tapTimerMenuOption(in: app, candidates: ["30 min"])
        snapshot("02_free_timer", waitForLoadingIndicator: false)

        captureShuffleState(named: "03_free_shuffle", in: app)

        scrollToBottom(in: app)
        waitForExistence(of: app.otherElements.matching(identifier: "premium.library.teaser").firstMatch)
        snapshot("04_premium_library", waitForLoadingIndicator: false)

        openTimerMenu(in: app)
        tapTimerMenuOption(in: app, candidates: ["1 hr", "1 h", "1 Std."])
        waitForExistence(of: panel(in: app, id: "panel.timer.unlock"))
        snapshot("05_timer_upsell", waitForLoadingIndicator: false)

        app.terminate()

        let premiumApp = launchApp(premiumOverride: "premium")
        let binauralButton = button(in: premiumApp, id: "home.header.binaural")
        waitForHittable(binauralButton)
        binauralButton.tap()
        let binauralPanel = panel(in: premiumApp, id: "panel.binaural.container")
        waitForExistence(of: binauralPanel)
        snapshot("06_premium_binaural", waitForLoadingIndicator: false)
    }

    private func launchApp(premiumOverride: String) -> XCUIApplication {
        let app = XCUIApplication()
        setupSnapshot(app, waitForAnimations: true)
        app.launchArguments += [
            "-OASISPremiumOverride", premiumOverride,
            "-OASISResetState", "YES"
        ]
        app.launch()
        return app
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

    private func openTimerMenu(in app: XCUIApplication) {
        let timerButton = button(in: app, id: "home.header.timer")
        waitForHittable(timerButton)
        timerButton.tap()
    }

    private func tapTimerMenuOption(in app: XCUIApplication, candidates: [String], timeout: TimeInterval = 8) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for candidate in candidates {
                let option = app.buttons.matching(identifier: candidate).firstMatch
                if option.exists {
                    tapElementReliably(option, timeout: 1)
                    return
                }
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        XCTFail("Timer option not found: \(candidates.joined(separator: ", "))")
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
