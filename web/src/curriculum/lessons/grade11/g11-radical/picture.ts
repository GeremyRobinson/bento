// The g11-radical picture (Curriculum fixes-02, Part B): a square root is the side of a square. √(x + a) = b says the
// square with side b has area x + a, so its b × b unit squares are the + a and the x together. Built on the area grid.
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import type { SceneDiagram, SceneItem } from "../../../../explanations/diagrams/scene/schema";
import { r1 } from "../../../../explanations/diagrams/scene/helpers";
import { formatNumber as f } from "../../../schemas/math-text";
import { count } from "../../../text";

/** Grade 11's parts: the + a in the first colour, x in the third (blue). */
const PA = "p0", PX = "p2";

export function radicalEquationPicture(o: { a: number; b: number; sq: number; x: number }): SceneDiagram {
  const { a, b, sq, x } = o;
  const s = Math.min(60, 240 / b), pm = `${a < 0 ? "−" : "+"} ${Math.abs(a)}`;
  // what lies outside the square: x's extra squares when a is negative, or the + a spilling over when x is below 0
  const outside = a < 0 ? -a : Math.max(0, a - sq);
  const lines = [
    { text: `√(x ${pm}) = ${b}, so the area is x ${pm}`, from: 0, until: 0 },
    { text: `side ${b}, area ${b} × ${b}`, from: 1, until: 1 },
    { text: `x ${pm} = ${sq}`, from: 2, until: 2 },
    a < 0
      ? { text: `x is ${-a} more than ${sq}`, from: 3, until: 3, cls: `lbl ${PX}` }
      : x > 0 ? { text: `${a} of the ${sq} squares are the ${pm}`, from: 3, until: 3, cls: `lbl ${PA}` }
        : x === 0 ? { text: `the ${pm} fills the whole square`, from: 3, until: 3, cls: `lbl ${PA}` }
          : { text: `the ${pm} is ${outside} more than ${sq}`, from: 3, until: 3, cls: `lbl ${PA}` },
    { text: `x = ${sq} ${a < 0 ? "+" : "−"} ${Math.abs(a)} = ${f(x)}`, from: 3, until: 3 },
    { text: `√(${f(x)} ${pm}) = √${sq} = ${b}`, from: 4 },
  ];
  const d = buildAreaGrid({
    family: "area-model",
    cols: [{ label: `${b}`, size: b }],
    rows: [{ label: `${b}`, size: b }],
    cells: [[null]],
    outlineFrom: 0,
    maxWidth: s * b,
    maxHeight: s * b,
    lines,
    alt: `A square with side ${b} has area ${sq}, which is x ${pm}. ${a > 0 ? `Take away ${count(a, "square")} for the + ${a}` : `Add ${count(-a, "square")} for the − ${-a}`}: x = ${f(x)}.`,
  });
  const g = d.geometry, x0 = g.left, y0 = g.top, u = g.width / b;
  const items: SceneItem[] = [
    { type: "text", x: r1(x0 + g.width / 2), y: r1(y0 + g.height / 2), text: `area x ${pm}`, cls: "lbl p0", from: 0, until: 0, enter: "rise", delay: 0.3 },
  ];
  const sqAt = (k: number, ox: number, rows: number): [number, number] => [ox + Math.floor(k / rows) * u, y0 + (k % rows) * u];
  // beat 1: the unit squares sweep in, row by row
  for (let k = 0; k < sq; k++) {
    const [cx, cy] = [x0 + (k % b) * u, y0 + Math.floor(k / b) * u];
    const box = { type: "rect" as const, x: r1(cx + 1.5), y: r1(cy + 1.5), w: r1(u - 3), h: r1(u - 3), rx: 3 };
    items.push({ ...box, cls: `xbox ${PX}`, from: 1, until: 2, enter: "pop", delay: r1(0.1 + (1.2 * k) / sq) });
    // beat 3: the first a of them are the + a, the rest are x
    const isA = a > 0 && k < a;
    items.push({ ...box, cls: `xchip ${isA ? PA : PX}`, from: 3, enter: "fade", delay: r1(0.2 + (0.8 * k) / sq) });
  }
  // beat 3: the squares outside the square, in columns beside it: x's extra ones, or the + a's overflow struck out
  const ox = x0 + g.width + 14;
  for (let k = 0; k < outside; k++) {
    const [cx, cy] = sqAt(k, ox, b);
    const box = { type: "rect" as const, x: r1(cx + 1.5), y: r1(cy + 1.5), w: r1(u - 3), h: r1(u - 3), rx: 3 };
    const delay = r1(1.1 + 0.15 * k);
    items.push({ ...box, cls: `xbox ${a < 0 ? PX : PA} dash`, from: 3, enter: "pop", delay });
    if (a > 0) items.push({ type: "line", x1: r1(cx + 2), y1: r1(cy + u - 2), x2: r1(cx + u - 2), y2: r1(cy + 2), cls: "ln2", from: 3, enter: "draw", delay: r1(delay + 0.4) });
  }
  // beat 4: the side is read back
  items.push({ type: "rect", x: r1(x0 - 3), y: r1(y0 - 3), w: r1(g.width + 6), h: r1(u + 6), rx: 6, cls: "hlline", from: 4, enter: "fade", delay: 0.2 });
  const right = outside ? ox + Math.ceil(outside / b) * u + 14 : 0;
  return { ...d, width: r1(Math.max(d.width, right)), items: [...d.items, ...items] };
}
