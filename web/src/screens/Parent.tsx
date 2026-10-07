import { useEffect, useMemo, useState, type CSSProperties, type ReactNode } from "react";
import { useApp } from "../app/AppState";
import { plural, when } from "../app/format";
import { gradeOf } from "../curriculum/grades";
import { lessonById } from "../curriculum/registry";
import { createRng } from "../curriculum/generators/rng";
import { LEVELS, type Level } from "../engine/mastery/levels";
import { lastScore, type Progress } from "../engine/mastery/progress";
import { chapterScores, firstDate, hasHistory, hintSummary, mistakePatterns, timeParts, weekStats, workedExample, type Pattern, type StepView } from "../app/grownup";
import { SplitScreen } from "../components/screen/Screen";
import { GradeNum } from "../components/Shelf";
import { Pill } from "../components/primitives/Pill";
import { LockIcon } from "../components/primitives/icons";
import { MathLine, Rich } from "../components/primitives/MathLine";
import { toPlainText } from "../curriculum/schemas/math-text";
import { Diagram } from "../components/diagrams/Diagram";
import { explainMistake } from "../components/reports/SessionReportView";
import { GROWN_UP } from "../app/copy";

const PHONE = "(max-width: 699px)", TALL = "(max-width: 699px), (orientation: portrait)";
/** whether the window matches a media query, kept current as it changes */
function useMedia(query: string): boolean {
  const q = useMemo(() => (typeof matchMedia !== "undefined" ? matchMedia(query) : null), [query]);
  const [on, setOn] = useState(!!q?.matches);
  useEffect(() => {
    if (!q) return;
    const f = () => setOn(q.matches);
    q.addEventListener?.("change", f);
    return () => q.removeEventListener?.("change", f);
  }, [q]);
  return on;
}

/**
 * "For the grown-up" (Design's spec): one instance of the Screen master. The list holds the mistake patterns and the
 * scores by chapter; the detail shows the picked pattern worked through, this week's numbers, where hints went and one
 * thing to try at home. Everything comes from this device's saved history.
 */
export function Parent() {
  const { progress, reports } = useApp();
  const g = progress.grade ?? 0;
  return hasHistory(progress, reports) ? <GrownUp g={g} /> : <Empty g={g} />;
}

/** the battery circle (the island's fill), 0 to 4 */
function Bat({ n }: { n: Level | null }) {
  return (
    <span className={`ibat${n === 4 ? " p4" : ""}`} style={{ "--p": (n ?? 0) / 4 } as CSSProperties} role="img"
      aria-label={n == null ? "Not started" : `${n}, ${LEVELS[n]}`}><i /><span aria-hidden>{n ?? ""}</span></span>
  );
}

function Head({ g, sub }: { g: number; sub: string }) {
  return (
    <header className="shead">
      <GradeNum grade={g} />
      <h1>{GROWN_UP}</h1>
      <p className="ysub">{sub}</p>
    </header>
  );
}

const Legend = () => (
  <ul className="gu-legend" aria-label="What the scores mean">
    {([0, 1, 2, 3, 4] as Level[]).map(n => <li key={n}>{n} {LEVELS[n]}</li>)}
  </ul>
);

const Privacy = () => (
  <p className="gu-foot"><LockIcon size={16} /><span><b>Everything here stays on this device.</b> No account. Nothing is sent anywhere.</span></p>
);

