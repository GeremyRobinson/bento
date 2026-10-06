// The Reliability diagram (16): the reader's 1,797 held-out predictions sorted by how sure it was (bins 0.1 wide); each
// bar is how often it was right in that bin, against the dashed "says 80%, right 80%" diagonal. Temperature T divides
// the scores before softmax and slides every prediction's confidence; the "not sure" line trades how many digits it
// answers (coverage) against how often those answers are right.
// The build's last part (fieldnotes): fit T on the 823 training digits the reader never trained on, set the threshold,
// test it on a scribble, and write the Reader field notes, gathering the slope, the compute and the loophole.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { DEFAULT_PLAN, digitData, forward, predictions, softmaxT, type DigitSet } from "../digits";
import { fitTemperature, reliability, sciText, sci } from "../maths";
import { Btn, Btns, lin, Pad, padCounts, useTrainer } from "./common";

type Stroke = [number, number][];
/** the training digits past the 3,000 the reader learned from: held out, for fitting T */
const calibSet = (): DigitSet => { const t = digitData().train; return { x: t.x.slice(DEFAULT_PLAN.n), y: t.y.slice(DEFAULT_PLAN.n) }; };

export function ReliabilityScene({ props }: SceneProps) {
  return <Diagram quiet={flag(props, "quiet")} focus={flag(props, "focus")} project={flag(props, "project")} Tstart={num(props, "T", 1)} />;
}
export function FieldNotesScene() {
  return <Diagram quiet={false} focus={false} project />;
}

