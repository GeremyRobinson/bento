// Solid shapes: does it roll, does it have a flat face, and what is it called.
import { text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildSolid, type SolidKind } from "../../../../explanations/diagrams/early-k/solids";
import { expectedOf, restoreVia, wholeIn } from "../../_number-line/steps";
import { tapStep, words } from "../kit";
import { aOrAnWord } from "../../../text";

interface Solid { kind: SolidKind; name: string; flat: string; rolls: boolean; faces: number; is: string; where: string; things: string[] }
const SOLIDS: Solid[] = [
  { kind: "cube", name: "cube", flat: "square", rolls: false, faces: 6, is: "has 6 flat square faces", where: "the top, the bottom and 4 sides", things: ["block", "dice", "box"] },
  { kind: "sphere", name: "sphere", flat: "circle", rolls: true, faces: 0, is: "is round all over", where: "it is round all over, so no part of it is flat", things: ["ball", "orange", "marble"] },
  { kind: "cylinder", name: "cylinder", flat: "rectangle", rolls: true, faces: 2, is: "has two flat circle ends", where: "one circle at each end", things: ["can", "drum", "candle"] },
  { kind: "cone", name: "cone", flat: "triangle", rolls: true, faces: 1, is: "has one flat circle and a point", where: "the circle at the bottom", things: ["party hat", "ice-cream cone", "traffic cone"] },
];
const cap = (s: string) => s[0]!.toUpperCase() + s.slice(1);

/** shape picks from SOLIDS; thing is −1 for the plain solid, else a real thing in its outline; turn 2 lays it on its side */
export interface SolidProblem { shape: number; thing: number; turn: number }

export function createSolid(shape: number, thing: number, turn: number): SolidProblem {
  wholeIn("shape", shape, 0, SOLIDS.length - 1);
  wholeIn("thing", thing, -1, 2);
  wholeIn("turn", turn, 0, 2);
  if (thing >= 0 && turn === 2) throw new Error("real things stand upright");
  return { shape, thing, turn };
}

/** the four names to tap: the answer, its flat look-alike and two other solids, in an order fixed by the problem */
function namesOf(p: SolidProblem): string[] {
  const s = SOLIDS[p.shape]!, others = SOLIDS.filter(x => x !== s);
  others.splice((p.turn + p.thing + 3) % 3, 1);
  const all = [s.name, s.flat, ...others.map(x => x.name)].map(cap), k = p.shape % 4;
  return [...all.slice(k), ...all.slice(0, k)];
}

function answers(p: SolidProblem): AnswerModel {
  const s = SOLIDS[p.shape]!, names = namesOf(p), right = names.indexOf(cap(s.name));
  const yesNo = ["Yes", "No"];
  return {
    steps: [
      tapStep({
        id: "roll", label: "Roll or stack?", question: "Can it roll?", prompt: words("Can it roll?"),
        choices: yesNo, right: s.rolls ? 0 : 1,
        wrong: () => s.kind === "cube" ? ["Thought a cube rolls", "A cube has flat faces and corners. It slides, but it can't roll."]
          : s.kind === "sphere" ? ["Thought a sphere can't roll", "A sphere is round all over. It rolls every way."]
          : ["Missed the round side", `A ${s.name} has a round side. Lay it down and it rolls.`],
        hint: "Is any part of it round?",
        explain: s.rolls ? `It has a round part, so it rolls.` : "It has only flat faces and corners, so it slides but doesn't roll.",
        work: [text(s.rolls ? "It rolls." : "It doesn't roll.")],
      }),
      tapStep({
        id: "flat", label: "Flat faces", question: "Does it have a flat face?", prompt: words("Does it have a flat face?"),
        choices: yesNo, right: s.faces ? 0 : 1,
        wrong: () => s.kind === "sphere" ? ["Found a flat face", "A sphere is round all over. It has no flat face."]
          : s.kind === "cylinder" ? ["Missed the flat ends", "Look at the ends. They are flat circles."]
          : s.kind === "cone" ? ["Missed the flat bottom", "Look at the bottom. It's a flat circle."]
          : ["Missed the flat faces", "Every side of a cube is a flat square."],
        hint: "Could it stand still on a table on one side?",
        explain: s.faces ? `It has ${s.faces === 1 ? "a flat face" : `${s.faces} flat faces`}: ${s.where}.` : `It has no flat face: ${s.where}.`,
        work: [text(s.faces ? "It has a flat face." : "No flat face.")],
      }),
      tapStep({
        id: "name", label: "Name it", question: "What is this shape called?", prompt: words("What is this shape called?"),
        choices: names, right,
        wrong: i => {
          const n = names[i]!.toLowerCase();
          if (n === s.flat) return ["Named the flat shape", `${aOrAnWord(n, true)} ${n} is flat, like a drawing. This shape is solid: ${aOrAnWord(s.name)} ${s.name}.`];
          if ((n === "cone" && s.kind === "cylinder") || (n === "cylinder" && s.kind === "cone")) return ["Mixed up cylinder and cone", "A cone comes to a point. A cylinder has two flat ends."];
          const o = SOLIDS.find(x => x.name === n)!;
          return ["Picked another solid", `${aOrAnWord(o.name, true)} ${o.name} ${o.is}. This one ${s.is}.`];
        },
        hint: `Use what you found: it ${s.rolls ? "rolls" : "doesn't roll"} and has ${s.faces === 0 ? "no flat face" : s.faces === 1 ? "1 flat face" : `${s.faces} flat faces`}. Which solid is like that?`,
        explain: `It ${s.is}. It's ${aOrAnWord(s.name)} ${s.name}.`,
        work: [text(`It's ${aOrAnWord(s.name)} ${s.name}.`)],
      }),
    ],
    finalParts: [-1],
  };
}

