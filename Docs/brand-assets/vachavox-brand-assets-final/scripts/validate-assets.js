#!/usr/bin/env node

const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

const PACKAGE_NAME = "vachavox-brand-assets-final";
const SCRIPT_DIR = __dirname;
const POSSIBLE_PACKAGE_ROOT = path.resolve(SCRIPT_DIR, "..");
const RUNNING_IN_PACKAGE = path.basename(POSSIBLE_PACKAGE_ROOT) === PACKAGE_NAME;
const REPO_ROOT = RUNNING_IN_PACKAGE ? path.resolve(POSSIBLE_PACKAGE_ROOT, "../../..") : path.resolve(SCRIPT_DIR, "..");
const OUTPUT_ROOT = RUNNING_IN_PACKAGE ? POSSIBLE_PACKAGE_ROOT : path.join(REPO_ROOT, "Docs", "brand-assets", PACKAGE_NAME);
const ZIP_PATH = RUNNING_IN_PACKAGE
  ? path.join(POSSIBLE_PACKAGE_ROOT, "..", "..", "vachavox-brand-assets-final.zip")
  : path.join(REPO_ROOT, "Docs", "vachavox-brand-assets-final.zip");

const REQUIRED_DIRS = [
  "docs",
  "logo/svg",
  "logo/png",
  "logo/webp",
  "logo/pdf",
  "logo/full-color",
  "logo/black",
  "logo/white",
  "logo/grayscale",
  "logo/light-theme",
  "logo/dark-theme",
  "mark/svg",
  "mark/png",
  "mark/webp",
  "mark/light-theme",
  "mark/dark-theme",
  "wordmark/svg",
  "wordmark/png",
  "wordmark/webp",
  "wordmark/light-theme",
  "wordmark/dark-theme",
  "lockups/horizontal",
  "lockups/icon-plus-wordmark",
  "lockups/light-theme",
  "lockups/dark-theme",
  "app-icons/macos",
  "app-icons/macos/iconset",
  "app-icons/ios",
  "app-icons/android",
  "app-icons/pwa",
  "favicons",
  "menu-bar-glyphs/black",
  "menu-bar-glyphs/white",
  "social/instagram",
  "social/facebook",
  "social/linkedin",
  "social/x-twitter",
  "social/youtube",
  "web/header",
  "web/footer",
  "web/open-graph",
  "web/pwa",
  "web/splash",
  "templates/app-splash",
  "templates/email-signature",
  "templates/business-card",
  "templates/letterhead",
  "templates/presentation",
  "themes",
  "scripts",
];

const REQUIRED_FILES = [
  "README.md",
  "docs/brand-guidelines.md",
  "docs/logo-usage.md",
  "docs/color-palette.md",
  "docs/typography.md",
  "docs/source-notes.md",
  "logo/svg/vachavox-logo-full-color.svg",
  "logo/png/vachavox-logo-full-color-1024.png",
  "logo/webp/vachavox-logo-full-color-1024.webp",
  "logo/pdf/vachavox-logo-full-color.pdf",
  "mark/svg/vachavox-mark-full-color.svg",
  "mark/png/vachavox-mark-full-color-1024.png",
  "mark/webp/vachavox-mark-full-color-1024.webp",
  "wordmark/svg/vachavox-wordmark-full-color.svg",
  "wordmark/png/vachavox-wordmark-full-color-1024.png",
  "wordmark/webp/vachavox-wordmark-full-color-1024.webp",
  "app-icons/macos/VachaVox.icns",
  "favicons/favicon.ico",
  "favicons/site.webmanifest",
  "themes/tokens.css",
  "themes/theme-light.css",
  "themes/theme-dark.css",
  "themes/tailwind-theme.js",
  "themes/colors.json",
  "scripts/generate-assets.js",
  "scripts/validate-assets.js",
];

