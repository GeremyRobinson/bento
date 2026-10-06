import { useLayoutEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { previewOf, statementBeat } from "../app/preview";
import { bandOf, GRADES, gradeOf, tintStyle } from "../curriculum/grades";
import { lessonsInGrade } from "../curriculum/registry";
import { unitsInGrade } from "../app/curriculum";
import { MathLine } from "../components/primitives/MathLine";
import { placeKey } from "../engine/session/practice";
import { PlayingDiagram } from "../components/diagrams/PlayingDiagram";
import { FitScreen } from "../components/screen/Screen";
import { Pill } from "../components/primitives/Pill";
import { GradeNum } from "../components/Shelf";

/**
 * The app's first screen while no grade is chosen: "Which grade are you in?" (Design, handoff 5). Nothing is picked
 * until the learner taps; the tapped year then shows what's inside, drawn from a real random problem.
 */
export function GradeQuestion() {
  const { chooseGrade, startTest, deps } = useApp();
  const [picked, setPicked] = useState<number | null>(null);
  const [ask, setAsk] = useState(false);
  const seed = useMemo(() => Math.floor(deps().rng.next() * 2 ** 31), []); // eslint-disable-line react-hooks/exhaustive-deps
  const shown = useMemo(() => {
    if (picked == null) return null;
    // a real first problem: the year's first lesson that draws a picture, with fresh random numbers (UI notes preview)
    for (const l of lessonsInGrade(picked)) {
      const pv = previewOf(l, seed + picked);
      if (pv?.ex.diagram && pv.ex.diagram.kind !== "chain") return pv;
    }
    return null;
  }, [picked, seed]); // eslint-disable-line react-hooks/exhaustive-deps
  const find = () => { if (picked == null) setAsk(true); else startTest(placeKey(picked)); };
  const d = picked == null ? null : gradeOf(picked);
  const chapters = picked == null ? [] : unitsInGrade(picked).filter(u => u.name !== "Skills");
  // the ring glides to the grade you tap
  const ring = useRef<HTMLSpanElement>(null), moved = useRef(false);
  useLayoutEffect(() => {
    const el = ring.current, b = el?.parentElement?.querySelector<HTMLElement>(".gbtn.on");
    if (!el) return;
    if (!b) { el.style.opacity = "0"; return; }
    if (!moved.current) el.style.transition = "opacity .2s";
    el.style.opacity = "1";
    el.style.width = el.style.height = `${b.offsetWidth + 10}px`;
    el.style.transform = `translate(${b.offsetLeft - 5}px,${b.offsetTop - 5}px)`;
    if (!moved.current) { void el.offsetHeight; el.style.transition = ""; moved.current = true; }
  });

  return (
    <FitScreen className="gq">
      <header className="gqhead">
        <h1>Which grade are you in?</h1>
        <button className="fpill" onClick={find}>Not sure? Find my level</button>
      </header>
      <div className="gstrip" role="radiogroup" aria-label="Grades">
        <span className="gring" ref={ring} aria-hidden />
        {GRADES.map(g => (
          <button key={g.grade} role="radio" aria-checked={g.grade === picked} aria-label={g.name} className={`gbtn${g.grade === picked ? " on" : ""}`}
            style={tintStyle(g) as CSSProperties} onClick={() => { setPicked(g.grade); setAsk(false); }}>{g.short}</button>
        ))}
      </div>
      <section className="gyear">
        {d == null ? (
          <p className="gempty">{ask ? "Tap the grade you think you're in, then Find my level checks it." : "Pick a grade to see what's inside."}</p>
        ) : (
          <div className="wrap t0 gyin" data-grade={d.grade} data-band={bandOf(d.grade)} key={d.grade}>
            <div className="gytext">
              <GradeNum grade={d.grade} />
              <h2>{d.subtitle}</h2>
              <p>{lessonsInGrade(d.grade).length} lessons in {chapters.length} chapter{chapters.length === 1 ? "" : "s"}.</p>
              <ul className="gychips" aria-label={`${d.name} chapters`}>{chapters.map(u => <li key={u.name}>{u.name}</li>)}</ul>
              <div className="gygo"><Pill go onClick={() => chooseGrade(d.grade)}>Start {d.name.split(" · ")[0]} ›</Pill></div>
            </div>
            {shown?.ex.diagram && (
              <figure className="gypic">
                <figcaption>A real first problem: <b><MathLine math={shown.ex.statement} /></b></figcaption>
                <div className="gyviz"><PlayingDiagram key={picked} ex={{ ...shown.ex, diagram: shown.ex.diagram }} end={statementBeat(shown.ex)} /></div>
              </figure>
            )}
          </div>
        )}
      </section>
    </FitScreen>
  );
}
