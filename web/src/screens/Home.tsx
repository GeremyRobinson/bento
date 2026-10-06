import { Pill, PillLabel } from "../components/primitives/Pill";
import { useApp } from "../app/AppState";
import { doneCount, entriesInGrade, gradeAverage, isReady, testKey, testReady, unitsInGrade, type Entry } from "../app/curriculum";
import { gradeOf } from "../curriculum/grades";
import { todayPlan, upNext, type TodayItem } from "../app/today";
import { placeKey } from "../engine/session/practice";
import { Check } from "../components/primitives/icons";
import { lastScore, timesDone } from "../engine/mastery/progress";
import { ScoreChip } from "../components/primitives/Score";
import { Fill } from "../components/Shelf";
import { ChapterPic } from "../components/Contents";
import { Welcome } from "./Welcome";
import { useMemo } from "react";


const KIND = { lesson: "Up next", review: "Review", test: "Unit test", facts: "Fact sprint" } as const;

/**
 * Home is the grade's book: its cover (what this year is about), today's short plan (one tap starts it) with how the
 * year is going beside it, then every chapter with a moving picture and its pages.
 */
export function Home() {
  const { progress } = useApp();
  // no grade chosen yet: choosing is the first thing, so the landing page's shelf stands in
  return progress.grade == null ? <Welcome shelf /> : <GradeHome g={progress.grade} />;
}

function GradeHome({ g }: { g: number }) {
  const { progress, go, openSheet, startLesson, startTest, startReview, canReview, deps } = useApp();
  const rng = useMemo(() => deps().rng, []); // eslint-disable-line react-hooks/exhaustive-deps
  const grade = gradeOf(g), list = entriesInGrade(g), units = unitsInGrade(g);
  const isDone = (id: string) => timesDone(progress, id) > 0;
  const next = upNext(progress, g);
  const plan = todayPlan(progress, g, deps().now, canReview());
  const first = plan.find(i => !i.done);
  const done = doneCount(progress, list), avg = gradeAverage(progress, g);
  const weak = list.filter(c => { const s = lastScore(progress, c.id); return s != null && s <= 1; });
  const gt = progress.tests[testKey(g)];
  const open = (c: Entry) => go({ name: "learn", lessonId: c.id });
  const run = (i: TodayItem) => i.kind === "lesson" ? (i.done ? startLesson(i.id) : go({ name: "learn", lessonId: i.id }))
    : i.kind === "review" ? startReview() : i.kind === "facts" ? go({ name: "facts", table: i.table, start: true }, "fwd") : startTest(i.key);
  const doneScore = (i: TodayItem) => i.kind === "review" ? progress.reviews[new Date(deps().now).toDateString()]
    : i.kind === "lesson" ? lastScore(progress, i.id) : i.kind === "facts" ? undefined : progress.tests[i.key]?.last;
  const minutes = plan.filter(i => !i.done).reduce((m, i) => m + i.minutes, 0);

  let k = 0;
  return (
    <>
      <header className="cover">
        <h1>{grade.name}</h1>
        <p className="ysub">This year: {grade.subtitle.toLowerCase()}.</p>
        <p className="muted">{list.length} lesson{list.length === 1 ? "" : "s"}{units.length > 1 ? ` in ${units.length} chapters` : ""}. Each starts with a picture that moves, then you solve it one step at a time.</p>
        <button className="tlink" onClick={() => openSheet(true)} aria-label="Change grade">Change grade</button>
      </header>
      <div className={`bhome${weak.length ? " tall" : ""}`}>
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
          {testReady(g) && <Pill onClick={() => startTest(testKey(g))}>Grade check-up</Pill>}
        </section>
        {weak.length > 0 && (
          <section className="tile b-weak"><h3>Practice again</h3>
            <div className="lessons">{weak.slice(0, 3).map(c => (
              <button key={c.id} className="lesson" disabled={!isReady(c.id)} onClick={() => open(c)}><ScoreChip n={lastScore(progress, c.id)} /><span className="name">{c.title}</span></button>
            ))}</div>
          </section>
        )}
      </div>
      <div className="units">
        {units.map((u, ui) => {
          const tk = testKey(g, u.name), t = progress.tests[tk];
          return (
            <section className="panel" key={u.name}>
              <ChapterPic entries={u.entries} rng={rng} />
              {(units.length > 1 || u.name !== "Skills") && (
                <div className="unit"><div><span className="k">Chapter {ui + 1}</span><h3>{u.name}</h3></div>
                  {testReady(g, u.name) && <Pill badged={!!t} onClick={() => startTest(tk)}>{t && <ScoreChip n={t.last} />}Unit test</Pill>}
                </div>
              )}
              <div className="lessons">{u.entries.map(c => {
                const sc = lastScore(progress, c.id), live = isReady(c.id); k++;
                return (
                  <button key={c.id} className={`lesson t${(k - 1) % 3}${live ? "" : " soon"}`} disabled={!live} onClick={() => open(c)}
                    aria-label={live ? undefined : `${c.title}, coming soon`}>
                    <span className={`badge${isDone(c.id) ? " on" : ""}`}>{k}</span><span className="name">{c.title}</span>
                    {sc != null ? <ScoreChip n={sc} /> : c === next?.entry ? <span className="dot busy" aria-label="up next" /> : live ? <span className="dot" /> : <span className="muted">soon</span>}
                  </button>
                );
              })}</div>
            </section>
          );
        })}
      </div>
    </>
  );
}


