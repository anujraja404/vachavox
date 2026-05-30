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
const ZIP_PATH = path.join(REPO_ROOT, "Docs", "vachavox-brand-assets-final.zip");
const APP_RESOURCE_DIR = path.join(REPO_ROOT, "Sources", "VachaVox", "Resources");
const DOCS_BRAND_DIR = path.join(REPO_ROOT, "Docs", "docs-brand");
const REPO_SOURCE_IMAGE = path.join(REPO_ROOT, "from-chatgpt", "logo-v2-detailed.png");
const PACKAGE_SOURCE_IMAGE = path.join(OUTPUT_ROOT, "docs", "source-logo-v2-detailed.png");
const SOURCE_IMAGE = fs.existsSync(REPO_SOURCE_IMAGE) ? REPO_SOURCE_IMAGE : PACKAGE_SOURCE_IMAGE;
const SOURCE_IMAGE_BUFFER = fs.existsSync(SOURCE_IMAGE) ? fs.readFileSync(SOURCE_IMAGE) : null;
const SELF_SOURCE = fs.readFileSync(__filename, "utf8");
const VALIDATOR_SOURCE = (() => {
  const repoValidator = path.join(REPO_ROOT, "Scripts", "validate_vachavox_brand_assets.js");
  const packageValidator = path.join(SCRIPT_DIR, "validate-assets.js");
  if (fs.existsSync(repoValidator)) return fs.readFileSync(repoValidator, "utf8");
  if (fs.existsSync(packageValidator)) return fs.readFileSync(packageValidator, "utf8");
  return null;
})();

const BRAND = {
  name: "VachaVox",
  accentFallback: "#2388FD",
  darkText: "#111820",
  mutedText: "#59616D",
  lightText: "#F8FAFC",
  lightBg: "#FFFFFF",
  lightSurface: "#F6F8FB",
  darkBg: "#111820",
  darkSurface: "#1B242E",
  borderLight: "#D9DEE6",
  borderDark: "#34404D",
  gray: "#7A828E",
};

const LOGO_WIDTHS = [256, 512, 1024, 1920];
const MARK_SIZES = [16, 18, 22, 32, 36, 44, 64, 128, 256, 512, 1024];
const APP_ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024];
const MENU_GLYPH_SIZES = [18, 22, 36, 44];

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

function mkdirp(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function writeFile(relPath, content) {
  const out = path.join(OUTPUT_ROOT, relPath);
  mkdirp(path.dirname(out));
  fs.writeFileSync(out, content);
  return out;
}

function copyFile(source, target) {
  mkdirp(path.dirname(target));
  fs.copyFileSync(source, target);
}

function hexToRgb(hex) {
  const h = hex.replace("#", "");
  return {
    r: parseInt(h.slice(0, 2), 16),
    g: parseInt(h.slice(2, 4), 16),
    b: parseInt(h.slice(4, 6), 16),
  };
}

function rgbToHex({ r, g, b }) {
  return `#${[r, g, b].map((v) => v.toString(16).padStart(2, "0")).join("")}`.toUpperCase();
}

function rgbToHsl({ r, g, b }) {
  r /= 255;
  g /= 255;
  b /= 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h = 0;
  let s = 0;
  const l = (max + min) / 2;
  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r:
        h = (g - b) / d + (g < b ? 6 : 0);
        break;
      case g:
        h = (b - r) / d + 2;
        break;
      default:
        h = (r - g) / d + 4;
        break;
    }
    h /= 6;
  }
  return {
    h: Math.round(h * 360),
    s: Math.round(s * 100),
    l: Math.round(l * 100),
  };
}

function rgbToCmyk({ r, g, b }) {
  const rr = r / 255;
  const gg = g / 255;
  const bb = b / 255;
  const k = 1 - Math.max(rr, gg, bb);
  if (k === 1) return { c: 0, m: 0, y: 0, k: 100 };
  return {
    c: Math.round(((1 - rr - k) / (1 - k)) * 100),
    m: Math.round(((1 - gg - k) / (1 - k)) * 100),
    y: Math.round(((1 - bb - k) / (1 - k)) * 100),
    k: Math.round(k * 100),
  };
}

function shade(hex, amount) {
  const rgb = hexToRgb(hex);
  const next = {};
  for (const key of ["r", "g", "b"]) {
    const target = amount >= 0 ? 255 : 0;
    next[key] = Math.round(rgb[key] + (target - rgb[key]) * Math.abs(amount));
  }
  return rgbToHex(next);
}

async function sampleAccentHex() {
  const { data, info } = await sharp(SOURCE_IMAGE_BUFFER).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const candidates = [];
  for (let i = 0; i < data.length; i += info.channels) {
    const r = data[i];
    const g = data[i + 1];
    const b = data[i + 2];
    if (b > 140 && b > r + 40 && b > g + 20 && b - r > 60) {
      candidates.push([r, g, b]);
    }
  }
  if (!candidates.length) return BRAND.accentFallback;
  const median = (index) => {
    const values = candidates.map((item) => item[index]).sort((a, b) => a - b);
    return values[Math.floor(values.length / 2)];
  };
  return rgbToHex({ r: median(0), g: median(1), b: median(2) });
}

function svgShell({ width, height, body, defs = "" }) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-label="VachaVox logo">
  <defs>
${defs}
  </defs>
