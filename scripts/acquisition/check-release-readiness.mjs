#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { spawnSync } from "node:child_process";

const REPO_ROOT = path.resolve(new URL("../..", import.meta.url).pathname);
const DEFAULT_PROJECT = "ios-native/OasisNative.xcodeproj";
const DEFAULT_FASTLANE_LOG = "fastlane/buildlogs/Oasis-OasisNative.log";
const DEFAULT_OUT = "scripts/acquisition/release-readiness.md";
const DEFAULT_JSON_OUT = "scripts/acquisition/release-readiness.json";

function parseArgs(argv) {
  const args = {
    project: DEFAULT_PROJECT,
    fastlaneLog: DEFAULT_FASTLANE_LOG,
    archive: "",
    out: DEFAULT_OUT,
    jsonOut: DEFAULT_JSON_OUT,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--project") {
      args.project = next;
      i += 1;
    } else if (arg === "--fastlane-log") {
      args.fastlaneLog = next;
      i += 1;
    } else if (arg === "--archive") {
      args.archive = next;
      i += 1;
    } else if (arg === "--out") {
      args.out = next;
      i += 1;
    } else if (arg === "--json-out") {
      args.jsonOut = next;
      i += 1;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return args;
}

function printHelp() {
  console.log(`Oasis release readiness check

Usage:
  node scripts/acquisition/check-release-readiness.mjs
  node scripts/acquisition/check-release-readiness.mjs --archive ~/Library/Developer/Xcode/Archives/.../OasisNative.xcarchive

Options:
  --project <path>       Xcode project. Default: ${DEFAULT_PROJECT}
  --fastlane-log <path>  Last Fastlane archive log. Default: ${DEFAULT_FASTLANE_LOG}
  --archive <path>       Explicit .xcarchive to inspect. Default: latest OasisNative archive
  --out <path>           Markdown output. Default: ${DEFAULT_OUT}
  --json-out <path>      JSON output. Default: ${DEFAULT_JSON_OUT}
`);
}

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: REPO_ROOT,
    encoding: "utf8",
    maxBuffer: 10 * 1024 * 1024,
  });
  return {
    status: result.status,
    stdout: result.stdout || "",
    stderr: result.stderr || "",
    error: result.error?.message || "",
  };
}

async function readIfExists(filePath) {
  try {
    return await fs.readFile(filePath, "utf8");
  } catch (error) {
    if (error.code === "ENOENT") return "";
    throw error;
  }
}

async function pathExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

function redactIdentities(output) {
  return output.replace(/[A-F0-9]{40}/g, "<sha1-redacted>");
}

async function latestArchive() {
  const archivesRoot = path.join(process.env.HOME || "", "Library/Developer/Xcode/Archives");
  const dateDirs = await fs.readdir(archivesRoot, { withFileTypes: true }).catch(() => []);
  const archives = [];
  for (const dateDir of dateDirs) {
    if (!dateDir.isDirectory()) continue;
    const dirPath = path.join(archivesRoot, dateDir.name);
    const entries = await fs.readdir(dirPath, { withFileTypes: true }).catch(() => []);
    for (const entry of entries) {
      if (entry.isDirectory() && entry.name.startsWith("OasisNative") && entry.name.endsWith(".xcarchive")) {
        const archivePath = path.join(dirPath, entry.name);
        const stat = await fs.stat(archivePath);
        archives.push({ archivePath, mtimeMs: stat.mtimeMs });
      }
    }
  }
  archives.sort((a, b) => b.mtimeMs - a.mtimeMs);
  return archives[0]?.archivePath || "";
}

