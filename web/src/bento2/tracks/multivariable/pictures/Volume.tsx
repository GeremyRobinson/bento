// The Volume builder (multivariable.md, tool 4): boxes on a rectangular grid under a surface (05), slices of a region
// with curved edges (06), polar boxes of rings and wedges (07), and project 2, Fill the lake.
import { useMemo, useState, type ReactElement } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, Toggle, useClock, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { lake, LAND, type Box } from "../maths";
import { FlatMap, mapper, nice, useLandscape, View3D, type Proj } from "./common";

const W = 360, H = 250;
const poly = (pts: [number, number][]) => pts.map(([x, y], i) => `${i ? "L" : "M"}${x.toFixed(1)},${y.toFixed(1)}`).join("") + "Z";

export function VolumeScene({ props }: SceneProps) {
  const L = useLandscape(props);
  const land = str<string>(props, "fn", "") === "land" || str<string>(props, "fn", "") === "mine";
  const box: Box = land ? L.box : [0, num(props, "x1", 2), 0, num(props, "y1", 2)];
  const floor = num(props, "floor", 0), f = L.f;
  const [n, setN] = useState(num(props, "n", 4));
  const quiet = flag(props, "quiet");
  const dx = (box[1] - box[0]) / n, dy = (box[3] - box[2]) / n;
  let total = 0, top = floor;
  for (let i = 0; i < n; i++) for (let j = 0; j < n; j++) {
    const h = f(box[0] + (i + 0.5) * dx, box[2] + (j + 0.5) * dy);
    total += (h - floor) * dx * dy; top = Math.max(top, h);
  }
  const exact = useMemo(() => {
    const N = 300, ex = (box[1] - box[0]) / N, ey = (box[3] - box[2]) / N;
    let s = 0;
    for (let i = 0; i < N; i++) for (let j = 0; j < N; j++) s += (f(box[0] + (i + 0.5) * ex, box[2] + (j + 0.5) * ey) - floor) * ex * ey;
    return s;
  }, [f, box.join(","), floor]); // eslint-disable-line react-hooks/exhaustive-deps
  const shown = Math.min(n, 30), sx = (box[1] - box[0]) / shown, sy = (box[3] - box[2]) / shown;
  const boxes = (P: Proj) => {
    const out: { d: number; el: ReactElement }[] = [];
    for (let i = 0; i < shown; i++) for (let j = 0; j < shown; j++) {
      const x0 = box[0] + i * sx, y0 = box[2] + j * sy, x1 = x0 + sx, y1 = y0 + sy, h = f(x0 + sx / 2, y0 + sy / 2);
      const t = [P(x0, y0, h), P(x1, y0, h), P(x1, y1, h), P(x0, y1, h)];
      const d = P(x0 + sx / 2, y0 + sy / 2, floor)[1];
      const sides = n <= 12 ? ([[[x0, y0], [x1, y0]], [[x1, y0], [x1, y1]], [[x1, y1], [x0, y1]], [[x0, y1], [x0, y0]]] as [[number, number], [number, number]][]).map(([[ax, ay], [bx, by]], k) =>
        <path key={k} d={poly([P(ax!, ay!, floor), P(bx!, by!, floor), P(bx!, by!, h), P(ax!, ay!, h)])} className="mvbox sky" />) : null;
      out.push({ d, el: <g key={`${i}-${j}`}>{sides}<path d={poly(t)} className="mvbox top sky" /></g> });
    }
    return out.sort((a, b) => a.d - b.d).map(o => o.el);
  };
  const zr: [number, number] = [floor, land ? Math.min(top, 3) : top * 1.05 + 1e-6];
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`${n * n} boxes under the surface${quiet ? "" : `, adding to ${nice(total, 3)}`}.`}>
      <View3D f={f} box={box} z={zr} rect={[0, 0, W, H]} levels={8} floor={false} n={12} overlay={boxes} />
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Boxes on each side, n" value={n} min={2} max={100} step={1} onChange={setN} marks={[{ v: 4, label: "4" }, { v: 10, label: "10" }, { v: 100, label: "100" }]} />}
      readouts={<>
        <Read label="Boxes" value={(n * n).toLocaleString("en-US")} />
        {!quiet && <Read label="Total of the boxes" value={fx(total, 3)} tone="sky" big />}
        {!quiet && <Read label="True volume" value={fx(exact, 3)} />}
      </>} />
  );
}

