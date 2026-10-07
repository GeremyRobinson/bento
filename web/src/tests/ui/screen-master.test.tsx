import { describe, expect, it } from "vitest";
import { fireEvent, screen } from "@testing-library/react";
import { renderApp, solveRun, tap } from "./helpers";

// stylesheets straight from disk (Vitest doesn't load CSS)
const fsName = "node:fs";
const fs = (await import(/* @vite-ignore */ fsName)) as { readFileSync(p: string, enc: "utf8"): string };
const cwd = (globalThis as unknown as { process: { cwd(): string } }).process.cwd();

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

  it("practice sits on Learn's grid master: the hero is the solve tile (equation, feedback line, step bar, picture), then the keypad", () => {
    renderApp({ grade: 3, chosen: true }, {}, "#/learn/g3-split");
    tap("Try one");
    const root = document.querySelector("#app > .screen.fit.lscreen.pscreen")!;
    expect(root).not.toBeNull();
    expect([...root.children].filter(c => !c.matches(".fdim,.fstack")).map(c => c.classList[0])).toEqual(["lintro", "lshero", "ppad"]);
    const hero = root.querySelector(".lshero")!;
    expect([...hero.children].map(c => c.classList[0])).toEqual(["lmath", "pfb", "pbar", "lpic"]);
    // the answer box sits in the equation, and the feedback line is there (empty) before anything is said
    expect(hero.querySelector(".lmath .ask .slot")).not.toBeNull();
    expect(hero.querySelector(".pfb")!.textContent).toBe("");
    expect(root.querySelector(".ppad .tray")).not.toBeNull();
    expect(root.querySelector(".pintro .ptestk")).toBeNull();
    // every mode has a way out
    expect(screen.getAllByRole("button", { name: "Quit" }).length).toBeGreaterThan(0);
  });

  it("a check-up says its rules over the problem, not in a bar of its own, then results sit in a fit screen", () => {
    renderApp();
    tap("Grade check-up");
    const kick = screen.getByText("5th grade check-up: no hints, one try per step");
    expect(kick).toHaveClass("ptestk");
    expect(kick.closest(".screen.pscreen.ptest")).not.toBeNull();
    expect(document.querySelector("#app > .bar")).toBeNull();
    expect(screen.queryByRole("button", { name: /^Hint, / })).toBeNull();
    solveRun();
    expect(document.querySelector("#app > .screen.fit.rscreen .rsum")).not.toBeNull();
    expect(document.querySelector("#app > .screen.fit.rscreen .rreport")).not.toBeNull();
  });

  it("quitting asks first only once answers would be lost", () => {
    renderApp({ grade: 3, chosen: true }, {}, "#/learn/g3-split");
    tap("Try one");
    tap("Quit");
    expect(screen.queryByRole("alertdialog")).toBeNull();
    expect(document.querySelector(".pscreen")).toBeNull();
    renderApp({ grade: 3, chosen: true }, {}, "#/learn/g3-split");
    tap("Try one");
    fireEvent.keyDown(window, { key: "1" });
    fireEvent.keyDown(window, { key: "Enter" });
    tap("Quit");
    expect(screen.getByRole("alertdialog", { name: /^Quit / })).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Keep going" }));
    expect(document.querySelector(".pscreen")).not.toBeNull();
  });

  it("Find my level's answer sits in a fit screen", () => {
    renderApp({ grade: 5, chosen: true });
    fireEvent.click(screen.getByRole("button", { name: /Find my level/ }));
    solveRun();
    expect(document.querySelector("#app > .screen.fit.placed")).not.toBeNull();
  });

  // the master locks the shared edges: the hero and the keypad share one grid column at every size, so the equation,
  // the answer box, the feedback line, the picture and the keys line up on the same left and right edges
  it("the hero and the keypad share one column in every layout", () => {
    const css = fs.readFileSync(`${cwd}/src/styles/screen.css`, "utf8");
    const areas = [...css.matchAll(/\.screen\.fit\.lscreen\.pscreen(?:\.\w+)*\{[^}]*grid-template-areas:([^;}]+)/g)].map(m => m[1]!);
    expect(areas.length).toBeGreaterThanOrEqual(3);
    for (const a of areas) {
      const rows = [...a.matchAll(/"([^"]+)"/g)].map(r => r[1]!.trim().split(/\s+/));
      const col = (name: string) => rows.map(r => r.indexOf(name)).find(i => i >= 0);
      expect(col("hero"), a).toBe(col("pad"));
      if (rows.some(r => r.includes("bar"))) expect(col("bar"), a).toBe(col("pad"));
    }
  });

  // Me and the grown-up page are being rebuilt on their own branches; they move onto FitScreen when those land
  it.todo("Me");
  it.todo("the grown-up page");
});
