#!/usr/bin/env ruby
# Re-set the App Store Connect display order for screenshots of a given version.
#
# `upload_to_app_store` uploads screenshots in parallel, so the displayOrder
# assigned by App Store Connect can drift from filename order whenever a later
# slot finishes uploading before an earlier one. This script walks every
# localization × screenshot set, pulls the current screenshots, and re-issues
# the order based on a strict alphabetical sort of `file_name`.

require "spaceship"

USERNAME = "jonathanluquet@me.com"
APP_BUNDLE = "com.jonathanluquet.drift"
TARGET_VERSION = ENV.fetch("TARGET_VERSION", "1.4.2")

Spaceship::ConnectAPI.login(USERNAME)

app = Spaceship::ConnectAPI::App.find(APP_BUNDLE)
raise "App not found for #{APP_BUNDLE}" unless app

version = app.get_app_store_versions.find { |v| v.version_string == TARGET_VERSION }
raise "Version #{TARGET_VERSION} not found" unless version
puts "Version #{version.version_string} (#{version.app_store_state})"

reordered = 0
already_ok = 0

version.get_app_store_version_localizations.each do |loc|
  Spaceship::ConnectAPI::AppScreenshotSet
    .all(app_store_version_localization_id: loc.id, includes: "appScreenshots")
    .each do |set|
      hydrated = Spaceship::ConnectAPI::AppScreenshotSet.get(
        app_screenshot_set_id: set.id,
        includes: "appScreenshots"
      )
      screenshots = Array(hydrated.app_screenshots)
      next if screenshots.empty?

      sorted_ids = screenshots.sort_by(&:file_name).map(&:id)
      current_ids = screenshots.map(&:id)
      label = "#{loc.locale}/#{set.screenshot_display_type}"
      if current_ids == sorted_ids
        already_ok += 1
        puts "  [#{label}] already ordered (#{screenshots.size} shots)"
        next
      end

      hydrated.reorder_screenshots(app_screenshot_ids: sorted_ids)
      reordered += 1
      puts "  [#{label}] reordered to #{screenshots.sort_by(&:file_name).map(&:file_name).join(", ")}"
    end
end

puts "Done. #{reordered} sets reordered, #{already_ok} already in order."
