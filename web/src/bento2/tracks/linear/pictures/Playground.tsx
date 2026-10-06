// ★ The Transformation playground (linear-algebra.md, "New for Development"): drag the two column arrows of a 2 × 2
// matrix and the grid, a letter F and the unit square bend with them. Modes: move (05), compose (06, "A then B" with
// an order switch), det (07, signed area, shaded pink when the picture flips), undo (08, Undo applies A⁻¹ and grays
// out at det 0), circle (15 and 17, the unit circle to an ellipse with its axes and the arrows that land on them),
// and filter (the project "Filter and undo": a turn, a shear and a scale chained on an 8 × 8 sprite).
import { useEffect, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, Toggle, useSvgDrag, useTween } from "../../../ui/kit";
import { Surface3D } from "../../../ui/Surface3D";
import { useB2 } from "../../../ui/useB2";
import { apply2, det2, inv2, mm, sn, svd2, sym2, type Vec } from "../maths";
import { Arrow, Grid, Handle, ink, MatRead, plane, poly, pt, snap, tint, tintEdge, type Plane } from "./plane";

type Mode = "move" | "compose" | "det" | "undo" | "circle" | "filter";
type M2 = number[][];
const I2: M2 = [[1, 0], [0, 1]];
const lerp = (A: M2, B: M2, t: number): M2 => A.map((r, i) => r.map((x, j) => x + (B[i]![j]! - x) * t));
/** the letter F: it shows a turn, a stretch and (most of all) a mirror */
const F = [[0, 0], [0, 2], [1.2, 2], [1.2, 1.6], [0.4, 1.6], [0.4, 1.2], [1, 1.2], [1, 0.8], [0.4, 0.8], [0.4, 0]];
const SQ = [[0, 0], [1, 0], [1, 1], [0, 1]];
const PRESETS: Record<string, { M: M2; label: string }> = {
  turn: { M: [[0, -1], [1, 0]], label: "Turn" }, shear: { M: [[1, 1], [0, 1]], label: "Shear" },
  stretch: { M: [[2, 0], [0, 1]], label: "Stretch" }, mirror: { M: [[1, 0], [0, -1]], label: "Mirror" },
};
/** an 8 × 8 sprite (a little ship) for the filter */
const SPRITE = ["...##...", "..####..", "..#..#..", ".######.", "########", "##.##.##", "#..##..#", "...##..."];

/** the image of the grid under M: whole-number lines, bent */
function BentGrid({ p, M, n = 8, o = 0.45 }: { p: Plane; M: M2; n?: number; o?: number }) {
  const L = 30, out = [];
  for (let k = -n; k <= n; k++) {
    const a = apply2(M, [k, -L]), b = apply2(M, [k, L]), c = apply2(M, [-L, k]), d = apply2(M, [L, k]);
    out.push(<line key={`v${k}`} x1={p.X(a[0]!)} y1={p.Y(a[1]!)} x2={p.X(b[0]!)} y2={p.Y(b[1]!)} style={{ ...ink("trav", k === 0 ? 1.6 : 1), opacity: k === 0 ? 0.9 : o }} />);
    out.push(<line key={`h${k}`} x1={p.X(c[0]!)} y1={p.Y(c[1]!)} x2={p.X(d[0]!)} y2={p.Y(d[1]!)} style={{ ...ink("trav", k === 0 ? 1.6 : 1), opacity: k === 0 ? 0.9 : o }} />);
  }
  return <g>{out}</g>;
}
const shape = (p: Plane, M: M2, pts: number[][]) => poly(p, pts.map(v => apply2(M, v)));

export function PlaygroundScene(sp: SceneProps) {
  const mode = str<Mode>(sp.props, "mode", "move");
  if (mode === "compose") return <ComposeView {...sp} />;
  if (mode === "circle") return <CircleView {...sp} />;
  if (mode === "filter") return <FilterView {...sp} />;
  return <MoveView {...sp} mode={mode} />;
}

