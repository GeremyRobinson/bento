// The epidemic model (diffeq.md, "New for Development" 8): S, I and R for a town, an R₀ readout, the herd-immunity line
// on S, a marker at the peak (which always sits where S crosses that line), and a vaccination slider. As the
// Outbreak planner it saves R0 and vax_needed.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { solve } from "../maths";
import { frame } from "./plot";

const W = 360, H = 250, I0 = 0.001;

export function simulate(beta: number, D: number, vax: number) {
  const g = 1 / D, S0 = (1 - vax) * (1 - I0);
  const run = solve((_t, y) => { const inf = beta * y[0]! * y[1]!; return [-inf, inf - g * y[1]!, g * y[1]!]; }, [S0, I0, vax * (1 - I0)], 0, 400, 0.25);
  let k = 0;
  run.forEach((p, i) => { if (p.y[1]! > run[k]!.y[1]!) k = i; });
  const end = run.findIndex((p, i) => i > k && p.y[1]! < I0 / 2);
  return { run: end > 0 ? run.slice(0, end + 1) : run, peak: run[k]! };
}

export function SirScene({ props, marker, place }: SceneProps) {
  const [beta, setBeta] = useState(num(props, "beta", 0.4));
  const [D, setD] = useState(num(props, "D", 10));
  const [vax, setVax] = useState(num(props, "vax", 0));
  const quiet = flag(props, "quiet"), project = place === "project" || flag(props, "project");
  const { b2, save, note } = useB2();
  const R0 = beta * D, herd = Math.max(0, 1 - 1 / R0);
  const { run, peak } = useMemo(() => simulate(beta, D, vax), [beta, D, vax]);
  const tEnd = Math.max(60, run.at(-1)!.t);
  const f = frame(0, tEnd, 0, 1, { l: 34, r: 352, t: 14, b: 214 });
  const curve = (j: number) => path(run.filter((_, i) => i % 2 === 0).map(p => [f.X(p.t), f.Y(p.y[j]!)] as [number, number]));
  const outbreak = R0 * (1 - vax) > 1 && peak.y[1]! > I0 * 1.5;
  const saved = b2.shelf.R0?.value === R0 && b2.shelf.vax_needed?.value === herd;
  const onSave = () => {
    save("R0", R0, "de-outbreak", { note: `β = ${fx(beta, 2)} a day for ${fx(D, 1)} days` });
    save("vax_needed", herd, "de-outbreak", { note: "the fraction to vaccinate, 1 − 1/R₀" });
    note({ id: "de-outbreak", track: "de", title: "Outbreak planner", project: "de-outbreak", data: { beta, D, vax },
      lines: [`R₀ = ${fx(R0, 2)}: vaccinate ${fx(herd * 100, 1)}% to stop outbreaks.`, `With ${fx(vax * 100, 0)}% vaccinated the peak is ${outbreak ? `${fx(peak.y[1]! * 100, 1)}% sick at once, on day ${fx(peak.t, 0)}` : "nothing: the outbreak can't start"}.`] });
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`SIR town with R₀ = ${fx(R0, 2)}${quiet ? "" : `; infections peak at ${fx(peak.y[1]! * 100, 1)} percent`}.`}>
      <line x1={f.box.l} y1={f.box.b} x2={f.box.r} y2={f.box.b} className="b2axis" />
      <line x1={f.box.l} y1={f.box.t} x2={f.box.l} y2={f.box.b} className="b2axis" />
      {[0.25, 0.5, 0.75, 1].map(y => <line key={y} x1={f.box.l} y1={f.Y(y)} x2={f.box.r} y2={f.Y(y)} className="b2grid" />)}
      <text x={f.box.l - 6} y={f.Y(1) + 4} textAnchor="end" className="b2t">all</text>
      <text x={f.box.r} y={f.box.b + 16} textAnchor="end" className="b2t">{fx(tEnd, 0)} days</text>
      {!quiet && R0 > 1 && <>
        <line x1={f.box.l} y1={f.Y(1 / R0)} x2={f.box.r} y2={f.Y(1 / R0)} className="b2mark amber" />
        <text x={f.box.r} y={f.Y(1 / R0) - 6} textAnchor="end" className="b2t amber">herd line 1/R₀</text>
      </>}
      <path d={curve(0)} className="b2curve sky" />
      <path d={curve(2)} className="b2curve mint" />
      <path d={curve(1)} className="b2curve pink" />
      {!quiet && outbreak && <>
        <line x1={f.X(peak.t)} y1={f.box.t} x2={f.X(peak.t)} y2={f.box.b} className="b2mark pink" />
        <circle cx={f.X(peak.t)} cy={f.Y(peak.y[1]!)} r="5" className="b2dot pink" />
        <circle cx={f.X(peak.t)} cy={f.Y(peak.y[0]!)} r="5" className="b2dot sky" />
      </>}
      {marker && <line x1={f.box.l} y1={f.Y(marker[0])} x2={f.box.r} y2={f.Y(marker[0])} className="b2mark guess" />}
      <text x={f.box.l + 6} y={f.Y(run[0]!.y[0]!) + 16} className="b2t sky">S</text>
      <text x={f.X(peak.t) + 8} y={f.Y(peak.y[1]!) - 6} className="b2t pink">I</text>
      <text x={f.box.r - 4} y={f.Y(run.at(-1)!.y[2]!) + 16} textAnchor="end" className="b2t mint">R</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Contacts a day β" value={beta} min={0.1} max={1} step={0.01} onChange={setBeta} format={x => fx(x, 2)} />
        <Slider label="Infectious days D" value={D} min={2} max={14} step={0.5} onChange={setD} format={x => `${fx(x, 1)} days`} />
        <Slider label="Vaccinated" value={vax} min={0} max={0.95} step={0.01} onChange={setVax} format={x => `${fx(x * 100, 0)}%`} />
      </>}
      readouts={<>
        <Read label="R₀ = βD" value={fx(R0, 2)} tone="amber" />
        {!quiet && <Read label="Herd immunity" value={`${fx(herd * 100, 1)}%`} tone="amber" />}
        {!quiet && <Read label="Peak sick at once" value={outbreak ? `${fx(peak.y[1]! * 100, 1)}%` : "no outbreak"} tone="pink" />}
        {!quiet && vax > 0 && <Read label="R₀ after vaccinating" value={fx(R0 * (1 - vax), 2)} />}
      </>}
      foot={project ? <SaveRow what={<>Keep <b>R0 = {fx(R0, 2)}</b> and <b>vax_needed = {fx(herd * 100, 1)}%</b></>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
