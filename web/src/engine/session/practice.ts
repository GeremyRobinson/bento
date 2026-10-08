// The practice engine: pure functions from one session state to the next.
// Same rules as the current app (index.html: newRun, startProblem, loadStep, check, hint, pass, showMe, nextProblem,
// startTest, startReview, opStep).
import { bandOf, gradeOf, type Band } from "../../curriculum/grades";
import type { Rng } from "../../curriculum/generators/rng";
import { formatNumber, toPlainText } from "../../curriculum/schemas/math-text";
import { lessonById, lessonsInGrade, requireLesson, LESSONS } from "../../curriculum/registry";
import type { AnswerStep, AnyLesson } from "../../curriculum/schemas/lesson";
import { canShowMe, canSkip, hintBudget, HINT_WAIT_MS, lessonLength, MAX_LESSON_LENGTH, RUSHED_MS, tierFor, type Tier } from "../adaptive-help/policy";
import { CATEGORIES, diagnose, nudge, SAY } from "../diagnosis/diagnose";
import { parseNumber } from "../evaluation/numbers";
import { answerIds, checkStep, expectedValues, finalPartsOf, finalStep, runtimeSteps, type RuntimeStep } from "../evaluation/steps";
import { levelOf, problemXp, stepPoints } from "../mastery/levels";
import { lastScore, type Progress } from "../mastery/progress";
import { PRAISE } from "./praise";
import type { Mistake, PracticeSession, RunItem, SessionReport } from "./types";
import { FIND_MY_LEVEL, NO_UNIT, TODAYS_REVIEW } from "../../app/copy";

/** Clock and randomness are passed in, so every rule can be tested exactly. */
export interface Deps {
  now: number;
  rng: Rng;
}

const isTest = (s: PracticeSession) => s.mode === "test";
export const currentItem = (s: PracticeSession): RunItem => s.items[s.i]!;
export const lessonOfItem = (it: RunItem): AnyLesson => requireLesson(it.lessonId);
export const bandOfSession = (s: PracticeSession): Band => bandOf(lessonOfItem(currentItem(s)).grade);

/** The canonical problem for the current item, re-validated by its lesson. */
export function problemOf(it: RunItem): unknown {
  const p = lessonOfItem(it).restore(it.problem);
  if (p == null) throw new Error(`stored problem for ${it.lessonId} is not valid`);
  return p;
}

// ---------------------------------------------------------------- word problems

export const OPS = ["+", "−", "×", "÷"] as const;
const OP_NAME = { "+": "Add", "−": "Subtract", "×": "Multiply", "÷": "Divide" } as const;
const OP_WHY = {
  "+": "Putting amounts together means adding.",
  "−": "Taking away, or finding how much more, means subtracting.",
  "×": "Equal groups, or a part of a group, means multiplying.",
  "÷": "Sharing equally, or splitting into groups, means dividing.",
} as const;

/** "Read the story": pick the operation first. The answer is the index of the story's operation. */
export function operationStep(lesson: AnyLesson, p: unknown): AnswerStep {
  const story = lesson.story!(p), k = OPS.indexOf(story.op);
  return {
    id: "story", label: "Read the story", question: "Which operation solves it?", prompt: [],
    choices: OPS.map(o => `${o} ${OP_NAME[o]}`),
    slots: [{ id: "c", expected: k }],
    known: [],
    check: v => (v.c === k ? { ok: true } : { ok: false, kind: "Picked the wrong operation", message: "Read the story again. Is it putting together, taking away, equal groups, or sharing?", generic: false }),
    hint: OP_WHY[story.op], explain: OP_WHY[story.op],
    work: [...lesson.display(p), { t: "muted", v: [{ t: "text", v: ` (${OP_NAME[story.op].toLowerCase()})` }] }],
  };
}

/** Every step of an item as practice runs it: the story's operation first when it's a word problem. */
function fullSteps(it: RunItem): RuntimeStep[] {
  const lesson = lessonOfItem(it), p = problemOf(it);
  const model = lesson.answers(p);
  const lead = it.story && lesson.story ? runtimeSteps({ steps: [operationStep(lesson, p)], finalParts: [-1] }) : [];
  return [...lead, ...runtimeSteps(model).map((s, k) => ({ ...s, label: `Step ${k + 1 + lead.length} · ${s.base}` }))];
}
const leadOf = (it: RunItem) => (it.story && lessonOfItem(it).story ? 1 : 0);

