// The build: two living models (diffeq.md, "The build"). A clock pendulum and a population, each with its phase
// portrait, its graph against time and live sliders, both stepped by the stepper on your shelf. The pieces come from
// the Number shelf (L_pend, A_drive, H_safe, allee_A and K_fish, R0 and vax_needed, stepper), with friendly
// defaults for any not saved yet. Saved to the Notebook as "Two living models".
import { useMemo, useState } from "react";
import { fx, path, Read, SaveRow, Scene, Slider, Toggle } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { G, METHOD_NAMES, METHODS, solve, stepWith, type Method } from "../maths";
import { pushNeeded } from "./Clock";
import { frame } from "./plot";

const W = 360, H = 300;
const shelfNum = (v: unknown, d: number) => (typeof v === "number" && Number.isFinite(v) ? v : d);

/** the clock pendulum, kicked by `push` each time it passes the bottom going forward */
function pendulumRun(L: number, beta: number, push: number, m: Method) {
  const f = (_t: number, y: number[]) => [y[1]!, -(G / L) * Math.sin(y[0]!) - beta * y[1]!];
  let y = [0.07, 0], t = 0;
  const h = 0.01, out = [{ t, y }];
  while (t < 40) {
    const n = stepWith(m, f, t, y, h);
    if (y[0]! < 0 && n[0]! >= 0 && n[1]! > 0) n[1] = n[1]! + push;
    y = n; t += h; out.push({ t, y });
  }
  return out;
}

