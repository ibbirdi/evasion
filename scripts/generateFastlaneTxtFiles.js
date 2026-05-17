const fs = require("fs");
const path = require("path");

const locales = ["en-US", "fr-FR", "de-DE", "es-ES", "it", "pt-BR"];
const fields = [
  "name",
  "subtitle",
  "promotional_text",
  "keywords",
  "release_notes",
  "description",
];

const canonicalRoot = path.join(__dirname, "..", "fastlane", "metadata");
const outputRoots = [
  canonicalRoot,
  path.join(__dirname, "fastlane", "metadata"),
];

for (const locale of locales) {
  const sourceDir = path.join(canonicalRoot, locale);
  const values = Object.fromEntries(
    fields.map((field) => {
      const sourcePath = path.join(sourceDir, `${field}.txt`);
      return [field, fs.readFileSync(sourcePath, "utf8").trimEnd()];
    })
  );

  for (const root of outputRoots) {
    const dir = path.join(root, locale);
    fs.mkdirSync(dir, { recursive: true });

    for (const [field, value] of Object.entries(values)) {
      fs.writeFileSync(path.join(dir, `${field}.txt`), `${value}\n`);
    }
  }

  console.log(`Synced Fastlane metadata for ${locale}`);
}
