// ★ The orbit sandbox (orbits.md, "New for Development" 1). One picture, five ways in:
//   launch (the tool's default): pick a body, drag the launch arrow (speed and direction), and read the conic: a, e, the
//     near and far distances, the energy's sign and the type. An energy bar for b2-or-06, time warp, a guess marker for
//     the far point (b2-or-04).
//   pull: a probe you drag away from Earth, its gravity arrow and the field around it (b2-or-01).
//   pair: two circular orbits, r and k·r, side by side with speed arrows; or one real orbit at height h (b2-or-02).
//   integrator: the circle stepped by Euler or symplectic Euler, with an energy graph (b2-or-07).
//   transfer: the Mars transfer flown by symplectic Euler at a step in hours, with its worst energy error (b2-or-07's Use it).
import { useEffect, useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle, useClock, useSvgDrag, useTween } from "../../../ui/kit";
import {
  AU, MU_AU, MU_E, MU_MARS, MU_SUN, PLANET_AU, R_KM, R_MARS_KM, conicOf, energy, gAt, period, propagator, step, transferDrift, vCirc,
  type Method, type State,
} from "../maths";
import { Arrow, conicPath, dur, km } from "./parts";

export function SandboxScene(sp: SceneProps) {
  const mode = str<string>(sp.props, "mode", "launch");
  if (mode === "pull") return <PullView {...sp} />;
  if (mode === "pair") return <PairView {...sp} />;
  if (mode === "integrator") return <IntegratorView {...sp} />;
  if (mode === "transfer") return <TransferView {...sp} />;
  return <LaunchView {...sp} />;
}

/* ---------------------------------------------------------------- pull ---------------------------------------------------------------- */

function PullView({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), from = num(props, "from", 0);
  const [d, setD] = useState(num(props, "d", 1.6));
  const [ang, setAng] = useState(-0.35);
  const [moved, setMoved] = useState(false);
  // the reveal slides the probe out from `from` to `d`, so the arrow can be seen shrinking
  const t = useClock(from > 0 && !moved, 2);
  const k = Math.min(1, Math.max(0, (t - 0.3) / 1.4)), ease = k < 0.5 ? 2 * k * k : 1 - (-2 * k + 2) ** 2 / 2;
  const dd = from > 0 && !moved ? from + (d - from) * ease : d;
  const { ref, drag } = useSvgDrag();
  const W = 360, H = 260, cx = 70, cy = 136, R = 34, g0 = 84;
  const g = (r: number) => gAt((r - 1) * R_KM);
  const px = cx + dd * R * Math.cos(ang), py = cy + dd * R * Math.sin(ang);
  const arrowLen = (r: number) => (g(r) / 9.81) * g0;
  const field = [];
  for (const rr of [1.6, 2.6, 4, 5.6, 7.4]) for (let j = 0; j < 12; j++) {
    const a = (j / 12) * 2 * Math.PI + rr * 0.4, x = cx + rr * R * Math.cos(a), y = cy + rr * R * Math.sin(a);
    if (x < 6 || x > W - 6 || y < 6 || y > H - 6) continue;
    const L = Math.max(4, arrowLen(rr) * 0.45);
    field.push(<line key={`${rr}-${j}`} x1={x} y1={y} x2={x - L * Math.cos(a)} y2={y - L * Math.sin(a)} className="b2grid strong" />);
  }
  const onDrag = drag((x, y) => {
    setMoved(true);
    setD(Math.min(8, Math.max(1.02, Math.hypot(x - cx, y - cy) / R)));
    setAng(Math.atan2(y - cy, x - cx));
  });
  const ghost = from > 0 && Math.abs(dd - from) > 0.05;
  const gx = cx + from * R * Math.cos(ang), gy = cy + from * R * Math.sin(ang);
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={`A probe ${fx(dd, 2)} Earth radii from Earth's center${quiet ? "" : `, pulled at ${fx(g(dd), 2)} meters per second squared`}.`}>
      {field}
      <circle cx={cx} cy={cy} r={R} className="b2earth" />
      <text x={cx} y={cy + 4} textAnchor="middle" className="b2t sky">Earth</text>
      <line x1={cx} y1={cy} x2={px} y2={py} className="b2orbit" />
      {ghost && <>
        <Arrow x1={gx} y1={gy} x2={gx - arrowLen(from) * Math.cos(ang)} y2={gy - arrowLen(from) * Math.sin(ang)} tone="amber" />
        <circle cx={gx} cy={gy} r="5" className="b2dot amber" />
        <text x={gx} y={gy - 12} textAnchor="middle" className="b2t amber">{fx(g(from), 2)}</text>
      </>}
      <Arrow x1={px} y1={py} x2={px - arrowLen(dd) * Math.cos(ang)} y2={py - arrowLen(dd) * Math.sin(ang)} tone="sky" />
      <circle cx={px} cy={py} r="7" className="b2dot sky" />
      {!quiet && <text x={px} y={py - 13} textAnchor="middle" className="b2t sky">{fx(g(dd), 2)} m/s²</text>}
      <circle cx={px} cy={py} r="22" className="b2hit" {...onDrag} />
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label={quiet ? "Height above the ground" : "Distance from Earth's center"} value={d} min={1} max={8} step={0.01} onChange={v => { setMoved(true); setD(v); }} format={v => `${km((quiet ? v - 1 : v) * R_KM)} km`}
        marks={[{ v: 1, label: "Ground" }, { v: 1 + 400 / R_KM, label: "Station" }, { v: 2, label: "2 R⊕" }, { v: 4, label: "4 R⊕" }]} />}
      readouts={<>
        {!quiet && <Read label="Distance r" value={`${km(dd * R_KM)} km`} />}
        <Read label="Height" value={`${km((dd - 1) * R_KM)} km`} />
        {!quiet && <Read label="Pull g" value={`${fx(g(dd), 2)} m/s²`} tone="sky" big />}
        {!quiet && <Read label="Of the ground's" value={`${Math.round((100 * g(dd)) / 9.81)}%`} />}
        {ghost && !quiet && <Read label={`Distance × ${fx(dd / from, 2)}`} value={`pull × 1/${fx((dd / from) ** 2, 2)}`} tone="amber" />}
      </>}
    />
  );
}

