import { num, op, sub, sup, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildPlane } from "../../../../explanations/diagrams/plane/build";
import { attempt, expected, f, ints, ns, supText } from "../../_plane/kit";
import { count } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** a, a·r, a·r², … and the term number n we want. */
export interface GeoProblem { kind: "sequence.geometric"; a: number; r: number; n: number }

export function createGeo(a: number, r: number, n: number): GeoProblem {
  if (a < 1 || r < 2 || n < 2) throw new Error("a positive start, a ratio of 2 or more, and a later term");
  return { kind: "sequence.geometric", a, r, n };
}

/** a 1..5, r 2 or 3, n 5..8 (the first four terms are already shown, so the asked-for term never is). */
export const generateGeo = (rng: Rng) => createGeo(rng.int(1, 5), rng.pick([2, 3]), rng.int(5, 8));

export function restoreGeo(raw: unknown): GeoProblem | null {
  const v = ints(raw, ["a", "r", "n"] as const);
  return v && attempt(() => createGeo(v.a, v.r, v.n));
}

const first4 = ({ a, r }: GeoProblem) => [0, 1, 2, 3].map(k => a * r ** k);
export const geoMath = (p: GeoProblem): MathText => [text(`${first4(p).join(", ")}, …`)];
const term = (n: number): MathText => [text("a"), sub(n)];

export function geoAnswers({ a, r, n }: GeoProblem): AnswerModel {
  const pw = r ** (n - 1);
  return {
    steps: [
      ns({ id: "r", label: "Common ratio", prompt: s => [text("r"), op("="), num(a * r), op("÷"), num(a), op("="), ...s], ans: r,
        hint: "Divide a term by the one before it.", wrong: [[a * r - a, "Subtracted instead of divided", "Geometric sequences multiply. Divide to find the ratio."]] }),
      ns({ id: "jumps", label: "Count the jumps", question: `From term 1 to term ${n}, how many jumps?`, prompt: s => s, ans: n - 1,
        hint: `You start on term 1, so getting to term ${n} takes one jump fewer than ${n}.`, wrong: [[n, "Off by one", `You start on term 1, so it's ${n} minus 1, which is ${count(n - 1, "jump")}.`]] }),
      ns({ id: "pow", label: "Ratio to the power", prompt: s => [num(r), sup(n - 1), op("="), ...s], ans: pw,
        hint: `Multiply ${count(n - 1, "copy", "copies")} of ${r}.`, wrong: [[r * (n - 1), "Multiplied instead of a power", `${r}${supText(n - 1)} means ${r} times itself ${n - 1} times.`]] }),
      ns({ id: "term", label: "Times the first term", prompt: s => [...term(n), op("="), num(a), op("×"), num(pw), op("="), ...s], ans: a * pw,
        hint: "Start at the first term and multiply it by the growth from all the jumps.", wrong: [[a + pw, "Added", "The first term grows by the whole factor: multiply."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainGeo(p: GeoProblem, model: AnswerModel): Explanation {
  const { a, n } = p, r = expected(model, "r"), pw = expected(model, "pow"), an = expected(model, "term");
  const terms = Array.from({ length: n }, (_, i) => a * r ** i);
  return {
    heading: "aₙ = a₁ · rⁿ⁻¹",
    idea: ["The ratio is the same every time, so term n is the first term times the ratio, n − 1 times."],
    statement: geoMath(p),
    caption: `Each term is ${r === 2 ? "double" : "triple"} the one before: term ${n} is ${f(a)} × ${f(r)}${supText(n - 1)} = ${f(an)}.`,
    diagram: buildPlane({
      alt: `Graph: the terms ${terms.map(f).join(", ")} plotted against their term numbers 1 to ${n}, growing by × ${f(r)}.`,
      fit: [[0, 0], [n + 0.5, an]],
      items: [
        { kind: "curve", f: x => a * r ** (x - 1), x0: 1, x1: n, cls: "ln2 dash", from: 3 },
        ...terms.map((t, i) => ({
          kind: "point" as const, at: [i + 1, t] as const, cls: i === n - 1 ? ("dota" as const) : ("dotp" as const),
          from: i < 4 ? 0 : 3, delay: i * 0.15,
          label: { text: f(t), acc: i === n - 1, optional: i !== n - 1 && i !== 0, prefer: ["n"] as "n"[] },
        })),
      ],
    }),
    timeline: beats(4),
    steps: [
      { id: "terms", narration: `The sequence starts ${first4(p).map(f).join(", ")}. Find term ${n}.`, math: geoMath(p), state: 0 },
      { id: "r", narration: `Divide a term by the one before it: ${f(a * r)} ÷ ${f(a)} = ${f(r)}. Each jump multiplies by ${f(r)}.`,
        math: [text("r"), op("="), num(a * r), op("÷"), num(a), op("="), num(r)], state: 1, answerStep: "r", result: r },
      { id: "pow", narration: `From term 1 to term ${n} is ${count(n - 1, "jump")}, so multiply by ${f(r)} ${n - 1} times: ${f(r)}${supText(n - 1)} = ${f(pw)}.`,
        math: [num(r), sup(n - 1), op("="), num(pw)], state: 2, answerStep: "pow", result: pw },
      { id: "term", narration: `Start at ${f(a)} and multiply: ${f(a)} × ${f(pw)} = ${f(an)}.`,
        math: [...term(n), op("="), num(a), op("×"), num(pw), op("="), num(an)], state: 3, answerStep: "term", result: an },
    ],
  };
}

export const lesson: LessonDefinition<GeoProblem> = withEasyStart({
  id: "g11-geo",
  grade: 11,
  unit: "Sequences",
  title: "Geometric sequences",
  pre: "g11-seq",
  reference: createGeo(3, 2, 6),
  generate: rng => generateGeo(rng),
  restore: restoreGeo,
  display: geoMath,
  displayNote: p => `Find term number ${p.n}.`,
  answers: geoAnswers,
  explain: explainGeo,
});
