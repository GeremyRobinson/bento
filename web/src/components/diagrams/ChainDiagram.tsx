import type { CSSProperties } from "react";
import type { ChainDiagram as Chain } from "../../explanations/diagrams/chain/schema";
import { MathLine } from "../primitives/MathLine";

/** Lines of math, each following from the one above, revealed beat by beat. */
export function ChainDiagram({ diagram: d, at }: { diagram: Chain; at: number }) {
  const shown = d.lines.filter(l => l.from <= at);
  return (
    <div className="rs" role="img" aria-label={d.alt} style={{ "--n": d.lines.length } as CSSProperties}>
      {shown.map((l, i) => (
        <div key={i} style={{ display: "contents" }}>
          {i > 0 && <span className="rs-arrow a-rise" aria-hidden="true">↓</span>}
          <div className="rs-line a-rise"><MathLine math={l.math} keep /></div>
        </div>
      ))}
    </div>
  );
}
