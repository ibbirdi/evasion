import { ChannelId } from "../types/mixer";

// HSL gradient: S=55%, L=83%, hue step=30° (0°→330°)
export const CHANNEL_COLORS: Record<ChannelId, string> = {
  oiseaux: "#ECBCBC", // H=0°   Pastel Coral
  vent: "#ECD4BC", //    H=30°  Pastel Peach
  plage: "#ECECBC", //   H=60°  Pastel Sand
  goelands: "#D4ECBC", // H=90°  Pastel Lime
  foret: "#BCECBC", //   H=120° Pastel Green
  pluie: "#BCECD4", //   H=150° Pastel Mint
  tonnerre: "#BCECEC", // H=180° Pastel Cyan
  cigales: "#BCD4EC", // H=210° Pastel Sky
  grillons: "#BCBCEC", // H=240° Pastel Periwinkle
  ville: "#D4BCEC", //   H=270° Pastel Lavender
  voiture: "#ECBCEC", // H=300° Pastel Orchid
  train: "#ECBCD4", //   H=330° Pastel Rose
};
