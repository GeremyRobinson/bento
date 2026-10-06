import { formatNumber as f, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeRow } from "../../../../explanations/diagrams/tape/schema";
import { expectedOf, gcd, ns, round6 } from "../../_tape-family/steps";
import { count } from "../../../text";

/** O goes up or down by p%. */
export interface PercentChangeProblem { O: number; p: number; up: boolean }

export function createPercentChange(O: number, p: number, up: boolean): PercentChangeProblem {
  if (!Number.isInteger(O) || !Number.isInteger(p) || O <= 0 || p <= 0 || (!up && p >= 100)) throw new Error(`not a percent-change problem: ${O}, ${p}%`);
  return { O, p, up };
}

/** Same ranges as the current app: 10, 20, 25, 50 or 75 percent, from 20–200, up or down half the time. */
export function generatePercentChange(rng: Rng): PercentChangeProblem {
  const p = rng.pick([10, 20, 25, 50, 75]), O = rng.pick([20, 40, 60, 80, 100, 120, 200]);
  return createPercentChange(O, p, rng.next() < 0.5);
}

const newValue = ({ O, p, up }: PercentChangeProblem) => O + ((up ? 1 : -1) * O * p) / 100;

function answers(pr: PercentChangeProblem): AnswerModel {
  const { O, p } = pr, N = newValue(pr), c = Math.abs(N - O);
  return {
    steps: [
      ns({ id: "change", l: "How much did it change?", a: s => [text("|"), num(N), op("−"), num(O), text("|"), op("="), ...s], ans: c, h: "Subtract to find the change.",
        w: [[N + O, "Added", "The change is the gap between the two amounts: subtract."]] }),
      ns({ id: "divide", l: "Divide by the original", a: s => [num(c), op("÷"), num(O), op("="), ...s], ans: round6(c / O), h: `Always divide by where you started: ${O}.`,
        w: [[round6(c / N), "Divided by the new number", "Divide by the original amount."]] }),
      ns({ id: "percent", l: "Write it as a percent", a: s => [num(round6(c / O)), op("="), ...s, text("%")], ans: p, h: "Percent means hundredths: how many hundredths is it?",
        w: [[round6(c / O), "Kept the decimal", `A percent counts hundredths: ${f(round6(c / O))} is how many hundredths?`], [round6(c / O * 10), "Moved the point one place", "Hundredths: move the point two places."]] }),
    ],
    finalParts: [-1],
  };
}

/**
 * "was" and "now" bars cut into blocks of g% of the original (g = the largest block the change is made of).
 * Beat 1 marks the change, beat 2 compares it with the original, beat 3 names the percent.
 */
export function percentChangePicture(pr: PercentChangeProblem) {
  const { O, p, up } = pr, N = newValue(pr), c = Math.abs(N - O), g = gcd(p, 100), each = (O * g) / 100, d = p / 100;
  const sign = up ? "+" : "−";
  const now: TapeRow = up
    ? { length: 1 + d, parts: (100 + p) / g, fills: [{ a: 0, b: 1, tone: "on" }, { a: 1, b: 1 + d, tone: "acc", from: 1 }] }
    : { length: 1, parts: 100 / g, fills: [{ a: 0, b: 1 - d, tone: "on" }, { a: 1 - d, b: 1, tone: "cut", from: 1 }] };
  const [a, b] = up ? [1, 1 + d] : [1 - d, 1];
  return buildTape({
    rows: [
      { length: 1, parts: 100 / g, fills: [{ a: 0, b: 1, tone: "on" }], each: [{ text: () => f(each) }], label: [{ text: `was ${O}` }] },
      { ...now, each: [{ text: () => f(each) }], label: [{ text: `now ${f(N)}` }], total: [{ text: `${sign}${p}%`, from: 3, acc: true }] },
    ],
    brackets: [
      { row: 1, a, b, text: `${sign}${f(c)}`, side: "below", from: 1, until: 1, acc: true },
      { row: 1, a, b, text: `${f(c)} ÷ ${O} = ${f(round6(c / O))}`, side: "below", from: 2, acc: true },
    ],
    alt: `${O} as ${count(100 / g, "block")} of ${f(each)}; now ${f(N)}, a change of ${f(c)}, which is ${p}% of ${O}.`,
  });
}

function explain(pr: PercentChangeProblem, model: AnswerModel): Explanation {
  const { O, up } = pr, N = newValue(pr), g = gcd(pr.p, 100);
  const c = expectedOf(model.steps, "change"), r = expectedOf(model.steps, "divide"), p = expectedOf(model.steps, "percent");
  return {
    heading: "Change ÷ original",
    idea: ["Percent change compares the change with where you started, so the same change is a bigger percent of a smaller start.", "Change ÷ original, written as hundredths, is the percent."],
    statement: [num(O), op("→"), num(N)],
    diagram: percentChangePicture(pr),
    caption: `Each block is ${g}% of ${O}, which is ${f((O * g) / 100)}.`,
    timeline: beats(4),
    steps: [
      { id: "change", state: 1, answerStep: "change", result: c, math: [text("|"), num(N), op("−"), num(O), text("|"), op("="), num(c)],
        narration: `It went ${up ? "up" : "down"} from ${O} to ${f(N)}: a change of ${f(c)}.` },
      { id: "divide", state: 2, answerStep: "divide", result: r, math: [num(c), op("÷"), num(O), op("="), num(r)],
        narration: `Compare the change with where you started, ${O}: ${f(c)} ÷ ${O} = ${f(r)}.` },
      { id: "percent", state: 3, answerStep: "percent", result: p, math: [num(r), op("="), num(p), text("%")],
        narration: `Move the point two places right: ${f(r)} = ${p}%, a ${p}% ${up ? "increase" : "decrease"}.` },
    ],
  };
}

export const lesson: LessonDefinition<PercentChangeProblem> = {
  id: "g7-pctchange",
  grade: 7,
  unit: "Proportions and percents",
  title: "Percent change",
  pre: "g7-discount",
  // the current app's card and picture: 50 → 65 is +30%
  reference: createPercentChange(50, 30, true),
  generate: rng => generatePercentChange(rng),
  restore: raw => {
    if (!raw || typeof raw !== "object") return null;
    const r = raw as Record<string, unknown>;
    if (typeof r.O !== "number" || typeof r.p !== "number" || typeof r.up !== "boolean") return null;
    try { return createPercentChange(r.O, r.p, r.up); } catch { return null; }
  },
  display: (pr): MathText => [num(pr.O), op("→"), num(newValue(pr))],
  displayNote: () => "What's the percent change?",
  answers,
  explain,
};
