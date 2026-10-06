// ★ The Simulator (probability.md, "New for Development"): (a) a running average with its ±2σ/√n band (01), and the
// π dartboard (01, Use it); (b) letters into envelopes (02); (c) event rain on a time strip with counts per window and
// the Binomial(n, λ/n) overlay (05); (d) a random walk with its longest streak (19); (e) a two-state Markov board
// (19); (f) the p-value wall with Bonferroni, the BH staircase and a peeking mode (15). Every run is seeded: Again
// moves the seed, so a run can be replayed exactly.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle, useClock } from "../../../ui/kit";
import { Phi, poissonPmf, binomPmf, gauss, seeded } from "../maths";
import { Act, Acts, Bars, commas, K, lin, useRunOut, WrapToggle } from "./parts";

type Mode = "avg" | "pi" | "env" | "rain" | "walk" | "markov" | "wall";
const MODES: { v: Mode; label: string }[] = [
  { v: "avg", label: "Average" }, { v: "env", label: "Envelopes" }, { v: "rain", label: "Rain" },
  { v: "walk", label: "Walk" }, { v: "markov", label: "Markov" }, { v: "wall", label: "p-values" }, { v: "pi", label: "π" },
];
const W = 360, H = 240;

export function SimScene({ props, place }: SceneProps) {
  const first = str<Mode>(props, "mode", "avg");
  const [mode, setMode] = useState<Mode>(first);
  const lessonModes = first === "walk" ? MODES.filter(m => m.v === "walk" || m.v === "markov") : first === "markov" ? MODES.filter(m => m.v === "markov" || m.v === "walk") : null;
  const choices = place === "lesson" ? lessonModes : MODES;
  const pick = choices && choices.length > 1 ? <WrapToggle label="Simulator mode" value={mode} options={choices} onChange={setMode} /> : null;
  const P = { props: mode === first ? props : {}, pick };
  return mode === "avg" ? <Avg {...P} /> : mode === "pi" ? <Pi {...P} /> : mode === "env" ? <Env {...P} /> : mode === "rain" ? <Rain {...P} />
    : mode === "walk" ? <Walk {...P} /> : mode === "markov" ? <Markov {...P} /> : <Wall {...P} />;
}
type Part = { props: SceneProps["props"]; pick: React.ReactNode };

