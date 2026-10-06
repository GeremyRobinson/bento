// The step-by-step solver (diffeq.md, "New for Development" 1c and 2): Euler, Heun and RK4 on dy/dt = y from y(0) = 1
// to t = 1 against the true eᵗ, with the error plot (log-log, slopes 1, 2 and 4) and the step slider. One step drawn
// with its two slopes for de-03's Work it, and the stepper picker for its Use it, which saves `stepper`.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, Toggle } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { METHOD_NAMES, METHODS, solve, type Method } from "../maths";
import { Arrow, frame } from "./plot";

const W = 360, H = 250;
const TONE: Record<Method, string> = { euler: "pink", heun: "sky", rk4: "mint" };
/** the error at t = 1 for dy/dt = y, y(0) = 1 */
const errAt = (m: Method, h: number) => Math.abs(solve((_t, y) => [y[0]!], [1], 0, 1, h, m).at(-1)!.y[0]! - Math.E);

function ErrorPlot({ h, quiet, halve }: { h: number; quiet: boolean; halve: boolean }) {
  const box = { l: 222, r: 352, t: 16, b: 196 };
  const f = frame(-6, -1, -12, 0, box);
  const hs = Array.from({ length: 26 }, (_, k) => -6 + k / 5);
  const shown = quiet ? (["euler"] as Method[]) : METHODS;
  return (
    <g>
      <line x1={box.l} y1={box.b} x2={box.r} y2={box.b} className="b2axis" />
      <line x1={box.l} y1={box.t} x2={box.l} y2={box.b} className="b2axis" />
      {[-12, -8, -4, 0].map(e => <line key={e} x1={box.l} y1={f.Y(e)} x2={box.r} y2={f.Y(e)} className="b2grid" />)}
      <text x={box.l + 4} y={box.t + 10} className="b2t">error</text>
      <text x={box.r} y={box.b + 16} textAnchor="end" className="b2t">h →</text>
      <text x={box.l} y={box.b + 16} className="b2t">1/64</text>
      {shown.map(m => <path key={m} d={path(hs.map(x => [f.X(x), f.Y(Math.max(-12, Math.log10(errAt(m, 2 ** x))))] as [number, number]))} className={`b2curve ${TONE[m]}`} style={{ strokeWidth: 2 }} />)}
      <line x1={f.X(Math.log2(h))} y1={box.t} x2={f.X(Math.log2(h))} y2={box.b} className="b2mark" />
      {halve && <line x1={f.X(Math.log2(h / 2))} y1={box.t} x2={f.X(Math.log2(h / 2))} y2={box.b} className="b2mark amber" />}
      {shown.map(m => [h, ...(halve ? [h / 2] : [])].map(hh => <circle key={`${m}${hh}`} cx={f.X(Math.log2(hh))} cy={f.Y(Math.max(-12, Math.log10(errAt(m, hh))))} r="4" className={`b2dot ${TONE[m]}`} />))}
    </g>
  );
}

