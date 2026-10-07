// Picture graphs: one picture per thing. Read a row, find the longest (or shortest), compare two rows or put them together.
import { text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildRows } from "../../../../explanations/diagrams/early-g1/data";
import { wholeIn } from "../../_number-line/steps";
import { tapStep, words } from "../../gradeK/kit";
import { THEMES, bothStep, checkCounts, moreStep, readRow } from "../_data";

/** ask 0 reads row x; 1 which has the most (few: the fewest); 2 how many more x than y; 3 x and y together */
export interface PicGraphProblem { theme: number; counts: number[]; ask: number; x: number; y: number; few: boolean }

export function createPicGraph(theme: number, counts: number[], ask: number, x: number, y: number, few = false): PicGraphProblem {
  wholeIn("theme", theme, 0, THEMES.length - 1);
  const c = checkCounts(counts, 3, 1, 9);
  wholeIn("ask", ask, 0, 3);
  wholeIn("x", x, 0, 2);
  wholeIn("y", y, 0, 2);
  if (ask >= 2 && x === y) throw new Error("two different rows");
  if (ask === 2 && c[x]! <= c[y]!) throw new Error("x has more than y");
  return { theme, counts: c, ask, x, y, few: ask === 1 && few === true };
}

function answers(p: PicGraphProblem): AnswerModel {
  const th = THEMES[p.theme]!, c = p.counts;
  if (p.ask === 0) {
    // read the row, then use the line-up: is it longer or shorter than another row? (the answer stays the count)
    const read = readRow("read", th, c, p.x, { kind: "picture" });
    if (p.x === p.y) return { steps: [read], finalParts: [-1] };
    const longer = c[p.x]! > c[p.y]!, X = th.names[p.x]!, Y = th.names[p.y]!;
    return {
      steps: [read, tapStep({
        id: "line-up", label: "Compare it", question: `Is the ${X} row longer or shorter than the ${Y} row?`,
        prompt: [text(`${X} row: longer or shorter than ${Y}?`)], choices: ["Longer", "Shorter"], right: longer ? 0 : 1,
        wrong: () => [longer ? "Said shorter" : "Said longer", `The pictures line up. Look where each row ends: the ${X} row ${longer ? "goes past" : "stops before"} the end of the ${Y} row.`],
        hint: "The pictures line up, one under the other. Which row reaches further?",
        explain: `${X} has ${c[p.x]} and ${Y} has ${c[p.y]}, so the ${X} row is ${longer ? "longer" : "shorter"}: ${longer ? "more" : "fewer"} ${th.things === "days" ? "days" : "pictures"}.`,
        work: [text(`The ${X} row is ${longer ? "longer" : "shorter"}.`)],
      })],
      finalParts: [0],
    };
  }
  if (p.ask === 1) {
    const word = p.few ? "fewest" : "most", v = p.few ? Math.min(...c) : Math.max(...c), right = c.indexOf(v);
    const other = c.indexOf(p.few ? Math.max(...c) : Math.min(...c));
    return {
      steps: [tapStep({
        id: "compare", label: "Compare", question: `Which has the ${word}?`,
        prompt: [text(`Which row has the ${word} ${th.things === "days" ? "days" : "pictures"}?`)],
        choices: th.names, right,
        wrong: i => i === other
          ? [`Picked the ${p.few ? "most" : "fewest"}`, `That row is the ${p.few ? "longest" : "shortest"}. The ${word} is the ${p.few ? "shortest" : "longest"} row.`]
          : ["Picked a middle row", `Look at where each row ends. The ${word} is the ${p.few ? "shortest" : "longest"} row.`],
        hint: `The pictures line up, so the ${p.few ? "shortest" : "longest"} row has the ${word}.`,
        explain: `${th.names[right]} has ${v}, the ${p.few ? "shortest" : "longest"} row.`,
        work: [text(`${th.names[right]} has the ${word}.`)],
      })],
      finalParts: [-1],
    };
  }
  const reads = [readRow("x", th, c, p.x, { kind: "picture" }), readRow("y", th, c, p.y, { kind: "picture" })];
  return { steps: [...reads, p.ask === 2 ? moreStep(th, c, p.x, p.y) : bothStep(th, c, p.x, p.y)], finalParts: [-1] };
}

const alt = (p: PicGraphProblem) => `A picture graph of ${THEMES[p.theme]!.title.toLowerCase()}: ${THEMES[p.theme]!.names.join(", ")}.`;
const rowsRead = (p: PicGraphProblem) => (p.ask === 0 ? [p.x] : p.ask === 1 ? [0, 1, 2] : [p.x, p.y]);

function explain(p: PicGraphProblem, model: AnswerModel): Explanation {
  const th = THEMES[p.theme]!, last = model.steps[p.ask === 0 ? 0 : model.steps.length - 1]!, more = p.ask === 2;
  const read = rowsRead(p);
  return {
    heading: "Picture graphs",
    idea: ["Each picture is one thing, so the longest row has the most."],
    statement: words(`This graph shows ${th.title.toLowerCase()}. ${last.question ?? ""}`),
    diagram: buildRows({
      kind: "pictures", title: th.title, names: th.names, counts: p.counts, icon: th.icon, read,
      ...(more ? { more: [p.x, p.y] as [number, number], beats: { fill: 0, read: 1, more: 2 } } : { beats: { fill: 0, read: 1 } }),
      alt: `${alt(p)} The pictures go up one at a time, then ${read.map(i => `${th.names[i]} shows ${p.counts[i]}`).join(", ")}.${more ? ` The ${p.counts[p.x]! - p.counts[p.y]!} extra ${th.names[p.x]} pictures light up.` : ""}`,
    }),
    caption: `${last.explain}`,
    timeline: beats(more ? 3 : 2),
    steps: [
      { id: "fill", narration: "Each picture is one thing. The rows line up so you can compare them.", math: words(th.title), state: 0 },
      ...model.steps.map((s, i, all) => ({
        id: s.id, narration: s.explain, math: s.work, answerStep: s.id, result: s.slots[0]!.expected!,
        state: more && i === all.length - 1 ? 2 : 1,
      })),
    ],
  };
}

export const lesson: LessonDefinition<PicGraphProblem> = {
  id: "g1-picgraph",
  grade: 1,
  unit: "Data",
  title: "Picture graphs",
  reference: createPicGraph(1, [6, 3, 8], 2, 2, 1),
  generate: (rng, index) => {
    const ask = index < 3 ? index % 2 : index % 4;
    for (;;) {
      const counts = rng.shuffle([1, 2, 3, 4, 5, 6, 7, 8, 9]).slice(0, 3), x = rng.int(0, 2);
      const y = rng.pick([0, 1, 2].filter(i => i !== x));
      if (ask === 2 && counts[x]! <= counts[y]!) continue;
      return createPicGraph(rng.int(0, THEMES.length - 1), counts, ask, x, y, ask === 1 && rng.int(0, 2) === 0);
    }
  },
  restore: raw => {
    const r = raw as Partial<PicGraphProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createPicGraph(r.theme as number, r.counts as number[], r.ask as number, r.x as number, r.y as number, r.few === true); } catch { return null; }
  },
  display: p => words(answers(p).steps[p.ask === 0 ? 0 : answers(p).steps.length - 1]!.question ?? ""),
  picture: p => buildRows({ kind: "pictures", title: THEMES[p.theme]!.title, names: THEMES[p.theme]!.names, counts: p.counts, icon: THEMES[p.theme]!.icon, alt: alt(p) }),
  answers,
  explain,
  pre: "k-sort",
};
