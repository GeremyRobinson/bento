// The Slice tool (multivariable.md, tool 2): cut the landscape with y = b or x = a and open the cut curve with its
// tangent (02); or cut along any direction through a point, with a compass needle and the slope-against-angle dial (11).
import { useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle, useClock, useSvgDrag } from "../../../ui/kit";
import { grad } from "../maths";
import { Arrow, FlatMap, mapper, nice, useLandscape } from "./common";

const W = 360, H = 250;
/** a graph frame: maps (t, z) into a rectangle with z auto-scaled */
function graph(rect: [number, number, number, number], t0: number, t1: number, z0: number, z1: number) {
  const [x, y, w, h] = rect;
  return { X: (t: number) => x + ((t - t0) / (t1 - t0)) * w, Z: (z: number) => y + h - ((Math.max(z0, Math.min(z1, z)) - z0) / (z1 - z0)) * h, rect };
}
const range = (vals: number[], pad = 0.1): [number, number] => {
  const lo = Math.min(...vals), hi = Math.max(...vals), p = Math.max(1e-6, (hi - lo) * pad);
  return [lo - p, hi + p];
};

export function SliceScene({ props, marker }: SceneProps) {
  const { f, box } = useLandscape(props);
  const [a, setA] = useState(num(props, "a", 1)), [b, setB] = useState(num(props, "b", 1));
  const [dir, setDir] = useState<"x" | "y">(str<string>(props, "dir", "x") === "y" ? "y" : "x");
  const quiet = flag(props, "quiet");
  const { ref, drag } = useSvgDrag();
  const wide = box[1] - box[0] > box[3] - box[2];
  const m = mapper(box, wide ? [6, 70, 160, 80] : [6, 40, 150, 150]);
  const [t0, t1] = dir === "x" ? [box[0], box[1]] : [box[2], box[3]];
  const along = (t: number) => (dir === "x" ? f(t, b) : f(a, t));
  const ts = Array.from({ length: 121 }, (_, i) => t0 + ((t1 - t0) * i) / 120);
  const zs = ts.map(along);
  const [z0, z1] = range(wide ? zs.map(z => Math.min(z, 3)) : zs);
  const G = graph([196, 24, 156, 170], t0, t1, z0, z1);
  const at = dir === "x" ? a : b, zAt = along(at), [gx, gy] = grad(f, a, b), slope = dir === "x" ? gx : gy;
  const tan = (s: number) => { const d = (t1 - t0) / 5; return path([[G.X(at - d), G.Z(zAt - s * d)], [G.X(at + d), G.Z(zAt + s * d)]]); };
  const guessSlope = marker?.[0];
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`The slice ${dir === "x" ? `y = ${nice(b)}` : `x = ${nice(a)}`} of the landscape, with its tangent at the point${quiet ? "" : `: slope ${nice(slope)}`}.`}>
      <FlatMap f={f} box={box} m={m} levels={12}>
        {dir === "x" ? <line x1={m.X(box[0])} y1={m.Y(b)} x2={m.X(box[1])} y2={m.Y(b)} className="mvcut amber" />
          : <line x1={m.X(a)} y1={m.Y(box[2])} x2={m.X(a)} y2={m.Y(box[3])} className="mvcut amber" />}
        <circle cx={m.X(a)} cy={m.Y(b)} r="6" className="mvball" />
        <circle cx={m.X(a)} cy={m.Y(b)} r="18" className="b2hit" {...drag((x, y) => {
          setA(Math.round(Math.max(box[0], Math.min(box[1], m.ix(x))) * 10) / 10);
          setB(Math.round(Math.max(box[2], Math.min(box[3], m.iy(y))) * 10) / 10);
        })} />
      </FlatMap>
      <text x={m.frame[0]} y={m.frame[1] - 8} className="b2t">map: drag the point</text>
      <rect x={G.rect[0]} y={G.rect[1]} width={G.rect[2]} height={G.rect[3]} className="mvframe" />
      <path d={path(ts.map((t, i) => [G.X(t), G.Z(zs[i]!)]))} className="b2curve amber" />
      {guessSlope != null && <path d={tan(guessSlope)} className="mvtrail dash" />}
      {!quiet && <path d={tan(slope)} className="b2curve pink" />}
      <circle cx={G.X(at)} cy={G.Z(zAt)} r="5" className="mvball" />
      <text x={G.rect[0] + G.rect[2]} y={G.rect[1] + G.rect[3] + 16} textAnchor="end" className="b2t">{dir}</text>
      <text x={G.rect[0]} y={G.rect[1] - 7} className="b2t amber">{dir === "x" ? `slice y = ${nice(b)}` : `slice x = ${nice(a)}`}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Toggle label="Which slice" value={dir} onChange={setDir} options={[{ v: "x", label: "Slice y = b" }, { v: "y", label: "Slice x = a" }]} />
        <Slider label="a (x of the point)" value={a} min={box[0]} max={box[1]} step={0.1} onChange={setA} format={v => nice(v, 1)} />
        <Slider label="b (y of the point)" value={b} min={box[2]} max={box[3]} step={0.1} onChange={setB} format={v => nice(v, 1)} />
      </>}
      readouts={<>
        <Read label="Height" value={fx(f(a, b), 2)} tone="trav" />
        {guessSlope != null && <Read label="Your tangent's slope" value={nice(guessSlope)} />}
        {!quiet && <Read label="Slope east, f_x" value={fx(gx, 2)} tone={dir === "x" ? "pink" : undefined} />}
        {!quiet && <Read label="Slope north, f_y" value={fx(gy, 2)} tone={dir === "y" ? "pink" : undefined} />}
      </>} />
  );
}

