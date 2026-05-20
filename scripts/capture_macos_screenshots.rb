#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"

ROOT = File.expand_path("..", __dir__)
PROJECT = File.join(ROOT, "ios-native", "OasisNative.xcodeproj")
DERIVED_DATA = File.join(ROOT, "fastlane", "macos-screenshot-derived-data")
APP_PATH = File.join(DERIVED_DATA, "Build", "Products", "Debug", "Oasis.app")
EXECUTABLE = File.join(APP_PATH, "Contents", "MacOS", "Oasis")
OUTPUT_ROOT = File.join(ROOT, "fastlane", "screenshots-macos")

LOCALES = %w[en-US fr-FR de-DE es-ES it pt-BR].freeze
SCENARIOS = [
  "01_menu_bar_mixer",
  "02_sound_detail",
  "03_auto_range",
  "04_saved_ambiences",
  "05_binaural_timer"
].freeze

def run!(*command)
  puts command.join(" ")
  system(*command) || raise("Command failed: #{command.join(" ")}")
end

def apple_locale(locale)
  locale.tr("-", "_")
end

def terminate_existing_oasis
  system("/usr/bin/pkill", "-x", "Oasis")
  sleep 0.25
end

def launch_oasis(locale, scenario, output)
  Process.spawn(
    EXECUTABLE,
    "-OASISMacScreenshot", "YES",
    "-OASISMacScreenshotScenario", scenario,
    "-OASISMacScreenshotOutput", output,
    "-OASISPremiumOverride", "premium",
    "-OASISResetState", "YES",
    "-OASISImmersiveAudioEnabled", "YES",
    "-AppleLanguages", "(#{locale})",
    "-AppleLocale", apple_locale(locale),
    out: File.join(ROOT, "fastlane", "buildlogs", "OasisMac-#{locale}-#{scenario}.out.log"),
    err: File.join(ROOT, "fastlane", "buildlogs", "OasisMac-#{locale}-#{scenario}.err.log")
  )
end

def wait_for_process!(pid, timeout_seconds:)
  deadline = Time.now + timeout_seconds

  loop do
    waited_pid = Process.waitpid(pid, Process::WNOHANG)
    if waited_pid
      status = $?
      raise "Oasis exited with status #{status.exitstatus}" unless status.success?

      return
    end

    if Time.now > deadline
      Process.kill("TERM", pid)
      raise "Timed out waiting for Oasis screenshot process #{pid}"
    end

    sleep 0.2
  end
end

FileUtils.mkdir_p(File.join(ROOT, "fastlane", "buildlogs"))

run!(
  "xcodebuild",
  "-scheme", "OasisMac",
  "-project", PROJECT,
  "-configuration", "Debug",
  "-destination", "platform=macOS",
  "-derivedDataPath", DERIVED_DATA,
  "build",
  "CODE_SIGNING_ALLOWED=NO"
)

raise "Missing built app executable at #{EXECUTABLE}" unless File.executable?(EXECUTABLE)

FileUtils.rm_rf(OUTPUT_ROOT)
FileUtils.mkdir_p(OUTPUT_ROOT)

terminate_existing_oasis

LOCALES.each do |locale|
  SCENARIOS.each do |scenario|
    output = File.join(OUTPUT_ROOT, locale, "#{scenario}.png")
    FileUtils.mkdir_p(File.dirname(output))

    puts "Capturing #{locale} / #{scenario}"
    pid = launch_oasis(locale, scenario, output)

    begin
      wait_for_process!(pid, timeout_seconds: 24)
      raise "Missing screenshot output at #{output}" unless File.size?(output)
    ensure
      begin
        Process.kill("TERM", pid)
        Process.wait(pid)
      rescue Errno::ESRCH, Errno::ECHILD
        # App already exited.
      end
      terminate_existing_oasis
    end
  end
end

puts "Captured #{LOCALES.size * SCENARIOS.size} macOS screenshots into #{OUTPUT_ROOT}"