/* ---------------------------------------------------------------- pair ---------------------------------------------------------------- */

function PairView({ props }: SceneProps) {
  const quiet = flag(props, "quiet");
  const single = typeof props.h === "number";
  const [k, setK] = useState(num(props, "k", 4));
  const [h, setH] = useState(num(props, "h", 300));
  // still while a guess or a problem is open, so the lap times give nothing away
  const t = useClock(!quiet, 0.6);
  const W = 360, H = 260, cx = 180, cy = 130;
  if (single) {
    const r = R_KM + h, v = vCirc(MU_E, r * 1000) / 1000, T = period(MU_E, r * 1000);
    const s = 112 / r, ang = (t * 2 * Math.PI) / (2.4 * (T / period(MU_E, (R_KM + 300) * 1000)) ** (1 / 3));
    const sx = cx + r * s * Math.cos(ang), sy = cy - r * s * Math.sin(ang), L = 9 * v;
    const svg = (
      <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A circular orbit ${km(h)} km above Earth${quiet ? "" : `, moving at ${fx(v, 2)} kilometers per second`}.`}>
        <circle cx={cx} cy={cy} r={R_KM * s} className="b2earth" />
        <circle cx={cx} cy={cy} r={r * s} className="b2orbit" />
        <Arrow x1={sx} y1={sy} x2={sx - L * Math.sin(ang)} y2={sy - L * Math.cos(ang)} tone="sky" />
        <circle cx={sx} cy={sy} r="6" className="b2sat" />
        <text x="12" y="22" className="b2t">drawn to scale</text>
      </svg>
    );
    return (
      <Scene svg={svg}
        controls={<Slider label="Height above Earth" value={h} min={150} max={36000} step={50} onChange={setH} format={x => `${km(x)} km`}
          marks={[{ v: 300, label: "Parking" }, { v: 400, label: "Station" }, { v: 20200, label: "GPS" }, { v: 35800, label: "Geo" }]} />}
        readouts={<>
          {!quiet && <Read label="Radius r" value={`${km(r)} km`} />}
          {!quiet && <Read label="Speed √(μ/r)" value={`${fx(v, 2)} km/s`} tone="sky" big />}
          {!quiet && <Read label="One lap" value={dur(T)} />}
        </>} />
    );
  }
  const outer = 112, inner = outer / k, w0 = 2.2;
  const a1 = t * w0, a2 = t * w0 * k ** -1.5;
  const p1 = [cx + inner * Math.cos(a1), cy - inner * Math.sin(a1)], p2 = [cx + outer * Math.cos(a2), cy - outer * Math.sin(a2)];
  const L = 34;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Two circular orbits, one ${fx(k, 1)} times as wide as the other${quiet ? "" : `; the outer one moves ${fx(1 / Math.sqrt(k), 2)} times as fast`}.`}>
      <circle cx={cx} cy={cy} r="5" className="b2dot" />
      <circle cx={cx} cy={cy} r={inner} className="b2orbit" />
      <circle cx={cx} cy={cy} r={outer} className="b2orbit" />
      <Arrow x1={p1[0]!} y1={p1[1]!} x2={p1[0]! - L * Math.sin(a1)} y2={p1[1]! - L * Math.cos(a1)} tone="sky" />
      <circle cx={p1[0]} cy={p1[1]} r="5" className="b2dot sky" />
      {!quiet && <Arrow x1={p2[0]!} y1={p2[1]!} x2={p2[0]! - (L / Math.sqrt(k)) * Math.sin(a2)} y2={p2[1]! - (L / Math.sqrt(k)) * Math.cos(a2)} tone="pink" />}
      <circle cx={p2[0]} cy={p2[1]} r="5" className="b2dot pink" />
      <text x="12" y="22" className="b2t sky">r</text>
      <text x="12" y="40" className="b2t pink">{fx(k, 1).replace(/\.0$/, "")}r</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Outer orbit's radius" value={k} min={1.5} max={25} step={0.5} onChange={setK} format={x => `${fx(x, 1)} × r`} marks={[{ v: 4, label: "× 4" }, { v: 9, label: "× 9" }, { v: 16, label: "× 16" }]} />}
      readouts={<>
        <Read label="Inner speed" value="v" tone="sky" />
        {!quiet && <Read label="Outer speed" value={`${fx(1 / Math.sqrt(k), 2)} v`} tone="pink" big />}
        {!quiet && <Read label="Outer lap takes" value={`${fx(k ** 1.5, 1)} × as long`} />}
      </>} />
  );
}

