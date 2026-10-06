import { describe, expect, it } from "vitest";

/**
 * Nothing on screen is typed in by hand: colours, weights, motion and layers come from the tokens in
 * styles/tokens.css, so dark mode, "Less motion" and a design change reach every screen at once. A raw value slipping
 * back in fails here, with the file and the declaration. scripts/tokenize.mjs fixes most of them on its own
 * (`node scripts/tokenize.mjs`), and the last check runs it to make sure nothing is left for it to do.
 */
// file names from Vite's glob; text straight from disk (Vitest doesn't load stylesheets, so ?raw CSS comes back empty)
const fsName = "node:fs";
const fs = (await import(/* @vite-ignore */ fsName)) as { readFileSync(p: URL, enc: "utf8"): string };
const read = (m: Record<string, unknown>) => Object.keys(m).filter(f => !f.includes("/tests/") && !f.includes("/sandbox/") && !f.startsWith("./"))
  .map(f => [f.replace("../../", ""), fs.readFileSync(new URL(f, import.meta.url), "utf8")] as [string, string]);
const css = read(import.meta.glob("../../**/*.css"));
const ui = read(import.meta.glob(["../../app/**/*.tsx", "../../components/**/*.tsx", "../../screens/**/*.tsx"]));

/** where the values live; everything else reads them */
const TOKENS = "styles/tokens.css";
/** @font-face takes a weight range (100 900), not a weight */
const FONTS = "styles/fonts.css";

