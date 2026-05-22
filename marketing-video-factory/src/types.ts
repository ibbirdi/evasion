import { z } from "zod";

export const LANGS = ["fr", "en", "de", "es", "it", "ptbr"] as const;
export const LangSchema = z.enum(LANGS);
export type Lang = z.infer<typeof LangSchema>;

export const PositionSchema = z.enum(["top", "center", "bottom"]);
export type Position = z.infer<typeof PositionSchema>;

export const SizeSchema = z.enum(["sm", "md", "lg", "xl", "xxl"]);
export type Size = z.infer<typeof SizeSchema>;

export const MoodSchema = z.enum([
  "sleep",
  "focus",
  "immersion",
  "premium",
  "product",
]);
export type Mood = z.infer<typeof MoodSchema>;

const LocalizedTextSchema = z.object({
  fr: z.string().min(1),
  en: z.string().min(1),
  de: z.string().min(1).optional(),
  es: z.string().min(1).optional(),
  it: z.string().min(1).optional(),
  ptbr: z.string().min(1).optional(),
});

export const OverlaySpecSchema = z
  .object({
    start: z.number().min(0),
    duration: z.number().min(0.3),
    position: PositionSchema.default("bottom"),
    size: SizeSchema.optional(),
    // Renders a soft black gradient band behind the text for readability
    // over busy backgrounds (e.g., the live app screen). Off by default —
    // intro overlays usually look better without it.
    backdrop: z.boolean().default(false),
    text: LocalizedTextSchema.optional(),
    textRef: z.enum(["hook", "caption"]).optional(),
  })
  .refine((v) => v.text !== undefined || v.textRef !== undefined, {
    message: "Overlay must declare either `text` or `textRef`.",
  });
export type OverlaySpec = z.infer<typeof OverlaySpecSchema>;

// ---------------- Scenario actions ----------------

// Every action carries `at` (seconds from scenario start). The runner schedules
// actions on a monotonic clock so playback feels deterministic.

const ActionBase = z.object({
  at: z.number().min(0),
  // Optional human note — shown in CLI debug logs.
  label: z.string().optional(),
});

export const WaitActionSchema = ActionBase.extend({
  type: z.literal("wait"),
  duration: z.number().min(0.05).default(0.5),
});

export const TapActionSchema = ActionBase.extend({
  type: z.literal("tap"),
  // Accessibility identifier of the element to tap. Examples:
  //   "channel.mute.pluie"           – mute toggle for the rain channel
  //   "channel.spatial.pluie"        – open the spatial sheet for rain
  //   "channel.identity.foret"       – open the sound-detail sheet for forest
  //   "home.bottom.presets"          – open the presets panel
  //   "home.bottom.binaural"         – open the binaural panel
  //   "home.bottom.shuffle"          – tap shuffle (auto-mix)
  //   "home.bottom.playback"         – toggle play/pause
  //   "home.header.timer"            – open the timer menu
  target: z.string().min(1),
  // Element category — defaults to "button". Some panels are otherElements.
  kind: z
    .enum(["button", "otherElement", "slider", "any"])
    .default("button"),
});

export const SetSliderActionSchema = ActionBase.extend({
  type: z.literal("setSlider"),
  // Accessibility identifier of the slider (e.g. "channel.slider.pluie").
  target: z.string().min(1),
  // Target normalized value in [0, 1].
  value: z.number().min(0).max(1),
});

export const DragSpatialActionSchema = ActionBase.extend({
  type: z.literal("dragSpatial"),
  // Normalized destination on the stage in [-1, 1] for each axis.
  // x: -1 = far left, +1 = far right.
  // y: -1 = front,    +1 = back.
  to: z.object({
    x: z.number().min(-1).max(1),
    y: z.number().min(-1).max(1),
  }),
  // Animate the drag over this many seconds (smooth puck travel).
  duration: z.number().min(0).default(1.2),
  // Optional starting point on the stage (defaults to the centre).
  from: z
    .object({ x: z.number().min(-1).max(1), y: z.number().min(-1).max(1) })
    .optional(),
});

export const SwipeActionSchema = ActionBase.extend({
  type: z.literal("swipe"),
  target: z.string().min(1),
  direction: z.enum(["up", "down", "left", "right"]),
});

export const ScrollToActionSchema = ActionBase.extend({
  type: z.literal("scrollTo"),
  target: z.string().min(1),
  maxSwipes: z.number().int().min(1).max(20).default(8),
});

export const DismissPanelActionSchema = ActionBase.extend({
  type: z.literal("dismissPanel"),
  // Drag handle of the bottom sheet down. Works for spatial, presets, binaural,
  // sound-detail, paywall, timer-unlock — every panel uses presentationDetents.
});

export const ActionSchema = z.discriminatedUnion("type", [
  WaitActionSchema,
  TapActionSchema,
  SetSliderActionSchema,
  DragSpatialActionSchema,
  SwipeActionSchema,
  ScrollToActionSchema,
  DismissPanelActionSchema,
]);
export type Action = z.infer<typeof ActionSchema>;

// ---------------- Scenario ----------------

