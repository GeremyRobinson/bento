// The Error bowl (multivariable.md, tool 11): a scatter plot whose points you drag, a line y = mx + b with two handles,
// and beside it the total squared error E(m, b) as a contour bowl over the (m, b) plane with your line as a ball on it
// (17). "Roll" lets the ball run downhill to the bowl's bottom, which is the best line. With `fn: "land"` the points are
// Two lakes' heights at 4 spots along the road y = 1/2.
import { useEffect, useMemo, useRef, useState } from "react";
import { flag, str, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, useSvgDrag } from "../../../ui/kit";
import { LAND, type Box, type F2 } from "../maths";
import { FlatMap, mapper, nice } from "./common";

const W = 360, H = 250;
const r1 = (v: number) => Math.round(v * 10) / 10;

function bestLine(xs: number[], ys: number[]) {
  const n = xs.length, Sx = xs.reduce((a, b) => a + b, 0), Sy = ys.reduce((a, b) => a + b, 0);
  const Sxx = xs.reduce((a, x) => a + x * x, 0), Sxy = xs.reduce((a, x, i) => a + x * ys[i]!, 0);
  const m = (n * Sxy - Sx * Sy) / (n * Sxx - Sx * Sx);
  return { m, b: (Sy - m * Sx) / n, n, Sx, Sxx };
}

