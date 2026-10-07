// Add and subtract within 1000: break the second number into hundreds, tens and ones, and hop by each on an open number line.
import { num, op } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildOpenLine } from "../../../../explanations/diagrams/early-g2/lines";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { slips } from "../kit";
import { count } from "../../../text";

/** a + b or a − b (sub = 1) with three-digit numbers; b has no zero digits so every hop is real. */
export interface Within1000Problem { a: number; b: number; sub: number }

const digits = (n: number) => ({ h: Math.floor(n / 100), t: Math.floor(n / 10) % 10, o: n % 10 });

export function createWithin1000(a: number, b: number, sub: number): Within1000Problem {
  wholeIn("a", a, 100, 999);
  wholeIn("b", b, 111, 999);
  wholeIn("sub", sub, 0, 1);
  const { h, t, o } = digits(b);
  if (!h || !t || !o) throw new Error("every digit of b must be 1 to 9");
  if (sub ? a <= b : a + b > 999) throw new Error(sub ? "a must be bigger than b" : "the sum must stay within 999");
  return { a, b, sub };
}

/** Early problems never cross a ten or a hundred; later ones may. */
function generate(rng: Rng, index: number): Within1000Problem {
  const easy = index < 4, sub = rng.int(0, 1);
  for (;;) {
    const b = rng.int(1, sub ? 6 : 5) * 100 + rng.int(1, 9) * 10 + rng.int(1, 9);
    const a = sub ? rng.int(b + 50, 999) : rng.int(100, 999 - b);
    if (a > 999 || a < 100 || (sub && a <= b)) continue;
    const A = digits(a), B = digits(b);
    const crosses = sub ? A.o < B.o || A.t < B.t : A.o + B.o >= 10 || A.t + B.t >= 10;
    if (easy === crosses) continue;
    return createWithin1000(a, b, sub);
  }
}

const hopsOf = ({ a, b, sub }: Within1000Problem) => {
  const s = sub ? -1 : 1, B = digits(b);
  const p1 = a + s * 100 * B.h, p2 = p1 + s * 10 * B.t, r = p2 + s * B.o;
  return { s, B, p1, p2, r };
};

/** What you get by working each digit on its own with no carrying or trading. */
const digitwise = (x: number, y: number, sub: number, place: 1 | 10 | 100) => {
  const dx = Math.floor(x / place) % 10, dy = Math.floor(y / place) % 10;
  return x - dx * place + (sub ? Math.abs(dx - dy) : (dx + dy) % 10) * place;
};

function answers(p: Within1000Problem): AnswerModel {
  const { a, b, sub } = p, { s, B, p1, p2, r } = hopsOf(p);
  const sign = sub ? "−" : "+", verb = sub ? "Take away" : "Add";
  const T = digits(p1).t, O = digits(p2).o;
  const tensCross = sub ? T < B.t : T + B.t >= 10, onesCross = sub ? O < B.o : O + B.o >= 10;
  const allDigits = [100, 10, 1].reduce((x, place) => digitwise(x, b, sub, place as 1 | 10 | 100), a);
  return {
    steps: [
      oneBox({
        id: "hundreds", label: `${verb} the hundreds`,
        question: `${b} is ${B.h * 100} + ${B.t * 10} + ${B.o}. Start with the hundreds.`,
        prompt: x => [num(a), op(sign), num(B.h * 100), op("="), x], ans: p1,
        wrong: slips(p1, [
          [a + s * B.h, "Used ones, not hundreds", `The ${B.h} in ${b} is in the hundreds place, so it means ${B.h * 100}.`],
          [a + s * B.h * 10, "Used tens, not hundreds", `The ${B.h} in ${b} is in the hundreds place, so it means ${B.h * 100}, not ${B.h * 10}.`],
          [a - s * B.h * 100, sub ? "Added instead" : "Took away instead", sub ? "This is taking away, so the number gets smaller." : "This is adding, so the number gets bigger."],
        ]),
        hint: `Only the hundreds digit changes: ${digits(a).h} ${sign} ${B.h}.`,
        explain: `${a} ${sign} ${B.h * 100} = ${p1}.`,
      }),
      oneBox({
        id: "tens", label: `${verb} the tens`,
        prompt: x => [num(p1), op(sign), num(B.t * 10), op("="), x], ans: p2,
        wrong: slips(p2, [
          [p1 + s * B.t, "Used ones, not tens", `The ${B.t} is in the tens place, so it means ${B.t * 10}.`],
          tensCross && [digitwise(p1, B.t * 10, sub, 10), sub ? "Smaller from bigger" : "Forgot to carry",
            sub ? `${count(T, "ten")} is not enough to take away ${B.t}. Trade a hundred for 10 tens, so the hundreds go down by 1.`
              : `${T} + ${count(B.t, "ten")} make ${count(T + B.t, "ten")}. That's a new hundred, so the hundreds go up by 1.`],
        ]),
        hint: sub ? `Count back ${count(B.t, "ten")} from ${p1}.` : `Count on ${count(B.t, "ten")} from ${p1}.`,
        explain: `${p1} ${sign} ${B.t * 10} = ${p2}.`,
      }),
      oneBox({
        id: "ones", label: `${verb} the ones`,
        prompt: x => [num(p2), op(sign), num(B.o), op("="), x], ans: r,
        wrong: slips(r, [
          onesCross && [digitwise(p2, B.o, sub, 1), sub ? "Smaller from bigger" : "Forgot to carry",
            sub ? `${count(O, "one")} is not enough to take away ${B.o}. Trade a ten for 10 ones, so the tens go down by 1.`
              : `${O} + ${B.o} = ${O + B.o}. That makes a new ten, so the tens go up by 1.`],
          [p2 + s * B.o * 10, "Used tens, not ones", `The ${B.o} is in the ones place, so it means just ${B.o}.`],
        ]),
        hint: sub ? `Count back ${B.o} from ${p2}.` : `Count on ${B.o} from ${p2}.`,
        explain: `${p2} ${sign} ${B.o} = ${r}.`,
      }),
      oneBox({
        id: "answer", label: "Answer",
        prompt: x => [num(a), op(sign), num(b), op("="), x], ans: r,
        wrong: slips(r, [
          [allDigits, sub ? "Smaller from bigger" : "Forgot to carry",
            sub ? "In a place where the top digit is smaller, trade from the next place first." : "When a place makes 10 or more, carry 1 to the next place."],
          [sub ? a + b : Math.abs(a - b), sub ? "Added instead" : "Took away instead", sub ? "This is taking away, so the answer is smaller." : "This is adding, so the answer is bigger."],
        ]),
        hint: `Use your last hop: it landed on the answer.`,
        explain: `${a} ${sign} ${b} = ${r}.`,
      }),
    ],
    finalParts: [-1],
  };
}

