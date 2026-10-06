// Line plots: an X above the number line for each thing measured. Read a stack, find the tallest, count the ones
// longer than a length, or find how much longer the longest is than the shortest.
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildLinePlot } from "../../../../explanations/diagrams/early-g2/lineplot";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { tapStep, words, singularWork } from "../../gradeK/kit";
import { count, slips } from "../kit";

const THINGS = [
  { many: "pencils", one: "pencil", title: "Pencil lengths" },
  { many: "leaves", one: "leaf", title: "Leaf lengths" },
  { many: "ribbons", one: "ribbon", title: "Ribbon lengths" },
  { many: "worms", one: "worm", title: "Worm lengths" },
];

/** data: whole-inch lengths from lo to lo + 5. ask 0 how many are v long; 1 which length came up most; 2 how many are longer than v; 3 longest − shortest */
export interface LinePlotProblem { thing: number; lo: number; data: number[]; ask: number; v: number }

const howMany = (data: number[], v: number) => data.filter(u => u === v).length;
const modeOf = (data: number[]) => {
  const vs = [...new Set(data)], top = Math.max(...vs.map(v => howMany(data, v)));
  return vs.filter(v => howMany(data, v) === top);
};

export function createLinePlot(thing: number, lo: number, data: number[], ask: number, v: number): LinePlotProblem {
  wholeIn("thing", thing, 0, THINGS.length - 1);
  wholeIn("lo", lo, 2, 8);
  if (!Array.isArray(data) || data.length < 8 || data.length > 12) throw new Error("8 to 12 measurements");
  data.forEach((u, i) => wholeIn(`data[${i}]`, u, lo, lo + 5));
  if (modeOf(data).length !== 1) throw new Error("exactly one tallest stack");
  wholeIn("ask", ask, 0, 3);
  wholeIn("v", v, lo, lo + 5);
  if (ask === 0 && !howMany(data, v)) throw new Error("v has at least one X");
  if (ask === 2 && !data.some(u => u > v)) throw new Error("something is longer than v");
  return { thing, lo, data: [...data], ask, v };
}

function answers(p: LinePlotProblem): AnswerModel {
  const th = THINGS[p.thing]!, d = p.data, v = p.v;
  if (p.ask === 0) {
    // plot one more first, so the X is something the learner does; then read the stack with the new X in it
    const n = howMany(d, v) + 1, spots = [v - 1, v, v + 1], said = (x: number) => `Above ${x}`;
    return { steps: [
      tapStep({
        id: "plot", label: "Plot one more", question: `A new ${th.one} is ${v} inches long. Where does its X go?`,
        prompt: words(`The new X goes ?`), choices: spots.map(said), right: 1,
        wrong: i => [`Put it above ${spots[i]}`, `That's above ${spots[i]}. Find ${v} on the line: the X goes right above it.`],
        hint: `Find ${v} on the number line. Each X sits above its own length.`,
        explain: `The new ${th.one} is ${v} inches, so its X goes on top of the stack above ${v}.`,
        work: [text(`Above ${v}`)],
      }),
      oneBox({
        id: "stack", label: "Read a stack", question: `Now how many ${th.many} are ${v} inches long?`,
        prompt: s => [s, text(` ${th.many}`)], ans: n,
        wrong: slips(n, [
          [n - 1, "Left out the new X", `Count the new ${th.one} too: its X is on top of the stack.`],
          [howMany(d, v - 1), "Read the next stack", `That's the stack above ${v - 1}. Find ${v} on the line first.`],
          [howMany(d, v + 1), "Read the next stack", `That's the stack above ${v + 1}. Find ${v} on the line first.`],
          [d.length + 1, "Counted every X", `That's every ${th.one}. Count only the X's above ${v}.`],
        ]),
        hint: `Find ${v} on the line. Count the X's above it, the new one too.`,
        explain: `There ${n === 1 ? "is 1 X" : `are ${n} X's`} above ${v}: ${count(n, th.one, th.many)}.`,
      }),
    ], finalParts: [-1] };
  }
  if (p.ask === 1) {
    const m = modeOf(d)[0]!, n = howMany(d, m);
    return { steps: [oneBox({
      id: "mode", label: "Tallest stack", question: "Which length came up most?",
      prompt: s => [s, text(" inches")], ans: m,
      wrong: slips(m, [
        [n, "Gave the number of X's", "That's how many X's. The question asks which length: read the number under the stack."],
        [m - 1, "Read the number beside it", `That number is next to the tallest stack. Read the number right under it.`],
        [m + 1, "Read the number beside it", `That number is next to the tallest stack. Read the number right under it.`],
      ]),
      hint: "Find the tallest stack. Read the number under it.",
      explain: `The tallest stack, ${count(n, "X", "X's")}, is above ${m}. ${m} inches came up most.`,
    })], finalParts: [-1] };
  }
  if (p.ask === 2) {
    const n = d.filter(u => u > v).length, ge = d.filter(u => u >= v).length;
    return { steps: [oneBox({
      id: "longer", label: "Count the stacks", question: `How many ${th.many} are longer than ${v} inches?`,
      prompt: s => [s, text(` ${th.many}`)], ans: n,
      wrong: slips(n, [[ge, `Counted ${v} too`, `Longer than ${v} doesn't include ${v} itself.`]]),
      hint: `Count the X's to the right of ${v}, not above it.`,
      explain: `${count(n, "X", "X's")} to the right of ${v}: ${count(n, th.one, th.many)}.`,
    })], finalParts: [-1] };
  }
  const hi = Math.max(...d), lo = Math.min(...d);
  const steps: AnswerStep[] = [
    oneBox({ id: "max", label: "Longest", question: `How long is the longest ${th.one}?`, prompt: s => [s, text(" inches")], ans: hi,
      wrong: slips(hi, [
        [modeOf(d)[0]!, "Read the tallest stack", "The tallest stack is the most common length. The longest is the X farthest right."],
        [lo, "Read the shortest", "That's the X farthest left, the shortest. The longest is farthest right."],
        [p.lo + 6, "Read the end of the line", "Read the farthest-right X, not the end of the line."],
      ]),
      hint: "Find the X farthest to the right.", explain: `The longest is ${hi} inches.` }),
    oneBox({ id: "min", label: "Shortest", question: `How long is the shortest ${th.one}?`, prompt: s => [s, text(" inches")], ans: lo,
      wrong: slips(lo, [
        [p.lo - 1, "Read the start of the line", "Read the farthest-left X, not the start of the line."],
        [hi, "Read the longest", "That's the X farthest right, the longest. The shortest is farthest left."],
      ]),
      hint: "Find the X farthest to the left.", explain: `The shortest is ${lo} inches.` }),
    oneBox({ id: "diff", label: "How much longer", question: "How much longer is the longest than the shortest?",
      prompt: s => [num(hi), op("−"), num(lo), op("="), s, text(" inches")], ans: hi - lo,
      wrong: slips(hi - lo, [[hi + lo, "Added", "How much longer means the difference. Subtract."]]),
      hint: "Subtract the shortest from the longest.", explain: `${hi} − ${lo} = ${hi - lo}. The longest is ${count(hi - lo, "inch", "inches")} longer.` }),
  ];
  return { steps, finalParts: [-1] };
}

