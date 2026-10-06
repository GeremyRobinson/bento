// Shared helpers for the UI flow tests: start the app on a given save, and solve whatever is on screen like a student.
import { act, fireEvent, render, screen, within } from "@testing-library/react";
import { App } from "../../app/App";
import { AppProvider, type AppData } from "../../app/AppState";
import { currentStep } from "../../engine/session/practice";
import { expectedValues } from "../../engine/evaluation/steps";
import { formatNumber } from "../../curriculum/schemas/math-text";
import { createRng } from "../../curriculum/generators/rng";
import { emptyProgress, type Progress } from "../../engine/mastery/progress";
import type { SessionReport } from "../../engine/session/types";

export const clock = { t: Date.UTC(2026, 9, 2, 15) };
/** the app's data after the latest change, so a test can answer whatever lesson is on screen */
let latest: AppData | null = null;
const onData = (d: AppData) => { latest = d; };
const now = () => (clock.t += 3000);

export function renderApp(progress: Partial<Progress> = { grade: 5, chosen: true }, reports: Record<string, SessionReport> = {}, hash = "#/") {
  history.replaceState(null, "", hash);
  clock.t = Date.UTC(2026, 9, 2, 15);
  return render(
    <AppProvider initial={{ progress: { ...emptyProgress(), ...progress }, reports }} store={null} now={now} rng={createRng(42)} onData={onData}>
      <App />
    </AppProvider>,
  );
}

const pad = () => document.querySelector(".tray") as HTMLElement;
const tap = (name: string | RegExp) => fireEvent.click(screen.getByRole("button", { name }));

/** Works out the answer from the step on screen (a × b, or a sum), like the existing lesson-flow test. */
export function answerOnScreen(): string {
  let ask = document.querySelector(".ask .mline")!.getAttribute("data-plain")!.replace(/−/g, "-");
  // "Final answer only": the answer to the whole problem shown above the step
  if (ask === "blank") ask = `${document.querySelector(".pprob .math .mline")!.getAttribute("data-plain")} = blank`;
  const m = ask.match(/^(-?\d+) ([×+]) (-?\d+)(?: \+ (-?\d+))? = blank$/);
  if (!m) throw new Error(`can't read step: ${ask}`);
  const nums = [m[1], m[3], m[4]].filter(Boolean).map(Number);
  return String(m[2] === "×" ? nums[0]! * nums[1]! : nums.reduce((a, b) => a + b, 0));
}

/** Answers the step on screen correctly, whatever the lesson: taps the right choice, or types each box's answer. */
export function answerCurrentStep(): void {
  const run = latest?.progress.run;
  if (!run) throw new Error("no run in progress");
  if (run.pick) { tap(run.pick.right); return; }
  const step = currentStep(run)!, want = expectedValues(step);
  if (step.choices) { tap(step.choices[want.c!]!); return; }
  for (const [id, v] of Object.entries(want)) {
    fireEvent.click(document.querySelector(`.ask [data-slot="${id}"]`)!);
    for (let i = 0; i < 12; i++) fireEvent.click(within(pad()).getByRole("button", { name: "Erase" }));
    for (const ch of formatNumber(v)) {
      const name = ch === "−" || ch === "-" ? "Negative" : ch === "." ? "Decimal point" : ch;
      fireEvent.click(within(pad()).getByRole("button", { name }));
    }
  }
  tap("Check");
}

/** Answers the step on screen wrongly, whatever the lesson: another choice, or the first box off by one. */
export function answerWrong(): void {
  const run = latest?.progress.run;
  if (!run) throw new Error("no run in progress");
  if (run.pick) { tap(run.pick.options.find(o => o !== run.pick!.right)!); return; }
  const step = currentStep(run)!, want = expectedValues(step);
  if (step.choices) { tap(step.choices.find((_, i) => i !== want.c)!); return; }
  const [id, v] = Object.entries(want)[0]!;
  fireEvent.click(document.querySelector(`.ask [data-slot="${id}"]`)!);
  for (let i = 0; i < 12; i++) fireEvent.click(within(pad()).getByRole("button", { name: "Erase" }));
  for (const ch of formatNumber(v + 1)) fireEvent.click(within(pad()).getByRole("button", { name: ch === "−" ? "Negative" : ch === "." ? "Decimal point" : ch }));
  tap("Check");
}

const FINISH = /^(Next problem|Finish lesson|Finish test|Finish review)$/;

/** Solves every problem of the run on screen and presses the finish button. Returns how many problems were solved. */
export function solveRun(): number {
  let solved = 0;
  for (let guard = 0; guard < 400; guard++) {
    const next = screen.queryByRole("button", { name: FINISH });
    if (next) {
      const last = next.textContent !== "Next problem";
      solved++;
      fireEvent.click(next);
      if (last) return solved;
      continue;
    }
    answerCurrentStep();
  }
  throw new Error("the run never finished");
}

/** Gets every step wrong until "Show me" opens, then uses it: the lowest possible score. */
export function failRun(): void {
  for (let guard = 0; guard < 800; guard++) {
    const next = screen.queryByRole("button", { name: FINISH });
    if (next) {
      const last = next.textContent !== "Next problem";
      fireEvent.click(next);
      if (last) return;
      continue;
    }
    // Show me lives in the hint stack, which the light bulb opens (practice-spec §2b)
    if (document.querySelector(".pfb")?.textContent?.includes("Show me")) {
      const bulb = screen.queryByRole("button", { name: /^Hint, / });
      if (bulb) fireEvent.click(bulb);
      const show = screen.queryByRole("button", { name: "Show me the step" });
      if (show) { fireEvent.click(show); continue; }
      const got = screen.queryByRole("button", { name: "Got it" });
      if (got) fireEvent.click(got);
    }
    answerWrong();
    act(() => { clock.t += 10000; });
  }
  throw new Error("the run never finished");
}

export { tap };
