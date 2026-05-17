# Oasis — Marketing Video Factory

Scenario-driven marketing video generator for **Oasis** (TikTok, Instagram Reels, YouTube Shorts).

Each video is produced by:

1. **Booting an iPhone 17 Pro Max simulator** and screen-recording it.
2. **Replaying a scripted scenario** (`scenarios/<id>.json`) — taps, slider drags, spatial puck drags, sheet dismissals — via an XCUITest target inside the Oasis project.
3. **Post-processing** the raw recording with FFmpeg: crop to 9:16, overlay timed text, layer the Oasis audio mix on top, encode H.264/AAC.
4. Writing a `.mp4` next to a `.json` sidecar (caption + hashtags ready to post).

No SaaS, no backend, no Figma comps — only the iOS Simulator and FFmpeg.

---

## Prerequisites

- macOS with Xcode + the iPhone 17 Pro Max simulator runtime
- Node.js **≥ 20**
- FFmpeg on PATH (`brew install ffmpeg`)

---

## Install

```bash
cd marketing-video-factory
npm install
npm run sync        # symlinks Oasis audio aliases (rain.m4a, forest.m4a, …)
npm run validate    # checks FFmpeg + configs + scenarios
```

---

## Quickstart

```bash
npm run record -- --scenario sleep-rain-demo
```

What this does:

1. Picks (or boots) the `iPhone 17 Pro Max` simulator.
2. Builds the UI test target (cached after first run).
3. Starts `xcrun simctl io booted recordVideo` in the background.
4. Runs the XCUITest `OasisNativeUITests/MarketingScenarioRunner/testRunScenario` which reads the scenario JSON and replays its action timeline against the live app.
5. Stops the recording when the test ends.
6. Reads the start-marker the test left behind, so FFmpeg skips boot/xcodebuild overhead.
7. Crops the raw recording to 1080×1920, overlays timed text, layers the configured Oasis audio mix, encodes the final MP4.

Output:

```
output/<YYYY-MM-DD>/oasis_<scenario>_<lang>_<time>_<seed>.mp4
output/<YYYY-MM-DD>/oasis_<scenario>_<lang>_<time>_<seed>.json   # caption + hashtags + metadata
```

---

## Commands

| Command | What it does |
|---|---|
| `npm run validate` | Checks FFmpeg, configs, and scenarios — reports issues with hints. |
| `npm run list` | Lists scenarios and audio mixes. |
| `npm run record -- --scenario <id>` | Records and renders one scenario. |
| `npm run sync` | Symlinks Oasis audio from `ios-native/.../Audio/` into `assets/audio/`. |
| `npm run clean` | Removes `.tmp/`. Add `--all` to also wipe `output/`. |
| `npm run typecheck` | Runs `tsc --noEmit`. |

`record` flags:

```
--scenario <id>     scenario filename without .json (default: sleep-rain-demo)
--lang <fr|en>      overrides the scenario's lang (also drives the iOS UI locale)
--device <name>     simulator name (default: "iPhone 17 Pro Max")
--seed <n>          deterministic hook/caption pick
--dry-run           prints the plan, skips the simulator and FFmpeg
--keep-raw          keeps the simulator's raw .mp4 alongside the final output
--debug             streams xcodebuild and FFmpeg output inline
```

---

## Scenario format

Scenarios live in `scenarios/<id>.json`. Each describes a timeline of actions and overlays:

```jsonc
{
  "id": "sleep-rain-demo",
  "mood": "sleep",                       // sleep | focus | immersion | premium | product
  "angle": "ambient-mixing",
  "lang": "fr",
  "duration": 18,                        // seconds — the test runs for exactly this long
  "premium": "premium",                  // launches the app with premium unlocked
  "audioMix": "sleep-rain-thunder",      // mix from config/audio-mixes.json
  "hookCategory": "sleep",               // pool from config/hooks.<lang>.json
  "captionCategory": "sleep",            // pool from config/captions.<lang>.json
  "hashtagCategories": ["core", "sleep", "general"],

  "actions": [
    { "at": 1.2,  "type": "setSlider",   "target": "channel.slider.pluie",   "value": 0.75 },
    { "at": 2.6,  "type": "setSlider",   "target": "channel.slider.foret",   "value": 0.50 },
    { "at": 4.0,  "type": "setSlider",   "target": "channel.slider.tonnerre","value": 0.22 },
    { "at": 5.6,  "type": "tap",         "target": "channel.spatial.pluie" },
    { "at": 6.8,  "type": "dragSpatial", "to": { "x": -0.7, "y":  0.7 }, "duration": 1.6 },
    { "at": 8.6,  "type": "dragSpatial", "to": { "x":  0.0, "y":  0.85 },"duration": 1.2 },
    { "at": 10.2, "type": "dismissPanel" },
    { "at": 11.6, "type": "tap",         "target": "home.bottom.presets" },
    { "at": 13.0, "type": "dismissPanel" }
  ],

  "overlays": [
    { "start": 0.4,  "duration": 4.4, "textRef": "hook",                                    "position": "top"    },
    { "start": 5.4,  "duration": 4.6, "text": { "fr": "Place chaque son dans l'espace." }, "position": "top"    },
    { "start": 15.8, "duration": 2.2, "text": { "fr": "Oasis — sons naturels immersifs" }, "position": "bottom" }
  ]
}
```

