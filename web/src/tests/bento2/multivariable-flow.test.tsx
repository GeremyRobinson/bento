// Multivariable through the UI: every lesson's five stages and Deeper render without an error, every project and
// every tool opens, and every picture draws for each state a lesson puts it in (Play, Guess, reveal, Work it's
// problems, Use it) with no stray NaN or undefined.
import { afterEach, describe, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { renderApp } from "../ui/helpers";
import { AppProvider } from "../../app/AppState";
import { emptyProgress } from "../../engine/mastery/progress";
import { createRng } from "../../curriculum/generators/rng";
import { sceneByName, type SceneValues } from "../../bento2/scenes";
import type { SceneRef } from "../../bento2/model";
import { MV_LESSONS } from "../../bento2/tracks/multivariable/lessons";
import { track } from "../../bento2/tracks/multivariable/index";

const tap = (name: string | RegExp) => fireEvent.click(screen.getByRole("button", { name }));
afterEach(() => { vi.restoreAllMocks(); cleanup(); });

function draw(ref: SceneRef, place: "lesson" | "tool" | "project" = "lesson", extra: SceneValues = {}, marker?: [number, number]) {
  const C = sceneByName(ref.scene);
  expect(C, ref.scene).toBeDefined();
  const Comp = C!;
  const { container } = render(
    <AppProvider initial={{ progress: emptyProgress(), reports: {} }} store={null} now={() => 0} rng={createRng(1)}>
      <Comp props={{ ...(ref.props ?? {}), ...extra }} place={place} marker={marker} />
    </AppProvider>,
  );
  const text = container.textContent ?? "";
  const attrs = [...container.querySelectorAll("*")].flatMap(el => [...el.attributes].map(a => a.value)).join(" ");
  const svg = container.querySelector("svg");
  cleanup();
  return { svg, text, attrs };
}
const clean = (r: ReturnType<typeof draw>, what: string) => {
  expect(r.svg, what).not.toBeNull();
  expect(r.text, what).not.toMatch(/NaN|undefined/);
  expect(r.attrs, what).not.toMatch(/NaN|undefined/);
};

describe("Multivariable: every picture draws", () => {
  for (const l of MV_LESSONS) {
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
    for (const t of track.tools) if (sceneByName(t.id)) clean(draw({ scene: t.id }, "tool"), t.id);
  });
});

describe("Multivariable in the app", () => {
  it("every lesson's stages render, one after another", () => {
    const errors = vi.spyOn(console, "error");
    for (const l of MV_LESSONS) {
      const { unmount } = renderApp({ grade: 5, chosen: true }, {}, `#/b2/hills/${l.id}`);
      expect(screen.getByRole("heading", { level: 1, name: l.title })).toBeInTheDocument();
      fireEvent.click(screen.getByRole("tab", { name: "Guess" }));
      const radios = screen.queryAllByRole("radio");
      if (radios.length) fireEvent.click(radios[0]!);
      tap("Lock in my guess");
      fireEvent.click(screen.getByRole("tab", { name: "Name it" }));
      fireEvent.click(screen.getByRole("tab", { name: "Work it" }));
      expect(document.querySelector(".b2steps")).not.toBeNull();
      fireEvent.click(screen.getByRole("tab", { name: "Use it" }));
      fireEvent.click(screen.getByRole("button", { name: "Deeper" }));
      unmount();
    }
    expect(errors).not.toHaveBeenCalled();
  });

  it("the track screen, its projects and its tools open", () => {
    const errors = vi.spyOn(console, "error");
    for (const p of track.projects) {
      const { unmount } = renderApp({ grade: 5, chosen: true }, {}, `#/b2/hills/pick/${p.id}`);
      expect(screen.getAllByText(p.name).length).toBeGreaterThan(0);
      unmount();
    }
    renderApp({ grade: 5, chosen: true }, {}, "#/b2/hills");
    expect(screen.getByRole("heading", { level: 1, name: track.name })).toBeInTheDocument();
    for (const t of track.tools) {
      fireEvent.click(screen.getAllByRole("button", { name: "Tools" })[0]!);
      fireEvent.click(within(screen.getByRole("dialog", { name: "Tools" })).getByRole("button", { name: new RegExp(t.name) }));
      expect(screen.getByRole("dialog", { name: t.name })).toBeInTheDocument();
      fireEvent.keyDown(window, { key: "Escape" });
    }
    expect(errors).not.toHaveBeenCalled();
  });
});
