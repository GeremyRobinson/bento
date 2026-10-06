// Multivariable's live pictures by scene name. Each one draws from the props a lesson passes (often a typed formula,
// Two lakes, or the learner's own landscape), so the picture always shows the learner's own numbers.
import type { SceneComponent } from "../../scenes";
import { BowlScene } from "./pictures/Bowl";
import { AnnealScene, DescentScene, MultiStartScene, RaceScene } from "./pictures/Descent";
import { FenceScene, ParkScene } from "./pictures/Fence";
import { FieldScene } from "./pictures/Field";
import { FlatsScene, GradientScene, RainScene } from "./pictures/Gradient";
import { HikerScene, MyLandScene } from "./pictures/Hiker";
import { MorphScene } from "./pictures/Morph";
import { CompassScene, SliceScene } from "./pictures/Slice";
import { PlaneScene, SurfaceScene } from "./pictures/Surface";
import { ValleyScene } from "./pictures/Valley";
import { LakeScene, PolarScene, SweepScene, VolumeScene } from "./pictures/Volume";
import { WarpScene } from "./pictures/Warp";

export const scenes: Record<string, SceneComponent> = {
  surface: SurfaceScene, tangent: PlaneScene, slice: SliceScene, compass: CompassScene, hiker: HikerScene, myland: MyLandScene,
  volume: VolumeScene, sweep: SweepScene, polar: PolarScene, lake: LakeScene, warp: WarpScene, field: FieldScene,
  gradient: GradientScene, rain: RainScene, flats: FlatsScene, morph: MorphScene, downhill: DescentScene, finder: DescentScene,
  race: RaceScene, multistart: MultiStartScene, anneal: AnnealScene, fence: FenceScene, park: ParkScene, bowl: BowlScene,
  valley: ValleyScene,
};