${body}
</svg>
`;
}

function colorsFor(variant, accent) {
  switch (variant) {
    case "black":
      return { bar: "#000000", accent: "#000000", text: "#000000", bg: "transparent" };
    case "white":
      return { bar: "#FFFFFF", accent: "#FFFFFF", text: "#FFFFFF", bg: "transparent" };
    case "grayscale":
      return { bar: "#2B3037", accent: "#8A929D", text: "#2B3037", bg: "transparent" };
    case "dark-theme":
      return { bar: "#F8FAFC", accent, text: "#F8FAFC", bg: "transparent" };
    case "light-theme":
    case "transparent":
    case "full-color":
    default:
      return { bar: BRAND.darkText, accent, text: BRAND.darkText, bg: "transparent" };
  }
}

function markGroup({ variant = "full-color", accent = BRAND.accentFallback, scale = 1, x = 0, y = 0 }) {
  const c = colorsFor(variant, accent);
  const bars = [
    { x: 24, y: 74, w: 11, h: 43, fill: c.bar },
    { x: 47, y: 57, w: 13, h: 76, fill: c.bar },
    { x: 70, y: 68, w: 13, h: 112, fill: c.bar },
    { x: 93, y: 89, w: 13, h: 132, fill: c.bar },
    { x: 116, y: 112, w: 13, h: 118, fill: c.bar },
    { x: 139, y: 134, w: 13, h: 86, fill: c.accent },
    { x: 162, y: 113, w: 13, h: 86, fill: c.accent },
    { x: 185, y: 89, w: 13, h: 132, fill: c.bar },
    { x: 208, y: 68, w: 13, h: 112, fill: c.bar },
    { x: 231, y: 57, w: 13, h: 76, fill: c.bar },
    { x: 254, y: 74, w: 11, h: 43, fill: c.bar },
  ];
  const body = bars
    .map((bar) => `<rect x="${bar.x}" y="${bar.y}" width="${bar.w}" height="${bar.h}" rx="${bar.w / 2}" fill="${bar.fill}"/>`)
    .join("\n    ");
  return `<g transform="translate(${x} ${y}) scale(${scale})">
    <g transform="translate(-18 -23)">
    ${body}
    </g>
  </g>`;
}

function markSvg({ variant = "full-color", accent = BRAND.accentFallback, background = "transparent" }) {
  const defs =
    background === "dark"
      ? `    <linearGradient id="darkMarkBg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#1E2933"/>
      <stop offset="1" stop-color="#101820"/>
    </linearGradient>`
      : "";
  const bg =
    background === "dark"
      ? `<rect x="0" y="0" width="256" height="256" rx="28" fill="url(#darkMarkBg)"/>`
      : background === "light"
        ? `<rect x="0" y="0" width="256" height="256" rx="28" fill="#FFFFFF"/>`
        : "";
  return svgShell({
    width: 256,
    height: 256,
    defs,
    body: `  ${bg}
  ${markGroup({ variant, accent, scale: 0.86, x: 19.2, y: 24.4 })}`,
  });
}

function wordmarkSvg({ variant = "full-color", accent = BRAND.accentFallback, background = "transparent" }) {
  const c = colorsFor(variant, accent);
  const bg =
    background === "dark"
      ? `<rect x="0" y="0" width="760" height="180" rx="24" fill="${BRAND.darkBg}"/>`
      : background === "light"
        ? `<rect x="0" y="0" width="760" height="180" rx="24" fill="#FFFFFF"/>`
        : "";
  return svgShell({
    width: 760,
    height: 180,
    body: `  ${bg}
  <text x="20" y="125" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" font-size="112" font-weight="400" letter-spacing="0">
    <tspan fill="${c.text}">Vacha</tspan><tspan fill="${c.accent}">Vox</tspan>
  </text>`,
  });
}

function logoSvg({ variant = "full-color", accent = BRAND.accentFallback, background = "transparent" }) {
  const c = colorsFor(variant, accent);
  const bg =
    background === "dark"
      ? `<rect x="0" y="0" width="1080" height="270" rx="34" fill="${BRAND.darkBg}"/>`
      : background === "light"
        ? `<rect x="0" y="0" width="1080" height="270" rx="34" fill="#FFFFFF"/>`
        : "";
  return svgShell({
    width: 1080,
    height: 270,
    body: `  ${bg}
  ${markGroup({ variant, accent, scale: 0.84, x: 33, y: 13 })}
  <text x="326" y="177" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" font-size="118" font-weight="400" letter-spacing="0">
    <tspan fill="${c.text}">Vacha</tspan><tspan fill="${c.accent}">Vox</tspan>
  </text>`,
  });
}

function appIconSvg({ variant = "light", accent = BRAND.accentFallback }) {
  const dark = variant === "dark";
  const defs = `    <linearGradient id="iconBg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${dark ? "#25313B" : "#FFFFFF"}"/>
      <stop offset="1" stop-color="${dark ? "#101820" : "#F1F5F9"}"/>
    </linearGradient>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="150%">
      <feDropShadow dx="0" dy="28" stdDeviation="34" flood-color="#000000" flood-opacity="${dark ? "0.35" : "0.18"}"/>
    </filter>`;
  return svgShell({
    width: 1024,
    height: 1024,
    defs,
    body: `  <rect x="112" y="112" width="800" height="800" rx="178" fill="url(#iconBg)" filter="url(#shadow)"/>
  <rect x="114" y="114" width="796" height="796" rx="176" fill="none" stroke="${dark ? "#2D3945" : "#E4E8EE"}" stroke-width="6"/>
  ${markGroup({ variant: dark ? "dark-theme" : "full-color", accent, scale: 2.78, x: 160, y: 176 })}`,
  });
}

function lockupSvg({ variant = "full-color", accent = BRAND.accentFallback, background = "transparent", compact = false }) {
  const c = colorsFor(variant, accent);
  const darkBg = background === "dark";
  const width = compact ? 860 : 1180;
  const bg =
    background === "dark"
      ? `<rect x="0" y="0" width="${width}" height="220" rx="22" fill="${BRAND.darkBg}"/>`
      : background === "light"
        ? `<rect x="0" y="0" width="${width}" height="220" rx="22" fill="#FFFFFF" stroke="${BRAND.borderLight}"/>`
        : "";
  const icon = compact
    ? `<rect x="54" y="38" width="144" height="144" rx="30" fill="${darkBg ? "#1F2A35" : "#FFFFFF"}" stroke="${darkBg ? "#2D3945" : "#E2E8F0"}"/>
  ${markGroup({ variant, accent, scale: 0.55, x: 56.4, y: 43.7 })}`
    : `${markGroup({ variant, accent, scale: 0.62, x: 34, y: 10 })}`;
  const textX = compact ? 250 : 240;
  return svgShell({
    width,
    height: 220,
    body: `  ${bg}
  ${icon}
  <text x="${textX}" y="143" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" font-size="92" font-weight="400" letter-spacing="0">
    <tspan fill="${c.text}">Vacha</tspan><tspan fill="${c.accent}">Vox</tspan>
  </text>`,
  });
}

function menuGlyphSvg({ variant = "black", accent = BRAND.accentFallback }) {
  const color = variant === "white" ? "#FFFFFF" : "#000000";
  return svgShell({
    width: 64,
    height: 64,
    body: `  <g transform="translate(5.4 6.7) scale(0.21)">
    ${markGroup({ variant: variant === "white" ? "white" : "black", accent, scale: 1, x: 0, y: 0 })}
  </g>`.replaceAll("#000000", color),
  });
}

function menuGlyphCircleTemplateSvg() {
  return svgShell({
    width: 72,
    height: 72,
    defs: `    <mask id="menuCutout" maskUnits="userSpaceOnUse">
      <rect x="0" y="0" width="72" height="72" fill="#000000"/>
      <circle cx="36" cy="36" r="30" fill="#FFFFFF"/>
      <g transform="translate(8.2 8.6) scale(0.22)">
        ${markGroup({ variant: "black", scale: 1, x: 0, y: 0 })}
      </g>
    </mask>`,
    body: `  <circle cx="36" cy="36" r="30" fill="#000000" mask="url(#menuCutout)"/>`,
  });
}

function canvasTemplateSvg({ width, height, theme = "light", title, subtitle = "", kind = "social", accent = BRAND.accentFallback }) {
  const dark = theme === "dark";
  const bg = dark ? BRAND.darkBg : "#FFFFFF";
  const surface = dark ? BRAND.darkSurface : "#F7F9FC";
  const text = dark ? BRAND.lightText : BRAND.darkText;
  const muted = dark ? "#B8C1CC" : BRAND.mutedText;
  const safe = Math.round(Math.min(width, height) * 0.08);
  const logoWidth = Math.min(width - safe * 2, Math.round(width * 0.46));
  const logoHeight = Math.round(logoWidth * 0.25);
  const logoX = safe;
  const logoY = safe;
  const markSize = Math.round(Math.min(width, height) * 0.24);
  const markX = width - safe - markSize;
  const markY = height - safe - markSize;
  const titleSize = Math.max(30, Math.round(Math.min(width, height) * 0.075));
  const subSize = Math.max(18, Math.round(titleSize * 0.38));
  const defs = `    <linearGradient id="canvasBg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${bg}"/>
      <stop offset="1" stop-color="${dark ? "#17222D" : "#EEF4FF"}"/>
    </linearGradient>
    <linearGradient id="accentLine" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="${accent}"/>
      <stop offset="1" stop-color="${shade(accent, 0.42)}"/>
    </linearGradient>`;
  return svgShell({
    width,
    height,
    defs,
    body: `  <rect width="${width}" height="${height}" fill="url(#canvasBg)"/>
  <rect x="${safe}" y="${safe}" width="${Math.round(width - safe * 2)}" height="${Math.round(height - safe * 2)}" rx="${Math.round(Math.min(width, height) * 0.025)}" fill="${surface}" opacity="${dark ? "0.56" : "0.78"}"/>
  <rect x="${safe}" y="${safe}" width="${Math.round(Math.min(width - safe * 2, width * 0.36))}" height="${Math.max(6, Math.round(height * 0.012))}" rx="${Math.max(3, Math.round(height * 0.006))}" fill="url(#accentLine)"/>
  <g transform="translate(${logoX} ${logoY}) scale(${logoWidth / 1080})">
    ${logoSvg({ variant: dark ? "dark-theme" : "full-color", accent }).replace(/<\/?svg[^>]*>/g, "").replace(/<\?xml[^>]*>/g, "")}
  </g>
  <text x="${safe}" y="${Math.round(height * 0.49)}" fill="${text}" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" font-size="${titleSize}" font-weight="500" letter-spacing="0">${escapeXml(title)}</text>
  <text x="${safe}" y="${Math.round(height * 0.49 + titleSize * 0.8)}" fill="${muted}" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" font-size="${subSize}" font-weight="400" letter-spacing="0">${escapeXml(subtitle)}</text>
  <g transform="translate(${markX} ${markY}) scale(${markSize / 256})">
    ${markSvg({ variant: dark ? "dark-theme" : "full-color", accent }).replace(/<\/?svg[^>]*>/g, "").replace(/<\?xml[^>]*>/g, "")}
  </g>
  <text x="${safe}" y="${height - safe}" fill="${muted}" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" font-size="${Math.max(16, Math.round(subSize * 0.78))}" font-weight="400">${escapeXml(kind)}</text>`,
  });
}

