// Relativity's live pictures by scene name. A track tool's id is the scene it opens (relativity/index.ts, tools).
import type { SceneComponent } from "../../scenes";
import { SpacetimeScene } from "./pictures/Spacetime";
import { LightClockScene } from "./pictures/LightClock";
import { TwinScene } from "./pictures/Twin";
import { AdderScene } from "./pictures/SpeedAdder";
import { EnergyScene } from "./pictures/Energy";
import { SmallSpeedScene } from "./pictures/SmallSpeed";
import { RocketScene, WellScene } from "./pictures/Gravity";
import { ClocksScene, GpsScene } from "./pictures/Gps";

export const scenes: Record<string, SceneComponent> = {
  spacetime: SpacetimeScene,
  lightclock: LightClockScene,
  twin: TwinScene,
  adder: AdderScene,
  energy: EnergyScene,
  smallspeed: SmallSpeedScene,
  well: WellScene,
  rocket: RocketScene,
  gps: GpsScene,
  clocks: ClocksScene,
};