/** Slices of a region between two curves, vertical or horizontal (06); or a lake's shoreline on Two lakes. */
export function SweepScene({ props }: SceneProps) {
  const pick = flag(props, "pick");
  if (pick) return <PickRegion paint={flag(props, "paint")} />;
  return str<string>(props, "fn", "") === "land" ? <ShoreSweep /> : <CurveSweep k={num(props, "k", 2)} dir0={str<string>(props, "dir", "v") === "h" ? "h" : "v"} />;
}

function CurveSweep({ k, dir0 }: { k: number; dir0: "v" | "h" }) {
  const [dir, setDir] = useState<"v" | "h">(dir0);
  const [s, setS] = useState(0.5);
  const box: Box = [-0.15 * k, k * 1.12, -0.12 * k * k, k * k * 1.1];
  const m = mapper(box, [30, 8, 300, 220]);
  const xs = Array.from({ length: 81 }, (_, i) => (k * i) / 80);
  const region = [...xs.map(x => [m.X(x), m.Y(x * x)] as [number, number]), ...[...xs].reverse().map(x => [m.X(x), m.Y(k * x)] as [number, number])];
  const at = s * (dir === "v" ? k : k * k);
  const ends = dir === "v" ? [[at, at * at], [at, k * at]] : [[at / k, at], [Math.sqrt(at), at]];
  // the slices swept so far, filled
  const done: [number, number][] = dir === "v"
    ? [...xs.filter(x => x <= at).map(x => [m.X(x), m.Y(x * x)] as [number, number]), [m.X(at), m.Y(at * at)], [m.X(at), m.Y(k * at)], ...xs.filter(x => x <= at).reverse().map(x => [m.X(x), m.Y(k * x)] as [number, number])]
    : (() => { const ys = Array.from({ length: 81 }, (_, i) => (at * i) / 80); return [...ys.map(y => [m.X(y / k), m.Y(y)] as [number, number]), ...[...ys].reverse().map(y => [m.X(Math.sqrt(y)), m.Y(y)] as [number, number])]; })();
  const area = dir === "v" ? (k * at * at) / 2 - at ** 3 / 3 : (2 / 3) * at ** 1.5 - (at * at) / (2 * k);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`The region between y = x² and y = ${k === 1 ? "" : k}x, swept by a ${dir === "v" ? "vertical" : "horizontal"} line.`}>
      <line x1={m.X(box[0])} y1={m.Y(0)} x2={m.X(box[1])} y2={m.Y(0)} className="b2axis" />
      <line x1={m.X(0)} y1={m.Y(box[2])} x2={m.X(0)} y2={m.Y(box[3])} className="b2axis" />
      <path d={poly(region)} className="mvregion sky" />
      <path d={poly(done)} className="mvregion on sky" />
      <path d={path(xs.map(x => [m.X(x), m.Y(x * x)]))} className="b2curve pink" />
      <path d={path([[m.X(0), m.Y(0)], [m.X(k), m.Y(k * k)]])} className="b2curve trav" />
      <line x1={m.X(ends[0]![0]!)} y1={m.Y(ends[0]![1]!)} x2={m.X(ends[1]![0]!)} y2={m.Y(ends[1]![1]!)} className="mvcut amber" />
      {ends.map(([x, y], i) => <circle key={i} cx={m.X(x!)} cy={m.Y(y!)} r="5" className="mvdot amber" />)}
      <text x={m.X(k * 0.92)} y={m.Y(k * k * 0.92 * 0.92) + 18} className="b2t pink">y = x²</text>
      <text x={m.X(k * 0.55) - 8} y={m.Y(k * k * 0.55) - 8} textAnchor="end" className="b2t trav">y = {k === 1 ? "" : k}x</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Toggle label="Slices" value={dir} onChange={setDir} options={[{ v: "v", label: "Vertical slices" }, { v: "h", label: "Horizontal slices" }]} />
        <Slider label={dir === "v" ? "Sweep x" : "Sweep y"} value={s} min={0} max={1} step={0.005} onChange={setS} format={v => nice(v * (dir === "v" ? k : k * k))} />
      </>}
      readouts={<>
        <Read label="This slice runs" value={dir === "v" ? `y = ${nice(at * at)} to ${nice(k * at)}` : `x = ${nice(at / k)} to ${nice(Math.sqrt(at))}`} tone="amber" />
        <Read label="Area swept" value={fx(area, 3)} tone="sky" />
        <Read label="Whole region" value={fx(k ** 3 / 6, 3)} />
      </>} />
  );
}

