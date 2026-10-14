// End to end through the UI: home → learn (the generated picture and narration) → practice every problem → results.
import { act, fireEvent, render, screen, within } from "@testing-library/react";
import { App } from "../../app/App";
import { AppProvider } from "../../app/AppState";
import { createRng } from "../../curriculum/generators/rng";
import { emptyProgress } from "../../engine/mastery/progress";

let t = Date.UTC(2026, 9, 2, 15);
const now = () => (t += 3000);

function renderApp() {
  history.replaceState(null, "", "#/");
  const progress = { ...emptyProgress(), grade: 5, chosen: true };
  return render(<AppProvider initial={{ progress, reports: {} }} store={null} now={now} rng={createRng(42)}><App /></AppProvider>);
}

/** Works out the answer from the step on screen, like a student would. */
function answerOnScreen(): string {
  const q2 = document.querySelector(".v-ask .q2 .mline"), whole = document.querySelector(".v-ask .q2")?.textContent?.match(/^What is (.*)\?$/);
  // the skill check asks a word problem in its own words ("How many seats are there?", R-W1)
  const story = !q2 && !whole && !!document.querySelector(".v-ask .q2");
  let ask = (q2 ? `${q2.getAttribute("data-plain")} = blank` : whole ? `${whole[1]} = blank` : story ? "blank" : document.querySelector(".ask .mline")!.getAttribute("data-plain")!).replace(/−/g, "-");
  // its two numbers are in the story on the stage
  if (ask === "blank") ask = `${(document.querySelector(".v-stage .story")!.textContent!.match(/\d+/g) ?? []).slice(0, 2).join(" × ")} = blank`;
  // a × b, or a sum of any number of parts
  const m = ask.match(/^(-?\d+) × (-?\d+) = blank$/) ?? ask.match(/^(-?\d+(?: \+ -?\d+)+) = blank$/);
  if (!m) throw new Error(`can't read step: ${ask}`);
  return String(m.length === 3 ? Number(m[1]) * Number(m[2]) : m[1]!.split(" + ").map(Number).reduce((a, b) => a + b, 0));
}

