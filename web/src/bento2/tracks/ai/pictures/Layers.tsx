// Layers (05): the XOR corners, orange at (1, 0) and (0, 1), blue at (0, 0) and (1, 1). Two hidden ReLU neurons,
// h₁ = ReLU(x₁ + x₂) and h₂ = ReLU(x₁ + x₂ + b₂), each fold the plane along a line; the output y = h₁ + v₂h₂ − 0.5
// shades orange where it is positive. Drag b₂ and v₂ until the corners split. In the guess, one neuron alone tries
// (and can't). Use it saves the hand-built net and lets training find its own.
import { useEffect, useRef, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { mlpProb, mlpStep, newMlp, type Mlp } from "../maths";
import { Btn, Btns, lin } from "./common";

const CORNERS: [number, number, number][] = [[0, 0, 0], [1, 0, 1], [0, 1, 1], [1, 1, 0]];

export function LayersScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), single = flag(props, "single"), why = flag(props, "why"), canSave = flag(props, "save");
  const [b2v, setB2] = useState(num(props, "b2", 0));
  const [v2, setV2] = useState(num(props, "v2", -1));
  const [w1, setW1] = useState(1), [w2, setW2] = useState(1), [b, setB] = useState(-0.5);
  const [net, setNet] = useState<Mlp | null>(null);
  const [rounds, setRounds] = useState(0);
  const { b2, save } = useB2();
  const netRef = useRef<Mlp | null>(null);
  useEffect(() => {
    if (!net) return;
    netRef.current = net;
    let n = 0;
    const t = setInterval(() => {
      const m = netRef.current!;
      for (let k = 0; k < 20; k++) mlpStep(m, CORNERS.map(c => [c[0] * 2 - 1, c[1] * 2 - 1]), CORNERS.map(c => c[2]), 0.5);
      n += 20; setRounds(n);
      if (n >= 1200) clearInterval(t);
    }, 40);
    return () => clearInterval(t);
  }, [net]);

  const out = (x: number, y: number) => {
    if (single) return w1 * x + w2 * y + b;
    if (net) return mlpProb(netRef.current ?? net, [x * 2 - 1, y * 2 - 1]) - 0.5;
    const h1 = Math.max(0, x + y), h2 = Math.max(0, x + y + b2v);
    return h1 + v2 * h2 - 0.5;
  };
  const W = 360, H = 260, sx = lin(-0.5, 1.5, 60, 300), sy = lin(-0.5, 1.5, 250, 10), N = 24, cw = 240 / N, ch = 240 / N;
  const cells = [];
  for (let i = 0; i < N; i++) for (let j = 0; j < N; j++) {
    const v = out(-0.5 + ((i + 0.5) * 2) / N, -0.5 + ((j + 0.5) * 2) / N);
    cells.push(<rect key={`${i}-${j}`} x={60 + i * cw} y={250 - (j + 1) * ch} width={cw + 0.4} height={ch + 0.4} fill={v > 0 ? "var(--b2-amber)" : "var(--b2-sky)"} fillOpacity={Math.min(0.45, Math.abs(v) * 0.5) + 0.05} />);
  }
  const fold = (c: number, cls: string, label: string) => {
    // the line x₁ + x₂ = −c across the box
    const a: [number, number] = [-0.5, -c + 0.5], z: [number, number] = [1.5, -c - 1.5];
    return <g className={cls}><line x1={sx(a[0])} y1={sy(a[1])} x2={sx(z[0])} y2={sy(z[1])} className="b2mark" /><text x={sx(Math.min(1.45, -c + 0.45)) + 4} y={sy(0.05) - 4} className={`b2t ${cls}`}>{label}</text></g>;
  };
  const right = CORNERS.every(([x, y, c]) => (out(x, y) > 0 ? 1 : 0) === c);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`The XOR corners and ${single ? "one neuron's line" : "a network with two folds"}.${quiet ? "" : right ? " All four corners are split." : " The corners are not split yet."}`}>
      <defs><clipPath id="xbox"><rect x="60" y="10" width="240" height="240" /></clipPath></defs>
      {cells}
      {!single && !net && <g clipPath="url(#xbox)">{fold(0, "trav", "h₁ folds")}{fold(b2v, "mint", "h₂ folds")}</g>}
      {why && <g>
        <line x1={sx(1)} y1={sy(0)} x2={sx(0)} y2={sy(1)} className="b2leg amber" />
        <line x1={sx(0)} y1={sy(0)} x2={sx(1)} y2={sy(1)} className="b2leg sky" />
        <circle cx={sx(0.5)} cy={sy(0.5)} r="6" className="b2marker" />
        <text x={sx(0.5) + 12} y={sy(0.5) + 4} className="b2t">same middle</text>
      </g>}
      {CORNERS.map(([x, y, c]) => <circle key={`${x}${y}`} cx={sx(x)} cy={sy(y)} r="10" className={`aidot c${c}`} />)}
      {CORNERS.map(([x, y]) => <text key={`t${x}${y}`} x={sx(x) + (x ? 14 : -14)} y={sy(y) + (y ? -12 : 22)} textAnchor="middle" className="b2t">({x}, {y})</text>)}
    </svg>
  );
  const vals = [1, 1, 1, 1, 0, b2v, 1, v2, -0.5];
  const saved = Array.isArray(b2.shelf.xor_net?.value) && (b2.shelf.xor_net.value as number[]).every((v, i) => Math.abs(v - vals[i]!) < 1e-9);
  return (
    <Scene svg={svg}
      controls={single ? <>
        <Slider label="w₁" value={w1} min={-3} max={3} step={0.1} onChange={setW1} format={v => fx(v, 1)} />
        <Slider label="w₂" value={w2} min={-3} max={3} step={0.1} onChange={setW2} format={v => fx(v, 1)} />
        <Slider label="b" value={b} min={-3} max={3} step={0.1} onChange={setB} format={v => fx(v, 1)} />
      </> : <>
        <Slider label="h₂'s bias b₂" value={b2v} min={-2} max={1} step={0.1} onChange={v => { setB2(v); setNet(null); }} format={v => fx(v, 1)} />
        <Slider label="Output weight v₂" value={v2} min={-3} max={1} step={0.1} onChange={v => { setV2(v); setNet(null); }} format={v => fx(v, 1)} />
        {canSave && <Btns><Btn on={!net} onClick={() => { setRounds(0); setNet(newMlp([2, 2, 2], "relu", 4)); }}>Let training try</Btn></Btns>}
      </>}
      readouts={<>
        {!single && !net && <Read label="y = h₁ + v₂h₂ − 0.5" value={CORNERS.map(([x, y]) => fx(out(x, y), 1)).join(", ")} />}
        {net && <Read label="Training rounds" value={String(rounds)} />}
        {quiet ? <Read label="Corners" value="4" /> : <Read label="Corners split" value={right ? "all four" : "not yet"} tone={right ? "amber" : undefined} />}
      </>}
      foot={canSave && !net ? <SaveRow what={<>Keep your hand-built net as <b>xor_net</b></>} saved={saved}
        onSave={() => save("xor_net", vals, "b2-ai-05", { labels: ["W₁₁", "W₁₂", "W₂₁", "W₂₂", "b₁", "b₂", "v₁", "v₂", "c"], note: "an XOR net built by hand" })} /> : undefined}
    />
  );
}
