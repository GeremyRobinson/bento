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
import { Cover, PreviewWell, statusOf } from "./Home";
import { Marks } from "../components/Masters";
import { checkedCount } from "../app/rings";
import { isCheckKey, lessonOfCheck } from "../engine/mastery/skills";
import { plainProblem } from "../components/practice/ProblemView";
import { Rich } from "../components/primitives/MathLine";
import { lessonPic } from "../components/TilePics";
import { isReady, unitsInGrade } from "../app/curriculum";

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
      <p className="muted">{grade > from ? "You're ahead. This grade will be a challenge." : grade < from ? "A few things to practice first. You'll move fast." : "Right where you should be."}</p>
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
    : "Next time, Today brings this back so you can try again.";
  const why = skill ? `You finished the lesson. The skill check shows what you remember. ${then}`
    : test ? `${rep.clean} of ${rep.total} problems had every step right. ${then}` : `${rep.clean} of ${rep.total} problems with no mistakes. ${then}`;
  // one thing to watch for: the check's own slip, else the lesson's from just before it
  const practice = skill && lesson ? reports[lesson.id] : undefined;
  const watch = watchFor(rep, practice && rep.date - practice.date < 36e5 ? practice : undefined);
  const typed = (k: number) => rep.mistakes.filter(m => m.n === k + 1).pop()?.typed;
  // Back to your box is the one filled button, unless the next lesson waits: then that is (UI model v57)
  const nextBtn = !test && !review && next && rep.level >= 3;
  return (
    <div className="o-state done v-done">
      <section className="o-panel v-result" aria-label="Done">
        <span className="o-label o-in">{`Done \u00b7 ${lesson?.title ?? rep.title}`}</span>
        <span className="o-in" role="img" aria-label={`Score ${rep.level} of 4`}><Marks n={4} on={rep.level} /></span>
        <h2 className="o-title o-in">{rep.level} of 4{skill ? " on your own" : ""}: {words}.</h2>
        <p className="o-why o-in">{why}</p>
        <div className="o-row o-in">
          {nextBtn && <button className="o-btn fill" onClick={() => go({ name: "learn", lessonId: next.id }, "next")}>Next: {next.title}</button>}
          {test && <button className="o-btn" onClick={() => startTest(rep.key)}>Take it again</button>}
          <button className={`o-btn${nextBtn ? "" : " fill"}`} onClick={() => go({ name: "home", ...(lesson ? { pick: lesson.id } : {}) }, "back")}>Back to your box</button>
        </div>
        {low && lesson && <BuildUp lessonId={lesson.id} />}
        {rep.mode !== "practice" && rep.probs.length > 0 && <div className="v-recap o-in">
          <span className="o-label">{skill ? `Your ${SKILL_CHECK.toLowerCase()}` : review ? "Your review" : "Your test"}</span>
          {/* problem by problem: the sum with its answer, what was typed when it missed, and the tick or cross */}
          <ul className="v-chips">{rep.probs.map((x, k) => {
            const right = !x.wrong && !x.shown, put = right ? undefined : typed(k);
            return <li key={k} className={`v-rp ${right ? "right" : "wrong"}`}><span>{plainProblem(x.lessonId, x.problem, true)}</span>
              {put != null && <small>you put {put}</small>}<span className="mk" aria-hidden="true">{right ? "\u2713" : "\u2715"}</span>
              <span className="visually-hidden">{right ? "Right" : "Not this time"}</span></li>;
          })}</ul>
          {watch && <p className="o-why"><b>Watch for:</b> <Rich text={watch} /></p>}
        </div>}
        {watch && !(rep.mode !== "practice" && rep.probs.length > 0) && <p className="o-why o-in"><b>Watch for:</b> <Rich text={watch} /></p>}
      </section>
      {lesson ? <DoneBox g={g} id={lesson.id} /> : <section className="o-panel o-box" aria-label="Your box" />}
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

/** The lesson's chapter, as the box shows it: its tile now showing the new skill check, picked. A tap goes to the box
 *  with that lesson picked. */
function DoneBox({ g, id }: { g: number; id: string }) {
  const { progress, go, now } = useApp();
  const unit = unitsInGrade(g).find(u => u.entries.some(c => c.id === id));
  if (!unit) return <section className="o-panel o-box" aria-label="Your box" />;
  const n = checkedCount(progress, unit.entries);
  return (
    <section className="o-panel o-box" aria-label="Your box">
      <div className="o-bh"><h2 className="o-head">{unit.name}</h2><span className="o-st">{n} of {unit.entries.length} done</span></div>
      <div className="o-grid">{unit.entries.map(c => {
        const st = statusOf(progress, g, c.id, now()), last = progress.checks?.[c.id]?.last;
        return <Cover key={c.id} sel={c.id === id} disabled={!isReady(c.id)} pic={lessonPic(c.id)} name={c.title} p={(last ?? 0) / 4} word={st.word} tone={st.tone}
          onClick={() => go({ name: "home", pick: c.id }, "back")} label={`${c.title}, ${st.word}${last != null ? `, skill check ${last} of 4` : ""}`} />;
      })}</div>
    </section>
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