const THUMBS: { label: string; inside: (x: number, y: number) => boolean }[] = [
  { label: "A", inside: (x, y) => y <= x },
  { label: "B", inside: (x, y) => y >= x * x && y <= x },
  { label: "C", inside: (x, y) => y >= x },
  { label: "D", inside: (x, y) => x + y <= 1 },
];
function PickRegion({ paint }: { paint: boolean }) {
  const t = useClock(paint, 9);
  const sweep = paint ? Math.min(1, t / 2) : 0;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`Four shaded regions in the unit square, A to D.${paint ? " C is painted by the sweep." : ""}`}>
      {THUMBS.map((th, i) => {
        const ox = 40 + (i % 2) * 160, oy = 14 + Math.floor(i / 2) * 118, s = 96;
        const cells: ReactElement[] = [];
        const N = 24;
        for (let a = 0; a < N; a++) for (let b = 0; b < N; b++) {
          const x = (a + 0.5) / N, y = (b + 0.5) / N;
          if (th.inside(x, y)) cells.push(<rect key={`${a}-${b}`} x={ox + (a / N) * s} y={oy + s - ((b + 1) / N) * s} width={s / N + 0.3} height={s / N + 0.3} className={`mvbasin ${paint && i === 2 && x <= sweep ? "amber" : "sky"}`} />);
        }
        return (
          <g key={th.label}>
            {cells}
            <rect x={ox} y={oy} width={s} height={s} className={`mvthumb${paint && i === 2 ? " on" : ""}`} />
            {paint && i === 2 && sweep > 0 && <line x1={ox + sweep * s} y1={oy + s - sweep * s} x2={ox + sweep * s} y2={oy} className="mvcut amber" />}
            <text x={ox - 8} y={oy + 14} textAnchor="end" className="b2t">{th.label}</text>
          </g>
        );
      })}
    </svg>
  );
  return <Scene svg={svg} readouts={<Read label="Each square" value="0 ≤ x ≤ 1, 0 ≤ y ≤ 1" />} />;
}

/** On Two lakes: the shoreline f = 0 around the left valley, filled by vertical slices whose ends ride it. */
function ShoreSweep() {
  const g = (x: number) => -(((x * x - 1) ** 2) + x / 4);
  const xs = Array.from({ length: 401 }, (_, i) => -2 + i / 100).filter(x => x < 0.06 && g(x) > 0);
  const lo = xs[0]!, hi = xs[xs.length - 1]!;
  const [s, setS] = useState(0.5);
  const at = lo + s * (hi - lo), half = Math.sqrt(Math.max(0, g(at)));
  const m = mapper([-2, 2, -1, 1], [6, 4, 348, 174]);
  const top = xs.map(x => [m.X(x), m.Y(Math.sqrt(g(x)))] as [number, number]), bot = xs.map(x => [m.X(x), m.Y(-Math.sqrt(g(x)))] as [number, number]);
  const done = xs.filter(x => x <= at);
  let area = 0;
  for (const x of done) area += 2 * Math.sqrt(g(x)) * 0.01;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label="The left lake's shoreline on Two lakes, filled by vertical slices.">
      <FlatMap f={LAND} box={[-2, 2, -1, 1]} m={m} levels={12}>
        <path d={poly([...top, ...[...bot].reverse()])} className="mvregion sky" />
        {done.length > 1 && <path d={poly([...done.map(x => [m.X(x), m.Y(Math.sqrt(g(x)))] as [number, number]), ...[...done].reverse().map(x => [m.X(x), m.Y(-Math.sqrt(g(x)))] as [number, number])])} className="mvwater" />}
        <line x1={m.X(at)} y1={m.Y(half)} x2={m.X(at)} y2={m.Y(-half)} className="mvcut amber" />
        <circle cx={m.X(at)} cy={m.Y(half)} r="4" className="mvdot amber" /><circle cx={m.X(at)} cy={m.Y(-half)} r="4" className="mvdot amber" />
      </FlatMap>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Sweep x" value={s} min={0} max={1} step={0.005} onChange={setS} format={v => nice(lo + v * (hi - lo))} />}
      readouts={<>
        <Read label="Slice ends on the shore" value={`y = ±${nice(half)}`} tone="amber" />
        <Read label="Surface swept" value={fx(area, 3)} tone="mint" />
      </>} />
  );
}

