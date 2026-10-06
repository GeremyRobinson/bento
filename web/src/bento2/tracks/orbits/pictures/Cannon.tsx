// Newton's cannon (orbits.md, "New for Development" 2): a mountain on Earth with no air, and a speed slider. The ball
// lands farther and farther away until, at 7.91 km/s, the ground curves away as fast as it falls; at 11.19 km/s it
// escapes. The numbers are for a launch at the surface; the mountain is drawn huge so the short arcs can be seen.
import { useMemo, useState } from "react";
import { num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, useClock } from "../../../ui/kit";
import { MU_E, R_E, period, propagator, vCirc, vEsc } from "../maths";
import { dur } from "./parts";

const VC = vCirc(MU_E, R_E) / 1000, VE = vEsc(MU_E, R_E) / 1000, GROUND = 0.9;

export function CannonScene({ props }: SceneProps) {
  const [v, setV] = useState(num(props, "v", 5));
  const W = 360, H = 260, cx = 180, cy = 150, s = 100;
  // the flight, sampled in time until it hits the ground, laps once, or leaves the picture
  const flight = useMemo(() => {
    const pr = propagator(1, 0, 1, Math.max(1e-6, v / VC), 0);
    const pts: [number, number][] = [];
    if (!pr) return { pts: [[0, 1], [0, GROUND]] as [number, number][], end: "lands" as const };
    const T = Number.isFinite(pr.period) ? pr.period : 12, n = 1500;
    for (let i = 0; i <= n; i++) {
      const p = pr.pos((T * i) / n);
      if (p.r < GROUND) return { pts, end: "lands" as const };
      pts.push([p.x, p.y]);
      if (p.r > 3.2) return { pts, end: "leaves" as const };
    }
    return { pts, end: "laps" as const };
  }, [v]);
  const t = useClock(true, 99);
  const k = Math.min(1, ((t % 4.5) / 3.5));
  const shown = flight.pts.slice(0, Math.max(2, Math.round(k * flight.pts.length)));
  const ball = shown[shown.length - 1]!;
  const view = (p: [number, number]): [number, number] => [cx + p[0] * s, cy - p[1] * s];
  const T = period(MU_E, R_E);
  const outcome = v >= VE - 1e-9 ? "Escapes for good" : flight.end === "lands" ? "Falls back to the ground" : flight.end === "laps" ? "Goes all the way around" : "Flies far out and falls back";
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A cannonball fired sideways at ${fx(v, 2)} kilometers per second: ${outcome.toLowerCase()}.`}>
      <circle cx={cx} cy={cy} r={GROUND * s} className="b2earth" />
      <path d={`M${cx - 26},${cy - GROUND * s + 4} L${cx - 4},${cy - s - 2} L${cx + 4},${cy - s - 2} L${cx + 26},${cy - GROUND * s + 4} Z`} className="b2train" />
      <circle cx={cx} cy={cy} r={s} className="b2orbit" />
      <path d={path(flight.pts.map(view))} className="b2curve amber" style={{ opacity: 0.35 }} />
      <path d={path(shown.map(view))} className="b2curve amber" />
      <circle cx={view(ball)[0]} cy={view(ball)[1]} r="5" className="b2sat" />
      <text x="10" y="20" className="b2t">mountain drawn huge, no air</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Launch speed" value={v} min={0} max={12} step={0.01} onChange={setV} format={x => `${fx(x, 2)} km/s`}
        marks={[{ v: 4, label: "4" }, { v: Math.round(VC * 100) / 100, label: "7.91 circle" }, { v: Math.round(VE * 100) / 100, label: "11.19 escape" }]} />}
      readouts={<>
        <Read label="What happens" value={outcome} tone="amber" big />
        <Read label="Circular speed here" value={`${fx(VC, 2)} km/s`} />
        <Read label="Escape speed here" value={`${fx(VE, 2)} km/s`} />
        {Math.abs(v - VC) < 0.02 && <Read label="One lap" value={dur(T)} />}
      </>} />
  );
}