/* ---------------------------------------------------------------- launch ---------------------------------------------------------------- */

const BODIES = {
  toy: { name: "Toy planet", r0: 1, unit: "", mu: 1, scale: 1, vUnit: "" },
  earth: { name: "Earth", r0: R_KM + 300, unit: "km", mu: MU_E, scale: 1000, vUnit: "km/s" },
  mars: { name: "Mars", r0: R_MARS_KM + 400, unit: "km", mu: MU_MARS, scale: 1000, vUnit: "km/s" },
  sun: { name: "Sun", r0: 1, unit: "AU", mu: MU_SUN, scale: AU, vUnit: "km/s" },
} as const;
type BodyId = keyof typeof BODIES;
const KIND_NAME = { circle: "Circle", ellipse: "Ellipse", parabola: "Parabola", hyperbola: "Hyperbola" };

function LaunchView({ props, marker }: SceneProps) {
  const hide = flag(props, "hide"), quiet = flag(props, "quiet"), showE = flag(props, "energy"), sweep = flag(props, "sweep");
  const [body, setBody] = useState<BodyId>(str(props, "body", typeof props.mode === "string" ? "toy" : "earth") as BodyId);
  const [speed, setSpeed] = useState(num(props, "speed", 1.15));
  const [tilt, setTilt] = useState(0);
  const [warp, setWarp] = useState(1);
  // the body only sets the units and the drawn size; the shape depends on the speed ratio alone
  const [touched, setTouched] = useState(false);
  // the escape reveal slides the speed up from the circle until the orbit opens
  const [goal, setGoal] = useState(sweep ? 1 : speed);
  useEffect(() => { if (sweep) { const id = setTimeout(() => setGoal(speed), 400); return () => clearTimeout(id); } }, [sweep, speed]);
  const tw = useTween(goal, 2200);
  const s = sweep && !touched ? tw : speed;
  const B = BODIES[body];
  const W = 360, H = 260, cx = showE ? 236 : 214, cy = 130, r0 = 50;
  const Rp = body === "earth" ? R_KM / B.r0 : body === "mars" ? R_MARS_KM / B.r0 : body === "sun" ? 0.06 : 0.34;
  // the launch: at (1, 0) in units of the start distance, speed s × circular speed, tilted from sideways by `tilt`
  const vx = -s * Math.sin(tilt), vy = s * Math.cos(tilt);
  const c = conicOf(1, 1, 0, vx, vy);
  const prop = useMemo(() => propagator(1, 1, 0, vx, vy), [vx, vy]);
  const t = useClock(!hide, 0);
  // the ship flies its path, the time warp sets how fast; closed orbits loop each lap, open ones restart after a while
  const loop = prop && Number.isFinite(prop.period) ? prop.period : 9;
  const tt = ((t * 1.3 * warp) % loop + loop) % loop;
  const ship = prop?.pos(tt);
  const crash = c.near < Rp;
  const shipShown = ship && ship.r >= Rp && ship.r < 7;
  const { ref, drag } = useSvgDrag();
  const sx0 = cx + r0, sy0 = cy, vs = 46;
  const tipX = sx0 + vx * vs, tipY = sy0 - vy * vs;
  const onTip = drag((x, y) => {
    setTouched(true);
    const dx = (x - sx0) / vs, dy = -(y - sy0) / vs;
    setSpeed(Math.min(1.8, Math.max(0.3, Math.hypot(dx, dy))));
    setTilt(Math.max(-1.2, Math.min(1.2, Math.atan2(-dx, dy))));
  });
  const v0 = vCirc(B.mu, B.r0 * B.scale);
  const toUnits = (x: number) => x * B.r0;
  const dist = (x: number) => (!Number.isFinite(x) ? "never" : body === "toy" ? fx(toUnits(x), 2) : body === "sun" ? `${fx(toUnits(x), 3)} AU` : `${km(toUnits(x))} km`);
  const eps = s * s / 2 - 1, kind = KIND_NAME[c.kind];
  const typeText = crash ? `${kind}, hits the ${body === "sun" ? "Sun" : "planet"}` : kind;
  // energy bars, per kilogram, in units of μ/r at the start: kinetic s²/2 up, potential −1 down, total
  const bars = showE && !quiet && (() => {
    const z = 150, u = 50, bar = (x: number, v: number, tone: string, label: string, val: boolean) => (
      <g className={tone}>
        <rect x={x} y={v >= 0 ? z - v * u : z} width="18" height={Math.max(1.5, Math.abs(v) * u)} rx="3" className="b2bar" />
        <text x={x + 9} y={H - 8} textAnchor="middle" className="b2t">{label}</text>
        {val && <text x={x + 9} y={v >= 0 ? z - v * u - 6 : z + Math.abs(v) * u + 15} textAnchor="middle" className="b2t">{fx(v, 2)}</text>}
      </g>
    );
    return (
      <g>
        <line x1="8" y1={z} x2="104" y2={z} className="b2axis" />
        {bar(12, s * s / 2, "sky", "KE", !quiet)}
        {bar(44, -1, "pink", "PE", !quiet)}
        {bar(76, eps, "amber", "total", !quiet)}
      </g>
    );
  })();
  const farX = marker ? cx - marker[0] * r0 : 0;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={hide ? "A ship about to launch sideways, 10% faster than circular speed." : `A launch at ${fx(s, 2)} times circular speed: ${typeText.toLowerCase()}${quiet ? "" : `, eccentricity ${fx(c.e, 2)}`}.`}>
      {bars}
      {(hide || marker) && <line x1="4" y1={cy} x2={W - 4} y2={cy} className="b2grid strong" />}
      {!hide && <circle cx={cx} cy={cy} r={r0} className="b2orbit" />}
      {!hide && <path d={conicPath(c, cx, cy, r0, 8)} className="b2curve amber" />}
      {!hide && c.e < 1 && !crash && Number.isFinite(c.far) && <>
        <circle cx={cx + c.far * r0 * Math.cos(c.w + Math.PI)} cy={cy - c.far * r0 * Math.sin(c.w + Math.PI)} r="4" className="b2dot pink" />
        {!quiet && <text x={cx + c.far * r0 * Math.cos(c.w + Math.PI)} y={cy - c.far * r0 * Math.sin(c.w + Math.PI) - 10} textAnchor="middle" className="b2t pink">far</text>}
      </>}
      <circle cx={cx} cy={cy} r={Rp * r0} className="b2earth" />
      {marker && <>
        <line x1={farX} y1={cy - 16} x2={farX} y2={cy + 16} className="b2mark guess" />
        <circle cx={farX} cy={cy} r="7" className="b2mark guess round" />
        <text x={farX} y={cy - 22} textAnchor="middle" className="b2t">your far point</text>
      </>}
      {shipShown && <circle cx={cx + ship!.x * r0} cy={cy - ship!.y * r0} r="5" className="b2sat" />}
      <circle cx={sx0} cy={sy0} r="4" className="b2dot" />
      <Arrow x1={sx0} y1={sy0} x2={tipX} y2={tipY} tone="sky" />
      {!hide && <circle cx={tipX} cy={tipY} r="7" className="b2handle" />}
      {!hide && <circle cx={tipX} cy={tipY} r="22" className="b2hit" {...onTip} />}
      {!hide && <text x={tipX + 10} y={tipY - 6} className="b2t sky">launch</text>}
    </svg>
  );
  const vReal = (s * v0) / 1000;
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Launch speed" value={s} min={0.3} max={1.8} step={0.005} onChange={v => { setTouched(true); setSpeed(v); }}
          format={x => `${fx(x, 3)} × circular`} marks={[{ v: 1, label: "Circle" }, { v: Math.SQRT2, label: "Escape" }]} />
        {!hide && <Toggle label="Time warp" value={String(warp)} onChange={v => setWarp(Number(v))} options={["0.5", "1", "4"].map(v => ({ v, label: `× ${v}` }))} />}
        {!hide && <Toggle label="Central body" value={body} onChange={setBody} options={(Object.keys(BODIES) as BodyId[]).map(b => ({ v: b, label: BODIES[b].name }))} />}
      </>}
      readouts={hide ? <Read label="Start distance" value={dist(1)} /> : <>
        <Read label="Type" value={typeText} tone="amber" big />
        {!quiet && <Read label="a" value={c.e >= 0.995 ? (c.kind === "parabola" ? "infinite" : dist(c.a)) : dist(c.a)} />}
        {!quiet && <Read label="e" value={fx(c.e, 3)} />}
        <Read label="Near" value={dist(c.near)} />
        {!quiet && <Read label="Far" value={dist(c.far)} tone="pink" />}
        {!quiet && <Read label="Energy" value={Math.abs(eps) < 2e-3 ? "zero" : eps < 0 ? "negative: stays" : "positive: leaves"} />}
        {body !== "toy" && <Read label="Launch speed" value={`${fx(vReal, 2)} ${B.vUnit}`} tone="sky" />}
      </>} />
  );
}

