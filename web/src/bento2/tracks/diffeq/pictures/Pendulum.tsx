// The pendulum lab (diffeq.md, "New for Development" 6): a bob on a rigid rod swinging in real time, the release angle
// up to 179° or a push from the bottom that can send it over the top, its (θ, θ′) path on the phase plane with the
// separatrix, and an energy bar. Two pendulums side by side for de-10's reveal; the seconds pendulum saves L_pend
// and T_pend.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, Toggle } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { G, pendulumPeriod, smallPeriod, solve } from "../maths";
import { frame, useLoop } from "./plot";

const W = 360, H = 270, D2R = Math.PI / 180;

/** one full cycle of the swing (or one turn over the top), sampled */
function cycle(L: number, th0: number, w0: number) {
  const f = (_t: number, y: number[]) => [y[1]!, -(G / L) * Math.sin(y[0]!)];
  if (w0 === 0) {
    const T = pendulumPeriod(L, th0);
    return { T, pts: solve(f, [th0, 0], 0, T, T / 400) };
  }
  // pushed from the bottom with angular speed w0
  const top = 2 * Math.sqrt(G / L);
  if (w0 < top) {
    const amp = 2 * Math.asin(w0 / top), T = pendulumPeriod(L, amp);
    return { T, pts: solve(f, [0, w0], 0, T, T / 400) };
  }
  const pts = [{ t: 0, y: [0, w0] }];
  let y = [0, w0], t = 0;
  const h = 0.004;
  while (y[0]! < 2 * Math.PI && t < 30) { const s = solve(f, y, t, t + h, h)[1]!; y = s.y; t = s.t; pts.push({ t, y }); }
  return { T: t, pts };
}

function Bob({ cx, L, th, tone }: { cx: number; L: number; th: number; tone: string }) {
  const len = 40 + 52 * L, x = cx + len * Math.sin(th), y = 26 + len * Math.cos(th);
  return (
    <g>
      <circle cx={cx} cy="26" r={len} className="b2orbit" />
      <line x1={cx - 16} y1="26" x2={cx + 16} y2="26" className="b2axis" />
      <line x1={cx} y1="26" x2={x} y2={y} className="b2leg" style={{ strokeWidth: 2.5 }} />
      <circle cx={x} cy={y} r="10" className={`b2dot ${tone}`} />
    </g>
  );
}

