import { num, op, text } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildBox3d } from "../../../../explanations/diagrams/box3d/build";
import { expectedOf, ns, plusChain, readNumbers } from "../../area-common/steps";
import { aNum, cap } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** The surface of an l × w × h box: three pairs of matching faces. */
export interface SurfaceProblem { l: number; w: number; h: number }

export function createSurface(l: number, w: number, h: number): SurfaceProblem {
  if (![l, w, h].every(v => Number.isInteger(v) && v > 0)) throw new Error("sides are whole numbers");
  return { l, w, h };
}

/** Same as the current app: every side 2–10. */
export const generateSurface = (rng: Rng): SurfaceProblem => ({ l: rng.int(2, 10), w: rng.int(2, 10), h: rng.int(2, 10) });

export function surfaceAnswers({ l, w, h }: SurfaceProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "top", label: "Top and bottom", prompt: x => [num(l), op("×"), num(w), op("="), x], ans: l * w, hint: "One face: length × width.", wrong: [[l + w, "Added", "A face's area is length × width."]] }),
      ns({ id: "front", label: "Front and back", prompt: x => [num(l), op("×"), num(h), op("="), x], ans: l * h, hint: "The front face is as long as the box and as tall as it: length × height.", wrong: [[l + h, "Added", "A face's area is length × height."]] }),
      ns({ id: "side", label: "The two sides", prompt: x => [num(w), op("×"), num(h), op("="), x], ans: w * h, hint: "A side face is as wide as the box and as tall as it: width × height.", wrong: [[w + h, "Added", "A face's area is width × height."]] }),
      ns({ id: "total", label: "All six faces", prompt: x => [num(2), op("×"), text("("), ...plusChain([l * w, l * h, w * h]), text(")"), op("="), x], ans: 2 * (l * w + l * h + w * h),
        hint: "Each face has a matching partner.", wrong: [[l * w + l * h + w * h, "Counted only three faces", "Each face has a twin on the other side: double it."]] }),
    ],
    finalParts: [-1],
  };
}

export function explainSurface(p: SurfaceProblem, answers: AnswerModel): Explanation {
  const { l, w, h } = p;
  const T = expectedOf(answers.steps, "top"), F = expectedOf(answers.steps, "front"), S = expectedOf(answers.steps, "side"), total = expectedOf(answers.steps, "total");
  return {
    heading: "Three pairs of faces",
    idea: ["A box has three different faces, and each one has a twin on the other side. Add the three, then double."],
    statement: [num(l), op("×"), num(w), op("×"), num(h)],
    diagram: buildBox3d({
      mode: "faces", l, w, h, beats: { top: 1, front: 2, side: 3 },
      text: { top: String(T), front: String(F), side: String(S) },
      labels: { l: String(l), w: String(w), h: String(h), from: 0 },
      lines: [{ text: `2 × (${T} + ${F} + ${S}) = ${total}`, from: 4 }],
      alt: `${cap(aNum(l))} by ${w} by ${h} box: top ${T}, front ${F}, side ${S}, each one twice, ${total} in all.`,
    }),
    caption: "Three different faces, each one twice.",
    timeline: beats(5),
    steps: [
      { id: "top", narration: `Top and bottom are ${l} by ${w}: ${T} each.`, math: [num(l), op("×"), num(w), op("="), num(T)], state: 1, answerStep: "top", result: T },
      { id: "front", narration: `Front and back are ${l} by ${h}: ${F} each.`, math: [num(l), op("×"), num(h), op("="), num(F)], state: 2, answerStep: "front", result: F },
      { id: "side", narration: `The two sides are ${w} by ${h}: ${S} each.`, math: [num(w), op("×"), num(h), op("="), num(S)], state: 3, answerStep: "side", result: S },
      { id: "total", narration: `Each face has a twin you can't see, so double the three: ${total}.`, math: [num(2), op("×"), text("("), ...plusChain([T, F, S]), text(")"), op("="), num(total)], state: 4, answerStep: "total", result: total },
    ],
  };
}

export const lesson: LessonDefinition<SurfaceProblem> = withEasyStart({
  id: "g10-surface",
  grade: 10,
  unit: "Area and volume",
  title: "Surface area of a box",
  reference: createSurface(2, 3, 4),
  generate: rng => generateSurface(rng),
  restore: raw => { const r = readNumbers(raw, ["l", "w", "h"] as const); try { return r && createSurface(r.l, r.w, r.h); } catch { return null; } },
  display: p => [num(p.l), op("×"), num(p.w), op("×"), num(p.h)],
  displayNote: () => "Find the surface area: the total area of all 6 faces.",
  answers: surfaceAnswers,
  explain: explainSurface,
});
