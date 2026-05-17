import { execa, type ResultPromise } from "execa";

import { FactoryError, log } from "../logger.js";

export interface DeviceInfo {
  udid: string;
  name: string;
  state: "Booted" | "Shutdown" | string;
  runtime: string;
}

interface SimctlDevices {
  devices: Record<string, Array<{ udid: string; name: string; state: string; isAvailable?: boolean }>>;
}

export async function findDevice(name: string): Promise<DeviceInfo> {
  const { stdout } = await execa("xcrun", ["simctl", "list", "-j", "devices", "available"]);
  const parsed = JSON.parse(stdout) as SimctlDevices;
  const matches: DeviceInfo[] = [];
  for (const [runtime, devs] of Object.entries(parsed.devices)) {
    for (const d of devs) {
      if (d.isAvailable === false) continue;
      if (d.name === name) {
        matches.push({ udid: d.udid, name: d.name, state: d.state, runtime });
      }
    }
  }
  if (matches.length === 0) {
    throw new FactoryError(
      `Simulator "${name}" not found.`,
      `List with: xcrun simctl list devices available | grep -i "${name}"`,
    );
  }
  // Prefer an already-booted match; else pick the most recent runtime.
  const booted = matches.find((m) => m.state === "Booted");
  if (booted) return booted;
  matches.sort((a, b) => b.runtime.localeCompare(a.runtime));
  return matches[0]!;
}

export async function bootDevice(device: DeviceInfo): Promise<void> {
  if (device.state === "Booted") {
    log.debug(`Simulator "${device.name}" already booted (${device.udid}).`);
    return;
  }
  log.info(`Booting simulator "${device.name}"…`);
  await execa("xcrun", ["simctl", "boot", device.udid]);
  // Wait until home screen is reachable. Polling `bootstatus` is the canonical way.
  await execa("xcrun", ["simctl", "bootstatus", device.udid, "-b"]);
  // Bring Simulator.app forward so the recording captures it.
  await execa("open", ["-a", "Simulator"]);
}

export interface VideoRecorder {
  outputPath: string;
  stop: () => Promise<void>;
  process: ResultPromise;
}

export function startVideoRecording(
  device: DeviceInfo,
  outputPath: string,
): VideoRecorder {
  log.debug(`Starting recordVideo → ${outputPath}`);
  // simctl writes a clean H.264 mp4. `--codec=h264 --force` ensures overwrite.
  const proc = execa("xcrun", [
    "simctl",
    "io",
    device.udid,
    "recordVideo",
    "--codec=h264",
    "--force",
    outputPath,
  ]);
  let stopped = false;
  return {
    outputPath,
    process: proc,
    stop: async () => {
      if (stopped) return;
      stopped = true;
      // SIGINT flushes the file properly. SIGTERM/SIGKILL produce truncated files.
      proc.kill("SIGINT");
      try {
        await proc;
      } catch (err: unknown) {
        // SIGINT exit code is non-zero but expected.
        const e = err as { exitCode?: number; signal?: string; isCanceled?: boolean };
        if (e.signal !== "SIGINT" && e.isCanceled !== true) {
          log.debug(`recordVideo exited: code=${e.exitCode} signal=${e.signal}`);
        }
      }
    },
  };
}

export async function getDeviceScreenSize(device: DeviceInfo): Promise<{
  width: number;
  height: number;
}> {
  // Width/height inferred from name. Hardcoded lookup avoids parsing simctl
  // device-type plist. Extend as needed.
  const known: Record<string, { width: number; height: number }> = {
    "iPhone 17 Pro Max": { width: 1290, height: 2796 },
    "iPhone 16 Pro Max": { width: 1320, height: 2868 },
    "iPhone 15 Pro Max": { width: 1290, height: 2796 },
    "iPhone 14 Pro Max": { width: 1290, height: 2796 },
  };
  const size = known[device.name];
  if (!size) {
    throw new FactoryError(
      `Unknown device screen size for "${device.name}".`,
      `Add the width/height to src/sim/simulator.ts → getDeviceScreenSize().`,
    );
  }
  return size;
}