function escapeXml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

async function renderSvgToPng(svg, outPath, width, height) {
  mkdirp(path.dirname(outPath));
  let pipeline = sharp(Buffer.from(svg), { density: 384 });
  if (width || height) {
    pipeline = pipeline.resize(width ? Math.round(width) : null, height ? Math.round(height) : null, {
      fit: "contain",
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    });
  }
  await pipeline.png().toFile(outPath);
}

async function renderSvgToWebp(svg, outPath, width, height) {
  mkdirp(path.dirname(outPath));
  let pipeline = sharp(Buffer.from(svg), { density: 384 });
  if (width || height) {
    pipeline = pipeline.resize(width ? Math.round(width) : null, height ? Math.round(height) : null, {
      fit: "contain",
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    });
  }
  await pipeline.webp({ quality: 92 }).toFile(outPath);
}

function renderSvgToPdf(svgPath, outPath) {
  mkdirp(path.dirname(outPath));
  execFileSync("sips", ["-s", "format", "pdf", svgPath, "--out", outPath], { stdio: "ignore" });
}

function icoFromPngs(pngPaths, outPath) {
  const headerSize = 6;
  const entrySize = 16;
  const images = pngPaths.map((file) => fs.readFileSync(file));
  const out = Buffer.alloc(headerSize + entrySize * images.length + images.reduce((sum, img) => sum + img.length, 0));
  out.writeUInt16LE(0, 0);
  out.writeUInt16LE(1, 2);
  out.writeUInt16LE(images.length, 4);
  let imageOffset = headerSize + entrySize * images.length;
  pngPaths.forEach((file, index) => {
    const base = headerSize + entrySize * index;
    const size = Number(path.basename(file).match(/(\\d+)x\\d+/)?.[1] || 32);
    out.writeUInt8(size >= 256 ? 0 : size, base);
    out.writeUInt8(size >= 256 ? 0 : size, base + 1);
    out.writeUInt8(0, base + 2);
    out.writeUInt8(0, base + 3);
    out.writeUInt16LE(1, base + 4);
    out.writeUInt16LE(32, base + 6);
    out.writeUInt32LE(images[index].length, base + 8);
    out.writeUInt32LE(imageOffset, base + 12);
    images[index].copy(out, imageOffset);
    imageOffset += images[index].length;
  });
  mkdirp(path.dirname(outPath));
  fs.writeFileSync(outPath, out);
}

