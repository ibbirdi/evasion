#!/usr/bin/env python3
"""
Adds the new SoundChannelMetadata.swift and SoundDetailSheet.swift Swift files
and the 6 new ambient m4a audio files to the OasisNative Xcode target.

Idempotent: already-registered files are skipped.
"""

import re
import sys
from pathlib import Path

PBXPROJ = Path(__file__).resolve().parents[1] / "ios-native/OasisNative.xcodeproj/project.pbxproj"

# (filename, file UUID, build UUID, kind, group UUID)
# kind is "sourcecode.swift" or "file"
# Group UUIDs:
#   Models:   9F931F38A9610F04344AB17F
#   Overlays: 61C1233ED79C77E89155DFE0  (discovered below)
#   Audio:    D93EF40917181671FE83DA9B

FILES_SPEC = [
    {
        "name": "SoundChannelMetadata.swift",
        "file_uuid": "A20000000000000000000010",
        "build_uuid": "A10000000000000000000010",
        "kind": "sourcecode.swift",
        "phase": "Sources",
        "group_uuid": "9F931F38A9610F04344AB17F",  # Models
    },
    {
        "name": "SoundDetailSheet.swift",
        "file_uuid": "A20000000000000000000011",
        "build_uuid": "A10000000000000000000011",
        "kind": "sourcecode.swift",
        "phase": "Sources",
        # Overlays group UUID is looked up at runtime.
        "group_path": "Overlays",
    },
    {"name": "campfire1.m4a",        "file_uuid": "A20000000000000000000020", "build_uuid": "A10000000000000000000020", "kind": "file", "phase": "Resources", "group_uuid": "D93EF40917181671FE83DA9B"},
    {"name": "cafe1.m4a",            "file_uuid": "A20000000000000000000021", "build_uuid": "A10000000000000000000021", "kind": "file", "phase": "Resources", "group_uuid": "D93EF40917181671FE83DA9B"},
    {"name": "lac1.m4a",             "file_uuid": "A20000000000000000000022", "build_uuid": "A10000000000000000000022", "kind": "file", "phase": "Resources", "group_uuid": "D93EF40917181671FE83DA9B"},
    {"name": "savane1.m4a",          "file_uuid": "A20000000000000000000023", "build_uuid": "A10000000000000000000023", "kind": "file", "phase": "Resources", "group_uuid": "D93EF40917181671FE83DA9B"},
    {"name": "jungleamerique1.m4a",  "file_uuid": "A20000000000000000000024", "build_uuid": "A10000000000000000000024", "kind": "file", "phase": "Resources", "group_uuid": "D93EF40917181671FE83DA9B"},
    {"name": "jungleasie1.m4a",      "file_uuid": "A20000000000000000000025", "build_uuid": "A10000000000000000000025", "kind": "file", "phase": "Resources", "group_uuid": "D93EF40917181671FE83DA9B"},
]


def find_group_uuid_by_path(text: str, group_path: str) -> str:
    pattern = re.compile(
        r"([0-9A-F]{24})\s*/\*\s*" + re.escape(group_path) + r"\s*\*/\s*=\s*\{\s*isa\s*=\s*PBXGroup;",
        re.IGNORECASE,
    )
    match = pattern.search(text)
    if not match:
        raise RuntimeError(f"Could not locate group path '{group_path}' in pbxproj.")
    return match.group(1)


def insert_in_section(text: str, section_begin: str, section_end: str, inject: str) -> str:
    """Insert `inject` right before the end marker of a named section."""
    idx = text.find(section_begin)
    if idx < 0:
        raise RuntimeError(f"Missing section begin marker: {section_begin}")
    end_idx = text.find(section_end, idx)
    if end_idx < 0:
        raise RuntimeError(f"Missing section end marker: {section_end}")
    return text[:end_idx] + inject + text[end_idx:]