const altOf = (p: SolidProblem) => (p.thing >= 0 ? `${aOrAnWord(SOLIDS[p.shape]!.things[p.thing]!, true)} ${SOLIDS[p.shape]!.things[p.thing]}.` : "A solid shape.");

function explain(p: SolidProblem, model: AnswerModel): Explanation {
  const s = SOLIDS[p.shape]!, roll = expectedOf(model, "roll", "c"), flat = expectedOf(model, "flat", "c"), name = expectedOf(model, "name", "c");
  return {
    heading: "Solid shapes",
    idea: ["Flat shapes lie on paper. Solid shapes you can hold. Cubes, spheres, cylinders and cones are solid."],
    statement: words("What is this shape called?"),
    diagram: buildSolid({ kind: s.kind, turn: p.turn, ...(p.thing >= 0 ? { thing: p.thing } : {}), name: s.name, beats: { faces: 1, move: 2, name: 3 },
      alt: `${altOf(p)} Its flat faces light up, it ${s.rolls ? "rolls" : "slides"}, and its name appears: ${s.name}.` }),
    caption: `It ${s.is}: ${aOrAnWord(s.name)} ${s.name}.`,
    timeline: beats(4),
    steps: [
      { id: "look", narration: p.thing >= 0 ? `This ${s.things[p.thing]} is a solid shape. You could hold it.` : "This is a solid shape. You could hold it.", math: words("Look at it."), state: 0 },
      { id: "flat", narration: s.faces ? `It has ${s.faces === 1 ? "**1** flat face" : `**${s.faces}** flat faces`}.` : "It has **no** flat face.", math: [text(s.faces ? "It has a flat face." : "No flat face.")], state: 1, answerStep: "flat", result: flat },
      { id: "roll", narration: s.rolls ? "Give it a push. It **rolls**." : "Give it a push. It **slides**, but it doesn't roll.", math: [text(s.rolls ? "It rolls." : "It doesn't roll.")], state: 2, answerStep: "roll", result: roll },
      { id: "name", narration: `It ${s.is}. It's ${aOrAnWord(s.name)} **${s.name}**.`, math: [text(`It's ${aOrAnWord(s.name)} ${s.name}.`)], state: 3, answerStep: "name", result: name },
    ],
  };
}

export const lesson: LessonDefinition<SolidProblem> = {
  id: "k-solids",
  grade: 0,
  unit: "Shapes and measuring",
  title: "Solid shapes",
  reference: createSolid(2, -1, 0),
  generate: (rng, index) => {
    const shape = rng.int(0, SOLIDS.length - 1);
    if (index < 3) return createSolid(shape, -1, 0);
    if (index % 3 === 2) return createSolid(shape, rng.int(0, 2), 0);
    const kind = SOLIDS[shape]!.kind;
    return createSolid(shape, -1, kind === "cylinder" || kind === "cone" ? rng.pick([0, 2]) : kind === "cube" ? rng.int(0, 1) : 0);
  },
  restore: raw => restoreVia(raw, ["shape", "thing", "turn"] as const, v => createSolid(v.shape, v.thing, v.turn)),
  display: () => words("Look at this shape."),
  picture: p => buildSolid({ kind: SOLIDS[p.shape]!.kind, turn: p.turn, ...(p.thing >= 0 ? { thing: p.thing } : {}), alt: altOf(p) }),
  answers,
  explain,
  pre: "k-shapes",
};
