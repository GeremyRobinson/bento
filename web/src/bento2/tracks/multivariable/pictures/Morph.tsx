// The Shape morpher (multivariable.md, tool 9): f = ax² + bxy + cy² with three sliders; the surface morphs between
// bowl, dome, saddle and trough, with a live badge and D = 4ac − b² (13, 18). The guess shows only the x and y slices
// until the reveal turns the whole surface and draws the diagonal slice.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider } from "../../../ui/kit";
import type { F2 } from "../maths";
import { nice, View3D } from "./common";

const W = 360, H = 250;
export const shapeOf = (a: number, b: number, c: number) => {
  const D = 4 * a * c - b * b;
  if (Math.abs(D) < 1e-9) return a === 0 && b === 0 && c === 0 ? "Flat" : "Trough";
  if (D < 0) return "Saddle";
  return a > 0 ? "Bowl" : "Dome";
};

export function MorphScene({ props }: SceneProps) {
  const [a, setA] = useState(num(props, "a", 1)), [b, setB] = useState(num(props, "b", 0)), [c, setC] = useState(num(props, "c", 1));
  const quiet = flag(props, "quiet"), diag = flag(props, "diag");
  const f: F2 = useMemo(() => (x, y) => a * x * x + b * x * y + c * y * y, [a, b, c]);
  const D = 4 * a * c - b * b, shape = shapeOf(a, b, c);
  let lo = Infinity, hi = -Infinity;
  for (let i = 0; i <= 10; i++) for (let j = 0; j <= 10; j++) { const z = f(-2 + i * 0.4, -2 + j * 0.4); lo = Math.min(lo, z); hi = Math.max(hi, z); }
  if (hi - lo < 1e-6) { lo -= 1; hi += 1; }
  const ts = Array.from({ length: 41 }, (_, i) => -2 + i * 0.1);
  const slicePlot = (rect: [number, number, number, number], g: (t: number) => number, label: string, cls: string) => {
    const zs = ts.map(g), z0 = Math.min(...zs, 0), z1 = Math.max(...zs, 0.1);
    const X = (t: number) => rect[0] + ((t + 2) / 4) * rect[2], Z = (z: number) => rect[1] + rect[3] - ((z - z0) / (z1 - z0)) * rect[3];
    return <g>
      <rect x={rect[0]} y={rect[1]} width={rect[2]} height={rect[3]} className="mvframe" />
      <line x1={rect[0]} y1={Z(0)} x2={rect[0] + rect[2]} y2={Z(0)} className="b2grid strong" />
      <path d={path(ts.map((t, i) => [X(t), Z(zs[i]!)]))} className={`b2curve ${cls}`} />
      <text x={rect[0] + 6} y={rect[1] + 16} className={`b2t ${cls}`}>{label}</text>
    </g>;
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={quiet ? "The x slice and the y slice of the surface." : `f = ${nice(a)}x² + ${nice(b)}xy + ${nice(c)}y²: a ${shape.toLowerCase()}, D = ${nice(D)}.`}>
      {quiet ? <>
        {slicePlot([16, 24, 156, 180], t => a * t * t, "x slice (y = 0)", "sky")}
        {slicePlot([188, 24, 156, 180], t => c * t * t, "y slice (x = 0)", "amber")}
      </> : <View3D f={f} box={[-2, 2, -2, 2]} z={[lo, hi]} rect={[0, 0, W, H]} levels={10}
        overlay={P => diag ? <path d={path(ts.map(t => P(t, -t, f(t, -t))))} className="mvcut pink" /> : <>
          <path d={path(ts.map(t => P(t, 0, f(t, 0))))} className="mvcut sky" />
          <path d={path(ts.map(t => P(0, t, f(0, t))))} className="mvcut amber" />
        </>} />}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="a (x²)" value={a} min={-3} max={3} step={0.5} onChange={setA} format={v => nice(v)} />
        <Slider label="b (xy)" value={b} min={-6} max={6} step={0.5} onChange={setB} format={v => nice(v)} />
        <Slider label="c (y²)" value={c} min={-3} max={3} step={0.5} onChange={setC} format={v => nice(v)} />
      </>}
      readouts={<>
        {!quiet && <Read label="Shape" value={shape} tone={shape === "Saddle" ? "pink" : "sky"} big />}
        {!quiet && <Read label="D = 4ac − b²" value={fx(D, 2)} />}
        {!quiet && diag && <Read label="Along y = −x" value={`f = ${nice(a - b + c)}x²`} tone="pink" />}
      </>} />
  );
}