export const PremiumOverrideSchema = z.enum(["premium", "free"]);
export type PremiumOverride = z.infer<typeof PremiumOverrideSchema>;

export const ScenarioSchema = z.object({
  id: z.string().min(1),
  mood: MoodSchema,
  angle: z.string(),
  lang: LangSchema.default("fr"),
  duration: z.number().min(3).max(60),
  // Force premium/free for the launch. Most marketing scenarios want "premium"
  // so locked features (spatial, binaural) are reachable.
  premium: PremiumOverrideSchema.default("premium"),
  // Audio mix played on top of the recorded video (the simulator does not
  // capture audio reliably, so we layer the mix ourselves).
  audioMix: z.string().min(1),
  hookCategory: z.string().min(1),
  captionCategory: z.string().min(1),
  hashtagCategories: z.array(z.string()).default([]),
  // Actions executed BEFORE the recording's visible window begins. Use this
  // to put the app in a desired state (e.g., toggle the active-tracks filter
  // on, dismiss a sheet) without having the toggle animation appear in the
  // final video. Their `at` timestamps are relative to setup start, not the
  // scenario timeline.
  setup: z.array(ActionSchema).default([]),
  actions: z.array(ActionSchema).min(0),
  overlays: z.array(OverlaySpecSchema).default([]),
  // Overlays composited on the intro video segment only. Timestamps are
  // relative to the intro's start (0 = first frame of the final mp4).
  // Same shape as `overlays`. Ignored if no `intro` is set.
  introOverlays: z.array(OverlaySpecSchema).default([]),
  // Optional intro video prepended to the final output. The intro is
  // re-encoded into the same container (1080×1920, 30fps, H.264/AAC) and
  // fitted via letterbox over a blurred backdrop of itself.
  intro: z
    .object({
      // Absolute path, ~-expanded path, or path relative to the
      // marketing-video-factory root.
      path: z.string().min(1),
      // Optional max duration (s) to take from the intro. Omit to use full.
      duration: z.number().min(0.5).optional(),
    })
    .optional(),
  // Optional outro card appended to the final output. The `svg` path resolves
  // the same way as `intro.path` (absolute / ~ / relative to root); the SVG
  // is rasterised to a 1080×1920 PNG and looped for `duration` seconds, then
  // cross-faded against the body. Defaults to the bundled
  // assets/branding/oasis-end-card.svg when only `duration` is set.
  outro: z
    .object({
      svg: z.string().min(1).optional(),
      duration: z.number().min(0.5).max(8).default(2.6),
    })
    .optional(),
});
export type Scenario = z.infer<typeof ScenarioSchema>;

// ---------------- Audio / hooks / captions / hashtags ----------------

export const AudioTrackSchema = z.object({
  file: z.string().min(1),
  volume: z.number().min(0).max(2).default(1),
});
export type AudioTrack = z.infer<typeof AudioTrackSchema>;

export const AudioMixSchema = z.object({
  id: z.string().min(1),
  description: z.string().optional(),
  tracks: z.array(AudioTrackSchema).min(1),
  fadeIn: z.number().min(0).default(1),
  fadeOut: z.number().min(0).default(1),
});
export type AudioMix = z.infer<typeof AudioMixSchema>;

export const HooksFileSchema = z.record(z.string(), z.array(z.string().min(1)).min(1));
export type HooksFile = z.infer<typeof HooksFileSchema>;

export const CaptionsFileSchema = z.record(
  z.string(),
  z.array(z.string().min(1)).min(1),
);
export type CaptionsFile = z.infer<typeof CaptionsFileSchema>;

export const HashtagsFileSchema = z.object({
  fr: z.record(z.string(), z.array(z.string())),
  en: z.record(z.string(), z.array(z.string())),
  de: z.record(z.string(), z.array(z.string())),
  es: z.record(z.string(), z.array(z.string())),
  it: z.record(z.string(), z.array(z.string())),
  ptbr: z.record(z.string(), z.array(z.string())),
});
export type HashtagsFile = z.infer<typeof HashtagsFileSchema>;

export const AudioMixesFileSchema = z.object({
  mixes: z.array(AudioMixSchema).min(1),
});

// ---------------- Bundle ----------------

export interface ConfigBundle {
  mixes: AudioMix[];
  hooks: Record<Lang, HooksFile>;
  captions: Record<Lang, CaptionsFile>;
  hashtags: HashtagsFile;
}

export interface ResolvedOverlay {
  start: number;
  duration: number;
  position: Position;
  text: string;
  size?: Size;
  backdrop?: boolean;
}

export interface VideoMetadata {
  video: string;
  scenario: string;
  lang: Lang;
  mood: Mood;
  hook: string;
  caption: string;
  hashtags: string[];
  audioMix: string;
  durationSeconds: number;
  rawRecording: string;
  intro?: string;
  outro?: string;
  createdAt: string;
  seed: number;
}

export interface GenerateOptions {
  scenarioId: string;
  lang?: Lang;
  outputDir: string;
  seed?: number;
  dryRun: boolean;
  debug: boolean;
  device: string;
  keepRaw: boolean;
}
