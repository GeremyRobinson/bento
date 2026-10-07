import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import type { TapeRow } from "../../../../explanations/diagrams/tape/schema";
import { box, expectedOf, restoreVia, wholeIn } from "../_kit/steps";

/**
 * A two-step story, one step per operation. kind 0: a groups of b, then c taken away. kind 1: a groups of b, then c more.
 * kind 2: a things, c taken away, then the rest shared equally into b groups. `who` picks the story's person and things.
 */
export interface TwoStepProblem { kind: number; a: number; b: number; c: number; who: number }

const CAST = [
  { name: "Mia", they: "She", their: "her", things: "stickers", thing: "sticker", groups: "packs", group: "pack", lose: "gives away" },
  { name: "Leo", they: "He", their: "his", things: "crayons", thing: "crayon", groups: "boxes", group: "box", lose: "loses" },
  { name: "Ava", they: "She", their: "her", things: "marbles", thing: "marble", groups: "bags", group: "bag", lose: "loses" },
  { name: "Sam", they: "He", their: "his", things: "cookies", thing: "cookie", groups: "trays", group: "tray", lose: "eats" },
] as const;

export function createTwoStep(kind: number, a: number, b: number, c: number, who: number): TwoStepProblem {
  wholeIn("who", who, 0, CAST.length - 1);
  if (kind === 0 || kind === 1) {
    wholeIn("groups", a, 2, 9); wholeIn("in each", b, 2, 10);
    wholeIn("c", c, 1, kind === 0 ? a * b - 1 : 30);
  } else if (kind === 2) {
    wholeIn("groups", b, 2, 9); wholeIn("taken away", c, 1, 30);
    if ((a - c) % b !== 0) throw new Error("the rest must share out evenly");
    wholeIn("each", (a - c) / b, 2, 10);
  } else throw new Error("kind is 0, 1 or 2");
  return { kind, a, b, c, who };
}

/** Early problems use groups of 2, 5 or 10 and small numbers; later ones any facts. */
export function generateTwoStep(rng: Rng, index: number): TwoStepProblem {
  const kind = rng.int(0, 2), who = rng.int(0, CAST.length - 1), early = index < 3;
  if (kind < 2) {
    const a = rng.int(2, early ? 5 : 9), b = early ? rng.pick([2, 5, 10]) : rng.int(3, 9);
    const c = kind === 0 ? rng.int(2, Math.min(a * b - 1, early ? 9 : 20)) : rng.int(2, early ? 9 : 20);
    return createTwoStep(kind, a, b, c, who);
  }
  const b = early ? rng.pick([2, 5]) : rng.int(3, 8), q = rng.int(2, early ? 5 : 9), c = rng.int(2, early ? 9 : 15);
  return createTwoStep(2, b * q + c, b, c, who);
}

/** The story (numbers in bold), the question it asks, and the question as one short line of math. */
function story({ kind, a, b, c, who }: TwoStepProblem): { text: string; ask: string; short: MathText } {
  const w = CAST[who]!;
  if (kind === 0) return {
    text: `${w.name} has **${a}** ${w.groups} of **${b}** ${w.things}. ${w.they} gives **${c}** ${w.things} away.`,
    ask: `How many ${w.things} does ${w.name} have left?`,
    short: [text("? left")],
  };
  if (kind === 1) return {
    text: `${w.name} has **${a}** ${w.groups} of **${b}** ${w.things} and **${c}** more ${w.things}.`,
    ask: `How many ${w.things} does ${w.name} have in all?`,
    short: [text("? in all")],
  };
  return {
    text: `${w.name} has **${a}** ${w.things}. ${w.they} ${w.lose} **${c}**. ${w.they} shares the rest equally into **${b}** ${w.groups}.`,
    ask: `How many ${w.things} go in each ${w.group}?`,
    short: [text(`? in each ${w.group}`)],
  };
}