def insert_in_group(text: str, group_uuid: str, child_line: str) -> str:
    """Insert a child UUID line into the `children = (...)` of the given PBXGroup."""
    pattern = re.compile(
        r"(" + re.escape(group_uuid) + r"[^=]*=\s*\{\s*isa\s*=\s*PBXGroup;[^}]*?children\s*=\s*\()([^)]*)(\);)",
        re.DOTALL,
    )
    match = pattern.search(text)
    if not match:
        raise RuntimeError(f"Could not locate children block for group {group_uuid}")
    prefix, inner, suffix = match.group(1), match.group(2), match.group(3)
    if child_line.strip() in inner:
        return text  # already present
    # Keep consistent indentation (tabs).
    new_inner = inner.rstrip() + "\n\t\t\t\t" + child_line.strip() + ",\n\t\t\t"
    return text[:match.start()] + prefix + new_inner + suffix + text[match.end():]


def insert_in_phase(text: str, phase_label: str, file_uuid: str, name: str, kind_label: str) -> str:
    """
    Insert `{file_uuid} /* name in {phase_label} */,` inside the `files = (...)` block
    of the main target's PBXResourcesBuildPhase / PBXSourcesBuildPhase.
    """
    # Find all phase sections — the main target's is the one with content.
    section_begin = f"Begin PBX{phase_label}BuildPhase section"
    section_end = f"End PBX{phase_label}BuildPhase section"
    start = text.find(section_begin)
    end = text.find(section_end, start)
    if start < 0 or end < 0:
        raise RuntimeError(f"Missing {phase_label} build phase section")
    block = text[start:end]
    # There can be multiple phase blocks (UITests target too). Pick the largest (main target).
    phase_blocks = list(re.finditer(
        r"([0-9A-F]{24})\s*/\*\s*" + phase_label + r"\s*\*/\s*=\s*\{[^}]*?files\s*=\s*\(([^)]*)\);",
        block,
        re.DOTALL,
    ))
    if not phase_blocks:
        raise RuntimeError(f"No {phase_label} phase blocks found")
    target_block = max(phase_blocks, key=lambda m: len(m.group(2)))
    inner = target_block.group(2)
    line = f"{file_uuid} /* {name} in {phase_label} */,"
    if line in inner:
        return text  # already present
    new_inner = inner.rstrip() + "\n\t\t\t" + line + "\n\t\t"
    new_block = block[:target_block.start(2)] + new_inner + block[target_block.end(2):]
    return text[:start] + new_block + text[end:]


def main() -> int:
    text = PBXPROJ.read_text(encoding="utf-8")
    initial = text

    # Resolve Overlays group UUID.
    overlays_uuid = find_group_uuid_by_path(text, "Overlays")

    for spec in FILES_SPEC:
        name = spec["name"]
        file_uuid = spec["file_uuid"]
        build_uuid = spec["build_uuid"]
        kind = spec["kind"]
        phase = spec["phase"]
        group_uuid = spec.get("group_uuid") or (overlays_uuid if spec.get("group_path") == "Overlays" else None)
        if group_uuid is None:
            raise RuntimeError(f"Could not resolve group for {name}")

        # Skip if already present.
        if file_uuid in text and build_uuid in text:
            print(f"[skip] {name} already registered.")
            continue

        # 1. PBXBuildFile entry
        build_line = f"\t\t{build_uuid} /* {name} in {phase} */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {name} */; }};\n"
        text = insert_in_section(text, "/* Begin PBXBuildFile section */", "/* End PBXBuildFile section */", build_line)

        # 2. PBXFileReference entry
        file_line = f"\t\t{file_uuid} /* {name} */ = {{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = {kind}; path = {name}; sourceTree = \"<group>\"; }};\n"
        text = insert_in_section(text, "/* Begin PBXFileReference section */", "/* End PBXFileReference section */", file_line)

        # 3. Group membership
        text = insert_in_group(text, group_uuid, f"{file_uuid} /* {name} */")

        # 4. Build phase membership
        text = insert_in_phase(text, phase, build_uuid, name, phase)

        print(f"[ok] Registered {name}")

    if text == initial:
        print("No changes to write.")
        return 0

    PBXPROJ.write_text(text, encoding="utf-8")
    print("Wrote updated pbxproj.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
