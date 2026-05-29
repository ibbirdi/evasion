#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

FREE_CHANNELS = %w[oiseaux vent plage].freeze
PREMIUM_NOISES = %w[pink green fan aircraft].freeze
LEGACY_BUNDLED_IDS = %w[
  preset_default_nap
  preset_default_reset
  preset_default_starter
  preset_default_deep_sleep
  preset_default_deep_work
  preset_default_travel
  preset_default_reading
  preset_default_rain_cabin
  preset_default_morning
  preset_default_calm
  preset_default_storm
  preset_signature_oasis
].freeze

def usage
  warn "Usage: ruby scripts/exported_presets_to_swift.rb path/to/oasis-iphone-ambiences.json"
  exit 64
end

def swift_string(value)
  value.to_s.dump
end

def swift_bool(value)
  value ? "true" : "false"
end

def swift_number(value)
  format("%.4f", value.to_f).sub(/0+\z/, "").sub(/\.\z/, ".0")
end

def slug(value)
  value.to_s
       .downcase
       .unicode_normalize(:nfkd)
       .encode("ASCII", replace: "")
       .gsub(/[^a-z0-9]+/, "_")
       .gsub(/\A_+|_+\z/, "")
end

def normalized_dictionary(value)
  return value if value.is_a?(Hash)
  return {} unless value.is_a?(Array)

  value.each_slice(2).each_with_object({}) do |(key, entry), result|
    result[key] = entry if key
  end
end

def state_requires_premium?(preset)
  active_premium_channel = normalized_dictionary(preset["channels"]).any? do |channel, state|
    state && state["isMuted"] == false && !FREE_CHANNELS.include?(channel)
  end
  active_premium_noise = normalized_dictionary(preset["proceduralNoises"]).any? do |noise, state|
    state && state["isMuted"] == false && PREMIUM_NOISES.include?(noise)
  end

  active_premium_channel ||
    active_premium_noise ||
    (preset["isBinauralActive"] == true && preset["activeBinauralTrack"] != "delta") ||
    preset["timerDurationMinutes"].to_i > 30
end

def channel_state_swift(state)
  state ||= {}
  position = state["spatialPosition"] || {}
  range = state["autoVariationRange"]
  args = [
    "volume: #{swift_number(state.fetch("volume", 0.5))}",
    "isMuted: #{swift_bool(state.fetch("isMuted", true))}",
    "autoVariationEnabled: #{swift_bool(state.fetch("autoVariationEnabled", false))}"
  ]
  if range
    args << "autoVariationRange: AutoVariationRange(lowerBound: #{swift_number(range.fetch("lowerBound", 0.0))}, upperBound: #{swift_number(range.fetch("upperBound", 1.0))})"
  end
  args << "spatialPosition: SpatialPoint(x: #{swift_number(position.fetch("x", 0.0))}, y: #{swift_number(position.fetch("y", 0.0))})"
  "ChannelState(#{args.join(", ")})"
end

def noise_state_swift(state)
  state ||= {}
  "ProceduralNoiseState(volume: #{swift_number(state.fetch("volume", 0.42))}, isMuted: #{swift_bool(state.fetch("isMuted", true))})"
end

def dictionary_swift(hash, key_prefix, value_formatter)
  return "[:]" if hash.nil? || hash.empty?

  lines = hash.sort.map do |key, value|
    "            #{key_prefix}#{key}: #{value_formatter.call(value)}"
  end
  "[\n#{lines.join(",\n")}\n        ]"
end

path = ARGV.fetch(0) { usage }
archive = JSON.parse(File.read(path))
presets = archive.fetch("presets")
usage unless presets.is_a?(Array)

free_count = presets.count { |preset| !state_requires_premium?(preset) }
unless free_count == 2
  warn "Expected exactly 2 free/default-access ambiences, found #{free_count}."
  warn "Make exactly two exported ambiences use only free content: Birds, Wind, Beach, white/brown noise, Delta, and timers up to 30 min."
  exit 65
end

used_ids = {}
generated = presets.map.with_index do |preset, index|
  source_name = preset["name"].to_s.strip
  base_id = "preset_default_#{slug(source_name.empty? ? "ambience_#{index + 1}" : source_name)}"
  base_id = "#{base_id}_imported" if LEGACY_BUNDLED_IDS.include?(base_id)
  id = base_id
  suffix = 2
  while used_ids[id]
    id = "#{base_id}_#{suffix}"
    suffix += 1
  end
  used_ids[id] = true

  channels = dictionary_swift(normalized_dictionary(preset["channels"]), ".", method(:channel_state_swift))
  noises = dictionary_swift(normalized_dictionary(preset["proceduralNoises"]), ".", method(:noise_state_swift))
  args = [
    "id: #{swift_string(id)}",
    "name: #{swift_string(source_name)}",
    "channels: #{channels}",
    "proceduralNoises: #{noises}",
    "isBinauralActive: #{swift_bool(preset["isBinauralActive"] == true)}",
    "activeBinauralTrack: .#{preset["activeBinauralTrack"] || "delta"}",
    "binauralVolume: #{swift_number(preset.fetch("binauralVolume", 0.5))}",
    "timerDurationMinutes: #{preset["timerDurationMinutes"] || "nil"}",
    "immersiveAudioEnabled: #{swift_bool(preset["immersiveAudioEnabled"] == true)}"
  ]
  args << "backdropAssetName: #{swift_string(preset["backdropAssetName"])}" if preset["backdropAssetName"]

  "        Preset(\n            #{args.join(",\n            ")}\n        )"
end

puts <<~SWIFT
  // Generated from #{File.basename(path)}.
  // Paste this array body into Array.defaultPresets().
  return [
  #{generated.join(",\n")}
  ]
SWIFT
