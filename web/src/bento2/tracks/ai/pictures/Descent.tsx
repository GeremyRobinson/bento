// Gradient descent on one weight (02's Play): left, two points and the line y = wx; right, the loss over w with the
// ball at the current w and its slope as an arrow. Step moves the ball against the slope, by η times it.
import { useEffect, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { ArrowHead, fx, path, Read, Scene, Slider } from "../../../ui/kit";
import { reduceMotion } from "../../../../app/transition";
import { Btn, Btns, lin } from "./common";

export function DescentScene({ props, marker }: SceneProps) {
  const k = num(props, "k", 2), set = num(props, "set", 1), quiet = flag(props, "quiet"), auto = num(props, "steps", 0);
  const [eta, setEta] = useState(num(props, "eta", 0.1));
  const [ws, setWs] = useState<number[]>([0]);
  const pts: [number, number][] = set === 1 ? [[1, k], [2, 2 * k]] : [[1, k], [3, 3 * k]];
  const c = pts.reduce((s, [x]) => s + x * x, 0);
  const L = (w: number) => (c / 2) * (w - k) ** 2, grad = (w: number) => c * (w - k);
  const w = ws.at(-1)!;
  const stepOnce = () => setWs(a => { const v = a.at(-1)!, n = v - eta * grad(v); return Number.isFinite(n) && Math.abs(n) < 50 ? [...a, n] : a; });
  // the reveal plays the first few steps on its own
  useEffect(() => {
    if (!auto) return;
    if (reduceMotion()) { let v = 0; const a = [0]; for (let i = 0; i < auto; i++) { v -= eta * grad(v); a.push(v); } setWs(a); return; }
    let i = 0;
    const t = setInterval(() => { if (++i > auto) { clearInterval(t); return; } stepOnce(); }, 700);
    return () => clearInterval(t);
  }, [auto]); // eslint-disable-line react-hooks/exhaustive-deps

  const W = 360, H = 260;
  // left: the data; right: the loss curve
  const dx = lin(0, set === 1 ? 2.4 : 3.4, 18, 150), dy = lin(0, 3.4 * k, 236, 20);
  const wMax = Math.max(2.4 * k, 3), lx = lin(-0.4 * k, wMax, 176, 350), Lmax = L(-0.4 * k), ly = lin(0, Lmax, 236, 24);
  const curve: [number, number][] = Array.from({ length: 61 }, (_, i) => { const v = -0.4 * k + (i / 60) * (wMax + 0.4 * k); return [lx(v), ly(Math.min(Lmax, L(v)))]; });
  const g = grad(w), slope = (g * (ly(1) - ly(0))) / (lx(1) - lx(0)), alen = 34 / Math.hypot(1, slope);
  const bx = lx(w), by = ly(Math.min(Lmax, L(w)));
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`The line y = ${fx(w)}x and the loss curve; the ball is at w = ${fx(w)}${quiet ? "" : `, slope ${fx(g)}`}.`}>
      <line x1="18" y1="236" x2="150" y2="236" className="b2axis" />
      <line x1="18" y1="236" x2="18" y2="16" className="b2axis" />
      <line x1={dx(0)} y1={dy(0)} x2={dx(set === 1 ? 2.4 : 3.4)} y2={dy(w * (set === 1 ? 2.4 : 3.4))} className="b2curve pink" />
      {pts.map(([x, y], i) => <circle key={i} cx={dx(x)} cy={dy(y)} r="6" className="aidot c0" />)}
      <text x="24" y="28" className="b2t">y = wx</text>
      <line x1="176" y1="236" x2="350" y2="236" className="b2axis" />
      <path d={path(curve)} className="b2curve" />
      <text x="346" y="252" textAnchor="end" className="b2t">w</text>
      <text x="180" y="28" className="b2t pink">loss</text>
      {ws.length > 1 && ws.slice(1).map((v, i) => <line key={i} x1={lx(ws[i]!)} y1={ly(Math.min(Lmax, L(ws[i]!)))} x2={lx(v)} y2={ly(Math.min(Lmax, L(v)))} className="b2jump" />)}
      {!quiet && Math.abs(g) > 1e-6 && <g className="amber">
        <line x1={bx} y1={by} x2={bx - Math.sign(g) * alen} y2={by - Math.sign(g) * alen * slope} className="b2leg" />
        <ArrowHead x1={bx} y1={by} x2={bx - Math.sign(g) * alen} y2={by - Math.sign(g) * alen * slope} className="b2bar amber" />
      </g>}
      {marker && <g><circle cx={lx(marker[0])} cy={ly(Math.min(Lmax, L(marker[0])))} r="9" className="b2marker" /><text x={lx(marker[0])} y={ly(Math.min(Lmax, L(marker[0]))) - 14} textAnchor="middle" className="b2t">your guess</text></g>}
      <circle cx={bx} cy={by} r="8" className="b2dot mint" />
      <line x1={lx(k)} y1="236" x2={lx(k)} y2="244" className="b2axis" />
      <text x={lx(k)} y="256" textAnchor="middle" className="b2t">{k}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Learning rate η" value={eta} min={0.01} max={set === 1 ? 0.45 : 0.22} step={0.01} onChange={setEta} format={v => v.toFixed(2)} />
        <Btns><Btn on onClick={stepOnce}>Step</Btn><Btn onClick={() => setWs([0])}>Back to w = 0</Btn></Btns>
      </>}
      readouts={quiet ? <Read label="w" value={fx(w)} /> : <>
        <Read label="w" value={fx(w)} tone="mint" />
        <Read label="dL/dw" value={fx(g)} tone="amber" />
        <Read label="Next w = w − η · dL/dw" value={fx(w - eta * g)} />
        <Read label="Steps" value={String(ws.length - 1)} />
      </>}
    />
  );
}
