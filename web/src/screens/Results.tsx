import { Pill } from "../components/primitives/Pill";
import { useEffect, useState, type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { when } from "../app/format";
import { reduceMotion } from "../app/transition";
import { gradeOf, tintStyle } from "../curriculum/grades";
import { placeKey, placementResult } from "../engine/session/practice";
import { lessonById, lessonsInGrade } from "../curriculum/registry";
import { BuildUp } from "../components/BuildUp";
import type { SessionReport } from "../engine/session/types";
import { SessionReportView } from "../components/reports/SessionReportView";
import { FitScreen } from "../components/screen/Screen";
import { ALL_LESSONS, PRACTICE_AGAIN } from "../app/copy";
import { upNext } from "../app/today";
import { PreviewWell } from "./Home";
import { Cover } from "../components/Cover";
import { Rich } from "../components/primitives/MathLine";
import { lessonPic, TilePic } from "../components/TilePics";
import { unitsInGrade } from "../app/curriculum";
import { lastScore, timesDone } from "../engine/mastery/progress";

/** Counts up from 0 over a moment, like the current app's XP figure. */
export function CountUp({ to, pre = "" }: { to: number; pre?: string }) {
  const [v, setV] = useState(() => (reduceMotion() || typeof requestAnimationFrame === "undefined" ? to : 0));
  useEffect(() => {
    if (reduceMotion() || typeof requestAnimationFrame === "undefined") { setV(to); return; }
    const t0 = performance.now(), dur = 900;
    let id = 0;
    const tick = (t: number) => {
      const k = Math.min(1, (t - t0) / dur), e = 1 - Math.pow(1 - k, 3);
      setV(Math.round(to * e));
      if (k < 1) id = requestAnimationFrame(tick);
    };
    id = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(id);
  }, [to]);
  return <span aria-label={`${pre}${to}`}>{pre}{v}</span>;
}

/** After "Find my level": the grade to start in, and how each grade went. */
function Placed({ rep }: { rep: SessionReport }) {
  const { progress, chooseGrade, go, startTest } = useApp();
  const from = Number(rep.key.split(":")[1]);
  const { grade, next, rows } = placementResult(rep.probs, from), gd = gradeOf(grade), same = grade === from && progress.grade === from;
  return (
    <FitScreen className="placed" style={tintStyle(gd) as CSSProperties}>
      <span className="k">Your level</span>
      <h1>Start in {gd.name}.</h1>
      <p className="muted">{grade > from ? "You're ahead. The work here will stretch you." : grade < from ? "A few things to firm up first. You'll move fast." : "Right where you should be."}</p>
      <ol className="prows">{rows.map(r => (
        <li key={r.grade} className={r.grade <= grade ? "ok" : ""}>
          <span>{gradeOf(r.grade).name}</span>
          <span className="pdots" aria-label={`${r.right} of ${r.total} right`}>{Array.from({ length: r.total }, (_, i) => <i key={i} className={i < r.right ? "on" : ""} />)}</span>
        </li>
      ))}</ol>
      <div className="actions">
        <Pill go onClick={() => same ? go({ name: "home" }, "fwd") : chooseGrade(grade)}>Start {gd.name} ›</Pill>
        {next != null && <Pill onClick={() => startTest(placeKey(next))}>Try {gradeOf(next).name}</Pill>}
        {!same && progress.grade != null && <Pill onClick={() => go({ name: "home" }, "back")}>Stay in {gradeOf(progress.grade).name}</Pill>}
      </div>
    </FitScreen>
  );
}

/** The screen after a run: score ring, XP, time, what to do next, then the full report. */
export function Results() {
  const { lastReport: rep, progress, go, startLesson, startTest } = useApp();
  if (!rep) {
    // nothing finished yet: the grade's next lesson, with its own first picture, instead of an empty page (Review v43 #19)
    const next = progress.grade == null ? null : upNext(progress, progress.grade);
    return (
      <FitScreen className="rnone">
        <section className="panel">
          <h2>Nothing finished yet</h2>
          {next && <p className="muted">Up next in {gradeOf(progress.grade!).name}: {next.entry.title}.</p>}
          <div className="actions">
            {next && <Pill go onClick={() => go({ name: "learn", lessonId: next.entry.id }, "fwd")}>Start {next.entry.title} ›</Pill>}
            <Pill go={!next} onClick={() => go({ name: "home" })}>{ALL_LESSONS}</Pill>
          </div>
        </section>
        {next && <PreviewWell key={next.entry.id} candidates={[next.entry.id]} next={next.entry.id} />}
      </FitScreen>
    );
  }
  if (rep.key.startsWith("place:")) return <Placed rep={rep} />;
  const lesson = lessonById(rep.key), test = rep.mode === "test", review = rep.mode === "review";
  const grade = lesson ? lessonsInGrade(lesson.grade) : [], k = lesson ? grade.indexOf(lesson) : -1, next = grade[k + 1];
  const lastLesson = lessonById(rep.probs[rep.probs.length - 1]?.lessonId ?? "");
  const low = rep.mode === "practice" && rep.level <= 1;
  // v2 (G 2026-10-13): what the score means in words, what Today does next, and the lesson's tile filling in its chapter
  const words = ["not there yet", "just starting", "getting there", "nearly there", "you\u2019ve got it"][rep.level];
  const then = test ? "Today keeps track of how the test went." : rep.level >= 3
    ? (next ? `Next time, Today brings the next lesson: ${next.title}.` : "Next time, Today moves on to something new.")
    : "Next time, Today brings this back for another go, so it sticks.";
  const slip = rep.mistakes[0];
  const g = lesson?.grade ?? lastLesson?.grade ?? progress.grade ?? 5;
  return (
    <div className="screen v-work v-done">
      <section className="v-panel v-result" aria-label="Done">
        <span className="v-label">{`Done \u00b7 ${rep.title}`}</span>
        <span className="v-seg" aria-label={`Score ${rep.level} of 4`}>{[1, 2, 3, 4].map(k => <i key={k} className={k <= rep.level ? "on" : undefined} />)}</span>
        <h2>{rep.level} of 4: {words}.</h2>
        <p className="v-why">{test ? `${rep.clean} of ${rep.total} problems had every step right.` : `${rep.clean} of ${rep.total} problems with no mistakes.`} {then}</p>
        <div className="v-row">
          {rep.mode === "practice" && next && rep.level >= 3 && <button className="v-go" onClick={() => go({ name: "learn", lessonId: next.id }, "next")}>Next: {next.title}</button>}
          {test ? <button className="v-plain" onClick={() => startTest(rep.key)}>Take it again</button>
            : !review && lesson && <button className={rep.level >= 3 && next ? "v-plain" : "v-go"} onClick={() => startLesson(lesson.id)}>{PRACTICE_AGAIN}</button>}
          <button className="v-plain" onClick={() => go({ name: "home", ...(lesson ? { pick: lesson.id } : {}) }, "back")}>Back to your box</button>
        </div>
        {low && <BuildUp lessonId={rep.key} />}
        {slip && <p className="v-why"><b>Watch for:</b> {slip.msg ? <Rich text={slip.msg} /> : `step ${slip.step} of problem ${slip.n}, you put ${slip.typed} where it was ${slip.want}.`}</p>}
        <div className="v-recap"><SessionReportView rep={rep} /></div>
      </section>
      <section className="v-panel v-box" aria-label="Your box">{lesson ? <DoneBox g={g} id={lesson.id} /> : null}</section>
    </div>
  );
}

/** The lesson's chapter, its tile now showing the new skill check. */
function DoneBox({ g, id }: { g: number; id: string }) {
  const { progress } = useApp();
  const unit = unitsInGrade(g).find(u => u.entries.some(c => c.id === id));
  if (!unit) return null;
  const n = unit.entries.filter(c => timesDone(progress, c.id) > 0).length;
  return (<>
    <div className="v-bh"><b>{unit.name}</b><span className="v-meta">{n} of {unit.entries.length} done</span></div>
    {unit.entries.map(c => {
      const sc = lastScore(progress, c.id), done = timesDone(progress, c.id) > 0;
      return <Cover key={c.id} pick={c.id === id} className="still" tabIndex={-1} pic={<TilePic svg={lessonPic(c.id)} />} name={c.title} p={(sc ?? 0) / 4}
        word={!done ? "Not started" : sc === 4 ? "Solid" : "Keep going"} />;
    })}
  </>);
}

/** A saved report, opened from the lesson's "Last time" tile or from the grown-up page. */
export function ReportScreen({ rep }: { rep: SessionReport | undefined }) {
  return (
    <FitScreen className="rscreen rsaved">
      {rep && <header className="phead"><h1>{rep.title}</h1><span className="muted">{when(rep.date)}</span></header>}
      {rep ? <div className="bcol rreport"><SessionReportView rep={rep} /></div> : <p className="empty">That report isn't saved on this device.</p>}
    </FitScreen>
  );
}
