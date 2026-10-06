// The oracle box (quantum.md, the circuit board's oracle; 10): f's four output cells, tapped between 0 and 1, and the
// circuit H on both, oracle, H on both, stepped one stage at a time. The four amplitudes are signed bars; the 00 bar
// is outlined, since H on both adds all four signs into it. Constant f fills it, balanced f empties it.
import { useEffect, useState } from "react";
import { reduceMotion } from "../../../../app/transition";
import { flag, str, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, useTween } from "../../../ui/kit";
import { hh, LABELS2 } from "../maths";
import { amp } from "./parts";

const W = 360, H = 260, STAGES = ["start", "H on both", "oracle", "H on both"];

export function DjScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), play = flag(props, "play");
  const [f, setF] = useState<number[]>(str(props, "f", "0110").split("").map(Number));
  const [stage, setStage] = useState(quiet || play ? 0 : 3);
  useEffect(() => {
    if (!play) return;
    if (reduceMotion()) { setStage(3); return; }
    const ts = [1, 2, 3].map(s => setTimeout(() => setStage(s), 400 + s * 1100));
    return () => ts.forEach(clearTimeout);
  }, [play]);
  const start = [1, 0, 0, 0], s1 = [0.5, 0.5, 0.5, 0.5], s2 = s1.map((a, i) => (f[i] ? -a : a)), s3 = hh(s2);
  const states = [start, s1, s2, s3];
  const target = states[stage]!;
  const kind = f.every(x => x === f[0]) ? "constant" : f.filter(Boolean).length === 2 ? "balanced" : "neither: f breaks the promise";
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic dj" role="img"
      aria-label={`f = ${f.join(", ")}. At the ${STAGES[stage]} stage the amplitudes are ${target.map(amp).join(", ")}.`}>
      {STAGES.map((s, i) => (
        <g key={i} opacity={i === stage ? 1 : 0.45}>
          <rect x={8 + i * 88} y="8" width="80" height="28" rx="8" className="b2bar track" />
          {i === stage && <rect x={8 + i * 88} y="8" width="80" height="28" rx="8" className="b2mark amber" strokeDasharray="none" />}
          <text x={48 + i * 88} y="27" textAnchor="middle" className="b2t">{s}</text>
        </g>
      ))}
      <line x1="20" y1="148" x2="340" y2="148" className="b2axis" />
      {target.map((_, i) => <Bar key={i} i={i} value={target[i]!} hide={quiet && stage > 1} />)}
      {/* f's table: tap a cell to flip it */}
      {f.map((v, i) => (
        <g key={`f${i}`} onClick={quiet ? undefined : () => setF(g => g.map((x, j) => (j === i ? 1 - x : x)))} style={quiet ? undefined : { cursor: "pointer" }}>
          <rect x={30 + i * 80} y="226" width="60" height="28" rx="8" className={`b2bar ${v ? "pink" : "track"}`} opacity={v ? 0.45 : 1} />
          <text x={60 + i * 80} y="245" textAnchor="middle" className="b2t">f = {v}</text>
        </g>
      ))}
    </svg>
  );
  const p00 = s3[0]! ** 2;
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <span className="b2ops" role="group" aria-label="Step the circuit">
        <button type="button" className="ctl" disabled={stage === 0} onClick={() => setStage(s => s - 1)}>‹ Back a stage</button>
        <button type="button" className="ctl go" disabled={stage === 3} onClick={() => setStage(s => s + 1)}>Next stage ›</button>
        <small>Tap f's cells under the bars to change f.</small>
      </span>}
      readouts={<>
        <Read label="f" value={kind} />
        <Read label="Now" value={STAGES[stage]!} />
        <Read label="Chance of 00 at the end" value={quiet && stage < 3 ? "?" : fx(p00, 2)} tone="amber" big />
      </>}
    />
  );
}

/** one amplitude as a signed bar above or below the line; the 00 bar outlined */
function Bar({ i, value, hide }: { i: number; value: number; hide: boolean }) {
  const h = useTween(value * 70, 700), x = 34 + i * 80;
  return (
    <g className={value >= 0 ? "amber" : "trav"}>
      <rect x={x} y={64} width="52" height="158" rx="6" className="b2bar track" opacity="0.4" />
      {!hide && <rect x={x + 6} y={h >= 0 ? 148 - h : 148} width="40" height={Math.max(1, Math.abs(h))} rx="4" className="b2bar" />}
      {i === 0 && <rect x={x - 2} y="62" width="56" height="160" rx="8" className="b2mark amber" />}
      <text x={x + 26} y="58" textAnchor="middle" className="b2t">{LABELS2[i]}</text>
      {!hide && <text x={x + 26} y={h >= 0 ? 168 : 136} textAnchor="middle" className="b2t">{amp(value)}</text>}
    </g>
  );
}
