import { useApp } from "../app/AppState";
import { entriesInGrade, entryById, isReady, testKey, testReady, unitsInGrade } from "../app/curriculum";
import { gradeOf, GRADES } from "../curriculum/grades";
import { lessonById } from "../curriculum/registry";
import { upNext } from "../app/today";
import { lastScore, timesDone } from "../engine/mastery/progress";
import { bgClass, type TileSize } from "../components/BentoGrid";
import { PlayingDiagram } from "../components/diagrams/PlayingDiagram";
import { MathLine } from "../components/primitives/MathLine";
import { handOff, previewOf, statementBeat } from "../app/preview";
import { GradeQuestion } from "./GradeQuestion";
import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { Cover, Stat } from "../components/Cover";
import { chapterPic, lessonPic, TilePic } from "../components/TilePics";
import { Slider, type SliderOption } from "../components/primitives/Slider";
import { Chevron } from "../components/primitives/icons";
import { LESSON_CHECK_MINUTES, LESSON_MINUTES, TODAYS_REVIEW, UP_NEXT } from "../app/copy";
import { learnedCount } from "../app/rings";
import { dependsOn, dueBack, learned, toGoOver } from "../engine/mastery/skills";

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

/** what a lesson's tile and Today say about it, from its last skill check (one word, never a grade) */
export function statusOf(progress: ReturnType<typeof useApp>["progress"], g: number, id: string, now: number): { word: string; tone?: "next" | "rev"; done: boolean; score: number | null; checked: boolean } {
  const check = progress.checks?.[id], sc = check?.last ?? lastScore(progress, id), done = timesDone(progress, id) > 0 || !!check, checked = !!check;
  if (!isReady(id)) return { word: "Coming soon", done, score: sc, checked };
  // the model's words, first that applies (v2 spec H1); learned = a skill check of 3 or 4
  if (upNext(progress, g)?.entry.id === id && !learned(progress, id)) return { word: UP_NEXT, tone: "next", done, score: sc, checked };
  if (dueBack(progress, id, now)) return { word: "Review", tone: "rev", done, score: sc, checked };
  if (learned(progress, id)) return { word: "Solid", done, score: sc, checked };
  if (done) return { word: "Keep going", done, score: sc, checked };
  return { word: "Not started", done, score: sc, checked };
}

type Tab = "lessons" | "test" | "grade";
const TABS: SliderOption<Tab>[] = [{ id: "lessons", label: "Lessons" }, { id: "test", label: "Test" }, { id: "grade", label: "Grade" }];

/**
 * Home (v2, G 2026-10-13): one workspace. Today on one side says the one thing to do now and why; the box on the other
 * is the child's progress: a cover tile per chapter, each opening to a tile per lesson. Tapping a lesson puts it in
 * Today, so the child can always choose. The island's ring opens every grade in the box, in place.
 */
/** set before going home to open the grade list there (My Obento's "Switch grade") */
export const gradesNext = { open: false };

function GradeHome({ g }: { g: number }) {
  const { progress, route, go, reviewDue } = useApp();
  const next = upNext(progress, g);
  const routePick = route.name === "home" ? route.pick : undefined;
  // the lesson Today shows: the one tapped in the box, else a lesson left mid-practice (so Carry on is always one tap
  // away), else the one the app suggests
  const run = progress.run, runLesson = run?.mode === "practice" ? run.items[run.i]?.lessonId : undefined;
  const pick = routePick && entryById(routePick)?.grade === g ? routePick
    : runLesson && entryById(runLesson)?.grade === g ? runLesson : next?.entry.id ?? entriesInGrade(g)[0]?.id;
  const [view, setView] = useState<string | null>(() => (routePick ? entryById(routePick)?.unit ?? null : null));
  const [grades, setGrades] = useState(() => { const o = gradesNext.open; gradesNext.open = false; return o; });
  useEffect(() => {
    const on = () => setGrades(o => !o);
    addEventListener("bento:grades", on);
    return () => removeEventListener("bento:grades", on);
  }, []);
  useEffect(() => { dispatchEvent(new CustomEvent("bento:gradesopen", { detail: grades })); }, [grades]);
  const choose = (id: string) => go({ name: "home", pick: id }, "still");
  return (
    <div className="screen v-work v-home">
      {!routePick && !runLesson && reviewDue() ? <ReviewPanel /> : pick && <TodayPanel key={pick} g={g} id={pick} />}
      <section className="v-panel v-box" aria-label={grades ? "Every grade" : `${gradeOf(g).name} box`}>
        {grades ? <GradeList g={g} close={() => setGrades(false)} /> : <Box g={g} view={view} setView={setView} pick={pick} choose={choose} />}
      </section>
    </div>
  );
}

