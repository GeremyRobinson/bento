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

/** every way the picture might write the answer: the guess's own format, then plain figures */
function answerAs(g: AnyB2Lesson["guess"]): string[] {
  const figs = (x: number) => [...new Set([String(+x.toFixed(4)), x.toFixed(1), x.toFixed(2)].map(f => f.replace("-", "−")).concat(String(+x.toFixed(4))))];
  if (g.kind === "choice") return [g.options[g.answer]!];
  if (g.kind === "slider") return g.format ? [g.format(g.answer), ...(Number.isInteger(g.answer) ? [] : figs(g.answer))] : Number.isInteger(g.answer) ? [String(g.answer)] : figs(g.answer);
  const [x, y] = g.answer, f = (v: number) => String(+v.toFixed(2)).replace("-", "−");
  return [`(${f(x)}, ${f(y)})`, `(${String(x)}, ${String(y)})`, `(${x.toFixed(1)}, ${y.toFixed(1)})`];
}

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

  it("every scene a lesson, project or tool names has a picture", () => {
    const missing: string[] = [];
    for (const t of B2_TRACKS) {
      for (const l of t.lessons as AnyB2Lesson[]) for (const s of [l.play.scene, l.guess.scene, l.useIt.scene?.scene]) if (s && !sceneByName(s)) missing.push(`${l.id}: ${s}`);
      for (const p of t.projects ?? []) if (!sceneByName(p.scene.scene)) missing.push(`${t.code} project: ${p.scene.scene}`);
      for (const tool of t.tools ?? []) if (!sceneByName(tool.id)) missing.push(`${t.code} tool: ${tool.id}`);
    }
    expect(missing).toEqual([]);
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
    const bad: string[] = [], skipped: string[] = [];
    for (const l of lessons) {
      const g = l.guess, ask = words(g.ask);
      const said = answerAs(g).filter(a => a.trim().length >= 2 && !ask.includes(a) && SAME_BY_CHANCE[l.id] !== a);
      if (!said.length) { skipped.push(l.id); continue; }
      const pic = guessPicture(l);
      for (const a of said) {
        const at = pic.search(new RegExp(`(?<![\\d.,])${a.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}(?![\\d,]|\\.\\d)`));
        if (at >= 0) { bad.push(`${l.id}: "${a}" in …${pic.slice(Math.max(0, at - 50), at + 30)}…`); break; }
      }
      cleanup();
    }
    expect(bad).toEqual([]);
    // unchecked: one-character answers (a digit, a letter: they'd match nearly any picture) and answers the question
    // itself states; 18 of 154 today, and the count only grows if a new guess is one of those
    expect(skipped.length).toBeLessThanOrEqual(18);
  }, 120000);
});
