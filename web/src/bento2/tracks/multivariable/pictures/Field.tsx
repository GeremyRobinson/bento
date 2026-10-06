// The Vector field painter (multivariable.md, tool 6): arrows, flowing particles, a paddle wheel (the curl meter) and
// a drop of dye that grows or shrinks (the divergence meter) (09). Loop mode: the push along a path, its work meter,
// and curl × area beside it for Green's theorem (10). On Two lakes it paints the water, −∇f.
import type { ReactElement } from "react";
import { useMemo, useRef, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, useSvgDrag } from "../../../ui/kit";
import { grad, LAND, LAND_BOX, seeded, type Box } from "../maths";
import { compile } from "../maths";
import { useTime, Arrow, mapper, nice } from "./common";

const W = 360, H = 250;
type V2 = (x: number, y: number) => [number, number];
const h = 1e-4;
const divOf = (F: V2, x: number, y: number) => (F(x + h, y)[0] - F(x - h, y)[0] + F(x, y + h)[1] - F(x, y - h)[1]) / (2 * h);
const curlOf = (F: V2, x: number, y: number) => (F(x + h, y)[1] - F(x - h, y)[1] - F(x, y + h)[0] + F(x, y - h)[0]) / (2 * h);

export function FieldScene({ props }: SceneProps) {
  const land = str<string>(props, "fn", "") === "land";
  const Ps = str<string>(props, "P", ""), Qs = str<string>(props, "Q", "");
  const typed = !!Ps && !!Qs;
  const mode = str<string>(props, "mode", "paint");
  const quiet = flag(props, "quiet");
  const [a, setA] = useState(num(props, "a", 0)), [b, setB] = useState(num(props, "b", -1));
  const [c, setC] = useState(num(props, "c", 1)), [d, setD] = useState(num(props, "d", 0));
  const F: V2 = useMemo(() => {
    if (land) return (x, y) => { const [gx, gy] = grad(LAND, x, y); return [-gx, -gy]; };
    if (typed) { const P = compile(Ps), Q = compile(Qs); if (P && Q) return (x, y) => [P(x, y), Q(x, y)]; }
    return (x, y) => [a * x + b * y, c * x + d * y];
  }, [land, typed, Ps, Qs, a, b, c, d]);
  const box: Box = land ? LAND_BOX : [-3, 3, -3, 3];
  const m = mapper(box, land ? [6, 30, 348, 174] : mode === "paint" ? [70, 4, 220, 220] : [6, 4, 220, 220]);
  const { ref, drag } = useSvgDrag();
  const t = useTime(true, 2.5);

  // arrows on a grid, scaled to the longest
  const nx = land ? 17 : 11, ny = land ? 9 : 11;
  const grid: [number, number, number, number][] = [];
  let maxL = 1e-9;
  for (let i = 0; i < nx; i++) for (let j = 0; j < ny; j++) {
    const x = box[0] + ((box[1] - box[0]) * (i + 0.5)) / nx, y = box[2] + ((box[3] - box[2]) * (j + 0.5)) / ny, [p, q] = F(x, y);
    grid.push([x, y, p, q]); maxL = Math.max(maxL, Math.hypot(p, q));
  }
  const cell = Math.min((m.frame[2] / nx), (m.frame[3] / ny)) * 0.85;

  // particles: carried by the flow, reborn at random spots so the picture keeps moving
  const parts = useRef<[number, number, number][]>([]);
  const last = useRef(t);
  if (!parts.current.length) { const r = seeded(7); parts.current = Array.from({ length: 50 }, () => [box[0] + r() * (box[1] - box[0]), box[2] + r() * (box[3] - box[2]), r() * 3]); }
  const dt = Math.max(0, Math.min(0.05, t - last.current));
  last.current = t;
  const speed = 1.2 / maxL;
  parts.current = parts.current.map(([x, y, age], k) => {
    const [p, q] = F(x, y), nxp = x + p * dt * speed * (box[1] - box[0]) * 0.25, nyp = y + q * dt * speed * (box[1] - box[0]) * 0.25, na = age + dt;
    if (na > 3 || nxp < box[0] || nxp > box[1] || nyp < box[2] || nyp > box[3] || !Number.isFinite(nxp)) {
      const r = seeded(Math.floor(t * 1000) + k); return [box[0] + r() * (box[1] - box[0]), box[2] + r() * (box[3] - box[2]), 0];
    }
    return [nxp, nyp, na];
  });

  const [wheel, setWheel] = useState<[number, number]>([num(props, "wx", land ? -1 : 1.5), num(props, "wy", land ? 0 : 1)]);
  const [dye, setDye] = useState<[number, number]>(land ? [0.06, 0] : [-1.5, -1.5]);
  const curl = curlOf(F, ...wheel), div = divOf(F, ...dye);
  const spin = quiet ? 0 : (curl / 2) * t;
  const tau = (t % 3) / 3, dyeR = 10 * Math.exp(Math.max(-2.5, Math.min(1.2, (div * tau * 0.6) / Math.max(1, Math.abs(div) / 2))));

  const arrows = grid.map(([x, y, p, q], i) => {
    const L = Math.hypot(p, q) / maxL, ang = Math.atan2(q, p), len = cell * (0.25 + 0.75 * L);
    const sx = m.X(x), sy = m.Y(y);
    return L < 0.02 ? <circle key={i} cx={sx} cy={sy} r="1.2" className="mvdot" /> : <Arrow key={i} x1={sx - (Math.cos(ang) * len) / 2} y1={sy + (Math.sin(ang) * len) / 2} x2={sx + (Math.cos(ang) * len) / 2} y2={sy - (Math.sin(ang) * len) / 2} cls="mint faint" w={1.4} />;
  });
  const flow = <>
    <rect x={m.frame[0]} y={m.frame[1]} width={m.frame[2]} height={m.frame[3]} className="mvframe" />
    {arrows}
    {parts.current.map(([x, y], i) => <circle key={i} cx={m.X(x)} cy={m.Y(y)} r="2.2" className="mvparticle" />)}
  </>;

  if (mode === "loop" || mode === "path" || mode === "carts") return <WorkView F={F} m={m} flow={flow} mode={mode} props={props} quiet={quiet} t={t}
    sliders={!land && !typed ? { a, b, c, d, setA, setB, setC, setD } : null} />;

  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`A vector field with a paddle wheel at (${nice(wheel[0])}, ${nice(wheel[1])})${quiet ? "" : ` spinning at curl ${nice(curl)}`} and a drop of dye where the divergence is ${nice(div)}.`}>
      {flow}
      <g transform={`translate(${m.X(wheel[0])},${m.Y(wheel[1])}) rotate(${(-spin * 180) / Math.PI})`}>
        <circle r="13" className="mvwheel" />
        {[0, 1, 2, 3].map(k => <line key={k} x1="0" y1="0" x2={13 * Math.cos((k * Math.PI) / 2)} y2={13 * Math.sin((k * Math.PI) / 2)} className="mvwheel" />)}
      </g>
      <circle cx={m.X(wheel[0])} cy={m.Y(wheel[1])} r="20" className="b2hit" {...drag((x, y) => setWheel([Math.round(m.ix(x) * 10) / 10, Math.round(m.iy(y) * 10) / 10]))} />
      <circle cx={m.X(dye[0])} cy={m.Y(dye[1])} r={dyeR} className="mvdye" />
      <circle cx={m.X(dye[0])} cy={m.Y(dye[1])} r="18" className="b2hit" {...drag((x, y) => setDye([Math.round(m.ix(x) * 10) / 10, Math.round(m.iy(y) * 10) / 10]))} />
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={!land && !typed ? <>
        <div className="mvsl2"><Slider label="P: a" value={a} min={-3} max={3} step={0.5} onChange={setA} format={v => nice(v)} />
        <Slider label="P: b" value={b} min={-3} max={3} step={0.5} onChange={setB} format={v => nice(v)} />
        <Slider label="Q: c" value={c} min={-3} max={3} step={0.5} onChange={setC} format={v => nice(v)} />
        <Slider label="Q: d" value={d} min={-3} max={3} step={0.5} onChange={setD} format={v => nice(v)} /></div>
      </> : undefined}
      readouts={<>
        {!land && !typed && <Read minor label="F" value={`⟨${lin(a, b)}, ${lin(c, d)}⟩`} tone="mint" />}
        {!quiet && <Read label={`Curl at the wheel (${nice(wheel[0])}, ${nice(wheel[1])})`} value={`${fx(curl, 2)}${Math.abs(curl) < 1e-6 ? "" : curl > 0 ? ", counterclockwise" : ", clockwise"}`} tone="trav" />}
        <Read label={`Divergence at the dye (${nice(dye[0])}, ${nice(dye[1])})`} value={`${fx(div, 2)}${Math.abs(div) < 1e-6 ? "" : div > 0 ? ", spreads" : ", squeezes"}`} tone="amber" />
      </>} />
  );
}
/** "2x − y", "0" */
function lin(p: number, q: number) {
  const t: string[] = [];
  if (p) t.push(`${p === 1 ? "" : p === -1 ? "−" : nice(p)}x`);
  if (q) t.push(`${t.length ? (q < 0 ? " − " : " + ") : q < 0 ? "−" : ""}${Math.abs(q) === 1 ? "" : nice(Math.abs(q))}y`);
  return t.join("") || "0";
}