async function writeSvgSet({ baseRel, name, svg, widths = [], sizes = [], pdf = false }) {
  const svgPath = writeFile(`${baseRel}/${name}.svg`, svg);
  if (pdf) {
    renderSvgToPdf(svgPath, path.join(OUTPUT_ROOT, `${baseRel}/${name}.pdf`));
  }
  for (const width of widths) {
    const height = null;
    await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `${baseRel}/${name}-${width}.png`), width, height);
    await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `${baseRel}/${name}-${width}.webp`), width, height);
  }
  for (const size of sizes) {
    await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `${baseRel}/${name}-${size}.png`), size, size);
    await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `${baseRel}/${name}-${size}.webp`), size, size);
  }
  return svgPath;
}

async function generateBrandAssets(accent) {
  const logoVariants = [
    ["full-color", "full-color", "transparent"],
    ["transparent", "full-color", "transparent"],
    ["light-theme", "light-theme", "light"],
    ["dark-theme", "dark-theme", "dark"],
    ["black", "black", "transparent"],
    ["white", "white", "transparent"],
    ["grayscale", "grayscale", "transparent"],
  ];

  for (const [name, variant, bg] of logoVariants) {
    const svg = logoSvg({ variant, accent, background: bg });
    writeFile(`logo/svg/vachavox-logo-${name}.svg`, svg);
    writeFile(`logo/${name}/vachavox-logo-${name}.svg`, svg);
    const svgPath = path.join(OUTPUT_ROOT, `logo/svg/vachavox-logo-${name}.svg`);
    renderSvgToPdf(svgPath, path.join(OUTPUT_ROOT, `logo/pdf/vachavox-logo-${name}.pdf`));
    renderSvgToPdf(svgPath, path.join(OUTPUT_ROOT, `logo/${name}/vachavox-logo-${name}.pdf`));
    for (const width of LOGO_WIDTHS) {
      await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `logo/png/vachavox-logo-${name}-${width}.png`), width);
      await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `logo/webp/vachavox-logo-${name}-${width}.webp`), width);
      await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `logo/${name}/vachavox-logo-${name}-${width}.png`), width);
      await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `logo/${name}/vachavox-logo-${name}-${width}.webp`), width);
    }
  }

  const markVariants = [
    ["full-color", "full-color", "transparent"],
    ["black", "black", "transparent"],
    ["white", "white", "transparent"],
    ["grayscale", "grayscale", "transparent"],
    ["light-theme", "light-theme", "light"],
    ["dark-theme", "dark-theme", "dark"],
  ];
  for (const [name, variant, bg] of markVariants) {
    const svg = markSvg({ variant, accent, background: bg });
    writeFile(`mark/svg/vachavox-mark-${name}.svg`, svg);
    const themeDir = name === "light-theme" || name === "dark-theme" ? `mark/${name}` : null;
    if (themeDir) writeFile(`${themeDir}/vachavox-mark-${name}.svg`, svg);
    for (const size of MARK_SIZES) {
      await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `mark/png/vachavox-mark-${name}-${size}.png`), size, size);
      await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `mark/webp/vachavox-mark-${name}-${size}.webp`), size, size);
      if (themeDir) {
        await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `${themeDir}/vachavox-mark-${name}-${size}.png`), size, size);
        await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `${themeDir}/vachavox-mark-${name}-${size}.webp`), size, size);
      }
    }
  }

  const wordmarkVariants = [
    ["full-color", "full-color", "transparent"],
    ["black", "black", "transparent"],
    ["white", "white", "transparent"],
    ["grayscale", "grayscale", "transparent"],
    ["light-theme", "light-theme", "light"],
    ["dark-theme", "dark-theme", "dark"],
  ];
  for (const [name, variant, bg] of wordmarkVariants) {
    const svg = wordmarkSvg({ variant, accent, background: bg });
    writeFile(`wordmark/svg/vachavox-wordmark-${name}.svg`, svg);
    const themeDir = name === "light-theme" || name === "dark-theme" ? `wordmark/${name}` : null;
    if (themeDir) writeFile(`${themeDir}/vachavox-wordmark-${name}.svg`, svg);
    for (const width of LOGO_WIDTHS) {
      await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `wordmark/png/vachavox-wordmark-${name}-${width}.png`), width);
      await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `wordmark/webp/vachavox-wordmark-${name}-${width}.webp`), width);
      if (themeDir) {
        await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `${themeDir}/vachavox-wordmark-${name}-${width}.png`), width);
        await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `${themeDir}/vachavox-wordmark-${name}-${width}.webp`), width);
      }
    }
  }

  const lockups = [
    ["horizontal", "vachavox-lockup-horizontal-full-color", lockupSvg({ variant: "full-color", accent })],
    ["icon-plus-wordmark", "vachavox-lockup-icon-plus-wordmark", lockupSvg({ variant: "full-color", accent, compact: true })],
    ["light-theme", "vachavox-lockup-light-theme", lockupSvg({ variant: "light-theme", accent, background: "light", compact: true })],
    ["dark-theme", "vachavox-lockup-dark-theme", lockupSvg({ variant: "dark-theme", accent, background: "dark", compact: true })],
  ];
  for (const [dir, name, svg] of lockups) {
    writeFile(`lockups/${dir}/${name}.svg`, svg);
    for (const width of LOGO_WIDTHS) {
      await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `lockups/${dir}/${name}-${width}.png`), width);
      await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `lockups/${dir}/${name}-${width}.webp`), width);
    }
  }
}