/* ---------------- (a) the running average and its band ---------------- */
function Avg({ props, pick }: Part) {
  const quiet = flag(props, "quiet"), half = flag(props, "half"), upto = num(props, "upto", 0);
  const [p, setP] = useState(num(props, "p", 0.5));
  const [N, setN] = useState(upto || 100000);
  const [seed, setSeed] = useState(1);
  const k = useRunOut(true, 2.4, seed * 7 + N);
  // the running share of heads, kept at log-spaced checkpoints (every n up to 60, then 300 steps per run)
  const pts = useMemo(() => {
    const r = seeded(seed + 11), marks = new Set<number>();
    for (let n = 1; n <= Math.min(N, 60); n++) marks.add(n);
    for (let i = 0; i <= 300; i++) marks.add(Math.round(10 ** ((i / 300) * Math.log10(N))));
    const out: [number, number][] = [];
    let h = 0;
    for (let n = 1; n <= N; n++) { if (r.next() < p) h++; if (marks.has(n)) out.push([n, h / n]); }
    return out;
  }, [seed, N, p]);
  const L = Math.log10(Math.max(10, N)), X = lin(0, L, 40, W - 12), Y = lin(0, 1, H - 30, 12);
  const shownTo = Math.max(1, Math.round(10 ** (k * Math.log10(N))));
  const seen = pts.filter(([n]) => n <= shownTo);
  const last = seen[seen.length - 1] ?? [1, 0];
  const sig = Math.sqrt(p * (1 - p)), band = (n: number) => (2 * sig) / Math.sqrt(n);
  const bandPts: [number, number][] = [];
  for (let i = 0; i <= 80; i++) { const n = 10 ** ((i / 80) * L); bandPts.push([n, Math.min(1, p + band(n))]); }
  const lower = bandPts.map(([n]) => [n, Math.max(0, p - band(n))] as [number, number]).reverse();
  const poly = [...bandPts, ...lower].map(([n, y]) => `${X(Math.log10(n)).toFixed(1)},${Y(y).toFixed(1)}`).join(" ");
  const ticks = [1, 10, 100, 1000, 10000, 100000].filter(t => t <= N);
  const tickLab = (t: number) => (t >= 1000 ? `${t / 1000}k` : String(t));
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`The running share of heads over ${commas(last[0])} flips settles toward p = ${fx(p)}, inside a band that narrows like 1 over root n.`}>
      <polygon points={poly} style={{ fill: K.amber, fillOpacity: 0.16 }} />
      <line x1={X(0)} x2={X(L)} y1={Y(p)} y2={Y(p)} style={{ stroke: K.amber, strokeWidth: 1.5, strokeDasharray: "6 4" }} />
      <line x1={X(0)} x2={X(L)} y1={Y(0)} y2={Y(0)} className="b2axis" />
      {ticks.map(t => <g key={t}><line x1={X(Math.log10(t))} x2={X(Math.log10(t))} y1={Y(0)} y2={Y(0) + 5} className="b2axis" /><text x={X(Math.log10(t))} y={H - 10} textAnchor={t >= 10000 && t === ticks[ticks.length - 1] ? "end" : "middle"} className="b2t">{tickLab(t)}</text></g>)}
      <text x="8" y={Y(1) + 10} className="b2t">1</text><text x="8" y={Y(0)} className="b2t">0</text>
      <path d={path(seen.map(([n, s]) => [X(Math.log10(n)), Y(s)]))} style={{ fill: "none", stroke: K.sky, strokeWidth: 2 }} />
      {half && [100, 400].filter(n => n <= N).map(n => (
        <g key={n}>
          <line x1={X(Math.log10(n))} x2={X(Math.log10(n))} y1={Y(p + band(n))} y2={Y(p - band(n))} style={{ stroke: K.amber, strokeWidth: 2 }} />
          <text x={X(Math.log10(n)) - 4} y={Y(p + band(n)) - 4} textAnchor="end" className="b2t amber">±{fx(band(n))}</text>
        </g>
      ))}
      <text x={X(0) - 6} y={Y(p) + 4} textAnchor="end" className="b2t amber">p</text>
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<>
        <Slider label="Chance of heads p" value={p} min={0.05} max={0.95} step={0.01} onChange={setP} format={x => fx(x)} />
        <Acts>
          {[1, 100, 100000].map(n => <Act key={n} on={N === n} onClick={() => { setN(n); setSeed(s => s + 1); }}>{n === 1 ? "1 flip" : `${commas(n)} flips`}</Act>)}
          <Act onClick={() => setSeed(s => s + 1)}>Again</Act>
        </Acts>
        {pick}
      </>}
      readouts={<>
        <Read label="Flips" value={commas(last[0])} />
        <Read label="Share of heads" value={fx(last[1], 3)} tone="sky" />
        {!quiet && <Read label="Band, ±2σ/√n" value={`±${fx(band(last[0]), 3)}`} tone="amber" />}
      </>}
    />
  );
}

