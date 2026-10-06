// The Surprise meter (information.md), in five modes:
// one: a spinner with a slice of size p and a surprise bar beside it, marked in halvings (02).
// bars: up to 8 probability bars you drag (they stay summing to 1), their surprise bars, and the entropy as a level line (03).
// coin: the entropy curve H(p) with a coin that flips live and a running bits-per-flip tally (04).
// cross: the truth p and a model q you drag; the meter shows H(p, q) above the floor H(p), the gap shaded (09).
// circles: a joint table you drag, drawn as two circles with areas H(X) and H(Y) overlapping by I(X; Y) (10).
import { useMemo, useState, type ReactNode } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle, useClock, useSvgDrag, useTween } from "../../../ui/kit";
import { crossEntropy, entropy, h2, seeded, surprise } from "../maths";

const W = 360;
/** a probability as people write it: 1/8, 2/3, 0.15 */
const fracText = (p: number) => {
  if (p < 1e-9) return "0";
  for (const d of [2, 3, 4, 5, 6, 8, 16, 32, 64, 128, 256, 512, 1000, 1024]) if (Math.abs(p * d - Math.round(p * d)) < 1e-6 && Math.round(p * d) > 0) return `${Math.round(p * d)}/${d}`;
  return Math.abs(p * 100 - Math.round(p * 100)) < 1e-6 ? fx(p, 2) : fx(p, 3);
};
type Mode = "one" | "bars" | "coin" | "cross" | "circles";

export function SurpriseScene(props: SceneProps) {
  const [mode, setMode] = useState<Mode>(str<Mode>(props.props, "mode", "one"));
  const pick = props.place !== "lesson" && (
    <Toggle label="Meter" value={mode} onChange={setMode} options={[{ v: "one", label: "One" }, { v: "bars", label: "Bars" }, { v: "coin", label: "Coin" }, { v: "cross", label: "Model" }, { v: "circles", label: "Two" }]} />
  );
  if (mode === "bars") return <Bars {...props} pick={pick} />;
  if (mode === "coin") return <Coin {...props} pick={pick} />;
  if (mode === "cross") return <Cross {...props} pick={pick} />;
  if (mode === "circles") return <Circles {...props} pick={pick} />;
  return <One {...props} pick={pick} />;
}
type WithPick = SceneProps & { pick: ReactNode };

/* ------------------------------------------------------------------ one event ------------------------------------------------------------------ */