/** Today: the one lesson to do now, why it's this one, Start, and its first problem drawn. */
function TodayPanel({ g, id }: { g: number; id: string }) {
  const { progress, go, startLesson, now } = useApp();
  const entry = entryById(id)!, lesson = lessonById(id), st = statusOf(progress, g, id, now());
  const suggested = upNext(progress, g)?.entry.id === id;
  const run = progress.run, carry = !!run && run.mode === "practice" && run.items.some(it => it.lessonId === id);
  const ids = useMemo(() => [id], [id]);
  const found = usePreviewPick(ids);
  // v2 spec H4: name a lesson only when Curriculum lists this one in what it builds on (the first, in chapter order)
  const unlocks = entriesInGrade(g).find(c => c.id !== id && dependsOn(c.id).includes(id));
  const why = !lesson ? "This lesson is being rebuilt. It opens here soon."
    : carry ? "You left this one part way. Your work is kept."
    : suggested && !st.done ? `Next in ${entry.unit || gradeOf(g).name}.${unlocks ? ` ${unlocks.title} needs it, so it comes first.` : ""}`
    : st.score === 4 ? "Your skill check says you\u2019ve got this. Practise any time to keep it."
    : st.done ? `Your last skill check scored ${st.score ?? 0} of 4. Another go makes it stick.`
    : "Not started yet. Every lesson is open, so you can start here.";
  const start = () => {
    if (carry) return go({ name: "practice" }, "fwd");
    if (st.done) return startLesson(id);
    if (found) handOff(id, found.pic.problem);
    go({ name: "learn", lessonId: id }, "fwd");
  };
  return (
    <section className="v-panel v-today" aria-label="Today">
      <span className="v-label">{carry ? "In progress" : suggested ? "Today" : entry.unit || gradeOf(g).name}</span>
      <h2>{entry.title}</h2>
      <p className="v-why">{why}</p>
      <div className="v-row">
        <button className="v-go" disabled={!lesson} onClick={start}>{carry ? "Carry on" : st.done ? "Practise" : "Start"}</button>
        <span className="v-meta">{carry && run ? `Problem ${run.i + 1} of ${run.items.length}` : st.done ? `Practice and skill check \u00b7 about ${LESSON_MINUTES} minutes` : `Lesson and skill check \u00b7 about ${LESSON_CHECK_MINUTES} minutes`}</span>
      </div>
      <div className="v-todaypic">{found && <PlayingDiagram ex={{ ...found.pic.ex, diagram: found.pic.ex.diagram! }} end={statementBeat(found.pic.ex)} />}</div>
    </section>
  );
}

/** about how long a review problem takes, for Today's meta line (8 problems, about 5 minutes) */
const REVIEW_MIN_PER_PROBLEM = 0.6;

/** Today's review (v2-backend-plan.md; words from v2 spec H3): learned lessons due back come first, in the Today panel */
function ReviewPanel() {
  const { progress, startReview, reviewPlan, now } = useApp();
  const { due, problems } = reviewPlan(), one = due.length === 1 ? lessonById(due[0]!) : undefined;
  const days = one ? Math.floor((now() - (progress.checks[one.id]?.date ?? now())) / 864e5) : 0;
  const ago = days >= 14 ? `${Math.floor(days / 7)} weeks ago` : `${days} ${days === 1 ? "day" : "days"} ago`;
  const why = one ? `Your last skill check on ${one.title} was ${ago}. A quick review keeps it.`
    : `${due.length} lessons you\u2019ve learned are due back. A quick review keeps them.`;
  const meta = problems ? `${problems} problems \u00b7 about ${Math.max(1, Math.round(problems * REVIEW_MIN_PER_PROBLEM))} minutes` : "A few problems \u00b7 about 5 minutes";
  return (
    <section className="v-panel v-today" aria-label={TODAYS_REVIEW}>
      <span className="v-label">{TODAYS_REVIEW}</span>
      {one && <h2>{one.title}</h2>}
      <p className="v-why">{why}</p>
      <div className="v-row">
        <button className="v-go" onClick={startReview}>Start</button>
        <span className="v-meta">{meta}</span>
      </div>
    </section>
  );
}

