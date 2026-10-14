// Dividing by a decimal (the current app's g5-divdec): multiply both numbers by 10, then divide whole numbers.
import { formatNumber as f, mark, num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { chainExplanation } from "../../../../explanations/diagrams/chain/build";
import { expectedOf, oneBox, restoreVia, round6, wholeIn } from "../../_number-line/steps";
import { buildDoubleLine } from "../../../../explanations/diagrams/early-g4/double-line";
import type { SceneDiagram, SceneItem } from "../../../../explanations/diagrams/scene/schema";
import { lightSteps, pathXs } from "../../../../explanations/diagrams/scene/helpers";

/** (d × qt)/10 ÷ d/10, so the answer is the whole number qt */
export interface DivDecimalProblem { d: number; qt: number }

export function createDivDecimal(d: number, qt: number): DivDecimalProblem {
  wholeIn("d", d, 2, 9);
  wholeIn("qt", qt, 2, 12);
  return { d, qt };
}

function answers({ d, qt }: DivDecimalProblem): AnswerModel {
  const x = (d * qt) / 10, y = d / 10;
  return {
    steps: [
      oneBox({ id: "divisor", label: "Make the divisor whole", prompt: s => [num(y), op("×"), num(10), op("="), s], ans: d, hint: "Move its decimal point one place right.",
        wrong: [[d * 10, "Moved the point too far", "Times 10 moves the point one place."], [round6(y / 10), "Moved the point the wrong way", "Times 10 makes it bigger: the point moves right."]] }),
      oneBox({
        id: "other", label: "Do the same to the other number", prompt: s => [num(x), op("×"), num(10), op("="), s], ans: d * qt,
        hint: "Multiply it by 10 too, so the answer doesn't change.", wrong: [[round6(x), "Changed only one number", "Multiply both numbers by 10."]],
      }),
      oneBox({ id: "divide", label: "Divide", prompt: s => [num(d * qt), op("÷"), num(d), op("="), s], ans: qt, hint: `How many ${d}s make ${d * qt}?`,
        wrong: [[round6(qt / 10), "Put the point back", "Both numbers got 10 times bigger, so the answer is the same. Don't move the point back."], [d * qt * d, "Multiplied", `How many ${d}s fit in ${d * qt}? That's dividing.`]] }),
    ],
    finalParts: [-1],
  };
}

/** the picture's beats: one tenth matched, every tick matched (the ends found), the hops counted */
const BEATS = { one: 0, all: 1, extra: null, total: 2 } as const;

/**
 * What this lesson's picture must show (Review g5 #10, as the live site did): the two end points (6 and 60) are marked
 * in the picture's colour once both lines reach them, their dots and their numbers together, and the hops that count
 * how many times the divisor fits are drawn in the picture's colour, not the ink grey of a plain line.
 */
/** a tick number marked as a label, still growing away from its line on a phone (.up / .down) */
const asLabel = (cls?: string) => (cls ?? "").replace(/\b(sm|xs)\b/, "lbl");

function markEnds(d: SceneDiagram, all: number, last: number): SceneDiagram {
  const dots = d.items.filter((i): i is Extract<SceneItem, { type: "circle" }> => i.type === "circle" && i.cls === "dotp");
  const top = dots.reduce<typeof dots[number] | undefined>((a, c) => (!a || c.cy < a.cy ? c : a), undefined);
  const bottom = dots.reduce<typeof dots[number] | undefined>((a, c) => (!a || c.cy > a.cy ? c : a), undefined);
  if (!top || !bottom || top === bottom) return d;
  const items = d.items.flatMap((it): SceneItem[] => {
    if (it.type === "path" && it.cls === "ln thin pq") return [{ ...it, cls: "ln thin" }];
    if (it.type !== "text" || Math.abs(it.x - top.cx) > 0.5) return [it];
    // the top end's number: plain until the lines are matched, then marked with its dot
    if (it.y < top.cy && (it.from ?? 0) < all) return [{ ...it, until: all - 1 }, { ...it, cls: asLabel(it.cls), from: all, enter: "pop", delay: top.delay ?? 0 }];
    // the bottom end's number: marked from the beat it is found, and it stays marked (the same look carries on)
    if (it.y > bottom.cy) {
      if ((it.from ?? 0) <= all) return [{ ...it, cls: asLabel(it.cls), enter: "pop", delay: bottom.delay ?? 0 }];
      const { enter: _e, delay: _d, ...stays } = it;
      return [{ ...stays, cls: asLabel(it.cls) }];
    }
    return [it];
  });
  // the worked step lit (the shared `lit` role), beat by beat: the divisor and its whole-number twin (0.5 and 5) while
  // the divisor is made whole, then the two ends (6 and 60) while the other number is
  const one = items.find((i): i is Extract<SceneItem, { type: "path" }> => i.type === "path" && /\bhl\b/.test(i.cls ?? "") && i.until === 0);
  const tick1 = one ? Math.max(...pathXs(one.d)) : null;
  return {
    ...d,
    items: lightSteps(items, it => it.type !== "text" ? null
      : tick1 != null && Math.abs(it.x - tick1) < 0.5 && (it.from ?? 0) === 0 ? [0]
      : /^lbl\b/.test(it.cls ?? "") && it.from === all ? [all] : null, last),
  };
}

function explain(p: DivDecimalProblem, model: AnswerModel) {
  const x = (p.d * p.qt) / 10, y = p.d / 10;
  const d = expectedOf(model, "divisor"), n = expectedOf(model, "other"), qt = expectedOf(model, "divide");
  return chainExplanation({
    heading: "Make the divisor a whole number",
    idea: ["Making both numbers ten times bigger doesn't change how many times one fits in the other."],
    statement: [num(x), op("÷"), num(y)],
    caption: `Move both points one place: ${f(x)} ÷ ${f(y)} and ${n} ÷ ${d} have the same answer.`,
    alt: `${f(x)} ÷ ${f(y)} becomes ${n} ÷ ${d} = ${qt}.`,
    diagram: markEnds(buildDoubleLine({
      n: qt, per: d, extra: 0, top: "", bottom: "", between: "× 10",
      topText: j => f(round6(j * y)), bottomText: j => String(j * d),
      beats: BEATS, hops: { from: BEATS.total },
      lines: [{ text: `${f(y)} × 10 = ${d}`, from: 0, until: 0 }, { text: `${f(x)} × 10 = ${n}`, from: 1, until: 1 }],
      total: `${n} ÷ ${d} = ${qt}, and ${f(x)} ÷ ${f(y)} = ${qt}`,
      alt: `A double number line: the top counts by ${f(y)} up to ${f(x)}, the bottom by ${d} up to ${n}, tick for tick. ${qt} hops on each line, so both divisions are ${qt}.`,
    }), BEATS.all, BEATS.total),
    beats: [
      { id: "divisor", narration: "Make the divisor a whole number.", math: [num(y), op("×"), num(10), op("="), num(d)],
        lines: [[num(x), op("÷"), num(y)], [num(y), op("×"), num(10), op("="), num(d)]], answerStep: "divisor", result: d },
      { id: "other", narration: `Do the same to ${f(x)}, so the answer doesn't change.`, math: [num(x), op("×"), num(10), op("="), num(n)],
        lines: [[mark(n), op("÷"), mark(d)]], answerStep: "other", result: n },
      { id: "divide", narration: "Now it's whole numbers: divide.", math: [num(n), op("÷"), num(d), op("="), num(qt)],
        lines: [[num(qt)]], answerStep: "divide", result: qt },
    ],
  });
}

export const lesson: LessonDefinition<DivDecimalProblem> = {
  id: "g5-divdec",
  grade: 5,
  unit: "Decimals",
  title: "Dividing by a decimal",
  pre: "g5-pow10",
  reference: createDivDecimal(6, 8), // 4.8 ÷ 0.6 = 8, the current app's example
  generate: rng => { const d = rng.int(2, 9), qt = rng.int(2, 12); return createDivDecimal(d, qt); },
  restore: raw => restoreVia(raw, ["d", "qt"] as const, v => createDivDecimal(v.d, v.qt)),
  display: p => [num((p.d * p.qt) / 10), op("÷"), num(p.d / 10)],
  answers,
  explain,
  story: p => ({ op: "÷", text: `You have **${f((p.d * p.qt) / 10)}** liters of juice. Each cup holds **${f(p.d / 10)}** liters. How many cups can you fill?` }),
};
