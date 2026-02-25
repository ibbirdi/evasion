import { create } from "zustand";

interface LiveState {
  // Volume variations for each channel [0.0 to 1.0 or null]
  variations: Record<string, number | null>;
  setVariation: (id: string, value: number | null) => void;
}

export const useLiveStore = create<LiveState>((set) => ({
  variations: {},
  setVariation: (id, value) =>
    set((state) => ({
      variations: {
        ...state.variations,
        [id]: value,
      },
    })),
}));
