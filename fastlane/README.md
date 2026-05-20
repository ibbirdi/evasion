fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Generate App Store screenshots for the native iOS app with XCTest + snapshot

### ios screenshots_only

```sh
[bundle exec] fastlane ios screenshots_only
```

Alias for screenshot generation

### ios app_previews

```sh
[bundle exec] fastlane ios app_previews
```

Generate localized App Preview videos from the App Store composites

### ios mac_screenshots

```sh
[bundle exec] fastlane ios mac_screenshots
```

Capture localized macOS menu bar panel screenshots

### ios mac_appstore_assets

```sh
[bundle exec] fastlane ios mac_appstore_assets
```

Generate upload-ready macOS App Store screenshots from panel captures

### ios mac_appstore_screenshots

```sh
[bundle exec] fastlane ios mac_appstore_screenshots
```

Capture and compose all localized macOS App Store screenshots

### ios mac_appstore_release

```sh
[bundle exec] fastlane ios mac_appstore_release
```

Upload macOS screenshots + metadata to App Store Connect (no binary)

### ios stage_appstore_assets

```sh
[bundle exec] fastlane ios stage_appstore_assets
```

Stage upload-ready screenshots without uploading App Preview videos

### ios appstore_metadata

```sh
[bundle exec] fastlane ios appstore_metadata
```

Upload metadata to App Store Connect without screenshots

### ios build_and_upload

```sh
[bundle exec] fastlane ios build_and_upload
```

Archive + export an App Store IPA and upload it to TestFlight/App Store Connect

### ios appstore_release

```sh
[bundle exec] fastlane ios appstore_release
```

Upload screenshots + metadata to App Store Connect (no binary)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
