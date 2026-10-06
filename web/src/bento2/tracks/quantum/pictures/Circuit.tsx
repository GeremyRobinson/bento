// The circuit board, one qubit (quantum.md, 05): tap gates onto the line (X, Z, H, S), and under each one the state
// after it as two amplitudes with their chance bars. The gates multiply into one 2×2 matrix, shown beside, so HZH
// can be seen to come out as X. Quiet keeps the states after the start back (Work it's answers).
import { useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { Read, Scene } from "../../../ui/kit";
import { cAbs2, cMul, cAdd, type Cx } from "../maths";
import { ampC } from "./parts";
import { openTool } from "../../../ui/useB2";

type M = [[Cx, Cx], [Cx, Cx]];
const r = Math.SQRT1_2;
const GATES: Record<string, M> = {
  X: [[[0, 0], [1, 0]], [[1, 0], [0, 0]]],
  Z: [[[1, 0], [0, 0]], [[0, 0], [-1, 0]]],
  H: [[[r, 0], [r, 0]], [[r, 0], [-r, 0]]],
  S: [[[1, 0], [0, 0]], [[0, 0], [0, 1]]],
};
const I: M = [[[1, 0], [0, 0]], [[0, 0], [1, 0]]];
const apply = (m: M, v: [Cx, Cx]): [Cx, Cx] => [cAdd(cMul(m[0][0], v[0]), cMul(m[0][1], v[1])), cAdd(cMul(m[1][0], v[0]), cMul(m[1][1], v[1]))];
const mul = (a: M, b: M): M => [0, 1].map(i => [0, 1].map(j => cAdd(cMul(a[i]![0]!, b[0]![j]!), cMul(a[i]![1]!, b[1]![j]!)))) as M;
const same = (a: M, b: M) => a.every((row, i) => row.every((c, j) => Math.abs(c[0] - b[i]![j]![0]) < 1e-9 && Math.abs(c[1] - b[i]![j]![1]) < 1e-9));
const W = 360, H = 260, MAX = 5;

export function CircuitScene({ props }: SceneProps) {
  const [gates, setGates] = useState<string[]>(str(props, "gates", "").split("").filter(g => g in GATES));
  const quiet = flag(props, "quiet");
  const start: [Cx, Cx] = [[num(props, "a", 1), 0], [num(props, "b", 0), 0]];
  const states = gates.reduce<[Cx, Cx][]>((acc, g) => [...acc, apply(GATES[g]!, acc.at(-1)!)], [start]);
  const U = gates.reduce<M>((acc, g) => mul(GATES[g]!, acc), I);
  const named = Object.entries({ ...GATES, I }).find(([, m]) => same(U, m))?.[0];
  const minus = Object.entries({ ...GATES, I }).find(([, m]) => same(U, m.map(row => row.map(c => [-c[0], -c[1]])) as M))?.[0];
  const n = states.length, colW = Math.min(72, (W - 40) / Math.max(n, 3));
  const x0 = Math.max(24, (W - n * colW) / 2), colX = (i: number) => x0 + i * colW + colW / 2;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic circuit" role="img"
      aria-label={`One qubit through ${gates.length ? gates.join(", ") : "no gates"}.${quiet ? "" : ` It ends with P(0) = ${cAbs2(states.at(-1)![0]).toFixed(2)}.`}`}>
      <line x1="8" y1="40" x2={W - 8} y2="40" className="b2axis" />
      {gates.map((g, i) => (
        <g key={i}>
          <rect x={x0 + (i + 1) * colW - 17} y="23" width="34" height="34" rx="7" className="b2bar track" />
          <rect x={x0 + (i + 1) * colW - 17} y="23" width="34" height="34" rx="7" fill="none" className="b2tri" />
          <text x={x0 + (i + 1) * colW} y="45" textAnchor="middle" className="b2t">{g}</text>
        </g>
      ))}
      {states.map((s, i) => {
        const hide = quiet && i > 0, cxs = colX(i), p0 = cAbs2(s[0]), p1 = cAbs2(s[1]);
        return (
          <g key={i}>
            <line x1={cxs - colW / 2 + 4} y1="76" x2={cxs + colW / 2 - 4} y2="76" className="b2grid strong" />
            <text x={cxs} y="98" textAnchor="middle" className="b2t sky">{hide ? "?" : ampC(...s[0])}</text>
            <text x={cxs} y="122" textAnchor="middle" className="b2t pink">{hide ? "?" : ampC(...s[1])}</text>
            {/* the chances: P(0) up from the middle line, P(1) down */}
            <rect x={cxs - 9} y={140} width="18" height="100" rx="4" className="b2bar track" />
            {!hide && <>
              <rect x={cxs - 9} y={140} width="18" height={p0 * 100} rx="4" className="b2bar sky" />
              <rect x={cxs - 9} y={140 + p0 * 100} width="18" height={p1 * 100} rx="4" className="b2bar pink" />
            </>}
          </g>
        );
      })}
      <text x="8" y="98" className="b2t sky">0</text>
      <text x="8" y="122" className="b2t pink">1</text>
    </svg>
  );
  const fmt = (c: Cx) => ampC(...c);
  return (
    <Scene svg={svg}
      controls={<span className="b2ops" role="group" aria-label="Gates">
        {Object.keys(GATES).map(g => <button type="button" key={g} className="ctl" disabled={gates.length >= MAX} onClick={() => setGates(x => [...x, g])}>{g}</button>)}
        <button type="button" className="ctl" disabled={!gates.length} onClick={() => setGates(x => x.slice(0, -1))}>Undo</button>
        <button type="button" className="ctl" disabled={!gates.length} onClick={() => setGates([])}>Clear</button>
        <button type="button" className="ctl" onClick={() => openTool("matrix", { A: U.map(row => row.map(c => c[0])), label: "U" })} disabled={U.some(row => row.some(c => Math.abs(c[1]) > 1e-9))}>Matrix pad</button>
      </span>}
      readouts={<>
        {quiet ? <Read label="Gates" value={gates.length ? gates.join(", ") : "none"} /> : <Read label="All the gates as one matrix" value={<span className="b2grid2">{U.flat().map((c, i) => <span key={i}>{fmt(c)}</span>)}</span>} />}
        {!quiet && named && gates.length > 1 && <Read label="That's the same as" value={named === "I" ? "no gate at all" : named} tone="amber" />}
        {!quiet && !named && minus && gates.length > 1 && <Read label="That's the same as" value={`−${minus}, a phase off ${minus}`} tone="amber" />}
        {!quiet && <Read label="P(0) at the end" value={cAbs2(states.at(-1)![0]).toFixed(3)} tone="sky" />}
      </>}
    />
  );
}
