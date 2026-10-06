// Estimators that know their own wobble. Variance mode of the Sample machine (10): samples from a population with
// variance 100, each giving a divide-by-n and a divide-by-(n − 1) estimate, with running averages. The bootstrap (11):
// resample 10 values with replacement and stack each resample's median. The Beta updater (12): a prior over a coin's
// chance, fed flips one at a time, with the posterior's mean and middle 95%. Honest error bars (project 3): one data
// set, three intervals.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { betaPdf, betaQuantile, gauss, median, seeded } from "../maths";
import { COMMUTE } from "../lessons2";
import { Act, Acts, K, lin, useRunOut } from "./parts";

const W = 360, H = 240;

/* ---------------- variance estimates ---------------- */
export function VarEstScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet");
  const [n, setN] = useState(num(props, "n", 4));
  const [seed, setSeed] = useState(1);
  const R = 300, k = useRunOut(!quiet, 5, seed * 17 + n);
  const est = useMemo(() => {
    const r = seeded(seed + 60 + n);
    return Array.from({ length: R }, () => { const xs = Array.from({ length: n }, () => 50 + 10 * gauss(r)); const m = xs.reduce((a, b) => a + b, 0) / n; const ss = xs.reduce((a, x) => a + (x - m) ** 2, 0); return [ss / n, ss / (n - 1)] as [number, number]; });
  }, [seed, n]);
  const j = quiet ? 0 : Math.max(1, Math.floor(k * R));
  const shown = est.slice(0, j);
  const avg = (i: 0 | 1) => (shown.length ? shown.reduce((a, e) => a + e[i], 0) / shown.length : NaN);
  const X = lin(0, 320, 22, W - 12);
  const row = (i: 0 | 1, y0: number, tone: string, lab: string) => {
    const stack = new Map<number, number>();
    return (
      <g>
        <text x="22" y={y0 - 76} className="b2t" style={{ fill: tone }}>{lab}</text>
        {shown.map((e, q) => { const b = Math.min(79, Math.floor(e[i] / 4)), c = stack.get(b) ?? 0; stack.set(b, c + 1); return c < 24 ? <circle key={q} cx={X(b * 4 + 2)} cy={y0 - 3 - c * 3} r="1.6" style={{ fill: tone, fillOpacity: 0.75 }} /> : null; })}
        <line x1={X(0)} x2={X(320)} y1={y0} y2={y0} className="b2axis" />
        {shown.length > 0 && <><line x1={X(avg(i))} x2={X(avg(i))} y1={y0 - 74} y2={y0 + 4} style={{ stroke: tone, strokeWidth: 2.5 }} />
          <text x={X(avg(i)) + 5} y={y0 - 62} className="b2t" style={{ fill: tone }}>{fx(avg(i), 0)}</text></>}
      </g>
    );
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Samples of ${n} from a population with variance 100.${quiet ? "" : ` Dividing by n averages ${fx(avg(0), 0)}; dividing by n − 1 averages ${fx(avg(1), 0)}.`}`}>
      <line x1={X(100)} x2={X(100)} y1="10" y2={H - 20} style={{ stroke: K.amber, strokeDasharray: "6 4", strokeWidth: 1.5 }} />
      <text x={X(100) + 4} y={H - 6} className="b2t amber">true 100</text>
      {row(0, 108, K.pink, "divide by n")}
      {row(1, 214, K.sky, "divide by n − 1")}
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<>
        <Slider label="Sample size n" value={n} min={2} max={10} step={1} onChange={setN} />
        <Acts><Act onClick={() => setSeed(s => s + 1)}>Draw again</Act></Acts>
      </>}
      readouts={<>
        <Read label="Samples" value={j} />
        {!quiet && <Read label="Divide by n, average" value={fx(avg(0), 1)} tone="pink" />}
        {!quiet && <Read label="Divide by n − 1, average" value={fx(avg(1), 1)} tone="sky" />}
        {!quiet && <Read label="(n − 1)/n × 100" value={fx((100 * (n - 1)) / n, 1)} />}
      </>}
    />
  );
}

/* ---------------- the bootstrap ---------------- */
const DATA = [12, 15, 17, 18, 21, 22, 24, 27, 31, 40];
export function BootScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), auto = flag(props, "auto");
  const data = str<string>(props, "data", "plain") === "commute" ? COMMUTE : DATA;
  const [B, setB] = useState(auto ? 1000 : 1);
  const [seed, setSeed] = useState(1);
  const k = useRunOut(true, auto ? 4 : 0.6, seed * 1000 + B);
  const all = useMemo(() => {
    const r = seeded(seed + 900);
    return Array.from({ length: 1000 }, () => { const idx = Array.from({ length: 10 }, () => r.int(0, 9)); return { idx, med: median(idx.map(i => data[i]!)), out: 10 - new Set(idx).size }; });
  }, [seed, data]);
  const shown = all.slice(0, Math.max(1, Math.round(B * k)));
  const last = shown[shown.length - 1]!;
  const counts = new Array(10).fill(0) as number[]; last.idx.forEach(i => counts[i]!++);
  const meds = shown.map(s => s.med), mm = meds.reduce((a, b) => a + b, 0) / meds.length;
  const se = Math.sqrt(meds.reduce((a, m) => a + (m - mm) ** 2, 0) / Math.max(1, meds.length - 1));
  const sorted = [...meds].sort((a, b) => a - b), q = (p: number) => sorted[Math.min(sorted.length - 1, Math.max(0, Math.round(p * (sorted.length - 1))))]!;
  const outShare = shown.reduce((a, s) => a + s.out, 0) / (shown.length * 10);
  const lo = Math.min(...data), hi = Math.max(...data), X = lin(lo - 2, hi + 2, 20, W - 12);
  const stack = new Map<number, number>();
  const cw = (W - 20) / 10;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={quiet ? "A data table of 10 values, ready to resample." : `Resample ${shown.length}: ${last.out} of the 10 values left out, median ${fx(last.med, 1)}. The bootstrap SE of the median is ${fx(se, 2)}.`}>
      {data.map((v, i) => (
        <g key={i}>
          <rect x={10 + i * cw + 2} y="10" width={cw - 4} height="30" rx="7" style={counts[i] || quiet ? { fill: K.sky, fillOpacity: 0.25, stroke: K.sky } : { fill: "none", stroke: K.faint, strokeDasharray: "3 3" }} />
          <text x={10 + i * cw + cw / 2} y="31" textAnchor="middle" className="b2t" style={{ fill: counts[i] || quiet ? K.text : K.muted }}>{v}</text>
          {counts[i]! > 1 && !quiet && <text x={10 + i * cw + cw / 2} y="58" textAnchor="middle" className="b2t sky">×{counts[i]}</text>}
        </g>
      ))}
      {!quiet && meds.map((m, i) => { const b = Math.round(m * 2), c = stack.get(b) ?? 0; stack.set(b, c + 1); return c < 40 ? <circle key={i} cx={X(m)} cy={H - 26 - c * 3.4} r="2" style={{ fill: K.amber, fillOpacity: 0.85 }} /> : null; })}
      <line x1={X(lo - 2)} x2={X(hi + 2)} y1={H - 22} y2={H - 22} className="b2axis" />
      {shown.length >= 20 && <><line x1={X(q(0.05))} x2={X(q(0.95))} y1={H - 14} y2={H - 14} style={{ stroke: K.amber, strokeWidth: 3 }} />
        <text x={X(q(0.95)) + 4} y={H - 10} className="b2t amber">90%</text></>}
      <text x="12" y="80" className="b2t">medians of the resamples</text>
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<Acts>
        <Act onClick={() => { setB(b => Math.min(1000, b + 1)); }}>Resample</Act>
        <Act onClick={() => setB(b => Math.min(1000, b + 100))}>×100</Act>
        <Act onClick={() => setB(1000)}>×1,000</Act>
        <Act onClick={() => { setSeed(s => s + 1); setB(1); }}>Start over</Act>
      </Acts>}
      readouts={<>
        <Read label="Resamples" value={shown.length} />
        {!quiet && <Read label="Left out this time" value={`${last.out} of 10`} tone="sky" />}
        {!quiet && <Read label="Left out, on average" value={`${fx(outShare * 100, 1)}%`} tone="sky" />}
        {!quiet && <Read label="SE of the median" value={fx(se, 2)} tone="amber" />}
        {!quiet && shown.length >= 20 && <Read label="90% interval" value={`${fx(q(0.05), 1)} to ${fx(q(0.95), 1)}`} tone="amber" />}
      </>}
    />
  );
}

/* ---------------- the Beta updater ---------------- */
export function BetaScene({ props, marker }: SceneProps) {
  const quiet = flag(props, "quiet");
  const [a, setA] = useState(num(props, "a", 2));
  const [b, setB] = useState(num(props, "b", 2));
  const [h, setH] = useState(num(props, "heads", 0));
  const [t, setT] = useState(num(props, "tails", 0));
  const A = a + h, Bb = b + t, mean = A / (A + Bb);
  const lo = betaQuantile(0.025, A, Bb), hi = betaQuantile(0.975, A, Bb);
  const X = lin(0, 1, 24, W - 12);
  const xs = Array.from({ length: 201 }, (_, i) => Math.min(0.999, Math.max(0.001, i / 200)));
  const post = xs.map(x => betaPdf(x, A, Bb)), prior = xs.map(x => betaPdf(x, a, b));
  const top = Math.min(14, Math.max(...post.filter(Number.isFinite), ...prior.filter(Number.isFinite), 1.2)) * 1.08;
  const Y = lin(0, top, H - 24, 12);
  const cl = (v: number) => Y(Math.min(top, v));
  const band: [number, number][] = [[X(lo), Y(0)], ...xs.filter(x => x >= lo && x <= hi).map(x => [X(x), cl(betaPdf(x, A, Bb))] as [number, number]), [X(hi), Y(0)]];
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Prior Beta(${fx(a, 1)}, ${fx(b, 1)}) and ${h} heads, ${t} tails.${quiet ? "" : ` The posterior Beta(${fx(A, 1)}, ${fx(Bb, 1)}) has mean ${fx(mean, 3)}.`}`}>
      <path d={path(xs.map((x, i) => [X(x), cl(prior[i]!)]))} style={{ fill: "none", stroke: K.pink, strokeWidth: 1.8, strokeDasharray: "6 4" }} />
      <text x={X(0.02)} y="22" className="b2t pink">prior</text>
      {!quiet && <>
        <path d={`${path(band)} Z`} style={{ fill: K.sky, fillOpacity: 0.22 }} />
        <path d={path(xs.map((x, i) => [X(x), cl(post[i]!)]))} style={{ fill: "none", stroke: K.sky, strokeWidth: 2.5 }} />
        <line x1={X(mean)} x2={X(mean)} y1={Y(0)} y2={cl(betaPdf(mean, A, Bb))} style={{ stroke: K.amber, strokeWidth: 2.5 }} />
        <text x={X(mean)} y={Math.max(14, cl(betaPdf(mean, A, Bb)) - 8)} textAnchor="middle" className="b2t amber">mean {fx(mean)}</text>
      </>}
      {marker && <><line x1={X(marker[0])} x2={X(marker[0])} y1="30" y2={Y(0)} className="b2mark guess" /><text x={X(marker[0]) + 6} y="44" className="b2t">your guess</text></>}
      <line x1={X(0)} x2={X(1)} y1={Y(0)} y2={Y(0)} className="b2axis" />
      {[0, 0.25, 0.5, 0.75, 1].map(v => <text key={v} x={X(v)} y={H - 6} textAnchor="middle" className="b2t">{fx(v)}</text>)}
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<>
        <Slider label="Prior a" value={a} min={0.5} max={20} step={0.5} onChange={setA} format={x => fx(x, 1)} />
        <Slider label="Prior b" value={b} min={0.5} max={20} step={0.5} onChange={setB} format={x => fx(x, 1)} />
        <Acts>
          <Act onClick={() => setH(x => x + 1)}>Head</Act>
          <Act onClick={() => setT(x => x + 1)}>Tail</Act>
          <Act onClick={() => { setH(0); setT(0); }}>Clear flips</Act>
        </Acts>
      </>}
      readouts={<>
        <Read label="Flips" value={`${h} heads, ${t} tails`} />
        {!quiet && <Read label="Posterior" value={`Beta(${fx(A, 1)}, ${fx(Bb, 1)})`} tone="sky" />}
        {!quiet && <Read label="Posterior mean" value={fx(mean, 3)} tone="amber" big />}
        {!quiet && <Read label="Middle 95%" value={`${fx(lo)} to ${fx(hi)}`} tone="sky" />}
        {!quiet && <Read label="Weight on the data" value={fx((h + t) / (a + b + h + t))} />}
      </>}
    />
  );
}

