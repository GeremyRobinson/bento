// The Diagonal table (computation.md, cs-14): programs down the side, inputs across, each cell H (halts) or L (loops).
// The diagonal lights, and the trouble program's row below flips every diagonal cell. Tap a cell to flip it and both
// rebuild; tap a program's name to set it beside trouble and see the cell where they must clash.
// Quiet (a Guess before Lock in, or Work it's table): the trouble row stays hidden.
import { useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { Read, Scene } from "../../../ui/kit";

const W = 360;
const flip = (c: string) => (c === "H" ? "L" : "H");

export function DiagonalScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet");
  const [T, setT] = useState(() => str<string>(props, "T", "HLLH,HLHL,LLHH,HHLH").split(","));
  const [k, setK] = useState(Math.round(num(props, "k", 0)));
  const n = T.length, cell = Math.min(40, 190 / (n + 1)), x0 = 120, y0 = 30;
  const trouble = T.map((r, i) => flip(r[i]!));
  const tap = (i: number, j: number) => { if (quiet) return; setT(t => t.map((r, a) => (a === i ? `${r.slice(0, j)}${flip(r[j]!)}${r.slice(j + 1)}` : r))); };
  const ty = y0 + n * cell + 14;
  const svg = (
    <svg viewBox={`0 0 ${W} ${ty + cell + 34}`} className="b2pic" role="img" aria-label={`A table of ${n} programs on ${n} inputs.${quiet ? "" : ` The trouble row is ${trouble.join(" ")}.`}`}>
      {Array.from({ length: n }, (_, j) => <text key={j} x={x0 + j * cell + cell / 2} y={y0 - 8} textAnchor="middle" className="b2t">{j + 1}</text>)}
      <text x={x0 + n * cell + 8} y={y0 - 8} className="b2t">input</text>
      {T.map((r, i) => (
        <g key={i}>
          {k === i + 1 && !quiet && <rect x="8" y={y0 + i * cell + 1} width={x0 - 12 + n * cell} height={cell - 2} rx="6" className="b2bar sky" opacity="0.18" />}
          <text x={x0 - 10} y={y0 + i * cell + cell / 2 + 5} textAnchor="end" className={`b2t ${k === i + 1 && !quiet ? "sky" : ""}`} onClick={() => !quiet && setK(i + 1)} style={{ cursor: quiet ? undefined : "pointer" }}>program {i + 1}</text>
          {[...r].map((c, j) => (
            <g key={j} onClick={() => tap(i, j)} style={{ cursor: quiet ? undefined : "pointer" }}>
              <rect x={x0 + j * cell + 2} y={y0 + i * cell + 2} width={cell - 4} height={cell - 4} rx="5" className={`b2bar ${c === "H" ? "track" : "unknown"}`} />
              {i === j && <rect x={x0 + j * cell + 1} y={y0 + i * cell + 1} width={cell - 2} height={cell - 2} rx="6" className="b2curve amber" fill="none" strokeWidth="2.5" />}
              <text x={x0 + j * cell + cell / 2} y={y0 + i * cell + cell / 2 + 5} textAnchor="middle" className={`b2t ${i === j ? "amber" : ""}`}>{c}</text>
            </g>
          ))}
        </g>
      ))}
      <line x1="8" y1={ty - 7} x2={x0 + n * cell} y2={ty - 7} className="b2axis" />
      <text x={x0 - 10} y={ty + cell / 2 + 5} textAnchor="end" className="b2t amber">trouble</text>
      {trouble.map((c, j) => {
        const clash = !quiet && k === j + 1;
        return (
          <g key={j}>
            <rect x={x0 + j * cell + 2} y={ty + 2} width={cell - 4} height={cell - 4} rx="5" className={`b2bar ${quiet ? "unknown" : "amber"}`} opacity={quiet ? 0.5 : 0.35} />
            {clash && <rect x={x0 + j * cell - 1} y={ty - 1} width={cell + 2} height={cell + 2} rx="7" className="b2curve sky" fill="none" strokeWidth="2.5" />}
            <text x={x0 + j * cell + cell / 2} y={ty + cell / 2 + 5} textAnchor="middle" className="b2t">{quiet ? "?" : c}</text>
          </g>
        );
      })}
      {!quiet && k > 0 && <text x="8" y={ty + cell + 26} className="b2t sky">program {k} on input {k}: {T[k - 1]![k - 1]}; trouble: {trouble[k - 1]}. They clash.</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      readouts={quiet ? <Read label="Programs" value={n} /> : <>
        <Read label="Diagonal" value={T.map((r, i) => r[i]).join(" ")} />
        <Read label="Trouble row" value={trouble.join(" ")} tone="amber" big />
        <Read label="Matches a program" value={T.some(r => r === trouble.join("")) ? "yes" : "never"} />
      </>}
    />
  );
}
