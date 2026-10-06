// The mission card, the track's build (orbits.md, "New for Development" 8): the whole Earth-to-Mars Hohmann trip on
// one screen, recomputed live from the parking altitude, the Mars orbit altitude and the engine. Earth and Mars on
// their circles with Mars's lead at launch; Launch flies the ship 259 days to meet Mars. Saves `mission` and the
// Notebook entry marked as the build. It shows which build pieces are already on the Number shelf.
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, Toggle, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { trackByCode } from "../../../registry";
import { PLANET_AU, marsPlan, windowTo } from "../maths";
import { km } from "./parts";

const ENGINES = ["300", "350", "380", "450"] as const;
type Engine = (typeof ENGINES)[number];

export function CardScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), project = flag(props, "project");
  const [h1, setH1] = useState(num(props, "h1", 300));
  const [h2, setH2] = useState(num(props, "h2", 400));
  const [isp, setIsp] = useState<Engine>((ENGINES.find(e => Number(e) === num(props, "isp", 450)) ?? "450"));
  const [fly, setFly] = useState(false);
  const { b2, save, note } = useB2();
  const m = marsPlan(h1, h2, Number(isp)), w = windowTo(PLANET_AU.Mars);
  const t = useClock(fly, 0);
  const k = fly ? Math.min(1, t / 5) : 0;
  const W = 360, H = 250, cx = 196, cy = 128, s = 72;
  const at = (1 + PLANET_AU.Mars) / 2, e = (PLANET_AU.Mars - 1) / (PLANET_AU.Mars + 1), b = at * Math.sqrt(1 - e * e);
  // Earth at the bottom at launch; the transfer runs half an ellipse to the top, where Mars arrives
  const deg = (d: number) => (d * Math.PI) / 180;
  const pos = (d: number, r: number): [number, number] => [cx + r * s * Math.cos(deg(d)), cy - r * s * Math.sin(deg(d))];
  const e0 = -90, eNow = e0 + (360 * k * m.days) / 365.25, mNow = e0 + m.phi + (360 * k * m.days) / (w.T2 * 365.25);
  // the ellipse with the Sun at a focus: near point at Earth (bottom), far point at the top
  const ell = (E: number): [number, number] => { const x = at * Math.cos(E) - at * e, y = b * Math.sin(E); return [cx + y * s, cy + x * s]; };
  const half: [number, number][] = [], full: [number, number][] = [];
  for (let j = 0; j <= 80; j++) full.push(ell((j / 80) * 2 * Math.PI));
  // fly along by Kepler's equation, so the ship slows as it climbs
  const Mk = Math.PI * k;
  let E = Mk;
  for (let j = 0; j < 30; j++) E -= (E - e * Math.sin(E) - Mk) / (1 - e * Math.cos(E));
  for (let j = 0; j <= 60; j++) half.push(ell((j / 60) * E));
  const ship = ell(E);
  const [ex, ey] = pos(eNow, 1), [mx, my] = pos(mNow, PLANET_AU.Mars);
  const arcPts: [number, number][] = [];
  for (let j = 0; j <= 24; j++) arcPts.push(pos(e0 + (m.phi * j) / 24, 0.42));
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={`The Mars plan: launch with Mars ${fx(m.phi, 0)} degrees ahead, fly ${km(m.days)} days${quiet ? "" : `, total delta v ${fx(m.total, 2)} km/s`}.`}>
      <circle cx={cx} cy={cy} r="8" className="b2dot amber" />
      <circle cx={cx} cy={cy} r={s} className="b2orbit" />
      <circle cx={cx} cy={cy} r={s * PLANET_AU.Mars} className="b2orbit" />
      <path d={path(full)} className="b2curve" style={{ strokeWidth: 1, opacity: 0.3 }} />
      {fly && <path d={path(half)} className="b2curve sky" style={{ strokeWidth: 2 }} />}
      {!fly && <><path d={path(arcPts)} className="b2curve amber" style={{ strokeWidth: 1.5 }} />
        <line x1={cx} y1={cy} x2={pos(e0, 1)[0]} y2={pos(e0, 1)[1]} className="b2grid strong" />
        <line x1={cx} y1={cy} x2={pos(e0 + m.phi, PLANET_AU.Mars)[0]} y2={pos(e0 + m.phi, PLANET_AU.Mars)[1]} className="b2grid strong" />
        <text x={pos(e0 + m.phi / 2, 0.55)[0]} y={pos(e0 + m.phi / 2, 0.55)[1] + 4} textAnchor="middle" className="b2t amber">{fx(m.phi, 0)}°</text></>}
      <circle cx={ex} cy={ey} r="6" className="b2dot sky" />
      <text x={ex + 9} y={ey + 14} className="b2t sky">Earth</text>
      <circle cx={mx} cy={my} r="6" className="b2dot pink" />
      <text x={mx + 9} y={my + 4} className="b2t pink">Mars</text>
      {fly && <circle cx={ship[0]} cy={ship[1]} r="4.5" className="b2sat" />}
      <text x="10" y="20" className="b2t">{fly ? `day ${km(k * m.days)} of ${km(m.days)}` : "at launch"}</text>
    </svg>
  );
  const track = trackByCode("or");
  const pieces = track ? track.buildPieces.filter(p => p in b2.shelf).length : 0, of = track?.buildPieces.length ?? 0;
  const value = [m.dep, m.cap, m.total, m.frac, m.days, m.phi];
  const cur = b2.shelf.mission?.value;
  const saved = Array.isArray(cur) && cur.length === value.length && value.every((v, i) => Math.abs(((cur as number[])[i] ?? NaN) - v) < 1e-9);
  const onSave = () => {
    save("mission", value, "or-mission", { labels: ["departure km/s", "capture km/s", "total km/s", "propellant %", "flight days", "Mars lead °"], note: `Mars plan: ${h1} km, ${h2} km, I_sp ${isp} s` });
    note({ id: "or-mission", track: "or", title: "The build: the Mars mission card", project: "or-mission", build: true, data: { h1, h2, isp: Number(isp) },
      lines: [`Parking orbit ${km(h1)} km up (${fx(m.vLEO, 2)} km/s). Launch with Mars ${fx(m.phi, 0)}° ahead; windows every ${km(w.S * 365.25)} days.`,
        `Departure burn ${fx(m.dep, 2)} km/s (v∞ ${fx(m.vinf1, 2)}), coast ${km(m.days)} days, capture ${fx(m.cap, 2)} km/s (v∞ ${fx(m.vinf2, 2)}) into ${km(h2)} km.`,
        `Total ${fx(m.total, 2)} km/s. With I_sp ${isp} s, ${fx(m.frac, 1)}% of the ship is propellant.`] });
  };
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Parking orbit" value={h1} min={150} max={1000} step={10} onChange={setH1} format={x => `${km(x)} km up`} />
        <Slider label="Mars orbit" value={h2} min={150} max={2000} step={10} onChange={setH2} format={x => `${km(x)} km up`} />
        <Toggle label="Engine" value={isp} onChange={setIsp} options={ENGINES.map(e => ({ v: e, label: `${e} s` }))} />
        <button type="button" className="ctl go" onClick={() => setFly(f => !f)}>{fly ? "Back to launch" : "Launch"}</button>
      </>}
      readouts={<>
        <Read label="Window" value={`Mars ${fx(m.phi, 0)}° ahead, every ${km(w.S * 365.25)} days`} tone="amber" />
        <Read label="Flight" value={`${km(m.days)} days`} />
        {!quiet && <Read label="Leave Earth" value={`${fx(m.dep, 2)} km/s (v∞ ${fx(m.vinf1, 2)})`} tone="sky" />}
        {!quiet && <Read label="Stay at Mars" value={`${fx(m.cap, 2)} km/s (v∞ ${fx(m.vinf2, 2)})`} tone="pink" />}
        {!quiet && <Read label="Total Δv" value={`${fx(m.total, 2)} km/s`} big />}
        {!quiet && <Read label="Propellant" value={`${fx(m.frac, 1)}% of the ship`} />}
        {project && <Read label="Build pieces on your shelf" value={`${pieces} of ${of}`} />}
      </>}
      foot={project && <SaveRow what={<>Keep <b>mission</b>: {fx(m.total, 2)} km/s, {fx(m.frac, 1)}% propellant, in your Notebook as the build</>} saved={saved} onSave={onSave} />} />
  );
}
