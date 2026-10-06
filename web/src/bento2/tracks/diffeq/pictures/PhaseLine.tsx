// ★ The flow sandbox's phase line strip (diffeq.md, "New for Development" 1a): the slope field of dy/dt = f(y) on the
// left, solutions that start where you tap, the phase line in the middle (rest points filled when stable, open when
// unstable, arrows between), and f's graph on its side at the right, whose roots you drag. Also the Allee population
// for de-01's Use it, which saves allee_A and K_fish.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, Toggle, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { solve } from "../maths";
import { sn } from "../text";
import { Arrow, frame, useLoop, useRun } from "./plot";

const W = 360, H = 270;
const FIELD = { l: 30, r: 206, t: 14, b: H - 14 }, PL = 228, FG = { l: 250, r: 350 };

interface ViewProps {
  f: (y: number) => number;
  roots: number[];
  lo: number; hi: number; tmax: number;
  quiet?: boolean;
  start?: number;
  run?: number;
  marker?: number;
  /** which roots can be dragged, and where they go */
  onRoot?: (i: number, y: number) => void;
  fixed?: number[];
  unit?: string;
}

/** the strip: field, phase line and f on its side, all on one y axis */
export function PhaseLineView({ f, roots, lo, hi, tmax, quiet, start, run, marker, onRoot, fixed = [], unit = "y" }: ViewProps) {
  const fr = frame(0, tmax, lo, hi, FIELD);
  const { Y, X, iy } = fr;
  const [starts, setStarts] = useState<[number, number][]>([]);
  const { ref, drag } = useSvgDrag();
  const t = useLoop(tmax);
  const runK = useRun(run !== undefined, 3);
  const sorted = [...roots].sort((a, b) => a - b);
  const slope = (y: number) => (f(y + 1e-5) - f(y - 1e-5)) / 2e-5;
  const fmax = Math.max(1e-6, ...Array.from({ length: 61 }, (_, k) => Math.abs(f(lo + ((hi - lo) * k) / 60))));
  const FX = (v: number) => (FG.l + FG.r) / 2 + (v / fmax) * ((FG.r - FG.l) / 2);
  const curve = useMemo(() => path(Array.from({ length: 121 }, (_, k) => { const y = lo + ((hi - lo) * k) / 120; return [FX(f(y)), Y(y)] as [number, number]; })), [f, lo, hi, fmax]); // eslint-disable-line react-hooks/exhaustive-deps
  const sol = (t0: number, y0: number) => solve((_t, y) => [f(y[0]!)], [y0], t0, tmax, 0.01).filter(p => p.y[0]! > lo - 1 && p.y[0]! < hi + 1).map(p => [X(p.t), Y(p.y[0]!)] as [number, number]);
  const paths = useMemo(() => starts.map(([t0, y0]) => sol(t0, y0)), [starts, f]); // eslint-disable-line react-hooks/exhaustive-deps
  const runPath = useMemo(() => (run !== undefined ? sol(0, run) : null), [run, f]); // eslint-disable-line react-hooks/exhaustive-deps
  // slope marks: direction (1, f) in picture units
  const marks = [];
  for (let i = 0; i < 9; i++) for (let j = 0; j < 15; j++) {
    const tt = (tmax * (i + 0.5)) / 9, yy = lo + ((hi - lo) * (j + 0.5)) / 15;
    const a = (FIELD.r - FIELD.l) / tmax, b = (-f(yy) * (FIELD.b - FIELD.t)) / (hi - lo), m = Math.hypot(a, b), L = 7;
    marks.push(<line key={`${i}-${j}`} x1={X(tt) - (a / m) * L} y1={Y(yy) - (b / m) * L} x2={X(tt) + (a / m) * L} y2={Y(yy) + (b / m) * L} className="b2axis" opacity={0.35} style={{ strokeWidth: 1.2 }} />);
  }
  const tap = (px: number, py: number) => { if (quiet) return; setStarts(s => [...s.slice(-5), [fr.ix(px), iy(py)]]); };
  // where a solution's dot is now: it slides along its path as time loops
  const dotAt = (pts: [number, number][], k: number) => pts[Math.min(pts.length - 1, Math.floor(k * (pts.length - 1)))];
  const loopK = (t % tmax) / tmax;
  const gaps = [lo, ...sorted, hi];
  return (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={`Slope field and phase line for d${unit}/dt = f(${unit}). Rest points at ${sorted.map(r => fx(r, 1)).join(", ")}.`}>
      <defs><clipPath id="plclip"><rect x={FIELD.l} y={FIELD.t} width={FIELD.r - FIELD.l} height={FIELD.b - FIELD.t} /></clipPath></defs>
      <rect x={FIELD.l} y={FIELD.t} width={FIELD.r - FIELD.l} height={FIELD.b - FIELD.t} className="b2hit" {...drag(tap)} />
      <g clipPath="url(#plclip)" pointerEvents="none">
        {!quiet && marks}
        {sorted.map((r, i) => <line key={i} x1={FIELD.l} y1={Y(r)} x2={FIELD.r} y2={Y(r)} className="b2mark amber" />)}
        {!quiet && paths.map((pts, i) => <path key={i} d={path(pts)} className="b2curve sky" style={{ strokeWidth: 2 }} />)}
        {!quiet && paths.map((pts, i) => { const d = dotAt(pts, loopK); return d && <circle key={`d${i}`} cx={d[0]} cy={d[1]} r="4" className="b2dot sky" />; })}
        {runPath && <path d={path(runPath.slice(0, Math.max(2, Math.ceil(runPath.length * runK))))} className="b2curve trav" />}
        {marker !== undefined && <line x1={FIELD.l} y1={Y(marker)} x2={PL + 10} y2={Y(marker)} className="b2mark guess" />}
      </g>
      <line x1={FIELD.l} y1={FIELD.b} x2={FIELD.r} y2={FIELD.b} className="b2axis" />
      <line x1={FIELD.l} y1={FIELD.t} x2={FIELD.l} y2={FIELD.b} className="b2axis" />
      <text x={FIELD.l - 6} y={Y(hi) + 10} textAnchor="end" className="b2t">{fx(hi, 0)}</text>
      <text x={FIELD.l - 6} y={Y(lo)} textAnchor="end" className="b2t">{fx(lo, 0)}</text>
      <text x={FIELD.r} y={FIELD.b - 6} textAnchor="end" className="b2t">t</text>
      {/* the phase line */}
      <line x1={PL} y1={FIELD.t} x2={PL} y2={FIELD.b} className="b2axis" />
      {!quiet && gaps.slice(0, -1).map((a, i) => {
        const b = gaps[i + 1]!, mid = (a + b) / 2, up = f(mid) > 0;
        if (Y(a) - Y(b) < 26) return null;
        const y1 = Y(mid) + (up ? 8 : -8), y2 = Y(mid) + (up ? -8 : 8);
        return <Arrow key={i} x1={PL} y1={y1} x2={PL} y2={y2} cls="sky" />;
      })}
      {sorted.map((r, i) => quiet
        ? <circle key={i} cx={PL} cy={Y(r)} r="6" className="b2clock" />
        : slope(r) < 0 ? <circle key={i} cx={PL} cy={Y(r)} r="6" className="b2dot amber" /> : <circle key={i} cx={PL} cy={Y(r)} r="6" className="b2clock amber" />)}
      {start !== undefined && <circle cx={PL} cy={Y(run !== undefined && runPath ? fr.iy(runPath[Math.max(0, Math.ceil(runPath.length * runK) - 1)]![1]) : start)} r="5" className="b2dot trav" />}
      {/* f on its side */}
      <line x1={FX(0)} y1={FIELD.t} x2={FX(0)} y2={FIELD.b} className="b2axis" />
      <path d={curve} className="b2curve pink" />
      <text x={FG.r} y={FIELD.t + 10} textAnchor="end" className="b2t pink">f</text>
      {roots.map((r, i) => fixed.includes(i) || !onRoot ? null : (
        <g key={`h${i}`}>
          <circle cx={FX(0)} cy={Y(r)} r="8" className="b2handle" />
          <rect x={FX(0) - 22} y={Y(r) - 16} width="44" height="32" className="b2hit" {...drag((_x, y) => onRoot(i, Math.round(iy(y) * 2) / 2))} />
        </g>
      ))}
    </svg>
  );
}

