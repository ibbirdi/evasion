import React from "react";
import { SymbolView } from "expo-symbols";

export interface ChannelConfig {
  id: string;
  sources: any[];
  color: string;
  icon: React.ReactNode;
}

const ICON_SIZE = 20;
const ICON_STYLE = { opacity: 1 };

export const AUDIO_CONFIG = {
  oiseaux: {
    id: "oiseaux",
    sources: [require("../../assets/audio/oiseaux1.m4a")],
    color: "hsl(0, 65%, 80%)", // 0 - rouge rosé
    icon: (
      <SymbolView
        name="bird.fill"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  vent: {
    id: "vent",
    sources: [require("../../assets/audio/vent1.m4a")],
    color: "hsl(26, 65%, 80%)", // 1 - orange
    icon: (
      <SymbolView
        name="wind"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  plage: {
    id: "plage",
    sources: [require("../../assets/audio/plage1.m4a")],
    color: "hsl(51, 65%, 80%)", // 2 - jaune
    icon: (
      <SymbolView
        name="water.waves"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  goelands: {
    id: "goelands",
    sources: [require("../../assets/audio/goelants1.m4a")],
    color: "hsl(77, 65%, 80%)", // 3 - jaune-vert
    icon: (
      <SymbolView
        name="bird"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  foret: {
    id: "foret",
    sources: [require("../../assets/audio/foret1.m4a")],
    color: "hsl(103, 65%, 80%)", // 4 - vert
    icon: (
      <SymbolView
        name="tree.fill"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  pluie: {
    id: "pluie",
    sources: [require("../../assets/audio/pluie1.m4a")],
    color: "hsl(129, 65%, 80%)", // 5 - vert menthe
    icon: (
      <SymbolView
        name="cloud.rain.fill"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  tonnerre: {
    id: "tonnerre",
    sources: [require("../../assets/audio/orage1.m4a")],
    color: "hsl(154, 65%, 80%)", // 6 - turquoise
    icon: (
      <SymbolView
        name="cloud.bolt.fill"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  cigales: {
    id: "cigales",
    sources: [require("../../assets/audio/cigales1.m4a")],
    color: "hsl(180, 65%, 80%)", // 7 - cyan
    icon: (
      <SymbolView
        name="ladybug.fill"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  grillons: {
    id: "grillons",
    sources: [require("../../assets/audio/grillons1.m4a")],
    color: "hsl(206, 65%, 80%)", // 8 - bleu ciel
    icon: (
      <SymbolView
        name="moon.stars"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  tente: {
    id: "tente",
    sources: [require("../../assets/audio/tente1.m4a")],
    color: "hsl(231, 65%, 80%)", // 9 - bleu indigo
    icon: (
      <SymbolView
        name="tent.fill"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  riviere: {
    id: "riviere",
    sources: [require("../../assets/audio/riviere1.m4a")],
    color: "hsl(257, 65%, 80%)", // 10 - violet
    icon: (
      <SymbolView
        name="drop.fill"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  village: {
    id: "village",
    sources: [require("../../assets/audio/ville1.m4a")],
    color: "hsl(283, 65%, 80%)", // 11 - mauve
    icon: (
      <SymbolView
        name="house.fill"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  voiture: {
    id: "voiture",
    sources: [require("../../assets/audio/voiture1.m4a")],
    color: "hsl(309, 65%, 80%)", // 14 - magenta
    icon: (
      <SymbolView
        name="car.fill"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
  train: {
    id: "train",
    sources: [require("../../assets/audio/train1.m4a")],
    color: "hsl(334, 65%, 80%)", // 13 - rose
    icon: (
      <SymbolView
        name="tram.fill"
        size={ICON_SIZE}
        tintColor="#FFF"
        style={ICON_STYLE}
      />
    ),
  },
} satisfies Record<string, ChannelConfig>;

export type ChannelId = keyof typeof AUDIO_CONFIG;
