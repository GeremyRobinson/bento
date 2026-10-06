import { finishSprint, type SprintAnswer } from "../engine/facts/mastery";
import { applySettings, readSettings, type Settings } from "./settings";
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { createRng, randomSeed, type Rng } from "../curriculum/generators/rng";
import { emptyProgress, type Progress } from "../engine/mastery/progress";
import { canReview, finishRun, startPractice, startReview, startTest, type Deps } from "../engine/session/practice";
import type { PracticeSession, SessionReport } from "../engine/session/types";
import { makeBackup, readBackup } from "../persistence/backup";
import { loadAll } from "../persistence/load";
import type { Store } from "../persistence/db";
import { parseRoute, routeHash, type Route } from "./routes";
import { withTransition, type Dir } from "./transition";

export interface AppData {
  progress: Progress;
  reports: Record<string, SessionReport>;
}

interface AppState extends AppData {
  route: Route;
  /** the report of the run that just finished, for the results screen */
  lastReport: SessionReport | null;
  sheetOpen: boolean;
  /** move to a screen; dir slides the cross-fade forward or back */
  go(route: Route, dir?: Dir): void;
  /** one step up to a parent page, through history when that is where you came from (never adds a history step) */
  back(route: Route): void;
  openSheet(open: boolean): void;
  /** pick a grade (from the sheet or the landing page); the landing page then gives way to home */
  chooseGrade(grade: number): void;
  startLesson(lessonId: string): void;
  /** a unit test ("unit:5:Fractions") or a grade check-up ("grade:5") */
  startTest(key: string): void;
  /** today's review, mixed from lessons already scored */
  startReview(): void;
  canReview(): boolean;
  /** apply one engine step to the run in progress */
  act(step: (s: PracticeSession, progress: Progress, deps: Deps) => PracticeSession | null): void;
  finish(): void;
  /** ends a test, check-up or review without scoring it, and goes home */
  /** ends the run in progress and forgets it; `stay` keeps the current screen (quitting from the Resume pill) */
  quit(opts?: { stay?: boolean }): void;
  /** save a finished fact sprint */
  saveSprint(table: string, answers: SprintAnswer[]): void;
  /** change accessibility and comfort settings */
  setSettings(patch: Partial<Settings>): void;
  exportBackup(): string;
  importBackup(json: string): Promise<void>;
  deps(): Deps;
}

const Ctx = createContext<AppState | null>(null);

export function useApp(): AppState {
  const v = useContext(Ctx);
  if (!v) throw new Error("useApp outside AppProvider");
  return v;
}

const SAVE_DELAY_MS = 250;

/** First time on this device (nothing saved and no grade picked): the landing page instead of home. */
export const firstRoute = (p: Progress, r: Route): Route => (!p.chosen && !p.xp && !p.done && r.name === "home" ? { name: "welcome" } : r);

/**
 * Loads saved data (IndexedDB, or the current app's localStorage save on the first run),
 * holds it in React state, and writes changes back shortly after they happen.
 * Tests pass `initial` and `now`/`rng` to skip storage and control time and randomness.
 */
