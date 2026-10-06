// Line plots with halves and fourths: measure to the nearest half or fourth inch, or read a line plot marked in fourths.
import { answer, frac, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildFracRuler, buildLinePlot, plotLabel } from "../../../../explanations/diagrams/early-g2/lineplot";
import { manyBoxes, oneBox, wholeIn } from "../../_number-line/steps";
import { tapStep, words, singularWork } from "../../gradeK/kit";
import { slips } from "../../grade2/kit";

const THINGS = [
  { many: "shells", one: "shell", title: "Shell lengths" },
  { many: "leaves", one: "leaf", title: "Leaf lengths" },
  { many: "crayons", one: "crayon", title: "Crayon lengths" },
  { many: "bugs", one: "bug", title: "Bug lengths" },
];
const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : a);

/**
 * kind 0: a thing `whole` inches and `quarters` fourths long, read to the nearest `to` (2 halves, 4 fourths);
 * kind 1: a line plot of `data` in fourths from `lo` (in fourths) for 2 inches; ask 0 how many are v long, 1 which length is most.
 */
export interface FracPlotProblem { kind: number; whole: number; quarters: number; to: number; thing: number; lo: number; data: number[]; ask: number; v: number }

const howMany = (d: number[], v: number) => d.filter(u => u === v).length;
const modes = (d: number[]) => { const vs = [...new Set(d)], top = Math.max(...vs.map(v => howMany(d, v))); return vs.filter(v => howMany(d, v) === top); };

export function createFracPlot(p: FracPlotProblem): FracPlotProblem {
  const base = { kind: p.kind, whole: 0, quarters: 0, to: 4, thing: 0, lo: 4, data: [] as number[], ask: 0, v: 0 };
  wholeIn("kind", p.kind, 0, 1);
  if (p.kind === 0) {
    wholeIn("whole", p.whole, 1, 5);
    if (p.to !== 2 && p.to !== 4) throw new Error("halves or fourths");
    if (p.to === 2 ? p.quarters !== 2 : p.quarters !== 1 && p.quarters !== 3) throw new Error("the end sits on a mark of that size");
    return { ...base, whole: p.whole, quarters: p.quarters, to: p.to };
  }
  wholeIn("thing", p.thing, 0, THINGS.length - 1);
  if (p.lo !== 4 && p.lo !== 8) throw new Error("the plot starts at 1 or 2 inches");
  if (!Array.isArray(p.data) || p.data.length < 8 || p.data.length > 12) throw new Error("8 to 12 X's");
  p.data.forEach((u, i) => wholeIn(`data[${i}]`, u, p.lo, p.lo + 8));
  if (modes(p.data).length !== 1) throw new Error("one tallest stack");
  wholeIn("ask", p.ask, 0, 1);
  wholeIn("v", p.v, p.lo, p.lo + 8);
  if (p.ask === 0 && !howMany(p.data, p.v)) throw new Error("v has an X");
  return { ...base, thing: p.thing, lo: p.lo, data: [...p.data], ask: p.ask, v: p.v };
}

/** a mixed number for v fourths, written out: "2 1/4" */
const said = (v: number) => {
  const w = Math.floor(v / 4), r = v % 4, g = gcd(r, 4);
  return r ? `${w ? `${w} ` : ""}${r / g}/${4 / g}` : String(w);
};
/** the three lengths to choose from for "came up most": the mode and two neighbors on the plot */
const choicesOf = (p: FracPlotProblem) => {
  const m = modes(p.data)[0]!, others = [...new Set(p.data)].filter(v => v !== m).sort((a, b) => howMany(p.data, b) - howMany(p.data, a) || a - b).slice(0, 2);
  const vals = [m, ...others].sort((a, b) => a - b);
  return { vals, right: vals.indexOf(m) };
};

