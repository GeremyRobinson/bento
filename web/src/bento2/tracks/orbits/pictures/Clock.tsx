// The mission clock (orbits.md, "New for Development" 5): Earth and a target planet circle the Sun (circles in one
// plane). Drag the launch date: the phase dial shows the angle from Earth to the target, with the angle a Hohmann
// transfer needs, a countdown to the next window and the synodic period. Launch flies a ghost ship on the transfer,
// stepped by symplectic Euler at your shelf's `h_step` (7 hours if it isn't there yet), while the target moves on.
import { useMemo, useState } from "react";
import { flag, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { MU_AU, PLANET_AU, step, windowTo, type State } from "../maths";
import { km } from "./parts";

type Target = "Venus" | "Mars" | "Jupiter" | "Saturn";
const TARGETS: Target[] = ["Venus", "Mars", "Jupiter", "Saturn"];
/** where each target starts, degrees ahead of Earth on day 0 */
const START: Record<Target, number> = { Venus: -20, Mars: 120, Jupiter: 160, Saturn: 40 };
const wrap = (d: number) => ((((d + 180) % 360) + 360) % 360) - 180;

export function ClockScene({ props, marker }: SceneProps) {
  const hide = flag(props, "hide"), quiet = flag(props, "quiet"), flyProp = flag(props, "fly");
  const [target, setTarget] = useState<Target>(str(props, "target", "Mars") as Target);
  const r2 = PLANET_AU[target], w = windowTo(r2);
  const [day, setDay] = useState(0);
  const [launch, setLaunch] = useState<number | null>(null);
  const { b2 } = useB2();
  const hHours = typeof b2.shelf.h_step?.value === "number" ? (b2.shelf.h_step.value as number) : 7;
  // the guess and its reveal fix the launch at the moment the target leads by the right angle (or by the guess)
  const fixed = hide || flyProp;
  const lead0 = fixed ? (hide && marker ? marker[0] : w.phi) : START[target];
  const earthAt = (d: number) => (fixed ? -90 : 0) + (360 * d) / 365.25;
  const targetAt = (d: number) => (fixed ? -90 : 0) + lead0 + (360 * d) / (w.T2 * 365.25);
  const phase = wrap(targetAt(day) - earthAt(day));
  // days until the phase next equals the transfer's lead: the phase changes at 360(1/T₂ − 1) degrees a year
  const rate = 360 * (1 / w.T2 - 1) / 365.25;
  const wait = (() => { const gap = wrap(w.phi - phase); const d = gap / rate; return d >= -0.5 ? d : d + Math.abs((360 / rate)); })();
  // the ship's flight, stepped by symplectic Euler in AU and years from Earth's position at launch
  const ship = useMemo(() => {
    const h = hHours / 24 / 365.25, out: [number, number][] = [];
    const s0: State = { x: 1, y: 0, vx: 0, vy: Math.sqrt(MU_AU * (2 - 1 / w.at)) };
    let s = s0;
    for (let t = 0; t <= w.t + 1e-9; t += h) { out.push([s.x, s.y]); s = step(s, h, MU_AU, "symplectic"); }
    return out;
  }, [hHours, w.at, w.t, r2]);
  const flying = flyProp || launch !== null;
  const t = useClock(flying, 99);
  const k = flying ? Math.min(1, t / 4.5) : 0;
  const L = flyProp ? 0 : launch ?? day;
  const flown = k * w.days;
  const dNow = flying ? L + flown : day;
  const W = 360, H = 260, cx = 214, cy = 130, s = 112 / Math.max(1, r2);
  const pos = (deg: number, r: number): [number, number] => [cx + r * s * Math.cos((deg * Math.PI) / 180), cy - r * s * Math.sin((deg * Math.PI) / 180)];
  const eA = earthAt(dNow), tA = targetAt(dNow), e0 = earthAt(L);
  const rot = (p: [number, number]): [number, number] => { const a = (e0 * Math.PI) / 180; return [cx + s * (p[0] * Math.cos(a) - p[1] * Math.sin(a)), cy - s * (p[0] * Math.sin(a) + p[1] * Math.cos(a))]; };
  const flownPts = ship.slice(0, Math.max(1, Math.round(k * (ship.length - 1)) + 1)).map(rot);
  const shipAt = flownPts[flownPts.length - 1]!;
  const arrive = targetAt(L + w.days), meetAngle = e0 + 180, miss = Math.abs(wrap(arrive - meetAngle));
  const [ex, ey] = pos(eA, 1), [tx, ty] = pos(tA, r2);
  // the phase dial: the needle is the angle from Earth to the target; the tick is the transfer's lead
  const D = { x: 40, y: 44, r: 28 };
  const needle = (deg: number) => [D.x + D.r * Math.cos(((90 - deg) * Math.PI) / 180), D.y - D.r * Math.sin(((90 - deg) * Math.PI) / 180)];
  const [nx, ny] = needle(phase), [qx, qy] = needle(w.phi);
  const ghost = hide && marker ? pos(earthAt(0) + marker[0], r2) : null;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={`Earth and ${target} around the Sun. ${hide ? "" : `${target} is ${fx(Math.abs(phase), 0)} degrees ${phase >= 0 ? "ahead of" : "behind"} Earth.`}`}>
      <circle cx={cx} cy={cy} r="8" className="b2dot amber" />
      <circle cx={cx} cy={cy} r={s} className="b2orbit" />
      <circle cx={cx} cy={cy} r={r2 * s} className="b2orbit" />
      {(flying || hide) && <path d={path(ship.map(rot))} className="b2curve" style={{ strokeWidth: 1, opacity: 0.35 }} />}
      {flying && <path d={path(flownPts)} className="b2curve sky" style={{ strokeWidth: 1.5 }} />}
      {flying && <circle cx={shipAt[0]} cy={shipAt[1]} r="4" className="b2sat" />}
      <circle cx={ex} cy={ey} r="6" className="b2dot sky" />
      <text x={ex + 9} y={ey + 4} className="b2t sky">Earth</text>
      {!hide && <><circle cx={tx} cy={ty} r="6" className="b2dot pink" /><text x={tx + 9} y={ty + 4} className="b2t pink">{target}</text></>}
      {ghost && <><circle cx={ghost[0]} cy={ghost[1]} r="8" className="b2mark guess round" /><text x={ghost[0] + 11} y={ghost[1] - 6} className="b2t">your {target}</text></>}
      {!hide && <g>
        <circle cx={D.x} cy={D.y} r={D.r} className="b2orbit" />
        <line x1={D.x} y1={D.y} x2={qx} y2={qy} className="b2mark amber" />
        <line x1={D.x} y1={D.y} x2={nx} y2={ny} className="b2leg pink" style={{ strokeWidth: 2 }} />
        <text x={D.x} y={D.y + D.r + 16} textAnchor="middle" className="b2t">phase</text>
      </g>}
    </svg>
  );
  const shown = !hide && !quiet;
  return (
    <Scene svg={svg}
      controls={!fixed && <>
        <Slider label="Launch date" value={day} min={0} max={Math.round(2.2 * w.S * 365.25)} step={1} onChange={d => { setLaunch(null); setDay(d); }} format={d => `day ${km(d)}`} />
        <Toggle label="Target" value={target} onChange={v => { setTarget(v); setLaunch(null); setDay(0); }} options={TARGETS.map(x => ({ v: x, label: x }))} />
        <button type="button" className="ctl go" onClick={() => setLaunch(day)}>Launch</button>
      </>}
      readouts={<>
        {!hide && <Read label={`${target} from Earth`} value={`${fx(Math.abs(phase), 0)}° ${phase >= 0 ? "ahead" : "behind"}`} tone="pink" big />}
        {shown && <Read label="Transfer needs" value={`${fx(Math.abs(w.phi), 0)}° ${w.phi >= 0 ? "ahead" : "behind"}`} tone="amber" />}
        {shown && !flying && <Read label="Next window" value={wait < 0.5 ? "now" : `in ${km(wait)} days`} />}
        {shown && <Read label="Windows every" value={`${km(w.S * 365.25)} days`} />}
        {!hide && <Read label="Flight" value={`${km(w.days)} days${flying ? `, day ${km(flown)}` : ""}`} tone="sky" />}
        {flying && k >= 1 && <Read label="At arrival" value={miss < 3 ? `meets ${target}` : `${target} is ${fx(miss, 0)}° away`} />}
        {!hide && <Read label="Stepper" value={`symplectic Euler, h = ${hHours} h`} />}
      </>} />
  );
}
