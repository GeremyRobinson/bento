// node scripts/grade-colours.mjs — writes every grade's colour tokens into src/styles/tokens.css (between the
// "grade colours" markers, in the light block and both dark blocks) from the one colour each grade has in
// src/curriculum/grades/index.ts. Change a grade's colour there, run this, and the whole grade follows: its accent
// (what you press, where you are, progress) and its pictures (soft / mid / deep parts, and a partner hue for a second
// amount). Goals: https://claude.ai/code/artifact/aa94be7d-43ba-4bfc-b1dc-164705d5922c (G 2026-10-13: "the colors for
// diagrams should be based on the grade color"; "vibrant fun").
import { readFileSync, writeFileSync } from "node:fs";

const root = new URL("../", import.meta.url);
const src = readFileSync(new URL("src/curriculum/grades/index.ts", root), "utf8");
const grades = [...src.matchAll(/\{ grade: (\d+),[^}]*color: "(#[0-9a-f]{6})"/g)].map(m => ({ g: +m[1], hex: m[2] }));
if (grades.length !== 13) throw new Error(`expected 13 grades, found ${grades.length}`);

// ---- OKLCH <-> sRGB
const lin = c => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
const gam = c => (c <= 0.0031308 ? 12.92 * c : 1.055 * c ** (1 / 2.4) - 0.055);
function hexToOklch(hex) {
  const [r, g, b] = [1, 3, 5].map(i => lin(parseInt(hex.slice(i, i + 2), 16) / 255));
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  const L = 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s;
  const A = 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s;
  const B = 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s;
  return { L, C: Math.hypot(A, B), H: ((Math.atan2(B, A) * 180) / Math.PI + 360) % 360 };
}
function oklchToRgb(L, C, H) {
  const a = C * Math.cos((H * Math.PI) / 180), b = C * Math.sin((H * Math.PI) / 180);
  const l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3, m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3, s = (L - 0.0894841775 * a - 1.291485548 * b) ** 3;
  return [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s];
}
// the most colourful version of (L, H) up to C that sRGB can show
function color(L, C, H) {
  for (let c = C; c >= 0; c -= 0.002) { const rgb = oklchToRgb(L, c, H); if (rgb.every(v => v >= -1e-4 && v <= 1 + 1e-4)) return "#" + rgb.map(v => Math.round(gam(Math.min(1, Math.max(0, v))) * 255).toString(16).padStart(2, "0")).join(""); }
  return "#808080";
}
const lum = hex => { const [r, g, b] = [1, 3, 5].map(i => lin(parseInt(hex.slice(i, i + 2), 16) / 255)); return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
const contrast = (x, y) => { const [a, b] = [lum(x), lum(y)].sort((p, q) => q - p); return (a + 0.05) / (b + 0.05); };
// lightest (light theme) or darkest-from-light (dark theme) L that still reads 4.5:1 against the card
function readable(H, C, card, dark) {
  for (let i = 0; i <= 60; i++) { const L = dark ? 0.8 + i * 0.01 : 0.62 - i * 0.01, c = color(L, C, H); if (contrast(c, card) >= 4.5) return c; }
  return dark ? "#ffffff" : "#000000";
}

// a second amount's hue: across the wheel, never red or green (they mean wrong and right)
const avoid = h => (h >= 10 && h < 50) || (h >= 125 && h < 165);
function partner(H) { let h = (H + 150) % 360; while (avoid(h)) h = (h + 25) % 360; return h; }


// the hero colour: the lightness where this hue is most colourful, as long as ink or white still reads 4.5:1 on it
const onMid = (c, mode) => (contrast(INK[mode], c) >= contrast("#ffffff", c) ? INK[mode] : "#ffffff");
const chroma = hex => hexToOklch(hex).C;
function vivid(H, mode) {
  // bright but not neon: chroma up to 0.19, at the lightness nearest 0.72 that reaches it
  let best = null, score = -1;
  for (let L = 0.58; L <= 0.84; L += 0.01) {
    const c = color(L, 0.19, H);
    if (Math.max(contrast(INK[mode], c), contrast("#ffffff", c)) < 4.5) continue;
    if (mode === "dark" && contrast(c, CARD.dark) < 3) continue;
    const sc = Math.round(chroma(c) * 100) - Math.abs(L - 0.72);
    if (sc > score) { score = sc; best = c; }
  }
  return best ?? color(0.76, 0.2, H);
}

const CARD = { light: "#ffffff", dark: "#1c1d1f" }, INK = { light: "#1b1c1f", dark: "#111213" };
// 5th grade keeps the approved model's accent exactly
const KEEP = { 5: { light: { acc: "#2456d6", "acc-on": "#ffffff", "acc-soft": "#e3eafb", "acc-fade": "#b9c8ef" }, dark: { acc: "#8fb0ff", "acc-on": "#0c1630", "acc-soft": "#1d2a4a", "acc-fade": "#36456b" } } };

function set({ g, hex }, mode) {
  const { H } = hexToOklch(hex), dark = mode === "dark", P = partner(H);
  const t = {};
  // accent: what you press, where you are, progress
  t["acc"] = dark ? color(0.78, 0.16, H) : readable(H, 0.2, CARD.light, false);
  t["acc-on"] = dark ? color(0.2, 0.05, H) : "#ffffff";
  t["acc-soft"] = dark ? color(0.3, 0.06, H) : color(0.95, 0.035, H);
  t["acc-fade"] = dark ? color(0.42, 0.08, H) : color(0.85, 0.07, H);
  // the page behind the panels: a faint wash of the grade colour, so the whole screen is the grade's world (the live site had it)
  t["page"] = dark ? color(0.19, 0.018, H) : color(0.975, 0.012, H);
  // pictures: bright mid (the hero colour), soft (not reached), deep (outlines and labels, 4.5:1 on the card)
  for (const [k, h] of [["pic", H], ["picb", P]]) {
    t[`${k}-mid`] = vivid(h, mode);
    t[`${k}-soft`] = dark ? color(0.33, 0.08, h) : color(0.93, 0.07, h);
    t[`${k}-deep`] = readable(h, 0.2, CARD[mode], dark);
  }
  // text on a mid part: ink or white, whichever reads better
  t["pic-on-mid"] = onMid(t["pic-mid"], mode);
  Object.assign(t, KEEP[g]?.[mode] ?? {});
  return Object.entries(t).map(([k, v]) => `--g${g}-${k}:${v};`).join(" ");
}

const block = mode => `/* grade colours (${mode}): generated by scripts/grade-colours.mjs from src/curriculum/grades/index.ts, do not edit by hand */\n  ` + grades.map(g => set(g, mode)).join("\n  ") + "\n  /* grade colours end */";
const path = new URL("src/styles/tokens.css", root);
let css = readFileSync(path, "utf8");
const re = /\/\* grade colours \((light|dark)\)[\s\S]*?\/\* grade colours end \*\//g;
const n = [...css.matchAll(re)].length;
if (n !== 3) throw new Error(`tokens.css needs 3 grade colour blocks (light, dark, dark), found ${n}`);
css = css.replace(re, (_, mode) => block(mode));
writeFileSync(path, css);
console.log("grade colours written for", grades.length, "grades");
