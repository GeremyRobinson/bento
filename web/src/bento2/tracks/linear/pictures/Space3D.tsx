// 3D space (linear-algebra.md, "New for Development"): drag anywhere to turn it. Modes: box (04, three arrows and
// the slanted box they make, with its volume), cube (07, a 3 × 3 matrix acting on the unit cube), collapse (10, the
// image of space flattening to a plane as the third column drops into the other two, with the null line lit), and
// planes (09, one plane per equation, with row-reduction playback: the planes change, the meeting point never moves).
import { useEffect, useRef, useState, type ReactNode } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { ArrowHead, fx, Read, Scene, Slider, useTween } from "../../../ui/kit";
import { addv, cross, det3, dot, fromCols, lin, norm, rankOf, scalev, sn, type Vec } from "../maths";
import type { Mat } from "../../../tools/matrix";
import { ink, MatRead, tint, tintEdge, type Tone } from "./plane";

type Mode = "box" | "cube" | "collapse" | "planes";
const W = 360, H = 290;

/** the camera: turn by yaw about the up axis, then tilt by pitch */
function camera(yaw: number, pitch: number, scale: number) {
  const c = Math.cos(yaw), s = Math.sin(yaw);
  const P = (v: Vec): [number, number] => {
    const X = v[0]! * c - v[1]! * s, Y = v[0]! * s + v[1]! * c;
    return [W / 2 + X * scale, H / 2 + Y * scale * Math.sin(pitch) - v[2]! * scale * Math.cos(pitch)];
  };
  /** the direction the eye looks along (it projects to a single point) */
  const look: Vec = [s * Math.cos(pitch), c * Math.cos(pitch), Math.sin(pitch)];
  return { P, look };
}
/** a yaw and pitch that look along a line */
const along = (L: Vec): [number, number] => [Math.atan2(L[0]!, L[1]!), Math.atan2(L[2]!, Math.hypot(L[0]!, L[1]!))];
/** a yaw and pitch that see a plane edge-on (the eye's direction lies in it), near a comfortable tilt */
function edgeOn(n: Vec, yaw0: number): [number, number] {
  let best: [number, number] = [yaw0, 0.5], bestCost = Infinity;
  for (let i = 0; i < 360; i++) {
    const y = yaw0 + (i * Math.PI) / 180 * (i % 2 ? 1 : -1) * 0.5;
    const s = Math.sin(y), c = Math.cos(y);
    const p = Math.abs(n[2]!) < 1e-9 ? 0.5 : Math.atan(-(s * n[0]! + c * n[1]!) / n[2]!);
    const cost = Math.abs(p - 0.45) + Math.abs(y - yaw0) * 0.05;
    if (p > -1.4 && p < 1.4 && cost < bestCost) { bestCost = cost; best = [y, p]; }
  }
  return best;
}

