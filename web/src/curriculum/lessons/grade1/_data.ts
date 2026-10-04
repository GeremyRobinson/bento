// Themes and question steps the data lessons share (tally charts, picture graphs, scaled graphs).
import { num, op, text } from "../../schemas/math-text";
import type { AnswerStep } from "../../schemas/lesson";
import type { Icon } from "../../../explanations/diagrams/early-g1/data";
import { oneBox, wholeIn } from "../_number-line/steps";
import { slips } from "../gradeK/kit";

export interface Theme { title: string; names: string[]; nouns: string[]; one: string[]; icon: Icon; things: string }
export const THEMES: Theme[] = [
  { title: "Favorite fruit", names: ["Apples", "Bananas", "Grapes"], nouns: ["apples", "bananas", "grapes"], one: ["apple", "banana", "grape"], icon: "apple", things: "votes" },
  { title: "Our pets", names: ["Dogs", "Cats", "Fish"], nouns: ["dogs", "cats", "fish"], one: ["dog", "cat", "fish"], icon: "paw", things: "pets" },
  { title: "Weather this month", names: ["Sunny", "Rainy", "Cloudy"], nouns: ["sunny days", "rainy days", "cloudy days"], one: ["sunny day", "rainy day", "cloudy day"], icon: "star", things: "days" },
  { title: "Favorite snacks", names: ["Crackers", "Popcorn", "Pretzels"], nouns: ["crackers", "popcorn", "pretzels"], one: ["cracker", "popcorn", "pretzel"], icon: "cookie", things: "votes" },
];

/** counts, all different, each lo to hi */
export function checkCounts(counts: unknown, n: number, lo: number, hi: number): number[] {
  if (!Array.isArray(counts) || counts.length !== n) throw new Error(`${n} counts`);
  counts.forEach((c, i) => wholeIn(`counts[${i}]`, c as number, lo, hi));
  if (new Set(counts).size !== n) throw new Error("every count is different");
  return [...counts] as number[];
}

/** read one row: how many in it */
export function readRow(id: string, th: Theme, counts: number[], x: number, o: { scale?: number } = {}): AnswerStep {
  const n = counts[x]!, others = counts.flatMap((c, i) => (i === x ? [] : [[c, i] as const]));
  return oneBox({
    id, label: `Read the ${th.names[x]} row`, question: `How many ${th.nouns[x]}?`,
    prompt: s => [text(`${th.names[x]}: `), s], ans: n,
    wrong: slips(n, [
      ...others.map(([c, i]) => [c, "Read another row", `That's the ${th.names[i]} row. Find the ${th.names[x]} row.`] as [number, string, string]),
      [n - (o.scale ?? 1), "Counted one short", "Count again, one at a time."],
      [n + (o.scale ?? 1), "Counted one too many", "Count again, one at a time."],
    ]),
    hint: `Find the ${th.names[x]} row and count along it.`,
    explain: `The ${th.names[x]} row shows ${n}.`,
  });
}

/** how many more x than y */
export function moreStep(th: Theme, counts: number[], x: number, y: number): AnswerStep {
  const a = counts[x]!, b = counts[y]!;
  return oneBox({
    id: "more", label: "Find the difference", question: `How many more ${th.nouns[x]} than ${th.nouns[y]}?`,
    prompt: s => [num(a), op("−"), num(b), op("="), s], ans: a - b,
    wrong: slips(a - b, [[a + b, "Added instead", "How many more means the difference. Take away."]]),
    hint: `Line up the rows. How many extra in the ${th.names[x]} row?`,
    explain: `${a} − ${b} = ${a - b}.`,
  });
}

/** x and y together */
export function bothStep(th: Theme, counts: number[], x: number, y: number): AnswerStep {
  const a = counts[x]!, b = counts[y]!;
  return oneBox({
    id: "both", label: "Put them together", question: `How many ${th.nouns[x]} and ${th.nouns[y]} together?`,
    prompt: s => [num(a), op("+"), num(b), op("="), s], ans: a + b,
    wrong: slips(a + b, [[Math.abs(a - b), "Subtracted instead", "Together means add."]]),
    hint: `Add the ${th.names[x]} row and the ${th.names[y]} row.`,
    explain: `${a} + ${b} = ${a + b}.`,
  });
}
