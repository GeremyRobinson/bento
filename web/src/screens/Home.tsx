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
import { PlayingDiagram } from "../components/diagrams/PlayingDiagram";
import { MathLine, Rich } from "../components/primitives/MathLine";
import { handOff, previewOf, statementBeat } from "../app/preview";
import { GradeQuestion } from "./GradeQuestion";
import { useLayoutEffect, useMemo, useRef, useState } from "react";
import { FACT_SPRINT, GRADE_CHECKUP, LESSON_MINUTES, minLabel, PRACTICE, PRACTICE_AGAIN, REVIEW, TODAYS_REVIEW, UP_NEXT } from "../app/copy";

const KIND = { lesson: UP_NEXT, review: REVIEW, test: "Unit test", facts: FACT_SPRINT } as const;
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
  const { progress, route, go, startTest } = useApp();
  const grade = gradeOf(g), units = unitsInGrade(g);
  const next = upNext(progress, g);
  const routePick = route.name === "home" ? route.pick : undefined;
  // the picked row: Today, or a lesson of this grade
  const pick = routePick && (routePick === "today" || entryById(routePick)?.grade === g) ? routePick : "today";
  const show = routePick ? "detail" : "list";
  const openUnit = units.find(u => u.entries.some(c => c.id === pick)) ?? units.find(u => u.entries.some(c => c.id === next?.entry.id)) ?? units[0];
  const [shut, setShut] = useState<string | null>(null);
  // beside the list, picking a row only glides the selection and swaps the detail; on a phone the detail is its own screen
  const select = (p: string) => go({ name: "home", pick: p }, typeof matchMedia !== "undefined" && matchMedia("(max-width: 699px)").matches ? "fwd" : "still");
  let k = 0;
  // the picked row's highlight glides to the row you tap, like the floating preview
  const knob = useRef<HTMLSpanElement>(null), placed = useRef(false);
  useLayoutEffect(() => {
    const el = knob.current, row = el?.parentElement?.querySelector<HTMLElement>(".srow.on");
    if (!el) return;
    if (!row) { el.style.opacity = "0"; return; }
    if (!placed.current) el.style.transition = "none";
    el.style.opacity = "1";
    el.style.transform = `translateY(${row.offsetTop}px)`;
    el.style.height = `${row.offsetHeight}px`;
    if (!placed.current) { void el.offsetHeight; el.style.transition = ""; placed.current = true; }
  });

  const listPane = (
    <>
      <span className="sknob" ref={knob} aria-hidden />
      {/* the list opens on the grade's big number, like the UI notes preview */}
      <header className="shead">
        <GradeNum grade={g} />
        <h1 className="vh">{grade.name}</h1>
      </header>
      <button className={`srow${pick === "today" ? " on" : ""}`} aria-current={pick === "today" ? "true" : undefined} onClick={() => select("today")}>
        <span className="sname"><b>Today</b></span><small className="smeta">{todayMeta(progress, g)}</small>
      </button>
      {units.map(u => {
        const isOpen = u === openUnit && shut !== u.name, done = doneCount(progress, u.entries);
        const lessons = u.entries.map(c => ({ c, n: ++k }));
        return (
          <div className={`schapter${isOpen ? " open" : ""}`} key={u.name}>
            <button className="srow chap" aria-expanded={isOpen}
              onClick={() => { if (isOpen) setShut(u.name); else { setShut(null); select((u.entries.find(c => c.id === next?.entry.id) ?? u.entries.find(c => isReady(c.id)) ?? u.entries[0]!).id); } }}>
              <span className="sname"><b>{u.name}</b></span><small className="smeta">{done === u.entries.length ? "Done" : done ? `${done} of ${u.entries.length}` : `${u.entries.length} lesson${u.entries.length === 1 ? "" : "s"}`}</small>
            </button>
            {isOpen && lessons.map(({ c }) => {
              const sc = lastScore(progress, c.id), live = isReady(c.id);
              return (
                <button key={c.id} className={`srow sles${pick === c.id ? " on" : ""}${live ? "" : " soon"}`} disabled={!live} aria-current={pick === c.id ? "true" : undefined}
                  onClick={() => select(c.id)} aria-label={live ? `${c.title}${c === next?.entry ? ", up next" : ""}` : `${c.title}, coming soon`}>
                  <span className={`sdot${timesDone(progress, c.id) > 0 ? " done" : ""}`} aria-hidden />
                  <span className="sname"><b>{c.title}</b></span>
                  {sc != null ? <ScoreChip n={sc} /> : c === next?.entry ? <small className="snext">{UP_NEXT}</small> : live ? <small className="smeta">{minLabel(LESSON_MINUTES)}</small> : <small>soon</small>}
                </button>
              );
            })}
          </div>
        );
      })}
      {testReady(g) && <div className="sfoot"><Pill onClick={() => startTest(testKey(g))}>{GRADE_CHECKUP}</Pill></div>}
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
  return next ? (next.again ? PRACTICE : UP_NEXT) : "All done";
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
  const nextLesson = upNext(progress, g)?.entry.id;
  const units = unitsInGrade(g);
  // Today as a bento that fills the screen (G 2026-10-06, "needs better use of space"): the up-next problem drawn big,
  // the plan, how far the year is, the streak, and every chapter as its own fill
  return (
    <div className={`bhome sday sbento${nextLesson ? "" : " nopic"}`}>
      {nextLesson && <PreviewWell key={nextLesson} lessonId={nextLesson} />}
      <section className="tile today">
        <h2>Today</h2>
        <p className="sub">{!plan.length ? "New lessons for this grade are almost ready." : first ? `About ${minutes} minutes.` : "That's everything for today."}</p>
        {plan.length > 0 && (
          <ol className="plan">{plan.map(i => (
            <li key={i.kind}>
              <button className={`pitem${i.done ? " done" : ""}${i === first ? " now" : ""}`} onClick={() => run(i)}
                aria-label={i.kind === "facts" ? `${FACT_SPRINT}: ${i.title}${i.done ? ", done" : ""}` : i.kind === "review" ? (i.done ? `${TODAYS_REVIEW}: done` : TODAYS_REVIEW) : i.kind === "lesson" && !i.done ? `${i.again ? PRACTICE : UP_NEXT}: ${i.title}` : undefined}>
                <span className="pmark" aria-hidden>{i.done ? <Check /> : null}</span>
                <span className="ptext"><small>{i.kind === "lesson" && i.again ? PRACTICE : KIND[i.kind]}</small><b>{i.title}</b></span>
                {i === first ? <PillLabel go>Start</PillLabel> : i.done ? <ScoreChip n={doneScore(i)} /> : <span className="pmin">{minLabel(i.minutes)}</span>}
              </button>
            </li>
          ))}</ol>
        )}
        {weak.length > 0 && (
          <div className="b-weak"><h3>{PRACTICE_AGAIN}</h3>
            <div className="lessons">{weak.slice(0, 3).map(c => (
              <button key={c.id} className="lesson" disabled={!isReady(c.id)} onClick={() => go({ name: "learn", lessonId: c.id })}><ScoreChip n={lastScore(progress, c.id)} /><span className="name">{c.title}</span></button>
            ))}</div>
          </div>
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
        {gt && <p className="muted gtline">{GRADE_CHECKUP} <ScoreChip n={gt.last} /></p>}
      </section>
      <section className="tile b-streak">
        <span className="bbig">{progress.streak}</span>
        <p><b>day{progress.streak === 1 ? "" : "s"}</b> in a row</p>
        <p className="muted">{progress.xp} XP</p>
      </section>
      <section className="tile b-chaps" aria-label="Chapters">
        {units.map(u => {
          const d = doneCount(progress, u.entries), n = u.entries.length;
          return (
            <button key={u.name} className="bchap battery" onClick={() => go({ name: "home", pick: (u.entries.find(c => timesDone(progress, c.id) === 0 && isReady(c.id)) ?? u.entries[0]!).id }, "still")}
              aria-label={`${u.name}: ${d} of ${n} done`}>
              <Fill frac={n ? d / n : 0} />
              <b>{u.name}</b><small>{d === n ? "Done" : `${d} of ${n}`}</small>
            </button>
          );
        })}
      </section>
    </div>
  );
}

/**
 * Up next, as a picture: the very first problem of the lesson waiting, in whatever room the plan leaves (UI notes
 * preview: a big live picture on top of the detail). It draws only when it fits PREVIEW_MIN tall.
 */
function PreviewWell({ lessonId }: { lessonId: string }) {
  const { deps } = useApp();
  const lesson = lessonById(lessonId);
  const seed = useMemo(() => Math.floor(deps().rng.next() * 2 ** 31), []); // eslint-disable-line react-hooks/exhaustive-deps
  const pv = useMemo(() => (lesson ? previewOf(lesson, seed) : null), [lesson, seed]);
  const pic = pv?.ex.diagram && pv.ex.diagram.kind !== "chain" ? pv : null;
  const box = useRef<HTMLElement>(null);
  const [h, setH] = useState(0);
  useLayoutEffect(() => {
    const el = box.current;
    if (!el) return;
    const measure = () => setH(el.clientHeight);
    measure();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
  }, [pic]);
  if (!pic) return null;
  const fits = h >= PREVIEW_MIN;
  return (
    <figure className={`card spreview grow${fits ? "" : " empty"}`} ref={box} aria-hidden={!fits}>
      {fits && <>
        <figcaption>Up next · {lesson!.title}, <b><MathLine math={pic.ex.statement} /></b></figcaption>
        <div className="sppic"><PlayingDiagram ex={{ ...pic.ex, diagram: pic.ex.diagram! }} end={statementBeat(pic.ex)} /></div>
      </>}
    </figure>
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
        <p className="k">{unit.name} · lesson {unit.entries.indexOf(entry) + 1} of {unit.entries.length}</p>
        <h2>{entry.title}</h2>
        {pv?.ex.idea?.[0] && <p className="sdidea"><Rich text={pv.ex.idea[0]} /></p>}
        <div className="sfootrow">
          {sc != null && <span className="slast">Last score <ScoreChip n={sc} /></span>}
          {testReady(g, unit.name) && <Pill badged={!!t} onClick={() => startTest(tk)}>{t && <ScoreChip n={t.last} />}{unit.name} test</Pill>}
          <span className="grow" />
          <Pill go disabled={!lesson} onClick={start}>Start lesson · {minLabel(LESSON_MINUTES)}</Pill>
        </div>
      </div>
      {fits && (
        <figure className="card spreview" style={{ height: Math.min(room, 460) }}>
          <figcaption>Preview · your first problem, <b><MathLine math={pv!.ex.statement} /></b></figcaption>
          <div className="sppic"><PlayingDiagram ex={{ ...pic!.ex, diagram: pic!.ex.diagram! }} end={statementBeat(pic!.ex)} /></div>
        </figure>
      )}
    </div>
  );
}
