// Story problems within 10: read the story, find the start, decide if there will be more or fewer, then add or take away.
import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { changeDots } from "../../../../explanations/diagrams/early-k/groups";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { TEN, countUp, indexIn, lines, slips, tapStep, words } from "../kit";
import { count, isAre } from "../../../text";

const NAMES = ["Mia", "Leo", "Ava", "Sam", "Zoe", "Ben"] as const;
const THINGS = ["apples", "crayons", "stickers", "shells", "blocks", "cookies"] as const;

/** a things, then b more join (take 0) or b go away (take 1); who, what and tale pick the words */
export interface StoryProblem { a: number; b: number; take: number; who: number; what: number; tale: number }

export function createStory(a: number, b: number, take: number, who: number, what: number, tale: number): StoryProblem {
  wholeIn("take", take, 0, 1);
  if (take) {
    wholeIn("a", a, 2, TEN);
    wholeIn("b", b, 1, a - 1);
  } else {
    wholeIn("a", a, 2, TEN - 1);
    wholeIn("b", b, 1, TEN - a);
  }
  indexIn("who", who, NAMES);
  indexIn("what", what, THINGS);
  wholeIn("tale", tale, 0, 1);
  return { a, b, take, who, what, tale };
}

/** The story in three short sentences, every number and word from the problem. */
function storyLines(p: StoryProblem): (string | number)[][] {
  const who = NAMES[p.who]!, what = THINGS[p.what]!;
  const start = p.tale ? [p.a, `${what} are on the table.`] : [`${who} has`, p.a, `${what}.`];
  if (!p.take) return [start, p.tale ? [`${who} puts on`, p.b, "more."] : [`${who} gets`, p.b, "more."], [`How many ${what} now?`]];
  return [start, p.tale ? [`${who} takes`, p.b, "away."] : [`${who} gives`, p.b, "away."], [`How many ${what} are left?`]];
}

/** The story as one paragraph. */
export const storyText = (p: StoryProblem) => storyLines(p).map(l => l.join(" ")).join(" ");
/** The story as the big problem line: one sentence per line. */
const storyMath = (p: StoryProblem) => lines(...storyLines(p).map(l => words(...l)));

/** "3 go away" or "1 goes away"; "3 more come" or "1 more comes" */
const goes = (b: number) => (b === 1 ? "1 goes away" : `${b} go away`);
const comes = (b: number) => (b === 1 ? "1 more comes" : `${b} more come`);
const sign = (p: StoryProblem) => (p.take ? "−" : "+");
const endOf = (p: StoryProblem) => (p.take ? p.a - p.b : p.a + p.b);
const sentence = (p: StoryProblem, end: MathText): MathText => [num(p.a), op(sign(p)), num(p.b), op("="), ...end];

