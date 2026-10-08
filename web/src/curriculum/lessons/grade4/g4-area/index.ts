import { num, op, sup, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import { r1 } from "../../../../explanations/diagrams/scene/helpers";
import { expectedOf, ns, readNumbers } from "../../area-common/steps";
import { count, aNum, cap } from "../../../text";

/** An l m by w m rectangle: its area and its perimeter. */
export interface RectProblem { l: number; w: number }

export function createRect(l: number, w: number): RectProblem {
  if (![l, w].every(v => Number.isInteger(v) && v > 0)) throw new Error("sides are whole numbers");
  return { l, w };
}

/** Same as the current app: length 3–15, width 2–10. */
export const generateRect = (rng: Rng): RectProblem => ({ l: rng.int(3, 15), w: rng.int(2, 10) });

export function rectAnswers({ l, w }: RectProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "area", label: "Area", question: "Area is the squares inside: length × width.", prompt: x => [num(l), op("×"), num(w), op("="), x, text(" m"), sup(2)], ans: l * w,
        hint: `${count(w, "row")} of ${count(l, "square")}.`, wrong: [[2 * (l + w), "Found the perimeter", "That's the distance around. Area is length × width."], [l + w, "Added instead of multiplied", "Area is length × width."]] }),
      ns({ id: "half", label: "Length + width", prompt: x => [num(l), op("+"), num(w), op("="), x], ans: l + w, hint: "Add one long side and one short side.",
        wrong: [[l * w, "Multiplied the sides", "This step goes along the edge: one long side plus one short side."]] }),
      ns({ id: "perimeter", label: "Perimeter", question: "Perimeter is the distance all the way around.", prompt: x => [num(2), op("×"), num(l + w), op("="), x, text(" m")], ans: 2 * (l + w),
        hint: "There are two long sides and two short sides.", wrong: [[l * w, "Found the area", "Perimeter goes around the edge: add all four sides."]] }),
    ],
    finalParts: [0, -1],
  };
}

export function explainRect(p: RectProblem, answers: AnswerModel): Explanation {
  const { l, w } = p;
  const area = expectedOf(answers.steps, "area"), half = expectedOf(answers.steps, "half"), per = expectedOf(answers.steps, "perimeter");
  return {
    heading: "Inside and around",
    idea: ["Area counts the squares inside, and perimeter is the distance around the edge."],
    statement: [num(l), text(" m by "), num(w), text(" m")],
    diagram: buildAreaGrid({
      cols: [{ label: `${l} m`, size: l }],
      rows: [{ label: `${w} m`, size: w }],
      cells: [[{ text: `${area} m`, sup: "2", from: 1 }]],
      outlineFrom: 0,
      units: 1,
      extras: g => {
        const x0 = r1(g.left), y0 = r1(g.top), x1 = r1(g.left + g.width), y1 = r1(g.top + g.height);
        return [
          { type: "path", d: `M${x0} ${y1} V${y0} H${x1}`, cls: "hlline", from: 2, until: 2, enter: "draw" },
          { type: "path", d: `M${x0} ${y1} V${y0} H${x1} V${y1} Z`, cls: "ln2", from: 3, enter: "draw slow" },
        ];
      },
      lines: [
        { text: `one long side + one short side = ${half} m`, from: 2, until: 2, cls: "lbl" },
        { text: `around: ${l} + ${w} + ${l} + ${w} = ${per} m`, from: 3 },
      ],
      alt: `${cap(aNum(l))} m by ${w} m rectangle: ${count(area, "square")} inside, ${per} m around.`,
    }),
    caption: `Area: ${l} × ${w} = ${area} square meters. Perimeter: ${l} + ${w} + ${l} + ${w} = ${per} meters.`,
    timeline: beats(4),
    steps: [
      { id: "area", narration: `${count(w, "row")} of ${count(l, "square")} fill the inside: ${area} square meters.`, math: [num(l), op("×"), num(w), op("="), num(area), text(" m"), sup(2)], state: 1, answerStep: "area", result: area },
      { id: "half", narration: `One long side and one short side: ${l} + ${w} = ${half} m.`, math: [num(l), op("+"), num(w), op("="), num(half)], state: 2, answerStep: "half", result: half },
      { id: "perimeter", narration: `All the way around is that twice: ${per} m.`, math: [num(2), op("×"), num(half), op("="), num(per), text(" m")], state: 3, answerStep: "perimeter", result: per },
    ],
  };
}

export const lesson: LessonDefinition<RectProblem> = {
  id: "g4-area",
  grade: 4,
  unit: "Measurement",
  title: "Area and perimeter",
  reference: createRect(5, 3),
  generate: rng => generateRect(rng),
  restore: raw => { const r = readNumbers(raw, ["l", "w"] as const); try { return r && createRect(r.l, r.w); } catch { return null; } },
  display: p => [num(p.l), text(" m by "), num(p.w), text(" m")],
  displayNote: () => "Find the area and the perimeter of the rectangle.",
  answers: rectAnswers,
  explain: explainRect,
};
