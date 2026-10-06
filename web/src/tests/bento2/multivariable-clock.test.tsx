// A browser can stamp an animation frame a hair before the clock started, so the kit's clock can read just below 0.
// Every Multivariable picture must still draw (this once blanked the app on lessons 10, 18 and 19).
import { describe, expect, it, vi } from "vitest";
import { cleanup, render } from "@testing-library/react";
import { AppProvider } from "../../app/AppState";
import { emptyProgress } from "../../engine/mastery/progress";
import { createRng } from "../../curriculum/generators/rng";
import { sceneByName } from "../../bento2/scenes";
import type { SceneRef } from "../../bento2/model";
import { MV_LESSONS } from "../../bento2/tracks/multivariable/lessons";
import { track } from "../../bento2/tracks/multivariable/index";

vi.mock("../../bento2/ui/kit", async orig => ({ ...(await orig<typeof import("../../bento2/ui/kit")>()), useClock: () => -0.004 }));

function draw(ref: SceneRef, place: "lesson" | "project" = "lesson") {
  const C = sceneByName(ref.scene)!;
  render(
    <AppProvider initial={{ progress: emptyProgress(), reports: {} }} store={null} now={() => 0} rng={createRng(1)}>
      <C props={ref.props ?? {}} place={place} />
    </AppProvider>,
  );
  cleanup();
}

describe("Multivariable pictures with a clock just below 0", () => {
  it("every lesson and project picture draws", () => {
    for (const l of MV_LESSONS) {
      for (const ref of [l.play, l.guess, { ...l.guess, props: { ...l.guess.props, quiet: false, ...l.guess.revealProps } }, l.useIt.scene, l.workIt.scene?.(l.workIt.reference)])
        if (ref) expect(() => draw(ref), `${l.id} ${ref.scene}`).not.toThrow();
    }
    for (const p of track.projects) expect(() => draw(p.scene, "project"), p.id).not.toThrow();
  });
});
