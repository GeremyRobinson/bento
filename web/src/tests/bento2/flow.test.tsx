// Bento² through the UI: picker D's Bento² side opens Relativity (it's in B2_TRACKS_LIVE), its track screen starts
// lesson 01, and the loop runs Play → Guess → Name it → Work it (typed on the keypad, with a named slip) → Use it.
// Finishing adds the lesson's ability to the track, and Use it keeps `c` on the Number shelf.
import { afterEach, describe, expect, it, vi } from "vitest";
import { fireEvent, screen, within } from "@testing-library/react";
import { renderApp } from "../ui/helpers";
import { re01 } from "../../bento2/tracks/relativity/lessons";
import { formatAnswer } from "../../bento2/steps";
import { C_KMS } from "../../bento2/tracks/relativity/physics";
// the "coming later" path is tested with one track held back (all ten are open in the app)
vi.mock("../../bento2/flags", async (load) => {
  const real = await load<typeof import("../../bento2/flags")>();
  const live = real.B2_TRACKS_LIVE.filter(id => id !== "ai");
  return { ...real, B2_TRACKS_LIVE: live, isTrackLive: (id: string) => live.includes(id) };
});

const tap = (name: string | RegExp) => fireEvent.click(screen.getByRole("button", { name }));
const pad = () => document.querySelector(".b2pad") as HTMLElement;
function type(text: string) {
  for (const ch of text.replace(/,/g, "")) {
    const name = ch === "−" || ch === "-" ? "Negative" : ch === "." ? "Decimal point" : ch === "/" ? "Fraction bar" : ch;
    fireEvent.click(within(pad()).getByRole("button", { name }));
  }
}

afterEach(() => { vi.restoreAllMocks(); delete document.documentElement.dataset.side; });

describe("Bento² from picker D through a lesson", () => {
  it("opens Relativity, runs lesson 01's loop, and saves its ability and c", () => {
    const gen = vi.spyOn(re01.workIt, "generate");
    renderApp({ grade: null, chosen: false }, {}, "#/learn/no-such-lesson");
    fireEvent.click(screen.getByRole("button", { name: "Bento squared" }));
    fireEvent.click(screen.getByRole("radio", { name: "Relativity" }));
    expect(screen.getAllByText("Open").length).toBeGreaterThan(0);
    tap("Open Relativity ›");

    // the track screen, in the b2 room
    expect(screen.getByRole("heading", { level: 1, name: "Relativity" })).toBeInTheDocument();
    expect(document.documentElement.dataset.side).toBe("b2");
    expect(screen.getAllByRole("button", { name: /Light is the speed everyone agrees on/ }).length).toBeGreaterThan(0);
    expect(document.body.textContent).not.toMatch(/\bscore\b|\bgrade\b|\btest\b/i);
    tap(/^Start: 01/);

    // Play
    expect(screen.getByRole("heading", { level: 1, name: re01.title })).toBeInTheDocument();
    expect(screen.getByRole("tab", { name: "Play" })).toHaveAttribute("aria-selected", "true");
    tap("Guess ›");
    // Guess: no next until you lock in; the guess is kept, never scored
    expect(screen.queryByRole("button", { name: "Name it ›" })).toBeNull();
    fireEvent.click(screen.getByRole("radio", { name: "c" }));
    tap("Lock in my guess");
    expect(screen.getByText(/Both frames read c/)).toBeInTheDocument();
    tap("Name it ›");
    expect(screen.getByLabelText("The formula")).toHaveTextContent("t = d / c");
    tap("Work it ›");

    // Work it: the problem the screen made, typed step by step on the keypad
    const p = gen.mock.results.at(-1)!.value as Parameters<typeof re01.workIt.steps>[0];
    const steps = re01.workIt.steps(p);
    expect(steps).toHaveLength(3);
    // a named slip first: c / d in place of d / c
    type(formatAnswer(C_KMS / p.d, 3));
    tap("Check");
    expect(screen.getByRole("status")).toHaveTextContent("Time is distance over speed: d / c.");
    for (const s of steps) {
      for (let i = 0; i < 16; i++) fireEvent.click(within(pad()).getByRole("button", { name: "Erase" }));
      type(formatAnswer(s.answer[0]!, s.form));
      tap("Check");
    }
    expect(screen.getByText("That's the whole problem.")).toBeInTheDocument();
    expect(pad()).toBeNull();
    tap("Another problem");
    expect(document.querySelector('.b2steps [data-state="now"]')).not.toBeNull();
    tap("Use it ›");

    // Use it: keep c on the shelf, and the lesson's ability shows on the track
    tap("Save");
    expect(screen.getByRole("button", { name: "On your shelf ✓" })).toBeInTheDocument();
    tap("Back to Relativity ›");
    expect(screen.getByLabelText("Your abilities")).toHaveTextContent(`You can ${re01.youCan}`);
    expect(screen.getByLabelText(/The build: 1 of 7 pieces/)).toBeInTheDocument();

    // the island's Tools button opens the tools list; the Number shelf has c
    fireEvent.click(screen.getAllByRole("button", { name: "Tools" })[0]!);
    fireEvent.click(within(screen.getByRole("dialog", { name: "Tools" })).getByRole("button", { name: "Number shelf" }));
    const shelf = screen.getByRole("dialog", { name: "Number shelf" });
    expect(within(shelf).getByText("c")).toBeInTheDocument();
    expect(shelf).toHaveTextContent("299,792,458");
  });

  it("a track that isn't open falls back to the book, and a b2 hash for an open track lands on its screen", () => {
    const { unmount } = renderApp({ grade: 5, chosen: true }, {}, "#/b2/ai");
    expect(screen.queryByRole("heading", { level: 1, name: "Linear algebra" })).toBeNull();
    expect(document.documentElement.dataset.side).toBeUndefined();
    unmount();
    renderApp({ grade: 5, chosen: true }, {}, "#/b2/relativity/b2-re-07");
    expect(screen.getByRole("heading", { level: 1, name: "Adding speeds near light" })).toBeInTheDocument();
    expect(document.documentElement.dataset.side).toBe("b2");
    // back from a lesson is its track
    fireEvent.click(screen.getByRole("button", { name: /^Back to Relativity$/ }));
    expect(screen.getByRole("heading", { level: 1, name: "Relativity" })).toBeInTheDocument();
  });
});