/** what every view shares: the plane, dragging, the columns, the saved data, and a tween for reveals and Undo */
function useBase({ props, place }: SceneProps, mode: Mode) {
  const quiet = flag(props, "quiet") || flag(props, "hide");
  const project = flag(props, "project") || place === "project";
  const { ref, drag } = useSvgDrag();
  const { b2, save, note } = useB2();
  const [c1, setC1] = useState<Vec>([num(props, "a", 2), num(props, "c", 1)]);
  const [c2, setC2] = useState<Vec>([num(props, "b", -1), num(props, "d", 1)]);
  const A: M2 = [[c1[0]!, c2[0]!], [c1[1]!, c2[1]!]];
  const big = mode === "circle" ? 4.2 : 5;
  const p = plane(-big, big, -big * 0.8, big * 0.8, 360, 280);
  const tipDrag = (set: (v: Vec) => void) => drag((px, py) => { const [x, y] = p.back(px, py); set([clampv(snap(x, 0.5)), clampv(snap(y, 0.5))]); });
  const [goal, setGoal] = useState(0);
  const t = useTween(goal, mode === "compose" ? 2400 : 1300);
  useEffect(() => { if (flag(props, "walk") || flag(props, "both") || flag(props, "proof") || flag(props, "plot")) setGoal(mode === "compose" ? 2 : 1); }, []); // eslint-disable-line react-hooks/exhaustive-deps
  const handles = !quiet && <>
    <Handle at={p.P(c1)} tone="sky" drag={tipDrag(setC1)} r={6} />
    <Handle at={p.P(c2)} tone="pink" drag={tipDrag(setC2)} r={6} />
  </>;
  const columns = <>
    <Arrow p={p} to={c1} tone="sky" label={quiet ? undefined : pt(c1)} />
    <Arrow p={p} to={c2} tone="pink" label={quiet ? undefined : pt(c2)} />
  </>;
  return { quiet, project, ref, drag, b2, save, note, c1, c2, A, D: det2(A), p, goal, setGoal, t, handles, columns };
}

function Frame({ base, mode, body, marker, onMarker, controls, readouts, foot }: {
  base: ReturnType<typeof useBase>; mode: Mode; body: React.ReactNode; marker?: [number, number]; onMarker?: (p: [number, number]) => void;
  controls?: React.ReactNode; readouts?: React.ReactNode; foot?: React.ReactNode;
}) {
  const { p, ref, drag, c1, c2, D } = base;
  const svg = (
    <svg ref={ref} viewBox="0 0 360 280" className="b2pic" role="img" aria-label={base.quiet ? `Transformation playground, ${mode}.` : `Transformation playground, ${mode}. Columns ${pt(c1)} and ${pt(c2)}, det ${sn(D)}.`}>
      <Grid p={p} />
      {body}
      {marker && mode !== "circle" && <g>
        <circle cx={p.X(marker[0])} cy={p.Y(marker[1])} r="8" className="b2marker" />
        {onMarker && <circle cx={p.X(marker[0])} cy={p.Y(marker[1])} r="22" className="b2hit" {...drag((px, py) => { const [x, y] = p.back(px, py); onMarker([snap(x, 0.5), snap(y, 0.5)]); })} />}
        <text x={p.X(marker[0]) + 11} y={p.Y(marker[1]) + 20} className="b2t">your guess</text>
      </g>}
    </svg>
  );
  return <Scene svg={svg} controls={controls} readouts={readouts} foot={foot} />;
}

