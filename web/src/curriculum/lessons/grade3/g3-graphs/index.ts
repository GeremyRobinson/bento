// Scaled picture and bar graphs: read the key (or the axis) first, then read a row or bar, compare two or add them.
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildRows, buildScaledBars, type Icon } from "../../../../explanations/diagrams/early-g1/data";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { words, singularWork } from "../../gradeK/kit";
import { slips } from "../../grade2/kit";

interface Theme { title: string; names: string[]; icon: Icon; things: string }
const THEMES: Theme[] = [
  { title: "Books read this month", names: ["Ana", "Ben", "Cleo", "Dev"], icon: "star", things: "books" },
  { title: "Favorite fruit", names: ["Apples", "Pears", "Plums", "Kiwis"], icon: "apple", things: "votes" },
  { title: "Pets at our school", names: ["Dogs", "Cats", "Fish", "Birds"], icon: "paw", things: "pets" },
  { title: "Cookies sold", names: ["Mon", "Tue", "Wed", "Thu"], icon: "cookie", things: "cookies" },
];
const SCALES = [2, 5, 10];

/** type 0 picture graph, 1 bar graph; each picture or grid line stands for `scale`; ask 0 how many in x, 1 x − y, 2 x + y */
export interface GraphProblem { type: number; scale: number; theme: number; counts: number[]; ask: number; x: number; y: number }

/** the smallest amount a row or bar can show: a half picture for scale 2, a bar halfway between lines for 2 and 10 */
const grain = (type: number, scale: number) => (type === 0 ? (scale === 2 ? 1 : scale) : scale === 5 ? 5 : scale / 2);
const most = (type: number, scale: number) => (type === 0 ? 9 * scale : 8 * scale);

export function createGraph(type: number, scale: number, theme: number, counts: number[], ask: number, x: number, y: number): GraphProblem {
  wholeIn("type", type, 0, 1);
  if (!SCALES.includes(scale)) throw new Error("scale 2, 5 or 10");
  wholeIn("theme", theme, 0, THEMES.length - 1);
  if (!Array.isArray(counts) || counts.length !== 4) throw new Error("4 counts");
  const g = grain(type, scale);
  counts.forEach((c, i) => { wholeIn(`counts[${i}]`, c, g, most(type, scale)); if (c % g) throw new Error("a count the graph can show"); });
  wholeIn("ask", ask, 0, 2);
  wholeIn("x", x, 0, 3);
  wholeIn("y", y, 0, 3);
  if (ask > 0 && x === y) throw new Error("two different rows");
  if (ask === 1 && counts[x]! <= counts[y]!) throw new Error("x has more");
  return { type, scale, theme, counts: [...counts], ask, x, y };
}

function readSteps(p: GraphProblem, i: number, id: string): AnswerStep[] {
  const th = THEMES[p.theme]!, c = p.counts[i]!, s = p.scale, name = th.names[i]!;
  if (p.type === 1) {
    const below = Math.floor(c / s) * s;
    return [oneBox({
      id, label: `Read ${name}`, question: `How many ${th.things} for ${name}?`,
      prompt: q => [text(`${name}: `), q], ans: c,
      wrong: slips(c, [
        [c / s, "Counted the lines", `Each line is ${s}, so count by ${s}s.`],
        below !== c && [below, "Missed the half", `The bar ends halfway between ${below} and ${below + s}. Halfway is ${below + s / 2}.`],
        ...p.counts.flatMap((v, k) => (k === i ? [] : [[v, "Read another bar", `That's the ${th.names[k]} bar.`] as [number, string, string]])),
      ]),
      hint: `Follow the top of the ${name} bar across to the side.`,
      explain: `The ${name} bar reaches ${c}.`,
    })];
  }
  const whole = Math.floor(c / s), half = c % s !== 0;
  return [
    oneBox({
      id: `${id}-pics`, label: "Count pictures", question: half ? `How many whole pictures for ${name}?` : `How many pictures for ${name}?`,
      prompt: q => [q, text(" pictures")], ans: whole,
      wrong: slips(whole, [half && [whole + 1, "Counted the half as whole", "The last picture is only half. Count the whole ones."], ...p.counts.flatMap((v, k) => (k === i ? [] : [[Math.floor(v / s), "Counted another row", `That's the ${th.names[k]} row.`] as [number, string, string]]))]),
      hint: `Count the pictures in the ${name} row.`,
      explain: `${whole} whole ${whole === 1 ? "picture" : "pictures"}${half ? " and a half" : ""}.`,
    }),
    oneBox({
      id, label: `How many ${name}`, question: `How many ${th.things} for ${name}?`,
      prompt: q => [num(whole), op("×"), num(s), ...(half ? [op("+"), num(s / 2)] : []), op("="), q], ans: c,
      wrong: slips(c, [[whole, "Counted pictures, not things", `Each picture is ${s}, so ${whole} ${whole === 1 ? "picture" : "pictures"} is ${whole} × ${s}.`], half && [whole * s, "Forgot the half picture", `Don't forget the half picture: half of ${s} is ${s / 2}.`]]),
      hint: `Each picture is ${s}.`,
      explain: `${whole} × ${s}${half ? ` + ${s / 2}` : ""} = ${c}.`,
    }),
  ];
}

