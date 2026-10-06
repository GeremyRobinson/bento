// The light clock (relativity.md): two mirrors on a train with a speed slider. The pulse zigzags; the right triangle
// with legs cτ and vt and hypotenuse ct is labelled live; a ground clock and a train clock tick side by side. Muon
// mode: a shower from 10 km up, with the lab view and the muon's view (contracted atmosphere) as a toggle (03).
import { useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, Toggle, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { gammaOf } from "../physics";

const W = 360, H = 260;
const MARKS = [{ v: 0.6, label: "3/5" }, { v: 0.8, label: "4/5" }, { v: 12 / 13, label: "12/13" }, { v: 0.96, label: "24/25" }];
const MUON_MARKS = [...MARKS, { v: 0.998, label: "0.998" }];
const TAU = 2.2, CMU = 0.3;

export function LightClockScene({ props, place, marker }: SceneProps) {
  const muonFirst = str<string>(props, "mode", "clock") === "muon";
  const [mode, setMode] = useState<"clock" | "muon">(muonFirst ? "muon" : "clock");
  const [beta, setBeta] = useState(num(props, "beta", 0.6));
  const [view, setView] = useState<"lab" | "muon">("lab");
  const project = flag(props, "project"), hide = flag(props, "hide");
  const g = gammaOf(beta);
  const t = useClock(true, 3.4);
  const { b2, save, note } = useB2();

  // the clock: mirrors 120 px apart, light at 110 px a second (slowed so you can follow it), the train at βc
  const d = 120, cpx = 110, oneWay = (d / cpx) * g, v = beta * cpx;
  const trainW = 120, span = W + trainW + 40;
  const trainX = ((20 + v * t) % span) - trainW + 40;
  const leg = Math.floor(t / oneWay), f = t / oneWay - leg;
  const yOf = (k: number) => (k % 2 === 0 ? 210 : 210 - d);
  const pulse: [number, number] = [trainX + trainW / 2, yOf(leg) + (yOf(leg + 1) - yOf(leg)) * f];
  // the zigzag the ground sees: where the pulse met the mirrors, back along the train's path
  const zig: [number, number][] = [pulse];
  for (let k = leg; k >= Math.max(0, leg - 5); k--) {
    const x = trainX + trainW / 2 - v * (t - k * oneWay);
    if (x < -20) break;
    zig.push([x, yOf(k)]);
  }
  const groundTicks = t / (2 * (d / cpx)), trainTicks = groundTicks / g;

  const tri = flag(props, "triangle"), sc = 20, a = 4 * sc, b = 4 * beta * g * sc;
  const clockSvg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic lc" role="img" aria-label={`A light clock on a train at ${fx(beta)} of light speed. Each tick takes γ = ${fx(g)} times longer seen from the ground.`}>
      <line x1="0" y1="236" x2={W} y2="236" className="b2axis" />
      <path d={path(zig)} className="b2zig" />
      <g transform={`translate(${trainX},0)`}>
        <rect x="0" y="78" width={trainW} height="150" rx="14" className="b2train" />
        <line x1="20" y1={210 - d} x2={trainW - 20} y2={210 - d} className="b2mirror" />
        <line x1="20" y1="210" x2={trainW - 20} y2="210" className="b2mirror" />
      </g>
      <circle cx={pulse[0]} cy={pulse[1]} r="6" className="b2pulse" />
      {/* the triangle for one trip up: legs cτ and vt, hypotenuse ct (in units where cτ = 4) */}
      {/* while guessing, the triangle's sides would give the answer away, so it isn't drawn at all */}
      {!hide && !flag(props, "quiet") && <g transform={`translate(${W - 24 - Math.min(b, 150)},${16})`} className={tri ? "b2tri on" : "b2tri"}>
        <path d={`M0,${a} L${Math.min(b, 150)},${a} L${Math.min(b, 150)},0 Z`} />
        <path d={`M0,${a} L${Math.min(b, 150)},0`} className="hyp" />
        <text x={Math.min(b, 150) + 6} y={a / 2 + 5} className="b2t">cτ = 4</text>
        <text x={Math.min(b, 150) / 2} y={a + 17} textAnchor="middle" className="b2t">vt = {fx(4 * beta * g)}</text>
        <text x={Math.min(b, 150) / 2 - 10} y={a / 2 - 6} textAnchor="end" className="b2t amber">ct = {fx(4 * g)}</text>
      </g>}
    </svg>
  );

  // muon mode: 10 km of atmosphere, the muon from the top. In the muon's view the muon stays put and the (shorter)
  // atmosphere rushes up past it; it decays at the same fraction of the way down in both views
  const L0 = num(props, "L0", 10), compare = flag(props, "compare");
  const far = beta * CMU * g * TAU, plain = beta * CMU * TAU, Lc = L0 / g;
  const top = 24, bot = 236, kmPx = (bot - top) / L0;
  const loop = 3.2, k = (t % loop) / loop;
  const lab = view === "lab";
  const travelled = Math.min(far, L0) * Math.min(1, k * 1.25);
  const muonY = lab ? top + travelled * kmPx : top + 14;
  const atmTop = top, atmH = lab ? L0 * kmPx : Lc * kmPx;
  const groundY = lab ? bot : top + 14 + atmH - (Math.min(far, L0) / g) * kmPx * Math.min(1, k * 1.25);
  const muonSvg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mu" role="img" aria-label={`Muons from ${L0} km up at ${fx(beta, 3)} of light speed, seen from the ${lab ? "lab" : "muon"}.`}>
      <rect x="96" y={lab ? atmTop : groundY - atmH} width="80" height={atmH} rx="10" className="b2atm" />
      <line x1="60" y1={lab ? bot : groundY} x2="212" y2={lab ? bot : groundY} className="b2axis" />
      <text x="216" y={(lab ? bot : groundY) + 4} className="b2t">ground</text>
      <text x="92" y={(lab ? atmTop : groundY - atmH) + 16} textAnchor="end" className="b2t">{fx(lab ? L0 : Lc, 2)} km</text>
      {lab && !hide && <>
        <line x1="96" y1={top + far * kmPx} x2="176" y2={top + far * kmPx} className="b2mark sky" />
        <text x="182" y={top + Math.min(far, L0) * kmPx + 4} className="b2t sky">with relativity: {fx(far)} km</text>
        {(compare || place !== "lesson") && <>
          <line x1="96" y1={top + plain * kmPx} x2="176" y2={top + plain * kmPx} className="b2mark pink" />
          <text x="182" y={top + plain * kmPx + 4} className="b2t pink">without: {fx(plain)} km</text>
        </>}
      </>}
      {marker && lab && <g><line x1="90" y1={bot - marker[0] * kmPx} x2="182" y2={bot - marker[0] * kmPx} className="b2mark guess" /><text x="186" y={bot - marker[0] * kmPx + 4} className="b2t">your guess</text></g>}
      <circle cx="136" cy={muonY} r="7" className="b2pulse" opacity={k * 1.25 > 1 ? Math.max(0, 1 - (k * 1.25 - 1) * 4) : 1} />
    </svg>
  );

  const saved = Math.abs(((b2.shelf.gamma?.value as number) ?? NaN) - g) < 1e-9;
  const onSave = () => {
    save("gamma", g, "re-lightclock", { note: `γ at β = ${fx(beta, 3)}` });
    note({ id: "re-lightclock", track: "re", title: "Your light clock", project: "re-lightclock", data: { beta },
      lines: [`β = ${fx(beta, 3)}, so γ = ${fx(g, 3)}`, `A muon gets ${fx(far)} km with relativity, ${fx(plain)} km without.`] });
  };

  return (
    <Scene className={mode === "muon" ? "muon" : undefined}
      svg={mode === "muon" ? muonSvg : clockSvg}
      controls={<>
        <Slider label="Speed β" value={beta} min={0.05} max={mode === "muon" ? 0.999 : 0.97} step={0.001} onChange={setBeta} format={x => `${fx(x, 3)}c`} marks={mode === "muon" ? MUON_MARKS : MARKS} />
        {(place !== "lesson" || muonFirst) && <Toggle label="Picture" value={mode} onChange={setMode} options={[{ v: "clock", label: "Light clock" }, { v: "muon", label: "Muons" }]} />}
        {mode === "muon" && <Toggle label="View" value={view} onChange={setView} options={[{ v: "lab", label: "Lab view" }, { v: "muon", label: "Muon's view" }]} />}
      </>}
      readouts={mode === "muon" ? (hide ? <Read label="γ" value={fx(g)} /> : <>
        <Read label="γ" value={fx(g)} />
        <Read label="Lab life" value={`${fx(g * TAU)} μs`} />
        <Read label="With relativity" value={`${fx(far)} km`} tone="sky" />
        <Read label="Without" value={`${fx(plain)} km`} tone="pink" />
        <Read label="Atmosphere for the muon" value={`${fx(Lc)} km`} />
      </>) : hide ? undefined : <>
        <Read label="γ" value={fx(g)} tone="amber" />
        <Read label="Ground clock" value={fx(groundTicks, 1)} />
        <Read label="Train clock" value={fx(trainTicks, 1)} tone="sky" />
        {project && <Read label="Muon from 10 km" value={`${fx(far)} km, not ${fx(plain)}`} />}
      </>}
      foot={project ? <SaveRow what={<>Keep <b>gamma = {fx(g, 3)}</b> on your Number shelf</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
