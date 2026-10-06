// Two-state flow (linear-algebra.md, "New pictures"): two stations with arrows labelled by the chances of moving, and
// dots that move step by step, beside the eigenvector reading. It is the project "Long-run forecaster" (bike share
// or weather), which keeps the steady shares as `steady`.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, Toggle, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { createRng } from "../../../../curriculum/generators/rng";
import { MatRead, ink, tint } from "./plane";

const DOTS = 40, STEP = 0.9;
const SETS = {
  bikes: { a: "Station A", b: "Station B", p: 3, q: 2 },
  weather: { a: "Sunny", b: "Rainy", p: 2, q: 4 },
} as const;

export function FlowScene({ props, place }: SceneProps) {
  const project = flag(props, "project") || place === "project";
  const [set, setSet] = useState<keyof typeof SETS>(str(props, "set", "bikes") as keyof typeof SETS);
  // chances in tenths, kept whole so 1 − p never prints float dust
  const [P, setP] = useState(num(props, "p", SETS[set].p));
  const [Q, setQ] = useState(num(props, "q", SETS[set].q));
  const [base, setBase] = useState(0);
  const [running, setRunning] = useState(false);
  const t = useClock(running, 0);
  const { b2, save, note } = useB2();
  const names = SETS[set];
  // every dot's station after each step, from a seeded coin, so a run can be replayed
  const path = useMemo(() => {
    const rng = createRng(11 + P * 13 + Q * 7);
    const out: number[][] = [Array.from({ length: DOTS }, (_, i) => (i < DOTS * 0.9 ? 0 : 1))];
    for (let k = 0; k < 400; k++) out.push(out[k]!.map(s => (s === 0 ? (rng.next() < P / 10 ? 1 : 0) : rng.next() < Q / 10 ? 0 : 1)));
    return out;
  }, [P, Q]);
  const auto = running ? Math.floor(t / STEP) : 0;
  const k = Math.min(400, base + auto);
  const f = running ? Math.min(1, (t % STEP) / 0.55) : 1;
  const now = path[k]!, before = path[Math.max(0, k - 1)]!;
  const atA = now.filter(s => s === 0).length;
  const steadyA = Q / (P + Q);
  const lam2 = (10 - P - Q) / 10;

  const W = 360, H = 250, ax = 92, bx = 268, cy = 128, R = 58;
  const spot = (st: number, i: number): [number, number] => {
    const g = Math.floor(i / 8), h = i % 8, cx = st === 0 ? ax : bx;
    return [cx - 35 + h * 10, cy - 28 + g * 12];
  };
  const dots = now.map((st, i) => {
    const [x1, y1] = spot(before[i]!, i), [x2, y2] = spot(st, i);
    const ff = k === 0 ? 1 : f;
    // a dot that changes station arcs over the top or under the bottom
    const lift = before[i] !== st ? Math.sin(Math.PI * ff) * (st === 1 ? -70 : 70) : 0;
    return <circle key={i} cx={x1 + (x2 - x1) * ff} cy={y1 + (y2 - y1) * ff + lift} r="4" className={`b2dot ${st === 0 ? "sky" : "pink"}`} />;
  });
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`${names.a} and ${names.b}: ${atA} of ${DOTS} dots at ${names.a} after ${k} steps. In the long run ${fx(steadyA * 100, 1)}% sit there.`}>
      <circle cx={ax} cy={cy} r={R} style={{ ...tint("sky", 0.12), ...ink("sky", 1.5) }} />
      <circle cx={bx} cy={cy} r={R} style={{ ...tint("pink", 0.12), ...ink("pink", 1.5) }} />
      <path d={`M${ax + 20},${cy - R + 2} Q${(ax + bx) / 2},${cy - R - 52} ${bx - 20},${cy - R + 2}`} style={ink("sky", 2)} />
      <path d={`M${bx - 20},${cy + R - 2} Q${(ax + bx) / 2},${cy + R + 52} ${ax + 20},${cy + R - 2}`} style={ink("pink", 2)} />
      <text x={(ax + bx) / 2} y={cy - R - 30} textAnchor="middle" className="b2t sky">p = {fx(P / 10, 1)}</text>
      <text x={(ax + bx) / 2} y={cy + R + 42} textAnchor="middle" className="b2t pink">q = {fx(Q / 10, 1)}</text>
      <text x={ax} y={cy + 4 + 40} textAnchor="middle" className="b2t sky">{names.a}</text>
      <text x={bx} y={cy + 4 + 40} textAnchor="middle" className="b2t pink">{names.b}</text>
      {dots}
      <text x={W - 6} y={18} textAnchor="end" className="b2t">step {k}</text>
    </svg>
  );
  const steady = [steadyA, 1 - steadyA];
  const saved = JSON.stringify(b2.shelf.steady?.value) === JSON.stringify(steady);
  return (
    <Scene svg={svg}
      controls={<>
        <Toggle label="Example" value={set} onChange={s => { setSet(s); setP(SETS[s].p); setQ(SETS[s].q); setBase(0); setRunning(false); }} options={[{ v: "bikes", label: "Bike share" }, { v: "weather", label: "Weather" }]} />
        <Slider label={`p, ${names.a} to ${names.b}`} value={P} min={1} max={9} step={1} onChange={v => { setP(v); setBase(0); setRunning(false); }} format={v => fx(v / 10, 1)} />
        <Slider label={`q, ${names.b} to ${names.a}`} value={Q} min={1} max={9} step={1} onChange={v => { setQ(v); setBase(0); setRunning(false); }} format={v => fx(v / 10, 1)} />
        <button type="button" className="ctl" onClick={() => { setBase(k + 1); setRunning(false); }}>One step</button>
        <button type="button" className="ctl go" onClick={() => { setBase(k); setRunning(r => !r); }}>{running ? "Pause" : "Run"}</button>
        <button type="button" className="ctl" onClick={() => { setBase(0); setRunning(false); }}>Start over</button>
      </>}
      readouts={<>
        <MatRead minor label="A" M={[[(10 - P) / 10, Q / 10], [P / 10, (10 - Q) / 10]]} />
        <Read label={`Now at ${names.a}`} value={`${atA} of ${DOTS}`} tone="sky" />
        <Read minor label="Eigenvalues" value={`1 and ${fx(lam2, 1)}`} tone="amber" />
        <Read label={`Long run at ${names.a}, q / (p + q)`} value={`${fx(steadyA * 100, 1)}%`} tone="amber" />
      </>}
      foot={project ? <SaveRow what={<>Keep <b>steady</b> = {fx(steady[0]!, 3)}, {fx(steady[1]!, 3)} ({names.a}, {names.b})</>} saved={saved} onSave={() => {
        save("steady", steady, "la-forecast", { labels: [names.a, names.b], note: `p = ${fx(P / 10, 1)}, q = ${fx(Q / 10, 1)}` });
        note({ id: "la-forecast", track: "la", title: "Long-run forecaster", project: "la-forecast", data: { p: P / 10, q: Q / 10 },
          lines: [`${names.a} to ${names.b} with chance ${fx(P / 10, 1)}, back with chance ${fx(Q / 10, 1)}.`, `In the long run ${fx(steadyA * 100, 1)}% at ${names.a}; the gap shrinks by ${fx(lam2, 1)} each step.`] });
      }} /> : undefined}
    />
  );
}
