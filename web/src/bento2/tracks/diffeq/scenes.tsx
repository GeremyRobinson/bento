// Differential equations' live pictures by scene name. A track tool's id is the scene it opens (diffeq/index.ts, tools).
import type { SceneComponent } from "../../scenes";
import { AlleeScene, PhaseLineScene } from "./pictures/PhaseLine";
import { CoolingScene } from "./pictures/Cooling";
import { StepperPickScene, SteppersScene } from "./pictures/Steppers";
import { HarvestScene } from "./pictures/Harvest";
import { PlaneScene } from "./pictures/Plane";
import { GalleryScene, TdMapScene } from "./pictures/TdMap";
import { SpringScene } from "./pictures/Spring";
import { PendulumScene } from "./pictures/Pendulum";
import { ResonanceScene } from "./pictures/Resonance";
import { ClockScene } from "./pictures/Clock";
import { NonlinearScene } from "./pictures/Nonlinear";
import { SpeciesScene } from "./pictures/Species";
import { SirScene } from "./pictures/Sir";
import { ChaosScene } from "./pictures/Chaos";
import { FlowScene } from "./pictures/Flow";
import { ModelsScene } from "./pictures/Models";

export const scenes: Record<string, SceneComponent> = {
  flow: FlowScene,
  phaseline: PhaseLineScene,
  allee: AlleeScene,
  cooling: CoolingScene,
  steppers: SteppersScene,
  stepperpick: StepperPickScene,
  harvest: HarvestScene,
  plane: PlaneScene,
  tdmap: TdMapScene,
  gallery: GalleryScene,
  spring: SpringScene,
  pendulum: PendulumScene,
  resonance: ResonanceScene,
  clock: ClockScene,
  nonlinear: NonlinearScene,
  species: SpeciesScene,
  sir: SirScene,
  chaos: ChaosScene,
  models: ModelsScene,
};
