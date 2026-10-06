// The Joint cloud (08, and Retest's neighbor in 17): 500 points from a two-variable bell with draggable σx, σy and ρ,
// the covariance ellipse (2 SDs) and its long axis, and a thin vertical slice you drag along x. The dot in the slice
// is the middle of its points; it rides the regression line, which is flatter than the long axis.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, useSvgDrag } from "../../../ui/kit";
import { gauss, seeded } from "../maths";
import { K, lin } from "./parts";

const W = 360, H = 240;

export function CloudScene({ props, marker, onMarker }: SceneProps) {
  const quiet = flag(props, "quiet");
  const [sx, setSx] = useState(num(props, "sx", 1));
  const [sy, setSy] = useState(num(props, "sy", 1));
  const [rho, setRho] = useState(num(props, "rho", 0.6));
  const [s, setS] = useState(num(props, "slice", 1.5));
  const uv = useMemo(() => { const r = seeded(8); return Array.from({ length: 500 }, () => [gauss(r), gauss(r)] as [number, number]); }, []);
  // equal SDs share one scale; otherwise each axis is in its own units, scaled so both clouds fit
  const nx = sx / Math.max(sx, sy), ny = sy / Math.max(sx, sy);
  const pts = uv.map(([u, v]) => [nx * u, ny * (rho * u + Math.sqrt(1 - rho * rho) * v)] as [number, number]);
  const X = lin(-3.4, 3.4, 30, W - 10), Y = lin(-3.2, 3.2, H - 12, 12);
  // the ellipse: eigenvectors of the (scaled) covariance matrix
  const a = nx * nx, b = rho * nx * ny, d = ny * ny, tr = a + d, det = a * d - b * b;
  const l1 = tr / 2 + Math.sqrt((tr * tr) / 4 - det), l2 = tr / 2 - Math.sqrt(Math.max(0, (tr * tr) / 4 - det));
  const ang = Math.abs(b) < 1e-12 ? (a >= d ? 0 : Math.PI / 2) : Math.atan2(l1 - a, b);
  const ell: [number, number][] = Array.from({ length: 73 }, (_, i) => {
    const t = (i / 72) * 2 * Math.PI, ex = 2 * Math.sqrt(l1) * Math.cos(t), ey = 2 * Math.sqrt(Math.max(0, l2)) * Math.sin(t);
    return [X(ex * Math.cos(ang) - ey * Math.sin(ang)), Y(ex * Math.sin(ang) + ey * Math.cos(ang))];
  });
  const slope = (rho * ny) / nx, axisSlope = Math.tan(ang);
  const sxPos = s * nx, band = 0.25 * nx;
  const inSlice = pts.filter(([x]) => Math.abs(x - sxPos) < band);
  const sliceMid = inSlice.length ? inSlice.reduce((t, [, y]) => t + y, 0) / inSlice.length : slope * sxPos;
  const { ref, drag } = useSvgDrag();
  const toZ = (px: number, py: number): [number, number] => [Math.round(((px - X(0)) / (X(1) - X(0)) / nx) * 10) / 10, Math.round(((py - Y(0)) / (Y(1) - Y(0)) / ny) * 10) / 10];
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A cloud with correlation ${fx(rho)}. A slice at x ${fx(s, 1)} SDs from the mean.${quiet ? "" : ` The slice's middle is ${fx(sliceMid / ny, 2)} SDs of y from its mean.`}`}
      {...(onMarker ? drag((px, py) => onMarker(toZ(px, py))) : {})}>
      <line x1={X(-3.4)} x2={X(3.4)} y1={Y(0)} y2={Y(0)} className="b2axis" />
      <line x1={X(0)} x2={X(0)} y1={Y(-3.2)} y2={Y(3.2)} className="b2axis" />
      <rect x={X(sxPos - band)} y={Y(3.2)} width={X(sxPos + band) - X(sxPos - band)} height={Y(-3.2) - Y(3.2)} style={{ fill: K.sky, fillOpacity: 0.12 }} {...(onMarker ? {} : drag(px => setS(Math.max(-2.8, Math.min(2.8, ((px - X(0)) / (X(1) - X(0))) / nx)))))} />
      {!quiet && pts.map(([x, y], i) => <circle key={i} cx={X(x)} cy={Y(y)} r="2.1" style={{ fill: Math.abs(x - sxPos) < band ? K.sky : K.muted, fillOpacity: Math.abs(x - sxPos) < band ? 0.95 : 0.45 }} />)}
      <path d={`${path(ell)} Z`} style={{ fill: "none", stroke: K.amber, strokeWidth: 1.8 }} />
      <line x1={X(-3.4)} x2={X(3.4)} y1={Y(-3.4 * axisSlope)} y2={Y(3.4 * axisSlope)} style={{ stroke: K.amber, strokeWidth: 1.5, strokeDasharray: "6 4" }} />
      <text x={X(2.6)} y={Y(2.6 * axisSlope) - 8} textAnchor="end" className="b2t amber">long axis</text>
      {!quiet && <>
        <line x1={X(-3.4)} x2={X(3.4)} y1={Y(-3.4 * slope)} y2={Y(3.4 * slope)} style={{ stroke: K.pink, strokeWidth: 2 }} />
        <circle cx={X(sxPos)} cy={Y(sliceMid)} r="7" style={{ fill: K.pink, stroke: "var(--page)", strokeWidth: 2 }} />
        <text x={X(-3.2)} y={Y(-3.2 * slope) + (slope > 0 ? -8 : 16)} className="b2t pink">best prediction</text>
      </>}
      {marker && <circle cx={X(marker[0] * nx)} cy={Y(marker[1] * ny)} r="9" className="b2marker" />}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Correlation ρ" value={rho} min={-0.95} max={0.95} step={0.05} onChange={setRho} format={x => fx(x)} />
        <Slider label="σx" value={sx} min={0.5} max={20} step={0.5} onChange={setSx} format={x => fx(x, 1)} />
        <Slider label="σy" value={sy} min={0.5} max={20} step={0.5} onChange={setSy} format={x => fx(x, 1)} />
        <Slider label="Slice at x, in SDs" value={s} min={-2.5} max={2.5} step={0.1} onChange={setS} format={x => fx(x, 1)} />
      </>}
      readouts={<>
        <Read label="Cov = ρσxσy" value={fx(rho * sx * sy)} />
        {!quiet && <Read label="Slice's middle, SDs of y" value={fx(sliceMid / ny)} tone="pink" />}
        {!quiet && <Read label="ρ × slice" value={fx(rho * s)} tone="pink" />}
        <Read label="Long axis, at the slice" value={fx((axisSlope * sxPos) / ny)} tone="amber" />
        {!quiet && <Read label="Leftover SD, σy√(1 − ρ²)" value={fx(sy * Math.sqrt(1 - rho * rho))} />}
      </>}
    />
  );
}
