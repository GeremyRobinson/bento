// The Logic gate board (computation.md, cs-04, cs-05, cs-15), in four modes:
// free: one gate of your choice between two switches and a light, its truth table beside it (cs-04's Play).
// circuit: a circuit of gates, laid out by depth, with switches for its inputs; 1s glow along the wires.
// nand: a gate built from NANDs alone (NOT 1, AND 2, OR 3, XOR 4), checked against the real gate on every row.
// adder: four full adders chained into a 4-bit ripple-carry adder; the carry ripples right to left, one column at a time.
// Quiet (a Guess before Lock in): nand shows only the gate to build; adder shows only the inputs.
import { useMemo, useState, type ReactNode } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { Read, SaveRow, Scene, Toggle, useClock } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { bin, carries, runCircuit, type Gate, type GateOp } from "../maths";

const W = 360;

/** a gate's symbol centred on (x, y): inputs come in at x − 22, the output leaves at x + 22 */
export function GateShape({ x, y, op, on, dim }: { x: number; y: number; op: GateOp | "?"; on: boolean; dim?: boolean }) {
  const and = `M${x - 18},${y - 14} H${x - 2} A14,14 0 0 1 ${x - 2},${y + 14} H${x - 18} Z`;
  const or = `M${x - 20},${y - 14} Q${x - 10},${y} ${x - 20},${y + 14} Q${x + 4},${y + 14} ${x + 16},${y} Q${x + 4},${y - 14} ${x - 20},${y - 14} Z`;
  const d = op === "AND" || op === "NAND" ? and : op === "OR" || op === "XOR" ? or : op === "NOT" ? `M${x - 16},${y - 12} L${x + 8},${y} L${x - 16},${y + 12} Z` : `M${x - 18},${y - 14} H${x + 14} V${y + 14} H${x - 18} Z`;
  const tone = on ? "amber" : "";
  return (
    <g opacity={dim ? 0.45 : 1}>
      <path d={d} className={`b2bar ${on ? "amber" : "track"}`} opacity={on ? 0.35 : 1} />
      <path d={d} className={`b2curve ${tone}`} strokeWidth="1.8" />
      {op === "XOR" && <path d={`M${x - 25},${y - 14} Q${x - 15},${y} ${x - 25},${y + 14}`} className={`b2curve ${tone}`} strokeWidth="1.8" />}
      {(op === "NAND" || op === "NOT") && <circle cx={op === "NOT" ? x + 12 : x + 16} cy={y} r="3.5" className={`b2curve ${tone}`} strokeWidth="1.8" fill="none" />}
      {op === "?" && <text x={x - 2} y={y + 5} textAnchor="middle" className="b2t">?</text>}
      <text x={x - 2} y={y + 30} textAnchor="middle" className="b2t">{op === "?" ? "" : op}</text>
    </g>
  );
}
const Wire = ({ d, on }: { d: string; on: boolean }) => <path d={d} className={`b2curve ${on ? "amber" : ""}`} strokeWidth={on ? 3 : 1.5} opacity={on ? 1 : 0.45} />;

