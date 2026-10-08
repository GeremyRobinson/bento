import { describe, expect, it } from "vitest";
import { KNOWN } from "./masters-known";

/**
 * Everything is built from the five masters (design-philosophy.md): Panel, Row, Accordion, Pill, Picture, plus the
 * hub's tile on the bento grid. Only a master says what a corner, a gap, a fill or a button looks like; every other
 * rule takes those from the masters' tokens (G 2026-10-08: "why does design insist on not using the masters?").
 * A page that sets its own corner, gap, fill or button look fails here with the file, the rule and what to use instead.
 *
 * KNOWN lists what was already off the masters when this check came in (2026-10-08). It may only shrink: when you
 * move a rule onto a master, delete its line there. A new entry is never the fix.
 */
const fsName = "node:fs";
const fs = (await import(/* @vite-ignore */ fsName)) as { readFileSync(p: URL, enc: "utf8"): string };
const read = (m: Record<string, unknown>) => Object.keys(m).filter(f => !f.includes("/tests/") && !f.includes("/sandbox/") && !f.startsWith("./"))
  .map(f => [f.replace("../../", ""), fs.readFileSync(new URL(f, import.meta.url), "utf8")] as [string, string]);
const css = read(import.meta.glob("../../**/*.css"));
const ui = read(import.meta.glob(["../../app/**/*.tsx", "../../components/**/*.tsx", "../../screens/**/*.tsx"]));

/** where the values are defined, and the Picture master's own sheets */
const SKIP = new Set(["styles/tokens.css", "styles/fonts.css", "styles/diagram-master.css", "styles/area-model.css"]);

/** the masters' own classes and their states: a rule made only of these is the master itself */
const MASTER = new Set([
  // Pill
  "ctl", "go", "circ", "badged", "sm",
  // Row
  "srow", "sname", "sles", "chap", "sdot", "slist", "smeta", "chev", "badge", "on", "done", "soon", "snext", "none",
  // Accordion (ListGroup)
  "sgroup", "sgroup-body", "sgroup-in", "sgroup-panel", "open", "opening",
  // the hub's tile on the bento grid
  "tile", "mtile", "k", "bgrid", "bg-in", "bg-t", "n", "s", "t", "w", "l", "f", "fit",
  // Picture
  "viz", "viz-svg", "am", "rs",
]);
/** the subject and every ancestor are master classes (elements, pseudo-classes and attributes don't count) */
const isMaster = (sel: string) => {
  const classes = sel.replace(/:{1,2}[\w-]+(\([^)]*\))?/g, "").replace(/\[[^\]]*\]/g, "").match(/\.[\w-]+/g) ?? [];
  return classes.length > 0 && classes.every(c => MASTER.has(c.slice(1)));
};
/** a picture draws inside .viz/.viz-svg: the Picture master's business */
const inPicture = (sel: string) => /\.(viz-svg|viz|am|rs)\b/.test(sel);

