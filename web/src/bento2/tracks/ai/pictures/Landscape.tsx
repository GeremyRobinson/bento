// The Loss landscape (ai.md, "Loss landscape"): the line fitter's loss over every (w, b), shaded from low (dark) to
// high, with the model as a ball. Drag the ball to set the line; press Descend and the ball rolls by gradient steps,
// leaving its path. Turn it to 3D to see the bowl. It shares its points and line with the Line fitter ("ai-line").
import { useEffect, useRef, useState } from "react";
import type { SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle, useSvgDrag } from "../../../ui/kit";
import { Surface3D } from "../../../ui/Surface3D";
import { useB2 } from "../../../ui/useB2";
import { bestLine, etaLimit, lineStep, mseOf } from "../maths";
import { Btn, Btns, lin } from "./common";

type Pt = [number, number];
const DEFAULT: Pt[] = [[0, 1], [1, 3], [2, 2], [3, 5], [4, 4]];

export function LandscapeScene(_: SceneProps) {
  const { tool, setToolState } = useB2();
  const shared = tool<{ pts?: Pt[]; w?: number; b?: number } | null>("ai-line", null);
  const pts = shared?.pts ?? DEFAULT;
  const [bw, bb] = bestLine(pts);
  const [w, setW] = useState(shared?.w ?? bw - 1.5);
  const [b, setB] = useState(shared?.b ?? bb + 2.5);
  const [eta, setEta] = useState(0.05);
  const [trail, setTrail] = useState<Pt[]>([]);
  const [view, setView] = useState<"map" | "3d">("map");
  const { ref, drag } = useSvgDrag();
  const latest = useRef({ w, b });
  latest.current = { w, b };
  useEffect(() => () => setToolState("ai-line", { pts, ...latest.current }), []); // eslint-disable-line react-hooks/exhaustive-deps

  const W = 360, H = 260, R = 3;
  const sx = lin(bw - R, bw + R, 30, 340), sy = lin(bb - R * 1.5, bb + R * 1.5, 240, 12);
  const ux = lin(30, 340, bw - R, bw + R), uy = lin(240, 12, bb - R * 1.5, bb + R * 1.5);
  const NX = 31, NY = 23, cells: { x: number; y: number; v: number }[] = [];
  let vmax = 0;
  for (let i = 0; i < NX; i++) for (let j = 0; j < NY; j++) {
    const cw = bw - R + ((i + 0.5) * 2 * R) / NX, cb = bb - R * 1.5 + ((j + 0.5) * 3 * R) / NY, v = Math.log1p(mseOf(pts, cw, cb));
    vmax = Math.max(vmax, v); cells.push({ x: i, y: j, v });
  }
  const descend = () => {
    let cw = w, cb = b;
    const out: Pt[] = [[cw, cb]];
    for (let k = 0; k < 40; k++) { [cw, cb] = lineStep(pts, cw, cb, eta); if (!Number.isFinite(cw) || Math.abs(cw) > 50) break; out.push([cw, cb]); }
    setTrail(out); setW(out.at(-1)![0]); setB(out.at(-1)![1]);
  };
  const loss = mseOf(pts, w, b);
  const cw = (340 - 30) / NX, ch = (240 - 12) / NY;
  const map = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`The loss over slope w and intercept b. The ball is at w = ${fx(w)}, b = ${fx(b)}, loss ${fx(loss)}.`}>
      {cells.map(c => <rect key={`${c.x}-${c.y}`} x={30 + c.x * cw} y={240 - (c.y + 1) * ch} width={cw + 0.5} height={ch + 0.5} fill="var(--b2-pink)" fillOpacity={0.05 + 0.6 * (c.v / vmax)} />)}
      <circle cx={sx(bw)} cy={sy(bb)} r="4" className="b2dot" />
      <text x={sx(bw) + 8} y={sy(bb) + 16} className="b2t">bottom</text>
      {trail.length > 1 && <path d={path(trail.map(([a, c]) => [sx(a), sy(c)]))} className="b2curve mint" />}
      <circle cx={sx(w)} cy={sy(b)} r="8" className="b2handle" />
      <circle cx={sx(w)} cy={sy(b)} r="22" className="b2hit" {...drag((px, py) => { setW(ux(px)); setB(uy(py)); setTrail([]); })} />
      <text x="34" y="26" className="b2t">b ↑</text>
      <text x="336" y="236" textAnchor="end" className="b2t">w →</text>
    </svg>
  );
  const scale = Math.max(1, mseOf(pts, bw + R, bb + R * 1.5) / 2);
  const surface = (
    <Surface3D domain={R} label="The loss as a bowl over (w, b)." zscale={1} zclip={2.6}
      f={(u, v) => mseOf(pts, bw + u, bb + v * 1.5) / scale - 1.2}
      points={[{ x: w - bw, y: (b - bb) / 1.5, z: Math.min(2.6, loss / scale - 1.2), cls: "mint", r: 7, label: "you" }]} />
  );
  return (
    <Scene svg={view === "map" ? map : surface}
      controls={<>
        <Toggle label="View" value={view} onChange={setView} options={[{ v: "map", label: "Map" }, { v: "3d", label: "Bowl in 3D" }]} />
        <Slider label="Learning rate η" value={eta} min={0.005} max={0.25} step={0.005} onChange={setEta} format={v => v.toFixed(3)} />
        <Btns><Btn on onClick={descend}>Descend 40 steps</Btn></Btns>
      </>}
      readouts={<>
        <Read label="w, b" value={`${fx(w)}, ${fx(b)}`} />
        <Read label="Loss" value={fx(loss, 3)} tone="pink" />
        <Read label="Settles for η below" value={fx(etaLimit(pts), 3)} />
      </>}
    />
  );
}