/** Steps for the current problem, derived fresh from its answer model each time. */
export function stepsOf(s: PracticeSession): RuntimeStep[] {
  const it = currentItem(s), full = fullSteps(it);
  if (!s.collapsed) return full;
  const lead = leadOf(it), model = lessonOfItem(it).answers(problemOf(it));
  return [...full.slice(0, lead), finalStep(finalPartsOf(model.steps, model.finalParts))];
}

export const currentStep = (s: PracticeSession): RuntimeStep | undefined => (s.solved ? undefined : stepsOf(s)[s.step]);

/** how many fresh draws a lesson gets to find a problem the run hasn't had yet */
const FRESH_TRIES = 24;

/**
 * One problem from a lesson. With `seen` (the run's problems so far), it is one the run hasn't had: some lessons have
 * only a handful of different problems at a level (G 2026-10-07: "I did the same problem 4 times in a row"), so the
 * lesson draws again until it finds a new one. When every problem it can make at this level is used up, it still never
 * gives the one just before.
 */
export function makeItem(lesson: AnyLesson, index: number, rng: Rng, seen: readonly RunItem[] = []): RunItem {
  const used = new Set(seen.filter(x => x.lessonId === lesson.id).map(x => JSON.stringify(x.problem)));
  const last = seen.length ? JSON.stringify(seen[seen.length - 1]!.problem) : null;
  let problem = lesson.generate(rng, index), fallback: unknown = null;
  for (let k = 0; k < FRESH_TRIES && used.has(JSON.stringify(problem)); k++) {
    if (fallback == null && JSON.stringify(problem) !== last) fallback = problem;
    problem = lesson.generate(rng, index);
  }
  if (used.has(JSON.stringify(problem)) && fallback != null) problem = fallback;
  const it: RunItem = { lessonId: lesson.id, problem };
  if (lesson.story && index % 3 === 2) it.story = true;
  return it;
}

/** n problems, each one the run hasn't had yet where the lesson can make one */
function freshItems(n: number, make: (k: number, seen: RunItem[]) => RunItem): RunItem[] {
  const out: RunItem[] = [];
  for (let k = 0; k < n; k++) out.push(make(k, out));
  return out;
}

/** a shuffle that never puts the same problem twice in a row when it can help it */
function spread(items: RunItem[], rng: Rng): RunItem[] {
  const out = rng.shuffle(items), same = (a?: RunItem, b?: RunItem) => !!a && !!b && a.lessonId === b.lessonId && JSON.stringify(a.problem) === JSON.stringify(b.problem);
  for (let i = 1; i < out.length; i++) if (same(out[i], out[i - 1])) {
    const j = out.findIndex((x, k) => k > i && !same(x, out[i - 1]) && !same(out[i], out[k - 1]) && !same(out[i], out[k + 1]));
    if (j > 0) [out[i], out[j]] = [out[j]!, out[i]!];
  }
  return out;
}

// ---------------------------------------------------------------- starting

export function startPractice(lessonId: string, progress: Progress, deps: Deps): PracticeSession {
  const lesson = requireLesson(lessonId);
  const n = lessonLength(lastScore(progress, lessonId));
  const items = freshItems(n, (i, seen) => makeItem(lesson, i, deps.rng, seen));
  const startTier = tierFor(lastScore(progress, lessonId));
  return newRun({ mode: "practice", key: lesson.id, title: lesson.title, items, startTier }, progress, deps);
}

export const testKey = (g: number, unit?: string) => (unit ? `unit:${g}:${unit}` : `grade:${g}`);

