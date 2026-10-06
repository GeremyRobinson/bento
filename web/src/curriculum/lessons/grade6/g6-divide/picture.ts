// The g6-divide picture (Curriculum fixes-02, Part B): a/b ÷ c/d asks how many c/d pieces fit in a/b. Two fraction
// bars, each one whole long; cut both into b·d small pieces and a/b is a·d of them, c/d is b·c of them; then copies
// of the c/d stretch, laid end to end under a/b, measure it: S/L copies. Built on the tape, like g5-unitdiv.
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeFill, TapeRow } from "../../../../explanations/diagrams/tape/schema";
import type { SceneDiagram, SceneItem } from "../../../../explanations/diagrams/scene/schema";

/** Grade 6's second part colour is lime (too close to "right"), so the second fraction takes its third, orange. */
const SECOND = "p2";

export function divideFractionsPicture(o: { a: number; b: number; c: number; d: number; S: number; L: number; mixed: string }): SceneDiagram {
  const { a, b, c, d, S, L, mixed } = o;
  const A = a / b, C = c / d, whole = Math.floor(S / L), part = S % L;
  const n = whole + (part ? 1 : 0);
  // copies of c/d laid end to end under a/b; the last one is cut short when it does not fit
  const copies: TapeFill[] = Array.from({ length: n }, (_, k) => ({
    a: k * C, b: Math.min((k + 1) * C, A), tone: part && k === n - 1 ? "acc" : "two", from: 3,
  }));
  const ticks = [{ count: b * d, from: 2 }];
  const rows: TapeRow[] = [
    { length: 1, parts: b, ticks, fills: [{ a: 0, b: A, tone: "on" }], label: [{ text: `${a}/${b}` }] },
    { length: 1, parts: d, ticks, fills: [{ a: 0, b: C, tone: "two" }], label: [{ text: `${c}/${d}` }] },
    { length: A, parts: 1, fills: copies, from: 3, label: [{ text: "copies", from: 3 }] },
  ];
  const d0 = buildTape({
    rows,
    brackets: [
      { row: 1, a: 0, b: 1, text: `1 ÷ ${c}/${d} = ${d}/${c}`, side: "above", from: 1, until: 1 },
      { row: 0, a: 0, b: A, text: `${a * d} small pieces`, side: "below", from: 2, until: 2 },
      { row: 1, a: 0, b: C, text: `${b * c} small pieces`, side: "above", from: 2, until: 2 },
      { row: 2, a: 0, b: A, text: `${S}/${L} = ${mixed} ${S < L ? "of a copy" : S === L ? "copy" : "copies"}`, side: "below", from: 3, acc: true },
    ],
    // beat 0 compares the sizes: the end of a/b against the c/d bar
    guides: [{ at: A, rows: [0, 1], from: 0 }, { at: A, rows: [0, 2], from: 3 }],
    alt: `${a}/${b} ÷ ${c}/${d}: cut both bars into ${b * d} small pieces; ${a}/${b} is ${a * d} of them and ${c}/${d} is ${b * c}. ${n === 1 && part ? "Less than one copy" : `${whole} whole ${whole === 1 ? "copy" : "copies"}${part ? " and part of one more" : ""}`} of ${c}/${d} fit in ${a}/${b}: ${mixed}.`,
  });
  // the second fraction's colour, and every other copy in a lighter shade of it so neighbours read apart
  let k = 0;
  const items = d0.items.map((it): SceneItem => {
    // the first fraction names its part colour, so the bar never takes a tint from around the picture
    if (it.type === "rect" && it.cls === "seg on") return { ...it, cls: "seg on p0" };
    if (it.type !== "rect" || !/\bseg on p1\b/.test(it.cls ?? "")) return it;
    const copy = (it.from ?? 0) === 3;
    const light = copy && k++ % 2 === 1;
    return { ...it, cls: (it.cls ?? "").replace(/\bp1\b/, SECOND), ...(light ? { vars: { "--tint": "color-mix(in srgb, var(--c2) 55%, var(--card))" } } : {}) };
  });
  // the small-piece ticks stay visible across a shaded stretch
  const shaded = items.filter((i): i is Extract<SceneItem, { type: "rect" }> => i.type === "rect" && /\bseg on\b/.test(i.cls ?? ""));
  const ticked = items.map((it): SceneItem => {
    if (it.type !== "line" || it.cls !== "tk") return it;
    const on = shaded.some(r => (r.from ?? 0) <= (it.from ?? 0) && it.x1 > r.x && it.x1 < r.x + r.w && it.y1 > r.y && it.y1 < r.y + r.h);
    return on ? { ...it, cls: "tk on" } : it;
  });
  // a copy cut short: a dashed outline shows the whole copy it is part of
  const bar = items.find((i): i is Extract<SceneItem, { type: "rect" }> => i.type === "rect" && i.cls === "seg" && i.from === 3);
  if (part && bar) {
    const u = bar.w / A, x = bar.x + (n - 1) * C * u;
    ticked.splice(ticked.indexOf(bar), 0, { type: "rect", x: Math.round(x * 10) / 10, y: bar.y, w: Math.round(C * u * 10) / 10, h: bar.h, rx: bar.rx ?? 0, cls: "pend", from: 3, enter: "fade", delay: 0.6 });
  }
  return { ...d0, items: ticked };
}
