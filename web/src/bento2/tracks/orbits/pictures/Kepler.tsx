// The Kepler checker (orbits.md, "New for Development" 3). Two views:
//   loglog: the real planets on log-log axes of distance against year length, on one line of slope 3/2, and a new planet
//     you drag along the distance axis (b2-or-03). A slider guess draws as a dashed line on the year axis.
//   areas: an ellipse with the wedge swept in each equal time step shaded; the planet moves by Kepler's equation, and
//     the near and far speed arrows show r × v staying the same (b2-or-05).
import { useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, useClock, useSvgDrag } from "../../../ui/kit";
import { Arrow } from "./parts";

export function KeplerScene(sp: SceneProps) {
  return str<string>(sp.props, "mode", "loglog") === "areas" ? <AreasView {...sp} /> : <LogLogView {...sp} />;
}

const PLANETS: { name: string; a: number; label?: boolean }[] = [
  { name: "Mercury", a: 0.387, label: true }, { name: "Venus", a: 0.723 }, { name: "Earth", a: 1, label: true }, { name: "Mars", a: 1.524 },
  { name: "Jupiter", a: 5.203, label: true }, { name: "Saturn", a: 9.537 }, { name: "Uranus", a: 19.19 }, { name: "Neptune", a: 30.07, label: true },
];

function LogLogView({ props, marker }: SceneProps) {
  const hide = flag(props, "hide");
  const [a, setA] = useState(num(props, "a", 2.5));
  const { ref, drag } = useSvgDrag();
  const W = 360, H = 250, x0 = 46, x1 = 346, y0 = 216, y1 = 14;
  const lx = [-0.6, 1.6], ly = [-0.9, 2.4];
  const X = (av: number) => x0 + ((Math.log10(av) - lx[0]!) / (lx[1]! - lx[0]!)) * (x1 - x0);
  const Y = (T: number) => y0 - ((Math.log10(T) - ly[0]!) / (ly[1]! - ly[0]!)) * (y0 - y1);
  const T = a ** 1.5;
  const onDrag = drag(x => setA(Math.min(40, Math.max(0.25, 10 ** (lx[0]! + ((x - x0) / (x1 - x0)) * (lx[1]! - lx[0]!))))));
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={`Planets on log-log axes of distance against year length, on one straight line. A new planet at ${fx(a, 2)} AU${hide ? "" : ` has a year of ${fx(T, 1)} years`}.`}>
      {[0.5, 1, 2, 5, 10, 20].map(v => <g key={v}><line x1={X(v)} y1={y1} x2={X(v)} y2={y0} className="b2grid" /><text x={X(v)} y={y0 + 16} textAnchor="middle" className="b2t">{v}</text></g>)}
      {[0.2, 1, 10, 100].map(v => <g key={v}><line x1={x0} y1={Y(v)} x2={x1} y2={Y(v)} className="b2grid" /><text x={x0 - 6} y={Y(v) + 4} textAnchor="end" className="b2t">{v}</text></g>)}
      <line x1={x0} y1={y0} x2={x1} y2={y0} className="b2axis" />
      <line x1={x0} y1={y1} x2={x0} y2={y0} className="b2axis" />
      <text x={x1} y={H - 2} textAnchor="end" className="b2t">distance, AU</text>
      <text x={x0 + 4} y={y1 + 10} className="b2t">year, Earth years</text>
      {!hide && <path d={path([[X(0.25), Y(0.125)], [X(40), Y(253)]])} className="b2curve sky" style={{ strokeWidth: 1.5, opacity: 0.7 }} />}
      {PLANETS.map(p => <g key={p.name}>
        <circle cx={X(p.a)} cy={Y(p.a ** 1.5)} r="4" className="b2dot sky" />
        {p.label && <text x={X(p.a) + (p.a > 20 ? -9 : 7)} y={Y(p.a ** 1.5) + (p.a > 20 ? 4 : 14)} textAnchor={p.a > 20 ? "end" : "start"} className="b2t">{p.name}</text>}
      </g>)}
      {marker && <>
        <line x1={x0} y1={Y(marker[0])} x2={x1} y2={Y(marker[0])} className="b2mark guess" />
        <text x={x0 + 6} y={Y(marker[0]) - 6} className="b2t">your guess: {fx(marker[0], 1)} years</text>
      </>}
      {!hide && <>
        <line x1={X(a)} y1={y0} x2={X(a)} y2={Y(T)} className="b2mark amber" />
        <line x1={x0} y1={Y(T)} x2={X(a)} y2={Y(T)} className="b2mark amber" />
      </>}
      <circle cx={X(a)} cy={hide ? y0 : Y(T)} r="7" className="b2dot amber" />
      <circle cx={X(a)} cy={hide ? y0 : Y(T)} r="22" className="b2hit" {...onDrag} />
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="New planet's distance" value={a} min={0.25} max={40} step={0.05} onChange={setA} format={v => `${fx(v, 2)} AU`} marks={[{ v: 4, label: "4 AU" }, { v: 9, label: "9 AU" }, { v: 16, label: "16 AU" }]} />}
      readouts={<>
        <Read label="Distance a" value={`${fx(a, 2)} AU`} tone="amber" />
        {!hide && <Read label="Year T = a^(3/2)" value={`${fx(T, 2)} years`} tone="amber" big />}
        {!hide && <Read label="T² and a³" value={`${fx(T * T, 1)} and ${fx(a ** 3, 1)}`} />}
        {!hide && <Read label="Line's slope" value="3/2" tone="sky" />}
      </>} />
  );
}