/** A unit test (up to 10 problems) or a grade check-up (up to 12), mixed from the lessons, no hints, one try per step. */
export function startTest(key: string, progress: Progress, deps: Deps): PracticeSession {
  const [kind, gs, unit] = key.split(":"), g = Number(gs);
  if (kind === "place") return startPlacement(g, progress, deps);
  const list = kind === "unit" ? lessonsInGrade(g).filter(l => (l.unit || NO_UNIT) === unit) : lessonsInGrade(g);
  if (!list.length) throw new Error(`no lessons for test ${key}`);
  const n = Math.min(kind === "unit" ? 10 : 12, Math.max(6, list.length * 2));
  const order = deps.rng.shuffle(list);
  const items = spread(freshItems(n, (k, seen) => makeItem(order[k % order.length]!, k, deps.rng, seen)), deps.rng);
  const title = kind === "unit" ? `${unit} test` : `${gradeOf(g).name} check-up`;
  return newRun({ mode: "test", key, title, items, startTier: 0, hintsLeft: 0 }, progress, deps);
}

export const placeKey = (g: number) => `place:${g}`;

/** The grades a placement around grade g looks at: two below, g itself and one above, where lessons exist. */
export const placementGrades = (g: number) =>
  [g - 2, g - 1, g, g + 1].filter((x, i, a) => x >= 0 && x <= 12 && a.indexOf(x) === i && lessonsInGrade(x).length > 0);

/**
 * Find my level: three problems from each grade around the one picked, easiest grade first, no hints and one try per
 * step, like a check-up. The results screen reads where the right answers stop.
 */
function startPlacement(g: number, progress: Progress, deps: Deps): PracticeSession {
  const grades = placementGrades(g);
  if (!grades.length) throw new Error(`no lessons around grade ${g}`);
  const items = grades.flatMap(x => deps.rng.shuffle(lessonsInGrade(x)).concat(lessonsInGrade(x)).slice(0, 3).map((l, k) => makeItem(l, 2 + k, deps.rng)));
  return newRun({ mode: "test", key: placeKey(g), title: FIND_MY_LEVEL, items, startTier: 0, hintsLeft: 0 }, progress, deps);
}

/**
 * Where a placement lands. A problem counts as right when every step was right first time, or with one slip on a long
 * problem (4 steps or more), and never after "Show me". A grade passes with 2 of its 3 right. The child starts in the
 * highest grade passed before the first one that isn't, never more than one below the grade they picked (a bigger
 * drop needs more than three problems to be sure) and never above the grades tested: a clean top grade offers
 * "Try the next grade" instead.
 */
export function placementResult(probs: { lessonId: string; wrong: number; shown: number; work?: unknown[] }[], picked?: number): { grade: number; next: number | null; rows: { grade: number; right: number; total: number }[] } {
  const rows: { grade: number; right: number; total: number }[] = [];
  for (const p of probs) {
    const g = lessonById(p.lessonId)?.grade;
    if (g == null) continue;
    let r = rows.find(x => x.grade === g);
    if (!r) rows.push(r = { grade: g, right: 0, total: 0 });
    r.total++;
    if (!p.shown && (p.wrong === 0 || (p.wrong === 1 && (p.work?.length ?? 0) >= 4))) r.right++;
  }
  rows.sort((a, b) => a.grade - b.grade);
  let grade = rows[0]?.grade ?? 0;
  for (const r of rows) {
    if (r.right * 3 < r.total * 2) break;
    grade = r.grade;
  }
  if (picked != null) grade = Math.max(grade, Math.min(picked - 1, rows.at(-1)?.grade ?? grade));
  const top = rows.at(-1);
  const next = top && top.grade === grade && top.right === top.total && grade < 12 ? grade + 1 : null;
  return { grade, next, rows };
}

/** Lessons already scored, weighted to low scores and long gaps since last practice. */
export function reviewPool(progress: Progress, now: number): { lesson: AnyLesson; weight: number }[] {
  return LESSONS.filter(l => progress.scores[l.id]).map(l => {
    const sc = progress.scores[l.id]!, days = (now - (progress.seen[l.id] || sc.date || now)) / 864e5;
    return { lesson: l, weight: (5 - sc.last) * (1 + days / 3) };
  });
}

export const canReview = (progress: Progress, now: number) => reviewPool(progress, now).length >= 2;