export function AppProvider(props: {
  children: ReactNode; initial?: AppData; store?: Store | null; now?: () => number; rng?: Rng;
  /** called after every change of the saved data (tests use it to see the run in progress) */
  onData?: (data: AppData) => void;
}) {
  const [data, setData] = useState<AppData | null>(props.initial ?? null);
  const { onData } = props;
  useEffect(() => { if (data) onData?.(data); }, [data, onData]);
  // settings live on <html>, so every screen and the transitions follow them
  useEffect(() => { if (data) applySettings(readSettings(data.progress.settings)); }, [data?.progress.settings]); // eslint-disable-line react-hooks/exhaustive-deps
  const [route, setRoute] = useState<Route>(() => {
    const r = parseRoute(typeof location === "undefined" ? "" : location.hash);
    return props.initial ? firstRoute(props.initial.progress, r) : r;
  });
  const [lastReport, setLastReport] = useState<SessionReport | null>(null);
  const [sheetOpen, openSheet] = useState(false);
  const store = useRef<Store | null>(props.store ?? null);
  const rng = useRef<Rng>(props.rng ?? createRng(randomSeed()));
  const now = props.now ?? Date.now;

  useEffect(() => {
    if (props.initial) return;
    let live = true;
    loadAll().catch(() => ({ store: null, ...emptyData() })).then(r => {
      if (!live) return;
      store.current = r.store;
      setData({ progress: r.progress, reports: r.reports });
      setRoute(rt => firstRoute(r.progress, rt));
    });
    return () => { live = false; };
  }, [props.initial]);

  // save shortly after each change, and right away when the page is hidden
  const pending = useRef<Progress | null>(null);
  const flush = useCallback(() => {
    const p = pending.current;
    pending.current = null;
    if (p && store.current) void store.current.putProgress(p).catch(() => {});
  }, []);
  useEffect(() => {
    if (!data) return;
    pending.current = data.progress;
    const t = setTimeout(flush, SAVE_DELAY_MS);
    return () => clearTimeout(t);
  }, [data?.progress, flush]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => {
    const onHide = () => flush();
    addEventListener("pagehide", onHide);
    document.addEventListener("visibilitychange", onHide);
    return () => { removeEventListener("pagehide", onHide); document.removeEventListener("visibilitychange", onHide); };
  }, [flush]);

  const caughtUp = useRef<string | null>(null);
  useEffect(() => {
    // a back() already showed this page; history only caught up with it
    const onHash = () => { if (caughtUp.current === location.hash) { caughtUp.current = null; return; } withTransition(() => setRoute(parseRoute(location.hash)), "back"); };
    addEventListener("hashchange", onHash);
    return () => removeEventListener("hashchange", onHash);
  }, []);

  const show = useCallback((r: Route) => {
    setRoute(r);
    const h = routeHash(r);
    // sandboxed frames can refuse history changes; the app keeps working from its own state
    // each entry remembers the page under it, so back can return to it instead of adding a step; an open overlay's
    // entry (the contents) is replaced by the page you open from it, so back from there skips the overlay
    try {
      if (location.hash !== h) {
        const entry = { prev: location.hash };
        if ((history.state as { overlay?: boolean } | null)?.overlay) history.replaceState({ prev: (history.state as { prev?: string }).prev ?? null }, "", h);
        else history.pushState(entry, "", h);
      }
    } catch { /* ignore */ }
    try { scrollTo(0, 0); } catch { /* ignore */ }
  }, []);
  const go = useCallback((r: Route, dir: Dir = "") => withTransition(() => show(r), dir), [show]);
  // one step up (the island's < and Escape): back through history when the page before is the parent, else the
  // parent replaces this page, so back never adds a step and browser back never returns you to where you just were
  const back = useCallback((r: Route) => {
    const h = routeHash(r);
    let viaHistory = false;
    try { viaHistory = (history.state as { prev?: string } | null)?.prev === h; } catch { /* ignore */ }
    withTransition(() => {
      setRoute(r);
      try {
        if (viaHistory) { caughtUp.current = h; history.back(); }
        else history.replaceState({ prev: null }, "", h);
      } catch { /* ignore */ }
      try { scrollTo(0, 0); } catch { /* ignore */ }
    }, "back");
  }, []);

  const deps = useCallback((): Deps => ({ now: now(), rng: rng.current }), [now]);

  const setProgress = (f: (p: Progress) => Progress) => setData(d => (d ? { ...d, progress: f(d.progress) } : d));

  const value = useMemo<AppState | null>(() => {
    if (!data) return null;
    // after a reload the results screen shows the newest saved report
    const latest = lastReport ?? (data.progress.log[0] ? data.reports[data.progress.log[0].key] ?? null : null);
    return {
      ...data, route, lastReport: latest, sheetOpen, go, back, openSheet, deps,
      chooseGrade: g => withTransition(() => {
        // a grade opens on its book: the year's cover, today's plan and every chapter
        setProgress(p => ({ ...p, grade: g, chosen: true }));
        openSheet(false);
        if (route.name !== "home") show({ name: "home" });
      }),
      startLesson: id => withTransition(() => {
        setProgress(p => ({ ...p, run: startPractice(id, p, deps()) }));
        show({ name: "practice" });
      }),
      startTest: key => withTransition(() => {
        setProgress(p => ({ ...p, run: startTest(key, p, deps()) }));
        show({ name: "practice" });
      }),
      startReview: () => {
        if (!canReview(data.progress, now())) return;
        withTransition(() => {
          setProgress(p => ({ ...p, run: startReview(p, deps()) }));
          show({ name: "practice" });
        });
      },
      canReview: () => canReview(data.progress, now()),
      act: step => setProgress(p => {
        if (!p.run) return p;
        const next = step(p.run, p, deps());
        return next ? { ...p, run: next } : p;
      }),
      quit: opts => opts?.stay ? setProgress(p => ({ ...p, run: null }))
        : withTransition(() => { setProgress(p => ({ ...p, run: null })); show({ name: "home" }); }, "back"),
      finish: () => {
        const run = data.progress.run;
        if (!run) return;
        const r = finishRun(run, data.progress, now());
        void store.current?.putReport(r.report).catch(() => {});
        withTransition(() => {
          setData(d => (d ? { progress: r.progress, reports: { ...d.reports, [r.report.key]: r.report } } : d));
          setLastReport(r.report);
          show({ name: "results" });
        });
      },
      saveSprint: (table, answers) => { if (answers.length) setProgress(p => finishSprint(p, table, p.grade, answers, now())); },
      setSettings: patch => setProgress(p => ({ ...p, settings: { ...readSettings(p.settings), ...patch } })),
      exportBackup: () => JSON.stringify(makeBackup(data.progress, data.reports, now())),
      importBackup: async json => {
        const b = readBackup(json);
        await store.current?.replaceAll(b.progress, b.reports);
        setData({ progress: b.progress, reports: b.reports });
      },
    };
  }, [data, route, lastReport, sheetOpen, go, back, show, deps, now]); // eslint-disable-line react-hooks/exhaustive-deps

  if (!value) return null;
  return <Ctx.Provider value={value}>{props.children}</Ctx.Provider>;
}

export const emptyData = (): AppData => ({ progress: emptyProgress(), reports: {} });