function MoveView(sp: SceneProps & { mode: Mode }) {
  const { props, marker, onMarker, mode } = sp;
  const base = useBase(sp, mode);
  const { quiet, p, A, D, c1, c2, t, goal, setGoal, handles, columns } = base;
  // undo: the picture plays A, then A⁻¹ brings it home
  const shown = mode === "undo" ? (t <= 1 ? lerp(I2, A, t) : Math.abs(D) > 1e-9 ? lerp(A, I2, t - 1) : A) : A;
  const flip = D < 0;
  const x = [num(props, "px", 2), num(props, "py", 1)];
  const Ax = apply2(A, x);
  const walk = flag(props, "walk");
  const w1 = Math.min(1, t * 2), w2 = Math.max(0, Math.min(1, t * 2 - 1));
  const proof = mode === "det" && flag(props, "proof") && !quiet && D > 0 && [c1[0]!, c1[1]!, c2[0]!, c2[1]!].every(v => v >= 0);
  const [a, c, b, d] = [c1[0]!, c1[1]!, c2[0]!, c2[1]!];
  const body = <>
    <BentGrid p={p} M={shown} />
    <polygon points={shape(p, shown, SQ)} style={mode === "det" ? tintEdge(flip ? "pink" : "sky", 0.22) : tint("amber", 0.16)} />
    {mode !== "det" && <polygon points={shape(p, shown, F)} style={tintEdge("mint", 0.3)} />}
    {proof && <g opacity={Math.min(1, t * 1.5)}>
      {/* the box around the parallelogram, less two pairs of triangles and two rectangles */}
      <rect x={p.X(0)} y={p.Y(c + d)} width={(a + b) * p.s} height={(c + d) * p.s} style={ink("amber", 1.5, "5 4")} />
      <polygon points={poly(p, [[0, 0], [a, 0], [a, c]])} style={tint("trav", 0.3)} />
      <polygon points={poly(p, [[b, d], [b, c + d], [a + b, c + d]])} style={tint("trav", 0.3)} />
      <polygon points={poly(p, [[0, 0], [0, d], [b, d]])} style={tint("mint", 0.3)} />
      <polygon points={poly(p, [[a, c], [a + b, c], [a + b, c + d]])} style={tint("mint", 0.3)} />
      <polygon points={poly(p, [[a, 0], [a + b, 0], [a + b, c], [a, c]])} style={tint("amber", 0.3)} />
      <polygon points={poly(p, [[0, d], [b, d], [b, c + d], [0, c + d]])} style={tint("amber", 0.3)} />
    </g>}
    {columns}
    {mode === "move" && walk && <>
      <Arrow p={p} to={[2 * a * w1, 2 * c * w1]} tone="sky" width={4} />
      {w2 > 0 && <Arrow p={p} from={[2 * a, 2 * c]} to={[2 * a + b * w2, 2 * c + d * w2]} tone="pink" width={4} />}
      {[1, 2].map(k => w1 * 2 >= k && <circle key={k} cx={p.X(k * a)} cy={p.Y(k * c)} r="3.5" className="b2dot sky" />)}
    </>}
    {mode === "move" && (!quiet || (walk && t > 0.95)) && <><circle cx={p.X(Ax[0]!)} cy={p.Y(Ax[1]!)} r="6" className="b2dot amber" /><text x={p.X(Ax[0]!) + 8} y={p.Y(Ax[1]!) + 18} className="b2t amber">{pt(Ax)}</text></>}
    {handles}
    {mode === "undo" && flag(props, "plot") && <InversePlot t={t} />}
  </>;
  const controls = mode === "undo" ? <>
    <button type="button" className="ctl" onClick={() => setGoal(1)} aria-pressed={goal === 1}>Apply A</button>
    <button type="button" className="ctl" disabled={Math.abs(D) < 1e-9 || goal !== 1} onClick={() => setGoal(2)}>Undo with A⁻¹</button>
    <button type="button" className="ctl" onClick={() => setGoal(0)}>Start over</button>
  </> : undefined;
  const inv = Math.abs(D) > 1e-9 ? inv2(A) : null;
  const readouts = <>
    <MatRead label="A" M={A} hide={quiet} />
    {(mode === "det" || mode === "undo") && !quiet && <Read label="det A" value={sn(D)} tone={flip ? "pink" : "sky"} />}
    {mode === "det" && !quiet && <Read label="The square becomes" value={D === 0 ? "squashed flat" : `${fx(Math.abs(D), 2).replace(/\.?0+$/, "")} square units${flip ? ", mirrored" : ""}`} tone={flip ? "pink" : "sky"} />}
    {mode === "undo" && !quiet && (inv ? <MatRead label="A⁻¹" M={inv} tone="amber" /> : <Read label="A⁻¹" value="none: det is 0" />)}
    {mode === "move" && !quiet && <Read label={`A${pt(x)}`} value={pt(Ax)} tone="amber" />}
  </>;
  return <Frame base={base} mode={mode} body={body} marker={marker} onMarker={onMarker} controls={controls} readouts={readouts} />;
}

