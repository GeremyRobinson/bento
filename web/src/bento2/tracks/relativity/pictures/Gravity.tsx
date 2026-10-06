// The gravity well (Grapher 3D, shared with `mv` and `or`): z = −1/r around Earth, with clocks at any radius; each
// clock's ticks show as a ring that pulses faster when higher. Rocket mode (equivalence): two clocks at the top and
// bottom of an accelerating rocket, with pulses sent up and the spacing readout (10).
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, useClock } from "../../../ui/kit";
import { Surface3D } from "../../../ui/Surface3D";
import { C, G0, R_E } from "../../../constants";
import { gravityGainUs, K_US } from "../physics";
import { showValue } from "../../../tools/expr";

const R_KM = R_E / 1000;
const ORBITS = [{ v: 6771 / R_KM, label: "Station" }, { v: 2, label: "2R" }, { v: 26571 / R_KM, label: "GPS" }, { v: 42164 / R_KM, label: "Geo" }];

export function WellScene({ props }: SceneProps) {
  const [r, setR] = useState(num(props, "r", 2));
  const quiet = flag(props, "quiet"), compare = flag(props, "compare");
  const t = useClock(true, 0.35);
  // ticks shown far faster than real, and the difference exaggerated, so a ring can be seen to beat faster higher up
  const rate = (rr: number) => 1 + 0.6 * (1 - 1 / rr);
  const ring = (rr: number) => (t * rate(rr)) % 1;
  const gain = gravityGainUs(r * R_KM);
  const lin = ((G0 * (r - 1) * R_E) / (C * C)) * 86400e6;
  const well = (
    <Surface3D polar={rr => -1 / rr} domain={8} rmin={1} zscale={2.2} label={`The gravity well around Earth, with a clock at ${fx(r, 2)} Earth radii.`}
      points={[
        { x: Math.cos(-0.9), y: Math.sin(-0.9), z: -1, cls: "pink", ring: ring(1), label: "ground" },
        { x: r * Math.cos(0.5), y: r * Math.sin(0.5), z: -1 / r, cls: "sky", ring: ring(r), r: 7, label: "your clock" },
      ]} />
  );
  // gh/c² (a straight line) against the true curve, which bends over toward its ceiling of 60.1 μs a day
  const chart = compare && (() => {
    const w = 340, h = 130, X = (rr: number) => 40 + ((rr - 1) / 6) * (w - 52), Y = (us: number) => h - 22 - (us / 200) * (h - 34);
    const pts = (fn: (rr: number) => number) => { const a: [number, number][] = []; for (let rr = 1; rr <= 7.001; rr += 0.05) a.push([X(rr), Math.max(4, Y(fn(rr)))]); return path(a); };
    return (
      <svg viewBox={`0 0 ${w} ${h}`} className="b2pic chart" role="img" aria-label="gh over c squared as a straight line against the true gain, which levels off at 60.1 microseconds a day">
        <line x1="40" y1={h - 22} x2={w - 8} y2={h - 22} className="b2axis" />
        <line x1="40" y1="6" x2="40" y2={h - 22} className="b2axis" />
        <line x1="40" y1={Y(K_US)} x2={w - 8} y2={Y(K_US)} className="b2grid strong" />
        <path d={pts(rr => ((G0 * (rr - 1) * R_E) / (C * C)) * 86400e6)} className="b2curve pink" />
        <path d={pts(rr => gravityGainUs(rr * R_KM))} className="b2curve sky" />
        <line x1={X(r)} y1="6" x2={X(r)} y2={h - 22} className="b2mark amber" />
        <text x={w - 10} y={Y(K_US) - 6} textAnchor="end" className="b2t">ceiling 60.1</text>
        <text x={X(2.2)} y="18" className="b2t pink">gh/c²</text>
        <text x="44" y={h - 6} className="b2t">μs a day against r, 1 to 7 Earth radii</text>
      </svg>
    );
  })();
  return (
    <Scene className={compare ? "two" : undefined} svg={well}
      controls={<Slider label="Clock's orbit radius" value={r} min={1} max={8} step={0.01} onChange={setR} format={x => `${fx(x, 2)} R⊕`} marks={ORBITS} />}
      readouts={<>
        <Read label="r" value={`${Math.round(r * R_KM).toLocaleString("en-US")} km`} />
        {!quiet && <Read label="R/r" value={fx(1 / r, 4)} />}
        {!quiet && <Read label="Gains on the ground" value={`${fx(gain, 1)} μs a day`} tone="sky" />}
        {compare && <Read label="gh/c² would say" value={`${fx(lin, 1)} μs a day`} tone="pink" />}
      </>}
      foot={chart || undefined}
    />
  );
}

export function RocketScene({ props }: SceneProps) {
  const [acc, setAcc] = useState(num(props, "acc", 1));
  const hide = flag(props, "hide"), count = flag(props, "count");
  const t = useClock(true, 1.7);
  const W = 360, H = 260, top = 46, bot = 214, cpx = 70;
  // pulses leave the bottom once a second and arrive further apart: the stretch is drawn × 10¹⁴ so it can be seen
  const k = 1 + 0.18 * acc;
  const pulses = [];
  for (let n = Math.floor(t) - 6; n <= Math.floor(t); n++) {
    if (n < 0) continue;
    const age = t - n;
    // speed grows with height in the picture, which spreads the pulses apart as they climb
    const a = (k - 1) / (bot - top), h = a > 1e-9 ? (Math.exp(a * cpx * age) - 1) / a : cpx * age;
    if (h < bot - top) pulses.push(<line key={n} x1="150" x2="210" y1={bot - h} y2={bot - h} className="b2pulseline" />);
  }
  const frac = (acc * G0 * 100) / (C * C);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic rk" role="img" aria-label={`A rocket accelerating at ${fx(acc, 1)} g. Pulses sent up from the bottom clock arrive at the top further apart.`}>
      <path d={`M130,${bot + 16} L130,${top} Q180,${top - 40} 230,${top} L230,${bot + 16} Z`} className="b2train" />
      <circle cx="180" cy={top + 10} r="12" className="b2clock sky" />
      <circle cx="180" cy={bot} r="12" className="b2clock pink" />
      <text x="240" y={top + 15} className="b2t sky">top clock</text>
      <text x="240" y={bot + 5} className="b2t pink">bottom clock</text>
      {pulses}
      {/* the rocket speeds up: a flame that grows with the acceleration */}
      <path d={`M150,${bot + 18} L180,${bot + 18 + 14 * acc} L210,${bot + 18} Z`} className="b2flame" />
      <text x="16" y="24" className="b2t">pulses drawn {fx(k, 2)}× further apart at the top</text>
      <text x="16" y="42" className="b2t">(the real stretch is 10¹⁴ times smaller)</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Acceleration" value={acc} min={0} max={3} step={0.05} onChange={setAcc} format={x => `${fx(x, 2)} g`} />}
      readouts={hide ? <Read label="Bottom sends" value="1 pulse a second" tone="pink" /> : <>
        <Read label="Bottom sends" value="1 pulse a second" tone="pink" />
        <Read label="Top gains, 100 m up" value={`${showValue(frac, 3)} of each second`} tone="sky" />
        {count && <Read label="In a minute of rocket time" value={`bottom 60, top 60 + ${showValue(60 * frac, 2)}`} />}
      </>}
    />
  );
}
