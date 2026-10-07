import { num, op, sqrt, text, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid } from "../../../../explanations/diagrams/area-model/grid";
import { buildBox3d } from "../../../../explanations/diagrams/box3d/build";
import { r1 } from "../../../../explanations/diagrams/scene/helpers";
import { expectedOf, ns } from "../../area-common/steps";
import { count } from "../../../text";
import { withEasyStart } from "../../easy-start";

/** √(n²) or ∛(n³): find n. */
export interface RootProblem { cube: boolean; n: number }

export function createRoot(cube: boolean, n: number): RootProblem {
  if (!Number.isInteger(n) || n < 1) throw new Error("the root is a whole number");
  return { cube, n };
}

/** Same as the current app: a cube root 40% of the time (n 2–6), otherwise a square root (n 2–15). */
export function generateRoot(rng: Rng): RootProblem {
  const cube = rng.next() < 0.4;
  return { cube, n: cube ? rng.int(2, 6) : rng.int(2, 15) };
}

const power = ({ cube, n }: RootProblem) => n ** (cube ? 3 : 2);
const radical = (p: RootProblem): MathText => (p.cube ? [text("∛"), num(power(p))] : [sqrt(power(p))]);

export function rootAnswers(p: RootProblem): AnswerModel {
  const { cube, n } = p, k = cube ? 3 : 2, v = power(p);
  return {
    steps: [
      ns({ id: "root", label: "Find the root", question: `What number times itself${cube ? ", three times," : ""} makes ${v}?`, prompt: x => [...radical(p), op("="), x], ans: n,
        hint: cube ? `Try a number times itself three times, and get closer: is it more or less than ${v}?` : `Try a number times itself, and get closer: is it more or less than ${v}?`,
        wrong: [[v / k, "The root isn't a division", `${cube ? "Cube" : "Square"} root means the number that multiplies by itself.`]] }),
      ns({ id: "check", label: "Check it", prompt: x => [...Array.from({ length: k }, (_, i) => (i ? [op("×"), num(n)] : [num(n)])).flat(), op("="), x], ans: v, hint: `Multiply ${n} by itself${cube ? " three times" : ""}: you should get back the number under the root.`,
        wrong: [[n * k, `Multiplied by ${k}`, `${cube ? "Cubed" : "Squared"} means ${n} times itself, not ${n} × ${k}.`]] }),
    ],
    finalParts: [0],
  };
}

export function explainRoot(p: RootProblem, answers: AnswerModel): Explanation {
  const { cube } = p, v = power(p), n = expectedOf(answers.steps, "root"), check = expectedOf(answers.steps, "check");
  const times = Array.from({ length: cube ? 3 : 2 }, () => String(n)).join(" × ");
  const diagram = cube
    ? buildBox3d({
      mode: "cubes", l: n, w: n, h: n, layerBeats: [0], labels: { l: String(n), w: String(n), h: String(n), from: 1 },
      lines: [{ text: `${count(v, "cube")}`, from: 0, until: 1, cls: "lbl" }, { text: `${times} = ${check}`, from: 2 }],
      alt: `A cube built from ${v} unit cubes; each edge is ${n}.`,
    })
    : buildAreaGrid({
      cols: [{ label: String(n), size: n, from: 1 }], rows: [{ label: String(n), size: n, from: 1 }],
      cells: [[{ text: String(v) }]], units: 0,
      extras: g => [
        { type: "text", x: r1(g.left + g.width / 2), y: r1(g.top - 16), text: "?", cls: "lbl acc", until: 0 },
        { type: "text", x: r1(g.left - 12), y: r1(g.top + g.height / 2), text: "?", cls: "lbl acc end", until: 0 },
      ],
      lines: [{ text: `${times} = ${check}`, from: 2 }],
      alt: `A square made of ${v} unit squares; each side is ${n}.`,
    });
  return {
    heading: cube ? "Undo the cube" : "Undo the square",
    idea: ["A root undoes a power, like the side of a square or the edge of a cube."],
    statement: radical(p),
    diagram,
    caption: cube ? `A cube with volume ${v} has edges of ${n}.` : `A square with area ${v} has sides of ${n}.`,
    timeline: beats(3),
    steps: [
      { id: "root", narration: cube ? `${count(v, "cube")} make a cube with ${n} along each edge.` : `${count(v, "square")} make a square with ${n} along each side.`, math: [...radical(p), op("="), num(n)], state: 1, answerStep: "root", result: n },
      { id: "check", narration: `Check it: ${times} = ${check}.`, math: [...times.split(" × ").flatMap((t, i) => (i ? [op("×"), num(Number(t))] : [num(Number(t))])), op("="), num(check)], state: 2, answerStep: "check", result: check },
    ],
  };
}

export const lesson: LessonDefinition<RootProblem> = withEasyStart({
  id: "g8-roots",
  grade: 8,
  unit: "Exponents and roots",
  title: "Square and cube roots",
  reference: createRoot(false, 9),
  generate: rng => generateRoot(rng),
  restore: raw => {
    if (!raw || typeof raw !== "object") return null;
    const r = raw as Record<string, unknown>;
    if (typeof r.cube !== "boolean" || typeof r.n !== "number") return null;
    try { return createRoot(r.cube, r.n); } catch { return null; }
  },
  display: radical,
  answers: rootAnswers,
  explain: explainRoot,
});
