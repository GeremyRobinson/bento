// Today's review needs at least two scored lessons that exist. While only one lesson may be rebuilt, this file
// registers a twin of g5-mult2 under another id, so the review flow is tested whatever has been ported.
import { fireEvent, screen } from "@testing-library/react";
import { vi } from "vitest";
import type { AnyLesson } from "../../curriculum/schemas/lesson";
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

describe("today's review", () => {
  it("mixes problems from scored lessons, has no practice-again, and shows as done on home", () => {
    renderApp({ grade: 5, chosen: true, done: 2, lessons: { "g5-mult2": 1, "review-twin": 1 },
      scores: { "g5-mult2": scored(1), "review-twin": scored(3) }, seen: { "g5-mult2": t - 3 * day, "review-twin": t - day } });
    const tile = screen.getByRole("button", { name: /Today's review/ });
    expect(tile).toHaveTextContent("5 min");
    fireEvent.click(tile);
    // a mixed run: Quit rather than Lesson, and each problem names its lesson
    expect(screen.getByRole("button", { name: "Quit" })).toBeInTheDocument();
    expect(document.querySelector(".pscreen .plabel")!.textContent).toMatch(/Multiply two-digit numbers|Twin of two-digit multiplying/);
    expect(screen.getByRole("button", { name: "Hint, 4 left" })).toBeInTheDocument();
    expect(solveRun()).toBe(8);
    expect(document.querySelector(".island")).toHaveTextContent("Today's review");
    expect(screen.queryByRole("button", { name: "Practice again" })).toBeNull();
    expect(screen.queryByRole("button", { name: "Take it again" })).toBeNull();
    tap("All lessons");
    const done = screen.getByRole("button", { name: /Today's review: done/ });
    expect(done.querySelector(".score b")!.textContent).toBe("4");
  });
});

// the hint is a light bulb beside Settings (practice-spec §2b): it opens a Settings-style stack, and the bulb carries the count left
describe("hints", () => {
  it("the light bulb gives a hint after a first try and says how many are left", () => {
    renderApp({ grade: 5, chosen: true, done: 2, lessons: { "g5-mult2": 1, "review-twin": 1 },
      scores: { "g5-mult2": scored(1), "review-twin": scored(3) }, seen: { "g5-mult2": t - 3 * day, "review-twin": t - day } });
    fireEvent.click(screen.getByRole("button", { name: /Today's review/ }));
    // wrong tries land on the feedback line under the equation; the bulb's hint opens as its own stack
    const line = () => document.querySelector(".pfb")?.textContent ?? "";
    const stack = () => document.querySelector(".phint")?.textContent ?? "";
    expect(screen.queryByRole("button", { name: /^Hints?$/ })).toBeNull(); // no second hint button under the keypad
    // a wrong first try, then the hint
    fireEvent.keyDown(window, { key: "1" });
    fireEvent.keyDown(window, { key: "Enter" });
    expect(line()).toMatch(/^Look again\./);
    // at a score of 3 the first try may have been the shortcut, which opens the steps; one wrong try on a real step
    if (/needs the steps/.test(line())) { fireEvent.keyDown(window, { key: "1" }); fireEvent.keyDown(window, { key: "Enter" }); }
    fireEvent.click(screen.getByRole("button", { name: "Hint, 4 left" }));
    expect(stack()).toMatch(/^Hint · 3 left/);
    expect(line()).not.toMatch(/Hint/);
    expect(screen.getByRole("button", { name: "Hint, 3 left" })).toBeInTheDocument();
    // reopening shows the same hint and costs nothing
    fireEvent.click(screen.getByRole("button", { name: "Got it" }));
    expect(stack()).toBe("");
    fireEvent.click(screen.getByRole("button", { name: "Hint, 3 left" }));
    expect(stack()).toMatch(/^Hint · 3 left/);
    fireEvent.click(screen.getByRole("button", { name: "Got it" }));
    expect(solveRun()).toBeGreaterThanOrEqual(8);
  });
});
