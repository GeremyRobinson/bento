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
  checks: { "g5-mult2": { last: 2, best: 2, date: t, due: t + 864e5, passes: 0 } },
  log: [
    { key: "g5-mult2", mode: "practice", title: LESSON, date: t, level: 2, total: 4, hints: 1, shown: 0, cats: { "Lost the place value": 2, "Off by one": 1 }, rushed: 0 },
    { key: "g5-mult2", mode: "practice", title: LESSON, date: lastWeek, level: 1, total: 6, hints: 3, shown: 2, cats: {}, rushed: 0 },
  ],
};

// the person button opens Me, whose Stuck shelf ends with the way to the grown-up page
const openPage = () => { fireEvent.click(screen.getByRole("button", { name: "Me" })); tap(/^For the grown-up/); };

describe("the grown-up page", () => {
  it("with no history: three calm cards, and Back steps to Me", () => {
    renderApp();
    openPage();
    expect(screen.getByRole("button", { name: /^Are they doing the work\? 0 min, this week$/ })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /^Is it sticking\? 0 learned, out of \d+ lessons$/ })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Where can I help? Nothing yet, Finished lessons show up here" })).toBeInTheDocument();
    // the island names the page and steps back to Me
    const place = within(screen.getAllByRole("banner").find(b => b.classList.contains("o-island"))!);
    expect(place.getByText("Me · on this device")).toBeInTheDocument();
    expect(place.getByText("For the grown\u2011up")).toBeInTheDocument();
    tap("Back");
    expect(screen.getByRole("button", { name: /For the grown-up/ })).toBeInTheDocument();
  });

  it("with history: open a question, then switch along the bar to the others", () => {
    renderApp(progress, { "g5-mult2": report });
    openPage();
    // this week's time comes from the saved run; a usual week from the weeks before it that had time
    fireEvent.click(screen.getByRole("button", { name: /^Are they doing the work\? 10 min, this week/ }));
    expect(screen.getByRole("heading", { level: 2, name: "10 minutes this week" })).toBeInTheDocument();
    const bar = within(screen.getByRole("tablist", { name: "Three questions" }));
    expect(bar.getByRole("tab", { name: "Doing the work, 10 min" })).toHaveAttribute("aria-selected", "true");

    // where to help: the most common mistake, wrong beside right, hints, and privacy
    fireEvent.click(bar.getByRole("tab", { name: "Where to help, 1 thing" }));
    expect(screen.getByRole("heading", { level: 2, name: LESSON })).toBeInTheDocument();
    const mistakes = within(screen.getByRole("region", { name: "Mistakes they keep making" }));
    expect(mistakes.getByText("141")).toBeInTheDocument();
    expect(mistakes.getByText("1410")).toBeInTheDocument();
    expect(within(screen.getByRole("region", { name: "Hints and checks" })).getByText("4 hints")).toBeInTheDocument();
    expect(screen.getByText("Everything here stays on this device.")).toBeInTheDocument();

    // is it sticking: scores by chapter in the app's words
    fireEvent.click(bar.getByRole("tab", { name: /^Is it sticking, / }));
    expect(screen.getAllByText("Approaching · 2 of 4").length).toBeGreaterThan(0);
  });
});

describe("one score everywhere", () => {
  // Review 81e53ef: the grown-up page read the practice score while Grades and Done read the skill check
  it("the grown-up page's chapter score is the latest skill check, the same as the Grades tab", () => {
    const check = { last: 3, best: 4, date: t, due: t + 7 * 864e5, passes: 1 };
    renderApp({ ...progress, scores: { "g5-mult2": scored(4, t) }, checks: { "g5-mult2": check } } as Partial<Progress>, { "g5-mult2": report });
    openPage();
    fireEvent.click(screen.getByRole("button", { name: /^Is it sticking\? / }));
    expect(screen.getAllByText("Proficient · 3 of 4").length).toBeGreaterThan(0);
    expect(screen.queryByText("Advanced · 4 of 4")).toBeNull();
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
