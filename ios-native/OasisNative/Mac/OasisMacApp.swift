import AppKit
import Observation
import SwiftUI

@main
struct OasisMacApp: App {
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate

    init() {
        AppBootstrap.configure()
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
private final class MacAppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var statusItem: NSStatusItem?
    private var panelController: MacMenuBarPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        model.bootstrapIfNeeded()
        model.handleScenePhase(.active)

        panelController = MacMenuBarPanelController(model: model)
        configureStatusItem()
        updateStatusItem()
        observeStatusItemState()

        if AppConfiguration.isRunningMacScreenshotAutomation {
            openPanelForScreenshot(outputPath: AppConfiguration.macScreenshotOutputPath)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        model.handleScenePhase(.active)
    }

    func applicationWillResignActive(_ notification: Notification) {
        model.handleScenePhase(.inactive)
        panelController?.hide()
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.handleScenePhase(.background)
    }

    @objc private func togglePanel(_ sender: Any?) {
        Task { @MainActor in
            await Task.yield()
            guard let button = statusItem?.button else { return }
            panelController?.toggle(relativeTo: button)
            updateStatusItem()
        }
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item

        guard let button = item.button else { return }
        button.target = self
        button.action = #selector(togglePanel(_:))
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyUpOrDown
        button.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.contentTintColor = nil
        button.toolTip = L10n.string(L10n.App.title)
        // Mouse-up actions can be swallowed on the first click that activates a fresh LSUIElement app.
        _ = button.sendAction(on: [.leftMouseDown, .rightMouseDown])
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }
        let image = NSImage(systemSymbolName: "wind", accessibilityDescription: L10n.string(L10n.App.title))
        image?.isTemplate = true
        button.image = image
        button.contentTintColor = nil
    }

    private func openPanelForScreenshot(outputPath: String? = nil) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            guard let button = statusItem?.button else { return }
            panelController?.show(relativeTo: button)

            if let outputPath {
                try? await Task.sleep(for: .milliseconds(1_100))

                do {
                    guard let panelController else {
                        throw NSError(
                            domain: "oasis.mac_screenshot",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Panel controller is unavailable"]
                        )
                    }
                    try panelController.writeSnapshot(to: outputPath)
                    NSApp.terminate(nil)
                } catch {
                    let message = "Failed to write macOS screenshot: \(error.localizedDescription)\n"
                    FileHandle.standardError.write(Data(message.utf8))
                    exit(4)
                }
            }
        }
    }

    private func observeStatusItemState() {
        withObservationTracking {
            _ = model.isPlaying
            _ = model.activeAmbientChannelsCount
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.updateStatusItem()
                self.observeStatusItemState()
            }
        }
    }
}

@MainActor
private final class MacMenuBarPanelController {
    private let model: AppModel
    private let chromeState = MacPanelChromeState()
    private let panel: BorderlessMacPanel

    init(model: AppModel) {
        self.model = model
        panel = BorderlessMacPanel(contentRect: NSRect(origin: .zero, size: MacPanelLayout.idealSize))

        let rootView = MacMixerPanel()
            .environment(model)
            .environment(chromeState)
            .frame(
                minWidth: MacPanelLayout.idealSize.width,
                idealWidth: MacPanelLayout.idealSize.width,
                maxWidth: .infinity,
                minHeight: MacPanelLayout.idealSize.height,
                idealHeight: MacPanelLayout.idealSize.height,
                maxHeight: .infinity
            )

        panel.contentViewController = NSHostingController(rootView: rootView)
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView?.layer?.masksToBounds = false
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if panel.isVisible && panel.isKeyWindow && NSApp.isActive {
            hide()
        } else {
            show(relativeTo: button)
        }
    }

    func hide() {
        panel.orderOut(nil)
    }

    func show(relativeTo button: NSStatusBarButton) {
        model.bootstrapIfNeeded()
        model.handleScenePhase(.active)
        positionPanel(relativeTo: button)
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
    }

    func writeSnapshot(to path: String) throws {
        guard let contentView = panel.contentView else {
            throw NSError(
                domain: "oasis.mac_screenshot",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Panel content view is unavailable"]
            )
        }

        panel.displayIfNeeded()
        contentView.layoutSubtreeIfNeeded()

        let bounds = contentView.bounds
        guard let representation = contentView.bitmapImageRepForCachingDisplay(in: bounds) else {
            throw NSError(
                domain: "oasis.mac_screenshot",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Unable to create a bitmap representation"]
            )
        }

        contentView.cacheDisplay(in: bounds, to: representation)

        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw NSError(
                domain: "oasis.mac_screenshot",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Unable to encode panel snapshot as PNG"]
            )
        }

        let outputURL = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: outputURL)
    }

    private func positionPanel(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window,
              let screen = buttonWindow.screen ?? NSScreen.main else {
            panel.center()
            return
        }

        let visibleFrame = screen.visibleFrame
        let width = min(MacPanelLayout.idealSize.width, visibleFrame.width - (MacPanelLayout.screenMargin * 2))
        let height = min(MacPanelLayout.idealSize.height, visibleFrame.height - (MacPanelLayout.screenMargin * 2))
        let buttonFrameInWindow = button.convert(button.bounds, to: nil)
        let buttonFrame = buttonWindow.convertToScreen(buttonFrameInWindow)

        let arrowMargin = MacPanelLayout.cornerRadius + (MacPanelLayout.popoverArrowWidth / 2)
        let preferredArrowX = min(
            max(MacPanelLayout.defaultArrowX, arrowMargin),
            width - arrowMargin
        )
        let preferredX = buttonFrame.midX - preferredArrowX
        let x = min(
            max(preferredX, visibleFrame.minX + MacPanelLayout.screenMargin),
            visibleFrame.maxX - width - MacPanelLayout.screenMargin
        )
        let arrowX = buttonFrame.midX - x
        chromeState.arrowX = min(max(arrowX, arrowMargin), width - arrowMargin)

        let preferredY = buttonFrame.minY - height - MacPanelLayout.statusItemGap
        let y = max(preferredY, visibleFrame.minY + MacPanelLayout.screenMargin)

        panel.setFrame(
            NSRect(
                x: x.rounded(.toNearestOrAwayFromZero),
                y: y.rounded(.toNearestOrAwayFromZero),
                width: width.rounded(.toNearestOrAwayFromZero),
                height: height.rounded(.toNearestOrAwayFromZero)
            ),
            display: true
        )
    }
}

private final class BorderlessMacPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        animationBehavior = .utilityWindow
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        orderOut(sender)
    }
}
