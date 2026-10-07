import { useLayoutEffect, useState, type CSSProperties } from "react";
import type { AreaDiagram } from "../../explanations/diagrams/area-model/schema";
import type { AnimationState } from "../../explanations/schema";
import { formatNumber } from "../../curriculum/schemas/math-text";
import { ROW } from "../../explanations/diagrams/area-model/build";
import { useLabelFloor } from "./labelFloor";
import { layoutRect } from "../../app/transition";

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
 * Draws an area model exactly as its diagram model says. Every position, size and label comes from the model;
 * this component only decides which parts are visible at the current animation state, and which way round it lies:
 * when its tile is wide and the rectangle tall (or the other way), it turns a quarter so the longer side runs along
 * the longer side of the tile and the picture draws bigger (G 19:29 "changing the priority for numbers based on screen
 * size"). A story's picture never turns, so its rows stay the story's rows.
 */
export function AreaModelDiagram({ diagram: d, timeline, at, turn = true }: { diagram: AreaDiagram; timeline: AnimationState[]; at: number; /** may lie the other way round to fit its tile */ turn?: boolean }) {
  const v = areaView(timeline, at);
  const top = d.vertical.start, height = d.vertical.length;
  const left = d.horizontal.start, width = d.horizontal.length;
  const label = `${d.vertical.label} by ${d.horizontal.label} rectangle, split into ${d.regions
    .map(r => `${d.vertical.label} by ${r.partLabel} = ${r.productLabel}`).join(" and ")}. Total ${formatNumber(d.total.value)}.`;
  const ref = useLabelFloor(d.width);
  // which way round fits the tile bigger; a little hysteresis keeps it from flipping back and forth at the edge
  const [turned, setTurned] = useState(false);
  useLayoutEffect(() => {
    const box = ref.current?.parentElement;
    if (!turn || !box) { setTurned(false); return; }
    const pick = () => {
      const r = layoutRect(box);
      if (r.width <= 0 || r.height <= 0) return;
      const flat = Math.min(r.width / d.width, r.height / d.height), side = Math.min(r.width / d.height, r.height / d.width);
      setTurned(t => (t ? side >= flat / 1.1 : side > flat * 1.1));
    };
    pick();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(pick);
    ro.observe(box);
    return () => ro.disconnect();
  }, [d, turn, ref]);
  const T = turn && turned;
  const P = (x: number, y: number) => (T ? { x: y, y: x } : { x, y });
  const W = T ? d.height : d.width, H = T ? d.width : d.height;
  // the finished picture (every part, shown yet or not) sits in the middle of the canvas (G 18:09 "check if pictures are
  // centered"); it is centred once, so parts appear where they stay and nothing slides between beats (G 19:34)
  const [shift, setShift] = useState<{ k: string; dx: number; dy: number }>({ k: "", dx: 0, dy: 0 });
  const pic = `${d.width}x${d.height}:${d.total.value}:${T}`;
  useLayoutEffect(() => {
    const g = ref.current?.querySelector<SVGGElement>(".vcentre");
    if (!g || typeof g.getBBox !== "function") return;
    let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity;
    g.querySelectorAll<SVGGraphicsElement>("text,rect,line").forEach(e => {
      try {
        let b = e.getBBox();
        if (!(b.height > 0 || b.width > 0)) return;
        // shapes in the turned group measure in their own (unturned) units
        if (e.closest(".turned")) b = { x: b.y, y: b.x, width: b.height, height: b.width } as DOMRect;
        x0 = Math.min(x0, b.x); x1 = Math.max(x1, b.x + b.width); y0 = Math.min(y0, b.y); y1 = Math.max(y1, b.y + b.height);
      } catch { /* not measurable */ }
    });
    if (y1 > y0) setShift({ k: pic, dx: Math.round(W / 2 - (x0 + x1) / 2), dy: Math.round(H / 2 - (y0 + y1) / 2) });
  }, [pic, ref, W, H]);
  const sh = shift.k === pic ? shift : { dx: 0, dy: 0 };
  const end = T ? "end" : "middle";
  return (
    <svg ref={ref} className="am" viewBox={`0 0 ${W} ${H}`} role="img" aria-label={label}
      data-split={v.split} data-sum={v.sum} data-turned={T} style={{ "--w": W, "--h": H } as CSSProperties}>
      <g className="vcentre" style={{ transform: `translate(${sh.dx}px, ${sh.dy}px)` }}>
      {/* the side labels sit just outside the rectangle and grow away from it, so a label held big on a phone never runs into it */}
      <text className={`axis-label${T ? " out-top" : ""}`} {...P(left - LABEL_GAP, top + height / 2)} style={{ textAnchor: T ? "middle" : "end" }}>{d.vertical.label}</text>
      <text className={`whole${T ? "" : " out-top"}`} {...P(left + width / 2, top - LABEL_GAP)} style={{ textAnchor: end }}>{d.horizontal.label}</text>
      {d.regions.map(r => {
        const below = r.labelPlacement !== "inside";
        const lead = { a: P(r.x + r.width / 2, r.y + r.height - 6), b: P(r.x + r.width / 2, r.y + r.height + 8 + r.productRow * ROW) };
        return (
          <g key={r.index} className={`region r${r.index % 3}`} data-shown={v.shown.has(r.index) || v.sum} data-active={v.active === r.index}>
            <g className={T ? "turned" : undefined} transform={T ? "matrix(0 1 1 0 0 0)" : undefined}>
              <rect x={r.x} y={r.y} width={r.width} height={r.height} />
              {r.seats.map((l, k) => <line key={k} className={l.ten ? "seat ten" : "seat"} x1={l.x1} y1={l.y1} x2={l.x2} y2={l.y2} />)}
            </g>
            <text className={`part${T ? "" : " out-top"}`} {...P(r.x + r.width / 2, top - LABEL_GAP - (T ? 0 : r.partRow * ROW))} style={{ textAnchor: end }}>{r.partLabel}</text>
            {!below ? (
              <text className="product" {...P(r.x + r.width / 2, r.y + r.height / 2)}>{r.productLabel}</text>
            ) : (
              <g className="product">
                <line className="leader" x1={lead.a.x} y1={lead.a.y} x2={lead.b.x} y2={lead.b.y} />
                <text {...P(r.x + r.width / 2, r.y + r.height + 22 + r.productRow * ROW)} style={{ textAnchor: T ? "start" : "middle" }}>{r.productLabel}</text>
              </g>
            )}
          </g>
        );
      })}
      <g className={T ? "turned" : undefined} transform={T ? "matrix(0 1 1 0 0 0)" : undefined}>
        {d.splits.map(x => <line key={x} className="split-line" x1={x} y1={top - 6} x2={x} y2={top + height + 6} />)}
      </g>
      </g>
    </svg>
  );
}
