import { describe, expect, it } from "vitest";
import { fireEvent, screen, within } from "@testing-library/react";
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

  // v2 (G 2026-10-13): practice is the one workspace, a stage beside the solve panel, still inside the Screen master
  it("practice sits in the v2 workspace: the stage (problem, picture), then the solve panel (step bar, ask line, say line, tools, keypad)", () => {
    renderApp({ grade: 3, chosen: true }, {}, "#/learn/g3-split");
    tap("Try one");
    const root = document.querySelector("#app > .screen.v-work.v-prac")!;
    expect(root).not.toBeNull();
    expect([...root.children].map(c => c.classList[0])).toEqual(["v-panel", "v-panel"]);
    const [stage, solve] = [...root.children];
    expect(stage).toHaveClass("v-stage");
    expect(stage!.querySelector(".v-prob.pprob")).not.toBeNull();
    expect(solve).toHaveClass("v-solve");
    // nothing worked out yet, so no done lines: the step bar, the ask line, the say line, the tools, then the keys
    expect([...solve!.children].map(c => c.classList[0])).toEqual(["v-steps", "v-ask", "v-say", "v-tools", "ppad"]);
    // the answer box sits in the ask line, and the say line is there (empty) before anything is said
    expect(solve!.querySelector(".v-ask .ask .slot")).not.toBeNull();
    expect(solve!.querySelector(".v-say")!.textContent).toBe("");
    expect(solve!.querySelector(".ppad .tray")).not.toBeNull();
    expect(solve!.querySelector(".v-steps .v-meta")).toBeNull(); // the test rules only show in a test
    // every mode has a way out: the island's step back
    expect(screen.getByRole("button", { name: /^Back to / })).toBeInTheDocument();
  });

  it("a check-up says its rules over the problem, not in a bar of its own, then results sit in the Screen master", () => {
    renderApp();
    // v2: the box's Test view holds the grade's test
    fireEvent.click(within(screen.getByRole("group", { name: "5th grade views" })).getByRole("button", { name: "Test" }));
    fireEvent.click(screen.getByRole("button", { name: "5th grade test, not taken yet" }));
    const kick = screen.getByText(/: no hints, one try per step$/);
    expect(kick).toHaveClass("v-meta");
    expect(kick.closest(".v-steps")).not.toBeNull();
    expect(kick.closest("#app > .screen.v-prac.test")).not.toBeNull();
    expect(document.querySelector("#app > .bar")).toBeNull();
    expect(screen.queryByRole("button", { name: /^Hint, / })).toBeNull();
    solveRun();
    expect(document.querySelector("#app > .screen.v-done .v-result")).not.toBeNull();
    expect(document.querySelector("#app > .screen.v-done .v-recap")).not.toBeNull();
  });

  // v2 dropped the quit question on purpose: leaving a run never loses it, so there is nothing to confirm
  it("leaving a run keeps it: Today offers to carry on where it was left", () => {
    // the lesson Today suggests, so Today is where it waits (home with no pick shows the suggested lesson)
    renderApp({ grade: 5, chosen: true });
    fireEvent.click(within(screen.getByRole("region", { name: "Today" })).getByRole("button", { name: "Start" }));
    tap("Try one");
    fireEvent.keyDown(window, { key: "1" });
    fireEvent.keyDown(window, { key: "Enter" });
    const problem = document.querySelector(".v-stage .v-prob")!.textContent;
    tap(/^Back to /);
    expect(screen.queryByRole("alertdialog")).toBeNull();
    expect(document.querySelector(".v-prac")).toBeNull();
    const today = within(screen.getByRole("region", { name: "Today" }));
    expect(today.getByText("In progress")).toBeInTheDocument();
    expect(today.getByText(/^Problem 1 of \d+$/)).toBeInTheDocument();
    fireEvent.click(today.getByRole("button", { name: "Carry on" }));
    expect(document.querySelector("#app > .screen.v-prac")).not.toBeNull();
    expect(document.querySelector(".v-stage .v-prob")!.textContent).toBe(problem);
  });

  it("Find my level's answer sits in a fit screen", () => {
    renderApp({ grade: 5, chosen: true });
    // v2: Find my level is a row on the My Obento page
    fireEvent.click(screen.getByRole("button", { name: /^My Obento:/ }));
    fireEvent.click(screen.getByRole("button", { name: /Find my level/ }));
    solveRun();
    expect(document.querySelector("#app > .screen.fit.placed")).not.toBeNull();
  });

  // the master locks the shared edges: the keys always sit straight under the picture, so on a phone the hero, the
  // picture and the keys share one column, and on a wide screen the picture and the keys share the column beside the
  // solve panel (G 20:08 "whats all this empty space on the left?")
  it("the keypad shares the picture's column in every layout", () => {
    const css = fs.readFileSync(`${cwd}/src/styles/screen.css`, "utf8");
    const areas = [...css.matchAll(/\.screen\.fit\.lscreen\.pscreen(?:\.\w+)*\{[^}]*grid-template-areas:([^;}]+)/g)].map(m => m[1]!);
    expect(areas.length).toBeGreaterThanOrEqual(3);
    for (const a of areas) {
      const rows = [...a.matchAll(/"([^"]+)"/g)].map(r => r[1]!.trim().split(/\s+/));
      const col = (name: string) => rows.map(r => r.indexOf(name)).find(i => i >= 0);
      expect(col("pad"), a).toBeDefined();
      if (rows.some(r => r.includes("pic"))) expect(col("pic"), a).toBe(col("pad"));
    }
  });

  // Me and the grown-up page are being rebuilt on their own branches; they move onto FitScreen when those land
  it.todo("Me");
  it.todo("the grown-up page");
});
