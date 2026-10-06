// The build: a two-qubit search (quantum.md, 12 and the track's build). The circuit H on both, oracle, H on both,
// flip all but 00, H on both, on the circuit board, stepped one gate at a time with the four amplitudes as signed bars
// (in units of 1/2). Tap a bar to hide the marked item there. In the build, each next state is typed by hand before
// the board shows it. Run sends 1,000 shots: every one lands on the marked item. Saves `grover` and the Notebook entry.
import { useEffect, useMemo, useState } from "react";
import { reduceMotion } from "../../../../app/transition";
import { flag, num, type SceneProps } from "../../../scenes";
import { Read, SaveRow, Scene, useTween } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { hh, LABELS2, shots, tally } from "../maths";
import { parseTyped } from "../../../steps";
import { shownOf, TONE2, useRun } from "./parts";

const W = 360, H = 260, N = 1000, ZERO = 164, AMP = 76;
const STAGES = ["start", "H on both", "oracle", "H on both", "flip all but 00", "H on both"];
const tuple2 = (v: number[]) => `(${v.map(x => (x < 0 ? `−${-x}` : String(x))).join(", ")})`;

export function statesFor(m: number): number[][] {
  const s0 = [2, 0, 0, 0], s1 = hh(s0), s2 = s1.map((x, i) => (i === m ? -x : x)), s3 = hh(s2), s4 = s3.map((x, i) => (i ? -x : x)), s5 = hh(s4);
  return [s0, s1, s2, s3, s4, s5].map(v => v.map(x => (Object.is(x, -0) ? 0 : x)));
}

