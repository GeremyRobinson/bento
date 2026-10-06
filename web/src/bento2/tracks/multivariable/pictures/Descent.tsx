// The Best-choice finder (multivariable.md, tool 10): gradient descent with a step-size dial and a trail of steps (14);
// the narrow-valley race with momentum and Newton toggles (19); many balls at once with a string between two points,
// the convexity check (18); and noise with a temperature dial plus the 1,000-drop simulator (20).
import { useMemo, useRef, useState, type ReactNode } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, useClock, useSvgDrag } from "../../../ui/kit";
import { descend, eig2, flatSpots, grad, hess, seeded, type Box, type F2 } from "../maths";
import { FlatMap, mapper, nice, useLandscape } from "./common";

const W = 360, H = 250;
const inBox = (b: Box, x: number, y: number) => x >= b[0] && x <= b[1] && y >= b[2] && y <= b[3];
const Btn = ({ onClick, children, on }: { onClick: () => void; children: ReactNode; on?: boolean }) =>
  <button type="button" className="ctl" aria-pressed={on} onClick={onClick}>{children}</button>;

/** the largest curvature in view, for a safe step size */
function maxCurv(f: F2, box: Box) {
  let L = 1e-6;
  for (let i = 0; i <= 12; i++) for (let j = 0; j <= 12; j++) {
    const x = box[0] + ((box[1] - box[0]) * i) / 12, y = box[2] + ((box[3] - box[2]) * j) / 12, [a, c, b] = hess(f, x, y), [l1, l2] = eig2(a, b, c);
    L = Math.max(L, Math.abs(l1), Math.abs(l2));
  }
  return L;
}

export function DescentScene({ props }: SceneProps) {
  const L = useLandscape(props);
  const { f, box } = L;
  const quiet = flag(props, "quiet"), auto = flag(props, "auto");
  const typed = !!str<string>(props, "src", "");
  const [s, setS] = useState<[number, number]>([num(props, "sx", 0.5), num(props, "sy", 1)]);
  const [eta, setEta] = useState(num(props, "eta", typed ? 0.25 : 0.1));
  const [k, setK] = useState(0);
  const t = useClock(auto, 99);
  const target = typed ? 10 : 80;
  const shown = quiet ? 0 : Math.max(k, auto ? Math.min(target, Math.floor(t / (typed ? 0.35 : 0.08))) : 0);
  const pts = useMemo(() => descend(f, s[0], s[1], eta, shown), [f, s, eta, shown]);
  const { ref, drag } = useSvgDrag();
  const wide = box[1] - box[0] > box[3] - box[2];
  const m = mapper(box, wide ? [6, 4, 348, 174] : [70, 4, 220, 220]);
  const [x, y] = pts[pts.length - 1]!, off = !inBox(box, x, y);
  const [gx, gy] = grad(f, x, y);
  const visible = pts.filter(([a, b]) => inBox(box, a, b));
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`Gradient descent with step size ${nice(eta, 3)}: after ${shown} steps the ball is ${off ? "off the map" : `at (${nice(x)}, ${nice(y)})`}.`}>
      <FlatMap f={f} box={box} m={m} levels={14}>
        {visible.length > 1 && <path d={path(pts.map(([a, b]) => [m.X(Math.max(box[0], Math.min(box[1], a))), m.Y(Math.max(box[2], Math.min(box[3], b)))]))} className="mvtrail" />}
        {visible.map(([a, b], i) => <circle key={i} cx={m.X(a)} cy={m.Y(b)} r="3" className="mvstep" />)}
        <circle cx={m.X(s[0])} cy={m.Y(s[1])} r="5" className="mvball ghost" />
        {!off && <circle cx={m.X(x)} cy={m.Y(y)} r="7" className="mvball" />}
        <circle cx={m.X(s[0])} cy={m.Y(s[1])} r="18" className="b2hit" {...drag((px, py) => { setK(0); setS([Math.round(Math.max(box[0], Math.min(box[1], m.ix(px))) * 10) / 10, Math.round(Math.max(box[2], Math.min(box[3], m.iy(py))) * 10) / 10]); })} />
      </FlatMap>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <>
        <Slider label="Step size η" value={eta} min={typed ? 0.02 : 0.005} max={typed ? 1.2 : 0.3} step={typed ? 0.01 : 0.005} onChange={v => { setEta(v); }} format={v => nice(v, 3)} />
        <span className="b2marks">
          <Btn onClick={() => setK(Math.max(k, shown) + 1)}>Step</Btn>
          <Btn onClick={() => setK(Math.max(k, shown) + 10)}>Run 10</Btn>
          <Btn onClick={() => setK(0)}>Start over</Btn>
        </span>
      </>}
      readouts={<>
        <Read label="Steps" value={String(shown)} />
        <Read label="Ball at" value={off ? "off the map" : `(${fx(x, 3)}, ${fx(y, 3)})`} tone="trav" />
        {!off && <Read label="Height" value={fx(f(x, y), 3)} />}
        {!off && <Read label="|∇f| there" value={fx(Math.hypot(gx, gy), 3)} tone="pink" />}
      </>} />
  );
}

