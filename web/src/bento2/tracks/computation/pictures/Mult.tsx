// The machine room (computation.md, cs-15 and the build): adder4 next to an 8-bit register [A | Q] with a carry C.
// A starts at 0, Q holds the multiplier, M the multiplicand. Each of four rounds: if Q's last bit is 1, adder4 adds M
// into A (keeping its carry out), then [C | A | Q] shifts right one place. Step or run it; after round 4, [A | Q] is the
// product. In the build it saves mult4: the answer, the adds, the steps and the gates.
// Quiet (a Guess before Lock in): the register sits at its start and nothing is counted.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { Read, SaveRow, Scene, Slider, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { bin } from "../maths";

const W = 360;
const STILL = 1e9;
type Phase = { A: number; Q: number; C: number; round: number; kind: "start" | "add" | "skip" | "shift"; sum?: number; before?: number };
export function phases(a: number, b: number): Phase[] {
  let A = 0, Q = b, C = 0;
  const out: Phase[] = [{ A, Q, C, round: 0, kind: "start" }];
  for (let r = 1; r <= 4; r++) {
    if (Q & 1) { const before = A, sum = A + a; C = sum >> 4; A = sum & 15; out.push({ A, Q, C, round: r, kind: "add", sum, before }); }
    else out.push({ A, Q, C, round: r, kind: "skip" });
    Q = (Q >> 1) | ((A & 1) << 3); A = (A >> 1) | (C << 3); C = 0;
    out.push({ A, Q, C, round: r, kind: "shift" });
  }
  return out;
}