/** draws a circuit: switches on the left, gates in columns by depth, the light on the right */
function Board({ gates, ins, env, onFlip, H = 230, hideOut, label }: { gates: Gate[]; ins: string[]; env: Record<string, number>; onFlip?: (v: string) => void; H?: number; hideOut?: boolean; label?: ReactNode }) {
  const vals = runCircuit(gates, env);
  const depth: number[] = [];
  gates.forEach((g, k) => { const d = (s: string | number | undefined) => (typeof s === "number" ? depth[s]! : 0); depth[k] = 1 + Math.max(d(g.a), d(g.b)); });
  const D = Math.max(1, ...depth), colX = (d: number) => 36 + d * ((W - 100) / D);
  const byCol = (d: number) => gates.map((_, k) => k).filter(k => depth[k] === d);
  const spread = (i: number, m: number) => 24 + ((i + 1) * (H - 60)) / (m + 1);
  const pos: Record<string, [number, number]> = {};
  ins.forEach((v, i) => { pos[v] = [colX(0), spread(i, ins.length)]; });
  for (let d = 1; d <= D; d++) byCol(d).forEach((k, i, all) => { pos[k] = [colX(d), spread(i, all.length)]; });
  const outOf = (s: string | number) => { const [x, y] = pos[String(s)]!; return typeof s === "number" ? [x + 22, y] : [x + 14, y]; };
  const valOf = (s: string | number) => (typeof s === "number" ? vals[s]! : env[s]!);
  const last = gates.length - 1, [lx, ly] = outOf(last) as [number, number];
  return (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A circuit of ${gates.length} gates; the output is ${hideOut ? "hidden" : vals[last]}.`}>
      {gates.map((g, k) => {
        const [gx, gy] = pos[k]!, srcs = g.b == null ? [g.a] : [g.a, g.b];
        return srcs.map((s, j) => {
          const [sx, sy] = outOf(s), py = g.b == null ? gy : gy + (j ? 8 : -8), mid = gx - 25 - j * 3;
          return <Wire key={`${k}-${j}`} d={`M${sx},${sy} H${mid} V${py} H${gx - 20}`} on={!hideOut && valOf(s) === 1} />;
        });
      })}
      <Wire d={`M${lx},${ly} H${W - 34}`} on={!hideOut && vals[last] === 1} />
      {ins.map(v => {
        const [x, y] = pos[v]!;
        return (
          <g key={v} onClick={() => onFlip?.(v)} style={{ cursor: onFlip ? "pointer" : undefined }}>
            <rect x={x - 16} y={y - 13} width="30" height="26" rx="13" className={`b2bar ${env[v] ? "amber" : "track"}`} />
            <text x={x - 1} y={y + 5} textAnchor="middle" className="b2t">{env[v]}</text>
            <text x={x - 1} y={y - 18} textAnchor="middle" className="b2t">{v}</text>
            {onFlip && <rect x={x - 20} y={y - 20} width="38" height="40" className="b2hit" style={{ cursor: "pointer" }} />}
          </g>
        );
      })}
      {gates.map((g, k) => <GateShape key={k} x={pos[k]![0]} y={pos[k]![1]} op={g.op} on={!hideOut && vals[k] === 1} />)}
      <circle cx={W - 22} cy={ly} r="12" className={`b2bar ${hideOut ? "unknown" : vals[last] ? "amber" : "track"}`} />
      <text x={W - 22} y={ly + 5} textAnchor="middle" className="b2t">{hideOut ? "?" : vals[last]}</text>
      {label}
    </svg>
  );
}

export function GatesScene(props: SceneProps) {
  const first = str<string>(props.props, "mode", "free");
  const [mode, setMode] = useState(first);
  const pick = props.place === "tool" && (
    <Toggle label="Board" value={mode} onChange={setMode} options={[{ v: "free", label: "One gate" }, { v: "nand", label: "From NANDs" }, { v: "adder", label: "4-bit adder" }]} />
  );
  if (mode === "circuit") return <CircuitBoard {...props} />;
  if (mode === "nand") return <Nand {...props} pick={pick} />;
  if (mode === "adder") return <Adder {...props} pick={pick} />;
  return <Free {...props} pick={pick} />;
}

const OPS: GateOp[] = ["AND", "OR", "XOR", "NAND", "NOT"];
function Free({ props, pick }: SceneProps & { pick: ReactNode }) {
  const [op, setOp] = useState<GateOp>(str<GateOp>(props, "gate", "AND"));
  const [env, setEnv] = useState<Record<string, number>>({ a: 1, b: 0 });
  const gates: Gate[] = op === "NOT" ? [{ op, a: "a" }] : [{ op, a: "a", b: "b" }];
  const f = (a: number, b: number) => runCircuit(gates, { a, b })[0]!;
  const rowsAB = op === "NOT" ? [[0, 0], [1, 0]] : [[0, 0], [0, 1], [1, 0], [1, 1]];
  const table = (
    <g>
      <text x="236" y="168" className="b2t">{op === "NOT" ? "a → out" : "a b → out"}</text>
      {rowsAB.map(([a, b], i) => {
        const here = a === env.a && (op === "NOT" || b === env.b);
        return (
          <g key={i}>
            {here && <rect x="230" y={174 + i * 14} width="96" height="14" rx="3" className="b2mark sky" />}
            <text x="236" y={185 + i * 14} className="b2t">{op === "NOT" ? `${a}` : `${a} ${b}`}</text>
            <text x="300" y={185 + i * 14} className={`b2t ${f(a!, b!) ? "amber" : ""}`}>{f(a!, b!)}</text>
          </g>
        );
      })}
    </g>
  );
  return (
    <Scene svg={<Board gates={gates} ins={op === "NOT" ? ["a"] : ["a", "b"]} env={env} onFlip={v => setEnv(e => ({ ...e, [v]: 1 - e[v]! }))} H={240} label={table} />}
      controls={<>{pick}<Toggle label="Gate" value={op} onChange={setOp} options={OPS.map(o => ({ v: o, label: o }))} /></>}
      readouts={<>
        <Read label="Out" value={f(env.a!, env.b!)} tone="amber" big />
        <Read label="Gates" value={1} />
        <Read label="Lit on" value={`${rowsAB.filter(([a, b]) => f(a!, b!)).length} of ${rowsAB.length} rows`} />
      </>}
    />
  );
}

/** "XOR:x:y AND:0:x" → gates */
export const gatesFrom = (s: string): Gate[] => s.split(" ").filter(Boolean).map(t => {
  const [op, a, b] = t.split(":");
  const src = (x: string | undefined) => (x == null ? undefined : /^\d+$/.test(x) ? Number(x) : x);
  return { op: op as GateOp, a: src(a)!, ...(b != null ? { b: src(b) } : {}) };
});
function CircuitBoard({ props }: SceneProps) {
  const gates = useMemo(() => gatesFrom(str<string>(props, "c", "XOR:x:y AND:0:x")), [props]);
  const ins = ["x", "y", "z"].filter(v => gates.some(g => g.a === v || g.b === v));
  const start = str<string>(props, "env", "");
  const [env, setEnv] = useState<Record<string, number>>(() => Object.fromEntries(ins.map((v, i) => [v, Number(start[i] ?? 0)])));
  const out = runCircuit(gates, env).at(-1)!, quiet = flag(props, "quiet");
  return (
    <Scene svg={<Board gates={gates} ins={ins} env={env} onFlip={v => setEnv(e => ({ ...e, [v]: 1 - e[v]! }))} H={Math.max(200, 70 * ins.length)} hideOut={quiet} />}
      readouts={<>
        <Read label="Inputs" value={ins.map(v => `${v} = ${env[v]}`).join(", ")} />
        {!quiet && <Read label="Out" value={out} tone="amber" big />}
        <Read label="Gates" value={gates.length} />
      </>}
    />
  );
}

const NAND_BUILDS: Record<string, Gate[]> = {
  NOT: [{ op: "NAND", a: "a", b: "a" }],
  AND: [{ op: "NAND", a: "a", b: "b" }, { op: "NAND", a: 0, b: 0 }],
  OR: [{ op: "NAND", a: "a", b: "a" }, { op: "NAND", a: "b", b: "b" }, { op: "NAND", a: 0, b: 1 }],
  XOR: [{ op: "NAND", a: "a", b: "b" }, { op: "NAND", a: "a", b: 0 }, { op: "NAND", a: "b", b: 0 }, { op: "NAND", a: 1, b: 2 }],
};
function Nand({ props, pick }: SceneProps & { pick: ReactNode }) {
  const quiet = flag(props, "quiet");
  const [target, setTarget] = useState(str<string>(props, "gate", "AND"));
  const [env, setEnv] = useState<Record<string, number>>({ a: 1, b: 1 });
  const build = NAND_BUILDS[target]!, ins = target === "NOT" ? ["a"] : ["a", "b"];
  const real = (a: number, b: number) => runCircuit([target === "NOT" ? { op: "NOT", a: "a" } : { op: target as GateOp, a: "a", b: "b" }], { a, b })[0]!;
  const made = (a: number, b: number) => runCircuit(build, { a, b }).at(-1)!;
  const settings = target === "NOT" ? [[0, 0], [1, 0]] : [[0, 0], [0, 1], [1, 0], [1, 1]];
  const agree = settings.filter(([a, b]) => real(a!, b!) === made(a!, b!)).length;
  const svg = quiet ? (
    <svg viewBox={`0 0 ${W} 200`} className="b2pic" role="img" aria-label={`Build ${target} from NAND gates.`}>
      <text x="20" y="30" className="b2t">build this</text>
      <GateShape x={90} y={100} op={target as GateOp} on={false} />
      <text x="170" y="105" className="b2t">from</text>
      <GateShape x={260} y={100} op="NAND" on={false} />
      <text x="292" y="105" className="b2t">× ?</text>
    </svg>
  ) : <Board gates={build} ins={ins} env={env} onFlip={v => setEnv(e => ({ ...e, [v]: 1 - e[v]! }))} H={target === "XOR" ? 240 : 210} />;
  return (
    <Scene svg={svg}
      controls={quiet ? undefined : <>{pick}
        <Toggle label="Build" value={target} onChange={setTarget} options={["NOT", "AND", "OR", "XOR"].map(o => ({ v: o, label: o }))} /></>}
      readouts={quiet ? <Read label="Build" value={`${target} from NANDs`} /> : <>
        <Read label="NANDs" value={build.length} tone="amber" big />
        <Read label={`Matches ${target}`} value={`on ${agree} of ${settings.length} rows`} tone="sky" />
        <Read label="Out" value={made(env.a!, env.b!)} />
      </>}
    />
  );
}

function Adder({ props, place, pick }: SceneProps & { pick: ReactNode }) {
  const quiet = flag(props, "quiet");
  const [a, setA] = useState(Math.round(num(props, "a", 11)) & 15);
  const [b, setB] = useState(Math.round(num(props, "b", 6)) & 15);
  const t = Math.max(0, useClock(!quiet, STILL));
  const [t0, setT0] = useState(0);
  const step = quiet ? -1 : t >= STILL ? 4 : Math.min(4, Math.floor(Math.max(0, t - t0) / 0.6));
  const cs = carries(a, b), sum = a + b;
  const { b2, save, note } = useB2();
  const restart = () => setT0(t);
  const flipA = (k: number) => { setA(x => x ^ (1 << k)); restart(); };
  const flipB = (k: number) => { setB(x => x ^ (1 << k)); restart(); };
  const colX = (k: number) => W - 64 - k * 76; // column k from the right
  const svg = (
    <svg viewBox={`0 0 ${W} 250`} className="b2pic" role="img" aria-label={`${bin(a, 4)} + ${bin(b, 4)}${quiet ? "" : ` = ${bin(sum, 5)}, ${sum}`}.`}>
      {[0, 1, 2, 3].map(k => {
        const x = colX(k), ab = (a >> k) & 1, bb = (b >> k) & 1, cin = k ? cs[k - 1]! : 0, done = step >= k + 1, lit = !quiet && done;
        const s = ab ^ bb ^ cin;
        return (
          <g key={k}>
            <text x={x} y="14" textAnchor="middle" className="b2t">column {k + 1}</text>
            {[["a", ab, 24, () => flipA(k)], ["b", bb, 58, () => flipB(k)]].map(([nm, v, y, on]) => (
              <g key={nm as string} onClick={on as () => void} style={{ cursor: "pointer" }}>
                <rect x={x - 26} y={y as number} width="24" height="26" rx="6" className={`b2bar ${v ? "amber" : "track"}`} />
                <text x={x - 14} y={(y as number) + 18} textAnchor="middle" className="b2t">{v as number}</text>
                <rect x={x - 30} y={(y as number) - 2} width="32" height="30" className="b2hit" style={{ cursor: "pointer" }} />
              </g>
            ))}
            <path d={`M${x - 14},50 V102 M${x - 14},84 V102`} className={`b2curve ${ab || bb ? "amber" : ""}`} strokeWidth="1.5" opacity="0.6" />
            <rect x={x - 32} y="102" width="64" height="48" rx="8" className={`b2bar ${lit ? "sky" : "track"}`} opacity={lit ? 0.3 : 1} />
            <rect x={x - 32} y="102" width="64" height="48" rx="8" className="b2ring" />
            <text x={x} y="123" textAnchor="middle" className="b2t">full</text>
            <text x={x} y="140" textAnchor="middle" className="b2t">adder</text>
            {/* carry out of this column, into the next one on the left */}
            <path d={`M${x - 32},126 H${x - 44}`} className={`b2curve ${lit && cs[k] ? "amber" : ""}`} strokeWidth={lit && cs[k] ? 3 : 1.5} />
            {!quiet && <text x={x - 38} y="118" textAnchor="middle" className={`b2t ${lit && cs[k] ? "amber" : ""}`}>{lit ? cs[k] : ""}</text>}
            <path d={`M${x},150 V176`} className={`b2curve ${lit && s ? "amber" : ""}`} strokeWidth="1.5" />
            <rect x={x - 13} y="176" width="26" height="28" rx="6" className={`b2bar ${quiet || !lit ? "unknown" : s ? "amber" : "track"}`} />
            <text x={x} y="195" textAnchor="middle" className="b2t">{quiet || !lit ? "?" : s}</text>
          </g>
        );
      })}
      <text x="4" y="40" className="b2t">a</text>
      <text x="4" y="74" className="b2t">b</text>
      <circle cx="20" cy="126" r="11" className={`b2bar ${quiet || step < 4 ? "unknown" : cs[3] ? "amber" : "track"}`} />
      <text x="20" y="131" textAnchor="middle" className="b2t">{quiet || step < 4 ? "?" : cs[3]}</text>
      <text x="20" y="160" textAnchor="middle" className="b2t">carry</text>
      <text x="20" y="174" textAnchor="middle" className="b2t">out</text>
      <text x="4" y="196" className="b2t">sum</text>
      {!quiet && step >= 4 && <text x={W - 8} y="232" textAnchor="end" className="b2t amber">{bin(a, 4)} + {bin(b, 4)} = {bin(sum, 5)} = {sum}</text>}
    </svg>
  );
  const saved = JSON.stringify(b2.shelf.adder4?.value) === JSON.stringify([a, b, sum, 20]);
  return (
    <Scene svg={svg}
      controls={<>{pick}{!quiet && <button type="button" className="ctl" onClick={restart}>Ripple again</button>}</>}
      readouts={quiet ? <><Read label="a" value={`${bin(a, 4)} = ${a}`} /><Read label="b" value={`${bin(b, 4)} = ${b}`} /></> : <>
        <Read label="a + b" value={`${a} + ${b} = ${sum}`} tone="amber" big />
        <Read label="Carries, right to left" value={cs.join(" ")} />
        <Read label="Gates" value="4 full adders × 5 = 20" />
      </>}
      foot={place === "project" && !quiet && <SaveRow what={<>Keep <b>adder4</b>: {a} + {b} = {sum}, 20 gates</>} saved={saved} onSave={() => {
        save("adder4", [a, b, sum, 20], "cs-adder", { labels: ["a", "b", "a + b", "gates"], note: "your 4-bit ripple-carry adder: 4 full adders, 20 gates" });
        note({ id: "cs-adder", track: "cs", title: "Your adder chip", project: "cs-adder", data: { a, b, sum, gates: 20 },
          lines: [`${bin(a, 4)} + ${bin(b, 4)} = ${bin(sum, 5)} (${a} + ${b} = ${sum}).`, `Carries, right to left: ${cs.join(" ")}.`, "4 full adders, 20 gates: 8 XOR, 8 AND, 4 OR."] });
      }} />}
    />
  );
}
/** with Less motion the clock holds this still value, so the ripple shows finished */
const STILL = 1e9;
