// Faces, edges and corners: count them on a solid with its hidden edges dashed, then name it.
import { num, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildSolid, POLY_COUNTS, seenCounts } from "../../../../explanations/diagrams/early-k/solids";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { tapStep, words } from "../../gradeK/kit";
import { slips } from "../kit";

const SOLIDS = [
  { kind: "cube", name: "Cube" },
  { kind: "box", name: "Rectangular prism" },
  { kind: "pyramid", name: "Pyramid" },
  { kind: "triPrism", name: "Triangular prism" },
] as const;
const NAMES = SOLIDS.map(s => s.name);

/** solid 0 cube, 1 rectangular prism, 2 square pyramid, 3 triangular prism; turn changes which side is in view */
export interface FacesProblem { solid: number; turn: number }

export function createFaces(solid: number, turn: number): FacesProblem {
  wholeIn("solid", solid, 0, SOLIDS.length - 1);
  wholeIn("turn", turn, 0, 2);
  return { solid, turn };
}

const WHY: Record<string, Record<string, string>> = {
  Cube: { "Rectangular prism": "Every face is a square, so it's a cube." },
  "Rectangular prism": { Cube: "A cube's faces are all squares. These faces are rectangles: a rectangular prism." },
  Pyramid: { "Triangular prism": "A triangular prism has a triangle at each end. This one's faces all meet at one point at the top: a pyramid." },
  "Triangular prism": { Pyramid: "A pyramid's faces meet at one point. This has a triangle at each end: a triangular prism." },
};

function answers(p: FacesProblem): AnswerModel {
  const s = SOLIDS[p.solid]!, c = POLY_COUNTS[s.kind], seen = seenCounts(s.kind, p.turn);
  return {
    steps: [
      oneBox({
        id: "faces", label: "Faces", question: "How many flat faces?",
        prompt: q => [q, text(" faces")], ans: c.faces,
        wrong: slips(c.faces, [[seen.faces, "Counted only the faces in view", `You can see ${seen.faces}. ${c.faces - seen.faces} more are hidden at the back and bottom.`]]),
        hint: "Count the faces you see, then the ones hidden behind the dashed edges.",
        explain: `${c.faces} flat faces: ${seen.faces} you can see and ${c.faces - seen.faces} hidden.`,
      }),
      oneBox({
        id: "edges", label: "Edges", question: "How many edges?",
        prompt: q => [q, text(" edges")], ans: c.edges,
        wrong: slips(c.edges, [[seen.edges, "Counted only the solid lines", "Some edges are hidden too. Count the dashed ones."]]),
        hint: "An edge is where two faces meet. Count the solid lines and the dashed ones.",
        explain: `${c.edges} edges, the dashed ones included.`,
      }),
      oneBox({
        id: "corners", label: "Corners", question: "How many corners?",
        prompt: q => [q, text(" corners")], ans: c.corners,
        wrong: slips(c.corners, [
          c.faces !== c.corners && [c.faces, "Counted the faces", "That's the faces. Corners are the points where edges meet."],
          [c.edges, "Counted the edges", "That's the edges, the lines. Corners are the points where the lines meet."],
          [c.corners - 1, "Missed a hidden corner", "One corner is round the back. Look where the dashed edges meet."],
        ]),
        hint: "A corner is a point where edges meet.",
        explain: `${c.corners} corners.`,
      }),
      tapStep({
        id: "name", label: "Name it", question: "What is this solid called?",
        prompt: [text("It's a ?")], choices: [...NAMES], right: p.solid,
        wrong: i => {
          const why = WHY[s.name]?.[NAMES[i]!];
          return why ? [`Picked ${NAMES[i]!.toLowerCase()}`, why] : [`Picked ${NAMES[i]!.toLowerCase()}`, `Count again: ${c.faces} faces, ${c.edges} edges, ${c.corners} corners. That's a ${s.name.toLowerCase()}.`];
        },
        hint: "Look at the shape of its faces and whether they meet at a point.",
        explain: `${c.faces} faces, ${c.edges} edges and ${c.corners} corners: a ${s.name.toLowerCase()}.`,
        work: [text(`It's a ${s.name.toLowerCase()}.`)],
      }),
    ],
    finalParts: [-1, 0],
  };
}

const ALT = "A solid shape, with its hidden edges dashed.";

function explain(p: FacesProblem, model: AnswerModel): Explanation {
  const s = SOLIDS[p.solid]!, c = POLY_COUNTS[s.kind];
  const state: Record<string, number> = { faces: 1, edges: 2, corners: 3, name: 4 };
  return {
    heading: "Faces, edges and corners",
    idea: ["A solid shape has flat faces. Two faces meet at an edge. Edges meet at a corner."],
    statement: words("Count its faces, edges and corners."),
    diagram: buildSolid({ kind: s.kind, turn: p.turn, hidden: true, running: true, name: s.name, beats: { faces: 1, edges: 2, corners: 3, name: 4 },
      alt: `${ALT} Its ${c.faces} faces light one by one, its ${c.edges} edges trace and its ${c.corners} corners pop: a ${s.name.toLowerCase()}.` }),
    caption: `${c.faces} faces, ${c.edges} edges, ${c.corners} corners.`,
    timeline: beats(5),
    steps: [
      { id: "look", narration: "Dashed lines are edges hidden at the back.", math: words("Look at it."), state: 0 },
      ...model.steps.map(st => ({ id: st.id, narration: st.explain, math: st.work ?? [num(st.slots[0]!.expected as number)], state: state[st.id]!, answerStep: st.id, result: st.slots[0]!.expected! })),
    ],
  };
}

export const lesson: LessonDefinition<FacesProblem> = {
  id: "g2-solids",
  grade: 2,
  unit: "Shapes",
  title: "Faces, edges and corners",
  reference: createFaces(1, 0),
  // a new solid every time: the order cycles, so no solid comes twice in a row
  generate: (rng, index) => createFaces([1, 3, 0, 2][index % 4]!, rng.int(0, 2)),
  restore: raw => {
    const r = raw as Partial<FacesProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createFaces(r.solid as number, r.turn as number); } catch { return null; }
  },
  display: () => words("Count its faces, edges and corners."),
  picture: p => buildSolid({ kind: SOLIDS[p.solid]!.kind, turn: p.turn, hidden: true, alt: ALT }),
  answers,
  explain,
  pre: "k-solids",
};
