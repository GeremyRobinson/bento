// The Best-choice finder's fences (multivariable.md, tool 10): walk a fence with ∇f and ∇g at your feet and a height
// meter, and watch the arrows line up at the best spot (15); a square plot on a bowl with its boundary scan unrolled
// into a graph (16); and project 4, Best spot in the park.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { descend, grad, type Box, type F2 } from "../maths";
import { Arrow, FlatMap, mapper, nice, useLandscape } from "./common";

const W = 360, H = 250;

export function FenceScene(sp: SceneProps) {
  const mode = str<string>(sp.props, "mode", "line");
  if (mode === "square") return <SquarePlot {...sp} />;
  return <FenceWalk {...sp} road={mode === "road"} />;
}

/** a fence g(x, y) = c, walked by one number s: the line px + qy = c (by x), or a road y = c on a landscape (by x) */
function FenceWalk({ props, marker, road }: SceneProps & { road: boolean }) {
  const L = useLandscape(road ? props : {});
  const p = num(props, "fp", 1), q = num(props, "fq", 2), c0 = num(props, "fc", 8), r2 = str<string>(props, "obj", "xy") === "r2";
  const [c, setC] = useState(road ? num(props, "road", 0.5) : c0);
  const quiet = flag(props, "quiet");
  const f: F2 = road ? L.f : r2 ? (x, y) => x * x + y * y : (x, y) => x * y;
  const box: Box = road ? L.box : [0, (c0 / p) * 1.12, 0, (c0 / q) * 1.12];
  const sMin = road ? box[0] : 0, sMax = road ? box[1] : c / p;
  const [s, setS] = useState(num(props, "s", road ? 0 : 2));
  const at = (x: number): [number, number] => (road ? [x, c] : [x, (c - p * x) / q]);
  const gG: [number, number] = road ? [0, 1] : [p, q];
  const [x, y] = at(Math.min(sMax, s)), [gx, gy] = grad(f, x, y);
  const xs = Array.from({ length: 201 }, (_, i) => sMin + ((sMax - sMin) * i) / 200), fs = xs.map(v => f(...at(v)));
  const want = road || r2 ? Math.min(...fs) : Math.max(...fs), bi = fs.indexOf(want), bx = xs[bi]!;
  const lam = Math.hypot(gx, gy) / Math.hypot(...gG) * Math.sign(gx * gG[0] + gy * gG[1] || 1);
  const cross = (gx * gG[1] - gy * gG[0]) / (Math.hypot(gx, gy) * Math.hypot(...gG) || 1);
  const wide = box[1] - box[0] > (box[3] - box[2]) * 1.4;
  const m = mapper(box, wide ? [6, 4, 348, 160] : [6, 6, 200, 200]);
  const strip: [number, number, number, number] = wide ? [26, 182, 324, 52] : [220, 30, 134, 160];
  const z0 = Math.min(...fs), z1 = Math.max(...fs.map(v => (road ? Math.min(v, 2) : v))) + 1e-6;
  const SX = (v: number) => strip[0] + ((v - sMin) / (sMax - sMin)) * strip[2], SZ = (z: number) => strip[1] + strip[3] - ((Math.min(z1, z) - z0) / (z1 - z0)) * strip[3];
  const { ref, drag } = useSvgDrag();
  const unit = (v: [number, number], l = 30): [number, number] => { const n = Math.hypot(...v) || 1; return [(v[0] / n) * l, (v[1] / n) * l]; };
  const [ax, ay] = unit([gx, gy]), [bx2, by2] = unit(gG, 24);
  const sx = m.X(x), sy = m.Y(y);
  const fence = road ? [[box[0], c], [box[1], c]] : [[0, c / q], [c / p, 0]];
  const guess = marker?.[0];
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={quiet ? "A fence across the contour map, with ∇f and ∇g at the walker." : `Walking the fence: at (${nice(x)}, ${nice(y)}) the height is ${nice(f(x, y), 3)}. ∇f and ∇g ${Math.abs(cross) < 0.02 ? "line up" : "point different ways"}.`}>
      <FlatMap f={f} box={box} m={m} levels={road ? 14 : r2 ? [1, 4, 9, 16, 25, 36, 49, 64, 100, 144, 196, 256].map(v => (v * c0 * c0) / 256) : Array.from({ length: 10 }, (_, i) => ((i + 1) * (c0 * c0)) / (4 * p * q * 6))}>
        <line x1={m.X(fence[0]![0]!)} y1={m.Y(fence[0]![1]!)} x2={m.X(fence[1]![0]!)} y2={m.Y(fence[1]![1]!)} className="mvfence" />
        {!quiet && <circle cx={m.X(at(bx)[0])} cy={m.Y(at(bx)[1])} r="9" className="b2mark amber" />}
        {guess != null && <circle cx={m.X(at(guess)[0])} cy={m.Y(at(guess)[1])} r="9" className="b2mark guess round" />}
        <Arrow x1={sx} y1={sy} x2={sx + ax} y2={sy - ay} cls="pink" w={3} />
        <Arrow x1={sx} y1={sy} x2={sx + bx2} y2={sy - by2} cls="amber" w={2.4} />
        <circle cx={sx} cy={sy} r="6" className="mvball" />
        {!quiet && <circle cx={sx} cy={sy} r="18" className="b2hit" {...drag(px => setS(Math.round(Math.max(sMin, Math.min(sMax, m.ix(px))) * 20) / 20))} />}
      </FlatMap>
      <text x={m.X(fence[1]![0]!) - 4} y={m.Y(fence[1]![1]!) - 8} textAnchor="end" className="b2t amber">{road ? `road y = ${nice(c)}` : "fence"}</text>
      {!quiet && <rect x={strip[0]} y={strip[1]} width={strip[2]} height={strip[3]} className="mvframe" />}
      {!quiet && <path d={path(xs.map((v, i) => [SX(v), SZ(fs[i]!)]))} className="b2curve sky" />}
      {!quiet && <circle cx={SX(bx)} cy={SZ(want)} r="4.5" className="mvdot amber" />}
      {!quiet && <>
      <line x1={SX(Math.min(sMax, s))} y1={strip[1]} x2={SX(Math.min(sMax, s))} y2={strip[1] + strip[3]} className="mvtrail dash" />
      <text x={strip[0]} y={strip[1] - 6} className="b2t sky">height along the {road ? "road" : "fence"}</text>
      </>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <>
        <Slider label={`Walk along the ${road ? "road" : "fence"}: x`} value={Math.min(sMax, s)} min={sMin} max={sMax} step={0.05} onChange={setS} format={v => nice(v)} />
        <Slider label={road ? "Move the road: y =" : `Loosen the fence: ${p === 1 ? "" : p}x + ${q === 1 ? "" : q}y =`} value={c} min={road ? -0.9 : c0 * 0.5} max={road ? 0.9 : c0 * 1.5} step={road ? 0.05 : 0.5} onChange={setC} format={v => nice(v)} />
      </>}
      readouts={<>
        {!quiet && <Read label={`f(${nice(x)}, ${nice(y)})`} value={fx(f(x, y), 3)} tone="sky" />}
        {!quiet && <Read label="∇f" value={`⟨${fx(gx, 2)}, ${fx(gy, 2)}⟩`} tone="pink" />}
        <Read label="∇g" value={`⟨${nice(gG[0])}, ${nice(gG[1])}⟩`} tone="amber" />
        {!quiet && <Read label="Lined up?" value={Math.abs(cross) < 0.02 ? `yes, λ = ${fx(lam, 2)}` : "not yet"} tone={Math.abs(cross) < 0.02 ? "amber" : undefined} />}
        {!quiet && <Read label={road || r2 ? "Lowest on it" : "Highest on it"} value={`${fx(want, 3)} at (${nice(at(bx)[0])}, ${nice(at(bx)[1])})`} tone="amber" />}
      </>} />
  );
}

