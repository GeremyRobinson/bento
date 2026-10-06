// The Sample machine and Galton board (07, and the sum machine project): drag any population shape (lopsided,
// two-humped, flat, or your own bars), pick the sample size n, and 3,000 samples' averages pile into a histogram with
// the normal curve the central limit theorem predicts. The Galton board view drops a ball through n rows, each row
// pushing it by one piece of the same shape, and the pile is still a bell.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, Toggle, useClock, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { seeded } from "../maths";
import { Bars, K, lin, useRunOut } from "./parts";

const W = 360, H = 240;
const SHAPES: Record<string, number[]> = {
  lopsided: [8, 6, 4.5, 3, 2.2, 1.5, 1, 0.7, 0.4, 0.2, 0.1],
  twohump: [0.6, 4, 7, 4, 0.8, 0.3, 0.8, 4, 7, 4, 0.6],
  flat: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
};
const S = 3000, NB = 44;

export function CltScene({ props, marker, place }: SceneProps) {
  const quiet = flag(props, "quiet"), bracket = flag(props, "bracket"), auto = flag(props, "auto"), project = flag(props, "project");
  const [w, setW] = useState<number[]>(SHAPES[str(props, "shape", "lopsided")] ?? SHAPES.lopsided!);
  const [n, setN] = useState(num(props, "n", 1));
  const [view, setView] = useState<"means" | "galton">("means");
  const [as, setAs] = useState<"avg" | "total">(project ? "total" : "avg");
  const { b2, save, note } = useB2();
  const tot = w.reduce((a, b) => a + b, 0), p = w.map(v => v / tot);
  const mu = p.reduce((s, q, i) => s + q * i, 0), sig = Math.sqrt(p.reduce((s, q, i) => s + q * (i - mu) ** 2, 0));
  // in the guess the population is shown in points with σ = 10 around 50
  const sd10 = bracket, a = sd10 ? 10 / sig : 1, c = sd10 ? 50 - a * mu : 0, T = (v: number) => a * v + c;
  const cdf = p.reduce<number[]>((acc, q) => [...acc, (acc[acc.length - 1] ?? 0) + q], []);
  const draw = (u: number) => { const i = cdf.findIndex(x => u <= x); return i < 0 ? 10 : i; };
  const runs = auto ? 10000 : S;
  const means = useMemo(() => {
    const r = seeded(17 + n);
    return Array.from({ length: runs }, () => { let s = 0; for (let k = 0; k < n; k++) s += draw(r.next()); return s / n; });
  }, [w, n, runs]); // eslint-disable-line react-hooks/exhaustive-deps
  const k = useRunOut(true, 2.5, n * 31 + Math.round(tot * 7));
  const shown = means.slice(0, Math.max(1, Math.floor(k * means.length)));
  const lo = T(0), hi = T(10), X = lin(lo, hi, 24, W - 10), base = H - 22, hgt = 118;
  const h = new Array(NB).fill(0) as number[];
  for (const m of shown) { const i = Math.min(NB - 1, Math.floor(((m - 0) / 10) * NB)); h[i]!++; }
  const binW = (X(hi) - X(lo)) / NB;
  const se = (sig * a) / Math.sqrt(n), MU = T(mu);
  const peak = Math.max(...h) || 1;
  const dens = (x: number) => Math.exp(-(((x - MU) / se) ** 2) / 2) / (se * Math.sqrt(2 * Math.PI));
  const scaleD = (shown.length * ((hi - lo) / NB));
  const top = Math.max(peak, dens(MU) * scaleD) * 1.05;
  const normal: [number, number][] = Array.from({ length: 121 }, (_, i) => { const x = lo + ((hi - lo) * i) / 120; return [X(x), base - ((dens(x) * scaleD) / top) * hgt]; });
  // the population panel: drag a bar to reshape it
  const { ref, drag } = useSvgDrag();
  const PX = lin(0, 11, 24, 150), pmax = Math.max(...w);
  const totalMode = as === "total", unit = (v: number) => (totalMode ? v * n : v);
  // the Galton board: one ball falls through n rows (shown up to 12), pushed by one piece per row
  const t = useClock(view === "galton", 4);
  const rowsShown = Math.min(n, 12);
  const ball = useMemo(() => { const r = seeded(Math.floor(t / 2.2) + 400); return Array.from({ length: n }, () => draw(r.next())); }, [Math.floor(t / 2.2), n, w]); // eslint-disable-line react-hooks/exhaustive-deps
  const frac = (t % 2.2) / 2.2;
  const cum = ball.reduce<number[]>((acc, v) => [...acc, (acc[acc.length - 1] ?? 0) + v], [0]);
  const gX = (row: number, s: number) => X(T(row ? s / row : mu)), gY = lin(0, rowsShown, 92, 182);
  const rowAt = Math.min(rowsShown, Math.floor(frac * (rowsShown + 1)));
  const ballX = gX(Math.max(1, Math.round((rowAt / rowsShown) * n)), cum[Math.max(1, Math.round((rowAt / rowsShown) * n))]!);
  const zSum: [number, number, number] = [n * mu, sig * Math.sqrt(n), n * mu + 2.33 * sig * Math.sqrt(n)];
  const saved = JSON.stringify(b2.shelf.zSum?.value) === JSON.stringify(zSum);
  const onSave = () => {
    save("zSum", zSum, "pr-sum", { labels: ["mean of the total", "SD of the total", "1-in-100 cutoff"], note: `the sum of ${n} pieces` });
    note({ id: "pr-sum", track: "pr", title: "The sum machine", project: "pr-sum", data: { n, mean: zSum[0], sd: zSum[1] },
      lines: [`One piece: mean ${fx(mu)}, SD ${fx(sig)}.`, `The total of ${n}: mean ${fx(zSum[0])}, SD ${fx(zSum[1])}.`, `Only 1 in 100 totals passes ${fx(zSum[2])} (z = 2.33).`] });
  };
  const half = marker ? marker[0] : 0;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A population with mean ${fx(T(mu))} and SD ${fx(sig * a)}. ${quiet ? `Averages of ${n} are drawn when you lock in.` : `${shown.length} averages of ${n} pile into a bell with SD ${fx(se)}.`}`}>
      {w.map((v, i) => (
        <rect key={i} x={PX(i) + 1} y={70 - (v / pmax) * 56} width={PX(1) - PX(0) - 2} height={(v / pmax) * 56} rx="2" style={{ fill: K.pink, fillOpacity: 0.8, cursor: "ns-resize" }}
          {...drag((_, y) => setW(ws => ws.map((u, j) => (j === i ? Math.max(0.05, ((70 - y) / 56) * pmax) : u))))} />
      ))}
      <line x1={PX(0)} x2={PX(11)} y1="70" y2="70" className="b2axis" />
      <text x={PX(11) + 8} y="30" className="b2t pink">one piece</text>
      <text x={PX(11) + 8} y="48" className="b2t">drag its bars</text>
      {view === "means" && !quiet && <>
        <Bars counts={h} x={i => X(lo) + i * binW + 0.5} w={binW - 1} base={base} height={hgt} tone={K.sky} top={top} opacity={0.75} />
        <path d={path(normal)} style={{ fill: "none", stroke: K.amber, strokeWidth: 2 }} />
      </>}
      {view === "galton" && <>
        {Array.from({ length: rowsShown }, (_, r) => Array.from({ length: 11 }, (_, i) => <circle key={`${r}-${i}`} cx={X(T(i))} cy={gY(r + 0.5)} r="1.8" style={{ fill: K.faint }} />))}
        <Bars counts={h} x={i => X(lo) + i * binW + 0.5} w={binW - 1} base={base} height={44} tone={K.sky} top={peak} opacity={0.75} />
        <circle cx={ballX} cy={gY(rowAt)} r="6" style={{ fill: K.amber }} />
      </>}
      {bracket && marker && <g>
        <line x1={X(MU - half)} x2={X(MU + half)} y1={base + 8} y2={base + 8} style={{ stroke: K.text, strokeWidth: 2, strokeDasharray: "2 3" }} />
        <line x1={X(MU - half)} x2={X(MU - half)} y1={base - 40} y2={base + 12} className="b2mark guess" />
        <line x1={X(MU + half)} x2={X(MU + half)} y1={base - 40} y2={base + 12} className="b2mark guess" />
      </g>}
      {auto && bracket && <g>
        <line x1={X(MU - 1.96 * se)} x2={X(MU - 1.96 * se)} y1={base - hgt} y2={base} style={{ stroke: K.amber, strokeWidth: 2 }} />
        <line x1={X(MU + 1.96 * se)} x2={X(MU + 1.96 * se)} y1={base - hgt} y2={base} style={{ stroke: K.amber, strokeWidth: 2 }} />
        <text x={X(MU + 1.96 * se) + 4} y={base - hgt + 14} className="b2t amber">95%</text>
      </g>}
      <line x1={X(lo)} x2={X(hi)} y1={base} y2={base} className="b2axis" />
      {[0, 2.5, 5, 7.5, 10].map(v => <text key={v} x={X(T(v))} y={H - 6} textAnchor="middle" className="b2t">{fx(unit(T(v)), sd10 ? 0 : 1).replace(/\.0$/, "")}</text>)}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Sample size n" value={n} min={1} max={50} step={1} onChange={setN} />
        <Toggle label="Shape" value={(Object.keys(SHAPES).find(s => JSON.stringify(SHAPES[s]) === JSON.stringify(w)) ?? "own") as string}
          onChange={v => SHAPES[v] && setW(SHAPES[v]!)} options={[{ v: "lopsided", label: "Lopsided" }, { v: "twohump", label: "Two humps" }, { v: "flat", label: "Flat" }]} />
        <Toggle label="View" value={view} onChange={setView} options={[{ v: "means", label: "Averages" }, { v: "galton", label: "Galton board" }]} />
        {(project || place === "tool") && <Toggle label="Axis" value={as} onChange={setAs} options={[{ v: "avg", label: "Average" }, { v: "total", label: "Total" }]} />}
      </>}
      readouts={<>
        <Read label="One piece: mean, SD" value={`${fx(T(mu))}, ${fx(sig * a)}`} tone="pink" />
        {!quiet && (totalMode
          ? <Read label="Total: mean, SD (σ√n)" value={`${fx(n * mu)}, ${fx(sig * Math.sqrt(n))}`} tone="sky" />
          : <Read label="Averages: SD (σ/√n)" value={fx(se)} tone="sky" />)}
        {!quiet && project && <Read label="1-in-100 cutoff" value={fx(zSum[2])} tone="amber" big />}
        {bracket && marker && <Read label="Your bracket" value={`±${fx(half)}`} />}
        {auto && bracket && <Read label="Middle 95%" value={`±${fx(1.96 * se)}`} tone="amber" />}
      </>}
      foot={project && <SaveRow what={<>Keep <b>zSum</b>: total mean {fx(zSum[0])}, SD {fx(zSum[1])}, cutoff {fx(zSum[2])}</>} saved={saved} onSave={onSave} />}
    />
  );
}
