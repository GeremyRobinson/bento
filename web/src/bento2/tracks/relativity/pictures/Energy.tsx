// The energy triangle (Vector board, relativity.md): legs mc² and pc, hypotenuse E, with γ and β read off as ratios.
// Drag the momentum arrow's tip; the speed β = pc / E creeps toward 1 but never reaches it.
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider, useSvgDrag } from "../../../ui/kit";

const W = 360, H = 250;

export function EnergyScene({ props }: SceneProps) {
  const [m, setM] = useState(num(props, "m", 3));
  const [p, setP] = useState(num(props, "p", 4));
  const hide = flag(props, "hide");
  const E = Math.hypot(m, p), beta = p / E;
  const big = Math.max(m, p, 4), s = Math.min(240 / big, 190 / big);
  const ox = 40, oy = H - 34;
  const tip: [number, number] = [ox + m * s, oy - p * s];
  const { ref, drag } = useSvgDrag();
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic en" role="img" aria-label={`Energy triangle: rest energy ${fx(m, 1)}, momentum ${fx(p, 1)}${hide ? "" : `, total energy ${fx(E, 2)}`} MeV.`}>
      <path d={`M${ox},${oy} L${tip[0]},${oy} L${tip[0]},${tip[1]} Z`} className="b2tri on" />
      <line x1={ox} y1={oy} x2={tip[0]} y2={oy} className="b2leg sky" />
      <line x1={tip[0]} y1={oy} x2={tip[0]} y2={tip[1]} className="b2leg pink" />
      <line x1={ox} y1={oy} x2={tip[0]} y2={tip[1]} className="b2leg amber" />
      <text x={(ox + tip[0]) / 2} y={oy + 20} textAnchor="middle" className="b2t sky">mc² = {fx(m, 1)}</text>
      <text x={tip[0] + 8} y={(oy + tip[1]) / 2} className="b2t pink">pc = {fx(p, 1)}</text>
      <text x={(ox + tip[0]) / 2 - 12} y={(oy + tip[1]) / 2 - 8} textAnchor="end" className="b2t amber">E = {hide ? "?" : fx(E, 2)}</text>
      <circle cx={tip[0]} cy={tip[1]} r="9" className="b2handle" />
      <circle cx={tip[0]} cy={tip[1]} r="22" className="b2hit" {...drag((_, y) => setP(Math.max(0, Math.min(big * 1.2, Math.round(((oy - y) / s) * 10) / 10))))} />
      {/* the speed gauge: β = pc / E, never 1 */}
      <rect x="40" y="14" width="200" height="10" rx="5" className="b2bar track" />
      <rect x="40" y="14" width={200 * beta} height="10" rx="5" className="b2bar amber" />
      <text x="248" y="23" className="b2t">β = {hide ? "?" : fx(beta, 3)}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Rest energy mc²" value={m} min={0} max={30} step={0.5} onChange={setM} format={x => `${fx(x, 1)} MeV`} />
        <Slider label="Momentum pc" value={p} min={0} max={30} step={0.5} onChange={setP} format={x => `${fx(x, 1)} MeV`} />
      </>}
      readouts={<>
        <Read label="E" value={hide ? "?" : `${fx(E, 2)} MeV`} tone="amber" />
        <Read label="γ = E / mc²" value={hide || m === 0 ? (m === 0 ? "no rest mass" : "?") : fx(E / m, 3)} />
        <Read label="β = pc / E" value={hide ? "?" : fx(beta, 3)} />
        <Read label="Kinetic E − mc²" value={hide ? "?" : `${fx(E - m, 2)} MeV`} />
      </>}
    />
  );
}