function explain(p: Within1000Problem, model: AnswerModel): Explanation {
  const { a, b, sub } = p, { B } = hopsOf(p);
  const sign = sub ? "−" : "+";
  const p1 = expectedOf(model, "hundreds"), p2 = expectedOf(model, "tens"), r = expectedOf(model, "ones"), total = expectedOf(model, "answer");
  const H = B.h * 100, T = B.t * 10;
  return {
    heading: sub ? "Hop back by place" : "Hop on by place",
    idea: ["Hundreds, tens and ones are easy hops, so the second number breaks into those."],
    statement: [num(a), op(sign), num(b)],
    diagram: buildOpenLine({
      start: a,
      hops: [{ to: p1, label: `${sign}${H}`, beat: 1 }, { to: p2, label: `${sign}${T}`, beat: 2 }, { to: r, label: `${sign}${B.o}`, beat: 3 }],
      total: `${a} ${sign} ${b} = ${total}`, totalBeat: 4,
      alt: `An open number line from ${a}: hop ${sign}${H} to ${p1}, ${sign}${T} to ${p2}, then ${sign}${B.o} to ${r}.`,
    }),
    caption: `${b} = ${H} + ${T} + ${B.o}`,
    timeline: beats(5),
    steps: [
      { id: "hundreds", narration: `${sub ? "Hop back" : "Hop on"} ${H}: ${a} ${sign} ${H} = ${p1}.`, math: [num(a), op(sign), num(H), op("="), num(p1)], state: 1, answerStep: "hundreds", result: p1 },
      { id: "tens", narration: `${sub ? "Hop back" : "Hop on"} ${T}: ${p1} ${sign} ${T} = ${p2}.`, math: [num(p1), op(sign), num(T), op("="), num(p2)], state: 2, answerStep: "tens", result: p2 },
      { id: "ones", narration: `${sub ? "Hop back" : "Hop on"} ${B.o}: ${p2} ${sign} ${B.o} = ${r}.`, math: [num(p2), op(sign), num(B.o), op("="), num(r)], state: 3, answerStep: "ones", result: r },
      { id: "answer", narration: `The last hop lands on the answer: ${total}.`, math: [num(a), op(sign), num(b), op("="), num(total)], state: 4, answerStep: "answer", result: total },
    ],
  };
}

export const lesson: LessonDefinition<Within1000Problem> = {
  id: "g2-within1000",
  grade: 2,
  unit: "Adding and subtracting",
  title: "Add and subtract within 1000",
  pre: "g2-regroup",
  reference: createWithin1000(245, 132, 0),
  generate,
  restore: raw => restoreVia(raw, ["a", "b", "sub"] as const, v => createWithin1000(v.a, v.b, v.sub)),
  display: p => [num(p.a), op(p.sub ? "−" : "+"), num(p.b)],
  displayNote: p => `Break ${p.b} into hundreds, tens and ones.`,
  answers,
  explain,
};