function One({ props, marker, pick }: WithPick) {
  const [s, setS] = useState(surprise(num(props, "p", 0.25)));
  const p = 2 ** -s;
  const quiet = flag(props, "quiet"), halve = flag(props, "halve");
  const t = Math.max(0, useClock(true, 0));
  const shown = useTween(quiet ? 0 : s, 900);
  const cx = 110, cy = 130, R = 92, spin = (t * 40) % 360;
  const wedge = (frac: number) => {
    if (frac >= 0.9999) return `M${cx},${cy - R} A${R},${R} 0 1 1 ${cx - 0.01},${cy - R} Z`;
    const a = frac * 2 * Math.PI, x = cx + R * Math.sin(a), y = cy - R * Math.cos(a);
    return `M${cx},${cy} L${cx},${cy - R} A${R},${R} 0 ${frac > 0.5 ? 1 : 0} 1 ${x},${y} Z`;
  };
  const bx = 268, base = 240, per = 20; // 20 px a bit, up to 10 bits
  const ticks = Array.from({ length: 11 }, (_, k) => k);
  const svg = (
    <svg viewBox={`0 0 ${W} 260`} className="b2pic" role="img" aria-label={`A spinner with a slice of ${fracText(p)}. Its surprise is ${quiet ? "hidden" : `${fx(s)} bits`}.`}>
      <g transform={`rotate(${spin} ${cx} ${cy})`}>
        <circle cx={cx} cy={cy} r={R} className="b2bar track" />
        <path d={wedge(p)} className="b2bar amber" />
        {(halve || !quiet) && ticks.slice(1, Math.min(10, Math.floor(s + 1e-9)) + 1).map(k => <path key={k} d={wedge(2 ** -k)} className="b2mark sky" />)}
      </g>
      <path d={`M${cx - 7},${cy - R - 12} L${cx + 7},${cy - R - 12} L${cx},${cy - R + 2} Z`} className="b2bar" />
      <rect x={bx} y={base - 10 * per} width="30" height={10 * per} rx="5" className="b2bar track" />
      <rect x={bx} y={base - shown * per} width="30" height={Math.max(0, shown * per)} rx="5" className="b2bar pink" />
      {ticks.map(k => k <= 6 || k === 10 ? (
        <g key={k}>
          <line x1={bx - 4} y1={base - k * per} x2={bx} y2={base - k * per} className="b2axis" />
          <text x={bx - 8} y={base - k * per + 4} textAnchor="end" className="b2t">{quiet ? k : k === 0 ? "1" : `1/${2 ** k >= 1000 ? "1,024" : 2 ** k}`}</text>
        </g>
      ) : null)}
      <text x={bx + 15} y="22" textAnchor="middle" className="b2t pink">bits</text>
      {marker && <g><line x1={bx - 6} y1={base - marker[0] * per} x2={bx + 36} y2={base - marker[0] * per} className="b2mark guess" />
        <text x={bx + 40} y={base - marker[0] * per + 4} className="b2t">you</text></g>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>{pick}<Slider label="Probability p" value={s} min={0} max={Math.log2(1000)} step={0.01} onChange={setS} format={() => fracText(p)}
        marks={[{ v: 1, label: "1/2" }, { v: 2, label: "1/4" }, { v: 3, label: "1/8" }, { v: 4, label: "1/16" }, { v: Math.log2(10), label: "1/10" }, { v: Math.log2(1000), label: "1/1,000" }]} /></>}
      readouts={<>
        <Read label="p" value={fracText(p)} tone="amber" />
        {!quiet && <Read label="Surprise, log₂(1/p)" value={`${fx(s)} bits`} tone="pink" big />}
        {!quiet && <Read label="Halvings from 1" value={fx(s, 1)} />}
      </>}
    />
  );
}

/* ------------------------------------------------------------------ bars ------------------------------------------------------------------ */

const PRESETS: Record<string, number[]> = { half: [0.5, 0.25, 0.25], even: [0.25, 0.25, 0.25, 0.25], tilt: [0.4, 0.3, 0.15, 0.1, 0.05] };
/** sets one bar and rescales the others so they still add to 1 */
function setBar(ps: number[], i: number, v: number, floor = 0): number[] {
  const x = Math.max(floor, Math.min(1 - floor * (ps.length - 1), v));
  const rest = ps.reduce((a, p, j) => (j === i ? a : a + p), 0), left = 1 - x;
  return ps.map((p, j) => (j === i ? x : rest > 1e-9 ? Math.max(floor, (p / rest) * left) : left / (ps.length - 1)));
}

