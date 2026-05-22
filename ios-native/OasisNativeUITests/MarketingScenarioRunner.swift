import XCTest

/// Generic XCUITest harness that replays a marketing scenario inside a running
/// simulator. The scenario is a JSON document describing a timeline of actions
/// (tap, set slider, drag the spatial puck, …) and is consumed by the
/// Node-side video factory (`marketing-video-factory/`).
///
/// The Node driver writes the scenario to a known path, starts a screen
/// recording on the booted simulator, then invokes this XCUITest. The test
/// reads the scenario, drives the app on a precise schedule, then exits. The
/// recording is post-processed (crop / overlay text / mix Oasis audio) on the
/// host side.
///
/// Scenario JSON path is taken from the `OASIS_SCENARIO_PATH` environment
/// variable; falls back to `/tmp/oasis-marketing/scenario.json`.
@MainActor
final class MarketingScenarioRunner: XCTestCase {

    override func setUpWithError() throws {
        // Keep going past minor failures so the recording captures whatever
        // beat still works. The Node driver inspects the test's exit code only
        // as a soft signal.
        continueAfterFailure = true
    }

    func testRunScenario() throws {
        let scenario = try loadScenario()
        let locale = scenario.locale ?? "en_US"
        let appleLang = scenario.appleLanguages ?? "en"
        let app = XCUIApplication()
        app.launchArguments += [
            "-ui_testing",
            "-OASISPremiumOverride", scenario.premium,
            "-OASISResetState", "YES",
            "-AppleLanguages", "(\(appleLang))",
            "-AppleLocale", locale,
        ]
        app.launch()

        // Let the home screen finish its first paint so action timestamps line
        // up with what the viewer sees in the recording.
        sleep(seconds: 0.6)

        // Run any scenario `setup` actions BEFORE the recording's visible
        // window starts. The start marker is written after these complete, so
        // FFmpeg's `-ss` lands past their animations and the final video opens
        // with the desired pre-state (filter toggled, sheet pre-opened, …).
        if let setup = scenario.setup, !setup.isEmpty {
            let setupStarted = Date()
            for action in setup.sorted(by: { $0.at < $1.at }) {
                let wait = action.at - Date().timeIntervalSince(setupStarted)
                if wait > 0 { sleep(seconds: wait) }
                execute(action: action, in: app)
            }
            // Give SwiftUI a beat to finish its setup animations before we
            // mark the visible scenario start.
            sleep(seconds: 0.5)
        }

        // Synchronisation marker: the Node driver reads this Unix timestamp to
        // know exactly where in the recording the scenario started, then uses
        // `-ss <offset>` in FFmpeg to skip the boot/launch overhead.
        writeStartMarker()

        let startedAt = Date()
        let actions = scenario.actions.sorted { $0.at < $1.at }
        for action in actions {
            let elapsed = Date().timeIntervalSince(startedAt)
            let wait = action.at - elapsed
            if wait > 0 { sleep(seconds: wait) }
            execute(action: action, in: app)
        }

        // Hold the final frame for the remaining duration PLUS a safety buffer
        // so the simulator's post-test teardown (app termination → springboard)
        // happens AFTER the FFmpeg trim boundary. Without this buffer the last
        // few frames of the body mp4 capture the home screen, which then bleeds
        // into the body → outro crossfade.
        let total = Date().timeIntervalSince(startedAt)
        let tail = scenario.duration - total + 2.0
        if tail > 0 { sleep(seconds: tail) }
    }

    // MARK: - Scenario loading