export function ModelsScene() {
  const { b2, save, note } = useB2();
  const sh = b2.shelf;
  const step = sh.stepper?.value;
  const m: Method = Array.isArray(step) ? METHODS[step[0] as number] ?? "rk4" : "rk4";
  const h = Array.isArray(step) ? (step[1] as number) : 0.5;
  const [L, setL] = useState(shelfNum(sh.L_pend?.value, 0.994));
  const [beta, setBeta] = useState(0.02);
  const [push, setPush] = useState(shelfNum(sh.A_drive?.value, pushNeeded(0.994, 0.02)));
  const [pop, setPop] = useState<"fish" | "sir">("fish");
  const [H0, setH0] = useState(shelfNum(sh.H_safe?.value, 16));
  const [R0, setR0] = useState(shelfNum(sh.R0?.value, 4));
  const [vax, setVax] = useState(0);
  const allee = shelfNum(sh.allee_A?.value, 0) / shelfNum(sh.K_fish?.value, 1);

  const pend = useMemo(() => pendulumRun(L, beta, push, m), [L, beta, push, m]);
  const amp = Math.max(0.1, ...pend.map(p => Math.abs(p.y[0]!)));
  const wmax = Math.max(0.3, ...pend.map(p => Math.abs(p.y[1]!)));
  const pp = frame(-amp * 1.1, amp * 1.1, -wmax * 1.1, wmax * 1.1, { l: 8, r: 118, t: 22, b: 132 });
  const pt = frame(0, 40, -amp * 1.1, amp * 1.1, { l: 132, r: 352, t: 22, b: 132 });

  const fish = useMemo(() => [10, 30, 60, 100].map(P0 => solve((_t, y) => [y[0]! <= 0 ? 0 : y[0]! * (1 - y[0]! / 100) - H0], [P0], 0, 50, h, m)), [H0, h, m]);
  const sir = useMemo(() => { const D = 7, b = R0 / D, g = 1 / D; return solve((_t, y) => { const i = b * y[0]! * y[1]!; return [-i, i - g * y[1]!, g * y[1]!]; }, [(1 - vax) * 0.999, 0.001, vax * 0.999], 0, 200, Math.min(h, 2), m); }, [R0, vax, h, m]);
  const qp = frame(0, 100, -30, 30, { l: 8, r: 118, t: 172, b: 282 });
  const qt = pop === "fish" ? frame(0, 50, 0, 105, { l: 132, r: 352, t: 172, b: 282 }) : frame(0, 200, 0, 1, { l: 132, r: 352, t: 172, b: 282 });
  const sp = frame(0, 1, 0, 0.5, { l: 8, r: 118, t: 172, b: 282 });

  const saved = sh.L_pend?.value === L && sh.R0?.value === R0 && b2.notebook.some(n => n.id === "de-models");
  const onSave = () => {
    save("L_pend", L, "de-models", { unit: "m", note: "the build's pendulum length" });
    save("R0", R0, "de-models", { note: "the build's outbreak" });
    note({ id: "de-models", track: "de", title: "Two living models", project: "de-models", build: true, data: { L, beta, push, H: H0, R0, vax },
      lines: [`Pendulum: L = ${fx(L, 3)} m, friction ${fx(beta, 3)}, push ${fx(push, 4)} rad/s a cycle.`,
        `Fish: harvest ${fx(H0, 1)} thousand a year on K = 100 thousand${allee > 0 ? `, Allee threshold at ${fx(allee * 100, 0)}% of K` : ""}.`,
        `Outbreak: R₀ = ${fx(R0, 2)}, ${fx(vax * 100, 0)}% vaccinated.`, `Stepped with ${METHOD_NAMES[m]}, h = ${h}.`] });
  };
  const box = (b: { l: number; r: number; t: number; b: number }) => <rect x={b.l} y={b.t} width={b.r - b.l} height={b.b - b.t} rx="8" className="b2bar track" />;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Two living models: a ${fx(L, 3)} m pendulum and a ${pop === "fish" ? "fish stock" : "town's outbreak"}, stepped with ${METHOD_NAMES[m]}.`}>
      <text x="8" y="14" className="b2t trav">pendulum</text>
      {box(pp.box)}
      <path d={path(pend.filter((_, i) => i % 4 === 0).map(p => [pp.X(p.y[0]!), pp.Y(p.y[1]!)] as [number, number]))} className="b2curve trav" style={{ strokeWidth: 1.4 }} />
      <line x1={pt.box.l} y1={pt.Y(0)} x2={pt.box.r} y2={pt.Y(0)} className="b2axis" />
      <path d={path(pend.filter((_, i) => i % 4 === 0).map(p => [pt.X(p.t), pt.Y(p.y[0]!)] as [number, number]))} className="b2curve trav" style={{ strokeWidth: 1.4 }} />
      <text x={pt.box.r} y={pt.box.b + 14} textAnchor="end" className="b2t">40 s</text>
      <text x="8" y="164" className={`b2t ${pop === "fish" ? "sky" : "pink"}`}>{pop === "fish" ? "fish stock" : "outbreak"}</text>
      {box(qp.box)}
      {pop === "fish" ? <>
        <line x1={qp.box.l} y1={qp.Y(0)} x2={qp.box.r} y2={qp.Y(0)} className="b2axis" />
        <path d={path(Array.from({ length: 51 }, (_, k) => [qp.X(2 * k), qp.Y(Math.max(-30, 2 * k * (1 - (2 * k) / 100) - H0))] as [number, number]))} className="b2curve sky" />
        {allee > 0 && <line x1={qt.box.l} y1={qt.Y(allee * 100)} x2={qt.box.r} y2={qt.Y(allee * 100)} className="b2mark amber" />}
        {fish.map((r, i) => <path key={i} d={path(r.map(p => [qt.X(p.t), qt.Y(Math.max(0, p.y[0]!))] as [number, number]))} className="b2curve sky" style={{ strokeWidth: 1.6 }} />)}
        <text x={qt.box.r} y={qt.box.b + 14} textAnchor="end" className="b2t">50 years</text>
      </> : <>
        <path d={path(sir.map(p => [sp.X(p.y[0]!), sp.Y(Math.min(0.5, p.y[1]!))] as [number, number]))} className="b2curve pink" />
        {R0 > 1 && <line x1={sp.X(1 / R0)} y1={sp.box.t} x2={sp.X(1 / R0)} y2={sp.box.b} className="b2mark amber" />}
        {[0, 1, 2].map(j => <path key={j} d={path(sir.map(p => [qt.X(p.t), qt.Y(p.y[j]!)] as [number, number]))} className={`b2curve ${["sky", "pink", "mint"][j]}`} style={{ strokeWidth: 1.6 }} />)}
        <text x={qt.box.r} y={qt.box.b + 14} textAnchor="end" className="b2t">200 days</text>
      </>}
    </svg>
  );
  const have = ["allee_A", "K_fish", "stepper", "H_safe", "A_pend", "L_pend", "A_drive", "R0", "vax_needed"].filter(k => k in sh).length;
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Pendulum length" value={L} min={0.25} max={2} step={0.001} onChange={setL} format={x => `${fx(x, 3)} m`} />
        <Slider label="Friction" value={beta} min={0} max={0.2} step={0.005} onChange={setBeta} format={x => `${fx(x, 3)} per s`} />
        <Slider label="Push each cycle" value={push} min={0} max={0.05} step={0.0005} onChange={setPush} format={x => `${fx(x, 4)} rad/s`} />
        <Toggle label="Population" value={pop} onChange={setPop} options={[{ v: "fish", label: "Fish stock" }, { v: "sir", label: "Outbreak" }]} />
        {pop === "fish" ? <Slider label="Harvest" value={H0} min={0} max={30} step={0.5} onChange={setH0} format={x => `${fx(x, 1)} thousand a year`} />
          : <>
            <Slider label="R₀" value={R0} min={0.5} max={6} step={0.05} onChange={setR0} format={x => fx(x, 2)} />
            <Slider label="Vaccinated" value={vax} min={0} max={0.95} step={0.01} onChange={setVax} format={x => `${fx(x * 100, 0)}%`} />
          </>}
      </>}
      readouts={<>
        <Read label="Stepper" value={`${METHOD_NAMES[m]}, h = ${h}`} />
        <Read label="Period" value={`${fx(2 * Math.PI * Math.sqrt(L / G), 3)} s`} tone="trav" />
        <Read label="Pieces on your shelf" value={`${have} of 9`} />
      </>}
      foot={<SaveRow what={<>Keep the build, <b>Two living models</b>, in your Notebook</>} saved={saved} onSave={onSave} />}
    />
  );
}
