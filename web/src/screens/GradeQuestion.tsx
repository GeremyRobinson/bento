import { useMemo, useState, type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { previewOf } from "../app/preview";
import { bandOf, GRADES, gradeOf, tintStyle } from "../curriculum/grades";
import { lessonsInGrade } from "../curriculum/registry";
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
    // a lesson of the year that draws a picture, picked at random
    const rng = deps().rng;
    for (const l of rng.shuffle(lessonsInGrade(picked))) {
      const pv = previewOf(l, seed + picked);
      if (pv?.ex.diagram && pv.ex.diagram.kind !== "chain") return pv;
    }
    return null;
  }, [picked, seed]); // eslint-disable-line react-hooks/exhaustive-deps
  const find = () => { if (picked == null) setAsk(true); else startTest(placeKey(picked)); };
  const d = picked == null ? null : gradeOf(picked);

  return (
    <FitScreen className="gq">
      <header className="gqhead">
        <h1>Which grade are you in?</h1>
        <button className="tlink" onClick={find}>Not sure? Find my level ›</button>
      </header>
      <div className="gstrip" role="radiogroup" aria-label="Grades">
        {GRADES.map(g => (
          <button key={g.grade} role="radio" aria-checked={g.grade === picked} aria-label={g.name} className={`gbtn${g.grade === picked ? " on" : ""}`}
            style={tintStyle(g) as CSSProperties} onClick={() => { setPicked(g.grade); setAsk(false); }}>{g.short}</button>
        ))}
      </div>
      <section className="gyear">
        {d == null ? (
          <p className="muted gempty">{ask ? "Tap the grade you think you're in, then Find my level checks it." : "Pick a grade to see what's inside."}</p>
        ) : (
          <div className="wrap t0 gyin" data-grade={d.grade} data-band={bandOf(d.grade)} key={d.grade}>
            <div className="gytext">
              <GradeNum grade={d.grade} />
              <h2>{d.name}</h2>
              <p className="muted">This year: {d.subtitle.toLowerCase()}. {lessonsInGrade(d.grade).length} lessons.</p>
            </div>
            {shown?.ex.diagram && <div className="gypic"><PlayingDiagram key={picked} ex={{ ...shown.ex, diagram: shown.ex.diagram }} hold={600} /></div>}
            <div className="gygo"><Pill go className="dark" onClick={() => chooseGrade(d.grade)}>Start {d.name.split(" · ")[0]} ›</Pill></div>
          </div>
        )}
      </section>
    </FitScreen>
  );
}