const SIGN = [{ v: "-1", label: "f = −(…)(…)(…)" }, { v: "1", label: "f = +(…)(…)(…)" }];

export function PhaseLineScene({ props, marker }: SceneProps) {
  const [s, setS] = useState(num(props, "s", -1));
  const [roots, setRoots] = useState([num(props, "a", -1), num(props, "b", 2), num(props, "c", 4)]);
  const quiet = flag(props, "quiet");
  const start = typeof props.start === "number" ? props.start : undefined;
  const run = typeof props.run === "number" ? props.run : undefined;
  const f = useMemo(() => (y: number) => s * (y - roots[0]!) * (y - roots[1]!) * (y - roots[2]!), [s, roots]);
  const move = (i: number, y: number) => setRoots(rs => {
    const c = Math.max(-4.5, Math.min(6.5, y));
    if (rs.some((r, j) => j !== i && Math.abs(r - c) < 0.25)) return rs;
    return rs.map((r, j) => (j === i ? c : r));
  });
  const sorted = [...roots].sort((a, b) => a - b);
  const slope = (y: number) => s * sorted.filter(r => r !== y).reduce((m, r) => m * (y - r), 1);
  return (
    <Scene
      svg={<PhaseLineView f={f} roots={roots} lo={-5} hi={7} tmax={4} quiet={quiet} start={start} run={run} marker={marker?.[0]} onRoot={quiet ? undefined : move} />}
      controls={!quiet && <Toggle label="Sign of f" value={String(s)} options={SIGN} onChange={v => setS(Number(v))} />}
      readouts={<>
        <Read label="Rest points" value={sorted.map(r => sn(r)).join(", ")} tone="amber" />
        {!quiet && <Read label="Stable" value={sorted.filter(r => slope(r) < 0).map(r => sn(r)).join(", ") || "none"} />}
        {start !== undefined && <Read label={`f(${sn(start)})`} value={fx(f(start), 1)} tone="pink" />}
        {!quiet && <Read label="Tap the field" value="to start a solution" />}
      </>}
    />
  );
}

