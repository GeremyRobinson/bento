#!/usr/bin/env node
/**
 * Route hard-coded style values through the design tokens (src/styles/tokens.css).
 *
 *   node scripts/tokenize.mjs          rewrite src/**\/*.css in place
 *   node scripts/tokenize.mjs --check  change nothing; exit 1 and list the files that still need it
 *
 * Every replacement swaps a literal for a token whose value IS that literal, so nothing on screen changes. The script
 * is idempotent (a second run changes nothing), so a branch that edits the same stylesheets can rerun it after a merge
 * instead of re-applying a diff by hand. The tokens themselves are written by hand in tokens.css; this only rewrites
 * the places that use them. Left alone: tokens.css, fonts.css (@font-face weight ranges), the sandbox, comments,
 * keyframe steps, and custom-property definitions (those ARE the tokens) except the few listed in SIZE_PROPS.
 * No dependencies: plain Node.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../src");
const SKIP = new Set(["styles/tokens.css", "styles/fonts.css"]);

/* ---- the maps: literal -> token. Each token's value in tokens.css equals its literal exactly. ---- */

// motion: every duration and delay (ms values are written the same way the source wrote them; .5s and 500ms both map
// to --dur-500), and the one easing curve that wasn't a token yet
const DUR = ms => (ms < 1 ? "var(--dur-off)" : `var(--dur-${ms})`);
const EASE = { "cubic-bezier(.2,.7,.4,1)": "var(--ease-toss)" };

const Z = { "-1": "--z-under", "0": "--z-flat", "1": "--z-up", "2": "--z-up2", "15": "--z-island", "20": "--z-sheet", "30": "--z-dim",
  "31": "--z-stack", "32": "--z-island-open", "40": "--z-zoom", "99": "--z-halo" };

const WEIGHT = { "400": "--w-regular", "500": "--w-key", "550": "--w-mid", "650": "--w-bold" };

// the text scale (12-22px). 15px is the existing --small. Display sizes (25px and up) are tuned per element and stay.
const FONT = { "12px": "--fz-2xs", "13px": "--fz-xs", "14px": "--fz-sm", "15px": "--small", "16px": "--fz-md", "17px": "--fz-lg",
  "19px": "--fz-xl", "22px": "--fz-2xl" };

// corners: full pills and circles, and the on-grid steps. Off-grid corners (2, 3, 5, 6, 7, 14, 18, 22px) stay.
const RADIUS = { "999px": "--r-pill", "50%": "--r-round", "4px": "--r-xs", "8px": "--r-sm", "12px": "--r-md", "16px": "--r-lg",
  "20px": "--r-xl", "24px": "--r-2xl", "36px": "--r-sheet" };

// the 4px spacing grid, for padding, margin, gaps and offsets. Off-grid values (2, 3, 5, 6, 10, 14, 18, 22px) stay.
const SPACE = { "4px": "--sp-1", "8px": "--sp-2", "12px": "--sp-3", "16px": "--sp-4", "20px": "--sp-5", "24px": "--sp-6",
  "28px": "--sp-7", "32px": "--sp-8", "40px": "--sp-10" };

// control sizes: the floating capsule height, the circle inside it, and the smallest tap target
const SIZE = { "52px": "--float-h", "42px": "--float-in" };
const SIZE_PROPS = /^(height|width|min-height)$/;
const TAP = { "44px": "--tap" };

// colours used outside a token definition. Keys are written exactly as the source writes them.
const COLOR = {
  "rgba(255,255,255,.25)": "--white-a25",
  "rgba(0,0,0,.04)": "--black-a04", "rgba(0,0,0,.06)": "--black-a06", "rgba(0,0,0,.08)": "--black-a08",
  "rgb(0 0 0 / .12)": "--black-a12", "rgb(0 0 0 / .25)": "--black-a25", "rgba(0,0,0,.25)": "--black-a25",
  "rgba(15,20,30,.18)": "--ink-a18", "rgba(15,20,30,.25)": "--ink-a25", "rgba(15,20,30,.3)": "--ink-a30", "rgba(15,20,30,.35)": "--ink-a35",
  "rgba(10,12,16,.35)": "--scrim",
  "#fff": "--knob",
  "#000": "--mask-solid", "#0000": "--mask-clear",
  "white": "--mix-lift",
  "#eef0f4": "--cta-ink-dark", "#14161b": "--cta-text-dark",
  // Bento Advanced: always its own dark canvas, the same in both themes
  "#1d1b2e": "--adv-sky", "#0a0a0c": "--adv-night", "#f5f5f7": "--adv-ink", "#c4b5fd": "--adv-lilac", "#f0abfc": "--adv-pink",
  "rgb(255 255 255 / .04)": "--adv-card", "rgb(255 255 255 / .08)": "--adv-hair", "rgb(255 255 255 / .16)": "--adv-faint-line",
  "rgb(255 255 255 / .22)": "--adv-ring",
};
// a few colours are written inside custom-property definitions outside tokens.css; these get the token too
const COLOR_DEFS = { "--tint": { "#1b1d22": "--cta-ink" }, "--ink": { "#1b1d22": "--cta-ink" } };
// custom properties outside tokens.css whose value is built from grid sizes
const CUSTOM_SIZES = { "--pill-h": [SIZE], "--pill-pad": [SPACE], "--below-island": [SPACE, SIZE] };
const CUSTOM_WHOLE = { "--pill-weight": WEIGHT };
// exact rewrites: a fallback that can never be used (--on-tint is always set on :root)
const FIXUPS = [["var(--on-tint,#fff)", "var(--on-tint)"]];

