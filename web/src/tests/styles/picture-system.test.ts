import { describe, expect, it } from "vitest";
import { lessonsInGrade } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { PIC } from "../../explanations/diagrams/scene/picture-system";
import type { DiagramModel } from "../../explanations/schema";

/**
 * The picture system (styles/picture-system.css): every role a lesson picture can name resolves to a picture token,
 * so no picture shows the grade accent, cyan, teal, red or green (Review's colour gate K2, K4-K6; G 2026-10-13
 * "there needs to be a system"). A role mapped to anything else, a colour rule reading a role the system doesn't map,
 * or a 5th grade picture drawing a class that paints a real-world colour fails here.
 */
const fsName = "node:fs";
const fs = (await import(/* @vite-ignore */ fsName)) as { readFileSync(p: URL, enc: "utf8"): string };
const read = (m: Record<string, unknown>) => Object.keys(m).filter(f => !f.includes("/tests/") && !f.includes("/sandbox/") && !f.startsWith("./"))
  .map(f => [f.replace("../../", ""), fs.readFileSync(new URL(f, import.meta.url), "utf8")] as [string, string]);
const css = read(import.meta.glob("../../**/*.css"));
const SYSTEM = css.find(([f]) => f === "styles/picture-system.css")?.[1] ?? "";
const strip = (t: string) => t.replace(/\/\*[\s\S]*?\*\//g, "");
const rules = (t: string) => [...strip(t).matchAll(/([^{}]*)\{([^{}]*)\}/g)].map(m => ({
  sel: m[1]!.trim(),
  decls: Object.fromEntries(m[2]!.split(";").map(d => { const i = d.indexOf(":"); return i > 0 ? [d.slice(0, i).trim(), d.slice(i + 1).trim()] : null; }).filter((x): x is [string, string] => !!x)),
}));
const ON_PICTURE = "#app :is(.viz-svg,.am,.viz,.dotrow,.bb,.tf)";

/** the tokens a picture may paint with: the picture palette, the neutral base, and the system's own names for them */
const PICTURE_TOKEN = /^var\(--(pic-deep|pic-mid|pic-soft|pic-seatc|pic-line|pic-on-mid|pic-on-part|pic-on-step|v-ink|v-muted|v-line|v-done|v-key|v-card|deep|tint|soft|pic-outline)\)$/; // --tint, --soft and --deep are the part's own (mapped above)
/** every role a picture rule reads (diagram-master.css), and what it must resolve to on a picture. Fills are the 30% soft
    fill whether a part is done or waiting; only the step's part (.lit) is mid (lesson picture style guide, G 2026-10-14) */
const ROLES: Record<string, RegExp> = {
  "--tint": /pic-soft/, "--c0": /pic-soft/, "--c1": /pic-soft/, "--c2": /pic-soft/,
  "--k0": /pic-deep/, "--k1": /pic-deep/, "--k2": /pic-deep/, "--ink": /pic-deep/, "--deep": /pic-deep/, "--lbl": /--deep/,
  "--acc": /pic-deep/, "--soft-acc": /pic-soft/, "--ka": /v-ink/, "--text": /v-ink/, "--on-pic": /pic-deep/, "--on-tint": /pic-deep/,
  "--fill0": /pic-soft/, "--fill1": /pic-soft/, "--fill2": /pic-soft/, "--soft": /pic-soft/, "--soft0": /pic-soft/, "--soft1": /pic-soft/, "--soft2": /pic-soft/,
  "--tint-soft": /pic-soft/, "--dot": /pic-soft/, "--muted": /v-muted/, "--rule": /v-line/, "--faint": /v-done/, "--well": /v-key/, "--card": /v-card/,
};
/** real-world colours (coins, water, marbles): allowed in their own lessons, never in 5th grade's */
const REAL_WORLD = /var\(--d-(water|marble|copper|silver|coin)/;
/** the 5th grade lessons that tell two quantities apart (the second fraction, a fraction of a fraction) */
const TWO = new Set(["add", "sub", "mix", "g5-multfrac"]);

describe("the picture system", () => {
  it("maps every picture role to a picture token, with the accent and the old cyan answer colour mapped away", () => {
    const pic = rules(SYSTEM).find(r => r.sel === ON_PICTURE);
    expect(pic, "picture-system.css maps the roles on the picture itself").toBeTruthy();
    const bad = Object.entries(ROLES).filter(([role, want]) => !pic!.decls[role] || !want.test(pic!.decls[role]!) || !/^var\(--[\w-]+\)$/.test(pic!.decls[role]!))
      .map(([role]) => `${role}: ${pic!.decls[role] ?? "(not mapped)"}`);
    expect(bad).toEqual([]);
    for (const v of Object.values(pic!.decls)) if (v.startsWith("var(--") && !/--(lbl|deep)\b/.test(v)) expect(v).toMatch(/^var\(--(pic|v)-/);
  });

  it("draws a second amount in stripes of the same colour, only on a picture that opts in with .two", () => {
    // style guide rule 5 (G 2026-10-14): one colour; the second amount is striped, its outline the same deep
    const two = rules(SYSTEM).filter(r => /\.two\b/.test(r.sel));
    expect(two.length).toBeGreaterThan(0);
    for (const r of two) for (const [k, v] of Object.entries(r.decls)) {
      // (the problem line above a .two picture writes its second amount in the deep text colour: words can't be striped)
      if (/^--(c1|fill1|soft1)$/.test(k) && !r.sel.includes(":has(")) expect(v).toBe("url(#pic-stripe)");
      if (k === "--k1") expect(v).toMatch(/pic-deep/);
    }
    // nowhere else in the system does a role go violet
    // (a grade setting its own partner hue, --picb-* = --gN-picb-*, is the token itself, not a role going violet)
    for (const r of rules(SYSTEM).filter(r => !/\.two\b/.test(r.sel))) for (const [k, v] of Object.entries(r.decls)) if (!/^--picb-/.test(k)) expect(v, r.sel).not.toMatch(/picb-/);
  });

  it("paints parts and text only with picture tokens", () => {
    for (const r of rules(SYSTEM)) for (const [k, v] of Object.entries(r.decls)) {
      if (!/^(fill|stroke)$/.test(k) || /^(none|transparent)$/.test(v)) continue;
      expect(v, `${r.sel} { ${k} }`).toMatch(PICTURE_TOKEN);
    }
  });

  it("every colour rule a picture can hit reads only roles the system maps", () => {
    const known = new Set([...Object.keys(ROLES), "--pic-deep", "--pic-mid", "--pic-soft", "--pic-seatc", "--pic-line", "--picb-deep", "--picb-mid", "--picb-soft", "--pic-on-mid", "--pic-on-part", "--pic-on-step",
      "--v-ink", "--v-muted", "--v-line", "--v-done", "--v-key", "--v-card", "--v-acc", "--mix-lift", /* a solid's dark side, overridden by the system */ "--d-shadow", "--l0", "--l1", "--l2", "--la"]);
    const bad: string[] = [];
    for (const [f, t] of css) for (const r of rules(t)) {
      if (!/\.(viz-svg|am|viz)\b/.test(r.sel)) continue;
      for (const [k, v] of Object.entries(r.decls)) {
        if (!/^(fill|stroke|color)$/.test(k) || REAL_WORLD.test(v)) continue;
        for (const m of v.matchAll(/var\((--[\w-]+)/g)) if (!known.has(m[1]!) && !m[1]!.startsWith("--d-f")) bad.push(`${f}: ${r.sel.slice(0, 50)} { ${k}: ${m[1]} }`);
      }
    }
    expect([...new Set(bad)]).toEqual([]);
  });

  it("holds every line weight on screen inside a picture, so a tablet's zoom never thickens lines (Review 26fe1f8)", () => {
    const master = css.find(([f]) => f === "styles/diagram-master.css")?.[1] ?? "";
    const weights = [...strip(master).matchAll(/--dw-([\w-]+):/g)].map(m => m[1]!);
    expect(weights.length).toBeGreaterThan(5);
    const held = rules(SYSTEM).find(r => r.sel.includes("svg:is(.viz-svg,.am)"))?.decls ?? {};
    expect(held["--sw"]).toBe("min(1, var(--px, 1))");
    // --d-line is the outline inside a picture, held through --pic-outline
    for (const w of weights.filter(w => w !== "line")) expect(held[`--d-${w}`], w).toBe(`calc(var(--dw-${w}) * var(--sw))`);
    expect(held["--pic-outline"]).toBe("calc(var(--pic-outline-w) * var(--sw))");
  });

  // the outline is written once (--pic-outline-w); --pic-outline is that weight held on screen inside a picture
  it("keeps the CSS spacing tokens and the builders' numbers the same", () => {
    const app = rules(SYSTEM).find(r => r.sel === "#app")!.decls;
    expect([app["--pic-gap-area"], app["--pic-gap-bar"], app["--pic-gap-mixed"], app["--pic-label-gap"], app["--pic-label"], app["--pic-outline-w"]])
      .toEqual([`${PIC.gap.area}px`, `${PIC.gap.bar}px`, `${PIC.gap.mixed}px`, `${PIC.labelGap}px`, `${PIC.label}px`, `${PIC.outline}px`]);
  });

  it("5th grade pictures draw no real-world colour, and only two-quantity lessons turn violet", () => {
    // classes whose rules paint a real-world colour, read from the stylesheets
    const realWorld = new Set<string>();
    for (const [, t] of css) for (const r of rules(t)) if (/\.viz-svg/.test(r.sel) && Object.values(r.decls).some(v => REAL_WORLD.test(v)))
      for (const m of r.sel.replace(/\.viz-svg/g, "").matchAll(/\.([\w-]+)/g)) realWorld.add(m[1]!);
    expect(realWorld.size).toBeGreaterThan(0);
    const bad: string[] = [];
    for (const l of lessonsInGrade(5)) {
      if (l.id === "g5-mult2") continue; // the Design lead's lesson, on its own area model
      for (const p of [l.reference, ...Array.from({ length: 8 }, (_, i) => l.generate(createRng(i + 1), i))]) {
        const ds: (DiagramModel | undefined)[] = [l.explain(p, l.answers(p)).diagram, l.picture?.(p)];
        for (const d of ds) {
          if (d?.kind !== "scene") continue;
          if (d.two && !TWO.has(l.id)) bad.push(`${l.id}: two`);
          for (const it of d.items) for (const c of (it.cls ?? "").split(/\s+/)) if (realWorld.has(c) && !/^(c[0-2]|ring|on|cut|big|top|left|right)$/.test(c)) bad.push(`${l.id}: ${c}`);
        }
      }
    }
    expect([...new Set(bad)]).toEqual([]);
  });
});
