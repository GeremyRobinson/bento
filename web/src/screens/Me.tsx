import { Pill, PillLabel } from "../components/primitives/Pill";
import { useApp } from "../app/AppState";
import { doneCount, entriesInGrade, gradeAverage, isReady, testKey, unitsInGrade } from "../app/curriculum";
import { upNext } from "../app/today";
import { GRADES, gradeOf } from "../curriculum/grades";
import { LEVEL_XP } from "../engine/mastery/levels";
import { placeKey } from "../engine/session/practice";
import { lastScore, timesDone } from "../engine/mastery/progress";
import { gradeLevel, ScoreChip } from "../components/primitives/Score";
import { Fill, GradeNum } from "../components/Shelf";
import { Check, LockIcon } from "../components/primitives/icons";
import type { CSSProperties } from "react";
import { SplitScreen } from "../components/screen/Screen";
import { BentoGrid, bgClass } from "../components/BentoGrid";
import { CHOOSE_GRADE, FIND_MY_LEVEL, GROWN_UP, LESSON_MINUTES, minLabel, NO_UNIT, UP_NEXT, YOUR_BENTO } from "../app/copy";

/**
 * My Obento (G 2026-10-06; rebuilt G 2026-10-08 "doesn't look or feel like the rest of the app ... make better use of
 * its space"): the same screen as the grade's book, so it reads as one app. On the left, the Contents list: your grade's
 * big number, the grades you've worked in as rows, Find my level and the grown-up's report. On the right, the book's
 * bento: your level charging up, your streak and XP as number tiles, and the chapter you're in as a plan like Today.
 * No settings (those live on the Settings page). Nothing leaves this device.
 */