function ComposeView(sp: SceneProps) {
  const { props } = sp;
  const base = useBase(sp, "compose");
  const { p, t, goal, setGoal, quiet } = base;
  const [ka, setKa] = useState<string>(str(props, "A", "turn"));
  const [kb, setKb] = useState<string>(str(props, "B", "shear"));
  const [order, setOrder] = useState<"ab" | "ba">("ab");
  const Am = PRESETS[ka]!.M, Bm = PRESETS[kb]!.M;
  const first = order === "ab" ? Am : Bm, second = order === "ab" ? Bm : Am;
  const both = flag(props, "both");
  const at = (f: M2, s: M2) => (t <= 1 ? lerp(I2, f, t) : lerp(f, mm(s, f), t - 1));
  const one = at(first, second), other = at(second, first);
  const body = <>
    <BentGrid p={p} M={both ? I2 : one} o={0.3} />
    <polygon points={shape(p, I2, F)} style={ink("trav", 1.2, "4 4")} />
    <polygon points={shape(p, one, F)} style={tintEdge("sky", 0.3)} />
    {both && <polygon points={shape(p, other, F)} style={tintEdge("pink", 0.3)} />}
  </>;
  const controls = <>
    <Toggle label="Move A" value={ka} onChange={v => { setKa(v); setGoal(0); }} options={Object.entries(PRESETS).map(([k, v]) => ({ v: k, label: v.label }))} />
    <Toggle label="Move B" value={kb} onChange={v => { setKb(v); setGoal(0); }} options={Object.entries(PRESETS).map(([k, v]) => ({ v: k, label: v.label }))} />
    {!both && <Toggle label="Order" value={order} onChange={o => { setOrder(o); setGoal(0); }} options={[{ v: "ab", label: "A, then B" }, { v: "ba", label: "B, then A" }]} />}
    <button type="button" className="ctl go" onClick={() => setGoal(g => (g === 2 ? 0 : 2))}>{goal === 2 ? "Back to the start" : "Run"}</button>
  </>;
  const name = (k: string) => PRESETS[k]!.label.toLowerCase();
  const readouts = both ? <>
    <MatRead label={`${name(ka)}, then ${name(kb)}: BA`} M={mm(Bm, Am)} tone="sky" />
    <MatRead label={`${name(kb)}, then ${name(ka)}: AB`} M={mm(Am, Bm)} tone="pink" />
  </> : <>
    <MatRead label={`A (${name(ka)})`} M={Am} />
    <MatRead label={`B (${name(kb)})`} M={Bm} />
    {/* during a guess the product stays hidden: it would answer "same or different?" */}
    {!quiet && <MatRead label={order === "ab" ? "A, then B: BA" : "B, then A: AB"} M={mm(second, first)} tone="sky" />}
  </>;
  return <Frame base={base} mode="compose" body={body} controls={controls} readouts={readouts} />;
}

