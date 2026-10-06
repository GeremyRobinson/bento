// Forcing and resonance (diffeq.md, "New for Development" 6): a spring pushed with F·cos(ωt). The swing against time
// starts up and settles to its steady size, and the resonance curve draws that size against ω, live, with a dot at
// your drive. The reveal sweeps ω and lights the peak.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider } from "../../../ui/kit";
import { solve, steadyAmp } from "../maths";
import { frame, useRun } from "./plot";

const W = 360, H = 270;

export function ResonanceScene({ props, marker }: SceneProps) {
  const w0 = num(props, "w0", 5);
  const [w, setW] = useState(num(props, "w", 3));
  const [c, setC] = useState(num(props, "c", 1));
  const [F, setF] = useState(num(props, "F", 10));
  const quiet = flag(props, "quiet"), sweep = flag(props, "sweep");
  const k = useRun(sweep, 3);
  const amp = steadyAmp(F, w0, w, c);
  const peakW = Math.sqrt(Math.max(0, w0 * w0 - (c * c) / 2)), peakA = steadyAmp(F, w0, peakW, c);
  const wMax = Math.max(10, w0 * 2);
  const top = Math.max(peakA, amp) * 1.15;
  const run = useMemo(() => solve((t, y) => [y[1]!, F * Math.cos(w * t) - c * y[1]! - w0 * w0 * y[0]!], [0, 0], 0, 25, 0.01), [w, c, F, w0]);
  const tr = frame(0, 25, -top, top, { l: 30, r: 352, t: 12, b: 112 });
  const rc = frame(0, wMax, 0, top, { l: 30, r: 352, t: 140, b: 246 });
  const curve = (upto: number) => path(Array.from({ length: 161 }, (_, j) => (wMax * j) / 160).filter(x => x <= upto).map(x => [rc.X(x), rc.Y(Math.min(top, steadyAmp(F, w0, x, c)))] as [number, number]));
  const showCurve = !quiet || sweep;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Driven at ${fx(w, 2)} with natural frequency ${w0}: the swing settles to ${fx(amp, 2)}.`}>
      {/* the swing against time */}
      <line x1={tr.box.l} y1={tr.Y(0)} x2={tr.box.r} y2={tr.Y(0)} className="b2axis" />
      <line x1={tr.box.l} y1={tr.box.t} x2={tr.box.l} y2={tr.box.b} className="b2axis" />
      <line x1={tr.box.l} y1={tr.Y(amp)} x2={tr.box.r} y2={tr.Y(amp)} className="b2mark amber" />
      <line x1={tr.box.l} y1={tr.Y(-amp)} x2={tr.box.r} y2={tr.Y(-amp)} className="b2mark amber" />
      <path d={path(run.filter((_, i) => i % 2 === 0).map(p => [tr.X(p.t), tr.Y(Math.max(-top, Math.min(top, p.y[0]!)))] as [number, number]))} className="b2curve sky" style={{ strokeWidth: 1.6 }} />
      <text x={tr.box.r} y={tr.box.b + 14} textAnchor="end" className="b2t">25 s</text>
      {/* the resonance curve */}
      <line x1={rc.box.l} y1={rc.box.b} x2={rc.box.r} y2={rc.box.b} className="b2axis" />
      <line x1={rc.box.l} y1={rc.box.t} x2={rc.box.l} y2={rc.box.b} className="b2axis" />
      <line x1={rc.X(w0)} y1={rc.box.t} x2={rc.X(w0)} y2={rc.box.b} className="b2grid strong" />
      <text x={rc.X(w0)} y={rc.box.b + 15} textAnchor="middle" className="b2t">ω₀</text>
      <text x={rc.box.r} y={rc.box.b + 15} textAnchor="end" className="b2t">ω</text>
      <text x={rc.box.l + 4} y={rc.box.t + 4} className="b2t">size</text>
      {showCurve && <path d={curve(sweep ? 0.01 + wMax * k : wMax)} className="b2curve amber" />}
      {sweep && k >= 1 && <><circle cx={rc.X(peakW)} cy={rc.Y(peakA)} r="7" className="b2dot amber" /><text x={rc.X(peakW) + 10} y={rc.Y(peakA) + 4} className="b2t amber">peak</text></>}
      <circle cx={rc.X(w)} cy={rc.Y(Math.min(top, amp))} r="5.5" className="b2dot pink" />
      {marker && <line x1={rc.X(marker[0])} y1={rc.box.t} x2={rc.X(marker[0])} y2={rc.box.b} className="b2mark guess" />}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Drive ω" value={w} min={0.5} max={wMax} step={0.05} onChange={setW} format={x => fx(x, 2)} />
        <Slider label="Friction c" value={c} min={0.2} max={6} step={0.1} onChange={setC} format={x => fx(x, 1)} />
        <Slider label="Push F" value={F} min={5} max={180} step={1} onChange={setF} />
      </>}
      readouts={<>
        <Read label="Natural ω₀" value={String(w0)} />
        <Read label="Steady size" value={fx(amp, 2)} tone="pink" />
        {!quiet && <Read label="Peak at ω" value={fx(peakW, 2)} tone="amber" />}
      </>}
    />
  );
}
