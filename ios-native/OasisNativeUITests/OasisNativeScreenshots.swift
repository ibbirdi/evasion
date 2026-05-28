import XCTest

/// App Store screenshot test producing 10 captures per language. Each capture tells one
/// beat of the marketing narrative: hook → differentiators → depth → monetisation.
///
/// Designed to feed Figma comps that add headline copy, device frames and backgrounds.
/// Every scenario uses its own `launchApp` call so each screenshot starts from a clean
/// deterministic state — slower than navigating, but robust across 6 locales.
///
/// Captures:
///   01_hero            — Premium mix playing, waveform active, OASIS logo visible
///   02_library         — Premium scroll showing the international provenance (flags)
///   03_detail_sheet    — `SoundDetailSheet` open on Savanna (new sound) at .large detent
///   04_binaural        — Binaural panel with the 4 brainwave tracks
///   05_spatial         — Spatial 3D placement panel
///   06_ambiences       — My ambiences panel with saved Oasis mixes
///   07_timer           — Timer menu open with all four duration options
///   08_free_home       — Free tier base screen with the three starter sounds playing
///   09_noise           — Premium noise layers visible and active in the mixer
///   10_paywall         — Premium paywall triggered from the library Premium teaser
@MainActor
final class OasisNativeScreenshots: XCTestCase {

    override func setUpWithError() throws {
        // If scenario 3's tap can't find an element, we don't want to abort the whole
        // suite and force Fastlane to retry — scenarios 4-10 would never run, wasting
        // 30+ minutes per language. Record the failure and continue.
        continueAfterFailure = true
    }

