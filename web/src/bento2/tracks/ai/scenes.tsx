// The AI capstone's live pictures by scene name. A track tool's id is the scene it opens (ai/index.ts, tools).
import type { SceneComponent } from "../../scenes";
import "./ai.css";
import { FitterScene } from "./pictures/Fitter";
import { LandscapeScene } from "./pictures/Landscape";
import { DescentScene } from "./pictures/Descent";
import { EtaDialScene } from "./pictures/EtaDial";
import { NeuronScene } from "./pictures/Neuron";
import { LayersScene } from "./pictures/Layers";
import { BackpropScene } from "./pictures/Backprop";
import { SoftmaxScene } from "./pictures/Softmax";
import { TinyNetScene } from "./pictures/TinyNet";
import { ConfusionScene, DigitsScene } from "./pictures/Digits";
import { WordsScene } from "./pictures/Words";
import { AttentionScene } from "./pictures/Attention";
import { TransformerScene } from "./pictures/Transformer";
import { LettersScene } from "./pictures/Letters";
import { LogLogScene } from "./pictures/LogLog";
import { BatchScene } from "./pictures/Batch";
import { ComputeScene } from "./pictures/Compute";
import { GoalsScene } from "./pictures/Goals";
import { FieldNotesScene, ReliabilityScene } from "./pictures/Reliability";

export const scenes: Record<string, SceneComponent> = {
  fitter: FitterScene,
  landscape: LandscapeScene,
  descent: DescentScene,
  etadial: EtaDialScene,
  neuron: NeuronScene,
  layers: LayersScene,
  backprop: BackpropScene,
  softmax: SoftmaxScene,
  tinynet: TinyNetScene,
  digits: DigitsScene,
  confusion: ConfusionScene,
  words: WordsScene,
  attention: AttentionScene,
  transformer: TransformerScene,
  letters: LettersScene,
  loglog: LogLogScene,
  batch: BatchScene,
  compute: ComputeScene,
  goals: GoalsScene,
  reliability: ReliabilityScene,
  fieldnotes: FieldNotesScene,
};
