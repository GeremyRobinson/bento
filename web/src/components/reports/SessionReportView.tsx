import { lessonById } from "../../curriculum/registry";
import { entryById, titleOf } from "../../app/curriculum";
import { CATEGORIES } from "../../engine/diagnosis/diagnose";
import { LEVELS } from "../../engine/mastery/levels";
import type { Mistake, SessionReport } from "../../engine/session/types";
import { LEVEL_SENTENCES, plural, summaryLine, when } from "../../app/format";
import { MathLine, Rich } from "../primitives/MathLine";
import { ProblemView } from "../practice/ProblemView";
import { ScoreChip } from "../primitives/Score";
import { GROWN_UP } from "../../app/copy";

/** The step, then what went wrong; the step's name is left off when the message already starts with it. */
export const explainMistake = (m: { cat: Mistake["cat"]; label: string; msg: string }) => {
  if (m.cat !== "concept" && CATEGORIES[m.cat]) return `${CATEGORIES[m.cat][1]} Tip: ${CATEGORIES[m.cat][2]}`;
  const lead = m.label.toLowerCase().split(" ").slice(0, 2).join(" ");
  return m.msg.toLowerCase().startsWith(lead) ? m.msg : `${m.label}: ${m.msg}`;
};

/** "What you did" and "For the grown-up": every problem with its worked lines, and every mistake grouped by kind. */
export function SessionReportView({ rep }: { rep: SessionReport }) {
  const groups = new Map<string, { n: number; first: Mistake }>();
  for (const m of rep.mistakes) {
    const g = groups.get(m.kind);
    if (g) g.n++; else groups.set(m.kind, { n: 1, first: m });
  }
  const sorted = [...groups.entries()].sort((a, b) => b[1].n - a[1].n);
  const rushed = rep.mistakes.filter(m => m.rushed).length;
  const skills = [...new Set(rep.probs.map(p => p.lessonId))].filter(id => entryById(id) || lessonById(id)).map(titleOf);
  return (
    <>
      <section className="panel">
        <div className="head"><h2>What you did</h2><span className="muted">{when(rep.date)}</span></div>
        <div className="prose indent">
          <p>{rep.mode === "test" ? "Tested " : "Practiced "}{skills.map((t, i) => <span key={i}>{i ? ", " : ""}<b>{t}</b></span>)}.</p>
          <p>{summaryLine(rep)}</p>
        </div>
        <div className="probs">
          {rep.probs.map((pr, k) => {
            const l = lessonById(pr.lessonId), p = l?.restore(pr.problem);
            if (!l || p == null) return null;
            const tag = pr.shown ? ["busy", `shown ${pr.shown}×`] : pr.wrong ? ["err", plural(pr.wrong, "mistake")] : pr.hints ? ["busy", plural(pr.hints, "hint")] : ["ok", "no mistakes"];
            return (
              <details className="card" key={k}>
                <summary><span className="badge">{k + 1}</span><span className="name">{rep.mode !== "practice" ? l.title : `Problem ${k + 1}`}</span><span className={`dot ${tag[0]}`} /><span className="muted">{tag[1]}</span></summary>
                <ProblemView lessonId={pr.lessonId} problem={p} story={!!pr.story} />
                <div className="work">
                  {pr.work.map((w, j) => <div key={j} className={`workline${w.shown ? " shown" : ""}`}><span className="k">Step {j + 1}</span><span className="wl"><MathLine math={w.math} /></span></div>)}
                </div>
              </details>
            );
          })}
        </div>
      </section>
      <section className="panel rgrown">
        <div className="head"><h2>{GROWN_UP}</h2><ScoreChip n={rep.level} words /></div>
        <div className="prose indent">
          <p>Score {rep.level} of 4: {LEVELS[rep.level]}. {LEVEL_SENTENCES[rep.level]}</p>
          {rushed > 0 && <p>{plural(rushed, "answer")} came very quickly after a miss, which usually means guessing.</p>}
        </div>
        {sorted.length ? (
          <>
            <h3 className="label indent">Mistake patterns, most common first</h3>
            <div className="facts oncard">
              {sorted.map(([k, g]) => <div className="pattern" key={k}><span><b>{k}</b><span className="k"><Rich text={explainMistake(g.first)} /></span></span><span className="v">×{g.n}</span></div>)}
            </div>
            <h3 className="label indent">Every mistake</h3>
            <div className="facts mlist oncard">
              {rep.mistakes.map((m, i) => (
                <div key={i}><span>
                  <span className="k">Problem {m.n} · Step {m.step} · {m.label}{rep.mode !== "practice" && (entryById(m.lessonId) || lessonById(m.lessonId)) ? ` · ${titleOf(m.lessonId)}` : ""}</span>
                  <span>Typed <b className="mono">{m.typed}</b>, answer <b className="mono">{m.want}</b>. {m.kind}{m.rushed ? " (quick retry)" : ""}.</span>
                </span></div>
              ))}
            </div>
          </>
        ) : <p className="indent">No mistakes this time.</p>}
      </section>
    </>
  );
}
