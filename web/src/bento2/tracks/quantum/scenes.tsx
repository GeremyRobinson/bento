// Quantum's live pictures by scene name. A track tool's id is the scene it opens (quantum/index.ts, tools).
import type { SceneComponent } from "../../scenes";
import { SphereScene } from "./pictures/Sphere";
import { ArrowsScene } from "./pictures/Arrows";
import { SlitScene } from "./pictures/Slit";
import { CoinScene } from "./pictures/Coin";
import { CircuitScene } from "./pictures/Circuit";
import { HphScene } from "./pictures/Hph";
import { GridScene } from "./pictures/Grid";
import { PairScene } from "./pictures/Pair";
import { BellabScene } from "./pictures/Bellab";
import { DjScene } from "./pictures/Dj";
import { MeanScene } from "./pictures/Mean";
import { SearchScene } from "./pictures/Search";

export const scenes: Record<string, SceneComponent> = {
  sphere: SphereScene,
  arrows: ArrowsScene,
  slit: SlitScene,
  coin: CoinScene,
  circuit: CircuitScene,
  hph: HphScene,
  grid: GridScene,
  pair: PairScene,
  bellab: BellabScene,
  dj: DjScene,
  mean: MeanScene,
  search: SearchScene,
};
