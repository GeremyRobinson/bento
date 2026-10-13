import { Pill } from "../components/primitives/Pill";
import { useEffect, useState, type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { when } from "../app/format";
import { reduceMotion } from "../app/transition";
import { gradeOf, tintStyle } from "../curriculum/grades";
import { placeKey, placementResult } from "../engine/session/practice";
import { lessonById, requireLesson } from "../curriculum/registry";
import { toPlainText } from "../curriculum/schemas/math-text";
import { BuildUp } from "../components/BuildUp";
import type { SessionReport } from "../engine/session/types";
import { SessionReportView } from "../components/reports/SessionReportView";
import { FitScreen } from "../components/screen/Screen";
import { ALL_LESSONS, SKILL_CHECK } from "../app/copy";
import { upNext } from "../app/today";
import { PreviewWell, statusOf } from "./Home";
import { isCheckKey, learned, lessonOfCheck } from "../engine/mastery/skills";
import { plainProblem } from "../components/practice/ProblemView";
import { Cover } from "../components/Cover";
import { Rich } from "../components/primitives/MathLine";
import { lessonPic, TilePic } from "../components/TilePics";
import { isReady, unitsInGrade } from "../app/curriculum";
import { learnedCount } from "../app/rings";

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
  const { lastReport: rep, progress, reports, go, startTest } = useApp();
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
  // the skill check after a lesson scores the lesson (v2 model): "n of 4 on your own"
  const skill = isCheckKey(rep.key);
  const lesson = lessonById(skill ? lessonOfCheck(rep.key) : rep.key), test = rep.mode === "test" && !skill, review = rep.mode === "review";
  const lastLesson = lessonById(rep.probs[rep.probs.length - 1]?.lessonId ?? "");
  const g = lesson?.grade ?? lastLesson?.grade ?? progress.grade ?? 5;
  // what comes next is what Today will bring
  const up = lesson ? upNext(progress, g) : null, next = up && up.entry.id !== lesson?.id && lessonById(up.entry.id) ? up.entry : undefined;
  const low = !test && !review && rep.level <= 1;
  // v2 (G 2026-10-13): what the score means in words, what Today does next, and the lesson's tile filling in its chapter
  const words = ["not there yet", "just starting", "getting there", "nearly there", "you\u2019ve got it"][rep.level];
  const then = test ? "Today keeps track of how the test went." : rep.level >= 3
    ? (next ? `Next time, Today brings the next lesson: ${next.title}.` : "Next time, Today moves on to something new.")
    : "Next time, Today brings this back for another go, so it sticks.";
  const why = skill ? `You finished the lesson. The skill check shows how much stuck. ${then}`
    : test ? `${rep.clean} of ${rep.total} problems had every step right. ${then}` : `${rep.clean} of ${rep.total} problems with no mistakes. ${then}`;
  // one thing to watch for: the check's own slip, else the lesson's from just before it
  const practice = skill && lesson ? reports[lesson.id] : undefined;
  const watch = watchFor(rep, practice && rep.date - practice.date < 36e5 ? practice : undefined);
  return (
    <div className="screen v-work v-done">
      <section className="v-panel v-result" aria-label="Done">
        <span className="v-label">{`Done \u00b7 ${lesson?.title ?? rep.title}`}</span>
        <span className="v-seg" aria-label={`Score ${rep.level} of 4`}>{[1, 2, 3, 4].map(k => <i key={k} className={k <= rep.level ? "on" : undefined} />)}</span>
        <h2>{rep.level} of 4{skill ? " on your own" : ""}: {words}.</h2>
        <p className="v-why">{why}</p>
        <div className="v-row">
          {!test && !review && next && rep.level >= 3 && <button className="v-go" onClick={() => go({ name: "learn", lessonId: next.id }, "next")}>Next: {next.title}</button>}
          {test && <button className="v-plain" onClick={() => startTest(rep.key)}>Take it again</button>}
          <button className="v-plain" onClick={() => go({ name: "home", ...(lesson ? { pick: lesson.id } : {}) }, "back")}>Back to your box</button>
        </div>
        {low && lesson && <BuildUp lessonId={lesson.id} />}
        {rep.mode !== "practice" && rep.probs.length > 0 && <div className="v-recap">
          <span className="v-label">{skill ? `Your ${SKILL_CHECK.toLowerCase()}` : review ? "Your review" : "Your test"}</span>
          {rep.probs.map((x, k) => <div key={k} className="v-rp"><b>{plainProblem(x.lessonId, x.problem, true)}</b><span>{!x.wrong && !x.shown ? "Right" : "Not this time"}</span></div>)}
          {watch && <p className="v-why"><b>Watch for:</b> <Rich text={watch} /></p>}
        </div>}
        {watch && !(rep.mode !== "practice" && rep.probs.length > 0) && <p className="v-why"><b>Watch for:</b> <Rich text={watch} /></p>}
      </section>
      <section className="v-panel v-box" aria-label="Your box">{lesson ? <DoneBox g={g} id={lesson.id} /> : null}</section>
    </div>
  );
}

/**
 * Done's one Watch for line, in the child's own words (v2 model): a skill check's missed answer is shown worked ("For
 * 52 × 26 you put 1300. Step by step: 52 × 20 = 1040, 52 × 6 = 312, 1040 + 312 = 1352."); else what the lesson said to
 * look at when a step went wrong ("Look again at the lit strip: it's 20 across and 52 down."), never the grown-up's
 * category.
 */
function watchFor(rep: SessionReport, practice?: SessionReport): string | undefined {
  const m = rep.mistakes[0], pr = m && isCheckKey(rep.key) && m.label === "Final answer" ? rep.probs[m.n - 1] : undefined;
  if (m && pr) {
    try {
      const works = requireLesson(pr.lessonId).answers(pr.problem).steps.map(st => toPlainText(st.work));
      return `For ${plainProblem(pr.lessonId, pr.problem)} you put ${m.typed}. Step by step: ${works.join(", ")}.`;
    } catch { /* a lesson without worked steps: what it said below */ }
  }
  const all = [...rep.mistakes, ...(practice?.mistakes ?? [])], w = all.find(x => x.say) ?? all[0];
  return w && (w.say ?? w.msg);
}

/** The lesson's chapter, its tile now showing the new skill check; a tap goes to the box with that lesson picked. */
function DoneBox({ g, id }: { g: number; id: string }) {
  const { progress, go, now } = useApp();
  const unit = unitsInGrade(g).find(u => u.entries.some(c => c.id === id));
  if (!unit) return null;
  const n = learnedCount(progress, unit.entries);
  return (<>
    <div className="v-bh"><b>{unit.name}</b><span className="v-meta">{n} of {unit.entries.length} done</span></div>
    {unit.entries.map(c => {
      // a check of 3 or 4 is learned and fills the ring (v2 spec C3); the status wraps rather than being cut
      const st = statusOf(progress, g, c.id, now());
      return <Cover key={c.id} pick={c.id === id} disabled={!isReady(c.id)} pic={<TilePic svg={lessonPic(c.id)} />} name={c.title} p={learned(progress, c.id) ? 1 : (st.score ?? 0) / 4} tone={st.tone}
        word={<>{st.word}{st.checked && st.score != null && <span className="v-sc">{` \u00b7 ${st.score}/4`}</span>}</>}
        onClick={() => go({ name: "home", pick: c.id }, "back")} aria-label={`${c.title}, ${st.word}${st.checked && st.score != null ? `, skill check ${st.score} of 4` : ""}`} />;
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
