// Noisy steps (14's Play and Guess): the loss-landscape ball in a long, narrow valley, where every step uses a random
// batch of B examples, so its gradient wobbles around the true one. Below, twelve batch gradients at one spot: their
// spread circle shrinks like 1/√B as the batch grows. Plain SGD, momentum and Adam race from the same start with the
// same noise, so the only difference is the rule.
import { useEffect, useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { ArrowHead, fx, Read, Scene, Slider, Toggle, useClock } from "../../../ui/kit";
import { gauss, seeded } from "../digits";
import { lin } from "./common";

type Opt = "sgd" | "momentum" | "adam";
const STEPS = 60, SIGMA = 3, SPOT: [number, number] = [3, 0.3];
const grad = (x: number, y: number): [number, number] => [x, 20 * y];
const loss = (x: number, y: number) => 0.5 * (x * x + 20 * y * y);

/** a run of STEPS steps from (−4.5, 1.2) with batch noise σ/√B on each gradient entry */
export function runBatch(opt: Opt, B: number, seed = 9): [number, number][] {
  const r = seeded(seed), s = SIGMA / Math.sqrt(B);
  let x = -4.5, y = 1.2, vx = 0, vy = 0, mx = 0, my = 0, ax = 0, ay = 0;
  const out: [number, number][] = [[x, y]];
  for (let t = 1; t <= STEPS; t++) {
    const [gx0, gy0] = grad(x, y), gx = gx0 + s * gauss(r), gy = gy0 + s * gauss(r);
    if (opt === "sgd") { x -= 0.09 * gx; y -= 0.09 * gy; }
    else if (opt === "momentum") { vx = 0.8 * vx + gx; vy = 0.8 * vy + gy; x -= 0.03 * vx; y -= 0.03 * vy; }
    else {
      mx = 0.9 * mx + 0.1 * gx; my = 0.9 * my + 0.1 * gy; ax = 0.999 * ax + 0.001 * gx * gx; ay = 0.999 * ay + 0.001 * gy * gy;
      const c1 = 1 - 0.9 ** t, c2 = 1 - 0.999 ** t;
      x -= (0.25 * (mx / c1)) / (Math.sqrt(ax / c2) + 1e-8); y -= (0.25 * (my / c1)) / (Math.sqrt(ay / c2) + 1e-8);
    }
    out.push([x, y]);
  }
  return out;
}

/** the three paths drawing in, step by step (12 a second), the chosen rule on top */
function Paths({ runs, opt, X, Y }: { runs: Record<Opt, [number, number][]>; opt: Opt; X: (v: number) => number; Y: (v: number) => number }) {
  const [run, setRun] = useState(true);
  const t = useClock(run, STEPS);
  const shown = Math.max(0, Math.min(STEPS, Math.floor(t * 12)));
  useEffect(() => { if (run && shown >= STEPS) setRun(false); }, [run, shown]);
  const cl = (y: number) => Y(Math.max(-2, Math.min(2, y)));
  return <g>
    {(Object.keys(runs) as Opt[]).sort(o => (o === opt ? 1 : -1)).map(o => {
      const p = runs[o].slice(0, shown + 1), on = o === opt;
      return <g key={o} opacity={on ? 1 : 0.35}>
        <polyline points={p.map(([x, y]) => `${X(x)},${cl(y)}`).join(" ")} className={`b2curve ${o === "sgd" ? "sky" : o === "momentum" ? "mint" : "amber"}`} fill="none" strokeWidth={on ? 2 : 1.25} />
        {on && <circle cx={X(p.at(-1)![0])} cy={cl(p.at(-1)![1])} r="6" className="b2ball" />}
      </g>;
    })}
  </g>;
}

export function BatchScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), compare = num(props, "compare", 0);
  const [B, setB] = useState(num(props, "B", 4));
  const [opt, setOpt] = useState<Opt>("sgd");
  const runs = useMemo(() => ({ sgd: runBatch("sgd", B), momentum: runBatch("momentum", B), adam: runBatch("adam", B) }), [B]);
  const W = 360, H = 260, X = lin(-5.5, 5.5, 16, 344), Y = lin(-2, 2, 122, 14);
  const draws = useMemo(() => { const r = seeded(21); return Array.from({ length: 12 }, () => [gauss(r), gauss(r)] as [number, number]); }, []);
  const g0 = grad(...SPOT), k = 14, cx = 60, cy = 230;
  const wob = SIGMA / Math.sqrt(B), wobC = compare ? SIGMA / Math.sqrt(compare) : 0;
  const reach = (p: [number, number][]) => { const i = p.findIndex(q => loss(q[0], q[1]) < 0.5); return i < 0 ? null : i; };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={quiet ? `A ball stepping down a narrow valley with batches of ${B}.` : `Batches of ${B}: the gradient wobbles by about ${fx(wob, 1)} around the true one; ${opt} reaches the bottom ${reach(runs[opt]) == null ? "not within 60 steps" : `in ${reach(runs[opt])} steps`}.`}>
      {[0.5, 2, 5, 10].map(c => <ellipse key={c} cx={X(0)} cy={Y(0)} rx={X(Math.sqrt(2 * c)) - X(0)} ry={Y(0) - Y(Math.sqrt((2 * c) / 20))} className="b2grid" fill="none" />)}
      <circle cx={X(0)} cy={Y(0)} r="3" className="b2dot" />
      <Paths key={`${opt}-${B}`} runs={runs} opt={opt} X={X} Y={Y} />
      <text x="16" y="144" className="b2t sky">plain SGD</text>
      <text x="124" y="144" className="b2t mint">momentum</text>
      <text x="236" y="144" className="b2t amber">Adam</text>
      {/* twelve batch gradients at one spot */}
      <circle cx={cx + g0[0] * k * 0.5} cy={cy - g0[1] * k * 0.5} r={2 * wob * k * 0.5} className="aidiag" fill="none" />
      {compare > 0 && <circle cx={cx + g0[0] * k * 0.5} cy={cy - g0[1] * k * 0.5} r={2 * wobC * k * 0.5} className="aidiag" fill="none" opacity="0.5" />}
      {draws.map(([a, b], i) => { const x2 = cx + (g0[0] + wob * a) * k * 0.5, y2 = cy - (g0[1] + wob * b) * k * 0.5; return <g key={i}>
        <line x1={cx} y1={cy} x2={x2} y2={y2} className="b2curve pink" strokeWidth="1.25" opacity="0.7" /></g>; })}
      <line x1={cx} y1={cy} x2={cx + g0[0] * k * 0.5} y2={cy - g0[1] * k * 0.5} className="ailine" />
      <ArrowHead x1={cx} y1={cy} x2={cx + g0[0] * k * 0.5} y2={cy - g0[1] * k * 0.5} className="b2bar" />
      <text x="140" y="176" className="b2t pink">12 batch gradients</text>
      <text x="140" y="194" className="b2t">black: the true one</text>
      {compare > 0 && <text x="140" y="212" className="b2t">faint: B = {compare}</text>}
      <text x="140" y="230" className="b2t">{quiet ? "" : `spread ∝ 1/√B`}</text>
    </svg>
  );
  const steps = reach(runs[opt]);
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Batch size B" value={B} min={1} max={64} step={1} onChange={setB} marks={[{ v: 1, label: "1" }, { v: 4, label: "4" }, { v: 16, label: "16" }, { v: 64, label: "64" }]} />
        <Toggle label="Rule" value={opt} onChange={setOpt} options={[{ v: "sgd", label: "Plain SGD" }, { v: "momentum", label: "Momentum" }, { v: "adam", label: "Adam" }]} />
      </>}
      readouts={quiet ? <Read label="Batch size" value={String(B)} /> : <>
        <Read label="Wobble, σ/√B" value={fx(wob, 2)} tone="pink" big />
        {compare > 0 && <Read label={`Against B = ${compare}`} value={`${fx(wob / wobC)} as big`} />}
        <Read label="Steps to the bottom" value={steps == null ? "not in 60" : String(steps)} />
      </>}
    />
  );
}
