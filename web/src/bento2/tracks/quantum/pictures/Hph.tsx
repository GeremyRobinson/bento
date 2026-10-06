// H, phase, H (quantum.md, 06 and the project Dial a chance): a one-qubit circuit with a phase slider. After the first H
// the chances are 50/50 whatever φ is; the second H adds the arrows 1/2 and e^{iφ}/2 head to tail, and their sum is
// the amplitude of 0, so P(0) = cos²(φ/2). Run sends 1,000 shots. The project aims at a chance and saves `dial`.
import { useEffect, useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { ArrowHead, fx, Read, SaveRow, Scene, Slider, Toggle, useTween } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { shots, tally } from "../maths";
import { ShotBars, shownOf, useRun } from "./parts";
import { fr } from "../maths";

const W = 360, H = 260, N = 1000;
const TARGETS = [1, 3 / 4, 1 / 2, 1 / 4, 0];

export function HphScene({ props, place, marker }: SceneProps) {
  const [phi, setPhi] = useState(num(props, "phi", 60));
  const [target, setTarget] = useState(num(props, "target", 0.25));
  const quiet = flag(props, "quiet"), project = flag(props, "project"), sum = flag(props, "sum");
  const run = useRun(4, sum && place === "lesson");
  const { b2, save, note } = useB2();
  // the reveal grows the sum arrow out of the two halves
  const [g, setG] = useState(sum || !quiet ? (sum ? 0 : 1) : 0);
  useEffect(() => { if (sum) { const t = setTimeout(() => setG(1), 250); return () => clearTimeout(t); } }, [sum]);
  const grow = useTween(g, 1200);
  const t = (phi * Math.PI) / 180, P0 = (1 + Math.cos(t)) / 2, P1 = 1 - P0;
  const outs = useMemo(() => shots([P0, P1], N, 500 + run.runs), [run.runs]); // eslint-disable-line react-hooks/exhaustive-deps
  const shown = run.runs ? shownOf(run.k, N) : 0;
  const counts = tally(outs, 2, shown);
  const hide = quiet && !sum;
  const sc = 140, O: [number, number] = [36, 168];
  const A: [number, number] = [O[0] + sc / 2, O[1]];
  const B: [number, number] = [A[0] + (sc / 2) * Math.cos(t), A[1] - (sc / 2) * Math.sin(t)];
  const S: [number, number] = [O[0] + (B[0] - O[0]) * grow, O[1] + (B[1] - O[1]) * grow];
  const box = (x: number, label: string, tone?: string) => <g className={tone}>
    <rect x={x - 16} y="16" width="32" height="30" rx="7" className="b2bar track" />
    <text x={x} y="36" textAnchor="middle" className={`b2t${tone ? ` ${tone}` : ""}`}>{label}</text>
  </g>;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic hph" role="img"
      aria-label={`H, phase ${phi}°, H.${hide ? "" : ` The chance of 0 at the end is ${fx(P0, 3)}.`}`}>
      <line x1="10" y1="31" x2="214" y2="31" className="b2axis" />
      <text x="10" y="24" className="b2t">0</text>
      {box(58, "H")}{box(110, `${Math.round(phi)}°`, "pink")}{box(162, "H")}
      {/* the second H adds the two arrows: 1/2 and e^{iφ}/2 */}
      <circle cx={A[0]} cy={A[1]} r={sc / 2} className="b2ring" opacity="0.5" />
      <g className="sky"><line x1={O[0]} y1={O[1]} x2={A[0]} y2={A[1]} className="b2leg" /><ArrowHead x1={O[0]} y1={O[1]} x2={A[0]} y2={A[1]} className="b2dot" /></g>
      <g className="pink"><line x1={A[0]} y1={A[1]} x2={B[0]} y2={B[1]} className="b2leg" /><ArrowHead x1={A[0]} y1={A[1]} x2={B[0]} y2={B[1]} className="b2dot" /></g>
      {!hide && Math.hypot(S[0] - O[0], S[1] - O[1]) > 3 && <g className="amber">
        <line x1={O[0]} y1={O[1]} x2={S[0]} y2={S[1]} className="b2leg" strokeWidth="4" />
        <ArrowHead x1={O[0]} y1={O[1]} x2={S[0]} y2={S[1]} className="b2dot" />
      </g>}
      <text x={O[0]} y={O[1] + 22} className="b2t sky">1/2</text>
      <text x={B[0] + 6} y={B[1] + (Math.sin(t) > 0 ? -8 : 18)} className="b2t pink">e^(iφ)/2</text>
      {/* after the first H: always 50/50 */}
      <rect x="232" y="64" width="16" height="170" rx="4" className="b2bar track" />
      <rect x="232" y="64" width="16" height="85" rx="4" className="b2bar sky" />
      <rect x="232" y="149" width="16" height="85" rx="4" className="b2bar pink" />
      <text x="240" y="254" textAnchor="middle" className="b2t">mid</text>
      <ShotBars x={266} y={64} w={86} h={170} labels={["0", "1"]} ps={[P0, P1]} counts={run.runs ? counts : hide ? [0, 0] : [P0 * N, P1 * N]} n={N} tones={["sky", "pink"]} hideP={hide} guess={marker?.[0]} />
      {project && <line x1="262" y1={64 + (1 - target) * 170} x2="306" y2={64 + (1 - target) * 170} className="b2mark amber" strokeWidth="2.5" />}
    </svg>
  );
  const hit = Math.abs(P0 - target) < 0.005;
  const saved = JSON.stringify(b2.shelf.dial?.value) === JSON.stringify([phi, P0]);
  const onSave = () => {
    save("dial", [phi, P0], "qu-dial", { labels: ["φ (degrees)", "P(0)"], note: `H, phase ${phi}°, H` });
    note({ id: "qu-dial", track: "qu", title: "Dial a chance", project: "qu-dial", data: { phi, target },
      lines: [`H, phase(${phi}°), H gives P(0) = (1 + cos ${phi}°)/2 = ${fx(P0, 3)}.`, `Aimed at ${fr(target)}${hit ? ", and hit it" : ""}.`,
        ...(run.done ? [`1,000 shots gave ${counts[0]} zeros.`] : [])] });
  };
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Phase φ" value={phi} min={0} max={360} step={1} onChange={setPhi} format={v => `${v}°`} marks={[0, 60, 90, 120, 180].map(v => ({ v, label: `${v}°` }))} />
        {project && <Toggle label="Aim for P(0)" value={String(target)} onChange={v => setTarget(Number(v))} options={TARGETS.map(x => ({ v: String(x), label: fr(x) }))} />}
        {!hide && <button type="button" className="ctl go" onClick={run.run}>{run.runs ? "Run 1,000 again" : "Run 1,000 shots"}</button>}
      </>}
      readouts={<>
        <Read label="After the first H" value="P(0) = 1/2" />
        <Read label={hide ? "Amplitude of 0" : "Amplitude of 0, (1 + e^(iφ))/2"} value={hide ? "?" : `length ${fx(Math.abs(Math.cos(t / 2)), 3)}`} tone="amber" />
        <Read label="P(0) at the end" value={hide ? "?" : fx(P0, 3)} tone="sky" big />
        {shown > 0 && <Read label="Shots: 0s and 1s" value={`${counts[0]} and ${counts[1]}`} />}
        {project && <Read label={`Aim: P(0) = ${fr(target)}`} value={hit ? "on target" : `${P0 > target ? "lower" : "raise"} it: ${fx(Math.abs(P0 - target), 3)} off`} tone="amber" />}
      </>}
      foot={project ? <SaveRow what={<>Keep <b>dial</b>: φ = {phi}°, P(0) = {fx(P0, 3)}</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