async function projectVersions(projectPath) {
  if (projectPath.endsWith(".xcodeproj")) {
    const result = run("xcodebuild", [
      "-project",
      projectPath,
      "-scheme",
      "OasisNative",
      "-configuration",
      "Release",
      "-showBuildSettings",
    ]);
    if (result.status === 0) {
      return {
        marketingVersion: result.stdout.match(/MARKETING_VERSION = (.+)/)?.[1]?.trim() || "",
        buildNumber: result.stdout.match(/CURRENT_PROJECT_VERSION = (.+)/)?.[1]?.trim() || "",
        iOSDeploymentTarget: result.stdout.match(/IPHONEOS_DEPLOYMENT_TARGET = (.+)/)?.[1]?.trim() || "",
        bundleId: result.stdout.match(/PRODUCT_BUNDLE_IDENTIFIER = (.+)/)?.[1]?.trim() || "",
      };
    }
  }

  const raw = await readIfExists(projectPath.endsWith(".xcodeproj") ? path.join(projectPath, "project.pbxproj") : projectPath);
  const marketingVersions = [...raw.matchAll(/MARKETING_VERSION = ([^;]+);/g)].map((match) => match[1]);
  const buildNumbers = [...raw.matchAll(/CURRENT_PROJECT_VERSION = ([^;]+);/g)].map((match) => match[1]);
  const deploymentTargets = [...raw.matchAll(/IPHONEOS_DEPLOYMENT_TARGET = ([^;]+);/g)].map((match) => match[1]);
  return {
    marketingVersion: mostCommon(marketingVersions),
    buildNumber: mostCommon(buildNumbers),
    iOSDeploymentTarget: mostCommon(deploymentTargets),
  };
}

function mostCommon(values) {
  const counts = new Map();
  for (const value of values) counts.set(value, (counts.get(value) || 0) + 1);
  return [...counts.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] || "";
}

function parseArchiveInfo(raw) {
  const get = (key) => raw.match(new RegExp(`"${key}" => "([^"]+)"`))?.[1] || "";
  return {
    bundleId: get("CFBundleIdentifier"),
    marketingVersion: get("CFBundleShortVersionString"),
    buildNumber: get("CFBundleVersion"),
    signingIdentity: get("SigningIdentity"),
    team: get("Team"),
    name: get("Name"),
    scheme: get("SchemeName"),
  };
}

async function archiveInfo(archivePath) {
  if (!archivePath || !(await pathExists(archivePath))) return { exists: false, archivePath, info: {} };
  const infoPath = path.join(archivePath, "Info.plist");
  const result = run("plutil", ["-p", infoPath]);
  return {
    exists: result.status === 0,
    archivePath,
    info: result.status === 0 ? parseArchiveInfo(result.stdout) : {},
    error: result.status === 0 ? "" : (result.stderr || result.stdout || result.error).trim(),
  };
}

function signingStatus() {
  const result = run("security", ["find-identity", "-p", "codesigning", "-v"]);
  const output = redactIdentities([result.stdout, result.stderr].filter(Boolean).join("\n"));
  const hasAppleDevelopment = /Apple Development:/u.test(output);
  const hasDistribution = /(Apple Distribution:|iOS Distribution:)/u.test(output);
  return {
    status: result.status,
    hasAppleDevelopment,
    hasDistribution,
    output: output.trim(),
  };
}

async function fastlaneStatus(logPath) {
  const raw = await readIfExists(logPath);
  return {
    logPath,
    exists: raw.length > 0,
    archiveSucceeded: /\*\* ARCHIVE SUCCEEDED \*\*/u.test(raw),
    missingDistributionCert: /No signing certificate "iOS Distribution" found/u.test(raw),
    invalidXcodeCredentials: /missing Xcode-(Username|Token)/u.test(raw),
    appSpecificPasswordRequired: /app-specific password/u.test(raw),
  };
}

function verdict(check) {
  if (!check.archive.exists) return "blocked";
  if (!check.signing.hasDistribution) return "blocked";
  if (check.archive.info.signingIdentity && /Apple Development:/u.test(check.archive.info.signingIdentity)) return "blocked";
  if (check.fastlane.invalidXcodeCredentials || check.fastlane.appSpecificPasswordRequired) return "blocked";
  return "ready";
}

