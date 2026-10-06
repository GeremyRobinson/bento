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
  const ask = document.querySelector(".ask .mline")!.getAttribute("data-plain")!.replace(/−/g, "-");
  const m = ask.match(/^(-?\d+) ([×+]) (-?\d+)(?: \+ (-?\d+))? = blank$/);
  if (!m) throw new Error(`can't read step: ${ask}`);
  const nums = [m[1], m[3], m[4]].filter(Boolean).map(Number);
  return String(m[2] === "×" ? nums[0]! * nums[1]! : nums.reduce((a, b) => a + b, 0));
}

describe("a whole lesson in the browser", () => {
  it("learns, practices and finishes with a saved score", () => {
    renderApp();
    // home: up next is the rebuilt lesson
    fireEvent.click(screen.getByRole("button", { name: /Up next.*Multiply two-digit numbers/ }));

    // learn: a freshly generated problem (the owner's choice: every picture is random), its picture, and narration
    // from the same model. The statement, the picture and the narration must all describe the same numbers.
    const statement = document.querySelector(".lmath .mline")!.getAttribute("data-plain")!;
    const sm = statement.match(/^(\d+) × (\d+) = \1 × \((\d+) \+ (\d+)\)$/);
    expect(sm, statement).not.toBeNull();
    const [a, b, tens, ones] = sm!.slice(1).map(Number) as [number, number, number, number];
    expect(tens + ones).toBe(b);
    const pic = screen.getByRole("img");
    expect(pic.getAttribute("aria-label")).toBe(`${a} by ${b} rectangle, split into ${a} by ${tens} = ${a * tens} and ${a} by ${ones} = ${a * ones}. Total ${a * b}.`);
    // before Play the picture rests on its first frame, so Play only ever builds forward (G 2026-10-06)
    expect(pic.getAttribute("data-split")).toBe("false");
    fireEvent.click(screen.getByRole("button", { name: "Show all" }));
    expect(pic.getAttribute("data-split")).toBe("true");
    expect(pic.getAttribute("data-sum")).toBe("true");
    expect(screen.getByText("That's the whole problem. Your turn.")).toBeInTheDocument();
    expect(screen.getAllByText(`Add the parts to fill the whole rectangle: ${a * b}.`).length).toBeGreaterThan(0);

    // a new example redraws everything from a new problem
    fireEvent.click(screen.getByRole("button", { name: "Show another" }));
    expect(document.querySelector(".lmath .mline")!.getAttribute("data-plain")).not.toBe(statement);

    fireEvent.click(screen.getByRole("button", { name: "Show all" }));
    fireEvent.click(screen.getByRole("button", { name: "Your turn ›" }));

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

    // results: one miss on the first step of nine problems (one added after the miss)
    expect(screen.getByRole("heading", { level: 2, name: "Advanced" })).toBeInTheDocument();
    expect(screen.getByText(/9 problems in .*including 1 extra added for practice/)).toBeInTheDocument();
    expect(screen.getByText(/Typed/)).toHaveTextContent("Typed 1, answer");

    // home now shows the score and keeps no run in progress
    fireEvent.click(screen.getByRole("button", { name: "All lessons" }));
    expect(screen.queryByText(/Keep going/)).toBeNull();
    expect(document.querySelector(".srow.sles .score b")!.textContent).toBe("4");
  });
});
