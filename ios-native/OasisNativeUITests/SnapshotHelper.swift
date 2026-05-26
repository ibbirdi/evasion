//
//  SnapshotHelper.swift
//  Example
//
//  Created by Felix Krause on 10/8/15.
//

// -----------------------------------------------------
// IMPORTANT: When modifying this file, make sure to
//            increment the version number at the very
//            bottom of the file to notify users about
//            the new SnapshotHelper.swift
// -----------------------------------------------------

import Foundation
import XCTest

@MainActor
func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
    Snapshot.setupSnapshot(app, waitForAnimations: waitForAnimations)
}

@MainActor
func snapshot(_ name: String, waitForLoadingIndicator: Bool) {
    if waitForLoadingIndicator {
        Snapshot.snapshot(name)
    } else {
        Snapshot.snapshot(name, timeWaitingForIdle: 0)
    }
}

/// - Parameters:
///   - name: The name of the snapshot
///   - timeout: Amount of seconds to wait until the network loading indicator disappears. Pass `0` if you don't want to wait.
@MainActor
func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
    Snapshot.snapshot(name, timeWaitingForIdle: timeout)
}

@MainActor
func snapshotElement(_ name: String, element: XCUIElement, waitForExistence timeout: TimeInterval = 5) {
    Snapshot.snapshotElement(name, element: element, waitForExistence: timeout)
}

enum SnapshotError: Error, CustomDebugStringConvertible {
    case cannotFindSimulatorHomeDirectory
    case cannotRunOnPhysicalDevice

    var debugDescription: String {
        switch self {
        case .cannotFindSimulatorHomeDirectory:
            return "Couldn't find simulator home location. Please, check SIMULATOR_HOST_HOME env variable."
        case .cannotRunOnPhysicalDevice:
            return "Can't use Snapshot on a physical device."
        }
    }
}

