import { frac, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeRow } from "../../../../explanations/diagrams/tape/schema";
import type { SceneItem } from "../../../../explanations/diagrams/scene/schema";
import { lightSteps } from "../../../../explanations/diagrams/scene/helpers";
import { expectedOf, ints, ns, pieceName, round6 } from "../../_tape-family/steps";
import { count } from "../../../text";

/** W ÷ 1/d: how many pieces of size 1/d fit in W wholes. */
export interface UnitDivisionProblem { W: number; d: number }

export function createUnitDivision(W: number, d: number): UnitDivisionProblem {
  if (![W, d].every(Number.isInteger) || W < 1 || d < 2) throw new Error(`not a unit-fraction division: ${W} ÷ 1/${d}`);
  return { W, d };
}

/** Same ranges as the current app: 2–10 wholes, pieces of 1/2 to 1/8. */
// the first three: a few wholes cut into halves, thirds or fourths
export const generateUnitDivision = (rng: Rng, index = 3) => (index < 3 ? createUnitDivision(rng.int(2, 4), rng.int(2, 4)) : createUnitDivision(rng.int(2, 10), rng.int(2, 8)));

function answers({ W, d }: UnitDivisionProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "one", l: "Pieces in one whole", q: `How many 1/${count(d, "piece")} make 1 whole?`, a: s => s, ans: d, h: "Look at one whole bar and count the pieces in it.",
        w: [[d - 1, "Counted the cuts", "Count the pieces, not the cut lines between them."]] }),
      ns({ id: "all", l: "Pieces in all", a: s => [num(W), op("×"), num(d), op("="), ...s], ans: W * d, h: `${count(W, "whole")}, ${count(d, "piece")} in each.`,
        w: [[round6(W / d), "Divided the wrong way", `The pieces are small, so lots of them fit. The answer is bigger than ${W}.`]] }),
    ],
    finalParts: [-1],
  };
}

/**
 * The beat each whole is cut and counted on (Review g5 #6: 8, 12 and the answer arrived in one beat). The first whole is
 * cut on beat 1 (d pieces in one whole), the second on beat 2 (the count goes on: 2d), and the rest on beat 3, one whole
 * after another, the running count landing on each; the answer comes only after the last count.
 */
export const wholeBeat = (j: number) => Math.min(j + 1, 3);
/** seconds between one whole and the next when several are counted on the same beat */
const NEXT_WHOLE = 0.5;

/** One bar per whole, each cut into d pieces of 1/d and counted on in turn (wholeBeat). */
export function unitDivisionPicture({ W, d }: UnitDivisionProblem) {
  const rows: TapeRow[] = Array.from({ length: W }, (_, j): TapeRow => ({
    length: 1, parts: [{ count: 1, from: 0 }, { count: d, from: wholeBeat(j) }], fills: [{ a: 0, b: 1, tone: "on" }],
    each: [{ text: () => `1/${d}`, from: wholeBeat(j) }], label: [{ text: "1" }],
    total: [{ text: `${(j + 1) * d}`, from: wholeBeat(j), acc: j === W - 1 }],
  }));
  const tape = buildTape({ square: true, rows, gap: "mixed", alt: `${W} whole bars, each cut into ${count(d, "piece")} of 1/${d}: ${count(W * d, "piece")} in all.` });
  // the wholes that share the last beat are counted one after another, top to bottom: each part of a bar waits its turn
  const rowLabels = tape.items.filter((i): i is Extract<SceneItem, { type: "text" }> => i.type === "text" && i.text === "1" && !i.from).map(i => i.y);
  // the worked step lit (the shared `lit` role): the whole being cut and its running count, on the beat it is counted
  const lit = (items: SceneItem[]) => lightSteps(items, it => ((it.from ?? 0) > 0 && (it.type === "rect" || (it.type === "text" && /^\d+$/.test(it.text))) ? [it.from!] : null), wholeBeat(W - 1));
  if (W <= 3 || rowLabels.length !== W) return { ...tape, items: lit(tape.items) };
  const rowOf = (y: number) => rowLabels.reduce((best, ry, k) => (Math.abs(ry - y) < Math.abs(rowLabels[best]! - y) ? k : best), 0);
  const midY = (i: SceneItem): number => {
    switch (i.type) {
      case "rect": return i.y + i.h / 2;
      case "line": return (i.y1 + i.y2) / 2;
      case "circle": return i.cy;
      case "text": return i.y;
      case "polygon": return i.points.reduce((s, p) => s + p[1], 0) / i.points.length;
      case "path": { const n = i.d.match(/-?[\d.]+/g)?.map(Number) ?? [0]; const ys = n.filter((_, k) => k % 2 === 1); return ys.reduce((s, v) => s + v, 0) / Math.max(1, ys.length); }
    }
  };
  return {
    ...tape,
    items: lit(tape.items.map(i => (i.from === 3 ? { ...i, delay: Math.round(((i.delay ?? 0) + (rowOf(midY(i)) - 2) * NEXT_WHOLE) * 100) / 100 } : i))),
  };
}

function explain(p: UnitDivisionProblem, model: AnswerModel): Explanation {
  const { W, d } = p, one = expectedOf(model.steps, "one"), all = expectedOf(model.steps, "all");
  return {
    heading: "How many pieces fit?",
    idea: ["Dividing by a unit fraction asks how many of those pieces fit."],
    statement: [num(W), op("÷"), frac(1, d)],
    diagram: unitDivisionPicture(p),
    caption: `${count(W, "whole")}, ${d} ${pieceName(d)} in each: ${W * d} ${pieceName(d)}.`,
    timeline: beats(wholeBeat(W - 1) + 1),
    steps: [
      { id: "one", state: 1, answerStep: "one", result: one, math: [num(1), op("="), num(one), op("×"), frac(1, d)],
        narration: `Cut one whole into ${pieceName(d)}.` },
      { id: "all", state: wholeBeat(W - 1), answerStep: "all", result: all, math: [num(W), op("×"), num(one), op("="), num(all)],
        narration: `Every whole holds ${one}, so count them all.` },
    ],
  };
}

export const lesson: LessonDefinition<UnitDivisionProblem> = {
  id: "g5-unitdiv",
  grade: 5,
  unit: "Fractions",
  title: "Dividing by a unit fraction",
  pre: "g3-unitfrac",
  // the current app's card and picture: 3 ÷ 1/4 = 12
  reference: createUnitDivision(3, 4),
  generate: (rng, index) => generateUnitDivision(rng, index),
  restore: raw => {
    const r = ints(raw, ["W", "d"] as const);
    try { return r && createUnitDivision(r.W, r.d); } catch { return null; }
  },
  display: (p): MathText => [num(p.W), op("÷"), frac(1, p.d)],
  answers,
  explain,
  story: ({ W, d }) => ({ op: "÷", text: `You have **${W}** cups of flour. Each batch of cookies uses 1/${d} cup. How many batches can you make?` }),
};
