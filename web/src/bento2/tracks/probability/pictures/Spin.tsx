// Two spinners X and Y feeding a histogram of X + Y (03). The link knob makes Y lean with X (ρ > 0), ignore it, or
// lean against it; the sum's histogram widens, holds or narrows, because Var(X + Y) = Var X + Var Y + 2 Cov(X, Y).
// The needles show the latest draw as the histogram fills.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider } from "../../../ui/kit";
import { gauss, seeded } from "../maths";
import { Bars, K, lin, useRunOut } from "./parts";

const W = 360, H = 240, NB = 30, LO = -5, HI = 5, D = 2000;

function hist(xs: number[]) {
  const h = new Array(NB).fill(0);
  for (const x of xs) { const i = Math.floor(((x - LO) / (HI - LO)) * NB); if (i >= 0 && i < NB) h[i]++; }
  return h as number[];
}

export function SpinScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), both = flag(props, "both");
  const [rho, setRho] = useState(num(props, "link", 0));
  const k = useRunOut(true, 3.5, Math.round(rho * 100));
  const uv = useMemo(() => { const r = seeded(21); return Array.from({ length: D }, () => [gauss(r), gauss(r)] as [number, number]); }, []);
  const xy = uv.map(([u, v]) => [u, rho * u + Math.sqrt(1 - rho * rho) * v] as [number, number]);
  const j = Math.max(1, Math.floor(k * D));
  const sums = xy.slice(0, j).map(([x, y]) => x + y), indep = uv.slice(0, j).map(([u, v]) => u + v);
  const m = sums.reduce((a, b) => a + b, 0) / sums.length, sv = sums.reduce((a, s) => a + (s - m) ** 2, 0) / Math.max(1, sums.length - 1);
  const [lx, ly] = xy[j - 1]!;
  const dial = (cx: number, val: number, tone: string, lab: string) => {
    const a = (-90 + Math.max(-1, Math.min(1, val / 3)) * 150) * (Math.PI / 180);
    return (
      <g>
        <circle cx={cx} cy="46" r="32" style={{ fill: "none", stroke: K.line, strokeWidth: 1.5 }} />
        <line x1={cx} y1="46" x2={cx + 28 * Math.cos(a)} y2={46 + 28 * Math.sin(a)} style={{ stroke: tone, strokeWidth: 3, strokeLinecap: "round" }} />
        <circle cx={cx} cy="46" r="3.5" style={{ fill: tone }} />
        <text x={cx} y="96" textAnchor="middle" className="b2t">{lab} = {fx(val, 1)}</text>
      </g>
    );
  };
  const panel = (x0: number, x1: number, h: number[], tone: string, lab: string) => {
    const X = lin(0, NB, x0, x1), base = H - 22;
    return (
      <g>
        <Bars counts={h} x={i => X(i) + 0.5} w={(x1 - x0) / NB - 1} base={base} height={100} tone={tone} top={D * 0.14} />
        <line x1={x0} x2={x1} y1={base} y2={base} className="b2axis" />
        <text x={(x0 + x1) / 2} y={H - 6} textAnchor="middle" className="b2t">{lab}</text>
      </g>
    );
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Two spinners with link ${fx(rho)}. ${quiet ? "Their sum is drawn when you lock in." : `The sum X + Y has variance ${fx(2 + 2 * rho)}.`}`}>
      {dial(110, lx, K.sky, "X")}
      {dial(250, ly, K.pink, "Y")}
      <text x="180" y="50" textAnchor="middle" className="b2t">+</text>
      {!quiet && !both && panel(40, 320, hist(sums), K.amber, "X + Y")}
      {!quiet && both && <>{panel(14, 172, hist(indep), K.sky, "independent")}{panel(188, 346, hist(sums), K.amber, rho < 0 ? "leaning against" : rho > 0 ? "leaning with" : "independent")}</>}
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<Slider label="Link: Y leans with X" value={rho} min={-0.9} max={0.9} step={0.05} onChange={setRho} format={x => (Math.abs(x) < 0.025 ? "none" : x < 0 ? `against, ${fx(x)}` : `with, ${fx(x)}`)} marks={[{ v: -0.7, label: "against" }, { v: 0, label: "none" }, { v: 0.7, label: "with" }]} />}
      readouts={<>
        <Read label="Var X, Var Y" value="1, 1" />
        <Read label="Cov(X, Y)" value={fx(rho)} tone="pink" />
        {!quiet && <Read label="Var(X + Y) = 1 + 1 + 2 Cov" value={fx(2 + 2 * rho)} tone="amber" />}
        {!quiet && <Read label="Spread of the draws so far" value={fx(sv)} />}
      </>}
    />
  );
}