async function generateAppIcons(accent) {
  for (const variant of ["light", "dark"]) {
    const svg = appIconSvg({ variant, accent });
    writeFile(`app-icons/macos/vachavox-macos-icon-${variant}.svg`, svg);
    for (const size of APP_ICON_SIZES) {
      await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `app-icons/macos/vachavox-macos-icon-${variant}-${size}.png`), size, size);
      await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `app-icons/macos/vachavox-macos-icon-${variant}-${size}.webp`), size, size);
    }
  }

  const iconsetMap = [
    ["icon_16x16.png", 16],
    ["icon_16x16@2x.png", 32],
    ["icon_32x32.png", 32],
    ["icon_32x32@2x.png", 64],
    ["icon_128x128.png", 128],
    ["icon_128x128@2x.png", 256],
    ["icon_256x256.png", 256],
    ["icon_256x256@2x.png", 512],
    ["icon_512x512.png", 512],
    ["icon_512x512@2x.png", 1024],
  ];
  const iconSvg = appIconSvg({ variant: "light", accent });
  for (const [file, size] of iconsetMap) {
    await renderSvgToPng(iconSvg, path.join(OUTPUT_ROOT, "app-icons/macos/iconset", file), size, size);
  }
  const tempIconset = path.join(os.tmpdir(), "VachaVox.iconset");
  fs.rmSync(tempIconset, { recursive: true, force: true });
  fs.cpSync(path.join(OUTPUT_ROOT, "app-icons/macos/iconset"), tempIconset, { recursive: true });
  execFileSync("iconutil", [
    "-c",
    "icns",
    "-o",
    path.join(OUTPUT_ROOT, "app-icons/macos/VachaVox.icns"),
    tempIconset,
  ]);
  fs.rmSync(tempIconset, { recursive: true, force: true });

  const mobileTargets = [
    ["ios", "vachavox-ios-icon"],
    ["android", "vachavox-android-icon"],
    ["pwa", "vachavox-pwa-icon"],
  ];
  for (const [dir, name] of mobileTargets) {
    writeFile(`app-icons/${dir}/${name}.svg`, iconSvg);
    for (const size of APP_ICON_SIZES) {
      await renderSvgToPng(iconSvg, path.join(OUTPUT_ROOT, `app-icons/${dir}/${name}-${size}.png`), size, size);
      await renderSvgToWebp(iconSvg, path.join(OUTPUT_ROOT, `app-icons/${dir}/${name}-${size}.webp`), size, size);
    }
  }
}

async function generateFaviconsAndGlyphs(accent) {
  const faviconSvg = markSvg({ variant: "full-color", accent });
  const faviconSizes = [16, 32, 48, 180, 192, 512];
  const faviconPngs = {};
  for (const size of faviconSizes) {
    const name =
      size === 180
        ? "apple-touch-icon.png"
        : size === 192
          ? "android-chrome-192x192.png"
          : size === 512
            ? "android-chrome-512x512.png"
            : `favicon-${size}x${size}.png`;
    const outPath = path.join(OUTPUT_ROOT, "favicons", name);
    await renderSvgToPng(faviconSvg, outPath, size, size);
    faviconPngs[size] = outPath;
  }
  icoFromPngs([faviconPngs[16], faviconPngs[32], faviconPngs[48]], path.join(OUTPUT_ROOT, "favicons", "favicon.ico"));
  writeFile(
    "favicons/site.webmanifest",
    JSON.stringify(
      {
        name: "VachaVox",
        short_name: "VachaVox",
        icons: [
          { src: "android-chrome-192x192.png", sizes: "192x192", type: "image/png" },
          { src: "android-chrome-512x512.png", sizes: "512x512", type: "image/png" },
        ],
        theme_color: accent,
        background_color: "#ffffff",
        display: "standalone",
      },
      null,
      2
    )
  );

  for (const variant of ["black", "white"]) {
    const svg = menuGlyphSvg({ variant, accent });
    writeFile(`menu-bar-glyphs/${variant}/vachavox-menu-bar-glyph-${variant}.svg`, svg);
    for (const size of MENU_GLYPH_SIZES) {
      await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `menu-bar-glyphs/${variant}/vachavox-menu-bar-glyph-${variant}-${size}.png`), size, size);
    }
  }
  writeFile("menu-bar-glyphs/black/vachavox-menu-bar-glyph-circle-template.svg", menuGlyphCircleTemplateSvg());
  await renderSvgToPng(
    menuGlyphCircleTemplateSvg(),
    path.join(OUTPUT_ROOT, "menu-bar-glyphs/black/vachavox-menu-bar-glyph-template-72.png"),
    72,
    72
  );
}

