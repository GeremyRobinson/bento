// Your quantum coin (quantum.md, 03 and its project): two complex arrows, one for 0 and one for 1, dragged on a whole
// number grid. Bento scales them so their squares fill one bar exactly (the Born rule), then Run sends 1,000 shots
// that pile up against the predicted chances. The project saves the scaled state as `psi`.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { cAbs2, cx, fr, shots, tally, type Cx } from "../maths";
import { ShotBars, shownOf, useRun } from "./parts";
import { ArrowHead } from "../../../ui/kit";

const W = 360, H = 260, N = 1000;
/** an amplitude over √total: "3/5", "(1 + 2i)/3", "(1 + i)/√6" */
const scaled = (z: Cx, t: number) => {
  const k = Math.sqrt(t);
  if (Number.isInteger(k)) return z[1] === 0 ? fr(z[0] / k) : z[0] === 0 ? `${z[1] < 0 ? "−" : ""}${Math.abs(z[1]) === 1 ? "" : Math.abs(z[1])}i/${k}` : `(${cx(...z)})/${k}`;
  return `(${cx(...z)})/√${t}`;
};

export function CoinScene({ props, marker }: SceneProps) {
  const [al, setAl] = useState<Cx>([num(props, "a0", 1), num(props, "a1", 2)]);
  const [be, setBe] = useState<Cx>([num(props, "b0", 2), num(props, "b1", 0)]);
  const quiet = flag(props, "quiet"), project = flag(props, "project");
  const run = useRun(4, flag(props, "run"));
  const { b2, save, note } = useB2();
  const { ref, drag } = useSvgDrag();
  const t = cAbs2(al) + cAbs2(be), k = Math.sqrt(t), P0 = cAbs2(al) / t, P1 = 1 - P0;
  const outs = useMemo(() => shots([P0, P1], N, 100 + run.runs), [P0, P1, run.runs]);
  const shown = run.runs ? shownOf(run.k, N) : 0;
  const counts = tally(outs, 2, shown);
  const ox = 92, oy = 128, sc = 19;
  const P = (c: Cx): [number, number] => [ox + c[0] * sc, oy - c[1] * sc];
  const back = (x: number, y: number): Cx => [Math.max(-4, Math.min(4, Math.round((x - ox) / sc))), Math.max(-4, Math.min(4, Math.round((oy - y) / sc)))];
  const setIf = (f: (c: Cx) => void, other: Cx) => (x: number, y: number) => { const c = back(x, y); if (cAbs2(c) + cAbs2(other) > 0) f(c); };
  const hide = quiet && !run.runs;
  const barX = 196, barTop = 24, barH = 210;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic coin" role="img"
      aria-label={`Amplitudes ${cx(...al)} for 0 and ${cx(...be)} for 1.${hide ? "" : ` Scaled, P(0) = ${fx(P0, 3)} and P(1) = ${fx(P1, 3)}.`}${shown ? ` ${counts[0]} zeros and ${counts[1]} ones so far.` : ""}`}>
      {[-4, -3, -2, -1, 1, 2, 3, 4].map(g => <g key={g}>
        <line x1={ox + g * sc} y1={oy - 4 * sc} x2={ox + g * sc} y2={oy + 4 * sc} className="b2grid" />
        <line x1={ox - 4 * sc} y1={oy - g * sc} x2={ox + 4 * sc} y2={oy - g * sc} className="b2grid" />
      </g>)}
      <line x1={ox - 4 * sc} y1={oy} x2={ox + 4 * sc} y2={oy} className="b2grid strong" />
      <line x1={ox} y1={oy - 4 * sc} x2={ox} y2={oy + 4 * sc} className="b2grid strong" />
      {([[al, "sky", "α", setAl, be], [be, "pink", "β", setBe, al]] as const).map(([c, tone, name, set, other]) => (
        <g key={name} className={tone}>
          {cAbs2(c) > 0 && <>
            <line x1={ox} y1={oy} x2={P(c)[0]} y2={P(c)[1]} className="b2leg" />
            <ArrowHead x1={ox} y1={oy} x2={P(c)[0]} y2={P(c)[1]} className="b2dot" />
          </>}
          <circle cx={P(c)[0]} cy={P(c)[1]} r="15" className="b2hit" {...drag(setIf(set, other))} />
          <circle cx={P(c)[0]} cy={P(c)[1]} r="5" className="b2handle" pointerEvents="none" />
          <text x={P(c)[0] + 8} y={P(c)[1] - 8} className="b2t">{name}</text>
        </g>
      ))}
      {/* the one bar: the two squares, scaled, always fill it */}
      <rect x={barX} y={barTop} width="22" height={barH} rx="5" className="b2bar track" />
      {!hide && <>
        <rect x={barX} y={barTop} width="22" height={P0 * barH} rx="5" className="b2bar sky" />
        <rect x={barX} y={barTop + P0 * barH} width="22" height={P1 * barH} rx="5" className="b2bar pink" />
      </>}
      {marker && <line x1={barX - 6} y1={barTop + (1 - marker[0]) * barH} x2={barX + 28} y2={barTop + (1 - marker[0]) * barH} className="b2mark guess" />}
      <text x={barX + 11} y={barTop + barH + 17} textAnchor="middle" className="b2t">all</text>
      <ShotBars x={252} y={barTop} w={96} h={barH} labels={["0", "1"]} ps={[P0, P1]} counts={counts} n={N} tones={["sky", "pink"]} hideP={hide} />
    </svg>
  );
  const psi = [al[0] / k, al[1] / k, be[0] / k, be[1] / k];
  const saved = JSON.stringify(b2.shelf.psi?.value) === JSON.stringify(psi);
  const onSave = () => {
    save("psi", psi, "qu-coin", { labels: ["Re α", "Im α", "Re β", "Im β"], note: `the state (${cx(...al)}, ${cx(...be)})/${fx(k, 3).replace(/\.?0+$/, "")}` });
    note({ id: "qu-coin", track: "qu", title: "Your quantum coin", project: "qu-coin", data: { a0: al[0], a1: al[1], b0: be[0], b1: be[1] },
      lines: [`Amplitudes (${cx(...al)}, ${cx(...be)}), scaled by 1/√${t}.`, `Predicted P(0) = ${fx(P0, 3)}, so ${Math.round(N * P0)} zeros in 1,000 shots, give or take about ${fx(Math.sqrt(N * P0 * P1), 1)}.`,
        ...(run.done ? [`The run gave ${counts[0]} zeros: ${Math.abs(counts[0]! - N * P0) <= 2 * Math.sqrt(N * P0 * P1) + 1 ? "within" : "outside"} two of those spreads.`] : [])] });
  };
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <button type="button" className="ctl go" onClick={run.run}>{run.runs ? "Run 1,000 again" : "Run 1,000 shots"}</button>}
      readouts={<>
        <Read label="α, scaled" value={hide ? "?" : scaled(al, t)} tone="sky" />
        <Read label="β, scaled" value={hide ? "?" : scaled(be, t)} tone="pink" />
        <Read label="P(0)" value={hide ? "?" : fx(P0, 3)} tone="sky" />
        <Read label="P(1)" value={hide ? "?" : fx(P1, 3)} tone="pink" />
        {shown > 0 && <Read label="Shots: 0s and 1s" value={`${counts[0]} and ${counts[1]}`} big />}
        {run.done && !hide && <Read label="Typical miss √(Np(1 − p))" value={fx(Math.sqrt(N * P0 * P1), 1)} />}
      </>}
      foot={project ? <SaveRow what={<>Keep <b>psi</b> = ({cx(...al)}, {cx(...be)})/{Number.isInteger(k) ? k : `√${t}`} on your Number shelf</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
