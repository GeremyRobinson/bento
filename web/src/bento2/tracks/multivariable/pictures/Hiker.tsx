// The Hiker on a trail (multivariable.md, tool 3): a trail on the contour map, a walker who follows it, and a strip of
// height and rate of climb against time (04). Also project 1, My landscape: type or sculpt a terrain and keep it.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Toggle, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { evaluate, parse } from "../../../tools/expr";
import { compile, grad, LAND_BOX, LAND_SRC, type F2 } from "../maths";
import { useTime, FlatMap, mapper, MINE, nice, useLandscape, type MineState } from "./common";

const W = 360, H = 250;
type Pt = [number, number];
const bez = (A: Pt, M: Pt, B: Pt, s: number): Pt => [(1 - s) ** 2 * A[0] + 2 * s * (1 - s) * M[0] + s * s * B[0], (1 - s) ** 2 * A[1] + 2 * s * (1 - s) * M[1] + s * s * B[1]];

function trailFn(tx: string, ty: string): ((t: number) => Pt) | null {
  try { const X = parse(tx), Y = parse(ty); return t => [evaluate(X, { vars: { t } }), evaluate(Y, { vars: { t } })]; } catch { return null; }
}

export function HikerScene({ props, marker }: SceneProps) {
  const { f, box } = useLandscape(props);
  const quiet = flag(props, "quiet");
  const formula = str<string>(props, "tx", "") ? trailFn(str<string>(props, "tx", "t"), str<string>(props, "ty", "t")) : null;
  const t0 = num(props, "t0", 1);
  const [A, setA] = useState<Pt>([-1.6, -0.4]), [M, setM] = useState<Pt>([-0.3, 0]), [B, setB] = useState<Pt>([1, 0.4]);
  const T = formula ? 2 : 4, tStart = formula ? t0 - 1 : 0;
  const at = (t: number): Pt => (formula ? formula(t) : bez(A, M, B, t / T));
  const { ref, drag } = useSvgDrag();
  const clock = useTime(!quiet, formula ? 1 : 1.6);
  const tw = formula ? t0 : quiet ? 0 : (clock % (T + 1)) > T ? T : clock % (T + 1);
  const wide = box[1] - box[0] > box[3] - box[2];
  const m = mapper(box, wide ? [6, 4, 348, 150] : [6, 10, 180, 180]);
  const strip: [number, number, number, number] = wide ? [26, 166, 324, 62] : [204, 20, 150, 196];
  const N = 160, ts = Array.from({ length: N + 1 }, (_, i) => tStart + (T * i) / N);
  const hs = ts.map(t => { const [x, y] = at(t); return f(x, y); });
  const rate = (t: number) => { const p = at(t + 1e-4), q = at(t - 1e-4); return (f(...p) - f(...q)) / 2e-4; };
  const rs = ts.map(rate);
  const span = (v: number[]) => { const lo = Math.min(...v.filter(Number.isFinite)), hi = Math.max(...v.filter(Number.isFinite)); return [lo, hi === lo ? lo + 1 : hi] as const; };
  const [h0, h1] = span(hs), [r0, r1] = span(rs);
  const SX = (t: number) => strip[0] + ((t - tStart) / T) * strip[2];
  const SY = (v: number, lo: number, hi: number) => strip[1] + strip[3] - ((v - lo) / (hi - lo)) * strip[3];
  const peakI = rs.indexOf(Math.max(...rs)), peakT = ts[peakI]!;
  const [wx, wy] = at(tw), [gx, gy] = grad(f, wx, wy);
  const dragPt = (set: (p: Pt) => void) => drag((x, y) => set([Math.round(Math.max(box[0], Math.min(box[1], m.ix(x))) * 20) / 20, Math.round(Math.max(box[2], Math.min(box[3], m.iy(y))) * 20) / 20]));
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`A walker on a trail across the contour map. At time ${nice(tw, 1)} the height is ${nice(f(wx, wy))}${quiet ? "" : ` and the rate of climb is ${nice(rate(tw))}`}.`}>
      <FlatMap f={f} box={box} m={m} levels={14}>
        <path d={path(ts.map(t => { const [x, y] = at(t); return [m.X(x), m.Y(y)] as Pt; }))} className="mvtrail" />
        {!formula && [A, M, B].map((p, i) => <circle key={i} cx={m.X(p[0])} cy={m.Y(p[1])} r="6" className="mvhandle trav" />)}
        {!formula && !quiet && <circle cx={m.X(at(peakT)[0])} cy={m.Y(at(peakT)[1])} r="5" className="mvdot pink" />}
        {!formula && [1, 2, 3].map(k => { const [x, y] = at(k); return <g key={`t${k}`}><circle cx={m.X(x)} cy={m.Y(y)} r="2.5" className="mvdot" /><text x={m.X(x)} y={m.Y(y) + 15} textAnchor="middle" className="b2t">{k}</text></g>; })}
        {marker && !formula && (() => { const [x, y] = at(marker[0]); return <circle cx={m.X(x)} cy={m.Y(y)} r="8" className="b2mark guess round" />; })()}
        <circle cx={m.X(wx)} cy={m.Y(wy)} r="7" className="mvball" />
        {!formula && [[A, setA], [M, setM], [B, setB]].map(([p, set], i) => <circle key={`h${i}`} cx={m.X((p as Pt)[0])} cy={m.Y((p as Pt)[1])} r="18" className="b2hit" {...dragPt(set as (p: Pt) => void)} />)}
      </FlatMap>
      <rect x={strip[0]} y={strip[1]} width={strip[2]} height={strip[3]} className="mvframe" />
      {!quiet && <path d={path(ts.map((t, i) => [SX(t), SY(hs[i]!, h0, h1)]))} className="b2curve sky" />}
      {!quiet && <path d={path(ts.map((t, i) => [SX(t), SY(rs[i]!, r0, r1)]))} className="b2curve pink" />}
      {!quiet && !formula && <circle cx={SX(peakT)} cy={SY(rs[peakI]!, r0, r1)} r="5" className="mvdot pink" />}
      {marker && <line x1={SX(marker[0])} y1={strip[1]} x2={SX(marker[0])} y2={strip[1] + strip[3]} className="b2mark guess" />}
      <line x1={SX(tw)} y1={strip[1]} x2={SX(tw)} y2={strip[1] + strip[3]} className="mvtrail dash" />
      {!quiet && <text x={strip[0] + 4} y={strip[1] + 14} className="b2t sky">height</text>}
      {!quiet && <text x={strip[0] + strip[2] - 4} y={strip[1] + 14} textAnchor="end" className="b2t pink">rate of climb</text>}
      {!formula && wide ? Array.from({ length: T + 1 }, (_, k) => <text key={`k${k}`} x={SX(k)} y={strip[1] + strip[3] + 14} textAnchor="middle" className="b2t">{k === T ? `${k} s` : k}</text>)
        : <text x={strip[0] + strip[2]} y={strip[1] + strip[3] + 14} textAnchor="end" className="b2t">t</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      readouts={<>
        <Read label="Time t" value={nice(tw, 1)} />
        <Read label="Height" value={fx(f(wx, wy), 2)} tone="sky" />
        <Read label="Slopes f_x, f_y" value={`${fx(gx, 2)}, ${fx(gy, 2)}`} />
        {!quiet && <Read label="Rate of climb dz/dt" value={fx(rate(tw), 2)} tone="pink" />}
        {!quiet && !formula && <Read label="Steepest climb" value={`${fx(rs[peakI]!, 2)} at t = ${nice(peakT, 1)}`} tone="pink" />}
      </>} />
  );
}

