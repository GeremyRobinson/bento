// The Log-log plotter (13): held-out error against training-set size, on ordinary axes (a curve that flattens) or log-log
// axes (close to a straight line). On log-log axes the line's two ends are handles; "Best fit" puts it through the
// points by least squares on the logs. Past the last point the plot is shaded: no data here, so the line is a guess.
// Modes: demo (Play: a made-up set that follows a power law with noise), reader (the build's own runs at 100, 300,
// 1,000 and 3,000 digits; with `save` it trains them here), problem (Work it: the two measured points).
import { useEffect, useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Toggle, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { SCALING_ERR, SCALING_SIZES, scalingPlan } from "../digits";
import { logFit, ten } from "../maths";
import { Btn, Btns, lin, useTrainer } from "./common";

type Pt = [number, number];
/** Play's points: E = 0.9 · N^(−0.3), each nudged by a fixed few percent */
const DEMO: Pt[] = [[10, 0.45], [30, 0.33], [100, 0.23], [300, 0.165], [1000, 0.115], [3000, 0.083], [10000, 0.06]];
const TICKS = [1, 2, 5];

export function LogLogScene({ props, marker }: SceneProps) {
  const mode = str<string>(props, "mode", "demo"), quiet = flag(props, "quiet"), saving = flag(props, "save");
  const upto = num(props, "upto", 4);
  // the build's own runs, trained here when saving
  const [runs, setRuns] = useState<number[]>([]);
  const [go, setGo] = useState(false);
  const k = runs.length, plan = saving && go && k < 4 ? scalingPlan(SCALING_SIZES[k]!) : null;
  const tr = useTrainer(plan, { every: plan?.epochs ?? 1, testLimit: 1797 });
  useEffect(() => {
    const p = tr.passes.at(-1);
    if (plan && p && p.epoch === plan.epochs && !tr.busy) setRuns(r => (r.length === k ? [...r, p.testErr] : r));
  }, [tr.passes, tr.busy]); // eslint-disable-line react-hooks/exhaustive-deps
  const pts: Pt[] = useMemo(() => {
    if (mode === "problem") {
      const p = num(props, "p", 4), kk = num(props, "k", 2), E1 = num(props, "E1", 0.32), r = num(props, "r", 0.5);
      return [[10 ** p, E1], [10 ** (p + kk), E1 * r]];
    }
    if (mode === "reader") return saving ? runs.map((e, i) => [SCALING_SIZES[i]!, e] as Pt) : SCALING_SIZES.slice(0, upto).map((n, i) => [n, SCALING_ERR[i]!] as Pt);
    return DEMO;
  }, [mode, saving, runs, upto, props]);
  const [axes, setAxes] = useState<"log" | "plain">(mode === "demo" ? "plain" : "log");
  const fit = pts.length >= 2 ? logFit(pts) : null;
  // the line's two ends, in logs: [log N, log E] each
  const lastX = pts.length ? Math.log10(pts.at(-1)![0]) : 3, firstX = pts.length ? Math.log10(pts[0]![0]) : 1;
  const x0 = Math.floor(firstX) - (mode === "problem" ? 1 : 0.5), x1 = mode === "problem" ? lastX + num(props, "k", 2) + 0.6 : Math.max(lastX + 1, 4.5);
  const [ends, setEnds] = useState<[number, number] | null>(null);
  const line = ends ?? (fit && mode !== "demo" ? [fit[0] * x0 + fit[1], fit[0] * x1 + fit[1]] as [number, number] : [Math.log10(0.6), Math.log10(0.6)] as [number, number]);
  const slope = (line[1] - line[0]) / (x1 - x0);
  const { ref, drag } = useSvgDrag();
  const W = 360, H = 260, L0 = 46, R0 = 346, T0 = 16, B0 = 222;
  const ys = pts.map(p => Math.log10(p[1]));
  const yLo = Math.floor(Math.min(...ys, mode === "problem" ? Math.log10(num(props, "E1", 0.32) * num(props, "r", 0.5) ** 2) : 0) * 2 - 0.5) / 2, yHi = Math.min(0, Math.ceil(Math.max(...ys) * 2 + 0.5) / 2);
  const log = axes === "log";
  const nMax = (pts.length ? pts.at(-1)![0] : 10 ** x1) * 1.1, eMax = Math.ceil(Math.max(...pts.map(p => p[1]), 0.1) * 11) / 10;
  const X = log ? lin(x0, x1, L0, R0) : lin(0, nMax, L0, R0), Y = log ? lin(yLo, yHi, B0, T0) : lin(0, eMax, B0, T0);
  const uy = lin(B0, T0, yLo, yHi);
  const px = (n: number) => X(log ? Math.log10(n) : n), py = (e: number) => Y(log ? Math.log10(e) : e);
  const edge = px(pts.length ? pts.at(-1)![0] : 10 ** x1);
  const ticksX: number[] = [], ticksY: number[] = [];
  for (let e = Math.ceil(x0); e <= Math.floor(x1); e++) ticksX.push(e);
  for (let e = Math.floor(yLo); e <= 0; e++) for (const t of TICKS) { const v = Math.log10(t) + e; if (v >= yLo - 1e-9 && v <= yHi + 1e-9) ticksY.push(v); }
  const curveLine = log
    ? `M${X(x0)},${Y(line[0])} L${X(x1)},${Y(line[1])}`
    : Array.from({ length: 80 }, (_, i) => { const lx = x0 + ((Math.log10(nMax) - x0) * i) / 79, ly = line[0] + slope * (lx - x0); return `${i ? "L" : "M"}${X(10 ** lx).toFixed(1)},${Y(Math.min(eMax, 10 ** ly)).toFixed(1)}`; }).join(" ");
  const showLine = !quiet && (mode !== "reader" || pts.length >= 2) && (mode !== "demo" || log || ends != null);
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={`${pts.length} points of held-out error against training size on ${log ? "log-log" : "ordinary"} axes${showLine ? `; the line's slope is ${fx(slope)}` : ""}.`}>
      <rect x={edge} y={T0} width={Math.max(0, R0 - edge)} height={B0 - T0} className="aizone" />
      <text x={Math.min(R0 - 4, edge + 6)} y={T0 + 14} className="b2t pink">{edge < R0 - 60 ? "no data here" : ""}</text>
      <line x1={L0} y1={B0} x2={R0} y2={B0} className="b2axis" />
      <line x1={L0} y1={B0} x2={L0} y2={T0} className="b2axis" />
      {log ? ticksX.map(e => <g key={e}><line x1={X(e)} y1={T0} x2={X(e)} y2={B0} className="b2grid" /><text x={X(e)} y={B0 + 16} textAnchor="middle" className="b2t">{ten(e)}</text></g>)
        : [0, 0.5, 1].map(f => <text key={f} x={X(f * nMax)} y={B0 + 16} textAnchor={f === 1 ? "end" : "middle"} className="b2t">{f ? Math.round(f * nMax).toLocaleString("en-US") : "0"}</text>)}
      {log ? ticksY.map(v => <g key={v}><line x1={L0} y1={Y(v)} x2={R0} y2={Y(v)} className="b2grid" /><text x={L0 - 5} y={Y(v) + 4} textAnchor="end" className="b2t">{+(10 ** v).toPrecision(2)}</text></g>)
        : [0, 0.5, 1].map(f => <text key={f} x={L0 - 5} y={Y(f * eMax) + 4} textAnchor="end" className="b2t">{fx(f * eMax)}</text>)}
      <text x={R0} y={B0 + 32} textAnchor="end" className="b2t">training size N</text>
      <text x={L0 + 4} y={T0 + 2} className="b2t">held-out error</text>
      {showLine && <path d={curveLine} className="ailine" />}
      {showLine && log && mode !== "problem" && [0, 1].map(i => <g key={i}>
        <circle cx={X(i ? x1 : x0)} cy={Y(line[i]!)} r="7" className="b2handle" />
        <circle cx={X(i ? x1 : x0)} cy={Y(line[i]!)} r="20" className="b2hit" {...drag((_, y) => setEnds(e => { const c = [...(e ?? line)] as [number, number]; c[i] = Math.max(yLo, Math.min(yHi, uy(y))); return c; }))} />
      </g>)}
      {pts.map(([n, e], i) => <g key={i}>
        <circle cx={px(n)} cy={py(e)} r="5.5" className="b2dot sky" />
        {(mode === "problem" || (mode === "reader" && !quiet)) && <text x={px(n) + 8} y={py(e) - 8} className="b2t sky">{mode === "problem" ? fx(e) : `${fx(e * 100, 1)}%`}</text>}
      </g>)}
      {marker && mode === "reader" && <g>
        <circle cx={px(3000)} cy={py(Math.max(0.001, marker[0] / 100))} r="9" className="b2marker" />
        <text x={px(3000)} y={py(Math.max(0.001, marker[0] / 100)) + 24} textAnchor="middle" className="b2t">your guess</text>
      </g>}
      {saving && plan && <text x={L0 + 8} y={B0 - 10} className="b2t">training on {SCALING_SIZES[k]!.toLocaleString("en-US")} digits…</text>}
    </svg>
  );
  const alpha = fit ? Math.round(-fit[0] * 100) / 100 : null;
  const { b2, save, note } = useB2();
  const saved = alpha != null && b2.shelf.alpha_digits?.value === alpha;
  return (
    <Scene svg={svg}
      controls={<>
        <Toggle label="Axes" value={axes} onChange={setAxes} options={[{ v: "plain", label: "Ordinary axes" }, { v: "log", label: "Log-log axes" }]} />
        <Btns>
          {fit && log && mode !== "problem" && <Btn onClick={() => setEnds([fit[0] * x0 + fit[1], fit[0] * x1 + fit[1]])}>Best fit</Btn>}
          {saving && <Btn on={!go} onClick={() => setGo(true)} disabled={go}>{k >= 4 ? "All four trained" : go ? `Training ${k + 1} of 4` : "Train at 100, 300, 1,000, 3,000"}</Btn>}
        </Btns>
      </>}
      readouts={quiet ? <Read label="Runs shown" value={pts.map(p => p[0].toLocaleString("en-US")).join(", ")} /> : <>
        {showLine && <Read label="Your line's slope" value={fx(slope)} tone="amber" big />}
        {fit && mode !== "problem" && <Read label="Best-fit slope" value={fx(fit[0])} />}
        {mode === "reader" && pts.length > 0 && <Read label="Last error" value={`${fx(pts.at(-1)![1] * 100, 1)}%`} tone="sky" />}
      </>}
      foot={saving && alpha != null && k >= 4 ? <SaveRow what={<>Keep the slope's size, <b>α = {fx(alpha)}</b>, as <b>alpha_digits</b></>} saved={saved}
        onSave={() => {
          save("alpha_digits", alpha, "b2-ai-13", { note: "held-out error ∝ N^(−α) for the reader, fitted at 100 to 3,000 digits" });
          note({ id: "ai-scaling", track: "ai", title: "The reader's scaling line", data: { alpha, e3000: runs[3]! },
            lines: [`Held-out error at 100, 300, 1,000, 3,000 digits: ${runs.map(e => `${fx(e * 100, 1)}%`).join(", ")}.`, `Least-squares slope on log-log axes: −${fx(alpha)}. Past 3,000 the line is a guess; at 0 error it would need infinitely many digits.`] });
        }} /> : undefined}
    />
  );
}
