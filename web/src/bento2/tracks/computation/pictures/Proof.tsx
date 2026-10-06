// Proof steps (computation.md, cs-03 and cs-14), in two modes:
// dominoes: induction as a row of dominoes. Fill the base case and the first one tips; justify the step with the right
//   reason and the whole row falls. The odd numbers 1, 3, 5, … build the square beside it as L shapes, one per domino.
// stairs: the robot's stair count, ways(n) = ways(n − 1) + ways(n − 2), drawn as bars with the two it's built from lit,
//   and the proof column that can go to the Notebook.
import { useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { Read, SaveRow, Scene, Slider, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";

const W = 360;
const REASONS = ["Algebra", "Induction hypothesis", "What we want to prove"];

export function ProofScene(props: SceneProps) {
  return str<string>(props.props, "mode", "dominoes") === "stairs" ? <Stairs {...props} /> : <Dominoes {...props} />;
}

function Dominoes({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), run = flag(props, "run");
  const [n, setN] = useState(Math.round(num(props, "n", 12)));
  const [base, setBase] = useState(run);
  const [why, setWhy] = useState<string | null>(run ? "Induction hypothesis" : null);
  const valid = why === "Induction hypothesis";
  const reach = quiet ? 0 : base ? (valid ? n : 1) : 0;
  const t = Math.max(0, useClock(!quiet && reach > 0, 99));
  const fallen = Math.min(reach, Math.floor(t / 0.22) + (reach ? 1 : 0));
  const gap = Math.min(26, (W - 30) / n), dx = (i: number) => 18 + i * gap;
  const cell = Math.min(12, 128 / Math.max(1, n)), sq = fallen;
  const svg = (
    <svg viewBox={`0 0 ${W} 250`} className="b2pic" role="img" aria-label={`${n} dominoes; ${fallen} have fallen.`}>
      {Array.from({ length: n }, (_, i) => {
        const down = i < fallen, x = dx(i);
        return (
          <g key={i}>
            <rect x={x} y="18" width={Math.max(4, gap * 0.38)} height="40" rx="2" className="b2bar sky" opacity={down ? 1 : 0.3}
              transform={down ? `rotate(62 ${x + Math.max(4, gap * 0.38)} 58)` : undefined} />
            {(n <= 12 || (i + 1) % 5 === 0 || i === 0) && <text x={x + 3} y="76" textAnchor="middle" className="b2t">{i + 1}</text>}
          </g>
        );
      })}
      {!quiet && reach > 0 && reach < n && fallen === reach && <text x={dx(reach) + 4} y="14" className="b2t pink">stops here</text>}
      {!quiet && Array.from({ length: sq }, (_, k) => (
        // the k-th odd number, 2k + 1, as an L around the (k × k) square
        <g key={k} className={k % 2 ? "amber" : "sky"}>
          <rect x={20 + k * cell} y={96} width={cell - 1} height={(k + 1) * cell - 1} className="b2bar" opacity="0.8" />
          {k > 0 && <rect x={20} y={96 + k * cell} width={k * cell - 1} height={cell - 1} className="b2bar" opacity="0.8" />}
        </g>
      ))}
      {!quiet && sq > 0 && <text x={28 + sq * cell} y={104 + Math.min(sq, 3) * 4} className="b2t">{sq} × {sq} = {sq * sq}</text>}
      {quiet && <rect x="20" y="96" width="128" height="128" rx="4" className="b2bar unknown" opacity="0.4" />}
      <text x={W - 12} y="110" textAnchor="end" className="b2t">P(n): 1 + 3 + … + (2n − 1) = n²</text>
      <text x={W - 12} y="140" textAnchor="end" className={`b2t ${base ? "sky" : ""}`}>base: P(1) is 1 = 1² {base ? "✓" : "?"}</text>
      <text x={W - 12} y="166" textAnchor="end" className={`b2t ${valid ? "sky" : why ? "pink" : ""}`}>step: P(k) ⇒ P(k + 1) {valid ? "✓" : why ? "✗" : "?"}</text>
      <text x={W - 12} y="192" textAnchor="end" className="b2t">… + (2k − 1) + (2k + 1) = k² + 2k + 1</text>
      <text x={W - 12} y="214" textAnchor="end" className="b2t">= (k + 1)²</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <>
        <Slider label="Dominoes" value={n} min={3} max={20} step={1} onChange={setN} />
        <button type="button" className="ctl" aria-pressed={base} onClick={() => setBase(b => !b)}>Base case: 1 = 1²</button>
        <span className="cspick" role="group" aria-label="Reason for the step">
          <small>Step's reason</small>
          {REASONS.map(r => <button type="button" key={r} aria-pressed={why === r} onClick={() => setWhy(w => (w === r ? null : r))}>{r}</button>)}
        </span>
      </>}
      readouts={quiet ? <Read label="Dominoes" value={n} /> : <>
        <Read label="Fallen" value={`${fallen} of ${n}`} tone="sky" big />
        <Read label={`Sum to n = ${Math.max(1, fallen)}`} value={fallen ? fallen * fallen : "–"} tone="amber" />
        {why && !valid && <Read label="Why it stops" value={why === "Algebra" ? "the algebra needs P(k) first" : "that assumes what you're proving"} tone="pink" />}
      </>}
    />
  );
}

const ways = (n: number) => { let a = 1, b = 1; for (let k = 1; k < n; k++) [a, b] = [b, a + b]; return b; };
const LINES = [
  ["ways(1) = 1, ways(2) = 2", "Given: count them"],
  ["The last move is 1 step or 2", "Definition"],
  ["ways(n + 1) = ways(n) + ways(n − 1)", "Algebra"],
  ["= F(n + 1) + F(n) = F(n + 2)", "Induction hypothesis"],
];

function Stairs({ props }: SceneProps) {
  const [n, setN] = useState(Math.round(num(props, "n", 10)));
  const { b2, note } = useB2();
  const top = ways(n), bw = (W - 40) / n, h = (k: number) => (ways(k) / top) * 120, base = 236;
  const saved = b2.notebook.some(e => e.id === "cs-stairs");
  const svg = (
    <svg viewBox={`0 0 ${W} 280`} className="b2pic" role="img" aria-label={`Ways to climb 1 to ${n} stairs; ${n} stairs can be climbed ${top} ways.`}>
      {LINES.map(([l, r], i) => <text key={l} x="12" y={18 + i * 19} className="b2t">{l} <tspan className="b2t sky">· {r}</tspan></text>)}
      {Array.from({ length: n }, (_, i) => {
        const k = i + 1, tone = k === n ? "amber" : k === n - 1 || k === n - 2 ? "sky" : "";
        return (
          <g key={k}>
            <rect x={20 + i * bw + 2} y={base - h(k)} width={bw - 4} height={Math.max(1, h(k))} rx="2" className={`b2bar ${tone || "sky"}`} opacity={tone ? 1 : 0.3} />
            <text x={20 + i * bw + bw / 2} y={base + 18} textAnchor="middle" className="b2t">{k}</text>
            {(k >= n - 2 || n <= 8) && <text x={20 + i * bw + bw / 2} y={base - 6 - h(k)} textAnchor="middle" className={`b2t ${tone}`}>{ways(k)}</text>}
          </g>
        );
      })}
      <line x1="16" y1={base} x2={W - 16} y2={base} className="b2axis" />
      <text x="20" y="274" className="b2t">stairs</text>
      {n >= 3 && <text x={W - 16} y="274" textAnchor="end" className="b2t amber">{ways(n - 1)} + {ways(n - 2)} = {top}</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Stairs" value={n} min={1} max={15} step={1} onChange={setN} />
      </>}
      readouts={<>
        <Read label={`Ways for ${n} stairs`} value={top} tone="amber" big />
        <Read label="Fibonacci" value={`F(${n + 1}) = ${top}`} tone="sky" />
      </>}
      foot={<SaveRow what={<>Keep the proof column in your Notebook</>} saved={saved} onSave={() =>
        note({ id: "cs-stairs", track: "cs", title: "Stairs, by induction", data: { n, ways: top }, lines: [`${n} stairs: ${top} ways, F(${n + 1}).`, ...LINES.map(([l, r]) => `${l} (${r})`)] })} />}
    />
  );
}
