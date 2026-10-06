import { Pill, PillLabel } from "../components/primitives/Pill";
import { useApp } from "../app/AppState";
import { doneCount, entriesInGrade, entryById, gradeAverage, isReady, testKey, testReady, unitsInGrade, type Entry } from "../app/curriculum";
import { gradeOf } from "../curriculum/grades";
import { lessonById } from "../curriculum/registry";
import { todayPlan, upNext, type TodayItem } from "../app/today";
import { placeKey } from "../engine/session/practice";
import { Check } from "../components/primitives/icons";
import { lastScore, timesDone } from "../engine/mastery/progress";
import { ScoreChip } from "../components/primitives/Score";
import { Fill, GradeNum } from "../components/Shelf";
import { SplitScreen } from "../components/screen/Screen";
import { Diagram } from "../components/diagrams/Diagram";
import { MathLine, Rich } from "../components/primitives/MathLine";
import { handOff, previewOf } from "../app/preview";
import { GradeQuestion } from "./GradeQuestion";
import { useLayoutEffect, useMemo, useRef, useState } from "react";

const KIND = { lesson: "Up next", review: "Review", test: "Unit test", facts: "Fact sprint" } as const;
/** a lesson takes about this long: watch it, then eight problems */
const LESSON_MINUTES = 8;
/** the preview only shows when it fits at least this tall without shrinking any text (handoff 5) */
const PREVIEW_MIN = 150;

/**
 * Home is the grade's book, as a list beside its detail (Design, handoff 5): the list holds Today and every chapter,
 * the open chapter showing its lessons; the detail shows the picked row. On a phone the list fills the screen and
 * a tap opens the detail on its own.
 */
export function Home() {
  const { progress } = useApp();
  // no grade chosen yet: "Which grade are you in?" comes first, with nothing picked (G: choice is the default)
  return progress.grade == null ? <GradeQuestion /> : <GradeHome g={progress.grade} />;
}

function GradeHome({ g }: { g: number }) {
  const { progress, route, go, openSheet, startTest } = useApp();
  const grade = gradeOf(g), units = unitsInGrade(g);
  const next = upNext(progress, g);
  const routePick = route.name === "home" ? route.pick : undefined;
  // the picked row: Today, or a lesson of this grade
  const pick = routePick && (routePick === "today" || entryById(routePick)?.grade === g) ? routePick : "today";
  const show = routePick ? "detail" : "list";
  const openUnit = units.find(u => u.entries.some(c => c.id === pick)) ?? units.find(u => u.entries.some(c => c.id === next?.entry.id)) ?? units[0];
  const [shut, setShut] = useState<string | null>(null);
  const select = (p: string) => go({ name: "home", pick: p }, "fwd");
  let k = 0;

  const listPane = (
    <>
      <header className="shead">
        <GradeNum grade={g} />
        <div>
          <h1>{grade.name}</h1>
          <p className="ysub">This year: {grade.subtitle.toLowerCase()}.</p>
        </div>
        <button className="tlink" onClick={() => openSheet(true)} aria-label="Change grade">Change grade</button>
      </header>
      <button className={`srow${pick === "today" ? " on" : ""}`} aria-current={pick === "today" ? "true" : undefined} onClick={() => select("today")}>
        <span className="sname"><b>Today</b></span><small>{todayMeta(progress, g)}</small>
      </button>
      {units.map((u, ui) => {
        const isOpen = u === openUnit && shut !== u.name, done = doneCount(progress, u.entries);
        const lessons = u.entries.map(c => ({ c, n: ++k }));
        return (
          <div className={`schapter${isOpen ? " open" : ""}`} key={u.name}>
            <button className="srow chap" aria-expanded={isOpen}
              onClick={() => { if (isOpen) setShut(u.name); else { setShut(null); select((u.entries.find(c => c.id === next?.entry.id) ?? u.entries.find(c => isReady(c.id)) ?? u.entries[0]!).id); } }}>
              <span className="sname"><small>Chapter {ui + 1}</small><b>{u.name}</b></span><small>{done} of {u.entries.length}</small>
            </button>
            {isOpen && lessons.map(({ c, n }) => {
              const sc = lastScore(progress, c.id), live = isReady(c.id);
              return (
                <button key={c.id} className={`srow sles${pick === c.id ? " on" : ""}${live ? "" : " soon"}`} disabled={!live} aria-current={pick === c.id ? "true" : undefined}
                  onClick={() => select(c.id)} aria-label={live ? `${c.title}${c === next?.entry ? ", up next" : ""}` : `${c.title}, coming soon`}>
                  <span className={`badge${timesDone(progress, c.id) > 0 ? " on" : ""}`}>{n}</span>
                  <span className="sname"><b>{c.title}</b></span>
                  {sc != null ? <ScoreChip n={sc} /> : c === next?.entry ? <small className="snext">Up next</small> : live ? null : <small>soon</small>}
                </button>
              );
            })}
          </div>
        );
      })}
      {testReady(g) && <div className="sfoot"><Pill onClick={() => startTest(testKey(g))}>Grade check-up</Pill></div>}
    </>
  );

  const entry = pick === "today" ? null : entryById(pick)!;
  return (
    <SplitScreen label={`${grade.name} chapters`} show={show} list={listPane}
      detail={entry ? <LessonDetail key={entry.id} g={g} entry={entry} /> : <TodayDetail g={g} />} />
  );
}

