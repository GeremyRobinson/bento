// The twin trip planner (relativity.md): star distance and speed sliders (the friendly speeds 3/5, 4/5, 12/13
// marked), both worldlines with a tick every year, both ages on return, and the turnaround, where the traveler's
// "now" line jumps across the home twin's worldline.
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { gammaOf } from "../physics";

const W = 360, H = 300;
const STARS = [{ v: 4.25, label: "Alpha Centauri" }, { v: 8.6, label: "Sirius" }, { v: 11.9, label: "Procyon" }, { v: 25, label: "Vega" }];
const SPEEDS = [{ v: 0.6, label: "3/5" }, { v: 0.8, label: "4/5" }, { v: 12 / 13, label: "12/13" }];

export function TwinScene({ props }: SceneProps) {
  const [D, setD] = useState(num(props, "D", 3));
  const [beta, setBeta] = useState(num(props, "beta", 0.6));
  const hide = flag(props, "hide"), project = flag(props, "project");
  const { b2, save, note } = useB2();
  const g = gammaOf(beta), home = (2 * D) / beta, trav = home / g, turn = D / beta;
  // one scale for both axes, so light stays at 45°
  const s = Math.min((H - 40) / home, (W - 120) / D);
  const X = (x: number) => 60 + x * s, Y = (t: number) => H - 20 - t * s;
  const every = home > 120 ? 10 : home > 40 ? 5 : 1;
  const homeTicks = Array.from({ length: Math.floor(home / every + 1e-9) }, (_, i) => (i + 1) * every);
  const travTicks = Array.from({ length: Math.floor(trav / every + 1e-9) }, (_, i) => (i + 1) * every);
  // where a traveler tick sits: out at speed β until τ = trav/2, then back
  const travAt = (tau: number): [number, number] => {
    const t = tau * g;
    return t <= turn ? [beta * t, t] : [D - beta * (t - turn), t];
  };
  // the traveler's "now" just before and just after the turnaround meets the home worldline at these times
  const nowOut = turn - beta * D, nowBack = turn + beta * D;

  const saved = Array.isArray(b2.shelf.twin?.value) && Math.abs((b2.shelf.twin!.value as number[])[1]! - trav) < 1e-9 && Math.abs((b2.shelf.twin!.value as number[])[0]! - home) < 1e-9;
  const onSave = () => {
    save("twin", [home, trav], "re-twin", { labels: ["home", "traveler"], unit: "years", note: `${fx(D, 2)} light-years at ${fx(beta, 3)}c` });
    note({ id: "re-twin", track: "re", title: "Twin trip planner", project: "re-twin", data: { D, beta },
      lines: [`A star ${fx(D, 2)} light-years away at ${fx(beta, 3)}c.`, `Home twin ages ${fx(home, 1)} years; the traveler ${fx(trav, 1)}.`] });
  };

  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic twin" role="img" aria-label={`Twin trip: ${fx(D, 1)} light-years at ${fx(beta)} of light speed.${hide ? "" : ` Home ages ${fx(home, 1)} years, the traveler ${fx(trav, 1)}.`}`}>
      <line x1={X(0)} y1={Y(0)} x2={X(0)} y2={12} className="b2axis" />
      <line x1={X(0)} y1={Y(0)} x2={W - 8} y2={Y(0)} className="b2axis" />
      <line x1={X(D)} y1={Y(0)} x2={X(D)} y2={12} className="b2grid" />
      <text x={X(D)} y={Y(0) + 15} textAnchor="middle" className="b2t">star</text>
      <text x={X(0)} y={Y(0) + 15} textAnchor="middle" className="b2t">home</text>
      {/* light from home to the star and back, at 45° */}
      <polyline points={`${X(0)},${Y(0)} ${X(D)},${Y(D)} ${X(0)},${Y(2 * D)}`} className="b2light" />
      <line x1={X(0)} y1={Y(0)} x2={X(0)} y2={Y(home)} className="b2world home" />
      <polyline points={`${X(0)},${Y(0)} ${X(D)},${Y(turn)} ${X(0)},${Y(home)}`} className="b2trav thick" />
      {/* the turnaround: "now" swings from one line to the other */}
      <line x1={X(D)} y1={Y(turn)} x2={X(0)} y2={Y(nowOut)} className="b2now faint" />
      <line x1={X(D)} y1={Y(turn)} x2={X(0)} y2={Y(nowBack)} className="b2now faint" />
      <line x1={X(0) - 8} y1={Y(nowOut)} x2={X(0) - 8} y2={Y(nowBack)} className="b2jump" />
      {homeTicks.map(t => <circle key={`h${t}`} cx={X(0)} cy={Y(t)} r="2.8" className="b2dot" />)}
      {!hide && travTicks.map(tau => { const [x, t] = travAt(tau); return <circle key={`t${tau}`} cx={X(x)} cy={Y(t)} r="2.8" className="b2dot trav" />; })}
      {!hide && <>
        <text x={X(0) - 12} y={Y(home) + 4} textAnchor="end" className="b2t">{fx(home, 1)} y</text>
        <text x={X(0) + 10} y={Y(home) - 8} className="b2t sky">{fx(trav, 1)} y</text>
      </>}
      <text x={W - 8} y="22" textAnchor="end" className="b2t">a tick every {every === 1 ? "year" : `${every} years`}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Star distance" value={D} min={1} max={25} step={0.05} onChange={setD} format={x => `${fx(x, 2)} ly`} marks={STARS} />
        <Slider label="Cruise speed β" value={beta} min={0.3} max={0.99} step={0.001} onChange={setBeta} format={x => `${fx(x, 3)}c`} marks={SPEEDS} />
      </>}
      readouts={hide ? <Read label="γ" value={fx(g)} /> : <>
        <Read label="γ" value={fx(g)} />
        <Read label="Home twin ages" value={`${fx(home, 1)} years`} />
        <Read label="Traveler ages" value={`${fx(trav, 1)} years`} tone="sky" />
        <Read label="Difference" value={`${fx(home - trav, 1)} years`} tone="amber" />
        {/* the turnaround's jump is the side story here: phones keep the ages and drop it (minor) so nothing is cut */}
        <Read label="Now jumps by" value={`${fx(nowBack - nowOut, 1)} years`} tone="pink" minor />
      </>}
      foot={project ? <SaveRow what={<>Keep <b>twin = {fx(home, 1)}, {fx(trav, 1)} years</b> (home, traveler)</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