export function BowlScene({ props, marker, onMarker }: SceneProps) {
  const land = str<string>(props, "fn", "") === "land", quiet = flag(props, "quiet");
  const start = useMemo(() => {
    if (land) { const xs = [-1.5, -0.5, 0.5, 1.5]; return { xs, ys: xs.map(x => LAND(x, 0.5)) }; }
    const pts = str<string>(props, "pts", "-1,1;0,2;1,6").split(";").map(s => s.split(",").map(Number) as [number, number]);
    return { xs: pts.map(p => p[0]), ys: pts.map(p => p[1]) };
  }, [land, props]);
  const xs = start.xs;
  const [ys, setYs] = useState(start.ys);
  const fit = bestLine(xs, ys);
  // the picture's frames are fixed by the first data, so a point guess keeps its coordinates
  const frame = useMemo(() => {
    const f0 = bestLine(start.xs, start.ys), lo = Math.min(0, ...start.ys), hi = Math.max(...start.ys);
    const pad = Math.max(1, (hi - lo) * 0.25), span = land ? 1 : Math.max(4, (hi - lo) * 0.9);
    return {
      x0: Math.min(...start.xs) - 0.6, x1: Math.max(...start.xs) + 0.6, y0: lo - pad, y1: hi + pad,
      bowl: [r1(f0.m) - span, r1(f0.m) + span, r1(f0.b) - span, r1(f0.b) + span] as Box,
    };
  }, [start, land]);
  const [own, setOwn] = useState<[number, number]>(land ? [0, 1] : [0, r1((frame.y0 + frame.y1) / 2)]);
  const guessing = !!onMarker;
  const [m, b] = marker ?? own;
  const setMB = (p: [number, number]) => (onMarker ? onMarker(p) : setOwn(p));
  const E: F2 = useMemo(() => (mm, bb) => xs.reduce((a, x, i) => a + (ys[i]! - mm * x - bb) ** 2, 0), [xs, ys]);
  const eNow = E(m, b), eBest = E(fit.m, fit.b);

  // the ball rolls downhill on E: a gradient step sized by the bowl's steepest curvature
  const [rolling, setRolling] = useState(false);
  const cur = useRef<[number, number]>([m, b]);
  cur.current = [m, b];
  useEffect(() => {
    if (!rolling) return;
    const lmax = fit.Sxx + fit.n + Math.hypot(fit.Sxx - fit.n, 2 * fit.Sx); // 2 × E's Hessian's larger eigenvalue / 2
    const eta = 0.45 / lmax;
    let raf = 0;
    const tick = () => {
      const [mm, bb] = cur.current;
      const gm = xs.reduce((a, x, i) => a - 2 * x * (ys[i]! - mm * x - bb), 0), gb = xs.reduce((a, x, i) => a - 2 * (ys[i]! - mm * x - bb), 0);
      const next: [number, number] = [mm - eta * gm, bb - eta * gb];
      if (Math.hypot(next[0] - fit.m, next[1] - fit.b) < 0.005) { setOwn([fit.m, fit.b]); setRolling(false); return; }
      setOwn(next);
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [rolling, xs, ys, fit.m, fit.b, fit.Sxx, fit.n, fit.Sx]);

  const showBowl = !quiet;
  const sc: [number, number, number, number] = showBowl ? [22, 26, 164, 192] : [40, 26, 300, 192];
  const SX = (x: number) => sc[0] + ((x - frame.x0) / (frame.x1 - frame.x0)) * sc[2];
  const SY = (y: number) => sc[1] + sc[3] - ((y - frame.y0) / (frame.y1 - frame.y0)) * sc[3];
  const iy = (py: number) => frame.y0 + ((sc[1] + sc[3] - py) / sc[3]) * (frame.y1 - frame.y0);
  const bm = mapper(frame.bowl, [206, 26, 148, 192]);
  const levels = useMemo(() => Array.from({ length: 11 }, (_, i) => eBest + (i + 1) ** 2 * (land ? 0.02 : 0.6)), [eBest, land]);
  const { ref, drag } = useSvgDrag();
  const hx = [xs[0]!, xs[xs.length - 1]!];
  const clampY = (y: number) => Math.max(frame.y0, Math.min(frame.y1, y));
  const moveHandle = (k: 0 | 1, py: number) => {
    const yNew = clampY(iy(py)), other = m * hx[1 - k]! + b;
    const [xa, ya, xb, yb] = k === 0 ? [hx[0]!, yNew, hx[1]!, other] : [hx[0]!, other, hx[1]!, yNew];
    const mm = (yb - ya) / (xb - xa);
    setRolling(false);
    setMB([r1(mm), r1(ya - mm * xa)]);
  };
  const lineAt = (mm: number, bb: number) => ({ x1: SX(frame.x0), y1: SY(mm * frame.x0 + bb), x2: SX(frame.x1), y2: SY(mm * frame.x1 + bb) });
  const inBowl = (p: [number, number]): [number, number] => [Math.max(frame.bowl[0], Math.min(frame.bowl[1], p[0])), Math.max(frame.bowl[2], Math.min(frame.bowl[3], p[1]))];
  const ball = inBowl([m, b]);
  const range = frame.y1 - frame.y0, ystep = [0.25, 0.5, 1, 2, 5].find(v => range / v <= 6) ?? 10;
  const yticks = Array.from({ length: 40 }, (_, i) => Math.ceil(frame.y0 / ystep) * ystep + i * ystep).filter(v => v <= frame.y1);
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img"
      aria-label={`Points ${xs.map((x, i) => `(${nice(x)}, ${nice(ys[i]!)})`).join(", ")} and the line y = ${nice(m)}x + ${nice(b)}, ${quiet ? "" : `total squared error ${nice(eNow, 2)}.`}${quiet ? "" : ` The best line is y = ${nice(fit.m, 3)}x + ${nice(fit.b, 3)}.`}`}>
      <defs><clipPath id="mvbowlclip"><rect x={sc[0]} y={sc[1]} width={sc[2]} height={sc[3]} /></clipPath></defs>
      <rect x={sc[0]} y={sc[1]} width={sc[2]} height={sc[3]} className="mvframe" />
      {yticks.map(v => <g key={`y${v}`}>
        <line x1={sc[0]} y1={SY(v)} x2={sc[0] + sc[2]} y2={SY(v)} className="b2grid" />
        <text x={sc[0] - 3} y={SY(v) + 4} textAnchor="end" className="b2t">{nice(v)}</text>
      </g>)}
      {xs.map((x, i) => <text key={`x${i}`} x={SX(x)} y={sc[1] + sc[3] + 14} textAnchor="middle" className="b2t">{nice(x)}</text>)}
      {frame.y0 < 0 && <line x1={sc[0]} y1={SY(0)} x2={sc[0] + sc[2]} y2={SY(0)} className="b2grid strong" />}
      <g clipPath="url(#mvbowlclip)">
        {!quiet && <line {...lineAt(fit.m, fit.b)} className="mvcut amber" />}
        {xs.map((x, i) => <line key={i} x1={SX(x)} y1={SY(ys[i]!)} x2={SX(x)} y2={SY(m * x + b)} className="mvcut pink" />)}
        <line {...lineAt(m, b)} className="b2curve sky" />
      </g>
      {xs.map((x, i) => <g key={i}>
        <circle cx={SX(x)} cy={SY(ys[i]!)} r="5.5" className="mvdot" />
        {!land && !guessing && <circle cx={SX(x)} cy={SY(ys[i]!)} r="16" className="b2hit"
          {...drag((_, py) => { setRolling(false); setYs(v => v.map((w, j) => (j === i ? r1(clampY(iy(py))) : w))); })} />}
      </g>)}
      {hx.map((x, k) => <g key={`h${k}`}>
        <circle cx={SX(x)} cy={SY(m * x + b)} r="6" className="mvhandle sky" />
        {(guessing || !marker) && <circle cx={SX(x)} cy={SY(m * x + b)} r="18" className="b2hit" {...drag((_, py) => moveHandle(k as 0 | 1, py))} />}
      </g>)}
      <text x={sc[0]} y={sc[1] - 8} className="b2t">{land ? "height along y = 1/2" : guessing ? "drag the line's handles" : "drag the points and the line"}</text>
      <text x={sc[0] + sc[2]} y={sc[1] + sc[3] + 14} textAnchor="end" className="b2t">x</text>
      {showBowl && <>
        <FlatMap f={E} box={frame.bowl} m={bm} levels={levels}>
          {marker && !onMarker && <circle cx={bm.X(inBowl(marker)[0])} cy={bm.Y(inBowl(marker)[1])} r="8" className="b2mark guess round" />}
          <circle cx={bm.X(fit.m)} cy={bm.Y(fit.b)} r="4" className="mvdot amber" />
          <circle cx={bm.X(ball[0])} cy={bm.Y(ball[1])} r="7" className="mvball" />
        </FlatMap>
        <text x={bm.frame[0] + bm.frame[2] / 2} y={bm.frame[1] + bm.frame[3] + 16} textAnchor="middle" className="b2t">slope m</text>
        <text x={bm.frame[0]} y={bm.frame[1] - 8} className="b2t">the error bowl E(m, b)</text>
        <text x={bm.frame[0] - 4} y={bm.frame[1] + bm.frame[3] / 2} textAnchor="end" className="b2t">b</text>
      </>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={!guessing && !marker ? <span className="b2marks">
        <button type="button" className="ctl go" onClick={() => setRolling(true)} disabled={rolling || eNow - eBest < 1e-6}>Roll the ball</button>
        {!land && <button type="button" className="ctl" onClick={() => { setRolling(false); setYs(start.ys); }}>Put the points back</button>}
      </span> : undefined}
      readouts={<>
        <Read label="Your line" value={`y = ${fx(m, 2)}x + ${fx(b, 2)}`} tone="sky" />
        {!quiet && <Read label="Total squared error E" value={fx(eNow, 3)} tone="pink" big />}
        {!quiet && <Read label="Bottom of the bowl" value={`m = ${fx(fit.m, 3)}, b = ${fx(fit.b, 3)}`} tone="amber" />}
        {!quiet && <Read label="Smallest E" value={fx(eBest, 3)} tone="amber" />}
      </>} />
  );
}
