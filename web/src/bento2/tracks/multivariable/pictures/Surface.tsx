// ★ The Surface explorer (multivariable.md, tool 1): z = f(x, y) in 3D over its contour map, with a height plane that
// cuts the hill and drops its cut to the floor as one contour (01). Also the tangent-plane overlay with zoom (03).
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider, useSvgDrag } from "../../../ui/kit";
import { grad, type Box, type F2 } from "../maths";
import { FlatMap, mapper, nice, useLandscape, View3D } from "./common";

const W = 360, H = 250;

export function SurfaceScene({ props }: SceneProps) {
  const ellipse = str<string>(props, "fn", "") === "ellipse";
  const L = useLandscape(props);
  const [a, setA] = useState(num(props, "a", 1)), [b, setB] = useState(num(props, "b", 4));
  const k0 = num(props, "k", ellipse ? 4 : 0.3);
  const [k, setK] = useState(k0);
  const quiet = flag(props, "quiet"), cross = flag(props, "cross");
  const R = num(props, "r", 3);
  const f: F2 = useMemo(() => (ellipse ? (x, y) => a * x * x + b * y * y : L.f), [ellipse, a, b, L.f]);
  const box: Box = ellipse ? [-R, R, -R, R] : L.box;
  const zr: [number, number] = ellipse ? [0, Math.max(3 * k0, 12)] : [-0.3, 2.5];
  const levels = ellipse ? Array.from({ length: 8 }, (_, i) => ((i + 1) * zr[1]) / 9) : Array.from({ length: 13 }, (_, i) => -0.2 + i * 0.2);
  const m = mapper(box, ellipse ? [232, 46, 124, 124] : [228, 78, 128, 64]);
  const px = props.px, py = props.py, hasPt = typeof px === "number" && typeof py === "number";
  const xa = Math.sqrt(k / a), yb = Math.sqrt(k / b);
  const show = !quiet;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`A landscape in 3D over its contour map${show ? `, cut by a flat plane at height ${nice(k)}` : ""}. Drag to turn it.`}>
      <View3D f={f} box={box} z={zr} rect={[0, 0, 226, H]} levels={levels} floor={show} hiLevels={show ? [k] : []}
        overlay={P => <>
          {show && <path d={(box.length ? [[box[0], box[2]], [box[1], box[2]], [box[1], box[3]], [box[0], box[3]]] : []).map(([x, y], i) => { const [sx, sy] = P(x!, y!, Math.min(k, zr[1])); return `${i ? "L" : "M"}${sx},${sy}`; }).join("") + "Z"} className="mvplane amber" />}
          {hasPt && (() => { const [sx, sy] = P(px as number, py as number, Math.min(zr[1], f(px as number, py as number))); return <circle cx={sx} cy={sy} r="5" className="mvball" />; })()}
        </>} />
      <FlatMap f={f} box={box} m={m} levels={show ? levels : []} hi={show ? [k] : []}>
        {show && cross && ellipse && <>
          {[[xa, 0], [-xa, 0], [0, yb], [0, -yb]].map(([x, y], i) => <circle key={i} cx={m.X(x!)} cy={m.Y(y!)} r="3.5" className="mvdot amber" />)}
          <text x={m.X(xa)} y={m.Y(0) - 7} textAnchor="middle" className="b2t amber">{nice(xa)}</text>
          <text x={m.X(0) + 6} y={m.Y(yb) - 5} className="b2t amber">{nice(yb)}</text>
        </>}
        {hasPt && <circle cx={m.X(px as number)} cy={m.Y(py as number)} r="4" className="mvball" />}
      </FlatMap>
      {show && <text x={m.frame[0]} y={m.frame[1] - 8} className="b2t">contour map</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Height of the plane, k" value={k} min={ellipse ? 0.5 : -0.25} max={ellipse ? zr[1] * 0.9 : 2} step={ellipse ? 0.5 : 0.01} onChange={setK} format={v => nice(v)} />
        {ellipse && <Slider label="Stretch in x, a" value={a} min={0.5} max={9} step={0.5} onChange={setA} format={v => nice(v)} />}
        {ellipse && <Slider label="Stretch in y, b" value={b} min={0.5} max={9} step={0.5} onChange={setB} format={v => nice(v)} />}
      </>}
      readouts={<>
        <Read label="Plane at height" value={nice(k)} tone="amber" />
        {ellipse && show && <Read label="Crosses the x-axis at" value={`±${nice(xa)}`} />}
        {ellipse && show && <Read label="Crosses the y-axis at" value={`±${nice(yb)}`} />}
        {hasPt && <Read label={`Height at (${nice(px as number)}, ${nice(py as number)})`} value={nice(f(px as number, py as number))} tone="trav" />}
        {ellipse && <Read label="Landscape" value={`f = ${a === 1 ? "" : nice(a)}x² + ${b === 1 ? "" : nice(b)}y²`} />}
      </>} />
  );
}