async function generateSocialWebTemplates(accent) {
  const social = [
    ["social/instagram", "vachavox-instagram-profile", 320, 320, "Profile image", "Local-first dictation"],
    ["social/instagram", "vachavox-instagram-post", 1080, 1080, "Transforming sound into script", "Private local transcription"],
    ["social/instagram", "vachavox-instagram-story", 1080, 1920, "VachaVox", "Zero-cloud speech to text"],
    ["social/facebook", "vachavox-facebook-profile", 320, 320, "VachaVox", "Local transcription"],
    ["social/facebook", "vachavox-facebook-cover", 1640, 624, "Transforming sound into script, locally.", "Privacy-first macOS dictation"],
    ["social/linkedin", "vachavox-linkedin-company-logo", 300, 300, "VachaVox", "Local AI dictation"],
    ["social/linkedin", "vachavox-linkedin-banner", 1128, 191, "VachaVox", "Private speech-to-text for macOS"],
    ["social/x-twitter", "vachavox-x-profile", 400, 400, "VachaVox", "Local transcription"],
    ["social/x-twitter", "vachavox-x-header", 1500, 500, "VachaVox", "Transforming sound into script, locally."],
    ["social/youtube", "vachavox-youtube-profile", 800, 800, "VachaVox", "Local transcription"],
    ["social/youtube", "vachavox-youtube-banner", 2560, 1440, "VachaVox", "Private local dictation for macOS"],
  ];
  for (const [dir, name, width, height, title, subtitle] of social) {
    for (const theme of ["light", "dark"]) {
      const svg = canvasTemplateSvg({ width, height, theme, title, subtitle, kind: name, accent });
      writeFile(`${dir}/${name}-${theme}.svg`, svg);
      await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `${dir}/${name}-${theme}.png`), width, height);
      await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `${dir}/${name}-${theme}.webp`), width, height);
    }
  }

  const web = [
    ["web/header", "vachavox-header-logo-light", 640, 160, "VachaVox", "Header logo", "light"],
    ["web/header", "vachavox-header-logo-dark", 640, 160, "VachaVox", "Header logo", "dark"],
    ["web/footer", "vachavox-footer-logo-light", 640, 160, "VachaVox", "Footer logo", "light"],
    ["web/footer", "vachavox-footer-logo-dark", 640, 160, "VachaVox", "Footer logo", "dark"],
    ["web/open-graph", "vachavox-open-graph", 1200, 630, "VachaVox", "Transforming sound into script, locally.", "light"],
    ["web/splash", "vachavox-loading-screen-logo", 1024, 1024, "VachaVox", "Loading", "light"],
    ["web/splash", "vachavox-splash-screen-logo", 2048, 2048, "VachaVox", "Local-first dictation", "dark"],
    ["web/pwa", "vachavox-pwa-splash", 1536, 2048, "VachaVox", "Private macOS transcription", "light"],
  ];
  for (const [dir, name, width, height, title, subtitle, theme] of web) {
    const svg = canvasTemplateSvg({ width, height, theme, title, subtitle, kind: name, accent });
    writeFile(`${dir}/${name}.svg`, svg);
    await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `${dir}/${name}.png`), width, height);
    await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `${dir}/${name}.webp`), width, height);
  }
  copyFile(path.join(OUTPUT_ROOT, "logo/png/vachavox-logo-transparent-1024.png"), path.join(OUTPUT_ROOT, "web/header/vachavox-web-logo-transparent.png"));

  const templates = [
    ["templates/app-splash", "vachavox-app-splash", 1440, 900, "VachaVox", "Transforming sound into script, locally.", "dark"],
    ["templates/email-signature", "vachavox-email-signature", 900, 280, "VachaVox", "Privacy-first local dictation for macOS", "light"],
    ["templates/business-card", "vachavox-business-card-front", 1050, 600, "VachaVox", "Local-first transcription", "dark"],
    ["templates/business-card", "vachavox-business-card-back", 1050, 600, "Transforming sound into script", "vachavox.local", "light"],
    ["templates/letterhead", "vachavox-letterhead", 2550, 3300, "VachaVox", "Privacy-first local transcription", "light"],
    ["templates/presentation", "vachavox-presentation-title-slide", 1920, 1080, "VachaVox", "Transforming sound into script, locally.", "dark"],
    ["templates/presentation", "vachavox-presentation-content-slide", 1920, 1080, "Local-first transcription", "Fast, private, and offline-capable.", "light"],
  ];
  for (const [dir, name, width, height, title, subtitle, theme] of templates) {
    const svg = canvasTemplateSvg({ width, height, theme, title, subtitle, kind: name, accent });
    writeFile(`${dir}/${name}.svg`, svg);
    await renderSvgToPng(svg, path.join(OUTPUT_ROOT, `${dir}/${name}.png`), width, height);
    await renderSvgToWebp(svg, path.join(OUTPUT_ROOT, `${dir}/${name}.webp`), width, height);
  }
  writeFile(
    "templates/email-signature/vachavox-email-signature.html",
    `<!doctype html>
<html>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Helvetica Neue',Arial,sans-serif;color:${BRAND.darkText};">
  <table role="presentation" cellspacing="0" cellpadding="0">
    <tr>
      <td style="padding-right:14px;"><img src="../../mark/png/vachavox-mark-full-color-64.png" alt="VachaVox" width="64" height="64"></td>
      <td>
        <strong style="font-size:18px;">VachaVox</strong><br>
        <span style="color:${BRAND.mutedText};">Transforming sound into script, locally.</span>
      </td>
    </tr>
  </table>
</body>
</html>
`
  );
}

