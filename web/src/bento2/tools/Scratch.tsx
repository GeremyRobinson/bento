// Scratch paper: write with a finger or a pencil. Shape tidy-up and handwriting-to-math are the next pieces; the
// strokes are kept as points (in the tool's saved state) so a recognizer can read them later.
import { useEffect, useRef } from "react";
import { useB2 } from "../ui/useB2";

type Stroke = [number, number][];

export function Scratch() {
  const { tool, setToolState } = useB2();
  const strokes = tool<Stroke[]>("scratch", []);
  const canvas = useRef<HTMLCanvasElement>(null);
  const cur = useRef<Stroke | null>(null);
  const live = useRef<Stroke[]>(strokes);
  live.current = strokes;
  const draw = () => {
    const c = canvas.current, ctx = c?.getContext?.("2d");
    if (!c || !ctx) return;
    const ink = getComputedStyle(c).color;
    ctx.clearRect(0, 0, c.width, c.height);
    ctx.lineWidth = 2.4; ctx.lineCap = "round"; ctx.lineJoin = "round"; ctx.strokeStyle = ink;
    for (const s of [...live.current, ...(cur.current ? [cur.current] : [])]) {
      ctx.beginPath();
      s.forEach(([x, y], i) => (i ? ctx.lineTo(x * c.width, y * c.height) : ctx.moveTo(x * c.width, y * c.height)));
      ctx.stroke();
    }
  };
  useEffect(draw);
  const at = (e: React.PointerEvent<HTMLCanvasElement>): [number, number] => { const r = e.currentTarget.getBoundingClientRect(); return [(e.clientX - r.left) / r.width, (e.clientY - r.top) / r.height]; };
  return (
    <div className="b2scratch">
      <canvas ref={canvas} width={680} height={460} aria-label="Scratch paper: draw here" role="img"
        onPointerDown={e => { e.currentTarget.setPointerCapture?.(e.pointerId); cur.current = [at(e)]; }}
        onPointerMove={e => { if (cur.current) { cur.current.push(at(e)); draw(); } }}
        onPointerUp={() => { if (cur.current && cur.current.length > 1) setToolState("scratch", [...live.current, cur.current].slice(-200)); cur.current = null; }} />
      <div className="b2ops">
        <button type="button" className="ctl" disabled={!strokes.length} onClick={() => setToolState("scratch", strokes.slice(0, -1))}>Undo</button>
        <button type="button" className="ctl" disabled={!strokes.length} onClick={() => setToolState("scratch", [])}>Clear</button>
        <small>Shape tidy-up and handwriting to math come later.</small>
      </div>
    </div>
  );
}