/** a selector list split at its top-level commas */
const parts = (sel: string) => {
  const out: string[] = []; let depth = 0, cur = "";
  for (const c of sel) { if (c === "(") depth++; if (c === ")") depth--; if (c === "," && !depth) { out.push(cur.trim()); cur = ""; } else cur += c; }
  return [...out, cur.trim()].filter(Boolean);
};
function rules() {
  const out: { file: string; sel: string; prop: string; val: string }[] = [];
  for (const [file, text] of css) {
    if (SKIP.has(file)) continue;
    for (const m of text.replace(/\/\*[\s\S]*?\*\//g, "").matchAll(/([^{}]*)\{([^{}]*)\}/g)) {
      const sel = m[1]!.trim();
      if (sel.startsWith("@") || /^(from|to|[\d.]+%)(\s*,\s*([\d.]+%|from|to))*$/.test(sel)) continue; // keyframes
      for (const d of m[2]!.split(";")) {
        const i = d.indexOf(":");
        if (i > 0) out.push({ file, sel, prop: d.slice(0, i).trim(), val: d.slice(i + 1).replace(/!important/, "").trim() });
      }
    }
  }
  return out;
}

/** what each kind of value may be, and where it comes from */
const KINDS: { kind: string; prop: RegExp; ok: RegExp; use: string }[] = [
  {
    kind: "corner", prop: /^border(-(top|bottom|start|end)-(left|right|start|end))?-radius$/,
    ok: /^(0|inherit|initial|unset)$|var\(--(r-panel|r-row|r-card|r-box|r-pill|r-round|rbadge)\)/,
    use: "a corner from the nest: --r-panel, --r-row, --r-card, --r-box, or --r-pill/--r-round",
  },
  {
    kind: "gap", prop: /^(row-|column-)?gap$/,
    ok: /^(0|normal|inherit)$|^var\(--(nest|screen-gap|list-gap|pill-gap)\)$/,
    use: "--nest (8px inside a panel) or --screen-gap (16px between panels)",
  },
  {
    kind: "fill", prop: /^background(-color)?$/,
    ok: /^(none|transparent|inherit|initial|unset|0)$|^var\(--(g[1-4]|pane-plain|pane-glass|page|tint|ok|err)\)$/,
    use: "the glass ladder (--g1 to --g4, --pane-plain, --pane-glass), --tint, or --ok/--err for answers",
  },
];

/** every rule outside a master that sets its own corner, gap or fill */
function offCss() {
  const out: { key: string; val: string; use: string }[] = [];
  for (const d of rules()) {
    if (d.prop.startsWith("--")) continue;
    const k = KINDS.find(x => x.prop.test(d.prop));
    if (!k || k.ok.test(d.val)) continue;
    for (const p of parts(d.sel)) {
      if (isMaster(p) || inPicture(p)) continue;
      out.push({ key: `${d.file} | ${p} | ${d.prop}`, val: d.val, use: k.use });
    }
  }
  return out;
}

/** a raw <button> that isn't the Pill or a Row: it brings its own button look */
function offButtons() {
  const out: { key: string; val: string; use: string }[] = [];
  for (const [file, text] of ui) {
    if (file.endsWith("primitives/Pill.tsx")) continue;
    for (const m of text.matchAll(/<button\b[^>]*?className=(?:"([^"]*)"|\{`([^`]*)`\}|\{([^}]*)\})/g)) {
      const cls = (m[1] ?? m[2] ?? m[3] ?? "").replace(/\$\{[^}]*\}/g, " ").trim();
      const words: string[] = cls.match(/[\w-]+/g) ?? [];
      if (words.includes("srow") || words.includes("ctl")) continue;
      out.push({ key: `${file} | <button class="${words[0] ?? ""}">`, val: cls, use: "the Pill (or a Row, for a row you tap)" });
    }
  }
  return out;
}

const fmt = (o: { key: string; val: string; use: string }) => `${o.key}: ${o.val.slice(0, 50)}  →  use ${o.use}`;

describe("the masters own corners, gaps, fills and buttons", () => {
  it("found the stylesheets and the screens", () => {
    expect(css.length).toBeGreaterThan(10);
    expect(ui.length).toBeGreaterThan(20);
  });

  it("no new rule sets its own corner, gap or fill outside a master", () => {
    const known = new Set(KNOWN);
    expect(offCss().filter(o => !known.has(o.key)).map(fmt)).toEqual([]);
  });

  it("no new raw button outside the Pill and Row", () => {
    const known = new Set(KNOWN);
    expect(offButtons().filter(o => !known.has(o.key)).map(fmt)).toEqual([]);
  });

  it("catches a page that rounds its own card or styles its own button", () => {
    // the check itself: My Obento's card with its own big corner, a page's gap, a raw fill, a page re-styling the Pill
    const sample = [
      { sel: ".mytile", prop: "border-radius", val: "28px" },
      { sel: ".mytile", prop: "gap", val: "6px" },
      { sel: ".mytile", prop: "background", val: "var(--card)" },
      { sel: ".mytile .ctl", prop: "border-radius", val: "var(--r-lg)" },
    ];
    for (const s of sample) {
      const k = KINDS.find(x => x.prop.test(s.prop))!;
      expect(!k.ok.test(s.val) && !isMaster(s.sel)).toBe(true);
    }
    expect(isMaster(".srow.chap.on .sname")).toBe(true);
    expect(isMaster(".ctl.go:hover")).toBe(true);
    expect(KINDS[0]!.ok.test("calc(var(--r-panel) - var(--nest))")).toBe(true);
  });
});

/** for the known list: `npx vitest run src/tests/styles/masters.test.ts` with MASTERS_LIST=1 prints every current offender */
if ((globalThis as { process?: { env: Record<string, string | undefined> } }).process?.env.MASTERS_LIST) {
  const all = [...offCss(), ...offButtons()];
  console.log(JSON.stringify([...new Set(all.map(o => o.key))].sort(), null, 1));
  console.log(all.map(fmt).join("\n"));
}
