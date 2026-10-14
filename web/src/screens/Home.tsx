import { useApp } from "../app/AppState";
import { entriesInGrade, entryById, isReady, testKey, testReady, unitsInGrade, type Entry } from "../app/curriculum";
import { gradeOf, GRADES } from "../curriculum/grades";
import { lessonById } from "../curriculum/registry";
import { upNext } from "../app/today";
import { lastScore, timesDone } from "../engine/mastery/progress";
import { bgClass, type TileSize } from "../components/BentoGrid";
import { PlayingDiagram } from "../components/diagrams/PlayingDiagram";
import { MathLine } from "../components/primitives/MathLine";
import { handOff, previewOf, statementBeat } from "../app/preview";
import { GradeQuestion } from "./GradeQuestion";
import { useLayoutEffect, useMemo, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { chapterPic, lessonPic, TilePic } from "../components/TilePics";
import { Marks, ORing, OSlider, type Tab } from "../components/Masters";
import { LESSON_CHECK_MINUTES, LESSON_MINUTES, TODAYS_REVIEW, UP_NEXT } from "../app/copy";
import { checkedCount } from "../app/rings";
import { dependsOn, dueBack, learned, toGoOver } from "../engine/mastery/skills";
import { boxView, boxZoom, GRADES_VIEW, setBoxView, useBoxView } from "../app/box";
import { motionOff } from "../app/settings";
import type { Progress } from "../engine/mastery/progress";

/** the preview only shows when it fits at least this tall without shrinking any text (handoff 5) */
const PREVIEW_MIN = 150;

/**
 * Home (UI model v57): Today beside the box. Today says the one thing to do now and why; the box is the child's year:
 * a cover tile per chapter, each opening (a soft zoom) to a tile per lesson, with the tests and how the year is going
 * a slide (or a swipe) away. Tapping a lesson or a test puts it in Today, so the child can always choose. The island's
 * grid opens every grade in the box, in place. On a phone the two stack and the page scrolls.
 */
export function Home() {
  const { progress } = useApp();
  // no grade chosen yet: "Which grade are you in?" comes first, with nothing picked (G: choice is the default)
  return progress.grade == null ? <GradeQuestion /> : <GradeHome g={progress.grade} />;
}

/** what a lesson's tile and Today say about it, from its last skill check (one word, never a grade) */
export function statusOf(progress: Progress, g: number, id: string, now: number): { word: string; tone?: "next" | "rev" | "done"; done: boolean; score: number | null; checked: boolean } {
  const check = progress.checks?.[id], sc = check?.last ?? lastScore(progress, id), done = timesDone(progress, id) > 0 || !!check, checked = !!check;
  if (!isReady(id)) return { word: "Coming soon", done, score: sc, checked };
  // the model's words, first that applies: up next, to go over (due back or a low check), got it (3 or 4), keep going
  if (upNext(progress, g)?.entry.id === id && !learned(progress, id)) return { word: UP_NEXT, tone: "next", done, score: sc, checked };
  if (dueBack(progress, id, now) || toGoOver(progress, id)) return { word: "Go over", tone: "rev", done, score: sc, checked };
  if (learned(progress, id)) return { word: "Got it", tone: "done", done, score: sc, checked };
  if (done) return { word: "Keep going", done, score: sc, checked };
  return { word: "Not started", done, score: sc, checked };
}

/** set before going home to open every grade there (Me's "Switch grade") */
export const gradesNext = { set open(v: boolean) { if (v) setBoxView(GRADES_VIEW); } };

type View = "lessons" | "test" | "grade";
const TABS: Tab<View>[] = [{ id: "lessons", label: "Lessons" }, { id: "test", label: "Test" }, { id: "grade", label: "Grade" }];
const TEST_PICK = "test:";

function GradeHome({ g }: { g: number }) {
  const { progress, route, go, reviewDue } = useApp();
  const next = upNext(progress, g);
  const routePick = route.name === "home" ? route.pick : undefined;
  // what Today shows: a test or lesson tapped in the box, else a lesson left mid-practice (so Carry on is always one tap
  // away), else the one the app suggests
  const run = progress.run, runLesson = run?.mode === "practice" ? run.items[run.i]?.lessonId : undefined;
  const pickedTest = routePick?.startsWith(TEST_PICK) ? routePick.slice(TEST_PICK.length) : undefined;
  const pick = pickedTest ? routePick : routePick && entryById(routePick)?.grade === g ? routePick
    : runLesson && entryById(runLesson)?.grade === g ? runLesson : next?.entry.id ?? entriesInGrade(g)[0]?.id;
  const choose = (id: string) => go({ name: "home", pick: id }, "still");
  // coming home with a lesson named (from its Done screen) opens the box on that lesson's chapter, the lesson picked
  const named = routePick && !pickedTest ? entryById(routePick) : undefined;
  useLayoutEffect(() => { if (named?.grade === g && boxView() == null) setBoxView(named.unit); }, []); // eslint-disable-line react-hooks/exhaustive-deps
  return (
    <div className="o-state home">
      {pickedTest ? <TestToday key={pickedTest} g={g} tkey={pickedTest} />
        : !routePick && !runLesson && reviewDue() ? <ReviewToday /> : pick && <TodayPanel key={pick} g={g} id={pick} />}
      <Box g={g} pick={pick} choose={choose} />
    </div>
  );
}

/** the name a test goes by: the grade's test, or a chapter's */
const testName = (g: number, key: string) => key === testKey(g) ? `${gradeOf(g).name} test` : `${key.split(":").slice(2).join(":")} test`;

/** Today: the one lesson to do now, why it's this one, Start, and its first problem drawn. */
function TodayPanel({ g, id }: { g: number; id: string }) {
  const { progress, go, startLesson, now } = useApp();
  const entry = entryById(id)!, lesson = lessonById(id), st = statusOf(progress, g, id, now());
  const suggested = upNext(progress, g)?.entry.id === id;
  const run = progress.run, carry = !!run && run.mode === "practice" && run.items.some(it => it.lessonId === id);
  const fade = dueBack(progress, id, now());
  const ids = useMemo(() => [id], [id]);
  const found = usePreviewPick(ids);
  // v2 spec H4: name a lesson only when Curriculum lists this one in what it builds on (the first, in chapter order)
  const unlocks = entriesInGrade(g).find(c => c.id !== id && dependsOn(c.id).includes(id));
  const why = !lesson ? "This lesson is being rebuilt. It opens here soon."
    : carry ? "You left this one part way. Your work is kept."
    : suggested && !st.done ? `Next in ${entry.unit || gradeOf(g).name}.${unlocks ? ` ${unlocks.title} needs it, so it comes first.` : ""}`
    : fade ? "Your last skill check on this was a while ago. A quick go over keeps it."
    : st.score === 4 ? "Your skill check says you’ve got this. Practise any time to keep it."
    : st.done ? `Your last skill check scored ${st.score ?? 0} of 4. Another go makes it stick.`
    : "Not started yet. Every lesson is open, so you can start here.";
  const start = () => {
    if (carry) return go({ name: "practice" }, "fwd");
    if (st.done) return startLesson(id);
    if (found) handOff(id, found.pic.problem);
    go({ name: "learn", lessonId: id }, "fwd");
  };
  return (
    <section className="o-panel o-today" aria-label="Today">
      <span className="o-label o-in">{carry ? "In progress" : suggested ? "Today" : entry.unit || gradeOf(g).name}</span>
      <h2 className="o-title o-in">{entry.title}</h2>
      <p className="o-why o-in">{why}</p>
      <div className="o-row o-in">
        <button className="o-btn fill" disabled={!lesson} onClick={start}>{carry ? "Carry on" : !st.done ? "Start" : fade || st.tone === "rev" ? "Go over" : "Practise"}</button>
        <span className="o-small">{carry && run ? `Problem ${run.i + 1} of ${run.items.length} · your work is kept` : st.done ? `Practice and skill check · about ${LESSON_MINUTES} minutes` : `Lesson and skill check · about ${LESSON_CHECK_MINUTES} minutes`}</span>
      </div>
      <div className="o-art">{found && <PlayingDiagram ex={{ ...found.pic.ex, diagram: found.pic.ex.diagram! }} end={statementBeat(found.pic.ex)} />}</div>
    </section>
  );
}

/** Today holding a test the child picked in the box */
function TestToday({ g, tkey }: { g: number; tkey: string }) {
  const { startTest } = useApp();
  return (
    <section className="o-panel o-today" aria-label="Today">
      <span className="o-label o-in">Test</span>
      <h2 className="o-title o-in">{testName(g, tkey)}</h2>
      <p className="o-why o-in">4 problems on your own. No hints. It shows what stuck.</p>
      <div className="o-row o-in"><button className="o-btn fill" onClick={() => startTest(tkey)}>Start</button><span className="o-small">About 5 minutes</span></div>
    </section>
  );
}

/** about how long a review problem takes, for Today's meta line (8 problems, about 5 minutes) */
const REVIEW_MIN_PER_PROBLEM = 0.6;

/** Today's review (v2-backend-plan.md; words from v2 spec H3): learned lessons due back come first, in Today */
function ReviewToday() {
  const { progress, startReview, reviewPlan, now } = useApp();
  const { due, problems } = reviewPlan(), one = due.length === 1 ? lessonById(due[0]!) : undefined;
  const days = one ? Math.floor((now() - (progress.checks[one.id]?.date ?? now())) / 864e5) : 0;
  const ago = days >= 14 ? `${Math.floor(days / 7)} weeks ago` : `${days} ${days === 1 ? "day" : "days"} ago`;
  const why = one ? `Your last skill check on ${one.title} was ${ago}. A quick review keeps it.`
    : `${due.length} lessons you’ve learned are due back. A quick review keeps them.`;
  const meta = problems ? `${problems} problems · about ${Math.max(1, Math.round(problems * REVIEW_MIN_PER_PROBLEM))} minutes` : "A few problems · about 5 minutes";
  return (
    <section className="o-panel o-today" aria-label={TODAYS_REVIEW}>
      <span className="o-label o-in">{TODAYS_REVIEW}</span>
      {one && <h2 className="o-title o-in">{one.title}</h2>}
      <p className="o-why o-in">{why}</p>
      <div className="o-row o-in"><button className="o-btn fill" onClick={startReview}>Start</button><span className="o-small">{meta}</span></div>
    </section>
  );
}

/** Tile, the cover kind: a picture on top, the name, then a small ring and one word */
function Cover({ pic, name, p, word, tone, sel, disabled, onClick, label }: { pic?: string; name: string; p: number; word: string; tone?: string; sel?: boolean; disabled?: boolean; onClick: () => void; label: string }) {
  return (
    <button className={`o-tile o-cover${sel ? " sel" : ""}`} disabled={disabled} onClick={onClick} aria-label={label}>
      <span className="o-cpw"><TilePic svg={pic} /></span>
      <span className="o-tx"><span className="o-nm">{name}</span><span className="o-foot"><ORing p={p} /><span className={`o-st${tone ? ` ${tone}` : ""}`}>{word}</span></span></span>
    </button>
  );
}

/** Tile, the stat kind: a big ring with its number, a name and one line (a test, or how the year is going) */
function Stat({ p, big, name, line, tone, sel, onClick, disabled, label }: { p: number; big: string; name: string; line: string; tone?: string; sel?: boolean; onClick?: () => void; disabled?: boolean; label?: string }) {
  const inner = <><ORing p={p} label={big} size="l" /><span className="o-tx"><span className="o-nm">{name}</span><span className={`o-st${tone ? ` ${tone}` : ""}`}>{line}</span></span></>;
  return onClick ? <button className={`o-tile o-stat${sel ? " sel" : ""}`} onClick={onClick} disabled={disabled} aria-label={label}>{inner}</button> : <div className="o-tile o-stat">{inner}</div>;
}

/** how a set of lessons is going: done, got it, to go over (the Grade view's three stat tiles) */
function YearStats({ list }: { list: Entry[] }) {
  const { progress, now } = useApp();
  const m = list.length, n = checkedCount(progress, list), t = now();
  const so = list.filter(c => learned(progress, c.id) && !dueBack(progress, c.id, t)).length;
  const rv = list.filter(c => toGoOver(progress, c.id) || dueBack(progress, c.id, t)).length;
  return <>
    <Stat p={m ? n / m : 0} big={`${n}/${m}`} name="Lessons done" line={m - n ? `${m - n} still to do` : "All done"} />
    <Stat p={m ? so / m : 0} big={`${so}/${m}`} name="Got it" line="Scored 3 or 4" />
    <Stat p={m ? rv / m : 0} big={String(rv)} name="To go over" line={rv ? "Back in Today" : "Nothing yet"} />
  </>;
}

/** The box: every chapter, one chapter's lessons, or every grade; the tests and the year a slide away. */
function Box({ g, pick, choose }: { g: number; pick?: string; choose: (id: string) => void }) {
  const { progress, now } = useApp();
  const view = useBoxView();
  const [tabs, setTabs] = useState<Record<string, View>>({});
  const grade = gradeOf(g), units = unitsInGrade(g), all = entriesInGrade(g);
  const unit = view && view !== GRADES_VIEW ? units.find(u => u.name === view) : undefined;
  const tab: View = tabs[unit?.name ?? ""] ?? "lessons";
  const box = useRef<HTMLElement>(null), grid = useRef<HTMLDivElement>(null);

  // Lessons, Test, Grade: a slideshow. The old tiles slide out, the new ones slide in beside them and snap into place
  const ghost = useRef<{ el: HTMLElement; dir: number } | null>(null);
  const pickTab = (t: View) => {
    const order = TABS.map(x => x.id), dir = Math.sign(order.indexOf(t) - order.indexOf(tab));
    const old = grid.current;
    if (old && dir && !motionOff() && typeof old.animate === "function") {
      const c = old.cloneNode(true) as HTMLElement;
      c.removeAttribute("id"); c.setAttribute("aria-hidden", "true"); c.classList.remove("zin", "zout", "o-arrive");
      c.style.cssText = `position:absolute;margin:0;pointer-events:none;top:${old.offsetTop}px;left:${old.offsetLeft}px;width:${old.offsetWidth}px;height:${old.offsetHeight}px`;
      ghost.current = { el: c, dir };
    }
    setTabs(s => ({ ...s, [unit?.name ?? ""]: t }));
  };
  useLayoutEffect(() => {
    const gh = ghost.current, el = box.current, g2 = grid.current;
    ghost.current = null;
    if (!gh || !el || !g2) { if (motionOff() && g2) { g2.classList.remove("o-arrive"); void g2.offsetWidth; g2.classList.add("o-arrive"); } return; }
    const shift = (gh.el.offsetWidth || g2.offsetWidth) + parseFloat(getComputedStyle(el).columnGap || "10");
    el.appendChild(gh.el);
    const o = { duration: 500, easing: "cubic-bezier(.2,.8,.2,1)" }; // arrive speed, on the ease curve
    gh.el.animate([{ transform: "translateX(0)" }, { transform: `translateX(${-shift * gh.dir}px)` }], o).onfinish = () => gh.el.remove();
    g2.animate([{ transform: `translateX(${shift * gh.dir}px)` }, { transform: "translateX(0)" }], o);
  }, [tab]);

  // going a level deeper or back out: the soft zoom, once per change
  const [zoom, setZoom] = useState<string | null>(null);
  useLayoutEffect(() => { setZoom(boxZoom()); }, [view]);

  // swipe the box left or right to move between Lessons, Test and Grade (the same slide as tapping the slider)
  const sw = useRef({ x: 0, y: 0, t: 0, on: false, swiped: false });
  const onDown = (e: React.PointerEvent) => { if (e.pointerType === "mouse" && e.button) return; Object.assign(sw.current, { on: true, swiped: false, x: e.clientX, y: e.clientY, t: Date.now() }); };
  const onUp = (e: React.PointerEvent) => {
    const s = sw.current;
    if (!s.on) return;
    s.on = false;
    if (view === GRADES_VIEW) return;
    const dx = e.clientX - s.x, dy = e.clientY - s.y;
    if (Math.abs(dx) < 48 || Math.abs(dx) < Math.abs(dy) * 1.5 || Date.now() - s.t > 800) return;
    const i = TABS.findIndex(x => x.id === tab) + (dx < 0 ? 1 : -1);
    if (i < 0 || i >= TABS.length) return;
    s.swiped = true; setTimeout(() => { s.swiped = false; }, 350);
    pickTab(TABS[i]!.id);
  };
  // a swipe never also opens the tile it started on
  const onClickCapture = (e: React.MouseEvent) => { if (sw.current.swiped && !(e.target as Element).closest(".o-sw")) { e.stopPropagation(); e.preventDefault(); sw.current.swiped = false; } };

  const testTile = (key: string, name: string) => {
    const t = progress.tests[key], ready = testReady(g, key === testKey(g) ? undefined : key.split(":").slice(2).join(":"));
    return <Stat key={key} p={t ? t.last / 4 : 0} big={t ? `${t.last}/4` : "–"} name={name} line={!ready ? "Coming soon" : t ? `Last try ${t.last} of 4` : "Not taken yet"}
      tone={t?.last === 4 ? "done" : undefined} sel={pick === TEST_PICK + key} disabled={!ready} onClick={() => choose(TEST_PICK + key)}
      label={`${name}${t ? `, last try ${t.last} of 4` : ", not taken yet"}`} />;
  };

  let head: ReactNode, tiles: ReactNode, gridClass = "o-grid";
  if (view === GRADES_VIEW) {
    head = <h2 className="o-head">Every grade</h2>;
    gridClass += " o-grades";
    tiles = <GradeTiles g={g} />;
  } else {
    const list = unit ? unit.entries : all;
    head = <><h2 className="o-head">{unit ? unit.name : grade.name}</h2>
      <OSlider tabs={TABS} value={tab} onPick={pickTab} label={`${unit ? unit.name : grade.name} views`} /></>;
    if (tab === "lessons") tiles = unit
      ? unit.entries.map(c => {
        const st = statusOf(progress, g, c.id, now());
        return <Cover key={c.id} sel={c.id === pick} disabled={!isReady(c.id)} pic={lessonPic(c.id)} name={c.title} p={(progress.checks?.[c.id]?.last ?? 0) / 4} word={st.word} tone={st.tone}
          onClick={() => choose(c.id)} label={`${c.title}, ${st.word}${progress.checks?.[c.id] ? `, skill check ${progress.checks[c.id]!.last} of 4` : ""}`} />;
      })
      : units.map(u => {
        const n = checkedCount(progress, u.entries), m = u.entries.length;
        return <Cover key={u.name} pic={chapterPic(g, u.name)} name={u.name} p={m ? n / m : 0} word={n === m ? "All done" : `${n}/${m} done`} tone={n === m ? "done" : undefined}
          onClick={() => setBoxView(u.name, "zin")} label={`${u.name}, ${n} of ${m} lessons done`} />;
      });
    else if (tab === "test") tiles = unit ? testTile(testKey(g, unit.name), `${unit.name} test`) : <>
      {testTile(testKey(g), `${grade.name} test`)}
      {units.length > 1 && units.map(u => testTile(testKey(g, u.name), `${u.name} test`))}
    </>;
    else tiles = unit ? <YearStats list={list} /> : <>
      <div className="o-tile o-wide"><span className="o-tx"><span className="o-label">Your {grade.name} year</span><span className="o-nm">{grade.subtitle}.</span></span></div>
      <div className="o-tile o-wide"><div className="o-ptrack"><span className="o-label">The path</span>{units.map(u => {
        const n = checkedCount(progress, u.entries), m = u.entries.length, here = u.entries.some(c => c.id === pick);
        return <div key={u.name} className="o-prow"><span className="o-nm">{u.name}</span><Marks n={m} on={n} />
          <span className={`o-st${here ? " next" : n === m ? " done" : ""}`}>{n === m ? "Done" : here ? "Today" : n ? `${n} of ${m} done` : "Not started"}</span></div>;
      })}</div></div>
      <YearStats list={all} />
    </>;
  }
  return (
    <section className="o-panel o-box" ref={box} aria-label={view === GRADES_VIEW ? "Every grade" : `${grade.name} box`}
      onPointerDown={onDown} onPointerUp={onUp} onPointerCancel={() => { sw.current.on = false; }} onClickCapture={onClickCapture}>
      <div className="o-bh">{head}</div>
      <div key={`${view}|${tab}`} ref={grid} className={`${gridClass}${zoom ? ` ${zoom}` : ""}`} onAnimationEnd={() => setZoom(null)}>{tiles}</div>
    </section>
  );
}

/** the model's ordinal after a grade's number: 1st, 2nd, 3rd, 4th... (K has none) */
const ord = (n: number) => (n === 0 ? "" : n === 1 ? "st" : n === 2 ? "nd" : n === 3 ? "rd" : "th");

/** Every grade, in the box itself: each in its own colour, every tile as tall as the tallest */
function GradeTiles({ g }: { g: number }) {
  const { progress, chooseGrade } = useApp();
  const ref = useRef<HTMLDivElement>(null);
  // every grade tile is the size of the tallest one, so the grid reads as one set of equal cubes
  useLayoutEffect(() => {
    const el = ref.current?.parentElement;
    if (!el) return;
    const same = () => {
      el.style.removeProperty("--gt-h");
      let m = 0;
      el.querySelectorAll<HTMLElement>(".o-gt").forEach(t => { m = Math.max(m, t.offsetHeight); });
      if (m > 0) el.style.setProperty("--gt-h", `${m}px`);
    };
    same();
    const ro = typeof ResizeObserver === "undefined" ? null : new ResizeObserver(same);
    ro?.observe(el);
    return () => ro?.disconnect();
  }, []);
  return <>
    <span ref={ref} hidden />
    {GRADES.map(d => {
      const list = entriesInGrade(d.grade), n = checkedCount(progress, list), m = list.length, me = d.grade === g;
      return (
        <button key={d.grade} className={`o-tile o-gt${me ? " sel" : ""}`} style={{ "--gc": `var(--g${d.grade}-acc)`, "--gs": `var(--g${d.grade}-soft)` } as CSSProperties}
          onClick={() => { setBoxView(null, "zin"); if (!me) chooseGrade(d.grade); }} aria-label={`${d.name}, ${d.subtitle}`}>
          <span className="o-gnum">{d.short}<small>{ord(d.grade)}</small></span>
          <span className="o-tx"><span className="o-nm">{d.subtitle}</span>
            <span className="o-foot"><ORing p={m ? n / m : 0} /><span className="o-st">{me || n ? `${n} of ${m} done` : `${m} lessons`}</span></span></span>
        </button>
      );
    })}
  </>;
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
