// The product grid (quantum.md, inside the circuit board; 07 and 08): two qubits as a 2×2 grid of the four amplitudes,
// rows for the top qubit and columns for the bottom one. For separate qubits each cell is its row's amplitude times its
// column's, so the grid is a column times a row and ps − qr = 0. A CNOT swaps the 10 and 11 cells; then the grid
// usually can't be split, and the cross-check shows it. Measure the top qubit to see what the bottom one does.
import { useEffect, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider, Toggle, useTween } from "../../../ui/kit";
import { cnot, crossCheck, kron, LABELS2, stream } from "../maths";
import { amp } from "./parts";

const W = 360, H = 260, GX = 128, GY = 52, C = 92;
const angleOf = (x: number, y: number) => (Math.atan2(y, x) * 180) / Math.PI;
const MARKS = [{ v: 0, label: "0" }, { v: 45, label: "H" }, { v: 90, label: "1" }];

export function GridScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), steps = flag(props, "steps"), hasCnot = props.cnot !== undefined || steps;
  const [ta, setTa] = useState(angleOf(num(props, "a", 1), num(props, "b", 0)));
  const [ba, setBa] = useState(angleOf(num(props, "c", 1), num(props, "d", 0)));
  const [on, setOn] = useState<"off" | "on">(flag(props, "cnot") ? "on" : "off");
  const [read, setRead] = useState<number | null>(null);
  const [seed, setSeed] = useState(11);
  // the guess's reveal: H turns the top qubit to 45°, then the CNOT switches on
  const [goal, setGoal] = useState(ta);
  useEffect(() => {
    if (!steps) return;
    const a = setTimeout(() => setGoal(45), 300), b = setTimeout(() => setOn("on"), 2000);
    return () => { clearTimeout(a); clearTimeout(b); };
  }, [steps]);
  const tween = useTween(goal, 1400);
  const tAng = steps ? tween : ta;
  const top = [Math.cos((tAng * Math.PI) / 180), Math.sin((tAng * Math.PI) / 180)].map(x => (Math.abs(x) < 1e-12 ? 0 : x));
  const bot = [Math.cos((ba * Math.PI) / 180), Math.sin((ba * Math.PI) / 180)].map(x => (Math.abs(x) < 1e-12 ? 0 : x));
  const prod = kron(top, bot), v = on === "on" ? cnot(prod) : prod;
  const x = crossCheck(v), ent = Math.abs(x) > 1e-9;
  const light = num(props, "light", -1);
  const pTop1 = v[2]! ** 2 + v[3]! ** 2;
  const doMeasure = () => { const r = stream(seed)(); setSeed(s => s + 1); setRead(r < pTop1 ? 1 : 0); };
  const reset = <T,>(f: (t: T) => void) => (t: T) => { setRead(null); f(t); };
  const cond = read == null ? null : [v[read * 2]!, v[read * 2 + 1]!];
  const condP = cond ? cond.map(c => c ** 2 / (cond[0]! ** 2 + cond[1]! ** 2 || 1)) : null;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic grid" role="img"
      aria-label={`Two qubits as a grid of four amplitudes${quiet ? "" : `: ${v.map((a, i) => `${LABELS2[i]} ${amp(a)}`).join(", ")}`}.${quiet ? "" : ent ? " Entangled." : " A product of two qubits."}`}>
      <text x={GX + C} y="16" textAnchor="middle" className="b2t">bottom qubit</text>
      <text x="14" y={GY + C + 4} className="b2t">top</text>
      {[0, 1].map(j => <text key={`c${j}`} x={GX + j * C + C / 2} y={GY - 10} textAnchor="middle" className="b2t">{ent || on === "on" || quiet ? String(j) : `${j}: ${amp(bot[j]!)}`}</text>)}
      {[0, 1].map(i => <text key={`r${i}`} x={GX - 10} y={GY + i * C + C / 2 + 5} textAnchor="end" className="b2t">{ent || on === "on" || quiet ? String(i) : `${i}: ${amp(top[i]!)}`}</text>)}
      {v.map((a, k) => {
        const i = k >> 1, j = k & 1, x0 = GX + j * C, y0 = GY + i * C, s = Math.abs(a) * (C - 12);
        const dim = read != null && i !== read;
        return (
          <g key={k} opacity={dim ? 0.3 : 1}>
            <rect x={x0 + 2} y={y0 + 2} width={C - 4} height={C - 4} rx="8" className="b2bar track" />
            {!quiet && <rect x={x0 + C / 2 - s / 2} y={y0 + C / 2 - s / 2} width={s} height={s} rx="4" className={`b2bar ${a >= 0 ? "amber" : "trav"}`} opacity="0.85" />}
            <text x={x0 + 8} y={y0 + 18} className="b2t">{LABELS2[k]}</text>
            {!quiet && <text x={x0 + C - 8} y={y0 + C - 9} textAnchor="end" className="b2t">{amp(a)}</text>}
            {light === k && <rect x={x0 + 1} y={y0 + 1} width={C - 2} height={C - 2} rx="9" className="b2mark amber" strokeWidth="3" />}
          </g>
        );
      })}
      {read != null && <text x={GX - 10} y={GY + read * C + C / 2 + 24} textAnchor="end" className="b2t amber">read</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Top qubit's angle" value={Math.round(tAng)} min={-180} max={180} step={1} onChange={reset(setTa)} format={d => `${d}°`} marks={MARKS} />
        <Slider label="Bottom qubit's angle" value={Math.round(ba)} min={-180} max={180} step={1} onChange={reset(setBa)} format={d => `${d}°`} marks={MARKS} />
        {hasCnot && <Toggle label="CNOT" value={on} onChange={reset(setOn)} options={[{ v: "off", label: "No CNOT" }, { v: "on", label: "CNOT, top controls" }]} />}
        {!quiet && <button type="button" className="ctl" onClick={doMeasure}>Measure the top qubit</button>}
      </>}
      readouts={<>
        <Read label="ps − qr" value={quiet ? "?" : fx(x, 3)} tone="amber" />
        <Read label="So it is" value={quiet ? "?" : ent ? "entangled" : "a product"} />
        {!quiet && <Read label="Chances" value={v.map(a => fx(a * a, 2)).join(", ")} />}
        {read != null && condP && <Read label={`Top read ${read}; the bottom now reads`} value={condP[0]! > 0.9999 ? "0, for sure" : condP[1]! > 0.9999 ? "1, for sure" : `0 with chance ${fx(condP[0]!, 2)}`} tone="sky" />}
      </>}
    />
  );
}
