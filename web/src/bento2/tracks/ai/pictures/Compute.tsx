// The Compute meter (14): training compute C ≈ 6ND on a log scale from 1 to 10²⁶ FLOPs, where every step of the ruler
// is ten times the last, so a phone-sized run and the largest published runs fit on one line. On a log scale,
// multiplying is adding lengths: N's bar, D's bar and 6's short bar end to end make C's bar. Time is C over the speed.
// In Work it the C bar stays a question until the learner has worked it; with `build`, the reader's own run sits next
// to a published large run.
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { readerParams } from "../digits";
import { sci, sciText, ten } from "../maths";
import { lin } from "./common";

/** GPT-3's training compute as its paper reports it (Brown et al. 2020): about 3.14 × 10²³ FLOPs */
const GPT3 = 3.14e23;
const MAX = 26;

const timeText = (s: number) => s < 1e-3 ? `${fx(s * 1e6, 0)} µs` : s < 1 ? `${fx(s * 1000, 1)} ms` : s < 120 ? `${fx(s, 1)} s` : s < 7200 ? `${fx(s / 60, 1)} minutes` : s < 172800 ? `${fx(s / 3600, 1)} hours` : s < 3.15e7 * 2 ? `${fx(s / 86400, 0)} days` : `${sciText(...sci(s / 3.15e7))} years`;
const sciT = (x: number) => sciText(...sci(x));

export function ComputeScene({ props, place }: SceneProps) {
  const build = flag(props, "build"), work = place === "lesson" && !build && props.m != null;
  const { b2 } = useB2();
  const [nE, setNE] = useState(Math.log10(num(props, "m", 1)) + num(props, "a", 8));
  const [dE, setDE] = useState(Math.log10(num(props, "n", 1)) + num(props, "b", 9));
  const [s, setS] = useState(num(props, "s", 15));
  const reader = typeof b2.shelf.C_digits?.value === "number" ? (b2.shelf.C_digits.value as number) : 6 * readerParams(16) * 3000 * 20;
  const N = 10 ** nE, D = 10 ** dE, C = build ? reader : 6 * N * D, secs = C / 10 ** s;
  const W = 360, H = 260, X = lin(0, MAX, 24, 344);
  const bar = (y: number, from: number, to: number, cls: string, label: string, dash?: boolean) => <g>
    <rect x={X(from)} y={y} width={Math.max(2, X(to) - X(from))} height="16" rx="4" className={dash ? "aidiag" : `b2bar ${cls}`} fill={dash ? "none" : undefined} />
    <text x={X(from)} y={y - 5} className={`b2t ${dash ? "" : cls}`}>{label}</text>
  </g>;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={work ? `N = ${sciT(N)} and D = ${sciT(D)} as lengths on a log scale; C is for you to work out.` : `C = ${sciT(C)} FLOPs on a log scale, beside GPT-3's published ${sciT(GPT3)}; at ${ten(s)} FLOP/s it takes ${timeText(secs)}.`}>
      <line x1={X(0)} y1="226" x2={X(MAX)} y2="226" className="b2axis" />
      {Array.from({ length: MAX / 2 + 1 }, (_, i) => i * 2).map(e => <g key={e}>
        <line x1={X(e)} y1="222" x2={X(e)} y2="230" className="b2axis" />
        {e % 4 === 0 && <text x={X(e)} y="246" textAnchor="middle" className="b2t">{ten(e)}</text>}
      </g>)}
      <text x={X(MAX)} y="216" textAnchor="end" className="b2t">FLOPs, each mark × 100</text>
      {build ? <>
        {bar(40, 0, Math.log10(C), "amber", `the reader: ${sciT(C)}`)}
        {bar(96, 0, Math.log10(GPT3), "sky", `GPT-3 (published): ${sciT(GPT3)}`)}
      </> : <>
        {bar(34, 0, nE, "sky", `N = ${sciT(N)} parameters`)}
        {bar(80, 0, dE, "mint", `D = ${sciT(D)} tokens`)}
        {bar(126, 0, nE, "sky", "")}
        {bar(126, nE, nE + dE, "mint", "")}
        {bar(126, nE + dE, nE + dE + Math.log10(6), "pink", "")}
        <text x="24" y="121" className="b2t">end to end: N, then D, then 6</text>
        {work ? bar(172, 0, Math.min(MAX, nE + dE + Math.log10(6)), "", "C = 6ND: yours to work out", true) : bar(172, 0, Math.min(MAX, Math.log10(C)), "amber", `C = ${sciT(C)} FLOPs`)}
        {!work && <line x1={X(Math.log10(GPT3))} y1="20" x2={X(Math.log10(GPT3))} y2="222" className="aidiag" />}
        {!work && <text x={X(Math.log10(GPT3)) - 4} y="18" textAnchor="end" className="b2t">GPT-3</text>}
      </>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={build || work ? <Slider label="Speed, FLOP/s" value={s} min={9} max={18} step={1} onChange={setS} format={v => ten(v)} marks={[{ v: 12, label: "a phone" }, { v: 15, label: "a big chip" }]} /> : <>
        <Slider label="Parameters N" value={nE} min={3} max={12} step={0.1} onChange={setNE} format={v => sciT(10 ** v)} />
        <Slider label="Tokens D" value={dE} min={3} max={13} step={0.1} onChange={setDE} format={v => sciT(10 ** v)} />
        <Slider label="Speed, FLOP/s" value={s} min={9} max={18} step={1} onChange={setS} format={v => ten(v)} marks={[{ v: 12, label: "a phone" }, { v: 15, label: "a big chip" }]} />
      </>}
      readouts={work ? <><Read label="N" value={sciT(N)} tone="sky" /><Read label="D" value={sciT(D)} tone="mint" /><Read label="Speed" value={`${ten(s)} FLOP/s`} /></> : <>
        <Read label="C" value={`${sciT(C)} FLOPs`} tone="amber" big />
        <Read label={`Time at ${ten(s)} FLOP/s, at peak`} value={timeText(secs)} />
        {build && <Read label="GPT-3 used" value={`${sciT(GPT3 / C)} times as much`} tone="sky" />}
        {!build && <Read label="Tokens per parameter" value={fx(D / N, D / N < 10 ? 1 : 0)} />}
      </>}
    />
  );
}
