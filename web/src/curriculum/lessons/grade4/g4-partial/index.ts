import { answer, num, op, type MathText } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildAreaGrid, type AreaCell, type AreaSide } from "../../../../explanations/diagrams/area-model/grid";
import { expectedOf, numStep, plusChain, readNumbers } from "../../area-common/steps";
import { count, aNum, cap } from "../../../text";

/** n × m: a three-digit number times a one-digit number, one place at a time. */
export interface PartialProblem { n: number; m: number }

export function createPartial(n: number, m: number): PartialProblem {
  if (!Number.isInteger(n) || n < 100 || n > 999 || !Number.isInteger(m) || m < 1 || m > 9) throw new Error("n has three digits and m one");
  return { n, m };
}

/**
 * n 112–989, m 3–9, as in the current app, but never a whole number of hundreds (600): that is one strip and
 * practises no partial products (fixes-02 A1). A 0 in the tens (502) stays: "there are no tens, so that part is 0".
 */
export const generatePartial = (rng: Rng): PartialProblem => {
  let n: number;
  do n = rng.int(112, 989); while (n % 100 === 0);
  return { n, m: rng.int(3, 9) };
};

const places = (n: number) => ({ H: Math.floor(n / 100), T: Math.floor(n / 10) % 10, O: n % 10 });

export function partialAnswers({ n, m }: PartialProblem): AnswerModel {
  const { H, T, O } = places(n), P = [H * 100 * m, T * 10 * m, O * m];
  return {
    steps: [
      numStep({ id: "hundreds", label: "Hundreds", prompt: x => [num(H * 100), op("×"), num(m), op("="), x], ans: P[0]!,
        wrong: [[H * m, "Lost the place value", `That's ${H} × ${m}. The ${H} stands for ${H * 100}, so put two zeros on the end.`]],
        hint: `Do ${H} × ${m}, then add two zeros.`, explain: `${H} × ${m} = ${H * m}, so ${H * 100} × ${m} = ${P[0]}.`, work: [num(H * 100), op("×"), num(m), op("="), num(P[0]!)] }),
      numStep({ id: "tens", label: "Tens", prompt: x => [num(T * 10), op("×"), num(m), op("="), x], ans: P[1]!,
        wrong: T ? [[T * m, "Lost the place value", `That's ${T} × ${m}. The ${T} stands for ${T * 10}, so put a zero on the end.`]] : [],
        hint: T ? `Do ${T} × ${m}, then add one zero.` : "There are no tens, so this part is 0.", explain: `${T * 10} × ${m} = ${P[1]}.`, work: [num(T * 10), op("×"), num(m), op("="), num(P[1]!)] }),
      numStep({ id: "ones", label: "Ones", prompt: x => [num(O), op("×"), num(m), op("="), x], ans: P[2]!,
        wrong: [[O + m, "Added instead of multiplied", "This one is times, not plus."]],
        hint: O ? `${count(O, "group")} of ${m}.` : "There are no ones, so this part is 0.", explain: `${O} × ${m} = ${P[2]}.`, work: [num(O), op("×"), num(m), op("="), num(P[2]!)] }),
      numStep({ id: "sum", label: "Add the parts", prompt: x => [...plusChain(P), op("="), x], ans: n * m,
        // the commonest slip: only the two biggest parts added (fixes-02 A1); dropped when the ones part is 0
        wrong: [[P[0]! + P[1]!, "Left out a part", `Add all three parts: ${P.join(" + ")}.`]],
        hint: "Line them up by place value and add.", explain: `${P.join(" + ")} = ${n * m}.`, work: [num(n), op("×"), num(m), op("="), answer("x", n * m)] }),
    ],
    finalParts: [-1],
  };
}

export function explainPartial(p: PartialProblem, answers: AnswerModel): Explanation {
  const { n, m } = p, { H, T, O } = places(n);
  const ids = ["hundreds", "tens", "ones"] as const, names = ["hundreds", "tens", "ones"];
  const partsOf = [H * 100, T * 10, O];
  const P = ids.map(id => expectedOf(answers.steps, id)), total = expectedOf(answers.steps, "sum");
  // a place worth nothing gets no strip in the picture; its beat still says so
  const shown = partsOf.map((v, i) => [v, i] as const).filter(([v]) => v > 0);
  const cols: AreaSide[] = shown.map(([v]) => ({ label: String(v), size: v }));
  const cells: AreaCell[] = shown.map(([, i]) => ({ text: String(P[i]), from: i + 1, focus: [i + 1] }));
  // a number with one nonzero place (600) is already one strip: say the problem once, not "600 × 4 = 600 × 4"
  const split = shown.length > 1;
  const statement: MathText = [num(n), op("×"), num(m), ...(split ? [op("="), ...shown.flatMap(([v], k) => [...(k ? [op("+")] : []), num(v), op("×"), num(m)])] : [])];
  return {
    heading: "Multiply one place at a time",
    idea: ["Split the big number into hundreds, tens and ones. Multiply each part, then add."],
    statement,
    diagram: buildAreaGrid({
      cols, rows: [{ label: String(m), size: m }], cells: [cells], minRow: 80,
      lines: [{ text: split ? `${n} × ${m} = ${P.filter(x => x > 0).join(" + ")} = ${total}` : `${n} × ${m} = ${total}`, from: 4 }],
      alt: `${cap(aNum(m))} by ${n} rectangle cut by place value: ${shown.map(([v, i]) => `${m} × ${v} = ${P[i]}`).join(", ")}. Together ${total}.`,
    }),
    caption: split ? `${n} is ${shown.map(([v]) => v).join(" + ")}: one strip for each place.` : `${n} is just ${count(H, "hundred")}, so it is one strip.`,
    timeline: beats(5),
    steps: [
      ...ids.map((id, i) => ({
        id, narration: partsOf[i] ? `The ${names[i]}: ${partsOf[i]} × ${m} = ${P[i]}.` : `There are no ${names[i]}, so that part is 0.`,
        math: [num(partsOf[i]!), op("×"), num(m), op("="), num(P[i]!)], state: i + 1, answerStep: id, result: P[i]!,
      })),
      // a place worth 0 adds nothing, so the worked line leaves out "+ 0" (review v43 item 10)
      { id: "sum", narration: `Add the parts: ${total}.`, math: [...(split ? plusChain(P.filter(x => x > 0)) : [num(n), op("×"), num(m)]), op("="), num(total)], state: 4, answerStep: "sum", result: total },
    ],
  };
}

export const lesson: LessonDefinition<PartialProblem> = {
  id: "g4-partial",
  grade: 4,
  unit: "Whole numbers",
  title: "Multiply big numbers",
  pre: "g3-split",
  reference: createPartial(346, 7),
  generate: rng => generatePartial(rng),
  restore: raw => { const r = readNumbers(raw, ["n", "m"] as const); try { return r && createPartial(r.n, r.m); } catch { return null; } },
  display: p => [num(p.n), op("×"), num(p.m)],
  answers: partialAnswers,
  explain: explainPartial,
  story: ({ n, m }) => ({ op: "×", text: `A box holds **${n}** crayons. How many crayons are in **${m}** boxes?` }),
};
