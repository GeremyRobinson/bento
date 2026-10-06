import { useEffect, useMemo, useState, type CSSProperties } from "react";
import { gradeOf, tintStyle } from "../curriculum/grades";
import { lessonById } from "../curriculum/registry";
import type { Rng } from "../curriculum/generators/rng";
import { PlayingDiagram } from "./diagrams/PlayingDiagram";
import { reduceMotion } from "../app/transition";
import { GradeNum } from "./Shelf";
import { showcasePicture } from "../screens/Welcome";

type Pic = NonNullable<ReturnType<typeof showcasePicture>>;

/** How long one picture takes to play, plus a beat to look at the finished picture before the next one starts. */
const playMs = (ex: Pic) => 450 + ex.timeline.length * 750 + 1400;

/** One card at a time plays; the rest rest on their finished pictures. Returns which card is playing and its play count. */
function useTurns(cards: { ex: Pic }[]) {
  const [turn, setTurn] = useState({ i: -1, n: 0 });
  useEffect(() => {
    if (!cards.length || reduceMotion()) return;
    let k = -1, t: ReturnType<typeof setTimeout>;
    const seq = cards.map((_, i) => i);
    const step = () => {
      k = (k + 1) % seq.length;
      const i = seq[k]!;
      setTurn(s => ({ i, n: s.n + 1 }));
      t = setTimeout(step, playMs(cards[i]!.ex));
    };
    t = setTimeout(step, 900);
    return () => clearTimeout(t);
  }, [cards]);
  return turn;
}

/** The first lesson in the list whose picture draws. */
function firstPic(ids: string[], rng: Rng) {
  for (const id of ids) {
    const ex = showcasePicture(id, rng), l = lessonById(id);
    if (ex && l) return { ex, grade: l.grade };
  }
  return null;
}

/** One idea, K to 12th: the same idea (area) climbing from counting dots to calculus, one picture at a time (G approved, 2026-10-06). */
const CLIMB: [string[], string, string][] = [
  [["k-make10", "k-tens", "k-count20", "k-add"], "Count it", "Dots fill a ten-frame."],
  [["g3-facts", "g3-split", "g3-area"], "Rows of it", "Multiplying is counting rows."],
  [["g5-mult2", "g4-mult2x2", "g4-partial", "g5-volume"], "Split it", "Big numbers become boxes."],
  [["g8-pyth", "g8-leg"], "Square it", "Squares on the sides add up."],
  [["g12-defint", "g12-anti", "g12-limit"], "Fill it", "Thin boxes fill a curve."],
];

export function OneIdea({ rng }: { rng: Rng }) {
  const cards = useMemo(() => CLIMB.flatMap(([ids, title, note]) => {
    const p = firstPic(ids, rng);
    return p ? [{ ...p, title, note }] : [];
  }), [rng]);
  const turn = useTurns(cards);
  const at = Math.max(0, turn.i), c = cards[at];
  // the picture that was showing stays (same element, on its finished frame) and fades out over the new one as that
  // starts to draw, so the card is never blank between grades (v44 sweep #18)
  // worked out during render, so the old layer never leaves the DOM between the two pictures
  const [leaving, setLeaving] = useState<{ at: number; n: number } | null>(null);
  const [was, setWas] = useState({ at, n: turn.n });
  if (was.n !== turn.n) {
    setWas({ at, n: turn.n });
    setLeaving(reduceMotion() ? null : was);
  }
  const layers = [...(leaving && leaving.n !== turn.n ? [{ ...leaving, out: true }] : []), { at, n: turn.n, out: false }];
  if (!c) return null;
  // one calm stage: the list of five steps on the left, the one picture playing on the right
  return (
    <>
      <section className="lsec"><h2>One idea, K to 12th.</h2><p>Bento teaches math as one story. The square you count in kindergarten is the same square calculus fills in.</p></section>
      <div className="lone">
        <ol className="lonelist">
          {cards.map((k, i) => (
            <li key={i} className={i === at ? "on" : ""} style={tintStyle(gradeOf(k.grade)) as CSSProperties}>
              <GradeNum grade={k.grade} /><span><b>{k.title}</b><small>{k.note}</small></span>
            </li>
          ))}
        </ol>
        <figure className="lonepic gpal" data-grade={c.grade} style={tintStyle(gradeOf(c.grade)) as CSSProperties}>
          <div className="lstage">
            {layers.map(l => {
              const k = cards[l.at];
              return k && (
                <div key={l.n} className={`lsd gpal${l.out ? " out" : ""}`} data-grade={k.grade} style={tintStyle(gradeOf(k.grade)) as CSSProperties}
                  aria-hidden={l.out || undefined} onAnimationEnd={e => { if (l.out && e.target === e.currentTarget) setLeaving(null); }}>
                  <PlayingDiagram ex={k.ex} />
                </div>
              );
            })}
          </div>
          <figcaption key={`c${turn.n}`}><GradeNum grade={c.grade} /><span><b>{c.title}</b><small>{c.note}</small></span></figcaption>
        </figure>
      </div>
    </>
  );
}
