// The trace–determinant map (diffeq.md, "New for Development" 4): the (T, D) plane with the parabola T² = 4D and its
// regions, a dot you drag, and a mini phase portrait linked to it. Also the Phase portrait gallery project: four
// tiles, a matrix each, saved as A_saddle, A_node, A_spiral and A_center when its dot lands in the right region.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, Toggle, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { det, eigenLines, mul, regionNear, trace, TYPES, type M2 } from "../maths";
import { FieldArrows, frame, trajectory } from "./plot";
import { mat } from "../text";

const W = 360, H = 260;
const MAP = { l: 26, r: 222, t: 12, b: 248 }, MINI = { l: 238, r: 354, t: 72, b: 188 };
const LABELS: [string, number, number][] = [["saddle", 0, -1.8], ["node in", -3, 1.2], ["node out", 3, 1.2], ["spiral in", -1.5, 3.8], ["spiral out", 1.5, 3.8]];

/** a small portrait of x′ = Ax: arrows and a ring of paths */
export function Mini({ A, box = MINI }: { A: M2; box?: typeof MINI }) {
  const fr = frame(-3, 3, -3, 3, box);
  const F = (x: number, y: number): [number, number] => mul(A, [x, y]);
  const span = Math.max(1, ...A.flat().map(Math.abs));
  const paths = useMemo(() => Array.from({ length: 6 }, (_, k) => {
    const a = (k * Math.PI) / 3 + 0.3;
    return trajectory(fr, F, [2.6 * Math.cos(a), 2.6 * Math.sin(a)], 8 / span, 0.01 / span * 2, "rk4", true);
  }), [...A.flat()]); // eslint-disable-line react-hooks/exhaustive-deps
  const id = `mini${box.l}`;
  return (
    <g>
      <defs><clipPath id={id}><rect x={box.l} y={box.t} width={box.r - box.l} height={box.b - box.t} rx="10" /></clipPath></defs>
      <rect x={box.l} y={box.t} width={box.r - box.l} height={box.b - box.t} rx="10" className="b2bar track" />
      <g clipPath={`url(#${id})`}>
        <FieldArrows fr={fr} f={F} n={7} len={6} />
        {eigenLines(A).map(([u, w], i) => <line key={i} x1={fr.X(-9 * u)} y1={fr.Y(-9 * w)} x2={fr.X(9 * u)} y2={fr.Y(9 * w)} className="b2mark amber" />)}
        {paths.map((pts, i) => <path key={i} d={path(pts)} className="b2curve sky" style={{ strokeWidth: 1.6 }} />)}
      </g>
      <circle cx={fr.X(0)} cy={fr.Y(0)} r="3" className="b2dot amber" />
    </g>
  );
}

function MapBase({ quiet, shade }: { quiet: boolean; shade: boolean }) {
  const f = frame(-4, 4, -3, 5, MAP);
  const para = path(Array.from({ length: 81 }, (_, k) => { const T = -4 + k / 10; return [f.X(T), f.Y(Math.min(5, (T * T) / 4))] as [number, number]; }));
  const stable = `${path(Array.from({ length: 41 }, (_, k) => { const T = -4 + k / 10; return [f.X(T), f.Y((T * T) / 4)] as [number, number]; }))} L${f.X(0)},${f.Y(5)} L${f.X(-4)},${f.Y(5)} Z`;
  return (
    <g>
      {shade && <path d={stable} className="b2bar mint" opacity={0.25} />}
      <rect x={MAP.l} y={f.Y(0)} width={MAP.r - MAP.l} height={MAP.b - f.Y(0)} className="b2bar pink" opacity={0.07} />
      <line x1={MAP.l} y1={f.Y(0)} x2={MAP.r} y2={f.Y(0)} className="b2axis" />
      <line x1={f.X(0)} y1={MAP.t} x2={f.X(0)} y2={MAP.b} className="b2axis" />
      <line x1={f.X(0)} y1={f.Y(0)} x2={f.X(0)} y2={MAP.t} className="b2leg trav" style={{ strokeWidth: 2.5 }} />
      <path d={para} className="b2curve amber" />
      <text x={MAP.r - 2} y={f.Y(0) + 15} textAnchor="end" className="b2t">T</text>
      <text x={f.X(0) + 6} y={MAP.b - 4} className="b2t">D</text>
      {!quiet && LABELS.map(([s, T, D]) => <text key={s} x={f.X(T)} y={f.Y(D)} textAnchor="middle" className="b2t">{s}</text>)}
      {!quiet && <text x={f.X(0)} y={MAP.t + 12} textAnchor="middle" className="b2t trav">center</text>}
    </g>
  );
}

