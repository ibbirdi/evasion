import path from "node:path";

import {
  collectHashtags,
  findMix,
  loadConfig,
  loadScenario,
  OUTPUT_DIR,
  pickCaption,
  pickHook,
  TMP_DIR,
} from "../config.js";
import { FactoryError, log } from "../logger.js";
import { resolveTracks } from "../render/renderAudioMix.js";
import { writeMetadataJson } from "../render/renderCaption.js";
import { postProcess } from "../render/postProcess.js";
import {
  concatIntroAndBody,
  type IntroOverlay,
  resolveIntroPath,
} from "../render/concatIntro.js";
import { renderOverlayPng } from "../render/renderOverlay.js";
import { renderOutroPng, resolveOutroSvgPath } from "../render/renderOutro.js";
import type {
  GenerateOptions,
  Lang,
  Scenario,
  VideoMetadata,
  ResolvedOverlay,
} from "../types.js";
import { ensureDir, removeIfExists } from "../utils/fs.js";
import { createRng, makePicker, randomSeed } from "../utils/random.js";
import { formatDateStamp, formatTimeStamp, slugify } from "../utils/slug.js";

import {
  bootDevice,
  findDevice,
  startVideoRecording,
} from "./simulator.js";
import {
  ensureTestBuild,
  readStartMarker,
  runXCUITest,
  writeScenarioFile,
} from "./runTest.js";

const SCHEME = "OasisNative";
const UI_TEST_ID = "OasisNativeUITests/MarketingScenarioRunner/testRunScenario";

export interface RecordResult {
  videoPath: string;
  metadataPath: string;
  meta: VideoMetadata;
  skipped: boolean;
}

function resolveOverlaysList(
  list: Scenario["overlays"],
  scenarioId: string,
  lang: Lang,
  hook: string,
  caption: string,
): ResolvedOverlay[] {
  return list.map((ov) => {
    let text: string;
    if (ov.textRef === "hook") text = hook;
    else if (ov.textRef === "caption") text = caption;
    else if (ov.text) text = ov.text[lang];
    else
      throw new FactoryError(
        `Overlay in scenario "${scenarioId}" missing text/textRef.`,
      );
    return {
      start: ov.start,
      duration: ov.duration,
      position: ov.position,
      text,
      ...(ov.size ? { size: ov.size } : {}),
      ...(ov.backdrop ? { backdrop: true } : {}),
    };
  });
}

function resolveOverlays(
  scenario: Scenario,
  lang: Lang,
  hook: string,
  caption: string,
): ResolvedOverlay[] {
  return resolveOverlaysList(scenario.overlays, scenario.id, lang, hook, caption);
}


