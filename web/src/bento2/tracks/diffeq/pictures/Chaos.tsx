// The chaos panel (diffeq.md, "New for Development" 9): the logistic map's cobweb, its period-doubling bifurcation
// diagram, "two starts" (the log of the gap against step), and twin driven pendulums that start 0.001° apart.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, Toggle } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { solve } from "../maths";
import { frame, useLoop, useRun } from "./plot";

const W = 360, H = 270;
type View = "cobweb" | "bif" | "gap" | "twins";
const VIEWS: { v: View; label: string }[] = [{ v: "twins", label: "Pendulums" }, { v: "cobweb", label: "Cobweb" }, { v: "bif", label: "Bifurcation" }, { v: "gap", label: "Gap" }];
const map = (r: number, x: number) => r * x * (1 - x);

function Cobweb({ r, quiet }: { r: number; quiet: boolean }) {
  const t = useLoop(30);
  const n = Math.floor((t * 4) % 64) + 1;
  const f = frame(0, 1, 0, 1, { l: 30, r: 246, t: 12, b: 228 });
  const xs = [0.2];
  for (let i = 0; i < 64; i++) xs.push(map(r, xs[i]!));
  const web: [number, number][] = [[f.X(xs[0]!), f.Y(0)]];
  for (let i = 0; i < n; i++) { web.push([f.X(xs[i]!), f.Y(xs[i + 1]!)]); web.push([f.X(xs[i + 1]!), f.Y(xs[i + 1]!)]); }
  const fp = 1 - 1 / r, stable = Math.abs(2 - r) < 1;
  const ts = frame(0, 30, 0, 1, { l: 262, r: 352, t: 12, b: 228 });
  return (
    <g>
      <rect x={f.box.l} y={f.box.t} width={f.box.r - f.box.l} height={f.box.b - f.box.t} className="b2bar track" />
      <line x1={f.X(0)} y1={f.Y(0)} x2={f.X(1)} y2={f.Y(1)} className="b2axis" opacity={0.6} />
      <path d={path(Array.from({ length: 61 }, (_, k) => [f.X(k / 60), f.Y(map(r, k / 60))] as [number, number]))} className="b2curve amber" />
      <path d={path(web)} className="b2curve trav" style={{ strokeWidth: 1.4 }} />
      {!quiet && <circle cx={f.X(fp)} cy={f.Y(fp)} r="5" className={stable ? "b2dot sky" : "b2clock sky"} />}
      <text x={f.box.r - 4} y={f.box.b - 6} textAnchor="end" className="b2t">xₙ</text>
      <text x={f.box.l + 6} y={f.box.t + 14} className="b2t">xₙ₊₁</text>
      <rect x={ts.box.l} y={ts.box.t} width={ts.box.r - ts.box.l} height={ts.box.b - ts.box.t} className="b2bar track" />
      {xs.slice(Math.max(0, n - 30), n + 1).map((x, i) => <circle key={i} cx={ts.X(i)} cy={ts.Y(x)} r="2.4" className="b2dot trav" />)}
      <text x={(ts.box.l + ts.box.r) / 2} y={ts.box.b + 16} textAnchor="middle" className="b2t">last 30</text>
    </g>
  );
}

function Bifurcation({ r }: { r: number }) {
  const f = frame(2.5, 4, 0, 1, { l: 30, r: 352, t: 12, b: 228 });
  const d = useMemo(() => {
    let s = "";
    for (let c = 0; c <= 240; c++) {
      const rr = 2.5 + (1.5 * c) / 240;
      let x = 0.3;
      for (let i = 0; i < 300; i++) x = map(rr, x);
      for (let i = 0; i < 60; i++) { x = map(rr, x); s += `M${f.X(rr).toFixed(1)},${f.Y(x).toFixed(1)}h1`; }
    }
    return s;
  }, []); // eslint-disable-line react-hooks/exhaustive-deps
  return (
    <g>
      <path d={d} className="b2curve mint" style={{ strokeWidth: 1.2 }} />
      <line x1={f.X(r)} y1={f.box.t} x2={f.X(r)} y2={f.box.b} className="b2leg pink" style={{ strokeWidth: 2 }} />
      <line x1={f.box.l} y1={f.box.b} x2={f.box.r} y2={f.box.b} className="b2axis" />
      <text x={f.box.l} y={f.box.b + 16} className="b2t">r = 2.5</text>
      <text x={f.box.r} y={f.box.b + 16} textAnchor="end" className="b2t">4</text>
    </g>
  );
}