/* ---- the rewriter ---- */

const esc = s => s.replace(/[.*+?^${}()|[\]\\/]/g, "\\$&");
const NUM = String.raw`(?<![\w.#-])`; // a literal starts a token: not inside a name, a hex colour, a decimal or a negative
const lit = (map, v) => {
  const keys = Object.keys(map).sort((a, b) => b.length - a.length);
  if (!keys.length) return v;
  return v.replace(new RegExp(NUM + "(" + keys.map(esc).join("|") + String.raw`)(?![\w.%(])`, "g"), k => `var(${map[k]})`);
};
const colors = (v, map) => {
  const keys = Object.keys(map).sort((a, b) => b.length - a.length);
  return v.replace(new RegExp(String.raw`(?<![\w-])(` + keys.map(esc).join("|") + String.raw`)(?![\w-])`, "gi"), k => `var(${map[k] ?? map[k.toLowerCase()]})`);
};
// only whole components of a value (a top-level word, or an argument of max()/min()), never inside calc() arithmetic
// meant for something else; used for radii and font sizes
const whole = (map, v) => (/calc\(/.test(v) ? v : v.split(/(\s+|,|\(|\))/).map(p => (map[p] ? `var(${map[p]})` : p)).join(""));

function declaration(prop, value) {
  const p = prop.toLowerCase();
  let v = value;
  if (p.startsWith("--")) {
    if (COLOR_DEFS[p]) v = colors(v, COLOR_DEFS[p]);
    for (const m of CUSTOM_SIZES[p] ?? []) v = lit(m, v);
    if (CUSTOM_WHOLE[p]) v = whole(CUSTOM_WHOLE[p], v);
    return v;
  }
  if (/^(transition|animation)(-|$)/.test(p)) {
    v = v.replace(/(?<![\w.-])(\d*\.?\d+)(ms|s)(?![\w-])/g, (m, n, u) => {
      const ms = +(u === "s" ? (+n * 1000).toFixed(3) : n);
      return ms === 0 ? m : DUR(ms);
    });
    for (const [k, t] of Object.entries(EASE)) v = v.split(k).join(t);
  }
  if (p === "z-index" && Z[v.trim()]) v = v.replace(v.trim(), `var(${Z[v.trim()]})`);
  if (p === "font-weight") v = whole(WEIGHT, v);
  if (p === "font") v = v.replace(/^(\s*)(\d{3})(?=\s)/, (m, a, w) => a + (WEIGHT[w] ? `var(${WEIGHT[w]})` : w))
    .replace(/^(\s*\S+\s+)(\d+px)(?=[\s/])/, (m, a, s) => a + (FONT[s] ? `var(${FONT[s]})` : s));
  if (p === "font-size") v = v.replace(/^(\s*)(\d+px)(\s*(!important)?\s*)$/, (m, a, s, b) => a + (FONT[s] ? `var(${FONT[s]})` : s) + b);
  if (/radius$/.test(p)) v = whole(RADIUS, v);
  if (/^(padding|margin)(-|$)|^(gap|row-gap|column-gap|inset|top|right|bottom|left)$/.test(p)) v = lit(SPACE, v);
  if (SIZE_PROPS.test(p)) v = lit(SIZE, v);
  if (p === "min-height") v = lit(TAP, v);
  v = colors(v, COLOR);
  return v;
}

export function tokenize(css) {
  // set comments and strings aside so nothing inside them is touched
  const kept = [];
  const hold = s => `\u0000${kept.push(s) - 1}\u0000`;
  for (const [a, b] of FIXUPS) css = css.split(a).join(b);
  let text = css.replace(/\/\*[\s\S]*?\*\/|"(?:[^"\\]|\\.)*"/g, hold);
  // innermost blocks only: a rule's declarations (at-rule preludes and keyframe steps are skipped)
  text = text.replace(/([^{}]*)\{([^{}]*)\}/g, (m, sel, body) => {
    const s = sel.replace(/\u0000\d+\u0000/g, "").trim();
    if (/^(from|to|\d+%)(\s*,\s*(from|to|\d+%))*$/.test(s) || /^@font-face/.test(s)) return m;
    const out = body.replace(/(^|;)(\s*)([-a-zA-Z]+)(\s*:)([^;]*)/g, (d, semi, ws, prop, colon, val) => semi + ws + prop + colon + declaration(prop, val));
    return sel + "{" + out + "}";
  });
  return text.replace(/\u0000(\d+)\u0000/g, (m, i) => kept[+i]);
}

function files(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) return e.name === "sandbox" ? [] : files(p);
    return e.name.endsWith(".css") ? [p] : [];
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const check = process.argv.includes("--check");
  const changed = [];
  for (const f of files(root)) {
    const rel = path.relative(root, f).split(path.sep).join("/");
    if (SKIP.has(rel)) continue;
    const before = fs.readFileSync(f, "utf8"), after = tokenize(before);
    if (after === before) continue;
    changed.push(rel);
    if (!check) fs.writeFileSync(f, after);
  }
  console.log(changed.length ? `${check ? "needs tokens" : "tokenized"}: ${changed.join(", ")}` : "nothing to change");
  if (check && changed.length) process.exit(1);
}
