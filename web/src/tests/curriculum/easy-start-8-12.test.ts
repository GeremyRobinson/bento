// Grades 8 to 12: the first three problems of a run have smaller numbers than the typical problem after them
// (Curriculum fixes-02, Part C: "the first problems aren't easier").
import { LESSONS } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { problemSize } from "../../curriculum/lessons/easy-start";

const median = (xs: number[]) => { const s = [...xs].sort((a, b) => a - b); return s[Math.floor(s.length / 2)]!; };

describe.each(LESSONS.filter(l => l.grade >= 8).map(l => [l.id, l] as const))("%s", (_id, lesson) => {
  it("starts with smaller numbers than the median problem", () => {
    const early: number[] = [], later: number[] = [];
    for (let seed = 1; seed <= 40; seed++) {
      const rng = createRng(seed);
      for (let i = 0; i < 10; i++) (i < 3 ? early : later).push(problemSize(lesson, lesson.generate(rng, i)));
    }
    expect(median(early)).toBeLessThanOrEqual(median(later));
    expect(early.reduce((a, b) => a + b) / early.length).toBeLessThan(later.reduce((a, b) => a + b) / later.length);
  });
});
