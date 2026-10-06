// The Eigen finder (linear-algebra.md, "New for Development"): a test arrow on the unit circle and its image under A.
// When the two line up the arrow glows and the ratio of their lengths is λ. Modes: find (13), iterate (14, a trail of
// A x, A² x, A³ x … swinging onto one line), and stretch (17, the circle's image with the most-stretched arrow marked;
// in Use it it reads your filter M from the shelf and keeps its singular values as sigmaM).
import { useEffect, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, useSvgDrag, useTween } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { apply2, det2, norm, svd2, type Vec } from "../maths";
import { Arrow, Grid, ink, MatRead, plane, poly, tint, tintEdge } from "./plane";

type Mode = "find" | "iterate" | "stretch";
const ang = (v: Vec) => Math.atan2(v[1]!, v[0]!);
/** the real eigen-directions of a 2 × 2 (angles in [0, π)) */
function eigenAngles(A: number[][]): { th: number; l: number }[] {
  const t = A[0]![0]! + A[1]![1]!, d = det2(A), disc = t * t - 4 * d;
  if (disc < -1e-12) return [];
  const ls = disc < 1e-12 ? [t / 2] : [(t + Math.sqrt(disc)) / 2, (t - Math.sqrt(disc)) / 2];
  return ls.flatMap(l => {
    const r0 = [A[0]![0]! - l, A[0]![1]!], r1 = [A[1]![0]!, A[1]![1]! - l];
    const r = norm(r0) > norm(r1) ? r0 : r1;
    if (norm(r) < 1e-12) return [{ th: 0, l }, { th: Math.PI / 2, l }];
    let th = Math.atan2(r[0]!, -r[1]!);
    if (th < 0) th += Math.PI;
    if (th >= Math.PI - 1e-9) th -= Math.PI;
    return [{ th, l }];
  });
}

