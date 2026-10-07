import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildRadians } from "../../../../explanations/diagrams/circle/build";
import { asRecord, expected, gcd, mt, ns, numberField, piText } from "../../_geometry/kit";
import { count } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** An angle of nπ/d radians to write in degrees. */
export interface RadiansToDegreesProblem {
  kind: "trig.radiansToDegrees";
  n: number;
  d: number;
}

export function createRadiansToDegrees(n: number, d: number): RadiansToDegreesProblem {
  if (![n, d].every(v => Number.isInteger(v) && v > 0) || gcd(n, d) !== 1 || n >= 2 * d) throw new Error("nπ/d in lowest terms, less than a full turn");
  return { kind: "trig.radiansToDegrees", n, d };
}

export function restoreRadiansToDegrees(raw: unknown): RadiansToDegreesProblem | null {
  const r = asRecord(raw), n = r && numberField(r, "n"), d = r && numberField(r, "d");
  if (n == null || d == null) return null;
  try { return createRadiansToDegrees(n, d); } catch { return null; }
}

export function radiansToDegreesAnswers({ n, d }: RadiansToDegreesProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "piece", label: "One piece", prompt: s => mt`180° ÷ ${d} = ${s}°`, ans: 180 / d, hint: "π is 180°, so split 180 into the bottom number of pieces.", wrong: [[180 * d, "Multiplied", `π/${d} is 180° split into ${d} pieces: divide.`]] }),
      ns({ id: "degrees", label: "Times the top", prompt: s => mt`${n} × ${180 / d}° = ${s}°`, ans: (180 * n) / d, hint: `The top says how many of those pieces: ${n} of them.`, wrong: [[180 / d + n, "Added", `${count(n, "piece")} of ${180 / d}° each: multiply.`]] }),
    ],
    finalParts: [-1],
  };
}

export function explainRadiansToDegrees({ n, d }: RadiansToDegreesProblem, answers: AnswerModel): Explanation {
  const piece = expected(answers, "piece"), deg = expected(answers, "degrees");
  return {
    heading: "π = 180°",
    idea: ["π radians is a half turn, which is 180°."],
    statement: mt`${piText(n, d)} = ?°`,
    caption: `Each π/${d} is ${piece}°. ${n === 1 ? "One of them" : `${n} of them`}: ${deg}°.`,
    diagram: buildRadians({
      t: deg, piece, pieceBeat: 1, angleBeat: 2,
      pieceNote: `π/${d} = 180° ÷ ${d} = ${piece}°`,
      answerNote: `${n} × ${piece}° = ${deg}°`,
      alt: `A circle with the half turn, π, cut into ${count(d, "piece")} of ${piece}°. ${piText(n, d)} covers ${n} of them: ${deg}°.`,
    }),
    timeline: beats(3),
    steps: [
      { id: "half-turn", narration: `π is a half turn, 180°. The angle ${piText(n, d)} is ${n} piece${n === 1 ? "" : "s"} of π/${d}.`, math: mt`π = 180°`, state: 0 },
      { id: "piece", narration: `Split the half turn into ${d} equal pieces: 180° ÷ ${d} = ${piece}°.`, math: mt`180° ÷ ${d} = ${piece}°`, state: 1, answerStep: "piece", result: piece },
      { id: "degrees", narration: `Take ${n} of those pieces: ${n} × ${piece}° = ${deg}°.`, math: mt`${n} × ${piece}° = ${deg}°`, state: 2, answerStep: "degrees", result: deg },
    ],
  };
}

export const lesson: LessonDefinition<RadiansToDegreesProblem> = withEasyStart({
  id: "g12-deg",
  grade: 12,
  unit: "Trigonometry",
  title: "Radians to degrees",
  pre: "g12-rad",
  reference: createRadiansToDegrees(5, 6),
  generate: rng => {
    let n: number, d: number;
    do { d = rng.pick([2, 3, 4, 6]); n = rng.int(1, 2 * d - 1); } while (gcd(n, d) !== 1);
    return createRadiansToDegrees(n, d);
  },
  restore: restoreRadiansToDegrees,
  display: p => (p.n === 1 ? mt`π/${p.d}` : mt`${p.n}π/${p.d}`),
  displayNote: () => "Write it in degrees.",
  answers: radiansToDegreesAnswers,
  explain: explainRadiansToDegrees,
});
