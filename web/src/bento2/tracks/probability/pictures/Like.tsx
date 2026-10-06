// The Likelihood viewer (09, 16): data in, the likelihood curve over the parameter, a marker you drag along it, a log
// switch (the peak stays put), and a second value to compare as a likelihood ratio. Poisson mode fits a rate to a
// made-up week of counts. The evidence walk (16, 19) flips a coin and draws the running log likelihood ratio between
// "fair" and "loaded" against two stop lines.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle, useClock, useSvgDrag } from "../../../ui/kit";
import { seeded } from "../maths";
import { Act, Acts, K, lin, WrapToggle } from "./parts";

const W = 360, H = 240;
const WEEK = [12, 9, 15, 11, 8, 14, 8];

export function LikeScene({ props, marker }: SceneProps) {
  const first = str<"coin" | "poisson" | "walk">(props, "mode", "coin");
  const [mode, setMode] = useState(first);
  const pick = <WrapToggle label="Likelihood viewer" value={mode} onChange={setMode} options={[{ v: "coin", label: "Coin" }, { v: "poisson", label: "Counts" }, { v: "walk", label: "Evidence walk" }]} />;
  return mode === "walk" ? <Walk pick={pick} /> : <Curve props={mode === first ? props : {}} poisson={mode === "poisson"} marker={marker} pick={pick} />;
}

function Curve({ props, poisson, marker, pick }: { props: SceneProps["props"]; poisson: boolean; marker?: [number, number]; pick: React.ReactNode }) {
  const quiet = flag(props, "quiet");
  const [n, setN] = useState(num(props, "n", 10));
  const [k, setK] = useState(num(props, "k", 7));
  const [days, setDays] = useState(7);
  const [log, setLog] = useState(false);
  const [p1, setP1] = useState(poisson ? 13 : 0.5);
  const [p2, setP2] = useState(poisson ? 9 : 0.5);
  const kk = Math.min(k, n);
  // log-likelihood, up to a constant
  const S = (WEEK.reduce((a, b) => a + b, 0) * days) / 7;
  const ll = poisson ? (l: number) => S * Math.log(l) - days * l : (q: number) => kk * Math.log(Math.max(1e-300, q)) + (n - kk) * Math.log(Math.max(1e-300, 1 - q));
  const [lo, hi] = poisson ? [4, 18] : [0, 1];
  const peak = poisson ? S / days : kk / n, top = ll(Math.min(hi - 1e-9, Math.max(lo + 1e-9, peak)));
  const rel = (q: number) => (log ? Math.max(-10, ll(q) - top) : Math.exp(ll(q) - top));
  const X = lin(lo, hi, 30, W - 12), Y = log ? lin(-10, 0, H - 26, 16) : lin(0, 1, H - 26, 16);
  const pts: [number, number][] = Array.from({ length: 241 }, (_, i) => { const q = lo + ((hi - lo) * Math.min(0.9999, Math.max(0.0001, i / 240))); return [X(q), Y(rel(q))]; });
  const { ref, drag } = useSvgDrag();
  const toQ = (px: number) => Math.min(hi - 0.001, Math.max(lo + 0.001, lo + ((px - X(lo)) / (X(hi) - X(lo))) * (hi - lo)));
  const lr = Math.exp(ll(p1) - ll(p2));
  const ticks = poisson ? [4, 8, 12, 16] : [0, 0.25, 0.5, 0.75, 1];
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={poisson ? `The likelihood of a rate λ for these counts peaks at the mean, ${fx(peak, 1)}.` : `The likelihood of p for ${kk} heads in ${n} flips${quiet ? "" : ` peaks at ${fx(peak)}`}.`}>
      <line x1={X(lo)} x2={X(hi)} y1={Y(log ? -10 : 0)} y2={Y(log ? -10 : 0)} className="b2axis" />
      {ticks.map(t => <text key={t} x={X(t)} y={H - 8} textAnchor="middle" className="b2t">{poisson ? t : fx(t)}</text>)}
      {!quiet && <>
        <path d={path(pts)} style={{ fill: "none", stroke: K.sky, strokeWidth: 2.5 }} />
        <line x1={X(peak)} x2={X(peak)} y1={Y(log ? 0 : 1)} y2={Y(log ? -10 : 0)} style={{ stroke: K.sky, strokeDasharray: "4 4" }} />
        <text x={X(peak)} y="12" textAnchor="middle" className="b2t sky">peak {poisson ? fx(peak, 1) : fx(peak)}</text>
        <line x1={X(p2)} x2={X(p2)} y1={Y(rel(p2))} y2={Y(log ? -10 : 0)} style={{ stroke: K.pink, strokeWidth: 2 }} />
        <circle cx={X(p2)} cy={Y(rel(p2))} r="5" style={{ fill: K.pink }} />
        <rect x={X(lo)} y="0" width={X(hi) - X(lo)} height={H} style={{ fill: "transparent" }} {...drag(px => setP1(toQ(px)))} />
        <line x1={X(p1)} x2={X(p1)} y1={Y(rel(p1))} y2={Y(log ? -10 : 0)} style={{ stroke: K.amber, strokeWidth: 2 }} />
        <circle cx={X(p1)} cy={Y(rel(p1))} r="9" className="b2marker" {...drag(px => setP1(toQ(px)))} />
      </>}
      {marker && <><line x1={X(marker[0])} x2={X(marker[0])} y1="20" y2={Y(log ? -10 : 0)} className="b2mark guess" /><text x={X(marker[0]) + 6} y="34" className="b2t">your guess</text></>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {poisson ? <Slider label="Days of counts" value={days} min={7} max={56} step={7} onChange={setDays} />
          : <><Slider label="Flips n" value={n} min={1} max={100} step={1} onChange={v => { setK(Math.round((kk / n) * v)); setN(v); }} />
            <Slider label="Heads k" value={kk} min={0} max={n} step={1} onChange={setK} /></>}
        <Slider label={poisson ? "Compare with λ" : "Compare with p"} value={p2} min={lo + (poisson ? 0 : 0.01)} max={hi - (poisson ? 0 : 0.01)} step={poisson ? 0.1 : 0.01} onChange={setP2} format={x => fx(x, poisson ? 1 : 2)} />
        <Acts><Act on={log} onClick={() => setLog(v => !v)}>Log</Act></Acts>
        {pick}
      </>}
      readouts={quiet ? <Read label="Data" value={`${kk} heads in ${n}`} /> : <>
        <Read label={poisson ? "Counts" : "Data"} value={poisson ? `${days} days, mean ${fx(peak, 1)}` : `${kk} heads in ${n}`} />
        <Read label={poisson ? "λ̂ = x̄" : "p̂ = k/n"} value={fx(peak, poisson ? 1 : 3)} tone="sky" />
        <Read label={`Height at ${fx(p1, poisson ? 1 : 2)}`} value={log ? fx(rel(p1), 2) : fx(rel(p1), 3)} tone="amber" />
        <Read label={`L(${fx(p1, poisson ? 1 : 2)}) / L(${fx(p2, poisson ? 1 : 2)})`} value={lr > 1e4 || lr < 1e-4 ? lr.toExponential(1) : fx(lr, 3)} tone="pink" />
      </>}
    />
  );
}