export function EigenScene({ props, place, marker, onMarker }: SceneProps) {
  const mode = str<Mode>(props, "mode", "find");
  const quiet = flag(props, "quiet") || flag(props, "hide");
  const { ref, drag } = useSvgDrag();
  const { b2, save } = useB2();
  const shelfM = b2.shelf.M?.value as number[][] | undefined;
  const useM = flag(props, "useShelf") && Array.isArray(shelfM) && shelfM.length === 2 && Array.isArray(shelfM[0]);
  const A = useM ? shelfM! : [[num(props, "a", 4), num(props, "b", 1)], [num(props, "c", 2), num(props, "d", 3)]];
  const [th, setTh] = useState(num(props, "th", 0.35));
  const [n, setN] = useState(num(props, "n", 0));
  const big = mode === "find" ? Math.max(3, ...eigenAngles(A).map(e => Math.abs(e.l) + 0.6)) : 5;
  const p = plane(-big, big, -big * 0.78, big * 0.78, 360, 280);
  const eig = eigenAngles(A);

  // the reveal for 13 sweeps the test arrow round once, marking every match it passes
  const [sweepGoal, setSweepGoal] = useState(0);
  const sweep = useTween(sweepGoal, 3600);
  useEffect(() => { if (flag(props, "sweep")) setSweepGoal(2 * Math.PI); }, []); // eslint-disable-line react-hooks/exhaustive-deps
  // the reveal for 14 runs 50 steps
  const [runGoal, setRunGoal] = useState(0);
  const run = useTween(runGoal, 3000);
  useEffect(() => { if (flag(props, "run50")) setRunGoal(50); }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const sweeping = flag(props, "sweep") && mode !== "iterate";
  const theta = sweeping ? sweep : th;
  const x = [Math.cos(theta), Math.sin(theta)], Ax = apply2(A, x);
  const off = Math.abs(Math.sin(ang(Ax) - theta));
  const lined = norm(Ax) < 1e-9 || off < 0.02;
  const lam = Ax[0]! * x[0]! + Ax[1]! * x[1]!;
  const onCircle = (px: number, py: number) => {
    const [X, Y] = p.back(px, py);
    let a = Math.atan2(Y, X);
    // a gentle pull onto a matching direction, so the glow can be found by hand
    for (const e of eig) for (const c of [e.th, e.th + Math.PI, e.th - Math.PI]) if (Math.abs(a - c) < 0.035) a = c;
    setTh(a);
  };
  const s = svd2(A);
  let body: React.ReactNode = null, readouts: React.ReactNode = null, controls: React.ReactNode = null, foot: React.ReactNode = null;
  const circle = Array.from({ length: 97 }, (_, i) => { const a = (2 * Math.PI * i) / 96; return [Math.cos(a), Math.sin(a)]; });

  if (mode === "find" || mode === "stretch") {
    const passed = sweeping ? eig.flatMap(e => [e.th, e.th + Math.PI].filter(c => c <= sweep).map(c => ({ c, l: e.l }))) : [];
    body = <>
      {mode === "stretch" && !quiet && <polygon points={poly(p, circle.map(v => apply2(A, v)))} style={tintEdge("sky", 0.1)} />}
      <polyline points={poly(p, circle)} style={ink("trav", 1.4, "4 4")} />
      {!quiet && mode === "find" && eig.map((e, i) => <line key={i} x1={p.X(-9 * Math.cos(e.th))} y1={p.Y(-9 * Math.sin(e.th))} x2={p.X(9 * Math.cos(e.th))} y2={p.Y(9 * Math.sin(e.th))} className="b2mark amber" opacity={flag(props, "showLines") ? 1 : 0} />)}
      {passed.map((m, i) => <g key={i}>
        <line x1={p.X(0)} y1={p.Y(0)} x2={p.X(Math.cos(m.c) * Math.max(1, Math.abs(m.l)))} y2={p.Y(Math.sin(m.c) * Math.max(1, Math.abs(m.l)))} style={ink("amber", 2.5)} />
        <circle cx={p.X(Math.cos(m.c))} cy={p.Y(Math.sin(m.c))} r="6" className="b2dot amber" />
      </g>)}
      {mode === "stretch" && flag(props, "most") && <>
        <line x1={p.X(-s.u[0]![0]! * s.s[0])} y1={p.Y(-s.u[0]![1]! * s.s[0])} x2={p.X(s.u[0]![0]! * s.s[0])} y2={p.Y(s.u[0]![1]! * s.s[0])} style={ink("amber", 3)} />
        <Arrow p={p} to={s.v[0]!} tone="amber" dash="4 3" label="most stretched" />
      </>}
      {!quiet && lined && <circle cx={p.X(x[0]!)} cy={p.Y(x[1]!)} r="16" style={tint("amber", 0.35)} />}
      {!quiet && <Arrow p={p} to={Ax} tone="pink" label="Ax" width={3} />}
      {!(quiet && mode === "stretch") && <Arrow p={p} to={x} tone="sky" label="x" width={3} />}
      {!quiet && !sweeping && <circle cx={p.X(x[0]!)} cy={p.Y(x[1]!)} r="22" className="b2hit" {...drag(onCircle)} />}
      {marker && <g>
        <line x1={p.X(0)} y1={p.Y(0)} x2={p.X(marker[0])} y2={p.Y(marker[1])} className="b2mark" />
        <circle cx={p.X(marker[0])} cy={p.Y(marker[1])} r="8" className="b2marker" />
        {onMarker && <circle cx={p.X(marker[0])} cy={p.Y(marker[1])} r="22" className="b2hit" {...drag((px, py) => { const [X, Y] = p.back(px, py); const a = Math.atan2(Y, X); onMarker([r2(Math.cos(a)), r2(Math.sin(a))]); })} />}
      </g>}
    </>;
    readouts = <>
      <MatRead label="A" M={A.map(r => r.map(v => r2(v)))} />
      {!quiet && mode === "find" && <Read label="x and Ax" value={lined ? "lined up" : `${fx((Math.asin(Math.min(1, off)) * 180) / Math.PI, 0)}° apart`} tone={lined ? "amber" : undefined} />}
      {!quiet && mode === "find" && <Read label="λ = |Ax| / |x|, signed" value={lined ? fx(lam, 2) : "only when lined up"} tone="amber" />}
      {!quiet && mode === "stretch" && <Read label="|Ax|, the stretch" value={fx(norm(Ax), 2)} tone="pink" />}
      {!quiet && mode === "stretch" && <Read label="σ₁, σ₂" value={`${fx(s.s[0], 2)}, ${fx(s.s[1], 2)}`} tone="amber" />}
    </>;
    if (mode === "stretch" && flag(props, "save")) {
      const val = [r4(s.s[0]), r4(s.s[1])];
      const saved = JSON.stringify(b2.shelf.sigmaM?.value) === JSON.stringify(val);
      foot = <SaveRow what={useM ? <>Keep <b>sigmaM</b> = {fx(s.s[0], 2)}, {fx(s.s[1], 2)}, from your filter M</> : <>No filter M on your shelf yet: this keeps A's, <b>sigmaM</b> = {fx(s.s[0], 2)}, {fx(s.s[1], 2)}</>}
        saved={saved} onSave={() => save("sigmaM", val, place === "project" ? "la-filter" : "b2-la-17", { labels: ["σ₁", "σ₂"], note: useM ? "the singular values of your filter M" : "singular values" })} />;
    }
  } else {
    // iterate: each Aᵏx shown by its direction on a ring, the newest brightest
    const x0 = [num(props, "x0", 0), num(props, "y0", 1)];
    const steps = flag(props, "run50") ? Math.round(run) : n;
    const dirs: Vec[] = [];
    let v = x0;
    for (let k = 0; k <= steps; k++) { dirs.push(v); v = apply2(A, v); const l = norm(v); if (l > 1e-12) v = v.map(c => c / l); }
    const R = 3.4;
    const lastDir = dirs[dirs.length - 1]!.map(c => c / (norm(dirs[dirs.length - 1]!) || 1));
    body = <>
      <polyline points={poly(p, circle.map(c => c.map(z => z * R)))} style={ink("trav", 1, "3 5")} />
      {!quiet && eig.map((e, i) => <line key={i} x1={p.X(-9 * Math.cos(e.th))} y1={p.Y(-9 * Math.sin(e.th))} x2={p.X(9 * Math.cos(e.th))} y2={p.Y(9 * Math.sin(e.th))} className="b2mark amber" />)}
      {dirs.map((d, k) => { const u = d.map(c => (c / (norm(d) || 1)) * R); return <circle key={k} cx={p.X(u[0]!)} cy={p.Y(u[1]!)} r={k === dirs.length - 1 ? 6 : 4} className="b2dot pink" opacity={0.25 + 0.75 * ((k + 1) / dirs.length)} />; })}
      <Arrow p={p} to={lastDir.map(c => c * R)} tone="pink" label={steps === 0 ? "x" : steps === 1 ? "Ax" : `A${sup(steps)}x`} width={3} />
      {marker && <g>
        <line x1={p.X(0)} y1={p.Y(0)} x2={p.X(marker[0] * R)} y2={p.Y(marker[1] * R)} className="b2mark" />
        <circle cx={p.X(marker[0] * R)} cy={p.Y(marker[1] * R)} r="8" className="b2marker" />
        {onMarker && <circle cx={p.X(marker[0] * R)} cy={p.Y(marker[1] * R)} r="22" className="b2hit" {...drag((px, py) => { const [X, Y] = p.back(px, py); const a = Math.atan2(Y, X); onMarker([r2(Math.cos(a)), r2(Math.sin(a))]); })} />}
      </g>}
    </>;
    controls = !flag(props, "run50") ? <Slider label="Steps n" value={n} min={0} max={20} step={1} onChange={setN} format={k => String(k)} /> : undefined;
    const e1 = eig[0];
    readouts = <>
      <MatRead label="A" M={A.map(r => r.map(c => r2(c)))} />
      {!quiet && eig.length > 0 && <Read label="λ₁, λ₂" value={eig.map(e => fx(e.l, 2)).join(", ")} tone="amber" />}
      {!quiet && e1 && <Read label="Aⁿx heads for the line of" value={`λ = ${fx(e1.l, 2)}`} tone="amber" />}
    </>;
  }
  const svg = (
    <svg ref={ref} viewBox="0 0 360 280" className="b2pic" role="img" aria-label={`Eigen finder, ${mode}. A = ${JSON.stringify(A)}.`}>
      <Grid p={p} />
      {body}
    </svg>
  );
  return <Scene svg={svg} controls={controls} readouts={readouts} foot={foot} />;
}

const r2 = (x: number) => Math.round(x * 100) / 100;
const r4 = (x: number) => Math.round(x * 10000) / 10000;
const SUP: Record<string, string> = { "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹" };
const sup = (k: number) => String(k).replace(/./g, d => SUP[d] ?? d);
