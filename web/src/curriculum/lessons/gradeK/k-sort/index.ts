// Sort and count: count each kind of thing in a mixed-up pile, then say which group has the most (or the fewest).
import { num, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildSort, type Glyph } from "../../../../explanations/diagrams/early-k/sort";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { countUp, slips, tapStep, words } from "../kit";
import { count } from "../../../text";

/** looks: what this kind of thing looks like, so a sorting slip can say why it belongs with its group */
interface Kind { glyph: Glyph; one: string; many: string; looks: string }
const KINDS: Kind[][] = [
  [{ glyph: "button", one: "button", many: "buttons", looks: "It is round with 4 little holes" },
    { glyph: "leaf", one: "leaf", many: "leaves", looks: "It has a pointed tip and a line down the middle" },
    { glyph: "block", one: "block", many: "blocks", looks: "It has 4 corners and a little square in the middle" }],
  [{ glyph: "circle", one: "circle", many: "circles", looks: "It is round all the way, with no corners" },
    { glyph: "square", one: "square", many: "squares", looks: "It has 4 corners and 4 straight sides" },
    { glyph: "triangle", one: "triangle", many: "triangles", looks: "It has 3 corners and 3 straight sides" }],
];
/** the thing the learner sorts first: the first one of a group that turns with the problem */
const pickOf = (p: SortProblem) => ({ group: (p.theme + p.counts[0]!) % p.counts.length, item: 0 });
const cap = (s: string) => s[0]!.toUpperCase() + s.slice(1);

/** by 0 sorts kinds of things, 1 shapes; counts holds one count per kind; theme turns which kinds come first; ask 1 asks for the fewest */
export interface SortProblem { by: number; counts: number[]; theme: number; ask: number }

export function createSort(by: number, counts: number[], theme: number, ask: number): SortProblem {
  wholeIn("by", by, 0, 1);
  wholeIn("theme", theme, 0, 2);
  wholeIn("ask", ask, 0, 1);
  if (!Array.isArray(counts) || counts.length < 2 || counts.length > 3) throw new Error("two or three kinds");
  counts.forEach((c, i) => wholeIn(`counts[${i}]`, c, 1, 8));
  if (new Set(counts).size !== counts.length) throw new Error("every group has a different count");
  if (counts.reduce((a, b) => a + b, 0) > 15) throw new Error("15 things at most");
  return { by, counts: [...counts], theme, ask };
}

const kindsOf = (p: SortProblem) => { const all = KINDS[p.by]!; return p.counts.map((_, i) => all[(i + p.theme) % 3]!); };

function answers(p: SortProblem): AnswerModel {
  const kinds = kindsOf(p), total = p.counts.reduce((a, b) => a + b, 0);
  const pick = p.ask ? Math.min(...p.counts) : Math.max(...p.counts), other = p.ask ? Math.max(...p.counts) : Math.min(...p.counts);
  const right = p.counts.indexOf(pick), word = p.ask ? "fewest" : "most";
  const g = pickOf(p).group, k0 = kinds[g]!;
  return {
    steps: [
      tapStep({
        id: "sort", label: "Sort one", question: "Which group does the ringed one go in?",
        prompt: words("The ringed one goes with the ?"), choices: kinds.map(k => cap(k.many)), right: g,
        wrong: () => ["Put it in the wrong group", `${k0.looks}, like the ${k0.many}.`],
        hint: "Look at its shape. Which things look just like it?",
        explain: `${k0.looks}, so it goes with the ${k0.many}.`,
        work: [text(`It goes with the ${k0.many}.`)],
      }),
      ...p.counts.map((n, i) => {
        const k = kinds[i]!;
        return oneBox({
          id: `count${i}`, label: `Count the ${k.many}`, question: `How many ${k.many}?`,
          prompt: x => [text(`${cap(k.many)}: `), x], ans: n,
          wrong: slips(n, [
            [total, "Counted everything", `That's all of them. Count only the ${k.many}.`],
            ...(n > 1 ? [[n - 1, "Skipped one", `One short. Touch each ${k.one} as you count.`] as [number, string, string]] : []),
            [n + 1, "Counted one twice", `One too many. Touch each ${k.one} only once.`],
          ]),
          hint: `Find every ${k.one}. Touch each one as you count.`,
          explain: `${countUp(1, n)}. There ${n === 1 ? "is" : "are"} ${count(n, k.one, k.many)}.`,
        });
      }),
      tapStep({
        id: "compare", label: `Which has the ${word}?`, question: `Which group has the ${word}?`,
        prompt: [...p.counts.flatMap((n, i) => [...(i ? [text(", ")] : []), num(n), text(` ${n === 1 ? kinds[i]!.one : kinds[i]!.many}`)])],
        choices: kinds.map(k => cap(k.many)), right,
        wrong: i => p.counts[i] === other
          ? [`Picked the ${p.ask ? "most" : "fewest"}`, `That group has the ${p.ask ? "most" : "fewest"}. Which group has the ${word}?`]
          : ["Picked a middle group", `That group is in the middle. Put the rows side by side: the ${word} is the ${p.ask ? "shortest" : "longest"} row.`],
        hint: p.ask ? "Put the rows side by side. The shortest row has the fewest." : "Put the rows side by side. The longest row has the most.",
        explain: `${pick} is the ${p.ask ? "smallest" : "biggest"} number, so the ${kinds[right]!.many} have the ${word}.`,
        work: [text(`The ${kinds[right]!.many} have the ${word}.`)],
      }),
    ],
    finalParts: [-1],
  };
}

