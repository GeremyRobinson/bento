// Gradient arrows (multivariable.md, tool 7): ∇f at every grid point and at one point you drag, always at right angles
// to its contour (12). Also project 3, the Rain map (streams follow −∇f, basins colored, passes marked), and the flat
// spot finder that classifies pits, peaks and passes by the Hessian (13).
import { useMemo, useState, type ReactElement } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, useClock, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { basins, contour, flatSpots, grad, hess, KIND_WORD, sample, seeded } from "../maths";
import { Arrow, FlatMap, mapper, nice, segPath, useLandscape } from "./common";

const W = 360, H = 250;

export function GradientScene({ props }: SceneProps) {
  const { f, box } = useLandscape(props);
  const pick = flag(props, "pick"), quiet = flag(props, "quiet");
  const [p, setP] = useState<[number, number]>([num(props, "px", 1), num(props, "py", 1)]);
  const { ref, drag } = useSvgDrag();
  const wide = box[1] - box[0] > box[3] - box[2];
  const m = mapper(box, wide ? [6, 4, 348, 174] : [70, 4, 220, 220]);
  const [gx, gy] = grad(f, ...p), G = Math.hypot(gx, gy);
  const level = f(...p);
  const here = useMemo(() => contour(sample(f, box, 60), level), [f, box, level]);
  // arrows on a grid, scaled to the longest
  const n = wide ? [15, 8] : [9, 9];
  const field: [number, number, number, number][] = [];
  let maxG = 1e-9;
  for (let i = 0; i < n[0]!; i++) for (let j = 0; j < n[1]!; j++) {
    const x = box[0] + ((box[1] - box[0]) * (i + 0.5)) / n[0]!, y = box[2] + ((box[3] - box[2]) * (j + 0.5)) / n[1]!, [u, v] = grad(f, x, y);
    field.push([x, y, u, v]); maxG = Math.max(maxG, Math.hypot(u, v));
  }
  const cell = Math.min(m.frame[2] / n[0]!, m.frame[3] / n[1]!) * 0.8;
  const ux = gx / (G || 1), uy = gy / (G || 1), L = 40, cx = m.X(p[0]), cy = m.Y(p[1]);
  const len = pick ? L : Math.max(14, Math.min(60, (G / maxG) * 60));
  // the four choices: along the contour, up (∇f), down (−∇f), and uphill but slanted
  const s45 = Math.SQRT1_2, choices: [number, number][] = [[-uy, ux], [ux, uy], [-ux, -uy], [s45 * (ux - uy), s45 * (uy + ux)]];
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`Gradient at (${nice(p[0])}, ${nice(p[1])})${quiet ? "" : `: ⟨${nice(gx)}, ${nice(gy)}⟩, length ${nice(G)}`}. It crosses the contour at a right angle.`}>
      <FlatMap f={f} box={box} m={m} levels={12}>
        {!quiet && !pick && field.map(([x, y, u, v], i) => { const l = (Math.hypot(u, v) / maxG) * cell, a = Math.atan2(v, u); return l < 1.5 ? null : <Arrow key={i} x1={m.X(x)} y1={m.Y(y)} x2={m.X(x) + Math.cos(a) * l} y2={m.Y(y) - Math.sin(a) * l} cls="pink faint" w={1.3} />; })}
        <path d={segPath(here, m.X, m.Y)} className="mvcont hi amber" />
        {pick ? choices.map(([u, v], i) => {
          const on = !quiet && i === 1;
          return <g key={i}>
            <Arrow x1={cx} y1={cy} x2={cx + u * L} y2={cy - v * L} cls={on ? "pink" : quiet ? "trav" : "trav faint"} w={on ? 3.2 : 2.2} />
            <text x={cx + u * (L + 13)} y={cy - v * (L + 13) + 5} textAnchor="middle" className={`b2t ${on ? "pink" : ""}`}>{"ABCD"[i]}</text>
          </g>;
        }) : <>
          <Arrow x1={cx} y1={cy} x2={cx + ux * len} y2={cy - uy * len} cls="pink" w={3.2} />
          <path d={`M${cx - uy * 9},${cy - ux * 9} l${ux * 9},${-uy * 9} l${uy * 9},${ux * 9}`} className="mvframe" />
        </>}
        <circle cx={cx} cy={cy} r="5" className="mvball" />
        {!pick && <circle cx={cx} cy={cy} r="18" className="b2hit" {...drag((x, y) => setP([Math.round(Math.max(box[0], Math.min(box[1], m.ix(x))) * 10) / 10, Math.round(Math.max(box[2], Math.min(box[3], m.iy(y))) * 10) / 10]))} />}
      </FlatMap>
    </svg>
  );
  return (
    <Scene svg={svg}
      readouts={<>
        <Read label="Point" value={`(${nice(p[0])}, ${nice(p[1])})`} tone="trav" />
        {!quiet && <Read label="∇f" value={`⟨${fx(gx, 2)}, ${fx(gy, 2)}⟩`} tone="pink" />}
        {!quiet && <Read label="Steepest slope |∇f|" value={fx(G, 2)} tone="pink" />}
        <Read label="Its contour" value={`f = ${fx(level, 2)}`} tone="amber" />
      </>} />
  );
}

