import { num, op, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildTape } from "../../../../explanations/diagrams/tape/build";
import { expectedOf, ints, ns } from "../../_tape-family/steps";
import { count } from "../../../text";

/** c cm on the map = km km for real; two towns are c·g cm apart on the map. */
export interface ScaleProblem { c: number; km: number; g: number }

export function createScale(c: number, km: number, g: number): ScaleProblem {
  if (![c, km, g].every(x => Number.isInteger(x) && x > 0)) throw new Error(`not a scale problem: ${c} cm = ${km} km, ${count(g, "group")}`);
  return { c, km, g };
}

/** Same ranges as the current app: 1–4 cm stands for 2–9 km, the towns 2–8 of those apart. */
// the first three: short lines and small scales
export const generateScale = (rng: Rng, index = 3) => (index < 3 ? createScale(rng.int(1, 2), rng.int(2, 5), rng.int(2, 4)) : createScale(rng.int(1, 4), rng.int(2, 9), rng.int(2, 8)));

function answers({ c, km, g }: ScaleProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "groups", l: "How many map units?", a: s => [num(c * g), op("÷"), num(c), op("="), ...s], ans: g, h: `Each group is ${c} cm long. How many groups fit along the line?`,
        w: [[c * g * c, "Multiplied", `Count how many ${c} cm groups fit: that's dividing.`]] }),
      ns({ id: "real", l: "Real distance", a: s => [num(g), op("×"), num(km), op("="), ...s, text(" km")], ans: g * km, h: `Each group is ${km} km.`,
        w: [[c * g * km, "Skipped a step", `Each ${c} cm (not each 1 cm) is ${km} km.`]] }),
    ],
    finalParts: [-1],
  };
}

/** The map distance as a bar; beat 1 cuts it into groups of c cm; beat 2 lays the same number of km groups under it. */
export function scalePicture({ c, km, g }: ScaleProblem) {
  return buildTape({
    rows: [
      { length: g, parts: [{ count: 1, from: 0 }, { count: g, from: 1 }], fills: [{ a: 0, b: g, tone: "on" }], each: [{ text: () => `${c} cm`, from: 1 }],
        label: [{ text: "map" }], total: [{ text: `${c * g} cm` }] },
      { length: g, parts: g, from: 2, fills: [{ a: 0, b: g, tone: "two" }], each: [{ text: () => `${km} km` }], label: [{ text: "real" }],
        total: [{ text: `${g * km} km`, acc: true }] },
    ],
    alt: `A map distance of ${c * g} cm cut into ${count(g, "group")} of ${c} cm; each group is ${km} km, so the real distance is ${g * km} km.`,
  });
}

function explain(p: ScaleProblem, model: AnswerModel): Explanation {
  const { c, km } = p, g = expectedOf(model.steps, "groups"), real = expectedOf(model.steps, "real");
  return {
    heading: "Count the groups",
    idea: ["A scale says every few cm on the map stand for the same real distance, so a longer line is just more of those groups.", "Count the groups, then multiply by what each group stands for."],
    statement: [num(c), text(" cm"), op("="), num(km), text(" km")],
    diagram: scalePicture(p),
    caption: `Each ${c} cm on the map is ${km} km for real.`,
    timeline: beats(3),
    steps: [
      { id: "groups", state: 1, answerStep: "groups", result: g, math: [num(c * g), op("÷"), num(c), op("="), num(g)],
        narration: `Cut the ${c * g} cm into groups of ${c} cm: ${c * g} ÷ ${c} = ${count(g, "group")}.` },
      { id: "real", state: 2, answerStep: "real", result: real, math: [num(g), op("×"), num(km), op("="), num(real), text(" km")],
        narration: `Each group is ${km} km for real: ${g} × ${km} = ${real} km.` },
    ],
  };
}

export const lesson: LessonDefinition<ScaleProblem> = {
  id: "g7-scale",
  grade: 7,
  unit: "Proportions and percents",
  title: "Scale drawings",
  pre: "g7-prop",
  // the current app's card and picture: 2 cm = 5 km, 8 cm is 20 km
  reference: createScale(2, 5, 4),
  generate: (rng, index) => generateScale(rng, index),
  restore: raw => {
    const r = ints(raw, ["c", "km", "g"] as const);
    try { return r && createScale(r.c, r.km, r.g); } catch { return null; }
  },
  display: (p): MathText => [num(p.c), text(" cm"), op("="), num(p.km), text(" km")],
  displayNote: p => `On the map, two towns are ${p.c * p.g} cm apart. How far is that really?`,
  answers,
  explain,
};
