// Bar graphs: read two bars against the scale, then compare them (how many more) or put them together (in all).
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildBarGraph } from "../../../../explanations/diagrams/early-g2/measure";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { slips, type Slip } from "../kit";
import { words } from "../../gradeK/kit";

/** Four bars (v0 to v3) on a theme; the question is about bars x and y. kind 0 asks how many more, 1 asks how many in all. */
export interface BarGraphProblem { theme: number; v0: number; v1: number; v2: number; v3: number; x: number; y: number; kind: number }

const THEMES = [
  {
    title: "Our favorite fruit", names: ["apples", "bananas", "grapes", "pears"],
    more: (a: string, b: string) => `How many more children picked ${a} than ${b}?`,
    total: (a: string, b: string) => `How many children picked ${a} or ${b}?`,
  },
  {
    title: "Pets in our class", names: ["dogs", "cats", "fish", "birds"],
    more: (a: string, b: string) => `How many more ${a} than ${b} are there?`,
    total: (a: string, b: string) => `How many ${a} and ${b} are there in all?`,
  },
  {
    title: "Weather this month", names: ["sunny", "rainy", "cloudy", "windy"],
    more: (a: string, b: string) => `How many more ${a} days than ${b} days were there?`,
    total: (a: string, b: string) => `How many ${a} and ${b} days were there in all?`,
  },
];

const valuesOf = (p: BarGraphProblem) => [p.v0, p.v1, p.v2, p.v3];

export function createBarGraph(theme: number, v0: number, v1: number, v2: number, v3: number, x: number, y: number, kind: number): BarGraphProblem {
  wholeIn("theme", theme, 0, THEMES.length - 1);
  [v0, v1, v2, v3].forEach((v, i) => wholeIn(`v${i}`, v, 1, 10));
  wholeIn("x", x, 0, 3);
  wholeIn("y", y, 0, 3);
  wholeIn("kind", kind, 0, 1);
  if (x === y) throw new Error("the question needs two different bars");
  const vals = [v0, v1, v2, v3];
  if (kind === 0 && vals[x]! <= vals[y]!) throw new Error("the first bar must be taller to ask how many more");
  return { theme, v0, v1, v2, v3, x, y, kind };
}

/** Early graphs go up to 8 with four different bars, so no first graph is flat; later ones go up to 10. */
function generate(rng: Rng, index: number): BarGraphProblem {
  const top = index < 3 ? 8 : 10;
  for (;;) {
    const v = [rng.int(1, top), rng.int(1, top), rng.int(1, top), rng.int(1, top)];
    if (index < 3 && new Set(v).size < 4) continue;
    const [x, y] = rng.shuffle([0, 1, 2, 3]) as [number, number];
    const kind = rng.int(0, 1);
    if (kind === 0 && v[x]! <= v[y]!) continue;
    return createBarGraph(rng.int(0, THEMES.length - 1), v[0]!, v[1]!, v[2]!, v[3]!, x, y, kind);
  }
}

const questionOf = (p: BarGraphProblem) => {
  const th = THEMES[p.theme]!, a = th.names[p.x]!, b = th.names[p.y]!;
  return p.kind ? th.total(a, b) : th.more(a, b);
};

function readSlips(vals: number[], names: string[], i: number, other: number): Slip[] {
  const v = vals[i]!, name = names[i]!;
  return slips(v, [
    [vals[other]!, "Read the other bar", `That's the ${names[other]} bar. Find the bar named ${name}.`],
    [v + 1, "Read the line above", `That's one line too high. The ${name} bar stops just below that line. Look across from the very top of the bar.`],
    [v - 1, "Read the line below", `That's one line too low. The ${name} bar goes past that line. Look across from the very top of the bar.`],
    ...vals.map((w, j): Slip | false => j !== i && j !== other && [w, "Read a different bar", `That's the ${names[j]} bar. Check the word under each bar for ${name}.`]),
  ]);
}