export async function recordScenario(opts: GenerateOptions): Promise<RecordResult> {
  const bundle = await loadConfig();
  const scenario = await loadScenario(opts.scenarioId);
  const lang = opts.lang ?? scenario.lang;
  // The XCUITest reads `premium`, `actions`, `duration`, `id` from the JSON.
  // We persist the lang at the top-level too in case future scenarios localise actions.
  const mix = findMix(bundle, scenario.audioMix);
  if (!mix) {
    throw new FactoryError(
      `Scenario "${scenario.id}" references unknown audio mix "${scenario.audioMix}".`,
    );
  }
  const tracks = await resolveTracks(mix);

  const seed = opts.seed ?? randomSeed();
  const rng = createRng(seed);
  const picker = makePicker(rng);
  const hook = pickHook(bundle, lang, scenario.hookCategory, picker);
  const caption = pickCaption(bundle, lang, scenario.captionCategory, picker);
  const hashtags = collectHashtags(bundle, lang, scenario.hashtagCategories);
  const overlays = resolveOverlays(scenario, lang, hook, caption);

  const dateDir = path.join(opts.outputDir ?? OUTPUT_DIR, formatDateStamp());
  await ensureDir(dateDir);
  const baseName = `oasis_${slugify(scenario.id)}_${lang}_${formatTimeStamp()}_${seed.toString(36)}`;
  const videoPath = path.join(dateDir, `${baseName}.mp4`);
  const metadataPath = path.join(dateDir, `${baseName}.json`);
  const rawRecording = path.join(TMP_DIR, `${baseName}_raw.mp4`);
  const buildLogPath = path.join(TMP_DIR, `${baseName}_test.log`);

  // If the scenario declares an intro video, the post-process renders the
  // scenario body to a temp file first; a second FFmpeg pass concatenates
  // intro + body and writes the final mp4 to `videoPath`.
  const introResolvedPath = scenario.intro ? resolveIntroPath(scenario.intro.path) : null;
  const bodyOnlyPath = introResolvedPath
    ? path.join(TMP_DIR, `${baseName}_body.mp4`)
    : videoPath;

  log.banner("Oasis Video Factory — scenario record");
  log.step("Scenario", scenario.id);
  log.step("Language", lang);
  log.step("Device", opts.device);
  log.step("Duration", `${scenario.duration}s`);
  log.step("Audio mix", mix.id);
  log.step("Hook", hook);
  log.step("Caption", caption);
  log.step("Hashtags", hashtags.join(" "));
  log.step("Output", path.relative(process.cwd(), videoPath));

  const meta: VideoMetadata = {
    video: path.relative(process.cwd(), videoPath),
    scenario: scenario.id,
    lang,
    mood: scenario.mood,
    hook,
    caption,
    hashtags,
    audioMix: mix.id,
    durationSeconds: scenario.duration,
    rawRecording: path.relative(process.cwd(), rawRecording),
    ...(introResolvedPath
      ? { intro: path.relative(process.cwd(), introResolvedPath) }
      : {}),
    createdAt: new Date().toISOString(),
    seed,
  };

  if (opts.dryRun) {
    log.warn("Dry run — skipping simulator + FFmpeg. Writing metadata only.");
    await writeMetadataJson(metadataPath, meta);
    return { videoPath, metadataPath, meta, skipped: true };
  }

  // The scenario file the XCUITest reads. Pinned path so the test does not
  // need command-line argument plumbing through xcodebuild.
  const scenarioPath = await writeScenarioFile({ ...scenario, lang }, lang);

  // Pick + boot the simulator.
  const device = await findDevice(opts.device);
  await bootDevice(device);
  log.step("Simulator", `${device.name} (${device.udid.slice(0, 8)}…)`);

  // Build the UI test target up-front so we don't time the test against an
  // unrelated compilation step.
  await ensureTestBuild({ device, scheme: SCHEME, debug: opts.debug });

  // Start the screen recording, then run the test. The test launches the app
  // and replays the scenario actions on a precise schedule.
  await ensureDir(TMP_DIR);
  await removeIfExists(rawRecording);
  const recordingStartedAtUnix = Date.now() / 1000;
  const recorder = startVideoRecording(device, rawRecording);
  log.info("Recording started — replaying scenario in the simulator…");

  let testError: unknown = null;
  try {
    await runXCUITest({
      device,
      scenarioPath,
      testIdentifier: UI_TEST_ID,
      scheme: SCHEME,
      buildLogPath,
      debug: opts.debug,
    });
  } catch (err) {
    testError = err;
  } finally {
    await recorder.stop();
    log.info("Recording stopped.");
  }

  if (testError) {
    log.warn(`UI test reported an error: ${(testError as Error).message}`);
  }

  // Sync: the XCUITest stamps a Unix timestamp right before it starts running
  // scenario actions. Subtract the moment we started the recording to know
  // how many seconds of boot/xcodebuild overhead to skip in FFmpeg.
  const scenarioStartedAtUnix = await readStartMarker();
  let startOffsetSec = 0;
  if (scenarioStartedAtUnix != null) {
    startOffsetSec = Math.max(0, scenarioStartedAtUnix - recordingStartedAtUnix);
    log.step("Start offset", `${startOffsetSec.toFixed(2)}s (boot + xcodebuild overhead)`);
  } else {
    log.warn("No start marker from the XCUITest — using offset 0 (recording may start before app launch).");
  }

  log.info("Post-processing recording…");
  await postProcess({
    rawRecording,
    startOffsetSec,
    duration: scenario.duration,
    overlays,
    mix,
    tracks,
    output: bodyOnlyPath,
    debug: opts.debug,
    baseName,
  });

  if (introResolvedPath) {
    log.step("Intro", path.relative(process.cwd(), introResolvedPath));

    // Resolve intro overlays (hook/caption refs supported, same as body).
    const introOverlays = resolveOverlaysList(
      scenario.introOverlays,
      scenario.id,
      lang,
      hook,
      caption,
    );

    // Pre-render each intro overlay to a transparent 1080×1920 PNG.
    const introOverlayPngs: IntroOverlay[] = [];
    for (let i = 0; i < introOverlays.length; i++) {
      const ov = introOverlays[i]!;
      const png = path.join(TMP_DIR, `${baseName}_intro_ov${i}.png`);
      await renderOverlayPng({
        text: ov.text,
        position: ov.position,
        ...(ov.size ? { size: ov.size } : {}),
        ...(ov.backdrop ? { backdrop: true } : {}),
        outPath: png,
      });
      introOverlayPngs.push({ pngPath: png, start: ov.start, duration: ov.duration });
    }

    // Optional outro card — SVG → PNG once, looped by FFmpeg.
    let outroPngPath: string | null = null;
    let outroDuration: number | null = null;
    if (scenario.outro) {
      const outroSvg = resolveOutroSvgPath(scenario.outro.svg);
      log.step("Outro", path.relative(process.cwd(), outroSvg));
      outroPngPath = path.join(TMP_DIR, `${baseName}_outro.png`);
      await renderOutroPng(outroSvg, outroPngPath);
      outroDuration = scenario.outro.duration;
      meta.outro = path.relative(process.cwd(), outroSvg);
    }

    try {
      await concatIntroAndBody({
        introPath: introResolvedPath,
        ...(scenario.intro?.duration !== undefined
          ? { introMaxDuration: scenario.intro.duration }
          : {}),
        introOverlays: introOverlayPngs,
        bodyPath: bodyOnlyPath,
        ...(outroPngPath ? { outroPngPath } : {}),
        ...(outroDuration !== null ? { outroDuration } : {}),
        output: videoPath,
        debug: opts.debug,
      });
    } finally {
      for (const o of introOverlayPngs) {
        await removeIfExists(o.pngPath);
        await removeIfExists(o.pngPath.replace(/\.png$/, ".svg"));
      }
      if (outroPngPath) {
        await removeIfExists(outroPngPath);
        await removeIfExists(outroPngPath.replace(/\.png$/, ".svg"));
      }
    }
    if (!opts.keepRaw) {
      await removeIfExists(bodyOnlyPath);
    }
  }

  await writeMetadataJson(metadataPath, meta);
  if (!opts.keepRaw) {
    await removeIfExists(rawRecording);
  }

  log.success(`Done → ${path.relative(process.cwd(), videoPath)}`);
  return { videoPath, metadataPath, meta, skipped: false };
}
