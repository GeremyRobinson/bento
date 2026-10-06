// Probability's live pictures by scene name. A track tool's id is the scene it opens (probability/index.ts, tools).
import type { SceneComponent } from "../../scenes";
import { SimScene } from "./pictures/Sim";
import { BayesScene } from "./pictures/Bayes";
import { SpinScene } from "./pictures/Spin";
import { DensScene } from "./pictures/Dens";
import { CltScene } from "./pictures/Clt";
import { CloudScene } from "./pictures/Cloud";
import { LikeScene } from "./pictures/Like";
import { BetaScene, BootScene, ErrBarsScene, VarEstScene } from "./pictures/Est";
import { CourtScene, PowerScene, ShuffleScene } from "./pictures/Tests";
import { RetestScene, SimpsonScene } from "./pictures/Traps";
import { BenchScene } from "./pictures/Bench";

export const scenes: Record<string, SceneComponent> = {
  sim: SimScene,
  bayes: BayesScene,
  spin: SpinScene,
  dens: DensScene,
  clt: CltScene,
  cloud: CloudScene,
  like: LikeScene,
  varest: VarEstScene,
  boot: BootScene,
  beta: BetaScene,
  errbars: ErrBarsScene,
  shuffle: ShuffleScene,
  power: PowerScene,
  court: CourtScene,
  retest: RetestScene,
  simpson: SimpsonScene,
  bench: BenchScene,
};
