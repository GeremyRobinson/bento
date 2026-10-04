// Quadrilaterals: count sides and square corners, check equal and parallel sides, then give the most special name.
import { text } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildQuad, classify, quadCorners, QUAD_NAMES, TURNS, turned } from "../../../../explanations/diagrams/early-g3/quads";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { tapStep, words } from "../../gradeK/kit";
import { slips } from "../../grade2/kit";

/**
 * shape 0 square, 1 rectangle, 2 rhombus, 3 parallelogram, 4 trapezoid, 5 other; w, h, slant, top size it (see quadCorners);
 * turn indexes TURNS; warm adds the "how many sides" warm-up; also 1 asks "is it also a rectangle / square?"
 */
export interface QuadProblem { shape: number; w: number; h: number; slant: number; top: number; turn: number; warm: number; also: number }

export function createQuad(p: QuadProblem): QuadProblem {
  wholeIn("shape", p.shape, 0, 5);
  for (const k of ["w", "h", "slant", "top"] as const) wholeIn(k, p[k], 0, 240);
  wholeIn("turn", p.turn, 0, TURNS.length - 1);
  wholeIn("warm", p.warm, 0, 1);
  wholeIn("also", p.also, 0, 1);
  if (p.also && p.shape > 1) throw new Error("only squares and rectangles get the also question");
  const c = classify(quadCorners(p.shape, p.w, p.h, p.slant, p.top));
  if (!c.ok || c.name !== p.shape) throw new Error("the numbers make that shape");
  return { ...p };
}

const cornersOf = (p: QuadProblem) => turned(quadCorners(p.shape, p.w, p.h, p.slant, p.top), TURNS[p.turn]!);

function nameSlip(p: QuadProblem, i: number): [string, string] {
  const picked = `Picked ${QUAD_NAMES[i]!.toLowerCase()}`, c = classify(quadCorners(p.shape, p.w, p.h, p.slant, p.top));
  if (p.shape === 0 && i === 1) return [picked, "It is a rectangle, but all 4 sides are equal too. Its most special name is square."];
  if (p.shape === 0 && i === 2) return [picked, "It has 4 square corners too: it's a square."];
  if (p.shape === 3 && i === 1) return [picked, "A rectangle needs 4 square corners. This one leans."];
  if (i === 5) return [picked, "It is a quadrilateral, but it has a more special name. Look at its sides and corners."];
  if ((i === 0 || i === 1) && c.nRight < 4) return [picked, `A ${QUAD_NAMES[i]!.toLowerCase()} needs 4 square corners. This has ${c.nRight}.`];
  if ((i === 0 || i === 2) && !c.allEqual) return [picked, `A ${QUAD_NAMES[i]!.toLowerCase()} has 4 equal sides. These aren't all equal.`];
  if (i === 3 && c.nPar < 2) return [picked, "A parallelogram has 2 pairs of parallel sides."];
  if (i === 4 && c.nPar !== 1) return [picked, "A trapezoid has exactly 1 pair of parallel sides."];
  return [picked, `It fits a more special name: ${QUAD_NAMES[p.shape]!.toLowerCase()}.`];
}

function answers(p: QuadProblem): AnswerModel {
  const c = classify(quadCorners(p.shape, p.w, p.h, p.slant, p.top)), name = QUAD_NAMES[p.shape]!;
  const steps: AnswerStep[] = [];
  if (p.warm) steps.push(oneBox({ id: "sides", label: "Sides", question: "How many sides?", prompt: s => [s, text(" sides")], ans: 4, wrong: slips(4, [[3, "Missed a side", "Trace all the way around and count every side."]]), hint: "Trace around it and count.", explain: "4 sides: a quadrilateral." }));
  steps.push(
    oneBox({
      id: "corners", label: "Square corners", question: "How many square corners?", prompt: s => [s, text(" square corners")], ans: c.nRight,
      wrong: slips(c.nRight, [c.nRight !== 4 && [4, "Counted every corner", "Check the corners with a square corner: they don't all fit."]]),
      hint: "A square corner is like the corner of a page.", explain: c.nRight ? `${c.nRight} square ${c.nRight === 1 ? "corner" : "corners"}.` : "No square corners.",
    }),
    tapStep({
      id: "equal", label: "Equal sides", question: "Are all 4 sides the same length?", prompt: [text("All 4 sides equal?")], choices: ["Yes", "No"], right: c.allEqual ? 0 : 1,
      wrong: () => (c.allEqual ? ["Said no", "Measure them: all 4 sides are the same length."] : ["Said yes", "Compare them: some sides are longer than others."]),
      hint: "Compare each side with the others.", explain: c.allEqual ? "All 4 sides are equal." : "The sides aren't all equal.", work: [text(c.allEqual ? "Yes" : "No")],
    }),
    tapStep({
      id: "parallel", label: "Parallel sides", question: "How many pairs of sides go the same direction and never meet?", prompt: [text("Pairs of parallel sides: ?")], choices: ["0", "1", "2"], right: c.nPar,
      wrong: i => ["Counted the pairs wrong", i > c.nPar ? "Run the sides on in your head: some pairs would meet." : "Look again: opposite sides that go the same way never meet."],
      hint: "Look at opposite sides. Would they ever meet if they kept going?", explain: `${c.nPar} ${c.nPar === 1 ? "pair" : "pairs"} of parallel sides.`, work: [text(String(c.nPar))],
    }),
    tapStep({
      id: "name", label: "Name it", question: "What is its most special name?", prompt: [text("It's a ?")], choices: [...QUAD_NAMES], right: p.shape,
      wrong: i => nameSlip(p, i),
      hint: "Square corners? Equal sides? Parallel sides?", explain: `It's a ${name.toLowerCase()}.`, work: [text(name)],
    }),
  );
  if (p.also) steps.push(p.shape === 0
    ? tapStep({ id: "also", label: "Also", question: "Is this square also a rectangle?", prompt: [text("Also a rectangle?")], choices: ["Yes", "No"], right: 0,
      wrong: () => ["Said no", "A rectangle needs 4 square corners. A square has them, so every square is a rectangle."], hint: "What does a rectangle need?", explain: "Yes: every square is a rectangle.", work: [text("Yes")] })
    : tapStep({ id: "also", label: "Also", question: "Is this rectangle also a square?", prompt: [text("Also a square?")], choices: ["Yes", "No"], right: 1,
      wrong: () => ["Said yes", "A square needs 4 equal sides. These aren't all equal."], hint: "What does a square need?", explain: "No: its sides aren't all equal.", work: [text("No")] }));
  return { steps, finalParts: [-1] };
}

