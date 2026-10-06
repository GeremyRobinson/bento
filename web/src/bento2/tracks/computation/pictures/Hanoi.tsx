// The Tower of Hanoi (computation.md, cs-09): 1 to 10 disks. Tap a peg to lift its top disk and another to drop it (a big
// disk never goes on a small one), or tap "Solve" to play the recursive solution: the top n − 1 aside, the biggest
// across, the n − 1 back on top. The move counter runs either way.
// Quiet (a Guess before Lock in): the tower stands still and no counter shows.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { Read, Scene, Slider, useClock } from "../../../ui/kit";
import { group } from "../../../steps";

const W = 360;
const STILL = 1e9;
type Move = [number, number];
function solution(n: number, from = 0, to = 2, via = 1, out: Move[] = []): Move[] {
  if (n === 0) return out;
  solution(n - 1, from, via, to, out);
  out.push([from, to]);
  solution(n - 1, via, to, from, out);
  return out;
}
const start = (n: number) => [Array.from({ length: n }, (_, i) => n - i), [], []] as number[][];
const apply = (pegs: number[][], [a, b]: Move) => { const p = pegs.map(x => [...x]); p[b]!.push(p[a]!.pop()!); return p; };

export function HanoiScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet");
  const [n, setN] = useState(Math.max(1, Math.min(10, Math.round(num(props, "n", 4)))));
  const [pegs, setPegs] = useState(() => start(n));
  const [moves, setMoves] = useState(0);
  const [held, setHeld] = useState<number | null>(null);
  const [solving, setSolving] = useState(flag(props, "solve") ? 1 : 0);
  const sol = useMemo(() => solution(n), [n]);
  const rate = Math.max(2, sol.length / 8);
  const t = Math.max(0, useClock(solving > 0 && !quiet, STILL + solving));
  const k = solving > 0 && !quiet ? (t >= STILL ? sol.length : Math.min(sol.length, Math.floor(t * rate))) : 0;
  const shown = useMemo(() => (solving > 0 ? sol.slice(0, k).reduce(apply, start(n)) : pegs), [solving, sol, k, n, pegs]);
  const count = solving > 0 ? k : moves;
  const reset = (m: number) => { setN(m); setPegs(start(m)); setMoves(0); setHeld(null); setSolving(0); };
  const tap = (p: number) => {
    if (quiet || solving) return;
    if (held == null) { if (pegs[p]!.length) setHeld(p); return; }
    const top = pegs[held]!.at(-1)!, under = pegs[p]!.at(-1);
    if (p !== held && (under == null || under > top)) { setPegs(apply(pegs, [held, p])); setMoves(m => m + 1); }
    setHeld(null);
  };
  const px = (p: number) => 64 + p * 116, base = 190, dh = Math.min(16, 140 / n);
  const last = solving > 0 && k > 0 ? sol[k - 1]![1] : -1;
  const svg = (
    <svg viewBox={`0 0 ${W} 230`} className="b2pic" role="img" aria-label={`A tower of ${n} disks on three pegs.${quiet ? "" : ` ${count} moves so far.`}`}>
      <line x1="10" y1={base} x2={W - 10} y2={base} className="b2axis" />
      {[0, 1, 2].map(p => (
        <g key={p} onClick={() => tap(p)} style={{ cursor: quiet ? undefined : "pointer" }}>
          <rect x={px(p) - 3} y={base - 150} width="6" height="150" rx="3" className="b2bar unknown" />
          {shown[p]!.map((d, i) => {
            const w = 22 + (d / n) * 84, lifted = held === p && i === shown[p]!.length - 1, moved = last === p && i === shown[p]!.length - 1;
            return <rect key={d} x={px(p) - w / 2} y={base - (i + 1) * dh - (lifted ? 14 : 0)} width={w} height={dh - 2} rx={Math.min(6, dh / 2)} className={`b2bar ${lifted || moved ? "amber" : "sky"}`} opacity={0.55 + (0.45 * d) / n} />;
          })}
          <text x={px(p)} y={base + 18} textAnchor="middle" className="b2t">{"ABC"[p]}</text>
          <rect x={px(p) - 56} y={base - 160} width="112" height="186" className="b2hit" style={{ cursor: quiet ? undefined : "pointer" }} />
        </g>
      ))}
      {!quiet && shown[2]!.length === n && <text x={W - 12} y="20" textAnchor="end" className="b2t amber">moved in {group(count)}</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <>
        <Slider label="Disks" value={n} min={1} max={10} step={1} onChange={reset} />
        <button type="button" className="ctl go" onClick={() => { setPegs(start(n)); setMoves(0); setHeld(null); setSolving(s => s + 1); }}>Solve</button>
        <button type="button" className="ctl" onClick={() => reset(n)}>Reset</button>
      </>}
      readouts={quiet ? <Read label="Disks" value={n} /> : <>
        <Read label="Moves" value={group(count)} tone="amber" big />
        <Read label="Fewest possible, 2ⁿ − 1" value={group(2 ** n - 1)} tone="sky" />
        <Read label="At one move a second" value={2 ** n - 1 < 3600 ? `${group(2 ** n - 1)} s` : `${(Math.round((2 ** n - 1) / 360) / 10)} hours`} />
      </>}
    />
  );
}
