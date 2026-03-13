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

        waitForHittable(app.buttons["home.header.timer"])
        app.buttons["home.header.timer"].tap()
        waitForHittable(app.buttons["30 min"])
        app.buttons["30 min"].tap()

        captureShuffleState(named: "01_shuffle_a", in: app)
        captureShuffleState(named: "02_shuffle_b", in: app)
        captureShuffleState(named: "03_shuffle_c", in: app)

        waitForHittable(app.buttons["home.bottom.presets"])
        app.buttons["home.bottom.presets"].tap()
        waitForLocalizedText(in: app, candidates: presetPanelTitles)
        waitForHittable(firstExistingStaticText(in: app, candidates: firstPresetTitles))
        firstExistingStaticText(in: app, candidates: firstPresetTitles).tap()

        waitForHittable(app.buttons["home.bottom.presets"])
        app.buttons["home.bottom.presets"].tap()
        waitForLocalizedText(in: app, candidates: presetPanelTitles)
        snapshot("04_presets", waitForLoadingIndicator: false)
        dismissSheet(on: app, waitingForTitlesToDisappear: presetPanelTitles)

        waitForHittable(app.buttons["home.header.binaural"])
        app.buttons["home.header.binaural"].tap()
        waitForLocalizedText(in: app, candidates: binauralPanelTitles)
        snapshot("05_binaural", waitForLoadingIndicator: false)
        dismissSheet(on: app, waitingForTitlesToDisappear: binauralPanelTitles)

        scrollToBottom(in: app)
        snapshot("06_bottom", waitForLoadingIndicator: false)
    }

    private func captureShuffleState(named name: String, in app: XCUIApplication) {
        waitForHittable(app.buttons["home.bottom.shuffle"])
        app.buttons["home.bottom.shuffle"].tap()
        snapshot(name, waitForLoadingIndicator: false)
    }

    private func scrollToBottom(in app: XCUIApplication) {
        let scrollView = app.scrollViews["home.scroll"]
        for _ in 0..<5 {
            scrollView.swipeUp()
        }
    }

    private func dismissSheet(on app: XCUIApplication, waitingForTitlesToDisappear titles: [String]) {
        let title = firstExistingStaticText(in: app, candidates: titles)
        if title.exists {
            let start = title.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            let end = start.withOffset(CGVector(dx: 0, dy: 360))
            start.press(forDuration: 0.05, thenDragTo: end)
        } else {
            app.swipeDown()
        }
        waitForLocalizedTextToDisappear(in: app, candidates: titles)
    }

    private var presetPanelTitles: [String] {
        [
            "My Oasis",
            "Mes Oasis",
            "Mis oasis",
            "Meine Oasis",
            "Le mie oasi",
            "Meus Oasis"
        ]
    }

    private var firstPresetTitles: [String] {
        [
            "Calm Forest",
            "Calme en forêt",
            "Bosque Tranquilo",
            "Ruhiger Wald",
            "Foresta Calma",
            "Floresta Calma"
        ]
    }

    private var binauralPanelTitles: [String] {
        [
            "BINAURAL BEATS",
            "SONS BINAURAUX",
            "SONIDOS BINAURALES",
            "BINAURALE BEATS",
            "SUONI BINAURALI",
            "SONS BINAURAIS"
        ]
    }

    private func firstExistingStaticText(in app: XCUIApplication, candidates: [String]) -> XCUIElement {
        for title in candidates {
            let text = app.staticTexts[title]
            if text.exists {
                return text
            }
        }

        return app.staticTexts[candidates[0]]
    }

    private func waitForLocalizedText(in app: XCUIApplication, candidates: [String], timeout: TimeInterval = 8) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            for title in candidates where app.staticTexts[title].exists {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        XCTFail("Localized text not found: \(candidates.joined(separator: ", "))")
    }

    private func waitForLocalizedTextToDisappear(in app: XCUIApplication, candidates: [String], timeout: TimeInterval = 8) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let anyVisible = candidates.contains { app.staticTexts[$0].exists }
            if !anyVisible {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        XCTFail("Localized text still visible: \(candidates.joined(separator: ", "))")
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
}
