import type { CSSProperties } from "react";
import type { AreaDiagram } from "../../explanations/diagrams/area-model/schema";
import type { AnimationState } from "../../explanations/schema";
import { formatNumber } from "../../curriculum/schemas/math-text";
import { useLabelFloor } from "./labelFloor";

/** What the picture shows at one point of the timeline. Pure, so tests can check it without rendering. */
export function areaView(timeline: AnimationState[], at: number) {
  const reached = timeline.slice(0, at + 1);
  const now = timeline[at];
  return {
    split: reached.some(s => s.phase !== "factors"),
    shown: new Set(reached.flatMap(s => (s.phase === "region" ? [s.index] : []))),
    active: now?.phase === "region" ? now.index : null,
    sum: reached.some(s => s.phase === "sum"),
  };
}

const LABEL_GAP = 10;

/**
 * Draws an area model exactly as its diagram model says (v2 lesson spec G1-G9). Every position, size and label comes from
 * the model; this component only decides which parts are lit and which results show at the current animation state.
 * Each column and row is labelled once, outside the picture: column labels centred over their column, row labels at the
 * picture's left edge, in line with the problem. A label is lit while its part is the one being worked on.
 */
export function AreaModelDiagram({ diagram: d, timeline, at, ask }: { diagram: AreaDiagram; timeline: AnimationState[]; at: number; ask?: number; /** kept for callers; the v2 picture never turns */ turn?: boolean }) {
  const view = areaView(timeline, at);
  // practice lights the part it is asking about (no answer yet)
  const asked = ask != null ? timeline[ask] : undefined;
  const v = { ...view, active: asked?.phase === "region" ? asked.index : view.active };
  const lit = v.active != null ? d.regions[v.active] : undefined;
  const label = `${d.vertical.label} by ${d.horizontal.label} rectangle, split into ${d.regions
    .map(r => `${r.equation.factors[0]} by ${r.equation.factors[1]} = ${r.productLabel}`).join(" and ")}. Total ${formatNumber(d.total.value)}.`;
  const ref = useLabelFloor(d.width);
  const top = d.vertical.start;
  return (
    <svg ref={ref} className="am" viewBox={`0 0 ${d.width} ${d.height}`} preserveAspectRatio="xMinYMin meet" role="img" aria-label={label}
      data-split={v.split} data-sum={v.sum} style={{ "--w": d.width, "--h": d.height } as CSSProperties}>
      {d.cols.map((c, i) => (
        <text key={`c${i}`} className="part out-top" data-lit={!lit || lit.col === i} x={c.start + c.length / 2} y={top - LABEL_GAP} style={{ textAnchor: "middle" }}>{c.label}</text>
      ))}
      {d.rows.map((r, i) => (
        <text key={`r${i}`} className="part" data-lit={!lit || lit.row === i} x={0} y={r.start + r.length / 2} style={{ textAnchor: "start" }}>{r.label}</text>
      ))}
      {d.regions.map(r => (
        <g key={r.index} className="region" data-shown={v.shown.has(r.index) || v.sum} data-active={v.active === r.index}>
          {/* one shape per part: the fill, with its outline just outside it so every seat shows whole (G1, G2) */}
          <rect className="fill edge" x={r.x - 1.5} y={r.y - 1.5} width={r.width + 3} height={r.height + 3} rx={5.5} />
          {r.seats.map((l, k) => <line key={k} className="seat" x1={l.x1} y1={l.y1} x2={l.x2} y2={l.y2} />)}
          {/* the part's result sits inside it, sized to the part (G6) */}
          <text className="product" x={r.x + r.width / 2} y={r.y + r.height / 2} style={{ "--fs": Math.round(Math.max(12, Math.min(48, r.height * 0.42, r.width * 0.3))) } as CSSProperties}>{r.productLabel}</text>
        </g>
      ))}
    </svg>
  );
}
