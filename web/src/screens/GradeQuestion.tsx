import { useLayoutEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { previewOf, statementBeat } from "../app/preview";
import { bandOf, gradeOf, tintStyle } from "../curriculum/grades";
import { lessonsInGrade } from "../curriculum/registry";
import { unitsInGrade } from "../app/curriculum";
import { MathLine } from "../components/primitives/MathLine";
import { placeKey } from "../engine/session/practice";
import { PlayingDiagram } from "../components/diagrams/PlayingDiagram";
import { SplitScreen } from "../components/screen/Screen";
import { Pill } from "../components/primitives/Pill";
import { GradeNum } from "../components/Shelf";
import { FIND_MY_LEVEL, NO_UNIT } from "../app/copy";

/** the four parts of Bento, as the grade list groups them (Design's grade picker D) */
const PARTS = [
  { name: "Bento Early", grades: [0, 1, 2] },
  { name: "Bento Core", grades: [3, 4, 5] },
  { name: "Bento Middle", grades: [6, 7, 8] },
  { name: "Bento High", grades: [9, 10, 11, 12] },
];

/** a grade's first lesson that draws a picture, with fresh random numbers */
function firstPicture(grade: number, seed: number) {
  for (const l of lessonsInGrade(grade)) {
    const pv = previewOf(l, seed + grade);
    if (pv?.ex.diagram && pv.ex.diagram.kind !== "chain") return pv;
  }
  return null;
}

const phone = () => typeof matchMedia !== "undefined" && matchMedia("(max-width: 699px)").matches;

/**
 * The app's first screen while no grade is chosen (Design's grade picker D, G 2026-10-06): one list of all 13 grades
 * with their subjects, and the picked grade's real first problem playing beside it, as one instance of the Screen
 * master. It opens with nothing picked and a random grade's picture in a neutral well, so choosing stays the default;
 * colour arrives with a choice. Tapping a row glides the highlight and swaps only the detail. On a phone the row opens
 * in place with its picture and Start, so nothing scrolls past one screen.
 */
export function GradeQuestion() {
  const { chooseGrade, startTest, deps } = useApp();
  const [picked, setPicked] = useState<number | null>(null);
  const [ask, setAsk] = useState(false);
  const seed = useMemo(() => Math.floor(deps().rng.next() * 2 ** 31), []); // eslint-disable-line react-hooks/exhaustive-deps
  // before a choice: any grade's picture, so the well is never empty
  const teaser = useMemo(() => firstPicture(seed % 13, seed), [seed]);
  const shown = useMemo(() => (picked == null ? null : firstPicture(picked, seed)), [picked, seed]);
  const find = () => { if (picked == null) setAsk(true); else startTest(placeKey(picked)); };

  // the highlight glides to the row you tap
  const knob = useRef<HTMLSpanElement>(null), placed = useRef(false);
  useLayoutEffect(() => {
    const el = knob.current, row = el?.parentElement?.querySelector<HTMLElement>(".srow.on");
    if (!el) return;
    if (!row) { el.style.opacity = "0"; return; }
    if (!placed.current) el.style.transition = "none";
    el.style.opacity = "1";
    el.style.transform = `translateY(${row.offsetTop}px)`;
    el.style.height = `${row.offsetHeight}px`;
    if (!placed.current) { void el.offsetHeight; el.style.transition = ""; placed.current = true; }
  });

  const detail = (g: number | null, inline = false) => {
    if (g == null) return (
      <div className="gdl gneutral">
        <div className="gdtext">
          <h2>{ask ? "Tap the grade you think you're in" : "Pick your grade"}</h2>
          <p>{ask ? "Then Find my level checks it with a few problems." : "Every grade starts with a picture like this one, drawn from a real problem."}</p>
        </div>
        {teaser?.ex.diagram && (
          // the picture keeps its own grade's colours; only the chrome around it waits for a choice
          <figure className="gdpic" data-grade={seed % 13} data-band={bandOf(seed % 13)}>
            <div className="gyviz"><PlayingDiagram key="teaser" ex={{ ...teaser.ex, diagram: teaser.ex.diagram }} end={statementBeat(teaser.ex)} /></div>
          </figure>
        )}
      </div>
    );
    const d = gradeOf(g), chapters = unitsInGrade(g).filter(u => u.name !== NO_UNIT), n = lessonsInGrade(g).length;
    return (
      <div className={`gdl${inline ? " inline" : ""}`} data-grade={g} data-band={bandOf(g)} key={g} style={tintStyle(d) as CSSProperties}>
        {!inline && (
          <div className="gdtext">
            <GradeNum grade={g} />
            <h2>{d.subtitle}</h2>
            <p>{n} lessons in {chapters.length} chapter{chapters.length === 1 ? "" : "s"}.</p>
          </div>
        )}
        {shown?.ex.diagram && (
          <figure className="gdpic">
            <figcaption>Your first problem: <b><MathLine math={shown.ex.statement} /></b></figcaption>
            <div className="gyviz"><PlayingDiagram key={g} ex={{ ...shown.ex, diagram: shown.ex.diagram }} end={statementBeat(shown.ex)} /></div>
          </figure>
        )}
        <div className="gdgo">
          <Pill go onClick={() => chooseGrade(g)}>Start {d.name.split(" · ")[0]} ›</Pill>
          {inline && <small>{chapters.length} chapter{chapters.length === 1 ? "" : "s"}</small>}
        </div>
      </div>
    );
  };

  const list = (
    <>
      <span className="sknob" ref={knob} aria-hidden />
      <header className="shead gqh">
        <h1>Which grade are you in?</h1>
        <button className="tlink" onClick={find}>Not sure? {FIND_MY_LEVEL} ›</button>
      </header>
      <div role="radiogroup" aria-label="Grades">
        {PARTS.map(part => (
          <div key={part.name} className="gpart">
            <span className="slbl">{part.name}</span>
            {part.grades.map(g => {
              const d = gradeOf(g), on = g === picked;
              return (
                <div key={g} className="gitem">
                  <button role="radio" aria-checked={on} aria-label={d.name} className={`srow grow${on ? " on" : ""}`} style={tintStyle(d) as CSSProperties}
                    onClick={() => { setAsk(false); setPicked(on && phone() ? null : g); }}>
                    <span className="gcol"><GradeNum grade={g} /></span>
                    <span className="sname"><b>{d.subtitle}</b></span>
                    <small>{lessonsInGrade(g).length} lessons</small>
                  </button>
                  {/* on a phone the picked row opens in place, with its picture and Start */}
                  {on && phone() && <div className="gopen">{detail(g, true)}</div>}
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </>
  );

  return <SplitScreen list={list} detail={detail(picked)} show="list" label="Grades" />;
}
