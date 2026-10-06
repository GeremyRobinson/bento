// ★ The flow sandbox's phase plane (diffeq.md, "New for Development" 1b and 5): any 2×2 system x′ = Ax as an arrow
// field, eigen-lines when the eigenvalues are real, paths that start where you tap, and the trace, determinant and
// eigenvalues (complex ones as α ± βi). Modes: a spring y″ + by′ + cy = 0 bouncing beside its plane (de-05), a free
// matrix (de-06, de-07), and the pendulum near the bottom, whose matrix saves as A_pend.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { det, eig, eigenLines, G, mul, regionNear, trace, TYPES, type M2 } from "../maths";
import { Arrow, FieldArrows, frame, part, trajectory, useLoop, useRun } from "./plot";

const W = 360, H = 280;
type Mode = "spring" | "matrix" | "pend";

/** "3, −1" or "−1 ± 2i" */
export function eigText(A: M2) {
  const e = eig(trace(A), det(A));
  return e.real ? `${fx(e.l1, 2)}, ${fx(e.l2, 2)}`.replace(/\.00/g, "") : `${fx(e.a, 2)} ± ${fx(e.b, 2)}i`.replace(/\.00/g, "");
}

export function PlaneScene({ props, marker, onMarker, place }: SceneProps) {
  const mode = str<Mode>(props, "mode", "matrix");
  const quiet = flag(props, "quiet");
  const { b2, save } = useB2();
  const [b, setB] = useState(num(props, "b", 1));
  const [c, setC] = useState(num(props, "c", 4));
  const [L, setL] = useState(num(props, "L", 1));
  const [beta, setBeta] = useState(num(props, "beta", 0.5));
  const [m, setM] = useState<[number, number, number, number]>([num(props, "a11", 0), num(props, "a12", 1), num(props, "a21", -2), num(props, "a22", -1)]);
  const A: M2 = mode === "spring" ? [[0, 1], [-c, -b]] : mode === "pend" ? [[0, 1], [-G / L, -beta]] : [[m[0], m[1]], [m[2], m[3]]];
  const T = trace(A), D = det(A);
  const box = mode === "spring" ? { l: 12, r: 272, t: 10, b: 270 } : { l: 50, r: 310, t: 10, b: 270 };
  const fr = mode === "pend" ? frame(-1.2, 1.2, -4, 4, box) : frame(-4, 4, -4, 4, box);
  const F = (x: number, y: number): [number, number] => mul(A, [x, y]);
  const { ref, drag } = useSvgDrag();
  const t = useLoop(3);
  const hasStart = typeof props.sx === "number";
  const start: [number, number] = [num(props, "sx", mode === "pend" ? 0.8 : 2), num(props, "sy", 0)];
  const runK = useRun(flag(props, "run"), flag(props, "quarter") ? 2 : 5);
  const [taps, setTaps] = useState<[number, number][]>(quiet || hasStart ? [] : mode === "pend" ? [[1, 0], [-1, 0], [0, 3.5]] : [[3, 1], [-3, -1], [1, -3], [-1, 3]]);
  const span = Math.max(1, ...A.flat().map(Math.abs));
  const tmax = Math.min(12, 30 / span);
  const paths = useMemo(() => taps.map(s => trajectory(fr, F, s, tmax, tmax / 600)), [taps, ...A.flat(), mode]); // eslint-disable-line react-hooks/exhaustive-deps
  const main = useMemo(() => trajectory(fr, F, start, flag(props, "quarter") ? Math.PI / 2 / Math.max(0.2, eigImag(A)) : tmax, tmax / 600), [...A.flat(), mode, start[0], start[1]]); // eslint-disable-line react-hooks/exhaustive-deps
  const lines = eigenLines(A);
  const showLines = (!quiet || flag(props, "lines")) && lines.length > 0;
  // the probe (de-05): the state at (px, py), its true arrow, and the learner's guessed one
  const probe = flag(props, "probe") ? [num(props, "px", 1), num(props, "py", -1)] as [number, number] : null;
  const AS = 0.5;
  // the test arrow on a circle (de-06): A·v lines up with v on an eigen-line
  const [phi, setPhi] = useState(0.3);
  const v: [number, number] = [2.5 * Math.cos(phi), 2.5 * Math.sin(phi)], Av = mul(A, v);
  const cross = (v[0] * Av[1] - v[1] * Av[0]) / (Math.hypot(...v) * Math.hypot(...Av) || 1);
  const lit = flag(props, "probeRing") && Math.abs(cross) < 0.06;
  const e = eig(T, D);
  const loopK = (t % 6) / 6;
  const dot = (pts: [number, number][], k: number) => pts[Math.min(pts.length - 1, Math.floor(k * (pts.length - 1)))];
  const tapAt = (px: number, py: number) => { if (quiet) return; setTaps(s => [...s.slice(-5), [fr.ix(px), fr.iy(py)]]); };
  // the spring's mass follows the main path's position
  const massK = flag(props, "run") ? runK : loopK, massP = dot(main, massK);
  const massX = massP ? fr.ix(massP[0]) : start[0];
  const swings = !e.real && e.a < 0 ? Math.ceil(Math.log(0.01) / ((2 * Math.PI * e.a) / e.b) - 1e-9) : null;
  const project = place === "project" || flag(props, "saveable");
  const shelfA = b2.shelf.A_pend?.value;
  const savedPend = Array.isArray(shelfA) && JSON.stringify(shelfA) === JSON.stringify(A);
  const setEntry = (i: number) => (x: number) => setM(mm => mm.map((y, j) => (j === i ? x : y)) as [number, number, number, number]);
  const lim = Math.max(6, Math.ceil(Math.max(...m.map(Math.abs))));

  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={`Phase plane of x′ = Ax with A = [[${A[0].map(x => fx(x, 2)).join(", ")}], [${A[1].map(x => fx(x, 2)).join(", ")}]]${quiet ? "" : `: ${TYPES[regionNear(T, D)] ?? "a line of rest points"}`}.`}>
      <defs><clipPath id="ppclip"><rect x={box.l} y={box.t} width={box.r - box.l} height={box.b - box.t} /></clipPath></defs>
      <rect x={box.l} y={box.t} width={box.r - box.l} height={box.b - box.t} className="b2hit" {...drag(tapAt)} />
      <g clipPath="url(#ppclip)" pointerEvents="none">
        <line x1={box.l} y1={fr.Y(0)} x2={box.r} y2={fr.Y(0)} className="b2axis" opacity={0.6} />
        <line x1={fr.X(0)} y1={box.t} x2={fr.X(0)} y2={box.b} className="b2axis" opacity={0.6} />
        {!quiet && <FieldArrows fr={fr} f={F} n={13} len={9} />}
        {showLines && lines.map(([u, w], i) => <line key={i} x1={fr.X(-20 * u)} y1={fr.Y(-20 * w)} x2={fr.X(20 * u)} y2={fr.Y(20 * w)} className="b2mark amber" />)}
        {lit && lines.map(([u, w], i) => Math.abs(u * v[1] - w * v[0]) / 2.5 < 0.1 && <line key={`l${i}`} x1={fr.X(-20 * u)} y1={fr.Y(-20 * w)} x2={fr.X(20 * u)} y2={fr.Y(20 * w)} className="b2leg amber" style={{ strokeWidth: 3 }} />)}
        {paths.map((pts, i) => <path key={i} d={path(pts)} className="b2curve sky" style={{ strokeWidth: 1.8 }} />)}
        {paths.map((pts, i) => { const d = dot(pts, loopK); return d && <circle key={`d${i}`} cx={d[0]} cy={d[1]} r="3.5" className="b2dot sky" />; })}
        {(hasStart || mode === "spring") && !(quiet && !flag(props, "run")) && <path d={flag(props, "run") ? part(main, runK) : path(main)} className="b2curve trav" />}
        {(hasStart || mode === "spring") && massP && !(quiet && !flag(props, "run")) && <circle cx={massP[0]} cy={massP[1]} r="5" className="b2dot trav" />}
      </g>
      <circle cx={fr.X(0)} cy={fr.Y(0)} r="4" className="b2dot amber" />
      {hasStart && <circle cx={fr.X(start[0])} cy={fr.Y(start[1])} r="5.5" className="b2clock trav" />}
      {probe && <circle cx={fr.X(probe[0])} cy={fr.Y(probe[1])} r="5" className="b2dot" />}
      {probe && (flag(props, "showProbe") || (!quiet && !onMarker)) && (() => { const [u, w] = F(...probe); return <Arrow x1={fr.X(probe[0])} y1={fr.Y(probe[1])} x2={fr.X(probe[0] + AS * u)} y2={fr.Y(probe[1] + AS * w)} cls="pink" w={3} />; })()}
      {probe && marker && <>
        <Arrow x1={fr.X(probe[0])} y1={fr.Y(probe[1])} x2={fr.X(probe[0] + AS * marker[0])} y2={fr.Y(probe[1] + AS * marker[1])} cls="trav" w={2.5} />
        {onMarker && <>
          <circle cx={fr.X(probe[0] + AS * marker[0])} cy={fr.Y(probe[1] + AS * marker[1])} r="9" className="b2marker" />
          <circle cx={fr.X(probe[0] + AS * marker[0])} cy={fr.Y(probe[1] + AS * marker[1])} r="22" className="b2hit"
            {...drag((x, y) => onMarker([Math.round(((fr.ix(x) - probe[0]) / AS) * 2) / 2, Math.round(((fr.iy(y) - probe[1]) / AS) * 2) / 2]))} />
        </>}
      </>}
      {flag(props, "probeRing") && <>
        <circle cx={fr.X(0)} cy={fr.Y(0)} r={fr.X(2.5) - fr.X(0)} className="b2ring" />
        <Arrow x1={fr.X(0)} y1={fr.Y(0)} x2={fr.X(v[0])} y2={fr.Y(v[1])} cls="trav" w={2.5} />
        {(() => { const s = 2.5 / Math.max(2.5, Math.hypot(...Av)); return <Arrow x1={fr.X(v[0])} y1={fr.Y(v[1])} x2={fr.X(v[0] + s * Av[0])} y2={fr.Y(v[1] + s * Av[1])} cls="pink" w={2.5} />; })()}
        <circle cx={fr.X(v[0])} cy={fr.Y(v[1])} r="9" className="b2handle" />
        <circle cx={fr.X(v[0])} cy={fr.Y(v[1])} r="22" className="b2hit" {...drag((x, y) => setPhi(Math.atan2(fr.iy(y), fr.ix(x))))} />
      </>}
      <text x={box.r - 4} y={fr.Y(0) - 6} textAnchor="end" className="b2t">{mode === "pend" ? "θ" : "x₁"}</text>
      <text x={fr.X(0) + 6} y={box.t + 12} className="b2t">{mode === "pend" ? "θ′" : "x₂"}</text>
      {mode === "spring" && (() => {
        // the spring beside the plane, its mass at the path's position
        const x0 = 316, top = 22, rest = 140, y = rest + massX * 26, coils = 9;
        const zig = Array.from({ length: coils * 2 + 1 }, (_, i) => [x0 + (i === 0 || i === coils * 2 ? 0 : i % 2 ? -10 : 10), top + ((y - 16 - top) * i) / (coils * 2)] as [number, number]);
        return (
          <g>
            <line x1={x0 - 26} y1={top} x2={x0 + 26} y2={top} className="b2axis" />
            <path d={path(zig)} className="b2curve" style={{ strokeWidth: 1.6 }} />
            <rect x={x0 - 18} y={y - 16} width="36" height="32" rx="6" className="b2bar trav" />
            <line x1={x0 - 30} y1={rest} x2={x0 - 22} y2={rest} className="b2axis" />
          </g>
        );
      })()}
    </svg>
  );

  const controls = mode === "spring" ? <>
    <Slider label="Friction b" value={b} min={0} max={4} step={0.1} onChange={setB} format={x => fx(x, 1)} />
    <Slider label="Spring c" value={c} min={1} max={9} step={0.1} onChange={setC} format={x => fx(x, 1)} />
  </> : mode === "pend" ? <>
    <Slider label="Length L" value={L} min={0.25} max={2} step={0.01} onChange={setL} format={x => `${fx(x, 2)} m`} />
    <Slider label="Friction β" value={beta} min={0} max={2} step={0.05} onChange={setBeta} format={x => `${fx(x, 2)} per s`} />
  </> : <>
    {(["a₁₁", "a₁₂", "a₂₁", "a₂₂"] as const).map((lab, i) => <Slider key={lab} label={lab} value={m[i]!} min={-lim} max={lim} step={0.5} onChange={setEntry(i)} format={x => fx(x, 1).replace(".0", "")} />)}
  </>;
  return (
    <Scene svg={svg} controls={controls}
      readouts={<>
        {!quiet && <Read label="T, D" value={`${fx(T, 2).replace(".00", "")}, ${fx(D, 2).replace(".00", "")}`} />}
        {!quiet && <Read label="Eigenvalues" value={eigText(A)} tone="amber" />}
        {!quiet && <Read label="Type" value={TYPES[regionNear(T, D)] ?? "a line of rest points"} />}
        {!quiet && flag(props, "turns") && !e.real && <Read label="A turn takes" value={fx((2 * Math.PI) / e.b, 2)} tone="trav" />}
        {!quiet && flag(props, "turns") && !e.real && <Read label="Size left after a turn" value={fx(Math.exp((2 * Math.PI * e.a) / e.b), 3)} tone="trav" />}
        {flag(props, "swings") && <Read label="Swings to fall under 1%" value={swings === null ? "never" : String(swings)} tone="trav" big />}
        {lit && <Read label="A·v lines up with v" value="an eigen-line" tone="amber" />}
        {!quiet && <Read label="Tap the plane" value="to start a path" />}
      </>}
      foot={mode === "pend" && project
        ? <SaveRow what={<>Keep <b>A_pend = [[0, 1], [−{fx(G / L, 2)}, −{fx(beta, 2)}]]</b> for the build</>} saved={savedPend} onSave={() => { save("A_pend", A.map(r => [...r]), "b2-de-05", { note: `the pendulum near the bottom, L = ${fx(L, 2)} m, β = ${fx(beta, 2)}` }); }} />
        : undefined}
    />
  );
}

/** the turning rate β of A, or 0 */
function eigImag(A: M2) { const e = eig(trace(A), det(A)); return e.real ? 0 : e.b; }