export function Me() {
  const { progress, go, openSheet, startTest, chooseGrade } = useApp();
  // before a grade is chosen the page stays neutral and asks for one; nothing assumes a grade
  const g = progress.chosen ? progress.grade : null, grade = g == null ? null : gradeOf(g);
  const gxp = g == null ? 0 : progress.gxp[g] ?? 0, { lvl, into } = gradeLevel(gxp);
  const lessonsDone = Object.keys(progress.lessons).length;

  const chapters = g == null ? [] : unitsInGrade(g).filter(u => u.name !== NO_UNIT);
  const next = g == null ? undefined : upNext(progress, g)?.entry;
  const ci = Math.max(0, chapters.findIndex(u => u.name === (next?.unit || NO_UNIT)));
  const chapter = chapters[ci];
  const score = chapter && g != null ? progress.tests[testKey(g, chapter.name)]?.best ?? 0 : 0;
  const chDone = chapter ? doneCount(progress, chapter.entries) : 0;

  // the grades you've worked in, and the one you're on
  const yours = GRADES.map(d => d.grade).filter(n => n === g || doneCount(progress, entriesInGrade(n)) > 0);
  const switchGrade = () => dispatchEvent(new CustomEvent("bento:contents", { detail: "shelf" }));

  const list = (
    <>
      <header className="shead">
        {grade ? <GradeNum grade={g!} /> : <h1>{YOUR_BENTO}</h1>}
        {grade
          ? <Pill small className="scheck" onClick={switchGrade}>Switch grade</Pill>
          : <Pill small go className="scheck" onClick={() => openSheet(true)}>{CHOOSE_GRADE}</Pill>}
      </header>
      {yours.map(n => {
        const all = entriesInGrade(n), d = doneCount(progress, all), avg = gradeAverage(progress, n);
        return (
          <button key={n} className={`srow mgrade${n === g ? " on" : ""}`} aria-current={n === g ? "true" : undefined}
            onClick={() => n === g ? go({ name: "home" }, "fwd") : chooseGrade(n)}>
            <span className="sname"><b>{gradeOf(n).name}</b></span>
            <small className="smeta">{avg != null ? `average ${avg.toFixed(1)} · ` : ""}{d} of {all.length}</small>
          </button>
        );
      })}
      {g != null && (
        <button className="srow" onClick={() => startTest(placeKey(g))}>
          <span className="sname"><b>{FIND_MY_LEVEL}</b></span><small className="smeta">›</small>
        </button>
      )}
      <button className="srow mgrown" onClick={() => go({ name: "parent" }, "fwd")}>
        <span className="sname"><b>{GROWN_UP}</b></span><small className="smeta"><LockIcon size={12} /> Report ›</small>
      </button>
    </>
  );

  const detail = grade ? (
    <BentoGrid fit className="bhome sbento mybook">
      <section className={`tile b-stats mylevel battery ${bgClass("l")}`}>
        <Fill frac={into / LEVEL_XP} />
        <small className="k">{YOUR_BENTO} · {grade.name}</small>
        <span className="bbig">Level {lvl}</span>
        <p><b>{into} of {LEVEL_XP} XP</b> to level {lvl + 1}</p>
      </section>
      <section className={`tile b-streak ${bgClass("n")}`}>
        <span className="bbig">{progress.streak}</span>
        <p><b>day{progress.streak === 1 ? "" : "s"}</b> in a row</p>
      </section>
      <section className={`tile b-streak ${bgClass("n")}`}>
        <span className="bbig">{progress.xp.toLocaleString("en-US")}</span>
        <p><b>XP</b> · {lessonsDone} lesson{lessonsDone === 1 ? "" : "s"} done</p>
      </section>
      {chapter && (
        <section className={`tile today ${bgClass("f")}`}>
          <header className="thead"><h2>{chapter.name}</h2>
            <p className="sub">Chapter {ci + 1} of {chapters.length} · {chDone} of {chapter.entries.length} lessons · test {score} of 4</p></header>
          <div className="tbody">
            <ol className="plan">{chapter.entries.filter(c => isReady(c.id)).map(c => {
              const done = timesDone(progress, c.id) > 0, now = c === next, sc = lastScore(progress, c.id);
              return (
                <li key={c.id}>
                  <button className={`pitem${done ? " done" : ""}${now ? " now" : ""}`} onClick={() => go({ name: "learn", lessonId: c.id }, "fwd")}>
                    <span className="pmark" aria-hidden>{done ? <Check /> : null}</span>
                    <span className="ptext">{now && <small>{UP_NEXT}</small>}<b>{c.title}</b></span>
                    {now ? <PillLabel go>Start</PillLabel> : sc != null ? <ScoreChip n={sc} /> : <span className="pmin">{minLabel(LESSON_MINUTES)}</span>}
                  </button>
                </li>
              );
            })}</ol>
          </div>
          {next && chapter.entries.includes(next) && <Pill go className="tstart" onClick={() => go({ name: "learn", lessonId: next.id }, "fwd")} aria-label={`Start: ${next.title}`}>Start</Pill>}
        </section>
      )}
    </BentoGrid>
  ) : (
    <section className="tile today mychoose">
      <header className="thead"><h2>Choose your grade</h2>
        <p className="sub">Your level, streak and chapters show up here once you start. You can change grade any time.</p></header>
      <Pill go onClick={() => openSheet(true)}>{CHOOSE_GRADE}</Pill>
    </section>
  );

  return <SplitScreen className="mine" label={YOUR_BENTO} show="list" list={list} detail={detail} />;
}

/**
 * My Obento inside the nav hub (G 2026-10-08: "make the nav bar the hub for options like the dynamic island"): the
 * person circle opens the hub here. The same cards as the hub's Year: your level charging up, your numbers, the
 * chapter you're in with what's up next, the grades you've worked in, and the grown-up's report.
 */
