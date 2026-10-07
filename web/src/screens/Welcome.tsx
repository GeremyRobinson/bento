import { Pill } from "../components/primitives/Pill";
import { useCallback, useEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { entryById } from "../app/curriculum";
import { GRADES, gradeOf, tintStyle } from "../curriculum/grades";
import { lessonById, lessonsInGrade } from "../curriculum/registry";
import type { Rng } from "../curriculum/generators/rng";
import { PlayingDiagram } from "../components/diagrams/PlayingDiagram";
import { reduceMotion } from "../app/transition";
import { FeatureBox } from "../components/LandingTiles";
import { GradeNum } from "../components/Shelf";
import { OneIdea } from "../components/LandingStory";
import { Advanced } from "../components/Advanced";
import type { Explanation } from "../explanations/schema";
import { START_LEARNING } from "../app/copy";

/**
 * Layouts for the landing grid, in the order the tiles are placed. Each one fills three columns by three rows
 * exactly, so whichever is drawn, the bento stays a clean rectangle with no gaps.
 */
type Size = "big" | "wide" | "one";
const LAYOUTS: Size[][] = [
  ["big", "one", "one", "one", "one", "one"],
  ["one", "big", "one", "one", "one", "one"],
  ["big", "one", "one", "wide", "one"],
  ["one", "big", "one", "one", "wide"],
  ["wide", "one", "one", "wide", "wide", "one"],
  ["one", "wide", "wide", "one", "one", "wide"],
];

export interface Showcase { id: string; size: Size; color: string; tail?: boolean }

/**
 * A fresh landing grid on every visit: a random layout, and one random lesson from each of a few random grades,
 * each showing a picture drawn from its own random problem.
 */
export function pickShowcase(rng: Rng): (Showcase & { ex: Pictured })[] {
  const sizes = rng.pick(LAYOUTS);
  const out: (Showcase & { ex: Pictured })[] = [];
  for (const g of rng.shuffle(GRADES.map(x => x.grade))) {
    if (out.length === sizes.length) break;
    for (const l of rng.shuffle(lessonsInGrade(g))) {
      const ex = showcasePicture(l.id, rng);
      if (ex) { out.push({ id: l.id, size: sizes[out.length]!, color: gradeOf(g).color, ex }); break; }
    }
  }
  // in two columns, single tiles pair up; an odd one out takes the whole row instead of leaving a gap
  const ones = out.filter(o => o.size === "one");
  if (ones.length % 2) ones[ones.length - 1]!.tail = true;
  return out;
}

type Pictured = Explanation & { diagram: NonNullable<Explanation["diagram"]> };

/** Showcases want pictures, not ladders of equations: those look crammed in a tile (G, 2026-10-03), so they're passed over. */
const tooTall = (d: Pictured["diagram"]) => d.kind === "chain";

/** A fresh problem's explanation picture for a showcase lesson, or null while the lesson isn't rebuilt (or has no picture that fits a tile). */
export function showcasePicture(id: string, rng: Rng): Pictured | null {
  const lesson = lessonById(id);
  if (!lesson) return null;
  const tryOne = (p: unknown): Pictured | null => {
    const ex = lesson.explain(p, lesson.answers(p));
    if (!ex.diagram || tooTall(ex.diagram)) return null;
    return ex as Pictured;
  };
  try { return tryOne(lesson.generate(rng, 0)); } catch { /* fall back to the worked reference */ }
  try { return tryOne(lesson.reference); } catch { return null; }
}

/**
 * The hero's three pictures, each from its own pool of lessons with rich, full-tile diagrams (Design, handoff 2):
 * the big tile, then early and core grades, then middle and high school. Sparse pictures and equation ladders stay out.
 */
export const HERO_POOLS = [
  ["g8-pyth", "g10-polygon", "g5-volume", "g10-surface", "g9-growth", "g8-system", "g11-comb", "g2-time5"],
  ["g2-hundreds", "g1-tensones", "g2-regroup", "g6-lcm", "g3-area", "g7-prob", "g1-time"],
  ["g9-solvefactor", "g11-log", "g12-tangent", "g8-roots", "g10-pyramid", "g9-factor", "g11-complex"],
];
/** Each tile shows its finished picture this long before it plays (G 2026-10-03: open on the finished picture); the big tile starts first, the others a beat later each; a change waits until no other tile changed for GAP. */
const HOLD = 3000;
const STAGGER = 600, GAP = 1200;

type Shot = { id: string; grade: number; ex: Pictured };

/** The next lesson in a pool whose picture draws, from a grade the other tiles aren't showing. */
function nextShot(pool: string[], from: number, avoid: number[], rng: Rng): [Shot, number] | null {
  for (let k = 1; k <= pool.length; k++) {
    const at = (from + k) % pool.length, id = pool[at]!, grade = lessonById(id)?.grade;
    if (grade == null || avoid.includes(grade)) continue;
    const ex = showcasePicture(id, rng);
    if (ex) return [{ id, grade, ex }, at];
  }
  return null;
}

/** One hero tile: a lesson's moving picture with its grade and title. Tap to skip to the next one. */
function HeroTile({ shot, n, big, start, next }: { shot: Shot; n: number; big: boolean; start: number; next: () => void }) {
  // every tile opens on its finished picture, holds it, then plays; the stagger keeps the three out of step
  const hold = HOLD + start;
  useEffect(() => {
    if (reduceMotion()) return;
    const t = setTimeout(next, hold + 2400 + shot.ex.timeline.length * 750);
    return () => clearTimeout(t);
  }, [shot, hold, next]);
  const g = gradeOf(shot.grade), entry = entryById(shot.id);
  return (
    // the card stays put; only what's inside it fades over to the next picture
    <figure className={`lhpic gpal${big ? "" : " sm"}`} data-grade={shot.grade} style={tintStyle(g) as CSSProperties} onClick={next}>
      <figcaption key={`c${n}`}><GradeNum grade={shot.grade} /><span><small>See it first</small><b>{entry?.title ?? shot.id}</b></span></figcaption>
      <div className="lhd" key={`d${n}`}><PlayingDiagram ex={shot.ex} hold={hold} /></div>
    </figure>
  );
}

/** The hero box: three moving pictures from three different grades, one per pool, taking turns to change. */
function HeroPictures({ rng }: { rng: Rng }) {
  const pools = useMemo(() => HERO_POOLS.map(p => rng.shuffle(p.filter(id => lessonById(id)))), [rng]);
  const [tiles, setTiles] = useState(() => {
    const out: { shot: Shot; at: number; n: number }[] = [];
    for (const pool of pools) {
      const r = nextShot(pool, -1, out.map(t => t.shot.grade), rng);
      if (r) out.push({ shot: r[0], at: r[1], n: 0 });
    }
    return out;
  });
  const last = useRef(0);
  const advance = useCallback((i: number) => {
    const wait = last.current + GAP - Date.now();
    if (wait > 0) { setTimeout(() => advance(i), wait); return; }
    last.current = Date.now();
    setTiles(ts => {
      const r = nextShot(pools[i]!, ts[i]!.at, ts.filter((_, j) => j !== i).map(t => t.shot.grade), rng);
      return r ? ts.map((t, j) => (j === i ? { shot: r[0], at: r[1], n: t.n + 1 } : t)) : ts;
    });
  }, [pools, rng]);
  const nexts = useMemo(() => tiles.map((_, i) => () => advance(i)), [tiles.length, advance]); // eslint-disable-line react-hooks/exhaustive-deps
  return <>{tiles.map((t, i) => <HeroTile key={i} shot={t.shot} n={t.n} big={i === 0} start={i * STAGGER} next={nexts[i]!} />)}</>;
}

/** The first screen on a new device: what Bento is, the real thing working, and one idea climbing from K to 12th. */
/** preview and dev builds carry the design sandbox; on the landing page its way in is the footer */
const SANDBOX = import.meta.env.MODE === "preview" || import.meta.env.MODE === "development";

export function Welcome() {
  const { deps, go, progress, openSheet } = useApp();
  const rng = useMemo(() => deps().rng, []); // eslint-disable-line react-hooks/exhaustive-deps
  // Start learning is the one way in: grades are chosen in the app, in picker D, with nothing picked (G 2026-10-06)
  const start = () => { go({ name: "home" }, "fwd"); if (progress.grade != null) openSheet(true); };
  // arriving by a page change, only the hero is drawn with the page; the sections below it follow once the page has
  // come forward, so the change never waits on the whole landing (Review page-switch report, fix C)
  // one section at a time, a frame apart, so no single frame holds the screen
  const [rest, setRest] = useState(() => typeof document === "undefined" || !document.documentElement.hasAttribute("data-paged") ? 3 : 0);
  useEffect(() => { if (rest >= 3) return; const t = setTimeout(() => setRest(n => n + 1), rest ? 50 : 550); return () => clearTimeout(t); }, [rest]);
  return (
    <div className="land">
      <section className="lhero">
        <h1>Math that <span>clicks.</span></h1>
        <p>Watch each idea play out, then solve it one step at a time. If you slip, Bento shows you the exact step and why.</p>
        <div className="lcta"><Pill go onClick={start}>{START_LEARNING}</Pill><span>Start free. No account.</span></div>
      </section>
      <section className="lhbox">
        <HeroPictures rng={rng} />
      </section>
      {rest > 0 && <OneIdea rng={rng} />}
      {rest > 1 && <>
        <section className="lsec"><h2>Everything in one box.</h2><p>Lessons, plus everything that helps them stick.</p></section>
        <FeatureBox rng={rng} />
      </>}
      {rest > 2 && <Advanced />}
      <footer className="lfoot">Bento · Kindergarten to 12th grade{SANDBOX && <> · <button className="tlink" onClick={() => dispatchEvent(new Event("bento:sandbox"))}>Sandbox</button></>}</footer>
    </div>
  );
}
