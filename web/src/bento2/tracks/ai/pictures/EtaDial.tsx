// The Learning-rate dial (ai.md): a ball on the bowl L(w) = a(w − m)², its first steps redrawn as η turns: creep,
// land, zigzag, bounce, blow up. Below, a long narrow valley, L = ½(x² + 10y²), where one η has to suit both
// directions: the steep one sets the limit, and the shallow one crawls.
import { useEffect, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, useTween } from "../../../ui/kit";
import { FATES, fateOf } from "../lessons-a";
import { lin } from "./common";

export function EtaDialScene({ props, marker }: SceneProps) {
  const a = num(props, "a", 2), m = num(props, "m", 3), d = num(props, "d", 10), quiet = flag(props, "quiet"), sweep = flag(props, "sweep");
  const [etaSet, setEtaRaw] = useState(num(props, "eta", 0.1));
  const [touched, setTouched] = useState(false);
  const setEta = (v: number) => { setTouched(true); setEtaRaw(v); };
  // the reveal sweeps η up from small to the edge, and the path flips from settling to bouncing as it arrives
  const [goal, setGoal] = useState(sweep ? 0.02 : etaSet);
  useEffect(() => { if (sweep) setGoal(etaSet); }, []); // eslint-disable-line react-hooks/exhaustive-deps
  const swept = useTween(goal, 2600);
  const eta = sweep && !touched ? swept : etaSet;
  const r = 1 - 2 * eta * a, fate = fateOf(Math.round(r * 100) / 100);
  const W = 360, H = 260;
  const span = d * 1.6, wx = lin(m - span, m + span, 14, 346), Lmax = a * span * span, ly = lin(0, Lmax, 130, 12);
  const bowl: [number, number][] = Array.from({ length: 81 }, (_, i) => { const w = m - span + (i / 80) * 2 * span; return [wx(w), ly(a * (w - m) ** 2)]; });
  const ws = [m + d];
  for (let k = 0; k < 10; k++) ws.push(m + r * (ws.at(-1)! - m));
  const clip = (w: number) => Math.max(m - span, Math.min(m + span, w));
  const P = (w: number): [number, number] => [wx(clip(w)), ly(Math.min(Lmax, a * (clip(w) - m) ** 2))];
  // the valley: two curvatures, 1 and 10; the same η on both
  const vx = lin(-10, 10, 20, 340), vy = lin(-2.2, 2.2, 252, 152);
  const vp: [number, number][] = [[-9, 1.8]];
  for (let k = 0; k < 24; k++) { const [x, y] = vp.at(-1)!; vp.push([x * (1 - eta * 0.5), y * (1 - eta * 5)]); }
  const vis = vp.filter(([x, y]) => Math.abs(x) < 12 && Math.abs(y) < 3);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={quiet ? `The bowl with a = ${a}.` : `The bowl with a = ${a}. At η = ${fx(eta)} each step multiplies the distance by ${fx(r)}.`}>
      <path d={path(bowl)} className="b2curve" />
      <path d={path(ws.map(P))} className="b2jump" />
      {ws.slice(0, 6).map((w, i) => <circle key={i} cx={P(w)[0]} cy={P(w)[1]} r={i ? 4 : 6} className={`b2dot ${i ? "pink" : "mint"}`} />)}
      <line x1={wx(m)} y1="130" x2={wx(m)} y2="138" className="b2axis" />
      <text x={wx(m)} y="150" textAnchor="middle" className="b2t">bottom</text>
      {marker && <text x="346" y="24" textAnchor="end" className="b2t">your guess: η = {fx(marker[0])}</text>}
      {[1, 2, 3].map(k => <ellipse key={k} cx={vx(0)} cy={vy(0)} rx={(vx(10) - vx(0)) * k / 3} ry={((vy(-2.2) - vy(0)) * k) / 3 / 1.4} className="b2grid strong" fill="none" />)}
      <path d={path(vis.map(([x, y]) => [vx(x), vy(y)]))} className="b2curve amber" />
      <circle cx={vx(vis.at(-1)![0])} cy={vy(vis.at(-1)![1])} r="5" className="b2dot amber" />
      <text x="22" y="166" className="b2t">narrow valley</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Learning rate η" value={etaSet} min={0.01} max={1.5 / a} step={0.005} onChange={setEta} format={v => v.toFixed(3)}
        marks={[{ v: 1 / (4 * a), label: "1/(4a)" }, { v: 1 / (2 * a), label: "1/(2a)" }, { v: 3 / (4 * a), label: "3/(4a)" }, { v: 1 / a, label: "1/a" }]} />}
      readouts={quiet ? <Read label="a" value={String(a)} /> : <>
        <Read label="η" value={fx(eta, 3)} />
        <Read label="Factor r = 1 − 2ηa" value={fx(r)} tone="pink" />
        <Read label="What happens" value={FATES[fate]!} big />
        <Read label="Valley, steep way" value={fx(1 - eta * 5)} tone="amber" />
      </>}
    />
  );
}