function answers(p: FracPlotProblem): AnswerModel {
  if (p.kind === 0) {
    const extra = p.to === 2 ? 1 : p.quarters, name = p.to === 2 ? "halves" : "fourths", one = p.to === 2 ? "half" : "fourth";
    return {
      steps: [
        oneBox({
          id: "whole", label: "Whole inches", question: "How many whole inches long?", prompt: s => [s, text(" whole inches")], ans: p.whole,
          work: [answer("x", p.whole), text(p.whole === 1 ? " whole inch" : " whole inches")],
          wrong: slips(p.whole, [[p.whole + 1, "Read the next inch", `It hasn't reached ${p.whole + 1} yet. Read the last whole number it passes.`]]),
          hint: "Find the last whole-inch number it passes.", explain: `It passes ${p.whole}, but not ${p.whole + 1}.`,
        }),
        oneBox({
          id: "extra", label: "The extra part", question: `How many ${name} more?`, prompt: s => [s, text(` ${name}`)], ans: extra,
          work: [answer("x", extra), text(` ${extra === 1 ? one : name}`)],
          wrong: slips(extra, [[extra + 1, "Counted the marks", `Count the spaces past ${p.whole}, not the marks. The mark at ${p.whole} is where you start.`]]),
          hint: `From ${p.whole}, count the ${one}-inch spaces to the end.`, explain: `${extra} ${extra === 1 ? one : name} past ${p.whole}.`,
        }),
        manyBoxes({
          id: "write", label: "Write it", question: "How long is it, as a mixed number?",
          prompt: b => [b.w!, frac([b.n!], [b.d!]), text(" inches")], ans: { w: p.whole, n: extra, d: p.to }, small: ["w"],
          wrong: [[{ w: p.whole, n: extra, d: p.to === 2 ? 4 : 2 }, "Used the wrong size of piece", `The pieces are ${name}, so the bottom number is ${p.to}.`]],
          hint: `${p.whole} whole ${p.whole === 1 ? "inch" : "inches"} and ${extra} ${extra === 1 ? one : name}.`,
        }),
      ],
      finalParts: [-1],
    };
  }
  const th = THINGS[p.thing]!;
  if (p.ask === 0) {
    const n = howMany(p.data, p.v);
    return { steps: [oneBox({
      id: "stack", label: "Read a stack", question: `How many ${th.many} are ${said(p.v)} ${p.v === 4 ? "inch" : "inches"} long?`, prompt: s => [s, text(` ${th.many}`)], ans: n,
      wrong: slips(n, [-1, 1].map(dv => [howMany(p.data, p.v + dv), "Read the next stack", `That's ${said(p.v + dv)}. Each space is one fourth: count the marks from ${Math.floor(p.v / 4)}.`] as [number, string, string])),
      hint: `Find ${said(p.v)} on the line, then count the X's above it.`, explain: `${n} X's above ${said(p.v)}.`,
    })], finalParts: [-1] };
  }
  const { vals, right } = choicesOf(p);
  return { steps: [tapStep({
    id: "mode", label: "Tallest stack", question: "Which length came up most?", prompt: [text("The most common length is ?")],
    choices: vals.map(v => `${said(v)} in`), right,
    wrong: () => ["Picked a shorter stack", "Find the tallest stack and read the length under it."],
    hint: "Find the tallest stack.", explain: `The tallest stack is at ${said(vals[right]!)} inches.`, work: [text(`${said(vals[right]!)} inches`)],
  })], finalParts: [-1] };
}

const plot = (p: FracPlotProblem) => ({ d: 4, lo: p.lo, hi: p.lo + 8, data: p.data, title: THINGS[p.thing]!.title });
const alt = (p: FracPlotProblem) => (p.kind === 0 ? "A crayon on an inch ruler with half and quarter marks." : `A line plot of ${THINGS[p.thing]!.one} lengths, marked in fourths of an inch.`);