const PRESETS = [
  { label: "Two lakes", src: LAND_SRC },
  { label: "Bowl", src: "x^2 + 2*y^2" },
  { label: "Saddle", src: "x^2 - y^2" },
  { label: "Three hills", src: "exp(-(x+1)^2*3 - y^2*4) + exp(-(x-1)^2*3 - y^2*4) - 0.6*exp(-x^2*4 - (y-0.6)^2*6)" },
];

/** Project 1 · My landscape: type a formula or sculpt the ground, then keep it as `land`. */
export function MyLandScene({ props }: SceneProps) {
  const project = flag(props, "project");
  const { tool, setToolState, save, note, b2 } = useB2();
  const saved0 = tool<MineState>(MINE, { src: LAND_SRC }).src;
  const [src, setSrc] = useState(saved0);
  const [text, setText] = useState(saved0);
  const [mode, setMode] = useState<"walk" | "raise" | "dig">("walk");
  const [hx, setHx] = useState(0.5), [hy, setHy] = useState(0.5);
  const f: F2 = useMemo(() => compile(src) ?? (() => 0), [src]);
  const ok = compile(text) != null;
  const box = LAND_BOX;
  const { ref, drag } = useSvgDrag();
  const m = mapper(box, [6, 4, 348, 174]);
  const [gx, gy] = grad(f, hx, hy);
  const tap = (x: number, y: number) => {
    const X = Math.round(m.ix(x) * 20) / 20, Y = Math.round(m.iy(y) * 20) / 20;
    if (mode === "walk") { setHx(Math.max(box[0], Math.min(box[1], X))); setHy(Math.max(box[2], Math.min(box[3], Y))); return; }
    const bump = `${mode === "raise" ? "+" : "-"} 0.5*exp(-((x - ${ex(X)})^2 + (y - ${ex(Y)})^2)/0.12)`;
    const next = `${src} ${bump}`;
    setSrc(next); setText(next);
  };
  const heights = [1, 0, -1].map(y => [-2, -1, 0, 1, 2].map(x => Math.round(f(x, y) * 1000) / 1000));
  const isSaved = (b2.tools[MINE] as MineState | undefined)?.src === src && "land" in b2.shelf;
  const onSave = () => {
    setToolState(MINE, { src });
    save("land", heights, "mv-land", { note: `heights of f = ${src} at y = 1, 0, −1 (rows) and x = −2 to 2` });
    note({ id: "mv-land", track: "mv", title: "My landscape", project: "mv-land", data: { x: hx, y: hy },
      lines: [`f(x, y) = ${src}`, `The hiker at (${nice(hx)}, ${nice(hy)}): height ${fx(f(hx, hy), 3)}, slopes ${fx(gx, 2)} east and ${fx(gy, 2)} north.`] });
  };
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`Your landscape's contour map. The hiker at (${nice(hx)}, ${nice(hy)}) reads height ${nice(f(hx, hy))}.`}>
      <FlatMap f={f} box={box} m={m} levels={14}>
        <rect x={m.frame[0]} y={m.frame[1]} width={m.frame[2]} height={m.frame[3]} className="b2hit" {...drag(tap)} />
        <line x1={m.X(hx)} y1={m.Y(hy)} x2={m.X(hx) + gx * 14} y2={m.Y(hy) - gy * 14} className="mvcut pink" />
        <circle cx={m.X(hx)} cy={m.Y(hy)} r="7" className="mvball" />
      </FlatMap>
      <text x={8} y={H - 50} className="b2t">{mode === "walk" ? "tap or drag to move the hiker" : mode === "raise" ? "tap to raise a hill" : "tap to dig a hollow"}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <div className="mvform">
          <input aria-label="Your landscape, f(x, y) =" value={text} onChange={e => { setText(e.currentTarget.value); if (compile(e.currentTarget.value)) setSrc(e.currentTarget.value); }} spellCheck={false} />
          <small>{ok ? "f(x, y) =" : "Can't read that yet"}</small>
        </div>
        <span className="b2marks">{PRESETS.map(p => <button type="button" key={p.label} className={p.src === src ? "on" : undefined} onClick={() => { setSrc(p.src); setText(p.src); }}>{p.label}</button>)}</span>
        <Toggle label="What a tap does" value={mode} onChange={setMode} options={[{ v: "walk", label: "Walk" }, { v: "raise", label: "Raise" }, { v: "dig", label: "Dig" }]} />
      </>}
      readouts={<>
        <Read label="Height" value={fx(f(hx, hy), 3)} tone="trav" />
        <Read label="Slope east, f_x" value={fx(gx, 2)} tone="pink" />
        <Read label="Slope north, f_y" value={fx(gy, 2)} tone="pink" />
        <Read label="Local plane tilt" value={`${fx(gx, 2)}, ${fx(gy, 2)}`} tone="amber" />
      </>}
      foot={project && <SaveRow what={<>Keep <b>land</b>: this landscape, for every piece of the valley finder</>} saved={isSaved} onSave={onSave} />} />
  );
}
const ex = (x: number) => (x < 0 ? `(${x})` : String(x));
