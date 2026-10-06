// Make 10: some dots are in a ten frame. How many more fill it? Count the empty boxes.
import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { fillTen } from "../../../../explanations/diagrams/early-k/frames";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { TEN, countUp, slips } from "../kit";
import { count } from "../../../text";

/** `have` dots in a ten frame, 1 to 9 */
export interface MakeTenProblem { have: number }

export function createMakeTen(have: number): MakeTenProblem {
  wholeIn("have", have, 1, TEN - 1);
  return { have };
}

function answers({ have }: MakeTenProblem): AnswerModel {
  const need = TEN - have;
  return {
    steps: [
      oneBox({
        id: "have", label: "Count the dots", question: "How many dots are in the ten frame?",
        prompt: s => [text("Dots: "), s], ans: have,
        wrong: slips(have, [
          [need, "Counted the empty boxes", "Those are the empty boxes. Count the boxes that **have** a dot."],
          [TEN, "Counted every box", `A full frame would be ${TEN}. Count only the boxes with a dot.`],
          [have - 1, "Skipped a dot", "One short. Touch each dot as you count."],
          [have + 1, "Counted a dot twice", "One too many. Touch each dot only once."],
        ]),
        hint: "Touch each dot and count.",
        explain: `${countUp(1, have)}. There ${have === 1 ? "is 1 dot" : `are ${count(have, "dot")}`}.`,
      }),
      oneBox({
        id: "need", label: "Fill the frame", question: `How many more make ${TEN}?`,
        prompt: s => [num(have), op("+"), s, op("="), num(TEN)], ans: need,
        wrong: slips(need, [
          [TEN, "Wrote the whole frame", `${TEN} is the full frame. How many **more** dots does it need?`],
          [have, "Counted the dots again", `That's the dots already there. Count the **empty** boxes.`],
          [TEN + have, "Added them up", `That's too many. The frame only holds ${TEN}. Count the empty boxes.`],
          [need - 1, "Missed an empty box", "One short. Touch every empty box."],
          [need + 1, "Counted a box twice", "One too many. Touch each empty box only once."],
        ]),
        hint: `Count the empty boxes. Or start at ${have} and count up to ${TEN}.`,
        explain: `Put a dot in each empty box: ${countUp(1, need)}. ${have} and ${need} make ${TEN}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: MakeTenProblem, model: AnswerModel): Explanation {
  const have = expectedOf(model, "have"), need = expectedOf(model, "need");
  return {
    heading: "Fill the ten frame",
    idea: [`A ten frame holds ${TEN}. The empty boxes show how many more you need.`],
    statement: [num(p.have), op("+"), text("?"), op("="), num(TEN)],
    diagram: fillTen(p.have, `A ten frame with ${count(have, "dot")}. ${need} more fill it: ${have} + ${need} = ${TEN}.`, { have: 0, fill: 1, whole: 2 }),
    caption: `${have} and ${need} make ${TEN}.`,
    timeline: beats(3),
    steps: [
      { id: "have", narration: `Count the dots: ${countUp(1, have)}. There ${have === 1 ? "is" : "are"} **${have}**.`, math: [text("Dots: "), num(have)], state: 0, answerStep: "have", result: have },
      { id: "need", narration: `Put a dot in each empty box and count them: ${countUp(1, need)}. That's **${need}** more.`, math: [num(have), op("+"), num(need)], state: 1, answerStep: "need", result: need },
      { id: "ten", narration: `Now the frame is full. ${have} and ${need} make ${TEN}.`, math: [num(have), op("+"), num(need), op("="), num(TEN)], state: 2 },
    ],
  };
}

export const lesson: LessonDefinition<MakeTenProblem> = {
  id: "k-make10",
  grade: 0,
  unit: "Adding and subtracting",
  title: "Make 10",
  pre: "k-bonds",
  reference: createMakeTen(7),
  generate: (rng, index) => createMakeTen(rng.int(index < 3 ? 6 : 1, TEN - 1)),
  restore: raw => restoreVia(raw, ["have"] as const, v => createMakeTen(v.have)),
  display: p => [num(p.have), op("+"), text("?"), op("="), num(TEN)],
  picture: p => fillTen(p.have, `A ten frame with ${count(p.have, "dot")}`),
  answers,
  explain,
};