/* ---------------- π from random drops ---------------- */
function Pi({ pick }: Part) {
  const [e, setE] = useState(3);
  const [seed, setSeed] = useState(1);
  const D = Math.round(10 ** e);
  const k = useRunOut(true, 1.6, seed * 13 + D);
  const pts = useMemo(() => { const r = seeded(seed + 77); return Array.from({ length: D }, () => [r.next(), r.next()] as [number, number]); }, [seed, D]);
  const shown = Math.max(1, Math.round(k * D));
  let inside = 0; for (let i = 0; i < shown; i++) if (pts[i]![0] ** 2 + pts[i]![1] ** 2 <= 1) inside++;
  const est = (4 * inside) / shown, S = 210, ox = 20, oy = 14;
  const draw = pts.slice(0, Math.min(shown, 1500));
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`${commas(shown)} random drops in a square; the share inside the quarter circle times 4 is ${fx(est, 3)}.`}>
      <rect x={ox} y={oy} width={S} height={S} style={{ fill: "none", stroke: K.line }} />
      <path d={`M${ox},${oy} A${S},${S} 0 0 1 ${ox + S},${oy + S}`} transform={`rotate(0)`} style={{ fill: "none", stroke: K.amber, strokeWidth: 1.5 }} />
      {draw.map(([x, y], i) => <circle key={i} cx={ox + x * S} cy={oy + S - y * S} r={1.6} style={{ fill: x * x + y * y <= 1 ? K.sky : K.pink, fillOpacity: 0.8 }} />)}
      <text x={ox + S + 12} y={oy + 30} className="b2t sky">inside</text>
      <text x={ox + S + 12} y={oy + 52} className="b2t pink">outside</text>
      <text x={ox + S + 12} y={oy + 96} className="b2t">4 × share</text>
      <text x={ox + S + 12} y={oy + 116} className="b2t amber">{fx(est, 3)}</text>
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<>
        <Slider label="Drops" value={e} min={1} max={5.05} step={0.01} onChange={setE} format={() => commas(D)} marks={[{ v: 2, label: "100" }, { v: 4, label: "10,000" }, { v: 5.0414, label: "110,000" }]} />
        <Acts><Act onClick={() => setSeed(s => s + 1)}>Drop again</Act></Acts>
        {pick}
      </>}
      readouts={<>
        <Read label="Estimate of π" value={fx(est, 4)} tone="amber" big />
        <Read label="Off by" value={fx(Math.abs(est - Math.PI), 4)} />
        <Read label="Typical error, 1.64/√n" value={fx(1.642 / Math.sqrt(shown), 4)} />
      </>}
    />
  );
}

/* ---------------- (b) letters into envelopes ---------------- */
function Env({ props, pick }: Part) {
  const quiet = flag(props, "quiet");
  const [n, setN] = useState(num(props, "n", 10));
  const [seed, setSeed] = useState(1);
  const S = 400, k = useRunOut(!quiet, 6, seed * 3 + n);
  const runs = useMemo(() => {
    const r = seeded(seed + 5);
    return Array.from({ length: S }, () => { const perm = r.shuffle(Array.from({ length: n }, (_, i) => i)); return perm.map((v, i) => v === i); });
  }, [seed, n]);
  const j = Math.max(0, Math.min(S - 1, Math.floor(k * (S - 1))));
  const cum: number[] = [];
  let tot = 0; for (let i = 0; i <= j; i++) { tot += runs[i]!.filter(Boolean).length; cum.push(tot / (i + 1)); }
  const now = runs[j]!, cols = Math.ceil(Math.sqrt(n * 2.4)), rows = Math.ceil(n / cols), cell = Math.min(24, 330 / cols, 96 / rows);
  const X = lin(0, S, 40, W - 12), Y = lin(0, 3, H - 22, 128);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={quiet ? `${n} letters, shuffled into ${n} envelopes.` : `Shuffle ${j + 1}: ${now.filter(Boolean).length} of ${n} letters in the right envelope. Running average ${fx(cum[j]!)}.`}>
      {now.map((m, i) => (
        <rect key={i} x={(W - cols * cell) / 2 + (i % cols) * cell + 1.5} y={10 + Math.floor(i / cols) * cell + 1.5} width={cell - 3} height={cell - 3} rx="3"
          style={m && !quiet ? { fill: K.amber } : { fill: "none", stroke: K.faint, strokeWidth: 1.2 }} />
      ))}
      <line x1={X(0)} x2={X(S)} y1={Y(0)} y2={Y(0)} className="b2axis" />
      {!quiet && <><line x1={X(0)} x2={X(S)} y1={Y(1)} y2={Y(1)} style={{ stroke: K.amber, strokeDasharray: "6 4", strokeWidth: 1.2 }} />
        <text x="8" y={Y(1) + 4} className="b2t amber">1</text></>}<text x="8" y={Y(0)} className="b2t">0</text>
      {!quiet && <path d={path(cum.map((c, i) => [X(i + 1), Y(Math.min(3, c))]))} style={{ fill: "none", stroke: K.sky, strokeWidth: 2 }} />}
      <text x={X(S)} y={H - 6} textAnchor="end" className="b2t">shuffles</text>
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<>
        <Slider label="Letters n" value={n} min={2} max={100} step={1} onChange={v => { setN(v); setSeed(s => s + 1); }} />
        <Acts><Act onClick={() => setSeed(s => s + 1)}>Shuffle again</Act></Acts>
        {pick}
      </>}
      readouts={<>
        <Read label="Letters" value={n} />
        {!quiet && <Read label="Shuffles" value={commas(j + 1)} />}
        {!quiet && <Read label="Right envelope, this shuffle" value={now.filter(Boolean).length} tone="amber" />}
        {!quiet && <Read label="Running average" value={fx(cum[j]!)} tone="sky" />}
      </>}
    />
  );
}