/** The box: every chapter as a cover tile, or one chapter's lessons, with the tests and how the year is going a slide away. */
function Box({ g, view, setView, pick, choose }: { g: number; view: string | null; setView: (v: string | null) => void; pick?: string; choose: (id: string) => void }) {
  const { progress, startTest, now } = useApp();
  const [tab, setTab] = useState<Tab>("lessons");
  const grade = gradeOf(g), units = unitsInGrade(g), all = entriesInGrade(g);
  const unit = view ? units.find(u => u.name === view) : undefined;
  // progress is the ring everywhere: a lesson counts once its skill check is 3 or 4 (app/rings.ts)
  const list = unit ? unit.entries : all, done = learnedCount(progress, list), m = list.length;
  const solid = done;
  const goOver = list.filter(c => toGoOver(progress, c.id)).length;
  const testTile = (key: string, name: string) => {
    const t = progress.tests[key], ready = testReady(g, key.startsWith("grade:") ? undefined : unit?.name ?? key.split(":").slice(2).join(":"));
    return <Stat key={key} p={t ? t.last / 4 : 0} big={t ? `${t.last}/4` : "\u2013"} name={name} line={!ready ? "Coming soon" : t ? `Last try ${t.last} of 4` : "Not taken yet"}
      onClick={ready ? () => startTest(key) : undefined} label={`${name}${t ? `, last try ${t.last} of 4` : ", not taken yet"}`} />;
  };
  const stats = <>
    <Stat p={m ? done / m : 0} big={`${done}/${m}`} name="Lessons done" line={m - done ? `${m - done} still to do` : "All done"} />
    <Stat p={m ? solid / m : 0} big={`${solid}/${m}`} name="Got it" line="Skill check 3 or 4" />
    <Stat p={m ? goOver / m : 0} big={String(goOver)} name="To go over" line={goOver ? "Back in Today" : "Nothing yet"} />
  </>;
  return (<>
    <div className="v-bh">
      {unit && <button className="v-ib" onClick={() => { setView(null); setTab("lessons"); }} aria-label="All chapters"><Chevron dir="left" /></button>}
      <b>{unit ? unit.name : grade.name}</b>
      <span className="v-meta">{unit ? `${done} of ${m} done` : ""}</span>
      <Slider options={TABS} value={tab} onPick={setTab} label={unit ? `${unit.name} views` : `${grade.name} views`} className="v-sw" />
    </div>
    {!unit && tab === "lessons" && units.map(u => {
      const n = learnedCount(progress, u.entries), k = u.entries.length;
      return <Cover key={u.name} pic={<TilePic svg={chapterPic(g, u.name)} />} name={u.name} p={k ? n / k : 0} word={n === k ? `All ${k} done` : `${n} of ${k} done`}
        onClick={() => { setView(u.name); setTab("lessons"); }} aria-label={`${u.name}, ${n} of ${k} lessons done`} />;
    })}
    {unit && tab === "lessons" && unit.entries.map(c => {
      const st = statusOf(progress, g, c.id, now());
      return <Cover key={c.id} pick={c.id === pick} disabled={!isReady(c.id)} pic={<TilePic svg={lessonPic(c.id)} />} name={c.title} p={(st.score ?? 0) / 4} tone={st.tone}
        word={<>{st.word}{st.checked && st.score != null && <span className="v-sc">{` \u00b7 ${st.score}/4`}</span>}</>}
        onClick={() => choose(c.id)} aria-label={`${c.title}, ${st.word}${st.checked && st.score != null ? `, skill check ${st.score} of 4` : ""}`} />;
    })}
    {tab === "test" && (unit ? testTile(testKey(g, unit.name), `${unit.name} test`) : <>
      {testTile(testKey(g), `${grade.name} test`)}
      {units.length > 1 && units.map(u => testTile(testKey(g, u.name), `${u.name} test`))}
    </>)}
    {tab === "grade" && (unit ? stats : <>
      <div className="v-wide"><span className="v-label">Your {grade.name} year</span><p className="v-yr">{grade.subtitle}.</p></div>
      <div className="v-wide"><span className="v-label">The path</span><div className="v-path">{units.map(u => {
        const n = learnedCount(progress, u.entries), now = u.entries.some(c => c.id === pick);
        return <div key={u.name} className="v-pstep"><b>{u.name}</b><span className="v-seg" aria-hidden>{u.entries.map(c => <i key={c.id} className={learned(progress, c.id) ? "on" : undefined} />)}</span>
          <span className={`v-st${now ? " next" : ""}`}>{n === u.entries.length ? "Done" : now ? "Today" : n ? `${n} of ${u.entries.length} done` : "Not started"}</span></div>;
      })}</div></div>
      {stats}
    </>)}
  </>);
}

/** Every grade, in the box itself (opened from the island's ring): each with how many of its lessons are done. */
function GradeList({ g, close }: { g: number; close: () => void }) {
  const { progress, chooseGrade } = useApp();
  return (<>
    <div className="v-bh"><button className="v-ib" onClick={close} aria-label="Back to your box"><Chevron dir="left" /></button><b>Every grade</b><span className="v-meta">Pick one</span></div>
    {GRADES.map(d => {
      const list = entriesInGrade(d.grade), n = learnedCount(progress, list);
      return <Cover key={d.grade} pick={d.grade === g} className="v-gtile" pic={<span className="v-gbig">{d.short}</span>} name={d.name} p={list.length ? n / list.length : 0}
        word={d.grade === g ? "Your grade" : n ? `${n} of ${list.length} done` : d.subtitle}
        onClick={() => { close(); if (d.grade !== g) chooseGrade(d.grade); }} aria-label={`${d.name}, ${n} of ${list.length} lessons done`} />;
    })}
  </>);
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
