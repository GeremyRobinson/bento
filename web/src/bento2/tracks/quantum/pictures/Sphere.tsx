// ★ The qubit sphere (Bloch sphere, quantum.md "New for Development"): an arrow on a ball, dragged on the ball or by
// θ (down from the top) and φ (around). Readouts: the amplitudes cos(θ/2) and e^{iφ} sin(θ/2), P(0), P(1), and a bar
// for the height z = P(0) − P(1). Gates play as turns: X and Z by 180° about their axes, H about the diagonal, S by
// 90° about the vertical. Measure snaps the arrow to the top or the bottom; Run sends 1,000 shots to the bars.
import { useEffect, useMemo, useRef, useState } from "react";
import { reduceMotion } from "../../../../app/transition";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { ArrowHead, fx, path, Read, Scene, Slider, useSvgDrag } from "../../../ui/kit";
import { blochVec, fromVec, GATE_TURNS, shots, stream, tally, turn } from "../maths";
import { ShotBars, shownOf, useRun } from "./parts";

type V = [number, number, number];
const W = 360, H = 260, CX = 136, CY = 132, R = 100, N = 1000;
const EL = (18 * Math.PI) / 180, AZ = (20 * Math.PI) / 180;
const EH: V = [-Math.sin(AZ), Math.cos(AZ), 0];
const EV: V = [-Math.sin(EL) * Math.cos(AZ), -Math.sin(EL) * Math.sin(AZ), Math.cos(EL)];
const ED: V = [Math.cos(EL) * Math.cos(AZ), Math.cos(EL) * Math.sin(AZ), Math.sin(EL)];
const dot = (a: V, b: V) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const proj = (p: V): [number, number] => [CX + R * dot(p, EH), CY - R * dot(p, EV)];
const ease = (k: number) => (k < 0.5 ? 2 * k * k : 1 - (-2 * k + 2) ** 2 / 2);
const norm = (v: V): V => { const l = Math.hypot(...v) || 1; return [v[0] / l, v[1] / l, v[2] / l]; };

interface Anim { from: V; axis: V; angle: number; t0: number; ms: number }

