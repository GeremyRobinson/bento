import { Pill, PillLabel } from "../components/primitives/Pill";
import { useApp } from "../app/AppState";
import { doneCount, entriesInGrade, entryById, isReady, testKey, testReady, unitsInGrade, type Entry } from "../app/curriculum";
import { gradeOf } from "../curriculum/grades";
import { lessonById } from "../curriculum/registry";
import { todayPlan, upNext, type TodayItem } from "../app/today";
import { placeKey } from "../engine/session/practice";
import { Check } from "../components/primitives/icons";
import { lastScore, timesDone } from "../engine/mastery/progress";
import { ScoreChip } from "../components/primitives/Score";
import { Fill, GradeNum } from "../components/Shelf";
import { SplitScreen } from "../components/screen/Screen";
import { ListGroup } from "../components/screen/ListGroup";
import { BentoGrid, bgClass, type TileSize } from "../components/BentoGrid";
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
  // on a phone a chapter tap only opens the chapter (the lessons are the next tap); beside the list it also picks a lesson
  const [opened, setOpened] = useState<string | null>(null);
  // beside the list, picking a row only moves the white pill to it and swaps the detail; on a phone the detail is its own screen
  const phone = () => typeof matchMedia !== "undefined" && matchMedia("(max-width: 699px)").matches;
  const select = (p: string) => go({ name: "home", pick: p }, phone() ? "fwd" : "still");
  let k = 0;

  const listPane = (
    <>
      {/* the list opens on the grade's big number, like the UI notes preview */}
      <header className="shead">
        <GradeNum grade={g} />
        <h1 className="vh">{grade.name}</h1>
        {/* the grade's check-up sits beside its number, top right (G 2026-10-07) */}
        {testReady(g) && <Pill small className="scheck" onClick={() => startTest(testKey(g))}>{GRADE_CHECKUP}</Pill>}
      </header>
      <button className={`srow${pick === "today" ? " on" : ""}`} aria-current={pick === "today" ? "true" : undefined} onClick={() => select("today")}>
        <span className="sname"><b>Today</b></span><small className="smeta">{todayMeta(progress, g)}</small>
      </button>
      {units.map(u => {
        const isOpen = (opened ? u.name === opened : u === openUnit) && shut !== u.name, done = doneCount(progress, u.entries);
        const lessons = u.entries.map(c => ({ c, n: ++k }));
        return (
          <ListGroup className="schapter" open={isOpen} key={u.name} head={
            <button className={`srow chap${!isOpen && u.entries.some(c => c.id === pick) ? " holds" : ""}`} aria-expanded={isOpen}
              onClick={() => { if (isOpen) setShut(u.name); else { setShut(null); setOpened(null); if (phone()) { setOpened(u.name); return; } select((u.entries.find(c => c.id === next?.entry.id) ?? u.entries.find(c => isReady(c.id)) ?? u.entries[0]!).id); } }}>
              <span className="sname"><b>{u.name}</b></span><small className="smeta">{done === u.entries.length ? "Done" : !done && u.entries.includes(next?.entry as never) ? UP_NEXT : `${done} of ${u.entries.length}`}</small>
            </button>}>
            {lessons.map(({ c }) => {
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
          </ListGroup>
        );
      })}
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
  const done = doneCount(progress, list);
  const weak = list.filter(c => { const s = lastScore(progress, c.id); return s != null && s <= 1; });
  const run = (i: TodayItem) => i.kind === "lesson" ? (i.done ? startLesson(i.id) : go({ name: "learn", lessonId: i.id }))
    : i.kind === "review" ? startReview() : i.kind === "facts" ? go({ name: "facts", table: i.table, start: true }, "fwd") : startTest(i.key);
  const doneScore = (i: TodayItem) => i.kind === "review" ? progress.reviews[new Date(deps().now).toDateString()]
    : i.kind === "lesson" ? lastScore(progress, i.id) : i.kind === "facts" ? undefined : progress.tests[i.key]?.last;
  const minutes = plan.filter(i => !i.done).reduce((m, i) => m + i.minutes, 0);
  const nextLesson = upNext(progress, g)?.entry.id;
  // the picture comes from the next lesson; when that one is all equations, from the next lesson after it that draws
  // one (G 2026-10-06: Today always has a live picture)
  const ready = list.filter(c => isReady(c.id)), at = Math.max(0, ready.findIndex(c => c.id === nextLesson));
  const picFrom = [...ready.slice(at), ...ready.slice(0, at)].map(c => c.id);
  const found = usePreviewPick(picFrom), pic = found != null;
  // Today as a bento that fills the screen (G 2026-10-06, "needs better use of space"): the up-next problem drawn big,
  // the plan, how far the year is and the streak. No chapters tile: Contents beside it already lists them, so Today
  // runs the full width along the bottom, its plan side by side (G 21:27, 22:04)
  return (
    <BentoGrid fit className={`bhome sday sbento${pic ? "" : " nopic"}`}>
      {pic && <PreviewWell pick={found} next={nextLesson} size="l" />}
      <section className={`tile b-stats battery ${bgClass("n")}`}>
        <Fill frac={list.length ? done / list.length : 0} />
        <span className="bbig">{done}</span>
        <p><b>of {list.length}</b> lessons done</p>
      </section>
      <section className={`tile b-streak ${bgClass("n")}`}>
        <span className="bbig">{progress.streak}</span>
        <p><b>day{progress.streak === 1 ? "" : "s"}</b> in a row</p>
      </section>
      <section className={`tile today ${bgClass("f")}`}>
        <header className="thead"><h2>Today</h2>
          <p className="sub">{!plan.length ? "New lessons for this grade are almost ready." : first ? `About ${minutes} minutes.` : "That's everything for today."}</p></header>
        <div className="tbody">
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
        </div>
        {/* on a phone the plan scrolls between the title and this Start, which never scrolls away (Design 2026-10-07) */}
        {first && <Pill go className="tstart" onClick={() => run(first)} aria-label={`Start: ${first.title}`}>Start</Pill>}
      </section>
    </BentoGrid>
  );
}

/**
 * Up next, as a picture: the very first problem of the lesson waiting, in whatever room the plan leaves (UI notes
 * preview: a big live picture on top of the detail). It draws only when it fits PREVIEW_MIN tall.
 */
/** the first lesson in line whose first problem draws a picture (one search, shared by the well and the page that sizes it) */
export function usePreviewPick(candidates: string[]) {
  const { deps } = useApp();
  const seed = useMemo(() => Math.floor(deps().rng.next() * 2 ** 31), []); // eslint-disable-line react-hooks/exhaustive-deps
  return useMemo(() => {
    for (const id of candidates) {
      const l = lessonById(id), pv = l ? previewOf(l, seed) : null;
      if (l && pv?.ex.diagram && pv.ex.diagram.kind !== "chain") return { lesson: l, pic: pv };
    }
    return null;
  }, [candidates.join(), seed]); // eslint-disable-line react-hooks/exhaustive-deps
}
type PreviewPick = ReturnType<typeof usePreviewPick>;

export function PreviewWell({ candidates = [], pick, next, size }: { candidates?: string[]; pick?: PreviewPick; next?: string; size?: TileSize }) {
  const own = usePreviewPick(pick === undefined ? candidates : []);
  const found = pick === undefined ? own : pick;
  const lesson = found?.lesson, pic = found?.pic ?? null;
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
    <figure className={`card spreview grow${fits ? "" : " empty"} ${bgClass(size)}`} ref={box} aria-hidden={!fits}>
      {fits && <>
        <figcaption>{lesson!.id === next ? "Up next" : "Coming up"} · {lesson!.title}, <b><MathLine math={pic.ex.statement} /></b></figcaption>
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
