import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import { expectedOf, ns } from "../../_tape-family/steps";

export const ITEMS = ["notebooks", "apples", "pencils", "stickers", "tickets"] as const;

/** n items cost $u·n; how much do m cost? */
export interface UnitRateProblem { u: number; n: number; m: number; item: string }

export function createUnitRate(u: number, n: number, m: number, item: string): UnitRateProblem {
  if (![u, n, m].every(x => Number.isInteger(x) && x > 0) || !item) throw new Error(`not a unit-rate problem: ${n} ${item} for $${u * n}`);
  return { u, n, m, item };
}

/** Same ranges as the current app: $2–15 each, 2–9 bought, 2–12 asked about. */
// the first three: small prices and counts
export const generateUnitRate = (rng: Rng, index = 3) => (index < 3
  ? createUnitRate(rng.int(2, 5), rng.int(2, 4), rng.int(2, 6), rng.pick(ITEMS))
  : createUnitRate(rng.int(2, 15), rng.int(2, 9), rng.int(2, 12), rng.pick(ITEMS)));

const $ = (s: MathText): MathText => [text("$"), ...s];

function answers({ u, n, m }: UnitRateProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "one", l: "Cost of one", a: s => [...$([num(u * n)]), op("÷"), num(n), op("="), ...$(s)], ans: u, h: `Share the cost over ${n}.`,
        w: [[u * n * n, "Multiplied instead of divided", "To find the cost of one, divide."]] }),
      ns({ id: "many", l: `Cost of ${m}`, a: s => [num(m), op("×"), ...$([num(u)]), op("="), ...$(s)], ans: m * u, h: `${m} of them at $${u} each.`,
        w: [[u * n * m, "Used the cost of all of them", `Use the cost of one, $${u}, not $${u * n}.`], [m + u, "Added", `${m} of them, $${u} each: that's ${m} groups of $${u}.`]] }),
    ],
    finalParts: [-1],
  };
}

/** One box per item, the same size in both rows. Beat 1 shares the cost over the n boxes; beat 2 builds the m boxes. */
export function unitRatePicture({ u, n, m, item }: UnitRateProblem) {
  return buildTape({
    rows: [
      { length: n, parts: n, fills: [{ a: 0, b: n, tone: "on", from: 1 }], each: [{ text: () => `$${u}`, from: 1 }], label: [{ text: `${n} ${item}` }],
        total: [{ text: `$${u * n}` }] },
      { length: m, parts: m, from: 1, fills: [{ a: 0, b: m, tone: "two", from: 2 }], each: [{ text: () => `$${u}`, from: 2 }], label: [{ text: `${m} ${item}` }],
        total: [{ text: "?", until: 1 }, { text: `$${m * u}`, from: 2, acc: true }] },
    ],
    alt: `${n} ${item} cost $${u * n}, so each costs $${u}; ${m} ${item} cost $${m * u}.`,
  });
}

function explain(p: UnitRateProblem, model: AnswerModel): Explanation {
  const { n, m, item } = p, u = expectedOf(model.steps, "one"), total = expectedOf(model.steps, "many");
  return {
    heading: "Find the cost of one first",
    idea: ["Every one costs the same, so the cost of one gets you to any number of them."],
    statement: [num(n), text(` ${item} cost $`), num(u * n)],
    diagram: unitRatePicture(p),
    caption: `Each box is one of the ${item}: $${u}.`,
    timeline: beats(3),
    steps: [
      { id: "one", state: 1, answerStep: "one", result: u, math: [...$([num(u * n)]), op("÷"), num(n), op("="), ...$([num(u)])],
        narration: `Share $${u * n} over ${n} ${item}: one costs $${u}.` },
      { id: "many", state: 2, answerStep: "many", result: total, math: [num(m), op("×"), ...$([num(u)]), op("="), ...$([num(total)])],
        narration: `${m} of them at $${u} each: ${m} × $${u} = $${total}.` },
    ],
  };
}

export const lesson: LessonDefinition<UnitRateProblem> = {
  id: "g6-rate",
  grade: 6,
  unit: "Ratios and percents",
  title: "Unit rates",
  pre: "g5-divide",
  // the current app's card and picture: 4 apples cost $12, so 7 apples cost $21
  reference: createUnitRate(3, 4, 7, "apples"),
  generate: (rng, index) => generateUnitRate(rng, index),
  restore: raw => {
    if (!raw || typeof raw !== "object") return null;
    const r = raw as Record<string, unknown>;
    if (![r.u, r.n, r.m].every(x => typeof x === "number") || typeof r.item !== "string") return null;
    try { return createUnitRate(r.u as number, r.n as number, r.m as number, r.item); } catch { return null; }
  },
  display: (p): MathText => [num(p.n), text(` ${p.item} cost $`), num(p.u * p.n)],
  displayNote: p => `How much do ${p.m} ${p.item} cost?`,
  answers,
  explain,
};
