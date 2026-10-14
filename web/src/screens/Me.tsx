import type { ReactNode } from "react";
import { Pill } from "../components/primitives/Pill";
import { Marks } from "../components/Masters";
import { lessonPic, TilePic } from "../components/TilePics";
import { dueBack, learnedNow, REVIEW_DAYS, toGoOver } from "../engine/mastery/skills";
import { useApp } from "../app/AppState";
import { doneCount, entriesInGrade, gradeAverage, isReady, testKey, unitsInGrade, type Entry } from "../app/curriculum";
import { upNext } from "../app/today";
import { GRADES, gradeOf } from "../curriculum/grades";
import { LEVEL_XP } from "../engine/mastery/levels";
import { placeKey } from "../engine/session/practice";
import { gradeLevel } from "../components/primitives/Score";
import { Fill, GradeNum } from "../components/Shelf";
import { LockIcon } from "../components/primitives/icons";
import type { CSSProperties } from "react";
import { CHOOSE_GRADE, FIND_MY_LEVEL, GROWN_UP, NO_UNIT, YOUR_BENTO } from "../app/copy";

/** days in words: "1 day", "5 days" */
const days = (n: number) => (n === 1 ? "1 day" : `${n} days`);

/**
 * Me (UI model v61, G 2026-10-14): the child's own page, three shelves. Go over: what slipped or scored under 3, the
 * first one the button's. Getting stronger: learned lessons on their way through the four checks (3, 7, 21 and 60 days).
 * Stuck: lessons that passed all four. A lesson moves right as its checks pass. The grown-up's page sits behind the lock.
 */
export function Me() {
  const { progress, go, openSheet, now } = useApp();
  const g = progress.chosen ? progress.grade : null;
  if (g == null) {
    // before a grade is chosen the page stays neutral and asks for one; nothing assumes a grade
    return (
      <div className="o-state me">
        <section className="o-panel" aria-label={YOUR_BENTO}>
          <h2 className="o-head o-in">Choose your grade</h2>
          <p className="o-why o-in">Your lessons show up here once you start. You can change grade any time.</p>
          <div className="o-row o-in"><button className="o-btn fill" onClick={() => openSheet(true)}>{CHOOSE_GRADE}</button></div>
        </section>
      </div>
    );
  }
  const t = now(), all = entriesInGrade(g).filter(c => isReady(c.id));
  const passes = (id: string) => progress.checks?.[id]?.passes ?? 0;
  const over = all.filter(c => dueBack(progress, c.id, t) || toGoOver(progress, c.id));
  const grow = all.filter(c => learnedNow(progress, c.id, t) && passes(c.id) < REVIEW_DAYS.length);
  const stuck = all.filter(c => learnedNow(progress, c.id, t) && passes(c.id) >= REVIEW_DAYS.length);
  const first = over[0] ?? upNext(progress, g)?.entry;
  const open = (id: string) => go({ name: "learn", lessonId: id }, "fwd");
  const row = (c: Entry, word: string, sel = false) => (
    <button key={c.id} className={`o-tile o-lrow${sel ? " sel" : ""}`} onClick={() => open(c.id)} aria-label={`${c.title}, ${word}`}>
      <span className="o-cpw"><TilePic svg={lessonPic(c.id)} /></span>
      <span className="o-tx"><span className="o-nm">{c.title}</span><Marks n={REVIEW_DAYS.length} on={passes(c.id)} /><span className={`o-st${sel ? " next" : ""}`}>{word}</span></span>
    </button>
  );
  const shelf = (name: string, list: Entry[], fill: boolean, body: ReactNode, foot?: ReactNode) => (
    <section className="o-panel o-shelfp" aria-label={name}>
      <div className="o-shh"><h2 className="o-head">{name}</h2><span className={`o-count${fill ? " fill" : ""}`}>{list.length}</span></div>
      <div className="o-shelf">{body}</div>
      {foot ?? <span />}
    </section>
  );
  return (
    <div className="o-state me">
      {shelf("Go over", over, over.length > 0,
        over.length ? over.map((c, i) => row(c, dueBack(progress, c.id, t) ? "Time to go over it" : `Last check ${progress.checks[c.id]!.last} of 4`, i === 0))
          : <p className="o-why">Nothing to go over. Nice.</p>,
        first && <button className="o-btn fill o-in" onClick={() => open(first.id)}>{over.length ? "Go over: " : "Up next: "}{first.title}</button>)}
      {shelf("Getting stronger", grow, false,
        grow.length ? grow.map(c => row(c, `Next check in ${days(Math.max(1, Math.ceil((progress.checks[c.id]!.due - t) / 864e5)))}`))
          : <p className="o-why">Learn a lesson and it comes here.</p>)}
      {shelf("Stuck", stuck, false,
        <>{stuck.map(c => row(c, "Stuck for good"))}<p className="o-why">Pass all four checks and a lesson moves here.</p></>,
        <button className="o-btn o-gulink" onClick={() => go({ name: "parent" }, "fwd")}><span className="o-lk"><LockIcon /> {GROWN_UP}</span></button>)}
    </div>
  );
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
    [progress.streak, progress.streak === 1 ? "day in a row" : "days in a row"],
    [progress.xp.toLocaleString("en-US"), "points in all"],
    [lessonsDone, lessonsDone === 1 ? "lesson done" : "lessons done"],
  ];

  return (
    <section className="zme">
      <article className="zcard battery zlevel" style={{ "--i": 0 } as CSSProperties}>
        {grade ? <>
          <Fill frac={into / LEVEL_XP} />
          <GradeNum grade={g!} />
          <span className="zl-text"><span className="k">{YOUR_BENTO} · {grade.name}</span><b>Level {lvl}</b>
            <small>{into} of {LEVEL_XP} points to level {lvl + 1}</small></span>
          <Pill onClick={toGrades}>Change grade</Pill>
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
          <small className="muted">{chDone} of {chapter.entries.length} lessons · chapter test {score} of 4</small>
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
                <small>{d} of {all.length} lessons{avg != null ? ` · average score ${avg.toFixed(1)} of 4` : ""}{gt ? ` · test ${gt.last} of 4` : ""}</small></span>
            </button>
          );
        })}
      </>}
      {g != null && <Pill className="zfind" onClick={() => { leave(); startTest(placeKey(g)); }}>{FIND_MY_LEVEL} ›</Pill>}
    </section>
  );
}