/* ---------------- (c) event rain ---------------- */
function Rain({ props, pick }: Part) {
  const quiet = flag(props, "quiet"), exact = flag(props, "exact");
  const [lam, setLam] = useState(num(props, "rate", 3));
  const [binom, setBinom] = useState(false);
  const [bn, setBn] = useState(10);
  const [seed, setSeed] = useState(1);
  const t = useClock(true, 7.5);
  const M = 20;
  const { arrivals, counts } = useMemo(() => {
    const r = seeded(seed + 31), arrivals: number[] = [];
    for (let x = -Math.log(1 - r.next()) / lam; x < M; x += -Math.log(1 - r.next()) / lam) arrivals.push(x);
    // many more minutes, for the count bars
    const counts = new Array(16).fill(0);
    for (let w = 0; w < 4000; w++) { let c = 0; for (let x = -Math.log(1 - r.next()) / lam; x < 1; x += -Math.log(1 - r.next()) / lam) c++; counts[Math.min(15, c)]++; }
    return { arrivals, counts };
  }, [seed, lam]);
  const win = Math.floor(t * 1.5) % M, inWin = arrivals.filter(a => a >= win && a < win + 1).length;
  const sx = lin(0, M, 14, W - 14), kMax = Math.min(15, Math.max(6, Math.ceil(lam * 2.6)));
  const bx = lin(0, kMax + 1, 30, W - 10), bw = (W - 40) / (kMax + 1) - 4, base = H - 22, hgt = 116;
  const pmf = Array.from({ length: kMax + 1 }, (_, k) => poissonPmf(k, lam));
  const emp = counts.slice(0, kMax + 1).map(c => c / 4000);
  const top = Math.max(...pmf, ...emp) * 1.05;
  const tall = pmf.map((v, k) => [v, k] as [number, number]).sort((a, b) => b[0] - a[0]).slice(0, 2).map(x => x[1]);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Arrivals at ${fx(lam, 1)} a minute over ${M} minutes; minute ${win + 1} caught ${inWin}.`}>
      <rect x={sx(win)} y="8" width={sx(1) - sx(0)} height="52" rx="4" style={{ fill: K.sky, fillOpacity: 0.18, stroke: K.sky }} />
      <line x1={sx(0)} x2={sx(M)} y1="60" y2="60" className="b2axis" />
      {Array.from({ length: M + 1 }, (_, i) => <line key={i} x1={sx(i)} x2={sx(i)} y1="57" y2="63" className="b2axis" />)}
      {arrivals.map((a, i) => <circle key={i} cx={sx(a)} cy={22 + ((i * 37) % 30)} r="3.2" style={{ fill: a >= win && a < win + 1 ? K.amber : K.muted }} />)}
      <text x={sx(0)} y="78" className="b2t">20 minutes; the window counts {inWin}</text>
      {!quiet && <>
        <Bars counts={emp} x={i => bx(i) + 2} w={bw} base={base} height={hgt} tone={K.sky} top={top} opacity={0.55} />
        {binom && <Bars counts={Array.from({ length: kMax + 1 }, (_, k) => (k <= bn ? binomPmf(k, bn, Math.min(1, lam / bn)) : 0))} x={i => bx(i) + 2} w={bw} base={base} height={hgt} tone={K.pink} top={top} outline />}
        {pmf.map((v, k) => <circle key={k} cx={bx(k) + 2 + bw / 2} cy={base - (v / top) * hgt} r="3.5" style={{ fill: K.amber }} />)}
        {exact && tall.map(k => <text key={k} x={bx(k) + 2 + bw / 2} y={base - (pmf[k]! / top) * hgt - 8} textAnchor="middle" className="b2t amber">{fx(pmf[k]!, 3)}</text>)}
      </>}
      <line x1={bx(0)} x2={bx(kMax + 1)} y1={base} y2={base} className="b2axis" />
      {Array.from({ length: kMax + 1 }, (_, k) => <text key={k} x={bx(k) + 2 + bw / 2} y={H - 6} textAnchor="middle" className="b2t">{k}</text>)}
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<>
        <Slider label="Rate λ, a minute" value={lam} min={0.5} max={6} step={0.1} onChange={setLam} format={x => fx(x, 1)} marks={[{ v: 1, label: "1" }, { v: 2, label: "2" }, { v: 3, label: "3" }]} />
        <Acts>
          <Act on={binom} onClick={() => setBinom(b => !b)}>Binomial(n, λ/n)</Act>
          <Act onClick={() => setSeed(s => s + 1)}>New rain</Act>
        </Acts>
        {binom && <Slider label="Slots n" value={bn} min={Math.ceil(lam)} max={80} step={1} onChange={setBn} />}
        {pick}
      </>}
      readouts={<>
        <Read label="This window" value={inWin} tone="amber" />
        {!quiet && <Read label="Mean = variance = λ" value={fx(lam, 1)} />}
        {!quiet && <Read label="P(X = 0)" value={fx(Math.exp(-lam), 4)} />}
        {!quiet && <Read label="Most common count" value={Math.abs(lam - Math.round(lam)) < 1e-9 ? `${Math.round(lam) - 1} and ${Math.round(lam)} tie` : String(Math.floor(lam))} tone="amber" />}
      </>}
    />
  );
}

/* ---------------- (d) the random walk and its longest streak ---------------- */
const longest = (fl: boolean[]) => { let best = 1, run = 1, at = 0, bestAt = 0; for (let i = 1; i < fl.length; i++) { if (fl[i] === fl[i - 1]) { run++; if (run > best) { best = run; bestAt = at; } } else { run = 1; at = i; } } return { best, bestAt }; };
function Walk({ props, pick }: Part) {
  const quiet = flag(props, "quiet"), many = flag(props, "many");
  const [seed, setSeed] = useState(1);
  const k = useRunOut(!quiet, 2.2, seed);
  const flips = useMemo(() => { const r = seeded(seed + 101); return Array.from({ length: 100 }, () => r.next() < 0.5); }, [seed]);
  const hist = useMemo(() => {
    if (!many) return null;
    const r = seeded(999), h = new Array(21).fill(0);
    for (let s = 0; s < 2000; s++) h[Math.min(20, longest(Array.from({ length: 100 }, () => r.next() < 0.5)).best)]++;
    return h as number[];
  }, [many]);
  const shown = Math.max(2, Math.round(k * 100));
  const tot = [0]; flips.forEach(f => tot.push(tot[tot.length - 1]! + (f ? 1 : -1)));
  const { best, bestAt } = longest(flips);
  const lo = Math.min(...tot), hi = Math.max(...tot), X = lin(0, 100, 30, W - 10), Y = lin(Math.min(-6, lo - 1), Math.max(6, hi + 1), many ? 110 : H - 24, 10);
  const showStreak = !quiet && shown >= bestAt + best;
  const hx = lin(0, 21, 30, W - 10), base = H - 18;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A fair coin's running total over 100 flips.${quiet ? "" : ` The longest streak is ${best}.`}`}>
      <line x1={X(0)} x2={X(100)} y1={Y(0)} y2={Y(0)} className="b2axis" />
      {!quiet && <path d={path(tot.slice(0, shown + 1).map((v, i) => [X(i), Y(v)]))} style={{ fill: "none", stroke: K.sky, strokeWidth: 2 }} />}
      {quiet && <text x={W / 2} y={Y(0) - 12} textAnchor="middle" className="b2t">100 flips, drawn when you lock in</text>}
      {showStreak && <path d={path(tot.slice(bestAt, bestAt + best + 1).map((v, i) => [X(bestAt + i), Y(v)]))} style={{ fill: "none", stroke: K.amber, strokeWidth: 4 }} />}
      {showStreak && <text x={X(bestAt + best / 2)} y={Y(Math.max(tot[bestAt]!, tot[bestAt + best]!)) - 8} textAnchor="middle" className="b2t amber">{best} in a row</text>}
      <text x="4" y={Y(0) + 4} className="b2t">0</text>
      {hist && <>
        <Bars counts={hist} x={i => hx(i) + 1} w={(W - 40) / 21 - 2} base={base} height={90} tone={K.amber} />
        <line x1={hx(0)} x2={hx(21)} y1={base} y2={base} className="b2axis" />
        {[3, 7, 11, 15, 19].map(v => <text key={v} x={hx(v) + 6} y={H - 3} textAnchor="middle" className="b2t">{v}</text>)}
        <text x={W - 10} y={130} textAnchor="end" className="b2t amber">longest streak, 2,000 runs</text>
      </>}
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<><Acts><Act onClick={() => setSeed(s => s + 1)}>New 100 flips</Act></Acts>{pick}</>}
      readouts={<>
        <Read label="Flips" value={quiet ? 100 : shown} />
        {!quiet && <Read label="Running total" value={tot[shown]!} tone="sky" />}
        {!quiet && <Read label="Longest streak" value={best} tone="amber" />}
      </>}
    />
  );
}