const REEF = { A: 150, K: 1200 };

/** dP/dt = rP(P/A − 1)(1 − P/K): below A the herd dies out */
export function AlleeScene({ props, place }: SceneProps) {
  const { b2, save, note } = useB2();
  const shelfA = b2.shelf.allee_A?.value, shelfK = b2.shelf.K_fish?.value;
  const [A, setA] = useState(typeof shelfA === "number" ? shelfA : num(props, "A", REEF.A));
  const [K, setK] = useState(typeof shelfK === "number" ? shelfK : num(props, "K", REEF.K));
  const r = 0.4;
  const f = useMemo(() => (P: number) => r * P * (P / A - 1) * (1 - P / K), [A, K]);
  const canSave = place === "project" || flag(props, "saveable");
  const saved = shelfA === A && shelfK === K;
  const onSave = () => {
    save("allee_A", A, "b2-de-01", { unit: "fish", note: "the Allee threshold: below it the herd dies out" });
    save("K_fish", K, "b2-de-01", { unit: "fish", note: "the reef's carrying capacity" });
    note({ id: "de-allee", track: "de", title: "Allee threshold", project: "b2-de-01", data: { A, K }, lines: [`A reef fish with threshold ${A} and capacity ${K}.`, `A herd of ${A + 1} or more grows toward ${K}; any fewer dies out.`] });
  };
  return (
    <Scene
      svg={<PhaseLineView f={f} roots={[0, A, K]} lo={-K * 0.05} hi={K * 1.25} tmax={20} unit="P" fixed={[0, 1, 2]} />}
      controls={<>
        <Slider label="Threshold A" value={A} min={20} max={Math.min(600, K - 50)} step={10} onChange={setA} format={v => `${v} fish`} marks={[{ v: REEF.A, label: "Reef: 150" }]} />
        <Slider label="Capacity K" value={K} min={400} max={2000} step={50} onChange={v => { setK(v); if (A > v - 50) setA(v - 50); }} format={v => `${v} fish`}
          marks={[{ v: REEF.K, label: "Reef: 1,200" }]} />
      </>}
      readouts={<>
        <Read label="Dies out below" value={`${A} fish`} tone="amber" />
        <Read label="Grows toward" value={`${K} fish`} tone="sky" />
      </>}
      foot={canSave ? <SaveRow what={<>Keep <b>allee_A = {A}</b> and <b>K_fish = {K}</b> for the build</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
