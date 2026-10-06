// Amplitude arrows (quantum.md, 01 and 02). Add: two arrows head to tail, the sum arrow, and its squared length drawn
// as a square whose area is the chance; a "which path" switch throws the cross term away and shows the two squares
// on their own. Multiply: z and w on the complex plane, dragged by their heads, and zw with length |z||w| at the
// angle of z plus the angle of w. A point guess drags a marker on the plane; the reveal turns z a quarter turn.
import { useEffect, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { ArrowHead, fx, Read, Scene, Slider, Toggle, useSvgDrag, useTween } from "../../../ui/kit";
import { cAbs2, cMul, cx, type Cx } from "../maths";

const W = 360, H = 260;

function Arrow({ from, to, tone, thick }: { from: [number, number]; to: [number, number]; tone: string; thick?: boolean }) {
  if (Math.hypot(to[0] - from[0], to[1] - from[1]) < 2) return null;
  return (
    <g className={tone}>
      <line x1={from[0]} y1={from[1]} x2={to[0]} y2={to[1]} className="b2leg" strokeWidth={thick ? 4 : 3} />
      <ArrowHead x1={from[0]} y1={from[1]} x2={to[0]} y2={to[1]} className="b2dot" />
    </g>
  );
}

export function ArrowsScene(sp: SceneProps) {
  return str<string>(sp.props, "mode", "add") === "mult" ? <MultArrows {...sp} /> : <AddArrows {...sp} />;
}

function AddArrows({ props }: SceneProps) {
  const [a, setA] = useState(num(props, "a", 0.3));
  const [b, setB] = useState(num(props, "b", 0.4));
  const [theta, setTheta] = useState(num(props, "theta", 60));
  const [which, setWhich] = useState<"no" | "yes">("no");
  const quiet = flag(props, "quiet"), sweep = flag(props, "sweep");
  // the reveal sweeps the second arrow from lined up (0°) to opposite (180°)
  const [goal, setGoal] = useState(sweep ? 0 : theta);
  useEffect(() => { if (sweep) { const t = setTimeout(() => setGoal(180), 300); return () => clearTimeout(t); } }, [sweep]);
  const swept = useTween(goal, 3200);
  const th = sweep ? swept : theta;
  const { ref, drag } = useSvgDrag();
  // the arrows fill the left part whatever their lengths; the chance box on the right keeps one fixed scale
  const L = Math.min(210 / (a + b), 105 / b, 520), O: [number, number] = [22, 130];
  const A: [number, number] = [O[0] + a * L, O[1]];
  const t = (th * Math.PI) / 180;
  const B: [number, number] = [A[0] + b * L * Math.cos(t), A[1] - b * L * Math.sin(t)];
  const sum = Math.hypot(B[0] - O[0], B[1] - O[1]) / L, P = sum * sum, classical = a * a + b * b;
  const showP = !quiet || sweep;
  // the chance box: the outline is a chance of 1; a square of side |a + b| inside it has area P
  const bx = 250, by = 70, bs = 100;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic arrows" role="img"
      aria-label={`Two amplitude arrows, ${fx(a)} and ${fx(b)}, at ${Math.round(th)}°.${showP ? ` The sum has length ${fx(sum)}, so the chance is ${fx(P)}.` : ""}`}>
      <Arrow from={O} to={A} tone="sky" />
      <Arrow from={A} to={B} tone="pink" />
      {which === "no" && showP && <Arrow from={O} to={B} tone="amber" thick />}
      <circle cx={A[0]} cy={A[1]} r={b * L} className="b2ring" opacity="0.5" />
      <circle cx={B[0]} cy={B[1]} r="18" className="b2hit" {...drag((x, y) => !sweep && setTheta(Math.round((((Math.atan2(A[1] - y, x - A[0]) * 180) / Math.PI) + 360) % 360)))} />
      <circle cx={B[0]} cy={B[1]} r="6" className="b2handle" pointerEvents="none" />
      <text x={(O[0] + A[0]) / 2} y={O[1] + 20} textAnchor="middle" className="b2t sky">a</text>
      <text x={(A[0] + B[0]) / 2 + 10} y={(A[1] + B[1]) / 2 - 8} className="b2t pink">b</text>
      <rect x={bx} y={by} width={bs} height={bs} className="b2tri" />
      <text x={bx + bs / 2} y={by - 8} textAnchor="middle" className="b2t">a chance of 1</text>
      {which === "no" ? <>
        {showP && <rect x={bx} y={by + bs - sum * bs} width={sum * bs} height={sum * bs} className="b2bar amber" opacity="0.35" />}
        {showP && <rect x={bx} y={by + bs - sum * bs} width={sum * bs} height={sum * bs} className="b2mark amber" strokeDasharray="none" />}
        <text x={bx + bs / 2} y={by + bs + 22} textAnchor="middle" className="b2t amber">P = {showP ? fx(P) : "?"}</text>
      </> : <>
        <rect x={bx} y={by + bs - a * bs} width={a * bs} height={a * bs} className="b2bar sky" opacity="0.45" />
        <rect x={bx + a * bs} y={by + bs - b * bs} width={b * bs} height={b * bs} className="b2bar pink" opacity="0.45" />
        <text x={bx + bs / 2} y={by + bs + 22} textAnchor="middle" className="b2t">a² + b² = {fx(classical)}</text>
      </>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Angle θ between the arrows" value={theta} min={0} max={360} step={1} onChange={setTheta} format={v => `${v}°`} marks={[0, 60, 90, 120, 180].map(v => ({ v, label: `${v}°` }))} />
        <Slider label="Length a" value={a} min={0.05} max={0.6} step={0.05} onChange={setA} format={v => fx(v)} />
        <Slider label="Length b" value={b} min={0.05} max={0.6} step={0.05} onChange={setB} format={v => fx(v)} />
        <Toggle label="Which path" value={which} onChange={setWhich} options={[{ v: "no", label: "Paths unknown" }, { v: "yes", label: "Which path known" }]} />
      </>}
      readouts={<>
        <Read label="θ" value={`${Math.round(th)}°`} />
        <Read label="|a|²" value={fx(a * a)} tone="sky" />
        <Read label="|b|²" value={fx(b * b)} tone="pink" />
        <Read label={!showP ? "P" : which === "no" ? "P = |a + b|²" : "P = |a|² + |b|²"} value={showP ? fx(which === "no" ? P : classical) : "?"} tone="amber" big />
      </>}
    />
  );
}

