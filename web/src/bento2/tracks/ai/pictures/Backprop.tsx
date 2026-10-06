// The Backprop graph (06): y = w₂ · ReLU(w₁x), L = ½(y − t)², as a chain of boxes. Forward writes each value on the
// wire after its box (blue), one box at a time; Backward writes each gradient (orange), right to left, each box
// multiplying by its own local slope. Nudge w₁ to check: L changes by about gradient × nudge.
import { useEffect, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { ArrowHead, fx, Read, Scene, Slider } from "../../../ui/kit";
import { reduceMotion } from "../../../../app/transition";
import { Btn, Btns } from "./common";

export function BackpropScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet");
  const x = num(props, "x", 2);
  const [w1, setW1] = useState(num(props, "w1", 1));
  const [w2, setW2] = useState(num(props, "w2", 3));
  const t = num(props, "t", 4);
  const [fwd, setFwd] = useState(quiet ? 0 : 5);
  const [bwd, setBwd] = useState(0);
  const [nudge, setNudge] = useState(false);
  const a = w1 * x, h = Math.max(0, a), y = w2 * h, L = 0.5 * (y - t) ** 2;
  const dy = y - t, dw2 = dy * h, dh = dy * w2, da = a > 0 ? dh : 0, dw1 = da * x;
  // sweeps: one box per beat
  const sweep = (set: (n: number) => void, n: number) => {
    if (reduceMotion()) { set(n); return () => {}; }
    let k = 0; set(0);
    const id = setInterval(() => { k++; set(k); if (k >= n) clearInterval(id); }, 450);
    return () => clearInterval(id);
  };
  useEffect(() => { if (flag(props, "back")) { setFwd(5); return sweep(setBwd, 5); } }, []); // eslint-disable-line react-hooks/exhaustive-deps
  const W = 360, H = 260, Y = 110;
  const nodes = [{ x: 22, label: "x" }, { x: 92, label: "× w₁" }, { x: 162, label: "ReLU" }, { x: 232, label: "× w₂" }, { x: 306, label: "½(y − t)²" }];
  const vals = [x, a, h, y, L], names = ["x", "a", "h", "y", "L"];
  const grads: (number | null)[] = [null, da, dh, dy, 1];
  const local = ["", `× x = ${fx(x, 0)}`, a > 0 ? "× 1" : "× 0", `× w₂ = ${fx(w2, 0)}`, `y − t = ${fx(dy, 0)}`];
  const eps = 0.01, dL = 0.5 * (w2 * Math.max(0, (w1 + eps) * x) - t) ** 2 - L;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={quiet ? `The chain x, times w₁ = ${w1}, ReLU, times w₂ = ${w2}, loss.` : `The chain x, times w₁, ReLU, times w₂, loss. L = ${fx(L, 1)}; dL/dw₁ = ${fx(dw1, 0)}, dL/dw₂ = ${fx(dw2, 0)}.`}>
      {nodes.slice(0, -1).map((n, i) => <g key={i}>
        <line x1={n.x + 26} y1={Y} x2={nodes[i + 1]!.x - 28} y2={Y} className="aiwire" />
        <ArrowHead x1={n.x} y1={Y} x2={nodes[i + 1]!.x - 28} y2={Y} className="b2bar" />
      </g>)}
      {nodes.map((n, i) => <g key={n.label}>
        <rect x={n.x - 26} y={Y - 20} width={i === 4 ? 60 : 52} height="40" rx="8" className={`aibox${i <= fwd - 1 ? " on" : ""}`} />
        <text x={n.x + (i === 4 ? 4 : 0)} y={Y + 5} textAnchor="middle" className="b2t" style={{ fill: "var(--text)" }}>{n.label}</text>
        {i <= fwd - 1 && <text x={n.x + 2} y={Y - 32} textAnchor="middle" className="b2t sky">{names[i]} = {fx(vals[i]!, i === 4 ? 1 : 0)}</text>}
        {grads[i] != null && 4 - i <= bwd - 1 && <>
          <text x={n.x + 2} y={Y + 42} textAnchor="middle" className="b2t amber">∂L/∂{names[i]} = {fx(grads[i]!, 0)}</text>
          <text x={n.x + 2} y={Y + 62} textAnchor="middle" className="b2t">{local[i]}</text>
        </>}
      </g>)}
      {bwd >= 5 && <>
        <text x="20" y="214" className="b2t amber">∂L/∂w₂ = (y − t)·h = {fx(dw2, 0)}</text>
        <text x="20" y="236" className="b2t amber">∂L/∂w₁ = ∂L/∂a · x = {fx(dw1, 0)}</text>
      </>}
      {nudge && <text x="20" y="40" className="b2t mint">w₁ + 0.01: L moves {fx(dL, 3)}, gradient × 0.01 = {fx(dw1 * eps, 3)}</text>}
      <text x="20" y="20" className="b2t">target t = {t}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="w₁" value={w1} min={-2} max={3} step={1} onChange={v => { setW1(v); setNudge(false); }} />
        <Slider label="w₂" value={w2} min={-2} max={3} step={1} onChange={v => { setW2(v); setNudge(false); }} />
        <Btns>
          <Btn on={fwd < 5} onClick={() => { setBwd(0); sweep(setFwd, 5); }}>Forward</Btn>
          <Btn on={fwd >= 5 && bwd < 5} onClick={() => { setFwd(5); sweep(setBwd, 5); }}>Backward</Btn>
          <Btn onClick={() => setNudge(n => !n)}>Nudge w₁</Btn>
        </Btns>
      </>}
      readouts={quiet ? <Read label="Target t" value={String(t)} /> : <>
        <Read label="L" value={fx(L, 1)} tone="sky" />
        <Read label="∂L/∂w₂" value={bwd >= 5 ? fx(dw2, 0) : "?"} tone="amber" />
        <Read label="∂L/∂w₁" value={bwd >= 5 ? fx(dw1, 0) : "?"} tone="amber" />
      </>}
    />
  );
}
