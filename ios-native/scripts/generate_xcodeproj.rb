#!/usr/bin/env ruby

require "xcodeproj"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
PROJECT_DIR = File.join(ROOT, "OasisNative.xcodeproj")
SOURCE_ROOT = File.join(ROOT, "OasisNative")

FileUtils.rm_rf(PROJECT_DIR)

project = Xcodeproj::Project.new(PROJECT_DIR)
project.root_object.attributes["LastUpgradeCheck"] = "2620"
project.root_object.attributes["TargetAttributes"] = {}

target = project.new_target(:application, "OasisNative", :ios, "26.0")
target.product_name = "Oasis"

project.root_object.attributes["TargetAttributes"][target.uuid] = {
  "CreatedOnToolsVersion" => "26.2"
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

main_group = project.main_group
app_group = main_group.new_group("OasisNative", "OasisNative")

def add_group(parent:, absolute_path:, target:)

  Dir.children(absolute_path).sort.each do |entry|
    next if entry == ".DS_Store"

    child_absolute_path = File.join(absolute_path, entry)

    if File.directory?(child_absolute_path)
      if File.extname(entry) == ".xcassets"
        file_reference = parent.new_file(entry)
        file_reference.last_known_file_type = "folder.assetcatalog"
        target.resources_build_phase.add_file_reference(file_reference)
        next
      end

      subgroup = parent.new_group(entry, entry)
      add_group(parent: subgroup, absolute_path: child_absolute_path, target: target)
      next
    end

    file_reference = parent.new_file(entry)

    case File.extname(entry)
    when ".swift", ".metal"
      target.source_build_phase.add_file_reference(file_reference)
    when ".png", ".m4a"
      target.resources_build_phase.add_file_reference(file_reference)
    when ".plist"
      next
    else
      target.resources_build_phase.add_file_reference(file_reference)
    end
  end
end

add_group(parent: app_group, absolute_path: SOURCE_ROOT, target: target)

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(PROJECT_DIR, "OasisNative", true)

project.save
