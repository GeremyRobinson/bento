// Orbits through the UI (with the track opened for the test; the shipped flag is Development's to flip): lesson 01's
// loop typed on the keypad with a named slip and `g_ISS` saved, every lesson's five stages and Deeper render without an
// error, and every track tool and project picture opens.
import { afterEach, describe, expect, it, vi } from "vitest";
import { fireEvent, screen, within } from "@testing-library/react";
import { renderApp } from "../ui/helpers";
import { or01, ORBITS_LESSONS } from "../../bento2/tracks/orbits/lessons";
import { track } from "../../bento2/tracks/orbits/index";
import { formatAnswer } from "../../bento2/steps";

vi.mock("../../bento2/flags", () => ({ B2_TRACKS_LIVE: ["relativity", "orbit"], isTrackLive: (id: string) => ["relativity", "orbit"].includes(id) }));

const tap = (name: string | RegExp) => fireEvent.click(screen.getByRole("button", { name }));
const pad = () => document.querySelector(".b2pad") as HTMLElement;
function type(text: string) {
  for (const ch of text.replace(/,/g, "")) {
    const name = ch === "−" || ch === "-" ? "Negative" : ch === "." ? "Decimal point" : ch === "/" ? "Fraction bar" : ch;
    fireEvent.click(within(pad()).getByRole("button", { name }));
  }
}

afterEach(() => { vi.restoreAllMocks(); delete document.documentElement.dataset.side; });

describe("Orbits in the app", () => {
  it("runs lesson 01's loop and keeps g_ISS", () => {
    const gen = vi.spyOn(or01.workIt, "generate");
    renderApp({ grade: 5, chosen: true }, {}, "#/b2/orbit/b2-or-01");
    expect(screen.getByRole("heading", { level: 1, name: or01.title })).toBeInTheDocument();
    tap("Guess ›");
    fireEvent.click(screen.getByRole("radio", { name: "1/4" }));
    tap("Lock in my guess");
    expect(screen.getByText(/A quarter/)).toBeInTheDocument();
    tap("Name it ›");
    expect(screen.getByLabelText("The formula")).toHaveTextContent("g(r) = GM / r²");
    tap("Work it ›");
    const p = gen.mock.results.at(-1)!.value as Parameters<typeof or01.workIt.steps>[0];
    expect(p.kind).toBe(0);
    const steps = or01.workIt.steps(p);
    if (p.kind === 0) {
      // a named slip first: 1/k for 1/k²
      type(`1/${p.k}`);
      tap("Check");
      expect(screen.getByRole("status")).toHaveTextContent("Gravity falls with the square of the distance");
    }
    for (const s of steps) {
      for (let i = 0; i < 16; i++) fireEvent.click(within(pad()).getByRole("button", { name: "Erase" }));
      type(formatAnswer(s.answer[0]!, s.form));
      tap("Check");
    }
    expect(screen.getByText("That's the whole problem.")).toBeInTheDocument();
    tap("Use it ›");
    tap("Save");
    expect(screen.getByRole("button", { name: "On your shelf ✓" })).toBeInTheDocument();
    tap("Back to Orbits and spaceflight ›");
    expect(screen.getByLabelText("Your abilities")).toHaveTextContent(`You can ${or01.youCan}`);
    expect(document.body.textContent).not.toMatch(/\bscore\b|\bgrade\b|\btest\b/i);
  });

  it("every lesson's stages render", () => {
    const errors = vi.spyOn(console, "error");
    for (const l of ORBITS_LESSONS) {
      const { unmount } = renderApp({ grade: 5, chosen: true }, {}, `#/b2/orbit/${l.id}`);
      expect(screen.getByRole("heading", { level: 1, name: l.title })).toBeInTheDocument();
      fireEvent.click(screen.getByRole("tab", { name: "Guess" }));
      const radios = screen.queryAllByRole("radio");
      if (radios.length) fireEvent.click(radios[0]!);
      tap("Lock in my guess");
      fireEvent.click(screen.getByRole("tab", { name: "Name it" }));
      fireEvent.click(screen.getByRole("tab", { name: "Work it" }));
      expect(document.querySelector(".b2steps")).not.toBeNull();
      fireEvent.click(screen.getByRole("tab", { name: "Use it" }));
      fireEvent.click(screen.getByRole("button", { name: "Deeper" }));
      unmount();
    }
    expect(errors).not.toHaveBeenCalled();
  });

  it("the track screen, its projects and its tools open", () => {
    const errors = vi.spyOn(console, "error");
    for (const p of track.projects) {
      const { unmount } = renderApp({ grade: 5, chosen: true }, {}, `#/b2/orbit/pick/${p.id}`);
      expect(screen.getAllByText(p.name).length).toBeGreaterThan(0);
      unmount();
    }
    renderApp({ grade: 5, chosen: true }, {}, "#/b2/orbit");
    expect(screen.getByRole("heading", { level: 1, name: "Orbits and spaceflight" })).toBeInTheDocument();
    for (const t of track.tools) {
      fireEvent.click(screen.getAllByRole("button", { name: "Tools" })[0]!);
      fireEvent.click(within(screen.getByRole("dialog", { name: "Tools" })).getByRole("button", { name: new RegExp(t.name) }));
      expect(screen.getByRole("dialog", { name: t.name })).toBeInTheDocument();
      fireEvent.keyDown(window, { key: "Escape" });
    }
    expect(errors).not.toHaveBeenCalled();
  });
});