function Gap({ r, k, quiet, run, marker }: { r: number; k: number; quiet: boolean; run: boolean; marker?: number }) {
  const prog = useRun(run, 3);
  const f = frame(0, 30, -11, 0.5, { l: 52, r: 352, t: 12, b: 228 });
  const a = [0.2], b = [0.2 + 10 ** -k];
  for (let i = 0; i < 30; i++) { a.push(map(r, a[i]!)); b.push(map(r, b[i]!)); }
  const gaps = a.map((x, i) => Math.log10(Math.max(1e-16, Math.abs(x - b[i]!))));
  const shown = quiet && !run ? 0 : run ? Math.ceil(30 * prog) : 30;
  return (
    <g>
      <line x1={f.box.l} y1={f.box.b} x2={f.box.r} y2={f.box.b} className="b2axis" />
      <line x1={f.box.l} y1={f.box.t} x2={f.box.l} y2={f.box.b} className="b2axis" />
      {[-10, -5, 0].map(e => <text key={e} x={f.box.l - 6} y={f.Y(e) + 4} textAnchor="end" className="b2t">{e === 0 ? "1" : `10${e === -5 ? "⁻⁵" : "⁻¹⁰"}`}</text>)}
      <line x1={f.box.l} y1={f.Y(-1)} x2={f.box.r} y2={f.Y(-1)} className="b2mark amber" />
      <text x={f.box.r} y={f.Y(-1) - 6} textAnchor="end" className="b2t amber">0.1</text>
      {/* the doubling line crosses 0.1 at the answer, so it waits for the reveal */}
      {!(quiet && !run) && <line x1={f.X(0)} y1={f.Y(-k)} x2={f.X(30)} y2={f.Y(-k + 30 * Math.log10(2))} className="b2mark sky" />}
      {gaps.slice(0, shown + 1).map((g, i) => <circle key={i} cx={f.X(i)} cy={f.Y(Math.min(0.5, g))} r="3.5" className="b2dot pink" />)}
      {marker !== undefined && <line x1={f.X(marker)} y1={f.box.t} x2={f.X(marker)} y2={f.box.b} className="b2mark guess" />}
      <text x={f.box.r} y={f.box.b + 16} textAnchor="end" className="b2t">step 30</text>
    </g>
  );
}

function useTwins(F: number) {
  return useMemo(() => {
    const f = (t: number, y: number[]) => [y[1]!, -Math.sin(y[0]!) - 0.5 * y[1]! + F * Math.cos((2 * t) / 3), y[3]!, -Math.sin(y[2]!) - 0.5 * y[3]! + F * Math.cos((2 * t) / 3)];
    const d = (0.001 * Math.PI) / 180;
    return solve(f, [0.2, 0, 0.2 + d, 0], 0, 90, 0.02);
  }, [F]);
}

