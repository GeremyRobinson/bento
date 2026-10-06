// The burn planner (orbits.md, "New for Development" 4): two circular orbits, a forward (or backward) burn at the
// inner one that stretches the orbit, a second burn half an orbit later, and a Δv ledger that adds them up. The
// Hohmann preset sets both burns exactly. As a project (Geostationary delivery) it adds the propellant fraction with
// your engine's `ve` and saves `dv_hohmann`. A toy planet (μ = 1, r₁ = 1) for b2-or-09's first problems.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { MU_E, R_KM, conicOf, hohmann, propagator, propFraction } from "../maths";
import { Arrow, conicPath, dur, km } from "./parts";

export function BurnScene({ props }: SceneProps) {
  const toy = flag(props, "toy"), quiet = flag(props, "quiet"), project = flag(props, "project");
  const h1 = num(props, "h1", 300);
  const mu = toy ? 1 : MU_E, r1 = toy ? 1 : (R_KM + h1) * 1000, unit = toy ? 1 : 1000;
  const [r2, setR2] = useState(toy ? num(props, "r2", 4) : num(props, "r2", 42164) * 1000);
  const exact = hohmann(mu, r1, r2);
  const preset = flag(props, "hohmann");
  const [dv1, setDv1] = useState(preset ? exact.dv1 / unit : num(props, "dv1", toy ? 0.15 : 1.2));
  const [dv2, setDv2] = useState(preset ? exact.dv2 / unit : 0);
  const { b2, save, note } = useB2();
  // the transfer: from (r₁, 0) moving up at circle speed plus Δv₁; the second burn comes half an orbit later
  const v1 = Math.sqrt(mu / r1) + dv1 * unit;
  const tr = conicOf(mu, r1, 0, 0, v1);
  const bound = tr.e < 1 && tr.near > (toy ? 0.3 : R_KM * 1000);
  const rOpp = tr.p / (1 + tr.e * Math.cos(Math.PI - tr.w));
  const vOpp = bound ? Math.sqrt(mu * (2 / rOpp - 1 / tr.a)) : 0;
  const fin = bound ? conicOf(mu, -rOpp, 0, 0, -(vOpp + dv2 * unit)) : null;
  const coast = bound ? Math.PI * Math.sqrt(tr.a ** 3 / mu) : NaN;
  const total = Math.abs(dv1) + (bound ? Math.abs(dv2) : 0);
  const round = !!fin && fin.e < 0.01 && Math.abs(rOpp - r2) / r2 < 0.01;
  const reach = bound ? rOpp / r2 : Infinity;
  // the ship: coasts the transfer (2.5 s), then rides the new orbit (2.5 s), again and again
  const t = useClock(!quiet, 2.5);
  const pTr = useMemo(() => propagator(mu, r1, 0, 0, v1), [mu, r1, v1]);
  const pFin = useMemo(() => (bound ? propagator(mu, -rOpp, 0, 0, -(vOpp + dv2 * unit)) : null), [bound, mu, rOpp, vOpp, dv2, unit]);
  const ph = t % 5;
  const ship = !bound ? pTr?.pos(ph * 0.4 * Math.sqrt(r1 ** 3 / mu) * 3) : ph < 2.5 ? pTr?.pos((ph / 2.5) * coast) : pFin?.pos(((ph - 2.5) / 2.5) * coast);
  const W = 360, H = 260, cx = 190, cy = 130, s = 112 / r2;
  const Rpx = toy ? 0 : R_KM * 1000 * s;
  const ve = typeof b2.shelf.ve?.value === "number" ? (b2.shelf.ve.value as number) : 4.4145;
  const frac = 100 * propFraction(total, ve);
  const L = (dv: number) => (toy ? 120 : 26) * dv;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={`A transfer from ${toy ? "r = 1" : `${km(r1 / 1000)} km`} toward ${toy ? `r = ${fx(r2, 1)}` : `${km(r2 / 1000)} km`}${quiet ? "" : `: burns of ${fx(dv1, 2)} and ${fx(dv2, 2)}`}.`}>
      {toy ? <circle cx={cx} cy={cy} r="6" className="b2dot" /> : <circle cx={cx} cy={cy} r={Math.max(3, Rpx)} className="b2earth" />}
      <circle cx={cx} cy={cy} r={r1 * s} className="b2orbit" />
      <circle cx={cx} cy={cy} r={r2 * s} className="b2orbit" />
      <path d={conicPath(tr, cx, cy, s, r2 * 2.2)} className="b2curve amber" style={{ strokeWidth: 1.5, opacity: 0.45 }} />
      {fin && <path d={conicPath(fin, cx, cy, s, r2 * 2.2)} className="b2curve sky" style={{ strokeWidth: 2 }} />}
      <Arrow x1={cx + r1 * s} y1={cy} x2={cx + r1 * s} y2={cy - L(dv1)} tone="pink" />
      {bound && !quiet && <Arrow x1={cx - rOpp * s} y1={cy} x2={cx - rOpp * s} y2={cy + L(dv2)} tone="pink" />}
      {bound && <circle cx={cx - rOpp * s} cy={cy} r="4" className="b2dot pink" />}
      {ship && <circle cx={cx + ship.x * s} cy={cy - ship.y * s} r="5" className="b2sat" />}
      <text x={cx + r1 * s + 6} y={cy + 16} className="b2t pink">Δv₁</text>
      {bound && <text x={cx - rOpp * s - 6} y={cy - 8} textAnchor="end" className="b2t pink">Δv₂</text>}
      {!toy && <text x="10" y="20" className="b2t">drawn to scale</text>}
    </svg>
  );
  const vfmt = (x: number) => `${fx(x, 2)}${toy ? "" : " km/s"}`;
  const savedNow = Math.abs(((b2.shelf.dv_hohmann?.value as number) ?? NaN) - total) < 1e-9;
  const onSave = () => {
    save("dv_hohmann", total, "or-geo", { unit: "km/s", note: `two burns from ${km(r1 / 1000)} km to ${km(r2 / 1000)} km` });
    note({ id: "or-geo", track: "or", title: "Geostationary delivery", project: "or-geo", data: { r2: r2 / 1000 },
      lines: [`From ${km(r1 / 1000)} km to ${km(r2 / 1000)} km: Δv₁ ${fx(dv1, 2)} km/s, Δv₂ ${fx(dv2, 2)} km/s, total ${fx(total, 2)} km/s.`,
        `Coast ${dur(coast)}. Propellant with v_e = ${fx(ve, 2)} km/s: ${fx(frac, 1)}% of the ship.`] });
  };
  return (
    <Scene svg={svg}
      controls={!quiet && <>
        <Slider label="First burn Δv₁" value={dv1} min={toy ? -0.3 : -2} max={toy ? 0.42 : 3.2} step={toy ? 0.002 : 0.01} onChange={setDv1} format={vfmt} />
        <Slider label="Second burn Δv₂" value={dv2} min={toy ? -0.3 : -2} max={toy ? 0.4 : 3} step={toy ? 0.002 : 0.01} onChange={setDv2} format={vfmt} disabled={!bound} />
        <Slider label="Outer orbit" value={toy ? r2 : r2 / 1000} min={toy ? 1.5 : 8000} max={toy ? 10 : 60000} step={toy ? 0.5 : 100} onChange={v => setR2(toy ? v : v * 1000)}
          format={v => (toy ? `r = ${fx(v, 1)}` : `${km(v)} km`)} marks={toy ? undefined : [{ v: 26600, label: "GPS" }, { v: 42200, label: "Geo" }]} />
        <button type="button" className="ctl" onClick={() => { setDv1(exact.dv1 / unit); setDv2(exact.dv2 / unit); }}>Hohmann preset</button>
      </>}
      readouts={quiet ? <Read label="From and to" value={toy ? `r = 1 to r = ${fx(r2, 1)}` : `${km(r1 / 1000)} km to ${km(r2 / 1000)} km`} /> : <>
        <Read minor label="Δv₁" value={vfmt(dv1)} tone="pink" />
        <Read minor label="Δv₂" value={bound ? vfmt(dv2) : "none"} tone="pink" />
        <Read label="Ledger total" value={vfmt(total)} big />
        <Read label="Far point" value={!bound ? "escapes" : reach > 0.995 && reach < 1.005 ? "touches the outer orbit" : `${fx(reach * 100, 0)}% of the way`} tone="amber" />
        {bound && <Read minor label="Coast" value={toy ? `${fx(coast, 2)} time units` : dur(coast)} />}
        <Read minor label="New orbit" value={round ? "round, on the outer circle" : fin ? `e = ${fx(fin.e, 3)}` : "none"} tone="sky" />
        {project && <Read label={`Propellant, v_e ${fx(ve, 2)} km/s`} value={`${fx(frac, 1)}%`} />}
      </>}
      foot={project && <SaveRow what={<>Keep <b>dv_hohmann = {fx(total, 2)} km/s</b>{round ? "" : " (not round yet)"} and the plan in your Notebook</>} saved={savedNow} onSave={onSave} />} />
  );
}