function renderMarkdown(check) {
  const status = verdict(check);
  const lines = [
    "# Oasis Release Readiness",
    "",
    `Generated: ${check.generatedAt}`,
    `Verdict: ${status}`,
    "",
    "## Version",
    "",
    `- Project marketing version: ${check.project.marketingVersion || "unknown"}`,
    `- Project build number: ${check.project.buildNumber || "unknown"}`,
    `- iOS deployment target: ${check.project.iOSDeploymentTarget || "unknown"}`,
    "",
    "## Archive",
    "",
    `- Archive path: ${check.archive.archivePath || "not found"}`,
    `- Archive exists: ${check.archive.exists ? "yes" : "no"}`,
    `- Archive version/build: ${check.archive.info.marketingVersion || "unknown"} (${check.archive.info.buildNumber || "unknown"})`,
    `- Bundle ID: ${check.archive.info.bundleId || "unknown"}`,
    `- Signing identity: ${check.archive.info.signingIdentity || "unknown"}`,
    `- Team: ${check.archive.info.team || "unknown"}`,
    "",
    "## Signing",
    "",
    `- Apple Development identity installed: ${check.signing.hasAppleDevelopment ? "yes" : "no"}`,
    `- Apple/iOS Distribution identity installed: ${check.signing.hasDistribution ? "yes" : "no"}`,
    "",
    "## Fastlane",
    "",
    `- Log path: ${check.fastlane.logPath}`,
    `- Archive succeeded in last log: ${check.fastlane.archiveSucceeded ? "yes" : "no"}`,
    `- Missing distribution certificate: ${check.fastlane.missingDistributionCert ? "yes" : "no"}`,
    `- Invalid Xcode keychain credentials: ${check.fastlane.invalidXcodeCredentials ? "yes" : "no"}`,
    `- App-specific password required: ${check.fastlane.appSpecificPasswordRequired ? "yes" : "no"}`,
    "",
    "## Next Actions",
    "",
  ];

  if (status === "ready") {
    lines.push("- Rerun `bundle exec fastlane build_and_upload ipa_name:OasisNative-1.5.1-b7.ipa`.");
  } else {
    if (!check.signing.hasDistribution) {
      lines.push("- Install or refresh the App Store distribution certificate/profile for team `346GF2QVCC` in Xcode.");
    }
    if (/Apple Development:/u.test(check.archive.info.signingIdentity || "")) {
      lines.push("- Re-export or re-archive with an Apple/iOS Distribution signing identity; the current archive is signed with Apple Development.");
    }
    if (check.fastlane.invalidXcodeCredentials) {
      lines.push("- Open Xcode Settings > Accounts, refresh `jonathanluquet@me.com`, and make sure the account has a valid Xcode token.");
    }
    if (check.fastlane.appSpecificPasswordRequired) {
      lines.push("- Create an app-specific password at `account.apple.com` and provide it to Fastlane when prompted.");
    }
    lines.push("- After fixing signing/auth, rerun this preflight before upload.");
  }

  return `${lines.join("\n").trim()}\n`;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const archivePath = args.archive ? path.resolve(args.archive.replace(/^~/u, process.env.HOME || "")) : await latestArchive();
  const check = {
    generatedAt: new Date().toISOString(),
    project: await projectVersions(path.resolve(REPO_ROOT, args.project)),
    archive: await archiveInfo(archivePath),
    signing: signingStatus(),
    fastlane: await fastlaneStatus(path.resolve(REPO_ROOT, args.fastlaneLog)),
  };
  check.verdict = verdict(check);

  const markdown = renderMarkdown(check);
  const outPath = path.resolve(REPO_ROOT, args.out);
  const jsonPath = path.resolve(REPO_ROOT, args.jsonOut);
  await fs.mkdir(path.dirname(outPath), { recursive: true });
  await fs.mkdir(path.dirname(jsonPath), { recursive: true });
  await fs.writeFile(outPath, markdown);
  await fs.writeFile(jsonPath, `${JSON.stringify(check, null, 2)}\n`);
  console.log(`Wrote ${outPath}`);
  console.log(`Wrote ${jsonPath}`);
  console.log(`Verdict: ${check.verdict}`);
}

main().catch((error) => {
  console.error(error.stack || error.message);
  process.exit(1);
});