function CircleView(sp: SceneProps) {
  const { props, marker, onMarker } = sp;
  const base = useBase(sp, "circle");
  const { p, quiet, A, drag, handles, columns } = base;
  const symm = flag(props, "sym");
  const [sa, setSa] = useState(num(props, "sa", 2));
  const [sb, setSb] = useState(num(props, "sb", 1));
  const [sd, setSd] = useState(num(props, "sd", 2));
  const [view, setView] = useState<"ellipse" | "surface">("ellipse");
  const M: M2 = symm ? [[sa, sb], [sb, sd]] : A;
  const s = svd2(M), e = symm ? sym2(M) : null;
  const circ = Array.from({ length: 97 }, (_, i) => { const a = (2 * Math.PI * i) / 96; return [Math.cos(a), Math.sin(a)]; });
  const pts = circ.map(v => apply2(M, v));
  // a symmetric matrix's axes are its eigenvectors (stretched by λ); any matrix's are its singular directions
  const ax = (k: 0 | 1) => (e ? e.v[k]!.map(x => x * e.l[k]!) : s.u[k]!.map(x => x * s.s[k]!));
  const inp = (k: 0 | 1) => (e ? e.v[k]! : s.v[k]!);
  const viewToggle = symm && flag(props, "surface") && <Toggle label="View" value={view} onChange={setView} options={[{ v: "ellipse", label: "Ellipse" }, { v: "surface", label: "Surface z = xᵀAx" }]} />;
  if (symm && view === "surface") {
    const f = (x: number, y: number) => sa * x * x + 2 * sb * x * y + sd * y * y;
    const zs = 1 / Math.max(1, Math.abs(sa) + Math.abs(sb) + Math.abs(sd));
    return <Scene svg={<Surface3D f={f} domain={1.2} zscale={zs * 1.4} label={`The surface z = xᵀAx for A = [[${sn(sa)}, ${sn(sb)}], [${sn(sb)}, ${sn(sd)}]].`} />}
      controls={<>{symSliders(sa, sb, sd, setSa, setSb, setSd)}{viewToggle}</>}
      readouts={<><Read label="λ₁, λ₂" value={`${fx(e!.l[0], 2)}, ${fx(e!.l[1], 2)}`} tone="amber" /><Read label="Shape" value={shapeOf(e!.l)} /></>} />;
  }
  const show = !quiet;
  const body = <>
    <polyline points={poly(p, circ)} style={ink("trav", 1.4, "4 4")} />
    {/* during a guess the ellipse is not drawn yet: its long axis is the answer */}
    {show && <polygon points={poly(p, pts)} style={tintEdge("sky", 0.12)} />}
    {show && <>
      <line x1={p.X(-ax(0)[0]!)} y1={p.Y(-ax(0)[1]!)} x2={p.X(ax(0)[0]!)} y2={p.Y(ax(0)[1]!)} style={ink("amber", 3)} />
      <line x1={p.X(-ax(1)[0]!)} y1={p.Y(-ax(1)[1]!)} x2={p.X(ax(1)[0]!)} y2={p.Y(ax(1)[1]!)} style={ink("mint", 3)} />
      <Arrow p={p} to={inp(0)} tone="amber" dash="4 3" width={2} />
      <Arrow p={p} to={inp(1)} tone="mint" dash="4 3" width={2} />
    </>}
    {!symm && columns}
    {!symm && handles}
    {marker && <g>
      <line x1={p.X(-marker[0] * 5)} y1={p.Y(-marker[1] * 5)} x2={p.X(marker[0] * 5)} y2={p.Y(marker[1] * 5)} className="b2mark" />
      <circle cx={p.X(marker[0] * 2)} cy={p.Y(marker[1] * 2)} r="8" className="b2marker" />
      {onMarker && <circle cx={p.X(marker[0] * 2)} cy={p.Y(marker[1] * 2)} r="22" className="b2hit" {...drag((px, py) => { const [x, y] = p.back(px, py); const a = Math.atan2(y, x); onMarker([round2(Math.cos(a)), round2(Math.sin(a))]); })} />}
    </g>}
  </>;
  const controls = symm ? <>{symSliders(sa, sb, sd, setSa, setSb, setSd)}{viewToggle}</> : undefined;
  const readouts = <>
    <MatRead label="A" M={M} hide={quiet && !symm} />
    {show && (e ? <>
      <Read label="λ₁ (long axis)" value={fx(e.l[0], 2)} tone="amber" />
      <Read label="λ₂" value={fx(e.l[1], 2)} tone="mint" />
      <Read label="Shape of xᵀAx" value={shapeOf(e.l)} />
    </> : <>
      <Read label="σ₁ (longest)" value={fx(s.s[0], 2)} tone="amber" />
      <Read label="σ₂ (shortest)" value={fx(s.s[1], 2)} tone="mint" />
      <Read label="σ₁σ₂ = |det A|" value={fx(s.s[0] * s.s[1], 2)} />
    </>)}
  </>;
  return <Frame base={base} mode="circle" body={body} marker={marker} onMarker={onMarker} controls={controls} readouts={readouts} />;
}