type Sliders = { a: number; b: number; c: number; d: number; setA: (v: number) => void; setB: (v: number) => void; setC: (v: number) => void; setD: (v: number) => void } | null;

/** Work along a path or around a loop, beside curl × area (Green's theorem); and two carts on Two lakes. */
function WorkView({ F, m, flow, mode, props, quiet, t, sliders }: {
  F: V2; m: ReturnType<typeof mapper>; flow: ReactElement; mode: string; props: SceneProps["props"]; quiet: boolean; t: number; sliders: Sliders;
}) {
  const { ref, drag } = useSvgDrag();
  const rect = flag(props, "rect");
  const [c, setC] = useState<[number, number]>([num(props, "lx", 0), num(props, "ly", 0)]);
  const [r, setR] = useState(num(props, "lr", 1.5));
  const lw = num(props, "lw", 2), lh = num(props, "lh", 2);
  const [end, setEnd] = useState<[number, number]>([num(props, "ex", 2), num(props, "ey", 1)]);
  // the path as points with their tangents, 240 of them, counterclockwise for a loop
  const N = 240;
  const curves: [number, number][][] = mode === "carts"
    ? [Array.from({ length: N + 1 }, (_, i) => { const s = i / N; return [-1.2 + 2.2 * s, -0.6 + 1.1 * s]; }),
      Array.from({ length: N + 1 }, (_, i) => { const s = i / N; return [(1 - s) ** 2 * -1.2 + 2 * s * (1 - s) * -0.2 + s * s, (1 - s) ** 2 * -0.6 + 2 * s * (1 - s) * 1.6 + s * s * 0.5]; })]
    : mode === "path" ? [Array.from({ length: N + 1 }, (_, i) => [end[0] * (i / N), end[1] * (i / N)])]
      : rect ? [Array.from({ length: N + 1 }, (_, i) => {
        const s = (i / N) * 4, k = Math.min(3, Math.floor(s)), u = s - k, x0 = c[0] - lw / 2, x1 = c[0] + lw / 2, y0 = c[1] - lh / 2, y1 = c[1] + lh / 2;
        return [[x0 + (x1 - x0) * u, y0], [x1, y0 + (y1 - y0) * u], [x1 - (x1 - x0) * u, y1], [x0, y1 - (y1 - y0) * u]][k] as [number, number];
      })]
        : [Array.from({ length: N + 1 }, (_, i) => { const a = (2 * Math.PI * i) / N; return [c[0] + r * Math.cos(a), c[1] + r * Math.sin(a)]; })];
  const work = (pts: [number, number][], upto = 1) => {
    let w = 0;
    const n = Math.round((pts.length - 1) * upto);
    for (let i = 0; i < n; i++) { const [x0, y0] = pts[i]!, [x1, y1] = pts[i + 1]!, [p, q] = F((x0 + x1) / 2, (y0 + y1) / 2); w += p * (x1 - x0) + q * (y1 - y0); }
    return w;
  };
  const prog = mode === "carts" || !quiet ? Math.min(1, (t % 5) / 4) : 0;
  const totals = curves.map(pts => work(pts));
  // curl × area inside, by a grid of small squares
  const inside = mode === "loop";
  let green = 0;
  if (inside) {
    const n = 40, [x0, x1, y0, y1] = rect ? [c[0] - lw / 2, c[0] + lw / 2, c[1] - lh / 2, c[1] + lh / 2] : [c[0] - r, c[0] + r, c[1] - r, c[1] + r];
    const dx = (x1 - x0) / n, dy = (y1 - y0) / n;
    for (let i = 0; i < n; i++) for (let j = 0; j < n; j++) {
      const x = x0 + (i + 0.5) * dx, y = y0 + (j + 0.5) * dy;
      if (!rect && Math.hypot(x - c[0], y - c[1]) > r) continue;
      green += curlOf(F, x, y) * dx * dy;
    }
  }
  const bars = (pts: [number, number][]) => pts.filter((_, i) => i % 12 === 0 && i < pts.length - 1).map(([x, y], k) => {
    const i = k * 12, [x1, y1] = pts[i + 1]!, tx = x1 - x, ty = y1 - y, L = Math.hypot(tx, ty) || 1, [p, q] = F(x, y), push = (p * tx + q * ty) / L;
    const nxp = ty / L, nyp = -tx / L, len = Math.max(-22, Math.min(22, push * 6));
    return <line key={k} x1={m.X(x)} y1={m.Y(y)} x2={m.X(x) + nxp * len} y2={m.Y(y) - nyp * len} className={`mvcut ${push >= 0 ? "pink" : "trav"}`} />;
  });
  const meterBox = [236, 20, 116, 196];
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={mode === "carts" ? `Two trails between the same two spots: the work along each is ${nice(totals[0]!)} and ${nice(totals[1]!)}.` : `A ${mode === "path" ? "path" : "loop"} in a field${quiet ? "" : `: work ${nice(totals[0]!)}${inside ? `, curl × area ${nice(green)}` : ""}`}.`}>
      {flow}
      {curves.map((pts, k) => <path key={k} d={path(pts.map(([x, y]) => [m.X(x), m.Y(y)]))} className={`mvtrail${k ? " dash" : ""}`} />)}
      {!quiet && curves.map((pts, k) => <g key={`b${k}`}>{bars(pts)}</g>)}
      {(mode === "carts" || !quiet) && curves.map((pts, k) => { const [x, y] = pts[Math.round(prog * (pts.length - 1))]!; return <circle key={`w${k}`} cx={m.X(x)} cy={m.Y(y)} r="6" className="mvball" />; })}
      {mode === "loop" && <circle cx={m.X(c[0])} cy={m.Y(c[1])} r="16" className="b2hit" {...drag((x, y) => setC([Math.round(m.ix(x) * 10) / 10, Math.round(m.iy(y) * 10) / 10]))} />}
      {mode === "loop" && <circle cx={m.X(c[0])} cy={m.Y(c[1])} r="3.5" className="mvdot trav" />}
      {mode === "path" && <><circle cx={m.X(end[0])} cy={m.Y(end[1])} r="6" className="mvhandle trav" /><circle cx={m.X(end[0])} cy={m.Y(end[1])} r="18" className="b2hit" {...drag((x, y) => setEnd([Math.round(m.ix(x)), Math.round(m.iy(y))]))} /></>}
      {mode !== "carts" && !quiet && <g>
        {[{ v: work(curves[0]!, prog), label: "work", cls: "pink" }, ...(inside ? [{ v: green, label: "curl·area", cls: "trav" }] : [])].map((mt, k) => {
          const x = meterBox[0]! + 8 + k * 62, zero = meterBox[1]! + meterBox[3]! / 2, scale = 80 / Math.max(1, Math.abs(totals[0]!), Math.abs(green));
          const hgt = mt.v * scale;
          return <g key={k}>
            <rect x={x} y={hgt >= 0 ? zero - hgt : zero} width="30" height={Math.max(1, Math.abs(hgt))} rx="4" className={`b2bar ${mt.cls}`} />
            <text x={x + 15} y={zero + (hgt >= 0 ? 16 : -6) + (hgt < 0 ? 0 : 0)} textAnchor="middle" className={`b2t ${mt.cls}`}>{nice(mt.v)}</text>
            <text x={x + 15} y={meterBox[1]! + meterBox[3]! + 14} textAnchor="middle" className="b2t">{mt.label}</text>
          </g>;
        })}
        <line x1={meterBox[0]} y1={meterBox[1]! + meterBox[3]! / 2} x2={meterBox[0]! + meterBox[2]!} y2={meterBox[1]! + meterBox[3]! / 2} className="b2axis" />
      </g>}
    </svg>
  );
  const s = sliders;
  return (
    <Scene svg={svg}
      controls={<>
        {mode === "loop" && !rect && <Slider label="Loop radius" value={r} min={0.5} max={2.5} step={0.1} onChange={setR} format={v => nice(v, 1)} />}
        {s && <>
          <div className="mvsl2"><Slider label="P: a" value={s.a} min={-2} max={2} step={0.5} onChange={s.setA} format={v => nice(v)} />
          <Slider label="P: b" value={s.b} min={-2} max={2} step={0.5} onChange={s.setB} format={v => nice(v)} />
          <Slider label="Q: c" value={s.c} min={-2} max={2} step={0.5} onChange={s.setC} format={v => nice(v)} />
          <Slider label="Q: d" value={s.d} min={-2} max={2} step={0.5} onChange={s.setD} format={v => nice(v)} /></div>
        </>}
      </>}
      readouts={mode === "carts" ? <>
        <Read label="Work by −∇f, straight trail" value={fx(totals[0]!, 3)} tone="pink" />
        <Read label="Work by −∇f, curved trail" value={fx(totals[1]!, 3)} tone="pink" />
        <Read label="f(start) − f(end)" value={fx(LAND(-1.2, -0.6) - LAND(1, 0.5), 3)} />
      </> : <>
        {s && <Read minor label="F" value={`⟨${lin(s.a, s.b)}, ${lin(s.c, s.d)}⟩`} tone="mint" />}
        {!quiet && <Read label={inside ? "Work around the loop" : "Work along the path"} value={fx(totals[0]!, 3)} tone="pink" big />}
        {!quiet && inside && <Read label="Curl × area inside" value={fx(green, 3)} tone="trav" big />}
      </>} />
  );
}
