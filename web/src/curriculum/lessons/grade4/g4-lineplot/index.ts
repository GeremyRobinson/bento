// Line plots with fractions: read lengths in fourths or eighths off a line plot, then subtract, add up, or count.
import { answer, frac, num, op, slot, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildLinePlot } from "../../../../explanations/diagrams/early-g2/lineplot";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { words } from "../../gradeK/kit";
import { slips } from "../_kit";

const THINGS = [
  { many: "ribbons", one: "ribbon", title: "Ribbon lengths" },
  { many: "pencils", one: "pencil", title: "Pencil lengths" },
  { many: "seeds", one: "seed", title: "Bean sprout heights" },
  { many: "nails", one: "nail", title: "Nail lengths" },
];
const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : a);
/** v d-ths in lowest terms as [whole, n, d] */
export const mixedOf = (v: number, d: number): [number, number, number] => { const w = Math.floor(v / d), r = v % d, g = gcd(r, d) || d; return [w, r / g, d / g]; };
const said = (v: number, d: number) => { const [w, n, dd] = mixedOf(v, d); return n ? `${w ? `${w} ` : ""}${n}/${dd}` : String(w); };
const inches = (v: number, d: number) => `${said(v, d)} ${v === d ? "inch" : "inches"}`;

/** d 4 or 8; data in d-ths on a plot from lo to lo + 2d; ask 0 longest − shortest, 1 total of the ones at v, 2 how many longer than v */
export interface FracLineProblem { d: number; thing: number; lo: number; data: number[]; ask: number; v: number }

const howMany = (data: number[], v: number) => data.filter(u => u === v).length;
const modes = (data: number[]) => { const vs = [...new Set(data)], top = Math.max(...vs.map(v => howMany(data, v))); return vs.filter(v => howMany(data, v) === top); };
const finalOf = (p: FracLineProblem) => (p.ask === 0 ? Math.max(...p.data) - Math.min(...p.data) : p.ask === 1 ? howMany(p.data, p.v) * p.v : p.data.filter(u => u > p.v).length);

export function createFracLine(p: FracLineProblem): FracLineProblem {
  if (p.d !== 4 && p.d !== 8) throw new Error("fourths or eighths");
  wholeIn("thing", p.thing, 0, THINGS.length - 1);
  if (p.lo !== 0 && p.lo !== p.d) throw new Error("the plot starts at 0 or 1 inch");
  if (!Array.isArray(p.data) || p.data.length < 8 || p.data.length > 12) throw new Error("8 to 12 X's");
  p.data.forEach((u, i) => wholeIn(`data[${i}]`, u, p.lo + 1, p.lo + 2 * p.d));
  if (modes(p.data).length !== 1) throw new Error("one tallest stack");
  wholeIn("ask", p.ask, 0, 2);
  wholeIn("v", p.v, p.lo + 1, p.lo + 2 * p.d);
  if (p.ask === 1 && !howMany(p.data, p.v)) throw new Error("v has an X");
  if (p.ask < 2) {
    // fraction answers are never whole numbers, so every box has something in it
    const xs = p.ask === 0 ? [Math.max(...p.data), Math.min(...p.data), finalOf(p)] : [p.v, finalOf(p)];
    if (xs.some(x => x % p.d === 0)) throw new Error("not a whole number of inches");
  }
  return { d: p.d, thing: p.thing, lo: p.lo, data: [...p.data], ask: p.ask, v: p.v };
}

/** a mixed-number answer in three boxes; any equal fraction counts (2/4 for 1/2), and the whole box may stay empty below 1 */
function mixedStep(o: { id: string; label: string; question: string; value: number; d: number; lead?: MathText; wrong?: [number, string, string][]; hint: string; explain: string }): AnswerStep {
  const [w, n, dd] = mixedOf(o.value, o.d), target = o.value / o.d;
  const prompt = (W: ReturnType<typeof slot>, N: ReturnType<typeof slot>, D: ReturnType<typeof slot>) => [...(o.lead ?? []), W, frac([N], [D]), text(" in")];
  return {
    id: o.id, label: o.label, question: o.question,
    prompt: prompt(slot("w", true), slot("n"), slot("d")),
    slots: [{ id: "w", expected: w }, { id: "n", expected: n }, { id: "d", expected: dd }],
    known: [],
    check: v => {
      if (v.n == null || v.d == null) return { ok: false, soft: true, message: "Fill in the fraction: top and bottom." };
      if (!v.d) return { ok: false, soft: true, message: "The bottom number can't be 0." };
      const got = (v.w ?? 0) + v.n / v.d;
      if (Math.abs(got - target) < 1e-9) return { ok: true };
      for (const [x, kind, message] of o.wrong ?? []) if (Math.abs(got - x / o.d) < 1e-9) return { ok: false, kind, message, generic: false };
      return { ok: false, kind: o.label, message: `Not quite. ${o.hint}`, generic: true };
    },
    hint: o.hint, explain: o.explain,
    work: prompt(answer("w", w), answer("n", n), answer("d", dd)),
  };
}

