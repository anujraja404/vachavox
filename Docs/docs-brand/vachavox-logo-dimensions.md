# VachaVox Logo Dimensions

Source of truth: `Docs/brand-assets/vachavox-brand-assets-final/docs/source-logo-v2-detailed.png`, copied from the approved VachaVox logo board.

## Source Board

| File | Dimensions | Color | DPI |
| --- | ---: | --- | ---: |
| `source-logo-v2-detailed.png` | 1448 x 1086 px | RGB PNG | 72 |

## Generated Masters

| Asset | Master ViewBox | Export Sizes |
| --- | ---: | --- |
| Horizontal logo | 1080 x 270 | 256, 512, 1024, 1920 px wide |
| Standalone mark | 256 x 256 | 16, 18, 22, 32, 36, 44, 64, 128, 256, 512, 1024 px square |
| Wordmark | 760 x 180 | 256, 512, 1024, 1920 px wide |
| macOS app icon | 1024 x 1024 | 16, 32, 64, 128, 256, 512, 1024 px square |
| Menu bar glyph | 64 x 64 | 18, 22, 36, 44 px square; 72 px template resource |

## App Resource Targets

| Repo File | Purpose | Dimensions |
| --- | --- | ---: |
| `Sources/VachaVox/Resources/VachaVox.icns` | Packaged macOS app icon | iconset through 1024 px |
| `Sources/VachaVox/Resources/MenuBarIcon.png` | macOS status item template glyph | 72 x 72 px |
| `Docs/docs-brand/VachaVox_logo_transparent.png` | Transparent horizontal logo preview | 1024 px wide |
| `Docs/docs-brand/vvox_logo_icon.png` | Final app icon preview | 1024 x 1024 px |

## Spacing Rules

- Keep at least one outer waveform bar height of clear space around the horizontal logo.
- Keep at least 16% of the standalone mark width as padding when placing it inside square icons.
- Center the waveform optically inside app icons and framed lockups so top/bottom and left/right whitespace read as uniform.
- Use the full-color logo on light surfaces and the dark-theme logo on dark surfaces.
- Keep the sampled blue accent fixed at the generated palette value from the source board.
