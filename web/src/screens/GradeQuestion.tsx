import { useEffect, useLayoutEffect, useMemo, useRef, useState, type CSSProperties } from "react";
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
import { TRACKS, TRACK_PARTS, type Track } from "../app/tracks";
import { HorizonPic } from "../components/Advanced";
import type { DiagramModel } from "../explanations/schema";

type Side = "bento" | "b2";
/** small per-device memories, never required: storage can be missing or blocked */
const remember = {
  get: (k: string) => { try { return localStorage.getItem(k); } catch { return null; } },
  set: (k: string, v: string) => { try { localStorage.setItem(k, v); } catch { /* fine without it */ } },
};
const notifyList = () => (remember.get("bento2-notify") ?? "").split(",").filter(Boolean);

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

/** The picture's own shape, so a portrait iPad's well can wrap it instead of leaving it tiny in a tall box (v44 sweep #17). */
const aspectOf = (d: DiagramModel): CSSProperties | undefined =>
  "width" in d && "height" in d && d.width > 0 && d.height > 0 ? ({ "--ar": `${Math.round(d.width)} / ${Math.round(d.height)}` } as CSSProperties) : undefined;
const phone = () => typeof matchMedia !== "undefined" && matchMedia("(max-width: 699px)").matches;

/**
 * The app's first screen while no grade is chosen (Design's grade picker D, G 2026-10-06): one list of all 13 grades
 * with their subjects, and the picked grade's real first problem playing beside it, as one instance of the Screen
 * master. It opens with nothing picked and a random grade's picture in a neutral well, so choosing stays the default;
 * colour arrives with a choice. Tapping a row glides the highlight and swaps only the detail. On a phone the row opens
 * in place with its picture and Start, so nothing scrolls past one screen.
 */
