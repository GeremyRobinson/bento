import type { MathText } from "../../curriculum/schemas/math-text";
import type { Tier } from "../adaptive-help/policy";
import type { MistakeCategory } from "../diagnosis/diagnose";

/** One problem in a run. The canonical problem is stored, so resuming shows exactly the same problem. */
export interface RunItem {
  lessonId: string;
  problem: unknown;
  /** told as a word problem (every third problem of lessons that have stories) */
  story?: boolean;
}

export interface WorkLine {
  math: MathText;
  /** filled in by "Show me" rather than by the student */
  shown: boolean;
}

export interface Feedback {
  type: "good" | "bad" | "hint";
  /** the bold lead, e.g. "Not yet." or "Nice!" */
  strong?: string;
  text?: string;
  /** extra lines under the message */
  lines?: string[];
  /** celebration mark for the younger bands */
  pop?: "big" | "star";
  /** hints still left in the lesson, shown muted under a hint */
  left?: number;
}

export interface Mistake {
  /** problem number, from 1 */
  n: number;
  /** step number, from 1 */
  step: number;
  label: string;
  lessonId: string;
  typed: string;
  want: string;
  kind: string;
  cat: MistakeCategory | "concept";
  msg: string;
  rushed: boolean;
}

export interface ProblemRecord {
  lessonId: string;
  problem: unknown;
  story?: boolean;
  work: WorkLine[];
  hints: number;
  wrong: number;
  shown: number;
  ms: number;
}

export interface Plan {
  options: string[];
  right: string;
  misses: number;
}

export interface PracticeSession {
  mode: "practice" | "test" | "review";
  key: string;
  title: string;
  items: RunItem[];
  i: number;
  /** the problems already finished, by index: a set can be done in any order (G 2026-10-08, the problem picker) */
  done?: number[];
  step: number;
  work: WorkLine[];
  /** this problem is being done as one final answer */
  collapsed: boolean;
  /** the student chose "Final answer only" (on by default at the top tier) */
  skip: boolean;
  /** this problem may still be collapsed (a miss turns it off) */
  skipThis: boolean;
  tier: Tier;
  startTier: Tier;
  values: Record<string, string>;
  active: string | null;
  pick: Plan | null;
  misses: number;
  hinted: boolean;
  hintsLeft: number;
  lastTry: number;
  stepT0: number;
  prob: { wrong: number; hints: number; shown: number; t0: number };
  pts: number;
  maxPts: number;
  clean: number;
  extra: number;
  xpEarned: number;
  hints: number;
  shown: number;
  mistakes: Mistake[];
  probs: ProblemRecord[];
  feedback: Feedback | null;
  /** short-lived effect for the UI: shake on a miss, slide in a new line */
  fx: "shake" | "line" | "feedback" | null;
  t0: number;
  /** the current problem is solved and waits for "Next problem" */
  solved: boolean;
}

export interface SessionReport {
  key: string;
  mode: PracticeSession["mode"];
  title: string;
  date: number;
  ms: number;
  total: number;
  extra: number;
  clean: number;
  hints: number;
  shown: number;
  pct: number;
  level: 0 | 1 | 2 | 3 | 4;
  xp: number;
  probs: ProblemRecord[];
  mistakes: Mistake[];
}
