// The Pendulum clock project (diffeq.md, after de-11): a seconds pendulum from L_pend with a little friction and one
// push each cycle. Friction shrinks the swing by e^(−βT/2) a cycle; the push adds p/ω. Size the push so the swing
// holds steady, read the drift per day, and save A_drive. It becomes the pendulum half of the build.
import { useState } from "react";
import { flag, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { G, pendulumPeriod } from "../maths";
import { frame, useLoop } from "./plot";

const W = 360, H = 250, A0 = (4 * Math.PI) / 180, CYCLES = 60;

/** the swing's size after each cycle, from a0, with friction β and a push p each cycle */
export function envelope(L: number, beta: number, p: number, n = CYCLES) {
  const w = Math.sqrt(G / L), T = pendulumPeriod(L, A0), keep = Math.exp((-beta * T) / 2);
  const out = [A0];
  for (let i = 0; i < n; i++) out.push(out[i]! * keep + p / w);
  return out;
}
export const pushNeeded = (L: number, beta: number) => Math.sqrt(G / L) * A0 * (1 - Math.exp((-beta * pendulumPeriod(L, A0)) / 2));

export function ClockScene({ props, place }: SceneProps) {
  const { b2, save, note } = useB2();
  const shelfL = b2.shelf.L_pend?.value;
  const [L, setL] = useState(typeof shelfL === "number" ? shelfL : 0.994);
  const [beta, setBeta] = useState(0.02);
  const [p, setP] = useState(typeof b2.shelf.A_drive?.value === "number" ? (b2.shelf.A_drive.value as number) : 0.004);
  const env = envelope(L, beta, p), need = pushNeeded(L, beta), T = pendulumPeriod(L, A0);
  const last = env[CYCLES]!, steady = Math.abs(last - A0) / A0 < 0.02;
  const drift = ((T - 2) / 2) * 86400;
  const t = useLoop(0);
  // the bob swings at the size it has reached, cycle by cycle
  const n = Math.min(CYCLES, Math.floor(t / T) % (CYCLES + 1)), th = env[n]! * Math.cos((2 * Math.PI * t) / T);
  const len = 150, bx = 70 + len * Math.sin(th * 4), by = 20 + len * Math.cos(th * 4);
  const g = frame(0, CYCLES, 0, A0 * 2, { l: 160, r: 352, t: 16, b: 200 });
  const project = place === "project" || flag(props, "project");
  const saved = b2.shelf.A_drive?.value === p;
  const onSave = () => {
    save("A_drive", p, "de-clock", { unit: "rad/s a cycle", note: `the push that holds a ${fx(L, 3)} m pendulum at 4°` });
    note({ id: "de-clock", track: "de", title: "Pendulum clock", project: "de-clock", data: { L, beta, p },
      lines: [`L = ${fx(L, 3)} m, period ${fx(T, 4)} s at a 4° swing.`, `Friction ${fx(beta, 3)} per s; a push of ${fx(p, 4)} rad/s each cycle (${steady ? "holds steady" : `needs ${fx(need, 4)}`}).`, `Drift: ${fx(Math.abs(drift), 1)} s a day ${drift >= 0 ? "slow" : "fast"}.`] });
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A ${fx(L, 3)} m clock pendulum: after ${CYCLES} cycles its swing is ${fx((last * 180) / Math.PI, 2)} degrees.`}>
      <line x1="50" y1="20" x2="90" y2="20" className="b2axis" />
      <line x1="70" y1="20" x2={bx} y2={by} className="b2leg" style={{ strokeWidth: 2.5 }} />
      <circle cx={bx} cy={by} r="11" className="b2dot trav" />
      <text x="70" y={H - 12} textAnchor="middle" className="b2t">swing × 4</text>
      <line x1={g.box.l} y1={g.box.b} x2={g.box.r} y2={g.box.b} className="b2axis" />
      <line x1={g.box.l} y1={g.box.t} x2={g.box.l} y2={g.box.b} className="b2axis" />
      <line x1={g.box.l} y1={g.Y(A0)} x2={g.box.r} y2={g.Y(A0)} className="b2mark amber" />
      <text x={g.box.r} y={g.Y(A0) - 6} textAnchor="end" className="b2t amber">4°</text>
      <path d={path(env.map((a, i) => [g.X(i), g.Y(Math.min(A0 * 2, a))] as [number, number]))} className="b2curve sky" />
      <circle cx={g.X(n)} cy={g.Y(Math.min(A0 * 2, env[n]!))} r="4.5" className="b2dot trav" />
      <text x={g.box.r} y={g.box.b + 16} textAnchor="end" className="b2t">{CYCLES} cycles</text>
      <text x={g.box.l + 4} y={g.box.t + 4} className="b2t">swing</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Length" value={L} min={0.9} max={1.1} step={0.001} onChange={setL} format={x => `${fx(x, 3)} m`} />
        <Slider label="Friction β" value={beta} min={0.005} max={0.08} step={0.001} onChange={setBeta} format={x => `${fx(x, 3)} per s`} />
        <Slider label="Push each cycle" value={p} min={0} max={0.03} step={0.0002} onChange={setP} format={x => `${fx(x, 4)} rad/s`} />
      </>}
      readouts={<>
        <Read label="Period at 4°" value={`${fx(T, 4)} s`} />
        <Read label="Drift a day" value={`${fx(Math.abs(drift), 1)} s ${drift >= 0 ? "slow" : "fast"}`} tone="amber" />
        <Read label="Swing after 60 cycles" value={`${fx((last * 180) / Math.PI, 2)}°`} tone="sky" />
        <Read label="Holds steady" value={steady ? "yes" : p < need ? "no, it dies down" : "no, it grows"} />
      </>}
      foot={project ? <SaveRow what={<>Keep <b>A_drive = {fx(p, 4)} rad/s</b> a cycle{steady ? "" : `, though ${fx(need, 4)} holds it steady`}</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