/** The narrow-valley race: plain descent at the best fixed step, momentum, and Newton (19). */
export function RaceScene({ props }: SceneProps) {
  const land = str<string>(props, "fn", "") === "land";
  const quiet = flag(props, "quiet");
  const [a, setA] = useState(num(props, "a", 1)), [b, setB] = useState(land ? 25 : num(props, "b", 3));
  const [mom, setMom] = useState(true), [newton, setNewton] = useState(!land);
  const f: F2 = useMemo(() => (land ? (x, y) => (x * x - 1) ** 2 + b * y * y + x / 4 : (x, y) => a * x * x + b * y * y), [land, a, b]);
  const box: Box = land ? [-0.2, 1.6, -0.9, 0.9] : [-2.4, 2.4, -1.2, 1.2];
  const start: [number, number] = land ? [0.3, 0.7] : [2, 1];
  // curvatures near the bottom set the best fixed step and the momentum
  const lo = land ? Math.min(12 * 0.97 * 0.97 - 4, 2 * b) : 2 * Math.min(a, b), hi = land ? Math.max(12 * 0.97 * 0.97 - 4, 2 * b) : 2 * Math.max(a, b);
  const eta = 2 / (lo + hi), kappa = hi / lo;
  const beta = ((Math.sqrt(kappa) - 1) / (Math.sqrt(kappa) + 1)) ** 2, etaM = 4 / (Math.sqrt(hi) + Math.sqrt(lo)) ** 2;
  const runs = useMemo(() => {
    const plain = descend(f, ...start, eta, 3000), fast = descend(f, ...start, etaM, 3000, { momentum: beta }), nt = land ? [] : descend(f, ...start, 1, 3, { newton: true });
    const bottom = plain[plain.length - 1]!, d0 = Math.hypot(start[0] - bottom[0], start[1] - bottom[1]);
    const count = (pts: [number, number][]) => { const i = pts.findIndex(([x, y]) => Math.hypot(x - bottom[0], y - bottom[1]) <= d0 / 1000); return i < 0 ? null : i; };
    return { plain, fast, nt, n: [count(plain), count(fast), land ? null : count(nt)] };
  }, [f, eta, etaM, beta, land]); // eslint-disable-line react-hooks/exhaustive-deps
  const t = useClock(!quiet, 99), shown = quiet ? 0 : Math.floor(t * 18);
  const m = mapper(box, [6, 4, 348, 174]);
  const draw = (pts: [number, number][], cls: string) => {
    const p = pts.slice(0, shown + 1);
    return <>
      <path d={path(p.map(([x, y]) => [m.X(x), m.Y(y)]))} className={`b2curve ${cls}`} style={{ strokeWidth: 1.6 }} />
      {(() => { const [x, y] = p[p.length - 1]!; return <circle cx={m.X(x)} cy={m.Y(y)} r="5" className={`mvdot ${cls}`} />; })()}
    </>;
  };
  const word = (n: number | null | undefined) => (n == null ? "more than 3,000" : n.toLocaleString("en-US"));
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`A valley with κ = ${nice(kappa, 1)}. Plain descent zig-zags${quiet ? "" : ` and needs ${word(runs.n[0])} steps`}.`}>
      <FlatMap f={f} box={box} m={m} levels={14}>
        {draw(runs.plain, "trav")}
        {mom && draw(runs.fast, "amber")}
        {newton && !land && draw(runs.nt, "sky")}
        <circle cx={m.X(start[0])} cy={m.Y(start[1])} r="5" className="mvball ghost" />
      </FlatMap>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {land ? <Slider label="Stretch y: f = (x² − 1)² + s·y² + x/4, s" value={b} min={1} max={25} step={1} onChange={setB} />
          : <>
            <Slider label="a (x²)" value={a} min={1} max={3} step={1} onChange={setA} />
            <Slider label="b (y²)" value={b} min={1} max={40} step={1} onChange={setB} marks={[{ v: 3, label: "3" }, { v: 30, label: "30" }]} />
          </>}
        <span className="b2marks">
          <Btn on={mom} onClick={() => setMom(v => !v)}>Momentum</Btn>
          {!land && <Btn on={newton} onClick={() => setNewton(v => !v)}>Newton step</Btn>}
        </span>
      </>}
      readouts={<>
        <Read label="κ" value={nice(kappa, 2)} />
        <Read label="Best fixed step η" value={nice(eta, 4)} />
        {!quiet && <Read label="Plain: steps to shrink 1,000×" value={word(runs.n[0]!)} tone="trav" big />}
        {!quiet && mom && <Read label="Momentum" value={word(runs.n[1]!)} tone="amber" />}
        {!quiet && newton && !land && <Read label="Newton" value={word(runs.n[2]!)} tone="sky" />}
      </>} />
  );
}

