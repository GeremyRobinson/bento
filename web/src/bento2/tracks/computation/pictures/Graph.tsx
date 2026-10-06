// The Graph explorer (computation.md, cs-10, cs-11, cs-12), in two modes:
// path: places and roads with travel times. Tap a road and drag its time; the shortest path from A to the target (tap a
//   place to make it the target) lights and reroutes. "Run Dijkstra" settles places one by one, nearest first.
// tour: cities on a map. Tap them in order for a round trip, drag them to move them; "Try them all" cycles through
//   every tour with a counter, and "Add a city" makes the counter jump. A log strip takes a guess at the count.
// Quiet (a Guess before Lock in, or Work it's map): no route is lit and no distances or counts show.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { Read, Scene, Slider, useClock, useSvgDrag } from "../../../ui/kit";
import { group } from "../../../steps";
import { dijkstra, greedyWalk, routeLength, seeded, type Graph } from "../maths";
import { graphFrom, posOf, routeText } from "../lessons2";
import { factorialOf } from "../common";

const W = 360;
const STILL = 1e9;
const CITY_NAMES = "ABCDEFGHIJ";
const CITY = "7|0-1-4,0-2-2,1-4-5,1-6-3,2-6-6,2-5-7,6-3-4,4-3-2,5-3-3,6-4-1,6-5-2";

export function GraphScene(props: SceneProps) {
  return str<string>(props.props, "mode", "path") === "tour" ? <Tour {...props} /> : <Paths {...props} />;
}

function Paths({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), greedyOn = flag(props, "greedy"), plain = flag(props, "plain");
  const start = useMemo(() => graphFrom(str<string>(props, "g", CITY)), [props]);
  const [ws, setWs] = useState(() => start.edges.map(e => e[2]));
  const [sel, setSel] = useState<number | null>(null);
  const [t, setT] = useState(Math.round(num(props, "t", 3)));
  const [run, setRun] = useState(0);
  const g: Graph = { names: start.names, edges: start.edges.map(([a, b], i) => [a, b, ws[i]!]) };
  const P = posOf(g.names.length);
  const dj = dijkstra(g);
  const route = (() => { const q = [t]; while (dj.prev[q[0]!]! >= 0) q.unshift(dj.prev[q[0]!]!); return q; })();
  const greedy = greedyOn ? greedyWalk(g, t) : null;
  const clock = Math.max(0, useClock(run > 0, STILL + run));
  const settled = run > 0 ? (clock >= STILL ? g.names.length : Math.min(g.names.length, Math.floor(clock / 0.7) + 1)) : quiet ? 0 : g.names.length;
  const done = dj.order.slice(0, settled);
  const onRoute = (a: number, b: number, r: number[] | null) => !!r && r.some((v, i) => i > 0 && ((r[i - 1] === a && v === b) || (r[i - 1] === b && v === a)));
  const lit = !quiet && settled === g.names.length;
  const svg = (
    <svg viewBox={`0 0 ${W} 230`} className="b2pic" role="img" aria-label={`A map of ${g.names.length} places.${lit ? ` The shortest route from A to ${g.names[t]} is ${routeText(g, route)}, ${dj.d[t]}.` : ""}`}>
      {g.edges.map(([a, b, w], i) => {
        const [x1, y1] = P[a]!, [x2, y2] = P[b]!, on = lit && onRoute(a, b, route), bad = !!greedy && onRoute(a, b, greedy) && !on;
        return (
          <g key={i} onClick={() => !quiet && setSel(i)} style={{ cursor: quiet ? undefined : "pointer" }}>
            <line x1={x1} y1={y1} x2={x2} y2={y2} className={`b2curve ${on ? "amber" : ""}`} strokeWidth={on ? 5 : 2} opacity={on ? 1 : 0.4} />
            {bad && <line x1={x1} y1={y1} x2={x2} y2={y2} className="b2curve pink" strokeWidth="2.5" strokeDasharray="6 5" />}
            {sel === i && <line x1={x1} y1={y1} x2={x2} y2={y2} className="b2mark sky" strokeWidth="9" opacity="0.5" />}
            {!plain && <g><rect x={(x1 + x2) / 2 - 11} y={(y1 + y2) / 2 - 10} width="22" height="20" rx="6" className="b2bar track" />
              <text x={(x1 + x2) / 2} y={(y1 + y2) / 2 + 5} textAnchor="middle" className={`b2t ${on ? "amber" : ""}`}>{w}</text></g>}
            <line x1={x1} y1={y1} x2={x2} y2={y2} stroke="transparent" strokeWidth="18" />
          </g>
        );
      })}
      {g.names.map((nm, i) => {
        const [x, y] = P[i]!, isDone = done.includes(i);
        return (
          <g key={nm} onClick={() => !quiet && i > 0 && setT(i)} style={{ cursor: quiet || !i ? undefined : "pointer" }}>
            <circle cx={x} cy={y} r="15" className={`b2bar ${isDone && !quiet ? "sky" : "track"}`} />
            <circle cx={x} cy={y} r="15" className="b2curve" strokeWidth="1.5" fill="none" opacity="0.6" />
            {(i === t || i === 0) && <circle cx={x} cy={y} r="19" className={`b2ring ${i === t ? "amber" : "sky"}`} />}
            <text x={x} y={y + 5} textAnchor="middle" className="b2t">{nm}</text>
            {isDone && !quiet && <text x={x} y={y + (y > 150 ? 34 : -22)} textAnchor="middle" className="b2t sky">{dj.d[i]}</text>}
          </g>
        );
      })}
      {greedy && <text x="8" y="16" className="b2t pink">cheapest road first: {routeText(g, greedy)} = {routeLength(g, greedy)}</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <>
        {sel != null && <Slider label={`Road ${g.names[g.edges[sel]![0]]}–${g.names[g.edges[sel]![1]]}`} value={ws[sel]!} min={1} max={12} step={1} onChange={v => setWs(x => x.map((w, i) => (i === sel ? v : w)))} />}
        <button type="button" className="ctl go" onClick={() => setRun(r => r + 1)}>Run Dijkstra</button>
      </>}
      readouts={quiet ? <Read label="From A to" value={g.names[t]} /> : <>
        <Read label={`Shortest, A to ${g.names[t]}`} value={lit ? dj.d[t] : "…"} tone="amber" big />
        <Read label="Route" value={lit ? routeText(g, route) : "…"} tone="amber" />
        <Read label="Settled" value={`${settled} of ${g.names.length}: ${done.map(i => g.names[i]).join(", ")}`} tone="sky" />
      </>}
    />
  );
}

