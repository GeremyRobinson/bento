// The parts Multivariable's pictures share: which landscape a picture shows (a typed formula, the default "Two
// lakes", or the learner's own from project 1), a flat contour map, and a 3D view that turns with one finger and keeps
// its contour map on the floor. Overlays get the projection, so planes, balls and cuts sit in the same space.
import { useMemo, useRef, useState, type ReactNode } from "react";
import { num, str, type SceneValues } from "../../../scenes";
import { path } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { compile, contour, LAND, LAND_BOX, LAND_SRC, levelsOf, sample, type Box, type F2 } from "../maths";
import "../mv.css";

/** the learner's own landscape, kept by project 1 (My landscape) in the tools' state */
export const MINE = "mv-land";
export interface MineState { src: string }

/** A picture's landscape from its props: `src` (a typed formula), `fn: "land"` (Two lakes) or `fn: "mine"`. */
export function useLandscape(props: SceneValues): { f: F2; box: Box; src: string; mine: boolean } {
  const { tool } = useB2();
  const fn = str<string>(props, "fn", "");
  const typed = str<string>(props, "src", "");
  const mineSrc = tool<MineState>(MINE, { src: LAND_SRC }).src;
  const src = fn === "mine" ? mineSrc : fn === "land" || !typed ? LAND_SRC : typed;
  const r = num(props, "r", 0);
  return useMemo(() => {
    const f = compile(src) ?? LAND;
    const box: Box = fn === "land" || fn === "mine" || (!typed && !r) ? LAND_BOX : [-(r || 3), r || 3, -(r || 3), r || 3];
    return { f, box, src, mine: fn === "mine" };
  }, [src, fn, typed, r]);
}

/** maps a landscape box onto a rectangle of the SVG, y up */
export function mapper(box: Box, rect: [number, number, number, number]) {
  const [x0, x1, y0, y1] = box, [rx, ry, rw, rh] = rect;
  const s = Math.min(rw / (x1 - x0), rh / (y1 - y0));
  const ox = rx + (rw - s * (x1 - x0)) / 2, oy = ry + (rh - s * (y1 - y0)) / 2;
  return {
    s,
    X: (x: number) => ox + (x - x0) * s,
    Y: (y: number) => oy + (y1 - y) * s,
    ix: (px: number) => x0 + (px - ox) / s,
    iy: (py: number) => y1 - (py - oy) / s,
    frame: [ox, oy, s * (x1 - x0), s * (y1 - y0)] as [number, number, number, number],
  };
}
export type Mapper = ReturnType<typeof mapper>;

/** contour lines as one path per level, for a flat map */
export function useContours(f: F2, box: Box, levels: number | number[], n = 48) {
  return useMemo(() => {
    const g = sample(f, box, n, Math.max(8, Math.round((n * (box[3] - box[2])) / (box[1] - box[0]))));
    const ls = typeof levels === "number" ? levelsOf(g, levels) : levels;
    return { grid: g, levels: ls, segs: ls.map(l => contour(g, l)) };
  }, [f, box, typeof levels === "number" ? levels : levels.join(","), n]); // eslint-disable-line react-hooks/exhaustive-deps
}
export const segPath = (segs: [number, number, number, number][], X: (x: number) => number, Y: (y: number) => number) =>
  segs.map(([a, b, c, d]) => `M${X(a).toFixed(1)},${Y(b).toFixed(1)}L${X(c).toFixed(1)},${Y(d).toFixed(1)}`).join("");

/** A flat contour map in a rectangle: the box's frame, its contour lines, and children drawn on top. */
export function FlatMap({ f, box, m, levels = 12, hi, children, cls = "sky" }: {
  f: F2; box: Box; m: Mapper; levels?: number | number[]; hi?: number[]; children?: ReactNode; cls?: string;
}) {
  const c = useContours(f, box, levels);
  const hiSegs = useMemo(() => (hi ?? []).map(l => contour(c.grid, l)), [c.grid, hi?.join(",")]); // eslint-disable-line react-hooks/exhaustive-deps
  const [fx0, fy0, fw, fh] = m.frame;
  return (
    <g>
      <rect x={fx0} y={fy0} width={fw} height={fh} className="mvframe" />
      <path d={c.segs.map(s => segPath(s, m.X, m.Y)).join("")} className={`mvcont ${cls}`} />
      {hiSegs.map((s, i) => <path key={i} d={segPath(s, m.X, m.Y)} className="mvcont hi amber" />)}
      {children}
    </g>
  );
}

export type Proj = (x: number, y: number, z: number) => [number, number];

/**
 * A landscape in 3D, as a hairline wireframe over its contour map on the floor. Drag the empty space to turn it.
 * `overlay` gets the projection, so a cut, a plane or a ball sits on the same surface.
 */
