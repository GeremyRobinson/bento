// Area of a sector and arc length: the same three steps (fraction of the turn, the whole, that fraction of it).
import { formatNumber as f, frac, sup } from "../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../schemas/lesson";
import type { Rng } from "../../generators/rng";
import { beats, type Explanation } from "../../../explanations/schema";
import { buildSector } from "../../../explanations/diagrams/circle/build";
import { asRecord, expected, fracText, fs, gcd, mt, ns, numberField, round6 } from "./kit";

export interface CirclePartProblem {
  kind: "geometry.sector" | "geometry.arc";
  /** angle in degrees */
  t: number;
  r: number;
}

export const CIRCLE_PART_ANGLES = [90, 180, 270, 60, 120, 45] as const;

/** Same as the current app: radii that keep the answer to a few decimals. */
export function generateCirclePart(rng: Rng): { t: number; r: number } {
  const t = rng.pick(CIRCLE_PART_ANGLES);
  return { t, r: t % 90 ? (t === 45 ? 2 * rng.int(1, 5) : 3 * rng.int(1, 3)) : rng.int(2, 10) };
}

const make = (kind: CirclePartProblem["kind"]) => (t: number, r: number): CirclePartProblem => {
  if (!(t > 0 && t < 360) || !(r > 0)) throw new Error("angle between 0 and 360, radius positive");
  return { kind, t, r };
};

function restore(kind: CirclePartProblem["kind"]) {
  return (raw: unknown): CirclePartProblem | null => {
    const rec = asRecord(raw);
    const t = rec && numberField(rec, "t"), r = rec && numberField(rec, "r");
    if (t == null || r == null) return null;
    try { return make(kind)(t, r); } catch { return null; }
  };
}

function answers({ kind, t, r }: CirclePartProblem): AnswerModel {
  const g = gcd(t, 360), part = frac(t / g, 360 / g);
  const first = fs({ id: "fraction", label: "Fraction of the circle", prompt: s => mt`${t} ÷ 360 = ${s}`, N: t, D: 360, hint: `A full turn is 360°, so the slice is ${t} parts out of 360. Divide top and bottom by the same number.`,
    wrong: [[t, 180, "Used a half turn", "A full turn is 360°, not 180°."]] });
  if (kind === "geometry.sector") {
    const A = round6(3.14 * r * r);
    return {
      steps: [
        first,
        ns({ id: "whole", label: "Whole circle", prompt: s => mt`3.14 × ${r}${sup("2")} = ${s}`, ans: A, hint: `A circle's area is π × r × r: 3.14 × ${r} × ${r}.`, wrong: [[round6(3.14 * 2 * r), "Squared as times 2", `r² means ${r} × ${r}.`]] }),
        ns({ id: "part", label: "The slice", prompt: s => mt`${part} × ${A} = ${s}`, ans: round6((A * t) / 360), hint: "The slice is that fraction of the whole circle, so multiply the area by it.", wrong: [[round6(A * 360 / t), "Divided by the fraction", "The slice is smaller than the circle: multiply by the fraction."]] }),
      ],
      finalParts: [-1],
    };
  }
  const C = round6(2 * 3.14 * r);
  return {
    steps: [
      first,
      ns({ id: "whole", label: "Whole circumference", prompt: s => mt`2 × 3.14 × ${r} = ${s}`, ans: C, hint: "The distance around a circle is 2 × π × r.", wrong: [[round6(3.14 * r), "Used the radius alone", "Circumference is 2 × π × r."]] }),
      ns({ id: "part", label: "The arc", prompt: s => mt`${part} × ${C} = ${s}`, ans: round6((C * t) / 360), hint: "The arc is that fraction of the way around, so multiply the circumference by it.", wrong: [[round6(C * 360 / t), "Divided by the fraction", "The arc is shorter than the way around: multiply by the fraction."]] }),
    ],
    finalParts: [-1],
  };
}

function explain(p: CirclePartProblem, model: AnswerModel): Explanation {
  const sector = p.kind === "geometry.sector", { t, r } = p;
  const n = expected(model, "fraction", "n"), d = expected(model, "fraction", "d");
  const whole = expected(model, "whole"), part = expected(model, "part");
  const fr = fracText(n, d);
  return {
    heading: sector ? "A fraction of the circle" : "A fraction of the circumference",
    idea: sector ? ["A sector is a slice of the circle, so its area is that share of the whole circle."] : ["An arc is a slice of the edge, so its length is that share of the circumference."],
    statement: sector ? mt`${frac(t, 360)} × 3.14 × ${r}${sup("2")}` : mt`${frac(t, 360)} × 2 × 3.14 × ${r}`,
    caption: `${t}° is ${fr} of the circle, so the ${sector ? "slice" : "arc"} is ${fr} of ${f(whole)}: ${f(part)}.`,
    diagram: buildSector({
      mode: sector ? "sector" : "arc", r, t, fraction: fr, whole, part, pi: "3.14", fractionBeat: 1, wholeBeat: 2, partBeat: 3,
      alt: `A circle of radius ${r} with a ${t}° ${sector ? "slice" : "arc"}: ${fr} of the circle. The whole ${sector ? "area" : "circumference"} is ${f(whole)}, so the ${sector ? "slice" : "arc"} is ${f(part)}.`,
    }),
    timeline: beats(4),
    steps: [
      { id: "circle", narration: `A circle with radius ${r}, and a ${sector ? "slice" : "piece of the edge"} with an angle of ${t}°.`, math: mt`r = ${r}, ${t}°`, state: 0 },
      { id: "fraction", narration: `A full turn is 360°, so ${t}° is ${t}/360 = ${fr} of the circle.`, math: mt`${frac(t, 360)} = ${frac(n, d)}`, state: 1, answerStep: "fraction", result: n },
      sector
        ? { id: "whole", narration: `The whole circle's area is 3.14 × ${r} × ${r} = ${f(whole)}.`, math: mt`3.14 × ${r}${sup("2")} = ${whole}`, state: 2, answerStep: "whole", result: whole }
        : { id: "whole", narration: `The whole way around is 2 × 3.14 × ${r} = ${f(whole)}.`, math: mt`2 × 3.14 × ${r} = ${whole}`, state: 2, answerStep: "whole", result: whole },
      { id: "part", narration: `Take ${fr} of it: ${f(part)}.`, math: mt`${frac(n, d)} × ${whole} = ${part}`, state: 3, answerStep: "part", result: part },
    ],
  };
}

export function circlePartLesson(kind: CirclePartProblem["kind"], meta: { id: string; title: string; pre?: string; reference: [number, number]; note: string }): LessonDefinition<CirclePartProblem> {
  const create = make(kind);
  return {
    id: meta.id,
    grade: 10,
    unit: "Circles",
    title: meta.title,
    ...(meta.pre ? { pre: meta.pre } : {}),
    reference: create(...meta.reference),
    generate: rng => { const { t, r } = generateCirclePart(rng); return create(t, r); },
    restore: restore(kind),
    display: p => mt`radius ${p.r}, angle ${p.t}°`,
    displayNote: () => meta.note,
    answers,
    explain,
  };
}
