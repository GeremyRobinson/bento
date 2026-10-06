// ★ The spacetime diagram (relativity.md, "New for Development"): time up, space across, c = 1 so light runs at 45°.
// Drag the traveler's speed β: their time axis tilts to slope 1/β and their "now" line to slope β. Calibration
// hyperbolas (ct)² − x² = 1, 4, 9 make the tilted ticks line up; events are draggable with both readouts; one event
// shows its light cone; the boost goes to the Matrix pad. Modes: light (01), pair (04), boost (05), interval (06), free.
import { useEffect, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle, useSvgDrag, useTween } from "../../../ui/kit";
import { openTool } from "../../../ui/useB2";
import { applyBoost, boost, gammaOf } from "../physics";
import { formatAnswer, toFraction } from "../../../steps";

type Mode = "light" | "pair" | "boost" | "interval" | "free";
type Frame = "ground" | "traveler";
const W = 360, H = 300;
const VIEWS: Record<Mode, [number, number, number, number]> = {
  light: [-6, 6, -1, 8], pair: [-3, 8, -5, 5], boost: [-7, 7, -2, 9], interval: [-6, 7, -1, 9], free: [-6, 6, -2, 8],
};
const BETA_MARKS = [{ v: 0, label: "0" }, { v: 0.6, label: "3/5" }, { v: 0.8, label: "4/5" }];
/** a number as a short fraction when it is one (5/4), else to 2 places */
const nice = (x: number) => { const f = formatAnswer(x, "fraction"); return f.length <= 6 && Math.abs(eval2(f) - x) < 1e-9 ? f : fx(x); };
const eval2 = (f: string) => { const [n, d] = f.replace("−", "-").split("/").map(Number); return d ? n! / d : n!; };
/** The boost for β as exact entries for the Matrix pad: β = p/q gives γ = q/√(q² − p²) and −βγ = −p/√(q² − p²), so
 *  det Λ comes out 1, not 0.9994 from 4-figure decimals. */
export function boostCells(beta: number): string[][] {
  const [p, q] = toFraction(beta, 1000);
  if (Math.abs(p / q - beta) > 1e-12) return boost(beta).map(r => r.map(x => String(x)));
  const n = q * q - p * p, k = Math.round(Math.sqrt(n));
  const over = (top: number) => (k * k === n ? (top % k === 0 ? String(top / k) : `${top}/${k}`) : `${top}/√(${n})`);
  const off = p > 0 ? `-${over(p)}` : p < 0 ? over(-p) : "0";
  return [[over(q), off], [off, over(q)]];
}
const sendBoost = (beta: number) => openTool("matrix", { A: boost(beta), cells: boostCells(beta), label: `boost for β = ${nice(beta)}` });

