// The Vector board (linear-algebra.md, "New for Development"): arrows you drag by their tips, on the plane.
// Modes: sum (01, tip to tail with scale sliders), span (02, every mix a u + b v shaded, collapsing to a line when
// the arrows line up), shadow (03, w's shadow on u's line with the drop line), basis (12 and the project "Your own
// grid": a skewed grid from two arrows and points written in it), gram (16, the Gram–Schmidt step button).
import { useEffect, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, Toggle, useSvgDrag, useTween } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { det2, dot, inv2, lin, norm, sn, vec } from "../maths";
import { Arrow, Grid, Handle, plane, poly, pt, SkewGrid, snap, tint, tintEdge } from "./plane";

type Mode = "sum" | "span" | "shadow" | "basis" | "gram";
const H = 280;

const v2 = (props: SceneProps["props"], k: string, d: [number, number]): [number, number] => [num(props, `${k}x`, d[0]), num(props, `${k}y`, d[1])];

export function VectorsScene({ props, place, marker, onMarker }: SceneProps) {
  const mode = str<Mode>(props, "mode", "sum");
  const quiet = flag(props, "quiet") || flag(props, "hide");
  const project = flag(props, "project") || place === "project";
  const { b2, save, note } = useB2();
  const shelfBasis = b2.shelf.basis?.value as number[][] | undefined;
  const fromShelf = mode === "basis" && flag(props, "useShelf") && Array.isArray(shelfBasis) && shelfBasis.length === 2 && Math.abs(det2(shelfBasis)) > 1e-9;
  const [u, setU] = useState<[number, number]>(fromShelf ? [shelfBasis![0]![0]!, shelfBasis![1]![0]!] : v2(props, "u", mode === "shadow" ? [3, 1] : mode === "gram" ? [3, 1] : [3, 1]));
  const [v, setV] = useState<[number, number]>(fromShelf ? [shelfBasis![0]![1]!, shelfBasis![1]![1]!] : v2(props, "v", mode === "gram" ? [2, 3] : [1, 2]));
  const [w, setW] = useState<[number, number]>(v2(props, "w", mode === "shadow" ? [2, 4] : [5, 3]));
  const [a, setA] = useState(num(props, "a", 1));
  const [b, setB] = useState(num(props, "b", 1));
  const [pts, setPts] = useState<[number, number][]>(mode === "basis" ? (flag(props, "one") ? [v2(props, "x", [3, 5])] : [[4, 1], [-2, 3], [1, -3]]) : []);
  // starts slanted, then moves to the asked-for step so a reveal animates the subtraction
  const [phase, setPhase] = useState(0);
  const askPhase = num(props, "phase", 0);
  useEffect(() => { setPhase(askPhase); }, [askPhase]);
  const [showMove, setShowMove] = useState(flag(props, "move"));
  const { ref, drag } = useSvgDrag();
  const p = plane(-6, 6, -5, 5, 360, H);
  const tip = (set: (v: [number, number]) => void, step = 1) => drag((px, py) => { const [x, y] = p.back(px, py); set([clamp(snap(x, step), -6, 6), clamp(snap(y, step), -5, 5)]); });

  // the reveal for "sum": v slides from the origin to the tip of u
  const [slideGoal, setSlideGoal] = useState(0);
  useEffect(() => { if (flag(props, "parallelogram")) setSlideGoal(1); }, []); // eslint-disable-line react-hooks/exhaustive-deps
  const slide = useTween(slideGoal, 1400);
  // the Gram–Schmidt step: 0 slanted, 1 shadow removed, 2 both length 1
  const ph = useTween(phase, 1300);

  const D = det2([[u[0], v[0]], [u[1], v[1]]]);
  let svgBody: React.ReactNode = null, controls: React.ReactNode = null, readouts: React.ReactNode = null, foot: React.ReactNode = null;

  if (mode === "sum") {
    const au = [a * u[0], a * u[1]], bv = [b * v[0], b * v[1]], s = [au[0]! + bv[0]!, au[1]! + bv[1]!];
    const tail = flag(props, "parallelogram") ? [au[0]! * slide, au[1]! * slide] : au;
    svgBody = <>
      {flag(props, "parallelogram") && <polygon points={poly(p, [[0, 0], au, s, bv])} style={tint("amber", 0.1 * slide)} />}
      {flag(props, "parallelogram") && <Arrow p={p} to={bv} tone="pink" faint />}
      <Arrow p={p} to={au} tone="sky" label={coef(a, "u")} />
      <Arrow p={p} from={tail} to={[tail[0]! + bv[0]!, tail[1]! + bv[1]!]} tone="pink" label={coef(b, "v")} />
      {!quiet && <Arrow p={p} to={s} tone="amber" width={3.2} />}
      {!quiet && <text x={p.X(s[0]!) + 8} y={p.Y(s[1]!) + 18} className="b2t amber">{pt(s)}</text>}
      {!quiet && <Handle at={p.P(u)} tone="sky" drag={tip(setU)} r={6} />}
      {!quiet && <Handle at={p.P(v)} tone="pink" drag={tip(setV)} r={6} />}
    </>;
    controls = <>
      <Slider label="a, copies of u" value={a} min={-3} max={3} step={0.5} onChange={setA} format={x => fx(x, 1)} />
      <Slider label="b, copies of v" value={b} min={-3} max={3} step={0.5} onChange={setB} format={x => fx(x, 1)} />
    </>;
    readouts = <>
      <Read label="u" value={vec(u)} tone="sky" />
      <Read label="v" value={vec(v)} tone="pink" />
      {!quiet && <Read label={`${coef(a, "u")} + ${coef(b, "v")}`.replace("+ −", "− ")} value={pt(s)} tone="amber" />}
    </>;
  } else if (mode === "span") {
    // every mix with a and b from −3 to 3: a parallelogram that flattens to a segment when u and v line up
    const corners = [[-3, -3], [3, -3], [3, 3], [-3, 3]].map(([x, y]) => [x! * u[0] + y! * v[0], x! * u[1] + y! * v[1]]);
    const flat = Math.abs(D) < 1e-9;
    const target = !flag(props, "noTarget");
    const showGrid = !quiet && (flag(props, "skew") || !target);
    const inv = flat ? null : inv2([[u[0], v[0]], [u[1], v[1]]]);
    const ab = inv ? [inv[0]![0]! * w[0] + inv[0]![1]! * w[1], inv[1]![0]! * w[0] + inv[1]![1]! * w[1]] : null;
    svgBody = <>
      <polygon points={poly(p, corners)} style={tintEdge("trav", flat ? 0.5 : 0.1)} />
      {showGrid && !flat && <SkewGrid p={p} a={u} b={v} n={7} o={0.35} />}
      {flag(props, "skew") && ab && <>
        <Arrow p={p} to={[ab[0]! * u[0], ab[0]! * u[1]]} tone="sky" width={3.4} />
        <Arrow p={p} from={[ab[0]! * u[0], ab[0]! * u[1]]} to={w} tone="pink" width={3.4} />
      </>}
      <Arrow p={p} to={u} tone="sky" label="u" />
      <Arrow p={p} to={v} tone="pink" label="v" />
      {target && <><circle cx={p.X(w[0])} cy={p.Y(w[1])} r="6" className="b2dot amber" /><text x={p.X(w[0]) + 9} y={p.Y(w[1]) - 9} className="b2t amber">w {vec(w)}</text></>}
      {!quiet && <Handle at={p.P(u)} tone="sky" drag={tip(setU)} r={6} />}
      {!quiet && <Handle at={p.P(v)} tone="pink" drag={tip(setV)} r={6} />}
      {!quiet && target && !flag(props, "skew") && <Handle at={p.P(w)} tone="amber" drag={tip(setW)} r={5} />}
    </>;
    readouts = <>
      <Read label="u₁v₂ − u₂v₁" value={sn(D)} />
      <Read label="The mixes reach" value={flat ? (norm(u) + norm(v) ? "one line" : "one point") : "the whole plane"} tone="trav" />
      {target && !quiet && ab && <Read label="w = a u + b v" value={`a = ${fx(ab[0]!, 2)}, b = ${fx(ab[1]!, 2)}`} tone="amber" />}
      {target && !quiet && !ab && <Read label="w" value="off the line: no mix reaches it" tone="amber" />}
    </>;
  } else if (mode === "shadow") {
    const uu = dot(u, u), k = uu ? dot(u, w) / uu : 0, sh = [k * u[0], k * u[1]];
    const ang = uu && norm(w) ? (Math.acos(Math.max(-1, Math.min(1, dot(u, w) / (Math.sqrt(uu) * norm(w))))) * 180) / Math.PI : 90;
    const L = 20, show = !quiet;
    // the marker slides along u's line only: a shadow always lands there
    const onLine = (px: number, py: number) => { const [x, y] = p.back(px, py); const t = uu ? (x * u[0] + y * u[1]) / uu : 0; onMarker?.([Math.round(t * u[0] * 4) / 4, Math.round(t * u[1] * 4) / 4]); };
    svgBody = <>
      <line x1={p.X(-L * u[0])} y1={p.Y(-L * u[1])} x2={p.X(L * u[0])} y2={p.Y(L * u[1])} className="b2grid strong" />
      {show && <line x1={p.X(w[0])} y1={p.Y(w[1])} x2={p.X(sh[0]!)} y2={p.Y(sh[1]!)} className="b2mark amber" />}
      {show && <Arrow p={p} to={sh} tone="amber" width={4} />}
      <Arrow p={p} to={u} tone="sky" label="u" />
      <Arrow p={p} to={w} tone="pink" label="w" />
      {!quiet && <Handle at={p.P(w)} tone="pink" drag={tip(setW)} r={6} />}
      {!quiet && <Handle at={p.P(u)} tone="sky" drag={tip(setU)} r={6} />}
      {marker && <g>
        <circle cx={p.X(marker[0])} cy={p.Y(marker[1])} r="8" className="b2marker" />
        {onMarker && <circle cx={p.X(marker[0])} cy={p.Y(marker[1])} r="22" className="b2hit" {...drag(onLine)} />}
      </g>}
    </>;
    readouts = show ? <>
      <Read label="u·w" value={sn(dot(u, w))} />
      <Read label="angle" value={`${fx(ang, 0)}°`} />
      <Read label="multiplier u·w / u·u" value={sn(k)} tone="amber" />
      <Read label="shadow" value={pt(sh, 2)} tone="amber" />
    </> : <Read label="u" value={vec(u)} tone="sky" />;
  } else if (mode === "basis") {
    const P = [[u[0], v[0]], [u[1], v[1]]], flat = Math.abs(D) < 1e-9, Pi = flat ? null : inv2(P);
    const coords = (x: number[]) => (Pi ? [Pi[0]![0]! * x[0]! + Pi[0]![1]! * x[1]!, Pi[1]![0]! * x[0]! + Pi[1]![1]! * x[1]!] : null);
    const lam = [num(props, "d1", 3), num(props, "d2", -1)];
    svgBody = <>
      {!flat && <SkewGrid p={p} a={u} b={v} n={9} o={0.4} />}
      {showMove && !flat && <>
        <Arrow p={p} to={[lam[0]! * u[0], lam[0]! * u[1]]} tone="sky" faint width={5} />
        <Arrow p={p} to={[lam[1]! * v[0], lam[1]! * v[1]]} tone="pink" faint width={5} />
      </>}
      <Arrow p={p} to={u} tone="sky" label="b₁" />
      <Arrow p={p} to={v} tone="pink" label="b₂" />
      {pts.map((x, i) => {
        const c = coords(x);
        return <g key={i}>
          {!quiet && c && flag(props, "walk") && <>
            <line x1={p.X(0)} y1={p.Y(0)} x2={p.X(c[0]! * u[0])} y2={p.Y(c[0]! * u[1])} className="b2mark sky" />
            <line x1={p.X(c[0]! * u[0])} y1={p.Y(c[0]! * u[1])} x2={p.X(x[0]!)} y2={p.Y(x[1]!)} className="b2mark pink" />
          </>}
          <circle cx={p.X(x[0]!)} cy={p.Y(x[1]!)} r="6" className="b2dot amber" />
          <text x={p.X(x[0]!) + 9} y={p.Y(x[1]!) - 9} className="b2t amber">{pts.length > 1 ? `${"ABC"[i]} ` : ""}{quiet || !c ? pt(x) : `[${pt(c, 2).slice(1, -1)}]`}</text>
          {!quiet && <circle cx={p.X(x[0]!)} cy={p.Y(x[1]!)} r="18" className="b2hit" {...tip(nx => setPts(ps => ps.map((q, j) => (j === i ? nx : q))))} />}
        </g>;
      })}
      {!quiet && !flag(props, "fixed") && <Handle at={p.P(u)} tone="sky" drag={tip(setU)} r={6} />}
      {!quiet && !flag(props, "fixed") && <Handle at={p.P(v)} tone="pink" drag={tip(setV)} r={6} />}
    </>;
    controls = !project && flag(props, "canMove") ? <Toggle label="The move" value={showMove ? "on" : "off"} onChange={x => setShowMove(x === "on")}
      options={[{ v: "off", label: "Points" }, { v: "on", label: `Stretch by ${sn(lam[0]!)} and ${sn(lam[1]!)}` }]} /> : undefined;
    readouts = <>
      <Read label="Your basis, b₁ and b₂" value={`${vec(u)}, ${vec(v)}`} tone="trav" />
      {flat && <Read label="Grid" value="flat: b₁ and b₂ line up" />}
      {!quiet && pts.map((x, i) => { const c = coords(x); return <Read key={i} label={`${pts.length > 1 ? `${"ABC"[i]}: ` : ""}usual ${pt(x)}, in your grid`} value={c ? `[${pt(c, 2).slice(1, -1)}]` : "none"} tone="amber" />; })}
    </>;
    if (project) {
      const val = [[u[0], v[0]], [u[1], v[1]]];
      const saved = JSON.stringify(b2.shelf.basis?.value) === JSON.stringify(val);
      foot = <SaveRow what={flat ? <>Pull the arrows apart first: a flat grid can't name points.</> : <>Keep <b>basis</b> = columns {vec(u)} and {vec(v)}</>} saved={saved} onSave={() => {
        if (flat) return;
        save("basis", val, "la-grid", { note: "your two basis arrows, as columns" });
        note({ id: "la-grid", track: "la", title: "Your own grid", project: "la-grid", data: { ux: u[0], uy: u[1], vx: v[0], vy: v[1] },
          lines: [`Basis arrows b₁ = ${vec(u)} and b₂ = ${vec(v)}.`, ...pts.map((x, i) => { const c = coords(x)!; return `${"ABC"[i]} = ${pt(x)} is ${lin([[round2(c[0]!), "b₁"], [round2(c[1]!), "b₂"]])}.`; })] });
      }} />;
    }
  } else {
    // gram: v loses its shadow on u, then both shrink to length 1
    const uu = dot(u, u), k = uu ? dot(u, v) / uu : 0;
    const t1 = Math.min(1, ph), t2 = Math.max(0, ph - 1);
    const vp = [v[0] - t1 * k * u[0], v[1] - t1 * k * u[1]];
    const nu = norm(u), nvp = norm([v[0] - k * u[0], v[1] - k * u[1]]);
    const su = 1 + t2 * (1 / (nu || 1) - 1), sv = 1 + t2 * (1 / (nvp || 1) - 1);
    const U = [u[0] * su, u[1] * su], V = [vp[0]! * sv, vp[1]! * sv];
    const vFinal = [v[0] - k * u[0], v[1] - k * u[1]];
    svgBody = <>
      {Math.abs(D) > 1e-9 && <SkewGrid p={p} a={U} b={V} n={12} o={0.3} />}
      {!quiet && t1 > 0 && <Arrow p={p} from={vp} to={v} tone="amber" faint width={2} />}
      {!quiet && <Arrow p={p} to={[k * u[0] * (1 - t2), k * u[1] * (1 - t2)]} tone="amber" faint width={5} />}
      <Arrow p={p} to={U} tone="sky" label={t2 > 0.5 ? "q₁" : "u"} />
      <Arrow p={p} to={V} tone="pink" label={t2 > 0.5 ? "q₂" : t1 > 0.5 ? "v′" : "v"} />
      {ph < 0.01 && !quiet && <Handle at={p.P(u)} tone="sky" drag={tip(setU)} r={6} />}
      {ph < 0.01 && !quiet && <Handle at={p.P(v)} tone="pink" drag={tip(setV)} r={6} />}
      {marker && <g>
        <circle cx={p.X(marker[0])} cy={p.Y(marker[1])} r="8" className="b2marker" />
        {onMarker && <circle cx={p.X(marker[0])} cy={p.Y(marker[1])} r="22" className="b2hit" {...drag((px, py) => { const [x, y] = p.back(px, py); onMarker([snap(x, 0.5), snap(y, 0.5)]); })} />}
      </g>}
    </>;
    controls = !quiet ? <span className="b2toggle" role="group" aria-label="Gram–Schmidt">
      <button type="button" aria-pressed={phase === 0} onClick={() => setPhase(0)}>Start</button>
      <button type="button" aria-pressed={phase === 1} onClick={() => setPhase(1)}>Remove the shadow</button>
      <button type="button" aria-pressed={phase === 2} onClick={() => setPhase(2)}>Length 1</button>
    </span> : undefined;
    readouts = quiet ? <><Read label="u" value={vec(u)} tone="sky" /><Read label="v" value={vec(v)} tone="pink" /></> : <>
      <Read label="u·v / u·u" value={sn(k)} tone="amber" />
      <Read label="v′ = v − shadow" value={pt(vFinal, 2)} tone="pink" />
      <Read label="v′·u" value={fx(dot(vFinal, u), 2).replace("−0.00", "0.00")} />
      <Read label="|u|, |v′|" value={`${fx(nu, 2)}, ${fx(nvp, 2)}`} />
    </>;
  }

  const svg = (
    <svg ref={ref} viewBox={`0 0 360 ${H}`} className="b2pic" role="img" aria-label={`Vector board, ${mode} view. u = ${vec(u)}, v = ${vec(v)}.`}>
      <Grid p={p} />
      {svgBody}
      {marker && (mode === "sum" || mode === "span") && <g>
        <circle cx={p.X(marker[0])} cy={p.Y(marker[1])} r="8" className="b2marker" />
        {onMarker && <circle cx={p.X(marker[0])} cy={p.Y(marker[1])} r="22" className="b2hit" {...drag((px, py) => { const [x, y] = p.back(px, py); onMarker([snap(x, 0.5), snap(y, 0.5)]); })} />}
        <text x={p.X(marker[0]) + 11} y={p.Y(marker[1]) + 20} className="b2t">your guess</text>
      </g>}
    </svg>
  );
  return <Scene svg={svg} controls={controls} readouts={readouts} foot={foot} />;
}

const clamp = (x: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, x));
const round2 = (x: number) => Math.round(x * 100) / 100;
/** "u", "−v", "2.5u" for a slider's scale */
const coef = (c: number, name: string) => (c === 1 ? name : c === -1 ? `−${name}` : `${fx(c, 1).replace(/\.0$/, "")}${name}`);