/* ---------------- honest error bars (project 3) ---------------- */
export function ErrBarsScene({ props }: SceneProps) {
  const project = flag(props, "project");
  const [n, setN] = useState(num(props, "n", 20));
  const [k, setK] = useState(num(props, "k", 14));
  const { b2, save, note } = useB2();
  const kk = Math.min(k, n), ph = kk / n;
  const wald = 1.96 * Math.sqrt((ph * (1 - ph)) / n);
  const boot = useMemo(() => {
    const r = seeded(n * 1000 + kk), vals: number[] = [];
    for (let s = 0; s < 2000; s++) { let c = 0; for (let i = 0; i < n; i++) if (r.next() < ph) c++; vals.push(c / n); }
    vals.sort((x, y) => x - y);
    const m = vals.reduce((x, y) => x + y, 0) / vals.length;
    return { lo: vals[50]!, hi: vals[1949]!, se: Math.sqrt(vals.reduce((x, v) => x + (v - m) ** 2, 0) / (vals.length - 1)) };
  }, [n, kk, ph]);
  const A = 1 + kk, B = 1 + n - kk, pm = A / (A + B), blo = betaQuantile(0.025, A, B), bhi = betaQuantile(0.975, A, B);
  const rows: [string, number, number, number, string][] = [
    ["Best fit (MLE)", ph, Math.max(0, ph - wald), Math.min(1, ph + wald), K.sky],
    ["Bootstrap", ph, boot.lo, boot.hi, K.amber],
    ["Bayes, flat prior", pm, blo, bhi, K.pink],
  ];
  const X = lin(0, 1, 24, W - 12);
  const agree = Math.max(...rows.map(r => r[2])) <= Math.min(...rows.map(r => r[3]));
  const width = Math.max(...rows.map(r => r[3] - r[2])) - Math.min(...rows.map(r => r[3] - r[2]));
  const verdict = width < 0.03 ? "All three agree closely." : "They differ most when n is small or the share is near 0 or 1.";
  const saved = Math.abs(((b2.shelf.bootSE?.value as number) ?? NaN) - boot.se) < 1e-12 && Math.abs(((b2.shelf.postMean?.value as number) ?? NaN) - pm) < 1e-12;
  const onSave = () => {
    save("bootSE", boot.se, "pr-errbars", { note: `bootstrap SE of p̂, ${kk} of ${n}` });
    save("postMean", pm, "pr-errbars", { note: `posterior mean, flat prior, ${kk} of ${n}` });
    note({ id: "pr-errbars", track: "pr", title: "Honest error bars", project: "pr-errbars", data: { n, k: kk },
      lines: [`${kk} successes in ${n} (made up).`, ...rows.map(r => `${r[0]}: ${fx(r[1], 3)}, from ${fx(r[2], 3)} to ${fx(r[3], 3)}.`), verdict] });
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`${kk} of ${n}: three intervals. ${verdict}`}>
      {rows.map(([lab, c, lo, hi, tone], i) => {
        const y = 40 + i * 62;
        return (
          <g key={lab}>
            <text x={X(0)} y={y - 12} className="b2t" style={{ fill: tone }}>{lab}</text>
            <line x1={X(lo)} x2={X(hi)} y1={y} y2={y} style={{ stroke: tone, strokeWidth: 6, strokeLinecap: "round", strokeOpacity: 0.7 }} />
            <circle cx={X(c)} cy={y} r="7" style={{ fill: tone, stroke: "var(--page)", strokeWidth: 2 }} />
            <text x={X(hi) + 8 > W - 60 ? X(lo) - 8 : X(hi) + 8} y={y + 5} textAnchor={X(hi) + 8 > W - 60 ? "end" : "start"} className="b2t">{fx(lo)} to {fx(hi)}</text>
          </g>
        );
      })}
      {agree && <rect x={X(Math.max(...rows.map(r => r[2])))} y="22" width={Math.max(1, X(Math.min(...rows.map(r => r[3]))) - X(Math.max(...rows.map(r => r[2]))))} height="170" style={{ fill: K.text, fillOpacity: 0.06 }} />}
      <line x1={X(0)} x2={X(1)} y1={H - 22} y2={H - 22} className="b2axis" />
      {[0, 0.25, 0.5, 0.75, 1].map(v => <text key={v} x={X(v)} y={H - 6} textAnchor="middle" className="b2t">{fx(v)}</text>)}
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<>
        <Slider label="Tries n" value={n} min={4} max={200} step={1} onChange={v => { setK(Math.round((kk / n) * v)); setN(v); }} />
        <Slider label="Successes k" value={kk} min={0} max={n} step={1} onChange={setK} />
      </>}
      readouts={<>
        <Read label="p̂ = k/n" value={fx(ph, 3)} tone="sky" />
        <Read label="Bootstrap SE" value={fx(boot.se, 3)} tone="amber" />
        <Read label="Posterior mean" value={fx(pm, 3)} tone="pink" />
        <Read label="Where they agree" value={agree ? `${fx(Math.max(...rows.map(r => r[2])))} to ${fx(Math.min(...rows.map(r => r[3])))}` : "nowhere"} />
      </>}
      foot={project && <SaveRow what={<>Keep <b>bootSE = {fx(boot.se, 3)}</b> and <b>postMean = {fx(pm, 3)}</b>: Luck detector v1</>} saved={saved} onSave={onSave} />}
    />
  );
}