export function View3D({ f, box, z, rect, levels = 10, overlay, yaw0 = 0.75, pitch0 = 0.62, n = 22, floor = true, hiLevels }: {
  f: F2; box: Box; z: [number, number]; rect: [number, number, number, number]; levels?: number | number[];
  overlay?: (P: Proj) => ReactNode; yaw0?: number; pitch0?: number; n?: number; floor?: boolean; hiLevels?: number[];
}) {
  const [yaw, setYaw] = useState(yaw0), [pitch, setPitch] = useState(pitch0);
  const last = useRef<{ x: number; y: number } | null>(null);
  const [x0, x1, y0, y1] = box, [zlo, zhi] = z, [rx, ry, rw, rh] = rect;
  const R = Math.max(x1 - x0, y1 - y0) / 2, xc = (x0 + x1) / 2, yc = (y0 + y1) / 2, ZH = 1.1;
  const S = Math.min(rw / 2.9, rh / (1.45 * Math.sin(pitch) * 2 + ZH * Math.cos(pitch) * 1.05));
  const cx = rx + rw / 2, cy = ry + rh / 2 + (ZH * Math.cos(pitch) * S) / 2 - 4;
  const P: Proj = (x, y, zz) => {
    const u = (x - xc) / R, v = (y - yc) / R, w = ((zz - zlo) / (zhi - zlo)) * ZH;
    const X = u * Math.cos(yaw) - v * Math.sin(yaw), Y = u * Math.sin(yaw) + v * Math.cos(yaw);
    return [cx + X * S, cy - Y * S * Math.sin(pitch) - w * S * Math.cos(pitch)];
  };
  const inZ = (v: number) => Number.isFinite(v) && v >= zlo - 1e-9 && v <= zhi + 1e-9;
  const wire = useMemo(() => {
    const out: string[] = [];
    const run = (pts: [number, number, number][]) => {
      let cur: [number, number][] = [];
      for (const [x, y, v] of pts) {
        if (inZ(v)) cur.push(P(x, y, v));
        else { if (cur.length > 1) out.push(path(cur)); cur = []; }
      }
      if (cur.length > 1) out.push(path(cur));
    };
    for (let i = 0; i <= n; i++) {
      const a: [number, number, number][] = [], b: [number, number, number][] = [];
      const u = x0 + ((x1 - x0) * i) / n, v = y0 + ((y1 - y0) * i) / n;
      for (let j = 0; j <= 48; j++) {
        const yy = y0 + ((y1 - y0) * j) / 48, xx = x0 + ((x1 - x0) * j) / 48;
        a.push([u, yy, f(u, yy)]); b.push([xx, v, f(xx, v)]);
      }
      run(a); run(b);
    }
    return out;
  }, [f, box, zlo, zhi, yaw, pitch, rect.join(",")]); // eslint-disable-line react-hooks/exhaustive-deps
  const c = useContours(f, box, levels, 40);
  const floorPath = floor ? c.segs.map(s => s.map(([a, b, cc, d]) => { const p = P(a, b, zlo), q = P(cc, d, zlo); return `M${p[0].toFixed(1)},${p[1].toFixed(1)}L${q[0].toFixed(1)},${q[1].toFixed(1)}`; }).join("")).join("") : "";
  const hiPaths = (hiLevels ?? []).map(l => contour(c.grid, l));
  const corners: [number, number][] = [[x0, y0], [x1, y0], [x1, y1], [x0, y1]];
  const floorRect = corners.map(([x, y]) => P(x, y, zlo));
  const onDown = (e: React.PointerEvent<SVGRectElement>) => { (e.target as Element).setPointerCapture?.(e.pointerId); last.current = { x: e.clientX, y: e.clientY }; };
  const onMove = (e: React.PointerEvent<SVGRectElement>) => {
    if (!last.current) return;
    const dx = e.clientX - last.current.x, dy = e.clientY - last.current.y;
    last.current = { x: e.clientX, y: e.clientY };
    setYaw(v => v + dx * 0.01);
    setPitch(p => Math.max(0.15, Math.min(1.35, p + dy * 0.008)));
  };
  const end = () => (last.current = null);
  return (
    <g>
      <rect x={rx} y={ry} width={rw} height={rh} className="b2hit mvturn" onPointerDown={onDown} onPointerMove={onMove} onPointerUp={end} onPointerCancel={end} />
      <path d={path(floorRect) + "Z"} className="mvfloor" />
      {floor && <path d={floorPath} className="mvcont sky" />}
      {hiPaths.map((s, i) => (
        <g key={i}>
          <path d={s.map(([a, b, cc, d]) => { const p = P(a, b, zlo), q = P(cc, d, zlo); return `M${p[0]},${p[1]}L${q[0]},${q[1]}`; }).join("")} className="mvcont hi amber" />
          <path d={s.map(([a, b, cc, d]) => { const p = P(a, b, hiLevels![i]!), q = P(cc, d, hiLevels![i]!); return `M${p[0]},${p[1]}L${q[0]},${q[1]}`; }).join("")} className="mvcut amber" />
        </g>
      ))}
      <g className="b2wire mvwire">{wire.map((d, i) => <path key={i} d={d} />)}</g>
      {overlay?.(P)}
    </g>
  );
}

/** an arrow from (x1, y1) to (x2, y2) in SVG units, with its head */
export function Arrow({ x1, y1, x2, y2, cls, w = 2.5 }: { x1: number; y1: number; x2: number; y2: number; cls: string; w?: number }) {
  const a = Math.atan2(y2 - y1, x2 - x1), L = Math.hypot(x2 - x1, y2 - y1), h = Math.min(8, L * 0.45);
  const hx = x2 - h * Math.cos(a), hy = y2 - h * Math.sin(a);
  return (
    <g className={`mvarrow ${cls}`}>
      <line x1={x1} y1={y1} x2={hx} y2={hy} style={{ strokeWidth: w }} />
      {L > 1 && <path d={`M${x2},${y2} L${hx - (h / 2) * Math.sin(a)},${hy + (h / 2) * Math.cos(a)} L${hx + (h / 2) * Math.sin(a)},${hy - (h / 2) * Math.cos(a)} Z`} />}
    </g>
  );
}

/** a number as the pictures print it, trimmed: 2, 2.5, −0.25 */
export const nice = (x: number, places = 2) => {
  const v = Number(x.toFixed(places));
  return (v < 0 ? "−" : "") + String(Math.abs(v));
};
