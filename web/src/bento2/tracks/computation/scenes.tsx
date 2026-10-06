// Computation's live pictures by scene name. A track tool's id is the scene it opens (computation/index.ts, tools).
import type { SceneComponent } from "../../scenes";
import { StageScene } from "./pictures/Stage";
import { TruthTableScene } from "./pictures/TruthTable";
import { ProofScene } from "./pictures/Proof";
import { GatesScene } from "./pictures/Gates";
import { GrowthScene } from "./pictures/Growth";
import { GraphScene } from "./pictures/Graph";
import { HanoiScene } from "./pictures/Hanoi";
import { MachineScene } from "./pictures/Machine";
import { DiagonalScene } from "./pictures/Diagonal";
import { RaceScene } from "./pictures/Race";
import { MultScene } from "./pictures/Mult";
import "./computation.css";

export const scenes: Record<string, SceneComponent> = {
  "cs-stage": StageScene,
  "cs-truth": TruthTableScene,
  "cs-proof": ProofScene,
  "cs-gates": GatesScene,
  "cs-growth": GrowthScene,
  "cs-graph": GraphScene,
  "cs-hanoi": HanoiScene,
  "cs-machine": MachineScene,
  "cs-diagonal": DiagonalScene,
  "cs-race": RaceScene,
  "cs-mult": MultScene,
};