function answers(p: TwoStepProblem): AnswerModel {
  const { kind, a, b, c, who } = p, w = CAST[who]!;
  if (kind < 2) {
    const P = a * b;
    return {
      steps: [
        box({
          id: "groups", label: "How many in the groups", question: `${a} ${w.groups} with ${b} in each. Multiply.`,
          prompt: x => [num(a), op("×"), num(b), op("="), x], ans: P,
          wrong: [
            [a + b, "Added the groups and the things", `${a} ${w.groups} of ${b} is ${a} equal groups. Multiply: ${a} × ${b}.`],
            [(a - 1) * b, "One group short", `That's ${a - 1} × ${b}. There are ${a} ${w.groups}: count ${b} more.`],
            [(a + 1) * b, "One group too many", `That's ${a + 1} × ${b}. There are only ${a} ${w.groups}.`],
          ],
          hint: `Count by ${b}s, once for each of the ${a} ${w.groups}.`, explain: `${a} × ${b} = ${P} ${w.things} in the ${w.groups}.`,
        }),
        kind === 0
          ? box({
              id: "change", label: "Take some away", question: `${w.they} gives ${c} away. Subtract.`,
              prompt: x => [num(P), op("−"), num(c), op("="), x], ans: P - c,
              wrong: [
                [P + c, "Added instead of taking away", `Giving ${w.things} away leaves fewer. Subtract ${c}.`],
                ...(b > c ? [[a * (b - c), `Took ${c} from every ${w.group}`, `${w.they} gave away ${c} in all, not ${c} from each ${w.group}.`] as [number, string, string]] : []),
              ],
              hint: `Count back ${c} from ${P}.`, explain: `${P} − ${c} = ${P - c}.`,
            })
          : box({
              id: "change", label: "Add the extra", question: `There are ${c} more. Add.`,
              prompt: x => [num(P), op("+"), num(c), op("="), x], ans: P + c,
              wrong: [
                [P - c, "Took away instead of adding", `${c} more means the total gets bigger. Add ${c}.`],
                [a * (b + c), `Added ${c} to every ${w.group}`, `The ${c} extra ${w.things} are added once, not to each ${w.group}.`],
              ],
              hint: `Count on ${c} from ${P}.`, explain: `${P} + ${c} = ${P + c}.`,
            }),
      ],
      finalParts: [-1],
    };
  }
  const R = a - c, q = R / b;
  return {
    steps: [
      box({
        id: "left", label: "Take some away first", question: `${a} ${w.things}, ${c} gone. How many are left to share?`,
        prompt: x => [num(a), op("−"), num(c), op("="), x], ans: R,
        wrong: [[a + c, "Added instead of taking away", `${c} ${w.things} are gone, so there are fewer. Subtract.`]],
        hint: `Count back ${c} from ${a}.`, explain: `${a} − ${c} = ${R} left to share.`,
      }),
      box({
        id: "share", label: "Share equally", question: `Share ${R} into ${b} equal ${w.groups}.`,
        prompt: x => [num(R), op("÷"), num(b), op("="), x], ans: q,
        wrong: [
          [R - b, "Subtracted instead of sharing", `Sharing into ${b} equal ${w.groups} means dividing: ${b} × ? = ${R}.`],
          [b, `Wrote the number of ${w.groups}`, `${b} is how many ${w.groups}. How many go in each one?`],
          [q + 1, "Too many in each", `${b} × ${q + 1} = ${b * (q + 1)}, more than ${R}. Each one gets fewer.`],
          [q - 1, "Too few in each", `${b} × ${q - 1} = ${b * (q - 1)}, so ${R - b * (q - 1)} would be left over. Each one gets more.`],
        ],
        hint: `${b} × ? = ${R}.`, explain: `${R} ÷ ${b} = ${q}, because ${b} × ${q} = ${R}.`,
      }),
    ],
    finalParts: [-1],
  };
}

