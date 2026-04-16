#!/bin/bash
set -euo pipefail

SRC="$HOME/Downloads"
DST="/Users/jonathanluquet/CODE/evasion/ios-native/OasisNative/Resources/Audio"

declare -a MAP=(
  "688992__ambient-x__campfire-just-after-dusk-on-the-st-marys-river-5-28-23-9-minutes.wav|campfire1.m4a"
  "422097__felixblume__restaurant-atmosphere-crowded.wav|cafe1.m4a"
  "445956__yarmonics__180905-fritton-lake-lakeside-2-stereo-hydrophone_01.mp3|lac1.m4a"
  "512090__eardeer__mkuze-river.wav|savane1.m4a"
  "587720__globofonia__night-montepio-frogs-crikets-and-night-birds.wav|jungleamerique1.m4a"
  "250273__anantich__140930-night-jungle-nature-ambiencechiangmai_thailand-cicades-dew-drops-ortfsd664cs3e.wav|jungleasie1.m4a"
)

echo "Converting 6 files to HE-AAC 40kbps m4a..."
for entry in "${MAP[@]}"; do
  src_name="${entry%|*}"
  dst_name="${entry#*|}"
  src_path="$SRC/$src_name"
  dst_path="$DST/$dst_name"

  if [[ ! -f "$src_path" ]]; then
    echo "  [SKIP] Missing: $src_name"
    continue
  fi

  echo "  [..] $src_name -> $dst_name"
  afconvert -f m4af -d 'aach@24000' -b 40000 -s 0 "$src_path" "$dst_path"
  size=$(stat -f%z "$dst_path")
  dur=$(afinfo "$dst_path" 2>/dev/null | awk '/estimated duration/ {print $3}')
  printf "  [OK] %s (%.1f MB, %s sec)\n" "$dst_name" "$(echo "scale=1; $size/1048576" | bc)" "$dur"
done
echo "Done."
ls -lh "$DST" | grep -E "(campfire|cafe|lac|savane|jungle)" | awk '{print "  " $NF, $5}'
