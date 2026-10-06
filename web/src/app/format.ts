import type { SessionReport } from "../engine/session/types";
import { SHOW_ME } from "./copy";

// Small text helpers shared by the screens, worded exactly as in the current app.
export const when = (t: number) => new Date(t).toLocaleDateString(undefined, { month: "short", day: "numeric" });
export const mins = (ms: number) => Math.max(1, Math.round(ms / 60000));
export const plural = (n: number, w: string) => `${n} ${w}${n === 1 ? "" : "s"}`;

export function summaryLine(rep: SessionReport): string {
  const pct = Math.round(rep.pct * 100);
  return rep.mode === "test"
    ? `${plural(rep.total, "problem")} in ${plural(mins(rep.ms), "minute")}. ${rep.clean} with every step right. ${pct}% of steps right on the first try.`
    : `${plural(rep.total, "problem")} in ${plural(mins(rep.ms), "minute")}${rep.extra ? `, including ${rep.extra} extra added for practice` : ""}. ${rep.clean} with no mistakes and no hints. ${plural(rep.hints, "hint")} used, "${SHOW_ME}" ${plural(rep.shown, "time")}. ${pct}% of steps right on the first try.`;
}

export const LEVEL_SENTENCES = [
  "Not yet showing this skill.",
  "Starting to get it, with a lot of help.",
  "Getting there: some steps are solid, others need more practice.",
  "Meets the goal: most steps right on the first try.",
  "Above the goal: nearly every step right on the first try.",
] as const;
