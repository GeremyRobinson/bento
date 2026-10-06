// The Algorithm stage (computation.md, the track's main tool), in three modes:
// search: two searchers race on the same sorted cards, linear from the left and binary from the middle, one step each
//   per tick; "×10 input" reruns on ten times the cards and logs both worst cases (cs-06).
// sort: the same shuffled bars sorted twice at the same comparison rate, bubble sort and merge sort, with counters (cs-07).
// subset: weights and a target; tap weights to try an answer (checked at once), or search all 2ⁿ subsets with a
//   counter (cs-12). In a project it makes a puzzle with a hidden answer and saves it.
// Quiet (a Guess before Lock in): nothing runs and no counter shows.
import { useMemo, useState, type ReactNode } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { Read, SaveRow, Scene, Slider, Toggle, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { group } from "../../../steps";
import { bitLength, seeded } from "../maths";

const W = 360;
const STILL = 1e9;

export function StageScene(props: SceneProps) {
  const [mode, setMode] = useState(str<string>(props.props, "mode", "search"));
  const pick = props.place === "tool" && (
    <Toggle label="Stage" value={mode} onChange={setMode} options={[{ v: "search", label: "Search" }, { v: "sort", label: "Sort" }, { v: "subset", label: "Subsets" }]} />
  );
  if (mode === "sort") return <Sort {...props} pick={pick} />;
  if (mode === "subset") return <Subset {...props} pick={pick} />;
  return <Search {...props} pick={pick} />;
}

/* ------------------------------------------------------------------ search ------------------------------------------------------------------ */

/** the card positions binary search opens looking for position t among 0..n − 1 (middle rounded down) */
function opens(n: number, t: number) {
  const out: { mid: number; lo: number; hi: number }[] = [];
  let lo = 0, hi = n - 1;
  while (lo <= hi) { const mid = Math.floor((lo + hi) / 2); out.push({ mid, lo, hi }); if (mid === t) break; if (mid < t) lo = mid + 1; else hi = mid - 1; }
  return out;
}
const LOG_TICKS = [1, 10, 100, 1000, 10000, 100000, 1000000];

function Search({ props, marker, pick }: SceneProps & { pick: ReactNode }) {
  const quiet = flag(props, "quiet"), worst = flag(props, "worst");
  const [n, setN] = useState(Math.round(num(props, "n", 15)));
  const [t, setT] = useState(() => n - 1);
  const [log, setLog] = useState<number[]>([]);
  const [run, setRun] = useState(0);
  const target = Math.min(t, n - 1);
  const bin = useMemo(() => opens(n, target), [n, target]);
  const clock = Math.max(0, useClock(!quiet, STILL + run));
  const k = quiet ? 0 : clock >= STILL ? Infinity : Math.floor(clock / 0.4) + 1;
  const linSteps = Math.min(k, target + 1), binSteps = Math.min(k, bin.length);
  const cards = n <= 31, x0 = 14, x1 = W - 14, cw = (x1 - x0) / n, xOf = (i: number) => x0 + (i / n) * (x1 - x0);
  const val = (i: number) => 3 * i + 2;
  const times10 = () => { setLog(l => [...l, n]); const m = Math.min(10000000, n * 10); setN(m); setT(m - 1); setRun(r => r + 1); };
  const strip = marker || worst;
  const lx = (v: number) => 20 + (Math.log10(Math.max(1, v)) / 6) * 320;
  const lane = (y: number, label: string, tone: string, steps: number, body: ReactNode) => (
    <g>
      <text x={x0} y={y - 6} className={`b2t ${tone}`}>{label}{quiet ? "" : `: ${group(steps)} opened`}</text>
      {body}
    </g>
  );
  const linBody = cards
    ? Array.from({ length: n }, (_, i) => (
      <g key={i} onClick={() => { setT(i); setRun(r => r + 1); }} style={{ cursor: "pointer" }}>
        <rect x={xOf(i) + 0.5} y="26" width={cw - 1} height="30" rx="3" className={`b2bar ${i < linSteps ? (i === target ? "amber" : "sky") : "track"}`} opacity={i < linSteps && i !== target ? 0.5 : 1} />
        {cw > 13 && <text x={xOf(i) + cw / 2} y="46" textAnchor="middle" className="b2t">{i < linSteps ? val(i) : ""}</text>}
      </g>))
    : <><rect x={x0} y="26" width={x1 - x0} height="30" rx="4" className="b2bar track" />
      <rect x={x0} y="26" width={Math.max(2, (linSteps / n) * (x1 - x0))} height="30" rx="4" className="b2bar sky" /></>;
  const open = bin.slice(0, binSteps), now = open[open.length - 1];
  const binBody = cards
    ? Array.from({ length: n }, (_, i) => {
      const out = now && (i < now.lo || i > now.hi), opened = open.some(o => o.mid === i);
      return (
        <g key={i}>
          <rect x={xOf(i) + 0.5} y="96" width={cw - 1} height="30" rx="3" className={`b2bar ${opened ? (i === target ? "amber" : "sky") : "track"}`} opacity={out ? 0.25 : 1} />
          {cw > 13 && <text x={xOf(i) + cw / 2} y="116" textAnchor="middle" className="b2t">{opened ? val(i) : ""}</text>}
        </g>
      );
    })
    : <><rect x={x0} y="96" width={x1 - x0} height="30" rx="4" className="b2bar track" opacity="0.4" />
      {now && <rect x={xOf(now.lo)} y="96" width={Math.max(2, xOf(now.hi + 1) - xOf(now.lo))} height="30" rx="2" className="b2bar track" />}
      {open.map((o, j) => <line key={j} x1={xOf(o.mid)} y1="92" x2={xOf(o.mid)} y2="130" className={`b2curve ${o.mid === target ? "amber" : "sky"}`} strokeWidth="1.5" />)}</>;
  const svg = (
    <svg viewBox={`0 0 ${W} ${strip ? 250 : 170}`} className="b2pic" role="img" aria-label={`${group(n)} sorted cards.${quiet ? "" : ` Linear search has opened ${linSteps}, binary search ${binSteps}.`}`}>
      {lane(20, "card by card", "sky", linSteps, linBody)}
      {lane(90, "halving", "amber", binSteps, binBody)}
      {!quiet && <text x={x0} y="152" className="b2t">target: {cards ? val(target) : `card ${group(target + 1)}`}{cards ? " (tap a card to change it)" : ""}</text>}
      {strip && <g>
        <line x1="20" y1="200" x2="340" y2="200" className="b2axis" />
        {LOG_TICKS.map(v => <g key={v}><line x1={lx(v)} y1="195" x2={lx(v)} y2="205" className="b2axis" /><text x={lx(v)} y="222" textAnchor="middle" className="b2t">{v >= 1e6 ? "1M" : v >= 1000 ? `${v / 1000}k` : v}</text></g>)}
        <text x="20" y="182" className="b2t">cards opened, log scale</text>
        {marker && <g><line x1={20 + (marker[0] / 6) * 320} y1="186" x2={20 + (marker[0] / 6) * 320} y2="212" className="b2mark guess" /><text x={20 + (marker[0] / 6) * 320} y="244" textAnchor="middle" className="b2t">your guess</text></g>}
        {!quiet && binSteps === bin.length && <g><circle cx={lx(bin.length)} cy="200" r="6" className="b2bar amber" /><text x={lx(bin.length) + 8} y="190" className="b2t amber">{bin.length}</text></g>}
      </g>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <>
        {pick}
        <Slider label="Cards" value={Math.log10(n)} min={Math.log10(7)} max={6} step={0.01} onChange={v => { const m = Math.max(3, Math.round(10 ** v)); setN(m); setT(m - 1); setRun(r => r + 1); }} format={() => group(n)}
          marks={[{ v: Math.log10(15), label: "15" }, { v: 2, label: "100" }, { v: 3, label: "1,000" }, { v: 6, label: "1,000,000" }]} />
        <button type="button" className="ctl" onClick={times10}>×10 input</button>
        <button type="button" className="ctl" onClick={() => setRun(r => r + 1)}>Race again</button>
      </>}
      readouts={quiet ? <Read label="Cards" value={group(n)} /> : <>
        <Read label="Linear, worst" value={group(n)} tone="sky" />
        <Read label="Binary, worst" value={bitLength(n)} tone="amber" big />
        {log.slice(-3).map(m => <Read key={m} label={`at ${group(m)}`} value={`${group(m)} vs ${bitLength(m)}`} />)}
      </>}
    />
  );
}

/* ------------------------------------------------------------------ sort ------------------------------------------------------------------ */

function sortRuns(n: number) {
  const r = seeded(n * 7 + 1), a = Array.from({ length: n }, (_, i) => i + 1);
  for (let i = n - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [a[i], a[j]] = [a[j]!, a[i]!]; }
  // bubble sort, the full version: pass p makes n − 1 − p comparisons; keep up to 128 snapshots
  const every = Math.max(1, Math.ceil((n - 1) / 128)), bubble: { at: number; xs: number[] }[] = [{ at: 0, xs: [...a] }];
  const b = [...a];
  let comps = 0;
  for (let p = 0; p < n - 1; p++) {
    for (let i = 0; i < n - 1 - p; i++) { comps++; if (b[i]! > b[i + 1]!) [b[i], b[i + 1]] = [b[i + 1]!, b[i]!]; }
    if ((p + 1) % every === 0 || p === n - 2) bubble.push({ at: comps, xs: [...b] });
  }
  // merge sort bottom up (for n = 2ᵏ it's the same splits as top down), a snapshot per level
  const merge: { at: number; xs: number[] }[] = [{ at: 0, xs: [...a] }];
  let m = [...a], mc = 0;
  for (let size = 1; size < n; size *= 2) {
    const next: number[] = [];
    for (let s = 0; s < n; s += 2 * size) {
      const L = m.slice(s, s + size), R = m.slice(s + size, s + 2 * size);
      let i = 0, j = 0;
      while (i < L.length && j < R.length) { mc++; next.push(L[i]! <= R[j]! ? L[i++]! : R[j++]!); }
      next.push(...L.slice(i), ...R.slice(j));
    }
    m = next;
    merge.push({ at: mc, xs: [...m] });
  }
  return { bubble, merge, bubbleTotal: comps, mergeTotal: mc };
}
const snapAt = (s: { at: number; xs: number[] }[], c: number) => { let k = 0; while (k + 1 < s.length && s[k + 1]!.at <= c) k++; return s[k]!; };

function Sort({ props, pick }: SceneProps & { pick: ReactNode }) {
  const quiet = flag(props, "quiet");
  const [lg, setLg] = useState(Math.round(Math.log2(num(props, "n", 64))));
  const n = 2 ** lg;
  const [run, setRun] = useState(0);
  const R = useMemo(() => sortRuns(n), [n]);
  const t = Math.max(0, useClock(!quiet, STILL + run));
  // the same comparison rate for both: bubble sort's whole run takes about 14 seconds
  const c = quiet ? 0 : t >= STILL ? Infinity : (R.bubbleTotal / 14) * t;
  const bc = Math.min(R.bubbleTotal, Math.floor(c)), mc = Math.min(R.mergeTotal, Math.floor(c));
  const bars = (xs: number[], y: number, tone: string) => {
    const w = 332 / n;
    return <path d={xs.map((v, i) => `M${(14 + (i + 0.5) * w).toFixed(2)},${y}v${(-(v / n) * 70).toFixed(1)}`).join("")} className={`b2curve ${tone}`} strokeWidth={Math.max(0.6, w * 0.8)} />;
  };
  const svg = (
    <svg viewBox={`0 0 ${W} 230`} className="b2pic" role="img" aria-label={`${n} bars sorted by bubble sort and merge sort.${quiet ? "" : ` Comparisons so far: ${bc} and ${mc}.`}`}>
      <text x="14" y="16" className="b2t sky">bubble sort{quiet ? "" : `: ${group(bc)} comparisons${bc === R.bubbleTotal ? ", done" : ""}`}</text>
      {bars(snapAt(R.bubble, bc).xs, 98, "sky")}
      <text x="14" y="128" className="b2t amber">merge sort{quiet ? "" : `: ${group(mc)} comparisons${mc === R.mergeTotal ? ", done" : ""}`}</text>
      {bars(snapAt(R.merge, mc).xs, 210, "amber")}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <>
        {pick}
        <Slider label="Bars" value={lg} min={3} max={10} step={1} onChange={v => { setLg(v); setRun(r => r + 1); }} format={() => group(n)}
          marks={[{ v: 3, label: "8" }, { v: 6, label: "64" }, { v: 10, label: "1,024" }]} />
        <button type="button" className="ctl" onClick={() => setRun(r => r + 1)}>Race again</button>
      </>}
      readouts={quiet ? <Read label="Bars" value={group(n)} /> : <>
        <Read label="Bubble, n(n − 1)/2" value={group(R.bubbleTotal)} tone="sky" />
        <Read label="Merge, this shuffle" value={`${group(R.mergeTotal)} (worst ${group(n * lg - n + 1)})`} tone="amber" />
        <Read label="Bubble ÷ merge" value={`about ${Math.round(R.bubbleTotal / R.mergeTotal)}×`} big />
      </>}
    />
  );
}

