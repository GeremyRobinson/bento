import type { Rng } from "../generators/rng";
import type { MathText } from "./math-text";
import type { DiagramModel, Explanation } from "../../explanations/schema";

export type GradeNumber = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12;

/**
 * Short text for hints and messages. `**bold**` marks emphasis; fractions are written "3/4".
 * Every number in it comes from the problem model.
 */
export type RichText = string;

/** One box the student fills in. `expected: null` means the box should stay empty (e.g. no whole part). */
export interface AnswerSlot {
  id: string;
  expected: number | null;
}

/** A wrong answer we can predict from the problem, with the reason it happens. */
export interface KnownMistake {
  /** the typed values that trigger it, by slot id */
  values: Record<string, number>;
  kind: string;
  message: RichText;
}

/** Result of checking one step. Same shape as the current app's check functions. */
export type StepCheck =
  | { ok: true }
  | { ok: false; soft: true; message: RichText }
  | { ok: false; soft?: false; kind: string; message: RichText; generic: boolean };

/** One step of the derived answer model. Every number in it comes from the canonical problem. */
export interface AnswerStep {
  id: string;
  label: string;
  /** an optional instruction above the math */
  question?: RichText;
  /** the math with answer boxes in it */
  prompt: MathText;
  /** a short line under the step */
  note?: RichText;
  slots: AnswerSlot[];
  /** tap-to-answer steps: the student picks one; the slot "c" expects the right index */
  choices?: string[];
  /**
   * Predictable slips, checked in order when every box matches nothing right.
   * Steps whose rules can't be written as values (equivalent fractions, any order, lowest terms)
   * give `check` instead; it is still a pure function of the problem.
   */
  known: KnownMistake[];
  check?: (values: Record<string, number | null>) => StepCheck;
  hint: RichText;
  /** what "Show me" says after filling the answer in */
  explain: RichText;
  /** the finished line that stays on screen once the step is done */
  work: MathText;
}

export interface AnswerModel {
  steps: AnswerStep[];
  /** which steps together make the final answer (negative counts from the end); default: the last step */
  finalParts: number[];
}

/** A word problem told about the same numbers. `op` is the operation the story needs. */
export interface Story {
  op: "+" | "−" | "×" | "÷";
  text: RichText;
}

/**
 * A lesson is a pipeline: generate → canonical problem → answer model → explanation.
 * Nothing problem-specific is written anywhere else.
 */
export interface LessonDefinition<P = unknown> {
  id: string;
  grade: GradeNumber;
  unit: string;
  title: string;
  /** the worked example the learn screen opens on; "Another one" generates more */
  reference: P;
  /** index is the problem's place in the run (the current app makes the first problems easier) */
  generate(rng: Rng, index: number): P;
  /** validates a stored or imported problem (including the current app's saved shape) and returns the canonical model, or null */
  restore(raw: unknown): P | null;
  /** the problem as the student sees it, above the steps */
  display(problem: P): MathText;
  /** an optional line under the problem, e.g. "Factor it." */
  displayNote?(problem: P): RichText;
  /** word problems: the whole question at reading size, shown in place of the short math line */
  lead?(problem: P): RichText;
  /** counters under the problem in practice, built from its numbers (the current app's dots, ten frames and base-ten blocks) */
  displayCounters?(problem: P): Counters;
  /** an optional picture shown with the problem, e.g. the dots to count (the current app's dots and ten frames) */
  /** an optional picture shown with the problem, e.g. the dots to count (the current app's dots and ten frames). In
   *  practice it gets the id of the step being asked, so it can circle the part that step is about (G 2026-10-07) */
  picture?(problem: P, step?: string): DiagramModel;
  answers(problem: P): AnswerModel;
  explain(problem: P, answers: AnswerModel): Explanation;
  /** some lessons tell every third problem as a story */
  story?(problem: P): Story;
  /** the lesson underneath this one, suggested after a score of 0 or 1 */
  pre?: string;
}

/** Erases the problem type so lessons of different kinds can live in one registry. */
export type AnyLesson = LessonDefinition<any>;

/** One group of counters standing for a number: loose dots, a ten frame, or tens rods and ones cubes. */
export interface CounterGroup { kind: "dots" | "tenFrame" | "blocks"; value: number }
/** Groups shown in a row with an operation sign between them, e.g. 3 dots + 2 dots. */
export interface Counters { groups: CounterGroup[]; op: string }
