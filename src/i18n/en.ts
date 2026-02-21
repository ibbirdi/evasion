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
    grillons: "Crickets" as string,
    ville: "City" as string,
    voiture: "Car Ride" as string,
    train: "Train" as string,
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
  paywall: {
    title: "Unlock the Full Experience" as string,
    benefit_1: "Unlimited access to all 12 premium sounds" as string,
    benefit_2: "Sleep and focus timer" as string,
    benefit_3: "Save your custom mixes" as string,
    benefit_4: "Exclusive high-fidelity mixing" as string,
    no_sub: "Pay once. Yours forever. No subscriptions." as string,
    cta: "Unlock Lifetime - " as string,
    restore: "Restore Purchases" as string,
    terms: "Terms of Use" as string,
  },
};

export type Translations = typeof en;