/* ---------------- (e) the two-state Markov board ---------------- */
function Markov({ props, pick }: Part) {
  const [a, setA] = useState(num(props, "a", 0.25));
  const [b, setB] = useState(num(props, "b", 0.5));
  const [start, setStart] = useState<"A" | "B">("B");
  const t = useClock(true, 1e4);
  const T = 2400;
  const chain = useMemo(() => {
    const r = seeded(7), s: number[] = [start === "A" ? 0 : 1];
    for (let i = 1; i < T; i++) { const c = s[i - 1]!; s.push(c === 0 ? (r.next() < a ? 1 : 0) : (r.next() < b ? 0 : 1)); }
    const inA = [0]; s.forEach(x => inA.push(inA[inA.length - 1]! + (x === 0 ? 1 : 0)));
    return { s, inA };
  }, [a, b, start]);
  const step = Math.min(T - 1, Math.floor(t * 3)), now = chain.s[step]!, shareA = chain.inA[step + 1]! / (step + 1);
  const piA = b / (a + b);
  const cA = [80, 92] as const, cB = [210, 92] as const, R = 38, by = lin(0, 1, 214, 40);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Sunny switches to rainy with chance ${fx(a)}, rainy to sunny with ${fx(b)}. After ${step + 1} days the share of sunny days is ${fx(shareA)}; the long run is ${fx(piA)}.`}>
      <circle cx={cA[0]} cy={cA[1]} r={R} style={{ fill: K.amber, fillOpacity: now === 0 ? 0.35 : 0.12, stroke: K.amber, strokeWidth: 1.5 }} />
      <circle cx={cB[0]} cy={cB[1]} r={R} style={{ fill: K.sky, fillOpacity: now === 1 ? 0.35 : 0.12, stroke: K.sky, strokeWidth: 1.5 }} />
      <text x={cA[0]} y={cA[1] + 5} textAnchor="middle" className="b2t amber">sunny A</text>
      <text x={cB[0]} y={cB[1] + 5} textAnchor="middle" className="b2t sky">rainy B</text>
      <path d={`M${cA[0] + 26},${cA[1] - 28} Q145,40 ${cB[0] - 26},${cB[1] - 28}`} style={{ fill: "none", stroke: K.muted, strokeWidth: 1.5 }} />
      <path d={`M${cB[0] - 26},${cB[1] + 28} Q145,144 ${cA[0] + 26},${cA[1] + 28}`} style={{ fill: "none", stroke: K.muted, strokeWidth: 1.5 }} />
      <text x="145" y="46" textAnchor="middle" className="b2t">a = {fx(a)}</text>
      <text x="145" y="150" textAnchor="middle" className="b2t">b = {fx(b)}</text>
      <circle cx={now === 0 ? cA[0] : cB[0]} cy={cA[1] - R - 2} r="7" style={{ fill: K.text }} />
      {([{ lab: "A", v: shareA, pi: piA, c: K.amber, x: 290 }, { lab: "B", v: 1 - shareA, pi: 1 - piA, c: K.sky, x: 328 }]).map(({ lab, v, pi, c, x }) => (
        <g key={lab}>
          <rect x={x - 13} y={by(v)} width="26" height={by(0) - by(v)} rx="3" style={{ fill: c, fillOpacity: 0.8 }} />
          <line x1={x - 18} x2={x + 18} y1={by(pi)} y2={by(pi)} style={{ stroke: K.text, strokeWidth: 1.5, strokeDasharray: "4 3" }} />
          <text x={x} y={H - 8} textAnchor="middle" className="b2t">{lab}</text>
        </g>
      ))}
      <text x="309" y="28" textAnchor="middle" className="b2t">share</text>
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<>
        <Slider label="a: A to B" value={a} min={0.05} max={0.95} step={0.01} onChange={setA} format={x => fx(x)} />
        <Slider label="b: B to A" value={b} min={0.05} max={0.95} step={0.01} onChange={setB} format={x => fx(x)} />
        <Toggle label="Start in" value={start} onChange={setStart} options={[{ v: "A", label: "Start sunny" }, { v: "B", label: "Start rainy" }]} />
        {pick}
      </>}
      readouts={<>
        <Read label="Days" value={commas(step + 1)} />
        <Read label="Share sunny" value={fx(shareA, 3)} tone="amber" />
        <Read label="π_A = b/(a + b)" value={fx(piA, 3)} />
      </>}
    />
  );
}

/* ---------------- (f) the p-value wall, and peeking ---------------- */
function Wall({ props, pick }: Part) {
  const quiet = flag(props, "quiet"), many = flag(props, "many");
  const [m, setM] = useState(num(props, "m", 20));
  const [seed, setSeed] = useState(1);
  const [sorted, setSorted] = useState(false);
  const [bonf, setBonf] = useState(false);
  const [bh, setBh] = useState(false);
  const [peek, setPeek] = useState(false);
  const ps = useMemo(() => { const r = seeded(seed + 3); return Array.from({ length: m }, () => Math.max(1e-4, r.next())); }, [seed, m]);
  const famShare = useMemo(() => {
    if (!many) return null;
    const r = seeded(4242); let any = 0;
    for (let f = 0; f < 10000; f++) { let hit = false; for (let i = 0; i < m; i++) if (r.next() < 0.05) hit = true; if (hit) any++; }
    return any / 10000;
  }, [many, m]);
  const order = sorted || bh ? [...ps].sort((x, y) => x - y) : ps;
  const X = lin(0, m, 36, W - 8), Y = lin(0, 4, H - 24, 14), bw = Math.max(1, (W - 44) / m - 1.5);
  const ny = (p: number) => Y(-Math.log10(p));
  const dips = ps.filter(p => p < 0.05).length;
  const bhLine = order.map((_, i) => [X(i), ny(((i + 1) * 0.05) / m), X(i + 1), ny(((i + 1) * 0.05) / m)]);
  // peeking: one null experiment checked after every 10 people, up to 200
  const peekRun = useMemo(() => {
    const r = seeded(seed + 900); let s = 0; const out: [number, number][] = [];
    for (let n = 1; n <= 200; n++) { s += gauss(r); if (n % 10 === 0) out.push([n, 2 * (1 - Phi(Math.abs(s) / Math.sqrt(n)))]); }
    return out;
  }, [seed]);
  const peekShare = useMemo(() => {
    if (!peek) return 0;
    const r = seeded(31337); let stopped = 0;
    for (let e = 0; e < 1000; e++) { let s = 0; for (let n = 1; n <= 200; n++) { s += gauss(r); if (n % 10 === 0 && 2 * (1 - Phi(Math.abs(s) / Math.sqrt(n))) < 0.05) { stopped++; break; } } }
    return stopped / 1000;
  }, [peek]);
  const stopAt = peekRun.findIndex(([, p]) => p < 0.05);
  const PX = lin(0, 200, 36, W - 8);
  const svg = peek ? (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`One experiment with no real effect, checked every 10 people.${stopAt >= 0 ? ` It first dips under 0.05 at ${peekRun[stopAt]![0]} people.` : " It never dips under 0.05."}`}>
      <line x1={PX(0)} x2={PX(200)} y1={ny(0.05)} y2={ny(0.05)} style={{ stroke: K.amber, strokeDasharray: "6 4", strokeWidth: 1.5 }} />
      <text x={PX(200)} y={ny(0.05) - 6} textAnchor="end" className="b2t amber">0.05</text>
      <line x1={PX(0)} x2={PX(200)} y1={Y(0)} y2={Y(0)} className="b2axis" />
      <path d={path(peekRun.map(([n, p]) => [PX(n), ny(p)]))} style={{ fill: "none", stroke: K.sky, strokeWidth: 2 }} />
      {peekRun.map(([n, p], i) => <circle key={n} cx={PX(n)} cy={ny(p)} r={i === stopAt ? 6 : 3} style={{ fill: i === stopAt ? K.amber : K.sky }} />)}
      <text x={PX(100)} y={H - 6} textAnchor="middle" className="b2t">people so far</text>
      <text x="4" y={Y(0)} className="b2t">1</text><text x="4" y={Y(3) + 4} className="b2t">0.001</text>
    </svg>
  ) : (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`${m} tests with nothing real. Taller bars are smaller p-values; ${quiet ? "some" : dips} dip under 0.05.`}>
      {order.map((p, i) => <rect key={i} x={X(i) + 0.75} y={ny(p)} width={bw} height={Y(0) - ny(p)} rx={Math.min(2, bw / 3)} style={{ fill: p < 0.05 ? K.amber : K.faint }} />)}
      <line x1={X(0)} x2={X(m)} y1={Y(0)} y2={Y(0)} className="b2axis" />
      <line x1={X(0)} x2={X(m)} y1={ny(0.05)} y2={ny(0.05)} style={{ stroke: K.amber, strokeDasharray: "6 4", strokeWidth: 1.5 }} />
      <text x={X(m)} y={ny(0.05) - 5} textAnchor="end" className="b2t amber">α = 0.05</text>
      {bonf && <><line x1={X(0)} x2={X(m)} y1={ny(0.05 / m)} y2={ny(0.05 / m)} style={{ stroke: K.pink, strokeWidth: 1.5 }} /><text x={X(0) + 4} y={ny(0.05 / m) - 5} className="b2t pink">α/m</text></>}
      {bh && <path d={bhLine.map(([x1, y1, x2, y2], i) => `${i ? "L" : "M"}${x1!.toFixed(1)},${y1!.toFixed(1)} L${x2!.toFixed(1)},${y2!.toFixed(1)}`).join(" ")} style={{ fill: "none", stroke: K.sky, strokeWidth: 2 }} />}
      {bh && <text x={X(m * 0.55)} y={ny(0.05 * 0.55) + 16} className="b2t sky">BH</text>}
      <text x="4" y={Y(0)} className="b2t">1</text><text x="4" y={Y(3) + 4} className="b2t">0.001</text>
    </svg>
  );
  return (
    <Scene className="prs" svg={svg}
      controls={<>
        {!peek && <Slider label="Tests m" value={m} min={1} max={100} step={1} onChange={setM} />}
        <Acts>
          <Act onClick={() => setSeed(s => s + 1)}>Run again</Act>
          {!peek && <Act on={sorted || bh} onClick={() => setSorted(s => !s)}>Sort</Act>}
          {!peek && <Act on={bonf} onClick={() => setBonf(v => !v)}>Bonferroni</Act>}
          {!peek && <Act on={bh} onClick={() => setBh(v => !v)}>BH staircase</Act>}
          <Act on={peek} onClick={() => setPeek(v => !v)}>Peek every 10</Act>
        </Acts>
        {pick}
      </>}
      readouts={peek ? <>
        <Read label="Stopped at" value={stopAt >= 0 ? `${peekRun[stopAt]![0]} people` : "never"} tone="amber" />
        <Read label="Of 1,000 peeking runs, stopped as “significant”" value={`${fx(peekShare * 100, 1)}%`} />
      </> : <>
        {!quiet && <Read label="Under 0.05 by luck" value={dips} tone="amber" />}
        {bonf && <Read label="Under α/m" value={ps.filter(p => p <= 0.05 / m).length} tone="pink" />}
        {famShare != null && <Read label="Runs with at least one, of 10,000" value={`${fx(famShare * 100, 1)}%`} tone="amber" big />}
        {!quiet && famShare == null && <Read label="1 − 0.95ᵐ" value={`${fx((1 - 0.95 ** m) * 100, 1)}%`} />}
      </>}
    />
  );
}
