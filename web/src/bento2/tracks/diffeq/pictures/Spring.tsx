// The spring lab (diffeq.md, toolbox "Spring and pendulum lab"): a mass on a spring with a friction dial. The mass
// moves, its graph against time and its phase-plane path run together, and the dial marks critical damping.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider } from "../../../ui/kit";
import { solve } from "../maths";
import { frame, useLoop } from "./plot";

const W = 360, H = 284;

export function SpringScene({ props, marker }: SceneProps) {
  const m0 = num(props, "m", 1), k0 = num(props, "k", 4), cc0 = 2 * Math.sqrt(m0 * k0);
  const [m, setM] = useState(m0);
  const [k, setK] = useState(k0);
  const [c, setC] = useState(num(props, "c", 1));
  const quiet = flag(props, "quiet"), crit = flag(props, "crit");
  const w = Math.sqrt(k / m), cc = 2 * Math.sqrt(m * k), z = c / cc;
  const Tw = Math.min(4 * ((2 * Math.PI) / w), 30 / w);
  const run = useMemo(() => solve((_t, y) => [y[1]!, (-c * y[1]! - k * y[0]!) / m], [1, 0], 0, Tw, Tw / 600), [m, k, c, Tw]);
  const t = useLoop(Tw);
  const idx = Math.min(run.length - 1, Math.floor((((t / 6) % 1) * (run.length - 1))));
  const x = run[idx]!.y[0]!, v = run[idx]!.y[1]!;
  const g = frame(0, Tw, -1.15, 1.15, { l: 30, r: 352, t: 96, b: 222 });
  const vmax = Math.max(w, ...run.map(p => Math.abs(p.y[1]!)));
  const ph = frame(-1.2, 1.2, -vmax * 1.2, vmax * 1.2, { l: 262, r: 352, t: 8, b: 82 });
  const dial = { l: 30, r: 352, y: 260 }, cmax = 2.5 * cc0, DX = (cv: number) => dial.l + (Math.min(cmax, cv) / cmax) * (dial.r - dial.l);
  const mx = 140 + x * 70, coils = 10;
  const zig = Array.from({ length: coils * 2 + 1 }, (_, i) => [20 + ((mx - 22 - 20) * i) / (coils * 2), 46 + (i === 0 || i === coils * 2 ? 0 : i % 2 ? -9 : 9)] as [number, number]);
  const type = z === 0 ? "No friction" : Math.abs(z - 1) < 0.02 ? "Critical" : z < 1 ? "Bounces" : "Creeps";
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A ${fx(m, 1)} kilogram mass on a spring, k = ${fx(k, 0)}, friction ${fx(c, 1)}${quiet ? "" : `: ${type.toLowerCase()}`}.`}>
      {/* the mass on its spring */}
      <line x1="20" y1="22" x2="20" y2="70" className="b2axis" />
      <line x1="140" y1="72" x2="140" y2="80" className="b2axis" />
      <path d={path(zig)} className="b2curve" style={{ strokeWidth: 1.6 }} />
      <rect x={mx - 22} y="28" width="44" height="36" rx="7" className="b2bar trav" />
      {/* its phase-plane path */}
      <rect x={ph.box.l} y={ph.box.t} width={ph.box.r - ph.box.l} height={ph.box.b - ph.box.t} rx="8" className="b2bar track" />
      <path d={path(run.map(p => [ph.X(p.y[0]!), ph.Y(p.y[1]!)] as [number, number]))} className="b2curve sky" style={{ strokeWidth: 1.5 }} />
      <circle cx={ph.X(x)} cy={ph.Y(v)} r="4" className="b2dot trav" />
      {/* against time */}
      <line x1={g.box.l} y1={g.Y(0)} x2={g.box.r} y2={g.Y(0)} className="b2axis" />
      <line x1={g.box.l} y1={g.box.t} x2={g.box.l} y2={g.box.b} className="b2axis" />
      <text x={g.box.r} y={g.Y(0) - 6} textAnchor="end" className="b2t">t</text>
      <text x={g.box.l + 4} y={g.box.t + 10} className="b2t">x</text>
      <path d={path(run.map(p => [g.X(p.t), g.Y(p.y[0]!)] as [number, number]))} className="b2curve sky" />
      <circle cx={g.X(run[idx]!.t)} cy={g.Y(x)} r="5" className="b2dot trav" />
      {/* the friction dial */}
      <line x1={dial.l} y1={dial.y} x2={dial.r} y2={dial.y} className="b2axis" />
      <text x={dial.l} y={dial.y + 18} className="b2t">friction 0</text>
      <circle cx={DX(c)} cy={dial.y} r="6" className="b2dot pink" />
      {(crit || !quiet) && <><line x1={DX(cc)} y1={dial.y - 12} x2={DX(cc)} y2={dial.y + 6} className="b2leg amber" style={{ strokeWidth: 3 }} /><text x={DX(cc)} y={dial.y - 16} textAnchor="middle" className="b2t amber">critical</text></>}
      {marker && <circle cx={DX(marker[0])} cy={dial.y} r="8" className="b2marker" />}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Mass m" value={m} min={m0 / 4} max={m0 * 4} step={m0 / 20} onChange={setM} format={v => `${fx(v, m0 >= 10 ? 0 : 2)} kg`} />
        <Slider label="Stiffness k" value={k} min={k0 / 4} max={k0 * 4} step={k0 / 40} onChange={setK} format={v => `${fx(v, k0 >= 100 ? 0 : 1)} N/m`} />
        <Slider label="Friction c" value={c} min={0} max={Math.round(cmax * 10) / 10} step={cc0 / 100} onChange={setC} format={v => `${fx(v, cc0 >= 100 ? 0 : 2)} N·s/m`} />
      </>}
      readouts={<>
        <Read label="ω = √(k/m)" value={`${fx(w, 2)} per s`} />
        <Read label="Period" value={`${fx((2 * Math.PI) / w, 2)} s`} />
        {!quiet && <Read label="c_crit = 2√(mk)" value={fx(cc, cc >= 100 ? 0 : 2)} tone="amber" />}
        {!quiet && <Read label="ζ" value={fx(z, 2)} tone="pink" />}
        {!quiet && <Read label="Motion" value={type} />}
      </>}
    />
  );
}
