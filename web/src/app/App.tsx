import { Facts } from "../screens/Facts";
import { useEffect } from "react";
import { bandOf, lineOf } from "../curriculum/grades";
import { lessonById } from "../curriculum/registry";
import { currentItem } from "../engine/session/practice";
import { GradeSheet } from "../components/GradeSheet";
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
import { canCrossFade } from "./transition";

/** Picks the screen for the route and sets the grade band and tint the styles key off. */
export function App() {
  const { route, progress, reports, lastReport, sheetOpen } = useApp();
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
  const choosing = route.name === "welcome" || (route.name === "home" && grade == null);
  // lesson screens are neutral and the same in every lesson; only the pictures carry the grade colors (design handoff-4)
  const neutral = !top && !!lesson;

  // the canvas behind the bento follows the line the screen belongs to; the landing page stays plain
  const line = choosing || grade == null ? "welcome" : lineOf(grade).id;
  useEffect(() => { document.documentElement.dataset.line = line; }, [line]);

  useEffect(() => {
    document.title = route.name === "learn" && lesson ? `${lesson.title} · Bento` : "Bento";
  }, [route.name, lesson]);

  let screen;
  switch (route.name) {
    case "welcome": screen = <Welcome shelf={!!route.shelf} />; break;
    case "learn": screen = lessonById(route.lessonId) ? <Learn lessonId={route.lessonId} /> : grade == null ? <Welcome shelf /> : <Home />; break;
    case "practice": screen = <Practice />; break;
    case "results": screen = <Results />; break;
    case "report": screen = <ReportScreen rep={reports[route.key]} />; break;
    case "parent": screen = <Parent />; break;
    case "me": screen = <Me />; break;
    case "facts": screen = <Facts table={route.table} start={!!route.start} />; break;
    default: screen = grade == null ? <Welcome shelf /> : <Home />;
  }
  // a new screen (or a new grade on a top-level screen) re-enters; with view transitions the browser cross-fades instead
  const viewKey = [route.name, route.name === "learn" ? route.lessonId : route.name === "report" ? route.key : route.name === "facts" ? route.table ?? "" : "", top ? chosenGrade : ""].join("|");
  return (
    <main id="app" className={`wrap t0${neutral ? " neutral" : ""}${canCrossFade() ? "" : " fresh"}`} data-band={grade == null ? "middle" : bandOf(grade)} data-grade={grade ?? "none"} key={viewKey}>
      <Island grade={grade} guest={choosing} />
      {screen}
      {sheetOpen && <GradeSheet />}
    </main>
  );
}