function FilterView(sp: SceneProps) {
  const { props } = sp;
  const base = useBase(sp, "filter");
  const { p, t, goal, setGoal, project, b2, save, note } = base;
  const [deg, setDeg] = useState(num(props, "deg", 30));
  const [k, setK] = useState(num(props, "k", 0.5));
  const [sx, setSx] = useState(num(props, "sx", 1.5));
  const [sy, setSy] = useState(num(props, "sy", 1));
  const r = (deg * Math.PI) / 180;
  const R: M2 = [[Math.cos(r), -Math.sin(r)], [Math.sin(r), Math.cos(r)]], Hm: M2 = [[1, k], [0, 1]], S: M2 = [[sx, 0], [0, sy]];
  const M = mm(S, mm(Hm, R)).map(rw => rw.map(clean)), dM = det2(M), ok = Math.abs(dM) > 1e-9;
  const Mi = ok ? inv2(M).map(rw => rw.map(clean)) : null;
  const shown = t <= 1 ? lerp(I2, M, t) : lerp(M, I2, t - 1);
  const cell = 0.42;
  const pix: number[][][] = [];
  SPRITE.forEach((row, i) => [...row].forEach((ch, j) => { if (ch === "#") { const x = (j - 4) * cell, y = (3.5 - i) * cell; pix.push([[x, y], [x + cell, y], [x + cell, y + cell], [x, y + cell]]); } }));
  const body = <>
    <BentGrid p={p} M={shown} o={0.25} />
    {pix.map((q, i) => <polygon key={`o${i}`} points={poly(p, q)} style={ink("trav", 0.8, "2 2")} />)}
    {pix.map((q, i) => <polygon key={i} points={shape(p, shown, q)} style={tint("mint", 0.75)} />)}
  </>;
  const controls = <>
    <Slider label="Turn" value={deg} min={-180} max={180} step={15} onChange={v => { setDeg(v); setGoal(0); }} format={x => `${sn(x)}°`} />
    <Slider label="Shear" value={k} min={-1} max={1} step={0.25} onChange={v => { setK(v); setGoal(0); }} format={x => fx(x, 2)} />
    <Slider label="Stretch across" value={sx} min={0.5} max={2} step={0.25} onChange={v => { setSx(v); setGoal(0); }} format={x => fx(x, 2)} />
    <Slider label="Stretch up" value={sy} min={-2} max={2} step={0.25} onChange={v => { setSy(v); setGoal(0); }} format={x => fx(x, 2)} />
    <button type="button" className="ctl" aria-pressed={goal === 1} onClick={() => setGoal(1)}>Filter with M</button>
    <button type="button" className="ctl" disabled={goal !== 1 || !ok} onClick={() => setGoal(2)}>Undo with Minv</button>
  </>;
  const readouts = <>
    <MatRead label="M" M={M.map(rw => rw.map(round2))} tone="sky" />
    <Read label="det M, the area scale" value={fx(dM, 2)} tone={dM < 0 ? "pink" : "sky"} />
    {Mi ? <MatRead label="Minv" M={Mi.map(rw => rw.map(round2))} tone="amber" /> : <Read label="Minv" value="none: the sprite is squashed flat" />}
  </>;
  let foot: React.ReactNode;
  if (project) {
    const saved = JSON.stringify(b2.shelf.M?.value) === JSON.stringify(M);
    foot = <SaveRow what={ok ? <>Keep <b>M</b> and <b>Minv</b> (det {fx(dM, 2)})</> : <>A squashed sprite can't be undone: move "Stretch up" off 0.</>} saved={saved} onSave={() => {
      if (!ok) return;
      save("M", M, "la-filter", { note: `turn ${sn(deg)}°, shear ${fx(k, 2)}, stretch ${fx(sx, 2)} across and ${fx(sy, 2)} up` });
      save("Minv", Mi!, "la-filter", { note: "undoes M" });
      note({ id: "la-filter", track: "la", title: "Filter and undo", project: "la-filter", data: { deg, k, sx, sy },
        lines: [`Turn ${sn(deg)}°, then shear ${fx(k, 2)}, then stretch ${fx(sx, 2)} across and ${fx(sy, 2)} up.`,
          `det M = ${fx(dM, 2)}: the sprite's area is multiplied by ${fx(Math.abs(dM), 2)}${dM < 0 ? ", and it is mirrored" : ""}.`] });
    }} />;
  }
  return <Frame base={base} mode="filter" body={body} controls={controls} readouts={readouts} foot={foot} />;
}