/** Today's review: up to 8 problems from scored lessons, at most 2 from each (4 when there are only a few lessons). */
export function startReview(progress: Progress, deps: Deps): PracticeSession {
  const pool = reviewPool(progress, deps.now).map(x => ({ ...x, n: 0 }));
  const each = pool.length >= 4 ? 2 : 4, n = Math.min(8, pool.length * each), items: RunItem[] = [];
  while (items.length < n) {
    const live = pool.filter(x => x.n < each), tot = live.reduce((a, x) => a + x.weight, 0);
    let r = deps.rng.next() * tot, k = 0;
    while (k < live.length - 1 && r > live[k]!.weight) { r -= live[k]!.weight; k++; }
    live[k]!.n++;
    items.push(makeItem(live[k]!.lesson, deps.rng.int(1, 8), deps.rng, items));
  }
  return newRun({ mode: "review", key: "review", title: TODAYS_REVIEW, items: spread(items, deps.rng), startTier: 0, hintsLeft: 4 }, progress, deps);
}

function newRun(o: { mode: PracticeSession["mode"]; key: string; title: string; items: RunItem[]; startTier: Tier; hintsLeft?: number },
  progress: Progress, deps: Deps): PracticeSession {
  const s: PracticeSession = {
    mode: o.mode, key: o.key, title: o.title, items: o.items, i: 0, step: 0, work: [],
    collapsed: false, skip: true, skipThis: true, tier: 0, startTier: o.startTier,
    values: {}, active: null, pick: null, misses: 0, hinted: false,
    hintsLeft: o.hintsLeft ?? hintBudget(o.items.length), lastTry: 0, stepT0: deps.now,
    prob: { wrong: 0, hints: 0, shown: 0, t0: deps.now },
    pts: 0, maxPts: 0, clean: 0, extra: 0, xpEarned: 0, hints: 0, shown: 0,
    mistakes: [], probs: [], feedback: null, fx: null, t0: deps.now, solved: false,
  };
  return startProblem(s, progress, deps);
}

function startProblem(s: PracticeSession, progress: Progress, deps: Deps): PracticeSession {
  const tier = isTest(s) ? 0 : tierFor(lastScore(progress, currentItem(s).lessonId));
  const next: PracticeSession = {
    ...s, step: 0, work: [], solved: false, collapsed: false, skipThis: true, tier,
    prob: { wrong: 0, hints: 0, shown: 0, t0: deps.now },
  };
  return loadStep(next, deps);
}

/** Prepare the current step: collapse to a final answer when allowed, offer plan choices at tier 1, clear the boxes. */
function loadStep(s: PracticeSession, deps: Deps): PracticeSession {
  let next = { ...s };
  const it = currentItem(next), lead = leadOf(it), full = fullSteps(it);
  if (!next.collapsed && next.skip && next.skipThis && canSkip({ test: isTest(next), tier: next.tier }) && next.step === lead && full.length - lead > 1) {
    next = { ...next, collapsed: true };
  }
  next = { ...next, values: {}, misses: 0, hinted: false, lastTry: 0, stepT0: deps.now, feedback: null };
  next.pick = planFor(next, deps.rng);
  const step = currentStep(next);
  next.active = next.pick || !step || step.choices ? null : answerIds(step.slots)[0] ?? null;
  return next;
}

// ---------------------------------------------------------------- plan the step (tier 1)

function planFor(s: PracticeSession, rng: Rng): PracticeSession["pick"] {
  const steps = stepsOf(s), here = steps[s.step];
  const later = steps.slice(s.step + 1).filter(t => !t.choices);
  if (s.tier !== 1 || !here || here.choices || here.skipped || !later.length) return null;
  const right = here.base, options = [right];
  for (const t of rng.shuffle(later)) if (options.length < 3 && !options.includes(t.base)) options.push(t.base);
  if (options.length < 3) {
    const lesson = lessonOfItem(currentItem(s));
    for (const m of rng.shuffle(LESSONS.filter(m => m.grade === lesson.grade && m.unit === lesson.unit && m.id !== lesson.id))) {
      if (options.length >= 3) break;
      try {
        const first = m.answers(m.generate(rng, 1)).steps[0];
        if (first && !options.includes(first.label)) options.push(first.label);
      } catch { /* a sister lesson that can't make a problem just isn't offered */ }
    }
  }
  return { options: rng.shuffle(options), right, misses: 0 };
}

