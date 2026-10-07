import { useLayoutEffect, useState, type CSSProperties } from "react";
import type { AreaDiagram } from "../../explanations/diagrams/area-model/schema";
import type { AnimationState } from "../../explanations/schema";
import { formatNumber } from "../../curriculum/schemas/math-text";
import { ROW } from "../../explanations/diagrams/area-model/build";
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

const LABEL_GAP = 18;

/**
 * Draws an area model exactly as its diagram model says. Every position, size and label comes from the model;
 * this component only decides which parts are visible at the current animation state.
 */
export function AreaModelDiagram({ diagram: d, timeline, at }: { diagram: AreaDiagram; timeline: AnimationState[]; at: number }) {
  const v = areaView(timeline, at);
  const top = d.vertical.start, height = d.vertical.length;
  const left = d.horizontal.start, width = d.horizontal.length;
  const label = `${d.vertical.label} by ${d.horizontal.label} rectangle, split into ${d.regions
    .map(r => `${d.vertical.label} by ${r.partLabel} = ${r.productLabel}`).join(" and ")}. Total ${formatNumber(d.total.value)}.`;
  const ref = useLabelFloor(d.width);
  // what's drawn so far sits in the middle of the canvas, top to bottom (G 18:09 "check if pictures are centered"): the
  // canvas keeps room below for product labels that only show later, so the picture slides down into the centre until then
  const [shift, setShift] = useState<{ d: AreaDiagram | null; dy: number; slide: boolean }>({ d: null, dy: 0, slide: false });
  const shownKey = [...v.shown].join(",") + (v.sum ? "+" : "");
  useLayoutEffect(() => {
    const g = ref.current?.querySelector<SVGGElement>(".vcentre");
    if (!g || typeof g.getBBox !== "function") return;
    let y0 = Infinity, y1 = -Infinity;
    g.querySelectorAll<SVGGraphicsElement>("text,rect,line").forEach(e => {
      if (e.closest('[data-shown="false"]')) return;
      try { const b = e.getBBox(); if (b.height > 0 || b.width > 0) { y0 = Math.min(y0, b.y); y1 = Math.max(y1, b.y + b.height); } } catch { /* not measurable */ }
    });
    // a new picture lands centred; only one that grows slides
    if (y1 > y0) { const dy = Math.round(d.height / 2 - (y0 + y1) / 2); setShift(o => ({ d, dy, slide: o.d === d })); }
  }, [d, shownKey, ref]);
  return (
    <svg ref={ref} className="am" viewBox={`0 0 ${d.width} ${d.height}`} role="img" aria-label={label}
      data-split={v.split} data-sum={v.sum} style={{ "--w": d.width, "--h": d.height } as CSSProperties}>
      <g className={`vcentre${shift.slide ? " slide" : ""}`} style={{ transform: `translateY(${shift.d === d ? shift.dy : 0}px)` }}>
      <text className="axis-label" x={left - 28} y={top + height / 2}>{d.vertical.label}</text>
      <text className="whole" x={left + width / 2} y={top - LABEL_GAP}>{d.horizontal.label}</text>
      {d.regions.map(r => (
        <g key={r.index} className={`region r${r.index % 3}`} data-shown={v.shown.has(r.index) || v.sum} data-active={v.active === r.index}>
          <rect x={r.x} y={r.y} width={r.width} height={r.height} />
          {r.seats.map((l, k) => <line key={k} className={l.ten ? "seat ten" : "seat"} x1={l.x1} y1={l.y1} x2={l.x2} y2={l.y2} />)}
          <text className="part" x={r.x + r.width / 2} y={top - LABEL_GAP - r.partRow * ROW}>{r.partLabel}</text>
          {r.labelPlacement === "inside" ? (
            <text className="product" x={r.x + r.width / 2} y={r.y + r.height / 2}>{r.productLabel}</text>
          ) : (
            <g className="product">
              <line className="leader" x1={r.x + r.width / 2} y1={r.y + r.height - 6} x2={r.x + r.width / 2} y2={r.y + r.height + 8 + r.productRow * ROW} />
              <text x={r.x + r.width / 2} y={r.y + r.height + 22 + r.productRow * ROW}>{r.productLabel}</text>
            </g>
          )}
        </g>
      ))}
      {d.splits.map(x => <line key={x} className="split-line" x1={x} y1={top - 6} x2={x} y2={top + height + 6} />)}
      </g>
    </svg>
  );
}