function GrownUp({ g }: { g: number }) {
  const { progress, reports, route, go, deps } = useApp();
  // a phone shows the list or the detail; a tall screen (phone or portrait) moves the two small cards into the list,
  // so the worked example gets the detail's whole height
  const phone = useMedia(PHONE), tall = useMedia(TALL);
  const now = deps().now;
  const patterns = useMemo(() => mistakePatterns(reports), [reports]);
  const chapters = useMemo(() => chapterScores(progress, g), [progress, g]);
  const routePick = route.name === "parent" ? route.pick : undefined;
  const pat = patterns.find(p => p.id === routePick) ?? patterns[0] ?? null;
  // on a phone nothing is picked until a row is tapped; beside the list, the first pattern shows
  const on = phone && !routePick ? null : pat;
  const show = routePick && pat ? "detail" : "list";
  const select = (id: string) => go({ name: "parent", pick: id }, phone ? "fwd" : "still");
  const since = firstDate(progress);

  const stats = <Stats chapters={chapters.length} at3={chapters.filter(c => c.score != null && c.score >= 3).length} now={now} />;
  const hints = <HintsCard />;
  const home = <HomeCard pat={pat} g={g} />;

  const list = (
    <>
      <Head g={g} sub={since ? `${plural(progress.log.length, "session")} since ${when(since)}` : gradeOf(g).name} />
      {phone && stats}
      <div className="slbl"><span>Mistake patterns</span>{patterns.length > 0 && <span>wrong / tries</span>}</div>
      {patterns.length ? patterns.slice(0, 8).map(p => (
        <button key={p.id} className={`srow${p === on ? " on" : ""}`} aria-current={p === on ? "true" : undefined} onClick={() => select(p.id)}
          aria-label={`${p.kind}, ${p.lesson}: ${p.wrong} of ${p.tries} problems`}>
          <span className="sname"><b>{p.kind}</b><small>{p.lesson}</small></span><small>{p.wrong} / {p.tries}</small>
        </button>
      )) : <p className="gu-none">No mistakes saved yet.</p>}
      {tall && hints}
      {tall && home}
      <div className="slbl"><span>Scores by chapter</span><span>0 to 4</span></div>
      {chapters.map(c => (
        <div key={c.name} className="gu-chap">
          <div className="srow chap">
            <span className="sname"><b>{c.name}</b><small className={c.score == null ? "none" : undefined}>{c.score == null ? "Not started" : `${c.score} · ${LEVELS[c.score]}`}</small></span>
            <Bat n={c.score} />
          </div>
          {c.lessons.map(l => (
            <div key={l.id} className="srow sles"><span className="sname"><b>{l.title}</b></span><Bat n={l.score} /></div>
          ))}
        </div>
      ))}
      <Legend />
      <p className="gu-how">A chapter's score is the average of its lessons' latest scores, rounded down.</p>
      <Privacy />
    </>
  );

  const detail = (
    <>
      {!phone && stats}
      {pat ? <MistakeCard key={pat.id} pat={pat} /> : (
        <article className="sdtext gu-mcard gu-calm">
          <p className="k">Mistake patterns</p>
          <h2 id="gu-title">No mistakes saved yet.</h2>
          <p className="gu-p">When a lesson has a wrong answer, it shows up here, with their steps next to the right ones.</p>
        </article>
      )}
      {!tall && <div className="gu-row">{hints}{home}</div>}
    </>
  );

  return <SplitScreen className="gu" label="Patterns and scores" show={phone ? show : "detail"} list={list} detail={detail} detailLabel="gu-title" />;
}

/** No history yet: the page says so calmly, and what will show up here. */
function Empty({ g }: { g: number }) {
  return (
    <SplitScreen className="gu" label="Patterns and scores" show="list" detailLabel="gu-title"
      list={<>
        <Head g={g} sub={gradeOf(g).name} />
        <p className="gu-none">Nothing yet. Finished lessons show up here.</p>
        <div className="slbl"><span>Scores</span><span>0 to 4</span></div>
        <Legend />
        <Privacy />
      </>}
      detail={
        <article className="sdtext gu-mcard gu-calm">
          <p className="k">{GROWN_UP}</p>
          <h2 id="gu-title">Nothing to show yet.</h2>
          <p className="gu-p">Once a lesson is finished, this page shows the time spent, the scores by chapter, and any mistake patterns, with their steps next to the right ones.</p>
        </article>
      } />
  );
}

