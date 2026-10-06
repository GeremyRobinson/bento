import { formatNumber as f } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation, type ExplanationStep } from "../../../../explanations/schema";
import { buildRightTriangle } from "../../../../explanations/diagrams/right-triangle/build";
import { asRecord, expected, ms, mt, ns, numberField } from "../../_geometry/kit";
import { withEasyStart } from "../../easy-start";

/** A 45-45-90 triangle with leg s, or a 30-60-90 triangle with short leg s. */
export interface SpecialTriangleProblem {
  kind: "geometry.specialRightTriangle";
  t: 45 | 30;
  s: number;
}

export function createSpecialTriangle(t: number, s: number): SpecialTriangleProblem {
  if (t !== 45 && t !== 30) throw new Error("the triangle is 45-45-90 or 30-60-90");
  if (!Number.isInteger(s) || s <= 0) throw new Error("the leg is a positive whole number");
  return { kind: "geometry.specialRightTriangle", t, s };
}

export function restoreSpecialTriangle(raw: unknown): SpecialTriangleProblem | null {
  const r = asRecord(raw);
  const t = r && numberField(r, "t"), s = r && numberField(r, "s");
  if (t == null || s == null) return null;
  try { return createSpecialTriangle(t, s); } catch { return null; }
}

export function specialTriangleAnswers({ t, s }: SpecialTriangleProblem): AnswerModel {
  const steps = t === 45 ? [
    ms({ id: "hyp", label: "Hypotenuse", prompt: S => mt`${S.c!}√${S.r!}`, ans: { c: s, r: 2 }, hint: "Half a square: leg² + leg² is two leg²'s. Take the square root: the leg comes out in front, and what stays under the root?",
      wrong: [[{ c: 2 * s, r: 1 }, "Doubled the leg", "Doubling is for the 30-60-90 hypotenuse. These legs are equal, so use √2."], [{ c: s, r: 3 }, "Used √3", "√3 belongs to 30-60-90."]] }),
  ] : [
    ns({ id: "hyp", label: "Hypotenuse", prompt: x => mt`2 × ${s} = ${x}`, ans: 2 * s, hint: `This triangle is half of an equilateral triangle, so the hypotenuse is a whole side: 2 × ${s}.`,
      wrong: [[s, "Used the short leg", "The short leg is half a side of the equilateral triangle; the hypotenuse is a whole side."]] }),
    ms({ id: "long", label: "Long leg", prompt: S => mt`${S.c!}√${S.r!}`, ans: { c: s, r: 3 }, hint: `Long leg² = hypotenuse² − short leg² = (2 × ${s})² − ${s}², which is three of ${s}². Take the square root: ${s} comes out in front.`,
      wrong: [[{ c: s, r: 2 }, "Used √2", "√2 is for 45-45-90 triangles. 30-60-90 uses √3."], [{ c: 2 * s, r: 3 }, "Used the hypotenuse", `Use the short leg, not the hypotenuse: ${s}√3.`]] }),
  ];
  return { steps, finalParts: [-1] };
}

