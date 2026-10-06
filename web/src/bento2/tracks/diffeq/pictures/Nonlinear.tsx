// Linearize at a rest point (de-12): the full pendulum with friction, θ″ = −sin θ − bθ′ (with g/L = 1), or the
// system x′ = y, y′ = −ax + x³ − by. Arrows, paths from taps, rest points, and the separatrix when there is no
// friction. Zoom into a rest point and the curved flow straightens into its Jacobian's linear portrait.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle, useSvgDrag } from "../../../ui/kit";
import { regionNear, TYPES, type M2 } from "../maths";
import { FieldArrows, frame, trajectory, useLoop } from "./plot";
import { eigText } from "./Plane";

const W = 360, H = 270, BOX = { l: 10, r: 350, t: 10, b: 260 };

export function NonlinearScene({ props }: SceneProps) {
  const sys = str<"pend" | "duff">(props, "sys", "pend");
  const a = num(props, "a", 4);
  const quiet = flag(props, "quiet");
  const [b, setB] = useState(num(props, "b", 0));
  const [zoom, setZoom] = useState(num(props, "zoom", 1));
  const [at, setAt] = useState(num(props, "zoomAt", 0));
  const rests = sys === "pend" ? [-2 * Math.PI, -Math.PI, 0, Math.PI, 2 * Math.PI] : [-Math.sqrt(a), 0, Math.sqrt(a)];
  const focus = sys === "pend" ? (at ? Math.PI : 0) : at ? Math.sqrt(a) : 0;
  const F = (x: number, y: number): [number, number] => [y, sys === "pend" ? -Math.sin(x) - b * y : -a * x + x ** 3 - b * y];
  const J = (x: number): M2 => [[0, 1], [sys === "pend" ? -Math.cos(x) : -a + 3 * x * x, -b]];
  const hw = (sys === "pend" ? 4.4 : 1.9 * Math.sqrt(a)) / zoom, hh = hw * ((BOX.b - BOX.t) / (BOX.r - BOX.l));
  const fr = frame(focus - hw, focus + hw, -hh, hh, BOX);
  const { ref, drag } = useSvgDrag();
  const t = useLoop(0);
  const defaults: [number, number][] = sys === "pend" ? [[0.5, 0], [2.5, 0], [-2, 2.2], [-4, 2.4], [4, -2.4], [Math.PI - 0.05, 0.1]] : [[0.3 * Math.sqrt(a), 0], [0.7 * Math.sqrt(a), 0], [0, 0.5 * a], [-1.2 * Math.sqrt(a), 0.3 * a]];
  const [taps, setTaps] = useState<[number, number][]>(defaults);
  const tmax = sys === "pend" ? 14 : 8 / Math.sqrt(a);
  const paths = useMemo(() => taps.map(s => trajectory(fr, F, s, tmax, tmax / 900, "rk4", true)), [taps, b, zoom, at]); // eslint-disable-line react-hooks/exhaustive-deps
  const sep = (s: 1 | -1, k: number) => path(Array.from({ length: 81 }, (_, j) => { const x = -Math.PI + (2 * Math.PI * j) / 80; return [fr.X(x + 2 * k * Math.PI), fr.Y(s * 2 * Math.cos(x / 2))] as [number, number]; }));
  const Jf = J(focus), T = Jf[0][0] + Jf[1][1], D = Jf[0][0] * Jf[1][1] - Jf[0][1] * Jf[1][0];
  const loopK = (t % 8) / 8;
  const names = sys === "pend" ? ["Bottom, θ = 0", "Top, θ = π"] : ["Origin", `(${fx(Math.sqrt(a), 0)}, 0)`];
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`${sys === "pend" ? "Pendulum" : "Nonlinear system"} phase plane${zoom > 1 ? `, zoomed ${fx(zoom, 1)} times into ${names[at]}` : ""}.`}>
      <defs><clipPath id="nlclip"><rect x={BOX.l} y={BOX.t} width={BOX.r - BOX.l} height={BOX.b - BOX.t} rx="8" /></clipPath></defs>
      <rect x={BOX.l} y={BOX.t} width={BOX.r - BOX.l} height={BOX.b - BOX.t} className="b2hit" {...drag((x, y) => { if (!quiet) setTaps(s => [...s.slice(-7), [fr.ix(x), fr.iy(y)]]); })} />
      <g clipPath="url(#nlclip)" pointerEvents="none">
        <line x1={BOX.l} y1={fr.Y(0)} x2={BOX.r} y2={fr.Y(0)} className="b2axis" opacity={0.5} />
        <FieldArrows fr={fr} f={F} n={15} len={8} />
        {sys === "pend" && b === 0 && [-1, 0, 1].map(k => <g key={k}><path d={sep(1, k)} className="b2mark amber" /><path d={sep(-1, k)} className="b2mark amber" /></g>)}
        {!quiet && paths.map((pts, i) => <path key={i} d={path(pts)} className="b2curve sky" style={{ strokeWidth: 1.8 }} />)}
        {!quiet && paths.map((pts, i) => { const d = pts[Math.floor(loopK * (pts.length - 1))]; return d && <circle key={`d${i}`} cx={d[0]} cy={d[1]} r="3.5" className="b2dot sky" />; })}
        {rests.map((x, i) => {
          const j = J(x), d = j[0][0] * j[1][1] - j[0][1] * j[1][0], saddle = d < 0;
          return <circle key={i} cx={fr.X(x)} cy={fr.Y(0)} r={6} className={quiet ? "b2clock" : saddle ? "b2clock pink" : b > 0 ? "b2dot mint" : "b2clock mint"} />;
        })}
      </g>
      {sys === "pend" && zoom === 1 && <>
        <text x={fr.X(0)} y={fr.Y(0) + 22} textAnchor="middle" className="b2t">bottom</text>
        <text x={fr.X(Math.PI)} y={fr.Y(0) + 22} textAnchor="middle" className="b2t">top</text>
      </>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {sys === "pend" && <Slider label="Friction b" value={b} min={0} max={1} step={0.05} onChange={setB} format={x => fx(x, 2)} />}
        <Slider label="Zoom" value={zoom} min={1} max={6} step={0.1} onChange={setZoom} format={x => `× ${fx(x, 1)}`} />
        <Toggle label="Zoom into" value={String(at)} onChange={v => setAt(Number(v))} options={names.map((n, i) => ({ v: String(i), label: n }))} />
      </>}
      readouts={<>
        {!quiet && <Read label="J here" value={`[[0, 1], [${fx(Jf[1][0], 2).replace(".00", "")}, ${fx(Jf[1][1], 2).replace(".00", "")}]]`} />}
        {!quiet && <Read label="T, D" value={`${fx(T, 2).replace(".00", "")}, ${fx(D, 2).replace(".00", "")}`} />}
        {!quiet && <Read label="Eigenvalues" value={eigText(Jf)} tone="amber" />}
        {!quiet && <Read label="Linear portrait" value={TYPES[regionNear(T, D)] ?? "a line of rest points"} />}
      </>}
    />
  );
}
