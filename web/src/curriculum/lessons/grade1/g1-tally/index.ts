// Tally charts: read a row by counting bundles of 5, compare two rows, or add them all.
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildRows } from "../../../../explanations/diagrams/early-g1/data";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { slips, words } from "../../gradeK/kit";
import { THEMES, checkCounts, moreStep, readRow } from "../_data";

/** ask 0 reads row x; 1 how many more in x than y; 2 how many in all */
export interface TallyProblem { theme: number; counts: number[]; ask: number; x: number; y: number }

export function createTally(theme: number, counts: number[], ask: number, x: number, y: number): TallyProblem {
  wholeIn("theme", theme, 0, THEMES.length - 1);
  const c = checkCounts(counts, 3, 1, 14);
  wholeIn("ask", ask, 0, 2);
  wholeIn("x", x, 0, 2);
  wholeIn("y", y, 0, 2);
  if (ask === 1 && (x === y || c[x]! <= c[y]!)) throw new Error("x has more than y");
  if (ask === 2 && c[0]! + c[1]! + c[2]! > 20) throw new Error("in all is 20 at most");
  return { theme, counts: c, ask, x, y };
}

function readBundles(p: TallyProblem): AnswerStep[] {
  const th = THEMES[p.theme]!, n = p.counts[p.x]!, five = Math.floor(n / 5), rest = n % 5;
  if (n < 5) return [readRow("all", th, p.counts, p.x)];
  return [
    oneBox({
      id: "bundles", label: "Count the bundles", question: "How many bundles of 5?",
      prompt: s => [text("Bundles: "), s], ans: five,
      wrong: slips(five, [[five * 5, "Counted the marks in the bundles", "That's how many marks are in the bundles. How many bundles are there?"]]),
      hint: "A bundle is 4 marks with a line across them.", explain: `There ${five === 1 ? "is 1 bundle" : `are ${five} bundles`} of 5.`,
    }),
    oneBox({
      id: "rest", label: "Count the rest", question: "How many single marks are left?",
      prompt: s => [text("Single marks: "), s], ans: rest,
      wrong: slips(rest, [[rest + 1, "Counted the line across", "The line across is the 5th mark of its bundle, not an extra one."]]),
      hint: "Count the marks that aren't in a bundle.", explain: `${rest} single ${rest === 1 ? "mark" : "marks"}.`,
    }),
    oneBox({
      id: "all", label: "How many in all", question: `How many ${th.nouns[p.x]}?`,
      prompt: s => [text(`${th.names[p.x]}: `), s], ans: n,
      wrong: slips(n, [
        [five + rest, "Counted a bundle as 1", `Each bundle is 5, not 1. Count ${Array.from({ length: five }, (_, i) => 5 * (i + 1)).join(", ")}, then count on.`],
        [n - 1, "Counted one short", "Count by 5s for the bundles, then count on."],
        [n + 1, "Counted one too many", "Count by 5s for the bundles, then count on."],
      ]),
      hint: "Count by 5s for the bundles, then count on.",
      explain: `${Array.from({ length: five }, (_, i) => 5 * (i + 1)).join(", ")}${rest ? `, then ${Array.from({ length: rest }, (_, i) => five * 5 + i + 1).join(", ")}` : ""}. That's ${n}.`,
    }),
  ];
}

function answers(p: TallyProblem): AnswerModel {
  const th = THEMES[p.theme]!, c = p.counts;
  if (p.ask === 0) return { steps: readBundles(p), finalParts: [-1] };
  if (p.ask === 1) return { steps: [readRow("x", th, c, p.x), readRow("y", th, c, p.y), moreStep(th, c, p.x, p.y)], finalParts: [-1] };
  const sum = c[0]! + c[1]! + c[2]!;
  return {
    steps: [
      ...c.map((_, i) => readRow(`row${i}`, th, c, i)),
      oneBox({
        id: "total", label: "Add them all", question: "How many in all?",
        prompt: s => [num(c[0]!), op("+"), num(c[1]!), op("+"), num(c[2]!), op("="), s], ans: sum,
        wrong: slips(sum, c.map((v, i) => [sum - v, "Left out a row", `You left out the ${th.names[i]} row. Add all three.`] as [number, string, string])),
        hint: "Add all three rows.", explain: `${c[0]} + ${c[1]} + ${c[2]} = ${sum}.`,
      }),
    ],
    finalParts: [-1],
  };
}

const rowsRead = (p: TallyProblem) => (p.ask === 0 ? [p.x] : p.ask === 1 ? [p.x, p.y] : [0, 1, 2]);
const alt = (p: TallyProblem) => `A tally chart of ${THEMES[p.theme]!.title.toLowerCase()}: ${THEMES[p.theme]!.names.join(", ")}.`;

function explain(p: TallyProblem, model: AnswerModel): Explanation {
  const th = THEMES[p.theme]!, last = model.steps.at(-1)!, ans = last.slots[0]!.expected!;
  return {
    heading: "Tally marks",
    idea: ["A tally mark is one line for each thing. Every fifth line goes across the four before it, so you can count by 5s."],
    statement: words(last.question ?? ""),
    diagram: buildRows({ kind: "tally", title: th.title, names: th.names, counts: p.counts, icon: th.icon, read: rowsRead(p), beats: { fill: 0, read: 1 },
      alt: `${alt(p)} The marks go up one at a time, then ${rowsRead(p).map(i => `${th.names[i]} is counted: ${p.counts[i]}`).join(", ")}.` }),
    caption: `${last.explain}`,
    timeline: beats(2),
    steps: [
      { id: "fill", narration: "Each thing adds one mark. The fifth mark goes across the other four.", math: words(th.title), state: 0 },
      ...model.steps.map(s => ({ id: s.id, narration: s.explain, math: s.work, state: 1, answerStep: s.id, result: s.slots[0]!.expected! })),
    ].map((s, i, all) => (i === all.length - 1 ? { ...s, result: ans } : s)),
  };
}

export const lesson: LessonDefinition<TallyProblem> = {
  id: "g1-tally",
  grade: 1,
  unit: "Data",
  title: "Tally charts",
  reference: createTally(0, [7, 4, 9], 0, 0, 1),
  generate: (rng, index) => {
    const early = index < 3, hi = early ? 9 : 14;
    for (;;) {
      const counts = rng.shuffle(Array.from({ length: hi }, (_, i) => i + 1)).slice(0, 3);
      const ask = early ? 0 : index % 3, x = rng.int(0, 2);
      if (ask === 2 && counts.reduce((a, b) => a + b, 0) > 20) continue;
      if (ask === 1) {
        const y = rng.pick([0, 1, 2].filter(i => i !== x));
        if (counts[x]! <= counts[y]!) continue;
        return createTally(rng.int(0, THEMES.length - 1), counts, 1, x, y);
      }
      return createTally(rng.int(0, THEMES.length - 1), counts, ask, x, (x + 1) % 3);
    }
  },
  restore: raw => {
    const r = raw as Partial<TallyProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createTally(r.theme as number, r.counts as number[], r.ask as number, r.x as number, r.y as number); } catch { return null; }
  },
  display: p => words(answers(p).steps.at(-1)!.question ?? ""),
  picture: p => buildRows({ kind: "tally", title: THEMES[p.theme]!.title, names: THEMES[p.theme]!.names, counts: p.counts, icon: THEMES[p.theme]!.icon, alt: alt(p) }),
  answers,
  explain,
  pre: "k-sort",
};
