// Linear algebra's live pictures by scene name (la- first, since every track's names share one table). A track tool's id is the scene it opens (linear/index.ts, tools).
import type { SceneComponent } from "../../scenes";
import { PlaygroundScene } from "./pictures/Playground";
import { VectorsScene } from "./pictures/Vectors";
import { Space3DScene } from "./pictures/Space3D";
import { EigenScene } from "./pictures/Eigen";
import { CompressorScene } from "./pictures/Compressor";
import { FlowScene } from "./pictures/Flow";
import { ResidualScene } from "./pictures/Residual";
import { CloudScene } from "./pictures/Cloud";

export const scenes: Record<string, SceneComponent> = {
  "la-playground": PlaygroundScene,
  "la-vectors": VectorsScene,
  "la-space": Space3DScene,
  "la-eigen": EigenScene,
  "la-compressor": CompressorScene,
  "la-flow": FlowScene,
  "la-residual": ResidualScene,
  "la-cloud": CloudScene,
};