/** the eccentric anomaly for a mean anomaly M (Newton's method on Kepler's equation) */
function eccAnomaly(M: number, e: number) {
  let E = e > 0.8 ? Math.PI : M;
  for (let k = 0; k < 40; k++) { const d = (E - e * Math.sin(E) - M) / (1 - e * Math.cos(E)); E -= d; if (Math.abs(d) < 1e-12) break; }
  return E;
}

function AreasView({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), arrows = flag(props, "arrows");
  const [e, setE] = useState(num(props, "e", 0.5));
  const t = useClock(!quiet, 0.15);
  const W = 360, H = 250, N = 12;
  // a fixed: the ellipse fits; the Sun sits at the right-hand focus, so the near point is on the right
  const A = Math.min(160, 106 / Math.sqrt(1 - e * e)), B = A * Math.sqrt(1 - e * e), cx = 180, cy = 116;
  const fx0 = cx + A * e;
  const at = (M: number): [number, number] => { const E = eccAnomaly(M, e); return [cx + A * Math.cos(E), cy - B * Math.sin(E)]; };
  const lapS = 9, M = ((t / lapS) * 2 * Math.PI) % (2 * Math.PI), now = Math.floor((M / (2 * Math.PI)) * N);
  const wedges = Array.from({ length: N }, (_, k) => {
    const pts: [number, number][] = [[fx0, cy]];
    for (let j = 0; j <= 16; j++) pts.push(at(((k + j / 16) / N) * 2 * Math.PI));
    return <path key={k} d={`${path(pts)} Z`} className={k === now ? "b2tri on" : k % 2 ? "b2cone" : "b2cone past"} />;
  });
  const p = at(M);
  const vRatio = (1 + e) / (1 - e), L = 22;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`An ellipse of eccentricity ${fx(e, 2)} cut into ${N} wedges swept in equal times, all of equal area.`}>
      {wedges}
      <ellipse cx={cx} cy={cy} rx={A} ry={B} className="b2curve" style={{ strokeWidth: 1.5 }} />
      <circle cx={fx0} cy={cy} r="7" className="b2dot amber" />
      <circle cx={p[0]} cy={p[1]} r="5" className="b2dot sky" />
      {arrows && <>
        <Arrow x1={cx + A} y1={cy} x2={cx + A} y2={cy - L * Math.sqrt(vRatio) * 1.6} tone="pink" />
        <Arrow x1={cx - A} y1={cy} x2={cx - A} y2={cy + (L / Math.sqrt(vRatio)) * 1.6} tone="pink" />
        <text x={cx + A - 6} y={cy - L * Math.sqrt(vRatio) * 1.6 - 4} textAnchor="end" className="b2t pink">fast</text>
        <text x={cx - A + 6} y={cy + (L / Math.sqrt(vRatio)) * 1.6 + 14} className="b2t pink">slow</text>
      </>}
      <text x="10" y={H - 8} className="b2t">each wedge: 1/{N} of the year, the same area</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Eccentricity e" value={e} min={0} max={0.85} step={0.01} onChange={setE} format={v => fx(v, 2)} marks={[{ v: 0, label: "Circle" }, { v: 0.5, label: "1/2" }]} />}
      readouts={<>
        <Read label="Far over near" value={`${fx((1 + e) / (1 - e), 2)} ×`} />
        <Read label="Each wedge" value={`${fx(100 / N, 1)}% of the area`} tone="sky" />
        {!quiet && <Read label="v_near / v_far" value={`${fx(vRatio, 2)} ×`} tone="pink" big />}
      </>} />
  );
}