function explain(p: FracPlotProblem, model: AnswerModel): Explanation {
  const idea = ["A ruler has marks for halves and fourths of an inch. Measure to the nearest one, then put an X on the line plot."];
  const last = model.steps.at(-1)!;
  if (p.kind === 0) {
    const len = 4 * p.whole + p.quarters;
    return {
      heading: "Measure to a fourth", idea, statement: words("How long is it?"),
      diagram: buildFracRuler({ len, max: Math.max(4, p.whole + 1), to: p.to, beats: { whole: 1, extra: 2 }, text: `${plotLabel(len, 4)} in`, alt: `${alt(p)} It is ${said(len)} inches long.` }),
      caption: `${said(len)} inches.`, timeline: beats(3),
      steps: [
        { id: "look", narration: "Long marks are inches, middle ones halves, short ones fourths.", math: words("Look at the marks."), state: 0 },
        ...model.steps.map((s, i) => ({ id: s.id, narration: s.explain, math: s.work ?? [], state: Math.min(i + 1, 2), answerStep: s.id, result: s.slots[0]!.expected! })),
      ],
    };
  }
  const lit = p.ask === 0 ? [p.v] : modes(p.data);
  return {
    heading: "Line plots in fourths", idea, statement: words(last.question ?? ""),
    diagram: buildLinePlot({ ...plot(p), beats: { drop: 0, light: 1 }, light: lit, alt: `${alt(p)} The X's drop in, then the stack the question is about lights up.` }),
    caption: `${last.explain}`, timeline: beats(2),
    steps: [
      { id: "drop", narration: "Each thing measured drops an X above its length.", math: words(THINGS[p.thing]!.title), state: 0 },
      ...model.steps.map(s => ({ id: s.id, narration: s.explain, math: s.work ?? [], state: 1, answerStep: s.id, result: s.slots[0]!.expected! })),
    ],
  };
}

export const lesson: LessonDefinition<FracPlotProblem> = {
  id: "g3-lineplot",
  grade: 3,
  unit: "Data",
  title: "Line plots with halves and fourths",
  reference: createFracPlot({ kind: 0, whole: 2, quarters: 3, to: 4, thing: 0, lo: 4, data: [], ask: 0, v: 0 }),
  generate: (rng, index) => {
    const base = { kind: 0, whole: 0, quarters: 0, to: 4, thing: 0, lo: 4, data: [] as number[], ask: 0, v: 0 };
    if (index < 2) return createFracPlot({ ...base, whole: rng.int(1, 5), quarters: 2, to: 2 });
    if (index % 2 === 0) return rng.int(0, 2) ? createFracPlot({ ...base, whole: rng.int(1, 5), quarters: rng.pick([1, 3]), to: 4 }) : createFracPlot({ ...base, whole: rng.int(1, 5), quarters: 2, to: 2 });
    for (;;) {
      const lo = rng.pick([4, 8]), n = rng.int(8, 12), data = Array.from({ length: n }, () => lo + Math.min(8, Math.floor((rng.int(0, 8) + rng.int(0, 8)) / 2)));
      if (modes(data).length !== 1) continue;
      const ask = (index >> 1) % 2, v = rng.pick([...new Set(data)]);
      return createFracPlot({ ...base, kind: 1, thing: rng.int(0, THINGS.length - 1), lo, data, ask, v });
    }
  },
  restore: raw => {
    const r = raw as Partial<FracPlotProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createFracPlot(r as FracPlotProblem); } catch { return null; }
  },
  display: p => words(p.kind === 0 ? "How long is the crayon?" : answers(p).steps.at(-1)!.question ?? ""),
  picture: p => (p.kind === 0 ? buildFracRuler({ len: 4 * p.whole + p.quarters, max: Math.max(4, p.whole + 1), to: p.to, alt: alt(p) }) : buildLinePlot({ ...plot(p), alt: alt(p) })),
  answers: p => singularWork(answers(p)),
  explain,
  pre: "g2-lineplot",
};
