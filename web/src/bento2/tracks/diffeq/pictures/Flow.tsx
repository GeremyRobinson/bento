// ★ The slope field and flow sandbox (diffeq.md, "New for Development" 1): one tool, three modes. The phase line strip
// for one equation, the phase plane for a 2×2 system, and the stepper race.
import { useState } from "react";
import type { SceneProps } from "../../../scenes";
import { Toggle } from "../../../ui/kit";
import { PhaseLineScene } from "./PhaseLine";
import { PlaneScene } from "./Plane";
import { SteppersScene } from "./Steppers";

type Mode = "line" | "plane" | "step";
const MODES: { v: Mode; label: string }[] = [{ v: "line", label: "Phase line" }, { v: "plane", label: "Phase plane" }, { v: "step", label: "Steppers" }];

export function FlowScene({ place }: SceneProps) {
  const [mode, setMode] = useState<Mode>("plane");
  return (
    <div style={{ display: "grid", gridTemplateRows: "auto minmax(0, 1fr)", gap: "8px", minHeight: "100%" }}>
      <Toggle label="Sandbox mode" value={mode} onChange={setMode} options={MODES} />
      {mode === "line" ? <PhaseLineScene props={{}} place={place} />
        : mode === "plane" ? <PlaneScene props={{ mode: "matrix", a11: 0, a12: 1, a21: -2, a22: -1 }} place={place} />
          : <SteppersScene props={{ h: 0.25 }} place={place} />}
    </div>
  );
}