const STOP = Math.log(19);
function Walk({ pick }: { pick: React.ReactNode }) {
  const [truth, setTruth] = useState<"fair" | "loaded">("loaded");
  const [seed, setSeed] = useState(1);
  const t = useClock(true, 1e4);
  const flips = useMemo(() => { const r = seeded(seed * 3 + (truth === "fair" ? 1 : 2)); return Array.from({ length: 80 }, () => r.next() < (truth === "fair" ? 0.5 : 0.75)); }, [seed, truth]);
  const llr = [0]; for (const f of flips) llr.push(llr[llr.length - 1]! + (f ? Math.log(1.5) : Math.log(0.5)));
  const stopAt = llr.findIndex(v => Math.abs(v) >= STOP);
  const end = stopAt < 0 ? 80 : stopAt, shown = Math.min(end, Math.floor(t * 4) + 1);
  const X = lin(0, 80, 34, W - 10), Y = lin(-5, 5, H - 20, 14);
  const heads = flips.slice(0, shown).filter(Boolean).length;
  const done = shown >= end && stopAt >= 0;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`The running log likelihood ratio after ${shown} flips is ${fx(llr[shown]!)}; the stop lines are at plus and minus ${fx(STOP)}.`}>
      <line x1={X(0)} x2={X(80)} y1={Y(STOP)} y2={Y(STOP)} style={{ stroke: K.amber, strokeWidth: 1.5, strokeDasharray: "6 4" }} />
      <line x1={X(0)} x2={X(80)} y1={Y(-STOP)} y2={Y(-STOP)} style={{ stroke: K.sky, strokeWidth: 1.5, strokeDasharray: "6 4" }} />
      <text x={X(80)} y={Y(STOP) - 6} textAnchor="end" className="b2t amber">stop: loaded</text>
      <text x={X(80)} y={Y(-STOP) + 16} textAnchor="end" className="b2t sky">stop: fair</text>
      <line x1={X(0)} x2={X(80)} y1={Y(0)} y2={Y(0)} className="b2axis" />
      <path d={path(llr.slice(0, shown + 1).map((v, i) => [X(i), Y(Math.max(-5, Math.min(5, v)))]))} style={{ fill: "none", stroke: K.pink, strokeWidth: 2.2 }} />
      <circle cx={X(shown)} cy={Y(Math.max(-5, Math.min(5, llr[shown]!)))} r="5" style={{ fill: K.pink }} />
      <text x="4" y={Y(0) + 4} className="b2t">0</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Acts><Act onClick={() => setSeed(s => s + 1)}>New coin</Act></Acts>
        <Toggle label="The coin really is" value={truth} onChange={v => { setTruth(v); setSeed(s => s + 1); }} options={[{ v: "fair", label: "Really fair" }, { v: "loaded", label: "Really loaded" }]} />
        {pick}
      </>}
      readouts={<>
        <Read label="Flips" value={`${heads} heads in ${shown}`} />
        <Read label="log LR, loaded over fair" value={fx(llr[shown]!)} tone="pink" />
        <Read label="Bayes factor" value={fx(Math.exp(llr[shown]!), 2)} />
        {done && <Read label="Stopped" value={llr[end]! > 0 ? "says loaded" : "says fair"} tone={llr[end]! > 0 ? "amber" : "sky"} big />}
      </>}
    />
  );
}