export function Space3DScene({ props }: SceneProps) {
  const mode = str<Mode>(props, "mode", "box");
  const quiet = flag(props, "quiet") || flag(props, "hide");
  const [yaw, setYaw] = useState(num(props, "yaw", 0.65));
  const [pitch, setPitch] = useState(num(props, "pitch", 0.42));
  const last = useRef<{ x: number; y: number } | null>(null);
  const [e, setE] = useState(num(props, "e", mode === "collapse" ? 1.5 : 2));
  const [stepAt, setStepAt] = useState(0);

  // the arrows: u, v and w = a u + b v lifted off their plane by e (box and collapse)
  const u: Vec = [num(props, "ux", 1), num(props, "uy", 0), num(props, "uz", 2)];
  const v: Vec = [num(props, "vx", 0), num(props, "vy", 1), num(props, "vz", 1)];
  const a = num(props, "a", 2), b = num(props, "b", 1);
  const nrm = cross(u, v), nUnit = scalev(1 / (norm(nrm) || 1), nrm);
  // w is given outright (wx, wy, wz), or as a u + b v lifted off their plane by e
  const given = typeof props.wx === "number";
  // just u and v, with no third arrow (16's work, where the third arrow would be the answer)
  const two = flag(props, "two");
  const w = given ? [num(props, "wx", 0), num(props, "wy", 0), num(props, "wz", 0)] : addv(addv(scalev(a, u), scalev(b, v)), scalev(e, nUnit));
  const M3: Mat = mode === "cube"
    ? [0, 1, 2].map(i => [0, 1, 2].map(j => num(props, `m${i}${j}`, i === j ? 1 : 0)))
    : fromCols([u, v, w]);
  const vol = det3(M3);

  // the planes of a system, and the row operations that clear below each pivot
  const sys = planesOf(props);
  const states = mode === "planes" ? reduceStates(sys.A, sys.b) : [];
  const cur = states[Math.min(stepAt, states.length - 1)];

  // a reveal turns the camera: edge-on to the plane of u and v (04), or along the planes' common line (09)
  const [k, setK] = useState(0);
  const tk = useTween(k, 1800);
  const from = useRef<[number, number]>([yaw, pitch]);
  const target: [number, number] | null = flag(props, "edge") ? edgeOn(nrm, yaw) : flag(props, "alongLine") && sys.line ? along(sys.line) : null;
  useEffect(() => { if (target) { from.current = [yaw, pitch]; setK(1); } }, []); // eslint-disable-line react-hooks/exhaustive-deps
  // the collapse reveal drops the third column into the plane
  const [flatGoal, setFlatGoal] = useState(e);
  useEffect(() => { if (flag(props, "flatten")) setFlatGoal(0); }, []); // eslint-disable-line react-hooks/exhaustive-deps
  const flatT = useTween(flatGoal, 1800);
  useEffect(() => { if (flag(props, "flatten")) setE(flatT); }, [flatT]); // eslint-disable-line react-hooks/exhaustive-deps

  const camYaw = target ? from.current[0] + (target[0] - from.current[0]) * tk : yaw;
  const camPitch = target ? from.current[1] + (target[1] - from.current[1]) * tk : pitch;
  const scale = mode === "planes" ? 30 : mode === "cube" ? 34 : 30;
  const { P } = camera(camYaw, camPitch, scale);

  const seg = (p: Vec, q: Vec, style: React.CSSProperties, key?: string | number) => { const [x1, y1] = P(p), [x2, y2] = P(q); return <line key={key} x1={x1} y1={y1} x2={x2} y2={y2} style={style} />; };
  const arrow = (to: Vec, tone: Tone, label?: string, from: Vec = [0, 0, 0]) => {
    const [x1, y1] = P(from), [x2, y2] = P(to);
    return <g className={tone} key={`${label}${to.join()}`}>
      <line x1={x1} y1={y1} x2={x2} y2={y2} className="b2curve" />
      {Math.hypot(x2 - x1, y2 - y1) > 6 && <ArrowHead x1={x1} y1={y1} x2={x2} y2={y2} className="b2dot" />}
      {label && <text x={x2 + 7} y={y2 - 6} className={`b2t ${tone}`}>{label}</text>}
    </g>;
  };
  const face = (pts: Vec[], style: React.CSSProperties, key: string | number) => <polygon key={key} points={pts.map(q => P(q).map(n => n.toFixed(1)).join(",")).join(" ")} style={style} />;
  const patch = (c: Vec, n: Vec, r: number, style: React.CSSProperties, key: string | number) => {
    const e1 = unit(Math.abs(n[2]!) < 0.9 ? cross(n, [0, 0, 1]) : cross(n, [1, 0, 0])), e2 = unit(cross(n, e1));
    const q = (x: number, y: number) => addv(c, addv(scalev(x * r, e1), scalev(y * r, e2)));
    return face([q(-1, -1), q(1, -1), q(1, 1), q(-1, 1)], style, key);
  };
  /** the parallelepiped on three arrows: faces first, then the edges */
  const box = (A: Vec, B: Vec, C: Vec, tone: Tone) => {
    const O: Vec = [0, 0, 0], AB = addv(A, B), AC = addv(A, C), BC = addv(B, C), ABC = addv(AB, C);
    const faces = [[O, A, AB, B], [C, AC, ABC, BC], [O, A, AC, C], [B, AB, ABC, BC], [O, B, BC, C], [A, AB, ABC, AC]];
    const edges: [Vec, Vec][] = [[O, A], [O, B], [O, C], [A, AB], [A, AC], [B, AB], [B, BC], [C, AC], [C, BC], [AB, ABC], [AC, ABC], [BC, ABC]];
    return <g>{faces.map((f, i) => face(f, tint(tone, 0.08), `f${i}`))}{edges.map(([p, q], i) => seg(p, q, { ...ink(tone, 1.2), opacity: 0.7 }, `e${i}`))}</g>;
  };

  const axes = <g>{([[1, 0, 0], [0, 1, 0], [0, 0, 1]] as Vec[]).map((d, i) => seg(scalev(-3.2, d), scalev(3.2, d), { stroke: "var(--b2-line)", strokeWidth: 1 }, `ax${i}`))}</g>;
  let body: ReactNode = null, controls: ReactNode = null, readouts: ReactNode = null;

  if (mode === "box") {
    body = <>
      {patch([0, 0, 0], nrm, 3, tintEdge("trav", 0.12), "plane")}
      {!quiet && !two && box(u, v, w, "amber")}
      {arrow(u, "sky", "u")}{arrow(v, "pink", "v")}{!two && arrow(w, "amber", "w")}
      {!given && seg(w, addv(scalev(a, u), scalev(b, v)), ink("amber", 1.2, "3 3"), "drop")}
    </>;
    controls = given ? undefined : <Slider label="w's height off the plane of u and v" value={e} min={-3} max={3} step={0.1} onChange={setE} format={x => fx(x, 1)} />;
    readouts = <>
      <Read label="u, v" value={`${vecs(u)}, ${vecs(v)}`} />
      {!two && <Read label="w" value={vecs(w)} tone="amber" />}
      {!quiet && <Read label="Volume of the box" value={fx(Math.abs(vol), 2)} tone="amber" />}
      {!quiet && <Read label="The three arrows" value={Math.abs(vol) < 1e-6 ? "lie flat: dependent" : "fill space: independent"} />}
    </>;
  } else if (mode === "cube") {
    const c = [0, 1, 2].map(j => M3.map(r => r[j]!)) as Vec[];
    body = <>
      {box([1, 0, 0], [0, 1, 0], [0, 0, 1], "trav")}
      {box(c[0]!, c[1]!, c[2]!, vol < 0 ? "pink" : "sky")}
      {arrow(c[0]!, "sky", "1st")}{arrow(c[1]!, "pink", "2nd")}{arrow(c[2]!, "amber", "3rd")}
    </>;
    readouts = <>
      <MatRead label="A" M={M3} />
      {!quiet && <Read label="Volume of the cube's image" value={fx(Math.abs(vol), 0)} tone={vol < 0 ? "pink" : "sky"} />}
    </>;
  } else if (mode === "collapse") {
    const r = rankOf(M3, 1e-6);
    const nullDir = r === 2 ? nullOf(M3) : null;
    body = <>
      {!quiet && box(u, v, w, r < 3 ? "pink" : "sky")}
      {!quiet && r < 3 && patch([0, 0, 0], nrm, 3, tintEdge("pink", 0.1), "img")}
      {arrow(u, "sky", "c₁")}{arrow(v, "sky", "c₂")}{arrow(w, "amber", "c₃")}
      {nullDir && !quiet && <>{seg(scalev(-4, nullDir), scalev(4, nullDir), ink("mint", 3.5), "null")}<text x={P(scalev(3.6, nullDir))[0] + 6} y={P(scalev(3.6, nullDir))[1]} className="b2t mint">sent to 0</text></>}
    </>;
    controls = <Slider label="Third column's height off the plane of the first two" value={e} min={-3} max={3} step={0.1} onChange={setE} format={x => fx(x, 1)} />;
    readouts = <>
      <MatRead label="A" M={M3.map(rw => rw.map(x => Math.round(x * 10) / 10))} />
      {!quiet && <Read label="The image of all of space" value={["a point", "a line", "a plane", "all of space"][r]!} tone={r < 3 ? "pink" : "sky"} />}
      {!quiet && <Read label="rank, nullity" value={`${r}, ${3 - r}`} />}
    </>;
  } else {
    const show = stepAt;
    const tones: Tone[] = ["sky", "pink", "amber"];
    const meet = sys.point;
    body = <>
      {cur!.A.map((row, i) => {
        const nn = row as Vec, len2 = dot(nn, nn);
        if (len2 < 1e-12) return null;
        // each patch sits around the meeting point (or line), or around the plane's point nearest the origin
        const c = meet ?? sys.linePoint ?? scalev(cur!.b[i]! / len2, nn);
        return <g key={i}>{patch(c, nn, 2.6, tintEdge(tones[i]!, 0.16), `p${i}`)}</g>;
      })}
      {meet && !quiet && <><circle cx={P(meet)[0]} cy={P(meet)[1]} r="6" className="b2dot mint" /><text x={P(meet)[0] + 9} y={P(meet)[1] - 9} className="b2t mint">{vecs(meet)}</text></>}
      {sys.line && sys.linePoint && !quiet && seg(addv(sys.linePoint, scalev(-4, unit(sys.line))), addv(sys.linePoint, scalev(4, unit(sys.line))), ink("mint", 3), "line")}
    </>;
    controls = states.length > 1 && !flag(props, "noSteps") ? <>
      <button type="button" className="ctl" disabled={show === 0} onClick={() => setStepAt(s => Math.max(0, s - 1))}>‹ Back</button>
      <button type="button" className="ctl go" disabled={show >= states.length - 1} onClick={() => setStepAt(s => Math.min(states.length - 1, s + 1))}>Next row operation ›</button>
    </> : undefined;
    readouts = <>
      <span className="b2r eqs" aria-label="The equations">
        <small>{cur!.say}</small>
        {cur!.A.map((row, i) => <b key={i} className={`tone-${tones[i]}`}>{eq(row, cur!.b[i]!)}</b>)}
      </span>
      {!quiet && <Read label="They meet" value={meet ? `at ${vecs(meet)}` : sys.line ? "along a line" : "nowhere"} tone="mint" />}
    </>;
  }

  const onDown = (ev: React.PointerEvent<SVGSVGElement>) => { (ev.target as Element).setPointerCapture?.(ev.pointerId); last.current = { x: ev.clientX, y: ev.clientY }; };
  const onMove = (ev: React.PointerEvent<SVGSVGElement>) => {
    if (!last.current || target) return;
    const dx = ev.clientX - last.current.x, dy = ev.clientY - last.current.y;
    last.current = { x: ev.clientX, y: ev.clientY };
    setYaw(y => y + dx * 0.01);
    setPitch(p => Math.max(-1.45, Math.min(1.45, p + dy * 0.008)));
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic s3" role="img" aria-label={`3D space, ${mode}. Drag to turn it.`}
      onPointerDown={onDown} onPointerMove={onMove} onPointerUp={() => (last.current = null)} onPointerCancel={() => (last.current = null)}>
      {axes}
      {body}
      <text x={W - 8} y={H - 8} textAnchor="end" className="b2t">drag to turn</text>
    </svg>
  );
  return <Scene svg={svg} controls={controls} readouts={readouts} />;
}