function Bars({ props, marker, pick }: WithPick) {
  const start = str<string>(props, "dist", "") ? str<string>(props, "dist", "").split(",").map(Number) : PRESETS[str<string>(props, "preset", "tilt")] ?? PRESETS.tilt!;
  const total = start.reduce((a, b) => a + b, 0);
  const [ps, setPs] = useState(start.map(x => x / total));
  const quiet = flag(props, "quiet");
  const { ref, drag } = useSvgDrag();
  const n = ps.length, H = entropy(ps), level = useTween(H, 700);
  const slot = (W - 40) / 8, x0 = 20 + (8 - n) * slot / 2;
  const top = 120, pH = 100, low = 250, sH = 22; // probability row: 100 px for 1; surprise row: 22 px a bit
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} 262`} className="b2pic" role="img" aria-label={`${n} outcomes; entropy ${quiet ? "hidden" : `${fx(H, 3)} bits`}.`}>
      <line x1="16" y1={top} x2={W - 16} y2={top} className="b2axis" />
      <line x1="16" y1={low} x2={W - 16} y2={low} className="b2axis" />
      <text x="16" y="14" className="b2t sky">p</text>
      <text x="16" y={top + 18} className="b2t pink">bits, log₂(1/p)</text>
      {ps.map((p, i) => {
        const x = x0 + i * slot, s = surprise(p), sh = Math.min(5.2, s) * sH;
        return (
          <g key={i}>
            <rect x={x + 6} y={top - p * pH} width={slot - 12} height={Math.max(1, p * pH)} rx="4" className="b2bar sky" />
            <text x={x + slot / 2} y={top - p * pH - 5} textAnchor="middle" className="b2t">{fracText(p)}</text>
            <rect x={x + 6} y={low - sh} width={slot - 12} height={sh} rx="4" className="b2bar pink" opacity="0.8" />
            <rect x={x} y={top - pH - 8} width={slot} height={pH + 10} className="b2hit" {...drag((_x, y) => setPs(v => setBar(v, i, (top - y) / pH, 0.005)))} />
          </g>
        );
      })}
      {!quiet && <g><line x1="16" y1={low - level * sH} x2={W - 16} y2={low - level * sH} className="b2leg amber" />
        <text x={W - 16} y={low - level * sH - 6} textAnchor="end" className="b2t amber">H = {fx(level, 3)}</text></g>}
      {marker && <g><line x1="16" y1={low - marker[0] * sH} x2={W - 16} y2={low - marker[0] * sH} className="b2mark guess" />
        <text x="18" y={low - marker[0] * sH - 5} className="b2t">your guess</text></g>}
    </svg>
  );
  const resize = (m: number) => setPs(Array.from({ length: m }, () => 1 / m));
  return (
    <Scene svg={svg}
      controls={<>
        {pick}
        <Slider label="Outcomes" value={n} min={2} max={8} step={1} onChange={resize} format={v => String(v)} />
        <button type="button" className="ctl" onClick={() => setPs(ps.map((_, i) => (i === 0 ? 0.993 : 0.007 / (n - 1))))}>Pile on one</button>
        <button type="button" className="ctl" onClick={() => resize(n)}>Flatten</button>
      </>}
      readouts={quiet ? <Read label="Outcomes" value={n} /> : <>
        <Read label="Entropy H" value={`${fx(H, 3)} bits`} tone="amber" big />
        <Read label="Most, log₂ n" value={`${fx(Math.log2(n), 3)} bits`} />
      </>}
    />
  );
}

/* ------------------------------------------------------------------ coin ------------------------------------------------------------------ */

function Coin({ props, pick }: WithPick) {
  const [p, setP] = useState(num(props, "p", 0.7));
  const quiet = flag(props, "quiet"), runs = num(props, "runs", 0);
  const [seed, setSeed] = useState(7);
  const t = Math.max(0, useClock(true, 20));
  // flips arrive 8 a second, from a seeded stream that restarts when p changes; a reveal shows `runs` flips at once
  const flips = useMemo(() => { const r = seeded(seed + Math.round(p * 1000)); return Array.from({ length: 400 }, () => r() < p); }, [p, seed]);
  const k = Math.min(400, Math.max(runs, Math.floor(t * 8)));
  const heads = flips.slice(0, k).filter(Boolean).length;
  const tally = k ? (heads * surprise(p) + (k - heads) * surprise(1 - p)) / k : 0;
  const H = h2(p);
  const gx = (x: number) => 40 + x * 290, gy = (y: number) => 200 - y * 160;
  const curve = Array.from({ length: 101 }, (_, i) => [gx(i / 100), gy(h2(i / 100))] as [number, number]);
  const last = flips[Math.max(0, k - 1)];
  const svg = (
    <svg viewBox={`0 0 ${W} 262`} className="b2pic" role="img" aria-label={`A coin with heads chance ${fx(p)}. ${quiet ? "" : `Entropy ${fx(H, 3)} bits per flip.`}`}>
      <line x1={gx(0)} y1={gy(0)} x2={gx(1)} y2={gy(0)} className="b2axis" />
      <line x1={gx(0)} y1={gy(0)} x2={gx(0)} y2={gy(1)} className="b2axis" />
      <text x={gx(0) - 6} y={gy(1) + 4} textAnchor="end" className="b2t">1</text>
      <text x={gx(0) - 6} y={gy(0) + 4} textAnchor="end" className="b2t">0</text>
      <text x={gx(0)} y={gy(0) + 18} textAnchor="middle" className="b2t">0</text>
      <text x={gx(1)} y={gy(0) + 18} textAnchor="middle" className="b2t">1</text>
      <text x={gx(0.5)} y={gy(0) + 18} textAnchor="middle" className="b2t">p</text>
      {!quiet && <path d={path(curve)} className="b2curve sky" />}
      {!quiet && <circle cx={gx(p)} cy={gy(H)} r="7" className="b2dot amber" />}
      {!quiet && <text x={gx(p) + (p > 0.6 ? -10 : 10)} y={gy(H) - 10} textAnchor={p > 0.6 ? "end" : "start"} className="b2t amber">H = {fx(H, 3)}</text>}
      {!quiet && k > 0 && <line x1={gx(0)} y1={gy(tally)} x2={gx(1)} y2={gy(tally)} className="b2mark pink" />}
      <circle cx="330" cy="24" r="16" className={`b2dot ${last ? "amber" : "sky"}`} />
      <text x="330" y="29" textAnchor="middle" className="b2t">{last ? "H" : "T"}</text>
      {flips.slice(Math.max(0, k - 24), k).map((f, i) => <circle key={i} cx={42 + i * 11} cy="236" r="4" className={`b2dot ${f ? "amber" : "sky"}`} />)}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {pick}
        <Slider label="Chance of heads p" value={p} min={0} max={1} step={0.01} onChange={setP} format={x => fx(x)}
          marks={[{ v: 0.1, label: "0.1" }, { v: 0.25, label: "1/4" }, { v: 0.5, label: "1/2" }, { v: 0.9, label: "0.9" }]} />
        <button type="button" className="ctl" onClick={() => setSeed(x => x + 1)}>Flip again</button>
      </>}
      readouts={<>
        <Read label="Flips" value={k} />
        <Read label="Heads" value={heads} tone="amber" />
        {!quiet && <Read label="Bits per flip, from the flips" value={fx(tally, 3)} tone="pink" />}
        {!quiet && <Read label="H(p)" value={`${fx(H, 3)} bits`} tone="sky" big />}
      </>}
    />
  );
}

/* ------------------------------------------------------------------ cross-entropy ------------------------------------------------------------------ */

function Cross({ props, pick }: WithPick) {
  const P = str<string>(props, "p", "0.5,0.25,0.125,0.125").split(",").map(Number);
  const flat = flag(props, "flat");
  const [q, setQ] = useState(flat ? P.map(() => 1 / P.length) : str<string>(props, "q", "") ? str<string>(props, "q", "").split(",").map(Number) : [0.4, 0.3, 0.2, 0.1].slice(0, P.length));
  const quiet = flag(props, "quiet");
  const { ref, drag } = useSvgDrag();
  const H = entropy(P), X = crossEntropy(P, q), D = X - H;
  const n = P.length, slot = 220 / n, x0 = 16, base1 = 110, base2 = 236, hh = 90;
  const mx = 290, mBase = 236, perBit = 50; // meter: 50 px a bit
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} 262`} className="b2pic" role="img" aria-label={`Truth and model over ${n} outcomes. ${quiet ? "" : `Cross-entropy ${fx(X, 3)} bits, floor ${fx(H, 3)}.`}`}>
      <text x={x0} y="14" className="b2t sky">truth p</text>
      <text x={x0} y={base1 + 22} className="b2t pink">model q, drag</text>
      <line x1={x0} y1={base1} x2={x0 + 220} y2={base1} className="b2axis" />
      <line x1={x0} y1={base2} x2={x0 + 220} y2={base2} className="b2axis" />
      {P.map((p, i) => {
        const x = x0 + i * slot;
        return (
          <g key={i}>
            <rect x={x + 5} y={base1 - p * hh} width={slot - 10} height={p * hh} rx="4" className="b2bar sky" />
            <rect x={x + 5} y={base2 - q[i]! * hh} width={slot - 10} height={q[i]! * hh} rx="4" className="b2bar pink" />
            <text x={x + slot / 2} y={base2 - q[i]! * hh - 5} textAnchor="middle" className="b2t">{fracText(q[i]!)}</text>
            <rect x={x} y={base2 - hh - 6} width={slot} height={hh + 8} className="b2hit" {...drag((_x, y) => setQ(v => setBar(v, i, (base2 - y) / hh, 0.01)))} />
          </g>
        );
      })}
      <rect x={mx} y={mBase - 4 * perBit} width="40" height={4 * perBit} rx="6" className="b2bar track" />
      {!quiet && <>
        <rect x={mx} y={mBase - Math.min(4, X) * perBit} width="40" height={Math.min(4, X) * perBit} rx="6" className="b2bar pink" opacity="0.85" />
        <rect x={mx} y={mBase - Math.min(4, X) * perBit} width="40" height={Math.max(0, Math.min(4, X) - H) * perBit} className="b2bar amber" opacity="0.7" />
        <line x1={mx - 8} y1={mBase - H * perBit} x2={mx + 48} y2={mBase - H * perBit} className="b2leg sky" />
        <text x={mx + 20} y={mBase - Math.min(4, X) * perBit - 6} textAnchor="middle" className="b2t pink">{fx(X, 2)}</text>
      </>}
      {[0, 1, 2, 3, 4].map(b => <text key={b} x={mx - 6} y={mBase - b * perBit + 4} textAnchor="end" className="b2t">{b}</text>)}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>{pick}<button type="button" className="ctl" onClick={() => setQ(P.map(() => 1 / n))}>Model guesses evenly</button><button type="button" className="ctl" onClick={() => setQ([...P])}>Model matches truth</button></>}
      readouts={quiet ? <Read label="Truth" value={`(${P.map(fracText).join(", ")})`} /> : <>
        <Read label="Floor H(p)" value={`${fx(H, 3)} bits`} tone="sky" />
        <Read label="Cross-entropy H(p, q)" value={`${fx(X, 3)} bits`} tone="pink" big />
        <Read label="Gap, KL" value={`${fx(D, 3)} bits`} tone="amber" />
      </>}
    />
  );
}