export function SphereScene({ props, marker }: SceneProps) {
  const quiet = flag(props, "quiet");
  const [base, setBase] = useState<V>(blochVec(num(props, "theta", 60), num(props, "phi", 30)));
  const [queue, setQueue] = useState<string[]>(str(props, "gates", "").split("").filter(g => g in GATE_TURNS));
  const [anim, setAnim] = useState<Anim | null>(null);
  const [now, setNow] = useState(0);
  const [log, setLog] = useState<string[]>([]);
  const seed = useRef(7);
  const run = useRun(4, flag(props, "run"));
  const { ref, drag } = useSvgDrag();

  // the turn in progress, if any, as a fraction of the way
  const k = anim ? (anim.ms ? Math.max(0, Math.min(1, (now - anim.t0) / anim.ms)) : 1) : 0;
  const v: V = anim ? turn(anim.from, anim.axis, anim.angle * ease(k)) : base;
  useEffect(() => {
    if (anim) {
      if (k >= 1) { setBase(turn(anim.from, anim.axis, anim.angle)); setAnim(null); return; }
      const raf = requestAnimationFrame(t => setNow(t));
      return () => cancelAnimationFrame(raf);
    }
    if (queue.length) {
      const g = GATE_TURNS[queue[0]!]!;
      const t0 = performance.now();
      setAnim({ from: base, axis: g.axis, angle: g.angle, t0: t0 + 250, ms: reduceMotion() ? 0 : 1100 });
      setNow(t0);
      setLog(l => [...l, queue[0]!].slice(-8));
      setQueue(q => q.slice(1));
    }
  }, [anim, k, queue, base]);

  const [th, ph] = fromVec(v);
  const P0 = (1 + v[2]) / 2, P1 = 1 - P0;
  const outs = useMemo(() => shots([P0, P1], N, 300 + run.runs), [run.runs]); // eslint-disable-line react-hooks/exhaustive-deps
  const shown = run.runs ? shownOf(run.k, N) : 0;
  const counts = tally(outs, 2, shown);

  const gate = (g: string) => setQueue(q => [...q, g]);
  const measure = () => {
    if (anim) return;
    const r = stream(seed.current++)();
    const target: V = r < P0 ? [0, 0, 1] : [0, 0, -1];
    const c = dot(base, target);
    if (c > 0.99999) return;
    const axis = c < -0.99999 ? ([0, 1, 0] as V) : norm([base[1] * target[2] - base[2] * target[1], base[2] * target[0] - base[0] * target[2], base[0] * target[1] - base[1] * target[0]]);
    const t0 = performance.now();
    setAnim({ from: base, axis, angle: (Math.acos(Math.max(-1, Math.min(1, c))) * 180) / Math.PI, t0, ms: reduceMotion() ? 0 : 500 });
    setNow(t0);
    setLog(l => [...l, target[2] > 0 ? "read 0" : "read 1"].slice(-8));
  };
  const set = (t: number, p: number) => { if (!anim) setBase(blochVec(t, p)); };
  // dragging on the ball: the point under the finger on the front half
  const onBall = (x: number, y: number) => {
    const u = (x - CX) / R, w = (CY - y) / R, d2 = u * u + w * w;
    const p: V = d2 >= 1 ? norm([u * EH[0] + w * EV[0], u * EH[1] + w * EV[1], u * EH[2] + w * EV[2]])
      : [u * EH[0] + w * EV[0] + Math.sqrt(1 - d2) * ED[0], u * EH[1] + w * EV[1] + Math.sqrt(1 - d2) * ED[1], u * EH[2] + w * EV[2] + Math.sqrt(1 - d2) * ED[2]];
    const [t, q] = fromVec(p);
    set(Math.round(t), Math.round(q));
  };

  const ringPts = (t: number) => Array.from({ length: 73 }, (_, i) => blochVec(t, i * 5));
  const halves = (pts: V[]) => {
    const front: [number, number][][] = [[]], back: [number, number][][] = [[]];
    for (const p of pts) {
      const isF = dot(p, ED) >= 0;
      (isF ? front : back).at(-1)!.push(proj(p));
      (isF ? back : front).push([]);
    }
    return { front: front.filter(s => s.length > 1).map(path).join(" "), back: back.filter(s => s.length > 1).map(path).join(" ") };
  };
  const eq = halves(ringPts(90));
  const mer = halves(Array.from({ length: 73 }, (_, i) => blochVec(i * 2.5, ph)).concat(Array.from({ length: 73 }, (_, i) => blochVec(180 - i * 2.5, ph + 180))));
  const ring = num(props, "ring", NaN);
  const ringH = Number.isFinite(ring) ? halves(ringPts(ring)) : null;
  const tip = proj(v), top = proj([0, 0, 1]), bot = proj([0, 0, -1]), xAx = proj([1, 0, 0]);
  const ghost = marker ? proj(blochVec(marker[0], 110)) : null;
  const zb = 262, zTop = 32, zH = 200, zMid = zTop + zH / 2;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic sphere" role="img"
      aria-label={`The qubit's arrow at θ = ${Math.round(th)}°, φ = ${Math.round(ph)}°.${quiet ? "" : ` P(0) = ${fx(P0)}, P(1) = ${fx(P1)}.`}`}>
      <circle cx={CX} cy={CY} r={R} className="b2ring" />
      <circle cx={CX} cy={CY} r={R} className="b2hit" {...drag(onBall)} />
      <path d={eq.back} className="b2grid strong" strokeDasharray="3 4" fill="none" />
      <path d={eq.front} className="b2grid strong" fill="none" />
      <path d={mer.back} className="b2grid" strokeDasharray="3 4" fill="none" />
      <path d={mer.front} className="b2grid strong" fill="none" />
      <line x1={top[0]} y1={top[1]} x2={bot[0]} y2={bot[1]} className="b2grid strong" />
      <line x1={CX} y1={CY} x2={xAx[0]} y2={xAx[1]} className="b2grid strong" strokeDasharray="2 3" />
      {ringH && <g className="amber"><path d={ringH.back} className="b2mark" opacity="0.5" /><path d={ringH.front} className="b2mark" /></g>}
      <text x={top[0] + 8} y={top[1] - 4} className="b2t sky">0</text>
      <text x={bot[0] + 8} y={bot[1] + 14} className="b2t pink">1</text>
      {ghost && <g><line x1={CX} y1={CY} x2={ghost[0]} y2={ghost[1]} className="b2mark guess" /><text x={ghost[0] + 8} y={ghost[1]} className="b2t">your guess</text></g>}
      <g className="amber">
        <line x1={CX} y1={CY} x2={tip[0]} y2={tip[1]} className="b2leg" strokeWidth={dot(v, ED) >= 0 ? 3.5 : 2.5} opacity={dot(v, ED) >= 0 ? 1 : 0.6} />
        <ArrowHead x1={CX} y1={CY} x2={tip[0]} y2={tip[1]} className="b2dot" />
      </g>
      <circle cx={tip[0]} cy={tip[1]} r="16" className="b2hit" {...drag(onBall)} />
      {/* the height bar: z = P(0) − P(1), from −1 at the bottom to +1 at the top */}
      <rect x={zb} y={zTop} width="14" height={zH} rx="4" className="b2bar track" />
      {!quiet && <rect x={zb} y={Math.min(zMid, zMid - v[2] * zH / 2)} width="14" height={Math.abs(v[2]) * zH / 2} rx="3" className="b2bar amber" />}
      <line x1={zb - 4} y1={zMid} x2={zb + 18} y2={zMid} className="b2axis" />
      <text x={zb + 7} y={zTop + zH + 17} textAnchor="middle" className="b2t">z</text>
      {run.runs > 0 && <ShotBars x={294} y={zTop} w={60} h={zH} labels={["0", "1"]} ps={[P0, P1]} counts={counts} n={N} tones={["sky", "pink"]} hideP={quiet} />}
    </svg>
  );
  const busy = !!anim || queue.length > 0;
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="θ, down from the top" value={Math.round(th)} min={0} max={180} step={1} onChange={t => set(t, ph)} format={x => `${x}°`} />
        <Slider label="φ, around" value={Math.round(ph)} min={0} max={359} step={1} onChange={p => set(th, p)} format={x => `${x}°`} />
        <span className="b2ops" role="group" aria-label="Gates">
          {["X", "Z", "H", "S"].map(g => <button type="button" key={g} className="ctl" disabled={busy && queue.length > 3} onClick={() => gate(g)}>{g}</button>)}
          {!quiet && <button type="button" className="ctl" disabled={busy} onClick={measure}>Measure</button>}
          {!quiet && <button type="button" className="ctl go" onClick={run.run}>Run 1,000</button>}
        </span>
      </>}
      readouts={quiet ? <>
        <Read label="θ" value={`${Math.round(th)}°`} tone="amber" minor />
        <Read label="φ" value={`${Math.round(ph)}°`} minor />
        {log.length > 0 && <Read label="Gates so far" value={log.join(", ")} minor />}
      </> : <>
        <Read label="Amplitude of 0, cos(θ/2)" value={fx(Math.cos((th * Math.PI) / 360), 3)} tone="sky" minor />
        <Read label="Amplitude of 1, e^(iφ) sin(θ/2)" value={`${fx(Math.sin((th * Math.PI) / 360), 3)} at ${Math.round(ph)}°`} tone="pink" minor />
        <Read label="P(0)" value={fx(P0, 3)} tone="sky" />
        <Read label="P(1)" value={fx(P1, 3)} tone="pink" />
        <Read label="Height z" value={fx(v[2], 3)} tone="amber" minor />
        {log.length > 0 && <Read label="Gates so far" value={log.join(", ")} minor />}
        {shown > 0 && <Read label="Shots: 0s and 1s" value={`${counts[0]} and ${counts[1]}`} />}
      </>}
    />
  );
}
