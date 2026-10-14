// Review's 5th grade full pass (2026-10-13): a mixed number printed as "34/9" for 3 4/9 (blocker 2), a missed answer
// read out as its boxes, "It's 1, 1, 18." (blocker 3), and a solved problem line left on "= ?" (item 7). These pin the
// three readers and sweep every lesson so none of them can come back.
import { describe, expect, it } from "vitest";
import { LESSONS } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { frac, mark, num, op, slot, text, toPlainText, type MathText } from "../../curriculum/schemas/math-text";
import { plainProblem } from "../../components/practice/ProblemView";
import { answerIds, expectedValues, finalPartsOf, finalStep, runtimeSteps, sayAnswer } from "../../engine/evaluation/steps";

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
  it("says a skill check's mixed-number answer as one number (add, mix)", () => {
    let seen = 0;
    for (const id of ["add", "mix"]) {
      const l = LESSONS.find(x => x.id === id)!, rng = createRng(5);
      for (let k = 0; k < 40; k++) {
        const model = l.answers(l.generate(rng, k) as never), f = finalStep(finalPartsOf(model.steps, model.finalParts)), ex = expectedValues(f);
        if (ex.w == null) continue;
        seen++;
        expect(sayAnswer(f, ex)).toBe(`${ex.w} ${ex.n}/${ex.d}`);
      }
    }
    expect(seen).toBeGreaterThan(0);
  });

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
        // a fraction answer has n and d boxes; the skill check's final step lays them out itself (boxesOf), so it is swept too
        const ids = answerIds(st.slots), fracBoxes = ids.some(x => /^n\d*$/.test(x)) && ids.some(x => /^d\d*$/.test(x));
        const said = sayAnswer(st, expectedValues(st));
        if (fracBoxes && !st.choices && /\d, \d/.test(said)) bad.push(`${l.id} ${st.id}: "${said}"`);
      }
    }
    expect(bad).toEqual([]);
  });
});

describe("the solved problem line (plainProblem)", () => {
  it("joins a rounded answer with \u2248, never = (g5-round)", () => {
    const l = LESSONS.find(x => x.id === "g5-round")!;
    expect(plainProblem("g5-round", l.reference, true)).toBe("3.476 \u2248 3.48");
  });

  it("writes the answer in, never leaving \"= ?\", in every lesson", () => {
    const bad: string[] = [];
    for (const l of LESSONS) for (const p of problemsOf(l)) {
      const s = plainProblem(l.id, p, true);
      if (/=\s*\?/.test(s)) bad.push(`${l.id}: "${s}"`);
    }
    expect(bad).toEqual([]);
  });
});

describe("g5-pow10's idea line (Curriculum, grade5.md §3, 2026-10-14)", () => {
  it("follows the example's power of 10, in words", () => {
    const l = LESSONS.find(x => x.id === "g5-pow10")!;
    const idea = (x: number, k: number) => { const p = { x, k }; return l.explain(p as never, l.answers(p as never)).idea; };
    expect(idea(3.47, 2)).toEqual(["Times 100 makes each digit worth a hundred times more, so the point hops two places right."]);
    expect(idea(3.47, 1)).toEqual(["Times 10 makes each digit worth ten times more, so the point hops one place right."]);
    expect(idea(3.47, 3)).toEqual(["Times 1000 makes each digit worth a thousand times more, so the point hops three places right."]);
  });
});