/* ------------------------------------------------------------------ subset ------------------------------------------------------------------ */

const sumOf = (ws: number[], m: number) => ws.reduce((s, w, i) => s + ((m >> i) & 1 ? w : 0), 0);
function newPuzzle(seed: number, n: number) {
  const r = seeded(seed * 131 + n), pool = Array.from({ length: 30 }, (_, i) => i + 1);
  for (let i = pool.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [pool[i], pool[j]] = [pool[j]!, pool[i]!]; }
  const ws = pool.slice(0, n), size = 2 + Math.floor(r() * Math.min(3, n - 2)), answer = ws.slice(0, size);
  const shown = [...ws];
  for (let i = shown.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [shown[i], shown[j]] = [shown[j]!, shown[i]!]; }
  return { ws: shown, target: answer.reduce((s, x) => s + x, 0), answer };
}

function Subset({ props, place, pick }: SceneProps & { pick: ReactNode }) {
  const quiet = flag(props, "quiet"), puzzle = flag(props, "puzzle");
  const [seed, setSeed] = useState(1);
  const [size, setSize] = useState(6);
  const made = useMemo(() => newPuzzle(seed, size), [seed, size]);
  const [extra, setExtra] = useState<number[]>([]);
  const ws = puzzle ? made.ws : [...str<string>(props, "ws", "3,7,12,5,9").split(",").map(Number), ...extra];
  const target = puzzle ? made.target : num(props, "target", 21);
  const [sel, setSel] = useState(0);
  const [run, setRun] = useState(flag(props, "search") ? 1 : 0);
  const total = 2 ** ws.length;
  const t = Math.max(0, useClock(run > 0 && !quiet, STILL + run));
  const tried = run > 0 && !quiet ? (t >= STILL ? total : Math.min(total, Math.floor(t * Math.max(5, total / 6)) + 1)) : 0;
  const firstHit = useMemo(() => { for (let m = 1; m < total; m++) if (sumOf(ws, m) === target) return m; return -1; }, [ws, target, total]);
  const hits = useMemo(() => { let h = 0; for (let m = 1; m < Math.min(tried, total); m++) if (sumOf(ws, m) === target) h++; return h; }, [ws, target, tried, total]);
  const now = tried >= total ? (firstHit > 0 ? firstHit : 0) : Math.max(0, tried - 1);
  const show = tried > 0 ? now : sel, s = sumOf(ws, show), hit = s === target;
  const { b2, save, note } = useB2();
  const maxW = Math.max(...ws, 1), gap = Math.min(52, (W - 24) / ws.length);
  const bx = (v: number) => 12 + (v / Math.max(target * 1.6, s, 1)) * (W - 24);
  const svg = (
    <svg viewBox={`0 0 ${W} 220`} className="b2pic" role="img" aria-label={`Weights ${ws.join(", ")} and target ${target}.${quiet ? "" : ` Showing a subset that sums to ${s}.`}`}>
      {ws.map((w, i) => {
        const on = ((show >> i) & 1) === 1, h = 18 + (w / maxW) * 70, x = 12 + i * gap;
        return (
          <g key={i} onClick={() => { if (tried === 0 || tried >= total) { setRun(0); setSel(m => m ^ (1 << i)); } }} style={{ cursor: "pointer" }}>
            <rect x={x + 3} y={110 - h} width={gap - 6} height={h} rx="5" className={`b2bar ${on ? (tried > 0 && tried < total ? "sky" : "amber") : "track"}`} />
            <rect x={x + 3} y={110 - h} width={gap - 6} height={h} rx="5" className="b2curve" strokeWidth="1.5" fill="none" opacity="0.5" />
            <text x={x + gap / 2} y={128} textAnchor="middle" className="b2t">{w}</text>
            <rect x={x} y="10" width={gap} height="124" className="b2hit" style={{ cursor: "pointer" }} />
          </g>
        );
      })}
      <rect x="12" y="150" width={W - 24} height="18" rx="4" className="b2bar track" />
      <rect x="12" y="150" width={Math.max(0, bx(s) - 12)} height="18" rx="4" className={`b2bar ${hit && s > 0 ? "mint" : "amber"}`} />
      <line x1={bx(target)} y1="142" x2={bx(target)} y2="176" className="b2axis" />
      <text x={bx(target)} y="192" textAnchor="middle" className="b2t">target {target}</text>
      <text x="12" y="212" className={`b2t ${hit && s > 0 ? "mint" : ""}`}>{s > 0 ? `${ws.filter((_, i) => (show >> i) & 1).join(" + ")} = ${s}${hit ? ", hits it" : ""}` : "tap weights to try an answer"}</text>
    </svg>
  );
  const saved = JSON.stringify(b2.shelf.puzzle?.value) === JSON.stringify([...ws, target]);
  return (
    <Scene svg={svg}
      controls={<>
        {pick}
        {puzzle && <Slider label="Weights" value={size} min={4} max={12} step={1} onChange={v => { setSize(v); setSel(0); setRun(0); }} />}
        {puzzle && <button type="button" className="ctl" onClick={() => { setSeed(x => x + 1); setSel(0); setRun(0); }}>New puzzle</button>}
        {!quiet && <button type="button" className="ctl go" onClick={() => setRun(r => r + 1)}>Search all</button>}
        {!quiet && !puzzle && ws.length < 12 && <button type="button" className="ctl" onClick={() => { setExtra(e => [...e, 2 + ((ws.length * 7) % 19)]); setRun(0); }}>Add a weight</button>}
        {sel > 0 && tried === 0 && <button type="button" className="ctl" onClick={() => setSel(0)}>Clear</button>}
      </>}
      readouts={<>
        <Read label="Your pick" value={sel ? `${sumOf(ws, sel)}${sumOf(ws, sel) === target ? ", it works" : ""}` : "–"} tone={sumOf(ws, sel) === target && sel ? "mint" : undefined} />
        {!quiet && <Read label="Subsets tried" value={`${group(tried)} of ${group(total)}`} tone="sky" big />}
        {!quiet && tried > 0 && <Read label="Hits so far" value={hits} />}
      </>}
      foot={puzzle && place === "project" && <SaveRow what={<>Keep <b>puzzle</b>: {ws.length} weights, target {target}</>} saved={saved} onSave={() => {
        save("puzzle", [...ws, target], "cs-puzzle", { labels: [...ws.map((_, i) => `weight ${i + 1}`), "target"], note: "a subset-sum puzzle: quick to check, slow to find" });
        note({ id: "cs-puzzle", track: "cs", title: "A puzzle that's easy to check", project: "cs-puzzle", data: { n: ws.length, target, subsets: total },
          lines: [`Weights ${ws.join(", ")}. Target ${target}.`, `A blind search tries up to 2${ws.length > 9 ? ws.length : "⁰¹²³⁴⁵⁶⁷⁸⁹"[ws.length]} = ${group(total)} subsets.`, `Hidden answer (fold this line over): ${made.answer.join(" + ")}.`] });
      }} />}
    />
  );
}
