import { frac, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeRow } from "../../../../explanations/diagrams/tape/schema";
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

/** One bar per whole. Beat 1 cuts the first into d pieces of 1/d; beat 2 cuts the rest and counts every piece. */
export function unitDivisionPicture({ W, d }: UnitDivisionProblem) {
  const rows: TapeRow[] = Array.from({ length: W }, (_, j): TapeRow => ({
    length: 1, parts: [{ count: 1, from: 0 }, { count: d, from: j === 0 ? 1 : 2 }], fills: [{ a: 0, b: 1, tone: "on" }],
    each: [{ text: () => `1/${d}`, from: j === 0 ? 1 : 2 }], label: [{ text: "1" }],
    total: j === 0 ? [{ text: `${d}`, from: 1, acc: W === 1 }] : [{ text: `${(j + 1) * d}`, from: 2, acc: j === W - 1 }],
  }));
  return buildTape({ rows, alt: `${W} whole bars, each cut into ${count(d, "piece")} of 1/${d}: ${count(W * d, "piece")} in all.` });
}

function explain(p: UnitDivisionProblem, model: AnswerModel): Explanation {
  const { W, d } = p, one = expectedOf(model.steps, "one"), all = expectedOf(model.steps, "all");
  return {
    heading: "How many pieces fit?",
    idea: ["Dividing by 1/4 asks how many quarters fit, and 4 quarters fit in every whole.", "So the answer is the number of wholes times the pieces in each whole."],
    statement: [num(W), op("÷"), frac(1, d)],
    diagram: unitDivisionPicture(p),
    caption: `${count(W, "whole")}, ${d} ${pieceName(d)} in each: ${W * d} ${pieceName(d)}.`,
    timeline: beats(3),
    steps: [
      { id: "one", state: 1, answerStep: "one", result: one, math: [num(1), op("="), num(one), op("×"), frac(1, d)],
        narration: `Cut one whole into ${pieceName(d)}: it holds ${count(one, "piece")} of 1/${d}.` },
      { id: "all", state: 2, answerStep: "all", result: all, math: [num(W), op("×"), num(one), op("="), num(all)],
        narration: `${count(W, "whole")} hold ${W} × ${one} = ${count(all, "piece")}, so ${W} ÷ 1/${d} = ${all}.` },
    ],
  };
}

export const lesson: LessonDefinition<UnitDivisionProblem> = {
  id: "g5-unitdiv",
  grade: 5,
  unit: "Fractions",
  title: "Dividing by a unit fraction",
  pre: "g5-fracof",
  // the current app's card and picture: 3 ÷ 1/4 = 12
  reference: createUnitDivision(3, 4),
  generate: (rng, index) => generateUnitDivision(rng, index),
  restore: raw => {
    const r = ints(raw, ["W", "d"] as const);
    try { return r && createUnitDivision(r.W, r.d); } catch { return null; }
  },
  display: (p): MathText => [num(p.W), op("÷"), frac(1, p.d)],
  displayNote: p => `How many 1/${count(p.d, "piece")} fit in ${p.W}?`,
  answers,
  explain,
  story: ({ W, d }) => ({ op: "÷", text: `You have **${W}** cups of flour. Each batch of cookies uses 1/${d} cup. How many batches can you make?` }),
};
