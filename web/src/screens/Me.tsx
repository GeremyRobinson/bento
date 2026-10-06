import { Pill } from "../components/primitives/Pill";
import { type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { doneCount, entriesInGrade, testKey, unitsInGrade } from "../app/curriculum";
import { upNext } from "../app/today";
import { GRADES, gradeOf, tintStyle } from "../curriculum/grades";
import { LEVEL_XP, LEVELS } from "../engine/mastery/levels";
import { placeKey } from "../engine/session/practice";
import { gradeLevel } from "../components/primitives/Score";
import { Fill, GradeNum } from "../components/Shelf";
import { LockIcon } from "../components/primitives/icons";
import { CHOOSE_GRADE, FIND_MY_LEVEL, GROWN_UP, NO_UNIT, YOUR_BENTO } from "../app/copy";

/** A chapter's 0-4 score as a four-cell battery, the same fill the book uses. */
function ChapterBattery({ score }: { score: number }) {
  return <span className="cbat" aria-hidden>{[0, 1, 2, 3].map(i => <i key={i} className={i < score ? "on" : ""} />)}</span>;
}

/** One number that matters, big, with what it counts underneath. */
function Stat({ n, label, className }: { n: string | number; label: string; className: string }) {
  return <section className={`tile mytile mystat ${className}`}><b className="mono">{n}</b><span>{label}</span></section>;
}

/**
 * My Bento (G 2026-10-06): its own page, reached from the person circle, with no pop-over version and no settings
 * (those live on the Settings page). A bento of you: your grade and level, the numbers that matter, the chapter
 * you're in and what's up next, the grades you've worked in, and the report for your grown-up. Nothing leaves this device.
 */
export function Me() {
  const { progress, go, openSheet, startTest } = useApp();
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

  // the grades you've worked in, and the one you're on, each with how far along it is
  const yours = GRADES.map(d => d.grade).filter(n => n === g || doneCount(progress, entriesInGrade(n)) > 0);

  return (
    <div className="bmine">
      <section className="tile mytile myhero battery" style={grade ? tintStyle(grade) as CSSProperties : undefined}>
        {grade ? <>
          <Fill frac={into / LEVEL_XP} />
          <span className="bbig"><GradeNum grade={g!} /></span>
          <div className="myh-text">
            <span className="k">{YOUR_BENTO} · {grade.name}</span>
            <h1>Level {lvl}</h1>
            <p className="muted">{into} of {LEVEL_XP} XP to level {lvl + 1}</p>
          </div>
          <Pill onClick={() => openSheet(true)}>Switch grade</Pill>
        </> : (
          <div className="myh-text">
            <span className="k">{YOUR_BENTO}</span>
            <h1>Choose your grade</h1>
            <p className="muted">Your level, streak and chapters show up here once you start. You can change grade any time.</p>
            <Pill go onClick={() => openSheet(true)}>{CHOOSE_GRADE}</Pill>
          </div>
        )}
      </section>

      <Stat className="mystreak" n={progress.streak} label="day streak" />
      <Stat className="myxp" n={progress.xp.toLocaleString("en-US")} label="XP in all" />
      <Stat className="mydone" n={lessonsDone} label={lessonsDone === 1 ? "lesson done" : "lessons done"} />

      {chapter && g != null && (
        <section className="tile mytile mychap" style={tintStyle(grade!) as CSSProperties} aria-label={`Chapter ${ci + 1}, ${chapter.name}, ${score} of 4, ${LEVELS[score]}`}>
          <span className="k">Chapter {ci + 1} of {chapters.length}</span>
          <h2>{chapter.name}</h2>
          <div className="mych-score"><ChapterBattery score={score} /><span><b>{LEVELS[score]}</b><small>{chDone} of {chapter.entries.length} lessons · test {score} of 4</small></span></div>
          {next && <Pill go onClick={() => go({ name: "learn", lessonId: next.id }, "fwd")}>Up next: {next.title} ›</Pill>}
        </section>
      )}

      <section className="tile mytile mygrades">
        <span className="k">Your grades</span>
        {yours.length ? (
          <ul className="mygl">{yours.map(n => {
            const all = entriesInGrade(n), d = doneCount(progress, all), gd = gradeOf(n);
            return (
              <li key={n} className={`battery${n === g ? " on" : ""}`} style={tintStyle(gd) as CSSProperties}>
                <Fill frac={all.length ? d / all.length : 0} />
                <GradeNum grade={n} /><span><b>{gd.subtitle}</b><small>{d} of {all.length} lessons</small></span>
              </li>
            );
          })}</ul>
        ) : <p className="muted">The grades you work in show up here.</p>}
        {g != null && <button className="tlink" onClick={() => startTest(placeKey(g))}>{FIND_MY_LEVEL} ›</button>}
      </section>

      <section className="tile mytile mygrown">
        <span className="k"><LockIcon />On this device</span>
        <h2>{GROWN_UP}</h2>
        <p className="muted">Scores by grade, the exact mistakes made, hints used and every session.</p>
        <Pill onClick={() => go({ name: "parent" }, "fwd")}>Open the report ›</Pill>
      </section>
    </div>
  );
}
