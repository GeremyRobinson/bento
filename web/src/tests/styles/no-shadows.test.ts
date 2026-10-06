import { describe, expect, it } from "vitest";

/**
 * No shadows anywhere (G 2026-10-06): what floats shows its edge with an outline, and what's picked or active shows
 * with its fill and outline. A box-shadow may only be a ring (no offset, no blur); text never has a shadow.
 */
const fsName = "node:fs";
const fs = (await import(/* @vite-ignore */ fsName)) as { readFileSync(p: URL, enc: "utf8"): string };
const css = Object.keys(import.meta.glob("../../**/*.css")).filter(f => !f.includes("/tests/") && !f.startsWith("./"))
  .map(f => [f.replace("../../", ""), fs.readFileSync(new URL(f, import.meta.url), "utf8")] as [string, string]);

/** a value's layers, split on the commas outside brackets */
const layers = (v: string) => { const out: string[] = []; let d = 0, cur = ""; for (const ch of v) { if (ch === "(") d++; if (ch === ")") d--; if (ch === "," && !d) { out.push(cur.trim()); cur = ""; } else cur += ch; } if (cur.trim()) out.push(cur.trim()); return out; };
/** a ring: a colour and four lengths of which the first three are 0 */
const isRing = (l: string) => {
  const t = l.replace(/\binset\b/, "").replace(/(rgba?|color-mix|var|calc)\((?:[^()]|\([^()]*\))*\)/g, "").trim();
  if (!t) return true;
  const n = [...t.matchAll(/(-?[\d.]+)(?:px)?/g)].map(m => Number(m[1]));
  return n.length >= 3 && n[0] === 0 && n[1] === 0 && n[2] === 0;
};

describe("no shadows", () => {
  it("every box-shadow, and every shadow token, is a ring at most", () => {
    const bad: string[] = [];
    for (const [f, s] of css) for (const m of s.matchAll(/(box-shadow|--[\w-]*shadow)\s*:\s*([^;}]+)/g)) {
      if (m[1] === "--d-shadow") continue; // a diagram's shading colour, not a shadow
      for (const l of layers(m[2]!)) if (l !== "none" && !l.startsWith("var(") && !isRing(l)) bad.push(`${f}: ${m[1]}:${l}`);
    }
    expect(bad).toEqual([]);
  });
  it("no text-shadow or drop-shadow", () => {
    const bad = css.flatMap(([f, s]) => [...s.matchAll(/text-shadow\s*:\s*(?!none)[^;}]+|drop-shadow\([^)]*\)/g)].map(m => `${f}: ${m[0]}`));
    expect(bad).toEqual([]);
  });
});
