#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "shellwords"

ROOT = File.expand_path("..", __dir__)
FFMPEG = ENV.fetch("FFMPEG_BIN", "ffmpeg")
FFPROBE = ENV.fetch("FFPROBE_BIN", "ffprobe")

LOCALES = %w[
  en-US
  fr-FR
  de-DE
  es-ES
  it
  pt-BR
].freeze

SLIDES = %w[
  01_hero
  02_library
  07_timer
  05_spatial
  08_free_home
  10_paywall
].freeze

WIDTH = 886
HEIGHT = 1920
FPS = 30
SECONDS_PER_SLIDE = 20.0 / SLIDES.length
EXPECTED_DURATION = SLIDES.length * SECONDS_PER_SLIDE
OUTPUT_NAME = "01_app_preview.mp4"

def run!(*command)
  stdout, stderr, status = Open3.capture3(*command)
  return stdout if status.success?

  warn stderr
  raise "Command failed: #{command.shelljoin}"
end

def ensure_tool!(tool)
  run!("which", tool)
rescue StandardError
  raise "#{tool} is required. Install ffmpeg or set #{tool == FFMPEG ? "FFMPEG_BIN" : "FFPROBE_BIN"}."
end

def slide_path(locale, slide)
  File.join(ROOT, "fastlane", "screenshots", locale, "figma-pro", "#{slide}.jpg")
end

def preview_path(locale)
  File.join(ROOT, "fastlane", "app-previews", locale, OUTPUT_NAME)
end

def ffmpeg_inputs(paths)
  paths.flat_map { |path| ["-loop", "1", "-t", SECONDS_PER_SLIDE.to_s, "-i", path] }
end

def filter_complex(input_count)
  chains = input_count.times.map do |index|
    "[#{index}:v]scale=#{WIDTH}:#{HEIGHT}:force_original_aspect_ratio=increase," \
      "crop=#{WIDTH}:#{HEIGHT},setsar=1,fps=#{FPS},format=yuv420p[v#{index}]"
  end
  concat_inputs = input_count.times.map { |index| "[v#{index}]" }.join
  (chains + ["#{concat_inputs}concat=n=#{input_count}:v=1:a=0[v]"]).join(";")
end

def assert_video!(path)
  raw = run!(
    FFPROBE,
    "-v", "error",
    "-show_entries", "stream=codec_type,width,height,channels,sample_rate:format=duration",
    "-of", "json",
    path
  )

  probe = JSON.parse(raw)
  video = probe.fetch("streams").find { |stream| stream["codec_type"] == "video" }
  audio = probe.fetch("streams").find { |stream| stream["codec_type"] == "audio" }
  duration = probe.fetch("format").fetch("duration").to_f

  raise "Missing video stream for #{path}" unless video
  raise "Missing audio stream for #{path}" unless audio

  width = video["width"].to_i
  height = video["height"].to_i
  raise "Unexpected size for #{path}: #{width}x#{height}" unless width == WIDTH && height == HEIGHT
  raise "Unexpected duration for #{path}: #{duration.round(2)}s" unless duration.between?(EXPECTED_DURATION - 0.1, EXPECTED_DURATION + 0.1)
  raise "Unexpected audio channels for #{path}: #{audio["channels"]}" unless audio["channels"].to_i == 2
  raise "Unexpected audio sample rate for #{path}: #{audio["sample_rate"]}" unless audio["sample_rate"].to_i == 44_100
end

ensure_tool!(FFMPEG)
ensure_tool!(FFPROBE)

LOCALES.each do |locale|
  paths = SLIDES.map { |slide| slide_path(locale, slide) }
  missing = paths.reject { |path| File.exist?(path) }
  raise "Missing screenshots for #{locale}: #{missing.join(", ")}" unless missing.empty?

  output = preview_path(locale)
  FileUtils.mkdir_p(File.dirname(output))

  command = [
    FFMPEG,
    "-y",
    *ffmpeg_inputs(paths),
    "-f", "lavfi",
    "-t", EXPECTED_DURATION.to_s,
    "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
    "-filter_complex", filter_complex(paths.length),
    "-map", "[v]",
    "-map", "#{paths.length}:a",
    "-c:v", "libx264",
    "-profile:v", "high",
    "-level", "4.0",
    "-pix_fmt", "yuv420p",
    "-c:a", "aac",
    "-b:a", "192k",
    "-ac", "2",
    "-ar", "44100",
    "-movflags", "+faststart",
    "-r", FPS.to_s,
    "-shortest",
    output
  ]

  run!(*command)
  assert_video!(output)
  puts "Generated #{output}"
end
