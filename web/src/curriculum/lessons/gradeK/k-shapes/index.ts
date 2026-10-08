// Flat shapes: count the straight sides, count the corners, then name the shape.
import { num, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { flatShape, type ShapeKind } from "../../../../explanations/diagrams/early-k/shapes";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { countUp, indexIn, slips, tapStep, words } from "../kit";

const KINDS: { kind: ShapeKind; name: string; sides: number }[] = [
  { kind: "circle", name: "circle", sides: 0 },
  { kind: "triangle", name: "triangle", sides: 3 },
  { kind: "square", name: "square", sides: 4 },
  { kind: "rectangle", name: "rectangle", sides: 4 },
  { kind: "hexagon", name: "hexagon", sides: 6 },
];
/** pixels per size unit in the picture */
const PX = 22;

/** shape picks from KINDS; w and h are its size in units; turn is in degrees */
export interface ShapeProblem { shape: number; w: number; h: number; turn: number }

export function createShape(shape: number, w: number, h: number, turn: number): ShapeProblem {
  indexIn("shape", shape, KINDS);
  wholeIn("w", w, 6, 11);
  wholeIn("h", h, 4, 9);
  wholeIn("turn", turn, -45, 45);
  // a rectangle is clearly longer than it is tall, so it never looks like a square
  if (KINDS[shape]!.kind === "rectangle" && 2 * w < 3 * h) throw new Error("a rectangle must be at least half again as wide as it is tall");
  return { shape, w, h, turn };
}

const cap = (s: string) => s[0]!.toUpperCase() + s.slice(1);
/** a, or an before a vowel */
const an = (s: string) => (/^[aeiou]/.test(s) ? `an ${s}` : `a ${s}`);
const sidesWord = (n: number) => (n === 1 ? "1 side" : `${n} sides`);

/** The names to tap: the four-sided one offered is the square for a square, the rectangle for a rectangle. */
function choicesOf(p: ShapeProblem): typeof KINDS {
  const k = KINDS[p.shape]!.kind;
  const four = k === "square" || k === "rectangle" ? k : (p.w + p.h) % 2 ? "square" : "rectangle";
  return KINDS.filter(x => x.sides !== 4 || x.kind === four);
}

function answers(p: ShapeProblem): AnswerModel {
  const s = KINDS[p.shape]!, n = s.sides, round = n === 0, options = choicesOf(p);
  const right = options.findIndex(x => x.kind === s.kind);
  const trace = "Put your finger on one corner. Go around the shape and count each straight side.";
  return {
    steps: [
      oneBox({
        id: "sides", label: "Count the sides", question: "How many straight sides does it have?",
        prompt: x => [text("Straight sides: "), x], ans: n,
        wrong: slips(n, round ? [
          [1, "Counted the round edge", "A circle's edge is round, not straight. So it has **0** straight sides."],
        ] : [
          [n - 1, "Missed a side", "You missed a side. Start at one corner and go all the way around."],
          [n + 1, "Counted a side twice", "One too many. Stop when you get back to the side you started on."],
        ]),
        hint: round ? "Run your finger around the edge. Is any part straight?" : trace,
        explain: round ? "The edge of a circle is round all the way. It has 0 straight sides." : `${countUp(1, n)}. It has ${n} straight sides.`,
      }),
      oneBox({
        id: "corners", label: "Count the corners", question: "How many corners does it have?",
        prompt: x => [text("Corners: "), x], ans: n,
        wrong: slips(n, round ? [
          [1, "Found a corner", "A circle is smooth all the way around. It has **0** corners."],
        ] : [
          [n - 1, "Missed a corner", "You missed a corner. A corner is where two sides meet. Touch each one."],
          [n + 1, "Counted a corner twice", "One too many. Stop when you get back to the corner you started on."],
        ]),
        hint: round ? "A corner is a point where two straight sides meet. Can you find one?" : "A corner is where two sides meet. Touch each corner as you count.",
        explain: round ? "There are no points where sides meet. It has 0 corners." : `${countUp(1, n)}. It has ${n} corners.`,
      }),
      tapStep({
        id: "name", label: "Name the shape", question: "What is this shape called?",
        prompt: [num(n), text(round ? " straight sides, " : " sides, "), num(n), text(" corners")],
        choices: options.map(x => cap(x.name)), right,
        wrong: i => {
          const o = options[i]!;
          if (round) return ["Picked a shape with corners", `${cap(an(o.name))} has straight sides and corners. This shape is round, with none.`];
          if (o.sides === 0) return ["Picked the round shape", `A circle is round, with no corners. This shape has ${sidesWord(n)}.`];
          return ["Counted sides for another shape", `${cap(an(o.name))} has ${sidesWord(o.sides)}. This shape has ${sidesWord(n)}.`];
        },
        hint: round ? "Which shape is round, with no sides and no corners?" : `Which shape has ${sidesWord(n)} and ${n} corners?`,
        explain: round ? "A round shape with no sides and no corners is a circle."
          : `${n} sides and ${n} corners${s.kind === "square" ? ", all the sides the same length" : s.kind === "rectangle" ? ", with two long sides and two short sides" : ""}: it's ${an(s.name)}.`,
        work: [text(`It's ${an(s.name)}.`)],
      }),
    ],
    finalParts: [-1],
  };
}

function picture(p: ShapeProblem, beatsOf?: { sides: number; corners: number; name: number }) {
  const s = KINDS[p.shape]!;
  return flatShape({
    kind: s.kind, w: p.w * PX, h: p.h * PX, turn: p.turn, name: s.name,
    ...(beatsOf ? { beats: beatsOf } : {}),
    alt: s.sides ? `${cap(an(s.name))} with ${s.sides} sides and ${s.sides} corners.` : "A circle: round, with no sides and no corners.",
  });
}

function explain(p: ShapeProblem, model: AnswerModel): Explanation {
  const s = KINDS[p.shape]!, sides = expectedOf(model, "sides"), corners = expectedOf(model, "corners"), right = expectedOf(model, "name", "c");
  const round = sides === 0;
  return {
    heading: "Sides and corners",
    idea: ["A shape's sides and corners tell you its name."],
    statement: words("What shape is this?"),
    diagram: picture(p, { sides: 0, corners: 1, name: 2 }),
    caption: round ? "Round, with no sides and no corners: a circle." : `${sides} sides and ${corners} corners: ${an(s.name)}.`,
    timeline: beats(3),
    steps: [
      { id: "sides", narration: round ? "Trace the edge. It is round all the way, so there are **0** straight sides." : `Trace each side: ${countUp(1, sides)}. **${sides}** straight sides.`,
        math: [text("Straight sides: "), num(sides)], state: 0, answerStep: "sides", result: sides },
      { id: "corners", narration: round ? "Look for a point where sides meet. There isn't one: **0** corners." : `Touch each corner: ${countUp(1, corners)}. **${corners}** corners.`,
        math: [text("Corners: "), num(corners)], state: 1, answerStep: "corners", result: corners },
      { id: "name", narration: round ? "Round, with no sides and no corners. It's a **circle**." : `${sides} sides and ${corners} corners. It's ${an(s.name).split(" ")[0]} **${s.name}**.`,
        math: [text(`It's ${an(s.name)}.`)], state: 2, answerStep: "name", result: right },
    ],
  };
}

export const lesson: LessonDefinition<ShapeProblem> = {
  id: "k-shapes",
  grade: 0,
  unit: "Shapes and measuring",
  title: "Flat shapes",
  reference: createShape(1, 9, 7, 0),
  generate: (rng, index) => {
    const easy = index < 3;
    const shape = easy ? rng.pick([0, 1, 2]) : rng.int(0, KINDS.length - 1);
    const kind = KINDS[shape]!.kind;
    const h = kind === "rectangle" ? rng.int(4, 6) : rng.int(6, 9);
    const w = kind === "rectangle" ? rng.int(Math.ceil((3 * h) / 2), 11) : rng.int(7, 10);
    const turns: Record<ShapeKind, number[]> = {
      circle: [0], triangle: [-30, -15, 0, 15, 30], square: [0, 15, 30, 45], rectangle: [-15, 0, 15], hexagon: [0, 15, 30],
    };
    return createShape(shape, w, h, easy ? 0 : rng.pick(turns[kind]));
  },
  restore: raw => restoreVia(raw, ["shape", "w", "h", "turn"] as const, v => createShape(v.shape, v.w, v.h, v.turn)),
  display: () => words("What shape is this?"),
  picture: p => picture(p),
  answers,
  explain,
};
