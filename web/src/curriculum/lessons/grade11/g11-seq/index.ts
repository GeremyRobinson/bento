// Arithmetic sequences (the current app's G11_SEQ): aₙ = a₁ + (n − 1)d, told as jumps along a number line.
import { answer, formatNumber as f, num, op, sub, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildNumberLine, fitRange, type Hop } from "../../../../explanations/diagrams/number-line/build";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { count } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** first term a1, common difference d, and the term number n to find */
export interface SequenceProblem { a1: number; d: number; n: number }

export function createSequence(a1: number, d: number, n: number): SequenceProblem {
  wholeIn("a1", a1, 1, 20); wholeIn("d", d, 2, 9); wholeIn("n", n, 10, 30);
  return { a1, d, n };
}

const term = (n: number): MathText => [text("a"), sub(n)];

function answers({ a1, d, n }: SequenceProblem): AnswerModel {
  const climb = (n - 1) * d;
  return {
    steps: [
      oneBox({ id: "d", label: "Common difference", note: "How much does each term go up?", prompt: s => [text("d"), op("="), s], ans: d,
        wrong: [[a1, "Common difference", `That's the first term. d is the jump: ${a1 + d} − ${a1}.`], [a1 + d, "Common difference", `That's the second term. Subtract: ${a1 + d} − ${a1}.`]],
        hint: `The jump is how much each term goes up: take the first term from the second, ${a1 + d} − ${a1}.`, explain: `Each term goes up by ${d}.` }),
      oneBox({ id: "jumps", label: "Count the jumps", question: `From term 1 to term ${n}, how many jumps?`, prompt: s => [s], ans: n - 1,
        wrong: [[n, "Off by one", `Term 1 is where you start, so it's ${n} minus 1, which is ${count(n - 1, "jump")}.`]],
        hint: `You start on term 1, so getting to term ${n} takes one jump fewer than ${n}.`, explain: `${n} − 1 = ${count(n - 1, "jump")}.`, work: [answer("x", n - 1), text(" jumps")] }),
      oneBox({ id: "climb", label: "Total climb", prompt: s => [num(n - 1), op("×"), num(d), op("="), s], ans: climb,
        hint: `Each jump climbs ${d}, so ${count(n - 1, "jump")} climb ${n - 1} × ${d}.`, explain: `${n - 1} × ${d} = ${climb}.`,
        wrong: [[n - 1 + d, "Added", `Each of the ${count(n - 1, "jump")} climbs ${d}: multiply.`]] }),
      oneBox({ id: "term", label: "Add the first term", prompt: s => [...term(n), op("="), num(a1), op("+"), num(climb), op("="), s], ans: a1 + climb,
        hint: "Start at the first term and add the climb.", wrong: [[climb, "Forgot the start", "The climb starts from the first term: add the first term on."]], explain: `${a1} + ${climb} = ${a1 + climb}.`, work: [...term(n), op("="), answer("x", a1 + climb)] }),
    ],
    finalParts: [-1],
  };
}

function explain(p: SequenceProblem, model: AnswerModel): Explanation {
  const { a1, n } = p, d = expectedOf(model, "d"), jumps = expectedOf(model, "jumps"), climb = expectedOf(model, "climb"), an = expectedOf(model, "term");
  // up to 12 jumps are drawn one by one; past that, too thin to read on a phone, the first 3 and the last 2 are drawn
  // and one long hop stands for the jumps between them
  const shown = jumps <= 12 ? jumps : 5, middle = jumps - 5;
  const hops: Hop[] = Array.from({ length: shown }, (_, i): Hop => {
    const k = jumps <= 12 || i < 3 ? i : i + middle;
    return { from: a1 + k * d, to: a1 + (k + 1) * d, beat: i < 3 ? 0 : 1, start: i === 0,
      ...(i < 3 ? { label: `+${d}`, delay: 0.5 * i } : { delay: Math.round(0.08 * (i - 3) * 100) / 100 }) };
  });
  if (jumps > 12) hops.splice(3, 0, { from: a1 + 3 * d, to: a1 + (jumps - 2) * d, beat: 1, start: false, label: `${middle} more jumps` });
  return {
    heading: "aₙ = a₁ + (n − 1)d",
    idea: ["The jump is the same every time, so term n is n − 1 jumps from the start."],
    statement: [...term(n), op("="), num(a1), op("+"), text("("), num(n), op("−"), num(1), text(")"), op("×"), num(d)],
    diagram: buildNumberLine({
      ...fitRange([a1, an], { maxTicks: 20, pad: 0, minStep: 1 }),
      hops,
      spans: [{ from: a1, to: an, beat: 2, label: `${jumps} × ${d} = ${climb}` }],
      marks: [{ v: an, label: `term ${n}: ${an}`, beat: 3, cls: "dota" }],
      alt: `Number line: from ${a1}, ${count(jumps, "jump")} of ${d} reach ${an}.`,
    }),
    caption: `Jump by ${d} each time: ${count(jumps, "jump")} from ${a1} reach ${an}.`,
    timeline: beats(4),
    steps: [
      { id: "d", narration: `Each term goes up by the same amount: ${a1 + d} − ${a1} = ${d}.`, math: [text("d"), op("="), num(d)], state: 0, answerStep: "d", result: d },
      { id: "jumps", narration: `Term 1 is where you start, so reaching term ${n} takes ${n} − 1 = ${count(jumps, "jump")}.`, math: [num(n), op("−"), num(1), op("="), num(jumps)], state: 1, answerStep: "jumps", result: jumps },
      { id: "climb", narration: `${count(jumps, "jump")} of ${d} climb ${jumps} × ${d} = ${climb}.`, math: [num(jumps), op("×"), num(d), op("="), num(climb)], state: 2, answerStep: "climb", result: climb },
      { id: "term", narration: `Start at the first term and add the climb: ${a1} + ${climb} = ${f(an)}.`, math: [...term(n), op("="), num(a1), op("+"), num(climb), op("="), num(an)], state: 3, answerStep: "term", result: an },
    ],
  };
}

export const lesson: LessonDefinition<SequenceProblem> = withEasyStart({
  id: "g11-seq",
  grade: 11,
  unit: "Sequences",
  title: "Arithmetic sequences",
  reference: createSequence(5, 4, 20), // 5, 9, 13, 17, … term 20 = 81, the current app's example
  generate: rng => createSequence(rng.int(1, 20), rng.int(2, 9), rng.int(10, 30)),
  restore: raw => restoreVia(raw, ["a1", "d", "n"] as const, v => createSequence(v.a1, v.d, v.n)),
  display: ({ a1, d }) => [0, 1, 2, 3].flatMap((k): MathText => [...(k ? [text(", ")] : []), num(a1 + k * d)]).concat([text(", …")]),
  displayNote: p => `Find term number ${p.n}.`,
  answers,
  explain,
});