/* ------------------------------------------------------------------ tour ------------------------------------------------------------------ */

function cities(n: number, seed = 3): [number, number][] {
  const r = seeded(seed * 97 + n), out: [number, number][] = [];
  while (out.length < n) {
    const p: [number, number] = [30 + r() * 300, 30 + r() * 150];
    if (out.every(q => Math.hypot(q[0] - p[0], q[1] - p[1]) > 46)) out.push(p);
  }
  return out;
}
const dist = (a: [number, number], b: [number, number]) => Math.round(Math.hypot(a[0] - b[0], a[1] - b[1]) / 10);
/** every tour from city 0, each loop once (the second city's index below the last's) */
function allTours(n: number): number[][] {
  const out: number[][] = [];
  const rest = Array.from({ length: n - 1 }, (_, i) => i + 1);
  const perm = (p: number[], left: number[]) => {
    if (!left.length) { if (p[1]! < p[p.length - 1]!) out.push(p); return; }
    left.forEach((c, i) => perm([...p, c], [...left.slice(0, i), ...left.slice(i + 1)]));
  };
  perm([0], rest);
  return out;
}

function Tour({ props, marker }: SceneProps) {
  const quiet = flag(props, "quiet"), count = flag(props, "count");
  const [n, setN] = useState(Math.round(num(props, "n", 5)));
  const [pts, setPts] = useState(() => cities(Math.round(num(props, "n", 5))));
  const [route, setRoute] = useState<number[]>([0]);
  const [run, setRun] = useState(0);
  const { ref, drag } = useSvgDrag();
  const tours = useMemo(() => (n <= 8 ? allTours(n) : []), [n]);
  const len = (r: number[]) => r.reduce((s, c, i) => s + dist(pts[c]!, pts[r[(i + 1) % r.length]!]!), 0);
  const clock = Math.max(0, useClock(run > 0, STILL + run));
  const k = run > 0 ? (clock >= STILL ? tours.length : Math.min(tours.length, Math.floor(clock * Math.max(4, tours.length / 8)) + 1)) : 0;
  const best = useMemo(() => tours.slice(0, k).reduce<number[] | null>((b, r) => (!b || len(r) < len(b) ? r : b), null), [tours, k, pts]); // eslint-disable-line react-hooks/exhaustive-deps
  const trying = k > 0 && k < tours.length ? tours[k - 1]! : null;
  const total = factorialOf(n - 1) / 2;
  const closed = route.length === n;
  const addCity = () => { const m = Math.min(10, n + 1); setN(m); setPts(cities(m)); setRoute([0]); setRun(0); };
  const tapCity = (i: number) => { if (quiet) return; setRun(0); setRoute(r => (r.includes(i) ? (i === 0 ? [0] : r.slice(0, r.indexOf(i))) : [...r, i])); };
  const line = (r: number[], close: boolean) => [...r, ...(close ? [r[0]!] : [])].map((c, i) => `${i ? "L" : "M"}${pts[c]![0].toFixed(1)},${pts[c]![1].toFixed(1)}`).join(" ");
  const strip = !!marker || count;
  const lx = (v: number) => 20 + ((v - 1) / 6) * 320;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${strip ? 280 : 210}`} className="b2pic" role="img" aria-label={`${n} cities.${quiet ? "" : ` ${group(total)} different round trips.`}`}>
      {best && <path d={line(best, true)} className="b2curve amber" strokeWidth="3" fill="none" />}
      {trying && <path d={line(trying, true)} className="b2curve sky" strokeDasharray="5 4" fill="none" opacity="0.8" />}
      {!run && route.length > 1 && <path d={line(route, closed)} className="b2curve sky" strokeWidth="3" fill="none" />}
      {pts.map((p, i) => (
        <g key={i}>
          <circle cx={p[0]} cy={p[1]} r="13" className={`b2bar ${route.includes(i) && !run ? "sky" : "track"}`} />
          <circle cx={p[0]} cy={p[1]} r="13" className="b2curve" strokeWidth="1.5" fill="none" opacity="0.6" />
          <text x={p[0]} y={p[1] + 5} textAnchor="middle" className="b2t">{CITY_NAMES[i]}</text>
          {!quiet && <circle cx={p[0]} cy={p[1]} r="17" className="b2hit" onClick={() => tapCity(i)} {...drag((x, y) => setPts(q => q.map((c, j) => (j === i ? [Math.max(16, Math.min(W - 16, x)), Math.max(16, Math.min(194, y))] : c))))} />}
        </g>
      ))}
      {strip && <g>
        <line x1="20" y1="236" x2="340" y2="236" className="b2axis" />
        {[1, 2, 3, 4, 5, 6, 7].map(e => <g key={e}><line x1={lx(e)} y1="231" x2={lx(e)} y2="241" className="b2axis" /><text x={lx(e)} y="258" textAnchor="middle" className="b2t">10{"⁰¹²³⁴⁵⁶⁷"[e]}</text></g>)}
        <text x="20" y="222" className="b2t">round trips, log scale</text>
        {marker && <g><line x1={lx(marker[0])} y1="226" x2={lx(marker[0])} y2="246" className="b2mark guess" /><text x={lx(marker[0])} y="276" textAnchor="middle" className="b2t">your guess</text></g>}
        {count && !quiet && <g><circle cx={lx(Math.log10(total))} cy="236" r="6" className="b2bar amber" /><text x={lx(Math.log10(total))} y="222" textAnchor="middle" className="b2t amber">{group(total)}</text></g>}
      </g>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <>
        {n <= 8 && <button type="button" className="ctl go" onClick={() => setRun(r => r + 1)}>Try them all</button>}
        {n < 10 && <button type="button" className="ctl" onClick={addCity}>Add a city</button>}
        <Slider label="Cities" value={n} min={4} max={10} step={1} onChange={m => { setN(m); setPts(cities(m)); setRoute([0]); setRun(0); }} />
      </>}
      readouts={quiet ? <Read label="Cities" value={n} /> : <>
        <Read label="Round trips, (n − 1)!/2" value={group(total)} tone="amber" big />
        {run > 0 && n <= 8 && <Read label="Tried" value={`${group(k)} of ${group(tours.length)}`} tone="sky" />}
        {best && <Read label="Best so far" value={len(best)} tone="amber" />}
        {!run && <Read label="Your tour" value={closed ? `${route.map(i => CITY_NAMES[i]).join("–")}–A = ${len(route)}` : `tap the cities in order (${route.length} of ${n})`} tone="sky" />}
      </>}
    />
  );
}
