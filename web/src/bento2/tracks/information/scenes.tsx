// Information's live pictures by scene name. A track tool's id is the scene it opens (information/index.ts, tools).
import type { SceneComponent } from "../../scenes";
import { GuessGameScene } from "./pictures/GuessGame";
import { SurpriseScene } from "./pictures/Surprise";
import { CodesScene } from "./pictures/Codes";
import { BitCounterScene } from "./pictures/BitCounter";
import { ErrorLabScene } from "./pictures/ErrorLab";
import { ShrinkerScene } from "./pictures/Shrinker";
import "./information.css";

export const scenes: Record<string, SceneComponent> = {
  "in-guess": GuessGameScene,
  "in-surprise": SurpriseScene,
  "in-codes": CodesScene,
  "in-bits": BitCounterScene,
  "in-errorlab": ErrorLabScene,
  "in-shrinker": ShrinkerScene,
};
