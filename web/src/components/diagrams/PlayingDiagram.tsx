import { useEffect, useRef, useState } from "react";
import { reduceMotion } from "../../app/transition";
import type { Explanation } from "../../explanations/schema";
import { Diagram } from "./Diagram";

const BEAT_MS = 750;

/**
 * An explanation's picture that plays through its whole timeline by itself: when it scrolls into view,
 * and again each time `replay` changes. Without motion (or without IntersectionObserver) it shows the finished picture.
 * With `autoplay` off it rests on the finished picture and plays only when `replay` changes (a tap).
 * With `hold` set it opens on the finished picture and starts playing that many ms after it comes into view.
 * With `end` set it stops at that beat instead of the last one.
 */
export function PlayingDiagram({ ex, replay = 0, autoplay = true, hold, end }: { ex: Explanation & { diagram: NonNullable<Explanation["diagram"]> }; replay?: number; autoplay?: boolean; hold?: number; end?: number }) {
  const last = Math.min(end ?? Infinity, ex.timeline.length - 1);
  const still = reduceMotion() || typeof IntersectionObserver === "undefined";
  const [at, setAt] = useState(still || !autoplay || hold != null ? last : 0);
  const [playing, setPlaying] = useState(false);
  // every restart draws a fresh picture from its first beat: going back to beat 0 on the same picture would run every
  // transition in reverse (the finished picture un-building itself), which reads as a glitch before each play
  const [gen, setGen] = useState(0);
  const restart = () => { setGen(g => g + 1); setAt(0); setPlaying(true); };
  const box = useRef<HTMLDivElement>(null);

  // start when at least a third of it is on screen
  useEffect(() => {
    if (still || !autoplay || !box.current) return;
    const io = new IntersectionObserver(es => {
      if (!es.some(e => e.isIntersecting)) return;
      io.disconnect();
      if (hold == null) setPlaying(true);
      else t = setTimeout(restart, hold);
    }, { threshold: 0.35 });
    let t: ReturnType<typeof setTimeout> | undefined;
    io.observe(box.current);
    return () => { io.disconnect(); clearTimeout(t); };
  }, [still, autoplay, hold]);

  // a tap replays from the start
  const first = useRef(true);
  useEffect(() => {
    if (first.current) { first.current = false; return; }
    if (still) return;
    restart();
  }, [replay, still]);

  useEffect(() => {
    if (!playing) return;
    if (at >= last) { setPlaying(false); return; }
    const t = setTimeout(() => setAt(a => Math.min(last, a + 1)), Math.max(at === 0 ? 450 : BEAT_MS, settleMs(ex.diagram, at)));
    return () => clearTimeout(t);
  }, [playing, at, last, ex.diagram]);

  return <div className="viz" ref={box}><Diagram key={gen} diagram={ex.diagram} timeline={ex.timeline} at={at} /></div>;
}

/** seconds each entrance runs (the picture animation vocabulary in components.css) */
const ENTER_S: Record<string, number> = { draw: 0.9, sweep: 1.2, grow: 1.2, growx: 0.7, growy: 0.9, level: 1, slide: 1, move: 1, swing: 0.9 };
/**
 * How long a beat must stay so the shapes that leave after it finish coming in and can be read: moving on sooner
 * cuts a callout off halfway (it half draws, then blinks out), which reads as a glitch (G 2026-10-08).
 */
function settleMs(d: Explanation["diagram"], at: number): number {
  if (!d || d.kind !== "scene") return 0;
  let end = 0;
  for (const it of d.items) {
    if (it.until !== at || !it.enter) continue;
    const word = it.enter.split(" ")[0]!;
    end = Math.max(end, (it.delay ?? 0) + (word === "draw" && it.enter.includes("slow") ? 1.6 : ENTER_S[word] ?? 0.5));
  }
  return end ? Math.round(end * 1000) + 700 : 0;
}