function MultArrows({ props, marker, onMarker }: SceneProps) {
  const [z, setZ] = useState<Cx>([num(props, "zr", 2), num(props, "zi", 1)]);
  const [w, setW] = useState<Cx>([num(props, "wr", 1), num(props, "wi", 1)]);
  const quiet = flag(props, "quiet"), turnIt = flag(props, "turn");
  const guessing = !!onMarker || !!marker;
  const [goal, setGoal] = useState(0);
  useEffect(() => { if (turnIt) { const t = setTimeout(() => setGoal(1), 300); return () => clearTimeout(t); } }, [turnIt]);
  const k = useTween(goal, 1800);
  const zw = cMul(z, w);
  const { ref, drag } = useSvgDrag();
  const R = Math.max(1.6, Math.hypot(...z), Math.hypot(...w), quiet && !turnIt ? 0 : Math.hypot(...zw), marker ? Math.hypot(...marker) : 0) * 1.12;
  const cxp = 180, cyp = 130, sc = 118 / R;
  const P = (c: Cx): [number, number] => [cxp + c[0] * sc, cyp - c[1] * sc];
  const back = (x: number, y: number): Cx => [Math.round((x - cxp) / sc), Math.round((cyp - y) / sc)];
  // the reveal: the product's arrow turns from z's direction by w's angle, stretching by |w|
  const angW = Math.atan2(w[1], w[0]), lw = Math.hypot(...w);
  const shown: Cx = turnIt ? cMul(z, [(1 + (lw - 1) * k) * Math.cos(angW * k), (1 + (lw - 1) * k) * Math.sin(angW * k)]) : zw;
  const showProduct = !quiet || turnIt;
  const ticks = Array.from({ length: Math.floor(R) }, (_, i) => i + 1);
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic plane" role="img"
      aria-label={`z = ${cx(...z)} and w = ${cx(...w)}.${showProduct ? ` Their product is ${cx(...zw)}.` : ""}`}
      {...(onMarker ? drag((x, y) => onMarker(back(x, y))) : {})}>
      <line x1="0" y1={cyp} x2={W} y2={cyp} className="b2grid strong" />
      <line x1={cxp} y1="0" x2={cxp} y2={H} className="b2grid strong" />
      {ticks.map(t => <g key={t}>
        <line x1={cxp + t * sc} y1={cyp - 3} x2={cxp + t * sc} y2={cyp + 3} className="b2axis" />
        <line x1={cxp - t * sc} y1={cyp - 3} x2={cxp - t * sc} y2={cyp + 3} className="b2axis" />
        <line x1={cxp - 3} y1={cyp - t * sc} x2={cxp + 3} y2={cyp - t * sc} className="b2axis" />
        <line x1={cxp - 3} y1={cyp + t * sc} x2={cxp + 3} y2={cyp + t * sc} className="b2axis" />
      </g>)}
      <circle cx={cxp} cy={cyp} r={sc} className="b2ring" />
      <text x={W - 6} y={cyp - 6} textAnchor="end" className="b2t">real</text>
      <text x={cxp + 6} y="16" className="b2t">imaginary</text>
      <Arrow from={[cxp, cyp]} to={P(z)} tone="sky" />
      {!guessing && <Arrow from={[cxp, cyp]} to={P(w)} tone="pink" />}
      {showProduct && <Arrow from={[cxp, cyp]} to={P(shown)} tone="amber" thick />}
      <text x={P(z)[0] + 8} y={P(z)[1] - 6} className="b2t sky">z</text>
      {!guessing && <text x={P(w)[0] + 8} y={P(w)[1] - 6} className="b2t pink">w</text>}
      {showProduct && <text x={P(shown)[0] + 8} y={P(shown)[1] + 16} className="b2t amber">{guessing ? "i·z" : "zw"}</text>}
      {!guessing && <>
        <circle cx={P(z)[0]} cy={P(z)[1]} r="16" className="b2hit" {...drag((x, y) => { const c = back(x, y); if (c[0] || c[1]) setZ(c); })} />
        <circle cx={P(w)[0]} cy={P(w)[1]} r="16" className="b2hit" {...drag((x, y) => { const c = back(x, y); if (c[0] || c[1]) setW(c); })} />
        <circle cx={P(z)[0]} cy={P(z)[1]} r="5" className="b2handle" pointerEvents="none" />
        <circle cx={P(w)[0]} cy={P(w)[1]} r="5" className="b2handle" pointerEvents="none" />
      </>}
      {marker && <g>
        <circle cx={P(marker as Cx)[0]} cy={P(marker as Cx)[1]} r="9" className="b2marker" />
        <text x={P(marker as Cx)[0] + 12} y={P(marker as Cx)[1] - 10} className="b2t">your guess</text>
      </g>}
    </svg>
  );
  const ang = (c: Cx) => `${Math.round(((Math.atan2(c[1], c[0]) * 180) / Math.PI + 360) % 360)}°`;
  return (
    <Scene svg={svg}
      readouts={guessing ? <>
        <Read label="z" value={cx(...z)} tone="sky" />
        <Read label="|z|" value={fx(Math.hypot(...z), 2)} />
        {showProduct && <Read label="i·z" value={cx(...zw)} tone="amber" big />}
      </> : <>
        <Read label="z" value={`${cx(...z)}, at ${ang(z)}`} tone="sky" />
        <Read label="w" value={`${cx(...w)}, at ${ang(w)}`} tone="pink" />
        <Read label="zw" value={showProduct ? `${cx(...zw)}, at ${ang(zw)}` : "?"} tone="amber" />
        <Read label="|z|² × |w|²" value={`${cAbs2(z)} × ${cAbs2(w)}`} />
        <Read label="|zw|²" value={showProduct ? String(cAbs2(zw)) : "?"} tone="amber" />
      </>}
    />
  );
}
