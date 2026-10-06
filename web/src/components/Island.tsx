import { useEffect, useState, type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import type { Route } from "../app/routes";
import { entriesInGrade, entryById, unitsInGrade } from "../app/curriculum";
import { gradeOf, inkOf } from "../curriculum/grades";
import { lessonById } from "../curriculum/registry";
import { currentItem, lessonOfItem } from "../engine/session/practice";
import { Contents, type Level } from "./Contents";
import { tableById } from "../engine/facts/tables";
import { Chevron } from "./primitives/icons";

/** A simple person: a head and shoulders. */
const MeIcon = () => (
  <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="8.5" r="3.6" /><path d="M5 20c1.2-3.6 4-5.4 7-5.4s5.8 1.8 7 5.4" /></svg>
);
/** Four small squares: the contents of the book. */
const GridIcon = () => (
  <svg viewBox="0 0 16 16" width="14" height="14" fill="currentColor" aria-hidden="true"><rect x="1" y="1" width="6" height="6" rx="1.6" /><rect x="9" y="1" width="6" height="6" rx="1.6" /><rect x="1" y="9" width="6" height="6" rx="1.6" /><rect x="9" y="9" width="6" height="6" rx="1.6" /></svg>
);

/** Where a lesson sits in its grade's book: its chapter, and which page of that chapter it is. */
export function pageOf(lessonId: string): { grade: number; chapter: string; page: number; pages: number } | null {
  const g = entryById(lessonId)?.grade ?? lessonById(lessonId)?.grade;
  if (g == null) return null;
  const ch = unitsInGrade(g).find(u => u.entries.some(c => c.id === lessonId));
  if (!ch) return { grade: g, chapter: gradeOf(g).name, page: 1, pages: entriesInGrade(g).length };
  return { grade: g, chapter: ch.name, page: ch.entries.findIndex(c => c.id === lessonId) + 1, pages: ch.entries.length };
}

type Place = { kicker: string; title: string; back?: { label: string; to: Route }; lesson?: string };

/** What the island says on each screen: a small line for where you are in the book, and the page you're on. */
function placeOf(route: Route, app: ReturnType<typeof useApp>, grade: number): Place {
  const contents = { label: "contents", to: { name: "home" } as Route };
  const chapterLine = (id: string, extra?: string) => {
    const p = pageOf(id);
    return p ? `${p.chapter === "Skills" ? gradeOf(p.grade).name : p.chapter} · ${extra ?? `${p.page} of ${p.pages}`}` : gradeOf(grade).name;
  };
  switch (route.name) {
    case "learn": return { kicker: chapterLine(route.lessonId), title: lessonById(route.lessonId)?.title ?? "Lesson", back: contents, lesson: route.lessonId };
    case "practice": {
      const run = app.progress.run;
      if (!run) return { kicker: gradeOf(grade).name, title: "Practice", back: contents };
      if (run.mode !== "practice") return { kicker: run.mode === "test" ? "Test" : "Review", title: run.title, back: contents };
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
        : { kicker: "For the grown-up", title: rep?.title ?? "Report", back: { label: "For the grown-up", to: { name: "parent" } } };
    }
    case "parent": return { kicker: "Me", title: "For the grown-up", back: { label: "Me", to: { name: "me" } } };
    case "me": return { kicker: "Me", title: "Your Bento", back: contents };
    case "facts": {
      const t = route.table ? tableById(route.table) : undefined;
      return t ? { kicker: "Facts", title: t.name, back: { label: "facts", to: { name: "facts" } } } : { kicker: gradeOf(grade).name, title: "Facts", back: contents };
    }
    default: {
      // on a phone the picked row's detail is its own screen, and back returns to the list
      const phone = typeof matchMedia !== "undefined" && matchMedia("(max-width: 699px)").matches;
      return route.name === "home" && route.pick && phone
        ? { kicker: gradeOf(grade).name, title: route.pick === "today" ? "Today" : lessonById(route.pick)?.title ?? "Lesson", back: { label: "chapters", to: { name: "home" } } }
        : { kicker: "Contents", title: gradeOf(grade).name };
    }
  }
}

/**
 * The one way around Bento: a small floating island at the top of every screen. It says where you are in the book
 * (chapter and page), steps back one page, and opens the contents, which zoom out from the page to its chapter, the
 * year, and every grade. Pinching the page closed does the same.
 */
export function Island({ grade: chosen, guest }: { grade: number | null; guest?: boolean }) {
  const app = useApp();
  const { progress, go, route } = app;
  // the landing page, and any grade page reached before a grade is chosen, get the plain guest island
  const welcome = !!guest || route.name === "welcome" || chosen == null;
  const grade = chosen ?? 0;
  const place = placeOf(route, app, grade);
  const [open, setOpen] = useState<Level | null>(null);
  const start: Level = route.name === "home" ? "shelf" : place.lesson ? "chapter" : "year";

  // pinching the page closed (two fingers coming together) zooms out to the contents; spreading them is left to the browser
  useEffect(() => {
    if (welcome || open) return;
    let d0 = 0;
    const dist = (t: TouchList) => Math.hypot(t[0]!.clientX - t[1]!.clientX, t[0]!.clientY - t[1]!.clientY);
    const onStart = (e: TouchEvent) => { d0 = e.touches.length === 2 && (visualViewport?.scale ?? 1) <= 1.01 ? dist(e.touches) : 0; };
    const onMove = (e: TouchEvent) => {
      if (!d0 || e.touches.length !== 2) return;
      if (dist(e.touches) / d0 < 0.7) { d0 = 0; setOpen(start); }
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
  const showResume = !!run && !!runGrade && route.name !== "practice" && !welcome;

  if (welcome) return (
    <div className="itop"><header className="island guest">
      <span className="iword">Bento</span>
      {progress.chosen
        ? <button className="ilink" onClick={() => go({ name: "home" }, "fwd")}>My lessons ›</button>
        : <span className="inote">Kindergarten to 12th grade</span>}
    </header></div>
  );

  return (
    <>
    <div className="itop">
      <header className="island" style={{ "--itint": inkOf(gradeOf(grade).color) } as CSSProperties}>
        {place.back
          ? <button className="iside" onClick={() => go(place.back!.to, "back")} aria-label={`Back to ${place.back.label}`}><Chevron dir="left" /></button>
          : <button className="iside iword" onClick={() => go({ name: "welcome" }, "back")} aria-label="Bento home page">Bento</button>}
        <button className="iplace" onClick={() => setOpen(start)} aria-label={`Contents. You're on ${place.title}`} aria-haspopup="dialog">
          <small>{place.kicker}</small>
          <b>{place.title}</b>
          <span className="igrid"><GridIcon /></span>
        </button>
        <button className={`iside ime${route.name === "me" || route.name === "parent" ? " on" : ""}`} onClick={() => go({ name: "me" }, "fwd")} aria-label={`Me: ${progress.streak} day streak, ${progress.xp} XP`}>
          <MeIcon />
        </button>
      </header>
      {showResume && (
        <button className="iresume" style={{ "--rtint": inkOf(runGrade!.color) } as CSSProperties} onClick={() => go({ name: "practice" }, "fwd")}
          aria-label={`Resume ${run!.title}, ${runGrade!.name}, problem ${run!.i + 1} of ${run!.items.length}`}>
          <span className="rdot" style={{ background: inkOf(runGrade!.color) }}>{runGrade!.short}</span>
          <span className="rtext"><small>Resume</small><b>{run!.title}</b></span>
          <span className="rcount">{run!.i + 1}/{run!.items.length}</span>
        </button>
      )}
    </div>
      {open && <Contents grade={place.lesson ? pageOf(place.lesson)?.grade ?? grade : grade} lessonId={place.lesson} level={open} close={() => setOpen(null)} />}
    </>
  );
}
