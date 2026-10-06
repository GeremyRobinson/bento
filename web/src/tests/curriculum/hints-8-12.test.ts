// Grades 8 to 12: a hint helps a learner who is stuck on the step, so it never just repeats the step's arithmetic
// ("21 ÷ 3."), never repeats the step's name, and never hands over an answer the learner can't already see: a
// number that is on the problem, in the step's own line, or found on an earlier step is fair to use (Curriculum
// fixes-02, Part C).
import { LESSONS } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { formatNumber, toPlainText } from "../../curriculum/schemas/math-text";

const BARE = /^[\d\s×÷+−\-().,·/=²³]+\.?$/;
const esc = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
/** the answer written as a number on its own, not as part of a bigger number, a power, a fraction or a term like 2a */
const says = (hint: string, v: number) => new RegExp(`(?<![\\d.,/−^√-])${esc(formatNumber(v))}(?![\\d/a-z]|[.,]\\d)`).test(hint);

describe.each(LESSONS.filter(l => l.grade >= 8).map(l => [l.id, l] as const))("%s hints", (_id, lesson) => {
  it("say why, not the sum, the step's name or the answer", () => {
    const rng = createRng(13), bad = new Set<string>();
    for (let i = 0; i < 40; i++) {
      const p = lesson.generate(rng, i), seen: number[] = [];
      const shown = toPlainText(lesson.display(p));
      for (const s of lesson.answers(p).steps) {
        const onScreen = (v: number) => says(shown, v) || says(toPlainText(s.prompt), v) || says(s.question ?? "", v) || seen.some(x => Math.abs(x - v) < 1e-9);
        const h = s.hint.replace(/\*\*/g, "").trim();
        if (BARE.test(h)) bad.add(`${s.label}: bare arithmetic "${h}"`);
        if (h.replace(/\.$/, "").toLowerCase() === s.label.toLowerCase()) bad.add(`${s.label}: hint is the step's name`);
        // a choice step's answer is an index, not something the hint can give away
        if (!s.choices) for (const x of s.slots) if (x.expected != null && Math.abs(x.expected) >= 2 && says(h, x.expected) && !onScreen(x.expected)) bad.add(`${s.label}: gives the answer ${x.expected} in "${h}"`);
        for (const x of s.slots) if (x.expected != null) seen.push(x.expected);
        seen.push(...(toPlainText(s.prompt).match(/\d+(\.\d+)?/g) ?? []).map(Number));
      }
    }
    expect([...bad].slice(0, 6)).toEqual([]);
  });
});