const ClockIcon = () => <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="11" cy="11" r="8" /><path d="M11 6.5V11l3 2" /></svg>;
const TickIcon = () => <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="m5.5 11.5 3.5 3.5 7.5-8" /></svg>;
const StarIcon = () => <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" aria-hidden="true"><path d="M11 3.5l2.2 4.6 5 .7-3.6 3.5.9 5-4.5-2.4-4.5 2.4.9-5L3.8 8.8l5-.7z" /></svg>;

function StatPill({ icon, value, label }: { icon: ReactNode; value: ReactNode; label: string }) {
  return <div className="gu-stat" role="listitem"><span className="ic">{icon}</span><div><b>{value}</b><span>{label}</span></div></div>;
}

/** This week's time and lessons, and the chapters at Proficient 3+ now */
function Stats({ chapters, at3, now }: { chapters: number; at3: number; now: number }) {
  const { progress, reports } = useApp();
  const w = weekStats(progress, reports, now);
  return (
    <div className="gu-stats" role="list" aria-label="This week">
      <StatPill icon={<ClockIcon />} label={w.atLeast ? "Time this week, at least" : "Time this week"}
        value={timeParts(w.ms).map(p => <span key={p.u}>{p.n}<small>{p.u}</small> </span>)} />
      <StatPill icon={<TickIcon />} label="Lessons this week" value={w.lessons} />
      <StatPill icon={<StarIcon />} label="At Proficient 3+" value={<>{at3} <small>of {plural(chapters, "chapter")}</small></>} />
    </div>
  );
}

function Mark({ s }: { s: "ok" | "wrong" | "shown" }) {
  return s === "ok" ? <span className="mk y" role="img" aria-label="Right">✓</span>
    : s === "wrong" ? <span className="mk x" role="img" aria-label="Wrong">✗</span>
    : <span className="mk o" role="img" aria-label="Shown by Show me">?</span>;
}

function StepPill({ v, side }: { v: StepView; side: "their" | "right" }) {
  const t = v.their, state = side === "right" ? "ok" : t.state;
  const cls = side === "right" ? (v.picked ? " good" : "") : t.state === "wrong" ? " bad" : t.state === "shown" ? " shown" : "";
  return (
    <div className={`gu-s${cls}`}>
      <span className="n" aria-label={`Step ${v.n}`}>{v.n}</span>
      <div><small>{v.label}</small>
        <strong>{side === "right" ? toPlainText(v.right) : t.state === "wrong" ? t.typed : toPlainText(t.math!)}</strong>
      </div>
      <Mark s={state} />
    </div>
  );
}

/** the picked pattern, worked through: their first tries beside the right steps, and the lesson's picture of it */
function MistakeCard({ pat }: { pat: Pattern }) {
  const { go } = useApp();
  const ex = useMemo(() => workedExample(pat), [pat]);
  const m = pat.mistake, e = ex?.explanation;
  const pic = e?.diagram && e.diagram.kind !== "chain" ? e : null;
  const said = pic ? pic.steps.map(s => s.narration.replace(/\*\*/g, "")).join(" ") : "";
  return (
    <article className="sdtext gu-mcard">
      <div className="gu-mh">
        <div><p className="k">Mistake pattern · {pat.lesson}</p><h2 id="gu-title">{pat.kind}</h2></div>
        <div className="gu-rate"><span className="badge">{pat.wrong}/{pat.tries}</span>
          <span><b>{pat.wrong} of {plural(pat.tries, "problem")}</b>{pat.runs > 1 ? `in the last ${pat.runs} runs` : "the last time"}</span></div>
      </div>
      {ex ? (
        <div className={`gu-ex${pic ? "" : " nopic"}`}>
          <div className="gu-col">
            <p className="k"><b>Their steps</b> · <MathLine math={ex.statement} /></p>
            {ex.steps.map(v => <StepPill key={v.n} v={v} side="their" />)}
            <p className="gu-why"><b>Step {ex.step}:</b> typed <span className="mono">{m.typed}</span> first.</p>
          </div>
          <div className="gu-col">
            <p className="k"><b>The right steps</b></p>
            {ex.steps.map(v => <StepPill key={v.n} v={v} side="right" />)}
            <p className="gu-why"><b className="y">Step {ex.step}:</b> <Rich text={explainMistake(m)} /></p>
          </div>
          {pic && (
            <figure className="gu-col gu-pic">
              <figcaption className="k"><b>The picture</b></figcaption>
              <div className="sppic" role="img" aria-label={said}>
                <div className="viz"><Diagram diagram={pic.diagram!} timeline={pic.timeline} at={pic.timeline.length - 1} fit /></div>
              </div>
            </figure>
          )}
        </div>
      ) : (
        <p className="gu-p">Typed <b className="mono">{m.typed}</b>, the answer was <b className="mono">{m.want}</b>. <Rich text={explainMistake(m)} /></p>
      )}
      <div className="gu-more"><Pill onClick={() => go({ name: "report", key: pat.report.key }, "fwd")}>See that session ›</Pill></div>
    </article>
  );
}

