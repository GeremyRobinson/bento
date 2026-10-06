// Data cloud with a turning line (linear-algebra.md, "New pictures"): a cloud of points and a line through its
// center. Turn the line: each point drops a shadow onto it, and a bar shows how spread out the shadows are. One
// direction makes the bar longest: the first principal component. The reveal sweeps the line all the way round.
import { useEffect, useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider, useSvgDrag, useTween } from "../../../ui/kit";
import { sym2 } from "../maths";
import { Grid, ink, plane, tint } from "./plane";

/** a leaning cloud: heights and weights, say, already centered */
const CLOUD: [number, number][] = [[-3, -2], [-2.5, -0.8], [-2, -1.6], [-1.4, -0.2], [-1, -1.2], [-0.5, 0.4], [0, -0.4], [0.3, 0.9], [0.8, 0.1], [1.2, 1.4], [1.6, 0.5], [2.1, 1.9], [2.6, 1.1], [3, 2.4]];

export function CloudScene({ props, marker }: SceneProps) {
  const quiet = flag(props, "quiet") || flag(props, "hide");
  const [deg, setDeg] = useState(num(props, "deg", 100));
  // a cloud of its own ("7,4;3,2;6,5;4,1"), or the leaning one
  const given = str(props, "pts", "").split(";").map(q => q.split(",").map(Number)).filter(q => q.length === 2 && q.every(Number.isFinite)) as [number, number][];
  const [pts, setPts] = useState(given.length > 1 ? given : CLOUD);
  const { ref, drag } = useSvgDrag();
  const cx0 = pts.reduce((s, q) => s + q[0], 0) / pts.length, cy0 = pts.reduce((s, q) => s + q[1], 0) / pts.length;
  const reach = Math.max(4.5, ...pts.map(q => Math.max(Math.abs(q[0] - cx0), Math.abs(q[1] - cy0) * 1.32) + 1));
  const p = given.length > 1 ? plane(cx0 - reach, cx0 + reach, cy0 - reach * 0.756, cy0 + reach * 0.756, 360, 270) : plane(-4.5, 4.5, -3.4, 3.4, 360, 270);
  const mx = pts.reduce((s, q) => s + q[0], 0) / pts.length, my = pts.reduce((s, q) => s + q[1], 0) / pts.length;
  const C = useMemo(() => {
    let a = 0, b = 0, d = 0;
    for (const [x, y] of pts) { a += (x - mx) ** 2; b += (x - mx) * (y - my); d += (y - my) ** 2; }
    return [[a, b], [b, d]];
  }, [pts, mx, my]);
  const e = sym2(C);
  const bestDeg = ((Math.atan2(e.v[0]![1]!, e.v[0]![0]!) * 180) / Math.PI + 360) % 180;
  // the reveal: the line sweeps round once, the bar rising and falling, and the best direction stays marked
  const [goal, setGoal] = useState(0);
  const sw = useTween(goal, 3200);
  useEffect(() => { if (flag(props, "sweep")) setGoal(180); }, []); // eslint-disable-line react-hooks/exhaustive-deps
  const sweeping = flag(props, "sweep") && sw < 179.5;
  const shown = marker ? marker[0] : sweeping ? sw : flag(props, "sweep") ? bestDeg : deg;
  const r = (shown * Math.PI) / 180, d = [Math.cos(r), Math.sin(r)];
  const spread = (dd: number[]) => pts.reduce((s, [x, y]) => s + ((x - mx) * dd[0]! + (y - my) * dd[1]!) ** 2, 0);
  const now = spread(d), most = e.l[0], total = e.l[0] + e.l[1];
  const L = 9;
  const barW = 150, bx = 200, by = 18;
  const svg = (
    <svg ref={ref} viewBox="0 0 360 270" className="b2pic" role="img" aria-label={quiet ? `A cloud of ${pts.length} points and a line through its center.` : `A cloud of ${pts.length} points and a line at ${fx(shown, 0)} degrees; the shadows' spread is ${fx(now, 1)} of the most possible ${fx(most, 1)}.`}>
      <Grid p={p} />
      {flag(props, "sweep") && !sweeping && <line x1={p.X(mx - L * Math.cos((bestDeg * Math.PI) / 180))} y1={p.Y(my - L * Math.sin((bestDeg * Math.PI) / 180))} x2={p.X(mx + L * Math.cos((bestDeg * Math.PI) / 180))} y2={p.Y(my + L * Math.sin((bestDeg * Math.PI) / 180))} style={ink("amber", 4)} opacity={0.5} />}
      <line x1={p.X(mx - L * d[0]!)} y1={p.Y(my - L * d[1]!)} x2={p.X(mx + L * d[0]!)} y2={p.Y(my + L * d[1]!)} style={ink(marker ? "trav" : "amber", 2.5, marker ? "6 4" : undefined)} />
      {pts.map(([x, y], i) => {
        const t = (x - mx) * d[0]! + (y - my) * d[1]!, sx = mx + t * d[0]!, sy = my + t * d[1]!;
        return <g key={i}>
          {!quiet && <line x1={p.X(x)} y1={p.Y(y)} x2={p.X(sx)} y2={p.Y(sy)} style={ink("pink", 1, "2 3")} />}
          {!quiet && <circle cx={p.X(sx)} cy={p.Y(sy)} r="3.5" className="b2dot amber" />}
          <circle cx={p.X(x)} cy={p.Y(y)} r="5" className="b2dot sky" />
          {!quiet && !marker && !flag(props, "sweep") && <circle cx={p.X(x)} cy={p.Y(y)} r="14" className="b2hit" {...drag((px, py) => { const [X, Y] = p.back(px, py); setPts(ps => ps.map((q, j) => (j === i ? [Math.round(X * 10) / 10, Math.round(Y * 10) / 10] : q))); })} />}
        </g>;
      })}
      <circle cx={p.X(mx)} cy={p.Y(my)} r="4" className="b2dot trav" />
      {!quiet && <g>
        <rect x={bx} y={by} width={barW} height="12" rx="6" className="b2bar track" />
        <rect x={bx} y={by} width={(barW * now) / total} height="12" rx="6" style={tint("amber", 0.9)} />
        <line x1={bx + (barW * most) / total} y1={by - 4} x2={bx + (barW * most) / total} y2={by + 16} style={ink("amber", 1.5)} />
        <text x={bx} y={by + 30} className="b2t amber">spread of the shadows</text>
      </g>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Turn the line" value={deg} min={0} max={179} step={1} onChange={setDeg} format={v => `${v}°`} />}
      readouts={quiet ? <Read label="Points" value={String(pts.length)} /> : <>
        <Read label="Spread along the line" value={fx(now, 1)} tone="amber" />
        <Read label="Most possible, λ₁" value={fx(most, 1)} tone="amber" />
        <Read label="Share on this line" value={`${fx((100 * now) / total, 1)}%`} />
        {flag(props, "sweep") && <Read label="Best direction" value={`${fx(bestDeg, 0)}°`} tone="amber" />}
      </>}
    />
  );
}