/** the reveal for 08: the largest entry of A⁻¹ against det, as the second column swings onto the first */
function InversePlot({ t }: { t: number }) {
  const x0 = 214, y0 = 18, w = 136, h = 96;
  const pts: string[] = [];
  for (let i = 0; i <= 60; i++) {
    const d = 0.05 + (2.95 * i) / 60, big = Math.max(2, 1) / d; // A = [[2, 1], [1, s]], det = 2s − 1, largest |entry| of A⁻¹ = 2 / det
    const x = x0 + (d / 3) * w, y = y0 + h - Math.min(1, big / 40) * h;
    if (i / 60 <= t) pts.push(`${x.toFixed(1)},${y.toFixed(1)}`);
  }
  return (
    <g>
      <rect x={x0 - 6} y={y0 - 6} width={w + 12} height={h + 30} rx="8" style={{ fill: "var(--page)", fillOpacity: 0.85 }} />
      <line x1={x0} y1={y0 + h} x2={x0 + w} y2={y0 + h} className="b2axis" />
      <line x1={x0} y1={y0} x2={x0} y2={y0 + h} className="b2axis" />
      <polyline points={pts.join(" ")} className="b2curve amber" />
      <text x={x0 + w} y={y0 + h + 18} textAnchor="end" className="b2t">det → 3</text>
      <text x={x0 + 6} y={y0 + 10} className="b2t amber">biggest entry of A⁻¹</text>
    </g>
  );
}

function symSliders(a: number, b: number, d: number, setA: (x: number) => void, setB: (x: number) => void, setD: (x: number) => void) {
  return <>
    <Slider label="a (top left)" value={a} min={-3} max={3} step={0.5} onChange={setA} format={x => fx(x, 1)} />
    <Slider label="b (off the diagonal)" value={b} min={-2} max={2} step={0.25} onChange={setB} format={x => fx(x, 2)} />
    <Slider label="d (bottom right)" value={d} min={-3} max={3} step={0.5} onChange={setD} format={x => fx(x, 1)} />
  </>;
}
export const shapeOf = (l: number[]) => {
  const [a, b] = [l[0]!, l[1]!], z = (x: number) => Math.abs(x) < 1e-9;
  if (z(a) && z(b)) return "flat";
  if (a > 0 && b > 0 && !z(b)) return "bowl";
  if (a < 0 && b < 0) return "upside-down bowl";
  if (z(b) && a > 0) return "trough";
  if (z(a) && b < 0) return "upside-down trough";
  return "saddle";
};
const clampv = (x: number) => Math.max(-4, Math.min(4, x));
const round2 = (x: number) => Math.round(x * 100) / 100;
/** sines and cosines of whole multiples of 15° leave float dust: 6.1e−17 is 0 */
const clean = (x: number) => (Math.abs(x - Math.round(x * 1e9) / 1e9) < 1e-12 ? Math.round(x * 1e9) / 1e9 : x);