    private func loadScenario() throws -> Scenario {
        let env = ProcessInfo.processInfo.environment
        let path = env["OASIS_SCENARIO_PATH"] ?? "/tmp/oasis-marketing/scenario.json"
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Scenario.self, from: data)
    }

    private func writeStartMarker() {
        let env = ProcessInfo.processInfo.environment
        let path = env["OASIS_START_MARKER_PATH"] ?? "/tmp/oasis-marketing/scenario-started.txt"
        let unix = Date().timeIntervalSince1970
        let text = String(format: "%.6f\n", unix)
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: (path as NSString).deletingLastPathComponent),
            withIntermediateDirectories: true
        )
        try? text.data(using: .utf8)?.write(to: URL(fileURLWithPath: path))
    }

    // MARK: - Action dispatch

    private func execute(action: Action, in app: XCUIApplication) {
        switch action {
        case .wait(let a):
            sleep(seconds: a.duration)
        case .tap(let a):
            tap(target: a.target, kind: a.kind, in: app)
        case .setSlider(let a):
            setSlider(target: a.target, value: a.value, in: app)
        case .dragSpatial(let a):
            dragSpatial(to: a.to, from: a.from, duration: a.duration, in: app)
        case .swipe(let a):
            swipe(target: a.target, direction: a.direction, in: app)
        case .scrollTo(let a):
            scrollTo(target: a.target, maxSwipes: a.maxSwipes, in: app)
        case .dismissPanel:
            dismissPanel(in: app)
        }
    }

    // MARK: - Action implementations

    private func tap(target: String, kind: ActionKind, in app: XCUIApplication) {
        let element = resolve(target: target, kind: kind, in: app)
        if waitForHittable(element, timeout: 3) {
            element.tap()
            return
        }
        // Some SwiftUI toolbar items (iOS 26 Liquid Glass wrapping) report
        // `isHittable == false` even when visible and tappable. Fall back to
        // a coordinate tap at the element's frame centre.
        if element.exists && element.frame.size.width > 0 {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }
        scrollTo(target: target, maxSwipes: 8, in: app)
        if waitForHittable(element, timeout: 2) {
            element.tap()
            return
        }
        XCTFail("Element '\(target)' not tappable")
    }

    private func setSlider(target: String, value: Double, in app: XCUIApplication) {
        let slider = app.sliders[target]
        if !slider.exists {
            scrollTo(target: target, maxSwipes: 8, in: app)
        }
        guard waitForExistence(slider, timeout: 4) else {
            XCTFail("Slider '\(target)' not found")
            return
        }
        let clamped = max(0.0, min(1.0, value))
        slider.adjust(toNormalizedSliderPosition: CGFloat(clamped))
    }

    private func dragSpatial(
        to destination: NormalizedPoint,
        from origin: NormalizedPoint?,
        duration: Double,
        in app: XCUIApplication
    ) {
        let stage = app.otherElements["spatial.stage"]
        guard waitForExistence(stage, timeout: 4) else {
            XCTFail("spatial.stage not found — is the spatial panel open?")
            return
        }
        // Normalized [-1, 1] (x: left↔right, y: front↔back) → XCUICoordinate
        // normalized offset [0, 1] within the stage element's bounds.
        func toCoord(_ p: NormalizedPoint) -> XCUICoordinate {
            let nx = max(0.02, min(0.98, (p.x + 1) * 0.5))
            let ny = max(0.02, min(0.98, (p.y + 1) * 0.5))
            return stage.coordinate(withNormalizedOffset: CGVector(dx: nx, dy: ny))
        }
        let start = toCoord(origin ?? NormalizedPoint(x: 0, y: 0))
        let end = toCoord(destination)
        let pressDuration = max(duration, 0.1)
        start.press(forDuration: 0.0, thenDragTo: end, withVelocity: 200, thenHoldForDuration: pressDuration)
    }

    private func swipe(target: String, direction: SwipeDirection, in app: XCUIApplication) {
        let el = resolve(target: target, kind: .any, in: app)
        guard waitForExistence(el, timeout: 4) else {
            XCTFail("Swipe target '\(target)' not found")
            return
        }
        switch direction {
        case .up:    el.swipeUp()
        case .down:  el.swipeDown()
        case .left:  el.swipeLeft()
        case .right: el.swipeRight()
        }
    }

    private func scrollTo(target: String, maxSwipes: Int, in app: XCUIApplication) {
        let scrollView = app.scrollViews["home.scroll"]
        let element = app.descendants(matching: .any).matching(identifier: target).firstMatch
        var attempts = 0
        while !element.isHittable && attempts < maxSwipes {
            if scrollView.exists {
                scrollView.swipeUp()
            } else {
                app.swipeUp()
            }
            attempts += 1
        }
    }

    private func dismissPanel(in app: XCUIApplication) {
        // Drag the topmost sheet downward. With iOS presentation detents this
        // dismisses the sheet whether it is .medium or .large.
        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.0))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    // MARK: - Element resolution

    private func resolve(target: String, kind: ActionKind, in app: XCUIApplication) -> XCUIElement {
        switch kind {
        case .button:
            // SwiftUI ToolbarItem buttons (e.g. `home.header.*`) aren't always
            // surfaced under `app.buttons`. Try a few common containers before
            // falling back to a global descendants scan.
            let candidates: [XCUIElement] = [
                app.buttons[target],
                app.navigationBars.buttons[target],
                app.otherElements[target],
            ]
            if let hit = candidates.first(where: { $0.exists }) { return hit }
            return app.descendants(matching: .any).matching(identifier: target).firstMatch
        case .otherElement:
            let direct = app.otherElements[target]
            return direct.exists ? direct : app.descendants(matching: .any).matching(identifier: target).firstMatch
        case .slider:
            return app.sliders[target]
        case .any:
            return app.descendants(matching: .any).matching(identifier: target).firstMatch
        }
    }

    // MARK: - Waiting helpers

    @discardableResult
    private func waitForExistence(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        if element.exists { return true }
        return element.waitForExistence(timeout: timeout)
    }

    @discardableResult
    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists && element.isHittable { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.08))
        }
        return false
    }

    private func sleep(seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(max(0, seconds)))
    }
}

