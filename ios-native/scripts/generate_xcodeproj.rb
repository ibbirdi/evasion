#!/usr/bin/env ruby

require "xcodeproj"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
PROJECT_DIR = File.join(ROOT, "OasisNative.xcodeproj")
SOURCE_ROOT = File.join(ROOT, "OasisNative")
UI_TEST_SOURCE_ROOT = File.join(ROOT, "OasisNativeUITests")

FileUtils.rm_rf(PROJECT_DIR)

project = Xcodeproj::Project.new(PROJECT_DIR)
project.root_object.attributes["LastUpgradeCheck"] = "2620"
project.root_object.attributes["TargetAttributes"] = {}

target = project.new_target(:application, "OasisNative", :ios, "26.0")
target.product_name = "Oasis"
ui_test_target = project.new_target(:ui_test_bundle, "OasisNativeUITests", :ios, "26.0")

revenuecat_package = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
revenuecat_package.repositoryURL = "https://github.com/RevenueCat/purchases-ios-spm.git"
revenuecat_package.requirement = {
  "kind" => "upToNextMajorVersion",
  "minimumVersion" => "5.43.0"
}
project.root_object.package_references << revenuecat_package

[
  "RevenueCat",
  "RevenueCatUI"
].each do |product_name|
  product_dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product_dependency.package = revenuecat_package
  product_dependency.product_name = product_name
  target.package_product_dependencies << product_dependency

  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = product_dependency
  target.frameworks_build_phase.files << build_file
end

project.root_object.attributes["TargetAttributes"][target.uuid] = {
  "CreatedOnToolsVersion" => "26.2"
}
project.root_object.attributes["TargetAttributes"][ui_test_target.uuid] = {
  "CreatedOnToolsVersion" => "26.2",
  "TestTargetID" => target.uuid
}

target.build_configurations.each do |config|
  settings = config.build_settings
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.jonathanluquet.drift"
  settings["MARKETING_VERSION"] = "1.1.0"
  settings["CURRENT_PROJECT_VERSION"] = "1"
  settings["INFOPLIST_FILE"] = "OasisNative/Support/Info.plist"
  settings["GENERATE_INFOPLIST_FILE"] = "NO"
  settings["SWIFT_VERSION"] = "6.0"
  settings["IPHONEOS_DEPLOYMENT_TARGET"] = "26.0"
  settings["TARGETED_DEVICE_FAMILY"] = "1"
  settings["PRODUCT_NAME"] = "Oasis"
  settings["INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphoneos*]"] = "YES"
  settings["INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphonesimulator*]"] = "YES"
  settings["INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphoneos*]"] = "YES"
  settings["INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphonesimulator*]"] = "YES"
  settings["INFOPLIST_KEY_UIStatusBarStyle[sdk=iphoneos*]"] = "UIStatusBarStyleDefault"
  settings["INFOPLIST_KEY_UIStatusBarStyle[sdk=iphonesimulator*]"] = "UIStatusBarStyleDefault"
  settings["DEVELOPMENT_ASSET_PATHS"] = "\"\""
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["ENABLE_USER_SCRIPT_SANDBOXING"] = "YES"
  settings["SWIFT_EMIT_LOC_STRINGS"] = "YES"
end

ui_test_target.add_dependency(target)

ui_test_target.build_configurations.each do |config|
  settings = config.build_settings
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.jonathanluquet.drift.UITests"
  settings["GENERATE_INFOPLIST_FILE"] = "YES"
  settings["SWIFT_VERSION"] = "6.0"
  settings["IPHONEOS_DEPLOYMENT_TARGET"] = "26.0"
  settings["TARGETED_DEVICE_FAMILY"] = "1"
  settings["PRODUCT_NAME"] = "OasisNativeUITests"
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["TEST_TARGET_NAME"] = "OasisNative"
  settings["ENABLE_USER_SCRIPT_SANDBOXING"] = "YES"
end

main_group = project.main_group
app_group = main_group.new_group("OasisNative", "OasisNative")
ui_test_group = main_group.new_group("OasisNativeUITests", "OasisNativeUITests")

def add_group(parent:, absolute_path:, target:, include_resources: true)

  Dir.children(absolute_path).sort.each do |entry|
    next if entry == ".DS_Store"

    child_absolute_path = File.join(absolute_path, entry)

    if File.directory?(child_absolute_path)
      if File.extname(entry) == ".xcassets"
        file_reference = parent.new_file(entry)
        file_reference.last_known_file_type = "folder.assetcatalog"
        target.resources_build_phase.add_file_reference(file_reference) if include_resources
        next
      end

      subgroup = parent.new_group(entry, entry)
      add_group(parent: subgroup, absolute_path: child_absolute_path, target: target, include_resources: include_resources)
      next
    end

    file_reference = parent.new_file(entry)

    case File.extname(entry)
    when ".swift", ".metal"
      target.source_build_phase.add_file_reference(file_reference)
    when ".png", ".m4a"
      target.resources_build_phase.add_file_reference(file_reference) if include_resources
    when ".plist"
      next
    else
      target.resources_build_phase.add_file_reference(file_reference) if include_resources
    end
  end
end

add_group(parent: app_group, absolute_path: SOURCE_ROOT, target: target, include_resources: true)
add_group(parent: ui_test_group, absolute_path: UI_TEST_SOURCE_ROOT, target: ui_test_target, include_resources: false) if Dir.exist?(UI_TEST_SOURCE_ROOT)

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(target, ui_test_target, launch_target: true)
scheme.save_as(PROJECT_DIR, "OasisNative", true)

project.save