/** what the Today row says under its name */
function todayMeta(progress: ReturnType<typeof useApp>["progress"], g: number): string {
  const next = upNext(progress, g);
  return next ? (next.again ? "Practice" : "Up next") : "All done";
}

/** Today: the short plan (one tap starts it), how the year is going, and anything worth practicing again. */
function TodayDetail({ g }: { g: number }) {
  const { progress, go, startLesson, startTest, startReview, canReview, deps } = useApp();
  const list = entriesInGrade(g);
  const plan = todayPlan(progress, g, deps().now, canReview());
  const first = plan.find(i => !i.done);
  const done = doneCount(progress, list), avg = gradeAverage(progress, g);
  const weak = list.filter(c => { const s = lastScore(progress, c.id); return s != null && s <= 1; });
  const gt = progress.tests[testKey(g)];
  const run = (i: TodayItem) => i.kind === "lesson" ? (i.done ? startLesson(i.id) : go({ name: "learn", lessonId: i.id }))
    : i.kind === "review" ? startReview() : i.kind === "facts" ? go({ name: "facts", table: i.table, start: true }, "fwd") : startTest(i.key);
  const doneScore = (i: TodayItem) => i.kind === "review" ? progress.reviews[new Date(deps().now).toDateString()]
    : i.kind === "lesson" ? lastScore(progress, i.id) : i.kind === "facts" ? undefined : progress.tests[i.key]?.last;
  const minutes = plan.filter(i => !i.done).reduce((m, i) => m + i.minutes, 0);
  return (
    <div className={`bhome sday${weak.length ? " tall" : ""}`}>
      <section className="tile today">
        <h2>Today</h2>
        <p className="sub">{!plan.length ? "New lessons for this grade are almost ready." : first ? `About ${minutes} minutes.` : "That's everything for today."}</p>
        {plan.length > 0 && (
          <ol className="plan">{plan.map(i => (
            <li key={i.kind}>
              <button className={`pitem${i.done ? " done" : ""}${i === first ? " now" : ""}`} onClick={() => run(i)}
                aria-label={i.kind === "facts" ? `Fact sprint: ${i.title}${i.done ? ", done" : ""}` : i.kind === "review" ? (i.done ? "Today's review: done" : "Today's review") : i.kind === "lesson" && !i.done ? `${i.again ? "Practice" : "Up next"}: ${i.title}` : undefined}>
                <span className="pmark" aria-hidden>{i.done ? <Check /> : null}</span>
                <span className="ptext"><small>{i.kind === "lesson" && i.again ? "Practice" : KIND[i.kind]}</small><b>{i.title}</b></span>
                {i === first ? <PillLabel go>Start</PillLabel> : i.done ? <ScoreChip n={doneScore(i)} /> : <span className="pmin">{i.minutes} min</span>}
              </button>
            </li>
          ))}</ol>
        )}
        <div className="tlinks">
          {!progress.log.length && <button className="tlink" onClick={() => startTest(placeKey(g))}>Not sure this is your grade? Find my level ›</button>}
          <button className="tlink" onClick={() => go({ name: "facts" }, "fwd")}>All facts ›</button>
        </div>
      </section>
      <section className="tile b-stats battery">
        <Fill frac={list.length ? done / list.length : 0} />
        <span className="bbig">{done}</span>
        <p><b>of {list.length}</b> lessons done{avg != null && <><br /><span className="muted">Average score {avg.toFixed(1)} of 4</span></>}</p>
        {gt && <p className="muted gtline">Grade check-up <ScoreChip n={gt.last} /></p>}
      </section>
      {weak.length > 0 && (
        <section className="tile b-weak"><h3>Practice again</h3>
          <div className="lessons">{weak.slice(0, 3).map(c => (
            <button key={c.id} className="lesson" disabled={!isReady(c.id)} onClick={() => go({ name: "learn", lessonId: c.id })}><ScoreChip n={lastScore(progress, c.id)} /><span className="name">{c.title}</span></button>
          ))}</div>
        </section>
      )}
    </div>
  );
}