@objcMembers
@MainActor
open class Snapshot: NSObject {
    static var app: XCUIApplication?
    static var waitForAnimations = true
    static var cacheDirectory: URL?
    static var didPrepareExtractedAssetsDirectory = false
    static var screenshotsDirectory: URL? {
        return cacheDirectory?.appendingPathComponent("screenshots", isDirectory: true)
    }
    static var extractedAssetsDirectory: URL? {
        let locale = ProcessInfo.processInfo.environment["FASTLANE_LANGUAGE"] ?? deviceLanguage
        guard !locale.isEmpty else { return nil }

        let sourceFile = URL(fileURLWithPath: #filePath)
        let repoRoot = sourceFile
            .deletingLastPathComponent() // OasisNativeUITests
            .deletingLastPathComponent() // ios-native
            .deletingLastPathComponent()

        return repoRoot
            .appendingPathComponent("fastlane", isDirectory: true)
            .appendingPathComponent("screenshots", isDirectory: true)
            .appendingPathComponent(locale, isDirectory: true)
            .appendingPathComponent("extracted-assets", isDirectory: true)
    }
    static var deviceLanguage = ""
    static var currentLocale = ""

    open class func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {

        Snapshot.app = app
        Snapshot.waitForAnimations = waitForAnimations

        do {
            let cacheDir = try getCacheDirectory()
            Snapshot.cacheDirectory = cacheDir
            if let screenshotsDir = Snapshot.screenshotsDirectory {
                try FileManager.default.createDirectory(
                    at: screenshotsDir,
                    withIntermediateDirectories: true
                )
            }
            setLanguage(app)
            setLocale(app)
            setLaunchArguments(app)
            prepareExtractedAssetsDirectory()
        } catch let error {
            NSLog(error.localizedDescription)
        }
    }

    class func setLanguage(_ app: XCUIApplication) {
        guard let cacheDirectory = self.cacheDirectory else {
            NSLog("CacheDirectory is not set - probably running on a physical device?")
            return
        }

        let path = cacheDirectory.appendingPathComponent("language.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            deviceLanguage = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
            app.launchArguments += ["-AppleLanguages", "(\(deviceLanguage))"]
        } catch {
            NSLog("Couldn't detect/set language...")
        }
    }

    class func setLocale(_ app: XCUIApplication) {
        guard let cacheDirectory = self.cacheDirectory else {
            NSLog("CacheDirectory is not set - probably running on a physical device?")
            return
        }

        let path = cacheDirectory.appendingPathComponent("locale.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            currentLocale = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
        } catch {
            NSLog("Couldn't detect/set locale...")
        }

        if currentLocale.isEmpty && !deviceLanguage.isEmpty {
            currentLocale = Locale(identifier: deviceLanguage).identifier
        }

        if !currentLocale.isEmpty {
            app.launchArguments += ["-AppleLocale", "\"\(currentLocale)\""]
        }
    }

    class func setLaunchArguments(_ app: XCUIApplication) {
        guard let cacheDirectory = self.cacheDirectory else {
            NSLog("CacheDirectory is not set - probably running on a physical device?")
            return
        }

        let path = cacheDirectory.appendingPathComponent("snapshot-launch_arguments.txt")
        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES", "-ui_testing"]

        do {
            let launchArguments = try String(contentsOf: path, encoding: String.Encoding.utf8)
            let regex = try NSRegularExpression(pattern: "(\\\".+?\\\"|\\S+)", options: [])
            let matches = regex.matches(in: launchArguments, options: [], range: NSRange(location: 0, length: launchArguments.count))
            let results = matches.map { result -> String in
                (launchArguments as NSString).substring(with: result.range)
            }
            app.launchArguments += results
        } catch {
            NSLog("Couldn't detect/set launch_arguments...")
        }
    }

    class func prepareExtractedAssetsDirectory() {
        guard !didPrepareExtractedAssetsDirectory, let assetsDir = extractedAssetsDirectory else { return }

        do {
            if FileManager.default.fileExists(atPath: assetsDir.path) {
                try FileManager.default.removeItem(at: assetsDir)
            }
            try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
            didPrepareExtractedAssetsDirectory = true
        } catch let error {
            NSLog("Unable to prepare extracted marketing assets directory: \(assetsDir.path)")
            NSLog(error.localizedDescription)
        }
    }

    open class func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
        if timeout > 0 {
            waitForLoadingIndicatorToDisappear(within: timeout)
        }

        NSLog("snapshot: \(name)")

        if Snapshot.waitForAnimations {
            sleep(1)
        }

        #if os(OSX)
            guard let app = self.app else {
                NSLog("XCUIApplication is not set. Please call setupSnapshot(app) before snapshot().")
                return
            }

            app.typeKey(XCUIKeyboardKeySecondaryFn, modifierFlags: [])
        #else

            guard self.app != nil else {
                NSLog("XCUIApplication is not set. Please call setupSnapshot(app) before snapshot().")
                return
            }

            let screenshot = XCUIScreen.main.screenshot()
            #if os(iOS) && !targetEnvironment(macCatalyst)
            let image = XCUIDevice.shared.orientation.isLandscape ? fixLandscapeOrientation(image: screenshot.image) : screenshot.image
            #else
            let image = screenshot.image
            #endif

            guard var simulator = ProcessInfo().environment["SIMULATOR_DEVICE_NAME"], let screenshotsDir = screenshotsDirectory else { return }

            do {
                let regex = try NSRegularExpression(pattern: "Clone [0-9]+ of ")
                let range = NSRange(location: 0, length: simulator.count)
                simulator = regex.stringByReplacingMatches(in: simulator, range: range, withTemplate: "")

                let path = screenshotsDir.appendingPathComponent("\(simulator)-\(name).png")
                try FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
                #if swift(<5.0)
                    try UIImagePNGRepresentation(image)?.write(to: path, options: .atomic)
                #else
                    try image.pngData()?.write(to: path, options: .atomic)
                #endif
            } catch let error {
                NSLog("Problem writing screenshot: \(name) to \(screenshotsDir)/\(simulator)-\(name).png")
                NSLog(error.localizedDescription)
            }
        #endif
    }