    func testAppStoreScreenshots() throws {
        // All 10 scenarios enabled. Each screenshot captures one beat of the
        // marketing narrative: hook → differentiators → depth → monetisation.
        let onlyScenarios: Set<String>? = nil

        func shouldRun(_ name: String) -> Bool {
            guard let onlyScenarios, !onlyScenarios.isEmpty else { return true }
            return onlyScenarios.contains(name)
        }

        // MARK: — Premium scenarios (8)

        if shouldRun("01_hero") {
            runScenario { app in
                // 01 Hero — rich mix playing, waveform undulating with the palette.
                launchApp(app, premiumOverride: "premium")
                startPlayingMix(in: app, shuffleFirst: true)
                snapshot("01_hero", waitForLoadingIndicator: false)
                snapshotElement("01_active_forest", element: element(in: app, id: "channel.row.foret"))
            }
        }

        if shouldRun("02_library") {
            runScenario { app in
                // 02 Library — rich 10-channel mix playing, scrolled into the
                // library so provenance-rich premium rows are visible.
                launchApp(app, premiumOverride: "premium")
                startPlayingMix(in: app, shuffleFirst: true)
                scrollToElement(id: "channel.row.riviere", in: app, maxSwipes: 6)
                pause(seconds: 0.3)
                snapshot("02_library", waitForLoadingIndicator: false)
                snapshotElement("02_active_river", element: element(in: app, id: "channel.row.riviere"))
            }
        }

        if shouldRun("03_detail_sheet") {
            runScenario { app in
                // 03 Detail sheet — Savanna (flag, region, author, licence). Opens at .large
                // under screenshot automation so the full content is in frame. Playback is
                // running underneath so the waveform in the header stays alive.
                launchApp(app, premiumOverride: "premium")
                startPlayingMix(in: app, shuffleFirst: true)
                scrollToElement(id: "channel.identity.savane", in: app, maxSwipes: 10)
                tap(button(in: app, id: "channel.identity.savane"))
                _ = panel(in: app, id: "panel.sound-detail.container").waitForExistence(timeout: 6)
                pause(seconds: 0.6)
                snapshot("03_detail_sheet", waitForLoadingIndicator: false)
                snapshotElement("03_detail_map", element: element(in: app, id: "sound.detail.map"))
            }
        }

        if shouldRun("04_binaural") {
            runScenario { app in
                // 04 Binaural panel — Delta (free) + Theta/Alpha/Beta (premium) visible.
                // Ambient mix also playing so the background above the sheet feels alive.
                // Binaural button lives in the bottom bar (was moved out of the
                // header when the native toolbar took over).
                launchApp(app, premiumOverride: "premium")
                startPlayingMix(in: app, shuffleFirst: true)
                waitForHittable(button(in: app, id: "home.bottom.binaural"))
                tap(button(in: app, id: "home.bottom.binaural"))
                _ = panel(in: app, id: "panel.binaural.container").waitForExistence(timeout: 6)
                pause(seconds: 0.5)
                snapshot("04_binaural", waitForLoadingIndicator: false)
                snapshotElement("04_binaural_modes", element: element(in: app, id: "binaural.track.grid"))
            }
        }

        if shouldRun("05_spatial") {
            runScenario { app in
                // 05 Spatial — 3D placement panel opened on the first audio row.
                launchApp(app, premiumOverride: "premium")
                startPlayingMix(in: app, shuffleFirst: true)
                waitForHittable(button(in: app, id: "channel.spatial.oiseaux"))
                tap(button(in: app, id: "channel.spatial.oiseaux"))
                _ = panel(in: app, id: "panel.spatial.container").waitForExistence(timeout: 6)
                pause(seconds: 0.5)
                snapshot("05_spatial", waitForLoadingIndicator: false)
                snapshotElement("05_spatial_stage", element: element(in: app, id: "spatial.stage"))
            }
        }

        if shouldRun("06_ambiences") {
            runScenario { app in
                // 06 My ambiences panel — saved Oasis mixes in one surface.
                launchApp(app, premiumOverride: "premium")
                startPlayingMix(in: app, shuffleFirst: true)
                waitForHittable(button(in: app, id: "home.bottom.compose"))
                tap(button(in: app, id: "home.bottom.compose"))
                _ = panel(in: app, id: "panel.compose.container").waitForExistence(timeout: 6)
                pause(seconds: 0.5)
                snapshot("06_ambiences", waitForLoadingIndicator: false)
                snapshotElement("06_ambience_duration", element: element(in: app, id: "compose.ambience.duration"))
                snapshotElement("06_saved_starter", element: element(in: app, id: "compose.ambience.preset_default_starter"))
                snapshotElement("06_saved_reset", element: element(in: app, id: "compose.ambience.preset_default_reset"))
                snapshotElement("06_saved_storm", element: element(in: app, id: "compose.ambience.preset_default_storm"))
            }
        }

        if shouldRun("07_timer") {
            runScenario { app in
                // 07 Timer menu — iOS Menu popover with the four duration options, localised.
                launchApp(app, premiumOverride: "premium")
                startPlayingMix(in: app, shuffleFirst: true)
                waitForHittable(button(in: app, id: "home.header.timer"))
                tap(button(in: app, id: "home.header.timer"))
                pause(seconds: 0.8) // let the system menu animate in
                snapshot("07_timer", waitForLoadingIndicator: false)
                snapshotElement("07_active_rain", element: element(in: app, id: "channel.row.pluie"))
            }
        }

        // MARK: — Free scenarios (2)

        if shouldRun("08_free_home") {
            runScenario { app in
                // 08 Free home — 3 starter sounds playing. Shows the ungated experience.
                launchApp(app, premiumOverride: "free")
                startPlayingMix(in: app, shuffleFirst: true)
                snapshot("08_free_home", waitForLoadingIndicator: false)
                snapshotElement("08_active_birds", element: element(in: app, id: "channel.row.oiseaux"))
            }
        }

        if shouldRun("09_noise") {
            runScenario { app in
                // 09 Noise layers — premium procedural noise rows active in the mixer.
                // The App Store slide uses this to explain the extra noise-cover layers.
                launchApp(app, premiumOverride: "premium")
                startPlayingMix(in: app, shuffleFirst: true)
                scrollToElement(id: "noise.row.green", in: app, maxSwipes: 12)
                tap(button(in: app, id: "noise.mute.green"))
                scrollToElement(id: "noise.row.fan", in: app, maxSwipes: 4)
                tap(button(in: app, id: "noise.mute.fan"))
                pause(seconds: 0.5)
                snapshot("09_noise", waitForLoadingIndicator: false)
                snapshotElement("09_noise_green", element: element(in: app, id: "noise.row.green"))
                snapshotElement("09_noise_fan", element: element(in: app, id: "noise.row.fan"))
            }
        }

        if shouldRun("10_paywall") {
            runScenario { app in
                // 10 Paywall — triggered from the teaser "See Premium" CTA.
                launchApp(app, premiumOverride: "free")
                startPlayingMix(in: app, shuffleFirst: true)
                scrollToElement(id: "premium.library.teaser", in: app, maxSwipes: 10)
                waitForHittable(button(in: app, id: "premium.library.teaser.primary"))
                tap(button(in: app, id: "premium.library.teaser.primary"))
                _ = panel(in: app, id: "premium.paywall.container").waitForExistence(timeout: 8)
                pause(seconds: 0.8)
                snapshot("10_paywall", waitForLoadingIndicator: false)
                snapshotElement("10_paywall_primary", element: element(in: app, id: "premium.paywall.primary"))
            }
        }
    }