export function ChaosScene({ props, marker, place }: SceneProps) {
  const [view, setView] = useState<View>(str<View>(props, "view", "twins"));
  const [r, setR] = useState(num(props, "r", 3.2));
  const [F, setF] = useState(1.2);
  const quiet = flag(props, "quiet");
  const { b2, note } = useB2();
  const twins = useTwins(F);
  const t = useLoop(0);
  const i = Math.floor(((t % 90) / 90) * (twins.length - 1)), now = twins[i]!;
  const part = twins.findIndex(p => Math.abs(p.y[0]! - p.y[2]!) > 0.1);
  const pf = frame(0, 90, -8, 1, { l: 40, r: 352, t: 150, b: 236 });
  const canSave = place === "project" || flag(props, "saveable");
  const saved = b2.notebook.some(n => n.id === "de-chaos" && n.data.F === F);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={view === "twins" ? `Two driven pendulums 0.001 degrees apart, push ${fx(F, 2)}: they part after ${part > 0 ? fx(twins[part]!.t, 0) : "more than 90"} seconds.` : `The logistic map at r = ${fx(r, 2)}.`}>
      {view === "cobweb" && <Cobweb r={r} quiet={quiet} />}
      {view === "bif" && <Bifurcation r={r} />}
      {view === "gap" && <Gap r={r} k={num(props, "k", 6)} quiet={quiet} run={flag(props, "run")} marker={marker?.[0]} />}
      {view === "twins" && <g>
        {[0, 2].map(j => { const th = now.y[j]!, cx = j === 0 ? 110 : 250, x = cx + 62 * Math.sin(th), y = 20 + 62 * Math.cos(th); return (
          <g key={j}>
            <line x1={cx - 14} y1="20" x2={cx + 14} y2="20" className="b2axis" />
            <line x1={cx} y1="20" x2={x} y2={y} className="b2leg" style={{ strokeWidth: 2.5 }} />
            <circle cx={x} cy={y} r="9" className={`b2dot ${j === 0 ? "sky" : "pink"}`} opacity={0.85} />
          </g>); })}
        <line x1={pf.box.l} y1={pf.box.b} x2={pf.box.r} y2={pf.box.b} className="b2axis" />
        <line x1={pf.box.l} y1={pf.box.t} x2={pf.box.l} y2={pf.box.b} className="b2axis" />
        <path d={path(twins.filter((_, j) => j % 10 === 0).map(p => [pf.X(p.t), pf.Y(Math.max(-8, Math.min(1, Math.log10(Math.abs(p.y[0]! - p.y[2]!) + 1e-12))))] as [number, number]))} className="b2curve trav" style={{ strokeWidth: 1.6 }} />
        <line x1={pf.X(now.t)} y1={pf.box.t} x2={pf.X(now.t)} y2={pf.box.b} className="b2mark" />
        <text x={pf.box.l + 6} y={pf.box.t + 10} className="b2t">gap, log scale</text>
        <text x={pf.box.r} y={pf.box.b + 16} textAnchor="end" className="b2t">90 s</text>
      </g>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Toggle label="View" value={view} onChange={setView} options={VIEWS} />
        {view === "twins" ? <Slider label="Push F" value={F} min={0.5} max={1.5} step={0.01} onChange={setF} format={x => fx(x, 2)} />
          : view !== "gap" && <Slider label="r" value={r} min={2.5} max={4} step={0.005} onChange={setR} format={x => fx(x, 3)} marks={[{ v: 3.2, label: "3.2" }, { v: 3.5, label: "3.5" }, { v: 3.9, label: "3.9" }]} />}
      </>}
      readouts={view === "twins" ? <>
        <Read label="They part (gap over 0.1) after" value={part > 0 ? `${fx(twins[part]!.t, 0)} s` : "more than 90 s"} tone="trav" />
      </> : view === "gap" ? <>
        <Read label="Gap doubles each step" value="at r = 4" />
      </> : quiet ? undefined : <>
        <Read label="Fixed point 1 − 1/r" value={fx(1 - 1 / r, 3)} tone="sky" />
        <Read label="Slope there, 2 − r" value={fx(2 - r, 3)} />
      </>}
      foot={canSave && view === "twins" ? <SaveRow what={<>Keep this push, <b>F = {fx(F, 2)}</b>, in your Notebook</>} saved={saved}
        onSave={() => note({ id: "de-chaos", track: "de", title: "A chaotic pendulum", data: { F }, lines: [`Driven pendulum, friction 0.5, push ${fx(F, 2)} at frequency 2/3.`, part > 0 ? `Two starts 0.001° apart part after ${fx(twins[part]!.t, 0)} s.` : "Two starts 0.001° apart stay together for 90 s."] })} /> : undefined}
    />
  );
}