/** A square plot [0, m]² on the bowl (x − p)² + (y − q)²: drag the bottom or the corner; the candidates light up. */
function SquarePlot({ props }: SceneProps) {
  const [pq, setPq] = useState<[number, number]>([num(props, "p", 1), num(props, "q", 1)]);
  const [m0, setM] = useState(num(props, "m", 2));
  const quiet = flag(props, "quiet");
  const [p, q] = pq;
  const f = (x: number, y: number) => (x - p) ** 2 + (y - q) ** 2;
  const box: Box = [-2.5, 5.5, -2.5, 5.5];
  const mp = mapper(box, [6, 6, 200, 200]);
  const { ref, drag } = useSvgDrag();
  const cl = (v: number) => Math.max(0, Math.min(m0, v));
  const corners: [number, number][] = [[0, 0], [m0, 0], [m0, m0], [0, m0]];
  const low: [number, number] = [cl(p), cl(q)];
  const high = corners.reduce((b, c) => (f(...c) > f(...b) ? c : b), corners[0]!);
  // the boundary scan: walk the fence from (0, 0) counterclockwise and unroll its height
  const per = 4 * m0, ss = Array.from({ length: 201 }, (_, i) => (per * i) / 200);
  const onFence = (s: number): [number, number] => { const k = Math.min(3, Math.floor(s / m0)), u = s - k * m0; return [[u, 0], [m0, u], [m0 - u, m0], [0, m0 - u]][k] as [number, number]; };
  const hs = ss.map(s => f(...onFence(s)));
  const strip: [number, number, number, number] = [222, 30, 132, 160], z1 = Math.max(...hs) + 1e-6, z0 = Math.min(0, ...hs);
  const SX = (s: number) => strip[0] + (s / per) * strip[2], SZ = (z: number) => strip[1] + strip[3] - ((z - z0) / (z1 - z0)) * strip[3];
  const inside = p >= 0 && p <= m0 && q >= 0 && q <= m0;
  const levels = [0.5, 1, 2, 4, 6, 9, 12, 16, 20, 25, 32];
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`A square plot from 0 to ${nice(m0)} on a bowl with its bottom at (${nice(p)}, ${nice(q)})${quiet ? "" : `. Lowest at (${nice(low[0])}, ${nice(low[1])}), ${inside ? "inside" : "on the fence"}`}.`}>
      <FlatMap f={f} box={box} m={mp} levels={levels}>
        <rect x={mp.X(0)} y={mp.Y(m0)} width={m0 * mp.s} height={m0 * mp.s} className="mvpark" />
        <circle cx={mp.X(p)} cy={mp.Y(q)} r="5" className="mvdot sky" />
        {!quiet && <>
          {corners.map((c, i) => <circle key={i} cx={mp.X(c[0])} cy={mp.Y(c[1])} r="3.5" className="mvdot amber" />)}
          <circle cx={mp.X(low[0])} cy={mp.Y(low[1])} r="7" className="mvball" />
          <circle cx={mp.X(high[0])} cy={mp.Y(high[1])} r="7" className="mvdot pink" />
        </>}
        <circle cx={mp.X(p)} cy={mp.Y(q)} r="18" className="b2hit" {...drag((x, y) => setPq([Math.round(mp.ix(x) * 2) / 2, Math.round(mp.iy(y) * 2) / 2]))} />
        <circle cx={mp.X(m0)} cy={mp.Y(m0)} r="7" className="mvhandle amber" />
        <circle cx={mp.X(m0)} cy={mp.Y(m0)} r="18" className="b2hit" {...drag(x => setM(Math.max(1, Math.min(5, Math.round(mp.ix(x))))))} />
      </FlatMap>
      <rect x={strip[0]} y={strip[1]} width={strip[2]} height={strip[3]} className="mvframe" />
      {[1, 2, 3].map(k => <line key={k} x1={SX(k * m0)} y1={strip[1]} x2={SX(k * m0)} y2={strip[1] + strip[3]} className="b2grid strong" />)}
      <path d={path(ss.map((s, i) => [SX(s), SZ(hs[i]!)]))} className="b2curve sky" />
      {!quiet && (() => { const lo = Math.min(...hs), hi = Math.max(...hs); return <>
        <circle cx={SX(ss[hs.indexOf(lo)]!)} cy={SZ(lo)} r="4.5" className="mvdot trav" />
        <circle cx={SX(ss[hs.indexOf(hi)]!)} cy={SZ(hi)} r="4.5" className="mvdot pink" />
      </>; })()}
      <text x={strip[0] + 4} y={strip[1] - 8} className="b2t sky">the fence, unrolled</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      readouts={<>
        <Read label="Bowl's bottom" value={quiet ? `(${nice(p)}, ${nice(q)})` : `(${nice(p)}, ${nice(q)}), ${inside ? "inside" : "outside"}`} tone="sky" />
        {!quiet && <Read label="Lowest" value={`${fx(f(...low), 2)} at (${nice(low[0])}, ${nice(low[1])})`} tone="trav" />}
        {!quiet && <Read label="Highest" value={`${fx(f(...high), 2)} at a corner (${nice(high[0])}, ${nice(high[1])})`} tone="pink" />}
      </>} />
  );
}