function answers(p: BarGraphProblem): AnswerModel {
  const vals = valuesOf(p), th = THEMES[p.theme]!, X = th.names[p.x]!, Y = th.names[p.y]!;
  const a = vals[p.x]!, b = vals[p.y]!, more = p.kind === 0, ans = more ? a - b : a + b;
  return {
    steps: [
      oneBox({
        id: "first", label: `Read the ${X} bar`, question: `How tall is the ${X} bar?`,
        prompt: s => [text(`${X}: `), s], ans: a, wrong: readSlips(vals, th.names, p.x, p.y),
        hint: `Find the top of the ${X} bar and look straight across to the numbers.`,
        explain: `The ${X} bar reaches ${a}.`,
      }),
      oneBox({
        id: "second", label: `Read the ${Y} bar`, question: `How tall is the ${Y} bar?`,
        prompt: s => [text(`${Y}: `), s], ans: b, wrong: readSlips(vals, th.names, p.y, p.x),
        hint: `Find the top of the ${Y} bar and look straight across to the numbers.`,
        explain: `The ${Y} bar reaches ${b}.`,
      }),
      oneBox({
        id: "combine", label: more ? "Compare" : "Put them together",
        question: more ? `How much taller is the ${X} bar?` : "Add the two bars.",
        prompt: s => [num(a), op(more ? "−" : "+"), num(b), op("="), s], ans,
        wrong: slips(ans, more
          ? [[a + b, "Added the bars", `"How many more" means compare. Take ${b} away from ${a}.`], [a, "Wrote the bigger bar", `${a} is all of the ${X}. How many more is that than ${b}?`]]
          : [[Math.abs(a - b), "Took away", `"In all" means put them together. Add ${a} and ${b}.`], [Math.max(a, b), "Wrote one bar", "Count both bars together."]]),
        hint: more ? `Count up from ${b} to ${a}.` : `Count on ${b} from ${a}.`,
        explain: more ? `${a} − ${b} = ${ans}.` : `${a} + ${b} = ${ans}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: BarGraphProblem, model: AnswerModel): Explanation {
  const th = THEMES[p.theme]!, X = th.names[p.x]!, Y = th.names[p.y]!, more = p.kind === 0;
  const a = expectedOf(model, "first"), b = expectedOf(model, "second"), r = expectedOf(model, "combine");
  const sum = more ? `${a} − ${b} = ${r}` : `${a} + ${b} = ${r}`;
  return {
    heading: more ? "Compare two bars" : "Add two bars",
    idea: ["Read each bar by looking straight across from its top to the numbers. Then compare or add."],
    statement: [text(questionOf(p))],
    diagram: buildBarGraph({
      title: th.title, names: th.names, values: valuesOf(p), first: p.x, second: p.y, kind: more ? "more" : "total",
      beats: { first: 1, second: 2, combine: 3 },
      text: { first: `${X}: ${a}`, second: `${Y}: ${b}`, combine: sum },
      alt: `A bar graph, ${th.title}: ${th.names.map((n, i) => `${n} ${valuesOf(p)[i]}`).join(", ")}. ${X} is ${a} and ${Y} is ${b}, so ${sum}.`,
    }),
    caption: more ? `The shaded part of the ${X} bar is how many more.` : "Put both bars together.",
    timeline: beats(4),
    steps: [
      { id: "first", narration: `Look across from the top of the ${X} bar: ${a}.`, math: [text(`${X}: `), num(a)], state: 1, answerStep: "first", result: a },
      { id: "second", narration: `Look across from the top of the ${Y} bar: ${b}.`, math: [text(`${Y}: `), num(b)], state: 2, answerStep: "second", result: b },
      { id: "combine", narration: more ? `The ${X} bar is taller by ${a} − ${b} = ${r}.` : `Put them together: ${a} + ${b} = ${r}.`, math: [num(a), op(more ? "−" : "+"), num(b), op("="), num(r)], state: 3, answerStep: "combine", result: r },
    ],
  };
}

export const lesson: LessonDefinition<BarGraphProblem> = {
  id: "g2-bargraph",
  grade: 2,
  unit: "Measurement and data",
  title: "Bar graphs",
  reference: createBarGraph(0, 7, 4, 6, 3, 0, 1, 0),
  generate,
  restore: raw => restoreVia(raw, ["theme", "v0", "v1", "v2", "v3", "x", "y", "kind"] as const,
    v => createBarGraph(v.theme, v.v0, v.v1, v.v2, v.v3, v.x, v.y, v.kind)),
  display: p => words(questionOf(p)),
  displayNote: questionOf,
  lead: questionOf,
  picture: p => {
    const th = THEMES[p.theme]!;
    return buildBarGraph({
      title: th.title, names: th.names, values: valuesOf(p), first: p.x, second: p.y, kind: p.kind ? "total" : "more",
      beats: { first: 1, second: 2, combine: 3 }, text: { first: "", second: "", combine: "" }, bare: true,
      alt: `A bar graph, ${th.title}: ${th.names.map((n, i) => `${n} ${valuesOf(p)[i]}`).join(", ")}.`,
    });
  },
  answers,
  explain,
};