export function GradeQuestion() {
  const { chooseGrade, startTest, deps, sheetOpen, openSheet } = useApp();
  // opened to change grade: Escape goes back to your lessons
  useEffect(() => {
    if (!sheetOpen) return;
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") openSheet(false); };
    addEventListener("keydown", onKey);
    return () => removeEventListener("keydown", onKey);
  }, [sheetOpen, openSheet]);
  const [picked, setPicked] = useState<number | null>(null);
  const [ask, setAsk] = useState(false);
  // Bento or Bento²: the switch remembers your last side on this device; a first visit opens on Bento
  const [side, setSide] = useState<Side>(() => (remember.get("bento-side") === "b2" ? "b2" : "bento"));
  const [track, setTrack] = useState<string | null>(null);
  const [notify, setNotify] = useState<string[]>(notifyList);
  const flip = (to: Side) => { if (to === side) return; setSide(to); setTrack(null); setPicked(null); setAsk(false); remember.set("bento-side", to); };
  // the room dims into Bento²'s dark canvas; leaving the grade screen always brings Bento's light back
  useEffect(() => {
    const root = document.documentElement;
    if (side === "b2") root.dataset.side = "b2"; else delete root.dataset.side;
    return () => { delete root.dataset.side; };
  }, [side]);
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
    // measured from the list itself: the rows' entry motion makes each row its own offset parent
    const list = el.parentElement!, top = row.getBoundingClientRect().top - list.getBoundingClientRect().top + list.scrollTop;
    el.style.transform = `translateY(${top}px)`;
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
            <div className="gyviz" style={aspectOf(teaser.ex.diagram)}><PlayingDiagram key="teaser" ex={{ ...teaser.ex, diagram: teaser.ex.diagram }} end={statementBeat(teaser.ex)} /></div>
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
            <div className="gyviz" style={aspectOf(shown.ex.diagram)}><PlayingDiagram key={g} ex={{ ...shown.ex, diagram: shown.ex.diagram }} end={statementBeat(shown.ex)} /></div>
          </figure>
        )}
        <div className="gdgo">
          <Pill go onClick={() => chooseGrade(g)}>Start {d.name.split(" · ")[0]} ›</Pill>
          {inline && <small>{chapters.length} chapter{chapters.length === 1 ? "" : "s"}</small>}
        </div>
      </div>
    );
  };

  const trackDetail = (t: Track | undefined, inline = false) => {
    if (!t) return (
      <div className="gdl gneutral b2d">
        <div className="gdtext">
          <h2>Bento²</h2>
          <p>Ten tracks past 12th grade: the math thinking machines are built from, then the sciences that use it. It's part of the membership, and it's on the way.</p>
        </div>
        <figure className="gdpic b2pic"><HorizonPic id="ai" /></figure>
      </div>
    );
    const n = TRACKS.indexOf(t) + 1, on = notify.includes(t.id);
    const toggle = () => { const next = on ? notify.filter(x => x !== t.id) : [...notify, t.id]; setNotify(next); remember.set("bento2-notify", next.join(",")); };
    return (
      <div className={`gdl b2d${inline ? " inline" : ""}`} key={t.id}>
        {!inline && (
          <div className="gdtext">
            <small className="b2kick">Track {n} of {TRACKS.length} · {t.part === "spine" ? "The spine" : "A branch"}</small>
            <h2>{t.name}</h2>
            <p>{t.about} Bento² is part of the membership.</p>
          </div>
        )}
        <figure className="gdpic b2pic"><HorizonPic id={t.id} /></figure>
        <div className="gdgo">
          <Pill onClick={toggle} aria-pressed={on}>{on ? "We'll tell you on this device ✓" : "Tell me when it's ready"}</Pill>
          <small>Coming later</small>
        </div>
      </div>
    );
  };

  const sideSwitch = (
    <div className="sideswitch" role="group" aria-label="Bento or Bento²">
      <span className="sidek" aria-hidden />
      <button aria-pressed={side === "bento"} onClick={() => flip("bento")}>Bento</button>
      <button aria-pressed={side === "b2"} aria-label="Bento squared" onClick={() => flip("b2")}>Bento²</button>
    </div>
  );

  let row = 0;
  const b2list = (
    <>
      <span className="sknob" ref={knob} aria-hidden />
      <header className="shead gqh">
        <div className="gqline"><h1>Where do you want to go?</h1>{sideSwitch}</div>
        <span className="b2note">A preview: every track is coming later.</span>
      </header>
      <div role="radiogroup" aria-label="Bento² tracks" className="sideset" key="b2">
        {TRACK_PARTS.map(part => (
          <div key={part.part} className="gpart">
            <span className="slbl" style={{ "--i": row++ } as CSSProperties}>{part.label}</span>
            {TRACKS.filter(t => t.part === part.part).map(t => {
              const on = t.id === track;
              return (
                <div key={t.id} className="gitem" style={{ "--i": row++ } as CSSProperties}>
                  <button role="radio" aria-checked={on} aria-label={t.name} className={`srow trow${on ? " on" : ""}`}
                    onClick={() => setTrack(on && phone() ? null : t.id)}>
                    <span className="ticon"><HorizonPic id={t.id} /></span>
                    <span className="sname"><b>{t.name}</b></span>
                    <small>Coming later</small>
                  </button>
                  {on && phone() && <div className="gopen">{trackDetail(t, true)}</div>}
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </>
  );

  row = 0;
  const list = (
    <>
      <span className="sknob" ref={knob} aria-hidden />
      <header className="shead gqh">
        <div className="gqline"><h1>Which grade are you in?</h1>{sideSwitch}</div>
        <button className="tlink" onClick={find}>Not sure? {FIND_MY_LEVEL} ›</button>
      </header>
      <div role="radiogroup" aria-label="Grades" className="sideset" key="bento">
        {PARTS.map(part => (
          <div key={part.name} className="gpart">
            <span className="slbl" style={{ "--i": row++ } as CSSProperties}>{part.name}</span>
            {part.grades.map(g => {
              const d = gradeOf(g), on = g === picked;
              return (
                <div key={g} className="gitem" style={{ "--i": row++ } as CSSProperties}>
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

  return side === "b2"
    ? <SplitScreen list={b2list} detail={trackDetail(TRACKS.find(t => t.id === track))} show="list" label="Bento² tracks" />
    : <SplitScreen list={list} detail={detail(picked)} show="list" label="Grades" />;
}
