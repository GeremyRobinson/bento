// de-02's picture: something that cools, drains or charges toward a set level. The coffee cup bends toward the room
// line, with every halving of the gap marked; the drip climbs toward its steady level; and the integrating-factor
// view draws y = atᵐ + C/tⁿ beside μy, the one derivative the factor makes.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider } from "../../../ui/kit";
import { fr } from "../text";
import { frame, useLoop } from "./plot";

const W = 360, H = 250, BOX = { l: 40, r: 350, t: 16, b: 222 };

function Axes({ f, xs, ys, xl, yl }: { f: ReturnType<typeof frame>; xs: number[]; ys: number[]; xl: string; yl: string }) {
  return (
    <g>
      {ys.map(y => <line key={`y${y}`} x1={BOX.l} y1={f.Y(y)} x2={BOX.r} y2={f.Y(y)} className="b2grid" />)}
      <line x1={BOX.l} y1={BOX.b} x2={BOX.r} y2={BOX.b} className="b2axis" />
      <line x1={BOX.l} y1={BOX.t} x2={BOX.l} y2={BOX.b} className="b2axis" />
      {xs.map(x => <text key={`x${x}`} x={f.X(x)} y={BOX.b + 16} textAnchor="middle" className="b2t">{fx(x, 0)}</text>)}
      {ys.map(y => <text key={`t${y}`} x={BOX.l - 6} y={f.Y(y) + 4} textAnchor="end" className="b2t">{fx(y, 0)}</text>)}
      <text x={BOX.r} y={BOX.b - 6} textAnchor="end" className="b2t">{xl}</text>
      <text x={BOX.l + 6} y={BOX.t + 10} className="b2t">{yl}</text>
    </g>
  );
}

