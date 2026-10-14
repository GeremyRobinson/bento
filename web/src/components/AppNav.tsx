import { useEffect, useLayoutEffect, useRef } from "react";
import { useApp } from "../app/AppState";
import { parseRoute, type Route } from "../app/routes";
import { entriesInGrade, unitsInGrade } from "../app/curriculum";
import { gradeOf } from "../curriculum/grades";
import { lessonById } from "../curriculum/registry";
import { currentItem, lessonOfItem } from "../engine/session/practice";
import { lessonLength } from "../engine/adaptive-help/policy";
import { lastScore } from "../engine/mastery/progress";
import { isCheckKey, lessonOfCheck } from "../engine/mastery/skills";
import { tableById } from "../engine/facts/tables";
import { checkedCount } from "../app/rings";
import { GRADES_VIEW, setBoxView, useBoxView } from "../app/box";
import { REVIEW } from "../app/copy";
import { SETTINGS_PAGE_NAME } from "../screens/Settings";
import { BackIcon, GridIcon, ORing, PersonIcon, SunIcon } from "./Masters";

/** what the island says: a small line over where you are, how far along the ring is, and where back goes */
interface Where { kick: string; title: string; p: number; back?: Route }

const HOME: Route = { name: "home" };

/** the page this one was opened from, when it's another in-app page (the corner tools step back to where you were) */
function cameFrom(route: Route): Route | undefined {
  let prev: unknown = null;
  try { prev = (history.state as { prev?: unknown } | null)?.prev; } catch { /* ignore */ }
  if (typeof prev !== "string" || !prev.startsWith("#/")) return undefined;
  const to = parseRoute(prev);
  return to.name === route.name || to.name === "welcome" || to.name === "settings" ? undefined : to;
}

function whereOf(app: ReturnType<typeof useApp>, grade: number, view: string | null): Where {
  const { route, progress } = app;
  const g = gradeOf(grade), all = entriesInGrade(grade), year = all.length ? checkedCount(progress, all) / all.length : 0;
  switch (route.name) {
    case "learn": {
      const l = lessonById(route.lessonId);
      return { kick: `Watch one · then try ${lessonLength(lastScore(progress, route.lessonId))}`, title: l?.title ?? "Lesson", p: 0, back: HOME };
    }
    case "practice": {
      const run = progress.run;
      if (!run) return { kick: g.name, title: "Practice", p: 0, back: HOME };
      const n = run.items.length, solved = (run.done?.length ?? 0) + (run.solved && !run.done?.includes(run.i) ? 1 : 0);
      if (isCheckKey(run.key)) return { kick: `Skill check · ${run.i + 1} of ${n}`, title: lessonById(lessonOfCheck(run.key))?.title ?? run.title, p: solved / n, back: HOME };
      if (run.mode === "test") return { kick: `Test · ${run.i + 1} of ${n}`, title: run.title, p: solved / n, back: HOME };
      if (run.mode !== "practice") return { kick: REVIEW, title: run.title, p: solved / n, back: HOME };
      return { kick: `Problem ${run.i + 1} of ${n}`, title: lessonOfItem(currentItem(run)).title, p: solved / n, back: HOME };
    }
    case "results": {
      const rep = app.lastReport;
      if (rep && isCheckKey(rep.key)) return { kick: `Done · skill check ${rep.level} of 4`, title: lessonById(lessonOfCheck(rep.key))?.title ?? rep.title, p: 1, back: HOME };
      return { kick: rep?.mode === "test" ? `Done · test ${rep.level} of 4` : "Done", title: rep?.title ?? "Done", p: 1, back: HOME };
    }
    case "report": {
      const l = lessonById(route.key);
      return { kick: l ? "Report" : "For the grown‑up", title: l?.title ?? app.reports[route.key]?.title ?? "Report", p: year, back: l ? { name: "learn", lessonId: l.id } : { name: "parent" } };
    }
    case "me": return { kick: g.name, title: "Me", p: year, back: cameFrom(route) ?? HOME };
    case "parent": return { kick: "Me · on this device", title: "For the grown‑up", p: year, back: { name: "me" } };
    case "settings": return route.page ? { kick: "Settings", title: SETTINGS_PAGE_NAME[route.page], p: year, back: { name: "settings" } }
      : { kick: g.name, title: "Settings", p: year, back: cameFrom(route) ?? HOME };
    case "facts": {
      const t = route.table ? tableById(route.table) : undefined;
      return t ? { kick: "Facts", title: t.name, p: year, back: { name: "facts" } } : { kick: g.name, title: "Facts", p: year, back: HOME };
    }
    default: {
      if (view === GRADES_VIEW) return { kick: "Pick a grade", title: "Every grade", p: year };
      const u = view ? unitsInGrade(grade).find(x => x.name === view) : undefined;
      if (u) return { kick: g.name, title: u.name, p: u.entries.length ? checkedCount(progress, u.entries) / u.entries.length : 0 };
      return { kick: `${checkedCount(progress, all)} of ${all.length} done`, title: g.name, p: year };
    }
  }
}

