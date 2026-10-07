import { describe, expect, it } from "vitest";

/**
 * Review's manual sweeps, as checks: things a stylesheet can get wrong that only show on one grade, one size or one
 * setting. Each failure names the file and the rule. Layout checks that need a real browser (clipping, a Panel line
 * without its corner, a page that scrolls) live in the smoke run, scripts/smoke.mjs.
 */
const fsName = "node:fs";
const fs = (await import(/* @vite-ignore */ fsName)) as { readFileSync(p: URL, enc: "utf8"): string };
const read = (m: Record<string, unknown>) => Object.keys(m).filter(f => !f.includes("/tests/") && !f.includes("/sandbox/") && !f.startsWith("./"))
  .map(f => [f.replace("../../", ""), fs.readFileSync(new URL(f, import.meta.url), "utf8")] as [string, string]);
const css = read(import.meta.glob("../../**/*.css"));
const ui = read(import.meta.glob(["../../**/*.tsx"]));

/** a selector list split at its top-level commas */
const parts = (sel: string) => {
  const out: string[] = []; let depth = 0, cur = "";
  for (const c of sel) { if (c === "(") depth++; if (c === ")") depth--; if (c === "," && !depth) { out.push(cur.trim()); cur = ""; } else cur += c; }
  return [...out, cur.trim()].filter(Boolean);
};
function rules() {
  const out: { file: string; sel: string; prop: string; val: string }[] = [];
  for (const [file, text] of css) {
    for (const m of text.replace(/\/\*[\s\S]*?\*\//g, "").matchAll(/([^{}]*)\{([^{}]*)\}/g)) {
      for (const d of m[2]!.split(";")) {
        const i = d.indexOf(":");
        if (i > 0) out.push({ file, sel: m[1]!.trim(), prop: d.slice(0, i).trim(), val: d.slice(i + 1).trim() });
      }
    }
  }
  return out;
}
const show = (d: { file: string; sel: string; prop: string; val: string }) => `${d.file}: ${d.sel.slice(-60)} { ${d.prop}:${d.val.slice(0, 60)} }`;

/** the diagrams' own palette: colourful per grade, never in the UI chrome */
const PALETTE = /var\(--(acc|ka|l1|l2|la)\b/;
/** where a diagram draws: anything under these is a picture, not chrome */
const PICTURE = /\.(viz-svg|viz|am|rs)\b/;
/** the rule styles something inside a picture: a picture class on the element itself or an ancestor, never a sibling
 *  (`.am ~ .x` is next to the picture, not in it) */
const inPicture = (sel: string) => {
  const bits = sel.split(/\s*([>+~])\s*|\s+/).filter(b => b !== undefined && b !== "");
  // bits alternate compound, combinator; a bare space between compounds is the descendant combinator
  const comp: string[] = [], comb: string[] = [];
  for (const b of bits) if (/^[>+~]$/.test(b)) comb[comp.length - 1] = b; else { if (comp.length && comb[comp.length - 1] === undefined) comb[comp.length - 1] = " "; comp.push(b); }
  return comp.some((c, i) => PICTURE.test(c) && comb.slice(i).every(k => k === " " || k === ">"));
};
const PALETTE_SHEETS = ["styles/bands.css", "styles/diagram-master.css"];
const PALETTE_ALLOWED: { sel: RegExp; why: string }[] = [
  { sel: /^\.mline mark$/, why: "the highlighted part of a math line points into the diagram beside it" },
];

describe("stylesheet structure", () => {
  it("the diagram palette stays in diagrams", () => {
    // custom properties too: `--pill-bg:var(--acc)` on a button would carry the palette into the chrome
    const bad = rules().filter(d => PALETTE.test(d.val) && !PALETTE_SHEETS.includes(d.file))
      .filter(d => !/^(from|to|[\d.]+%)$/.test(d.sel) && parts(d.sel).some(s => !inPicture(s) && !PALETTE_ALLOWED.some(a => a.sel.test(s))));
    expect(bad.map(show)).toEqual([]);
    const tsx = ui.flatMap(([f, t]) => t.split("\n").map((line, i) => ({ f, line, i })))
      .filter(({ f, line }) => PALETTE.test(line) && !f.includes("/diagrams/") && !/Confetti|confetti/.test(line) && !line.includes("cols = "))
      .map(({ f, line, i }) => `${f}:${i + 1}: ${line.trim().slice(0, 80)}`);
    expect(tsx).toEqual([]);
  });

  it("a page-level token that reads --rule or --muted is set again on .wrap, so grades get their own hue", () => {
    const all = rules();
    const onRoot = (sel: string) => parts(sel).every(s => /^(:root|html)(\[[^\]]*\]|:not\([^)]*\))*$/.test(s));
    const onWrap = new Set(all.filter(d => d.prop.startsWith("--") && parts(d.sel).some(s => /(^|\s)\.wrap$/.test(s))).map(d => d.prop));
    const bad = all.filter(d => d.prop.startsWith("--") && onRoot(d.sel) && /var\(--(rule|muted)\b/.test(d.val) && !onWrap.has(d.prop));
    expect(bad.map(show)).toEqual([]);
  });

  it("each view-transition-name is used once", () => {
    const names = rules().filter(d => d.prop === "view-transition-name" && d.val !== "none" && !d.val.startsWith("var("));
    const seen = new Map<string, string[]>();
    for (const d of names) seen.set(d.val, [...(seen.get(d.val) ?? []), show(d)]);
    expect([...seen.values()].filter(v => v.length > 1)).toEqual([]);
  });

  it("Less motion stops ::before and ::after too", () => {
    const global = rules().filter(d => /^(animation|transition)(-duration)?$/.test(d.prop))
      .filter(d => parts(d.sel).some(s => /^(\*|:root\[data-motion="reduce"\] \*)$/.test(s)));
    expect(global.length).toBeGreaterThan(1);
    const bad = global.filter(d => !(parts(d.sel).some(s => s.endsWith("*::before")) && parts(d.sel).some(s => s.endsWith("*::after"))));
    expect(bad.map(show)).toEqual([]);
  });
});