export function PendulumScene({ props, place }: SceneProps) {
  const { b2, save } = useB2();
  const [L, setL] = useState(num(props, "L", 1));
  const [deg, setDeg] = useState(num(props, "th0", 40));
  const [mode, setMode] = useState<"release" | "push">("release");
  const [v, setV] = useState(5);
  const quiet = flag(props, "quiet"), twin = num(props, "twin", 0), seconds = flag(props, "seconds");
  const w = Math.sqrt(G / L), vTop = 2 * Math.sqrt(G * L);
  const main = useMemo(() => cycle(L, deg * D2R, mode === "push" ? v / L : 0), [L, deg, mode, v]);
  const other = useMemo(() => (twin ? cycle(L, twin * D2R, 0) : null), [L, twin]);
  const ten = useMemo(() => (twin ? cycle(L, 10 * D2R, 0) : null), [L, twin]);
  const t = useLoop(0);
  const at = (c: { T: number; pts: { t: number; y: number[] }[] }) => c.pts[Math.min(c.pts.length - 1, Math.floor(((t % c.T) / c.T) * (c.pts.length - 1)))]!.y;
  const [th = 0, thd = 0] = at(main);
  const ph = frame(-Math.PI, Math.PI, -3.2 * w, 3.2 * w, { l: twin ? 360 : 196, r: 352, t: 14, b: 196 });
  const wrap = (a: number) => Math.atan2(Math.sin(a), Math.cos(a));
  const orbit = (amp: number) => { const pts: [number, number][] = []; for (let k = 0; k <= 80; k++) { const a = -amp + (2 * amp * k) / 80; pts.push([ph.X(a), ph.Y(Math.sqrt(Math.max(0, 2 * w * w * (Math.cos(a) - Math.cos(amp)))))]); } return path(pts) + " " + path(pts.map(([x, y]) => [x, 2 * ph.Y(0) - y] as [number, number])).replace("M", "L"); };
  const sep = (s: 1 | -1) => path(Array.from({ length: 81 }, (_, k) => { const a = -Math.PI + (2 * Math.PI * k) / 80; return [ph.X(a), ph.Y(s * 2 * w * Math.cos(a / 2))] as [number, number]; }));
  const trace = path(main.pts.map(p => [ph.X(wrap(p.y[0]!)), ph.Y(p.y[1]!)] as [number, number]).filter((p, i, arr) => i === 0 || Math.abs(p[0] - arr[i - 1]![0]) < 100));
  const E = 0.5 * L * L * thd * thd + G * L * (1 - Math.cos(th)), Emax = 0.5 * L * L * main.pts[0]!.y[1]! ** 2 + G * L * (1 - Math.cos(main.pts[0]!.y[0]!));
  const ke = E > 0 ? (0.5 * L * L * thd * thd) / Emax : 0;
  const T0 = smallPeriod(L), Tnow = mode === "release" ? pendulumPeriod(L, deg * D2R) : main.T;
  const project = place === "project" || flag(props, "saveable");
  const saved = b2.shelf.L_pend?.value === L && b2.shelf.T_pend?.value === T0;
  const onSave = () => {
    save("L_pend", L, "b2-de-10", { unit: "m", note: "the clock pendulum's length" });
    save("T_pend", T0, "b2-de-10", { unit: "s", note: "its small-swing period" });
  };
  const bar = { l: twin ? 30 : 20, r: twin ? 330 : 176, y: 236 };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A ${fx(L, 2)} m pendulum ${mode === "push" ? `pushed at ${fx(v, 1)} m/s` : `released at ${deg} degrees`}; small-swing period ${fx(T0, 2)} s.`}>
      {other ? <>
        <Bob cx={95} L={L} th={at(ten!)[0]!} tone="sky" />
        <Bob cx={265} L={L} th={at(other)[0]!} tone="pink" />
        <text x="95" y="212" textAnchor="middle" className="b2t sky">10°</text>
        <text x="265" y="212" textAnchor="middle" className="b2t pink">{twin}°</text>
      </> : <Bob cx={98} L={L} th={th} tone="trav" />}
      {!twin && <g>
        <rect x={ph.box.l} y={ph.box.t} width={ph.box.r - ph.box.l} height={ph.box.b - ph.box.t} rx="8" className="b2bar track" />
        <line x1={ph.box.l} y1={ph.Y(0)} x2={ph.box.r} y2={ph.Y(0)} className="b2axis" opacity={0.6} />
        <line x1={ph.X(0)} y1={ph.box.t} x2={ph.X(0)} y2={ph.box.b} className="b2axis" opacity={0.6} />
        {[30, 90, 150].map(a => <path key={a} d={orbit(a * D2R)} className="b2grid strong" fill="none" />)}
        <path d={sep(1)} className="b2mark amber" /><path d={sep(-1)} className="b2mark amber" />
        <path d={trace} className="b2curve trav" style={{ strokeWidth: 2 }} />
        <circle cx={ph.X(wrap(th))} cy={ph.Y(thd)} r="5" className="b2dot trav" />
        <text x={ph.box.r - 4} y={ph.Y(0) - 5} textAnchor="end" className="b2t">θ</text>
        <text x={ph.X(0) + 5} y={ph.box.t + 12} className="b2t">θ′</text>
      </g>}
      {/* energy: moving (pink) and height (sky) share a fixed total */}
      <rect x={bar.l} y={bar.y} width={(bar.r - bar.l) * ke} height="12" rx="4" className="b2bar pink" />
      <rect x={bar.l + (bar.r - bar.l) * ke} y={bar.y} width={(bar.r - bar.l) * (1 - ke)} height="12" rx="4" className="b2bar sky" />
      <text x={bar.l} y={bar.y + 30} className="b2t pink">moving</text>
      <text x={bar.r} y={bar.y + 30} textAnchor="end" className="b2t sky">height</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Length L" value={L} min={0.25} max={2} step={0.001} onChange={setL} format={x => `${fx(x, 3)} m`} marks={seconds ? [{ v: 0.994, label: "0.994 m" }] : undefined} />
        {!twin && <Toggle label="Start" value={mode} onChange={setMode} options={[{ v: "release", label: "Release" }, { v: "push", label: "Push from the bottom" }]} />}
        {!twin && mode === "release" && <Slider label="Release angle" value={deg} min={5} max={179} step={1} onChange={setDeg} format={x => `${x}°`} />}
        {!twin && mode === "push" && <Slider label="Speed at the bottom" value={v} min={0.5} max={Math.ceil(vTop * 1.5)} step={0.05} onChange={setV} format={x => `${fx(x, 2)} m/s`} />}
      </>}
      readouts={<>
        <Read label="Small-swing period" value={`${fx(T0, 2)} s`} tone="sky" />
        {!quiet && !twin && <Read label={mode === "push" && v / L >= 2 * w ? "Time per turn" : "This swing's period"} value={`${fx(Tnow, 2)} s`} tone="trav" />}
        {!quiet && !twin && mode === "push" && <Read label="Over the top above" value={`${fx(vTop, 2)} m/s`} tone="amber" />}
        {twin > 0 && <Read label={`${twin}° over 10°`} value={`× ${fx(pendulumPeriod(L, twin * D2R) / pendulumPeriod(L, 10 * D2R), 3)}`} tone="pink" big />}
      </>}
      foot={project ? <SaveRow what={<>Keep <b>L_pend = {fx(L, 3)} m</b> and <b>T_pend = {fx(T0, 2)} s</b></>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
