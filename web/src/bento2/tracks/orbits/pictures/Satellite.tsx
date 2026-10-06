// Pick a satellite (project after b2-or-03): choose a job and an altitude; the card gives the radius, speed and period
// and checks the job. Earth turns underneath at its real rate against the satellite, so a geostationary satellite
// stays over its spot. Saves `r_sat`, `v_sat` and `T_sat`.
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, Toggle, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { MU_E, R_KM, SIDEREAL_DAY, period, vCirc } from "../maths";
import { dur, km } from "./parts";

type Job = "station" | "gps" | "weather";
const JOBS: { v: Job; label: string }[] = [{ v: "station", label: "Space station" }, { v: "gps", label: "GPS" }, { v: "weather", label: "Weather, over one spot" }];
const LO = 160, HI = 50000;
const toH = (u: number) => LO * (HI / LO) ** u;
const toU = (h: number) => Math.log(h / LO) / Math.log(HI / LO);

function check(job: Job, h: number, T: number): { ok: boolean; text: string } {
  if (job === "station") return h >= 300 && h <= 500
    ? { ok: true, text: "Fits: low enough for crews to reach, high enough to stay up for years with small boosts." }
    : { ok: false, text: h < 300 ? "Too low: the thin air up there would pull it down within weeks." : "Stations sit 300 to 500 km up, where crews can reach them cheaply." };
  if (job === "gps") return Math.abs(T / (SIDEREAL_DAY / 2) - 1) < 0.01
    ? { ok: true, text: "Fits: two laps every sidereal day, so the pattern over the ground repeats daily." }
    : { ok: false, text: `GPS satellites make two laps a sidereal day (${km(SIDEREAL_DAY / 2)} s). This one takes ${km(T)} s.` };
  return Math.abs(T / SIDEREAL_DAY - 1) < 0.003
    ? { ok: true, text: "Fits: one lap per sidereal day, so it hovers over one spot on the equator." }
    : { ok: false, text: `To hover, the period must be one sidereal day, ${km(SIDEREAL_DAY)} s. This one takes ${km(T)} s.` };
}

export function SatelliteScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), project = flag(props, "project");
  const [job, setJob] = useState<Job>(JOBS[num(props, "job", 2)]?.v ?? "weather");
  const [u, setU] = useState(toU(num(props, "h", 400)));
  const { b2, save, note } = useB2();
  const h = toH(u), r = R_KM + h, v = vCirc(MU_E, r * 1000) / 1000, T = period(MU_E, r * 1000);
  // time runs one sidereal day every 8 seconds: Earth turns once, the satellite laps SIDEREAL_DAY / T times
  const t = useClock(true, 0.9), day = t / 8;
  const W = 360, H = 250, cx = 180, cy = 125, s = 108 / r;
  const earthTurn = 2 * Math.PI * day, satAng = 2 * Math.PI * day * (SIDEREAL_DAY / T);
  const res = check(job, h, T);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A satellite ${km(h)} km up${quiet ? "" : `, moving at ${fx(v, 2)} kilometers per second, one lap every ${dur(T)}`}.`}>
      <circle cx={cx} cy={cy} r={R_KM * s} className="b2earth" />
      <line x1={cx} y1={cy} x2={cx + R_KM * s * Math.cos(earthTurn)} y2={cy - R_KM * s * Math.sin(earthTurn)} className="b2leg sky" style={{ strokeWidth: 2 }} />
      <circle cx={cx + R_KM * s * Math.cos(earthTurn)} cy={cy - R_KM * s * Math.sin(earthTurn)} r="3.5" className="b2dot sky" />
      <circle cx={cx} cy={cy} r={r * s} className="b2orbit" />
      <circle cx={cx + r * s * Math.cos(satAng)} cy={cy - r * s * Math.sin(satAng)} r="6" className="b2sat" />
      <text x="10" y="20" className="b2t">to scale; the line turns with Earth</text>
    </svg>
  );
  const saved = Math.abs(((b2.shelf.T_sat?.value as number) ?? NaN) - T) < 1e-6;
  const onSave = () => {
    save("r_sat", r, "or-satellite", { unit: "km", note: `${JOBS.find(j => j.v === job)!.label} satellite, ${km(h)} km up` });
    save("v_sat", v, "or-satellite", { unit: "km/s", note: "its circular speed" });
    save("T_sat", T, "or-satellite", { unit: "s", note: "its period" });
    note({ id: "or-satellite", track: "or", title: "Pick a satellite", project: "or-satellite", data: { job: JOBS.findIndex(j => j.v === job), h },
      lines: [`${JOBS.find(j => j.v === job)!.label}: ${km(h)} km up, r = ${km(r)} km.`, `Speed ${fx(v, 2)} km/s, one lap every ${dur(T)}.`, res.text] });
  };
  return (
    <Scene svg={svg}
      controls={<>
        <Toggle label="Job" value={job} onChange={setJob} options={JOBS} />
        <Slider label="Altitude" value={u} min={0} max={1} step={0.0002} onChange={setU} format={x => `${km(toH(x))} km`}
          marks={[{ v: toU(400), label: "400 km" }, { v: toU(20200), label: "20,200 km" }, { v: toU(35786), label: "35,786 km" }]} />
      </>}
      readouts={<>
        {!quiet && <Read label="Radius r" value={`${km(r)} km`} />}
        {!quiet && <Read label="Speed" value={`${fx(v, 2)} km/s`} tone="sky" />}
        {!quiet && <Read label="Period" value={`${dur(T)}, ${km(T)} s`} tone="amber" big />}
        {!quiet && <Read label="The job" value={res.text} />}
      </>}
      foot={project && <SaveRow what={<>Keep <b>r_sat</b>, <b>v_sat</b> and <b>T_sat</b> for this satellite{res.ok ? "" : " (it doesn't fit the job yet)"}</>} saved={saved} onSave={onSave} />} />
  );
}