/** Bars of things: the equal groups, then the change; or the whole, then the rest cut into equal groups. */
export function twoStepPicture(p: TwoStepProblem, first: number, second: number) {
  const { kind, a, b, c, who } = p, w = CAST[who]!;
  let rows: TapeRow[];
  if (kind < 2) {
    const P = first;
    rows = [
      { length: P, parts: a, each: [{ text: () => String(b) }], label: [{ text: `${a} ${w.groups}` }], total: [{ text: String(P), from: 1, acc: true }] },
      kind === 0
        ? { length: P, parts: 1, from: 2, fills: [{ a: 0, b: P - c, tone: "on" }, { a: P - c, b: P, tone: "cut" }], label: [{ text: "left" }], total: [{ text: `${second} left`, acc: true }] }
        : { length: P + c, parts: 1, from: 2, fills: [{ a: 0, b: P, tone: "on" }, { a: P, b: P + c, tone: "two" }], label: [{ text: "in all" }], total: [{ text: String(second), acc: true }] },
    ];
  } else {
    const R = first;
    rows = [
      { length: a, parts: 1, fills: [{ a: 0, b: R, tone: "on", from: 1 }, { a: R, b: a, tone: "cut", from: 1 }], label: [{ text: w.things }], total: [{ text: String(a), until: 0 }, { text: `${R} left`, from: 1, acc: true }] },
      { length: R, parts: b, from: 2, each: [{ text: () => String(second) }], label: [{ text: `${b} ${w.groups}` }], total: [{ text: `${second} each`, acc: true }] },
    ];
  }
  return buildTape({
    rows, width: 540, maxRowHeight: 50,
    alt: kind === 0 ? `A bar of ${a} ${w.groups} with ${b} in each, ${first} in all. ${c} are crossed off, leaving ${second}.`
      : kind === 1 ? `A bar of ${a} ${w.groups} with ${b} in each, ${first} in all. ${c} more are added, making ${second}.`
      : `A bar of ${a} ${w.things}. ${c} are crossed off, leaving ${first}. Those are cut into ${b} equal ${w.groups} of ${second}.`,
  });
}

function explain(p: TwoStepProblem, model: AnswerModel): Explanation {
  const { kind, a, b, c, who } = p, w = CAST[who]!;
  const s1 = model.steps[0]!, s2 = model.steps[1]!;
  const first = expectedOf(model, s1.id), second = expectedOf(model, s2.id);
  const ops: ["×" | "−", "−" | "+" | "÷"] = kind === 0 ? ["×", "−"] : kind === 1 ? ["×", "+"] : ["−", "÷"];
  return {
    heading: "One step at a time",
    idea: ["The answer to the first part is the number you need for the second part."],
    statement: story(p).short,
    diagram: twoStepPicture(p, first, second),
    caption: `${story(p).text} ${story(p).ask}`,
    timeline: beats(3),
    steps: [
      { id: s1.id, state: 1, answerStep: s1.id, result: first, math: [num(a), op(ops[0]), num(kind < 2 ? b : c), op("="), num(first)],
        narration: kind < 2 ? `First the ${w.groups}: ${a} ${w.groups} of ${b} is ${a} × ${b} = ${first} ${w.things}.` : `First take away: ${a} − ${c} = ${first} ${w.things} left.` },
      { id: s2.id, state: 2, answerStep: s2.id, result: second, math: [num(first), op(ops[1]), num(kind < 2 ? c : b), op("="), num(second)],
        narration: kind === 0 ? `Then ${c} go away: ${first} − ${c} = ${second}. ${w.name} has ${second === 1 ? `1 ${w.thing}` : `${second} ${w.things}`} left.`
          : kind === 1 ? `Then add the ${c} more: ${first} + ${c} = ${second}. ${w.name} has ${second === 1 ? `1 ${w.thing}` : `${second} ${w.things}`} in all.`
          : `Then share them into ${b} equal ${w.groups}: ${first} ÷ ${b} = ${second} in each ${w.group}.` },
    ],
  };
}

export const lesson: LessonDefinition<TwoStepProblem> = {
  id: "g3-twostep",
  grade: 3,
  unit: "Multiplication and division",
  title: "Two-step word problems",
  pre: "g3-facts",
  reference: createTwoStep(0, 4, 6, 5, 0),
  generate: generateTwoStep,
  restore: raw => restoreVia(raw, ["kind", "a", "b", "c", "who"] as const, v => createTwoStep(v.kind, v.a, v.b, v.c, v.who)),
  display: p => story(p).short,
  displayNote: p => `${story(p).text} ${story(p).ask}`,
  lead: p => `${story(p).text} ${story(p).ask}`,
  answers,
  explain,
};