const DIMENSION_CHECKS = [
  ["favicons/favicon-16x16.png", 16, 16],
  ["favicons/favicon-32x32.png", 32, 32],
  ["favicons/favicon-48x48.png", 48, 48],
  ["favicons/apple-touch-icon.png", 180, 180],
  ["favicons/android-chrome-192x192.png", 192, 192],
  ["favicons/android-chrome-512x512.png", 512, 512],
  ["app-icons/macos/iconset/icon_16x16.png", 16, 16],
  ["app-icons/macos/iconset/icon_16x16@2x.png", 32, 32],
  ["app-icons/macos/iconset/icon_32x32.png", 32, 32],
  ["app-icons/macos/iconset/icon_32x32@2x.png", 64, 64],
  ["app-icons/macos/iconset/icon_128x128.png", 128, 128],
  ["app-icons/macos/iconset/icon_128x128@2x.png", 256, 256],
  ["app-icons/macos/iconset/icon_256x256.png", 256, 256],
  ["app-icons/macos/iconset/icon_256x256@2x.png", 512, 512],
  ["app-icons/macos/iconset/icon_512x512.png", 512, 512],
  ["app-icons/macos/iconset/icon_512x512@2x.png", 1024, 1024],
  ["menu-bar-glyphs/black/vachavox-menu-bar-glyph-black-18.png", 18, 18],
  ["menu-bar-glyphs/black/vachavox-menu-bar-glyph-black-22.png", 22, 22],
  ["menu-bar-glyphs/black/vachavox-menu-bar-glyph-black-36.png", 36, 36],
  ["menu-bar-glyphs/black/vachavox-menu-bar-glyph-black-44.png", 44, 44],
  ["menu-bar-glyphs/white/vachavox-menu-bar-glyph-white-18.png", 18, 18],
  ["menu-bar-glyphs/white/vachavox-menu-bar-glyph-white-22.png", 22, 22],
  ["menu-bar-glyphs/white/vachavox-menu-bar-glyph-white-36.png", 36, 36],
  ["menu-bar-glyphs/white/vachavox-menu-bar-glyph-white-44.png", 44, 44],
  ["social/instagram/vachavox-instagram-profile-light.png", 320, 320],
  ["social/instagram/vachavox-instagram-post-light.png", 1080, 1080],
  ["social/instagram/vachavox-instagram-story-light.png", 1080, 1920],
  ["social/facebook/vachavox-facebook-profile-light.png", 320, 320],
  ["social/facebook/vachavox-facebook-cover-light.png", 1640, 624],
  ["social/linkedin/vachavox-linkedin-company-logo-light.png", 300, 300],
  ["social/linkedin/vachavox-linkedin-banner-light.png", 1128, 191],
  ["social/x-twitter/vachavox-x-profile-light.png", 400, 400],
  ["social/x-twitter/vachavox-x-header-light.png", 1500, 500],
  ["social/youtube/vachavox-youtube-profile-light.png", 800, 800],
  ["social/youtube/vachavox-youtube-banner-light.png", 2560, 1440],
  ["web/open-graph/vachavox-open-graph.png", 1200, 630],
];

function ensureSharp() {
  try {
    return require("sharp");
  } catch (_) {
    const toolsDir = path.join(os.tmpdir(), "vachavox-brand-asset-tools");
    fs.mkdirSync(toolsDir, { recursive: true });
    const pkgPath = path.join(toolsDir, "package.json");
    if (!fs.existsSync(pkgPath)) {
      fs.writeFileSync(
        pkgPath,
        JSON.stringify(
          {
            private: true,
            type: "commonjs",
            dependencies: { sharp: "0.34.5" },
          },
          null,
          2
        )
      );
    }
    execFileSync("npm", ["install", "--prefix", toolsDir, "--silent"], { stdio: "inherit" });
    return require(path.join(toolsDir, "node_modules", "sharp"));
  }
}

const sharp = ensureSharp();

function fail(message, failures) {
  failures.push(message);
}

function countFiles(dir) {
  let total = 0;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === ".DS_Store") continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) total += countFiles(full);
    else total += 1;
  }
  return total;
}

async function checkDimensions(relPath, expectedWidth, expectedHeight, failures) {
  const file = path.join(OUTPUT_ROOT, relPath);
  if (!fs.existsSync(file)) {
    fail(`Missing dimension target: ${relPath}`, failures);
    return;
  }
  const meta = await sharp(file).metadata();
  if (meta.width !== expectedWidth || meta.height !== expectedHeight) {
    fail(`${relPath} expected ${expectedWidth}x${expectedHeight}, got ${meta.width}x${meta.height}`, failures);
  }
}

async function main() {
  const failures = [];
  if (!fs.existsSync(OUTPUT_ROOT)) fail(`Missing output root: ${OUTPUT_ROOT}`, failures);
  if (!fs.existsSync(ZIP_PATH)) fail(`Missing ZIP: ${ZIP_PATH}`, failures);

  for (const dir of REQUIRED_DIRS) {
    const full = path.join(OUTPUT_ROOT, dir);
    if (!fs.existsSync(full) || !fs.statSync(full).isDirectory()) {
      fail(`Missing required folder: ${dir}`, failures);
      continue;
    }
    const nonHidden = fs.readdirSync(full).filter((item) => !item.startsWith("."));
    if (!nonHidden.length) fail(`Required folder is empty: ${dir}`, failures);
  }

  for (const file of REQUIRED_FILES) {
    const full = path.join(OUTPUT_ROOT, file);
    if (!fs.existsSync(full) || !fs.statSync(full).isFile()) {
      fail(`Missing required file: ${file}`, failures);
    }
  }

  for (const [file, width, height] of DIMENSION_CHECKS) {
    await checkDimensions(file, width, height, failures);
  }

  for (const size of [16, 18, 22, 32, 36, 44, 64, 128, 256, 512, 1024]) {
    await checkDimensions(`mark/png/vachavox-mark-full-color-${size}.png`, size, size, failures);
    await checkDimensions(`mark/webp/vachavox-mark-full-color-${size}.webp`, size, size, failures);
  }

  for (const width of [256, 512, 1024, 1920]) {
    const meta = await sharp(path.join(OUTPUT_ROOT, `logo/png/vachavox-logo-full-color-${width}.png`)).metadata();
    if (meta.width !== width) fail(`Logo width mismatch for ${width}: got ${meta.width}`, failures);
  }

  if (failures.length) {
    console.error("Asset validation failed:");
    for (const item of failures) console.error(`- ${item}`);
    process.exit(1);
  }

  const fileCount = countFiles(OUTPUT_ROOT);
  console.log(`Asset validation passed. Files: ${fileCount}`);
  console.log(`Folder: ${OUTPUT_ROOT}`);
  console.log(`ZIP: ${ZIP_PATH}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