export function pickPlan(s: PracticeSession, index: number): PracticeSession {
  const pk = s.pick, here = currentStep(s);
  if (!pk || !here) return s;
  const choice = pk.options[index];
  const firstSlot = answerIds(here.slots)[0] ?? null;
  if (choice === pk.right) {
    return { ...s, pick: null, active: firstSlot, fx: "line", feedback: { type: "good", strong: "Good plan.", text: "Now do it." } };
  }
  const misses = pk.misses + 1;
  const mistake: Mistake = {
    n: s.i + 1, step: s.step + 1, label: "Planning", lessonId: currentItem(s).lessonId, typed: choice ?? "", want: pk.right,
    kind: CATEGORIES.plan[0], cat: "plan", msg: CATEGORIES.plan[1], rushed: false,
  };
  if (misses >= 2) {
    return { ...s, pick: null, active: firstSlot, fx: "shake", mistakes: [...s.mistakes, mistake],
      feedback: { type: "hint", text: `The next step is **${pk.right}**. Now do it.` } };
  }
  const isLater = stepsOf(s).slice(s.step + 1).some(t => t.base === choice);
  return { ...s, pick: { ...pk, misses }, fx: "shake", mistakes: [...s.mistakes, mistake],
    feedback: { type: "bad", strong: "Look again.", text: isLater ? "That step comes later. What has to happen first?" : "That step isn't part of this problem." } };
}

// ---------------------------------------------------------------- typing

export function focusSlot(s: PracticeSession, id: string): PracticeSession {
  return { ...s, active: id };
}

/** Number pad: digits, "−", ".", "back", and "next" (move to the next box). */
export function pressKey(s: PracticeSession, key: string): PracticeSession {
  const step = currentStep(s);
  if (!step || s.pick || step.choices || !s.active) return s;
  const ids = answerIds(step.slots);
  if (key === "next") return { ...s, active: ids[(ids.indexOf(s.active) + 1) % ids.length] ?? s.active };
  const cur = s.values[s.active] ?? "";
  let v = cur;
  if (key === "back") v = cur.slice(0, -1);
  else if (key === "−") v = cur.startsWith("−") ? cur.slice(1) : "−" + cur;
  else if (key === ".") v = cur.includes(".") ? cur : (cur === "" || cur === "−" ? cur + "0." : cur + ".");
  // up to 6 digits, and a lone leading zero is replaced, as in the current app
  else if (/^\d$/.test(key)) v = cur.replace(/[−.]/g, "").length >= 6 ? cur : (cur === "0" ? "" : cur === "−0" ? "−" : cur) + key;
  else return s;
  return { ...s, values: { ...s.values, [s.active]: v } };
}

/** Tap-to-answer steps check right away, like the current app. */
export function choose(s: PracticeSession, index: number, progress: Progress, deps: Deps): PracticeSession {
  const step = currentStep(s);
  if (!step?.choices) return s;
  return check({ ...s, values: { c: String(index) } }, progress, deps);
}

// ---------------------------------------------------------------- checking

/** How a set of answers reads in reports: a choice's words, a fraction, or numbers. */
function typedText(step: RuntimeStep, values: Record<string, number | null>): string {
  if (step.choices && values.c != null) return step.choices[values.c] ?? String(values.c);
  const keys = Object.keys(values);
  if (keys.length === 2 && values.n != null && values.d != null) {
    return values.d === 1 ? formatNumber(values.n) : `${formatNumber(values.n)}/${formatNumber(values.d)}`;
  }
  return Object.values(values).filter((x): x is number => x != null).map(formatNumber).join(", ");
}

