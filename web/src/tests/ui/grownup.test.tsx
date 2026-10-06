// "For the grown-up": one split screen built from this device's history, and a calm page when there is none yet.
import { fireEvent, screen, within } from "@testing-library/react";
import type { Progress } from "../../engine/mastery/progress";
import type { SessionReport } from "../../engine/session/types";
import { chapterScores, mistakePatterns, weekOf, workedExample } from "../../app/grownup";
import { renderApp, tap } from "./helpers";

const LESSON = "Multiply two-digit numbers";
// the helpers' clock starts on Friday 2 October 2026; Thursday is in the same week, the Friday before is not
const t = Date.UTC(2026, 9, 1, 15), lastWeek = Date.UTC(2026, 8, 25, 15);
const scored = (level: 0 | 1 | 2 | 3 | 4, date: number) => ({ last: level, best: level, pct: level / 4, date, mastered: false });

const report: SessionReport = {
  key: "g5-mult2", mode: "practice", title: LESSON, date: t, ms: 600000, total: 4, extra: 0, clean: 2, hints: 1, shown: 0, pct: 0.6, level: 2, xp: 50,
  probs: [
    { lessonId: "g5-mult2", problem: { a: 47, b: 36 }, work: [], hints: 0, wrong: 1, shown: 0, ms: 60000 },
    { lessonId: "g5-mult2", problem: { a: 23, b: 14 }, work: [], hints: 0, wrong: 0, shown: 0, ms: 60000 },
    { lessonId: "g5-mult2", problem: { a: 52, b: 31 }, work: [], hints: 1, wrong: 1, shown: 0, ms: 60000 },
    { lessonId: "g5-mult2", problem: { a: 64, b: 27 }, work: [], hints: 0, wrong: 1, shown: 0, ms: 60000 },
  ],
  mistakes: [
    { n: 1, step: 1, label: "Multiply by the tens", lessonId: "g5-mult2", typed: "141", want: "1410", kind: "Lost the place value", cat: "concept", msg: "The tens digit stands for 30, so add a zero.", rushed: false },
    { n: 3, step: 1, label: "Multiply by the tens", lessonId: "g5-mult2", typed: "156", want: "1560", kind: "Lost the place value", cat: "concept", msg: "The tens digit stands for 30, so add a zero.", rushed: false },
    { n: 4, step: 3, label: "Add the parts", lessonId: "g5-mult2", typed: "1729", want: "1728", kind: "Off by one", cat: "off1", msg: "The answer was exactly 1 off, usually a counting slip.", rushed: false },
  ],
};
const progress: Partial<Progress> = {
  grade: 5, chosen: true, done: 2, lessons: { "g5-mult2": 2 },
  scores: { "g5-mult2": scored(2, t) },
  log: [
    { key: "g5-mult2", mode: "practice", title: LESSON, date: t, level: 2, total: 4, hints: 1, shown: 0, cats: { "Lost the place value": 2, "Off by one": 1 }, rushed: 0 },
    { key: "g5-mult2", mode: "practice", title: LESSON, date: lastWeek, level: 1, total: 6, hints: 3, shown: 2, cats: {}, rushed: 0 },
  ],
};

const openPage = () => { fireEvent.click(screen.getByRole("button", { name: /^My Bento:/ })); tap("Open the report ›"); };