export function SearchScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), project = flag(props, "project"), auto = flag(props, "run");
  const hand = project || flag(props, "hand");
  const [m, setM] = useState(num(props, "m", 2));
  const [stage, setStage] = useState(0);
  const [typed, setTyped] = useState(["", "", "", ""]);
  const [msg, setMsg] = useState("");
  const run = useRun(4);
  const { b2, save, note } = useB2();
  const S = useMemo(() => statesFor(m), [m]);
  useEffect(() => {
    if (!auto) return;
    if (reduceMotion()) { setStage(5); run.run(); return; }
    const ts = [1, 2, 3, 4, 5].map(s => setTimeout(() => setStage(s), 200 + s * 800));
    const t = setTimeout(run.run, 200 + 6 * 800);
    return () => { ts.forEach(clearTimeout); clearTimeout(t); };
  }, [auto]); // eslint-disable-line react-hooks/exhaustive-deps
  const outs = useMemo(() => shots(S[5]!.map(x => (x / 2) ** 2), N, 700 + run.runs), [S, run.runs]);
  const shown = run.runs ? shownOf(run.k, N) : 0;
  const counts = tally(outs, 4, shown);
  const pick = (i: number) => { if (!quiet) { setM(i); setStage(0); setTyped(["", "", "", ""]); setMsg(""); } };
  const check = () => {
    const want = S[stage + 1]!, got = typed.map(t => parseTyped(t));
    if (got.some(g => g == null)) { setMsg("Fill in all four boxes, in units of 1/2."); return; }
    if (got.every((g, i) => Math.abs(g! - want[i]!) < 1e-9)) { setStage(s => s + 1); setTyped(["", "", "", ""]); setMsg(""); return; }
    if (got.every((g, i) => Math.abs(g! - want[i]! / 2) < 1e-9)) { setMsg("Boxes are in units of 1/2: an amplitude of 1/2 is typed as 1."); return; }
    setMsg(stage === 1 ? `The oracle flips the sign of ${LABELS2[m]} only.` : stage === 3 ? "Keep 00 and flip the other three." : "H on both: out(y) = ½ Σ (−1)^(x·y) a(x).");
  };
  const gx = [64, 112, 160, 208, 256];
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic search" role="img"
      aria-label={`Grover's search on two qubits, marked item ${LABELS2[m]}, at the ${STAGES[stage]} stage.${quiet && !auto ? "" : ` Amplitudes ${tuple2(S[stage]!)} in units of 1/2.`}`}>
      <line x1="20" y1="26" x2="300" y2="26" className="b2axis" />
      <line x1="20" y1="62" x2="300" y2="62" className="b2axis" />
      {[["H", 0, false], ["oracle", 1, true], ["H", 2, false], ["flip", 3, true], ["H", 4, false]].map(([label, i, both]) => {
        const x = gx[i as number]!, lit = (i as number) + 1 === stage;
        return (
          <g key={i as number} opacity={(i as number) + 1 <= stage ? 1 : 0.4}>
            {both ? <rect x={x - 20} y="12" width="40" height="64" rx="8" className="b2bar track" />
              : <><rect x={x - 15} y="12" width="30" height="28" rx="7" className="b2bar track" /><rect x={x - 15} y="48" width="30" height="28" rx="7" className="b2bar track" /></>}
            {both ? <text x={x} y="49" textAnchor="middle" className={`b2t${label === "oracle" ? " pink" : ""}`}>{label === "oracle" ? "O" : "F"}</text>
              : <><text x={x} y="31" textAnchor="middle" className="b2t">H</text><text x={x} y="67" textAnchor="middle" className="b2t">H</text></>}
            {lit && <rect x={x - 22} y="9" width="44" height="70" rx="9" className="b2mark amber" />}
          </g>
        );
      })}
      <text x="312" y="31" className="b2t">top</text>
      <text x="312" y="67" className="b2t">bottom</text>
      <line x1="20" y1={ZERO} x2="340" y2={ZERO} className="b2axis" />
      {S[stage]!.map((v, i) => <Amp key={i} i={i} v={v} marked={i === m} hide={quiet && stage > 0 && !auto} onPick={() => pick(i)} count={run.runs ? counts[i]! / N : null} />)}
    </svg>
  );
  const done = stage === 5;
  const final = S[5]!.map(x => x / 2);
  const saved = JSON.stringify(b2.shelf.grover?.value) === JSON.stringify(final) && done;
  const onSave = () => {
    save("grover", final, "qu-search", { labels: LABELS2, note: `two-qubit search, marked ${LABELS2[m]}` });
    note({ id: "qu-search", track: "qu", title: "The build: two-qubit search", project: "qu-search", build: true, data: { m },
      lines: [`Marked item ${LABELS2[m]}. Every state in units of 1/2:`, ...S.slice(1).map((v, i) => `${STAGES[i + 1]}: ${tuple2(v)}`),
        `Chance of reading ${LABELS2[m]}: 1. ${run.done ? `1,000 shots: ${counts[m]} on ${LABELS2[m]}.` : "One question, where a classical search can need three."}`] });
  };
  const entry = hand && !done;
  return (
    <Scene svg={svg}
      controls={<>
        {entry ? <span className="b2ops" role="group" aria-label="Type the next state">
          <small>After {STAGES[stage + 1]}, in units of 1/2:</small>
          <span className="b2cells" style={{ display: "grid", gridTemplateColumns: "repeat(4, minmax(48px, 64px))", gap: "6px" }}>
            {typed.map((t, i) => <input key={i} inputMode="numeric" aria-label={`Amplitude of ${LABELS2[i]}`} placeholder={LABELS2[i]} value={t}
              onChange={e => { const v = e.currentTarget.value; setTyped(x => x.map((y, j) => (j === i ? v : y))); }} onKeyDown={e => { if (e.key === "Enter") check(); }} />)}
          </span>
          <button type="button" className="ctl go" onClick={check}>Check</button>
          <button type="button" className="ctl" onClick={() => { setStage(s => s + 1); setTyped(["", "", "", ""]); setMsg(""); }}>Show me</button>
        </span> : <span className="b2ops" role="group" aria-label="Step the circuit">
          <button type="button" className="ctl" disabled={stage === 0} onClick={() => setStage(s => s - 1)}>‹ Back a gate</button>
          <button type="button" className="ctl" disabled={done} onClick={() => setStage(s => s + 1)}>Next gate ›</button>
          {!quiet && <button type="button" className="ctl go" disabled={!done} onClick={run.run}>Run 1,000 shots</button>}
          {!quiet && <small>Tap a bar to hide the item there.</small>}
        </span>}
      </>}
      readouts={<>
        <Read label="Marked item" value={LABELS2[m]!} tone="pink" />
        <Read label="Now" value={`after ${STAGES[stage]}`} />
        {!(quiet && !auto) && <Read label="State, in units of 1/2" value={tuple2(S[stage]!)} tone="amber" />}
        {msg && <Read label="Not yet" value={msg} />}
        {shown > 0 && <Read label={`Shots on ${LABELS2[m]}`} value={`${counts[m]} of ${shown}`} tone="pink" big />}
      </>}
      foot={project ? <SaveRow what={done ? <>Keep <b>grover</b> and the circuit in your Notebook: the track's build</> : <>Type every state to finish the build</>} saved={saved} onSave={() => done && onSave()} /> : undefined}
    />
  );
}

/** one amplitude as a signed bar, eased to its new height; a tap moves the marked item here */
function Amp({ i, v, marked, hide, onPick, count }: { i: number; v: number; marked: boolean; hide: boolean; onPick: () => void; count: number | null }) {
  const h = useTween((v / 2) * AMP, 600), x = 40 + i * 78;
  return (
    <g onClick={onPick} style={{ cursor: "pointer" }} className={TONE2[i]}>
      <rect x={x - 6} y="84" width="62" height="160" rx="8" className="b2bar track" opacity="0.35" />
      {marked && <rect x={x - 6} y="84" width="62" height="160" rx="8" className="b2mark pink" strokeWidth="2.5" />}
      {!hide && <rect x={x + 6} y={h >= 0 ? ZERO - h : ZERO} width="38" height={Math.max(1, Math.abs(h))} rx="4" className="b2bar" />}
      {!hide && <text x={x + 25} y={h >= 0 ? ZERO + 18 : ZERO - 8} textAnchor="middle" className="b2t">{v < 0 ? `−${-v}` : v}</text>}
      {count != null && <rect x={x + 6} y={236 - count * 40} width="38" height={Math.max(1, count * 40)} rx="3" className="b2bar" opacity="0.6" />}
      <text x={x + 25} y="258" textAnchor="middle" className="b2t">{LABELS2[i]}</text>
    </g>
  );
}
