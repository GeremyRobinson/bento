// Pieces the AI track's pictures share: a plot frame in picture coordinates, small button rows, the 8 × 8 drawing pad,
// and a trainer that runs the digit reader a pass at a time, so its curves draw while it learns.
import { useEffect, useRef, useState, type ReactNode } from "react";
import { useSvgDrag } from "../../../ui/kit";
import {
  digitData, evaluate, hasReader, keepReader, newReader, normalize, PAD_PEN, planKey, rasterize, trainRun, type Reader, type TrainPlan,
} from "../digits";

/** a linear map from data to picture coordinates */
export const lin = (d0: number, d1: number, p0: number, p1: number) => (v: number) => p0 + ((v - d0) / (d1 - d0)) * (p1 - p0);

export function Btns({ children }: { children: ReactNode }) {
  return <span className="aibtns">{children}</span>;
}
export function Btn({ on, onClick, children, label, disabled }: { on?: boolean; onClick: () => void; children: ReactNode; label?: string; disabled?: boolean }) {
  return <button type="button" className={`ctl${on ? " go" : ""}`} aria-label={label} disabled={disabled} onClick={onClick}>{children}</button>;
}

/** A pass of a run: training and held-out error and loss, for the curves. */
export interface Pass { epoch: number; trainErr: number; testErr: number; testBits: number }

/**
 * Trains the reader for `plan`, one pass per frame, and reports each pass. A finished run is kept, so asking again
 * for the same plan (another picture, or the same one reopened) gives the same reader at once.
 */
export function useTrainer(plan: TrainPlan | null, opts: { every?: number; testLimit?: number } = {}) {
  const [passes, setPasses] = useState<Pass[]>([]);
  const [net, setNet] = useState<Reader | null>(null);
  const [busy, setBusy] = useState(false);
  const key = plan ? planKey(plan) : "";
  const every = opts.every ?? 1, limit = opts.testLimit ?? 600;
  const done = useRef(new Map<string, { net: Reader; passes: Pass[] }>());
  useEffect(() => {
    if (!plan) { setNet(null); setPasses([]); return; }
    const kept = done.current.get(key) ?? memo.get(key);
    if (kept) { setNet(kept.net); setPasses(kept.passes); setBusy(false); return; }
    let stop = false;
    const data = digitData();
    const run = trainRun(plan, data);
    const out: Pass[] = [];
    setPasses([]); setNet(newReader(plan.h, plan.seed)); setBusy(true);
    const tick = () => {
      if (stop) return;
      const t0 = performance.now();
      let last: Reader | null = null, finished = false;
      // as many passes as fit in a frame's worth of time
      while (performance.now() - t0 < 24) {
        const s = run.next();
        if (s.done) { finished = true; break; }
        last = s.value.net;
        if (s.value.epoch % every === 0 || s.value.epoch === plan.epochs) {
          const te = evaluate(last, data.test, limit), tr = evaluate(last, data.train, Math.min(plan.n, 600));
          out.push({ epoch: s.value.epoch, trainErr: tr.error, testErr: te.error, testBits: te.bits });
          break;
        }
      }
      if (last) { setNet(last); setPasses([...out]); }
      if (finished || out.at(-1)?.epoch === plan.epochs) {
        const fin = last ?? null;
        if (fin) { keepReader(plan, fin); memo.set(key, { net: fin, passes: [...out] }); done.current.set(key, { net: fin, passes: [...out] }); }
        setBusy(false);
        return;
      }
      setTimeout(tick, 0);
    };
    const t = setTimeout(tick, 30);
    return () => { stop = true; clearTimeout(t); };
  }, [key]); // eslint-disable-line react-hooks/exhaustive-deps
  return { passes, net, busy, ready: !!plan && (hasReader(plan) || !busy) };
}
const memo = new Map<string, { net: Reader; passes: Pass[] }>();

type Stroke = [number, number][];

/**
 * The 8 × 8 drawing pad: finger strokes, fitted to the box and shrunk to 64 counts exactly as the bundled digits were.
 * Shows the counts as gray cells under the strokes. `x`, `y`, `size` place it in the parent SVG.
 */
export function Pad({ x, y, size, strokes, setStrokes, counts, drag, label }: {
  x: number; y: number; size: number; strokes: Stroke[]; setStrokes: (s: Stroke[]) => void; counts: Float64Array;
  drag: ReturnType<typeof useSvgDrag>["drag"]; label?: string;
}) {
  const live = useRef<Stroke[]>(strokes);
  live.current = strokes;
  const drawing = useRef(false);
  const cell = size / 8;
  const h = drag((px, py) => {
    const u = Math.min(1, Math.max(0, (px - x) / size)), v = Math.min(1, Math.max(0, (py - y) / size));
    const s = live.current, lastS = s[s.length - 1];
    if (!lastS || !drawing.current) { drawing.current = true; const next = [...s, [[u, v]] as Stroke]; live.current = next; setStrokes(next); return; }
    const p = lastS[lastS.length - 1]!;
    if (Math.hypot(p[0] - u, p[1] - v) < 0.015) return;
    const next = [...s.slice(0, -1), [...lastS, [u, v]] as Stroke];
    live.current = next;
    setStrokes(next);
  });
  return (
    <g aria-label={label ?? "Drawing pad"}>
      <rect x={x} y={y} width={size} height={size} rx="6" className="aipad" />
      {Array.from(counts, (c, i) => c > 0 && <rect key={i} x={x + (i % 8) * cell} y={y + Math.floor(i / 8) * cell} width={cell} height={cell} fill="var(--text)" fillOpacity={c * 0.85} />)}
      {strokes.map((st, i) => <polyline key={i} className="aiink" points={st.map(([u, v]) => `${x + u * size},${y + v * size}`).join(" ")} />)}
      <rect x={x} y={y} width={size} height={size} fill="transparent" style={{ touchAction: "none", cursor: "crosshair" }}
        onPointerDown={e => { drawing.current = false; h.onPointerDown(e); }} onPointerMove={h.onPointerMove}
        onPointerUp={() => { drawing.current = false; }} onPointerCancel={() => { drawing.current = false; }} />
    </g>
  );
}

/** what the pad's strokes look like to the reader: 64 numbers from 0 to 1 */
export const padCounts = (strokes: Stroke[]) => {
  if (!strokes.length) return new Float64Array(64);
  return Float64Array.from(rasterize(normalize(strokes), PAD_PEN), c => c / 16);
};

/** a digit from the bundled set, as pad cells (for when you'd rather not draw) */
export const sampleDigit = (k: number) => { const d = digitData().test; return { x: d.x[k % d.x.length]!, y: d.y[k % d.y.length]! }; };
