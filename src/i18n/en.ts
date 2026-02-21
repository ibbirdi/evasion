export const en = {
  header: {
    title: "D R I F T" as string,
    timer: "Timer" as string,
  },
  channels: {
    oiseaux: "Birds" as string,
    vent: "Wind" as string,
    plage: "Beach" as string,
    goelands: "Seagulls" as string,
    foret: "Forest" as string,
    pluie: "Rain" as string,
    tonnerre: "Thunder" as string,
    cigales: "Cicadas" as string,
    ville: "City" as string,
  },
  presets: {
    default_calm: "Calm Forest" as string,
    default_storm: "Distant Storm" as string,
  },
  modal: {
    title: "Presets" as string,
    defaultPresets: "Default Presets" as string,
    yourPresets: "Your Presets" as string,
    saveNew: "Save new preset" as string,
    presetName: "Preset name..." as string,
    save: "Save" as string,
    cancel: "Cancel" as string,
    noPresets: "No custom presets yet." as string,
  },
};

export type Translations = typeof en;
