// The GPS checker, the track's build (relativity.md): an orbit-radius slider from 1 to 7 Earth radii with presets
// (space station, GPS, Galileo, geostationary); two bars, speed (−) and height (+), and their net in μs per day; a map
// where "you are here" drifts by the map error as hours pass; the cancel radius 1.5 R⊕ marked; and the factory
// frequency 10.23 MHz × (1 − net fraction). It reads the build's earlier pieces from the Number shelf.
// Also here: Clocks that travel (project after b2-re-09).
import { useRef, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, useClock, useFollowProp } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { R_E } from "../../../constants";
import { CANCEL_KM, factoryMHz, gravityGainUs, lossPerDayUs, mapErrorKm, netDriftUs, speedLossUs } from "../physics";

const R_KM = R_E / 1000;
const PRESETS = [{ v: 6771 / R_KM, label: "Station" }, { v: 26571 / R_KM, label: "GPS" }, { v: 29600 / R_KM, label: "Galileo" }, { v: 42164 / R_KM, label: "Geo" }];

export function GpsScene({ props, marker }: SceneProps) {
  const [r, setR] = useState(num(props, "r", 26571 / R_KM));
  // a Guess reveal moves the orbit: it slides there rather than the picture starting over
  useFollowProp(props, num(props, "r", 26571 / R_KM), r, setR);
  const [hours, setHours] = useState(24);
  const hide = flag(props, "hide"), quiet = flag(props, "quiet"), project = flag(props, "project");
  const { b2, save, note } = useB2();
  const t = useClock(true, 0.8);
  const rk = r * R_KM, loss = speedLossUs(rk), gain = gravityGainUs(rk), net = netDriftUs(rk);
  const map = mapErrorKm(Math.abs(net)) * (hours / 24);
  // Earth is drawn small enough that the widest orbit (7 R⊕) stays clear of the bars and inside the left edge
  const W = 360, H = 250, ex = 94, ey = 122, eR = 12.8;
  // the satellite goes round (far faster than real), higher orbits slower, as Kepler says; the angle is summed
  // frame by frame so it carries on smoothly while the radius changes
  const spin = useRef({ t, ang: t * 1.6 * r ** -1.5 });
  if (t !== spin.current.t) spin.current = { t, ang: spin.current.ang + (t - spin.current.t) * 1.6 * r ** -1.5 };
  const ang = spin.current.ang;
  // three bars 62 apart, so "speed" and "height" stay clear of each other on a phone's larger labels
  const bx = 203, gap = 62, zero = 128, perUs = 1.5;
  const bar = (x: number, us: number, cls: string, label: string, show: boolean) => {
    const h = Math.abs(us) * perUs, y = us >= 0 ? zero - h : zero;
    return (
      <g>
        <rect x={x} y={y} width="22" height={Math.max(1, h)} rx="4" className={`b2bar ${cls}`} />
        <text x={x + 11} y={us >= 0 ? y - 6 : y + h + 15} textAnchor="middle" className={`b2t ${cls}`}>{show ? `${us >= 0 ? "+" : "−"}${fx(Math.abs(us), 1)}` : "?"}</text>
        <text x={x + 11} y={H - 6} textAnchor="middle" className="b2t">{label}</text>
      </g>
    );
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic gps" role="img" aria-label={`A satellite at ${Math.round(rk)} km from Earth's center. Speed costs ${fx(loss, 1)} microseconds a day, height gains ${fx(gain, 1)}${hide ? "" : `, net ${fx(net, 1)}`}.`}>
      <circle cx={ex} cy={ey} r={eR} className="b2earth" />
      {!hide && <circle cx={ex} cy={ey} r={eR * 1.5} className="b2cancel" />}
      {marker && <circle cx={ex} cy={ey} r={eR * marker[0]} className="b2mark guess round" />}
      <circle cx={ex} cy={ey} r={eR * r} className="b2orbit" />
      <circle cx={ex + eR * r * Math.cos(ang)} cy={ey + eR * r * Math.sin(ang)} r="6" className="b2sat" />
      {!hide && <text x={ex} y={ey - eR * 1.5 - 5} textAnchor="middle" className="b2t amber">cancel</text>}
      <line x1={bx - 10} y1={zero} x2={W - 6} y2={zero} className="b2axis" />
      {bar(bx, -loss, "pink", "speed", true)}
      {bar(bx + gap, gain, "sky", "height", true)}
      {bar(bx + 2 * gap, net, "amber", "net", !hide)}
      <text x={bx - 10} y="16" className="b2t">μs a day</text>
    </svg>
  );
  const shelfSr = b2.shelf.sr_drift?.value, shelfGr = b2.shelf.gr_drift?.value;
  const savedNet = Math.abs(((b2.shelf.gps_net?.value as number) ?? NaN) - net) < 1e-9;
  const onSave = () => {
    save("gps_net", net, "re-gps", { unit: "μs per day", note: `net drift at r = ${Math.round(rk).toLocaleString("en-US")} km` });
    if (shelfGr === undefined) save("gr_drift", gain, "re-gps", { unit: "μs per day", note: `height gain at r = ${Math.round(rk).toLocaleString("en-US")} km` });
    note({ id: "re-gps", track: "re", title: "The build: GPS checker", project: "re-gps", build: true, data: { r },
      lines: [`r = ${Math.round(rk).toLocaleString("en-US")} km: speed −${fx(loss, 1)} μs, height +${fx(gain, 1)} μs, net ${fx(net, 1)} μs a day.`,
        `Map error after a day: ${fx(mapErrorKm(Math.abs(net)), 1)} km. The effects cancel at ${Math.round(CANCEL_KM).toLocaleString("en-US")} km.`,
        `Factory frequency: ${factoryMHz(net).toFixed(10)} MHz.`] });
  };
  // the map: you stand still, and the fix drifts away from you as the hours pass
  // the map strip and the factory frequency belong to the build (the project); a lesson keeps to the drift itself
  const mapStrip = project && !quiet && !hide && (
    <div className="b2map">
      <svg viewBox="0 0 340 44" className="b2pic" role="img" aria-label={`After ${hours} hours your map would be ${fx(map, 1)} km off.`}>
        <line x1="10" y1="22" x2="330" y2="22" className="b2grid strong" />
        <circle cx="20" cy="22" r="6" className="b2dot pink" />
        <circle cx={20 + Math.min(300, (map / 12) * 300)} cy="22" r="6" className="b2dot amber" />
        <text x="20" y="40" className="b2t">you</text>
        {/* the label reads from the fix's dot toward the open side, so it never runs off the left near no drift */}
        {(() => { const fx0 = 20 + Math.min(300, (map / 12) * 300), left = fx0 < 170;
          return <text x={left ? Math.max(6, fx0 - 6) : fx0 + 6} y="14" textAnchor={left ? "start" : "end"} className="b2t amber">the map says you're here</text>; })()}
      </svg>
      <Slider label="Hours without the fix" value={hours} min={0} max={24} step={1} onChange={setHours} format={h => `${h} h`} />
    </div>
  );
  return (
    <Scene className="gpsscene" svg={svg}
      controls={<Slider label="Orbit radius" value={r} min={1.02} max={7} step={0.005} onChange={setR} format={x => `${Math.round(x * R_KM).toLocaleString("en-US")} km`} marks={PRESETS} />}
      readouts={<>
        <Read label="Speed" value={`−${fx(loss, 1)} μs`} tone="pink" />
        <Read label="Height" value={`+${fx(gain, 1)} μs`} tone="sky" />
        {!hide && !quiet && <Read label="Net a day" value={`${net >= 0 ? "+" : "−"}${fx(Math.abs(net), 1)} μs, ${net >= 0 ? "ahead" : "behind"}`} tone="amber" big />}
        {!hide && !quiet && <Read label={`Map error after ${hours} h`} value={`${fx(map, 1)} km`} />}
        {project && !hide && !quiet && <Read label="Factory frequency" value={`${factoryMHz(net).toFixed(9)} MHz`} />}
        {project && typeof shelfSr === "number" && <Read label="sr_drift, your shelf" value={`${fx(shelfSr, 1)} μs`} tone="pink" />}
        {project && typeof shelfGr === "number" && <Read label="gr_drift, your shelf" value={`+${fx(shelfGr, 1)} μs`} tone="sky" />}
      </>}
      foot={<>
        {mapStrip}
        {project && <SaveRow what={<>Keep <b>gps_net = {net >= 0 ? "+" : "−"}{fx(Math.abs(net), 1)} μs a day</b> and the checker in your Notebook</>} saved={savedNet} onSave={onSave} />}
      </>}
    />
  );
}

const TRAVELERS = [
  { id: "air", name: "Airliner", v: 0.25, ns: true },
  { id: "iss", name: "Space station", v: 7.67, ns: false },
  { id: "gps", name: "GPS satellite", v: 3.873, ns: false },
];

GpsScene.liveReveal = true;

export function ClocksScene({ props }: SceneProps) {
  const [days, setDays] = useState(30);
  const project = flag(props, "project");
  const { b2, save, note } = useB2();
  const sr = -lossPerDayUs(3.873);
  const saved = Math.abs(((b2.shelf.sr_drift?.value as number) ?? NaN) - sr) < 1e-9;
  const onSave = () => {
    save("sr_drift", sr, "re-clocks", { unit: "μs per day", note: "a GPS clock's loss from speed alone" });
    note({ id: "re-clocks", track: "re", title: "Clocks that travel", project: "re-clocks", data: { days },
      lines: TRAVELERS.map(c => `${c.name} at ${c.v} km/s: ${c.ns ? `${fx(lossPerDayUs(c.v) * 1000, 1)} ns` : `${fx(lossPerDayUs(c.v), 1)} μs`} behind a day.`) });
  };
  const most = lossPerDayUs(7.67) * days;
  const svg = (
    <svg viewBox="0 0 360 230" className="b2pic clocks" role="img" aria-label={`Three clocks after ${days} days: each falls behind a ground clock by an amount that grows with the square of its speed.`}>
      {TRAVELERS.map((c, i) => {
        const lag = lossPerDayUs(c.v) * days, y = 38 + i * 72, w = Math.max(2, (lag / most) * 200);
        return (
          <g key={c.id}>
            <text x="12" y={y} className="b2t">{c.name}, {c.v} km/s</text>
            <rect x="12" y={y + 8} width="200" height="16" rx="6" className="b2bar track" />
            {/* one colour for one meaning: pink is time lost to speed, as on the GPS checker's speed bar */}
            <rect x={212 - w} y={y + 8} width={w} height="16" rx="6" className="b2bar pink" />
            <text x="222" y={y + 21} className="b2t">−{c.ns ? `${fx(lag * 1000, 1)} ns` : lag >= 1000 ? `${fx(lag / 1000, 2)} ms` : `${fx(lag, 1)} μs`}</text>
          </g>
        );
      })}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Days in flight" value={days} min={1} max={365} step={1} onChange={setDays} format={d => `${d} ${d === 1 ? "day" : "days"}`} />}
      readouts={<>{TRAVELERS.map(c => <Read key={c.id} label={`${c.name}, a day`} value={c.ns ? `${fx(lossPerDayUs(c.v) * 1000, 1)} ns` : `${fx(lossPerDayUs(c.v), 1)} μs`} />)}</>}
      foot={project ? <SaveRow what={<>Keep <b>sr_drift = −{fx(-sr, 1)} μs a day</b> for the GPS build</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