function Race({ props }: SceneProps) {
  const [k, setK] = useState(Math.round(-Math.log2(num(props, "h", 0.25))));
  const quiet = flag(props, "quiet"), halve = flag(props, "halve");
  const h = 2 ** -k;
  const box = { l: 30, r: 196, t: 16, b: 196 };
  const f = frame(0, 1, 1, 2.8, box);
  const runs = useMemo(() => METHODS.map(m => solve((_t, y) => [y[0]!], [1], 0, 1, h, m)), [h]);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Euler, Heun and RK4 with step ${fx(h, 4)} on dy/dt = y, against e to the t.`}>
      <line x1={box.l} y1={box.b} x2={box.r} y2={box.b} className="b2axis" />
      <line x1={box.l} y1={box.t} x2={box.l} y2={box.b} className="b2axis" />
      <text x={box.r} y={box.b + 16} textAnchor="end" className="b2t">t = 1</text>
      <text x={box.l + 4} y={box.t + 10} className="b2t">y</text>
      <path d={path(Array.from({ length: 51 }, (_, j) => [f.X(j / 50), f.Y(Math.exp(j / 50))] as [number, number]))} className="b2curve" />
      <text x={f.X(1) - 4} y={f.Y(Math.E) - 8} textAnchor="end" className="b2t">eᵗ</text>
      {runs.map((r, i) => (
        <g key={i}>
          <path d={path(r.map(p => [f.X(p.t), f.Y(p.y[0]!)] as [number, number]))} className={`b2mark ${TONE[METHODS[i]!]}`} />
          {r.map((p, j) => <circle key={j} cx={f.X(p.t)} cy={f.Y(p.y[0]!)} r={h >= 1 / 8 ? 3.5 : 2} className={`b2dot ${TONE[METHODS[i]!]}`} />)}
        </g>
      ))}
      <ErrorPlot h={h} quiet={quiet} halve={halve} />
    </svg>
  );
  const ratio = (m: Method) => errAt(m, h) / errAt(m, h / 2);
  return (
    <Scene svg={svg}
      controls={<Slider label="Step h" value={k} min={1} max={6} step={1} onChange={setK} format={v => `1/${2 ** v}`} />}
      readouts={<>
        {METHODS.filter(m => !quiet || m === "euler").map(m => <Read key={m} label={`${METHOD_NAMES[m]} error`} value={errAt(m, h).toExponential(1).replace("-", "−")} tone={TONE[m]} />)}
        {halve && METHODS.map(m => <Read key={`r${m}`} label={`${METHOD_NAMES[m]}, h halved`} value={`÷ ${fx(ratio(m), 1)}`} tone={TONE[m]} />)}
      </>}
    />
  );
}

/** one step of dy/dt = at + by: the slope at the start, the trial Euler point, the slope there, and Heun's average */
function OneStep({ props }: SceneProps) {
  const a = num(props, "a", 1), b = num(props, "b", 1), y0 = num(props, "y0", 1), h = num(props, "h", 0.5);
  const F = (t: number, y: number) => a * t + b * y;
  const k1 = F(0, y0), eu = y0 + h * k1, k2 = F(h, eu), heun = y0 + (h / 2) * (k1 + k2);
  const C = y0 + a / (b * b), exact = (t: number) => C * Math.exp(b * t) - (a / b) * t - a / (b * b);
  const ys = [y0, eu, heun, exact(h), exact(1.4 * h)];
  const lo = Math.min(...ys) - 0.5, hi = Math.max(...ys) + 0.5;
  const box = { l: 34, r: 340, t: 16, b: 210 };
  const f = frame(0, 1.4 * h, lo, hi, box);
  const seg = (t: number, y: number, s: number) => ({ x1: f.X(t - 0.18 * h), y1: f.Y(y - 0.18 * h * s), x2: f.X(t + 0.18 * h), y2: f.Y(y + 0.18 * h * s) });
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label="One step: the start's slope gives the Euler point; the slope there, averaged with the first, gives Heun's point.">
      <line x1={box.l} y1={box.b} x2={box.r} y2={box.b} className="b2axis" />
      <line x1={box.l} y1={box.t} x2={box.l} y2={box.b} className="b2axis" />
      <line x1={f.X(h)} y1={box.t} x2={f.X(h)} y2={box.b} className="b2grid strong" />
      <text x={f.X(h)} y={box.b + 16} textAnchor="middle" className="b2t">t = h</text>
      <path d={path(Array.from({ length: 41 }, (_, j) => [f.X((1.4 * h * j) / 40), f.Y(exact((1.4 * h * j) / 40))] as [number, number]))} className="b2curve" opacity={0.6} />
      <Arrow x1={f.X(0)} y1={f.Y(y0)} x2={f.X(h)} y2={f.Y(eu)} cls="pink" />
      <line {...seg(0, y0, k1)} className="b2leg pink" />
      <line {...seg(h, eu, k2)} className="b2leg amber" />
      <Arrow x1={f.X(0)} y1={f.Y(y0)} x2={f.X(h)} y2={f.Y(heun)} cls="sky" />
      <circle cx={f.X(0)} cy={f.Y(y0)} r="5" className="b2dot" />
      <circle cx={f.X(h)} cy={f.Y(eu)} r="5" className="b2dot pink" />
      <circle cx={f.X(h)} cy={f.Y(heun)} r="5" className="b2dot sky" />
      <text x={f.X(h) + 8} y={f.Y(eu) + 4} className="b2t pink">Euler</text>
      <text x={f.X(h) + 8} y={f.Y(heun) + 4} className="b2t sky">Heun</text>
    </svg>
  );
  return <Scene svg={svg} readouts={<><Read label="Slope at the start" value="k₁" tone="pink" /><Read label="Slope at the far end" value="k₂" tone="amber" /><Read label="Heun moves with" value="their average" tone="sky" /></>} />;
}

export function SteppersScene(p: SceneProps) {
  return flag(p.props, "one") ? <OneStep {...p} /> : <Race {...p} />;
}

/** a logistic stock over 50 years, stepped by your method and h, against the exact curve */
export function StepperPickScene({ props, place }: SceneProps) {
  const { b2, save, note } = useB2();
  const sh = b2.shelf.stepper?.value;
  const [m, setM] = useState<Method>(Array.isArray(sh) ? METHODS[sh[0] as number] ?? "heun" : "heun");
  const [h, setH] = useState(Array.isArray(sh) ? (sh[1] as number) : 2);
  const K = typeof b2.shelf.K_fish?.value === "number" ? (b2.shelf.K_fish.value as number) : 1000, r = 0.3, P0 = K / 20;
  const exact = (t: number) => K / (1 + (K / P0 - 1) * Math.exp(-r * t));
  const run = useMemo(() => solve((_t, y) => [r * y[0]! * (1 - y[0]! / K)], [P0], 0, 50, h, m), [m, h, K, P0]);
  const err = Math.max(...run.map(p => Math.abs(p.y[0]! - exact(p.t)) / K));
  const ok = err < 0.001;
  const box = { l: 44, r: 350, t: 16, b: 200 };
  const f = frame(0, 50, 0, K * 1.1, box);
  const canSave = place === "project" || flag(props, "saveable");
  const saved = Array.isArray(sh) && sh[0] === METHODS.indexOf(m) && sh[1] === h;
  const onSave = () => {
    save("stepper", [METHODS.indexOf(m), h], "b2-de-03", { labels: ["method (0 Euler, 1 Heun, 2 RK4)", "h in years"], note: `${METHOD_NAMES[m]} with h = ${h} years` });
    note({ id: "de-stepper", track: "de", title: "Your stepper", project: "b2-de-03", data: { method: METHODS.indexOf(m), h }, lines: [`${METHOD_NAMES[m]}, h = ${h} years: largest error ${fx(err * 100, 3)}% of K over 50 years.`] });
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`${METHOD_NAMES[m]} with step ${h} years: largest error ${fx(err * 100, 2)} percent.`}>
      <line x1={box.l} y1={box.b} x2={box.r} y2={box.b} className="b2axis" />
      <line x1={box.l} y1={box.t} x2={box.l} y2={box.b} className="b2axis" />
      <text x={box.r} y={box.b + 16} textAnchor="end" className="b2t">50 years</text>
      <line x1={box.l} y1={f.Y(K)} x2={box.r} y2={f.Y(K)} className="b2mark amber" />
      <text x={box.l + 4} y={f.Y(K) - 6} className="b2t amber">K</text>
      <path d={path(Array.from({ length: 101 }, (_, j) => [f.X(j / 2), f.Y(exact(j / 2))] as [number, number]))} className="b2curve" opacity={0.6} />
      <path d={path(run.map(p => [f.X(p.t), f.Y(p.y[0]!)] as [number, number]))} className={`b2curve ${TONE[m]}`} style={{ strokeWidth: 2 }} />
      {run.length < 120 && run.map((p, j) => <circle key={j} cx={f.X(p.t)} cy={f.Y(p.y[0]!)} r="3" className={`b2dot ${TONE[m]}`} />)}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Toggle label="Method" value={m} onChange={setM} options={METHODS.map(v => ({ v, label: METHOD_NAMES[v] }))} />
        <Slider label="Step h" value={h} min={0.25} max={10} step={0.25} onChange={setH} format={v => `${v} years`} />
      </>}
      readouts={<>
        <Read label="Largest error" value={`${fx(err * 100, 3)}%`} tone={TONE[m]} />
        <Read label="Within 0.1%" value={ok ? "yes" : "not yet"} />
        <Read label="Steps for 50 years" value={String(run.length - 1)} />
      </>}
      foot={canSave ? <SaveRow what={<>Keep <b>stepper = {METHOD_NAMES[m]}, h = {h}</b>{ok ? "" : " (it misses 0.1% here)"}</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
