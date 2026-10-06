// Orbits' live pictures by scene name. A track tool's id is the scene it opens (orbits/index.ts, tools). Names carry
// the track's prefix so they never meet another track's.
import type { SceneComponent } from "../../scenes";
import { SandboxScene } from "./pictures/Sandbox";
import { CannonScene } from "./pictures/Cannon";
import { KeplerScene } from "./pictures/Kepler";
import { BurnScene } from "./pictures/Burn";
import { ClockScene } from "./pictures/Clock";
import { StackScene } from "./pictures/Stack";
import { DepartScene } from "./pictures/Depart";
import { CardScene } from "./pictures/Card";
import { SatelliteScene } from "./pictures/Satellite";
import { CometScene } from "./pictures/Comet";

export const scenes: Record<string, SceneComponent> = {
  "or-sandbox": SandboxScene,
  "or-cannon": CannonScene,
  "or-kepler": KeplerScene,
  "or-burn": BurnScene,
  "or-clock": ClockScene,
  "or-stack": StackScene,
  "or-depart": DepartScene,
  "or-card": CardScene,
  "or-satellite": SatelliteScene,
  "or-comet": CometScene,
};
