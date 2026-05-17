# Fonts

Drop .ttf or .otf files here to use custom typography in text overlays.

The renderer looks for, in order:
- `regular.ttf` / `regular.otf` — body weight
- `bold.ttf` / `bold.otf` — display weight

If neither is present, overlays fall back to the system sans-serif family
(`Helvetica Neue, Helvetica, Arial, sans-serif`), resolved by librsvg via
the macOS font book.

Recommended free fonts that match Oasis voice (calm, premium):
- Inter (https://rsms.me/inter/)
- Manrope (https://manropefont.com/)
- IBM Plex Sans

Drop them here, rename to `regular.ttf` and `bold.ttf`, and the renderer
will pick them up automatically.
