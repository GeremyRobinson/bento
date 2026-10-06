// The Machine builder (computation.md, cs-13): a tape of cells, a head with its state, and a rule table. Step or run it:
// each step reads, writes, moves and changes state, with a step counter and a halt light. Tap a cell to change the
// input (the machine starts over); a tap on the blank past the end adds a cell. Machines: add 1, flip every bit, and a unary adder.
// Quiet (a Guess before Lock in): the machine stands at its start and no counter shows.
import { useMemo, useState } from "react";
import { flag, str, type SceneProps } from "../../../scenes";
import { Read, Scene, Toggle, useClock } from "../../../ui/kit";
import { ruleText, runMachine } from "../maths";
import { MACHINES } from "../lessons3";

const W = 360;
const STILL = 1e9;
const CELL = 30;

export function MachineScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet");
  const [m, setM] = useState(str<string>(props, "m", "add1"));
  const [input, setInput] = useState(str<string>(props, "input", "1011"));
  const [k, setK] = useState(0);
  const [running, setRunning] = useState(flag(props, "run") ? 1 : 0);
  const M = MACHINES[m]!;
  const res = useMemo(() => runMachine(M, input || "0"), [M, input]);
  const clock = Math.max(0, useClock(running > 0 && !quiet, STILL + running));
  const at = quiet ? 0 : running > 0 ? (clock >= STILL ? res.steps : Math.min(res.steps, k + Math.floor(clock / 0.7))) : k;
  const conf = res.trace[at]!, halted = conf.q === "halt";
  const next = halted ? -1 : M.rules.findIndex(r => r.q === conf.q && r.read === (conf.tape[conf.head] ?? "_"));
  const restart = (s: string) => { setInput(s); setK(0); setRunning(0); };
  const tapCell = (i: number) => {
    if (quiet) return;
    // edits go to the input, so the machine starts over from its first step
    if (at !== 0 || i < 0 || i > input.length) { restart(input); return; }
    if (i === input.length) { if (input.length < 12) restart(`${input}1`); return; }
    restart(`${input.slice(0, i)}${input[i] === "1" ? "0" : "1"}${input.slice(i + 1)}`);
  };
  // the window of cells: the tape with a blank on each side, centred on the head where it can be
  const cells = ["_", ...conf.tape, "_"], head = conf.head + 1;
  const first = Math.max(0, Math.min(head - 5, cells.length - 11)), view = cells.slice(first, first + 11);
  const x0 = (W - view.length * CELL) / 2;
  const svg = (
    <svg viewBox={`0 0 ${W} ${146 + M.rules.length * 19}`} className="b2pic" role="img" aria-label={`The ${M.name} machine on ${input}.${quiet ? "" : ` After ${at} steps the tape reads ${conf.tape.join("").replace(/_/g, "")}${halted ? " and it has halted" : ""}.`}`}>
      {view.map((c, i) => {
        const real = first + i - 1;
        return (
          <g key={i} onClick={() => tapCell(real)} style={{ cursor: quiet ? undefined : "pointer" }}>
            <rect x={x0 + i * CELL + 1} y="30" width={CELL - 2} height="38" rx="5" className={`b2bar ${c === "1" ? "amber" : c === "0" ? "track" : "unknown"}`} opacity={c === "_" ? 0.35 : 1} />
            <text x={x0 + i * CELL + CELL / 2} y="55" textAnchor="middle" className="b2t">{c === "_" ? "" : c}</text>
          </g>
        );
      })}
      {(() => {
        const hx = x0 + (head - first) * CELL + CELL / 2;
        return (
          <g>
            <path d={`M${hx},74 L${hx - 9},88 L${hx + 9},88 Z`} className={`b2bar ${halted && !quiet ? "sky" : "amber"}`} />
            <text x={hx} y="108" textAnchor="middle" className={`b2t ${halted && !quiet ? "sky" : "amber"}`}>{conf.q}</text>
          </g>
        );
      })()}
      <text x="12" y="18" className="b2t">{M.name}</text>
      <circle cx={W - 22} cy="14" r="9" className={`b2bar ${halted && !quiet ? "sky" : "track"}`} />
      <circle cx={W - 22} cy="14" r="9" className="b2ring" />
      <text x={W - 37} y="19" textAnchor="end" className={`b2t ${halted && !quiet ? "sky" : ""}`}>{halted && !quiet ? `halted: ${conf.tape.join("").replace(/_/g, "")}` : "halt"}</text>
      <text x="12" y="134" className="b2t">rules: (state, read) → (write, move, next)</text>
      {M.rules.map((r, i) => (
        <g key={i}>
          {!quiet && i === next && <rect x="8" y={140 + i * 19} width={W - 16} height="18" rx="4" className="b2bar amber" opacity="0.25" />}
          <text x="14" y={154 + i * 19} className={`b2t ${!quiet && i === next ? "amber" : ""}`}>{ruleText(r)}</text>
        </g>
      ))}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {!quiet && <Toggle label="Machine" value={m} onChange={v => { setM(v); restart(v === "unary" ? "111011" : v === "flip" ? "1011" : "1011"); }}
          options={[{ v: "add1", label: "Add 1" }, { v: "flip", label: "Flip" }, { v: "unary", label: "Unary adder" }]} />}
        {!quiet && <button type="button" className="ctl" disabled={halted} onClick={() => { setRunning(0); setK(at + 1); }}>Step</button>}
        {!quiet && <button type="button" className="ctl go" disabled={halted} onClick={() => { setK(at); setRunning(r => r + 1); }}>Run</button>}
        {!quiet && <button type="button" className="ctl" onClick={() => restart(input)}>Reset</button>}
      </>}
      readouts={quiet ? <Read label="Tape" value={input} /> : <>
        <Read label="Steps" value={at} tone="amber" big />
        <Read label="State" value={conf.q} />
        <Read label="Tape" value={conf.tape.join("").replace(/_/g, "") || "blank"} tone="sky" />
      </>}
    />
  );
}