/* ------------------------------------------------------------------ circles ------------------------------------------------------------------ */

/** the overlap area of two circles at distance d */
function lens(r1: number, r2: number, d: number) {
  if (d >= r1 + r2) return 0;
  if (d <= Math.abs(r1 - r2)) return Math.PI * Math.min(r1, r2) ** 2;
  const a = r1 * r1 * Math.acos((d * d + r1 * r1 - r2 * r2) / (2 * d * r1)), b = r2 * r2 * Math.acos((d * d + r2 * r2 - r1 * r1) / (2 * d * r2));
  return a + b - 0.5 * Math.sqrt((-d + r1 + r2) * (d + r1 - r2) * (d - r1 + r2) * (d + r1 + r2));
}
/** the distance that gives an overlap of `area` (bisection: the overlap shrinks as the circles part) */
function distanceFor(r1: number, r2: number, area: number) {
  let lo = Math.abs(r1 - r2), hi = r1 + r2;
  for (let i = 0; i < 50; i++) { const mid = (lo + hi) / 2; if (lens(r1, r2, mid) > area) lo = mid; else hi = mid; }
  return (lo + hi) / 2;
}

function Circles({ props, pick }: WithPick) {
  const cols = Math.round(num(props, "cols", 2));
  const start = str<string>(props, "cells", "3,1,1,3").split(",").map(Number);
  const [cells, setCells] = useState(start);
  const quiet = flag(props, "quiet");
  const { ref, drag } = useSvgDrag();
  const rows = Math.ceil(cells.length / cols), tot = cells.reduce((a, b) => a + b, 0) || 1;
  const P = cells.map(c => c / tot);
  const rowP = Array.from({ length: rows }, (_, r) => P.slice(r * cols, r * cols + cols).reduce((a, b) => a + b, 0));
  const colP = Array.from({ length: cols }, (_, c) => P.filter((_, k) => k % cols === c).reduce((a, b) => a + b, 0));
  const hx = entropy(rowP), hy = entropy(colP), hxy = entropy(P), I = Math.max(0, hx + hy - hxy);
  // the largest entropy the table allows fills a circle of radius 56 (46 for a 4-wide table, so two still fit side by side)
  const most = Math.max(1, Math.log2(Math.max(rows, cols))), K = (Math.PI * (most > 1 ? 46 : 56) ** 2) / most;
  const r1 = Math.sqrt((hx * K) / Math.PI), r2 = Math.sqrt((hy * K) / Math.PI);
  const d = useTween(r1 > 0.5 && r2 > 0.5 ? distanceFor(r1, r2, I * K) : r1 + r2 + 8, 500);
  const cy = 120, mid = 266, c1 = mid - d / 2 - (r1 - r2) / 2, c2 = c1 + d;
  // the table: each cell a square; drag up or down on it to change its weight
  const cs = Math.min(48, 150 / Math.max(rows, cols)), tx = 14, ty = 40;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} 250`} className="b2pic" role="img" aria-label={`A ${rows} by ${cols} joint table. H(X) ${fx(hx, 3)}, H(Y) ${fx(hy, 3)}${quiet ? "" : `, shared ${fx(I, 3)} bits`}.`}>
      <text x={tx} y="24" className="b2t">drag a cell</text>
      {P.map((p, k) => {
        const r = Math.floor(k / cols), c = k % cols, x = tx + c * cs, y = ty + r * cs;
        return (
          <g key={k}>
            <rect x={x + 1} y={y + 1} width={cs - 2} height={cs - 2} rx="4" className="b2bar track" />
            <rect x={x + 1 + (cs - 2) * (1 - Math.sqrt(p)) / 2} y={y + 1 + (cs - 2) * (1 - Math.sqrt(p)) / 2} width={(cs - 2) * Math.sqrt(p)} height={(cs - 2) * Math.sqrt(p)} rx="3" className="b2bar trav" />
            {cs >= 40 && <text x={x + cs / 2} y={y + cs + 1} textAnchor="middle" className="b2t">{fracText(p)}</text>}
            <rect x={x} y={y} width={cs} height={cs} className="b2hit" {...drag((_x, yy) => setCells(v => v.map((w, j) => (j === k ? Math.max(0, Math.min(8, 8 * (1 - (yy - y) / cs))) : w))))} />
          </g>
        );
      })}
      <text x={tx} y={ty + rows * cs + 22} className="b2t">Y across, X down</text>
      {!quiet && <>
        {r1 > 0.5 && <circle cx={c1} cy={cy} r={r1} className="b2bar sky" opacity="0.35" />}
        {r2 > 0.5 && <circle cx={c2} cy={cy} r={r2} className="b2bar pink" opacity="0.35" />}
        <text x={c1 - r1 * 0.5} y={cy + r1 + 20} textAnchor="middle" className="b2t sky">H(X)</text>
        <text x={c2 + r2 * 0.5} y={cy + r2 + 20} textAnchor="middle" className="b2t pink">H(Y)</text>
      </>}
      {!quiet && I > 0.005 && <text x={(c1 + r1 + c2 - r2) / 2} y={cy + 5} textAnchor="middle" className="b2t amber">{fx(I, 2)}</text>}
    </svg>
  );
  const preset = (c: number[]) => setCells(c);
  return (
    <Scene svg={svg}
      controls={<>{pick}{cols === 2 && rows === 2 && <>
        <button type="button" className="ctl" onClick={() => preset([4, 0, 0, 4])}>Diagonal</button>
        <button type="button" className="ctl" onClick={() => preset([2, 2, 2, 2])}>Independent</button>
        <button type="button" className="ctl" onClick={() => preset([4, 0, 2, 2])}>Half, 0, quarter, quarter</button>
      </>}</>}
      readouts={quiet ? <Read label="Table" value={`${rows} × ${cols}`} /> : <>
        <Read label="H(X)" value={fx(hx, 3)} tone="sky" />
        <Read label="H(Y)" value={fx(hy, 3)} tone="pink" />
        <Read label="H(X, Y)" value={fx(hxy, 3)} />
        {!quiet && <Read label="Shared, I(X; Y)" value={`${fx(I, 3)} bits`} tone="amber" big />}
      </>}
    />
  );
}