/** Polar boxes: rings and wedges, each box's area r Δr Δθ (07). */
export function PolarScene({ props }: SceneProps) {
  const R = num(props, "R", 2), a = num(props, "a", 0), part = num(props, "part", 0);
  const [rings, setRings] = useState(num(props, "rings", 4)), [wedges, setWedges] = useState(num(props, "wedges", 12));
  const pair = flag(props, "pair"), quiet = flag(props, "quiet"), pond = flag(props, "pond");
  const [sel, setSel] = useState<[number, number]>([rings - 1, 1]);
  const span = [2 * Math.PI, Math.PI, Math.PI / 2, 2 * Math.PI][part]!, dr = (R - a) / rings, dt = span / wedges;
  const S = 105 / R, cx = 180, cy = part === 1 || part === 2 ? 190 : 122;
  const P = (r: number, t: number): [number, number] => [cx + r * S * Math.cos(t), cy - r * S * Math.sin(t)];
  const boxPath = (i: number, j: number) => {
    const r1 = a + i * dr, r2 = r1 + dr, t1 = j * dt, t2 = t1 + dt;
    const arc = (r: number, from: number, to: number) => Array.from({ length: 7 }, (_, k) => P(r, from + ((to - from) * k) / 6));
    return poly([...arc(r1, t1, t2), ...arc(r2, t2, t1)]);
  };
  const area = (i: number) => (((a + (i + 1) * dr) ** 2 - (a + i * dr) ** 2) / 2) * dt;
  const hl = pair ? [[0, 1], [1, 2]] : [sel];
  let pondV = 0;
  if (pond) for (let i = 0; i < rings; i++) { const rc = a + (i + 0.5) * dr; pondV += (1 - rc * rc) * area(i) * wedges; }
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`A ${part === 1 ? "half " : part === 2 ? "quarter " : ""}disk cut into ${rings * wedges} polar boxes.`}>
      {Array.from({ length: rings }, (_, i) => Array.from({ length: wedges }, (_, j) => {
        const on = hl.some(([hi, hj]) => hi === i && hj === j), depth = pond ? 1 - (a + (i + 0.5) * dr) ** 2 : 0;
        return <path key={`${i}-${j}`} d={boxPath(i, j)} className={`mvbox ${on ? "top amber" : pond ? "mint" : "sky"}`} style={pond ? { fillOpacity: 0.15 + depth * 0.5 } : undefined}
          onClick={() => !pair && setSel([i, j])} />;
      }))}
      {pair && !quiet && hl.map(([i, j], k) => { const [x, y] = P(a + (i! + 0.5) * dr, (j! + 0.5) * dt); return <text key={k} x={x + (k ? 10 : 6)} y={y - 12} className="b2t amber">{nice(area(i!), 3)}</text>; })}
      {pair && hl.map(([i, j], k) => { const [x, y] = P(a + (i! + 0.5) * dr, (j! + 0.5) * dt); return <circle key={`c${k}`} cx={x} cy={y} r="3" className="mvdot amber" />; })}
      <circle cx={cx} cy={cy} r="2.5" className="mvdot" />
    </svg>
  );
  const [si] = sel;
  return (
    <Scene svg={svg}
      controls={!pair ? <>
        <Slider label="Rings" value={rings} min={1} max={16} step={1} onChange={v => { setRings(v); setSel([Math.min(sel[0], v - 1), sel[1]]); }} />
        <Slider label="Wedges" value={wedges} min={4} max={36} step={1} onChange={v => { setWedges(v); setSel([sel[0], Math.min(sel[1], v - 1)]); }} />
      </> : undefined}
      readouts={<>
        <Read label="Δr" value={nice(dr, 3)} />
        <Read label="Δθ" value={nice(dt, 3)} />
        {pair ? !quiet && <Read label="Outer box ÷ inner box" value={nice(area(1) / area(0), 3)} tone="amber" big />
          : <Read label={`Box at r ≈ ${nice(a + (si + 0.5) * dr)}`} value={`area ${nice(area(si), 4)}`} tone="amber" />}
        {pond && <Read label="Water in the pond" value={`${fx(pondV, 3)} (π/2 = ${fx(Math.PI / 2, 3)})`} tone="mint" big />}
        {!pair && !pond && <Read label="All boxes" value={fx(area(0) * 0 + ((R * R - a * a) / 2) * span, 3)} />}
      </>} />
  );
}