// MARK: - Scenario decoding types

private struct Scenario: Decodable {
    let id: String
    let duration: Double
    let premium: String
    let setup: [Action]?
    let actions: [Action]
    let locale: String?
    let appleLanguages: String?
}

private enum ActionKind: String, Decodable {
    case button, otherElement, slider, any
}

private enum SwipeDirection: String, Decodable {
    case up, down, left, right
}

private struct NormalizedPoint: Decodable {
    let x: Double
    let y: Double
}

private enum Action: Decodable {
    case wait(WaitAction)
    case tap(TapAction)
    case setSlider(SetSliderAction)
    case dragSpatial(DragSpatialAction)
    case swipe(SwipeAction)
    case scrollTo(ScrollToAction)
    case dismissPanel(DismissPanelAction)

    var at: Double {
        switch self {
        case .wait(let a): return a.at
        case .tap(let a): return a.at
        case .setSlider(let a): return a.at
        case .dragSpatial(let a): return a.at
        case .swipe(let a): return a.at
        case .scrollTo(let a): return a.at
        case .dismissPanel(let a): return a.at
        }
    }

    private enum CodingKeys: String, CodingKey { case type }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        let single = try decoder.singleValueContainer()
        switch type {
        case "wait":         self = .wait(try single.decode(WaitAction.self))
        case "tap":          self = .tap(try single.decode(TapAction.self))
        case "setSlider":    self = .setSlider(try single.decode(SetSliderAction.self))
        case "dragSpatial":  self = .dragSpatial(try single.decode(DragSpatialAction.self))
        case "swipe":        self = .swipe(try single.decode(SwipeAction.self))
        case "scrollTo":     self = .scrollTo(try single.decode(ScrollToAction.self))
        case "dismissPanel": self = .dismissPanel(try single.decode(DismissPanelAction.self))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: c,
                debugDescription: "Unknown action type: \(type)"
            )
        }
    }
}

private struct WaitAction: Decodable {
    let at: Double
    let duration: Double
}
private struct TapAction: Decodable {
    let at: Double
    let target: String
    let kind: ActionKind
}
private struct SetSliderAction: Decodable {
    let at: Double
    let target: String
    let value: Double
}
private struct DragSpatialAction: Decodable {
    let at: Double
    let to: NormalizedPoint
    let from: NormalizedPoint?
    let duration: Double
}
private struct SwipeAction: Decodable {
    let at: Double
    let target: String
    let direction: SwipeDirection
}
private struct ScrollToAction: Decodable {
    let at: Double
    let target: String
    let maxSwipes: Int
}
private struct DismissPanelAction: Decodable {
    let at: Double
}
