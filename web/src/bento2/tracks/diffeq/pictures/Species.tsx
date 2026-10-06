// The two-species world (diffeq.md, "New for Development" 7): Lotka–Volterra rabbits x and foxes y. The loop in the
// phase plane around the rest point (c/d, a/b), and the two time graphs underneath in step with a dot going round it.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, useSvgDrag } from "../../../ui/kit";
import { solve } from "../maths";
import { Arrow, frame, useLoop } from "./plot";

const W = 360, H = 284;

export function SpeciesScene({ props, marker, onMarker }: SceneProps) {
  const b = num(props, "b", 0.05), d = num(props, "d", 0.01), a0 = num(props, "a", 1), c0 = num(props, "c", 0.5);
  const [a, setA] = useState(a0);
  const [c, setC] = useState(c0);
  const [start, setStart] = useState<[number, number]>([num(props, "x0", 70), num(props, "y0", 20)]);
  const quiet = flag(props, "quiet"), lynx = flag(props, "lynx");
  const xs = c / d, ys = a / b;
  // the view is set by the starting numbers, so a rest point that moves is seen to move
  const X0 = c0 / d, Y0 = a0 / b;
  const pl = frame(0, 3 * X0, 0, 3 * Y0, { l: 40, r: 352, t: 12, b: 168 });
  const P = (2 * Math.PI) / Math.sqrt(a * c), tmax = 2.5 * P;
  const run = useMemo(() => solve((_t, y) => [a * y[0]! - b * y[0]! * y[1]!, -c * y[1]! + d * y[0]! * y[1]!], start, 0, tmax, tmax / 1500), [a, c, b, d, start, tmax]);
  const top = Math.max(...run.map(p => Math.max(p.y[0]! / X0, p.y[1]! / Y0)), 1);
  const tg = frame(0, tmax, 0, top * 1.05, { l: 40, r: 352, t: 194, b: 262 });
  const t = useLoop(0);
  const k = Math.floor(((t / 10) % 1) * (run.length - 1)), now = run[k]!;
  const { ref, drag } = useSvgDrag();
  const tap = (px: number, py: number) => {
    const p: [number, number] = [Math.max(1, pl.ix(px)), Math.max(1, pl.iy(py))];
    if (onMarker) onMarker([Math.round(p[0]), Math.round(p[1])]); else if (!quiet) setStart(p);
  };
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Rabbits and foxes: rest point at ${fx(xs, 0)} rabbits and ${fx(ys, 0)} foxes; cycles take about ${fx(P, 1)} years near rest.`}>
      <rect x={pl.box.l} y={pl.box.t} width={pl.box.r - pl.box.l} height={pl.box.b - pl.box.t} className="b2hit" {...drag(tap)} />
      <g pointerEvents="none">
        <line x1={pl.box.l} y1={pl.box.b} x2={pl.box.r} y2={pl.box.b} className="b2axis" />
        <line x1={pl.box.l} y1={pl.box.t} x2={pl.box.l} y2={pl.box.b} className="b2axis" />
        <text x={pl.box.r} y={pl.box.b - 6} textAnchor="end" className="b2t sky">rabbits</text>
        <text x={pl.box.l + 6} y={pl.box.t + 10} className="b2t pink">foxes</text>
        <path d={path(run.map(p => [pl.X(p.y[0]!), pl.Y(Math.min(3 * Y0, p.y[1]!))] as [number, number]))} className="b2curve trav" style={{ strokeWidth: 2 }} />
        <circle cx={pl.X(now.y[0]!)} cy={pl.Y(Math.min(3 * Y0, now.y[1]!))} r="5.5" className="b2dot trav" />
        {!quiet && <circle cx={pl.X(xs)} cy={pl.Y(ys)} r="6" className="b2dot amber" />}
        {flag(props, "newRest") && <>
          <circle cx={pl.X(X0)} cy={pl.Y(Y0)} r="6" className="b2clock amber" />
          <Arrow x1={pl.X(X0)} y1={pl.Y(Y0) - 8} x2={pl.X(xs)} y2={pl.Y(ys) + 8} cls="amber" />
        </>}
        {marker && <circle cx={pl.X(marker[0])} cy={pl.Y(marker[1])} r="9" className="b2marker" />}
        {/* the two populations against time, in step with the dot */}
        <line x1={tg.box.l} y1={tg.box.b} x2={tg.box.r} y2={tg.box.b} className="b2axis" />
        <path d={path(run.filter((_, i) => i % 3 === 0).map(p => [tg.X(p.t), tg.Y(p.y[0]! / X0)] as [number, number]))} className="b2curve sky" style={{ strokeWidth: 2 }} />
        <path d={path(run.filter((_, i) => i % 3 === 0).map(p => [tg.X(p.t), tg.Y(p.y[1]! / Y0)] as [number, number]))} className="b2curve pink" style={{ strokeWidth: 2 }} />
        <line x1={tg.X(now.t)} y1={tg.box.t} x2={tg.X(now.t)} y2={tg.box.b} className="b2mark trav" />
        <text x={tg.box.r} y={tg.box.b + 15} textAnchor="end" className="b2t">{fx(tmax, 0)} years</text>
      </g>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Rabbit births a" value={a} min={0.25} max={2} step={0.05} onChange={setA} format={x => `${fx(x, 2)} a year`} />
        <Slider label="Fox deaths c" value={c} min={0.25} max={2} step={0.05} onChange={setC} format={x => `${fx(x, 2)} a year`} />
      </>}
      readouts={<>
        {!quiet && <Read label="Rest point" value={`${fx(xs, 0)} rabbits, ${fx(ys, 0)} foxes`} tone="amber" />}
        <Read label="b, d" value={`${b}, ${d}`} />
        {!quiet && <Read label="Period near rest" value={`${fx(P, 2)} years`} tone="trav" big={lynx} />}
        {!quiet && <Read label="Tap the plane" value="to set the start" />}
      </>}
    />
  );
}
