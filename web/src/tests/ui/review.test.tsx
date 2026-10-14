// Today's review needs at least two scored lessons that exist. While only one lesson may be rebuilt, this file
// registers a twin of g5-mult2 under another id, so the review flow is tested whatever has been ported.
import { fireEvent, screen, within } from "@testing-library/react";
import { vi } from "vitest";
import type { AnyLesson } from "../../curriculum/schemas/lesson";
import { emptyProgress, type Progress } from "../../engine/mastery/progress";
import { canReview, startReview } from "../../engine/session/practice";
import { createRng } from "../../curriculum/generators/rng";
import { renderApp, solveRun, tap } from "./helpers";

vi.mock("../../curriculum/registry", async importOriginal => {
  const real = await importOriginal<typeof import("../../curriculum/registry")>();
  const base = real.lessonById("g5-mult2")!;
  const twin: AnyLesson = { ...base, id: "review-twin", title: "Twin of two-digit multiplying" };
  const LESSONS = [...real.LESSONS, twin];
  const lessonById = (id: string) => (id === twin.id ? twin : real.lessonById(id));
  return {
    ...real, LESSONS, lessonById,
    requireLesson: (id: string) => { const l = lessonById(id); if (!l) throw new Error(`no lesson ${id}`); return l; },
    lessonsInGrade: (g: number) => LESSONS.filter(l => l.grade === g),
  };
});

const day = 864e5, t = Date.UTC(2026, 9, 1, 15);
const scored = (last: 0 | 1 | 2 | 3 | 4) => ({ last, best: last, pct: last / 4, date: t - 3 * day, mastered: false });
const save = (): Partial<Progress> => ({ grade: 5, chosen: true, done: 2, lessons: { "g5-mult2": 1, "review-twin": 1 },
  scores: { "g5-mult2": scored(1), "review-twin": scored(3) }, seen: { "g5-mult2": t - 3 * day, "review-twin": t - day } });

/**
 * v2 home (Today beside the box) has no "Today's review" tile any more, and nothing else in the UI starts one, so the
 * review is opened the way a reload would find it: a review run already in progress, at #/practice. Everything after
 * that is driven through the v2 practice and done screens.
 */
function openReview() {
  const p = { ...emptyProgress(), ...save() } as Progress;
  const now = Date.UTC(2026, 9, 2, 15); // the helpers' clock start
  expect(canReview(p, now)).toBe(true);
  renderApp({ ...p, run: startReview(p, { now, rng: createRng(7) }) }, {}, "#/practice");
}

const say = () => screen.getByRole("status").textContent ?? "";

describe("today's review", () => {
  it("mixes problems from scored lessons, has no practice-again, and shows as done on home", () => {
    openReview();
    // a mixed run: each problem names its lesson over the problem, and the review's 4 hints sit in the tools
    const stage = screen.getByRole("region", { name: "Problem" });
    expect(stage.querySelector(".v-label")!.textContent).toMatch(/^(Multiply two-digit numbers|Twin of two-digit multiplying)$/);
    expect(within(screen.getByRole("toolbar", { name: "Tools" })).getByRole("button", { name: "Hint, 4 left" })).toBeInTheDocument();
    expect(solveRun()).toBe(8);
    // done: the island and the done panel name the review, and a review offers no practice-again or retake
    expect(document.querySelector(".o-island")).toHaveTextContent("Today's review");
    const done = within(screen.getByRole("region", { name: "Done" }));
    expect(done.getByText("Done \u00b7 Today's review")).toBeInTheDocument();
    expect(done.getByLabelText("Score 4 of 4")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Practice again" })).toBeNull();
    expect(screen.queryByRole("button", { name: "Take it again" })).toBeNull();
    // back in the box nothing is left in progress (v2 home has no review tile to mark done; see openReview)
    tap("Back to your box");
    expect(within(screen.getByRole("region", { name: "Today" })).queryByRole("button", { name: "Carry on" })).toBeNull();
  });
});

// v2: the hint is the light bulb in the solve panel's tools, carrying the count left; its hint lands on the say line
describe("hints", () => {
  it("the light bulb gives a hint after a first try and says how many are left", () => {
    openReview();
    const tools = within(screen.getByRole("toolbar", { name: "Tools" }));
    expect(screen.queryByRole("button", { name: /^Hints?$/ })).toBeNull(); // no second hint button under the keypad
    // a wrong first try lands on the say line with its cross
    fireEvent.keyDown(window, { key: "1" });
    fireEvent.keyDown(window, { key: "Enter" });
    expect(say()).toMatch(/^\u2715 Not quite\./);
    // at a score of 3 the first try may have been the shortcut, which opens the steps; one wrong try on a real step
    if (/needs the steps/.test(say())) { fireEvent.keyDown(window, { key: "1" }); fireEvent.keyDown(window, { key: "Enter" }); }
    fireEvent.click(tools.getByRole("button", { name: "Hint, 4 left" }));
    expect(say()).toMatch(/^Hint:/);
    expect(say()).not.toMatch(/Not quite/);
    expect(tools.getByRole("button", { name: "Hint, 3 left" })).toBeInTheDocument();
    // asking again shows the same hint and costs nothing
    const first = say();
    fireEvent.click(tools.getByRole("button", { name: "Hint, 3 left" }));
    expect(say()).toBe(first);
    expect(tools.getByRole("button", { name: "Hint, 3 left" })).toBeInTheDocument();
    expect(solveRun()).toBeGreaterThanOrEqual(8);
  });
});
