import { useEffect, useState, type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import type { Route } from "../app/routes";
import { doneCount, entriesInGrade, entryById, unitsInGrade } from "../app/curriculum";
import { readAloudOn, readSettings } from "../app/settings";
import { reduceMotion } from "../app/transition";
import { gradeOf, inkOf } from "../curriculum/grades";
import { lessonById } from "../curriculum/registry";
import { currentItem, currentStep, lessonOfItem, problemOf } from "../engine/session/practice";
import { problemShape, ProblemLine } from "./practice/ProblemView";
import { upNext } from "../app/today";
import { Contents, type Level } from "./Contents";
import { BentoMark } from "./primitives/BentoMark";
import { MeStack } from "./MeStack";
import { ConfirmStack } from "./ConfirmStack";
import { tableById } from "../engine/facts/tables";
import { Chevron, LockIcon } from "./primitives/icons";
import { CONTENTS, GROWN_UP, NO_UNIT, PRACTICE, REPORT, REVIEW, SETTING, YOUR_BENTO } from "../app/copy";

/** A small cross: quit. */
const CrossIcon = () => (
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" aria-hidden><path d="M7 7l10 10M17 7L7 17" /></svg>
);

/** A simple person: a head and shoulders. */
const MeIcon = () => (
  <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="8.5" r="3.6" /><path d="M5 20c1.2-3.6 4-5.4 7-5.4s5.8 1.8 7 5.4" /></svg>
);

/** Where a lesson sits in its grade's book: its chapter, and which page of that chapter it is. */
export function pageOf(lessonId: string): { grade: number; chapter: string; page: number; pages: number } | null {
  const g = entryById(lessonId)?.grade ?? lessonById(lessonId)?.grade;
  if (g == null) return null;
  const ch = unitsInGrade(g).find(u => u.entries.some(c => c.id === lessonId));
  if (!ch) return { grade: g, chapter: gradeOf(g).name, page: 1, pages: entriesInGrade(g).length };
  return { grade: g, chapter: ch.name, page: ch.entries.findIndex(c => c.id === lessonId) + 1, pages: ch.entries.length };
}

type Place = { kicker: string; title: string; back?: { label: string; to: Route }; lesson?: string; /** says the page stays on this device, in place of the fill */ lock?: boolean };

/** What the island says on each screen: a small line for where you are in the book, and the page you're on. */
function placeOf(route: Route, app: ReturnType<typeof useApp>, grade: number): Place {
  const contents = { label: "contents", to: { name: "home" } as Route };
  const chapterLine = (id: string, extra?: string) => {
    const p = pageOf(id);
    return p ? `${p.chapter === NO_UNIT ? gradeOf(p.grade).name : p.chapter} · ${extra ?? `${p.page} of ${p.pages}`}` : gradeOf(grade).name;
  };
  switch (route.name) {
    case "learn": return { kicker: chapterLine(route.lessonId), title: lessonById(route.lessonId)?.title ?? "Lesson", back: contents, lesson: route.lessonId };
    case "practice": {
      const run = app.progress.run;
      if (!run) return { kicker: gradeOf(grade).name, title: PRACTICE, back: contents };
      if (run.mode !== "practice") return { kicker: run.mode === "test" ? "Test" : REVIEW, title: run.title, back: contents };
      const l = lessonOfItem(currentItem(run));
      return { kicker: chapterLine(l.id, "practice"), title: l.title, back: { label: l.title, to: { name: "learn", lessonId: l.id } }, lesson: l.id };
    }
    case "results": {
      const rep = app.lastReport, l = rep ? lessonById(rep.key) : undefined;
      return { kicker: l ? chapterLine(l.id, "done") : "Done", title: rep?.title ?? "Done", back: contents, lesson: l?.id };
    }
    case "report": {
      const rep = app.reports[route.key], l = lessonById(route.key);
      return l
        ? { kicker: chapterLine(l.id, "report"), title: l.title, back: { label: l.title, to: { name: "learn", lessonId: l.id } }, lesson: l.id }
        : { kicker: GROWN_UP, title: rep?.title ?? REPORT, back: { label: GROWN_UP, to: { name: "parent" } } };
    }
    case "parent": {
      // on a phone a picked pattern is its own screen, and back returns to the list
      const phone = typeof matchMedia !== "undefined" && matchMedia("(max-width: 699px)").matches;
      return { kicker: `Me · ${gradeOf(grade).name}`, title: GROWN_UP, lock: true,
        back: route.pick && phone ? { label: GROWN_UP, to: { name: "parent" } } : { label: "Me", to: { name: "me" } } };
    }
    case "me": return { kicker: "Me", title: YOUR_BENTO, back: contents };
    case "facts": {
      const t = route.table ? tableById(route.table) : undefined;
      return t ? { kicker: "Facts", title: t.name, back: { label: "facts", to: { name: "facts" } } } : { kicker: gradeOf(grade).name, title: "Facts", back: contents };
    }
    default: {
      // on a phone the picked row's detail is its own screen, and back returns to the list
      const phone = typeof matchMedia !== "undefined" && matchMedia("(max-width: 699px)").matches;
      return route.name === "home" && route.pick && phone
        ? { kicker: gradeOf(grade).name, title: route.pick === "today" ? "Today" : lessonById(route.pick)?.title ?? "Lesson", back: { label: "chapters", to: { name: "home" } } }
        : { kicker: homeChapter(route, app, grade), title: gradeOf(grade).name };
    }
  }
}

/** On the book, the small line names the chapter you're in: the picked lesson's, else the one up next. */
function homeChapter(route: Route, app: ReturnType<typeof useApp>, grade: number): string {
  const id = route.name === "home" && route.pick && route.pick !== "today" ? route.pick : upNext(app.progress, grade)?.entry.id;
  const p = id ? pageOf(id) : null;
  return p && p.grade === grade && p.chapter !== NO_UNIT ? p.chapter : CONTENTS;
}

/** "5th grade" with its number in the grade's colour, the way the UI notes preview names the grade. */
function GradeTitle({ grade }: { grade: number }) {
  const g = gradeOf(grade), style = { "--gn": inkOf(g.color), "--gn-d": g.color } as CSSProperties;
  const m = /^(\d+\w*)( grade)$/.exec(g.name);
  return m ? <b><span className="gnum ign" style={style}>{m[1]}</span>{m[2]}</b> : <b><span className="gnum ign" style={style}>{g.name}</span></b>;
}

/** preview and dev builds carry the design sandbox; quick settings is its way in */
const SANDBOX = import.meta.env.MODE === "preview" || import.meta.env.MODE === "development";

/** Sliders: the quick settings. */
const BulbIcon = () => (
  <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    <path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2.1h5c0-.9.4-1.6 1-2.1A6 6 0 0 0 12 3z" />
  </svg>
);

const SettingsIcon = () => (
  <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M4 7h10M18 7h2M4 17h4M12 17h8" /><circle cx="16" cy="7" r="2" /><circle cx="10" cy="17" r="2" /></svg>
);

/** How far along the place is: the page in its chapter on a lesson, the lessons done in the year elsewhere. */
function fillOf(place: Place, app: ReturnType<typeof useApp>, grade: number): number {
  // in practice, the battery is the run: each solved problem ticks it up by its share (practice-spec §5)
  const run = app.progress.run;
  if (app.route.name === "practice" && run) return (run.i + (run.solved ? 1 : 0)) / run.items.length;
  if (place.lesson) { const p = pageOf(place.lesson); if (p) return p.page / p.pages; }
  const all = entriesInGrade(grade);
  return all.length ? doneCount(app.progress, all) / all.length : 0;
}

/**
 * The one way around Bento, floating at the top of every screen (UI research's floating preview, G 2026-10-06):
 * the island in the middle says where you are (chapter and page) with one step back on its left and a fill for how
 * far along you are on its right; tapping it opens the contents, which zoom out from the page to its chapter, the
 * year, and every grade. Pinching the page closed does the same. Quick settings and Me float on their own in the
 * top-right corner; an unfinished lesson waits in the top-left one.
 */
export function Island({ grade: chosen, guest }: { grade: number | null; guest?: boolean }) {
  const app = useApp();
  const { progress, go, route, openSheet, quit } = app;
  // quitting a run you started and don't want to finish (G 2026-10-06): one quick confirm, then it's gone
  const [asking, setAsking] = useState(false);
  // Practice's hint stack is open: the bulb turns ink-filled while it is
  const [hinting, setHinting] = useState(false);
  useEffect(() => {
    const on = (e: Event) => setHinting(!!(e as CustomEvent).detail);
    addEventListener("bento:hintopen", on);
    return () => removeEventListener("bento:hintopen", on);
  }, []);
  // the landing page, and any grade page reached before a grade is chosen, get the plain guest island
  const welcome = !!guest || route.name === "welcome" || chosen == null;
  const grade = chosen ?? 0;
  const place = placeOf(route, app, grade);
  const [open, setOpen] = useState<Level | null>(null);
  // quick settings: open, closing (the pills ripple out, last first, as in the UI notes preview), or put away
  const [qs, setQs] = useState<"open" | "closing" | null>(null);
  const quick = qs === "open";
  const shut = () => setQs(q => (q === "open" ? "closing" : q));
  useEffect(() => {
    if (qs !== "closing") return;
    const t = setTimeout(() => setQs(null), reduceMotion() ? 0 : 240);
    return () => clearTimeout(t);
  }, [qs]);
  // Me: the same kind of floating stack, under the Me circle (Design's RedesignMe spec); only one stack is ever open
  const [me, setMe] = useState<"open" | "closing" | null>(null);
  const meOpen = me === "open";
  const shutMe = () => setMe(q => (q === "open" ? "closing" : q));
  useEffect(() => {
    if (me !== "closing") return;
    const t = setTimeout(() => setMe(null), reduceMotion() ? 0 : 240);
    return () => clearTimeout(t);
  }, [me]);
  const start: Level = route.name === "home" ? "shelf" : place.lesson ? "chapter" : "year";
  // going anywhere (Me included) puts quick settings away
  useEffect(() => { setQs(null); setMe(null); }, [route]);
  // feedback and quick settings never overlap: new feedback puts settings away, and opening settings tells Practice
  useEffect(() => {
    const onPanel = (e: Event) => { if ((e as CustomEvent).detail === "feedback") { shut(); shutMe(); } };
    addEventListener("bento:panel", onPanel);
    return () => removeEventListener("bento:panel", onPanel);
  }, []);
  const openMe = () => { shut(); setMe("open"); dispatchEvent(new CustomEvent("bento:panel", { detail: "settings" })); };
  const openQuick = () => { shutMe(); setQs("open"); dispatchEvent(new CustomEvent("bento:panel", { detail: "settings" })); };

  // pinching the page closed (two fingers coming together) zooms out to the contents; spreading them is left to the browser
  useEffect(() => {
    if (welcome || open) return;
    let d0 = 0;
    const dist = (t: TouchList) => Math.hypot(t[0]!.clientX - t[1]!.clientX, t[0]!.clientY - t[1]!.clientY);
    const onStart = (e: TouchEvent) => { d0 = e.touches.length === 2 && (visualViewport?.scale ?? 1) <= 1.01 ? dist(e.touches) : 0; };
    const onMove = (e: TouchEvent) => {
      if (!d0 || e.touches.length !== 2) return;
      if (dist(e.touches) / d0 < 0.7) { d0 = 0; if (start === "shelf") openSheet(true); else setOpen(start); }
    };
    document.addEventListener("touchstart", onStart, { passive: true });
    document.addEventListener("touchmove", onMove, { passive: true });
    return () => { document.removeEventListener("touchstart", onStart); document.removeEventListener("touchmove", onMove); };
  }, [welcome, open, start]);

  // the page behind steps back while the contents are open
  useEffect(() => {
    if (open) document.documentElement.dataset.zoomed = "";
    else delete document.documentElement.dataset.zoomed;
    return () => { delete document.documentElement.dataset.zoomed; };
  }, [open]);

  const run = progress.run, runGrade = run ? gradeOf(lessonOfItem(currentItem(run)).grade) : null;
  // the pages about you (Me, the grown-up page, facts) keep one island at the top (Review v43 item 17)
  const showResume = !!run && !!runGrade && !welcome && !["practice", "me", "parent", "facts"].includes(route.name);
  // in a lesson's practice, a light bulb sits beside Settings (UI notes preview); tests have no hints
  const hintable = route.name === "practice" && !!run && run.mode !== "test" && !!currentStep(run) && !run.pick;
  // on a phone, practice's island shows the problem itself in place of the lesson's name (practice-spec §2c A)
  const item = route.name === "practice" && run ? currentItem(run) : null;
  const shortProblem = item && problemShape(item.lessonId, problemOf(item), !!item.story).short ? item : null;

  // the way back to your lessons floats on its own in the right corner, so "Bento" stays centred in its pill (v44 sweep
  // item 5); on a phone it is a circle holding your grade's number, with a spacer on the left to keep the pill centred
  const mine = progress.chosen && progress.grade != null ? gradeOf(progress.grade) : null;
  if (welcome) return (
    <div className="itop guest"><span className="ispace" /><header className="island guest">
      <BentoMark className="iword" />
    </header>
      <div className="icorner right">
        {mine && (
          <button className="imine" onClick={() => { openSheet(false); go({ name: "home" }, "fwd"); }}>
            <span className="imtext">My lessons ›</span>
            <span className="gnum imgrade" aria-hidden style={{ "--gn": inkOf(mine.color), "--gn-d": mine.color } as CSSProperties}>{mine.short}</span>
          </button>
        )}
      </div>
    </div>
  );

  const g = gradeOf(grade), fill = fillOf(place, app, grade);
  // on the book itself, one step back is the grade question
  const back = place.back;
  return (
    <>
    <div className={`itop${quick || meOpen ? " qopen" : ""}`}>
      <div className="icorner left">
        {showResume && (
          <button className="iresume" onClick={() => go({ name: "practice" }, "fwd")}
            aria-label={`Resume ${run!.title}, ${runGrade!.name}, problem ${run!.i + 1} of ${run!.items.length}`}>
            <span className="rdot gnum" style={{ "--gn": runGrade!.color } as CSSProperties}>{runGrade!.short}</span>
            <span className="rtext"><small>Resume</small><b>{run!.title}</b></span>
            <span className="rcount">{run!.i + 1}/{run!.items.length}</span>
          </button>
        )}
        {showResume && (
          <button className="iresume-x" onClick={() => setAsking(true)} aria-label={`Quit ${run!.title}`}><CrossIcon /></button>
        )}
      </div>
      <header className="island">
        {back
          ? <button className="iback" onClick={() => go(back.to, "back")} aria-label={`Back to ${back.label}`}><Chevron dir="left" /></button>
          : <button className="iback" onClick={() => openSheet(true)} aria-label="Change grade"><Chevron dir="left" /></button>}
        <button className="iplace" onClick={() => setOpen(start === "shelf" ? "year" : start)} aria-label={`Contents. You're on ${place.title}`} aria-haspopup="dialog">
          <small>{place.kicker}</small>
          {place.title === gradeOf(grade).name ? <GradeTitle grade={grade} /> : <b className={shortProblem ? "ititle" : undefined}>{place.title}</b>}
          {shortProblem && <b className="iprob"><ProblemLine lessonId={shortProblem.lessonId} problem={problemOf(shortProblem)} solved={run!.solved} /></b>}
        </button>
        {place.lock
          ? <span className="ilock"><LockIcon />On this device</span>
          : <span className={`ibat${route.name === "practice" && run?.solved ? " tick" : ""}`} aria-hidden style={{ "--p": fill, "--gn": inkOf(g.color), "--gn-d": g.color } as CSSProperties}><i /></span>}
      </header>
      <div className="icorner right">
        {hintable && (
          <button className={`icon ihint${run!.hintsLeft || run!.hinted ? "" : " spent"}${hinting ? " on" : ""}`} onClick={() => { shut(); shutMe(); dispatchEvent(new Event("bento:hint")); }}
            aria-label={`Hint, ${run!.hintsLeft} left`} aria-expanded={hinting}><BulbIcon /><em className="ibadge" aria-hidden>{run!.hintsLeft}</em></button>
        )}
        <button className={`icon${quick ? " on" : ""}`} onClick={() => (quick ? shut() : openQuick())} aria-label="Settings" aria-expanded={quick}><SettingsIcon /></button>
        <button className={`icon ime${meOpen || route.name === "me" || route.name === "parent" ? " on" : ""}`} onClick={() => (meOpen ? shutMe() : openMe())}
          aria-label={`Me: ${progress.streak} day streak, ${progress.xp} XP`} aria-haspopup="dialog" aria-expanded={meOpen}>
          <MeIcon />
        </button>
      </div>
    </div>
      {qs && <QuickSettings closing={qs === "closing"} close={shut} />}
      {me && <MeStack closing={me === "closing"} close={shutMe} />}
      {asking && run && (
        <ConfirmStack title={`Quit ${run.title}?`} body="Your answers so far won't be kept." confirm="Quit"
          onCancel={() => setAsking(false)} onConfirm={() => { setAsking(false); quit({ stay: true }); }} />
      )}
      {open && <Contents grade={place.lesson ? pageOf(place.lesson)?.grade ?? grade : grade} lessonId={place.lesson} level={open} close={() => setOpen(null)} />}
    </>
  );
}

/**
 * Quick settings: a column of separate floating pills under the settings button, arriving one at a time, over a light
 * dim so they never sit on the problem. The rest of the settings live in Me.
 */
function QuickSettings({ close, closing }: { close: () => void; closing: boolean }) {
  const { progress, setSettings, go } = useApp();
  const s = readSettings(progress.settings);
  const aloud = readAloudOn(s, progress.grade);
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") close(); };
    addEventListener("keydown", onKey);
    return () => removeEventListener("keydown", onKey);
  }, [close]);
  const rows: { label: string; on: boolean; flip: () => void }[] = [
    { label: SETTING.motion, on: s.motion === "reduce", flip: () => setSettings({ motion: s.motion === "reduce" ? "system" : "reduce" }) },
    { label: SETTING.colorSafe, on: s.colorSafe, flip: () => setSettings({ colorSafe: !s.colorSafe }) },
    { label: SETTING.readAloud, on: aloud, flip: () => setSettings({ readAloud: !aloud }) },
    { label: SETTING.sounds, on: s.sounds, flip: () => setSettings({ sounds: !s.sounds }) },
  ];
  return (
    <>
      <div className={`fdim${closing ? " out" : ""}`} onClick={close} />
      <div className={`fstack qset${closing ? " out" : ""}`} role="dialog" aria-label="Settings" style={{ "--n": rows.length + (SANDBOX ? 4 : 3) } as CSSProperties}>
        <span className="flbl" style={{ "--i": 0 } as CSSProperties}>Settings</span>
        {rows.map((r, i) => (
          <button key={r.label} className="fpill toggle" role="switch" aria-checked={r.on} onClick={r.flip} style={{ "--i": i + 1 } as CSSProperties}>
            {r.label}<span className="sw" />
          </button>
        ))}
        <button className="fpill" onClick={() => { close(); go({ name: "me" }, "fwd"); }} style={{ "--i": rows.length + 1 } as CSSProperties}>All settings ›</button>
        {/* the website: what Bento is, from inside the app (G 2026-10-06) */}
        <button className="fpill" onClick={() => { close(); go({ name: "welcome" }, "back"); }} style={{ "--i": rows.length + 2 } as CSSProperties}>About Bento ›</button>
        {SANDBOX && <button className="fpill" onClick={() => { close(); dispatchEvent(new Event("bento:sandbox")); }} style={{ "--i": rows.length + 3 } as CSSProperties}>Sandbox ›</button>}
      </div>
    </>
  );
}
