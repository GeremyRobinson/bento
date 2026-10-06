import { describe, expect, it } from "vitest";

/**
 * Colours only ever come from tokens that have a dark value. Two ways a picture has gone black on a dark card:
 * a rule reads a token nobody defines (v41 dropped --ka, so "= 0.45" fell back to SVG's default black), and a
 * picture or its stylesheet sets a raw colour. Both fail here.
 */
// file names from Vite's glob; text straight from disk (Vitest doesn't load stylesheets, so ?raw CSS comes back empty)
const fsName = "node:fs";
const fs = (await import(/* @vite-ignore */ fsName)) as { readFileSync(p: URL, enc: "utf8"): string };
const read = (m: Record<string, unknown>) => Object.keys(m).filter(f => !f.includes("/tests/") && !f.startsWith("./"))
  .map(f => [f, fs.readFileSync(new URL(f, import.meta.url), "utf8")] as [string, string]);
const css = read(import.meta.glob("../../**/*.css"));
const code = read(import.meta.glob(["../../**/*.ts", "../../**/*.tsx"]));
const RAW = /#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(|\b(black|white)\b/;

describe("colour tokens", () => {
  it("every token a stylesheet reads without a fallback is defined somewhere", () => {
    const all = [...css, ...code].map(([, t]) => t).join("\n");
    // defined in a stylesheet, or set inline from code (style={{ "--gc": … }}, setProperty("--x", …))
    const defined = new Set([...all.matchAll(/(--[\w-]+)["'`]?\s*:|["'`](--[\w-]+)["'`]/g)].map(m => (m[1] ?? m[2])!));
    const missing: string[] = [];
    for (const [f, t] of css) {
      for (const m of t.matchAll(/var\((--[\w-]+)\s*\)/g)) {
        if (!defined.has(m[1]!)) missing.push(`${f.replace("../../", "")}: ${m[1]}`);
      }
    }
    expect([...new Set(missing)]).toEqual([]);
  });

  it("picture builders never set a raw colour", () => {
    const builders = code.filter(([f]) => /explanations\/diagrams|components\/diagrams/.test(f));
    expect(builders.length).toBeGreaterThan(20);
    const bad = builders.flatMap(([f, t]) => t.split("\n")
      .map((line, i) => ({ line: line.replace(/\/\/.*$|\/\*.*?\*\/|^\s*\*.*$/g, ""), i }))
      .filter(({ line }) => /\b(fill|stroke|color|vars)\b|--[\w-]+["']?\s*:/.test(line) && RAW.test(line.replace(/["'`][^"'`]*\bwhite (space|board)[^"'`]*["'`]/g, "")))
      .map(({ i }) => `${f.replace("../../", "")}:${i + 1}`));
    expect(bad).toEqual([]);
  });

  it("picture rules in the stylesheets paint with tokens, not raw colours", () => {
    const bad: string[] = [];
    for (const [f, t] of css) {
      const text = t.replace(/\/\*[\s\S]*?\*\//g, "");
      for (const m of text.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
        const sel = m[1]!, body = m[2]!;
        if (!/\.(viz-svg|viz|am|dotrow|bb|tf)\b/.test(sel)) continue;
        for (const d of body.split(";")) {
          const [prop, val] = d.split(":").map((s: string) => s.trim());
          // token definitions (--d-copper:#c77b4a) are where raw colours belong; painting must go through them
          if (prop && !prop.startsWith("--") && /^(fill|stroke|color|background(-color)?|stop-color)$/.test(prop) && val && RAW.test(val.replace(/var\([^)]*\)/g, "")) && !/color-mix/.test(val))
            bad.push(`${f.replace("../../", "")}: ${sel.trim().slice(0, 60)} { ${prop}: ${val} }`);
        }
      }
    }
    expect(bad).toEqual([]);
  });
});
