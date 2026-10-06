// The traps. Retest pair (17): score = skill + luck on two tests; pick the top group on test 1 and watch the same
// people's test 2 scores fall back toward the mean, with no treatment at all. Simpson table (18): two treatments on
// mild and severe cases; move the severe cases between them and the overall bars flip while the within-group bars
// stay put; the arrows show severity driving both the treatment choice and the outcome.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { ArrowHead, fx, Read, Scene, Slider } from "../../../ui/kit";
import { gauss, seeded } from "../maths";
import { K, lin } from "./parts";

const W = 360, H = 240;

export function RetestScene({ props, marker }: SceneProps) {
  const quiet = flag(props, "quiet"), low = flag(props, "low");
  const [rho, setRho] = useState(num(props, "skill", 0.5));
  const [share, setShare] = useState(quiet || marker ? 5 : 10);
  const base = useMemo(() => { const r = seeded(17); return Array.from({ length: 400 }, () => [gauss(r), gauss(r), gauss(r)] as [number, number, number]); }, []);
  const people = base.map(([s, e1, e2]) => [Math.sqrt(rho) * s + Math.sqrt(1 - rho) * e1, Math.sqrt(rho) * s + Math.sqrt(1 - rho) * e2] as [number, number]);
  const order = [...people].sort((a, b) => (low ? a[0] - b[0] : b[0] - a[0]));
  const group = order.slice(0, Math.max(1, Math.round((share / 100) * people.length)));
  const cut = group[group.length - 1]![0];
  const inG = (p: [number, number]) => (low ? p[0] <= cut : p[0] >= cut);
  const m1 = group.reduce((a, p) => a + p[0], 0) / group.length, m2 = group.reduce((a, p) => a + p[1], 0) / group.length;
  const Y = lin(-3.4, 3.4, H - 14, 14), x1 = 110, x2 = 260;
  const jit = (i: number) => ((i * 53) % 29) - 14;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Skill is ${fx(rho * 100, 0)}% of the score. The picked group averages ${fx(m1)} SDs on test 1${quiet ? "" : ` and ${fx(m2)} on test 2`}.`}>
      <line x1={x1} x2={x1} y1={Y(-3.4)} y2={Y(3.4)} className="b2axis" />
      <line x1={x2} x2={x2} y1={Y(-3.4)} y2={Y(3.4)} className="b2axis" />
      <line x1="40" x2={W - 30} y1={Y(0)} y2={Y(0)} style={{ stroke: K.line, strokeDasharray: "4 4" }} />
      <text x="8" y={Y(0) + 4} className="b2t">mean</text>
      <text x={x1} y={H - 1} textAnchor="middle" className="b2t">test 1</text>
      <text x={x2} y={H - 1} textAnchor="middle" className="b2t">test 2</text>
      {people.map((p, i) => (
        <g key={i}>
          <circle cx={x1 + jit(i)} cy={Y(p[0])} r="2" style={{ fill: inG(p) ? K.amber : K.muted, fillOpacity: inG(p) ? 0.95 : 0.35 }} />
          {(!quiet || !inG(p)) && <circle cx={x2 + jit(i)} cy={Y(p[1])} r="2" style={{ fill: inG(p) ? K.sky : K.muted, fillOpacity: inG(p) ? 0.95 : 0.35 }} />}
          {!quiet && inG(p) && <line x1={x1 + jit(i)} y1={Y(p[0])} x2={x2 + jit(i)} y2={Y(p[1])} style={{ stroke: K.sky, strokeOpacity: 0.25 }} />}
        </g>
      ))}
      <line x1={x1 - 26} x2={x1 + 26} y1={Y(m1)} y2={Y(m1)} style={{ stroke: K.amber, strokeWidth: 3 }} />
      <text x={x1 - 30} y={Y(m1) + 4} textAnchor="end" className="b2t amber">{fx(m1, 1)}</text>
      {!quiet && <><line x1={x2 - 26} x2={x2 + 26} y1={Y(m2)} y2={Y(m2)} style={{ stroke: K.sky, strokeWidth: 3 }} />
        <text x={x2 + 30} y={Y(m2) + 4} className="b2t sky">{fx(m2, 1)}</text></>}
      {marker && <><line x1={x2 - 30} x2={x2 + 30} y1={Y(marker[0])} y2={Y(marker[0])} className="b2mark guess" /><text x={x2 + 34} y={Y(marker[0]) + 4} className="b2t">guess</text></>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Share of the score that is skill" value={rho} min={0} max={1} step={0.05} onChange={setRho} format={x => `${fx(x * 100, 0)}%`} />
        <Slider label={low ? "Pick the bottom" : "Pick the top"} value={share} min={2} max={50} step={1} onChange={setShare} format={x => `${x}%`} />
      </>}
      readouts={<>
        <Read label="Test 1, the group" value={`${fx(m1)} SDs`} tone="amber" />
        {!quiet && <Read label="Test 2, same people" value={`${fx(m2)} SDs`} tone="sky" />}
        {!quiet && <Read label="ρ × test 1" value={`${fx(rho * m1)} SDs`} />}
      </>}
    />
  );
}

export function SimpsonScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet");
  const totA = props.ma != null ? num(props, "ma", 0) + num(props, "sa", 0) : 100, totB = props.mb != null ? num(props, "mb", 0) + num(props, "sb", 0) : 100;
  const [sa, setSa] = useState(num(props, "sa", 50));
  const [sb, setSb] = useState(num(props, "sb", 50));
  const ram = num(props, "ram", 90), ras = num(props, "ras", 50), rbm = num(props, "rbm", 80), rbs = num(props, "rbs", 40);
  const ma = totA - sa, mb = totB - sb;
  const A = (ma * ram + sa * ras) / totA, B = (mb * rbm + sb * rbs) / totB;
  const mild = ma + mb, sev = sa + sb, adjA = (ram * mild + ras * sev) / (mild + sev), adjB = (rbm * mild + rbs * sev) / (mild + sev);
  const Y = lin(0, 100, 196, 24), bw = 22;
  const pair = (x: number, a: number, b: number, lab: string, hide = false) => (
    <g>
      {!hide && <>
        <rect x={x} y={Y(a)} width={bw} height={Y(0) - Y(a)} rx="3" style={{ fill: K.pink }} />
        <rect x={x + bw + 4} y={Y(b)} width={bw} height={Y(0) - Y(b)} rx="3" style={{ fill: K.sky }} />
        <text x={x + bw / 2} y={Y(a) - 5} textAnchor="middle" className="b2t pink">{fx(a, 0)}</text>
        <text x={x + bw * 1.5 + 4} y={Y(b) - 5} textAnchor="middle" className="b2t sky">{fx(b, 0)}</text>
      </>}
      {hide && <rect x={x} y={Y(100)} width={bw * 2 + 4} height={Y(0) - Y(100)} rx="3" style={{ fill: K.faint, fillOpacity: 0.3 }} />}
      <text x={x + bw + 2} y={H - 22} textAnchor="middle" className="b2t">{lab}</text>
    </g>
  );
  const nodes = { sev: [290, 40], tr: [250, 130], out: [330, 130] } as const;
  type NodeId = keyof typeof nodes;
  const arrow = (f: NodeId, t: NodeId) => {
    const [a, b] = nodes[f], [c, d] = nodes[t], down = d > b, k = down ? 0.9 : 1;
    const y0 = down ? b + 8 : b + 12, x0 = down ? a : a + 32, x1 = down ? c : c - 28, ex = x0 + (x1 - x0) * k, ey = y0 + ((down ? d - 6 : d + 12) - y0) * k;
    return <g key={f + t}><line x1={x0} y1={y0} x2={ex} y2={ey} style={{ stroke: K.muted, strokeWidth: 1.5 }} /><ArrowHead x1={x0} y1={y0} x2={ex} y2={ey} className="b2dot" /></g>;
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Recovery rates. Mild: A ${ram}%, B ${rbm}%. Severe: A ${ras}%, B ${rbs}%.${quiet ? "" : ` Overall: A ${fx(A, 1)}%, B ${fx(B, 1)}%.`}`}>
      {pair(14, ram, rbm, "mild")}
      {pair(84, ras, rbs, "severe")}
      {pair(160, A, B, "overall", quiet)}
      <line x1="10" x2="222" y1={Y(0)} y2={Y(0)} className="b2axis" />
      <text x="14" y={H - 4} className="b2t pink">A</text><text x="34" y={H - 4} className="b2t sky">B</text>
      <text x="56" y={H - 4} className="b2t">% recovered</text>
      {arrow("sev", "tr")}{arrow("sev", "out")}{arrow("tr", "out")}
      <text x={nodes.sev[0]} y={nodes.sev[1]} textAnchor="middle" className="b2t amber">severity</text>
      <text x={nodes.tr[0]} y={nodes.tr[1] + 16} textAnchor="middle" className="b2t">treatment</text>
      <text x={nodes.out[0]} y={nodes.out[1] + 16} textAnchor="middle" className="b2t">outcome</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label={`Severe cases given A, of ${totA}`} value={sa} min={0} max={totA} step={totA % 10 ? 1 : 10} onChange={setSa} />
        <Slider label={`Severe cases given B, of ${totB}`} value={sb} min={0} max={totB} step={totB % 10 ? 1 : 10} onChange={setSb} />
      </>}
      readouts={<>
        {!quiet && <Read label="Overall, A and B" value={`${fx(A, 1)}%, ${fx(B, 1)}%`} big />}
        {!quiet && <Read label="Adjusted to one mix" value={`${fx(adjA, 1)}%, ${fx(adjB, 1)}%`} tone="amber" />}
        <Read label="Mix" value={`${mild} mild, ${sev} severe`} />
      </>}
    />
  );
}
