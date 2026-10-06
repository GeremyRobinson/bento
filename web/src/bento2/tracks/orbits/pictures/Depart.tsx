// The departure view (orbits.md, "New for Development" 7): a zoomed planet with its parking orbit and the burn point.
// Leaving Earth: drag the burn and the orbit stretches, then opens into a hyperbola whose far end carries the leftover
// speed v∞. Switch to the Sun's view and the ship is handed over with v∞ added to Earth's own speed (patched conics).
// Arriving at Mars: drag the arrival v∞ and see the capture burn at the low point.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, Toggle, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { MU_E, MU_MARS, MU_SUN, AU, PLANET_AU, R_KM, R_MARS_KM, conicOf, escapeBurn, marsPlan, propagator, vCirc, vEsc } from "../maths";
import { Arrow, conicPath, km } from "./parts";

export function DepartScene({ props }: SceneProps) {
  const mars = str<string>(props, "body", "Earth") === "Mars", quiet = flag(props, "quiet"), keep = flag(props, "keep");
  const mu = mars ? MU_MARS : MU_E, h = num(props, "h", mars ? 400 : 300), R = mars ? R_MARS_KM : R_KM, r = (R + h) * 1000;
  const vc = vCirc(mu, r) / 1000, ve = vEsc(mu, r) / 1000;
  const startVinf = num(props, "vinf", -1);
  const [dv, setDv] = useState(startVinf >= 0 && !mars ? escapeBurn(mu, r, startVinf * 1000) / 1000 : num(props, "dv", 3));
  const [vinfIn, setVinfIn] = useState(startVinf >= 0 ? startVinf : 2.65);
  const [view, setView] = useState<"planet" | "sun">("planet");
  const { b2, save } = useB2();
  // in units of the parking radius and circular speed; the burn is at the bottom of the parking orbit, heading right
  const vAfter = mars ? Math.sqrt(vinfIn ** 2 + ve * ve) : vc + dv;
  const burn = mars ? vAfter - vc : dv;
  const sNorm = vAfter / vc;
  const c = conicOf(1, 0, -1, sNorm, 0);
  const vinf = vAfter > ve ? Math.sqrt(vAfter ** 2 - ve * ve) : 0;
  const open = vAfter >= ve;
  const pr = useMemo(() => propagator(1, 0, -1, sNorm, 0), [sNorm]);
  const t = useClock(true, 1.2);
  const ph = t % 5;
  const shipN = !pr ? null : mars ? (ph < 4 ? pr.pos(-(4 - ph) * 2.2) : { x: Math.cos(-Math.PI / 2 + (ph - 4) * 1.4), y: Math.sin(-Math.PI / 2 + (ph - 4) * 1.4), r: 1 })
    : ph < 1 ? { x: Math.cos(-Math.PI / 2 - (1 - ph) * 1.4), y: Math.sin(-Math.PI / 2 - (1 - ph) * 1.4), r: 1 } : pr.pos((ph - 1) * 2.2);
  const W = 360, H = 260, cx = 92, cy = 168, s = 34;
  // the asymptote: the direction the ship heads (or came from) far away
  const nuInf = open && c.e > 1 ? Math.acos(-1 / c.e) : 0, asym = c.w + (mars ? -1 : 1) * nuInf;
  const farR = 6.4, ax = cx + farR * s * Math.cos(asym + (mars ? 0.06 : -0.06)), ay = cy - farR * s * Math.sin(asym + (mars ? 0.06 : -0.06));
  const ux = Math.cos(asym), uy = -Math.sin(asym), Lv = 13 * vinf;
  const planet = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={`${mars ? "Arriving at Mars" : "Leaving Earth"} from a ${km(h)} km orbit${quiet ? "" : `: a burn of ${fx(burn, 2)} km/s${open ? `, leftover speed ${fx(vinf, 2)} km/s` : ", still bound"}`}.`}>
      <circle cx={cx} cy={cy} r={300} className="b2cancel" style={{ opacity: 0.6 }} />
      <text x={W - 8} y="18" textAnchor="end" className="b2t amber">edge of {mars ? "Mars's" : "Earth's"} pull (not to scale)</text>
      <circle cx={cx} cy={cy} r={(s * R) / (R + h)} className="b2earth" />
      <circle cx={cx} cy={cy} r={s} className="b2orbit" />
      {(!quiet || mars) && <path d={conicPath(c, cx, cy, s, 9, open ? (mars ? "in" : "out") : "all")} className={`b2curve ${open ? "pink" : "amber"}`} />}
      {open && !quiet && <Arrow x1={ax} y1={ay} x2={ax + ux * Lv * (mars ? -1 : 1)} y2={ay + uy * Lv * (mars ? -1 : 1)} tone="pink" />}
      {open && !quiet && <text x={ax + ux * Lv * (mars ? -1 : 1) + 6} y={ay + uy * Lv * (mars ? -1 : 1) + (mars ? 16 : -6)} className="b2t pink">v∞ {fx(vinf, 2)}</text>}
      <Arrow x1={cx} y1={cy + s} x2={cx + (mars ? -1 : 1) * Math.max(8, 14 * burn)} y2={cy + s} tone="amber" />
      <text x={cx} y={cy + s + 18} textAnchor="middle" className="b2t amber">{mars ? "capture burn" : "burn"}</text>
      {shipN && shipN.r < 9 && <circle cx={cx + shipN.x * s} cy={cy - shipN.y * s} r="4.5" className="b2sat" />}
      <text x="10" y={H - 8} className="b2t">{mars ? "Mars" : "Earth"}, parking orbit {km(h)} km up</text>
    </svg>
  );
  // the Sun's frame: the ship leaves 1 AU at Earth's speed plus v∞, on the ellipse that v∞ buys
  const vE = vCirc(MU_SUN, AU) / 1000;
  const sun = conicOf(1, 1, 0, 0, (vE + vinf) / vE);
  const S = 70, scx = 180, scy = 128;
  const sunSvg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`In the Sun's frame the ship leaves at ${fx(vE + vinf, 2)} kilometers per second and reaches out to ${Number.isFinite(sun.far) ? fx(sun.far, 3) : "beyond"} AU.`}>
      <circle cx={scx} cy={scy} r="8" className="b2dot amber" />
      <circle cx={scx} cy={scy} r={S} className="b2orbit" />
      <circle cx={scx} cy={scy} r={S * PLANET_AU.Mars} className="b2orbit" />
      <path d={conicPath(sun, scx, scy, S, 3)} className="b2curve pink" />
      <circle cx={scx + S} cy={scy} r="5" className="b2dot sky" />
      <text x={scx + S + 8} y={scy + 16} className="b2t sky">Earth</text>
      <text x={scx - S * PLANET_AU.Mars + 4} y={scy - 8} className="b2t">Mars's orbit</text>
      <Arrow x1={scx + S} y1={scy} x2={scx + S} y2={scy - 18 - 8 * vinf} tone="pink" />
    </svg>
  );
  const plan = marsPlan(300, 400, 450);
  const saved = Math.abs(((b2.shelf.dv_depart?.value as number) ?? NaN) - plan.dep) < 1e-9 && Math.abs(((b2.shelf.dv_capture?.value as number) ?? NaN) - plan.cap) < 1e-9;
  return (
    <Scene svg={view === "sun" && !mars ? sunSvg : planet}
      controls={<>
        {mars
          ? <Slider label="Arriving with v∞" value={vinfIn} min={0} max={5} step={0.01} onChange={setVinfIn} format={x => `${fx(x, 2)} km/s`} marks={[{ v: 2.65, label: "From the transfer" }]} />
          : <Slider label="Burn Δv" value={dv} min={0} max={6} step={0.01} onChange={setDv} format={x => `${fx(x, 2)} km/s`} marks={[{ v: Math.round((ve - vc) * 100) / 100, label: "Just escapes" }]} />}
        {!mars && <Toggle label="View" value={view} onChange={setView} options={[{ v: "planet", label: "Earth's view" }, { v: "sun", label: "Sun's view" }]} />}
      </>}
      readouts={<>
        <Read label={mars ? "Capture burn" : "Burn"} value={quiet && mars ? "?" : `${fx(burn, 2)} km/s`} tone="amber" big={!quiet} />
        {!quiet && <Read label="Speed after" value={`${fx(vAfter, 2)} km/s`} />}
        {!quiet && <Read label="Escape speed here" value={`${fx(ve, 2)} km/s`} />}
        {!quiet && <Read label="Circle speed here" value={`${fx(vc, 2)} km/s`} />}
        {!quiet && <Read label="Leftover v∞" value={open ? `${fx(vinf, 2)} km/s` : "none: still bound"} tone="pink" />}
        {!quiet && view === "sun" && !mars && <Read label="Reaches out to" value={Number.isFinite(sun.far) ? `${fx(sun.far, 3)} AU` : "escapes the Sun"} />}
      </>}
      foot={keep && <SaveRow what={<>Keep <b>dv_depart = {fx(plan.dep, 2)} km/s</b> and <b>dv_capture = {fx(plan.cap, 2)} km/s</b></>} saved={saved}
        onSave={() => { save("dv_depart", plan.dep, "b2-or-11", { unit: "km/s", note: "departure burn from 300 km onto the Mars transfer" }); save("dv_capture", plan.cap, "b2-or-11", { unit: "km/s", note: "capture burn into a 400 km orbit at Mars" }); }} />} />
  );
}
