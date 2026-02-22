/**
 * Configuration for Zen Mode (Auto-hide UI)
 */
export const ZEN_CONFIG = {
  /** Delay in milliseconds of inactivity before Zen Mode activates */
  INACTIVITY_DELAY: 500,

  /** Duration in milliseconds for the UI to fade out into Zen Mode */
  FADE_OUT_DURATION: 2000,

  /** Duration in milliseconds for the UI to fade back in when user interacts */
  FADE_IN_DURATION: 300,

  /** Opacity level of UI elements in Zen Mode */
  ZEN_OPACITY: 0.05,

  /** Standard opacity level for active UI elements */
  NORMAL_OPACITY: 1,

  /** Opacity level for inactive/muted UI elements outside Zen Mode */
  INACTIVE_OPACITY: 0.4,
};
