// Review's Bento² sweep, as checks over every track: scene names never collide, every scene a lesson names exists, and
// the Guess stage never shows its own answer before the learner guesses.
import { afterEach, describe, expect, it } from "vitest";
import { cleanup, render } from "@testing-library/react";
import { AppProvider } from "../../app/AppState";
import { emptyProgress } from "../../engine/mastery/progress";
import { createRng } from "../../curriculum/generators/rng";
import { B2_TRACKS } from "../../bento2/registry";
import { sceneByName } from "../../bento2/scenes";
import type { AnyB2Lesson } from "../../bento2/model";

const modules = import.meta.glob<{ scenes: Record<string, unknown> }>("../../bento2/tracks/*/scenes.tsx", { eager: true });
const lessons: AnyB2Lesson[] = B2_TRACKS.flatMap(t => t.lessons as AnyB2Lesson[]);
const words = (r: unknown): string => typeof r === "string" ? r : Array.isArray(r) ? r.map(words).join(" ") : r && typeof r === "object" ? Object.values(r).map(words).join(" ") : "";
afterEach(cleanup);

/** a guess picture that shows the answer's figure for another reason, each checked by hand */
const SAME_BY_CHANCE: Record<string, string> = {
  "b2-ai-11": "cat", // the sentence itself: the guess is which of its words "it" attends to
  "b2-de-09": "4.0", // the spring's stiffness k is 4.0; the answer is the friction c
  "b2-in-10": "1.00", // H(X) is 1 bit; the answer is the shared information, which stays hidden
};

/** everything a learner can read or hear in the guess picture, drawn the way the lesson draws it before the guess */
function guessPicture(l: AnyB2Lesson) {
  const S = sceneByName(l.guess.scene)!;
  const { container } = render(
    <AppProvider initial={{ progress: emptyProgress(), reports: {} }} store={null} now={() => Date.UTC(2026, 9, 2)} rng={createRng(1)} onData={() => {}}>
      <S props={{ ...l.guess.props, quiet: true }} place="lesson" />
    </AppProvider>,
  );
  const labels = [...container.querySelectorAll("[aria-label]")].map(e => e.getAttribute("aria-label")).join(" ");
  return `${container.textContent} ${labels}`;
}

describe("Bento² guard", () => {
  it("found every track's lessons and scenes", () => {
    expect(lessons.length).toBeGreaterThan(100);
    expect(Object.keys(modules).length).toBeGreaterThan(5);
  });

  it("no two tracks name a scene the same (one track's picture would replace the other's)", () => {
    const owner = new Map<string, string[]>();
    for (const [file, m] of Object.entries(modules)) for (const name of Object.keys(m.scenes)) owner.set(name, [...(owner.get(name) ?? []), file.split("/").at(-2)!]);
    expect([...owner].filter(([, by]) => by.length > 1).map(([n, by]) => `${n}: ${by.join(", ")}`)).toEqual([]);
  });

  it("every scene a lesson's Play and Guess name has a picture", () => {
    expect(lessons.flatMap(l => [l.play.scene, l.guess.scene].filter(s => !sceneByName(s)).map(s => `${l.id}: ${s}`))).toEqual([]);
  });

  it("the Guess control doesn't start on the answer, and the answer is one of the choices", () => {
    const bad: string[] = [];
    for (const { id, guess: g } of lessons) {
      if (g.kind === "slider" && g.start !== undefined && Math.abs(g.start - g.answer) <= g.near) bad.push(`${id}: the slider starts on the answer`);
      if (g.kind === "point" && Math.hypot(g.start[0] - g.answer[0], g.start[1] - g.answer[1]) <= g.near) bad.push(`${id}: the marker starts on the answer`);
      if (g.kind === "choice" && g.options[g.answer] === undefined) bad.push(`${id}: the answer isn't one of the options`);
    }
    expect(bad).toEqual([]);
  });

  it("the guess picture doesn't show the answer before the guess (the question's own numbers aside)", () => {
    const bad: string[] = [];
    for (const l of lessons) {
      const g = l.guess, ask = words(g.ask);
      const said = g.kind === "choice" ? g.options[g.answer]! : g.kind === "slider" && g.format ? g.format(g.answer) : null;
      if (!said || said.trim().length < 2 || ask.includes(said) || SAME_BY_CHANCE[l.id] === said) continue;
      const pic = guessPicture(l), at = pic.search(new RegExp(`(?<![\\d.,])${said.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}(?![\\d,]|\\.\\d)`));
      if (at >= 0) bad.push(`${l.id}: "${said}" in …${pic.slice(Math.max(0, at - 50), at + 30)}…`);
      cleanup();
    }
    expect(bad).toEqual([]);
  }, 120000);
});
