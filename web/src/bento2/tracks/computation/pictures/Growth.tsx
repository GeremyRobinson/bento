// The Growth race (computation.md, cs-07, cs-08, cs-09, cs-11), in two modes:
// race: n, n log₂ n, n², n³, 2ⁿ (and n! on the log scale) against n, with a draggable n and each one's time at a
//   billion steps per second beside it.
// timeline: an n² algorithm's old running time and, after Lock in, its new one on a log timeline from 1 second to an hour.
// Quiet (a Guess before Lock in): the timeline shows only the old time.
import { useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { path, Read, Scene, Slider, Toggle } from "../../../ui/kit";
import { group } from "../../../steps";
import { human } from "../common";

const W = 360;
const lfact = (n: number) => { let s = 0; for (let k = 2; k <= n; k++) s += Math.log10(k); return s; };
export const CURVES = [
  { name: "n", f: (n: number) => n, lg: (n: number) => Math.log10(n), tone: "sky", dash: "" },
  { name: "n log₂ n", f: (n: number) => n * Math.log2(n), lg: (n: number) => Math.log10(n * Math.max(1e-9, Math.log2(n))), tone: "sky", dash: "5 4" },
  { name: "n²", f: (n: number) => n * n, lg: (n: number) => 2 * Math.log10(n), tone: "amber", dash: "" },
  { name: "n³", f: (n: number) => n ** 3, lg: (n: number) => 3 * Math.log10(n), tone: "amber", dash: "5 4" },
  { name: "2ⁿ", f: (n: number) => 2 ** n, lg: (n: number) => n * Math.log10(2), tone: "trav", dash: "" },
  { name: "n!", f: (n: number) => 10 ** lfact(n), lg: lfact, tone: "trav", dash: "2 3" },
];

export function GrowthScene(props: SceneProps) {
  return str<string>(props.props, "mode", "race") === "timeline" ? <Timeline {...props} /> : <Race {...props} />;
}

function Race({ props }: SceneProps) {
  const [n, setN] = useState(Math.round(num(props, "n", 20)));
  const [scale, setScale] = useState<"plain" | "log">("plain");
  const log = scale === "log";
  const X = 100, x = (v: number) => 34 + (v / X) * 300, YMAX = log ? 30 : 10000;
  const y = (v: number) => 200 - (Math.min(v, YMAX) / YMAX) * 180;
  const shown = CURVES.filter(c => log || c.name !== "n!");
  const svg = (
    <svg viewBox={`0 0 ${W} 230`} className="b2pic" role="img" aria-label={`Growth curves against n, at n = ${n}.`}>
      <line x1="34" y1="200" x2="334" y2="200" className="b2axis" />
      <line x1="34" y1="20" x2="34" y2="200" className="b2axis" />
      {(log ? [0, 10, 20, 30] : [0, 5000, 10000]).map(v => <g key={v}><line x1="30" y1={y(v)} x2="334" y2={y(v)} className="b2grid" /><text x="28" y={y(v) + 4} textAnchor="end" className="b2t">{log ? `10${["⁰", "¹⁰", "²⁰", "³⁰"][v / 10]}` : v ? `${v / 1000}k` : 0}</text></g>)}
      {[0, 50, 100].map(v => <text key={v} x={x(v)} y="216" textAnchor="middle" className="b2t">{v}</text>)}
      <text x="334" y="228" textAnchor="end" className="b2t">n</text>
      {shown.map(c => {
        const pts: [number, number][] = [];
        for (let v = 1; v <= X; v += 0.5) { const val = log ? c.lg(v) : c.f(v); pts.push([x(v), y(val)]); if ((log ? val : val) > YMAX) break; }
        const end = pts[pts.length - 1]!;
        return (
          <g key={c.name} className={c.tone}>
            <path d={path(pts)} className="b2curve" strokeDasharray={c.dash || undefined} />
            <text x={Math.min(end[0] + 5, 330)} y={end[1] <= 21 ? 34 : end[1] - 4} className="b2t" textAnchor={end[0] > 300 ? "end" : "start"}>{c.name}</text>
          </g>
        );
      })}
      <line x1={x(n)} y1="20" x2={x(n)} y2="200" className="b2mark" />
      <text x={x(n) + 4} y="192" className="b2t">n = {n}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="n" value={n} min={1} max={100} step={1} onChange={setN} marks={[{ v: 10, label: "10" }, { v: 20, label: "20" }, { v: 40, label: "40" }, { v: 64, label: "64" }]} />
        <Toggle label="Scale" value={scale} onChange={setScale} options={[{ v: "plain", label: "Plain" }, { v: "log", label: "Log scale" }]} />
      </>}
      readouts={<>
        {CURVES.map(c => <Read key={c.name} label={`${c.name}, at 10⁹ steps a second`} value={human(c.lg(n) > 300 ? Infinity : c.f(n) / 1e9)} tone={c.tone} />)}
      </>}
    />
  );
}

/** seconds on a log timeline from 1 s to 1 hour */
const TICKS: [number, string][] = [[1, "1 s"], [10, "10 s"], [60, "1 min"], [600, "10 min"], [3600, "1 h"]];
function Timeline({ props, marker }: SceneProps) {
  const quiet = flag(props, "quiet");
  const t0 = num(props, "t0", 3), factor = num(props, "factor", 100), t1 = t0 * factor;
  const tx = (s: number) => 24 + (Math.log10(s) / Math.log10(3600)) * 312;
  const svg = (
    <svg viewBox={`0 0 ${W} 200`} className="b2pic" role="img" aria-label={`An n² algorithm: ${t0} seconds on 1,000 items.${quiet ? "" : ` ${t1} seconds on 10,000.`}`}>
      <text x="24" y="22" className="b2t">an n² algorithm, time on a log scale</text>
      <line x1="24" y1="110" x2="336" y2="110" className="b2axis" />
      {TICKS.map(([s, l]) => <g key={s}><line x1={tx(s)} y1="104" x2={tx(s)} y2="116" className="b2axis" /><text x={tx(s)} y="134" textAnchor="middle" className="b2t">{l}</text></g>)}
      <circle cx={tx(t0)} cy="110" r="7" className="b2bar sky" />
      <text x={tx(t0)} y="86" textAnchor="middle" className="b2t sky">1,000 items: {t0} s</text>
      {marker && <g><line x1={tx(10 ** marker[0])} y1="94" x2={tx(10 ** marker[0])} y2="150" className="b2mark guess" /><text x={tx(10 ** marker[0])} y="168" textAnchor="middle" className="b2t">your guess</text></g>}
      {!quiet && <g>
        <path d={`M${tx(t0)},70 Q${(tx(t0) + tx(t1)) / 2},40 ${tx(t1)},70`} className="b2curve amber" fill="none" strokeWidth="1.5" />
        <text x={(tx(t0) + tx(t1)) / 2} y="48" textAnchor="middle" className="b2t amber">× {group(factor)}</text>
        <circle cx={tx(t1)} cy="110" r="7" className="b2bar amber" />
        <text x={Math.min(tx(t1), 300)} y="190" textAnchor="middle" className="b2t amber">10,000 items: {group(t1)} s = {human(t1)}</text>
      </g>}
    </svg>
  );
  return (
    <Scene svg={svg}
      readouts={quiet ? <Read label="1,000 items" value={`${t0} s`} tone="sky" /> : <>
        <Read label="Growth factor, (10,000 / 1,000)²" value={group(factor)} />
        <Read label="10,000 items" value={`${group(t1)} s`} tone="amber" big />
      </>}
    />
  );
}
