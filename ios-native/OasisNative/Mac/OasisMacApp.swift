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
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        model.handleScenePhase(.active)
    }

    func applicationWillResignActive(_ notification: Notification) {
        model.handleScenePhase(.inactive)
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.handleScenePhase(.background)
    }

    @objc private func togglePanel(_ sender: Any?) {
        guard let button = statusItem?.button else { return }
        panelController?.toggle(relativeTo: button)
        updateStatusItem()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item

        guard let button = item.button else { return }
        button.target = self
        button.action = #selector(togglePanel(_:))
        button.imagePosition = .imageOnly
        button.toolTip = L10n.string(L10n.App.title)
        _ = button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }

        let symbolName = model.isPlaying ? "waveform.circle.fill" : "water.waves"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: L10n.string(L10n.App.title))
        image?.isTemplate = true

        button.image = image
        button.contentTintColor = model.isPlaying ? NSColor.controlAccentColor : NSColor.labelColor
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
    private let panel: BorderlessMacPanel

    init(model: AppModel) {
        self.model = model
        panel = BorderlessMacPanel(contentRect: NSRect(origin: .zero, size: MacPanelLayout.idealSize))

        let rootView = MacMixerPanel()
            .environment(model)
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
        panel.contentView?.layer?.cornerRadius = MacPanelLayout.cornerRadius
        panel.contentView?.layer?.masksToBounds = true
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            show(relativeTo: button)
        }
    }

    private func show(relativeTo button: NSStatusBarButton) {
        model.bootstrapIfNeeded()
        model.handleScenePhase(.active)
        positionPanel(relativeTo: button)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
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

        let preferredX = buttonFrame.maxX - width
        let x = min(
            max(preferredX, visibleFrame.minX + MacPanelLayout.screenMargin),
            visibleFrame.maxX - width - MacPanelLayout.screenMargin
        )
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