/**
 * The island and its two corners (UI model v57): Settings on the left, Me on the right, the island centred between
 * them. The island starts with one round button: the grade picker on the box's top, back everywhere else; then where
 * you are, then the ring with the grade's number. It hugs its words; a long name steps one type size down, then takes
 * two lines. In a lesson on a phone the corners go and the island takes the row: back is the only way out.
 */
export function AppNav({ grade }: { grade: number }) {
  const app = useApp();
  const { route, go, back: up } = app;
  const view = useBoxView();
  const onHome = route.name === "home";
  const w = whereOf(app, grade, onHome ? view : null);
  const inBox = onHome && view != null;
  const back = () => {
    if (inBox) { setBoxView(null, view === GRADES_VIEW ? "zin" : "zout"); return; }
    if (w.back) up(w.back);
  };
  const hasBack = inBox || (!onHome && !!w.back);

  // a long name never gets cut: one type step down, then two lines with the kicker stepping aside
  const place = useRef<HTMLDivElement>(null);
  const fit = () => {
    const pl = place.current;
    if (!pl) return;
    const k = pl.querySelector("small")!, b = pl.querySelector("b")!;
    pl.classList.remove("fit1", "fit2", "kfit");
    if (k.scrollWidth > k.clientWidth + 1) pl.classList.add("kfit");
    if (b.scrollWidth > b.clientWidth + 1) { pl.classList.add("fit1"); if (b.scrollWidth > b.clientWidth + 1) pl.classList.replace("fit1", "fit2"); }
  };
  useLayoutEffect(fit);
  useEffect(() => { addEventListener("resize", fit); return () => removeEventListener("resize", fit); });

  // Escape is the same step as back, unless something on the page handles it first
  useEffect(() => {
    if (!hasBack) return;
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape" && !e.defaultPrevented && !document.querySelector(".zoom,.fstack,.confirm,.sheet,dialog[open],.v-plist")) back(); };
    addEventListener("keydown", onKey);
    return () => removeEventListener("keydown", onKey);
  });

  const g = gradeOf(grade);
  return (
    <div className="o-nav">
      <button className={`o-tool${route.name === "settings" ? " sel" : ""}`} onClick={() => { if (route.name !== "settings") go({ name: "settings" }, "fwd"); else if (route.page) go({ name: "settings" }, "back"); }} aria-label="Settings"><SunIcon /></button>
      <header className="o-island">
        {hasBack
          ? <button className="o-tool" onClick={back} aria-label="Back"><BackIcon /></button>
          : onHome && <button className="o-tool" onClick={() => setBoxView(GRADES_VIEW, "zout")} aria-label="Every grade"><GridIcon /></button>}
        <div className="o-place" ref={place}><small>{w.kick}</small><b>{w.title}</b></div>
        <ORing p={w.p} label={g.short} size="m" />
      </header>
      <button className={`o-tool${route.name === "me" || route.name === "parent" ? " sel" : ""}`} onClick={() => { if (route.name !== "me") go({ name: "me" }, "fwd"); }} aria-label="Me"
        aria-current={route.name === "me" ? "page" : undefined}><PersonIcon /></button>
    </div>
  );
}