export function check(s: PracticeSession, progress: Progress, deps: Deps): PracticeSession {
  const step = currentStep(s);
  if (!step) return s;
  if (s.pick) return { ...s, fx: "feedback", feedback: { type: "hint", text: "First pick the step that comes next." } };
  const ids = step.choices ? ["c"] : answerIds(step.slots);
  const values = Object.fromEntries(ids.map(id => [id, parseNumber(s.values[id])]));
  if (Object.values(values).every(x => x == null)) {
    return { ...s, fx: "feedback", feedback: { type: "hint", text: "Tap a box, then type your answer on the number pad." } };
  }
  const r = checkStep(step, values);
  if (r.ok) return pass(s, false, progress, deps);
  if (r.soft) return { ...s, fx: "feedback", feedback: { type: "hint", text: r.message } };

  const rushed = s.misses >= 1 && deps.now - s.lastTry < RUSHED_MS;
  const expected = expectedValues(step);
  const earlier = stepsOf(s).slice(0, s.step).flatMap(t => Object.values(expectedValues(t)));
  const cat = r.generic ? diagnose(expected, values, earlier) : "concept";
  const mistake: Mistake = {
    n: s.i + 1, step: s.step + 1, label: step.base, lessonId: currentItem(s).lessonId,
    typed: typedText(step, values), want: typedText(step, expected),
    kind: cat === "concept" ? r.kind : CATEGORIES[cat][0], cat, msg: cat === "concept" ? r.message : CATEGORIES[cat][1], rushed,
  };
  let next: PracticeSession = {
    ...s, lastTry: deps.now, misses: s.misses + 1, prob: { ...s.prob, wrong: s.prob.wrong + 1 }, fx: "shake",
    mistakes: [...s.mistakes, mistake],
  };

  if (step.skipped) { // the shortcut missed: do this one the long way
    next = loadStep({ ...next, skipThis: false, collapsed: false, maxPts: next.maxPts + 1, step: leadOf(currentItem(next)) }, deps);
    return { ...next, fx: "shake", feedback: { type: "bad", strong: "Look again.", text: "This one needs the steps. Here they are." } };
  }
  if (isTest(next)) {
    const shownValues = Object.fromEntries(Object.entries(expected).map(([k, v]) => [k, formatNumber(v)]));
    const after = pass({ ...next, values: shownValues }, true, progress, deps);
    return { ...after, feedback: { type: "hint", text: `Incorrect. The answer was **${typedText(step, expected)}**.${currentStep(after) ? " Keep going." : ""}` } };
  }
  const band = bandOfSession(next);
  const msg = cat === "concept" ? r.message
    : SAY[cat] ?? `${nudge(expected, values, band)} ${next.hinted ? step.hint : `Read the step again${next.hintsLeft ? ", or tap the light bulb for a hint" : ""}.`}`.trim();
  const lines: string[] = [];
  if (rushed) lines.push("Slow down a little and read the step again.");
  if (canShowMe({ test: false, misses: next.misses, hinted: next.hinted })) lines.push("Stuck? Tap **Show me**.");
  return { ...next, feedback: { type: "bad", strong: "Look again.", text: msg, lines } };
}

/** Hints are limited: about one for every two problems, and only after a first try. */
export function hint(s: PracticeSession, deps: Deps): PracticeSession {
  const step = currentStep(s);
  if (!step || isTest(s)) return s;
  if (s.hinted) return { ...s, fx: "feedback", feedback: { type: "hint", strong: "Hint:", text: step.hint, left: s.hintsLeft } };
  // the last hint says so kindly (UI notes preview)
  if (!s.hintsLeft) return { ...s, fx: "feedback", feedback: { type: "hint", text: "No hints left in this lesson. You can do it.", lines: showMeAvailable(s) ? ["Stuck? Tap **Show me**."] : [] } };
  if (!s.misses && deps.now - s.stepT0 < HINT_WAIT_MS) return { ...s, fx: "feedback", feedback: { type: "hint", text: "Try it once first. Then the hint opens." } };
  return {
    ...s, hinted: true, hintsLeft: s.hintsLeft - 1, hints: s.hints + 1, prob: { ...s.prob, hints: s.prob.hints + 1 }, fx: "feedback",
    feedback: { type: "hint", strong: "Hint:", text: step.hint, left: s.hintsLeft - 1 },
  };
}

export const showMeAvailable = (s: PracticeSession) => canShowMe({ test: isTest(s), misses: s.misses, hinted: s.hinted });
export const skipAvailable = (s: PracticeSession) => canSkip({ test: isTest(s), tier: s.tier });

