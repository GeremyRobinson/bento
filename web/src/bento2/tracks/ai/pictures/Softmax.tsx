// Softmax bars (07): a score for each class (drag its handle up or down), the chances as bars that always add to 1,
// and the surprise meter: −log₂ of the right answer's chance, in bits. Tap a class's name to make it the right one.
// The temperature divides every score before softmax. In the tool, up to 10 scores.
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider, useSvgDrag } from "../../../ui/kit";
import { log2, softmax } from "../maths";
import { CLASSES } from "../lessons-a";
import { Btn, Btns, lin } from "./common";

const MORE = ["owl", "cow", "bee", "elk", "yak", "ant", "eel"];

export function SoftmaxScene({ props, place, marker }: SceneProps) {
  const quiet = flag(props, "quiet");
  const [z, setZ] = useState([num(props, "z0", 2), num(props, "z1", 1), num(props, "z2", 0)]);
  const [c, setC] = useState(num(props, "c", 0));
  const [T, setT] = useState(1);
  const { ref, drag } = useSvgDrag();
  const names = [...CLASSES, ...MORE].slice(0, z.length);
  const p = softmax(z, T), bits = -log2(p[c]!);
  const W = 360, H = 260, n = z.length, colW = Math.min(64, 236 / n);
  const zy = lin(-2, 6, 236, 30), uz = lin(236, 30, -2, 6), py = lin(0, 1, 236, 30), by = lin(0, 4, 236, 30);
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={quiet ? `Scores ${z.map(v => fx(v, 1)).join(", ")}; the chances are hidden.` : `Scores ${z.map(v => fx(v, 1)).join(", ")} become chances ${p.map(v => fx(v)).join(", ")}. Surprise at ${names[c]}: ${fx(bits)} bits.`}>
      <line x1="16" y1="236" x2={16 + n * colW} y2="236" className="b2axis" />
      {z.map((v, i) => {
        const cx = 16 + i * colW + colW / 2, right = i === c;
        return <g key={i}>
          {!quiet && <rect x={cx - colW * 0.3} y={py(p[i]!)} width={colW * 0.6} height={236 - py(p[i]!)} rx="4" className={`b2bar ${right ? "amber" : "sky"}`} opacity={right ? 1 : 0.7} />}
          {!quiet && <text x={cx} y={py(p[i]!) - 6} textAnchor="middle" className={`b2t ${right ? "amber" : "sky"}`}>{fx(p[i]!)}</text>}
          {/* the score's handle rides on the bar's center line */}
          <line x1={cx} y1={zy(v)} x2={cx} y2={zy(0)} className="b2mark" />
          <circle cx={cx} cy={zy(v)} r="7" className="b2handle" />
          <circle cx={cx} cy={zy(v)} r="20" className="b2hit" {...drag((_, yy) => setZ(a => a.map((q, j) => (j === i ? Math.round(Math.max(-2, Math.min(6, uz(yy))) * 10) / 10 : q))))} />
          <text x={cx} y="252" textAnchor="middle" className={`b2t${right ? " amber" : ""}`} style={{ cursor: "pointer" }} onClick={() => setC(i)}>{names[i]}</text>
        </g>;
      })}
      {/* the surprise meter */}
      <rect x="300" y="30" width="22" height="206" rx="6" className="b2bar track" />
      {!quiet && <rect x="300" y={by(Math.min(4, bits))} width="22" height={236 - by(Math.min(4, bits))} rx="6" className="b2bar pink" />}
      {[0, 1, 2, 3, 4].map(k => <text key={k} x="330" y={by(k) + 4} className="b2t">{k}</text>)}
      {marker && <g><line x1="294" y1={by(marker[0])} x2="328" y2={by(marker[0])} className="b2mark guess" /></g>}
      <text x="311" y="20" textAnchor="middle" className="b2t pink">bits</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Temperature T" value={T} min={0.25} max={4} step={0.05} onChange={setT} format={v => v.toFixed(2)} marks={[{ v: 0.5, label: "0.5" }, { v: 1, label: "1" }, { v: 2, label: "2" }]} />
        <Btns>
          <Btn onClick={() => setZ(a => a.map(v => Math.min(6, v + 1)))}>Add 1 to every score</Btn>
          {place !== "lesson" && <Btn onClick={() => setZ(a => (a.length < 10 ? [...a, 0] : a.slice(0, 3)))}>{z.length < 10 ? "One more class" : "Back to three"}</Btn>}
        </Btns>
      </>}
      readouts={quiet ? <Read label="Scores" value={z.map(v => fx(v, 1)).join(", ")} /> : <>
        <Read label={`Chance of ${names[c]}`} value={fx(p[c]!, 3)} tone="amber" />
        <Read label="Surprise −log₂ p" value={`${fx(bits)} bits`} tone="pink" big />
        <Read label={`Gradient on ${names[c]}, p − 1`} value={fx(p[c]! - 1)} />
      </>}
    />
  );
}