describe("a whole lesson in the browser", () => {
  it("learns, practices and finishes with a saved score", () => {
    renderApp();
    // home (v2): Today suggests the rebuilt lesson as the one to do now, and Start opens it
    const today = within(screen.getByRole("region", { name: "Today" }));
    expect(today.getByRole("heading", { level: 2, name: "Multiply two-digit numbers" })).toBeInTheDocument();
    fireEvent.click(today.getByRole("button", { name: "Start" }));

    // learn (v2 "Watch one"): a freshly generated problem (the owner's choice: every picture is random), its picture, and
    // narration from the same model. The statement, the picture and the narration must all describe the same numbers.
    const stage = () => within(screen.getByRole("region", { name: "Problem" }));
    const statementNow = () => document.querySelector(".v-stage .v-prob .math .mline")!.getAttribute("data-plain")!;
    const statement = statementNow();
    // the stage shows the problem alone, like practice (v2 spec P2, P3); its split is in the first worked line
    const sm = statement.match(/^(\d+) × (\d+)$/);
    expect(sm, statement).not.toBeNull();
    const [a, b] = sm!.slice(1).map(Number) as [number, number];
    const tens = b - (b % 10), ones = b % 10;
    const pic = stage().getByRole("img");
    expect(pic.getAttribute("aria-label")).toBe(`${a} by ${b} rectangle, split into ${a} by ${tens} = ${a * tens} and ${a} by ${ones} = ${a * ones}. Total ${a * b}.`);
    // it opens on the picture's first frame and only ever builds forward from there (G 2026-10-06)
    expect(pic.getAttribute("data-split")).toBe("false");
    // every worked line is there from the start, the ones to come faint (v2 spec L3); the buttons are the model's two
    const lines = document.querySelectorAll(".v-wl li");
    expect(lines.length).toBeGreaterThan(1);
    expect(document.querySelectorAll(".v-wl li.later").length).toBe(lines.length - document.querySelectorAll(".v-wl li:not(.later)").length);
    expect(screen.queryByRole("button", { name: "Show all" })).toBeNull();
    // the arrow key steps through to the end
    for (let k = 0; k < 10; k++) fireEvent.keyDown(window, { key: "ArrowRight" });
    expect(document.querySelectorAll(".v-wl li.later").length).toBe(0);
    expect(pic.getAttribute("data-split")).toBe("true");
    expect(pic.getAttribute("data-sum")).toBe("true");
    // the whole worked example is written out, and the way on is to watch another or try one
    const side = within(screen.getByRole("region", { name: "Watch one" }));
    expect(side.getAllByText("add the two strips").length).toBeGreaterThan(0);
    expect(side.getByRole("button", { name: "Try one" })).toBeInTheDocument();

    // a new example (v2: Watch again) redraws everything from a new problem
    fireEvent.click(screen.getByRole("button", { name: "Watch again" }));
    expect(statementNow()).not.toBe(statement);

    fireEvent.click(screen.getByRole("button", { name: "Try one" }));

    // practice: a wrong answer gets a reason, then solve every step of every problem with the keypad
    const pad = () => document.querySelector(".tray") as HTMLElement;
    fireEvent.click(within(pad()).getByRole("button", { name: "1" }));
    fireEvent.click(screen.getByRole("button", { name: "Check" }));
    expect(screen.getByRole("status")).toHaveTextContent("Not quite.");
    act(() => { t += 10000; });
    let checked = false;
    for (let guard = 0; guard < 80; guard++) {
      const finish = screen.queryByRole("button", { name: /Next problem|Start the skill check|See how you did/ });
      if (finish) {
        const label = finish.textContent;
        fireEvent.click(finish);
        if (label === "See how you did") break;
        // then the skill check: 4 problems on your own, each asked whole, no hints and no problem list (v2 model)
        if (label === "Start the skill check") {
          checked = true;
          expect(document.querySelector(".o-island")).toHaveTextContent("Skill check · 1 of 4");
          expect(document.querySelector(".v-steps")).toHaveTextContent("Skill check");
          expect(screen.getByRole("status")).toHaveTextContent("Skill check: 4 problems on your own, no hints. It shows what you remember.");
          expect(screen.queryByRole("button", { name: /^Hint/ })).toBeNull();
          expect(screen.queryByRole("button", { name: "Problems" })).toBeNull();
        }
        continue;
      }
      // a word problem starts with "which operation?": the story is equal groups, so multiply
      const multiply = screen.queryByRole("button", { name: "× Multiply" });
      if (multiply) { fireEvent.click(multiply); continue; }
      fireEvent.click(within(pad()).getByRole("button", { name: "Erase" }));
      fireEvent.click(within(pad()).getByRole("button", { name: "Erase" }));
      for (const d of answerOnScreen()) fireEvent.click(within(pad()).getByRole("button", { name: d }));
      fireEvent.click(screen.getByRole("button", { name: "Check" }));
    }

    // done (v2 model): the skill check scores the lesson, 4 of 4 on your own, problem by problem, and the slip from practice
    expect(checked).toBe(true);
    const done = within(screen.getByRole("region", { name: "Done" }));
    expect(done.getByLabelText("Score 4 of 4")).toBeInTheDocument();
    expect(done.getByRole("heading", { level: 2, name: "4 of 4 on your own: you\u2019ve got it." })).toBeInTheDocument();
    expect(done.getByText(/^You finished the lesson\. The skill check shows what you remember\./)).toBeInTheDocument();
    expect(done.getByText("Your skill check")).toBeInTheDocument();
    expect(done.getAllByText("Right")).toHaveLength(4);
    expect(done.getByText("Watch for:")).toBeInTheDocument();
    // in the child's words, what practice said to look at, never the grown-up's category (v2 model)
    expect(done.getByText("Watch for:").parentElement!.textContent).toMatch(/^Watch for: Look again at the lit-up strip: it's \d+ wide and \d+ tall\.$/);
    expect(done.queryByRole("button", { name: "Practice again" })).toBeNull();
    expect(done.queryByRole("heading", { name: "What you did" })).toBeNull();

    // back in the box, the lesson's tile shows the score and Today keeps no run in progress
    fireEvent.click(screen.getByRole("button", { name: "Back to your box" }));
    expect(within(screen.getByRole("region", { name: "Today" })).queryByRole("button", { name: "Keep going" })).toBeNull();
    expect(screen.getByRole("button", { name: "Multiply two-digit numbers, Got it, skill check 4 of 4" })).toBeInTheDocument();
  }, 60000);
});
