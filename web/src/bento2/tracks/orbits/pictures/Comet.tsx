// The comet card (project after b2-or-06): a comet's closest and farthest distances from the Sun (Halley is the
// preset) give its ellipse, a, e, the period, and the speeds at both ends from vis-viva; equal areas checks them.
// The comet moves by Kepler's equation, fast near the Sun and slow far out. Saved in the Notebook.
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { AU, MU_SUN, vVis } from "../maths";

const PRESETS = [{ name: "Halley", near: 0.586, far: 35.1 }, { name: "Encke", near: 0.336, far: 4.09 }, { name: "67P", near: 1.243, far: 5.68 }];
// log sliders: near 0.1 to 5 AU, far 1 to 60 AU
const nearOf = (u: number) => 0.1 * 50 ** u, uNear = (x: number) => Math.log(x / 0.1) / Math.log(50);
const farOf = (u: number) => 60 ** u, uFar = (x: number) => Math.log(x) / Math.log(60);

export function CometScene({ props }: SceneProps) {
  const project = flag(props, "project");
  const [un, setUn] = useState(uNear(num(props, "near", 0.586)));
  const [uf, setUf] = useState(uFar(num(props, "far", 35.1)));
  const { b2, note } = useB2();
  const rn = Math.min(nearOf(un), farOf(uf)), rf = Math.max(nearOf(un), farOf(uf));
  const a = (rn + rf) / 2, e = (rf - rn) / (rf + rn), T = a ** 1.5;
  const vn = vVis(MU_SUN, rn * AU, a * AU) / 1000, vf = vVis(MU_SUN, rf * AU, a * AU) / 1000;
  const W = 360, H = 230;
  // fit the ellipse: the Sun at the right-hand focus, the far end on the left
  const s = Math.min(320 / (2 * a), 90 / Math.max(1e-9, a * Math.sqrt(1 - e * e))), sunX = 20 + (2 * a - rn) * s, cy = 112;
  const ex = sunX - a * e * s;
  const t = useClock(true, 0.1);
  const M = ((t / 8) * 2 * Math.PI) % (2 * Math.PI);
  let E = e > 0.8 ? Math.PI : M;
  for (let k = 0; k < 40; k++) { const d = (E - e * Math.sin(E) - M) / (1 - e * Math.cos(E)); E -= d; if (Math.abs(d) < 1e-12) break; }
  const px = ex + a * s * Math.cos(E), py = cy - a * Math.sqrt(1 - e * e) * s * Math.sin(E);
  const pts: [number, number][] = [];
  for (let k = 0; k <= 120; k++) { const th = (k / 120) * 2 * Math.PI; pts.push([ex + a * s * Math.cos(th), cy - a * Math.sqrt(1 - e * e) * s * Math.sin(th)]); }
  const earthR = 1 * s;
  const name = PRESETS.find(p => Math.abs(p.near - rn) < 0.01 && Math.abs(p.far - rf) < 0.05)?.name;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A comet's ellipse from ${fx(rn, 3)} to ${fx(rf, 1)} AU: a = ${fx(a, 2)} AU, e = ${fx(e, 3)}, a period of ${fx(T, 1)} years.`}>
      {earthR > 3 && earthR < 200 && <circle cx={sunX} cy={cy} r={earthR} className="b2orbit" />}
      <path d={`${path(pts)} Z`} className="b2curve amber" style={{ strokeWidth: 1.5 }} />
      <circle cx={sunX} cy={cy} r="6" className="b2dot amber" />
      <circle cx={px} cy={py} r="5" className="b2dot sky" />
      {earthR > 3 && earthR < 200 && <text x={sunX} y={cy - earthR - 6} textAnchor="middle" className="b2t">Earth's orbit</text>}
      <text x={20} y={cy + 18} className="b2t">far: {fx(rf, 1)} AU</text>
      <text x="10" y={H - 8} className="b2t">{name ?? "your comet"}</text>
    </svg>
  );
  const saved = b2.notebook.some(n => n.id === "or-comet" && n.data.near === rn && n.data.far === rf);
  const onSave = () => note({ id: "or-comet", track: "or", title: `Comet card: ${name ?? "your comet"}`, project: "or-comet", data: { near: rn, far: rf },
    lines: [`Near ${fx(rn, 3)} AU, far ${fx(rf, 2)} AU: a = ${fx(a, 2)} AU, e = ${fx(e, 3)}, period ${fx(T, 1)} years.`,
      `Speed ${fx(vn, 2)} km/s at the near end, ${fx(vf, 2)} km/s at the far end; ${fx(rn, 3)} × ${fx(vn, 2)} = ${fx(rf, 2)} × ${fx(vf, 2)}, equal areas.`] });
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Closest to the Sun" value={un} min={0} max={1} step={0.001} onChange={setUn} format={u => `${fx(nearOf(u), 3)} AU`}
          marks={PRESETS.map(p => ({ v: uNear(p.near), label: p.name }))} />
        <Slider label="Farthest from the Sun" value={uf} min={0} max={1} step={0.001} onChange={setUf} format={u => `${fx(farOf(u), 2)} AU`}
          marks={PRESETS.map(p => ({ v: uFar(p.far), label: p.name }))} />
      </>}
      readouts={<>
        <Read label="a" value={`${fx(a, 2)} AU`} tone="amber" />
        <Read label="e" value={fx(e, 3)} />
        <Read label="Period" value={`${fx(T, 1)} years`} big />
        <Read label="Near speed" value={`${fx(vn, 2)} km/s`} tone="sky" />
        <Read label="Far speed" value={`${fx(vf, 2)} km/s`} tone="sky" />
        <Read label="r × v, both ends" value={`${fx(rn * vn, 2)} and ${fx(rf * vf, 2)}`} />
      </>}
      foot={project && <SaveRow what={<>Keep this comet card in your Notebook</>} saved={saved} onSave={onSave} />} />
  );
}
