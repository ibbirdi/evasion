const fs = require("fs");
const path = require("path");

// Liste des codes de langues Apple pour ton app (6 langues)
const locales = [
  "fr-FR", // Français
  "en-US", // Anglais (US)
  "es-ES", // Espagnol (Espagne)
  "de-DE", // Allemand
  "it-IT", // Italien
  "pt-BR", // Portugais (Brésil) ou pt-PT
];

locales.forEach((locale) => {
  const dir = path.join(__dirname, "fastlane", "metadata", locale);

  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
    // On crée des fichiers vides pour forcer Fastlane à reconnaître la langue
    [
      "description.txt",
      "keywords.txt",
      "name.txt",
      "subtitle.txt",
      "promotional_text.txt",
    ].forEach((file) => {
      fs.writeFileSync(path.join(dir, file), "");
    });
    console.log(`📁 Dossier créé pour : ${locale}`);
  }
});
