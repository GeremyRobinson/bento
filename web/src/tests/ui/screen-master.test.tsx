import { describe, expect, it } from "vitest";
import { fireEvent, screen } from "@testing-library/react";
import { renderApp, solveRun, tap } from "./helpers";

/**
 * Every screen sits in the Screen master (components/screen/Screen.tsx), so the frame, the fit and the motion are set
 * in one place and a per-screen layout bug can't happen (G 2026-10-06: "isnt this all being fixed in the master?").
 * Only the landing page is its own thing.
 */
const root = () => document.querySelector("#app > .screen");

describe("every screen renders inside the Screen master", () => {
  it.each([
    ["the grade question", { grade: null as unknown as number, chosen: true }, "#/"],
    ["a grade's book", { grade: 5, chosen: true }, "#/"],
    ["a lesson", { grade: 3, chosen: true }, "#/learn/g3-split"],
    ["facts", { grade: 3, chosen: true }, "#/facts"],
    ["one facts table", { grade: 3, chosen: true }, "#/facts/times"],
    ["a saved report that isn't here", { grade: 5, chosen: true }, "#/report/nothing"],
    ["results with nothing finished", { grade: 5, chosen: true }, "#/results"],
    ["practice with nothing started", { grade: 5, chosen: true }, "#/practice"],
  ])("%s", (_name, progress, hash) => {
    renderApp(progress, {}, hash);
    expect(root()).not.toBeNull();
  });

  it("a fact sprint is a work screen: the question beside its keys", () => {
    renderApp({ grade: 3, chosen: true }, {}, "#/facts/times/go");
    expect(document.querySelector("#app > .screen.solve .wprob .fq")).not.toBeNull();
    expect(document.querySelector("#app > .screen.solve .wpad .tray")).not.toBeNull();
  });

  it("practice is a work screen, and a lesson's run is too", () => {
    renderApp({ grade: 3, chosen: true }, {}, "#/learn/g3-split");
    tap("Try one");
    expect(document.querySelector("#app > .screen.solve .wprob .card.wq")).not.toBeNull();
    expect(document.querySelector("#app > .screen.solve .wpad .tray")).not.toBeNull();
    expect(document.querySelector("#app > .screen.solve .wkick")).toBeNull();
  });

  it("a check-up says its rules in the work screen's kicker, not a bar of its own, then results sit in a fit screen", () => {
    renderApp();
    tap("Grade check-up");
    const kick = screen.getByText("5th grade check-up: no hints, one try per step");
    expect(kick).toHaveClass("wkick");
    expect(kick.closest(".screen.solve")).not.toBeNull();
    expect(document.querySelector("#app > .bar")).toBeNull();
    solveRun();
    expect(document.querySelector("#app > .screen.fit.rscreen .rsum")).not.toBeNull();
    expect(document.querySelector("#app > .screen.fit.rscreen .rreport")).not.toBeNull();
  });

  it("Find my level's answer sits in a fit screen", () => {
    renderApp({ grade: 5, chosen: true });
    fireEvent.click(screen.getByRole("button", { name: /Find my level/ }));
    solveRun();
    expect(document.querySelector("#app > .screen.fit.placed")).not.toBeNull();
  });

  // Me and the grown-up page are being rebuilt on their own branches; they move onto FitScreen when those land
  it.todo("Me");
  it.todo("the grown-up page");
});
