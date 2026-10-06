// Points, lines, rays and angles: name a line, ray or segment; name an angle by comparing it to a square corner;
// tell parallel, perpendicular and intersecting lines apart.
import { num, text } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAngleFig, buildFigure, buildPair } from "../../../../explanations/diagrams/early-g4/figures";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { tapStep, words } from "../../gradeK/kit";
import { slips } from "../_kit";

export const FIGURES = ["Line", "Ray", "Segment"];
export const ANGLES = ["Acute", "Right", "Obtuse", "Straight"];
export const PAIRS = ["Parallel", "Perpendicular", "Intersecting"];
const TURNS = [0, 25, 60, 90, 135, -20];

/** kind 0: FIGURES[item]; kind 1: an angle of deg degrees; kind 2: PAIRS[item], meeting at deg when intersecting. turn turns it */
export interface LinesProblem { kind: number; item: number; deg: number; turn: number }

export function createLines(p: LinesProblem): LinesProblem {
  wholeIn("kind", p.kind, 0, 2);
  wholeIn("turn", p.turn, 0, TURNS.length - 1);
  if (p.kind === 1) {
    wholeIn("deg", p.deg, 15, 180);
    if ((p.deg > 165 && p.deg !== 180) || (p.deg > 80 && p.deg < 100 && p.deg !== 90)) throw new Error("an angle that's clearly one kind");
    return { kind: 1, item: 0, deg: p.deg, turn: p.turn };
  }
  wholeIn("item", p.item, 0, 2);
  if (p.kind === 2 && p.item === 2) wholeIn("deg", p.deg, 30, 70);
  return { kind: p.kind, item: p.item, deg: p.kind === 2 && p.item === 2 ? p.deg : 0, turn: p.turn };
}

const angleName = (deg: number) => (deg < 90 ? 0 : deg === 90 ? 1 : deg < 180 ? 2 : 3);

function answers(p: LinesProblem): AnswerModel {
  if (p.kind === 0) {
    const ends = [0, 1, 2][p.item]!;
    return {
      steps: [
        oneBox({ id: "ends", label: "Endpoints", question: "How many endpoints?", prompt: s => [s, text(" endpoints")], ans: ends,
          wrong: slips(ends, [[2, "Counted the arrowheads", "Arrowheads mean it keeps going. They aren't endpoints."], [1, "Counted one end", "Look at both ends: is each a dot or an arrowhead?"]]),
          hint: "A dot is an endpoint. An arrowhead means it keeps going.", work: [num(ends), text(ends === 1 ? " endpoint" : " endpoints")], explain: ends ? `${ends} ${ends === 1 ? "endpoint" : "endpoints"}.` : "No endpoints: it goes on forever both ways." }),
        tapStep({ id: "name", label: "Name it", question: "What is it called?", prompt: [text("It's a ?")], choices: FIGURES, right: p.item,
          wrong: i => [`Picked ${FIGURES[i]!.toLowerCase()}`, i === 0 ? "A line goes on forever both ways: arrowheads at both ends." : i === 1 ? "A ray has one endpoint and goes on forever one way." : "A segment has two endpoints and stops at both."],
          hint: "Count the endpoints: 0 is a line, 1 a ray, 2 a segment.", explain: `${ends} endpoints: a ${FIGURES[p.item]!.toLowerCase()}.`.replace("0 endpoints", "No endpoints").replace("1 endpoints", "1 endpoint"), work: [text(FIGURES[p.item]!)] }),
      ],
      finalParts: [-1],
    };
  }
  if (p.kind === 1) {
    const k = angleName(p.deg), cmp = p.deg < 90 ? 0 : p.deg === 90 ? 1 : 2, names = p.deg === 180 ? ANGLES : ANGLES.slice(0, 3);
    return {
      steps: [
        tapStep({ id: "compare", label: "Compare to a square corner", question: "Is it smaller than a square corner, a square corner, or bigger?", prompt: [text("Compared to a square corner: ?")],
          choices: ["Smaller", "Square corner", "Bigger"], right: cmp,
          wrong: () => ["Judged by the arms", "Long arms don't make a bigger angle. Look at how wide it opens."],
          hint: "Picture the corner of a page at the point.", explain: cmp === 0 ? "It opens less than a square corner." : cmp === 1 ? "It's exactly a square corner." : "It opens wider than a square corner.", work: [text(["Smaller", "Square corner", "Bigger"][cmp]!)] }),
        tapStep({ id: "name", label: "Name it", question: "What kind of angle is it?", prompt: [text("It's ?")], choices: names, right: k,
          wrong: i => [`Picked ${names[i]!.toLowerCase()}`, ["Acute is smaller than a square corner.", "Right is exactly a square corner.", "Obtuse is bigger than a square corner but not a straight line.", "Straight is a straight line: 180°."][i]!],
          hint: "Smaller than a square corner: acute. A square corner: right. Bigger: obtuse.", explain: `It's ${k === 0 || k === 2 ? "an" : "a"} ${ANGLES[k]!.toLowerCase()} angle.`, work: [text(ANGLES[k]!)] }),
      ],
      finalParts: [-1],
    };
  }
  const meet = p.item !== 0;
  const steps: AnswerStep[] = [tapStep({ id: "meet", label: "Do they meet?", question: "If the lines kept going, would they meet?", prompt: [text("Would they meet?")], choices: ["Yes", "No"], right: meet ? 0 : 1,
    wrong: () => (meet ? ["Said no", "Keep them going: they get closer and cross."] : ["Said yes", "They stay the same distance apart, so they never meet."]),
    hint: "Picture both lines running on past the arrowheads.", explain: meet ? "Yes, they meet." : "No, they stay the same distance apart.", work: [text(meet ? "Yes" : "No")] })];
  if (meet) steps.push(tapStep({ id: "square", label: "Square corners?", question: "Do they make square corners where they meet?", prompt: [text("Square corners?")], choices: ["Yes", "No"], right: p.item === 1 ? 0 : 1,
    wrong: () => (p.item === 1 ? ["Said no", "Check with the corner of a page: it fits."] : ["Said yes", "Check with the corner of a page: the corners are too narrow and too wide."]),
    hint: "Picture the corner of a page where they cross.", explain: p.item === 1 ? "Yes: square corners." : "No: not square corners.", work: [text(p.item === 1 ? "Yes" : "No")] }));
  steps.push(tapStep({ id: "name", label: "Name it", question: "What are these lines called?", prompt: [text("They're ?")], choices: PAIRS, right: p.item,
    wrong: i => [`Picked ${PAIRS[i]!.toLowerCase()}`, i === 0 ? "Keep them going: they get closer and cross. Parallel lines stay the same distance apart." : i === 1 ? "Perpendicular lines meet at square corners." : p.item === 0 ? "These never meet, so they're parallel." : "They meet at square corners, so they're perpendicular."],
    hint: "Never meet: parallel. Meet at square corners: perpendicular. Otherwise: intersecting.", explain: `They're ${PAIRS[p.item]!.toLowerCase()}.`, work: [text(PAIRS[p.item]!)] }));
  return { steps, finalParts: [-1] };
}