    open class func snapshotElement(_ name: String, element: XCUIElement, waitForExistence timeout: TimeInterval = 5) {
        prepareExtractedAssetsDirectory()

        guard element.waitForExistence(timeout: timeout), element.frame.size.width > 0, element.frame.size.height > 0 else {
            NSLog("Unable to capture marketing asset '\(name)': element does not exist or has an empty frame.")
            return
        }

        let screenImage = XCUIScreen.main.screenshot().image
        let screenFrame = CGRect(origin: .zero, size: screenImage.size)
        let frame = element.frame
        let visibleFrame = frame.intersection(screenFrame)
        guard !visibleFrame.isNull, visibleFrame.width > 2, visibleFrame.height > 2 else {
            NSLog("Unable to capture marketing asset '\(name)': element is outside the visible screen.")
            return
        }

        let padding = elementCapturePadding(for: name)
        let captureFrame = visibleFrame
            .insetBy(dx: -padding.horizontal, dy: -padding.vertical)
            .intersection(screenFrame)

        guard let image = cropScreenImage(screenImage, to: captureFrame) else {
            NSLog("Unable to capture marketing asset '\(name)': screen crop failed.")
            return
        }

        guard let assetsDir = extractedAssetsDirectory else { return }
        let pngPath = assetsDir.appendingPathComponent("\(name).png")
        let metadataPath = assetsDir.appendingPathComponent("\(name).json")

        do {
            try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
            try image.pngData()?.write(to: pngPath, options: .atomic)

            let json = """
            {
              "name": "\(name)",
              "framePoints": { "x": \(frame.minX), "y": \(frame.minY), "width": \(frame.width), "height": \(frame.height) },
              "elementFramePoints": { "x": \(visibleFrame.minX), "y": \(visibleFrame.minY), "width": \(visibleFrame.width), "height": \(visibleFrame.height) },
              "visibleFramePoints": { "x": \(captureFrame.minX), "y": \(captureFrame.minY), "width": \(captureFrame.width), "height": \(captureFrame.height) },
              "paddingPoints": { "horizontal": \(padding.horizontal), "vertical": \(padding.vertical) },
              "screenPoints": { "width": \(screenImage.size.width), "height": \(screenImage.size.height) },
              "screenScale": \(screenImage.scale),
              "imagePixels": { "width": \(Int(image.size.width * image.scale)), "height": \(Int(image.size.height * image.scale)) }
            }
            """
            try json.data(using: .utf8)?.write(to: metadataPath, options: .atomic)
        } catch let error {
            NSLog("Problem writing marketing asset: \(name) to \(assetsDir)")
            NSLog(error.localizedDescription)
        }
    }

    private class func elementCapturePadding(for name: String) -> (horizontal: CGFloat, vertical: CGFloat) {
        if name.contains("_active_") {
            return (horizontal: 18, vertical: 12)
        }
        if name.hasPrefix("06_preset") {
            return (horizontal: 16, vertical: 10)
        }
        if name == "04_binaural_modes" {
            return (horizontal: 16, vertical: 12)
        }
        if name == "05_spatial_stage" {
            return (horizontal: 12, vertical: 12)
        }
        return (horizontal: 12, vertical: 10)
    }

    private class func cropScreenImage(_ image: UIImage, to frame: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let scale = image.scale
        let pixelBounds = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let pixelFrame = CGRect(
            x: floor(frame.minX * scale),
            y: floor(frame.minY * scale),
            width: ceil(frame.width * scale),
            height: ceil(frame.height * scale)
        ).intersection(pixelBounds)

        guard !pixelFrame.isNull, pixelFrame.width > 1, pixelFrame.height > 1,
              let cropped = cgImage.cropping(to: pixelFrame) else {
            return nil
        }

        return UIImage(cgImage: cropped, scale: scale, orientation: .up)
    }