function writeThemeFiles(accent) {
  const hover = shade(accent, -0.12);
  const light = shade(accent, 0.86);
  const colors = {
    primary: accent,
    primaryHover: hover,
    primarySoft: light,
    backgroundLight: "#FFFFFF",
    backgroundDark: BRAND.darkBg,
    surfaceLight: BRAND.lightSurface,
    surfaceDark: BRAND.darkSurface,
    textDark: BRAND.darkText,
    textLight: BRAND.lightText,
    textMuted: BRAND.mutedText,
    borderLight: BRAND.borderLight,
    borderDark: BRAND.borderDark,
    disabledLight: "#C7CED8",
    disabledDark: "#4E5A66",
    focusRing: shade(accent, 0.28),
    logoColorPrimary: BRAND.darkText,
    logoColorAccent: accent,
  };
  writeFile(
    "themes/colors.json",
    JSON.stringify(
      Object.fromEntries(
        Object.entries(colors).map(([name, hex]) => {
          const rgb = hexToRgb(hex);
          const hsl = rgbToHsl(rgb);
          const cmyk = rgbToCmyk(rgb);
          return [
            name,
            {
              hex,
              rgb: `rgb(${rgb.r}, ${rgb.g}, ${rgb.b})`,
              hsl: `hsl(${hsl.h} ${hsl.s}% ${hsl.l}%)`,
              cmyk: `cmyk(${cmyk.c}% ${cmyk.m}% ${cmyk.y}% ${cmyk.k}%)`,
            },
          ];
        })
      ),
      null,
      2
    )
  );
  const tokens = `:root {
  --color-primary: ${colors.primary};
  --color-primary-hover: ${colors.primaryHover};
  --color-primary-soft: ${colors.primarySoft};
  --color-background: ${colors.backgroundLight};
  --color-surface: ${colors.surfaceLight};
  --color-text: ${colors.textDark};
  --color-text-muted: ${colors.textMuted};
  --color-border: ${colors.borderLight};
  --color-disabled: ${colors.disabledLight};
  --color-focus-ring: ${colors.focusRing};
  --logo-color-primary: ${colors.logoColorPrimary};
  --logo-color-accent: ${colors.logoColorAccent};
}
`;
  writeFile("themes/tokens.css", tokens);
  writeFile(
    "themes/theme-light.css",
    `:root, [data-theme="light"] {
  --color-background: ${colors.backgroundLight};
  --color-surface: ${colors.surfaceLight};
  --color-text: ${colors.textDark};
  --color-text-muted: ${colors.textMuted};
  --color-border: ${colors.borderLight};
  --logo-color-primary: ${colors.textDark};
  --logo-color-accent: ${colors.primary};
}
`
  );
  writeFile(
    "themes/theme-dark.css",
    `:root[data-theme="dark"], [data-theme="dark"] {
  --color-background: ${colors.backgroundDark};
  --color-surface: ${colors.surfaceDark};
  --color-text: ${colors.textLight};
  --color-text-muted: #B8C1CC;
  --color-border: ${colors.borderDark};
  --logo-color-primary: ${colors.textLight};
  --logo-color-accent: ${colors.primary};
}
`
  );
  writeFile(
    "themes/tailwind-theme.js",
    `module.exports = {
  theme: {
    extend: {
      colors: {
        primary: "${colors.primary}",
        "primary-hover": "${colors.primaryHover}",
        "primary-soft": "${colors.primarySoft}",
        background: "var(--color-background)",
        surface: "var(--color-surface)",
        text: "var(--color-text)",
        muted: "var(--color-text-muted)",
        border: "var(--color-border)"
      },
      boxShadow: {
        focus: "0 0 0 3px ${colors.focusRing}"
      }
    }
  }
};
`
  );
}

