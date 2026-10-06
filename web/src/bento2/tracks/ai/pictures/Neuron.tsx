// One neuron (04): dots of two colors in the plane, two weights and a bias as sliders. The plane shades by the
// neuron's output σ(w₁x₁ + w₂x₂ + b), blue near 0 and orange near 1, with the 0.5 line drawn. In Use it, Train runs
// gradient descent on the log loss and the weights go to the shelf as neuron_w.
import { useEffect, useRef, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { sigmoid } from "../maths";
import { Btn, Btns, lin } from "./common";

const DOTS: [number, number, number][] = [[-2, -1, 0], [-1.5, 0.5, 0], [-0.5, -1.5, 0], [-2.2, 1.6, 0], [0.2, -2.2, 0], [-1, -0.4, 0],
  [1.5, 1, 1], [0.8, 2, 1], [2.2, -0.2, 1], [1.2, 0.2, 1], [0.1, 1.2, 1], [2, 2.2, 1]];

export function NeuronScene({ props, place }: SceneProps) {
  const k = flag(props, "doubled") ? 2 : 1;
  const [w1, setW1] = useState(num(props, "w1", 1) * k);
  const [w2, setW2] = useState(num(props, "w2", 1) * k);
  const [b, setB] = useState(num(props, "b", 0) * k);
  const [run, setRun] = useState(false);
  const trains = flag(props, "train") || place === "tool";
  const { b2, save } = useB2();
  const st = useRef({ w1, w2, b });
  st.current = { w1, w2, b };
  useEffect(() => {
    if (!run) return;
    const t = setInterval(() => {
      let { w1: a, w2: c, b: d } = st.current, g1 = 0, g2 = 0, gb = 0;
      for (const [x, y, lab] of DOTS) { const e = sigmoid(a * x + c * y + d) - lab; g1 += e * x; g2 += e * y; gb += e; }
      const n = DOTS.length;
      a -= (0.5 * g1) / n; c -= (0.5 * g2) / n; d -= (0.5 * gb) / n;
      setW1(Math.max(-8, Math.min(8, a))); setW2(Math.max(-8, Math.min(8, c))); setB(Math.max(-8, Math.min(8, d)));
    }, 50);
    return () => clearInterval(t);
  }, [run]);
  const W = 360, H = 260, sx = lin(-3, 3, 50, 310), sy = lin(-3, 3, 250, 10), N = 24, cw = 260 / N, ch = 240 / N;
  const cells = [];
  for (let i = 0; i < N; i++) for (let j = 0; j < N; j++) {
    const x = -3 + ((i + 0.5) * 6) / N, y = -3 + ((j + 0.5) * 6) / N, s = sigmoid(w1 * x + w2 * y + b);
    cells.push(<rect key={`${i}-${j}`} x={50 + i * cw} y={250 - (j + 1) * ch} width={cw + 0.4} height={ch + 0.4} fill={s > 0.5 ? "var(--b2-amber)" : "var(--b2-sky)"} fillOpacity={Math.abs(s - 0.5) * 0.7} />);
  }
  // the 0.5 line, clipped to the box
  const seg: [number, number][] = [];
  if (Math.abs(w2) > 1e-6) for (const x of [-3, 3]) seg.push([x, -(w1 * x + b) / w2]);
  else if (Math.abs(w1) > 1e-6) for (const y of [-3, 3]) seg.push([-b / w1, y]);
  const px = props.px, py = props.py, hasPt = typeof px === "number" && typeof py === "number";
  const logloss = DOTS.reduce((s, [x, y, lab]) => { const p = sigmoid(w1 * x + w2 * y + b); return s - Math.log2(Math.max(1e-9, lab ? p : 1 - p)); }, 0) / DOTS.length;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`One neuron with weights ${fx(w1)} and ${fx(w2)} and bias ${fx(b)}: orange where w₁x₁ + w₂x₂ + b is positive.`}>
      <defs><clipPath id="nbox"><rect x="50" y="10" width="260" height="240" /></clipPath></defs>
      {cells}
      <g clipPath="url(#nbox)">{seg.length === 2 && <line x1={sx(seg[0]![0])} y1={sy(seg[0]![1])} x2={sx(seg[1]![0])} y2={sy(seg[1]![1])} className="ailine" />}</g>
      <line x1="50" y1={sy(0)} x2="310" y2={sy(0)} className="b2grid strong" />
      <line x1={sx(0)} y1="10" x2={sx(0)} y2="250" className="b2grid strong" />
      {DOTS.map(([x, y, c], i) => <circle key={i} cx={sx(x)} cy={sy(y)} r="6" className={`aidot c${c}`} />)}
      {hasPt && <g><circle cx={sx(px as number)} cy={sy(py as number)} r="9" className="b2marker" /><text x={sx(px as number) + 12} y={sy(py as number) - 10} className="b2t">({px}, {py})</text></g>}
      <text x="306" y={sy(0) - 6} textAnchor="end" className="b2t">x₁</text>
      <text x={sx(0) + 6} y="24" className="b2t">x₂</text>
    </svg>
  );
  const vals = [w1, w2, b], saved = Array.isArray(b2.shelf.neuron_w?.value) && (b2.shelf.neuron_w.value as number[]).every((v, i) => Math.abs(v - vals[i]!) < 1e-9);
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="w₁" value={w1} min={-4} max={4} step={0.1} onChange={setW1} format={v => fx(v, 1)} />
        <Slider label="w₂" value={w2} min={-4} max={4} step={0.1} onChange={setW2} format={v => fx(v, 1)} />
        <Slider label="b" value={b} min={-4} max={4} step={0.1} onChange={setB} format={v => fx(v, 1)} />
        {trains && <Btns><Btn on={!run} onClick={() => setRun(r => !r)}>{run ? "Pause" : "Train"}</Btn></Btns>}
      </>}
      readouts={<>
        <Read label="z = w₁x₁ + w₂x₂ + b" value={hasPt ? fx(w1 * (px as number) + w2 * (py as number) + b) : "per point"} />
        {hasPt && <Read label="σ(z)" value={fx(sigmoid(w1 * (px as number) + w2 * (py as number) + b))} tone="amber" />}
        <Read label="Log loss" value={`${fx(logloss)} bits a dot`} tone="pink" />
      </>}
      foot={trains ? <SaveRow what={<>Keep <b>neuron_w</b> = ({fx(w1)}, {fx(w2)}, {fx(b)})</>} saved={saved}
        onSave={() => save("neuron_w", vals, "b2-ai-04", { labels: ["w₁", "w₂", "b"], note: "one neuron, tuned by hand and by training" })} /> : undefined}
    />
  );
}