/**
 * One lesson: where it sits, what it teaches, its three steps, and Start. Above it (beside it in portrait, below it on
 * a phone) the preview: the lesson's own picture of the very first problem the learner will get, when it fits.
 */
function LessonDetail({ g, entry }: { g: number; entry: Entry }) {
  const { progress, go, startTest, deps } = useApp();
  const lesson = lessonById(entry.id);
  const units = unitsInGrade(g), ui = units.findIndex(u => u.entries.includes(entry)), unit = units[ui]!;
  const seed = useMemo(() => Math.floor(deps().rng.next() * 2 ** 31), [entry.id]); // eslint-disable-line react-hooks/exhaustive-deps
  const pv = useMemo(() => (lesson ? previewOf(lesson, seed) : null), [lesson, seed]);
  const pic = pv?.ex.diagram && pv.ex.diagram.kind !== "chain" ? pv : null;
  const sc = lastScore(progress, entry.id), tk = testKey(g, unit.name), t = progress.tests[tk];
  const start = () => { if (pv) handOff(entry.id, pv.problem); go({ name: "learn", lessonId: entry.id }, "fwd"); };

  // the preview takes what's left beside the text, and only shows when that's at least PREVIEW_MIN tall
  const box = useRef<HTMLDivElement>(null), text = useRef<HTMLDivElement>(null);
  const [room, setRoom] = useState(0);
  useLayoutEffect(() => {
    const measure = () => {
      if (!box.current || !text.current) return;
      const gap = parseFloat(getComputedStyle(box.current).rowGap) || 16;
      setRoom(Math.floor(box.current.clientHeight - text.current.offsetHeight - gap));
    };
    measure();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(measure);
    if (box.current) ro.observe(box.current);
    if (text.current) ro.observe(text.current);
    return () => ro.disconnect();
  }, [pic]);
  const fits = !!pic && room >= PREVIEW_MIN;

  return (
    <div className="sdl" ref={box}>
      <div className="card sdtext" ref={text}>
        <p className="k">Chapter {ui + 1} · {unit.name} · {unit.entries.length} lesson{unit.entries.length === 1 ? "" : "s"}</p>
        <h2>{entry.title}</h2>
        {pv?.ex.idea?.[0] && <p className="sdidea"><Rich text={pv.ex.idea[0]} /></p>}
        <ol className="ssteps">
          <li><b>Learn</b><span>Watch it play out</span></li>
          <li><b>Practice</b><span>Solve it a step at a time</span></li>
          <li><b>Check</b><span>See your score{sc != null && <> · last <ScoreChip n={sc} /></>}</span></li>
        </ol>
        <div className="actions">
          <Pill go disabled={!lesson} onClick={start}>Start lesson · {LESSON_MINUTES} min</Pill>
          {testReady(g, unit.name) && <Pill badged={!!t} onClick={() => startTest(tk)}>{t && <ScoreChip n={t.last} />}{unit.name} test</Pill>}
        </div>
      </div>
      {fits && (
        <figure className="card spreview" style={{ height: Math.min(room, 460) }}>
          <figcaption>Preview · your first problem, <MathLine math={pv!.ex.statement} /></figcaption>
          <div className="sppic"><Diagram diagram={pic!.ex.diagram!} timeline={pic!.ex.timeline} at={pic!.ex.timeline.length - 1} /></div>
        </figure>
      )}
    </div>
  );
}