/** The tangent plane at a point you drag, with a zoom: the surface flattens into the sheet (03). */
export function PlaneScene({ props }: SceneProps) {
  const L = useLandscape(props);
  const [a, setA] = useState(num(props, "a", 1)), [b, setB] = useState(num(props, "b", 1));
  const [zoom, setZoom] = useState(num(props, "zoom", 1));
  const quiet = flag(props, "quiet");
  const tx = props.tx, ty = props.ty, hasT = typeof tx === "number" && typeof ty === "number";
  const { ref, drag } = useSvgDrag();
  const { f, box } = L;
  const f0 = f(a, b), [gx, gy] = grad(f, a, b);
  const plane = (x: number, y: number) => f0 + gx * (x - a) + gy * (y - b);
  const half = Math.max(box[1] - box[0], box[3] - box[2]) / 4 / zoom;
  const vb: Box = [a - half, a + half, b - half, b + half];
  // the height range of what's in view, padded, so the window always shows the surface and its sheet
  let lo = Infinity, hi = -Infinity;
  for (let i = 0; i <= 8; i++) for (let j = 0; j <= 8; j++) {
    const x = vb[0] + ((vb[1] - vb[0]) * i) / 8, y = vb[2] + ((vb[3] - vb[2]) * j) / 8;
    for (const z of [f(x, y), plane(x, y)]) { lo = Math.min(lo, z); hi = Math.max(hi, z); }
  }
  const pad = Math.max(1e-3, (hi - lo) * 0.15);
  const m = mapper(box, [232, 70, 124, 124 * Math.min(1, (box[3] - box[2]) / (box[1] - box[0]))]);
  const est = hasT ? plane(tx as number, ty as number) : 0, tru = hasT ? f(tx as number, ty as number) : 0;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`The tangent plane at (${nice(a)}, ${nice(b)}), zoomed ${nice(zoom, 1)} times. Slopes ${nice(gx)} and ${nice(gy)}.`}>
      <View3D f={f} box={vb} z={[lo - pad, hi + pad]} rect={[0, 0, 226, H]} levels={6} floor={false} n={16}
        overlay={P => {
          const cs = [[vb[0], vb[2]], [vb[1], vb[2]], [vb[1], vb[3]], [vb[0], vb[3]]].map(([x, y]) => P(x!, y!, plane(x!, y!)));
          const [sx, sy] = P(a, b, f0);
          const t = hasT ? P(tx as number, ty as number, tru) : null, te = hasT ? P(tx as number, ty as number, est) : null;
          return <>
            <path d={cs.map(([x, y], i) => `${i ? "L" : "M"}${x},${y}`).join("") + "Z"} className="mvplane amber" />
            <circle cx={sx} cy={sy} r="5" className="mvball" />
            {t && te && <>
              <circle cx={te[0]} cy={te[1]} r="4" className="mvdot amber" />
              {!quiet && <><circle cx={t[0]} cy={t[1]} r="4" className="mvdot sky" /><line x1={t[0]} y1={t[1]} x2={te[0]} y2={te[1]} className="mvcut pink" /></>}
            </>}
          </>;
        }} />
      <FlatMap f={f} box={box} m={m} levels={10}>
        <rect x={m.X(vb[0])} y={m.Y(vb[3])} width={m.X(vb[1]) - m.X(vb[0])} height={m.Y(vb[2]) - m.Y(vb[3])} className="mvtile" />
        {hasT && <circle cx={m.X(tx as number)} cy={m.Y(ty as number)} r="3.5" className="mvdot amber" />}
        <circle cx={m.X(a)} cy={m.Y(b)} r="6" className="mvball" />
        <circle cx={m.X(a)} cy={m.Y(b)} r="18" className="b2hit" {...drag((x, y) => {
          setA(Math.round(Math.max(box[0], Math.min(box[1], m.ix(x))) * 10) / 10);
          setB(Math.round(Math.max(box[2], Math.min(box[3], m.iy(y))) * 10) / 10);
        })} />
      </FlatMap>
      <text x={m.frame[0]} y={m.frame[1] - 8} className="b2t">drag the point</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Zoom" value={zoom} min={1} max={20} step={0.5} onChange={setZoom} format={v => `${nice(v, 1)}×`} marks={[{ v: 1, label: "1×" }, { v: 4, label: "4×" }, { v: 20, label: "20×" }]} />}
      readouts={<>
        <Read label={`f(${nice(a, 1)}, ${nice(b, 1)})`} value={fx(f0, 2)} tone="trav" />
        <Read label="Tilt of the plane (f_x, f_y)" value={`${fx(gx, 2)}, ${fx(gy, 2)}`} tone="amber" />
        {hasT && <Read label={`Plane's estimate at (${nice(tx as number)}, ${nice(ty as number)})`} value={fx(est, 3)} tone="amber" />}
        {hasT && !quiet && <Read label="True height" value={fx(tru, 3)} tone="sky" />}
      </>} />
  );
}
