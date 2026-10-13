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
  const q2 = document.querySelector(".v-ask .q2 .mline");
  const ask = (q2 ? `${q2.getAttribute("data-plain")} = blank` : document.querySelector(".ask .mline")!.getAttribute("data-plain")!).replace(/−/g, "-");
  const m = ask.match(/^(-?\d+) ([×+]) (-?\d+)(?: \+ (-?\d+))? = blank$/);
  if (!m) throw new Error(`can't read step: ${ask}`);
  const nums = [m[1], m[3], m[4]].filter(Boolean).map(Number);
  return String(m[2] === "×" ? nums[0]! * nums[1]! : nums.reduce((a, b) => a + b, 0));
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
    fireEvent.click(screen.getByRole("button", { name: "Show all" }));
    expect(pic.getAttribute("data-split")).toBe("true");
    expect(pic.getAttribute("data-sum")).toBe("true");
    // the whole worked example is written out, and the way on is to watch another or try one
    const side = within(screen.getByRole("region", { name: "Watch one" }));
    expect(side.getAllByText("Add the strips to fill the whole rectangle.").length).toBeGreaterThan(0);
    expect(side.getByRole("button", { name: "Try one" })).toBeInTheDocument();

    // a new example (v2: Watch again) redraws everything from a new problem
    fireEvent.click(screen.getByRole("button", { name: "Watch again" }));
    expect(statementNow()).not.toBe(statement);

    fireEvent.click(screen.getByRole("button", { name: "Show all" }));
    fireEvent.click(screen.getByRole("button", { name: "Try one" }));

    // practice: a wrong answer gets a reason, then solve every step of every problem with the keypad
    const pad = () => document.querySelector(".tray") as HTMLElement;
    fireEvent.click(within(pad()).getByRole("button", { name: "1" }));
    fireEvent.click(screen.getByRole("button", { name: "Check" }));
    expect(screen.getByRole("status")).toHaveTextContent("Look again.");
    act(() => { t += 10000; });
    for (let guard = 0; guard < 60; guard++) {
      const finish = screen.queryByRole("button", { name: /Next problem|Finish lesson/ });
      if (finish) {
        const last = finish.textContent === "Finish lesson";
        fireEvent.click(finish);
        if (last) break;
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

    // results (v2 done screen): one miss on the first step of nine problems (one added after the miss) still scores 4 of 4
    const done = within(screen.getByRole("region", { name: "Done" }));
    expect(done.getByLabelText("Score 4 of 4")).toBeInTheDocument();
    expect(done.getByRole("heading", { level: 2, name: /^4 of 4: / })).toBeInTheDocument();
    expect(screen.getByText(/9 problems in .*including 1 extra added for practice/)).toBeInTheDocument();
    expect(screen.getByText(/Typed/)).toHaveTextContent("Typed 1, answer");

    // back in the box, the lesson's tile shows the score and Today keeps no run in progress
    fireEvent.click(screen.getByRole("button", { name: "Back to your box" }));
    expect(within(screen.getByRole("region", { name: "Today" })).queryByRole("button", { name: "Carry on" })).toBeNull();
    expect(screen.getByRole("button", { name: "Multiply two-digit numbers, Solid, skill check 4 of 4" })).toBeInTheDocument();
  });
});
