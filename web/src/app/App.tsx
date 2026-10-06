import { Facts } from "../screens/Facts";
import { Fragment, lazy, Suspense, useEffect } from "react";
import { bandOf, gradeOf, lineOf } from "../curriculum/grades";
import { lessonById } from "../curriculum/registry";
import { tintOf } from "./tint";
import { useSandboxSeed } from "../sandbox/store";
import { currentItem } from "../engine/session/practice";
import { GradeQuestion } from "../screens/GradeQuestion";
import { Home } from "../screens/Home";
import { Me } from "../screens/Me";
import { Learn } from "../screens/Learn";
import { Parent } from "../screens/Parent";
import { Practice } from "../screens/Practice";
import { ReportScreen, Results } from "../screens/Results";
import { Welcome } from "../screens/Welcome";
import { useApp } from "./AppState";
import { isTopLevel } from "./routes";
import { Island } from "../components/Island";
import { motionOff } from "./settings";

// the design sandbox loads only in the preview and dev builds; the live site never carries it
const SANDBOX = import.meta.env.MODE === "preview" || import.meta.env.MODE === "development";
const Sandbox = SANDBOX ? lazy(() => import("../sandbox/Sandbox").then(m => ({ default: m.Sandbox }))) : () => null;
const SandboxBoard = SANDBOX ? lazy(() => import("../sandbox/Sandbox").then(m => ({ default: m.SandboxBoard }))) : () => null;

/** Picks the screen for the route and sets the grade band and tint the styles key off. */
export function App() {
  const { route, progress, reports, lastReport, sheetOpen } = useApp();
  const sbSeed = useSandboxSeed(SANDBOX);
  // no grade until the learner picks one (G: choice is the default); grade pages without one show the neutral look
  const chosenGrade = progress.grade;

  // the lesson whose look the screen takes: the one being learned or practiced, or the one a report is about
  let lessonId: string | null = null;
  let testGrade: number | null = null;
  if (route.name === "learn") lessonId = route.lessonId;
  else if (route.name === "practice" && progress.run) lessonId = currentItem(progress.run).lessonId;
  else if (route.name === "results" || route.name === "report") {
    const rep = route.name === "results" ? lastReport : reports[route.key];
    if (rep) {
      if (lessonById(rep.key)) lessonId = rep.key;
      else {
        const last = rep.probs[rep.probs.length - 1];
        if (last && lessonById(last.lessonId)) lessonId = last.lessonId;
        if (rep.mode === "test") testGrade = Number(rep.key.split(":")[1]);
      }
    }
  }
  const lesson = lessonId ? lessonById(lessonId) : undefined;
  const top = isTopLevel(route);
  const grade: number | null = top ? chosenGrade : testGrade ?? lesson?.grade ?? chosenGrade;
  // changing grade opens picker D over everything (Review v43 item 15: one way to change grade)
  const choosing = sheetOpen || route.name === "welcome" || (route.name === "home" && grade == null);
  const tint = top || !lesson ? 0 : tintOf(lesson);
  // the website and the grade picker are about every grade, so their surfaces stay neutral: a chosen grade's hue
  // would tint every card (G 2026-10-06: "why is this burgundy?")
  const neutral = route.name === "welcome" || sheetOpen;


  // the canvas behind the bento follows the line the screen belongs to; the landing page stays plain
  const line = choosing || grade == null ? "welcome" : lineOf(grade).id;
  useEffect(() => { document.documentElement.dataset.line = line; }, [line]);
  // the page behind the app takes a wash of the grade's hue, so the whole screen is one color family
  const hue = choosing || grade == null ? null : gradeOf(grade).color;
  useEffect(() => {
    const el = document.documentElement;
    if (hue) { el.dataset.hue = ""; el.style.setProperty("--page-hue", hue); }
    else { delete el.dataset.hue; el.style.removeProperty("--page-hue"); }
  }, [hue]);

  useEffect(() => {
    document.title = route.name === "learn" && lesson ? `${lesson.title} · Bento` : "Bento";
  }, [route.name, lesson]);

  // every tap on a control leaves a soft halo, so a finger knows it landed (Less motion turns it off)
  useEffect(() => {
    const onDown = (e: PointerEvent) => {
      if (motionOff() || !(e.target instanceof Element) || !e.target.closest("button:not([disabled])")) return;
      const h = document.createElement("span");
      h.className = "halo"; h.style.left = `${e.clientX}px`; h.style.top = `${e.clientY}px`;
      document.body.appendChild(h);
      setTimeout(() => h.remove(), 600);
    };
    document.addEventListener("pointerdown", onDown);
    return () => document.removeEventListener("pointerdown", onDown);
  }, []);

  let screen;
  switch (route.name) {
    case "welcome": screen = <Welcome shelf={!!route.shelf} />; break;
    case "learn": screen = lessonById(route.lessonId) ? <Learn lessonId={route.lessonId} /> : <Home />; break;
    case "practice": screen = <Practice />; break;
    case "results": screen = <Results />; break;
    case "report": screen = <ReportScreen rep={reports[route.key]} />; break;
    case "parent": screen = <Parent />; break;
    case "me": screen = <Me />; break;
    case "sandbox": screen = SANDBOX ? <Suspense fallback={null}><SandboxBoard /></Suspense> : <Home />; break;
    case "facts": screen = <Facts table={route.table} start={!!route.start} />; break;
    default: screen = <Home />;
  }
  if (sheetOpen) screen = <GradeQuestion />;
  // a new screen (or a new grade on a top-level screen) re-enters; with view transitions the browser cross-fades instead
  const viewKey = [sheetOpen ? "grades" : route.name, route.name === "learn" ? route.lessonId : route.name === "report" ? route.key : route.name === "facts" ? route.table ?? "" : "", top ? chosenGrade : "", SANDBOX ? sbSeed : ""].join("|");
  return (<>
    {/* the island stays put across screens (UI notes preview); only the screen under it is new, and its pieces
        stagger in (motion.css, "one motion master") */}
    <main id="app" className={`wrap t${tint}`} data-band={grade == null || neutral ? "middle" : bandOf(grade)} data-grade={neutral ? "none" : grade ?? "none"}>
      <Island grade={grade} guest={choosing} />
      <Fragment key={viewKey}>{screen}</Fragment>
    </main>
    {SANDBOX && <Suspense fallback={null}><Sandbox /></Suspense>}
  </>);
}
