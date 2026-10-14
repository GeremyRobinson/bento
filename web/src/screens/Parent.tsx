import { useMemo, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { useApp } from "../app/AppState";
import { plural } from "../app/format";
import { entriesInGrade, isReady, unitsInGrade } from "../app/curriculum";
import { lessonById } from "../curriculum/registry";
import { createRng } from "../curriculum/generators/rng";
import { LEVELS, type Level } from "../engine/mastery/levels";
import type { Progress } from "../engine/mastery/progress";
import { checkScore, dueBack, learnedNow, REVIEW_DAYS, toGoOver } from "../engine/mastery/skills";
import { checksAhead, hintSummary, mistakePatterns, usualWeek, weekRows, type Pattern, type WeekRow } from "../app/grownup";
import { LockIcon } from "../components/primitives/icons";
import { MathLine, Rich } from "../components/primitives/MathLine";
import { explainMistake } from "../components/reports/SessionReportView";
import { ORing, OSlider } from "../components/Masters";
import { motionOff } from "../app/settings";

const DAY = 864e5;
const days = (n: number) => plural(n, "day");
const short = (t: number) => new Date(t).toLocaleDateString("en-US", { month: "short", day: "numeric" });
const slash = (t: number) => { const d = new Date(t); return `${d.getMonth() + 1}/${d.getDate()}`; };
/** a check this week by its weekday, later ones by the date */
const whenDue = (due: number, now: number) => due - now < 6 * DAY ? new Date(due).toLocaleDateString("en-US", { weekday: "long" }) : short(due);

/**
 * "For the grown-up" (UI model v63): three questions. The page starts on three cards, each with its answer; open one
 * and the three become a two-line bar you tap or swipe along, never backing out. Plain words, no marks. Everything
 * comes from this device's saved history.
 */
export function Parent() {
  const { progress, reports, now: clock } = useApp();
  const g = progress.grade ?? 0;
  const [now] = useState(clock);
  const [q, setQ] = useState<number | null>(null);
  const d = useMemo(() => gather(progress, reports, g, now), [progress, reports, g, now]);
  const pane = useRef<HTMLDivElement>(null);

  const open = (to: number, dir = 0) => {
    setQ(to);
    const el = pane.current;
    if (dir && el?.animate && !motionOff())
      requestAnimationFrame(() => pane.current?.animate([{ transform: `translateX(${dir * 40}px)`, opacity: 0 }, { transform: "none", opacity: 1 }], { duration: 300, easing: "cubic-bezier(.2,.8,.2,1)" }));
  };
  // swipe left or right to move between the three questions
  const sw = useRef({ on: false, x: 0, y: 0, t: 0 });
  const down = (e: React.PointerEvent) => { if (q == null || (e.pointerType === "mouse" && e.button)) return; sw.current = { on: true, x: e.clientX, y: e.clientY, t: Date.now() }; };
  const up = (e: React.PointerEvent) => {
    const s = sw.current;
    if (!s.on || q == null) return;
    s.on = false;
    const dx = e.clientX - s.x, dy = e.clientY - s.y;
    if (Math.abs(dx) < 48 || Math.abs(dx) < Math.abs(dy) * 1.5 || Date.now() - s.t > 800) return;
    const to = q + (dx < 0 ? 1 : -1);
    if (to >= 0 && to <= 2) open(to, dx < 0 ? 1 : -1);
  };

  const QS = ["Are they doing the work?", "Is it sticking?", "Where can I help?"];
  const work = [`${d.thisWeek.min} min`, d.usual ? `this week · a usual week is about ${d.usual.min}` : "this week"];
  const stick = [`${d.learned} learned`, `out of ${plural(d.all, "lesson")}`];
  const help = d.focus ? ["1 thing", "to try together this week"] : ["Nothing yet", "Finished lessons show up here"];

  if (q == null) {
    const card = (i: number, a: string[], pic: ReactNode) => (
      <button className="o-panel o-qcard" onClick={() => open(i)} aria-label={`${QS[i]} ${a[0]}, ${a[1]}`}>
        <span className="o-label">{QS[i]}</span>
        <span className="o-ansbig"><span className="o-bignum">{a[0]}</span><span className="o-st">{a[1]}</span></span>
        <span className="o-qpic">{pic}</span>
      </button>
    );
    return (
      <div className="o-state report" aria-label="For the grown-up">
        {card(0, work, <WeekBars rows={d.weeks} sm />)}
        {card(1, stick, <>
          <ORing p={d.all ? d.learned / d.all : 0} label={`${d.learned}/${d.all}`} size="l" />
          <span className="o-rows">
            <span className="o-line2"><span>Go over</span><b>{d.over.length}</b></span>
            <span className="o-line2"><span>Getting stronger</span><b>{d.grow.length}</b></span>
            <span className="o-line2"><span>Stuck for good</span><b>{d.stuck.length}</b></span>
          </span>
        </>)}
        {card(2, help, d.focus && <>
          <span className="o-nm">{d.focus.lesson}</span>
          {d.focus.pat && <Chips pat={d.focus.pat} />}
          {d.focus.pat && <span className="o-st"><Rich text={explainMistake(d.focus.pat.mistake)} /></span>}
        </>)}
      </div>
    );
  }

  const tabs = [
    { id: "0", label: <><small>Doing the work</small><small className="o-short">The work</small><b>{work[0]}</b></>, aria: `Doing the work, ${work[0]}` },
    { id: "1", label: <><small>Is it sticking</small><small className="o-short">Sticking</small><b>{stick[0]}</b></>, aria: `Is it sticking, ${stick[0]}` },
    { id: "2", label: <><small>Where to help</small><small className="o-short">Help</small><b>{help[0]}</b></>, aria: `Where to help, ${help[0]}` },
  ];
  return (
    <div className="o-state report open" aria-label="For the grown-up" onPointerDown={down} onPointerUp={up} onPointerCancel={() => { sw.current.on = false; }}>
      <OSlider tabs={tabs} value={String(q)} onPick={v => open(+v, +v > q ? 1 : -1)} label="Three questions" className="two" />
      <div className="o-repd" ref={pane} key={q}>
        {q === 0 ? <Work d={d} /> : q === 1 ? <Sticking d={d} /> : <Help d={d} />}
      </div>
    </div>
  );
}

type Data = ReturnType<typeof gather>;

function gather(p: Progress, reports: Parameters<typeof mistakePatterns>[0], g: number, now: number) {
  const all = entriesInGrade(g).filter(c => isReady(c.id));
  const passes = (id: string) => p.checks?.[id]?.passes ?? 0;
  const over = all.filter(c => dueBack(p, c.id, now) || toGoOver(p, c.id));
  const grow = all.filter(c => learnedNow(p, c.id, now) && passes(c.id) < REVIEW_DAYS.length);
  const stuck = all.filter(c => learnedNow(p, c.id, now) && passes(c.id) >= REVIEW_DAYS.length);
  const weeks = weekRows(p, reports, now), patterns = mistakePatterns(reports);
  const pat = patterns[0] ?? null, focusId = pat?.lessonId ?? lowest(p, g);
  return {
    p, now, all: all.length, learned: grow.length + stuck.length, over, grow, stuck, passes,
    weeks, thisWeek: weeks[weeks.length - 1]!, usual: usualWeek(weeks), patterns,
    focus: focusId ? { id: focusId, lesson: lessonById(focusId)?.title ?? focusId, pat } : null,
    hints: hintSummary(p), ahead: checksAhead(p, now).slice(0, 3),
    units: unitsInGrade(g).map(u => {
      const done = u.entries.flatMap(c => { const s = checkScore(p, c.id); return s == null ? [] : [{ id: c.id, title: c.title, s, over: dueBack(p, c.id, now) }]; });
      const score = done.length ? (Math.floor(done.reduce((a, x) => a + x.s, 0) / done.length) as Level) : null;
      return { name: u.name, n: u.entries.length, done, score };
    }),
  };
}

/** one bar per week, its minutes on top, the week under it; this week's bar is still filling */
function WeekBars({ rows, sm }: { rows: WeekRow[]; sm?: boolean }) {
  const max = Math.max(1, ...rows.map(r => r.min)), last = rows.length - 1;
  return (
    <span className={`o-wbars${sm ? " sm" : ""}`} role="img" aria-label={rows.map((r, i) => `${i === last ? "This week" : `Week of ${short(r.from)}`}: ${r.min} minutes`).join(", ")}>
      <span className="o-wb">{rows.map((r, i) => (
        <span key={r.from}><b><span className="o-long">{r.min}{sm ? "" : " min"}</span><span className="o-short">{r.min}</span></b><i className={i === last ? "cur" : undefined} style={{ "--h": (r.min / max).toFixed(3) } as CSSProperties} /></span>
      ))}</span>
      <span className="o-wb o-wlab">{rows.map((r, i) => (
        <span key={r.from} className="o-st">{i === last ? "Now" : sm ? short(r.from) : <><span className="o-long"><b>{short(r.from)}</b><br />{days(r.days)}</span><span className="o-short">{slash(r.from)}</span></>}</span>
      ))}</span>
    </span>
  );
}

/** the wrong answer beside the right one */
function Chips({ pat }: { pat: Pattern }) {
  return (
    <ul className="v-chips o-inline">
      <li className="wrong"><span>{pat.mistake.typed}</span><span className="mk" aria-label="Wrong">✕</span></li>
      <li className="right"><span>{pat.mistake.want}</span><span className="mk" aria-label="Right">✓</span></li>
    </ul>
  );
}

const Sec = ({ children, label }: { children: ReactNode; label: string }) => <section className="o-panel o-rsec" aria-label={label}>{children}</section>;

function Work({ d }: { d: Data }) {
  const u = d.usual;
  return (
    <>
      <Sec label="This week">
        <span className="o-ansbig"><h2 className="o-bignum">{plural(d.thisWeek.min, "minute")} this week</h2>
          <span className="o-st">{u ? `A usual week is about ${u.min} minutes, on ${u.days[0] === u.days[1] ? u.days[0] : `${u.days[0]} or ${u.days[1]}`} days. ` : ""}Each bar is one week.</span></span>
        <WeekBars rows={d.weeks} />
      </Sec>
      <Sec label="Week by week">
        <span className="o-label">Week by week</span>
        <div className="o-cols2">{d.weeks.slice().reverse().map((w, i) => (
          <div key={w.from} className="o-tile o-plain">
            <div className="o-setrow"><span className="o-nm">{i ? `Week of ${short(w.from)}` : "This week"}</span><b>{w.min} min</b></div>
            <span className="o-st">{w.days ? days(w.days) : "No lessons"}</span>
            {w.learned.map(t => <span key={`l${t}`}>Learned {t}</span>)}
            {w.working.map(t => <span key={`w${t}`}>Working on {t}</span>)}
          </div>
        ))}</div>
      </Sec>
    </>
  );
}

function Sticking({ d }: { d: Data }) {
  const list = (xs: Data["over"], f: (id: string) => string) => xs.map(x => (
    <div key={x.id} className="o-tile o-plain"><span className="o-nm">{x.title}</span><span className="o-st">{f(x.id)}</span></div>
  ));
  const next = (id: string) => Math.max(1, Math.ceil(((d.p.checks?.[id]?.due ?? d.now) - d.now) / DAY));
  return (
    <>
      <Sec label="Lessons learned">
        <span className="o-ansbig"><h2 className="o-bignum">{d.learned} of {plural(d.all, "lesson")} learned</h2>
          <span className="o-st">Learned means the lesson’s last check scored 3 or 4. The app checks again after 3, 7, 21 and 60 days. After all four, a lesson is stuck for good.</span></span>
        <div className="o-cols3">
          <div className="o-rows"><h3 className="o-head">Go over · {d.over.length}</h3>{list(d.over, id => dueBack(d.p, id, d.now) ? "Time for its next check" : `Last check: ${d.p.checks?.[id]?.last ?? 0} of 4`)}</div>
          <div className="o-rows"><h3 className="o-head">Getting stronger · {d.grow.length}</h3>{list(d.grow, id => `Passed ${d.passes(id)} of 4 checks · next in ${days(next(id))}`)}</div>
          <div className="o-rows"><h3 className="o-head">Stuck for good · {d.stuck.length}</h3>{list(d.stuck, () => "Passed all 4 checks")}</div>
        </div>
      </Sec>
      <Sec label="Scores by chapter">
        <span className="o-ansbig"><span className="o-label">Scores by chapter</span>
          <span className="o-st">{([0, 1, 2, 3, 4] as Level[]).map(n => `${n} ${LEVELS[n]}`).join(" · ")}. A chapter’s score is the average of its lessons’ latest checks, rounded down.</span></span>
        <div className="o-cols2">{d.units.map(u => (
          <div key={u.name} className="o-tile o-plain">
            <div className="o-setrow"><span className="o-nm">{u.name}</span><b>{u.score == null ? "Not started yet" : `${LEVELS[u.score]} · ${u.score} of 4`}</b></div>
            {u.done.length ? u.done.map(x => (
              <div key={x.id} className="o-setrow"><span>{x.title}</span><span className="o-st">Scored {x.s}{x.over ? " · go over" : ""}</span></div>
            )) : <span className="o-st">{plural(u.n, "lesson")}, none started</span>}
          </div>
        ))}</div>
      </Sec>
    </>
  );
}

function Help({ d }: { d: Data }) {
  const f = d.focus;
  const made = useMemo(() => {
    const lesson = f ? lessonById(f.id) : undefined;
    if (!lesson) return null;
    try {
      const p = lesson.generate(createRng([...lesson.id].reduce((a, c) => (a * 31 + c.charCodeAt(0)) >>> 0, 7)), 0);
      return { math: lesson.display(p), idea: lesson.explain(p, lesson.answers(p)).idea?.[0] };
    } catch { return null; }
  }, [f]);
  const step = f?.pat && f.pat.mistake.cat !== "plan" ? f.pat.mistake.label : null;
  return (
    <>
      <Sec label="One thing to try">
        <span className="o-ansbig"><h2 className="o-bignum">{f ? f.lesson : "Nothing to show yet"}</h2>
          <span className="o-st">{f ? "The one thing to try together this week." : "Once a lesson is finished, this page shows where to help."}</span></span>
        {made && (
          <div className="o-cols2">
            <div className="o-tile o-plain"><span className="o-nm">Try together at home</span>
              <span>Do one like this together: <MathLine math={made.math} /></span>
              <span>{step ? <>Ask them to say each step out loud, most of all <b>{step.toLowerCase()}</b>.</> : "Ask them to say each step out loud."}</span></div>
            {made.idea && <div className="o-tile o-plain"><span className="o-nm">The idea</span><span><Rich text={made.idea} /></span></div>}
          </div>
        )}
      </Sec>
      {d.patterns.length > 0 && (
        <Sec label="Mistakes they keep making">
          <span className="o-label">Mistakes they keep making</span>
          <div className="o-cols2">{d.patterns.slice(0, 4).map((p, i) => (
            <div key={p.id} className="o-tile o-plain"><span className="o-nm">{p.lesson}{i ? "" : " · most often"}</span><Chips pat={p} />
              <span className="o-st">{p.kind}: <Rich text={explainMistake(p.mistake)} /> {p.wrong} of {plural(p.tries, "problem")}.</span></div>
          ))}</div>
        </Sec>
      )}
      <Sec label="Hints and checks">
        <span className="o-label">Where they asked for hints</span>
        <div className="o-rows">{d.hints.rows.length
          ? d.hints.rows.map(r => <div key={r.title} className="o-line2"><span>{r.title}</span><b>{plural(r.count, "hint")}</b></div>)
          : <p className="o-st">No hints in {plural(d.hints.sessions, "session")}.</p>}</div>
        {d.ahead.length > 0 && <>
          <span className="o-label">Checks coming up</span>
          <div className="o-rows">{d.ahead.map(c => <div key={c.id} className="o-line2"><span>{c.title}</span><b>{whenDue(c.due, d.now)}</b></div>)}</div>
        </>}
        <p className="o-st o-lk"><LockIcon /> <span><b>Everything here stays on this device.</b> No account. Nothing is sent anywhere.</span></p>
      </Sec>
    </>
  );
}

/** the lowest-scored lesson of the grade, else the latest one finished */
function lowest(p: Progress, g: number): string | undefined {
  const scored = Object.keys(p.checks ?? {}).filter(id => lessonById(id)?.grade === g).sort((a, b) => (checkScore(p, a) ?? 4) - (checkScore(p, b) ?? 4));
  return scored[0] ?? p.log.find(e => e.mode === "practice" && lessonById(e.key))?.key;
}