/** Project 4 · Best spot in the park: a fence you drag on your landscape, its lowest point, and a road with λ. */
export function ParkScene({ props }: SceneProps) {
  const { f, box } = useLandscape({ ...props, fn: "mine" });
  const project = flag(props, "project");
  const { b2, save, note } = useB2();
  const [A, setA] = useState<[number, number]>([-1.6, -0.6]), [B, setB] = useState<[number, number]>([-0.4, 0.7]);
  const [road, setRoad] = useState(0.5);
  const fenceBox: Box = [Math.min(A[0], B[0]), Math.max(A[0], B[0]), Math.min(A[1], B[1]), Math.max(A[1], B[1])];
  const best = useMemo(() => {
    let bv = Infinity, bp: [number, number] = [0, 0];
    for (let i = 0; i <= 40; i++) for (let j = 0; j <= 40; j++) {
      const x = fenceBox[0] + ((fenceBox[1] - fenceBox[0]) * i) / 40, y = fenceBox[2] + ((fenceBox[3] - fenceBox[2]) * j) / 40, v = f(x, y);
      if (v < bv) { bv = v; bp = [x, y]; }
    }
    const run = descend(f, bp[0], bp[1], 0.005, 400, { clamp: fenceBox }), end = run[run.length - 1]!;
    return { x: end[0], y: end[1], z: f(end[0], end[1]) };
  }, [f, fenceBox.join(",")]); // eslint-disable-line react-hooks/exhaustive-deps
  const onRoad = useMemo(() => {
    let bv = Infinity, bx = 0;
    for (let i = 0; i <= 4000; i++) { const x = box[0] + ((box[1] - box[0]) * i) / 4000, v = f(x, road); if (v < bv) { bv = v; bx = x; } }
    return { x: bx, z: bv, lam: grad(f, bx, road)[1] };
  }, [f, box, road]);
  const m = mapper(box, [6, 4, 348, 174]);
  const { ref, drag } = useSvgDrag();
  const onBorder = best.x <= fenceBox[0] + 1e-3 || best.x >= fenceBox[1] - 1e-3 || best.y <= fenceBox[2] + 1e-3 || best.y >= fenceBox[3] - 1e-3;
  const saved = Array.isArray(b2.shelf.fencedBest?.value) && Math.abs((b2.shelf.fencedBest!.value as number[])[2]! - best.z) < 1e-9;
  const onSave = () => {
    save("fencedBest", [best.x, best.y, best.z], "mv-park", { labels: ["x", "y", "height"], note: "the lowest point inside your park fence" });
    note({ id: "mv-park", track: "mv", title: "Best spot in the park", project: "mv-park", data: { x0: fenceBox[0], x1: fenceBox[1], y0: fenceBox[2], y1: fenceBox[3], road },
      lines: [`Park from (${nice(fenceBox[0])}, ${nice(fenceBox[2])}) to (${nice(fenceBox[1])}, ${nice(fenceBox[3])}): lowest at (${nice(best.x)}, ${nice(best.y)}), height ${fx(best.z, 3)}${onBorder ? ", on the fence" : ", inside"}.`,
        `Road y = ${nice(road)}: lowest at x = ${nice(onRoad.x)}, height ${fx(onRoad.z, 3)}, λ = ${fx(onRoad.lam, 2)}.`] });
  };
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`A park fence on your landscape. Its lowest point is at (${nice(best.x)}, ${nice(best.y)}), height ${nice(best.z, 3)}.`}>
      <FlatMap f={f} box={box} m={m} levels={14}>
        <rect x={m.X(fenceBox[0])} y={m.Y(fenceBox[3])} width={(fenceBox[1] - fenceBox[0]) * m.s} height={(fenceBox[3] - fenceBox[2]) * m.s} className="mvpark" />
        <line x1={m.X(box[0])} y1={m.Y(road)} x2={m.X(box[1])} y2={m.Y(road)} className="mvfence dash" />
        <circle cx={m.X(onRoad.x)} cy={m.Y(road)} r="6" className="mvdot amber" />
        <Arrow x1={m.X(onRoad.x)} y1={m.Y(road)} x2={m.X(onRoad.x)} y2={m.Y(road) - Math.max(-30, Math.min(30, onRoad.lam * 18))} cls="pink" />
        <circle cx={m.X(best.x)} cy={m.Y(best.y)} r="7" className="mvball" />
        {([[A, setA], [B, setB]] as const).map(([p, set], i) => <g key={i}>
          <circle cx={m.X(p[0])} cy={m.Y(p[1])} r="6" className="mvhandle amber" />
          <circle cx={m.X(p[0])} cy={m.Y(p[1])} r="18" className="b2hit" {...drag((x, y) => set([Math.round(Math.max(box[0], Math.min(box[1], m.ix(x))) * 20) / 20, Math.round(Math.max(box[2], Math.min(box[3], m.iy(y))) * 20) / 20]))} />
        </g>)}
      </FlatMap>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Road y =" value={road} min={-0.9} max={0.9} step={0.05} onChange={setRoad} format={v => nice(v)} />}
      readouts={<>
        <Read label="Lowest in the park" value={`(${fx(best.x, 2)}, ${fx(best.y, 2)}), height ${fx(best.z, 3)}`} tone="trav" />
        <Read label="Where" value={onBorder ? "on the fence" : "inside"} />
        <Read label="Lowest on the road" value={`x = ${fx(onRoad.x, 2)}, height ${fx(onRoad.z, 3)}`} tone="amber" />
        <Read label="λ there" value={fx(onRoad.lam, 2)} tone="pink" />
      </>}
      foot={project && <SaveRow what={<>Keep <b>fencedBest</b>: the pond's spot and height</>} saved={saved} onSave={onSave} />} />
  );
}