const lit = (p: LinePlotProblem) => {
  const d = p.data;
  if (p.ask === 0) return [p.v];
  if (p.ask === 1) return modeOf(d);
  if (p.ask === 2) return [...new Set(d.filter(u => u > p.v))];
  return [Math.max(...d), Math.min(...d)];
};
/** the plot; on the lesson page of a read-a-stack problem it has the learner's new X in it too */
const plot = (p: LinePlotProblem, withNew = false) => ({ d: 1, lo: p.lo - 1, hi: p.lo + 6, data: withNew && p.ask === 0 ? [...p.data, p.v] : p.data, title: THINGS[p.thing]!.title });
const alt = (p: LinePlotProblem) => `A line plot of ${THINGS[p.thing]!.one} lengths in inches.`;

function explain(p: LinePlotProblem, model: AnswerModel): Explanation {
  const last = model.steps.at(-1)!;
  return {
    heading: "Line plots",
    idea: ["A line plot puts an X above the number line for each thing measured. Tall stacks show the lengths that came up most."],
    statement: words(last.question ?? ""),
    diagram: buildLinePlot({ ...plot(p, true), beats: { drop: 0, light: 1 }, light: lit(p),
      alt: `${alt(p)} Each ${THINGS[p.thing]!.one} drops an X above its length, then the stacks the question is about light up.` }),
    caption: `${last.explain}`,
    timeline: beats(2),
    steps: [
      { id: "drop", narration: `Each ${THINGS[p.thing]!.one} is measured, and an X goes above its length.${p.ask === 0 ? ` The new one is ${p.v} inches, so its X goes above ${p.v}.` : ""}`, math: words(THINGS[p.thing]!.title), state: 0 },
      ...model.steps.map(s => ({ id: s.id, narration: s.explain, math: s.work ?? [num(s.slots[0]!.expected as number)], state: 1, answerStep: s.id, result: s.slots[0]!.expected! })),
    ],
  };
}

export const lesson: LessonDefinition<LinePlotProblem> = {
  id: "g2-lineplot",
  grade: 2,
  unit: "Measurement and data",
  title: "Line plots",
  reference: createLinePlot(0, 4, [5, 6, 5, 7, 4, 5, 6, 8, 5, 6], 0, 6),
  generate: (rng, index) => {
    const early = index < 3, ask = early ? index % 2 : index % 4, size = early ? 8 : rng.int(8, 12);
    for (;;) {
      const lo = rng.int(2, 8), data = Array.from({ length: size }, () => lo + Math.min(5, Math.floor(Math.abs(rng.int(0, 5) + rng.int(0, 5)) / 2)));
      if (modeOf(data).length !== 1) continue;
      const vs = [...new Set(data)];
      const v = ask === 2 ? rng.pick(vs.filter(u => data.some(w => w > u))) : rng.pick(vs);
      if (v == null) continue;
      return createLinePlot(rng.int(0, THINGS.length - 1), lo, data, ask, v);
    }
  },
  restore: raw => {
    const r = raw as Partial<LinePlotProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createLinePlot(r.thing as number, r.lo as number, r.data as number[], r.ask as number, r.v as number); } catch { return null; }
  },
  display: p => words(p.ask === 0
    ? `Add a ${THINGS[p.thing]!.one} that is ${p.v} inches long. Then how many ${THINGS[p.thing]!.many} are ${p.v} inches long?`
    : answers(p).steps.at(-1)!.question ?? ""),
  picture: p => buildLinePlot({ ...plot(p), alt: alt(p) }),
  answers: p => singularWork(answers(p)),
  explain,
  pre: "g2-measure",
};
