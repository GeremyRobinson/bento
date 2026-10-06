// Every AI picture renders, on every stage that names it (Play, Guess, the reveal, a Work it problem, Use it), in the
// tools panel and in each project, with a described SVG and no undefined or NaN in what it shows.
import { afterEach, describe, expect, it } from "vitest";
import { cleanup, render } from "@testing-library/react";
import { AppProvider } from "../../app/AppState";
import { emptyProgress } from "../../engine/mastery/progress";
import { createRng } from "../../curriculum/generators/rng";
import { sceneByName, type SceneValues } from "../../bento2/scenes";
import { trackByCode } from "../../bento2/registry";
import type { AnyB2Lesson } from "../../bento2/model";
import { scenes } from "../../bento2/tracks/ai/scenes";

const track = trackByCode("ai")!;
afterEach(cleanup);

function show(name: string, props: SceneValues, place: "lesson" | "tool" | "project", marker?: [number, number]) {
  const S = sceneByName(name)!;
  expect(S, name).toBeTruthy();
  const { container } = render(
    <AppProvider initial={{ progress: emptyProgress(), reports: {} }} store={null} now={() => Date.UTC(2026, 9, 2)} rng={createRng(1)} onData={() => {}}>
      <S props={props} place={place} marker={marker} onMarker={() => {}} />
    </AppProvider>,
  );
  const svg = container.querySelector("svg");
  expect(svg, name).toBeTruthy();
  expect(svg!.getAttribute("aria-label") ?? "", name).not.toBe("");
  expect(container.textContent + (svg!.getAttribute("aria-label") ?? ""), `${name} ${JSON.stringify(props)}`).not.toMatch(/undefined|NaN|Infinity/);
  cleanup();
}

describe("the AI pictures", () => {
  it("every scene name the track uses has a picture, and every picture is used", () => {
    const used = new Set<string>();
    for (const l of track.lessons as AnyB2Lesson[]) {
      used.add(l.play.scene); used.add(l.guess.scene);
      if (l.useIt.scene) used.add(l.useIt.scene.scene);
    }
    for (const p of track.projects ?? []) used.add(p.scene.scene);
    for (const t of track.tools ?? []) used.add(t.id);
    for (const n of used) expect(scenes[n], n).toBeTruthy();
    for (const n of Object.keys(scenes)) expect(used.has(n) || n === "confusion", n).toBe(true);
  });
  for (const l of track.lessons as AnyB2Lesson[]) {
    it(`${l.id}: its stages draw`, () => {
      show(l.play.scene, l.play.props ?? {}, "lesson");
      show(l.guess.scene, l.guess.props ?? {}, "lesson", l.guess.kind === "slider" ? [l.guess.start ?? 0, 0] : undefined);
      show(l.guess.scene, l.guess.revealProps ?? l.guess.props ?? {}, "lesson");
      for (let i = 0; i < 4; i++) {
        const sc = l.workIt.scene?.(l.workIt.generate(createRng(7 + i), i));
        if (sc) show(sc.scene, sc.props ?? {}, "lesson");
      }
      if (l.useIt.scene) show(l.useIt.scene.scene, l.useIt.scene.props ?? {}, "lesson");
    }, 30000);
  }
  it("the tools and projects draw", () => {
    for (const t of track.tools ?? []) show(t.id, {}, "tool");
    for (const p of track.projects ?? []) show(p.scene.scene, p.scene.props ?? {}, "project");
  }, 30000);
});