export function showMe(s: PracticeSession, progress: Progress, deps: Deps): PracticeSession {
  const step = currentStep(s);
  if (!step || !showMeAvailable(s)) return s;
  const values = Object.fromEntries(Object.entries(expectedValues(step)).map(([k, v]) => [k, formatNumber(v)]));
  return pass({ ...s, values, shown: s.shown + 1, prob: { ...s.prob, shown: s.prob.shown + 1 } }, true, progress, deps);
}

/** "Final answer only" ↔ "Show steps", at the top help tier. Applies from the start of the problem. */
export function toggleSkip(s: PracticeSession, deps: Deps): PracticeSession {
  if (!skipAvailable(s)) return s;
  const skip = !s.skip;
  return loadStep({ ...s, skip, skipThis: true, collapsed: false, step: 0, work: [] }, deps);
}

function pass(s: PracticeSession, shown: boolean, progress: Progress, deps: Deps): PracticeSession {
  const step = currentStep(s)!;
  const steps = stepsOf(s);
  const band = bandOfSession(s);
  let next: PracticeSession = {
    ...s,
    pts: s.pts + stepPoints({ shown, test: isTest(s), misses: s.misses, hinted: s.hinted }),
    maxPts: s.maxPts + 1,
    work: [...s.work, { math: step.work, shown }],
    step: s.step + 1,
    fx: "line",
  };
  if (next.step < steps.length) {
    const praise = deps.rng.pick(PRAISE[band]);
    next = loadStep(next, deps);
    return { ...next, feedback: shown ? { type: "hint", strong: `Here's how: ${step.explain}` } : { type: "good", strong: praise } };
  }

  // the problem is finished
  const pr = next.prob, clean = !pr.wrong && !pr.hints && !pr.shown;
  const xp = problemXp({ test: isTest(next), ...pr });
  const it = currentItem(next);
  next = {
    ...next, solved: true, pick: null, active: null, done: [...(next.done ?? []), next.i],
    xpEarned: next.xpEarned + xp, clean: next.clean + (clean ? 1 : 0),
    probs: [...next.probs, { lessonId: it.lessonId, problem: it.problem, ...(it.story ? { story: true } : {}), work: next.work, hints: pr.hints, wrong: pr.wrong, shown: pr.shown, ms: deps.now - pr.t0 }],
  };
  const lines: string[] = [];
  if (!isTest(next) && (pr.wrong || pr.shown) && next.items.length < MAX_LESSON_LENGTH) {
    next = { ...next, items: [...next.items, makeItem(lessonOfItem(it), next.items.length, deps.rng, next.items)], extra: next.extra + 1 };
    lines.push("One more like this is coming up, for practice.");
  }
  void progress;
  if (isTest(next)) return { ...next, feedback: { type: "good", strong: `Problem done. +${xp} XP` } };
  if (shown) return { ...next, feedback: { type: "hint", text: `Here's how: ${step.explain}`, lines: [`**+${xp} XP.** That one was tricky, and you finished it.`, ...lines] } };
  if (band === "little") return { ...next, feedback: { type: "good", pop: "big", strong: `You solved it! +${xp} XP`, lines } };
  if (band === "middle" || band === "high") return { ...next, feedback: { type: "good", strong: `Solved. +${xp} XP`, text: clean ? "No mistakes." : "", lines } };
  return { ...next, feedback: { type: "good", pop: "star", strong: `Solved! +${xp} XP`, text: clean ? "No mistakes." : "", lines } };
}

// ---------------------------------------------------------------- moving on and finishing

/** the problems still to do, after this one, in order round the set */
const openAfter = (s: PracticeSession): number[] => {
  const done = new Set(s.done ?? []), out: number[] = [];
  for (let k = 1; k < s.items.length; k++) { const j = (s.i + k) % s.items.length; if (!done.has(j) && j !== s.i) out.push(j); }
  return out;
};
/** nothing is left but this problem (a set can be done in any order, so it isn't always the last index) */
export const isLastProblem = (s: PracticeSession) => openAfter(s).length === 0;

/** Next problem still to do, or null when the run is over (then call finishRun). */
export function nextProblem(s: PracticeSession, progress: Progress, deps: Deps): PracticeSession | null {
  if (!s.solved) return s;
  const next = openAfter(s)[0];
  if (next == null) return null;
  return startProblem({ ...s, i: next }, progress, deps);
}