function Diagram({ quiet, focus, project, Tstart = 1 }: { quiet: boolean; focus: boolean; project: boolean; Tstart?: number }) {
  const tr = useTrainer(DEFAULT_PLAN, { every: 5 });
  const net = tr.ready && !tr.busy ? tr.net : null;
  const [T, setT] = useState(Tstart);
  const [thr, setThr] = useState(0.5);
  const [strokes, setStrokes] = useState<Stroke[]>([]);
  const { ref, drag } = useSvgDrag();
  const { b2, save, note } = useB2();
  const test = digitData().test;
  const preds = useMemo(() => (net ? predictions(net, test, T) : []), [net, T, test]);
  const base = useMemo(() => (net && project ? reliability(predictions(net, test, 1)) : null), [net, project, test]);
  const fitted = useMemo(() => (net && project ? (() => { const c = calibSet(); return fitTemperature(c.x.map((x, i) => ({ z: forward(net, x).z, y: c.y[i]! }))); })() : null), [net, project]);
  const rel = preds.length ? reliability(preds) : null;
  const covered = preds.filter(p => p.conf >= thr), cover = preds.length ? covered.length / preds.length : 0, accC = covered.length ? covered.filter(p => p.right).length / covered.length : 0;
  const W = 360, H = 260, L0 = 44, R0 = project ? 236 : 300, T0 = 22, B0 = 214;
  const X = lin(0.1, 1, L0, R0), Y = lin(0, 1, B0, T0);
  const top = preds.filter(p => p.conf >= 0.9), topRight = top.filter(p => p.right).length;
  const counts = padCounts(strokes);
  const scrib = net && strokes.length ? softmaxT(forward(net, counts).z, T) : null;
  const sBest = scrib ? Array.from(scrib).indexOf(Math.max(...scrib)) : -1;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={!net ? "The reader is training." : quiet ? "The reliability diagram's frame; the bars are hidden." : `At T = ${fx(T)}, ECE ${fx(rel!.ece, 3)}; answering only above ${fx(thr)}, it answers ${Math.round(cover * 100)}% and is right on ${fx(accC * 100, 1)}% of those.`}>
      <line x1={L0} y1={B0} x2={R0} y2={B0} className="b2axis" />
      <line x1={L0} y1={B0} x2={L0} y2={T0} className="b2axis" />
      {[0.2, 0.4, 0.6, 0.8, 1].map(v => <g key={v}>
        <text x={X(v)} y={B0 + 15} textAnchor="middle" className="b2t">{v}</text>
        <text x={L0 - 5} y={Y(v) + 4} textAnchor="end" className="b2t">{v}</text>
      </g>)}
      <text x={R0} y={B0 + 32} textAnchor="end" className="b2t">how sure it was</text>
      <text x={L0 + 4} y={T0 - 8} className="b2t">how often right</text>
      <line x1={X(0.1)} y1={Y(0.1)} x2={X(1)} y2={Y(1)} className="aidiag" />
      {!net && <text x={(L0 + R0) / 2} y={(T0 + B0) / 2} textAnchor="middle" className="b2t">training the reader: pass {tr.passes.at(-1)?.epoch ?? 0} of {DEFAULT_PLAN.epochs}</text>}
      {quiet && net && <text x={(L0 + R0) / 2} y={(T0 + B0) / 2} textAnchor="middle" className="b2t">bars hidden until you guess</text>}
      {!quiet && base && base.bins.map((b, i) => b.n > 0 && b.lo >= 0.1 && <rect key={`b${i}`} x={X(b.lo) + 2} y={Y(b.acc)} width={X(b.hi) - X(b.lo) - 4} height={B0 - Y(b.acc)} fill="none" className="aidiag" />)}
      {!quiet && rel && rel.bins.map((b, i) => b.n > 0 && b.lo >= 0.1 && <g key={i}>
        <rect x={X(b.lo) + 2} y={Y(b.acc)} width={X(b.hi) - X(b.lo) - 4} height={B0 - Y(b.acc)} className={`b2bar ${focus && b.lo >= 0.9 - 1e-9 ? "amber" : "sky"}`} opacity={0.35 + 0.65 * Math.min(1, b.n / 60)} />
      </g>)}
      {!quiet && net && <>
        <line x1={X(Math.max(0.1, thr))} y1={T0} x2={X(Math.max(0.1, thr))} y2={B0} className="b2mark" />
        <text x={X(Math.max(0.1, thr)) - 4} y={T0 + 14} textAnchor="end" className="b2t">not sure ←</text>
      </>}
            {project && <g>
        <text x="252" y="22" className="b2t">draw a scribble</text>
        <Pad x={252} y={30} size={96} strokes={strokes} setStrokes={setStrokes} counts={counts} drag={drag} label="Scribble pad" />
        {scrib && <text x="300" y="148" textAnchor="middle" className={`b2t ${scrib[sBest]! >= thr ? "amber" : "pink"}`}>{scrib[sBest]! >= thr ? `says ${sBest} (${fx(scrib[sBest]!)})` : `not sure (${fx(scrib[sBest]!)})`}</text>}
        {base && <text x="252" y="176" className="b2t">dashed: T = 1</text>}
      </g>}
    </svg>
  );
  const ece = rel?.ece ?? 0;
  const Ts = Math.round(T * 100) / 100, thrS = Math.round(thr * 100) / 100;
  const saved = b2.shelf.T_digits?.value === Ts && b2.shelf.not_sure?.value === thrS;
  const onSave = () => {
    save("T_digits", Ts, "ai-notes", { note: fitted != null ? `fitted on 823 held-out digits: ${fx(fitted)}` : "the reader's temperature" });
    save("not_sure", thrS, "ai-notes", { note: `answers ${Math.round(cover * 100)}% of held-out digits, right on ${fx(accC * 100, 1)}% of those` });
    const sh = b2.shelf, num = (k: string) => (typeof sh[k]?.value === "number" ? (sh[k]!.value as number) : null);
    const alpha = num("alpha_digits"), C = num("C_digits"), acc = num("acc_digits");
    const loop = [...b2.notebook].reverse().find(e => e.id === "ai-loophole");
    note({ id: "ai-notes", track: "ai", title: "Reader field notes", project: "ai-notes", build: true,
      data: { T: Ts, notSure: thrS, ece: Math.round(ece * 1000) / 1000, coverage: Math.round(cover * 1000) / 1000, ...(alpha != null ? { alpha } : {}), ...(C != null ? { C } : {}) },
      lines: [
        acc != null ? `Version 1: right on ${fx(acc * 100, 1)}% of 1,797 held-out digits.` : "Version 1: the 64 → 16 → 10 reader, trained on 3,000 digits.",
        alpha != null ? `Scaling: held-out error falls like N^(−${fx(alpha)}) from 100 to 3,000 digits. Past that the line is a guess.` : "Scaling: not fitted yet (lesson 13's Use it).",
        C != null ? `Training compute: about ${sciText(...sci(C))} FLOPs (6 × parameters × digits × passes).` : "Training compute: not estimated yet (lesson 14's Use it).",
        `Calibration: ECE ${fx(base?.ece ?? 0, 3)} at T = 1, ${fx(ece, 3)} at T = ${fx(Ts)}${fitted != null ? ` (best fit on held-out digits: ${fx(fitted)})` : ""}.`,
        `Not sure below ${fx(thrS)}: it answers ${Math.round(cover * 100)}% of held-out digits and is right on ${fx(accC * 100, 1)}% of those.`,
        loop ? `Loophole: ${loop.lines[1] ?? loop.lines[0]}` : "Loophole: none kept yet (lesson 15's Use it).",
        "What the score misses: it was only ever tested on digits, so a scribble that isn't one can still get a confident answer.",
      ] });
  };
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Temperature T" value={T} min={0.5} max={3} step={0.05} onChange={setT} format={v => v.toFixed(2)} marks={[{ v: 1, label: "1" }, ...(fitted != null ? [{ v: fitted, label: `fit ${fx(fitted)}` }] : [])]} />
        <Slider label="Not sure below" value={thr} min={0.3} max={0.99} step={0.01} onChange={setThr} format={v => v.toFixed(2)} />
        {project && <Btns>
          {fitted != null && <Btn on={Math.abs(T - fitted) > 0.004} onClick={() => setT(fitted)}>Fit T on held-out digits</Btn>}
          <Btn onClick={() => setStrokes([])}>Clear the pad</Btn>
        </Btns>}
      </>}
      readouts={quiet || !net ? <Read label="Held-out digits" value="1,797" /> : <>
        <Read label="ECE" value={fx(ece, 3)} tone="sky" big />
        <Read label="Top bin (0.9 and up)" value={focus ? `${topRight.toLocaleString("en-US")} of ${top.length.toLocaleString("en-US")} right` : `${top.length.toLocaleString("en-US")} digits`} tone={focus ? "amber" : undefined} />
        <Read label="Answers" value={`${Math.round(cover * 100)}%`} />
        <Read label="Right when it answers" value={`${fx(accC * 100, 1)}%`} tone="amber" />
      </>}
      foot={project && net ? <SaveRow what={<>Keep <b>T_digits = {fx(Ts)}</b> and <b>not_sure = {fx(thrS)}</b>, and write the Reader field notes</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