function answers(p: GraphProblem): AnswerModel {
  const th = THEMES[p.theme]!, s = p.scale, c = p.counts, a = c[p.x]!, b = c[p.y]!;
  const first = p.type === 0
    ? oneBox({ id: "key", label: "Read the key", question: `Each picture stands for how many ${th.things}?`, prompt: q => [text("1 picture = "), q], ans: s,
      wrong: slips(s, [[1, "Took a picture as 1", `Look at the key: one picture means ${s}.`]]), hint: "Look at the key under the graph.", explain: `The key says each picture is ${s} ${th.things}.` })
    : oneBox({ id: "scale", label: "Read the scale", question: "How much does each line on the side go up by?", prompt: q => [text("Each line: "), q], ans: s,
      wrong: slips(s, [[1, "Took a line as 1", `Read the numbers on the side: 0, ${s}, ${2 * s}. They go up by ${s}.`]]), hint: "Read the numbers up the side.", explain: `The lines go up by ${s}.` });
  const steps: AnswerStep[] = [first, ...readSteps(p, p.x, "x")];
  if (p.ask === 1) steps.push(...readSteps(p, p.y, "y"), oneBox({
    id: "more", label: "Find the difference", question: `How many more for ${th.names[p.x]} than ${th.names[p.y]}?`,
    prompt: q => [num(a), op("−"), num(b), op("="), q], ans: a - b,
    wrong: slips(a - b, [[a + b, "Added", "How many more means the difference. Subtract."]]),
    hint: "Subtract the smaller from the bigger.", explain: `${a} − ${b} = ${a - b}.`,
  }));
  if (p.ask === 2) steps.push(...readSteps(p, p.y, "y"), oneBox({
    id: "both", label: "Put them together", question: `How many for ${th.names[p.x]} and ${th.names[p.y]} together?`,
    prompt: q => [num(a), op("+"), num(b), op("="), q], ans: a + b,
    wrong: slips(a + b, [[Math.abs(a - b), "Subtracted", "Together means add."]]),
    hint: "Add the two.", explain: `${a} + ${b} = ${a + b}.`,
  }));
  return { steps, finalParts: [-1] };
}

const alt = (p: GraphProblem) => `A ${p.type ? "bar graph" : "picture graph"} of ${THEMES[p.theme]!.title.toLowerCase()}. ${p.type ? `The side goes up by ${p.scale}.` : `The key says each picture is ${p.scale}.`}`;
const rows = (p: GraphProblem) => (p.ask === 0 ? [p.x] : [p.x, p.y]);

function diagram(p: GraphProblem, learn: boolean) {
  const th = THEMES[p.theme]!;
  if (p.type === 1) return buildScaledBars({ title: th.title, names: th.names, counts: p.counts, scale: p.scale, ...(learn ? { beats: { grow: 0, read: 1 }, read: rows(p) } : {}), alt: alt(p) });
  return buildRows({ kind: "pictures", title: th.title, names: th.names, counts: p.counts, icon: th.icon, scale: p.scale, things: th.things,
    ...(learn ? { beats: { fill: 0, read: 1 }, read: rows(p) } : {}), alt: alt(p) });
}

function explain(p: GraphProblem, model: AnswerModel): Explanation {
  const last = model.steps.at(-1)!;
  return {
    heading: "Scaled graphs",
    idea: ["In a scaled graph, one picture or one square can stand for more than one thing. Read the key first."],
    statement: words(last.question ?? ""),
    diagram: diagram(p, true),
    caption: `${last.explain}`,
    timeline: beats(2),
    steps: [
      { id: "look", narration: p.type ? `The side goes up by ${p.scale}.` : `The key: each picture is ${p.scale}.`, math: words(THEMES[p.theme]!.title), state: 0 },
      ...model.steps.map(s => ({ id: s.id, narration: s.explain, math: s.work ?? [], state: 1, answerStep: s.id, result: s.slots[0]!.expected! })),
    ],
  };
}

export const lesson: LessonDefinition<GraphProblem> = {
  id: "g3-graphs",
  grade: 3,
  unit: "Data",
  title: "Scaled picture and bar graphs",
  reference: createGraph(0, 2, 1, [7, 4, 10, 5], 0, 0, 1),
  generate: (rng, index) => {
    const early = index < 3, type = early ? 0 : index % 2;
    // bar graphs take turns through the scales, so two in a row never share one
    const scale = early ? rng.pick([2, 5]) : type ? SCALES[(index >> 1) % 3]! : rng.pick(SCALES);
    const ask = early ? 0 : index % 3, g = grain(type, scale), hi = most(type, scale) / g;
    for (;;) {
      const counts = rng.shuffle(Array.from({ length: hi }, (_, i) => (i + 1) * g)).slice(0, 4), x = rng.int(0, 3);
      const y = rng.pick([0, 1, 2, 3].filter(i => i !== x));
      if (ask === 1 && counts[x]! <= counts[y]!) continue;
      return createGraph(type, scale, rng.int(0, THEMES.length - 1), counts, ask, x, y);
    }
  },
  restore: raw => {
    const r = raw as Partial<GraphProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createGraph(r.type as number, r.scale as number, r.theme as number, r.counts as number[], r.ask as number, r.x as number, r.y as number); } catch { return null; }
  },
  display: p => words(answers(p).steps.at(-1)!.question ?? ""),
  picture: p => diagram(p, false),
  answers: p => singularWork(answers(p)),
  explain,
  pre: "g2-bargraph",
};
