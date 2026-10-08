import { Pill } from "../components/primitives/Pill";
import { type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { doneCount, entriesInGrade, gradeAverage, testKey, unitsInGrade } from "../app/curriculum";
import { upNext } from "../app/today";
import { GRADES, gradeOf, tintStyle } from "../curriculum/grades";
import { LEVEL_XP, LEVELS } from "../engine/mastery/levels";
import { placeKey } from "../engine/session/practice";
import { gradeLevel } from "../components/primitives/Score";
import { Fill, GradeNum } from "../components/Shelf";
import { LockIcon } from "../components/primitives/icons";
import { Tile } from "../components/PageTile";
import { CHOOSE_GRADE, FIND_MY_LEVEL, GROWN_UP, NO_UNIT, YOUR_BENTO } from "../app/copy";

/** A chapter's 0-4 score as a four-cell battery, the same fill the book uses. */
function ChapterBattery({ score }: { score: number }) {
  return <span className="cbat" aria-hidden>{[0, 1, 2, 3].map(i => <i key={i} className={i < score ? "on" : ""} />)}</span>;
}

/** One fact about you as a Row: what it counts on the left, the number on the right (the same row as Settings). */
function Fact({ label, note, n }: { label: string; note?: string; n: string | number }) {
  return <div className="mtoggle mfact"><span className="mt-text"><b>{label}</b>{note && <small>{note}</small>}</span><b className="mf-n">{n}</b></div>;
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
    <div className="bset bmine">
      {/* you: your grade and level, then the numbers that matter as rows, the same Panel + Row as Settings (G 2026-10-08) */}
      <Tile className="myou" k={grade ? <>{YOUR_BENTO} · {grade.subtitle}</> : YOUR_BENTO} title={grade ? `Level ${lvl}` : "Choose your grade"}>
        {grade ? (
          <div className="mtoggle mfact mylevel battery" style={tintStyle(grade) as CSSProperties}>
            <Fill frac={into / LEVEL_XP} />
            <GradeNum grade={g!} />
            <span className="mt-text"><b>{grade.name}</b><small>{into} of {LEVEL_XP} XP to level {lvl + 1}</small></span>
          </div>
        ) : <p className="muted">Your level, streak and chapters show up here once you start. You can change grade any time.</p>}
        <Fact label="Day streak" note="Days in a row you've practised" n={progress.streak} />
        <Fact label="XP in all" note="Across every grade" n={progress.xp.toLocaleString("en-US")} />
        <Fact label="Lessons done" n={lessonsDone} />
        <div className="actions">
          {grade
            ? <Pill onClick={() => dispatchEvent(new CustomEvent("bento:contents", { detail: "shelf" }))}>Switch grade</Pill>
            : <Pill go onClick={() => openSheet(true)}>{CHOOSE_GRADE}</Pill>}
        </div>
      </Tile>

      {chapter && g != null && (
        <Tile className="mytile mychap" k={`Chapter ${ci + 1} of ${chapters.length}`} title={chapter.name}>
          <div className="mtoggle mfact"><ChapterBattery score={score} /><span className="mt-text"><b>{LEVELS[score]}</b><small>{chDone} of {chapter.entries.length} lessons · test {score} of 4</small></span></div>
          {next && <div className="actions"><Pill go onClick={() => go({ name: "learn", lessonId: next.id }, "fwd")}>Up next: {next.title} ›</Pill></div>}
        </Tile>
      )}

      <Tile className="mytile mygrades" k="Your grades">
        {yours.length ? (
          <ul className="mygl">{yours.map(n => {
            // each grade's average and check-up live here on every size (Design 2026-10-07), not in the book's number tiles
            const all = entriesInGrade(n), d = doneCount(progress, all), gd = gradeOf(n), avg = gradeAverage(progress, n), gt = progress.tests[testKey(n)];
            return (
              <li key={n} className={`mtoggle mfact battery${n === g ? " on" : ""}`} style={tintStyle(gd) as CSSProperties}>
                <Fill frac={all.length ? d / all.length : 0} />
                <GradeNum grade={n} /><span className="mt-text"><b>{gd.subtitle}</b><small>{d} of {all.length} lessons{avg != null && ` · average ${avg.toFixed(1)} of 4`}{gt && ` · check‑up ${gt.last} of 4`}</small></span>
              </li>
            );
          })}</ul>
        ) : <p className="muted">The grades you work in show up here.</p>}
        {g != null && <div className="actions"><Pill onClick={() => startTest(placeKey(g))}>{FIND_MY_LEVEL} ›</Pill></div>}
      </Tile>

      <Tile className="mytile mygrown" k={<><LockIcon />On this device</>} title={GROWN_UP}>
        <p className="muted">Scores by grade, the exact mistakes made, hints used and every session.</p>
        <div className="actions"><Pill onClick={() => go({ name: "parent" }, "fwd")}>Open the report ›</Pill></div>
      </Tile>
    </div>
  );
}
