// The Grid warper (multivariable.md, tool 5): a (u, v) grid on the left and its image under x = au + bv, y = cu + dv
// on the right, with one small square's image and its area beside |det J| (08).
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider } from "../../../ui/kit";
import { nice } from "./common";

const W = 360, H = 250;
const poly = (pts: [number, number][]) => pts.map(([x, y], i) => `${i ? "L" : "M"}${x.toFixed(1)},${y.toFixed(1)}`).join("") + "Z";

export function WarpScene({ props }: SceneProps) {
  const [a, setA] = useState(num(props, "a", 2)), [b, setB] = useState(num(props, "b", 1));
  const [c, setC] = useState(num(props, "c", 1)), [d, setD] = useState(num(props, "d", 3));
  const s = num(props, "s", 1), t = num(props, "t", 1), quiet = flag(props, "quiet");
  const det = a * d - b * c;
  const map = (u: number, v: number): [number, number] => [a * u + b * v, c * u + d * v];
  // left: the (u, v) region with a grid; right: its image, scaled to fit
  const n = 4, U = Math.max(s, t), lS = 120 / U, lx = 22, ly = 196;
  const L = (u: number, v: number): [number, number] => [lx + u * lS, ly - v * lS];
  const corners = [map(0, 0), map(s, 0), map(s, t), map(0, t)];
  const xs = corners.map(p => p[0]), ys = corners.map(p => p[1]);
  const x0 = Math.min(...xs, 0), x1 = Math.max(...xs, 0.5), y0 = Math.min(...ys, 0), y1 = Math.max(...ys, 0.5);
  const rS = Math.min(150 / (x1 - x0 || 1), 190 / (y1 - y0 || 1)), rx = 192 + (150 - rS * (x1 - x0)) / 2, ry = 22 + (190 - rS * (y1 - y0)) / 2;
  const R = (u: number, v: number): [number, number] => { const [x, y] = map(u, v); return [rx + (x - x0) * rS, ry + (y1 - y) * rS]; };
  const k = s / n, q = t / n, hu = s / n, hv = t / n; // one highlighted cell, near the middle
  const cu = Math.floor(n / 2) * k, cv = Math.floor(n / 2) * q;
  const cell = (P: (u: number, v: number) => [number, number]) => poly([P(cu, cv), P(cu + hu, cv), P(cu + hu, cv + hv), P(cu, cv + hv)]);
  const grid = (P: (u: number, v: number) => [number, number]) => <>
    {Array.from({ length: n + 1 }, (_, i) => <line key={`u${i}`} x1={P(i * k, 0)[0]} y1={P(i * k, 0)[1]} x2={P(i * k, t)[0]} y2={P(i * k, t)[1]} className="b2grid strong" />)}
    {Array.from({ length: n + 1 }, (_, j) => <line key={`v${j}`} x1={P(0, j * q)[0]} y1={P(0, j * q)[1]} x2={P(s, j * q)[0]} y2={P(s, j * q)[1]} className="b2grid strong" />)}
  </>;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`A (u, v) grid and its image under x = ${nice(a)}u + ${nice(b)}v, y = ${nice(c)}u + ${nice(d)}v${quiet ? "" : `. Areas stretch by |det J| = ${nice(Math.abs(det))}`}.`}>
      <path d={poly([L(0, 0), L(s, 0), L(s, t), L(0, t)])} className="mvregion sky" />
      {grid(L)}
      <path d={cell(L)} className="mvtile" />
      <text x={lx} y={ly + 18} className="b2t">(u, v)</text>
      <path d={poly([R(0, 0), R(s, 0), R(s, t), R(0, t)])} className="mvregion sky" />
      {grid(R)}
      <path d={cell(R)} className="mvtile" />
      <circle cx={R(0, 0)[0]} cy={R(0, 0)[1]} r="3" className="mvdot" />
      <text x={W - 8} y={ly + 18} textAnchor="end" className="b2t">(x, y)</text>
      <text x={W / 2 - 10} y={110} textAnchor="middle" className="b2t amber">→</text>
    </svg>
  );
  const sl = (label: string, v: number, set: (x: number) => void) => <Slider label={label} value={v} min={-3} max={3} step={0.5} onChange={set} format={x => nice(x)} />;
  return (
    <Scene svg={svg}
      controls={<>{sl("x = a·u, a", a, setA)}{sl("+ b·v, b", b, setB)}{sl("y = c·u, c", c, setC)}{sl("+ d·v, d", d, setD)}</>}
      readouts={<>
        <Read label="Region in (u, v)" value={nice(s * t, 3)} tone="sky" />
        <Read label="Small square" value={nice(hu * hv, 4)} tone="amber" />
        {!quiet && <Read label="Its image" value={nice(Math.abs(det) * hu * hv, 4)} tone="amber" />}
        {!quiet && <Read label="|det J|" value={fx(Math.abs(det), 2)} big />}
        {!quiet && <Read label="Image of the region" value={nice(Math.abs(det) * s * t, 3)} tone="sky" />}
      </>} />
  );
}
