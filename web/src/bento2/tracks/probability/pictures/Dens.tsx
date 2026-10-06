// The Distribution lab (06): a free density sketcher (drag the handles; the curve is rescaled so its area stays 1, and
// the area between two values you drag is shaded and read out), and the exponential wait with "You already waited t",
// which cuts off the curve before t and rescales the tail: it is the curve you started with, moved over.
import { useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle, useSvgDrag } from "../../../ui/kit";
import { Act, Acts, commas, K, lin } from "./parts";

const W = 360, H = 240;

export function DensScene({ props }: SceneProps) {
  const [mode, setMode] = useState<"sketch" | "exp">(str<string>(props, "mode", "sketch") === "exp" ? "exp" : "sketch");
  const pick = <Toggle label="Distribution lab" value={mode} onChange={setMode} options={[{ v: "sketch", label: "Sketch" }, { v: "exp", label: "Exponential" }]} />;
  return mode === "sketch" ? <Sketch pick={pick} /> : <Exp props={str<string>(props, "mode", "sketch") === "exp" ? props : {}} pick={pick} />;
}

/** trapezoid weights for 7 handles on 0..6 */
const WT = [0.5, 1, 1, 1, 1, 1, 0.5];
function Sketch({ pick }: { pick: React.ReactNode }) {
  const [h, setH] = useState([0.2, 1.4, 2.2, 1.2, 0.6, 1.0, 0.3]);
  const [a, setA] = useState(1);
  const [b, setB] = useState(3);
  const A = h.reduce((s, v, i) => s + v * WT[i]!, 0), f = h.map(v => v / A);
  const X = lin(0, 6, 30, W - 14), Y = lin(0, 0.7, H - 26, 14);
  const { ref, drag } = useSvgDrag();
  const setAt = (i: number, d: number) => {
    const rest = h.reduce((s, v, j) => (j === i ? s : s + v * WT[j]!), 0);
    const dd = Math.max(0, Math.min(0.9 / WT[i]!, d));
    setH(hs => hs.map((v, j) => (j === i ? Math.max(0.001, (dd * rest) / (1 - dd * WT[i]!)) : v)));
  };
  const at = (x: number) => { const i = Math.min(5, Math.floor(x)), t = x - i; return f[i]! * (1 - t) + f[i + 1]! * t; };
  const area = (lo: number, hi: number) => { let s = 0; const n = 300, d = (hi - lo) / n; for (let k = 0; k < n; k++) s += at(lo + (k + 0.5) * d) * d; return s; };
  const lo = Math.min(a, b), hi = Math.max(a, b);
  const shade: [number, number][] = [[X(lo), Y(0)]];
  for (let k = 0; k <= 60; k++) { const x = lo + ((hi - lo) * k) / 60; shade.push([X(x), Y(at(x))]); }
  shade.push([X(hi), Y(0)]);
  const mean = (() => { let s = 0; for (let k = 0; k < 600; k++) { const x = (k + 0.5) / 100; s += x * at(x) * 0.01; } return s; })();
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A sketched density with area 1. The area between ${fx(lo, 1)} and ${fx(hi, 1)} is ${fx(area(lo, hi), 3)}.`}>
      <path d={`${path(shade)} Z`} style={{ fill: K.sky, fillOpacity: 0.3 }} />
      <path d={path(f.map((v, i) => [X(i), Y(v)]))} style={{ fill: "none", stroke: K.sky, strokeWidth: 2.5 }} />
      <line x1={X(0)} x2={X(6)} y1={Y(0)} y2={Y(0)} className="b2axis" />
      {[0, 1, 2, 3, 4, 5, 6].map(i => <text key={i} x={X(i)} y={H - 8} textAnchor="middle" className="b2t">{i}</text>)}
      {f.map((v, i) => <circle key={i} cx={X(i)} cy={Y(v)} r="9" className="b2marker" {...drag((_, y) => setAt(i, (Y(0) - y) / (Y(0) - Y(1))))} />)}
      <text x={X((lo + hi) / 2)} y={Y(0) - 8} textAnchor="middle" className="b2t sky">{fx(area(lo, hi), 3)}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="From a" value={a} min={0} max={6} step={0.1} onChange={setA} format={x => fx(x, 1)} />
        <Slider label="To b" value={b} min={0} max={6} step={0.1} onChange={setB} format={x => fx(x, 1)} />
        {pick}
      </>}
      readouts={<>
        <Read label={`P(${fx(lo, 1)} < X < ${fx(hi, 1)})`} value={fx(area(lo, hi), 3)} tone="sky" big />
        <Read label="Total area" value={fx(area(0, 6), 2)} />
        <Read label="Mean" value={fx(mean, 2)} />
      </>}
    />
  );
}

function Exp({ props, pick }: { props: SceneProps["props"]; pick: React.ReactNode }) {
  const quiet = flag(props, "quiet");
  const [m, setM] = useState(num(props, "mean", 4));
  const [waitOn, setWaitOn] = useState(props.waited != null);
  const [t, setT] = useState(num(props, "waited", m));
  const lo = num(props, "lo", NaN), hi = num(props, "hi", NaN);
  const top = 4.2 * m, lam = 1 / m;
  const X = lin(0, top, 30, W - 14), Y = lin(0, lam * 1.15, H - 26, 14);
  const f = (x: number) => lam * Math.exp(-lam * x);
  const curve = (from: number, g: (x: number) => number) => { const pts: [number, number][] = []; for (let k = 0; k <= 120; k++) { const x = from + ((top - from) * k) / 120; pts.push([X(x), Y(Math.min(lam * 1.15, g(x)))]); } return pts; };
  const tw = Math.min(t, top * 0.75);
  const shadePts = (a: number, b: number): [number, number][] => [[X(a), Y(0)], ...Array.from({ length: 41 }, (_, k) => { const x = a + ((b - a) * k) / 40; return [X(x), Y(f(x))] as [number, number]; }), [X(b), Y(0)]];
  const big = m >= 1000, lab = (x: number) => (big ? commas(x) : fx(x, x % 1 ? 1 : 0));
  const ticks = [0, 1, 2, 3, 4].map(k => k * m);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`An exponential wait with mean ${lab(m)}.${waitOn ? ` After waiting ${lab(tw)}, the rescaled tail matches the original curve.` : ""}`}>
      {Number.isFinite(lo) && Number.isFinite(hi) && <path d={`${path(shadePts(lo, hi))} Z`} style={{ fill: K.sky, fillOpacity: 0.3 }} />}
      {waitOn && <rect x={X(0)} y={Y(lam * 1.15)} width={X(tw) - X(0)} height={Y(0) - Y(lam * 1.15)} style={{ fill: "var(--page)", fillOpacity: 0.55 }} />}
      <path d={path(curve(0, f))} style={{ fill: "none", stroke: K.sky, strokeWidth: 2.5, opacity: waitOn ? 0.45 : 1 }} />
      {waitOn && <>
        <path d={path(curve(tw, x => f(x) / Math.exp(-lam * tw)))} style={{ fill: "none", stroke: K.amber, strokeWidth: 3 }} />
        <path d={path(curve(tw, x => f(x - tw)))} style={{ fill: "none", stroke: K.text, strokeWidth: 1.5, strokeDasharray: "5 5" }} />
        <line x1={X(tw)} x2={X(tw)} y1={Y(0)} y2={Y(lam * 1.15)} style={{ stroke: K.amber, strokeWidth: 1.5 }} />
        <text x={X(tw) + 6} y={Y(lam) - 6} className="b2t amber">the tail, rescaled</text>
      </>}
      <line x1={X(m * Math.LN2)} x2={X(m * Math.LN2)} y1={Y(0)} y2={Y(f(m * Math.LN2))} style={{ stroke: K.pink, strokeWidth: 1.5, strokeDasharray: "4 3" }} />
      <text x={X(m * Math.LN2)} y={Y(f(m * Math.LN2)) - 6} textAnchor="middle" className="b2t pink">median</text>
      <line x1={X(0)} x2={X(top)} y1={Y(0)} y2={Y(0)} className="b2axis" />
      {ticks.map(x => <text key={x} x={X(x)} y={H - 8} textAnchor="middle" className="b2t">{lab(x)}</text>)}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Mean wait" value={m} min={big ? 1000 : 1} max={big ? 12000 : 20} step={big ? 10 : 0.5} onChange={setM} format={lab} />
        {waitOn && <Slider label="Already waited t" value={t} min={0} max={3 * m} step={m / 20} onChange={setT} format={lab} />}
        <Acts><Act on={waitOn} onClick={() => setWaitOn(w => !w)}>{waitOn ? "Start fresh" : `You already waited ${lab(t)}`}</Act></Acts>
        {pick}
      </>}
      readouts={<>
        <Read label="Rate λ = 1/mean" value={big ? fx(lam, 6) : fx(lam, 3)} />
        <Read label={`P(X > ${lab(tw)})`} value={fx(Math.exp(-lam * tw), 4)} tone="sky" />
        <Read label="Median, m ln 2" value={lab(m * Math.LN2)} tone="pink" />
        {Number.isFinite(lo) && <Read label={`P(${lab(lo)} < X < ${lab(hi)})`} value={fx(Math.exp(-lo / m) - Math.exp(-hi / m), 4)} tone="sky" />}
        {!quiet && waitOn && <Read label="Expected wait still to go" value={lab(m)} tone="amber" big />}
      </>}
    />
  );
}