describe("the grown-up page", () => {
  it("with no history: a calm page that says what will show, and that it stays on this device", () => {
    renderApp();
    openPage();
    expect(screen.getByRole("heading", { level: 1, name: "For the grown-up" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 2, name: "Nothing to show yet." })).toBeInTheDocument();
    expect(screen.getByRole("region", { name: "Nothing to show yet." })).toBeInTheDocument();
    expect(screen.getByText("Everything here stays on this device.")).toBeInTheDocument();
    expect(screen.getByText("On this device")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /problems$/ })).toBeNull();
    // the island names the page and the grade, and steps back to My Bento
    expect(screen.getByRole("button", { name: "Contents. You're on For the grown-up" })).toHaveTextContent("My Bento · 5th grade");
    tap("Back to My Bento");
    expect(screen.getByRole("button", { name: "Open the report ›" })).toBeInTheDocument();
  });

  it("with history: this week, the patterns, a worked example, scores by chapter, hints and a thing to try", () => {
    renderApp(progress, { "g5-mult2": report });
    openPage();
    // this week: time from the saved run, lessons from the log (last week's run counts for neither)
    const week = within(screen.getByRole("list", { name: "This week" }));
    expect(week.getAllByRole("listitem").map(li => li.textContent)).toEqual(["10m Time this week", "1Lessons this week", "0 of 4 chaptersAt Proficient 3+"]);

    // patterns, most problems wrong first, with wrong / tries counted in problems
    const rows = screen.getAllByRole("button", { name: /problems$/ });
    expect(rows.map(r => r.getAttribute("aria-label"))).toEqual([
      `Lost the place value, ${LESSON}: 2 of 4 problems`, `Off by one, ${LESSON}: 1 of 4 problems`]);
    expect(rows[0]).toHaveAttribute("aria-current", "true");

    // the worked example: the detail is labelled by its heading; the wrong step wears ✗, the right steps ✓
    const detail = screen.getByRole("region", { name: "Lost the place value" });
    expect(within(detail).getByText("2 of 4 problems")).toBeInTheDocument();
    expect(within(detail).getAllByRole("img", { name: "Wrong" })).toHaveLength(1);
    expect(within(detail).getAllByRole("img", { name: "Right" }).length).toBeGreaterThanOrEqual(1);
    expect(detail.querySelector(".gu-s.bad strong")).toHaveTextContent("141");

    // picking another pattern swaps the detail
    fireEvent.click(rows[1]!);
    expect(screen.getByRole("heading", { level: 2, name: "Off by one" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: `Off by one, ${LESSON}: 1 of 4 problems` })).toHaveAttribute("aria-current", "true");

    // scores by chapter with the app's words, hints over every saved session, one thing to try, privacy
    expect(screen.getAllByText("2 · Approaching").length).toBeGreaterThan(0);
    expect(screen.getByText("4 hints in 2 sessions. 2 steps filled in with Show me.")).toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 3, name: "Do one like it together." })).toBeInTheDocument();
    expect(screen.getByText("Everything here stays on this device.")).toBeInTheDocument();
  });
});

describe("what the page works out", () => {
  it("weeks run Monday to Monday", () => {
    const w = weekOf(new Date(2026, 9, 2, 12).getTime());
    expect(new Date(w.from).getDay()).toBe(1);
    expect(new Date(w.from).getDate()).toBe(28);
    expect(w.to - w.from).toBeGreaterThanOrEqual(7 * 864e5 - 3600e3);
  });

  it("a chapter's score is its lessons' average rounded down, and untouched chapters have none", () => {
    const ch = chapterScores({ ...(progress as Progress), scores: { "g5-mult2": scored(4, t), "g5-order": scored(3, t) } }, 5);
    const withScores = ch.filter(c => c.score != null);
    expect(withScores.length).toBeGreaterThan(0);
    for (const c of withScores) expect(c.score).toBe(Math.floor(c.lessons.reduce((a, l) => a + l.score, 0) / c.lessons.length));
    expect(ch.some(c => c.score == null && c.lessons.length === 0)).toBe(true);
  });

  it("the worked example sets their first tries beside the right steps, from the saved work", () => {
    const withWork: SessionReport = { ...report, probs: report.probs.map((p, i) => i ? p : { ...p, work: [
      { math: [{ t: "text", v: "47 × 30 = 1410" }], shown: false },
      { math: [{ t: "text", v: "47 × 6 = 282" }], shown: true },
      { math: [{ t: "text", v: "1410 + 282 = 1692" }], shown: false },
    ] }) };
    const ex = workedExample(mistakePatterns({ x: withWork })[0]!)!;
    expect(ex.steps.map(s => [s.n, s.their.state, s.picked])).toEqual([[1, "wrong", true], [2, "shown", false], [3, "ok", false]]);
    expect(ex.steps[0]!.their.typed).toBe("141");
  });
});
