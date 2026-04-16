#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_AUDIO_DIR="$PROJECT_DIR/OasisNative/Resources/Audio"

SOURCE_DIR="${1:-$DEFAULT_AUDIO_DIR}"
OUTPUT_DIR="${2:-$SOURCE_DIR}"
BITRATE="${OASIS_AUDIO_BITRATE:-40000}"

if ! command -v afconvert >/dev/null 2>&1; then
  echo "error: afconvert is required and was not found." >&2
  exit 1
fi

if ! command -v afinfo >/dev/null 2>&1; then
  echo "error: afinfo is required and was not found." >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "error: source audio directory not found: $SOURCE_DIR" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/oasis-audio.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Optimizing Oasis audio assets"
echo "source: $SOURCE_DIR"
echo "output: $OUTPUT_DIR"
echo "codec: HE-AAC (.m4a), bitrate: ${BITRATE} bps"

shopt -s nullglob
audio_files=("$SOURCE_DIR"/*.m4a)
if (( ${#audio_files[@]} == 0 )); then
  echo "error: no .m4a files found in $SOURCE_DIR" >&2
  exit 1
fi

for source_file in "${audio_files[@]}"; do
  filename="$(basename "$source_file")"
  temp_file="$WORK_DIR/$filename"
  output_file="$OUTPUT_DIR/$filename"

  echo "-> $filename"
  afconvert "$source_file" "$temp_file" \
    -f m4af \
    -d aach \
    -b "$BITRATE" \
    --soundcheck-generate \
    --no-filler

  afinfo "$temp_file" >/dev/null
  mv "$temp_file" "$output_file"
done

echo
du -sh "$OUTPUT_DIR"
