// The speed adder (relativity.md): two speed sliders, the result bar that approaches but never reaches 1, a
// Galilean ghost bar for comparison, and rapidity mode, where the speeds become lengths that simply add.
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider, Toggle } from "../../../ui/kit";
import { addSpeeds, rapidity } from "../physics";

const W = 360, H = 210;
const MARKS = [{ v: 0.5, label: "1/2" }, { v: 0.6, label: "3/5" }, { v: 0.8, label: "4/5" }, { v: 0.9, label: "0.9" }];

export function AdderScene({ props, marker }: SceneProps) {
  const [u, setU] = useState(num(props, "u", 0.5));
  const [v, setV] = useState(num(props, "v", 0.5));
  const [mode, setMode] = useState<"speed" | "rapidity">("speed");
  const hide = flag(props, "hide");
  const w = addSpeeds(u, v);
  const x0 = 96, unit = mode === "speed" ? 120 : 52;
  const L = (x: number) => x0 + x * unit;
  const rows = mode === "speed"
    ? [{ k: "u", label: "u", a: 0, b: u, cls: "sky" }, { k: "v", label: "v", a: 0, b: v, cls: "pink" }, { k: "sum", label: "u + v", a: 0, b: u + v, cls: "ghost" }, { k: "w", label: "u ⊕ v", a: 0, b: w, cls: "amber" }]
    : [{ k: "u", label: "w(u)", a: 0, b: rapidity(u), cls: "sky" }, { k: "v", label: "w(v)", a: rapidity(u), b: rapidity(u) + rapidity(v), cls: "pink" }, { k: "w", label: "w(u ⊕ v)", a: 0, b: rapidity(w), cls: "amber" }];
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic add" role="img" aria-label={`Adding ${fx(u)}c and ${fx(v)}c gives ${hide ? "a speed below c" : `${fx(w, 3)}c`}, not ${fx(u + v)}c.`}>
      {mode === "speed" && <>
        <line x1={L(1)} y1="8" x2={L(1)} y2={H - 8} className="b2light" />
        <text x={L(1) + 5} y="20" className="b2t amber">c</text>
      </>}
      <line x1={x0} y1="8" x2={x0} y2={H - 8} className="b2axis" />
      {rows.map((r, i) => {
        const y = 22 + i * (mode === "speed" ? 46 : 58), hidden = hide && r.k === "w";
        return (
          <g key={r.k}>
            <text x={x0 - 8} y={y + 18} textAnchor="end" className="b2t">{r.label}</text>
            {!hidden && <rect x={L(r.a)} y={y + 4} width={Math.max(0, (r.b - r.a) * unit)} height="20" rx="6" className={`b2bar ${r.cls}`} />}
            {hidden && <rect x={x0} y={y + 4} width={unit} height="20" rx="6" className="b2bar unknown" />}
            {!hidden && <text x={Math.min(W - 6, L(r.b) + 6)} y={y + 19} textAnchor={L(r.b) + 50 > W ? "end" : "start"} className="b2t">{mode === "speed" ? fx(r.b, 3) : fx(r.b - r.a, 2)}</text>}
            {marker && r.k === "w" && mode === "speed" && <line x1={L(marker[0])} y1={y} x2={L(marker[0])} y2={y + 28} className="b2mark guess" />}
          </g>
        );
      })}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Ship u" value={u} min={0} max={0.99} step={0.005} onChange={setU} format={x => `${fx(x, 3)}c`} marks={MARKS} />
        <Slider label="Probe v" value={v} min={0} max={0.99} step={0.005} onChange={setV} format={x => `${fx(x, 3)}c`} marks={MARKS} />
        <Toggle label="Bars" value={mode} onChange={setMode} options={[{ v: "speed", label: "Speeds" }, { v: "rapidity", label: "Rapidities" }]} />
      </>}
      readouts={<>
        <Read label="Plain sum" value={`${fx(u + v, 3)}c`} />
        <Read label="u ⊕ v" value={hide ? "?" : `${fx(w, 3)}c`} tone="amber" />
        {mode === "rapidity" && <Read label="w(u) + w(v)" value={hide ? "?" : `${fx(rapidity(u) + rapidity(v))} = w(u ⊕ v)`} />}
      </>}
    />
  );
}