function answers(p: StoryProblem): AnswerModel {
  const { a, b, take } = p, what = THINGS[p.what]!, end = endOf(p), other = take ? a + b : a - b;
  const change = take ? goes(b) : comes(b);
  return {
    steps: [
      oneBox({
        id: "start", label: "Find the start", question: `How many ${what} are there at the start?`,
        prompt: s => [text("At the start: "), s], ans: a,
        wrong: slips(a, [
          [b, "Picked the change", `That's how many ${take ? "go away" : "come"}. Look for how many there are **first**.`],
          [end, "Jumped to the end", "That's the answer at the end. First find how many there are at the start."],
        ]),
        hint: "Read the first sentence again. How many are there before anything changes?",
        explain: `The story starts with ${a} ${what}.`,
      }),
      tapStep({
        id: "more", label: "More or fewer?", question: `${change}. Will there be more or fewer at the end?`,
        prompt: [num(a), text(take ? ", then take away " : ", then add "), num(b)],
        choices: ["More", "Fewer"], right: take,
        wrong: () => take
          ? ["Thought it grows", `Some ${what} go away, so there will be **fewer** than ${a}.`]
          : ["Thought it shrinks", `More ${what} come, so there will be **more** than ${a}.`],
        hint: take ? `Do the ${what} come or go away?` : `Do more ${what} come, or do some go away?`,
        explain: take ? `${goes(b)}, so there will be fewer.` : `${comes(b)}, so there will be more.`,
        work: [text(take ? "Fewer: take away" : "More: add")],
      }),
      oneBox({
        id: "end", label: take ? "Take away" : "Add", question: `How many ${what} are there at the end?`,
        prompt: s => sentence(p, [s]), ans: end,
        wrong: slips(end, [
          [other, take ? "Added instead" : "Took away instead", take ? `Some go away, so the answer is **fewer** than ${a}. Take away ${b}.` : `More come, so the answer is **more** than ${a}. Add ${b}.`],
          [b, "Wrote the change", `That's how many ${take ? "go away" : "come"}. Start at ${a} and count ${take ? "back" : "on"} ${b}.`],
          [a, "Forgot the change", `${a} is the start. Now count ${take ? "back" : "on"} ${b}.`],
          [end + 1, "One too many", `One too many. Count ${take ? "back" : "on"} exactly ${b}.`],
          [end - 1, "One short", `One short. Count ${take ? "back" : "on"} exactly ${b}.`],
        ]),
        hint: take ? `Start at ${a} and count back ${b}.` : `Start at ${a} and count on ${b}.`,
        explain: take ? `${a}, then back ${b}: ${countUp(end, a - 1).split(", ").reverse().join(", ")}. ${end} ${isAre(end)} left.`
          : `${a}, then on ${b}: ${countUp(a + 1, end)}. Now there are ${end}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: StoryProblem, model: AnswerModel): Explanation {
  const what = THINGS[p.what]!, a = expectedOf(model, "start"), more = expectedOf(model, "more", "c"), end = expectedOf(model, "end");
  return {
    heading: "Act out the story",
    idea: ["Find how many there are at the start. Do more come, or do some go away? Then add or take away."],
    statement: storyMath(p),
    diagram: changeDots({ start: p.a, change: p.b, kind: p.take ? "take" : "join", beats: { start: 0, change: 1, end: 2 },
      alt: `${count(a, "dot")} for the ${what}. ${p.take ? `${p.b} ${isAre(p.b)} crossed out` : `${p.b} more join them`}, and ${end} ${isAre(end)} counted at the end.` }),
    caption: `${a} ${sign(p)} ${p.b} = ${end}`,
    timeline: beats(3),
    steps: [
      { id: "start", narration: `The story starts with **${a}** ${what}. Each dot is one.`, math: [text("At the start: "), num(a)], state: 0, answerStep: "start", result: a },
      { id: "more", narration: p.take ? `${goes(p.b)}. Cross ${p.b === 1 ? "it" : "them"} out. There will be **fewer**.` : `${comes(p.b)}. Add ${p.b === 1 ? "its dot" : "their dots"}. There will be **more**.`,
        math: [num(a), op(sign(p)), num(p.b)], state: 1, answerStep: "more", result: more },
      { id: "end", narration: `Count what is there now: ${countUp(1, end)}. **${end}** ${end === 1 ? what.slice(0, -1) : what}.`, math: sentence(p, [num(end)]), state: 2, answerStep: "end", result: end },
    ],
  };
}

export const lesson: LessonDefinition<StoryProblem> = {
  id: "k-story",
  grade: 0,
  unit: "Adding and subtracting",
  title: "Story problems within 10",
  pre: "k-add",
  reference: createStory(5, 2, 1, 0, 0, 0),
  generate: (rng, index) => {
    const take = rng.int(0, 1), top = index < 3 ? 6 : TEN;
    const a = take ? rng.int(3, top) : rng.int(2, top - 1);
    const b = take ? rng.int(1, Math.min(a - 1, index < 3 ? 3 : TEN)) : rng.int(1, Math.min(top - a, index < 3 ? 3 : TEN));
    return createStory(a, b, take, rng.int(0, NAMES.length - 1), rng.int(0, THINGS.length - 1), rng.int(0, 1));
  },
  restore: raw => restoreVia(raw, ["a", "b", "take", "who", "what", "tale"] as const, v => createStory(v.a, v.b, v.take, v.who, v.what, v.tale)),
  display: storyMath,
  picture: p => changeDots({ start: p.a, change: p.b, kind: p.take ? "take" : "join", alt: `${count(p.a, "dot")} for the ${THINGS[p.what]}` }),
  story: p => ({ op: p.take ? "−" : "+", text: storyText(p) }),
  answers,
  explain,
};