/** The direction compass at one point: turn the needle, read the slope that way, and watch slope against angle (11). */
export function CompassScene({ props, marker }: SceneProps) {
  const { f, box } = useLandscape(props);
  const [a, setA] = useState(num(props, "a", 1)), [b, setB] = useState(num(props, "b", 1));
  const [ang, setAng] = useState(num(props, "ang", 0));
  const quiet = flag(props, "quiet"), spin = flag(props, "spin");
  const t = useClock(spin, 99);
  const { ref, drag } = useSvgDrag();
  const wide = box[1] - box[0] > box[3] - box[2];
  const m = mapper(box, wide ? [6, 70, 176, 88] : [6, 34, 170, 170]);
  const [gx, gy] = grad(f, a, b), G = Math.hypot(gx, gy), gAng = ((Math.atan2(gy, gx) * 180) / Math.PI + 360) % 360;
  // the reveal spins the needle once (2.5 s); after that, or with Less motion, it rests on the steepest way up
  const spun = spin ? (t < 2.5 ? (t / 2.5) * 360 : gAng) : null;
  const needle = quiet && marker ? marker[0] : spun ?? ang;
  const rad = (needle * Math.PI) / 180, u: [number, number] = [Math.cos(rad), Math.sin(rad)], D = gx * u[0] + gy * u[1];
  const len = 34, cx = m.X(a), cy = m.Y(b);
  const dial = graph([206, 24, 146, 92], 0, 360, -G * 1.15 - 1e-6, G * 1.15 + 1e-6);
  const drawn = quiet ? 0 : spin && t < 2.5 ? (t / 2.5) * 360 : 360;
  const cos = Array.from({ length: 73 }, (_, i) => i * 5).filter(d => d <= drawn + 1e-9);
  const sl = graph([206, 150, 146, 70], -1.5, 1.5, ...range(Array.from({ length: 31 }, (_, i) => f(a + (i / 10 - 1.5) * u[0], b + (i / 10 - 1.5) * u[1]))));
  const slicePts = Array.from({ length: 61 }, (_, i) => -1.5 + i * 0.05).map(s => [sl.X(s), sl.Z(f(a + s * u[0], b + s * u[1]))] as [number, number]);
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`A compass at (${nice(a)}, ${nice(b)}) pointing ${Math.round(needle)} degrees. The slope that way is ${nice(D)}.`}>
      <FlatMap f={f} box={box} m={m} levels={12}>
        {!quiet && <Arrow x1={cx} y1={cy} x2={cx + (gx / (G || 1)) * len * 1.25} y2={cy - (gy / (G || 1)) * len * 1.25} cls="pink faint" />}
        <Arrow x1={cx} y1={cy} x2={cx + u[0] * len} y2={cy - u[1] * len} cls="trav" w={3} />
        <circle cx={cx} cy={cy} r="5" className="mvball" />
        <circle cx={cx + u[0] * len} cy={cy - u[1] * len} r="16" className="b2hit" {...drag((x, y) => { if (!quiet) setAng(Math.round(((Math.atan2(cy - y, x - cx) * 180) / Math.PI + 360) % 360)); })} />
      </FlatMap>
      <text x={m.frame[0]} y={m.frame[1] - 8} className="b2t">turn the needle</text>
      <rect x={dial.rect[0]} y={dial.rect[1]} width={dial.rect[2]} height={dial.rect[3]} className="mvframe" />
      <line x1={dial.X(0)} y1={dial.Z(0)} x2={dial.X(360)} y2={dial.Z(0)} className="b2grid strong" />
      {cos.length > 1 && <path d={path(cos.map(d => [dial.X(d), dial.Z(gx * Math.cos((d * Math.PI) / 180) + gy * Math.sin((d * Math.PI) / 180))]))} className="b2curve pink" />}
      {!quiet && drawn >= 360 && <circle cx={dial.X(gAng)} cy={dial.Z(G)} r="5" className="mvdot pink" />}
      <line x1={dial.X(needle)} y1={dial.rect[1]} x2={dial.X(needle)} y2={dial.rect[1] + dial.rect[3]} className="mvtrail dash" />
      <text x={dial.rect[0]} y={dial.rect[1] - 7} className="b2t pink">slope vs angle</text>
      <rect x={sl.rect[0]} y={sl.rect[1]} width={sl.rect[2]} height={sl.rect[3]} className="mvframe" />
      <path d={path(slicePts)} className="b2curve amber" />
      <circle cx={sl.X(0)} cy={sl.Z(f(a, b))} r="4" className="mvball" />
      <text x={sl.rect[0]} y={sl.rect[1] - 7} className="b2t amber">slice this way</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Needle angle" value={ang} min={0} max={359} step={1} onChange={setAng} format={v => `${Math.round(v)}°`} />
        <Slider label="Point x" value={a} min={box[0]} max={box[1]} step={0.1} onChange={setA} format={v => nice(v, 1)} />
        <Slider label="Point y" value={b} min={box[2]} max={box[3]} step={0.1} onChange={setB} format={v => nice(v, 1)} />
      </>}
      readouts={<>
        <Read label="Direction u" value={`⟨${fx(u[0], 2)}, ${fx(u[1], 2)}⟩`} tone="trav" />
        {!quiet && <Read label="Slope this way, D_u f" value={fx(D, 2)} tone="amber" />}
        {!quiet && <Read label="Steepest, at" value={`${Math.round(gAng)}°, slope ${fx(G, 2)}`} tone="pink" />}
      </>} />
  );
}