const altOf = (p: LinesProblem) => (p.kind === 0 ? "A figure with points A and B." : p.kind === 1 ? "An angle." : "Two lines.");
function picture(p: LinesProblem, learn = false) {
  const turn = TURNS[p.turn]!, name = p.kind === 0 ? FIGURES[p.item]! : p.kind === 1 ? `${ANGLES[angleName(p.deg)]} angle` : PAIRS[p.item]!;
  if (p.kind === 0) return buildFigure({ item: p.item, turn, ...(learn ? { beats: { more: 1, name: 2 }, name } : {}), alt: altOf(p) });
  if (p.kind === 1) return buildAngleFig({ deg: p.deg, turn, arm: p.deg < 90 ? 150 : 100, ...(learn ? { beats: { open: 1, name: 2 }, name } : {}), alt: altOf(p) });
  return buildPair({ item: p.item, deg: p.deg, turn, ...(learn ? { beats: { run: 1, name: 2 }, name } : {}), alt: altOf(p) });
}

function explain(p: LinesProblem, model: AnswerModel): Explanation {
  const last = model.steps.at(-1)!;
  return {
    heading: "Lines, rays and angles",
    idea: ["A line goes on forever both ways. A ray starts at a point and goes on forever one way. A segment has two endpoints. Two rays from one point make an angle."],
    statement: words(last.question ?? ""),
    diagram: picture(p, true),
    caption: `${last.explain}`,
    timeline: beats(3),
    steps: [
      { id: "look", narration: "Look at the ends and where the lines go.", math: words("Look at it."), state: 0 },
      ...model.steps.map((s, i, all) => ({ id: s.id, narration: s.explain, math: s.work, state: i === all.length - 1 ? 2 : 1, answerStep: s.id, result: s.slots[0]!.expected! })),
    ],
  };
}

export const lesson: LessonDefinition<LinesProblem> = {
  id: "g4-lines",
  grade: 4,
  unit: "Lines and shapes",
  title: "Points, lines, rays and angles",
  reference: createLines({ kind: 1, item: 0, deg: 130, turn: 1 }),
  generate: (rng, index) => {
    if (index < 3) return index === 1 ? createLines({ kind: 1, item: 0, deg: rng.pick([30, 90, 150]), turn: 0 }) : createLines({ kind: 0, item: rng.int(0, 2), deg: 0, turn: 0 });
    const kind = index % 3, turn = rng.int(0, TURNS.length - 1);
    if (kind === 1) {
      const deg = rng.int(0, 9) === 0 ? 180 : rng.int(0, 3) === 0 ? 90 : rng.pick([...Array.from({ length: 14 }, (_, i) => 15 + 5 * i), ...Array.from({ length: 14 }, (_, i) => 100 + 5 * i)]);
      return createLines({ kind, item: 0, deg, turn });
    }
    return createLines({ kind, item: rng.int(0, 2), deg: rng.int(30, 70), turn });
  },
  restore: raw => {
    const r = raw as Partial<LinesProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createLines(r as LinesProblem); } catch { return null; }
  },
  display: p => words(answers(p).steps.at(-1)!.question ?? ""),
  picture: p => picture(p),
  answers,
  explain,
  pre: "g3-quads",
};