export function MeHub({ leave, toGrades }: { leave: () => void; toGrades: () => void }) {
  const { progress, go, openSheet, startTest, chooseGrade } = useApp();
  const g = progress.chosen ? progress.grade : null, grade = g == null ? null : gradeOf(g);
  const gxp = g == null ? 0 : progress.gxp[g] ?? 0, { lvl, into } = gradeLevel(gxp);
  const lessonsDone = Object.keys(progress.lessons).length;
  const chapters = g == null ? [] : unitsInGrade(g).filter(u => u.name !== NO_UNIT);
  const next = g == null ? undefined : upNext(progress, g)?.entry;
  const ci = Math.max(0, chapters.findIndex(u => u.name === (next?.unit || NO_UNIT)));
  const chapter = chapters[ci];
  const score = chapter && g != null ? progress.tests[testKey(g, chapter.name)]?.best ?? 0 : 0;
  const chDone = chapter ? doneCount(progress, chapter.entries) : 0;
  const yours = GRADES.map(d => d.grade).filter(n => n === g || doneCount(progress, entriesInGrade(n)) > 0);
  const numbers: [string | number, string][] = [
    [progress.streak, progress.streak === 1 ? "day streak" : "days in a row"],
    [progress.xp.toLocaleString("en-US"), "XP in all"],
    [lessonsDone, lessonsDone === 1 ? "lesson done" : "lessons done"],
  ];

  return (
    <section className="zme">
      <article className="zcard battery zlevel" style={{ "--i": 0 } as CSSProperties}>
        {grade ? <>
          <Fill frac={into / LEVEL_XP} />
          <GradeNum grade={g!} />
          <span className="zl-text"><span className="k">{YOUR_BENTO} · {grade.name}</span><b>Level {lvl}</b>
            <small>{into} of {LEVEL_XP} XP to level {lvl + 1}</small></span>
          <Pill onClick={toGrades}>Switch grade</Pill>
        </> : <>
          <span className="zl-text"><span className="k">{YOUR_BENTO}</span><b>Choose your grade</b>
            <small>Your level, streak and chapters show up here once you start.</small></span>
          <Pill go onClick={() => { leave(); openSheet(true); }}>{CHOOSE_GRADE}</Pill>
        </>}
      </article>
      {numbers.map(([n, label], i) => (
        <article key={label} className="zcard znum" style={{ "--i": i + 1 } as CSSProperties}><span className="bbig">{n}</span><span>{label}</span></article>
      ))}
      {chapter && (
        <article className="zcard zchap" style={{ "--i": 4 } as CSSProperties}>
          <span className="k">Chapter {ci + 1} of {chapters.length}</span><b>{chapter.name}</b>
          <small className="muted">{chDone} of {chapter.entries.length} lessons · test {score} of 4</small>
          {next && <Pill go onClick={() => { leave(); go({ name: "learn", lessonId: next.id }, "fwd"); }}>Up next: {next.title} ›</Pill>}
        </article>
      )}
      <article className="zcard zgrown" style={{ "--i": 5 } as CSSProperties}>
        <span className="k"><LockIcon />On this device</span><b>{GROWN_UP}</b>
        <small className="muted">Scores by grade, the exact mistakes made, hints used and every session.</small>
        <Pill onClick={() => { leave(); go({ name: "parent" }, "fwd"); }}>Open the report ›</Pill>
      </article>
      {yours.length > 0 && <>
        <span className="k zme-k">Your grades</span>
        {yours.map((n, i) => {
          const all = entriesInGrade(n), d = doneCount(progress, all), avg = gradeAverage(progress, n), gt = progress.tests[testKey(n)];
          return (
            <button key={n} className={`zcard battery zgrade${n === g ? " on" : ""}`} style={{ "--i": 6 + i } as CSSProperties}
              onClick={() => { leave(); if (n === g) go({ name: "home" }, "back"); else chooseGrade(n); }}>
              <Fill frac={all.length ? d / all.length : 0} />
              <GradeNum grade={n} /><span className="zl-text"><b>{gradeOf(n).subtitle}</b>
                <small>{d} of {all.length} lessons{avg != null ? ` · average ${avg.toFixed(1)} of 4` : ""}{gt ? ` · check‑up ${gt.last} of 4` : ""}</small></span>
            </button>
          );
        })}
      </>}
      {g != null && <Pill className="zfind" onClick={() => { leave(); startTest(placeKey(g)); }}>{FIND_MY_LEVEL} ›</Pill>}
    </section>
  );
}