function writeDocs(accent) {
  const rgb = hexToRgb(accent);
  const hsl = rgbToHsl(rgb);
  const cmyk = rgbToCmyk(rgb);
  writeFile(
    "README.md",
    `# VachaVox Brand Assets Final

Generated from \`from-chatgpt/logo-v2-detailed.png\`, the approved final VachaVox brand board.

## Included

- Master horizontal logo, standalone mark, wordmark, lockups, app icons, favicons, menu bar glyphs, social assets, web assets, templates, theme tokens, and usage docs.
- SVG masters plus PNG, WebP, and PDF exports where practical.
- macOS iconset and \`VachaVox.icns\` for the SwiftPM app bundle.

## Recommended Files

- Web header: \`web/header/vachavox-header-logo-light.png\` or \`web/header/vachavox-header-logo-dark.png\`.
- macOS app: \`app-icons/macos/VachaVox.icns\` and \`menu-bar-glyphs/black/vachavox-menu-bar-glyph-template-72.png\`.
- iOS/Android/PWA: use the matching folders under \`app-icons/\` and \`favicons/\`.
- Social media: use platform-specific files under \`social/\`.
- Print or editable layout work: start from SVG/PDF files.

## Theme Usage

Use light-theme assets on white or near-white surfaces. Use dark-theme or white assets on dark surfaces. Keep the blue accent as the only logo accent color.
`
  );
  writeFile(
    "docs/brand-guidelines.md",
    `# VachaVox Brand Guidelines

## Brand Overview

VachaVox is a privacy-first local transcription app. The identity combines a V-shaped waveform mark with a clean wordmark. The blue center bars represent the structured digital output in \`Vox\`.

## Logo Anatomy

- Mark: V-shaped vertical waveform bars.
- Wordmark: \`Vacha\` in dark or white, \`Vox\` in blue.
- Accent: sampled primary blue \`${accent}\`.

## Clear Space

Keep clear space around the logo equal to at least the height of one outer waveform bar. For icon-only usage, keep at least 16% of the mark width as padding.

## Minimum Sizes

- Master horizontal logo: 128 px wide minimum for screen use.
- Standalone mark: 16 px minimum when using simplified menu-bar glyphs, 32 px preferred.
- Wordmark: 160 px wide minimum.

## Light And Dark Usage

Use full-color or light-theme assets on light surfaces. Use dark-theme assets on dark surfaces, where non-accent bars and \`Vacha\` are white.

## Incorrect Usage

Do not rotate the waveform, recolor the blue accent, stretch the mark, place dark assets on dark surfaces, or separate \`Vox\` from the wordmark color system.
`
  );
  writeFile(
    "docs/logo-usage.md",
    `# Logo Usage

Use the master logo for product pages, docs headers, release material, and larger app surfaces.

Use the standalone mark for app icons, favicons, avatars, compact UI, and small-space brand moments.

Use the wordmark when the mark is already nearby or when horizontal space is limited.

Use the app icon only for launcher/app-store contexts. Use menu bar glyphs only for macOS status item contexts.

Use full-color assets by default. Use black/white/grayscale only when color reproduction is unavailable or the surface requires a single-color mark.
`
  );
  writeFile(
    "docs/color-palette.md",
    `# Color Palette

| Token | HEX | RGB | HSL | CMYK | Usage |
| --- | --- | --- | --- | --- | --- |
| Primary Blue | ${accent} | rgb(${rgb.r}, ${rgb.g}, ${rgb.b}) | hsl(${hsl.h} ${hsl.s}% ${hsl.l}%) | cmyk(${cmyk.c}% ${cmyk.m}% ${cmyk.y}% ${cmyk.k}%) | Logo accent, links, focus |
| Primary Text | ${BRAND.darkText} | rgb(17, 24, 32) | hsl(212 31% 10%) | cmyk(47% 25% 0% 87%) | Text and dark mark bars |
| Light Background | #FFFFFF | rgb(255, 255, 255) | hsl(0 0% 100%) | cmyk(0% 0% 0% 0%) | Light surfaces |
| Dark Background | ${BRAND.darkBg} | rgb(17, 24, 32) | hsl(212 31% 10%) | cmyk(47% 25% 0% 87%) | Dark surfaces |
| Muted Text | ${BRAND.mutedText} | rgb(89, 97, 109) | hsl(216 10% 39%) | cmyk(18% 11% 0% 57%) | Secondary copy |
`
  );
  writeFile(
    "docs/typography.md",
    `# Typography

The supplied raster board does not include editable font outlines, so the generated SVG wordmark uses a close system-vector approximation based on Helvetica Neue, Helvetica, Arial, and sans-serif fallbacks.

Recommended UI pairing:

- Heading: SF Pro Display or Helvetica Neue Medium.
- Body: SF Pro Text or Helvetica Neue Regular.
- Button: SF Pro Text Medium.
- Caption: SF Pro Text Regular.

\`\`\`css
body {
  font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif;
}
\`\`\`
`
  );
  writeFile(
    "docs/source-notes.md",
    `# Source Notes

Source image: \`docs/source-logo-v2-detailed.png\` in this package. It is copied from the approved VachaVox logo board when the asset package is generated.

Observed source dimensions: 1448 x 1086 px, RGB, 72 DPI.

The primary blue accent was sampled from saturated blue pixels in the source board. The generated median accent is \`${accent}\`.

The waveform mark was reconstructed as clean SVG rounded vertical bars following the approved V-shaped audio waveform. The wordmark is a high-quality SVG text approximation because the raster board does not provide original vector text outlines.

App icons, standalone marks, framed lockups, and menu bar glyphs use optical centering so the waveform has uniform visual padding instead of excess whitespace at the bottom. Small menu bar glyphs use the same V waveform geometry rendered as a single-color template glyph. Detail is intentionally preserved down to 18 px, with the app resource exported at 72 px for macOS template rendering.

Canva/Figma handoff: all SVG and PNG outputs are import-ready. Canva local imports require public HTTPS URLs or manual upload through Canva. Figma editable handoff requires a target Figma file/team.
`
  );
}

function writePackageScripts() {
  writeFile("scripts/generate-assets.js", SELF_SOURCE.replaceAll("Scripts/generate_vachavox_brand_assets.js", "scripts/generate-assets.js"));
  if (!VALIDATOR_SOURCE) {
    throw new Error("Could not load validator source for package scripts.");
  }
  writeFile("scripts/validate-assets.js", VALIDATOR_SOURCE);
}

function createRequiredDirs() {
  for (const dir of REQUIRED_DIRS) mkdirp(path.join(OUTPUT_ROOT, dir));
}

function createZip() {
  if (fs.existsSync(ZIP_PATH)) fs.rmSync(ZIP_PATH);
  execFileSync("zip", ["-qry", ZIP_PATH, "vachavox-brand-assets-final"], {
    cwd: path.join(REPO_ROOT, "Docs", "brand-assets"),
  });
}

function syncAppAndDocsBrandAssets() {
  copyFile(path.join(OUTPUT_ROOT, "app-icons/macos/VachaVox.icns"), path.join(APP_RESOURCE_DIR, "VachaVox.icns"));
  copyFile(path.join(OUTPUT_ROOT, "menu-bar-glyphs/black/vachavox-menu-bar-glyph-template-72.png"), path.join(APP_RESOURCE_DIR, "MenuBarIcon.png"));
  copyFile(path.join(OUTPUT_ROOT, "logo/png/vachavox-logo-transparent-1024.png"), path.join(DOCS_BRAND_DIR, "VachaVox_logo_transparent.png"));
  copyFile(path.join(OUTPUT_ROOT, "app-icons/macos/vachavox-macos-icon-light-1024.png"), path.join(DOCS_BRAND_DIR, "vvox_logo_icon.png"));
}

async function main() {
  if (!SOURCE_IMAGE_BUFFER) {
    throw new Error(`Missing source image: ${SOURCE_IMAGE}`);
  }
  fs.rmSync(OUTPUT_ROOT, { recursive: true, force: true });
  mkdirp(OUTPUT_ROOT);
  createRequiredDirs();

  const accent = await sampleAccentHex();
  await generateBrandAssets(accent);
  await generateAppIcons(accent);
  await generateFaviconsAndGlyphs(accent);
  await generateSocialWebTemplates(accent);
  writeThemeFiles(accent);
  writeDocs(accent);
  writePackageScripts();
  fs.writeFileSync(path.join(OUTPUT_ROOT, "docs", "source-logo-v2-detailed.png"), SOURCE_IMAGE_BUFFER);
  syncAppAndDocsBrandAssets();
  createZip();

  const fileCount = countFiles(OUTPUT_ROOT);
  console.log(`Generated ${fileCount} files`);
  console.log(OUTPUT_ROOT);
  console.log(ZIP_PATH);
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

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