/** Many balls, and the string between two points: is there only one valley? (18) */
export function MultiStartScene({ props }: SceneProps) {
  const { f, box } = useLandscape(props);
  const quiet = flag(props, "quiet"), auto = flag(props, "auto");
  const [run, setRun] = useState(0);
  const t = useClock(auto || run > 0, 99);
  const wide = box[1] - box[0] > box[3] - box[2];
  const m = mapper(box, wide ? [6, 4, 348, 150] : [6, 4, 180, 180]);
  const strip: [number, number, number, number] = wide ? [26, 178, 324, 56] : [200, 40, 150, 140];
  const eta = 0.8 / maxCurv(f, box);
  const balls = useMemo(() => {
    const r = seeded(20 + run);
    return Array.from({ length: 20 }, () => descend(f, box[0] + r() * (box[1] - box[0]), box[2] + r() * (box[3] - box[2]), eta, 600));
  }, [f, box, eta, run]);
  const going = !quiet && (auto || run > 0);
  const step = going ? Math.min(600, Math.floor(t * 60)) : 0;
  const ends = balls.map(b => b[Math.min(step, b.length - 1)]!);
  const finals = balls.map(b => b[b.length - 1]!), spots: [number, number][] = [];
  for (const p of finals) if (!spots.some(q => Math.hypot(q[0] - p[0], q[1] - p[1]) < 0.05)) spots.push(p);
  // where the ground curves down in some direction: the convexity check
  const bad = useMemo(() => {
    const out: [number, number][] = [], n = 40, ny = Math.round((n * (box[3] - box[2])) / (box[1] - box[0]));
    for (let i = 0; i < n; i++) for (let j = 0; j < ny; j++) {
      const x = box[0] + ((box[1] - box[0]) * (i + 0.5)) / n, y = box[2] + ((box[3] - box[2]) * (j + 0.5)) / ny, [a, c, b] = hess(f, x, y);
      if (eig2(a, b, c)[0] < -1e-6) out.push([x, y]);
    }
    return { cells: out, w: (box[1] - box[0]) / n, h: (box[3] - box[2]) / ny };
  }, [f, box]);
  const [A, setA] = useState<[number, number]>([box[0] * 0.6, box[2] * 0.3]), [B, setB] = useState<[number, number]>([box[1] * 0.6, box[3] * 0.3]);
  const { ref, drag } = useSvgDrag();
  const ss = Array.from({ length: 81 }, (_, i) => i / 80);
  const ground = ss.map(s => f(A[0] + s * (B[0] - A[0]), A[1] + s * (B[1] - A[1]))), fa = ground[0]!, fb = ground[80]!;
  const string = ss.map(s => fa + s * (fb - fa));
  const z0 = Math.min(...ground, ...string), z1 = Math.max(...ground, ...string) + 1e-6;
  const SX = (s: number) => strip[0] + s * strip[2], SZ = (z: number) => strip[1] + strip[3] - ((z - z0) / (z1 - z0)) * strip[3];
  const dips = ss.some((_, i) => string[i]! < ground[i]! - 1e-9);
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`Twenty balls rolling downhill${going ? `; they stop at ${spots.length} ${spots.length === 1 ? "spot" : "spots"}` : ""}. ${quiet ? "" : ` The string from A to B ${dips ? "dips below" : "stays above"} the ground.`}`}>
      <FlatMap f={f} box={box} m={m} levels={12}>
        {!quiet && bad.cells.map(([x, y], i) => <rect key={i} x={m.X(x - bad.w / 2)} y={m.Y(y + bad.h / 2)} width={bad.w * m.s + 0.3} height={bad.h * m.s + 0.3} className="mvbasin pink" />)}
        {balls.map((b, i) => <g key={i}>
          {going && <path d={path(b.slice(0, step + 1).map(([x, y]) => [m.X(x), m.Y(y)]))} className="mvstream" />}
          <circle cx={m.X(ends[i]![0])} cy={m.Y(ends[i]![1])} r="3.5" className="mvball" />
        </g>)}
        {!quiet && <line x1={m.X(A[0])} y1={m.Y(A[1])} x2={m.X(B[0])} y2={m.Y(B[1])} className={`mvstring${dips ? " below" : ""}`} />}
        {!quiet && ([[A, setA, "A"], [B, setB, "B"]] as const).map(([p, set, lb]) => <g key={lb}>
          <circle cx={m.X(p[0])} cy={m.Y(p[1])} r="6" className="mvhandle amber" />
          <text x={m.X(p[0]) + 9} y={m.Y(p[1]) - 8} className="b2t amber">{lb}</text>
          <circle cx={m.X(p[0])} cy={m.Y(p[1])} r="18" className="b2hit" {...drag((x, y) => set([Math.max(box[0], Math.min(box[1], m.ix(x))), Math.max(box[2], Math.min(box[3], m.iy(y)))]))} />
        </g>)}
      </FlatMap>
      {!quiet && <>
        <rect x={strip[0]} y={strip[1]} width={strip[2]} height={strip[3]} className="mvframe" />
        <path d={path([...ss.map((s, i) => [SX(s), SZ(ground[i]!)] as [number, number]), [SX(1), strip[1] + strip[3]], [SX(0), strip[1] + strip[3]]]) + "Z"} className="mvground" />
        <path d={path(ss.map((s, i) => [SX(s), SZ(string[i]!)]))} className={`mvstring${dips ? " below" : ""}`} />
        <text x={strip[0]} y={strip[1] - 6} className="b2t">ground from A to B, and the string</text>
      </>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <span className="b2marks"><Btn onClick={() => setRun(r => r + 1)}>Drop 20 new balls</Btn></span>}
      readouts={<>
        {going && <Read label="Balls stop at" value={`${spots.length} ${spots.length === 1 ? "spot" : "spots"}`} tone="trav" big />}
        {!quiet && <Read label="The string" value={dips ? "dips below the ground" : "stays above the ground"} tone={dips ? "pink" : "amber"} />}
        {!quiet && <Read label="Convex everywhere in view?" value={bad.cells.length ? "No: it curves down in the pink patch" : "Yes"} tone={bad.cells.length ? "pink" : "sky"} />}
      </>} />
  );
}