/** every declaration outside comments: file, selector, property, value */
function declarations() {
  const out: { file: string; sel: string; prop: string; val: string }[] = [];
  for (const [file, text] of css) {
    if (file === FONTS) continue;
    const t = text.replace(/\/\*[\s\S]*?\*\//g, "");
    for (const m of t.matchAll(/([^{}]*)\{([^{}]*)\}/g)) {
      const sel = m[1]!.trim();
      for (const d of m[2]!.split(";")) {
        const i = d.indexOf(":");
        if (i < 0) continue;
        out.push({ file, sel, prop: d.slice(0, i).trim(), val: d.slice(i + 1).trim() });
      }
    }
  }
  return out;
}
const show = (d: { file: string; sel: string; prop: string; val: string }) => `${d.file}: ${d.sel.slice(-50)} { ${d.prop}:${d.val} }`;
const isDef = (prop: string) => prop.startsWith("--");

const RAW_COLOR = /#[0-9a-fA-F]{3,8}\b|\b(rgba?|hsla?|hwb|lab|lch|oklab|oklch)\(|(?<![\w-])(white|black)(?![\w-])/;
/**
 * The only raw colours outside a token definition, each with its reason. Keep this short: a new colour belongs in
 * tokens.css with a dark value.
 */
const COLOR_ALLOWED: { file: string; sel: RegExp; why: string }[] = [
  // bands.css owns the palettes; Early's canvas is scattered with counters in the Early grades' own colours
  { file: "styles/bands.css", sel: /^html\[data-line="early"\] body$/, why: "the Early canvas's counters (a palette, bands.css)" },
];

describe("no hard-coded styles", () => {
  it("found the stylesheets and the screens", () => {
    expect(css.map(([f]) => f)).toContain(TOKENS);
    expect(css.length).toBeGreaterThan(10);
    expect(ui.length).toBeGreaterThan(20);
  });

  it("layers come from the --z tokens", () => {
    const bad = declarations().filter(d => d.file !== TOKENS && d.prop === "z-index" && /^-?\d+\s*(!important)?$/.test(d.val));
    expect(bad.map(show)).toEqual([]);
  });

  it("durations and curves come from the motion tokens", () => {
    const bad = declarations().filter(d => {
      if (d.file === TOKENS) return false;
      // a curve may be defined as a token anywhere (--glide in nav.css), never written into a rule
      if (!isDef(d.prop) && /cubic-bezier\(|steps\(\s*\d+\s*,/.test(d.val)) return true;
      if (!/^(transition|animation)(-|$)/.test(d.prop)) return false;
      // 0s is "no delay", not a duration
      return /(?<![\w.-])(\d*\.?\d+)(ms|s)\b/.test(d.val.replace(/(?<![\w.-])0m?s\b/g, ""));
    });
    expect(bad.map(show)).toEqual([]);
  });

  it("weights are the design's: 400, 550 and 650, and 500 for the keypad's digits, always through --w tokens", () => {
    const tokens = css.find(([f]) => f === TOKENS)![1];
    const weights = Object.fromEntries([...tokens.matchAll(/(--w-[\w-]+)\s*:\s*(\d+)/g)].map(m => [m[1]!, +m[2]!]));
    expect(weights).toEqual({ "--w-regular": 400, "--w-key": 500, "--w-mid": 550, "--w-bold": 650 });
    const bad = declarations().filter(d => d.file !== TOKENS && !d.prop.startsWith("--w-") && (
      (/^font-weight$|^--[\w-]*weight$/.test(d.prop) && /(?<![\w-])\d{3}(?![\w%])/.test(d.val)) ||
      (d.prop === "font" && /^\d{3}\s/.test(d.val))));
    expect(bad.map(show)).toEqual([]);
  });

  it("colours come from tokens: no raw colour outside a token definition", () => {
    const bad = declarations().filter(d => d.file !== TOKENS && !isDef(d.prop) && RAW_COLOR.test(d.val)
      && !COLOR_ALLOWED.some(a => a.file === d.file && a.sel.test(d.sel)));
    expect(bad.map(show)).toEqual([]);
  });

  it("every colour token has a dark value", () => {
    const tokens = css.find(([f]) => f === TOKENS)![1].replace(/\/\*[\s\S]*?\*\//g, "");
    const light = tokens.match(/^:root\{([^}]*)\}/m)![1]!;
    const darkMedia = tokens.match(/:root:not\(\[data-theme="light"\]\)\{([^}]*)\}/)![1]!;
    const darkAttr = tokens.match(/:root\[data-theme="dark"\]\{([^}]*)\}/)![1]!;
    const names = (block: string, colorsOnly: boolean) => new Set([...block.matchAll(/(--[\w-]+)\s*:\s*([^;]+)/g)]
      .filter(m => !colorsOnly || RAW_COLOR.test(m[2]!)).map(m => m[1]!));
    // the picture roles (--c0, --c1, --c2, --acc) are recoloured for dark per grade in bands.css
    const colours = [...names(light, true)].filter(n => !["--c0", "--c1", "--c2", "--acc"].includes(n));
    // --ok, --busy, --err, --score3, --score0, --on-tint read on both themes (bands.css lifts --on-tint on .wrap)
    const sameEverywhere = ["--ok", "--busy", "--err", "--on-tint", "--score3", "--score0"];
    const missing = colours.filter(n => !sameEverywhere.includes(n) && !(names(darkMedia, false).has(n) && names(darkAttr, false).has(n)));
    expect(missing).toEqual([]);
  });

  it("screens style through classes, not inline colours or font sizes", () => {
    const bad = ui.flatMap(([f, t]) => t.split("\n").map((line, i) => ({ line, i }))
      .filter(({ line }) => /style=\{\{/.test(line) && (RAW_COLOR.test(line) || /\bfontSize\s*:|\bfontWeight\s*:|\bzIndex\s*:/.test(line)))
      .map(({ i }) => `${f}:${i + 1}`));
    expect(bad).toEqual([]);
  });

  it("the stylesheets are tokenized: scripts/tokenize.mjs has nothing left to change", async () => {
    const script = new URL("../../../scripts/tokenize.mjs", import.meta.url).pathname;
    const { tokenize } = (await import(/* @vite-ignore */ script)) as { tokenize(css: string): string };
    const left = css.filter(([f]) => f !== TOKENS && f !== FONTS).filter(([, t]) => tokenize(t) !== t).map(([f]) => f);
    expect(left).toEqual([]);
  });
});