### Actions

| `type` | Fields | What it does |
|---|---|---|
| `wait` | `duration` | Sleeps for `duration` seconds. |
| `tap` | `target` (accessibility id), optional `kind` (`button`/`otherElement`/`slider`/`any`) | Taps the element. |
| `setSlider` | `target`, `value` ∈ [0, 1] | Drags the slider to a normalized value. |
| `dragSpatial` | `to: {x, y}` ∈ [-1, 1], `duration`, optional `from` | Drags the spatial-audio puck. x = left↔right, y = front↔back. |
| `swipe` | `target`, `direction` (`up`/`down`/`left`/`right`) | Swipes a specific element. |
| `scrollTo` | `target`, `maxSwipes` | Scrolls the home list until the target is hittable. |
| `dismissPanel` | — | Drags the topmost bottom sheet down to dismiss it. |

Every action carries an `at` timestamp in seconds from scenario start. The runner schedules actions on a monotonic clock so the recording timeline matches the JSON exactly.

### Available iOS accessibility identifiers

Channels (substitute `<id>` with `pluie`, `vent`, `foret`, `tonnerre`, `mer`, `plage`, `oiseaux`, `riviere`, `lac`, `goelands`, `cigales`, `grillons`, `tente`, `campfire`, `cafe`, `village`, `mer`, `orageMontagne`, `savane`, `jungleAmerique`, `jungleAsie`):

- `channel.row.<id>`       — full row container
- `channel.identity.<id>`  — tap → opens the sound-detail sheet
- `channel.mute.<id>`      — left icon button (mute toggle)
- `channel.slider.<id>`    — volume slider
- `channel.spatial.<id>`   — opens the spatial sheet for this channel
- `channel.auto.<id>`      — AUTO pill

Header & bottom bar:

- `home.scroll`
- `home.header.timer`
- `home.bottom.shuffle`
- `home.bottom.playback`
- `home.bottom.presets`
- `home.bottom.binaural`
- `home.bottom.routepicker`

Panels (sheets):

- `panel.spatial.container`, `spatial.stage` (drag target)
- `panel.presets.container`, `presets.row.<id>`, `presets.name`, `presets.save`
- `panel.binaural.container`, `binaural.track.<delta|theta|alpha|beta>`, `binaural.tonalBed.toggle`
- `panel.sound-detail.container`
- `panel.timer.unlock`, `timer.unlock.option.<duration>`

Paywall + premium teaser:

- `premium.paywall.container`, `premium.paywall.primary`, `premium.paywall.restore`, `premium.paywall.close`
- `premium.library.teaser`, `premium.library.teaser.primary`

### Overlays

Same structure as actions: `start`, `duration`, `position`. The overlay text can be a localised pair `{ fr, en }` or `textRef: "hook" | "caption"` which pulls from `config/hooks.<lang>.json` / `config/captions.<lang>.json`.

Positions:

- `top` — narrow band above the OASIS header (y ≈ 80–250)
- `bottom` — band above the bottom bar (y ≈ 1640–1820)
- `center` — over the middle of the frame (used sparingly)

---

## How the simulator sync works

The simulator's screen recording starts immediately, but `xcodebuild test` then takes several seconds (build cache check + test runner boot + app launch). The XCUITest writes the Unix timestamp of the scenario-start moment to a known file. After the test finishes, the Node driver reads it and computes `startOffsetSec = scenarioStartedAt - recordingStartedAt`. FFmpeg seeks past that with `-ss` before cropping to the scenario duration. The output's frame 0 is therefore exactly the first action of the scenario.

---

## Config (shared across scenarios)

- `config/audio-mixes.json`   — track + volume + fade definitions
- `config/hooks.fr.json` / `hooks.en.json`
- `config/captions.fr.json` / `captions.en.json`
- `config/hashtags.json`

The same hooks/captions/hashtags pools are reused across scenarios — each scenario references a category, and the renderer picks one entry deterministically (seeded by `--seed`).

---

## Adding a new scenario

1. Decide the angle (sleep, focus, spatial, paywall, presets, binaural, etc.).
2. Write `scenarios/<id>.json` following the schema above.
3. `npm run validate` to check cross-references.
4. `npm run record -- --scenario <id> --keep-raw` and review the output.
5. Iterate on action timings and overlay placement.

The XCUITest runner is **generic** — it works for any scenario JSON. You never need to touch Swift to add a new video, only to add new identifiers to the iOS Views.
