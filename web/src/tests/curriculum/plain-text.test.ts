// Review's 5th grade full pass (2026-10-13): a mixed number printed as "34/9" for 3 4/9 (blocker 2), a missed answer
// read out as its boxes, "It's 1, 1, 18." (blocker 3), and a solved problem line left on "= ?" (item 7). These pin the
// three readers and sweep every lesson so none of them can come back.
import { describe, expect, it } from "vitest";
import { LESSONS } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { frac, mark, num, op, slot, text, toPlainText, type MathText } from "../../curriculum/schemas/math-text";
import { plainProblem } from "../../components/practice/ProblemView";
import { answerGroups, expectedValues, finalPartsOf, finalStep, runtimeSteps, sayAnswer } from "../../engine/evaluation/steps";

/** the numbers a reader would see in a plain line, in order ("47,382" is one number; an exponent is its own) */
const readBack = (s: string) => s.match(/\d+(?:,\d{3})*(?:\.\d+)?|[⁰¹²³⁴⁵⁶⁷⁸⁹]+/g) ?? [];
/** the same line with every piece read on its own, so nothing can run into its neighbour */
const apart = (m: MathText): string => m.map(t => (t.t === "mark" || t.t === "muted" || t.t === "bold" || t.t === "part" ? apart(t.v) : toPlainText([t]))).join(" ");

const problemsOf = (l: (typeof LESSONS)[number]) => {
  const rng = createRng(11);
  return [l.reference, ...Array.from({ length: 5 }, (_, i) => l.generate(rng, i))];
};

describe("plain text (toPlainText)", () => {
  it("keeps a whole number apart from the fraction after it: a mixed number reads \"3 4/9\"", () => {
    expect(toPlainText([num(3), frac(4, 9)])).toBe("3 4/9");
    expect(toPlainText([text("What is "), num(2), frac(1, 2), text("?")])).toBe("What is 2 1/2?");
    expect(toPlainText([num(2), frac(1, 2), op("="), frac(5, 2)])).toBe("2 1/2 = 5/2");
    expect(toPlainText([mark([num(3)]), mark([frac(4, 9)])])).toBe("3 4/9");
    expect(toPlainText([slot("w"), frac([slot("n")], [slot("d")])])).toBe("? ?/?");
  });

  it("leaves a fraction after an operator or a word as it was", () => {
    expect(toPlainText([frac(1, 2), op("+"), frac(1, 3)])).toBe("1/2 + 1/3");
    expect(toPlainText([text("of "), frac(2, 3)])).toBe("of 2/3");
  });

  it("reads back as the problem in every lesson: the same numbers, in the same order, none run together", () => {
    const bad: string[] = [];
    for (const l of LESSONS) for (const p of problemsOf(l)) {
      const lines = [l.display(p as never) as MathText, ...l.answers(p as never).steps.flatMap(st => [st.prompt, st.work])];
      for (const m of lines) {
        const s = toPlainText(m), got = readBack(s), want = readBack(apart(m));
        if (got.join(" ") !== want.join(" ")) bad.push(`${l.id}: "${s}" reads ${got.join(" ")}, the problem is ${want.join(" ")}`);
      }
    }
    expect(bad).toEqual([]);
  });
});

describe("an answer said aloud (sayAnswer)", () => {
  it("says a mixed number and a fraction the way they are written", () => {
    const step = { prompt: [num(5), frac(1, 6), op("+"), num(2), frac(7, 9), op("="), slot("w"), frac([slot("n")], [slot("d")])] };
    expect(sayAnswer(step, { w: 1, n: 1, d: 18 })).toBe("1 1/18");
    expect(sayAnswer({ prompt: [frac([slot("n")], [slot("d")])] }, { n: 5, d: 6 })).toBe("5/6");
    expect(sayAnswer({ prompt: [slot("x")] }, { x: 73 })).toBe("73");
  });

  it("never reads a fraction or mixed number answer as a list of its boxes, in any lesson", () => {
    const bad: string[] = [];
    for (const l of LESSONS) for (const p of problemsOf(l)) {
      const model = l.answers(p as never);
      for (const st of [...runtimeSteps(model), finalStep(finalPartsOf(model.steps, model.finalParts))]) {
        const fracBoxes = answerGroups(st.prompt).some(g => g.some(t => t.t === "frac"));
        const said = sayAnswer(st, expectedValues(st));
        if (fracBoxes && !st.choices && /\d, \d/.test(said)) bad.push(`${l.id} ${st.id}: "${said}"`);
      }
    }
    expect(bad).toEqual([]);
  });
});

describe("the solved problem line (plainProblem)", () => {
  it("writes the answer in, never leaving \"= ?\", in every lesson", () => {
    const bad: string[] = [];
    for (const l of LESSONS) for (const p of problemsOf(l)) {
      const s = plainProblem(l.id, p, true);
      if (/=\s*\?/.test(s)) bad.push(`${l.id}: "${s}"`);
    }
    expect(bad).toEqual([]);
  });
});
