// Lines of symmetry: fold along a dashed line to see if the halves match, or count every line of symmetry.
import { text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Pt } from "../../../../explanations/diagrams/geo/kit";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildFold, isSymmetry } from "../../../../explanations/diagrams/early-g4/fold";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { tapStep, words } from "../../gradeK/kit";
import { slips } from "../_kit";
import { noun } from "../../../text";

const reg = (n: number, r: number, start: number): Pt[] => Array.from({ length: n }, (_, i) => { const a = ((start + (360 * i) / n) * Math.PI) / 180; return [r * Math.cos(a), -r * Math.sin(a)]; });
const heart: Pt[] = Array.from({ length: 48 }, (_, i) => {
  const t = (2 * Math.PI * i) / 48;
  return [7 * 16 * Math.sin(t) ** 3, -7 * (13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t)) + 14];
});
const diag = (Math.atan2(130, 220) * 180) / Math.PI;

/** every shape upright, centered on the origin; `lines` are its lines of symmetry, `traps` tempting lines that aren't */
export const SHAPES: { name: string; poly: Pt[]; lines: number[]; traps: number[]; regular?: number }[] = [
  { name: "square", poly: [[-80, -80], [80, -80], [80, 80], [-80, 80]], lines: [0, 90, 45, 135], traps: [], regular: 4 },
  { name: "rectangle", poly: [[-110, -65], [110, -65], [110, 65], [-110, 65]], lines: [0, 90], traps: [diag, 180 - diag] },
  { name: "equilateral triangle", poly: reg(3, 100, 90), lines: [90, 30, 150], traps: [0], regular: 3 },
  { name: "isosceles triangle", poly: [[0, -110], [70, 60], [-70, 60]], lines: [90], traps: [0] },
  { name: "scalene triangle", poly: [[-20, -90], [100, 60], [-90, 60]], lines: [], traps: [90] },
  { name: "hexagon", poly: reg(6, 100, 0), lines: [0, 30, 60, 90, 120, 150], traps: [], regular: 6 },
  { name: "parallelogram", poly: [[-70, -60], [130, -60], [70, 60], [-130, 60]], lines: [], traps: [0, 90, (Math.atan2(60, 130) * 180) / Math.PI] },
  { name: "heart", poly: heart, lines: [90], traps: [0] },
  { name: "kite", poly: [[0, -120], [70, 0], [0, 60], [-70, 0]], lines: [90], traps: [0] },
  { name: "pentagon", poly: reg(5, 100, 90), lines: [90, 18, 54, 126, 162], traps: [0], regular: 5 },
];
const TURNS = [0, 15, 30, -20];
const candidates = (shape: number) => [...SHAPES[shape]!.lines, ...SHAPES[shape]!.traps];

/** kind 0: is candidates(shape)[line] a line of symmetry; kind 1: how many lines. turn turns the picture */
export interface SymProblem { kind: number; shape: number; line: number; turn: number }

export function createSym(p: SymProblem): SymProblem {
  wholeIn("kind", p.kind, 0, 1);
  wholeIn("shape", p.shape, 0, SHAPES.length - 1);
  wholeIn("turn", p.turn, 0, TURNS.length - 1);
  if (p.kind === 0) wholeIn("line", p.line, 0, candidates(p.shape).length - 1);
  return { kind: p.kind, shape: p.shape, line: p.kind === 0 ? p.line : 0, turn: p.turn };
}