/**
 * The problem picker (G 2026-10-08: "see how many questions they have on a test and pick and choose which ones they'd
 * like to answer first"). You can move to any problem you haven't finished before you start answering this one, or
 * once it's solved; a problem you've begun answering is finished first, so a test's one try per step can't be undone.
 */
export const canPick = (s: PracticeSession, index: number): boolean =>
  index >= 0 && index < s.items.length && index !== s.i && !(s.done ?? []).includes(index) && (s.solved || !started(s));
const started = (s: PracticeSession) => s.step > 0 || s.prob.wrong > 0 || s.prob.hints > 0 || s.prob.shown > 0 || s.work.length > 0;
export function goToProblem(s: PracticeSession, index: number, progress: Progress, deps: Deps): PracticeSession {
  if (!canPick(s, index)) return s;
  return startProblem({ ...s, i: index }, progress, deps);
}

export function finishRun(s: PracticeSession, progress: Progress, now: number): { progress: Progress; report: SessionReport } {
  const pct = s.maxPts ? s.pts / s.maxPts : 0, level = levelOf(pct);
  const report: SessionReport = {
    key: s.key, mode: s.mode, title: s.title, date: now, ms: now - s.t0, total: s.items.length, extra: s.extra, clean: s.clean,
    hints: s.hints, shown: s.shown, pct, level, xp: s.xpEarned, probs: s.probs, mistakes: s.mistakes,
  };
  const p: Progress = JSON.parse(JSON.stringify(progress)); // plain data; works on older iPads too
  p.xp += s.xpEarned;
  const grade = s.mode === "test" ? Number(s.key.split(":")[1]) : s.mode === "review" ? (p.grade ?? requireLesson(s.probs.at(-1)?.lessonId ?? s.items[0]!.lessonId).grade) : requireLesson(s.key).grade;
  p.gxp[grade] = (p.gxp[grade] ?? 0) + s.xpEarned;
  const today = new Date(now).toDateString(), yesterday = new Date(now - 864e5).toDateString();
  if (p.last !== today) p.streak = p.last === yesterday ? p.streak + 1 : 1;
  p.last = today;
  const book = s.mode === "test" ? p.tests : s.mode === "practice" ? p.scores : null;
  if (book) {
    const old = book[s.key];
    book[s.key] = { last: level, best: Math.max(level, old?.best ?? 0) as typeof level, pct, date: now,
      mastered: !!old?.mastered || (level === 4 && s.startTier === 2) };
  }
  if (s.mode === "practice") { p.done += 1; p.lessons[s.key] = (p.lessons[s.key] ?? 0) + 1; }
  if (s.mode === "review") p.reviews[today] = level;
  for (const it of s.items) p.seen[it.lessonId] = now;
  const cats: Record<string, number> = {};
  for (const m of s.mistakes) cats[m.kind] = (cats[m.kind] ?? 0) + 1;
  p.log = [{ key: s.key, mode: s.mode, title: s.title, date: now, level, total: report.total, hints: report.hints, shown: report.shown, cats,
    rushed: s.mistakes.filter(m => m.rushed).length }, ...p.log].slice(0, 60);
  p.run = null;
  return { progress: p, report };
}

/** A saved run can only resume if every lesson in it still exists and every stored problem is still valid. */
export function canResume(run: PracticeSession | null): run is PracticeSession {
  if (!run || !Array.isArray(run.items) || !run.items.length) return false;
  try {
    return run.items.every(it => lessonById(it.lessonId) && lessonById(it.lessonId)!.restore(it.problem) != null);
  } catch {
    return false;
  }
}

/** "Build up first": the lesson underneath, suggested after a 0 or 1. */
export function backFor(id: string): AnyLesson | null {
  const l = lessonById(id);
  if (!l) return null;
  if (l.pre && lessonById(l.pre)) return lessonById(l.pre)!;
  const g = lessonsInGrade(l.grade), k = g.indexOf(l);
  return k > 0 && g[k - 1]!.unit === l.unit ? g[k - 1]! : null;
}

/** Plain text for a math line in the current step, for screen readers and tests. */
export const stepText = (step: RuntimeStep) => toPlainText(step.prompt);
