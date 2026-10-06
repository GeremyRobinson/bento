// Grapher 2D: type y = …, drag a slider for any letter, see where the first two curves cross, trace a point.
import { useMemo, useState } from "react";
import { CONSTANT_VALUES } from "../constants";
import { shelfNumbers } from "../progress";
import { useB2 } from "../ui/useB2";
import { fx, path, Slider, useSvgDrag } from "../ui/kit";
import { evaluate, namesIn, parse, showValue, type Node } from "./expr";

interface GraphState { exprs: string[]; vars: Record<string, number>; view: [number, number, number, number] }
const W = 360, H = 240;
const CLS = ["sky", "pink", "mint"];
const strip = (s: string) => s.replace(/^\s*y\s*=\s*/, "");

/** where two curves cross on [a, b]: sign changes of f − g, sharpened by bisection */
export function crossings(f: (x: number) => number, g: (x: number) => number, a: number, b: number, n = 400): number[] {
  const out: number[] = [];
  const d = (x: number) => f(x) - g(x);
  let x0 = a, d0 = d(a);
  for (let i = 1; i <= n; i++) {
    const x1 = a + ((b - a) * i) / n, d1 = d(x1);
    if (Number.isFinite(d0) && Number.isFinite(d1) && (d0 === 0 || d0 * d1 < 0) && Math.abs(d1 - d0) < 1e3) {
      let lo = x0, hi = x1;
      for (let k = 0; k < 50; k++) { const m = (lo + hi) / 2; if (d(lo) * d(m) <= 0) hi = m; else lo = m; }
      out.push((lo + hi) / 2);
    }
    x0 = x1; d0 = d1;
  }
  return out.filter((x, i) => i === 0 || Math.abs(x - out[i - 1]!) > 1e-6);
}

