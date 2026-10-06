import { useApp } from "../app/AppState";
import { gradeAverage, isReady, testKey } from "../app/curriculum";
import { plural, when } from "../app/format";
import { CATALOG } from "../curriculum/catalog";
import { GRADES } from "../curriculum/grades";
import { LEVELS, type Level } from "../engine/mastery/levels";
import { lastScore } from "../engine/mastery/progress";
import type { Mistake } from "../engine/session/types";
import { ScoreChip } from "../components/primitives/Score";
import { Rich } from "../components/primitives/MathLine";
import { explainMistake } from "../components/reports/SessionReportView";


/** "For the grown-up": scores by grade, mistake patterns across sessions, what needs practice, and every recent session. */
export function Parent() {
  const { progress, reports, go } = useApp();
  const totals: Record<string, number> = {}, first: Record<string, Mistake> = {};
  for (const e of progress.log) for (const [k, n] of Object.entries(e.cats ?? {})) totals[k] = (totals[k] ?? 0) + n;
  for (const r of Object.values(reports)) for (const m of r.mistakes ?? []) first[m.kind] ??= m;
  const top = Object.entries(totals).sort((a, b) => b[1] - a[1]).slice(0, 8);
  const weak = CATALOG.filter(c => { const s = lastScore(progress, c.id); return s != null && s <= 2; });
  const hints = progress.log.reduce((a, e) => a + (e.hints || 0), 0), rushed = progress.log.reduce((a, e) => a + (e.rushed || 0), 0);
  const byGrade = GRADES.flatMap(gd => {
    const a = gradeAverage(progress, gd.grade), t = progress.tests[testKey(gd.grade)];
    if (a == null && !t) return [];
    return [{ gd, a, t }];
  });

  return (
    <>
      <div className="bgrown">
        <section className="panel">
          <div className="head"><h2>Scores by grade</h2><span className="muted">0 to 4</span></div>
          <div className="facts oncard">
            {byGrade.length ? byGrade.map(({ gd, a, t }) => (
              <div className="pattern" key={gd.grade}>
                <span><b>{gd.name}</b><span className="k">Lesson average {a == null ? "—" : `${a.toFixed(1)} of 4`} · check-up {t ? `${t.last}: ${LEVELS[t.last]}` : "not taken"}</span></span>
                <ScoreChip n={t ? t.last : a == null ? null : (Math.round(a) as Level)} />
              </div>
            )) : <div><span>No lessons finished yet.</span></div>}
          </div>
          <ul className="slegend" aria-label="What the scores mean">
            {([4, 3, 2, 1, 0] as Level[]).map(n => <li key={n}><ScoreChip n={n} /><span>{LEVELS[n]}</span></li>)}
          </ul>
          <p className="muted indent">Based on how many steps were right on the first try. Hints count half.</p>
        </section>
        <section className="panel">
          <div className="head"><h2>Mistake patterns</h2>{progress.log.length > 0 && <span className="muted">last {plural(progress.log.length, "session")}</span>}</div>
          {top.length ? (
            <div className="facts oncard">
              {top.map(([k, n]) => { const m = first[k]; return (
                <div className="pattern" key={k}><span><b>{k}</b>{m && <span className="k"><Rich text={explainMistake(m)} /></span>}</span><span className="v">×{n}</span></div>
              ); })}
            </div>
          ) : <p className="indent">No mistakes recorded yet.</p>}
          <p className="muted indent">{plural(hints, "hint")} used{rushed ? `, ${plural(rushed, "quick retry")} that looked like guessing` : ""}.</p>
        </section>
        {weak.length > 0 && (
          <section className="panel"><div className="head"><h2>Needs more practice</h2></div>
            <div className="lessons">{weak.map(c => (
              <button key={c.id} className="lesson" disabled={!isReady(c.id)} onClick={() => go({ name: "learn", lessonId: c.id })}>
                <ScoreChip n={lastScore(progress, c.id)} /><span className="name">{c.title}</span><span className="muted">{GRADES[c.grade]?.short}</span>
              </button>
            ))}</div>
          </section>
        )}
        <section className="panel">
          <div className="head"><h2>Recent sessions</h2></div>
          {progress.log.length ? (
            <div className="lessons">{progress.log.slice(0, 20).map((e, i) => (
              <button key={i} className="lesson" disabled={!reports[e.key]} onClick={() => go({ name: "report", key: e.key })}>
                <ScoreChip n={e.level} /><span className="name">{e.title}</span><span className="muted">{when(e.date)}{e.mode === "test" ? " · test" : ""}</span>
              </button>
            ))}</div>
          ) : <p style={{ padding: "0 5px" }}>Nothing yet. Finished lessons and tests show up here.</p>}
        </section>
      </div>
    </>
  );
}