const seedOf = (p: SortProblem) => p.counts.reduce((a, c) => a * 9 + c, p.by * 7 + p.theme * 3 + 1);
const altOf = (p: SortProblem) => { const total = p.counts.reduce((a, b) => a + b, 0); return p.by ? `${total} shapes, all mixed up.` : `${total} things of different kinds, all mixed up.`; };

function explain(p: SortProblem, model: AnswerModel): Explanation {
  const kinds = kindsOf(p), right = model.steps.at(-1)!.slots[0]!.expected!, word = p.ask ? "fewest" : "most";
  return {
    heading: "Sort, then count",
    idea: ["Putting matching things together makes each group easy to count."],
    statement: words(`Which group has the ${word}?`),
    diagram: buildSort({ glyphs: kinds.map(k => k.glyph), counts: p.counts, seed: seedOf(p), mark: right, beats: { rows: 1, count: 2, mark: 3 }, pick: { ...pickOf(p), until: 0 },
      alt: `${altOf(p)} They slide into rows, one row for each kind: ${p.counts.map((n, i) => count(n, kinds[i]!.one, kinds[i]!.many)).join(", ")}.` }),
    caption: `The ${kinds[right]!.many} have the ${word}.`,
    timeline: beats(4),
    steps: [
      { id: "sort", narration: `Everything is mixed up. Look at the ringed one: ${kinds[pickOf(p).group]!.looks.toLowerCase()}, so it goes with the ${kinds[pickOf(p).group]!.many}.`, math: words("Mixed up"), state: 0, answerStep: "sort", result: pickOf(p).group },
      { id: "rows", narration: "Put the things that match together, one row for each kind.", math: words("Sorted"), state: 1 },
      ...p.counts.map((n, i) => ({ id: `count${i}`, narration: `${countUp(1, n)}: **${count(n, kinds[i]!.one, kinds[i]!.many)}**.`, math: [text(`${cap(kinds[i]!.many)}: `), num(n)], state: 2, answerStep: `count${i}`, result: n })),
      { id: "compare", narration: `The ${p.ask ? "shortest" : "longest"} row has the ${word}: the **${kinds[right]!.many}**.`, math: [text(`The ${kinds[right]!.many} have the ${word}.`)], state: 3, answerStep: "compare", result: right },
    ],
  };
}

export const lesson: LessonDefinition<SortProblem> = {
  id: "k-sort",
  grade: 0,
  unit: "Shapes and measuring",
  title: "Sort and count",
  reference: createSort(0, [5, 3], 0, 0),
  generate: (rng, index) => {
    const early = index < 3, kinds = early ? 2 : 3, top = early ? 6 : 8, cap = early ? 8 : 15;
    for (;;) {
      const counts = rng.shuffle(Array.from({ length: top }, (_, i) => i + 1)).slice(0, kinds);
      if (counts.reduce((a, b) => a + b, 0) <= cap) return createSort(rng.int(0, 1), counts, rng.int(0, 2), index % 4 === 3 ? 1 : 0);
    }
  },
  restore: raw => {
    const r = raw as Partial<SortProblem> | null;
    if (!r || typeof r !== "object" || !Array.isArray(r.counts)) return null;
    try { return createSort(r.by as number, r.counts as number[], r.theme as number, r.ask as number); } catch { return null; }
  },
  display: p => words(`Sort them. Which group has the ${p.ask ? "fewest" : "most"}?`),
  picture: p => buildSort({ glyphs: kindsOf(p).map(k => k.glyph), counts: p.counts, seed: seedOf(p), pick: pickOf(p), alt: `${altOf(p)} One ${kindsOf(p)[pickOf(p).group]!.one} has a ring around it.` }),
  answers,
  explain,
  pre: "k-compare",
};
