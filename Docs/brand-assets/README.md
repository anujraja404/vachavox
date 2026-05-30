# VachaVox Brand Assets Index

This folder is the canonical home for the final VachaVox 0.3.2 brand asset package generated from the approved source board:

- Source board copy: [`vachavox-brand-assets-final/docs/source-logo-v2-detailed.png`](vachavox-brand-assets-final/docs/source-logo-v2-detailed.png)
- Generated asset folder: [`vachavox-brand-assets-final/`](vachavox-brand-assets-final/)
- Final ZIP package: [`../vachavox-brand-assets-final.zip`](../vachavox-brand-assets-final.zip)

## Important Files

| File | Purpose |
| --- | --- |
| [`vachavox-brand-assets-final/README.md`](vachavox-brand-assets-final/README.md) | Package-level overview, recommended files, and theme usage notes. |
| [`vachavox-brand-assets-final/docs/brand-guidelines.md`](vachavox-brand-assets-final/docs/brand-guidelines.md) | Brand rules for logo anatomy, spacing, minimum sizes, and incorrect usage. |
| [`vachavox-brand-assets-final/docs/logo-usage.md`](vachavox-brand-assets-final/docs/logo-usage.md) | Which logo variant to use for product, app, web, social, and menu bar contexts. |
| [`vachavox-brand-assets-final/docs/color-palette.md`](vachavox-brand-assets-final/docs/color-palette.md) | Sampled colors, HEX/RGB/HSL/CMYK values, and usage notes. |
| [`vachavox-brand-assets-final/docs/source-notes.md`](vachavox-brand-assets-final/docs/source-notes.md) | Source image, reconstruction notes, sampled blue, and known limitations. |
| [`../docs-brand/vachavox-logo-dimensions.md`](../docs-brand/vachavox-logo-dimensions.md) | Repo-level dimensions and app resource specs for the logo set. |

## Product App Assets

Use these files when updating the macOS app bundle:

| File | Purpose |
| --- | --- |
| [`vachavox-brand-assets-final/app-icons/macos/VachaVox.icns`](vachavox-brand-assets-final/app-icons/macos/VachaVox.icns) | macOS app icon source for `CFBundleIconFile`. |
| [`vachavox-brand-assets-final/app-icons/macos/iconset/`](vachavox-brand-assets-final/app-icons/macos/iconset/) | Full macOS iconset used to build the `.icns`. |
| [`vachavox-brand-assets-final/menu-bar-glyphs/black/vachavox-menu-bar-glyph-template-72.png`](vachavox-brand-assets-final/menu-bar-glyphs/black/vachavox-menu-bar-glyph-template-72.png) | Filled-circle template menu bar icon used by the app status item. |
| [`vachavox-brand-assets-final/menu-bar-glyphs/black/vachavox-menu-bar-glyph-circle-template.svg`](vachavox-brand-assets-final/menu-bar-glyphs/black/vachavox-menu-bar-glyph-circle-template.svg) | SVG source for the app's filled-circle menu bar icon. |

Current app resource copies live here:

- [`../../Sources/VachaVox/Resources/VachaVox.icns`](../../Sources/VachaVox/Resources/VachaVox.icns)
- [`../../Sources/VachaVox/Resources/MenuBarIcon.png`](../../Sources/VachaVox/Resources/MenuBarIcon.png)

## Web And Marketing Assets

| Folder | Purpose |
| --- | --- |
| [`vachavox-brand-assets-final/logo/`](vachavox-brand-assets-final/logo/) | Full horizontal logo variants in SVG, PNG, WebP, and PDF. |
| [`vachavox-brand-assets-final/mark/`](vachavox-brand-assets-final/mark/) | Standalone V-shaped waveform mark at small and large sizes. |
| [`vachavox-brand-assets-final/wordmark/`](vachavox-brand-assets-final/wordmark/) | Wordmark-only exports. |
| [`vachavox-brand-assets-final/lockups/`](vachavox-brand-assets-final/lockups/) | Horizontal and icon-plus-wordmark lockups for headers and banners. |
| [`vachavox-brand-assets-final/favicons/`](vachavox-brand-assets-final/favicons/) | Browser favicon, Apple touch icon, Android Chrome icons, and web manifest. |
| [`vachavox-brand-assets-final/social/`](vachavox-brand-assets-final/social/) | Instagram, Facebook, LinkedIn, X/Twitter, and YouTube assets. |
| [`vachavox-brand-assets-final/web/`](vachavox-brand-assets-final/web/) | Header, footer, Open Graph, PWA, and splash assets. |
| [`vachavox-brand-assets-final/templates/`](vachavox-brand-assets-final/templates/) | App splash, email signature, business card, letterhead, and presentation templates. |

## Theme And Regeneration Files

| File | Purpose |
| --- | --- |
| [`vachavox-brand-assets-final/themes/tokens.css`](vachavox-brand-assets-final/themes/tokens.css) | CSS variables for VachaVox colors and logo tokens. |
| [`vachavox-brand-assets-final/themes/theme-light.css`](vachavox-brand-assets-final/themes/theme-light.css) | Light theme token overrides. |
| [`vachavox-brand-assets-final/themes/theme-dark.css`](vachavox-brand-assets-final/themes/theme-dark.css) | Dark theme token overrides. |
| [`vachavox-brand-assets-final/themes/tailwind-theme.js`](vachavox-brand-assets-final/themes/tailwind-theme.js) | Tailwind extension snippet for the brand palette. |
| [`vachavox-brand-assets-final/themes/colors.json`](vachavox-brand-assets-final/themes/colors.json) | Machine-readable color palette metadata. |
| [`vachavox-brand-assets-final/scripts/generate-assets.js`](vachavox-brand-assets-final/scripts/generate-assets.js) | Package-local generator script. |
| [`vachavox-brand-assets-final/scripts/validate-assets.js`](vachavox-brand-assets-final/scripts/validate-assets.js) | Package-local validation script. |

## Verification Commands

Run these from the repository root:

```bash
node Docs/brand-assets/vachavox-brand-assets-final/scripts/validate-assets.js
Scripts/package_app.sh
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' -c 'Print :CFBundleVersion' build/VachaVox.app/Contents/Info.plist
```

Expected app version after packaging: `0.6.0` with build `20`.