/* ---------------------------------------------------------------- integrator ---------------------------------------------------------------- */

function runOrbit(h: number, m: Method, laps: number) {
  let s: State = { x: 1, y: 0, vx: 0, vy: 1 };
  const pts: [number, number][] = [[1, 0]], es: number[] = [energy(s, 1)], ts: number[] = [0];
  const n = Math.ceil((laps * 2 * Math.PI) / h), every = Math.max(1, Math.floor(n / 1400));
  for (let i = 1; i <= n; i++) {
    s = step(s, h, 1, m);
    if (i % every === 0 || i === n) { pts.push([s.x, s.y]); es.push(energy(s, 1)); ts.push((i * h) / (2 * Math.PI)); }
    if (Math.hypot(s.x, s.y) > 12) { pts.push([s.x, s.y]); es.push(energy(s, 1)); ts.push((i * h) / (2 * Math.PI)); break; }
  }
  return { pts, es, ts, end: s };
}

function IntegratorView({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), run = flag(props, "run");
  const [m, setM] = useState<Method>(str(props, "method", "euler") as Method);
  const [h, setH] = useState(num(props, "hstep", 0.1));
  const laps = 100;
  const orbit = useMemo(() => runOrbit(h, m, laps), [h, m]);
  // the run draws itself over a few seconds, so the spiral (or the steady loop) can be seen forming
  const t = useClock(!quiet, 99);
  const k = quiet ? 0 : Math.min(1, t / 6);
  const shown = Math.max(1, Math.round(k * (orbit.pts.length - 1)));
  // the view zooms out as the run grows, so the widest point drawn so far always fits
  const pts = orbit.pts.slice(0, shown + 1);
  const reach = Math.max(1, ...pts.map(p => Math.hypot(p[0], p[1])));
  const W = 360, H = 200, cx = 180, cy = 100, s = Math.min(36, 90 / reach);
  const last = pts[pts.length - 1]!;
  const lastR = Math.hypot(last[0], last[1]);
  const view = (p: [number, number]): [number, number] => [cx + p[0] * s, cy - p[1] * s];
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A circular orbit stepped by ${m === "euler" ? "Euler" : "symplectic Euler"} with step ${fx(h, 2)}${quiet ? "" : `; after the run it is ${fx(lastR, 2)} from the center`}.`}>
      <circle cx={cx} cy={cy} r="6" className="b2dot" />
      <circle cx={cx} cy={cy} r={s} className="b2orbit" />
      {!quiet && <path d={path(pts.map(view))} className={`b2curve ${m === "euler" ? "pink" : "sky"}`} style={{ strokeWidth: 1 }} />}
      <circle cx={view(last)[0]} cy={view(last)[1]} r="5" className="b2sat" />
      {quiet && <Arrow x1={cx + s} y1={cy} x2={cx + s} y2={cy - 30} tone="sky" />}
      <text x="10" y="20" className="b2t">dashed: the start circle, r = 1</text>
    </svg>
  );
  // the energy along the run: Euler's climbs; symplectic Euler's wobbles around the start
  const es = orbit.es.slice(0, shown + 1);
  const gw = 340, gh = 90, lo = -0.6, hi = 0.1, X = (i: number) => 10 + (i / Math.max(1, orbit.es.length - 1)) * (gw - 20), Y = (e: number) => gh - 8 - ((Math.min(hi, Math.max(lo, e)) - lo) / (hi - lo)) * (gh - 16);
  const graph = !quiet && (
    <svg viewBox={`0 0 ${gw} ${gh}`} className="b2pic" role="img" aria-label={`Energy over the run, from −0.5 to ${fx(es[es.length - 1]!, 3)}.`} style={{ maxHeight: 92 }}>
      <line x1="10" y1={Y(-0.5)} x2={gw - 10} y2={Y(-0.5)} className="b2grid strong" />
      <line x1="10" y1={Y(0)} x2={gw - 10} y2={Y(0)} className="b2grid" />
      <path d={path(es.map((e, i) => [X(i), Y(e)]))} className={`b2curve ${m === "euler" ? "pink" : "sky"}`} style={{ strokeWidth: 1.5 }} />
      <text x="14" y={Y(-0.5) - 5} className="b2t">energy −0.5</text>
      <text x={gw - 14} y={Y(0) - 5} textAnchor="end" className="b2t">0: escapes</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Toggle label="Stepper" value={m} onChange={setM} options={[{ v: "euler", label: "Euler" }, { v: "symplectic", label: "Symplectic Euler" }]} />
        <Slider label="Step h" value={h} min={0.01} max={0.5} step={0.01} onChange={setH} format={x => fx(x, 2)} marks={[{ v: 0.05, label: "0.05" }, { v: 0.1, label: "0.1" }, { v: 0.25, label: "1/4" }, { v: 0.5, label: "1/2" }]} />
      </>}
      readouts={quiet ? <Read label="Start" value="r = (1, 0), v = (0, 1), energy −0.5" /> : <>
        <Read label="Distance now" value={fx(lastR, 2)} tone={m === "euler" ? "pink" : "sky"} big />
        <Read label="Energy now" value={fx(es[es.length - 1]!, 3)} />
        <Read label="Orbits so far" value={lastR > 11.9 ? `${fx(orbit.ts[shown] ?? 0, 0)}, then it flew off` : `${fx(orbit.ts[shown] ?? 0, 0)} of ${laps}`} />
        {run && <Read label="Started at" value="r = 1, energy −0.5" />}
      </>}
      foot={graph || undefined} />
  );
}

/* ---------------------------------------------------------------- transfer ---------------------------------------------------------------- */

function TransferView({ props }: SceneProps) {
  const [hours, setHours] = useState(num(props, "hours", 12));
  const drift = useMemo(() => transferDrift(hours), [hours]);
  const pts = useMemo(() => {
    const h = hours / 24 / 365.25, at = (1 + PLANET_AU.Mars) / 2, tEnd = 0.5 * at ** 1.5;
    let s: State = { x: 1, y: 0, vx: 0, vy: Math.sqrt(MU_AU * (2 - 1 / at)) };
    const out: [number, number][] = [[1, 0]];
    for (let t = 0; t < tEnd; t += h) { s = step(s, h, MU_AU, "symplectic"); out.push([s.x, s.y]); }
    return out;
  }, [hours]);
  const W = 360, H = 240, cx = 196, cy = 120, sc = 66;
  const ok = drift <= 0.001;
  const v = (p: [number, number]): [number, number] => [cx + p[0] * sc, cy - p[1] * sc];
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`The Mars transfer stepped every ${hours} hours; the worst energy error is ${fx(drift * 100, 3)} percent.`}>
      <circle cx={cx} cy={cy} r="7" className="b2dot amber" />
      <circle cx={cx} cy={cy} r={sc} className="b2orbit" />
      <circle cx={cx} cy={cy} r={sc * PLANET_AU.Mars} className="b2orbit" />
      <path d={path(pts.map(v))} className="b2curve sky" style={{ strokeWidth: 1.5 }} />
      {pts.filter((_, i) => i % Math.max(1, Math.round(240 / hours)) === 0).map((p, i) => <circle key={i} cx={v(p)[0]} cy={v(p)[1]} r="1.8" className="b2dot sky" />)}
      <text x={cx + sc + 6} y={cy + 16} className="b2t sky">Earth's orbit</text>
      <text x={cx - sc * PLANET_AU.Mars} y={cy - sc * 1.15} className="b2t">Mars's orbit</text>
      <text x="10" y="20" className="b2t">dots every 10 days</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Step" value={hours} min={1} max={48} step={1} onChange={setHours} format={x => `${x} ${x === 1 ? "hour" : "hours"}`} />}
      readouts={<>
        <Read label="Steps for 259 days" value={km((259 * 24) / hours)} />
        <Read label="Worst energy error" value={`${fx(drift * 100, 3)}%`} tone="sky" big />
        <Read label="Within 0.1%?" value={ok ? "yes" : "no, take a smaller step"} />
      </>} />
  );
}

