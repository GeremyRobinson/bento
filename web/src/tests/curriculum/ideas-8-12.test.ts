// Grades 8 to 12: every lesson page opens on an intro that says why (Curriculum fixes-02, Part C pattern 1).
// The idea is about the method, not the problem, so it never repeats a number the problem shows.
import { LESSONS } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { toPlainText } from "../../curriculum/schemas/math-text";

const plain = (v: unknown): string => (typeof v === "string" ? v : JSON.stringify(v));

describe.each(LESSONS.filter(l => l.grade >= 8).map(l => [l.id, l] as const))("%s intro", (_id, lesson) => {
  it("has at least one full sentence, and no numbers from the problem", () => {
    const rng = createRng(5);
    for (const p of [lesson.reference, ...Array.from({ length: 12 }, (_, i) => lesson.generate(rng, i))]) {
      const idea = (lesson.explain(p, lesson.answers(p)).idea ?? []).map(plain).join(" ");
      expect(idea.length, "idea is missing").toBeGreaterThan(0);
      expect(idea).toMatch(/[a-z].*[.!?]$/);
      const shown = new Set(toPlainText(lesson.display(p)).match(/\d+(\.\d+)?/g) ?? []);
      // a triangle's name, like 30-60-90, is not a number from the problem
      const used = (idea.replace(/\d+-\d+-\d+/g, "").match(/\d+(\.\d+)?/g) ?? []).filter(n => shown.has(n) && n.length > 1);
      expect(used, `idea repeats the problem's numbers: ${idea}`).toEqual([]);
    }
  });
});