    /// Starts playback with a (optionally shuffled) mix. Every screenshot is taken with
    /// playback running, which keeps the header waveform animated and every active row
    /// lit up.
    ///
    /// Important: in screenshot automation, tapping the shuffle button already sets
    /// `isPlaying = true` inside `applyScreenshotShuffle()`. Tapping the playback button
    /// after shuffle would therefore TOGGLE playback off. So when we shuffle, we skip
    /// the playback tap. Non-shuffled scenarios still need the explicit playback tap.
    private func startPlayingMix(in app: XCUIApplication, shuffleFirst: Bool) {
        if shuffleFirst {
            waitForHittable(button(in: app, id: "home.bottom.shuffle"))
            tap(button(in: app, id: "home.bottom.shuffle"))
        } else {
            waitForHittable(button(in: app, id: "home.bottom.playback"))
            tap(button(in: app, id: "home.bottom.playback"))
        }
        pause(seconds: 0.8) // let the waveform react to the active palette
    }

    // MARK: - Scenario harness

    /// Runs a scenario with a fresh `XCUIApplication`. Terminates afterwards so the next
    /// scenario boots from a clean process — marginally slower but dead reliable across
    /// 6 languages × 10 captures.
    private func runScenario(_ body: (XCUIApplication) -> Void) {
        let app = XCUIApplication()
        body(app)
        app.terminate()
    }

    // MARK: - Launch helpers

    private func launchApp(_ app: XCUIApplication, premiumOverride: String) {
        setupSnapshot(app)
        app.launchArguments += [
            "-OASISPremiumOverride", premiumOverride,
            "-OASISResetState", "YES",
            "-OASISImmersiveAudioEnabled", "YES"
        ]
        app.launch()
        assertImmersiveAudioEnabled(in: app)
    }

    private func assertImmersiveAudioEnabled(in app: XCUIApplication) {
        let immersiveToggle = button(in: app, id: "home.header.immersive")
        _ = immersiveToggle.waitForExistence(timeout: 5)
        XCTAssertTrue(immersiveToggle.isSelected, "App Store screenshots must launch with immersive sound enabled.")
    }

    // MARK: - Element lookup

    private func button(in app: XCUIApplication, id: String) -> XCUIElement {
        app.buttons[id]
    }

    private func panel(in app: XCUIApplication, id: String) -> XCUIElement {
        app.otherElements[id]
    }

    private func element(in app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func element(in app: XCUIApplication, label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private var timerOptionLabels: [(assetSuffix: String, label: String)] {
        let usesEnglishHour = Snapshot.deviceLanguage.hasPrefix("en")
        return [
            ("15", "15 min"),
            ("30", "30 min"),
            ("60", usesEnglishHour ? "1 hr" : "1 h"),
            ("120", usesEnglishHour ? "2 hr" : "2 h")
        ]
    }

    // MARK: - Waiting

    @discardableResult
    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists && element.isHittable { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return false
    }

    /// Taps the element, retrying while the UI might still be animating in.
    private func tap(_ element: XCUIElement, timeout: TimeInterval = 5) {
        _ = waitForHittable(element, timeout: timeout)
        element.tap()
    }

    private func pause(seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    // MARK: - Scrolling

    /// Swipes up inside the main scroll view until the element with `id` becomes
    /// hittable, or until `maxSwipes` is reached. Works for both button and
    /// container identifiers since we look up both collections.
    private func scrollToElement(id: String, in app: XCUIApplication, maxSwipes: Int = 8) {
        let scrollView = app.scrollViews["home.scroll"]
        let target: XCUIElement = {
            if app.buttons[id].exists { return app.buttons[id] }
            if app.otherElements[id].exists { return app.otherElements[id] }
            return app.descendants(matching: .any).matching(identifier: id).firstMatch
        }()

        var attempts = 0
        while !target.isHittable && attempts < maxSwipes {
            if scrollView.exists {
                scrollView.swipeUp()
            } else {
                app.swipeUp()
            }
            attempts += 1
        }
    }
}