export function explainSpecialTriangle(p: SpecialTriangleProblem, answers: AnswerModel): Explanation {
  const { t, s } = p;
  if (t === 45) {
    const c = expected(answers, "hyp", "c"), r = expected(answers, "hyp", "r");
    const steps: ExplanationStep[] = [
      { id: "triangle", narration: `Both legs of a 45°-45°-90° triangle are the same: ${s} and ${s}. Two of these triangles make a square, cut along its diagonal.`, math: mt`45°-45°-90°, leg ${s}`, state: 0 },
      { id: "hyp", narration: `The hypotenuse is the square's diagonal: ${s}² + ${s}² = 2 × ${s}², so it is ${s} × √${r} = ${f(c)}√${r}.`, math: mt`${s} × √${r} = ${c}√${r}`, state: 1, answerStep: "hyp" },
    ];
    return {
      heading: "Half a square, half an equilateral triangle",
      idea: ["A 45-45-90 triangle is half a square. Its legs match, so leg² + leg² = 2 × leg², and the hypotenuse is leg × √2.", "A 30-60-90 triangle is half an equilateral triangle. The short leg is half a side, so the hypotenuse is twice it, and the Pythagorean theorem makes the long leg short leg × √3."],
      statement: mt`45°-45°-90°, leg ${s}`,
      caption: `Legs ${s} and ${s}: the hypotenuse is ${s}√2.`,
      diagram: buildRightTriangle({
        a: s, b: s,
        sides: { a: { text: String(s) }, b: { text: String(s) }, c: [{ text: "?", acc: true, until: 0 }, { text: `${s}√2`, acc: true, from: 1 }] },
        angles: [{ at: "B", text: "45°", acc: false }, { at: "C", text: "45°", acc: false }],
        hl: [{ side: "c", from: 1 }],
        alt: `A right triangle with two legs of ${s} and two 45° angles; its hypotenuse is ${s}√2.`,
      }),
      timeline: beats(2),
      steps,
    };
  }
  const hyp = expected(answers, "hyp");
  const long = expected(answers, "long", "c");
  return {
    heading: "Half a square, half an equilateral triangle",
    idea: ["A 45-45-90 triangle is half a square. Its legs match, so leg² + leg² = 2 × leg², and the hypotenuse is leg × √2.", "A 30-60-90 triangle is half an equilateral triangle. The short leg is half a side, so the hypotenuse is twice it, and the Pythagorean theorem makes the long leg short leg × √3."],
    statement: mt`30°-60°-90°, short leg ${s}`,
    caption: `Short leg ${s}: the hypotenuse is ${hyp} and the long leg is ${s}√3.`,
    diagram: buildRightTriangle({
      // drawn exactly: the long leg is √3 times the short one
      a: s, b: s * Math.sqrt(3),
      sides: {
        a: { text: String(s) },
        b: [{ text: "?", acc: true, until: 1 }, { text: `${long}√3`, acc: true, from: 2 }],
        c: [{ text: "?", acc: true, until: 0 }, { text: String(hyp), acc: true, from: 1 }],
      },
      angles: [{ at: "B", text: "30°", acc: false }, { at: "C", text: "60°", acc: false }],
      hl: [{ side: "c", from: 1, until: 1 }, { side: "b", from: 2 }],
      alt: `A 30°-60°-90° right triangle with short leg ${s}, hypotenuse ${hyp} and long leg ${s}√3.`,
    }),
    timeline: beats(3),
    steps: [
      { id: "triangle", narration: `In a 30°-60°-90° triangle the short leg, ${s}, is across from the 30° angle. Flip it over the long leg: together they make an equilateral triangle, all sides ${hyp}.`, math: mt`30°-60°-90°, short leg ${s}`, state: 0 },
      { id: "hyp", narration: `The short leg is half of a side of that equilateral triangle, and the hypotenuse is a whole side: 2 × ${s} = ${hyp}.`, math: mt`2 × ${s} = ${hyp}`, state: 1, answerStep: "hyp", result: hyp },
      { id: "long", narration: `By the Pythagorean theorem, long leg² = ${hyp}² − ${s}² = 3 × ${s}², so the long leg is ${long}√3.`, math: mt`${s} × √3 = ${long}√3`, state: 2, answerStep: "long" },
    ],
  };
}

export const lesson: LessonDefinition<SpecialTriangleProblem> = withEasyStart({
  id: "g10-special",
  grade: 10,
  unit: "Right triangles and trig",
  title: "Special right triangles",
  reference: createSpecialTriangle(45, 5),
  generate: rng => { const t = rng.next() < 0.5 ? 45 : 30; return createSpecialTriangle(t, rng.int(2, 12)); },
  restore: restoreSpecialTriangle,
  display: p => (p.t === 45 ? mt`45°-45°-90°, leg ${p.s}` : mt`30°-60°-90°, short leg ${p.s}`),
  displayNote: p => (p.t === 45 ? "Find the hypotenuse." : "Find the hypotenuse and the long leg."),
  answers: specialTriangleAnswers,
  explain: explainSpecialTriangle,
});