export function MultScene({ props, place }: SceneProps) {
  const quiet = flag(props, "quiet");
  const [a, setA] = useState(Math.round(num(props, "a", 13)) & 15);
  const [b, setB] = useState(Math.round(num(props, "b", 6)) & 15);
  const [k, setK] = useState(0);
  const [running, setRunning] = useState(flag(props, "run") ? 1 : 0);
  const ph = useMemo(() => phases(a, b), [a, b]);
  const clock = Math.max(0, useClock(running > 0 && !quiet, STILL + running));
  const at = quiet ? 0 : running > 0 ? (clock >= STILL ? 8 : Math.min(8, k + Math.floor(clock / 0.9))) : k;
  const p = ph[at]!, done = at === 8;
  const adds = ph.slice(1, at + 1).filter(x => x.kind === "add").length, steps = ph.slice(1, at + 1).filter(x => x.kind !== "skip").length;
  const totalAdds = ph.filter(x => x.kind === "add").length, product = (ph[8]!.A << 4) | ph[8]!.Q;
  const { b2, save, note } = useB2();
  const reset = () => { setK(0); setRunning(0); };
  const cells = [`${p.C}`, ...bin(p.A, 4), ...bin(p.Q, 4)];
  const cx = (i: number) => 45 + i * 30 + (i > 0 ? 6 : 0) + (i > 4 ? 6 : 0);
  const adding = p.kind === "add";
  const svg = (
    <svg viewBox={`0 0 ${W} 250`} className="b2pic" role="img" aria-label={`${a} × ${b} by shift and add.${quiet ? "" : ` Round ${p.round}; the register reads ${bin(p.A, 4)} ${bin(p.Q, 4)}.`}`}>
      <text x="12" y="20" className="b2t">M = {a}</text>
      {[...bin(a, 4)].map((c, i) => <g key={i}><rect x={12 + i * 22} y="28" width="20" height="24" rx="4" className={`b2bar ${c === "1" ? "sky" : "track"}`} /><text x={22 + i * 22} y="45" textAnchor="middle" className="b2t">{c}</text></g>)}
      <rect x="140" y="20" width="110" height="40" rx="8" className={`b2bar ${adding && !quiet ? "amber" : "track"}`} opacity={adding && !quiet ? 0.35 : 1} />
      <rect x="140" y="20" width="110" height="40" rx="8" className="b2ring" />
      <text x="195" y="45" textAnchor="middle" className="b2t">adder4</text>
      {adding && !quiet && <text x="262" y="45" className="b2t amber">{p.before} + {a} = {p.sum}</text>}
      <path d="M100,40 H140" className={`b2curve ${adding && !quiet ? "amber" : ""}`} strokeWidth="1.5" />
      <path d={`M${cx(2) + 15},92 V60`} className={`b2curve ${adding && !quiet ? "amber" : ""}`} strokeWidth="1.5" />
      <text x={cx(0) + 13} y="84" textAnchor="middle" className="b2t">C</text>
      <text x={(cx(1) + cx(4) + 28) / 2} y="84" textAnchor="middle" className="b2t">A</text>
      <text x={(cx(5) + cx(8) + 28) / 2} y="84" textAnchor="middle" className="b2t">Q</text>
      {cells.map((c, i) => (
        <g key={i}>
          <rect x={cx(i)} y="92" width="26" height="30" rx="5" className={`b2bar ${c === "1" ? (i >= 5 && !quiet && at > 0 ? "amber" : "sky") : "track"}`} opacity={i === 0 && c === "0" ? 0.5 : 1} />
          <text x={cx(i) + 13} y="112" textAnchor="middle" className="b2t">{c}</text>
        </g>
      ))}
      <rect x={cx(8) - 2} y="90" width="30" height="34" rx="6" className="b2curve trav" fill="none" strokeWidth="2" />
      <text x={cx(8) + 13} y="138" textAnchor="middle" className="b2t trav">Q₀</text>
      {!quiet && ph.slice(1, at + 1).filter(x => x.kind !== "shift").map((x, i) => (
        <text key={i} x="12" y={162 + i * 18} className="b2t">round {x.round}: Q₀ = {x.kind === "add" ? 1 : 0}, {x.kind === "add" ? `add: ${x.before} + ${a} = ${x.sum}${x.sum! >= 16 ? " (carry 1)" : ""}` : "no add"}, then shift</text>
      ))}
      {quiet && <text x="12" y="166" className="b2t">four rounds: add M if Q₀ is 1, then shift [C | A | Q] right</text>}
    </svg>
  );
  const val = [a, b, product, totalAdds, totalAdds + 4, 20];
  const saved = JSON.stringify(b2.shelf.mult4?.value) === JSON.stringify(val);
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <>
        <Slider label="M, multiplicand" value={a} min={0} max={15} step={1} onChange={v => { setA(v); reset(); }} />
        <Slider label="Q, multiplier" value={b} min={0} max={15} step={1} onChange={v => { setB(v); reset(); }} />
        <button type="button" className="ctl" disabled={done} onClick={() => { setRunning(0); setK(at + 1); }}>Step</button>
        <button type="button" className="ctl go" disabled={done} onClick={() => { setK(at); setRunning(r => r + 1); }}>Run</button>
        <button type="button" className="ctl" onClick={reset}>Reset</button>
      </>}
      readouts={quiet ? <><Read label="M" value={`${bin(a, 4)} = ${a}`} /><Read label="Q" value={`${bin(b, 4)} = ${b}`} /></> : <>
        <Read label="Round" value={`${p.round} of 4`} />
        <Read label="Adds" value={adds} tone="amber" />
        <Read label="Steps (adds and shifts)" value={steps} />
        <Read label={done ? "Product [A | Q]" : "[A | Q] so far"} value={`${bin(p.A, 4)} ${bin(p.Q, 4)}${done ? ` = ${product}` : ""}`} tone="amber" big />
        <Read label="Gates" value="adder4: 20" />
      </>}
      foot={place === "project" && done && <SaveRow what={<>Keep <b>mult4</b>: {a} × {b} = {product}, {totalAdds} {totalAdds === 1 ? "add" : "adds"}</>} saved={saved} onSave={() => {
        save("mult4", val, "cs-room", { labels: ["M", "Q", "product", "adds", "steps", "gates"], note: "your chip multiplying by shift and add" });
        note({ id: "cs-room", track: "cs", title: "The machine room", project: "cs-room", build: true, data: { a, b, product, adds: totalAdds, steps: totalAdds + 4, gates: 20 },
          lines: [`${a} × ${b} = ${product}: [A | Q] = ${bin(product >> 4, 4)} ${bin(product & 15, 4)}.`, `adder4 ran ${totalAdds} ${totalAdds === 1 ? "time" : "times"}, once per 1 in ${bin(b, 4)}; ${totalAdds + 4} steps with the 4 shifts.`, "20 gates of adder, driven by a 4-round program."] });
      }} />}
    />
  );
}