const ALT = "A four-sided shape.";

function explain(p: QuadProblem, model: AnswerModel): Explanation {
  const name = QUAD_NAMES[p.shape]!, state: Record<string, number> = { sides: 1, corners: 2, equal: 3, parallel: 4, name: 5, also: 5 };
  return {
    heading: "Quadrilaterals",
    idea: ["A quadrilateral has 4 sides. Some have special names because of their sides and corners. A square is a special rectangle and a special rhombus."],
    statement: words("What is its most special name?"),
    diagram: buildQuad({ corners: cornersOf(p), name, beats: { sides: 1, corners: 2, equal: 3, parallel: 4, name: 5 }, alt: `${ALT} Its sides count to 4, its square corners and equal sides are marked, its parallel sides run on: a ${name.toLowerCase()}.` }),
    caption: `It's a ${name.toLowerCase()}.`,
    timeline: beats(6),
    steps: [
      { id: "look", narration: "Look at its sides and corners.", math: words("Look at it."), state: 0 },
      ...model.steps.map(s => ({ id: s.id, narration: s.explain, math: s.work ?? [], state: state[s.id]!, answerStep: s.id, result: s.slots[0]!.expected! })),
    ],
  };
}

function sized(rng: { int: (a: number, b: number) => number }, shape: number) {
  const r = (a: number, b: number) => rng.int(a / 5, b / 5) * 5;
  switch (shape) {
    case 0: { const w = r(100, 160); return { w, h: w, slant: 0, top: 0 }; }
    case 1: return { w: r(150, 200), h: r(70, 120), slant: 0, top: 0 };
    case 2: return { w: r(100, 140), h: 0, slant: r(40, 70), top: 0 };
    case 3: return { w: r(120, 180), h: r(70, 110), slant: r(40, 70), top: 0 };
    case 4: { const w = r(160, 200), slant = rng.int(0, 1) ? 0 : r(20, 40); return { w, h: r(70, 110), slant, top: r(70, w - slant - 30) }; }
    default: return { w: r(140, 190), h: r(100, 130), slant: r(20, 50), top: r(20, 60) };
  }
}

export const lesson: LessonDefinition<QuadProblem> = {
  id: "g3-quads",
  grade: 3,
  unit: "Shapes",
  title: "Quadrilaterals",
  reference: createQuad({ shape: 3, w: 150, h: 90, slant: 50, top: 0, turn: 0, warm: 0, also: 0 }),
  generate: (rng, index) => {
    const early = index < 3, also = index % 4 === 3 ? 1 : 0;
    const shape = early ? [0, 1, 4][index]! : also ? rng.int(0, 1) : (index * 5 + rng.int(0, 1)) % 6;
    for (;;) {
      try { return createQuad({ shape, ...sized(rng, shape), turn: early ? 0 : rng.int(0, TURNS.length - 1), warm: early ? 1 : 0, also }); } catch { /* try new sizes */ }
    }
  },
  restore: raw => {
    const r = raw as Partial<QuadProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createQuad(r as QuadProblem); } catch { return null; }
  },
  display: () => words("What is this shape's most special name?"),
  picture: p => buildQuad({ corners: cornersOf(p), alt: ALT }),
  answers,
  explain,
  pre: "k-shapes",
};