function Coffee({ props, marker }: SceneProps) {
  const [A, setA] = useState(num(props, "A", 20));
  const [T0, setT0] = useState(num(props, "T0", 84));
  const [h, setH] = useState(num(props, "h", 10));
  const quiet = flag(props, "quiet");
  const t = useLoop(60);
  const f = frame(0, 60, 0, 100, BOX);
  const T = (tt: number) => A + (T0 - A) * 2 ** (-tt / h);
  const pts = useMemo(() => Array.from({ length: 121 }, (_, k) => [f.X(k / 2), f.Y(T(k / 2))] as [number, number]), [A, T0, h]); // eslint-disable-line react-hooks/exhaustive-deps
  const halvings = Array.from({ length: Math.floor(60 / h) }, (_, k) => k + 1);
  const now = (t * 6) % 60;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Coffee at ${T0} degrees cooling toward a ${A} degree room; the gap halves every ${h} minutes.`}>
      <Axes f={f} xs={[0, 20, 40, 60]} ys={[0, 50, 100]} xl="minutes" yl="°C" />
      <line x1={BOX.l} y1={f.Y(A)} x2={BOX.r} y2={f.Y(A)} className="b2mark amber" />
      <text x={BOX.r} y={f.Y(A) + 15} textAnchor="end" className="b2t amber">room {A}°</text>
      {quiet ? <>
        <line x1={f.X(30)} y1={BOX.t} x2={f.X(30)} y2={BOX.b} className="b2grid strong" />
        <text x={f.X(30) + 4} y={BOX.t + 10} className="b2t">30 min</text>
      </> : <>
        <path d={path(pts)} className="b2curve sky" />
        {halvings.map(n => (
          <g key={n}>
            <line x1={f.X(n * h)} y1={f.Y(A)} x2={f.X(n * h)} y2={f.Y(T(n * h))} className="b2mark pink" />
            <circle cx={f.X(n * h)} cy={f.Y(T(n * h))} r="3.5" className="b2dot pink" />
            {n <= 3 && h >= 6 && <text x={f.X(n * h) + 4} y={f.Y(T(n * h)) - 8} className="b2t pink">{fx((T0 - A) / 2 ** n, 0)}</text>}
          </g>
        ))}
        <circle cx={f.X(now)} cy={f.Y(T(now))} r="6" className="b2dot trav" />
      </>}
      <circle cx={f.X(0)} cy={f.Y(T0)} r="5" className="b2dot sky" />
      {marker && <circle cx={f.X(30)} cy={f.Y(marker[0])} r="7" className="b2marker" />}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Room" value={A} min={10} max={30} step={1} onChange={setA} format={v => `${v} °C`} />
        <Slider label="Start" value={T0} min={40} max={100} step={1} onChange={setT0} format={v => `${v} °C`} />
        <Slider label="Gap halves every" value={h} min={3} max={20} step={1} onChange={setH} format={v => `${v} min`} />
      </>}
      readouts={<>
        <Read label="Gap at the start" value={`${T0 - A} °C`} tone="pink" />
        {!quiet && <Read label="k = ln 2 / h" value={`${fx(Math.LN2 / h, 4)} per min`} />}
        {!quiet && <Read label="At 30 minutes" value={`${fx(T(30), 1)} °C`} tone="sky" />}
      </>}
    />
  );
}

function Factor({ props }: SceneProps) {
  const n = num(props, "n", 2), m = num(props, "m", 2), a = num(props, "a", 1);
  const [y0, setY0] = useState(num(props, "y0", 3));
  const quiet = flag(props, "quiet");
  const C = y0 - a;
  const y = (t: number) => a * t ** m + C / t ** n, mu = (t: number) => t ** n * y(t);
  const hi = Math.max(12, Math.ceil(a * 3 ** m + Math.abs(C)));
  const f = frame(0, 3, Math.min(0, -Math.abs(C)), hi, BOX);
  const pts = (g: (t: number) => number) => path(Array.from({ length: 101 }, (_, k) => { const t = 0.35 + (2.65 * k) / 100; return [f.X(t), f.Y(Math.max(f.y0, Math.min(hi, g(t))))] as [number, number]; }));
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`The solution y = ${a} t to the ${m} plus C over t to the ${n}, with y(1) = ${y0}.`}>
      <Axes f={f} xs={[1, 2, 3]} ys={[0, hi]} xl="t" yl="y" />
      <path d={pts(mu)} className="b2curve amber" opacity={0.7} />
      <path d={pts(y)} className="b2curve sky" />
      <circle cx={f.X(1)} cy={f.Y(y0)} r="5" className="b2dot sky" />
      <text x={f.X(1) + 8} y={f.Y(y0) - 8} className="b2t sky">y(1) = {y0}</text>
      {!quiet && <><circle cx={f.X(2)} cy={f.Y(y(2))} r="5" className="b2dot pink" /><text x={f.X(2) + 8} y={f.Y(y(2)) + 16} className="b2t pink">y(2) = {fr(y(2))}</text></>}
      {!quiet && <text x={BOX.r} y={f.Y(Math.min(hi, mu(2.6))) - 8} textAnchor="end" className="b2t amber">μy</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Start y(1)" value={y0} min={a - 3} max={a + 6} step={1} onChange={setY0} />}
      readouts={<>
        <Read label="C = y(1) − a" value={String(C).replace("-", "−")} tone="sky" />
        {!quiet && <Read label="μ" value={n === 1 ? "t" : "t²"} tone="amber" />}
      </>}
    />
  );
}

function Drip() {
  const [R, setR] = useState(40);
  const [k, setK] = useState(0.2);
  const t = useLoop(36);
  const target = R / k, half = Math.LN2 / k, near = 3 * half;
  const top = Math.max(420, Math.ceil((target * 1.15) / 100) * 100);
  const f = frame(0, 36, 0, top, BOX);
  const L = (tt: number) => target * (1 - Math.exp(-k * tt));
  const now = (t * 4) % 36;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A drip of ${R} milligrams an hour, cleared at ${fx(k * 100, 0)} percent an hour, settles at ${fx(target, 0)} milligrams.`}>
      <Axes f={f} xs={[0, 12, 24, 36]} ys={[0, top / 2, top]} xl="hours" yl="mg" />
      <line x1={BOX.l} y1={f.Y(target)} x2={BOX.r} y2={f.Y(target)} className="b2mark amber" />
      <rect x={BOX.l} y={f.Y(Math.min(top, target))} width={BOX.r - BOX.l} height={Math.max(0, f.Y(target * 7 / 8) - f.Y(Math.min(top, target)))} className="b2bar amber" opacity={0.15} />
      <path d={path(Array.from({ length: 145 }, (_, j) => [f.X(j / 4), f.Y(Math.min(top, L(j / 4)))] as [number, number]))} className="b2curve sky" />
      {near <= 36 && <><line x1={f.X(near)} y1={BOX.b} x2={f.X(near)} y2={f.Y(Math.min(top, L(near)))} className="b2mark pink" /><circle cx={f.X(near)} cy={f.Y(Math.min(top, L(near)))} r="4" className="b2dot pink" /></>}
      <circle cx={f.X(now)} cy={f.Y(Math.min(top, L(now)))} r="6" className="b2dot trav" />
      <text x={BOX.r} y={f.Y(Math.min(top, target)) - 6} textAnchor="end" className="b2t amber">steady level</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Drip rate" value={R} min={10} max={80} step={5} onChange={setR} format={v => `${v} mg/h`} />
        <Slider label="Cleared each hour" value={k} min={0.1} max={0.5} step={0.01} onChange={setK} format={v => `${fx(v * 100, 0)}%`} />
      </>}
      readouts={<>
        <Read label="Steady level" value={`${fx(target, 0)} mg`} tone="amber" />
        <Read label="Gap halves every" value={`${fx(half, 2)} h`} />
        <Read label="Within 1/8 after" value={`${fx(near, 1)} h`} tone="pink" />
      </>}
    />
  );
}

export function CoolingScene(p: SceneProps) {
  const mode = str<"coffee" | "factor" | "drip">(p.props, "mode", "coffee");
  return mode === "factor" ? <Factor {...p} /> : mode === "drip" ? <Drip /> : <Coffee {...p} />;
}