export function Grapher2D() {
  const { b2, tool, setToolState } = useB2();
  const st = tool<GraphState>("graph2d", { exprs: ["sin(x)", "a x + 1", ""], vars: { a: 0.5 }, view: [-6, 6, -4, 4] });
  const [trace, setTrace] = useState<number | null>(null);
  const set = (p: Partial<GraphState>) => setToolState("graph2d", { ...st, ...p });
  const known = useMemo(() => ({ ...CONSTANT_VALUES, ...shelfNumbers(b2) }), [b2]);
  const parsed = st.exprs.map(e => { if (!strip(e).trim()) return null; try { return { tree: parse(strip(e)) as Node, err: null }; } catch (er) { return { tree: null, err: (er as Error).message }; } });
  const free = [...new Set(parsed.flatMap(p => (p?.tree ? namesIn(p.tree) : [])).filter(n => n !== "x" && !(n in known)))];
  const fns = parsed.map(p => (p?.tree ? (x: number) => { try { return evaluate(p.tree!, { vars: { ...known, ...st.vars, x } }); } catch { return NaN; } } : null));
  const [x0, x1, y0, y1] = st.view;
  const X = (x: number) => ((x - x0) / (x1 - x0)) * W, Y = (y: number) => H - ((y - y0) / (y1 - y0)) * H;
  const curves = fns.map(f => {
    if (!f) return "";
    const segs: string[] = [];
    let cur: [number, number][] = [];
    for (let i = 0; i <= 300; i++) {
      const x = x0 + ((x1 - x0) * i) / 300, y = f(x);
      if (Number.isFinite(y) && Math.abs(y) < 1e6) cur.push([X(x), Math.max(-50, Math.min(H + 50, Y(y)))]);
      else { if (cur.length > 1) segs.push(path(cur)); cur = []; }
    }
    if (cur.length > 1) segs.push(path(cur));
    return segs.join(" ");
  });
  const cross = fns[0] && fns[1] ? crossings(fns[0], fns[1], x0, x1) : [];
  const { ref, drag } = useSvgDrag();
  const zoom = (k: number) => { const cx = (x0 + x1) / 2, cy = (y0 + y1) / 2; set({ view: [cx - ((x1 - x0) / 2) * k, cx + ((x1 - x0) / 2) * k, cy - ((y1 - y0) / 2) * k, cy + ((y1 - y0) / 2) * k] }); };
  const step = (a: number, b: number) => { const r = (b - a) / 8, p = 10 ** Math.floor(Math.log10(r)); return [1, 2, 5, 10].map(k => k * p).find(k => k >= r)!; };
  const gx = step(x0, x1), gy = step(y0, y1);
  return (
    <div className="b2graph">
      {st.exprs.map((e, i) => (
        <label key={i} className={`b2fx tone-${CLS[i]}`}>
          <span>y{i + 1} =</span>
          <input value={strip(e)} onChange={ev => { const exprs = [...st.exprs]; exprs[i] = ev.currentTarget.value; set({ exprs }); }} aria-label={`Curve ${i + 1}: y =`} spellCheck={false} autoComplete="off" />
          {parsed[i]?.err && <small className="err">{parsed[i]!.err}</small>}
        </label>
      ))}
      <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic g2" role="img" aria-label={`Graph of ${st.exprs.filter(Boolean).map(strip).join(" and ")}`}>
        {Array.from({ length: Math.floor((x1 - x0) / gx) + 2 }, (_, i) => Math.ceil(x0 / gx) * gx + i * gx).map(x => <line key={`x${x}`} x1={X(x)} y1="0" x2={X(x)} y2={H} className={Math.abs(x) < 1e-9 ? "b2axis" : "b2grid"} />)}
        {Array.from({ length: Math.floor((y1 - y0) / gy) + 2 }, (_, i) => Math.ceil(y0 / gy) * gy + i * gy).map(y => <line key={`y${y}`} x1="0" y1={Y(y)} x2={W} y2={Y(y)} className={Math.abs(y) < 1e-9 ? "b2axis" : "b2grid"} />)}
        {curves.map((d, i) => d && <path key={i} d={d} className={`b2curve ${CLS[i]}`} />)}
        {cross.map(x => <circle key={x} cx={X(x)} cy={Y(fns[0]!(x))} r="5" className="b2dot amber" />)}
        {trace != null && <>
          <line x1={X(trace)} y1="0" x2={X(trace)} y2={H} className="b2mark" />
          {fns.map((f, i) => f && Number.isFinite(f(trace)) && <circle key={i} cx={X(trace)} cy={Y(f(trace))} r="4.5" className={`b2dot ${CLS[i]}`} />)}
        </>}
        <rect x="0" y="0" width={W} height={H} className="b2hit" {...drag(px => setTrace(x0 + (px / W) * (x1 - x0)))} />
        <text x={W - 6} y={Math.min(H - 6, Math.max(14, Y(0) - 6))} textAnchor="end" className="b2t">x</text>
      </svg>
      <div className="b2read">
        {trace != null && <span className="b2r"><small>x</small><b>{fx(trace, 3)}</b></span>}
        {trace != null && fns.map((f, i) => f && <span key={i} className="b2r"><small>y{i + 1}</small><b className={`tone-${CLS[i]}`}>{Number.isFinite(f(trace)) ? showValue(f(trace), 5) : "none"}</b></span>)}
        {cross.length > 0 && <span className="b2r"><small>y1 and y2 cross at x =</small><b className="tone-amber">{cross.slice(0, 4).map(x => showValue(x, 5)).join(", ")}</b></span>}
        <span className="b2zoom"><button type="button" className="ctl" onClick={() => zoom(0.5)} aria-label="Zoom in">+</button><button type="button" className="ctl" onClick={() => zoom(2)} aria-label="Zoom out">−</button><button type="button" className="ctl" onClick={() => set({ view: [-6, 6, -4, 4] })}>Reset</button></span>
      </div>
      {free.map(n => (
        <Slider key={n} label={n} value={st.vars[n] ?? 1} min={-10} max={10} step={0.1} onChange={v => set({ vars: { ...st.vars, [n]: v } })} format={v => fx(v, 1)} />
      ))}
    </div>
  );
}
