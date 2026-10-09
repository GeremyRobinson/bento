import { useEffect, useRef, useState } from "react";
import { Pill } from "../primitives/Pill";

/** One line of ink: points as x, y, pressure triples in the pad's own pixels, and whether it rubs out. */
export type Stroke = { erase: boolean; pts: number[] };

const PEN = 3, RUB = 26;
const PenIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M4 20l1-4.5L15.5 5a2.1 2.1 0 0 1 3 3L8 18.5z" /><path d="M13.5 7l3 3" /></svg>
);
const EraserIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M9 20h11M5.5 15.5l9-9a2 2 0 0 1 2.8 0l1.7 1.7a2 2 0 0 1 0 2.8L11 19H8.5z" /><path d="M10 11l4.5 4.5" /></svg>
);
const UndoIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M9 7L5 11l4 4" /><path d="M5 11h9a5 5 0 0 1 0 10h-2" /></svg>
);
const ClearIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M5 7h14M10 7V5h4v2M7 7l1 12h8l1-12" /></svg>
);

function paint(g: CanvasRenderingContext2D, st: Stroke, ink: string) {
  const p = st.pts;
  g.globalCompositeOperation = st.erase ? "destination-out" : "source-over";
  g.strokeStyle = ink; g.fillStyle = ink; g.lineCap = "round"; g.lineJoin = "round";
  if (p.length === 3) { g.beginPath(); g.arc(p[0]!, p[1]!, (st.erase ? RUB : PEN * (0.6 + p[2]!)) / 2, 0, Math.PI * 2); g.fill(); return; }
  for (let i = 3; i < p.length; i += 3) {
    g.lineWidth = st.erase ? RUB : PEN * (0.6 + p[i + 2]!);
    g.beginPath(); g.moveTo(p[i - 3]!, p[i - 2]!); g.lineTo(p[i]!, p[i + 1]!); g.stroke();
  }
}

/**
 * Scratch Pad (master): a blank glass panel to write the work out on, like scrap paper (G 2026-10-09, "Show your work").
 * A finger, an Apple Pencil or a mouse writes; once a Pencil has touched it, a resting hand no longer draws. A pen, an
 * eraser, an undo and a clear sit along its foot. It's only ink: nothing reads or checks it. The ink belongs to whoever
 * shows the pad (`ink` / `setInk`), so a screen decides when it's wiped (practice: at the next problem).
 */
export function ScratchPad({ ink, setInk, className }: { ink: Stroke[]; setInk: (f: (s: Stroke[]) => Stroke[]) => void; className?: string }) {
  const cv = useRef<HTMLCanvasElement>(null);
  const [erase, setErase] = useState(false);
  const live = useRef<Stroke | null>(null), pen = useRef(false), inkRef = useRef(ink);
  inkRef.current = ink;

  const redraw = () => {
    const c = cv.current, g = c?.getContext("2d");
    if (!c || !g) return;
    const k = devicePixelRatio || 1;
    g.setTransform(1, 0, 0, 1, 0, 0); g.clearRect(0, 0, c.width, c.height); g.setTransform(k, 0, 0, k, 0, 0);
    const colour = getComputedStyle(c).color;
    for (const st of inkRef.current) paint(g, st, colour);
    if (live.current) paint(g, live.current, colour);
  };

  // the canvas matches the panel's size in device pixels, and redraws whenever the panel resizes or turns
  useEffect(() => {
    const c = cv.current;
    if (!c) return;
    const fit = () => { const k = devicePixelRatio || 1, r = c.getBoundingClientRect(); c.width = Math.round(r.width * k); c.height = Math.round(r.height * k); redraw(); };
    fit();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(fit); ro.observe(c);
    return () => ro.disconnect();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(redraw, [ink]); // eslint-disable-line react-hooks/exhaustive-deps

  const at = (e: React.PointerEvent) => {
    const r = cv.current!.getBoundingClientRect();
    return [e.clientX - r.left, e.clientY - r.top, e.pointerType === "pen" ? e.pressure : 0.5];
  };
  const down = (e: React.PointerEvent) => {
    if (e.pointerType === "pen") pen.current = true;
    else if (e.pointerType === "touch" && pen.current) return;
    if (e.button > 0) return;
    e.currentTarget.setPointerCapture(e.pointerId);
    live.current = { erase, pts: at(e) };
    redraw();
  };
  const move = (e: React.PointerEvent) => {
    const st = live.current;
    if (!st) return;
    const evs = e.nativeEvent.getCoalescedEvents?.() ?? [e.nativeEvent];
    for (const ev of evs) st.pts.push(...at(ev as unknown as React.PointerEvent));
    redraw();
  };
  const up = () => {
    const st = live.current;
    if (!st) return;
    live.current = null;
    setInk(s => [...s, st]);
  };

  return (
    <div className={["scratch", className].filter(Boolean).join(" ")}>
      <canvas ref={cv} className="scratch-ink" aria-label="Scratch pad: write your work here" role="img"
        onPointerDown={down} onPointerMove={move} onPointerUp={up} onPointerCancel={up} />
      {!ink.length && <span className="scratch-note" aria-hidden>Write your work here</span>}
      <div className="scratch-tools" role="toolbar" aria-label="Scratch pad tools">
        <Pill circ aria-label="Pen" aria-pressed={!erase} onClick={() => setErase(false)}><PenIcon /></Pill>
        <Pill circ aria-label="Eraser" aria-pressed={erase} onClick={() => setErase(true)}><EraserIcon /></Pill>
        <Pill circ aria-label="Undo" disabled={!ink.length} onClick={() => setInk(s => s.slice(0, -1))}><UndoIcon /></Pill>
        <Pill circ aria-label="Clear" disabled={!ink.length} onClick={() => setInk(() => [])}><ClearIcon /></Pill>
      </div>
    </div>
  );
}
