// The Bento² lesson model. One type per spec block (curriculum/specs/bento2/README.md, "Lesson block format"):
// every field in the spec has a field here, so a track helper can copy a block across line by line.
import type { Rng } from "../curriculum/generators/rng";
import type { RichText } from "../curriculum/schemas/lesson";

/** The ten tracks' codes, as lesson ids use them: b2-<code>-<nn>. */
export type TrackCode = "la" | "pr" | "mv" | "in" | "cs" | "ai" | "de" | "or" | "re" | "qu";

/** The always-there tools (toolbox.md, "The always-there tools"). Track tools are named by their own ids. */
export type CoreToolId = "calc" | "graph2d" | "graph3d" | "matrix" | "shelf" | "units" | "scratch" | "notebook";

/** A value the learner keeps on the Number shelf: a number, a list (with labels), or a matrix. */
export type ShelfValue = number | number[] | number[][];

/** What a picture is drawn from: a scene name the track's picture table knows, and the live numbers it starts on. */
export interface SceneRef {
  scene: string;
  /** the starting numbers; the learner drags from here */
  props?: Record<string, number | string | boolean>;
}

/** The Play stage: the live picture, what to drag, what changes (one or two sentences). */
export interface B2Play extends SceneRef {
  say: RichText;
}

/**
 * The Guess stage: a prediction drawn from the live numbers. Bento records whether it was right but never shows it as a
 * score: the reveal just shows the answer in the picture.
 */
export type B2Guess = SceneRef & {
  ask: RichText;
  /** what the reveal says, after the picture shows the answer */
  reveal: RichText;
  /** the props the picture takes for the reveal */
  revealProps?: Record<string, number | string | boolean>;
} & (
  | { kind: "choice"; options: string[]; answer: number }
  /** a slider (or a marker on a bar); a guess within `near` of the answer counts as right in the quiet record */
  | { kind: "slider"; min: number; max: number; step: number; answer: number; near: number; unit?: string; start?: number; format?: (x: number) => string }
  /** a point dragged on the picture; the picture reports it through onMarker */
  | { kind: "point"; answer: [number, number]; near: number; start: [number, number] }
);

/** The Name it stage: 1 to 3 sentences, then the formula. */
export interface B2NameIt {
  say: RichText[];
  formula: string[];
}

/** A predicted wrong answer and the reason, by value (one value per box of the step). */
export interface B2Slip {
  kind: string;
  values: number[];
  message: RichText;
}

/**
 * One typed or tapped step of Work it. `answer` holds one number per box. Numbers are checked within one unit of the
 * last stated place (`places`), fractions and wholes exactly (equivalent forms count). Tap steps keep the right index
 * in `answer[0]`.
 */
export interface B2Step {
  id: string;
  label: string;
  /** what each box is called, when a step has more than one ("γ", "βγ") */
  boxes?: string[];
  /** "fraction", "whole", or a number of decimal places */
  form: "fraction" | "whole" | number;
  answer: number[];
  unit?: string;
  /** a short line above the boxes */
  ask?: RichText;
  choices?: string[];
  slips: B2Slip[];
  hint: RichText;
  /** the finished line that stays once the step is done */
  done: RichText;
}

/** Work it: the problem generator with ranges, then the steps. Early problems (index < 3) use small friendly numbers. */
export interface B2WorkIt<P> {
  reference: P;
  generate(rng: Rng, index: number): P;
  /** the problem as the learner reads it */
  show(p: P): RichText;
  steps(p: P): B2Step[];
  /** the live picture for the problem, if the problem has one */
  scene?(p: P): SceneRef;
}

/** Use it: the small real task, and what it adds to the build or project (with a Number shelf name if it saves). */
export interface B2UseIt {
  say: RichText[];
  /** a value it saves to the Number shelf, worked out from the constants (unrounded) */
  saves?: { name: string; value: () => ShelfValue; unit?: string; labels?: string[]; note: string };
  /** the small project or build this lesson ends with (its id in the track's projects) */
  project?: string;
  /** the tool or picture the task runs in */
  scene?: SceneRef;
}

export interface B2Lesson<P = unknown> {
  /** b2-<code>-<nn> */
  id: string;
  track: TrackCode;
  /** the unit's number in the track, from 1 */
  unit: number;
  title: string;
  /** the ability line shown when the lesson is done */
  youCan: string;
  /** soft: lesson ids (b2-…) or Bento lesson ids (g11-radical); they light the map and suggest a refresher, never lock */
  needs: string[];
  /** toolbox tools the lesson opens; the track's main tool is starred in the track's tool table */
  tools: string[];
  play: B2Play;
  guess: B2Guess;
  nameIt: B2NameIt;
  workIt: B2WorkIt<P>;
  /** an independent check of the problem's answers, in step order (tap steps give the right index); tests compare */
  oracle(p: P): number[];
  useIt: B2UseIt;
  deeper: RichText[];
  /** a whole Deeper lesson: off the build's path on the map, never needed to finish the build */
  optional?: boolean;
}

export type AnyB2Lesson = B2Lesson<any>;

/** The loop every lesson runs, in order. */
export const STAGES = ["play", "guess", "name", "work", "use"] as const;
export type Stage = (typeof STAGES)[number];
export const STAGE_NAMES: Record<Stage, string> = { play: "Play", guess: "Guess", name: "Name it", work: "Work it", use: "Use it" };

/** A tool on the shelf of tools: core or a track's own. */
export interface B2ToolMeta {
  id: string;
  name: string;
  /** one line for the dock's label on a phone */
  short: string;
  /** the track's main tool, ★ */
  star?: boolean;
  /** still being built: opens a panel that says so, with the seam ready */
  stub?: boolean;
}

export interface B2Unit { n: number; name: string; adds: string }
export interface B2Project {
  id: string;
  /** the lesson it comes after */
  after: string;
  name: string;
  makes: string;
  /** shelf names it saves */
  shelf: string[];
  /** the track's build (the last project) */
  build?: boolean;
  scene: SceneRef;
}

/** Everything a track screen needs: from the track spec's header. */
export interface B2Track {
  code: TrackCode;
  /** the id the picker's track list uses (app/tracks.ts) */
  pickerId: string;
  name: string;
  about: string;
  build: { name: string; goal: string };
  units: B2Unit[];
  projects: B2Project[];
  tools: B2ToolMeta[];
  /** the shelf names the build is assembled from, in order; build progress is how many are saved */
  buildPieces: string[];
  lessons: AnyB2Lesson[];
}