function answers(p: FracLineProblem): AnswerModel {
  const th = THINGS[p.thing]!, d = p.d;
  if (p.ask === 0) {
    const hi = Math.max(...p.data), lo = Math.min(...p.data);
    return {
      steps: [
        mixedStep({ id: "max", label: "Longest", question: `How long is the longest ${th.one}?`, value: hi, d, hint: "Find the X farthest to the right.", explain: `The longest is ${inches(hi, d)}.` }),
        mixedStep({ id: "min", label: "Shortest", question: `How long is the shortest ${th.one}?`, value: lo, d, hint: "Find the X farthest to the left.", explain: `The shortest is ${inches(lo, d)}.` }),
        mixedStep({ id: "diff", label: "Difference", question: "How much longer is the longest than the shortest?", value: hi - lo, d,
          wrong: [[hi + lo, "Added", "How much longer means subtract."]],
          hint: `${said(hi, d)} − ${said(lo, d)}. Count the spaces between them on the line.`, explain: `${said(hi, d)} − ${said(lo, d)} = ${said(hi - lo, d)}.` }),
      ],
      finalParts: [-1],
    };
  }
  if (p.ask === 1) {
    const n = howMany(p.data, p.v);
    return {
      steps: [
        oneBox({ id: "count", label: "How many at that length", question: `How many ${th.many} are ${inches(p.v, d)} long?`, prompt: s => [s, text(` ${th.many}`)], ans: n,
          wrong: slips(n, [-1, 1].map(k => [howMany(p.data, p.v + k), "Read the next stack", `That's the stack above ${said(p.v + k, d)}. Find ${said(p.v, d)} first.`] as [number, string, string])),
          hint: `Find ${said(p.v, d)} on the line and count the X's.`, explain: `${n} X's above ${said(p.v, d)}.` }),
        mixedStep({ id: "total", label: "Total length", question: `Laid end to end, how long are those ${th.many} in all?`, value: n * p.v, d, lead: [num(n), op("×")],
          wrong: [[n * d, "Gave the count", `That's how many. Each one is ${said(p.v, d)} long: add ${said(p.v, d)} ${n} times.`]],
          hint: `${n} × ${said(p.v, d)}: add ${said(p.v, d)} ${n} times.`, explain: `${n} × ${said(p.v, d)} = ${said(n * p.v, d)} inches.` }),
      ],
      finalParts: [-1],
    };
  }
  const n = p.data.filter(u => u > p.v).length, ge = p.data.filter(u => u >= p.v).length;
  return { steps: [oneBox({ id: "longer", label: "Count", question: `How many ${th.many} are longer than ${inches(p.v, d)}?`, prompt: s => [s, text(` ${th.many}`)], ans: n,
    wrong: slips(n, [[ge, `Counted ${said(p.v, d)} too`, `Longer than ${said(p.v, d)} doesn't include ${said(p.v, d)} itself.`]]),
    hint: `Count the X's to the right of ${said(p.v, d)}.`, explain: `${n} X's to the right of ${said(p.v, d)}.` })], finalParts: [-1] };
}

const plot = (p: FracLineProblem) => ({ d: p.d, lo: p.lo, hi: p.lo + 2 * p.d, data: p.data, title: THINGS[p.thing]!.title });
const alt = (p: FracLineProblem) => `A line plot of ${THINGS[p.thing]!.one} lengths, marked in ${p.d === 4 ? "fourths" : "eighths"} of an inch.`;

function explain(p: FracLineProblem, model: AnswerModel): Explanation {
  const last = model.steps.at(-1)!;
  const lit = p.ask === 0 ? [Math.max(...p.data), Math.min(...p.data)] : p.ask === 1 ? [p.v] : [...new Set(p.data.filter(u => u > p.v))];
  return {
    heading: "Line plots with fractions",
    idea: ["When the measurements are fractions, the line plot is marked in halves, fourths or eighths. You can add and subtract the lengths you read."],
    statement: words(last.question ?? ""),
    diagram: buildLinePlot({ ...plot(p), beats: { drop: 0, light: 1 }, light: lit, alt: `${alt(p)} The X's drop in, then the stacks the question is about light up.` }),
    caption: `${last.explain}`,
    timeline: beats(2),
    steps: [
      { id: "drop", narration: "Each thing measured drops an X above its length.", math: words(THINGS[p.thing]!.title), state: 0 },
      ...model.steps.map(s => ({ id: s.id, narration: s.explain, math: s.work, state: 1, answerStep: s.id, result: s.slots.at(-1)!.expected! })),
    ],
  };
}

export const lesson: LessonDefinition<FracLineProblem> = {
  id: "g4-lineplot",
  grade: 4,
  unit: "Measurement",
  title: "Line plots with fractions",
  reference: createFracLine({ d: 4, thing: 0, lo: 0, data: [3, 5, 5, 6, 5, 7, 2, 6, 5], ask: 0, v: 5 }),
  generate: (rng, index) => {
    const early = index < 3, d = early ? 4 : rng.pick([4, 8]), ask = early ? 0 : index % 3;
    for (;;) {
      const lo = early ? 0 : rng.pick([0, d]), n = rng.int(8, 12);
      const span = early ? d - 1 : 2 * d, data = Array.from({ length: n }, () => lo + 1 + Math.min(span - 1, Math.floor((rng.int(0, span - 1) + rng.int(0, span - 1)) / 2)));
      const v = rng.pick([...new Set(data)]);
      try { return createFracLine({ d, thing: rng.int(0, THINGS.length - 1), lo, data, ask, v }); } catch { /* new data */ }
    }
  },
  restore: raw => {
    const r = raw as Partial<FracLineProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createFracLine(r as FracLineProblem); } catch { return null; }
  },
  display: p => words(answers(p).steps.at(-1)!.question ?? ""),
  picture: p => buildLinePlot({ ...plot(p), alt: alt(p) }),
  answers,
  explain,
  pre: "g3-lineplot",
};
