// Adding decimals (the current app's g5-adddec): line up the points, add whole parts and decimal parts, put them together.
import { formatNumber as f, mark, num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, round6, wholeIn } from "../../_number-line/steps";
import { count } from "../../../text";
import { buildDecimalColumns } from "../../../../explanations/diagrams/early-g4/columns";
import type { SceneDiagram, SceneItem } from "../../../../explanations/diagrams/scene/schema";
import { lightSteps, pathXs } from "../../../../explanations/diagrams/scene/helpers";

/** the picture's beats, one per worked step */
const BEATS = { lineUp: 0, whole: 1, decimal: 2, total: 3 } as const;

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

/**
 * What this lesson's picture must show (Review g5 #10, as the live site did): the 0 written in to make 5.40 is new, so it
 * wears the picture's colour (pic-deep) instead of the ink every other digit has; and the ring round the carried 1
 * comes in with its 1, never before it. (The columns master draws the ring as an .xring, whose glow animation in the
 * picture system replaces its entrance and so drops its delay; an .ln2 outline is the same deep line and keeps both.
 * A plain .ring can't be used: the score ring's own .ring rule sizes any element with that class.)
 */
function markNew(d: SceneDiagram, b: { lineUp: number; whole: number; decimal: number; total: number }): SceneDiagram {
  const carry = d.items.find(i => i.type === "text" && i.cls === "lbl big acc" && (i.from ?? 0) > 0 && i.enter === "pop");
  const items = d.items.map((it): SceneItem => {
    if (it.type === "text" && it.cls === "lbl big acc" && (it.from ?? 0) === 0 && it.enter === "pop") return { ...it, cls: "lbl big" };
    if (it.type === "rect" && it.cls === "xring") return { ...it, cls: "ln2", delay: carry?.delay ?? it.delay };
    return it;
  });
  // the worked step lit (the shared `lit` role), beat by beat: the written-in 0s while the points are lined up, then the
  // two numbers' whole digits while they are added, then their digits after the point
  const wire = items.find((i): i is Extract<SceneItem, { type: "path" }> => i.type === "path" && i.cls === "wire");
  const point = wire ? pathXs(wire.d)[0] : undefined;
  const litOn = (it: SceneItem): number[] | null => {
    if (it.type !== "text" || point == null || it.text === ".") return null;
    if (it.cls === "lbl big" && it.enter === "pop" && (it.from ?? 0) === b.lineUp) return [b.lineUp];
    if (it.cls === "lbl big pw" && !it.from) return [it.x < point ? b.whole : b.decimal];
    return null;
  };
  return { ...d, items: lightSteps(items, litOn, b.total) };
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
    idea: ["With the points lined up, tenths add to tenths and hundredths to hundredths."],
    statement: [num(a), op("+"), num(b)],
    ...(padded.length ? { caption: `Write ${rewrite} so both have hundredths.` } : {}),
    alt: `${f(a)} + ${f(b)}: whole parts ${W}, decimal parts ${f(D)}, total ${f(sum)}.`,
    diagram: markNew(buildDecimalColumns({
      a: Math.round(a * 100), b: Math.round(b * 100), shown: [decimalsShown(a), decimalsShown(b)], point: 2,
      beats: BEATS,
      alt: `${f(a)} and ${f(b)} lined up by their points${padded.length ? `, with ${rewrite}` : ""}: the whole columns make ${W}, the decimal columns make ${D.toFixed(2)}, together ${f(sum)}.`,
    }), BEATS),
    beats: [
      { id: "line-up", narration: padded.length ? `Write ${rewrite} so both numbers have hundredths.` : "Both already have hundredths, so the points line up.",
        math: [...hundredths(a), op("+"), ...hundredths(b)], lines: [[...hundredths(a), op("+"), ...hundredths(b)]] },
      { id: "whole", narration: "Add the whole numbers.", math: [num(wa), op("+"), num(wb), op("="), num(W)],
        lines: [[num(wa), op("+"), num(wb), op("="), num(W)]], answerStep: "whole", result: W },
      { id: "decimal", narration: `Add the parts after the point.${D >= 1 ? " That's more than 1 whole." : ""}`, math: [num(da), op("+"), num(db), op("="), num(D)],
        lines: [[text(da.toFixed(2)), op("+"), text(db.toFixed(2)), op("="), num(D)]], answerStep: "decimal", result: D },
      { id: "total", narration: "Put the two answers together.", math: [num(W), op("+"), num(D), op("="), num(sum)],
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
