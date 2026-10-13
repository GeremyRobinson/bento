import { useCallback, useMemo, useState, type CSSProperties } from "react";
import type { AreaDiagram, AreaRegion } from "../../explanations/diagrams/area-model/schema";
import type { AnimationState } from "../../explanations/schema";
import { formatNumber } from "../../curriculum/schemas/math-text";
import { useLabelFloor } from "./labelFloor";
import { PART_GAP, STRIP_SEAT_MIN } from "../../explanations/diagrams/area-model/build";
import { seatLines } from "../../explanations/diagrams/area-model/seats";

/** What the picture shows at one point of the timeline. Pure, so tests can check it without rendering. */
export function areaView(timeline: AnimationState[], at: number) {
  const reached = timeline.slice(0, at + 1);
  const now = timeline[at];
  return {
    split: reached.some(s => s.phase !== "factors"),
    shown: new Set(reached.flatMap(s => (s.phase === "region" ? [s.index] : []))),
    active: now?.phase === "region" ? now.index : null,
    left: new Set(reached.flatMap(s => (s.phase === "left" ? [s.index] : []))),
    sum: reached.some(s => s.phase === "sum"),
  };
}

const LABEL_GAP = 10;
/** on screen, whatever the picture's scale (v2 spec G1, G5, G6): parts at least 8px apart between their outlines, labels
 * 20px and 10px from their part, results 14px and inside their part. The outline is 3 units wide on each side of a gap. */
const SCREEN = { gap: 8, label: 20, labelGap: 10, result: 14, pad: 4 };
const LABEL_MIN = 28, RESULT_MAX = 26, OUTLINE = 3, DIGIT = 0.7, CAP = 0.72;

/** a result's size in picture units before the on-screen floor: fits its part, 12 to 26 (G6) */
export const resultSize = (w: number, h: number) => Math.round(Math.max(12, Math.min(RESULT_MAX, h * 0.42, w * 0.3)));

/** Where the parts and labels go once the picture's scale is known (`px`, units per screen pixel): gaps, label room and a
 * part's width never shrink below what reads on screen, so a small phone picture spreads its parts, makes room for its
 * labels and widens its strips (all by one stretch, so they keep their proportions) until the thinnest holds its result. Counts and seats still come from the numbers. */
export function areaFit(d: AreaDiagram, px: number, room = Infinity) {
  const lu = Math.max(LABEL_MIN, SCREEN.label * px), lg = Math.max(LABEL_GAP, SCREEN.labelGap * px);
  const gap = Math.max(PART_GAP, SCREEN.gap * px + 2 * OUTLINE);
  const side = Math.max(0, ...d.rows.map(r => r.label.length * lu * DIGIT)) + lg;
  const first = d.cols[0]?.start ?? d.horizontal.start, top = d.vertical.start;
  const dx = Math.max(0, side - first), dy = Math.max(0, lg + lu * CAP - top);
  const need = (r: AreaRegion) => r.productLabel.length * Math.max(resultSize(r.width, r.height), SCREEN.result * px) * DIGIT + 2 * Math.max(4, SCREEN.pad * px);
  // one stretch for every column, so the strips keep their proportions to each other (20 stays five times 4)
  // only as far as the panel has room at this scale: past that the picture would shrink and its text with it
  const fixedW = first + dx + gap * (d.cols.length - 1) + (d.width - (d.horizontal.start + d.horizontal.length));
  const total = d.cols.reduce((a, c) => a + c.length, 0);
  const want = Math.max(...d.cols.map((c, i) => Math.max(0, ...d.regions.filter(r => r.col === i).map(need)) / c.length));
  const k = Math.max(1, Math.min(want, (room - fixedW) / total));
  const widths = d.cols.map(c => c.length * k);
  const starts: number[] = [];
  widths.reduce((at, w, i) => (starts[i] = at, at + w + gap), first + dx);
  const right = starts.length ? starts[starts.length - 1]! + widths[widths.length - 1]! : first + dx;
  const width = Math.max(d.width, right + (d.width - (d.horizontal.start + d.horizontal.length)));
  return { lu, lg, dy, starts, widths, width, height: d.height + dy };
}

/**
 * The layout for a box on screen (`w` × `h` screen pixels; none yet = the plain layout). The scale and the stretch depend on
 * each other, so they are settled here, in a fixed number of steps: the scale only ever grows, and stops once it moves less
 * than 1%. Same box, same answer, so the picture lays out once and stays.
 */
