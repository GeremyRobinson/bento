// Differential equations' pictures render for every state a lesson puts them in: Play, the Guess and its reveal, Work
// it's problems, Use it, every project and every tool. Each draws a live SVG with no stray numbers (NaN, undefined).
import { describe, expect, it } from "vitest";
import { cleanup, render } from "@testing-library/react";
import { AppProvider } from "../../app/AppState";
import { emptyProgress } from "../../engine/mastery/progress";
import { createRng } from "../../curriculum/generators/rng";
import { trackByCode } from "../../bento2/registry";
import { sceneByName, type SceneValues } from "../../bento2/scenes";
import type { SceneRef } from "../../bento2/model";

const track = trackByCode("de")!;

function draw(ref: SceneRef, place: "lesson" | "tool" | "project" = "lesson", extra: SceneValues = {}, marker?: [number, number]) {
  const C = sceneByName(ref.scene)!;
  const { container } = render(
    <AppProvider initial={{ progress: emptyProgress(), reports: {} }} store={null} now={() => 0} rng={createRng(1)}>
      <C props={{ ...(ref.props ?? {}), ...extra }} place={place} marker={marker} />
    </AppProvider>,
  );
  const svg = container.querySelector("svg");
  const text = container.textContent ?? "";
  const attrs = [...container.querySelectorAll("*")].flatMap(el => [...el.attributes].map(a => a.value)).join(" ");
  cleanup();
  return { svg, text, attrs };
}
const clean = (r: ReturnType<typeof draw>, what: string) => {
  expect(r.svg, what).not.toBeNull();
  expect(r.text, what).not.toMatch(/NaN|undefined|Infinity/);
  expect(r.attrs, what).not.toMatch(/NaN|undefined|Infinity/);
};

describe("Differential equations: every picture draws", () => {
  for (const l of track.lessons) {
    it(`${l.id}: Play, Guess, reveal, Work it and Use it`, () => {
      clean(draw(l.play), `${l.id} play`);
      const g = l.guess;
      const marker: [number, number] | undefined = g.kind === "point" ? g.start : g.kind === "slider" ? [g.start ?? g.min, 0] : undefined;
      clean(draw(g, "lesson", {}, marker), `${l.id} guess`);
      clean(draw(g, "lesson", { quiet: false, hide: false, ...g.revealProps }, marker), `${l.id} reveal`);
      for (let i = 0; i < 8; i++) {
        const p = l.workIt.generate(createRng(500 + i), i);
        if (l.workIt.scene) clean(draw(l.workIt.scene(p)), `${l.id} work ${JSON.stringify(p)}`);
      }
      if (l.useIt.scene) clean(draw(l.useIt.scene), `${l.id} use`);
    });
  }
  it("every project and every tool", () => {
    for (const p of track.projects) clean(draw(p.scene, "project"), p.id);
    for (const t of track.tools) clean(draw({ scene: t.id }, "tool"), t.id);
  });
});