function answers(p: SymProblem): AnswerModel {
  const sh = SHAPES[p.shape]!;
  if (p.kind === 0) {
    const ok = isSymmetry(sh.poly, candidates(p.shape)[p.line]!);
    return { steps: [tapStep({
      id: "fold", label: "Fold it", question: "Fold along the dashed line. Do the two halves match?", prompt: [text("Do the halves match?")], choices: ["Yes", "No"], right: ok ? 0 : 1,
      wrong: () => ok ? ["Said no", "Fold it in your head: every corner lands on a corner. The halves match."]
        : p.shape === 1 ? ["Said yes", "Fold a rectangle on its diagonal and the corners stick out. The halves are the same size but don't match."]
        : p.shape === 6 ? ["Said yes", "A parallelogram's halves match if you turn one, but not if you fold it. It has no lines of symmetry."]
        : ["Said yes", "Fold it in your head: parts stick out past the other half."],
      hint: "Picture folding the paper on the line. Does one half land exactly on the other?",
      explain: ok ? "The halves match: it's a line of symmetry." : "The halves don't match: it's not a line of symmetry.", work: [text(ok ? "Yes" : "No")],
    })], finalParts: [-1] };
  }
  const n = sh.lines.length;
  return { steps: [oneBox({
    id: "count", label: "Count the lines", question: "How many lines of symmetry?", prompt: s => [s, text(` ${noun(n, "line")} of symmetry`)], ans: n,
    wrong: slips(n, [
      ...(p.shape === 1 ? [[4, "Counted the diagonals", "The diagonals don't work for a rectangle. Only the two through the middles of the sides: 2."] as [number, string, string]] : []),
      ...(p.shape === 0 ? [[2, "Missed the diagonals", "A square folds on its diagonals too: 4 in all."] as [number, string, string]] : []),
      ...(sh.regular ? [n - 1, n + 1].map(v => [v, "Off by one", `A regular shape with ${n} sides has ${n} lines of symmetry.`] as [number, string, string]) : []),
      ...(p.shape === 6 ? [[2, "Counted lines that don't fold", "Fold a parallelogram on any line and parts stick out. It has no lines of symmetry."] as [number, string, string]] : []),
    ]),
    hint: "Try each way you could fold it: across, up and down, corner to corner.",
    explain: n ? `${n} ${n === 1 ? "line" : "lines"} of symmetry.` : "No lines of symmetry.",
  })], finalParts: [-1] };
}

const alt = (p: SymProblem) => (p.kind === 0 ? `A ${SHAPES[p.shape]!.name} with a dashed line across it.` : `A ${SHAPES[p.shape]!.name}.`);

function explain(p: SymProblem, model: AnswerModel): Explanation {
  const sh = SHAPES[p.shape]!, s = model.steps[0]!;
  return {
    heading: "Lines of symmetry",
    idea: ["A line of symmetry folds a shape into two halves that match."],
    statement: words(s.question ?? ""),
    diagram: p.kind === 0
      ? buildFold({ poly: sh.poly, line: candidates(p.shape)[p.line]!, rotate: TURNS[p.turn]!, beats: { fold: 1 }, alt: `${alt(p)} One half folds over the line: ${s.explain}` })
      : buildFold({ poly: sh.poly, lines: sh.lines, rotate: TURNS[p.turn]!, beats: { count: 1 }, alt: `${alt(p)} ${s.explain} Each one draws in turn.` }),
    caption: `${s.explain}`,
    timeline: beats(2),
    steps: [
      { id: "look", narration: p.kind === 0 ? "Fold the paper on the dashed line." : "Find every way to fold it so the halves match.", math: words("Look at it."), state: 0 },
      { id: s.id, narration: s.explain, math: s.work, state: 1, answerStep: s.id, result: s.slots[0]!.expected! },
    ],
  };
}

export const lesson: LessonDefinition<SymProblem> = {
  id: "g4-symmetry",
  grade: 4,
  unit: "Lines and shapes",
  title: "Lines of symmetry",
  reference: createSym({ kind: 0, shape: 1, line: 2, turn: 0 }),
  generate: (rng, index) => {
    if (index < 3) {
      const shape = [1, 0, 7][index]!, c = SHAPES[shape]!, trap = c.traps.length > 0 && rng.int(0, 1) === 1;
      return createSym({ kind: 0, shape, line: trap ? c.lines.length + rng.int(0, c.traps.length - 1) : rng.int(0, c.lines.length - 1), turn: 0 });
    }
    const kind = index % 2, shape = rng.int(0, SHAPES.length - 1), n = candidates(shape).length, turn = index > 5 ? rng.int(0, TURNS.length - 1) : 0;
    return createSym({ kind, shape, line: rng.int(0, n - 1), turn });
  },
  restore: raw => {
    const r = raw as Partial<SymProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createSym(r as SymProblem); } catch { return null; }
  },
  display: p => words(answers(p).steps[0]!.question ?? ""),
  picture: p => buildFold({ poly: SHAPES[p.shape]!.poly, ...(p.kind === 0 ? { line: candidates(p.shape)[p.line]! } : {}), rotate: TURNS[p.turn]!, alt: alt(p) }),
  answers,
  explain,
  pre: "g4-lines",
};
