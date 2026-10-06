import { Pill } from "../components/primitives/Pill";
import { useEffect, useMemo, useState, type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { mins, when } from "../app/format";
import { reduceMotion } from "../app/transition";
import { bandOf, gradeOf, tintStyle } from "../curriculum/grades";
import { placeKey, placementResult } from "../engine/session/practice";
import { lessonById, lessonsInGrade } from "../curriculum/registry";
import { LEVELS } from "../engine/mastery/levels";
import { BuildUp } from "../components/BuildUp";
import type { SessionReport } from "../engine/session/types";
import { SessionReportView } from "../components/reports/SessionReportView";
import { FitScreen } from "../components/screen/Screen";
import { ALL_LESSONS, PRACTICE_AGAIN } from "../app/copy";

function Confetti() {
  const bits = useMemo(() => {
    const cols = ["var(--c0)", "var(--c1)", "var(--c2)", "var(--acc)"], r = (lo: number, hi: number) => lo + Math.floor(Math.random() * (hi - lo + 1));
    return Array.from({ length: 28 }, (_, i) => ({ "--x": `${r(-160, 160)}px`, "--y": `${r(-220, -80)}px`, "--r": `${r(-300, 300)}deg`, "--c": cols[i % 4], "--d": `${(i % 7) * 0.03}s` }) as CSSProperties);
  }, []);
  return <div className="confetti" aria-hidden="true">{bits.map((s, i) => <i key={i} style={s} />)}</div>;
}

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
  if (!rep) return <FitScreen className="rnone"><section className="panel"><p className="empty">Nothing finished yet.</p><div className="actions"><Pill go onClick={() => go({ name: "home" })}>{ALL_LESSONS}</Pill></div></section></FitScreen>;
  if (rep.key.startsWith("place:")) return <Placed rep={rep} />;
  const lesson = lessonById(rep.key), test = rep.mode === "test", review = rep.mode === "review";
  const grade = lesson ? lessonsInGrade(lesson.grade) : [], k = lesson ? grade.indexOf(lesson) : -1, next = grade[k + 1];
  const lastLesson = lessonById(rep.probs[rep.probs.length - 1]?.lessonId ?? "");
  const band = bandOf(lesson?.grade ?? lastLesson?.grade ?? progress.grade ?? 9);
  const low = rep.mode === "practice" && rep.level <= 1;
  return (
    <FitScreen className="rscreen">
      <section className="panel rsum">
        <div className={`donehead s${rep.level}`}>
          {rep.level >= 3 && band !== "high" && <Confetti />}
          <div className="ring"><svg viewBox="0 0 92 92"><circle className="trk" cx="46" cy="46" r="40" /><circle className="val" cx="46" cy="46" r="40" pathLength={1} style={{ strokeDasharray: 1, strokeDashoffset: 1 - rep.level / 4 }} /></svg><b>{rep.level}</b></div>
          <div className="donetext"><h2>{LEVELS[rep.level]}</h2><p className="muted">Score {rep.level} of 4 · {Math.round(rep.pct * 100)}% of steps right the first time</p></div>
        </div>
        <div className="bento">
          <div><span className="k">XP earned</span><span className="v"><CountUp to={rep.xp} pre="+" /></span></div>
          <div><span className="k">{test ? "All steps right" : "No mistakes"}</span><span className="v">{rep.clean}/{rep.total}</span></div>
          <div><span className="k">Time</span><span className="v">{mins(rep.ms)}<small className="muted"> min</small></span></div>
        </div>
        {low && <BuildUp lessonId={rep.key} />}
        <div className="actions">
          {rep.mode === "practice" && next && <Pill go onClick={() => go({ name: "learn", lessonId: next.id }, "next")}>Next lesson</Pill>}
          {test ? <Pill go onClick={() => startTest(rep.key)}>Take it again</Pill>
            : !review && lesson && <Pill onClick={() => startLesson(lesson.id)}>{PRACTICE_AGAIN}</Pill>}
          <Pill onClick={() => go({ name: "home" }, "back")}>{ALL_LESSONS}</Pill>
        </div>
      </section>
      <div className="bcol rreport">
        <SessionReportView rep={rep} />
      </div>
    </FitScreen>
  );
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