    class func fixLandscapeOrientation(image: UIImage) -> UIImage {
        #if os(watchOS)
            return image
        #else
            if #available(iOS 10.0, *) {
                let format = UIGraphicsImageRendererFormat()
                format.scale = image.scale
                let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
                return renderer.image { _ in
                    image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
                }
            } else {
                return image
            }
        #endif
    }

    class func waitForLoadingIndicatorToDisappear(within timeout: TimeInterval) {
        #if os(tvOS)
            return
        #endif

        guard let app = self.app else {
            NSLog("XCUIApplication is not set. Please call setupSnapshot(app) before snapshot().")
            return
        }

        let networkLoadingIndicator = app.otherElements.deviceStatusBars.networkLoadingIndicators.element
        let networkLoadingIndicatorDisappeared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: networkLoadingIndicator)
        _ = XCTWaiter.wait(for: [networkLoadingIndicatorDisappeared], timeout: timeout)
    }

    class func getCacheDirectory() throws -> URL {
        let cachePath = "Library/Caches/tools.fastlane"
        #if os(OSX)
            let homeDir = URL(fileURLWithPath: NSHomeDirectory())
            return homeDir.appendingPathComponent(cachePath)
        #elseif arch(i386) || arch(x86_64) || arch(arm64)
            guard let simulatorHostHome = ProcessInfo().environment["SIMULATOR_HOST_HOME"] else {
                throw SnapshotError.cannotFindSimulatorHomeDirectory
            }
            let homeDir = URL(fileURLWithPath: simulatorHostHome)
            return homeDir.appendingPathComponent(cachePath)
        #else
            throw SnapshotError.cannotRunOnPhysicalDevice
        #endif
    }
}

private extension XCUIElementAttributes {
    var snapshotBundleID: String? {
        (self as AnyObject).value(forKey: "bundleID") as? String
    }

    var isNetworkLoadingIndicator: Bool {
        if hasAllowListedIdentifier { return false }

        let hasOldLoadingIndicatorSize = frame.size == CGSize(width: 10, height: 20)
        let hasNewLoadingIndicatorSize = frame.size.width.isBetween(46, and: 47) && frame.size.height.isBetween(2, and: 3)

        return hasOldLoadingIndicatorSize || hasNewLoadingIndicatorSize
    }

    var hasAllowListedIdentifier: Bool {
        let allowListedIdentifiers = ["GeofenceLocationTrackingOn", "StandardLocationTrackingOn"]

        return allowListedIdentifiers.contains(identifier)
    }

    func isStatusBar(_ deviceWidth: CGFloat) -> Bool {
        let statusBarIdentifiers = ["StatusBar", "Status Bar"]

        let isStatusBar = statusBarIdentifiers.contains(identifier)
        let isNotFirstPartyApp = snapshotBundleID != "com.apple.springboard"
        let hasStatusBarSize = frame.size.width == deviceWidth && frame.size.height <= 30

        return isStatusBar || (isNotFirstPartyApp && hasStatusBarSize)
    }
}

private extension XCUIElementQuery {
    var networkLoadingIndicators: XCUIElementQuery {
        let isNetworkLoadingIndicator = NSPredicate { evaluatedObject, _ in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }

            return element.isNetworkLoadingIndicator
        }

        return self.containing(isNetworkLoadingIndicator)
    }

    @MainActor
    var deviceStatusBars: XCUIElementQuery {
        guard let app = Snapshot.app else {
            fatalError("XCUIApplication is not set. Please call setupSnapshot(app) before snapshot().")
        }

        let deviceWidth = app.windows.firstMatch.frame.width

        let isStatusBar = NSPredicate { evaluatedObject, _ in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }

            return element.isStatusBar(deviceWidth)
        }

        return self.containing(isStatusBar)
    }
}

private extension CGFloat {
    func isBetween(_ numberA: CGFloat, and numberB: CGFloat) -> Bool {
        return numberA...numberB ~= self
    }
}

// Please don't remove the lines below
// They are used to detect outdated configuration files
// SnapshotHelperVersion [1.30]