/** Noise and restarts: one ball with a temperature, and a 1,000-drop simulator (20). */
export function AnnealScene({ props }: SceneProps) {
  const { f, box } = useLandscape(props);
  const quiet = flag(props, "quiet"), drops = flag(props, "drops");
  const [T, setT] = useState(num(props, "temp", 0.15));
  const [cool, setCool] = useState(false);
  const [start, setStart] = useState<[number, number]>([num(props, "sx", 0.6), num(props, "sy", 0.6)]);
  const [sim, setSim] = useState(drops);
  const t = useClock(true, 0);
  const eta = 0.5 / maxCurv(f, box);
  const flats = useMemo(() => flatSpots(f, box), [f, box]);
  const pits = flats.filter(p => p.kind === "pit").sort((a, b) => a.z - b.z), pass = flats.filter(p => p.kind === "pass").sort((a, b) => a.z - b.z)[0];
  // the ball: a gradient step plus a random kick of size √(2ηT), cooling if asked
  const st = useRef<{ x: number; y: number; T: number; trail: [number, number][]; last: number; rnd: () => number }>({ x: start[0], y: start[1], T, trail: [], last: 0, rnd: seeded(5) });
  const S = st.current;
  if (S.trail.length === 0) S.trail = [[S.x, S.y]];
  const frames = Math.min(8, Math.max(0, Math.floor((t - S.last) * 60)));
  if (frames > 0) {
    S.last = t;
    for (let k = 0; k < frames; k++) {
      const [gx, gy] = grad(f, S.x, S.y), u1 = Math.max(1e-12, S.rnd()), u2 = S.rnd(), r = Math.sqrt(-2 * Math.log(u1));
      const kick = Math.sqrt(2 * eta * Math.max(0, S.T)) * 3;
      S.x = Math.max(box[0], Math.min(box[1], S.x - eta * gx + kick * r * Math.cos(2 * Math.PI * u2)));
      S.y = Math.max(box[2], Math.min(box[3], S.y - eta * gy + kick * r * Math.sin(2 * Math.PI * u2)));
      if (cool) S.T *= 0.997; else S.T = T;
      S.trail.push([S.x, S.y]);
    }
    if (S.trail.length > 90) S.trail = S.trail.slice(-90);
  }
  const restart = (p: [number, number]) => { setStart(p); st.current = { ...S, x: p[0], y: p[1], T, trail: [p], last: t }; };
  // the simulator: 1,000 drops, each rolled down −∇f; which bottom does each reach?
  const result = useMemo(() => {
    if (!sim || !pits.length) return null;
    const r = seeded(1000), lowest = pits[0]!, out: { x: number; y: number; low: boolean }[] = [];
    for (let i = 0; i < 1000; i++) {
      const x = box[0] + r() * (box[1] - box[0]), y = box[2] + r() * (box[3] - box[2]), run = descend(f, x, y, eta * 1.6, 400), [ex, ey] = run[run.length - 1]!;
      const near = pits.reduce((bst, p) => (Math.hypot(p.x - ex, p.y - ey) < Math.hypot(bst.x - ex, bst.y - ey) ? p : bst), lowest);
      out.push({ x, y, low: near === lowest });
    }
    return out;
  }, [sim, f, box, eta, pits]);
  const share = result ? result.filter(d => d.low).length / result.length : 0;
  const { ref, drag } = useSvgDrag();
  const wide = box[1] - box[0] > box[3] - box[2];
  const m = mapper(box, wide ? [6, 4, 348, 174] : [70, 4, 220, 220]);
  const here = pits.length ? pits.reduce((bst, p) => (Math.hypot(p.x - S.x, p.y - S.y) < Math.hypot(bst.x - S.x, bst.y - S.y) ? p : bst), pits[0]!) : null;
  const barrier = pass && here ? pass.z - here.z : null;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`A ball at temperature ${nice(S.T, 3)}${result && !quiet ? `; of 1,000 drops, ${Math.round(share * 1000)} end in the lowest valley` : ""}.`}>
      <FlatMap f={f} box={box} m={m} levels={14}>
        {result && !quiet && result.map((d, i) => <circle key={i} cx={m.X(d.x)} cy={m.Y(d.y)} r="1.8" className={`mvdot ${d.low ? "sky" : "pink"}`} />)}
        <path d={path(S.trail.map(([x, y]) => [m.X(x), m.Y(y)]))} className="mvtrail" style={{ opacity: 0.6 }} />
        {pass && <g transform={`translate(${m.X(pass.x)},${m.Y(pass.y)})`}><path d="M-6,-6L6,6M-6,6L6,-6" className="mvcut amber" /></g>}
        <circle cx={m.X(S.x)} cy={m.Y(S.y)} r="7" className="mvball" />
        <rect x={m.frame[0]} y={m.frame[1]} width={m.frame[2]} height={m.frame[3]} className="b2hit" {...drag((x, y) => restart([m.ix(x), m.iy(y)]))} />
      </FlatMap>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Temperature T" value={T} min={0} max={1} step={0.01} onChange={v => { setT(v); S.T = v; }} format={v => nice(v)} />
        <span className="b2marks">
          <Btn on={cool} onClick={() => setCool(c => !c)}>Cool slowly</Btn>
          <Btn on={sim} onClick={() => setSim(v => !v)}>Drop 1,000 balls</Btn>
        </span>
      </>}
      readouts={<>
        <Read label="Temperature now" value={nice(S.T, 3)} tone="amber" />
        {barrier != null && <Read label="Pass above this valley" value={fx(barrier, 3)} />}
        {barrier != null && <Read label="Chance a hop over it is kept" value={S.T > 0 ? fx(Math.exp(-barrier / S.T), 3) : "0"} tone="amber" />}
        {result && !quiet && <Read label="Drops ending in the lowest valley" value={`${(share * 100).toFixed(1)}%`} tone="sky" big />}
      </>} />
  );
}
