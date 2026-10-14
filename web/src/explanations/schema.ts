import type { MathText } from "../curriculum/schemas/math-text";
import type { RichText } from "../curriculum/schemas/lesson";
import type { AreaDiagram } from "./diagrams/area-model/schema";
import type { ChainDiagram } from "./diagrams/chain/schema";
import type { SceneDiagram } from "./diagrams/scene/schema";

/** Every diagram family is one of these. Scenes cover any picture built from shapes; chains are lines of math. */
export type DiagramModel = AreaDiagram | SceneDiagram | ChainDiagram;

/**
 * Animation is a list of named states; renderers only need the current index.
 * The area model uses its own phases; every other family uses "beat" states, and its shapes say from which beat they show.
 */
export type AnimationState =
  | { phase: "factors" }
  | { phase: "split" }
  | { phase: "region"; index: number }
  /** division: a strip not yet found shows what is left inside it (its result), still soft */
  | { phase: "left"; index: number }
  | { phase: "sum" }
  | { phase: "beat"; index: number };

export const beats = (n: number): AnimationState[] => Array.from({ length: n }, (_, index) => ({ phase: "beat", index }));

/** One beat of the explanation: what is said, the math shown, what lights up, and the answer it leads to. */
export interface ExplanationStep {
  id: string;
  narration: RichText;
  math: MathText;
  /** index into the timeline this step plays */
  state: number;
  /** answer-model step this beat explains, when there is one */
  answerStep?: string;
  /** value the beat arrives at; equals the answer model's expected value when answerStep is set */
  result?: number;
}

export interface Explanation {
  heading: string;
  /** the idea in a sentence or two, without problem numbers (kept from the current app's lesson cards) */
  idea?: RichText[];
  /** the problem in one line, e.g. 47 × 36 = 47 × (30 + 6) */
  statement: MathText;
  diagram?: DiagramModel;
  /** one line under the picture, built from the problem */
  caption?: RichText;
  timeline: AnimationState[];
  steps: ExplanationStep[];
  /** what the say line adds once the problem is solved, in this problem's numbers: "The four parts make 180." */
  solved?: RichText;
  /** the beat a picture shows at rest (Today, teasers) when its finished picture would give the answer away */
  rest?: number;
}
