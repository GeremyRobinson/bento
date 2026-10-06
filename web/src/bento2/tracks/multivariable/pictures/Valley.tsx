// The build · the valley finder (multivariable.md, project 5): any f(x, y), your own landscape or Two lakes, and an
// optional rectangular fence. "Search" drops 20 balls from seeded spots; each rolls downhill with a slow cool (a random
// kick that shrinks), and the lowest end wins. The Hessian test names what was found, a convexity check says whether one
// ball would have been enough, and the lake that would collect there fills up to the lowest pass.
import type { ReactElement } from "react";
import { useMemo, useState } from "react";
import { flag, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Toggle, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { compile, eig2, flatSpots, grad, hess, kindAt, KIND_WORD, lake, LAND_SRC, seeded, type Box, type F2 } from "../maths";
import { useTime, FlatMap, mapper, MINE, nice, type MineState } from "./common";

const W = 360, H = 250;
type Src = "mine" | "land" | "typed";

function search(f: F2, box: Box, fence: Box | null) {
  const area = fence ?? box, rnd = seeded(20);
  // the step size: half over the steepest curvature seen on a coarse grid
  let k = 1e-6;
  for (let i = 0; i <= 8; i++) for (let j = 0; j <= 8; j++) {
    const [a, c, b] = hess(f, area[0] + ((area[1] - area[0]) * i) / 8, area[2] + ((area[3] - area[2]) * j) / 8);
    k = Math.max(k, Math.abs(eig2(a, b, c)[0]), Math.abs(eig2(a, b, c)[1]));
  }
  const eta = Math.min(0.2, 0.5 / k), runs: [number, number][][] = [];
  for (let r = 0; r < 20; r++) {
    let x = area[0] + rnd() * (area[1] - area[0]), y = area[2] + rnd() * (area[3] - area[2]), T = 0.02;
    const trail: [number, number][] = [[x, y]];
    for (let s = 0; s < 240; s++) {
      const [gx, gy] = grad(f, x, y), u1 = Math.max(1e-12, rnd()), u2 = rnd(), g = Math.sqrt(-2 * Math.log(u1));
      const kick = Math.sqrt(2 * eta * T);
      x = Math.max(area[0], Math.min(area[1], x - eta * gx + kick * g * Math.cos(2 * Math.PI * u2)));
      y = Math.max(area[2], Math.min(area[3], y - eta * gy + kick * g * Math.sin(2 * Math.PI * u2)));
      T *= 0.97;
      trail.push([x, y]);
    }
    // finish with plain steps so every ball settles
    for (let s = 0; s < 200; s++) {
      const [gx, gy] = grad(f, x, y);
      x = Math.max(area[0], Math.min(area[1], x - eta * gx)); y = Math.max(area[2], Math.min(area[3], y - eta * gy));
    }
    trail.push([x, y]);
    runs.push(trail);
  }
  const ends = runs.map(t => t[t.length - 1]!), zs = ends.map(([x, y]) => f(x, y)), best = zs.indexOf(Math.min(...zs));
  // convex over the area? every curvature on the grid at least 0
  let convex = true;
  for (let i = 0; i <= 12 && convex; i++) for (let j = 0; j <= 12; j++) {
    const [a, c, b] = hess(f, area[0] + ((area[1] - area[0]) * i) / 12, area[2] + ((area[3] - area[2]) * j) / 12);
    if (eig2(a, b, c)[0] < -1e-3) { convex = false; break; }
  }
  const distinct = ends.filter((p, i) => ends.findIndex(q => Math.hypot(q[0] - p[0], q[1] - p[1]) < 0.05) === i).length;
  return { runs, best, x: ends[best]![0], y: ends[best]![1], z: zs[best]!, convex, distinct };
}

export function ValleyScene({ props }: SceneProps) {
  const project = flag(props, "project");
  const { b2, save, note, tool } = useB2();
  const mineSrc = tool<MineState>(MINE, { src: LAND_SRC }).src;
  const [which, setWhich] = useState<Src>("mine");
  const [text, setText] = useState("x^4 - 2*x^2 + y^2 + x*y/2");
  const [typed, setTyped] = useState(text);
  const src = which === "mine" ? mineSrc : which === "land" ? LAND_SRC : typed;
  const f = useMemo(() => compile(src) ?? compile(LAND_SRC)!, [src]);
  const box: Box = which === "typed" ? [-2, 2, -2, 2] : [-2, 2, -1, 1];
  const [fenced, setFenced] = useState(false);
  const [A, setA] = useState<[number, number]>([0.2, -0.6]), [B, setB] = useState<[number, number]>([1.6, 0.6]);
  const fence: Box | null = fenced ? [Math.min(A[0], B[0]), Math.max(A[0], B[0]), Math.min(A[1], B[1]), Math.max(A[1], B[1])] : null;
  const [run, setRun] = useState(0);
  const res = useMemo(() => (run ? search(f, box, fence) : null), [run, f, box.join(","), fence?.join(",")]); // eslint-disable-line react-hooks/exhaustive-deps
  const t = useTime(run > 0, 99), shown = Math.min(1, t / 2.5);
  const done = !!res && shown >= 1;
  const onFence = !!res && !!fence && (Math.abs(res.x - fence[0]) < 1e-3 || Math.abs(res.x - fence[1]) < 1e-3 || Math.abs(res.y - fence[2]) < 1e-3 || Math.abs(res.y - fence[3]) < 1e-3);
  const kind = res ? kindAt(f, res.x, res.y) : null;
  const [gx, gy] = res ? grad(f, res.x, res.y) : [0, 0];
  // the lake: fill from the lowest point up to the lowest pass above it (or a little, if there is none)
  const water = useMemo(() => {
    if (!res || onFence) return null;
    const passes = flatSpots(f, box).filter(p => p.kind === "pass" && p.z > res.z + 1e-6).sort((a, b) => a.z - b.z);
    const level = passes.length ? passes[0]!.z - 0.02 : res.z + 0.25;
    return { level, pass: passes[0] ?? null, ...lake(f, box, res.x, res.y, level - 1e-6, 120, Math.round((120 * (box[3] - box[2])) / (box[1] - box[0]))) };
  }, [res, onFence, f, box.join(",")]); // eslint-disable-line react-hooks/exhaustive-deps
  const m = mapper(box, which === "typed" ? [80, 4, 200, 200] : [6, 4, 348, 174]);
  const { ref, drag } = useSvgDrag();
  const rows: ReactElement[] = [];
  if (water && done) {
    const cw = (box[1] - box[0]) / water.nx, ch = (box[3] - box[2]) / water.ny;
    for (let j = 0; j < water.ny; j++) {
      let i = 0;
      while (i < water.nx) {
        if (!water.wet[j * water.nx + i]) { i++; continue; }
        const s = i;
        while (i < water.nx && water.wet[j * water.nx + i]) i++;
        rows.push(<rect key={`${j}-${s}`} x={m.X(box[0] + s * cw)} y={m.Y(box[2] + (j + 1) * ch)} width={(i - s) * cw * m.s + 0.4} height={ch * m.s + 0.4} className="mvwater" />);
      }
    }
  }
  // the cross-section through the lowest point, along x, with the lake's water in it
  const wide = which !== "typed";
  const sec: [number, number, number, number] = [26, 196, 324, 44];
  const sxs = Array.from({ length: 121 }, (_, i) => box[0] + ((box[1] - box[0]) * i) / 120);
  const gz = res ? sxs.map(x => f(x, res.y)) : [];
  const sz0 = res ? Math.min(...gz) - 0.05 : 0, sz1 = res ? Math.min(Math.max(...gz), (water?.level ?? res.z) + 1.5) : 1;
  const SX = (x: number) => sec[0] + ((x - box[0]) / (box[1] - box[0])) * sec[2], SZ = (z: number) => sec[1] + sec[3] - ((Math.min(sz1, z) - sz0) / (sz1 - sz0)) * sec[3];
  const wetRun = (() => {
    if (!water || !res) return null;
    let a = res.x, b = res.x;
    while (a > box[0] && f(a - 0.01, res.y) < water.level) a -= 0.01;
    while (b < box[1] && f(b + 0.01, res.y) < water.level) b += 0.01;
    return [a, b] as const;
  })();
  const snap = (v: number) => Math.round(v * 20) / 20;
  const what = !res ? "" : onFence ? "on the fence" : kind ? KIND_WORD[kind] : "";
  const saved = !!res && Array.isArray(b2.shelf.lowest?.value) && Math.abs((b2.shelf.lowest!.value as number[])[2]! - res.z) < 1e-9;
  const onSave = () => {
    if (!res) return;
    save("lowest", [res.x, res.y, res.z], "mv-valley", { labels: ["x", "y", "height"], note: `the lowest point of f(x, y) = ${src}${fence ? " inside the fence" : ""}` });
    note({ id: "mv-valley", track: "mv", title: "The build: the valley finder", project: "mv-valley", build: true, data: { fenced: fence ? 1 : 0 },
      lines: [`f(x, y) = ${src}${fence ? `, fenced to x from ${nice(fence[0])} to ${nice(fence[1])}, y from ${nice(fence[2])} to ${nice(fence[3])}` : ""}.`,
        `20 balls with a slow cool found ${res.distinct} resting place${res.distinct === 1 ? "" : "s"}. The lowest is (${nice(res.x, 3)}, ${nice(res.y, 3)}), height ${fx(res.z, 4)}: ${what}.`,
        res.convex ? "The landscape is convex here, so one ball would have found it." : "The landscape is not convex here, so the restarts were needed.",
        ...(water ? [`The lake there fills to ${fx(water.level, 3)}: volume ${fx(water.volume, 3)}, area ${fx(water.area, 3)}.`] : [])] });
  };
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic mv" role="img"
      aria-label={res ? `20 balls rolled downhill. The lowest point found is (${nice(res.x)}, ${nice(res.y)}), height ${nice(res.z, 3)}, ${what}.` : "The landscape's contour map, ready to search."}>
      <FlatMap f={f} box={box} m={m} levels={14}>
        {rows}
        {fence && <rect x={m.X(fence[0])} y={m.Y(fence[3])} width={(fence[1] - fence[0]) * m.s} height={(fence[3] - fence[2]) * m.s} className="mvpark" />}
        {res && res.runs.map((tr, i) => {
          const k = Math.max(1, Math.round(shown * (tr.length - 1)));
          const end = tr[k]!;
          return <g key={i}>
            <path d={path(tr.slice(0, k + 1).map(([x, y]) => [m.X(x), m.Y(y)]))} className="mvtrail" style={{ opacity: 0.35 }} />
            <circle cx={m.X(end[0])} cy={m.Y(end[1])} r="3.5" className="mvball ghost" />
          </g>;
        })}
        {water?.pass && done && <g transform={`translate(${m.X(water.pass.x)},${m.Y(water.pass.y)})`}><path d="M-6,-6L6,6M-6,6L6,-6" className="mvcut amber" /></g>}
        {res && done && <circle cx={m.X(res.x)} cy={m.Y(res.y)} r="8" className="mvball" />}
        {fence && ([[A, setA], [B, setB]] as const).map(([p, set], i) => <g key={i}>
          <circle cx={m.X(p[0])} cy={m.Y(p[1])} r="6" className="mvhandle amber" />
          <circle cx={m.X(p[0])} cy={m.Y(p[1])} r="18" className="b2hit" {...drag((x, y) => set([snap(Math.max(box[0], Math.min(box[1], m.ix(x)))), snap(Math.max(box[2], Math.min(box[3], m.iy(y))))]))} />
        </g>)}
      </FlatMap>
      {wide && res && done && <>
        <rect x={sec[0]} y={sec[1]} width={sec[2]} height={sec[3]} className="mvframe" />
        {wetRun && water && <rect x={SX(wetRun[0])} y={SZ(water.level)} width={SX(wetRun[1]) - SX(wetRun[0])} height={Math.max(0, sec[1] + sec[3] - SZ(water.level))} className="mvwater" />}
        <path d={path(sxs.map((x, i) => [SX(x), SZ(gz[i]!)]))} className="b2curve sky" />
        <circle cx={SX(res.x)} cy={SZ(res.z)} r="4" className="mvball" />
        <text x={sec[0]} y={sec[1] - 6} className="b2t">cross-section through the lowest point</text>
      </>}
      {!res && <text x={W / 2} y={H - 30} textAnchor="middle" className="b2t">press Search to drop 20 balls</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Toggle label="Which landscape" value={which} onChange={v => { setWhich(v); setRun(0); }}
          options={[{ v: "mine", label: "Mine" }, { v: "land", label: "Two lakes" }, { v: "typed", label: "Type one" }]} />
        {which === "typed" && <div className="mvform">
          <input aria-label="f(x, y) =" value={text} spellCheck={false}
            onChange={e => { const v = e.currentTarget.value; setText(v); if (compile(v)) { setTyped(v); setRun(0); } }} />
          <small>{compile(text) ? "f(x, y) =" : "Can't read that yet"}</small>
        </div>}
        <span className="b2marks">
          <button type="button" className={`ctl${fenced ? " on" : ""}`} aria-pressed={fenced} onClick={() => { setFenced(v => !v); setRun(0); }}>{fenced ? "Fence on" : "Add a fence"}</button>
          <button type="button" className="ctl go" onClick={() => setRun(r => r + 1)}>Search</button>
        </span>
      </>}
      readouts={res && done ? <>
        <Read label="Lowest found" value={`(${fx(res.x, 3)}, ${fx(res.y, 3)})`} tone="trav" big />
        <Read label="Height" value={fx(res.z, 4)} tone="trav" />
        <Read label="Hessian test" value={onFence ? `on the fence, ∇f = ⟨${fx(gx, 2)}, ${fx(gy, 2)}⟩` : what} tone="sky" />
        <Read label="Shape" value={res.convex ? "convex: one ball is enough" : `not convex: ${res.distinct} resting places`} tone="amber" />
        {water && <Read label="Lake there" value={`filled to ${fx(water.level, 3)}, volume ${fx(water.volume, 3)}`} tone="mint" />}
      </> : undefined}
      foot={project && res && done ? <SaveRow what={<>Keep <b>lowest</b>: the valley finder's answer</>} saved={saved} onSave={onSave} /> : undefined} />
  );
}