/** where hints, Show me and quick retries went, over every saved session */
function HintsCard() {
  const { progress } = useApp();
  const h = hintSummary(progress), max = Math.max(1, ...h.rows.map(r => r.count));
  const lines = [
    h.total ? `${plural(h.total, "hint")} in ${plural(h.sessions, "session")}.` : `No hints in ${plural(h.sessions, "session")}.`,
    h.shown ? `${plural(h.shown, "step")} filled in with Show me.` : "",
    h.rushed ? `${plural(h.rushed, "quick retry")} looked like guessing.` : "",
  ].filter(Boolean);
  return (
    <section className="gu-card" aria-labelledby="gu-hints">
      <h3 id="gu-hints">Where help was used</h3>
      <p>{lines.join(" ")}</p>
      {h.rows.length > 0 && (
        <ul className="gu-bars">{h.rows.map(r => (
          <li key={r.title} className="gu-hb"><span>{r.title}</span><span className="tr" aria-hidden><i style={{ width: `${(r.count / max) * 100}%` }} /></span><b>{r.count}</b></li>
        ))}</ul>
      )}
    </section>
  );
}

/** one thing to do together: a problem like the one that went wrong (or the lowest score), and the lesson's idea */
function HomeCard({ pat, g }: { pat: Pattern | null; g: number }) {
  const { progress } = useApp();
  const id = pat?.lessonId ?? lowest(progress, g);
  const lesson = id ? lessonById(id) : undefined;
  const made = useMemo(() => {
    if (!lesson) return null;
    try {
      const p = lesson.generate(createRng([...lesson.id].reduce((a, c) => (a * 31 + c.charCodeAt(0)) >>> 0, 7)), 0);
      const ex = lesson.explain(p, lesson.answers(p));
      return { math: lesson.display(p), idea: ex.idea?.[0] };
    } catch { return null; }
  }, [lesson]);
  if (!lesson || !made) return null;
  const step = pat && pat.mistake.cat !== "plan" ? pat.mistake.label : null;
  return (
    <section className="gu-card gu-home" aria-labelledby="gu-home">
      <p className="k">Try together at home</p>
      <h3 id="gu-home">Do one like it together.</h3>
      {made.idea && <p><Rich text={made.idea} /></p>}
      <p>{step ? <>Ask them to say each step out loud, most of all <b>{step.toLowerCase()}</b>.</> : <>Ask them to say each step out loud.</>}</p>
      <div className="gu-say"><MathLine math={made.math} /></div>
    </section>
  );
}

/** the lowest-scored lesson of the grade, else the latest one finished */
function lowest(p: Progress, g: number): string | undefined {
  const scored = Object.keys(p.scores).filter(id => lessonById(id)?.grade === g).sort((a, b) => (lastScore(p, a) ?? 4) - (lastScore(p, b) ?? 4));
  return scored[0] ?? p.log.find(e => e.mode === "practice" && lessonById(e.key))?.key;
}