export function settleFit(d: AreaDiagram, box: { w: number; h: number } | null) {
  if (!box || box.w <= 0) return areaFit(d, 0);
  let px = 0, fit = areaFit(d, 0);
  for (let i = 0; i < 12; i++) {
    const next = Math.max(px, fit.width / box.w, box.h > 0 ? fit.height / box.h : 0);
    if (next - px <= px * 0.01) break;
    px = next;
    fit = areaFit(d, px, box.w * px);
  }
  return fit;
}

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
  const v = { ...view, active: asked?.phase === "region" || asked?.phase === "left" ? asked.index : view.active };
  const lit = v.active != null ? d.regions[v.active] : undefined;
  const label = `${d.vertical.label} by ${d.horizontal.label} rectangle, split into ${d.regions
    .map(r => `${r.equation.factors[0]} by ${r.equation.factors[1]} = ${r.productLabel}`).join(" and ")}. Total ${formatNumber(d.total.value)}.`;
  // the box the picture has on screen; its scale is worked out from the box in one go (settleFit), so laying it out never
  // feeds back into the box (Review: React #185 on phones when the scale chased the stretch). A box that keeps moving
  // (a picture sized by its own width) stops being followed after a few changes
  const [box, setBox] = useState<{ w: number; h: number; n: number } | null>(null);
  const onBox = useCallback((w: number, h: number) => setBox(o => (!o || (o.n < 6 && (Math.abs(w - o.w) > 1 || Math.abs(h - o.h) > 1)) ? { w, h, n: (o?.n ?? 0) + 1 } : o)), []);
  const fit = useMemo(() => settleFit(d, box), [d, box]);
  const ref = useLabelFloor(fit.width, onBox);
  const top = d.vertical.start;
  return (
    <svg ref={ref} className="am" viewBox={`0 0 ${fit.width} ${fit.height}`} preserveAspectRatio="xMinYMin meet" role="img" aria-label={label}
      data-split={v.split} data-sum={v.sum} data-find={d.find || undefined} style={{ "--w": fit.width, "--h": fit.height } as CSSProperties}>
      <g transform={`translate(0 ${fit.dy})`} fill="none">
      {d.cols.map((c, i) => {
        // division finds the widths: a label shows once its strip is done, "?" while its width is asked (spec g5-divide)
        const found = !d.find || v.sum || d.regions.some(r => r.col === i && v.shown.has(r.index));
        const text = found ? c.label : v.active != null && d.regions[v.active]?.col === i && asked?.phase !== "left" ? "?" : null;
        return text == null ? null : <text key={`c${i}`} className="part out-top" data-lit={!lit || lit.col === i} x={fit.starts[i]! + fit.widths[i]! / 2} y={top - fit.lg - fit.lu * 0.36} style={{ textAnchor: "middle" }}>{text}</text>;
      })}
      {d.rows.map((r, i) => (
        <text key={`r${i}`} className="part" data-lit={!lit || lit.row === i} x={0} y={r.start + r.length / 2} style={{ textAnchor: "start" }}>{r.label}</text>
      ))}
      {d.regions.map(r => {
        const x = fit.starts[r.col]!, w = fit.widths[r.col]!;
        const seats = w === r.width ? r.seats.map(l => ({ ...l, x1: l.x1 - r.x + x, x2: l.x2 - r.x + x })) : seatLines(x, r.y, w, r.height, r.part, r.equation.factors[0], 0, STRIP_SEAT_MIN);
        return (
        <g key={r.index} className="region" data-shown={v.shown.has(r.index) || v.sum} data-active={v.active === r.index} data-left={v.left.has(r.index)}>
          {/* one shape per part: the fill, with its outline just outside it so every seat shows whole (G1, G2) */}
          <rect className="fill edge" x={x - 1.5} y={r.y - 1.5} width={w + 3} height={r.height + 3} rx={5.5} />
          {seats.map((l, k) => <line key={k} className="seat" x1={l.x1} y1={l.y1} x2={l.x2} y2={l.y2} />)}
          {/* the part's result sits inside it, sized to the part (G6) */}
          <text className="product" x={x + w / 2} y={r.y + r.height / 2} style={{ "--fs": resultSize(r.width, r.height) } as CSSProperties}>{r.productLabel}</text>
        </g>
        );
      })}
      </g>
    </svg>
  );
}
