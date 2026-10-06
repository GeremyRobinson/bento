// Harvesting and the bifurcation strip (diffeq.md, "New for Development" 3): the logistic growth hump with the
// harvest line across it, the phase line under it, the strip of rest points against H (stable solid, unstable dashed,
// a cursor on the slider), and stocks over 20 years. As the Fishery dial project it saves H_safe.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { harvestRests, solve } from "../maths";
import { Arrow, frame } from "./plot";

const W = 360, H = 280;

export function HarvestScene({ props, place, marker }: SceneProps) {
  const r = num(props, "r", 1), K = num(props, "K", 100), Hmax = (r * K) / 4;
  const [h, setH] = useState(num(props, "H", 10));
  const quiet = flag(props, "quiet"), project = place === "project" || flag(props, "project");
  const { b2, save, note } = useB2();
  const rest = harvestRests(r, K, h);
  const g = (P: number) => r * P * (1 - P / K);
  const top = { l: 30, r: 206, t: 14, b: 118 }, strip = { l: 236, r: 352, t: 14, b: 146 }, time = { l: 30, r: 352, t: 182, b: 262 };
  const fg = frame(0, K * 1.05, 0, Hmax * 1.5, top);
  const fs = frame(0, Hmax * 1.4, 0, K, strip);
  const ft = frame(0, 20, 0, K * 1.05, time);
  const lineY = 140;
  const branch = (sign: 1 | -1) => path(Array.from({ length: 41 }, (_, k) => { const hh = (Hmax * k) / 40, s = Math.sqrt(Math.max(0, 1 - hh / Hmax)); return [fs.X(hh), fs.Y((K / 2) * (1 + sign * s))] as [number, number]; }));
  const starts = [0.12, 0.3, 0.6, 1].map(k => k * K);
  const runs = useMemo(() => starts.map(P0 => solve((_t, y) => [y[0]! <= 0 ? 0 : g(y[0]!) - h], [P0], 0, 20, 0.05).map(p => [ft.X(p.t), ft.Y(Math.max(0, p.y[0]!))] as [number, number])), [h, r, K]); // eslint-disable-line react-hooks/exhaustive-deps
  // the phase line's arrows: growth minus harvest, sign by stretch
  const cuts = [0, ...(rest ?? []), K * 1.05];
  const margin = rest ? rest[1] - rest[0] : 0;
  const saved = b2.shelf.H_safe?.value === h;
  const onSave = () => {
    save("H_safe", h, "de-fishery", { unit: "thousand fish a year", note: `a harvest with ${fx(margin, 0)} thousand fish of margin over the threshold` });
    note({ id: "de-fishery", track: "de", title: "Fishery dial", project: "de-fishery", data: { r, K, H: h },
      lines: [`r = ${r}, K = ${K} thousand fish, harvest ${fx(h, 1)} thousand a year.`, rest ? `Collapse below ${fx(rest[0], 1)}; the stock settles at ${fx(rest[1], 1)}.` : "Past the fold: every stock crashes.", `Maximum sustainable yield ${fx(Hmax, 1)}.`] });
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Harvest ${fx(h, 1)} against a growth hump of height ${fx(Hmax, 1)}. ${rest ? `Rest points at ${fx(rest[0], 0)} and ${fx(rest[1], 0)}.` : "No rest points: the stock crashes."}`}>
      {/* the growth hump and the harvest line */}
      <line x1={top.l} y1={top.b} x2={top.r} y2={top.b} className="b2axis" />
      <path d={path(Array.from({ length: 61 }, (_, k) => { const P = (K * 1.05 * k) / 60; return [fg.X(P), fg.Y(Math.max(0, g(P)))] as [number, number]; }))} className="b2curve sky" />
      <line x1={top.l} y1={fg.Y(h)} x2={top.r} y2={fg.Y(h)} className="b2leg pink" style={{ strokeWidth: 2 }} />
      <text x={top.l + 2} y={top.t + 8} className="b2t sky">growth</text>
      <text x={top.r} y={fg.Y(h) - 6} textAnchor="end" className="b2t pink">H</text>
      {/* the phase line */}
      <line x1={top.l} y1={lineY} x2={top.r} y2={lineY} className="b2axis" />
      <text x={top.r} y={lineY + 16} textAnchor="end" className="b2t">P</text>
      {cuts.slice(0, -1).map((a, i) => {
        const b = cuts[i + 1]!, mid = (a + b) / 2, right = g(mid) - h > 0;
        if (fg.X(b) - fg.X(a) < 24) return null;
        return <Arrow key={i} x1={fg.X(mid) + (right ? -7 : 7)} y1={lineY} x2={fg.X(mid) + (right ? 7 : -7)} y2={lineY} cls="sky" />;
      })}
      {rest && <>
        <circle cx={fg.X(rest[0])} cy={lineY} r="5.5" className="b2clock amber" />
        <circle cx={fg.X(rest[1])} cy={lineY} r="5.5" className="b2dot amber" />
        <line x1={fg.X(rest[0])} y1={fg.Y(h)} x2={fg.X(rest[0])} y2={lineY} className="b2mark amber" />
        <line x1={fg.X(rest[1])} y1={fg.Y(h)} x2={fg.X(rest[1])} y2={lineY} className="b2mark amber" />
      </>}
      {/* the bifurcation strip */}
      <line x1={strip.l} y1={strip.b} x2={strip.r} y2={strip.b} className="b2axis" />
      <line x1={strip.l} y1={strip.t} x2={strip.l} y2={strip.b} className="b2axis" />
      <text x={strip.r} y={strip.b + 15} textAnchor="end" className="b2t">H</text>
      <text x={strip.l + 4} y={strip.t + 10} className="b2t">P</text>
      {!quiet && <path d={branch(1)} className="b2curve amber" />}
      {!quiet && <path d={branch(-1)} className="b2curve amber" strokeDasharray="5 4" />}
      {!quiet && <circle cx={fs.X(Hmax)} cy={fs.Y(K / 2)} r="3.5" className="b2dot amber" />}
      <line x1={fs.X(h)} y1={strip.t} x2={fs.X(h)} y2={strip.b} className="b2leg pink" style={{ strokeWidth: 2 }} />
      {rest && !quiet && <><circle cx={fs.X(h)} cy={fs.Y(rest[1])} r="4.5" className="b2dot amber" /><circle cx={fs.X(h)} cy={fs.Y(rest[0])} r="4.5" className="b2clock amber" /></>}
      {marker && <line x1={fs.X(marker[0])} y1={strip.t} x2={fs.X(marker[0])} y2={strip.b} className="b2mark guess" />}
      {/* stocks over 20 years */}
      <line x1={time.l} y1={time.b} x2={time.r} y2={time.b} className="b2axis" />
      <line x1={time.l} y1={time.t} x2={time.l} y2={time.b} className="b2axis" />
      <text x={time.r} y={time.b + 15} textAnchor="end" className="b2t">20 years</text>
      {runs.map((pts, i) => <path key={i} d={path(pts)} className="b2curve sky" style={{ strokeWidth: 1.8 }} opacity={0.85} />)}
      {rest && <line x1={time.l} y1={ft.Y(rest[0])} x2={time.r} y2={ft.Y(rest[0])} className="b2mark amber" />}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Harvest H" value={h} min={0} max={Math.round(Hmax * 1.3)} step={0.5} onChange={setH} format={v => `${fx(v, 1)} thousand a year`} />}
      readouts={<>
        {!quiet && <Read label="Most it can take" value={`${fx(Hmax, 0)} a year`} tone="sky" />}
        {!quiet && <Read label="Collapses below" value={rest ? fx(rest[0], 1) : "every stock crashes"} tone="amber" />}
        {!quiet && rest && <Read label="Settles at" value={fx(rest[1], 1)} tone="amber" />}
        {project && <Read label="Safety margin" value={rest ? `${fx(margin, 1)} thousand` : "none"} tone="pink" big />}
      </>}
      foot={project ? <SaveRow what={<>Keep <b>H_safe = {fx(h, 1)}</b> thousand fish a year{rest ? "" : ", though this crashes the stock"}</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