/** Project 2 · Fill the lake: tap a low spot, set the water level; the basin fills, with its volume and area. */
export function LakeScene({ props }: SceneProps) {
  const L = useLandscape({ ...props, fn: "mine" });
  const project = flag(props, "project");
  const { b2, save, note } = useB2();
  const { f, box } = L;
  const [spot, setSpot] = useState<[number, number]>([-1.03, 0]);
  const [level, setLevel] = useState(0);
  const { ref, drag } = useSvgDrag();
  const m = mapper(box, [6, 4, 348, 160]);
  const lk = useMemo(() => lake(f, box, spot[0], spot[1], level), [f, box, spot, level]);
  const rows: ReactElement[] = [];
  const cw = (box[1] - box[0]) / lk.nx, ch = (box[3] - box[2]) / lk.ny;
  for (let j = 0; j < lk.ny; j++) {
    let i = 0;
    while (i < lk.nx) {
      if (!lk.wet[j * lk.nx + i]) { i++; continue; }
      const s = i;
      while (i < lk.nx && lk.wet[j * lk.nx + i]) i++;
      rows.push(<rect key={`${j}-${s}`} x={m.X(box[0] + s * cw)} y={m.Y(box[2] + (j + 1) * ch)} width={(i - s) * cw * m.s + 0.4} height={ch * m.s + 0.4} className="mvwater" />);
    }
  }
  // the cross-section through the spot, along x
  const sec: [number, number, number, number] = [26, 184, 324, 52];
  const xs = Array.from({ length: 121 }, (_, i) => box[0] + ((box[1] - box[0]) * i) / 120);
  const gz = xs.map(x => f(x, spot[1])), z0 = Math.min(...gz, level) - 0.05, z1 = Math.min(Math.max(...gz), level + 1.5);
  const SX = (x: number) => sec[0] + ((x - box[0]) / (box[1] - box[0])) * sec[2], SZ = (z: number) => sec[1] + sec[3] - ((Math.min(z1, z) - z0) / (z1 - z0)) * sec[3];
  const wetX = xs.filter(x => { const i = Math.min(lk.nx - 1, Math.floor((x - box[0]) / cw)), j = Math.min(lk.ny - 1, Math.floor((spot[1] - box[2]) / ch)); return lk.wet[j * lk.nx + i] === 1; });
  const saved = Math.abs(((b2.shelf.lakeVolume?.value as number) ?? NaN) - lk.volume) < 1e-9;
  const onSave = () => {
    save("lakeVolume", lk.volume, "mv-lake", { note: `the lake at (${nice(spot[0])}, ${nice(spot[1])}) filled to height ${nice(level)}` });
    save("lakeArea", lk.area, "mv-lake", { note: `its surface area` });
    note({ id: "mv-lake", track: "mv", title: "Fill the lake", project: "mv-lake", data: { x: spot[0], y: spot[1], level },
      lines: [`A lake at (${nice(spot[0])}, ${nice(spot[1])}) filled to height ${nice(level)}.`, `Volume ${fx(lk.volume, 3)}, surface area ${fx(lk.area, 3)}.`] });
  };
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`A lake around (${nice(spot[0])}, ${nice(spot[1])}) filled to height ${nice(level)}: volume ${nice(lk.volume, 3)}, area ${nice(lk.area, 3)}.`}>
      <FlatMap f={f} box={box} m={m} levels={14}>
        {rows}
        <rect x={m.frame[0]} y={m.frame[1]} width={m.frame[2]} height={m.frame[3]} className="b2hit" {...drag((x, y) => setSpot([Math.max(box[0], Math.min(box[1], m.ix(x))), Math.max(box[2], Math.min(box[3], m.iy(y)))]))} />
        <circle cx={m.X(spot[0])} cy={m.Y(spot[1])} r="6" className="mvball" />
      </FlatMap>
      <rect x={sec[0]} y={sec[1]} width={sec[2]} height={sec[3]} className="mvframe" />
      {wetX.length > 0 && <rect x={SX(wetX[0]!)} y={SZ(level)} width={SX(wetX[wetX.length - 1]!) - SX(wetX[0]!)} height={Math.max(0, sec[1] + sec[3] - SZ(level))} className="mvwater" />}
      <path d={path(xs.map((x, i) => [SX(x), SZ(gz[i]!)]))} className="b2curve sky" />
      <text x={sec[0]} y={sec[1] - 6} className="b2t">cross-section through the spot</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Water level" value={level} min={-0.3} max={1} step={0.01} onChange={setLevel} format={v => nice(v)} />}
      readouts={<>
        <Read label="Lake volume" value={fx(lk.volume, 3)} tone="mint" big />
        <Read label="Surface area" value={fx(lk.area, 3)} tone="mint" />
        <Read label="Deepest" value={fx(Math.max(0, level - f(spot[0], spot[1])), 3)} />
      </>}
      foot={project && <SaveRow what={<>Keep <b>lakeVolume = {fx(lk.volume, 3)}</b> and <b>lakeArea = {fx(lk.area, 3)}</b></>} saved={saved} onSave={onSave} />} />
  );
}
