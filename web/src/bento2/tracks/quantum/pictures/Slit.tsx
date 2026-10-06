// The double-slit lab (quantum.md, 01): dots arrive one at a time and build stripes on the screen. Slit gap and
// wavelength sliders set the stripe spacing λL/d; a detector at the slits wipes the stripes into two plain humps.
// The faint curve beside the screen is the chance the dots are filling in.
import { useMemo, useState } from "react";
import { num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle } from "../../../ui/kit";
import { stream } from "../maths";
import { shownOf, useRun } from "./parts";

const W = 360, H = 260, TOP = 18, BOT = 242, SPAN = 40; // the screen shows ±40 mm
const DOTS = 900, BINS = 240;
const SLIT_W = 10; // μm, each slit's own width: the broad envelope

export function SlitScene({ props }: SceneProps) {
  const [gap, setGap] = useState(num(props, "gap", 40));
  const [wave, setWave] = useState(num(props, "wave", 600));
  const [det, setDet] = useState<"off" | "on">("off");
  const build = useRun(9, true);
  // the stripe spacing on a screen 1 m away, in mm: λL/d
  const spacing = (wave * 1e-9) / (gap * 1e-6) * 1000;
  const chance = (y: number) => {
    const u = (Math.PI * SLIT_W * 1e-6 * (y / 1000)) / (wave * 1e-9);
    const env = u === 0 ? 1 : (Math.sin(u) / u) ** 2;
    if (det === "on") {
      // which slit is known: two humps, one behind each slit, and no stripes
      const c = 6 + gap * 0.22, w = 9;
      return 0.55 * (Math.exp(-(((y - c) / w) ** 2)) + Math.exp(-(((y + c) / w) ** 2)));
    }
    return env * Math.cos((Math.PI * y) / spacing) ** 2;
  };
  const yOf = (mm: number) => TOP + ((SPAN - mm) / (2 * SPAN)) * (BOT - TOP);
  const curve = useMemo(() => Array.from({ length: BINS + 1 }, (_, i) => -SPAN + (2 * SPAN * i) / BINS).map(y => [y, chance(y)] as const), [gap, wave, det]); // eslint-disable-line react-hooks/exhaustive-deps
  const dots = useMemo(() => {
    const cdf: number[] = [];
    let s = 0;
    for (const [, p] of curve) { s += p; cdf.push(s); }
    const r = stream(17);
    return Array.from({ length: DOTS }, () => {
      const u = r() * s, j = cdf.findIndex(c => c >= u);
      return [304 + r() * 44, curve[Math.max(0, j)]![0] + (r() - 0.5) * (2 * SPAN / BINS)] as const;
    });
  }, [curve]);
  const shown = shownOf(build.k, DOTS);
  const peak = Math.max(...curve.map(c => c[1]));
  const sx = 112, gy = (gap / 80) * 46; // the slits drawn apart by the gap
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic slit" role="img"
      aria-label={`${shown} dots on the screen. ${det === "on" ? "With the detector on they make two plain humps." : `They build stripes ${fx(spacing, 1)} mm apart.`}`}>
      {/* the source and the waves it sends */}
      <circle cx="26" cy="130" r="7" className="b2pulse" />
      {[0, 1, 2].map(i => <path key={i} d={`M${44 + i * 20},${100} Q${54 + i * 20},130 ${44 + i * 20},160`} className="b2light" />)}
      {/* the barrier with two slits */}
      <line x1={sx} y1="14" x2={sx} y2={130 - gy - 5} className="b2mirror" />
      <line x1={sx} y1={130 - gy + 5} x2={sx} y2={130 + gy - 5} className="b2mirror" />
      <line x1={sx} y1={130 + gy + 5} x2={sx} y2="246" className="b2mirror" />
      {det === "on" && <>
        <circle cx={sx + 12} cy={130 - gy} r="6" className="b2event lit" />
        <circle cx={sx + 12} cy={130 + gy} r="6" className="b2event lit" />
        <text x={sx + 22} y={130 - gy - 10} className="b2t amber">detector</text>
      </>}
      {/* the chance curve the dots fill in, drawn leftward from the screen */}
      <path d={path(curve.map(([y, p]) => [300 - (p / peak) * 120, yOf(y)]))} className="b2curve amber" opacity="0.55" />
      <line x1="302" y1={TOP} x2="302" y2={BOT} className="b2axis" />
      {dots.slice(0, shown).map(([x, y], i) => <circle key={i} cx={x} cy={yOf(y)} r="1.6" className="b2dot sky" />)}
      <text x="352" y={BOT + 14} textAnchor="end" className="b2t">screen</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Slit gap d" value={gap} min={20} max={80} step={1} onChange={setGap} format={v => `${v} μm`} />
        <Slider label="Wavelength λ" value={wave} min={400} max={700} step={5} onChange={setWave} format={v => `${v} nm`} />
        <Toggle label="Detector at the slits" value={det} onChange={v => { setDet(v); build.run(); }} options={[{ v: "off", label: "No detector" }, { v: "on", label: "Detector on" }]} />
      </>}
      readouts={<>
        <Read label="Stripe spacing λL/d" value={det === "on" ? "no stripes" : `${fx(spacing, 1)} mm`} tone="amber" />
        <Read label="Dots so far" value={shown.toLocaleString("en-US")} tone="sky" />
        <Read label="Screen distance L" value="1 m" />
      </>}
    />
  );
}
