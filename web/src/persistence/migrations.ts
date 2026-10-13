// Turning older saved data into the current Progress shape.
// The current app saves to localStorage under "stepmath" and "stepmath-reports".
import { lessonById } from "../curriculum/registry";
import { emptyProgress, type Progress, type ScoreRecord } from "../engine/mastery/progress";
import { checksFromScores } from "../engine/mastery/skills";
import type { Level } from "../engine/mastery/levels";
import type { SessionReport } from "../engine/session/types";

const isObj = (x: unknown): x is Record<string, unknown> => !!x && typeof x === "object" && !Array.isArray(x);
const num = (x: unknown, d = 0) => (typeof x === "number" && Number.isFinite(x) ? x : d);
const level = (x: unknown): Level => Math.max(0, Math.min(4, Math.round(num(x)))) as Level;

function scoreBook(x: unknown): Record<string, ScoreRecord> {
  if (!isObj(x)) return {};
  return Object.fromEntries(Object.entries(x).filter(([, v]) => isObj(v)).map(([k, v]) => {
    const r = v as Record<string, unknown>;
    return [k, { last: level(r.last), best: level(r.best ?? r.last), pct: num(r.pct), date: num(r.date), mastered: !!r.mastered }];
  }));
}

const numberMap = (x: unknown): Record<string, number> =>
  isObj(x) ? Object.fromEntries(Object.entries(x).filter(([, v]) => typeof v === "number")) as Record<string, number> : {};

/**
 * Converts the current app's save to Progress. Every field is kept, including scores for lessons
 * that haven't been rebuilt yet, so nothing is lost while the migration is in progress.
 * The run in progress is not carried over (its format differs); it simply starts fresh.
 */
export function fromLegacySave(raw: unknown): Progress {
  const p = emptyProgress();
  if (!isObj(raw)) return p;
  p.grade = typeof raw.grade === "number" ? raw.grade : null;
  p.chosen = !!raw.chosen || num(raw.xp) > 0 || num(raw.done) > 0;
  p.xp = num(raw.xp);
  p.gxp = numberMap(raw.gxp);
  p.streak = num(raw.streak);
  p.last = typeof raw.last === "string" ? raw.last : "";
  p.done = num(raw.done);
  p.lessons = numberMap(raw.lessons);
  p.scores = scoreBook(raw.scores);
  p.tests = scoreBook(raw.tests);
  p.checks = checksFromScores(p.scores);
  p.seen = numberMap(raw.seen);
  p.reviews = Object.fromEntries(Object.entries(numberMap(raw.reviews)).map(([k, v]) => [k, level(v)]));
  p.log = Array.isArray(raw.log) ? (raw.log.filter(isObj) as unknown as Progress["log"]).slice(0, 60) : [];
  return p;
}

/** Legacy reports are kept as they are; problems of rebuilt lessons are re-validated into canonical models. */
export function fromLegacyReports(raw: unknown): Record<string, SessionReport> {
  if (!isObj(raw)) return {};
  const out: Record<string, SessionReport> = {};
  for (const [k, v] of Object.entries(raw)) {
    if (!isObj(v)) continue;
    const probs = Array.isArray(v.probs) ? v.probs.filter(isObj).map(pr => {
      const id = String(pr.id ?? pr.lessonId ?? k);
      const lesson = lessonById(id);
      return { lessonId: id, problem: lesson?.restore(pr.p ?? pr.problem) ?? pr.p ?? pr.problem ?? null,
        work: [], hints: num(pr.hints), wrong: num(pr.wrong), shown: num(pr.shown), ms: num(pr.ms) };
    }) : [];
    out[k] = { ...(v as unknown as SessionReport), key: k, probs, level: level(v.level) };
  }
  return out;
}

/** Brings any stored Progress up to the current version. Version 1 is the first. */
export function migrateProgress(raw: unknown): Progress {
  if (isObj(raw) && raw.version === 1) {
    const p = { ...emptyProgress(), ...(raw as unknown as Progress) };
    // a save from before skill checks: its practice scores of 3+ become checks, once
    return raw.checks === undefined ? { ...p, checks: checksFromScores(p.scores) } : p;
  }
  return fromLegacySave(raw);
}