export function SpacetimeScene({ props, marker, onMarker }: SceneProps) {
  const mode = str<Mode>(props, "mode", "free");
  const quiet = flag(props, "quiet");
  const [beta, setBeta] = useState(num(props, "beta", 0.4));
  const [frame, setFrame] = useState<Frame>(str<Frame>(props, "frame", mode === "light" && flag(props, "measure") ? "traveler" : "ground"));
  const [e1, setE1] = useState<[number, number]>([num(props, "e1t", mode === "free" ? 3 : 5), num(props, "e1x", mode === "free" ? 1 : 3)]);
  const [e2, setE2] = useState<[number, number]>([num(props, "e2t", 0), num(props, "e2x", 4)]);
  const [kink, setKink] = useState<[number, number]>([e1[0] / 2, e1[1] / 2 + 1.2]);
  const g = gammaOf(beta);
  const [x0, x1, t0, t1] = VIEWS[mode];
  const s = Math.min(W / (x1 - x0), H / (t1 - t0));
  const ox = (W - (x1 - x0) * s) / 2, oy = (H - (t1 - t0) * s) / 2;
  // the view's transform: ground coordinates, or the traveler's (every point boosted by β)
  const T = (ct: number, x: number): [number, number] => (frame === "traveler" ? applyBoost(beta, ct, x) : [ct, x]);
  const P = (ct: number, x: number): [number, number] => { const [a, b] = T(ct, x); return [ox + (b - x0) * s, H - oy - (a - t0) * s]; };
  const back = (px: number, py: number): [number, number] => [t0 + (H - oy - py) / s, x0 + (px - ox) / s];
  const line = (a: [number, number], b: [number, number]) => { const [p, q] = [P(...a), P(...b)]; return { x1: p[0], y1: p[1], x2: q[0], y2: q[1] }; };
  const { ref, drag } = useSvgDrag();
  const snap = (v: number) => Math.round(v * 2) / 2;
  const L = 30; // long enough to cross the view

  // the reveal for "pair": the traveler's "now" sweeps upward through both events
  const sweepTo = (ct: number, x: number) => g * (ct - beta * x);
  const lo = Math.min(sweepTo(0, 0), sweepTo(...e2)) - 2.5, hi = Math.max(sweepTo(0, 0), sweepTo(...e2)) + 1.5;
  const [goal, setGoal] = useState(lo);
  useEffect(() => { if (flag(props, "sweep")) setGoal(hi); }, []); // eslint-disable-line react-hooks/exhaustive-deps
  const sweep = useTween(goal, 2600);

  const hyp = (k2: number, spacelike = false, sign = 1) => {
    const pts: [number, number][] = [];
    for (let u = -3; u <= 3; u += 0.05) {
      const k = Math.sqrt(Math.abs(k2));
      const ct = spacelike ? k * Math.sinh(u) : sign * k * Math.cosh(u), x = spacelike ? sign * k * Math.cosh(u) : k * Math.sinh(u);
      pts.push(P(ct, x));
    }
    return path(pts);
  };

  const ticksOn = (dir: [number, number], n: number) => Array.from({ length: n }, (_, i) => i + 1).map(k => P(dir[0] * k, dir[1] * k));
  const tAxis: [number, number] = [g, g * beta], xAxis: [number, number] = [g * beta, g];
  const e1p = applyBoost(beta, ...e1);
  const s2 = e1[0] ** 2 - e1[1] ** 2;

  // the bent worldline: the kink stays where a clock could reach it (inside both light cones)
  const legTau = (a: [number, number], b: [number, number]) => { const d = (b[0] - a[0]) ** 2 - (b[1] - a[1]) ** 2; return b[0] > a[0] && d > 0 ? Math.sqrt(d) : NaN; };
  const tauStraight = s2 > 0 && e1[0] > 0 ? Math.sqrt(s2) : NaN;
  const tauBent = legTau([0, 0], kink) + legTau(kink, e1);
  const tickPts = (a: [number, number], b: [number, number], tau: number) =>
    Number.isFinite(tau) ? Array.from({ length: Math.floor(tau + 1e-9) }, (_, i) => i + 1).map(k => P(a[0] + ((b[0] - a[0]) * k) / tau, a[1] + ((b[1] - a[1]) * k) / tau)) : [];

  const showTraveler = mode !== "light";
  const showHyp = mode === "free" || mode === "boost";
  const hideEvent = flag(props, "hideEvent");
  const applied = flag(props, "applied");
  const lightBall = (w: number) => (frame === "traveler" ? (w - beta) / (1 - w * beta) : w);

  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic st" role="img"
      aria-label={`Spacetime diagram: time up, space across, light at 45 degrees. Traveler speed ${fx(beta)} of light speed.`}>
      <defs><clipPath id="stclip"><rect x="0" y="0" width={W} height={H} /></clipPath></defs>
      <g clipPath="url(#stclip)">
        {/* the ground's grid, one light-year and one year apart */}
        {Array.from({ length: x1 - x0 + 1 }, (_, i) => x0 + i).map(x => <line key={`gx${x}`} className="b2grid" {...line([t0 - L, x], [t1 + L, x])} />)}
        {Array.from({ length: t1 - t0 + 1 }, (_, i) => t0 + i).map(t => <line key={`gt${t}`} className="b2grid" {...line([t, x0 - L], [t, x1 + L])} />)}
        {mode === "free" && !quiet && (() => {
          // the light cone of the first event: future above, past below, elsewhere to the sides
          const [a, b] = e1, k = 30;
          const fut = path([P(a, b), P(a + k, b + k), P(a + k, b - k)]) + " Z", past = path([P(a, b), P(a - k, b + k), P(a - k, b - k)]) + " Z";
          return <g><path d={fut} className="b2cone" /><path d={past} className="b2cone past" /></g>;
        })()}
        {mode === "boost" && Array.from({ length: 21 }, (_, i) => i - 10).map(k => (
          <g key={`tg${k}`}>
            <line className="b2tgrid" {...line([(k / g) + beta * -L, -L], [(k / g) + beta * L, L])} />
            <line className="b2tgrid x" {...line([-L, (k / g) + beta * -L], [L, (k / g) + beta * L])} />
          </g>
        ))}
        {showHyp && [1, 2, 3].map(k => <path key={k} d={hyp(k * k)} className="b2hyp" />)}
        {mode === "interval" && Math.abs(s2) > 1e-9 && (s2 > 0 ? <path d={hyp(s2, false, Math.sign(e1[0]) || 1)} className="b2hyp on" /> : <><path d={hyp(s2, true, 1)} className="b2hyp on" /><path d={hyp(s2, true, -1)} className="b2hyp on" /></>)}
        {/* the ground's axes */}
        <line className="b2axis" {...line([-L, 0], [L, 0])} />
        <line className="b2axis" {...line([0, -L], [0, L])} />
        {/* light: 45° for everyone */}
        <line className="b2light" {...line([-L, -L], [L, L])} />
        <line className="b2light" {...line([-L, L], [L, -L])} />
        {/* the traveler: time axis (their worldline) and "now" line, ticks where the hyperbolas cross them */}
        {showTraveler && <>
          <line className="b2trav" {...line([-L, -L * beta], [L, L * beta])} />
          <line className="b2now" {...line([-L * beta, -L], [L * beta, L])} />
          {(mode === "free" || mode === "boost") && ticksOn(tAxis, 8).map(([x, y], i) => <circle key={`tt${i}`} cx={x} cy={y} r="3" className="b2dot trav" />)}
          {(mode === "free" || mode === "boost") && ticksOn(xAxis, 6).map(([x, y], i) => <circle key={`tx${i}`} cx={x} cy={y} r="3" className="b2dot now" />)}
        </>}
        {mode === "light" && <>
          {/* the lamp at rest, the rider passing it, and two balls thrown at half light speed */}
          <line className="b2world" {...line([-L, 0], [L, 0])} />
          <line className="b2trav" {...line([-L, -L * beta], [L, L * beta])} />
          <line className="b2ball" {...line([0, 0], [L, L * 0.5])} />
          <line className="b2ball" {...line([0, 0], [L, -L * 0.5])} />
          <circle {...(() => { const [x, y] = P(0, 0); return { cx: x, cy: y }; })()} r="7" className="b2flash" />
        </>}
        {mode === "pair" && <>
          {[[0, 0] as [number, number], e2].map((e, i) => <line key={`nl${i}`} className="b2now faint" {...line([e[0] - L * beta, e[1] - L], [e[0] + L * beta, e[1] + L])} />)}
          {flag(props, "sweep") && <line className="b2now sweep" {...line([sweep / g - L * beta, -L], [sweep / g + L * beta, L])} />}
          {[[0, 0] as [number, number], e2].map((e, i) => {
            const [x, y] = P(...e), lit = flag(props, "sweep") && sweep >= sweepTo(...e);
            return <g key={`ev${i}`}>
              <circle cx={x} cy={y} r={lit ? 10 : 7} className={`b2flash${lit ? " lit" : ""}`} {...(i === 1 && !quiet ? drag((px, py) => { const [a, b] = back(px, py); setE2([snap(a), snap(b)]); }) : {})} />
              <text x={x + 10} y={y - 10} className="b2t">{i === 0 ? "near" : "far"}</text>
            </g>;
          })}
        </>}
        {mode === "interval" && <>
          {!quiet && <line className="b2world" {...line([0, 0], e1)} />}
          {!quiet && tickPts([0, 0], e1, tauStraight).map(([x, y], i) => <circle key={`ts${i}`} cx={x} cy={y} r="3.2" className="b2dot trav" />)}
          {!quiet && <path className="b2bent" d={path([P(0, 0), P(...kink), P(...e1)])} />}
          {!quiet && [...tickPts([0, 0], kink, legTau([0, 0], kink)), ...tickPts(kink, e1, legTau(kink, e1))].map(([x, y], i) => <circle key={`tb${i}`} cx={x} cy={y} r="3.2" className="b2dot bent" />)}
          {!quiet && <circle {...(() => { const [x, y] = P(...kink); return { cx: x, cy: y }; })()} r="9" className="b2handle"
            {...drag((px, py) => { const [a, b] = back(px, py); setKink([a, b]); })} />}
          {!quiet && Math.abs(beta) > 0.01 && <circle {...(() => { const [x, y] = P(...e1p); return { cx: x, cy: y }; })()} r="6" className="b2ghost" />}
        </>}
        {/* the events */}
        {(mode === "free" || mode === "boost" || mode === "interval") && !hideEvent && (
          <g>
            {(() => { const [x, y] = P(0, 0); return <circle cx={x} cy={y} r="4" className="b2dot" />; })()}
            {(() => {
              const [x, y] = P(...e1);
              return <g>
                <circle cx={x} cy={y} r="7" className={`b2event${applied ? " lit" : ""}`} />
                {!quiet ? <circle cx={x} cy={y} r="16" className="b2hit" {...drag((px, py) => { const [a, b] = back(px, py); setE1([snap(a), snap(b)]); })} /> : null}
                <text x={x + 10} y={y - 10} className="b2t">{frame === "traveler" ? `(${nice(e1p[0])}, ${nice(e1p[1])})` : `(${nice(e1[0])}, ${nice(e1[1])})`}</text>
              </g>;
            })()}
          </g>
        )}
        {marker && (() => {
          const [x, y] = [ox + (marker[1] - x0) * s, H - oy - (marker[0] - t0) * s];
          return <g>
            <circle cx={x} cy={y} r="8" className="b2marker" />
            <circle cx={x} cy={y} r="22" className="b2hit" {...(onMarker ? drag((px, py) => { const [a, b] = back(px, py); onMarker([snap(a), snap(b)]); }) : {})} />
            <text x={x + 12} y={y + 18} className="b2t">({fx(marker[0], 1)}, {fx(marker[1], 1)})</text>
          </g>;
        })()}
      </g>
      {/* axis names */}
      {(() => { const [x, y] = P(t1 - 0.4, 0); return <text x={x + 6} y={Math.max(16, y)} className="b2t">ct</text>; })()}
      <text x={W - 6} y={Math.min(H - 6, P(0, x1)[1] - 6)} textAnchor="end" className="b2t">x</text>
      {showTraveler && (() => { const [x, y] = P(Math.min(t1 - 1, 6) * g * 0.8, Math.min(t1 - 1, 6) * g * beta * 0.8); return <text x={x + 8} y={y} className="b2t trav">ct′</text>; })()}
    </svg>
  );

  const controls = (
    <>
      <Slider label="Traveler speed β" value={beta} min={-0.95} max={0.95} step={0.01} onChange={setBeta} format={v => `${fx(v)}c`} marks={BETA_MARKS} />
      {(mode === "light" || mode === "boost" || mode === "free") && !flag(props, "lockFrame") && (
        <Toggle label="Frame" value={frame} onChange={setFrame} options={[{ v: "ground", label: mode === "light" ? "Lamp's frame" : "Ground's frame" }, { v: "traveler", label: mode === "light" ? "Your frame" : "Traveler's frame" }]} />
      )}
    </>
  );

  let readouts;
  if (mode === "light") readouts = <>
    <Read label="γ" value={fx(g)} />
    <Read label="Ball ahead" value={`${fx(lightBall(0.5))}c`} tone="mint" />
    <Read label="Light ahead" value={quiet ? "?" : flag(props, "measure") ? "c in both frames" : "1.00c"} tone="amber" />
  </>;
  else if (mode === "pair") {
    const d = g * (e2[0] - beta * e2[1]);
    readouts = quiet ? <Read label="γ" value={fx(g)} /> : <>
      <Read label="γ" value={nice(g)} />
      <Read label="Δt′" value={nice(d)} tone="sky" />
      <Read label="Δx′" value={nice(g * (e2[1] - beta * e2[0]))} tone="pink" />
      <Read label="First for the traveler" value={Math.abs(d) < 1e-9 ? "both at once" : d < 0 ? "the far flash" : "the near flash"} />
    </>;
  } else if (mode === "boost") {
    const M = boost(beta);
    readouts = <>
      <span className="b2mat" aria-label="The boost matrix">
        <small>Λ</small>
        <span className="b2grid2">{M.flat().map((v, i) => <b key={i}>{quiet ? "?" : nice(v)}</b>)}</span>
      </span>
      {!quiet && !hideEvent && <Read label="(ct′, x′)" value={`(${nice(e1p[0])}, ${nice(e1p[1])})`} tone="sky" />}
      {!quiet && <Read minor label="det Λ" value="1" />}
      {!quiet && <button type="button" className="ctl b2send" onClick={() => sendBoost(beta)}>Boost to Matrix pad ›</button>}
    </>;
  } else if (mode === "interval") {
    readouts = quiet ? undefined : <>
      <Read label="s²" value={nice(s2)} />
      <Read label="(cΔt′, Δx′)" value={`(${fx(e1p[0])}, ${fx(e1p[1])})`} tone="sky" />
      <Read label="τ straight" value={Number.isFinite(tauStraight) ? fx(tauStraight) : "no clock"} tone="sky" />
      <Read label="τ bent" value={Number.isFinite(tauBent) ? fx(tauBent) : "faster than light"} tone="mint" />
    </>;
  } else {
    readouts = <>
      <Read label="γ" value={fx(g)} />
      <Read label="(ct, x)" value={`(${fx(e1[0], 1)}, ${fx(e1[1], 1)})`} />
      <Read label="(ct′, x′)" value={`(${fx(e1p[0])}, ${fx(e1p[1])})`} tone="sky" />
      <Read label="Its kind from the origin" value={s2 > 1e-9 ? "timelike" : s2 < -1e-9 ? "spacelike" : "lightlike"} />
      <button type="button" className="ctl b2send" onClick={() => sendBoost(beta)}>Boost to Matrix pad ›</button>
    </>;
  }
  return <Scene svg={svg} controls={controls} readouts={readouts} />;
}
