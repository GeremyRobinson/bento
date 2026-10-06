// Reflect about the mean (quantum.md, inside the circuit board; 11): N amplitudes as bars, one marked. Each round
// plays in two moves: the oracle flips the marked bar below zero, then diffusion flips every bar to the other side of
// the dashed mean line. Under the bars, the marked chance after each round: it climbs, peaks and overshoots.
import { useEffect, useState } from "react";
import { reduceMotion } from "../../../../app/transition";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider, useTween } from "../../../ui/kit";
import { bestRounds, groverP, groverRound } from "../maths";

const W = 360, H = 268, ZERO = 104, AMP = 84, MAXK = 8;

export function MeanScene({ props, marker }: SceneProps) {
  const quiet = flag(props, "quiet"), play = flag(props, "play");
  const [N, setN] = useState(num(props, "N", 16));
  const [k, setK] = useState(num(props, "k", 1));
  useEffect(() => {
    if (!play) return;
    if (reduceMotion()) { setK(6); return; }
    const ts = [1, 2, 3, 4, 5, 6].map(r => setTimeout(() => setK(r), 300 + (r - 1) * 1500));
    return () => ts.forEach(clearTimeout);
  }, [play]);
  const kk = useTween(k, 1300);
  const m = Math.floor(N / 3);
  // the state after whole rounds, then part of the next round: the oracle's flip, then the reflection
  const whole = Math.max(0, Math.floor(kk + 1e-9)), part = kk - whole;
  let a = new Array<number>(N).fill(1 / Math.sqrt(N));
  for (let r = 0; r < whole; r++) a = groverRound(a, m);
  let mean: number | null = null;
  if (part > 1e-6) {
    const o = a.map((x, i) => (i === m ? -x : x));
    if (part < 0.5) a = a.map((x, i) => (i === m ? x * (1 - 4 * part) : x));
    else { const mu = o.reduce((s, x) => s + x, 0) / N, q = (part - 0.5) * 2; a = o.map(x => x + (2 * mu - 2 * x) * q); mean = mu; }
  } else mean = a.reduce((s, x) => s + x, 0) / N;
  const bw = Math.max(2, Math.min(18, 300 / N - 2)), step = 320 / N;
  const best = bestRounds(N), P = groverP(N, k);
  const cx = (r: number) => 44 + (r / MAXK) * 290, cy = (p: number) => 246 - p * 48;
  const showChart = !quiet || play;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mean" role="img"
      aria-label={`${N} amplitudes after ${k === 1 ? "one round" : `${k} rounds`}.${quiet ? "" : ` The marked one is found with chance ${fx(P, 3)}.`}`}>
      <line x1="18" y1={ZERO} x2="342" y2={ZERO} className="b2axis" />
      {a.map((x, i) => {
        const h = x * AMP, bx = 20 + i * step + (step - bw) / 2;
        return <rect key={i} x={bx} y={h >= 0 ? ZERO - h : ZERO} width={bw} height={Math.max(1, Math.abs(h))} rx={Math.min(3, bw / 2)} className={`b2bar ${i === m ? "pink" : "sky"}`} />;
      })}
      {mean != null && <>
        <line x1="18" y1={ZERO - mean * AMP} x2="342" y2={ZERO - mean * AMP} className="b2mark amber" />
        <text x="342" y={ZERO - mean * AMP - 6} textAnchor="end" className="b2t amber">mean</text>
      </>}
      <text x={20 + m * step + step / 2} y="16" textAnchor="middle" className="b2t pink">marked</text>
      {/* the marked chance after each round */}
      <line x1="40" y1="246" x2="340" y2="246" className="b2axis" />
      <line x1="40" y1="198" x2="340" y2="198" className="b2grid" />
      <text x="36" y="202" textAnchor="end" className="b2t">1</text>
      {Array.from({ length: MAXK + 1 }, (_, r) => (
        <g key={r}>
          {showChart && r <= (play ? k : MAXK) && <circle cx={cx(r)} cy={cy(groverP(N, r))} r={r === k ? 6 : 4} className={`b2dot ${r === k ? "amber" : "sky"}`} />}
          <text x={cx(r)} y="260" textAnchor="middle" className="b2t">{r}</text>
        </g>
      ))}
      {marker && <line x1={cx(marker[0])} y1="190" x2={cx(marker[0])} y2="248" className="b2mark guess" />}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={quiet && !play ? undefined : <>
        <Slider label="Items N" value={N} min={4} max={64} step={1} onChange={setN} marks={[4, 8, 16, 64].map(v => ({ v, label: String(v) }))} />
        <Slider label="Rounds" value={k} min={0} max={MAXK} step={1} onChange={setK} />
      </>}
      readouts={<>
        <Read label="Round" value={String(k)} />
        <Read label="P(marked)" value={quiet && !play ? "?" : fx(P, 3)} tone="pink" big />
        {!quiet && <Read label="Best round" value={`${best}, about (π/4)√N = ${fx((Math.PI / 4) * Math.sqrt(N), 1)}`} tone="amber" />}
        {play && <Read label="Chance after each round" value={Array.from({ length: k }, (_, r) => fx(groverP(N, r + 1), 3)).join(", ")} />}
      </>}
    />
  );
}
