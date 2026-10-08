// Adding decimals (the current app's g5-adddec): line up the points, add whole parts and decimal parts, put them together.
import { formatNumber as f, mark, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, round6, wholeIn } from "../../_number-line/steps";
import { count } from "../../../text";
import { buildDecimalColumns } from "../../../../explanations/diagrams/early-g4/columns";

/** a has tenths (1.1 to 99.9), b has hundredths (1.01 to 99.99) */
export interface AddDecimalsProblem { a: number; b: number }

export function createAddDecimals(a: number, b: number): AddDecimalsProblem {
  wholeIn("a × 10", round6(a * 10), 11, 999);
  wholeIn("b × 100", round6(b * 100), 101, 9999);
  return { a: round6(a), b: round6(b) };
}

const split = ({ a, b }: AddDecimalsProblem) => {
  const wa = Math.floor(a), wb = Math.floor(b);
  return { wa, wb, da: round6(a - wa), db: round6(b - wb) };
};

/** x written with hundredths; the zeros added to line up the points are marked */
function hundredths(x: number): MathText {
  const s = f(x), full = x.toFixed(2);
  return s === full ? [num(x)] : [text(s), mark(full.slice(s.length))];
}

/** digits after the point as the number is written (12.5 → 1) */
const decimalsShown = (x: number) => f(x).split(".")[1]?.length ?? 0;

function answers(p: AddDecimalsProblem): AnswerModel {
  const { a, b } = p, { wa, wb, da, db } = split(p);
  return {
    steps: [
      oneBox({ id: "whole", label: "Add the whole numbers", prompt: s => [num(wa), op("+"), num(wb), op("="), s], ans: wa + wb, hint: "Add the parts before the decimal points.",
        wrong: (wa % 10) + (wb % 10) >= 10 ? [[wa + wb - 10, "Forgot to carry", `The ones make ${(wa % 10) + (wb % 10)}: carry the 1 ten.`]] : [[Math.abs(wa - wb), "Subtracted", "This step adds the whole parts."]] }),
      oneBox({
        id: "decimal", label: "Add the decimal parts", prompt: s => [num(da), op("+"), num(db), op("="), s], ans: round6(da + db),
        hint: `Line up the points: ${f(da)} is the same as ${da.toFixed(2)}.`,
        wrong: [[round6((Math.round(da * 10) + Math.round(db * 100)) / 100), "Didn't line up the decimal points",
          `${f(da)} means ${count(Math.round(da * 10), "tenth")}, which is ${count(Math.round(da * 100), "hundredth")}. Line up the points.`]],
      }),
      oneBox({ id: "total", label: "Put them together", prompt: s => [num(a), op("+"), num(b), op("="), s], ans: round6(a + b), hint: `${wa + wb} + ${f(round6(da + db))}.`,
        wrong: da + db >= 1 ? [[round6(a + b - 1), "Lost a whole", `${f(round6(da + db))} is more than 1 whole: that 1 goes with the whole numbers.`]] : [[wa + wb, "Left off the decimal part", `Keep the ${f(round6(da + db))} after the point.`]] }),
    ],
    finalParts: [-1],
  };
}

function explain(p: AddDecimalsProblem, model: AnswerModel) {
  const { a, b } = p, { wa, wb, da, db } = split(p);
  const W = expectedOf(model, "whole"), D = expectedOf(model, "decimal"), sum = expectedOf(model, "total");
  const padded = [a, b].filter(x => f(x) !== x.toFixed(2));
  const rewrite = padded.map(x => `${f(x)} as ${x.toFixed(2)}`).join(" and ");
  return chainExplanation({
    heading: "Line up the decimal points",
    idea: ["Each place after the point is a size of piece, so only same-size pieces add."],
    statement: [num(a), op("+"), num(b)],
    ...(padded.length ? { caption: `Write ${rewrite} so both have hundredths.` } : {}),
    alt: `${f(a)} + ${f(b)}: whole parts ${W}, decimal parts ${f(D)}, total ${f(sum)}.`,
    diagram: buildDecimalColumns({
      a: Math.round(a * 100), b: Math.round(b * 100), shown: [decimalsShown(a), decimalsShown(b)], point: 2,
      beats: { lineUp: 0, whole: 1, decimal: 2, total: 3 },
      alt: `${f(a)} and ${f(b)} lined up by their points${padded.length ? `, with ${rewrite}` : ""}: the whole columns make ${W}, the decimal columns make ${D.toFixed(2)}, together ${f(sum)}.`,
    }),
    beats: [
      { id: "line-up", narration: padded.length ? `Line up the decimal points: write ${rewrite} so both numbers have hundredths.` : "Both numbers already have hundredths, so the points line up.",
        math: [...hundredths(a), op("+"), ...hundredths(b)], lines: [[...hundredths(a), op("+"), ...hundredths(b)]] },
      { id: "whole", narration: `Whole parts: ${wa} + ${wb} = ${W}.`, math: [num(wa), op("+"), num(wb), op("="), num(W)],
        lines: [[num(wa), op("+"), num(wb), op("="), num(W)]], answerStep: "whole", result: W },
      { id: "decimal", narration: `Decimal parts: ${da.toFixed(2)} + ${db.toFixed(2)} = ${D.toFixed(2)}.`, math: [num(da), op("+"), num(db), op("="), num(D)],
        lines: [[text(da.toFixed(2)), op("+"), text(db.toFixed(2)), op("="), num(D)]], answerStep: "decimal", result: D },
      { id: "total", narration: `Put them together: ${W} + ${f(D)} = ${f(sum)}.`, math: [num(W), op("+"), num(D), op("="), num(sum)],
        lines: [[num(W), op("+"), num(D), op("="), num(sum)]], answerStep: "total", result: sum },
    ],
  });
}

export const lesson: LessonDefinition<AddDecimalsProblem> = {
  id: "g5-adddec",
  grade: 5,
  unit: "Decimals",
  title: "Adding decimals",
  pre: "g4-dec",
  reference: createAddDecimals(12.5, 3.75), // 12.5 + 3.75 = 16.25, the current app's example
  // the first three: one-digit whole parts
  generate: (rng, index) => (index < 3 ? createAddDecimals(rng.int(11, 99) / 10, rng.int(101, 999) / 100) : createAddDecimals(rng.int(11, 999) / 10, rng.int(101, 9999) / 100)),
  restore: raw => restoreVia(raw, ["a", "b"] as const, v => createAddDecimals(v.a, v.b)),
  display: p => [num(p.a), op("+"), num(p.b)],
  answers,
  explain,
  story: p => ({ op: "+", text: `Maya biked **${f(p.a)}** km on Saturday and **${f(p.b)}** km on Sunday. How far did she bike in all?` }),
};
