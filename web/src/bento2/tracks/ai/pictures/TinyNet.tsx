// ★ The Tiny neural network (ai.md, "Tiny neural network"): dots of two colors you place, a 2-input network with one
// or two hidden layers of up to 8 neurons, ReLU or sigmoid, and a softmax output. The plane shades by the network's
// chance of orange, redrawn every training round. Train, Step and Pause; Reset replays from the same seed, so a run can
// be repeated exactly. With gradient labels on, the wires of a small net show their gradients each round. The
// Two-color splitter project (2 → 4 → 2) saves the trained weights as net_small.
import { useEffect, useRef, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, Toggle, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { mlpFlat, mlpForward, mlpParams, mlpProb, mlpStep, newMlp, patternDots, type Act, type Mlp, type Pattern } from "../maths";
import { Btn, Btns, lin } from "./common";

type Dot = { x: number; y: number; c: number };
const SEED = 7;

export function TinyNetScene({ props, place }: SceneProps) {
  const project = flag(props, "project") || place === "project", grads = flag(props, "grads"), full = place === "tool";
  const [pattern, setPattern] = useState<Pattern>(str<Pattern>(props, "pattern", "xor"));
  const [dots, setDots] = useState<Dot[]>(() => patternDots(str<Pattern>(props, "pattern", "xor"), 3, 40));
  const [hidden, setHidden] = useState(num(props, "hidden", 4));
  const [layers, setLayers] = useState<1 | 2>(1);
  const [act, setAct] = useState<Act>("relu");
  const [color, setColor] = useState(1);
  const [run, setRun] = useState(false);
  const sizes = layers === 1 ? [2, hidden, 2] : [2, hidden, hidden, 2];
  const [net, setNet] = useState<Mlp>(() => newMlp(sizes, act, SEED));
  const [round, setRound] = useState(0);
  const [bits, setBits] = useState<number | null>(null);
  const { b2, save, note } = useB2();
  const { ref } = useSvgDrag();
  const live = useRef({ net, dots });
  live.current = { net, dots };
  const reset = (s = sizes, a = act) => { setRun(false); setNet(newMlp(s, a, SEED)); setRound(0); setBits(null); };
  const trainRound = (k = 1) => {
    const { net: m, dots: d } = live.current;
    let b = 0;
    for (let i = 0; i < k; i++) b = mlpStep(m, d.map(q => [q.x, q.y]), d.map(q => q.c), 0.3);
    setBits(b); setRound(r => r + k); setNet({ ...m });
  };
  useEffect(() => {
    if (!run) return;
    const t = setInterval(() => trainRound(4), 50);
    return () => clearInterval(t);
  }, [run]); // eslint-disable-line react-hooks/exhaustive-deps

  const W = 360, H = 260, side = grads ? 210 : 240, X0 = grads ? 10 : 60, sx = lin(-1, 1, X0, X0 + side), sy = lin(-1, 1, 10 + side, 10);
  const ux = lin(X0, X0 + side, -1, 1), uy = lin(10 + side, 10, -1, 1);
  const N = 20, cw = side / N, cells = [];
  for (let i = 0; i < N; i++) for (let j = 0; j < N; j++) {
    const pr = mlpProb(net, [-1 + ((i + 0.5) * 2) / N, -1 + ((j + 0.5) * 2) / N]);
    cells.push(<rect key={`${i}-${j}`} x={X0 + i * cw} y={10 + side - (j + 1) * cw} width={cw + 0.4} height={cw + 0.4} fill={pr > 0.5 ? "var(--b2-amber)" : "var(--b2-sky)"} fillOpacity={0.06 + Math.abs(pr - 0.5) * 0.7} />);
  }
  const right = dots.filter(d => (mlpProb(net, [d.x, d.y]) > 0.5 ? 1 : 0) === d.c).length;
  // gradient labels: one round's gradient on each first-layer wire of a 2 → 2 → 2 net, by finite differences on the loss
  const wireGrads = grads ? (() => {
    const X = dots.map(d => [d.x, d.y]), Y = dots.map(d => d.c);
    const loss = (m: Mlp) => X.reduce((s, x, k) => s - Math.log(Math.max(1e-12, mlpForward(m, x).outs.at(-1)![Y[k]!]!)), 0) / X.length;
    return net.W.map((w, l) => Array.from(w, (_, i) => {
      const c = { ...net, W: net.W.map(q => Float64Array.from(q)) };
      c.W[l]![i]! += 1e-5; const up = loss(c); c.W[l]![i]! -= 2e-5; const dn = loss(c);
      return (up - dn) / 2e-5;
    }));
  })() : null;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`${dots.length} dots and a ${sizes.join(" → ")} network after ${round} rounds: ${right} of ${dots.length} on the right side.`}>
      {cells}
      <rect x={X0} y="10" width={side} height={side} fill="transparent" onPointerDown={e => {
        const svgEl = ref.current; const m = svgEl?.getScreenCTM?.(); if (!svgEl || !m || !svgEl.createSVGPoint) return;
        const pt = svgEl.createSVGPoint(); pt.x = e.clientX; pt.y = e.clientY; const q = pt.matrixTransform(m.inverse());
        setDots(ds => [...ds, { x: ux(q.x), y: uy(q.y), c: color }]);
      }} style={{ cursor: "copy" }} />
      {dots.map((d, i) => <circle key={i} cx={sx(d.x)} cy={sy(d.y)} r="5" className={`aidot c${d.c}`} pointerEvents="none" />)}
      {wireGrads && (() => {
        const lx = [250, 296, 342], ny = (n: number, k: number) => 40 + ((k + 0.5) * 180) / n;
        return <g>
          {net.W.map((w, l) => Array.from(w, (_, i) => {
            const nIn = net.sizes[l]!, j = Math.floor(i / nIn), a = i % nIn;
            const x1 = lx[l]!, y1 = ny(nIn, a), x2 = lx[l + 1]!, y2 = ny(net.sizes[l + 1]!, j);
            return <g key={`${l}-${i}`}>
              <line x1={x1} y1={y1} x2={x2} y2={y2} className="aiwire k amber" strokeWidth={Math.min(4, 0.5 + Math.abs(w[i]!))} opacity="0.6" />
              <text x={(x1 + x2) / 2} y={(y1 + y2) / 2 + (a ? 12 : -4)} textAnchor="middle" className="b2t amber">{fx(wireGrads[l]![i]!, 2)}</text>
            </g>;
          }))}
          {net.sizes.map((n, l) => Array.from({ length: n }, (_, k) => <circle key={`${l}${k}`} cx={lx[l]} cy={ny(n, k)} r="7" className="aibox" />))}
          <text x="296" y="24" textAnchor="middle" className="b2t amber">gradients</text>
        </g>;
      })()}
    </svg>
  );
  const flat = mlpFlat(net);
  const saved = Array.isArray(b2.shelf.net_small?.value) && (b2.shelf.net_small.value as number[]).length === flat.length && (b2.shelf.net_small.value as number[]).every((v, i) => Math.abs(v - flat[i]!) < 1e-9);
  const onSave = () => {
    save("net_small", flat, "ai-splitter", { note: `a ${sizes.join(" → ")} network, ${mlpParams(sizes)} numbers, after ${round} rounds` });
    note({ id: "ai-splitter", track: "ai", title: "Two-color splitter", project: "ai-splitter", data: { round, hidden, dots: dots.length },
      lines: [`${dots.length} dots in the ${pattern} pattern; a ${sizes.join(" → ")} network (${mlpParams(sizes)} numbers).`, `After ${round} rounds: ${right} of ${dots.length} dots on the right side${bits != null ? `, ${fx(bits)} bits of surprise a dot` : ""}.`] });
  };
  const pick = (p: Pattern) => { setPattern(p); setDots(patternDots(p, 3, 40)); reset(); };
  return (
    <Scene svg={svg}
      controls={<>
        <Btns>
          {(["xor", "rings", "stripes", "blobs"] as Pattern[]).map(p => <Btn key={p} on={pattern === p} onClick={() => pick(p)}>{p === "xor" ? "XOR" : p[0]!.toUpperCase() + p.slice(1)}</Btn>)}
          <Btn onClick={() => setColor(c => 1 - c)} label={`Next dot you tap: ${color ? "orange" : "blue"}`}>Tap adds {color ? "orange" : "blue"}</Btn>
        </Btns>
        {full && <>
          <Slider label="Hidden neurons" value={hidden} min={1} max={8} step={1} onChange={v => { setHidden(v); reset(layers === 1 ? [2, v, 2] : [2, v, v, 2]); }} />
          <Toggle label="Layers" value={String(layers) as "1" | "2"} onChange={v => { const L = Number(v) as 1 | 2; setLayers(L); reset(L === 1 ? [2, hidden, 2] : [2, hidden, hidden, 2]); }} options={[{ v: "1", label: "1 hidden layer" }, { v: "2", label: "2 hidden layers" }]} />
          <Toggle label="Bend" value={act} onChange={a => { setAct(a); reset(sizes, a); }} options={[{ v: "relu", label: "ReLU" }, { v: "sigmoid", label: "Sigmoid" }]} />
        </>}
        <Btns>
          <Btn on={!run} onClick={() => setRun(r => !r)}>{run ? "Pause" : "Train"}</Btn>
          <Btn onClick={() => trainRound(1)} disabled={run}>Step</Btn>
          <Btn onClick={() => reset()}>Reset</Btn>
        </Btns>
      </>}
      readouts={<>
        <Read label="Network" value={sizes.join(" → ")} />
        <Read label="Rounds" value={String(round)} />
        <Read label="Dots on the right side" value={`${right} of ${dots.length}`} tone="amber" />
        <Read label="Surprise, a dot" value={bits == null ? "train to see" : `${fx(bits)} bits`} tone="pink" />
      </>}
      foot={project ? <SaveRow what={<>Keep the trained net as <b>net_small</b> ({mlpParams(sizes)} numbers)</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
