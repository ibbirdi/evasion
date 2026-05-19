#!/bin/bash
set -euo pipefail

SRC="${1:-$HOME/Downloads/new sounds}"
DST="/Users/jonathanluquet/CODE/evasion/ios-native/OasisNative/Resources/Audio"

declare -a MAP=(
  "324497__deleted_user_2104797__int-rain-on-window-c.wav|pluieFenetre1.m4a|-1.5|0.71"
  "536843__garuda1982__rain-in-the-forest-atmo-field-recording.wav|pluieForet1.m4a|-1.5|0.71"
  "200270__jmbphilmes__rain-heavy-1-rural.wav|fortePluie1.m4a|-1.5|0.71"
  "853993__fran_marenco__night-wind-trees-ans-crickets-2.wav|ventNuit1.m4a|-1.5|0.71"
  "645637__felixblume__edge-of-the-forest-at-night-with-birds-crickets-toad-singing-coyote-at-a-distance-road-hum-and-far-oil-pump-recorded-in-a-tallgrass-prairie-in-oklahoma.wav|foretNuit1.m4a|-1.5|0.71"
  "742092__lastraindrop__floods-in-the-mountains-and-insect-chirping.wav|crueMontagne1.m4a|-1.5|0.71"
  "693478__jakobgille__watrfall_small-waterfall_gille_graz_zoomh3_binaural1o.wav|cascade1.m4a|-1.5|0.71"
  "671473__ambient-x__city-snowfall-90-minutes-warren-michigan-winter-storm-on-1-25-23.wav|neigeVille1.m4a|-6|0.25"
  "836527__forestfjord__autumn-downpour-log-cabin-axelfors-part-1.m4a|pluieCabane1.m4a|-1.5|0.71"
  "785210__nicola_ariutti__parque_cucao_pasarela_pt1_mirador-zoom164_165.flac|foretChiloe1.m4a|-1.5|0.71"
  "328294__felixblume__forest-at-dawn-owl-birds-crickets-and-insects-in-the-sian-kaan-biosphere-reserve.wav|aubeJungle1.m4a|-1.5|0.71"
  "848489__micmussfilm__small-harbor-ambiance-waves-seagulls-boats-and-distant-traffic.wav|port1.m4a|-1.5|0.71"
  "265963__refrain__goats-and-bells.wav|chevres1.m4a|-3|0.5"
  "196015__mc2method__wind-chimes.flac|carillons1.m4a|-1.5|0.71"
  "109230__inchadney__distant-churchbells.wav|cloches1.m4a|-1.5|0.71"
)

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 1
  fi
}

json_value() {
  python3 - "$1" "$2" <<'PY'
import json
import sys

payload, key = sys.argv[1], sys.argv[2]
data = json.loads(payload)
print(data[key])
PY
}

duration_seconds() {
  ffprobe -v error -show_entries format=duration -of default=nokey=1:noprint_wrappers=1 "$1"
}

loudnorm_stats() {
  local src_path="$1"
  local true_peak="$2"
  local input_args=()
  if (( $# > 2 )); then
    input_args=("${@:3}")
  fi
  local output
  if (( ${#input_args[@]} > 0 )); then
    output=$(
      ffmpeg -hide_banner -nostats "${input_args[@]}" -i "$src_path" \
        -af "loudnorm=I=-20:TP=${true_peak}:LRA=11:print_format=json" \
        -f null - 2>&1 >/dev/null
    )
  else
    output=$(
      ffmpeg -hide_banner -nostats -i "$src_path" \
        -af "loudnorm=I=-20:TP=${true_peak}:LRA=11:print_format=json" \
        -f null - 2>&1 >/dev/null
    )
  fi
  python3 - <<'PY' "$output"
import json
import re
import sys

text = sys.argv[1]
match = re.search(r"\{\s*\"input_i\".*?\}", text, re.S)
if not match:
    print(text)
    raise SystemExit("Could not parse loudnorm stats")
print(json.dumps(json.loads(match.group(0))))
PY
}

require_tool ffmpeg
require_tool ffprobe
require_tool python3

mkdir -p "$DST"

echo "Converting ${#MAP[@]} files to AAC-LC 96 kbps m4a..."
for entry in "${MAP[@]}"; do
  IFS="|" read -r src_name dst_name true_peak limiter_limit <<< "$entry"
  src_path="$SRC/$src_name"
  dst_path="$DST/$dst_name"

  if [[ ! -f "$src_path" ]]; then
    echo "  [SKIP] Missing: $src_name"
    continue
  fi

  dur=$(duration_seconds "$src_path")
  input_args=()
  if python3 - "$dur" <<'PY'
import sys
raise SystemExit(0 if float(sys.argv[1]) > 2700 else 1)
PY
  then
    input_args=(-ss 30 -t 2700)
    echo "  [..] $src_name -> $dst_name (trimmed to 45:00 from +30s)"
  else
    echo "  [..] $src_name -> $dst_name"
  fi

  if (( ${#input_args[@]} > 0 )); then
    stats=$(loudnorm_stats "$src_path" "$true_peak" "${input_args[@]}")
  else
    stats=$(loudnorm_stats "$src_path" "$true_peak")
  fi
  measured_i=$(json_value "$stats" input_i)
  measured_tp=$(json_value "$stats" input_tp)
  measured_lra=$(json_value "$stats" input_lra)
  measured_thresh=$(json_value "$stats" input_thresh)
  target_offset=$(json_value "$stats" target_offset)

  filter="loudnorm=I=-20:TP=${true_peak}:LRA=11:measured_I=${measured_i}:measured_TP=${measured_tp}:measured_LRA=${measured_lra}:measured_thresh=${measured_thresh}:offset=${target_offset}:linear=true:print_format=summary,alimiter=limit=${limiter_limit}:level=false,aformat=sample_fmts=fltp:channel_layouts=stereo"

  if (( ${#input_args[@]} > 0 )); then
    ffmpeg -hide_banner -y "${input_args[@]}" -i "$src_path" \
      -af "$filter" \
      -ar 44100 -ac 2 -c:a aac -b:a 96k -movflags +faststart "$dst_path"
  else
    ffmpeg -hide_banner -y -i "$src_path" \
      -af "$filter" \
      -ar 44100 -ac 2 -c:a aac -b:a 96k -movflags +faststart "$dst_path"
  fi

  size=$(stat -f%z "$dst_path")
  out_dur=$(duration_seconds "$dst_path")
  printf "  [OK] %s (%.1f MB, %.1f min)\n" "$dst_name" "$(echo "scale=1; $size/1048576" | bc)" "$(echo "scale=1; $out_dur/60" | bc)"
done

echo "Done."