const unit = (v: Vec) => scalev(1 / (norm(v) || 1), v);
const vecs = (v: Vec) => `(${v.map(x => (Math.abs(x - Math.round(x)) < 1e-6 ? sn(Math.round(x)) : fx(x, 1))).join(", ")})`;
/** "x + 2y − z = 4" */
const eq = (row: number[], rhs: number) => `${lin(row.slice(0, 3).map((c, i) => [Math.round(c * 1000) / 1000, "xyz"[i]!] as [number, string]))} = ${sn(Math.round(rhs * 1000) / 1000)}`;

/** a unit vector A sends to 0, for a rank-2 3 × 3 */
function nullOf(A: Mat): Vec | null {
  const cands = [cross(A[0]!, A[1]!), cross(A[0]!, A[2]!), cross(A[1]!, A[2]!)];
  const best = cands.reduce((x, y) => (norm(y) > norm(x) ? y : x));
  return norm(best) > 1e-9 ? unit(best) : null;
}

/** the system the planes show: from props r0 … r2 ("1,1,1,6"), or the spec's example */
function planesOf(props: SceneProps["props"]) {
  const rows = [0, 1, 2].map(i => str(props, `r${i}`, ["1,1,1,6", "2,3,1,11", "1,2,3,14"][i]!).split(",").map(Number));
  const A = rows.map(r => r.slice(0, 3)), b = rows.map(r => r[3]!);
  const d = det3(A);
  if (Math.abs(d) > 1e-9) {
    // Cramer's rule
    const point = [0, 1, 2].map(j => det3(A.map((r, i) => r.map((x, k) => (k === j ? b[i]! : x)))) / d);
    return { A, b, point, line: null as Vec | null, linePoint: null as Vec | null };
  }
  // singular: either they share a line, or they have no common point
  const aug = A.map((r, i) => [...r, b[i]!]);
  const consistent = rankOf(aug, 1e-9) === rankOf(A, 1e-9);
  const dir = [cross(A[0]!, A[1]!), cross(A[0]!, A[2]!), cross(A[1]!, A[2]!)].reduce((x, y) => (norm(y) > norm(x) ? y : x));
  if (!consistent || norm(dir) < 1e-9) return { A, b, point: null as Vec | null, line: null as Vec | null, linePoint: null as Vec | null };
  // the point of the line nearest the origin: least squares on two independent rows plus dir·x = 0
  const i = norm(cross(A[0]!, A[1]!)) > 1e-9 ? [0, 1] : norm(cross(A[0]!, A[2]!)) > 1e-9 ? [0, 2] : [1, 2];
  const M = [A[i[0]!]!, A[i[1]!]!, dir], rhs = [b[i[0]!]!, b[i[1]!]!, 0];
  const dm = det3(M);
  const linePoint = [0, 1, 2].map(j => det3(M.map((r, k) => r.map((x, c) => (c === j ? rhs[k]! : x)))) / dm);
  return { A, b, point: null as Vec | null, line: dir as Vec | null, linePoint: linePoint as Vec | null };
}

/** the system after each row operation, with what was done */
function reduceStates(A0: Mat, b0: number[]) {
  const A = A0.map(r => [...r]), b = [...b0];
  const out = [{ A: A.map(r => [...r]), b: [...b], say: "The three equations" }];
  const n = A.length;
  for (let c = 0; c < n - 1; c++) {
    if (Math.abs(A[c]![c]!) < 1e-12) break;
    for (let r = c + 1; r < n; r++) {
      const m = A[r]![c]! / A[c]![c]!;
      if (Math.abs(m) < 1e-12) continue;
      A[r] = A[r]!.map((x, j) => x - m * A[c]![j]!);
      b[r] = b[r]! - m * b[c]!;
      const k = Math.round(Math.abs(m) * 1000) / 1000;
      out.push({ A: A.map(rw => [...rw]), b: [...b], say: `Row ${r + 1} ${m > 0 ? "−" : "+"} ${k === 1 ? "" : `${sn(k)} × `}row ${c + 1}` });
    }
  }
  return out;
}
