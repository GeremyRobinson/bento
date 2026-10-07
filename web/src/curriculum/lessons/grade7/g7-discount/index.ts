import { formatNumber as f, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeSpec } from "../../../../explanations/diagrams/tape/schema";
import { expectedOf, gcd, ns } from "../../_tape-family/steps";
import { count } from "../../../text";

export const RATES = [10, 15, 20, 25, 30, 40, 50];

/** $P with p% off (a discount) or p% added (a tip). */
export interface DiscountProblem { P: number; p: number; off: boolean }

export function createDiscount(P: number, p: number, off: boolean): DiscountProblem {
  if (!Number.isInteger(P) || !Number.isInteger(p) || P <= 0 || p <= 0 || p >= 100) throw new Error(`not a discount problem: $${P}, ${p}%`);
  return { P, p, off };
}

/** Same ranges as the current app: $20–200 in steps of 20, one of its rates, off or tip half the time. */
export const generateDiscount = (rng: Rng) => createDiscount(20 * rng.int(1, 10), rng.pick(RATES), rng.next() < 0.5);

const $ = (v: number | MathText): MathText => [text("$"), ...(typeof v === "number" ? [num(v)] : v)];

function answers({ P, p, off }: DiscountProblem): AnswerModel {
  const amt = (P * p) / 100;
  return {
    steps: [
      ns({ id: "percent", l: `Find ${p}%`, a: s => [num(p), text("% of "), ...$(P), op("="), ...$(s)], ans: amt, h: `Find 10% first, one tenth of $${P}. Then build up to ${p}%.`,
        w: [[P * p, "Multiplied by the percent", `${p}% means ${p} out of every 100: find 10% first.`], [P + (off ? -amt : amt), "Found the new price", `That's the price after. This step asks for the ${p}% itself.`]] }),
      ns({ id: "total", l: off ? "Take it off" : "Add it on", a: s => [...$(P), op(off ? "−" : "+"), ...$(amt), op("="), ...$(s)], ans: P + (off ? -amt : amt),
        h: off ? "A discount takes money off." : "A tip adds money on.",
        w: [[P + (off ? amt : -amt), off ? "Added the discount" : "Subtracted the tip", off ? "A discount takes money off: subtract." : "Tips and tax add on: add."]] }),
    ],
    finalParts: [-1],
  };
}

/**
 * The price as a bar cut into equal blocks of g% (g = the largest block that p% is made of).
 * A discount marks its p% at the end of the bar and then takes it away; a tip adds p% more blocks onto the end.
 */
export function discountPicture({ P, p, off }: DiscountProblem) {
  const g = gcd(p, 100), blocks = 100 / g, each = (P * g) / 100, amt = (P * p) / 100, cut = p / 100;
  const spec: TapeSpec = off
    ? {
        rows: [{ length: 1, parts: blocks, label: [{ text: `$${P}` }],
          fills: [{ a: 0, b: 1 - cut, tone: "on" }, { a: 1 - cut, b: 1, tone: "on", until: 0 }, { a: 1 - cut, b: 1, tone: "acc", from: 1, until: 1 }, { a: 1 - cut, b: 1, tone: "cut", from: 2 }],
          each: [{ text: () => `$${f(each)}` }], total: [{ text: `$${f(P - amt)}`, from: 2, acc: true }] }],
        brackets: [{ row: 0, a: 1 - cut, b: 1, text: `${p}% = $${f(amt)}`, side: "above", from: 1, acc: true }],
        alt: `$${P} cut into ${count(blocks, "block")} of ${g}%; ${p}% off takes $${f(amt)} away, leaving $${f(P - amt)}.`,
      }
    : {
        rows: [
          { length: 1, parts: blocks, fills: [{ a: 0, b: 1, tone: "on" }], each: [{ text: () => `$${f(each)}` }], label: [{ text: "price" }], total: [{ text: `$${P}` }] },
          { length: 1 + cut, parts: (100 + p) / g, from: 1, fills: [{ a: 0, b: 1, tone: "on" }, { a: 1, b: 1 + cut, tone: "acc" }], each: [{ text: () => `$${f(each)}` }],
            label: [{ text: "total" }], total: [{ text: `$${f(P + amt)}`, from: 2, acc: true }] },
        ],
        brackets: [{ row: 1, a: 1, b: 1 + cut, text: `${p}% = $${f(amt)}`, side: "above", from: 1, acc: true }],
        alt: `$${P} cut into ${count(blocks, "block")} of ${g}%; a ${p}% tip adds ${p / g} more blocks, $${f(amt)}, for $${f(P + amt)}.`,
      };
  return buildTape(spec);
}

function explain(pr: DiscountProblem, model: AnswerModel): Explanation {
  const { P, p, off } = pr, amt = expectedOf(model.steps, "percent"), total = expectedOf(model.steps, "total");
  return {
    heading: "Find the percent, then add or subtract",
    idea: ["Percent means out of 100, so 10% of a price is one tenth of it."],
    statement: [...$(P), text(off ? `, ${p}% off` : `, ${p}% tip`)],
    diagram: discountPicture(pr),
    caption: off ? `${p}% off: $${f(amt)} comes off.` : `A ${p}% tip: $${f(amt)} goes on.`,
    timeline: beats(3),
    steps: [
      { id: "percent", state: 1, answerStep: "percent", result: amt, math: [num(p), text("% of "), ...$(P), op("="), ...$(amt)],
        narration: `10% of $${P} is $${f(P / 10)}, so ${p}% of $${P} is $${f(amt)}.` },
      { id: "total", state: 2, answerStep: "total", result: total, math: [...$(P), op(off ? "−" : "+"), ...$(amt), op("="), ...$(total)],
        narration: off ? `A discount takes money off: $${P} − $${f(amt)} = $${f(total)}.` : `A tip adds money on: $${P} + $${f(amt)} = $${f(total)}.` },
    ],
  };
}

export const lesson: LessonDefinition<DiscountProblem> = {
  id: "g7-discount",
  grade: 7,
  unit: "Proportions and percents",
  title: "Discounts, tax and tips",
  pre: "g6-pctof",
  // the current app's card and picture: $80, 25% off, sale price $60
  reference: createDiscount(80, 25, true),
  generate: rng => generateDiscount(rng),
  restore: raw => {
    if (!raw || typeof raw !== "object") return null;
    const r = raw as Record<string, unknown>;
    if (typeof r.P !== "number" || typeof r.p !== "number" || typeof r.off !== "boolean") return null;
    try { return createDiscount(r.P, r.p, r.off); } catch { return null; }
  },
  display: (pr): MathText => $(pr.P),
  displayNote: ({ p, off }) => (off ? `${p}% off. What's the sale price?` : `Add a ${p}% tip. What's the total?`),
  answers,
  explain,
};