const TONES = ["sky", "pink", "amber", "trav", "mint"];

/** Project 3 · Rain map: streams follow −∇f, each spot colored by the valley it drains to, passes marked. */
export function RainScene({ props }: SceneProps) {
  const { f, box } = useLandscape({ ...props, fn: "mine" });
  const project = flag(props, "project");
  const { b2, save, note } = useB2();
  const m = mapper(box, [6, 4, 348, 174]);
  const nx = 96, ny = 48;
  const { cells, shares, bottoms, passes, streams } = useMemo(() => {
    const g = sample(f, box, nx, ny), { label, bottoms } = basins(g);
    const W1 = nx + 1, count = new Array(bottoms.length).fill(0) as number[];
    const cells: ReactElement[] = [];
    for (let j = 0; j <= ny; j++) {
      let i = 0;
      while (i <= nx) {
        const lb = label[j * W1 + i]!, s = i;
        while (i <= nx && label[j * W1 + i] === lb) { count[lb]!++; i++; }
        const cw = (box[1] - box[0]) / nx, ch = (box[3] - box[2]) / ny;
        cells.push(<rect key={`${j}-${s}`} x={m.X(box[0] + (s - 0.5) * cw)} y={m.Y(box[2] + (j + 0.5) * ch)} width={(i - s) * cw * m.s + 0.4} height={ch * m.s + 0.4} className={`mvbasin ${TONES[lb % TONES.length]}`} />);
      }
    }
    const total = count.reduce((a, b) => a + b, 0);
    const bots = bottoms.map(k => { const i = k % W1, j = (k - i) / W1; return [box[0] + ((box[1] - box[0]) * i) / nx, box[2] + ((box[3] - box[2]) * j) / ny] as [number, number]; });
    const passes = flatSpots(f, box).filter(s => s.kind === "pass");
    const r = seeded(11), streams: [number, number][][] = [];
    for (let k = 0; k < 44; k++) {
      let x = box[0] + r() * (box[1] - box[0]), y = box[2] + r() * (box[3] - box[2]);
      const pts: [number, number][] = [[x, y]];
      for (let s = 0; s < 220; s++) {
        const [gx, gy] = grad(f, x, y), G = Math.hypot(gx, gy);
        if (G < 1e-3) break;
        x -= (gx / G) * 0.02; y -= (gy / G) * 0.02;
        if (x < box[0] || x > box[1] || y < box[2] || y > box[3]) break;
        pts.push([x, y]);
      }
      streams.push(pts);
    }
    return { cells, shares: count.map(c => c / total), bottoms: bots, passes, streams };
  }, [f, box]); // eslint-disable-line react-hooks/exhaustive-deps
  const t = useClock(true, 99);
  const shown = Math.min(streams.length, Math.floor(t * 12));
  const big = shares.map((s, i) => ({ s, i })).filter(o => o.s > 0.01);
  const value = big.map(o => o.s);
  const saved = Array.isArray(b2.shelf.basins?.value) && JSON.stringify(b2.shelf.basins!.value) === JSON.stringify(value);
  const onSave = () => {
    save("basins", value, "mv-rain", { labels: big.map(o => `basin ${o.i + 1}`), note: "the share of the plot draining to each valley" });
    note({ id: "mv-rain", track: "mv", title: "Rain map", project: "mv-rain", data: { basins: big.length, passes: passes.length },
      lines: [`${big.length} ${big.length === 1 ? "basin" : "basins"}: ${big.map(o => `${Math.round(o.s * 100)}%`).join(", ")} of the plot.`,
        passes.length ? `Passes at ${passes.map(p => `(${nice(p.x)}, ${nice(p.y)}), height ${nice(p.z, 3)}`).join("; ")}.` : "No passes inside the plot."] });
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`Rain map: ${big.length} basins. Streams run down −∇f into each valley; ${passes.length} ${passes.length === 1 ? "pass" : "passes"} marked.`}>
      <FlatMap f={f} box={box} m={m} levels={12}>
        {cells}
        {streams.slice(0, shown).map((s, i) => <path key={i} d={path(s.map(([x, y]) => [m.X(x), m.Y(y)]))} className="mvstream" />)}
        {bottoms.map(([x, y], i) => shares[i]! > 0.01 && <circle key={i} cx={m.X(x)} cy={m.Y(y)} r="4" className="mvdot" />)}
        {passes.map((p, i) => <g key={`p${i}`} transform={`translate(${m.X(p.x)},${m.Y(p.y)})`}><path d="M-6,-6L6,6M-6,6L6,-6" className="mvcut amber" /></g>)}
      </FlatMap>
      <text x={8} y={H - 54} className="b2t amber">✕ pass</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      readouts={<>
        {big.map(o => <Read key={o.i} label={`Basin ${o.i + 1}`} value={`${Math.round(o.s * 100)}% of the plot`} tone={TONES[o.i % TONES.length]} />)}
        {passes.map((p, i) => <Read key={`p${i}`} label="Pass" value={`(${nice(p.x)}, ${nice(p.y)}), height ${fx(p.z, 3)}`} tone="amber" />)}
      </>}
      foot={project && <SaveRow what={<>Keep <b>basins</b>: each valley's share of the plot</>} saved={saved} onSave={onSave} />} />
  );
}

/** The flat spots of a landscape, each classified by its Hessian; tap one to read its numbers (13). */
export function FlatsScene({ props }: SceneProps) {
  const { f, box } = useLandscape(props);
  const spots = useMemo(() => flatSpots(f, box), [f, box]);
  const [sel, setSel] = useState(0);
  const wide = box[1] - box[0] > box[3] - box[2];
  const m = mapper(box, wide ? [6, 4, 348, 174] : [70, 4, 220, 220]);
  const s = spots[Math.min(sel, spots.length - 1)];
  const H3 = s ? hess(f, s.x, s.y) : [0, 0, 0];
  const tone = (k: string) => (k === "pit" ? "sky" : k === "peak" ? "pink" : k === "pass" ? "amber" : "trav");
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img" aria-label={`${spots.length} flat spots: ${spots.map(p => KIND_WORD[p.kind]).join(", ")}.`}>
      <FlatMap f={f} box={box} m={m} levels={14}>
        {spots.map((p, i) => (
          <g key={i} onClick={() => setSel(i)} style={{ cursor: "pointer" }}>
            <circle cx={m.X(p.x)} cy={m.Y(p.y)} r={i === sel ? 8 : 6} className={`mvdot ${tone(p.kind)}`} />
            <circle cx={m.X(p.x)} cy={m.Y(p.y)} r="18" className="b2hit" />
            <text x={m.X(p.x)} y={m.Y(p.y) - 12} textAnchor="middle" className={`b2t ${tone(p.kind)}`}>{KIND_WORD[p.kind]}</text>
          </g>
        ))}
      </FlatMap>
    </svg>
  );
  return (
    <Scene svg={svg}
      readouts={s ? <>
        <Read label="Flat spot" value={`(${nice(s.x)}, ${nice(s.y)}), height ${fx(s.z, 3)}`} tone={tone(s.kind)} />
        <Read label="f_xx, f_yy, f_xy" value={`${fx(H3[0]!, 2)}, ${fx(H3[1]!, 2)}, ${fx(H3[2]!, 2)}`} />
        <Read label="D" value={fx(H3[0]! * H3[1]! - H3[2]! ** 2, 2)} />
        <Read label="Kind" value={KIND_WORD[s.kind]} tone={tone(s.kind)} big />
      </> : <Read label="Flat spots" value="none in view" />} />
  );
}
