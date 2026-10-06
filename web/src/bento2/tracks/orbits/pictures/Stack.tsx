// The rocket stack (orbits.md, "New for Development" 6): a 1-tonne dry ship on a propellant bar, and the Δv curve the
// rocket equation draws as the propellant grows. Each added tonne buys less than the one before; a better engine
// stretches the whole curve. `compare` shows a second stack for the guess's reveal.
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle } from "../../../ui/kit";
import { veOf } from "../maths";

const ENGINES = [{ v: "300", label: "I_sp 300 s" }, { v: "350", label: "350 s" }, { v: "450", label: "450 s" }] as const;

export function StackScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), cmp = num(props, "compare", 0);
  const fixedVe = num(props, "ve", 0);
  const [prop, setProp] = useState(num(props, "prop", 4));
  const [isp, setIsp] = useState(String(num(props, "isp", 450)) as "300" | "350" | "450");
  const ve = fixedVe || veOf(Number(isp)) / 1000;
  const dry = 1, MAX = 20;
  const dv = (m: number) => ve * Math.log((dry + m) / dry);
  const W = 360, H = 250, gx0 = 116, gx1 = 348, gy0 = 214, gy1 = 18;
  const top = Math.max(16, dv(MAX) * 1.08);
  const X = (m: number) => gx0 + (m / MAX) * (gx1 - gx0), Y = (v: number) => gy0 - (v / top) * (gy0 - gy1);
  const curve: [number, number][] = [];
  for (let m = 0; m <= MAX + 1e-9; m += 0.25) curve.push([X(m), Y(dv(m))]);
  const perT = 8.6;
  const stack = (x: number, m: number, tone: string, label: string) => (
    <g>
      <rect x={x} y={gy0 - m * perT - 14} width="26" height="14" rx="3" className="b2train" />
      <rect x={x + 2} y={gy0 - m * perT} width="22" height={Math.max(1, m * perT)} rx="2" className={`b2bar ${tone}`} />
      <path d={`M${x + 5},${gy0 - m * perT - 14} L${x + 13},${gy0 - m * perT - 26} L${x + 21},${gy0 - m * perT - 14} Z`} className="b2train" />
      <text x={x + 13} y={gy0 + 16} textAnchor="middle" className="b2t">{label}</text>
    </g>
  );
  const next = dv(prop + 1) - dv(prop);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={`A 1-tonne ship on ${fx(prop, 1)} tonnes of propellant${quiet ? "" : `: delta v ${fx(dv(prop), 2)} kilometers per second`}.`}>
      {stack(14, Math.min(prop, MAX), "amber", `${fx(prop, 1)} t`)}
      {cmp > 0 && stack(56, cmp, "sky", `${fx(cmp, 1)} t`)}
      <line x1={gx0} y1={gy0} x2={gx1} y2={gy0} className="b2axis" />
      <line x1={gx0} y1={gy1} x2={gx0} y2={gy0} className="b2axis" />
      <text x={gx1} y={gy0 + 16} textAnchor="end" className="b2t">propellant, tonnes</text>
      <text x={gx0 + 6} y={gy1 + 4} className="b2t">Δv, km/s</text>
      {[5, 10, 15, 20].map(m => <text key={m} x={X(m)} y={gy0 + 16} textAnchor="middle" className="b2t">{m === 20 ? "" : m}</text>)}
      <path d={path(curve)} className="b2curve amber" />
      <line x1={X(prop)} y1={gy0} x2={X(prop)} y2={Y(dv(prop))} className="b2mark amber" />
      <circle cx={X(prop)} cy={Y(dv(prop))} r="6" className="b2dot amber" />
      {!quiet && <text x={X(prop) + 9} y={Y(dv(prop)) + 16} className="b2t amber">{fx(dv(prop), 2)}</text>}
      {cmp > 0 && <>
        <circle cx={X(cmp)} cy={Y(dv(cmp))} r="6" className="b2dot sky" />
        <text x={X(cmp) + 9} y={Y(dv(cmp)) - 8} className="b2t sky">{fx(dv(cmp), 2)}, × {fx(dv(cmp) / dv(prop), 2)}</text>
      </>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Propellant" value={prop} min={0} max={MAX} step={0.1} onChange={setProp} format={m => `${fx(m, 1)} t on a 1 t ship`} marks={[{ v: 2, label: "2 t" }, { v: 4, label: "4 t" }, { v: 9, label: "9 t" }]} />
        {!fixedVe && <Toggle label="Engine" value={isp} onChange={setIsp} options={ENGINES.map(e => ({ v: e.v, label: e.label }))} />}
      </>}
      readouts={<>
        <Read label="Exhaust speed v_e" value={`${fx(ve, 2)} km/s`} />
        <Read label="Mass ratio" value={fx((dry + prop) / dry, 2)} />
        {!quiet && <Read label="Δv" value={`${fx(dv(prop), 2)} km/s`} tone="amber" big />}
        {!quiet && <Read label="The next tonne adds" value={`${fx(next, 2)} km/s`} />}
        {!quiet && <Read label="Propellant fraction" value={`${fx((100 * prop) / (dry + prop), 1)}%`} />}
      </>} />
  );
}