export function TdMapScene({ props, marker, onMarker }: SceneProps) {
  const quiet = flag(props, "quiet");
  const given: M2 | null = typeof props.a11 === "number" ? [[num(props, "a11", 0), num(props, "a12", 0)], [num(props, "a21", 0), num(props, "a22", 0)]] : null;
  const [td, setTd] = useState<[number, number]>([num(props, "T", -1), num(props, "D", 2)]);
  const [moved, setMoved] = useState(false);
  const { ref, drag } = useSvgDrag();
  const f = frame(-4, 4, -3, 5, MAP);
  const [T, D] = marker ?? td;
  const A: M2 = given && !moved ? given : [[0, 1], [-D, T]];
  const snap = (x: number) => Math.round(x * 4) / 4;
  const move = (x: number, y: number) => {
    const p: [number, number] = [Math.max(-4, Math.min(4, snap(f.ix(x)))), Math.max(-3, Math.min(5, snap(f.iy(y))))];
    if (onMarker) onMarker(p); else { setTd(p); setMoved(true); }
  };
  const reg = regionNear(T, D);
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Trace–determinant map, dot at T = ${fx(T, 2)}, D = ${fx(D, 2)}${quiet ? "" : `: ${TYPES[reg] ?? "D = 0"}`}.`}>
      <MapBase quiet={quiet} shade={flag(props, "shade")} />
      <rect x={MAP.l} y={MAP.t} width={MAP.r - MAP.l} height={MAP.b - MAP.t} className="b2hit" {...drag(move)} />
      <circle cx={f.X(T)} cy={f.Y(D)} r={marker ? 9 : 8} className={marker ? "b2marker" : "b2handle"} pointerEvents="none" />
      <Mini A={A} />
      <text x={(MINI.l + MINI.r) / 2} y={MINI.t - 8} textAnchor="middle" className="b2t">its portrait</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      readouts={<>
        <Read label="T" value={fx(T, 2)} />
        <Read label="D" value={fx(D, 2)} />
        {!quiet && <Read label="T² − 4D" value={fx(T * T - 4 * D, 2)} tone="amber" />}
        {!quiet && <Read label="Type" value={TYPES[reg] ?? "D = 0: a line of rest points"} />}
        {!quiet && <Read label="Rest is" value={T < 0 && D > 0 ? "stable" : "not stable"} />}
      </>}
    />
  );
}

const TILES = [
  { id: "A_saddle", name: "Saddle", ok: (r: number) => r === 0, tone: "pink" },
  { id: "A_node", name: "Node", ok: (r: number) => r === 1 || r === 2, tone: "sky" },
  { id: "A_spiral", name: "Spiral", ok: (r: number) => r === 3 || r === 4, tone: "mint" },
  { id: "A_center", name: "Center", ok: (r: number) => r === 5, tone: "trav" },
] as const;

export function GalleryScene() {
  const { b2, save, note } = useB2();
  const [tile, setTile] = useState(0);
  const [mats, setMats] = useState<M2[]>(() => TILES.map(t => { const v = b2.shelf[t.id]?.value; return Array.isArray(v) && Array.isArray(v[0]) ? (v as number[][]).map(r => [...r]) as M2 : [[2, 1], [1, 2]]; }));
  const A = mats[tile]!, T = trace(A), D = det(A), reg = regionNear(T, D), right = TILES[tile]!.ok(reg);
  const f = frame(-4, 4, -3, 5, MAP);
  const setEntry = (i: number, j: number) => (x: number) => setMats(ms => ms.map((M, k) => (k !== tile ? M : M.map((r, a) => r.map((v, b) => (a === i && b === j ? x : v))) as M2)));
  const savedHere = JSON.stringify(b2.shelf[TILES[tile]!.id]?.value) === JSON.stringify(A);
  const count = TILES.filter((t, k) => TILES[k]!.ok(regionNear(trace(mats[k]!), det(mats[k]!))) && JSON.stringify(b2.shelf[t.id]?.value) === JSON.stringify(mats[k])).length;
  const onSave = () => {
    if (!right) return;
    save(TILES[tile]!.id, A.map(r => [...r]), "de-gallery", { note: `a ${TILES[tile]!.name.toLowerCase()}: T = ${T}, D = ${D}` });
    note({ id: "de-gallery", track: "de", title: "Phase portrait gallery", project: "de-gallery", data: {},
      lines: TILES.map((t, k) => `${t.name}: ${mat(mats[k]!)}`) });
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Gallery tile ${TILES[tile]!.name}: T = ${T}, D = ${D}, ${TYPES[reg] ?? "D = 0"}.`}>
      <MapBase quiet={false} shade={false} />
      {mats.map((M, k) => <circle key={k} cx={f.X(Math.max(-4, Math.min(4, trace(M))))} cy={f.Y(Math.max(-3, Math.min(5, det(M))))} r={k === tile ? 8 : 5} className={k === tile ? "b2handle" : `b2dot ${TILES[k]!.tone}`} />)}
      <Mini A={A} />
      <text x={(MINI.l + MINI.r) / 2} y={MINI.t - 8} textAnchor="middle" className={`b2t ${TILES[tile]!.tone}`}>{TILES[tile]!.name}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Toggle label="Tile" value={String(tile)} onChange={v => setTile(Number(v))} options={TILES.map((t, k) => ({ v: String(k), label: t.name }))} />
        {[[0, 0, "a₁₁"], [0, 1, "a₁₂"], [1, 0, "a₂₁"], [1, 1, "a₂₂"]].map(([i, j, lab]) => (
          <Slider key={lab as string} label={lab as string} value={A[i as number]![j as number]!} min={-5} max={5} step={1} onChange={setEntry(i as number, j as number)} />
        ))}
      </>}
      readouts={<>
        <Read label="T, D" value={`${T}, ${D}`.replace(/-/g, "−")} />
        <Read label="Lands in" value={TYPES[reg] ?? "D = 0"} tone={TILES[tile]!.tone} />
        <Read label="Tiles kept" value={`${count} of 4`} />
      </>}
      foot={<SaveRow what={right ? <>Keep <b>{TILES[tile]!.id} = {mat(A)}</b></> : <>Move the dot into the {TILES[tile]!.name.toLowerCase()} region to keep it</>} saved={savedHere && right} onSave={onSave} />}
    />
  );
}
