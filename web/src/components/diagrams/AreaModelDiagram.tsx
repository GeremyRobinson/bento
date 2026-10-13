import { useCallback, useEffect, useMemo, useRef, useState, type CSSProperties } from "react";
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
    // division's subtract step works on the leftover strip: it lights, with what's left written in it
    active: now?.phase === "region" || now?.phase === "left" ? now.index : null,
    left: new Set(reached.flatMap(s => (s.phase === "left" ? [s.index] : []))),
    sum: reached.some(s => s.phase === "sum"),
  };
}

const LABEL_GAP = 10;
/** on screen, whatever the picture's scale (v2 spec G1, G5, G6): parts at least 8px apart between their outlines, labels
 * 20px and 10px from their part, results 14px and inside their part. The outline is 3 units wide on each side of a gap. */
const SCREEN = { gap: 8, label: 20, labelGap: 10, result: 14, pad: 4 };
const LABEL_MIN = 28, RESULT_MAX = 26, OUTLINE = 3, DIGIT = 0.7, CAP = 0.72;
/** a result that can't fit its strip, and the sum under the bracket, in picture units before the 14px floor */
const OUT_SIZE = 20, SUM_SIZE = 22, SUM_CHAR = 0.62;
const r1 = (v: number) => Math.round(v * 10) / 10;

/** a result's size in picture units before the on-screen floor: fits its part, 12 to 26 (G6) */
export const resultSize = (w: number, h: number) => Math.round(Math.max(12, Math.min(RESULT_MAX, h * 0.42, w * 0.3)));

/** Where a result too wide for its strip goes, and where the sum's bracket goes: under the picture or beside it. The settle
 * tries each and keeps the one that draws the picture biggest in its box (a flat phone picture has room beside it, a tall
 * one under it). */
export interface AreaPlace { out: "below" | "right"; sum: "below" | "right" }
const PLACES: AreaPlace[] = [{ out: "below", sum: "below" }, { out: "right", sum: "below" }, { out: "below", sum: "right" }, { out: "right", sum: "right" }];

/** the line under the bracket: the parts and what they make (division adds the widths it found, multiplication the strips) */
export const sumText = (d: AreaDiagram, answer = true) => {
  const terms = d.find ? d.cols.map(c => c.label) : d.regions.map(r => r.productLabel);
  return `${terms.join(" + ")} = ${answer ? (d.find ? d.horizontal.label : formatNumber(d.total.value)) : "?"}`;
};

/** Where the parts and labels go once the picture's scale is known (`px`, units per screen pixel): gaps, label room and a
 * part's width never shrink below what reads on screen, so a small phone picture spreads its parts, makes room for its
 * labels and widens its strips (all by one stretch, so they keep their proportions) until the thinnest holds its result.
 * A result that still can't sit inside its strip at 14px on screen moves just outside it, on a short leader (Review #13).
 * Each result is drawn as big as its strip holds (12 to 26 units). Counts and seats still come from the numbers. */
export function areaFit(d: AreaDiagram, px: number, room = Infinity, place: AreaPlace = PLACES[0]!) {
  const lu = Math.max(LABEL_MIN, SCREEN.label * px), lg = Math.max(LABEL_GAP, SCREEN.labelGap * px);
  const gap = Math.max(PART_GAP, SCREEN.gap * px + 2 * OUTLINE);
  const pad = Math.max(4, SCREEN.pad * px), floor = SCREEN.result * px;
  const side = Math.max(0, ...d.rows.map(r => r.label.length * lu * DIGIT)) + lg;
  const first = d.cols[0]?.start ?? d.horizontal.start, top = d.vertical.start, bottom = top + d.vertical.length;
  const dx = Math.max(0, side - first), dy = Math.max(0, lg + lu * CAP - top);
  const need = (r: AreaRegion) => r.productLabel.length * Math.max(resultSize(r.width, r.height), floor) * DIGIT + 2 * pad;
  const last = d.cols.length - 1, right0 = d.width - (d.horizontal.start + d.horizontal.length);
  // what can sit beside the strips, whatever the stretch: a result moved out of the last strip, the sum's bracket
  const outShown = Math.max(OUT_SIZE, floor), sumShown = Math.max(SUM_SIZE, floor);
  const withSum = d.regions.length > 1, tick = lg * 0.6;
  const sumW = sumText(d).length * sumShown * SUM_CHAR;
  const outRightW = (r: AreaRegion) => OUTLINE + lg + pad + r.productLabel.length * outShown * DIGIT;
  const sumRightW = withSum && place.sum === "right" ? OUTLINE + lg * 0.6 + tick + lg * 0.6 + sumW : 0;
  const maybeOut = place.out === "right" ? Math.max(0, ...d.regions.filter(r => r.col === last).map(outRightW)) : 0;
  // one stretch for every column, so the strips keep their proportions to each other (20 stays five times 4)
  // only as far as the panel has room at this scale: past that the picture would shrink and its text with it
  const fixedW = first + dx + gap * (d.cols.length - 1) + right0 + maybeOut + sumRightW;
  const total = d.cols.reduce((a, c) => a + c.length, 0);
  const want = Math.max(...d.cols.map((c, i) => Math.max(0, ...d.regions.filter(r => r.col === i).map(need)) / c.length));
  const k = Math.max(1, Math.min(want, (room - fixedW) / total));
  const widths = d.cols.map(c => c.length * k);
  const starts: number[] = [];
  widths.reduce((at, w, i) => (starts[i] = at, at + w + gap), first + dx);
  const right = starts.length ? starts[starts.length - 1]! + widths[widths.length - 1]! : first + dx;
  // each result as big as its strip holds, or outside it on a leader when 14px on screen won't fit
  const sides = d.regions.map(r => {
    const w = widths[r.col]!, len = r.productLabel.length;
    const size = Math.max(12, Math.min(RESULT_MAX, r.height * 0.42, (w - 2 * pad) / (len * DIGIT)));
    const inside = len * Math.max(size, floor) * DIGIT + 2 * pad <= w + 0.5;
    return { size, side: inside ? "in" as const : place.out === "right" && r.col === last ? "right" as const : "below" as const };
  });
  const belowOut = sides.some(o => o.side === "below") ? OUTLINE + lg + pad + outShown : 0;
  const rightOut = sides.some(o => o.side === "right") ? maybeOut : 0;
  const results = d.regions.map((r, i) => {
    const { size, side } = sides[i]!, x = starts[r.col]!, w = widths[r.col]!, cx = x + w / 2, mid = r.y + r.height / 2;
    if (side === "in") return { side, size, x: cx, y: mid, anchor: "middle" as const, leader: null };
    if (side === "right") {
      const x0 = x + w + OUTLINE;
      return { side, size: OUT_SIZE, x: x0 + lg + pad, y: mid, anchor: "start" as const, leader: [x0, mid, x0 + lg, mid].map(r1) };
    }
    const y0 = r.y + r.height + OUTLINE;
    return { side, size: OUT_SIZE, x: cx, y: y0 + lg + pad + outShown / 2, anchor: "middle" as const, leader: [cx, y0, cx, y0 + lg].map(r1) };
  });
  // the bracket under (or beside) the strips, and the sum it closes with
  let sum: { path: string; x: number; y: number; anchor: "middle" | "start"; size: number } | null = null, below = belowOut;
  if (withSum && place.sum === "below") {
    const yl = bottom + Math.max(OUTLINE, belowOut) + lg * 0.6 + tick, x0 = starts[0]! - OUTLINE, x1 = right + OUTLINE;
    sum = { path: `M${r1(x0)} ${r1(yl - tick)}V${r1(yl)}H${r1(x1)}V${r1(yl - tick)}`, x: (x0 + x1) / 2, y: yl + lg * 0.6 + sumShown / 2, anchor: "middle", size: SUM_SIZE };
    below = yl + lg * 0.6 + sumShown - bottom;
  } else if (withSum) {
    const xl = right + Math.max(OUTLINE, rightOut) + lg * 0.6 + tick;
    sum = { path: `M${r1(xl - tick)} ${r1(top - OUTLINE)}H${r1(xl)}V${r1(bottom + OUTLINE)}H${r1(xl - tick)}`, x: xl + lg * 0.6, y: (top + bottom) / 2, anchor: "start", size: SUM_SIZE };
  }
  const beside = place.sum === "right" && withSum ? Math.max(OUTLINE, rightOut) + sumRightW - OUTLINE : rightOut;
  // a sum wider than a narrow picture's strips takes the room it needs
  const spill = sum && place.sum === "below" ? Math.max(0, sum.x + sumW / 2 - right) : 0;
  const width = Math.max(d.width, right + Math.max(right0, beside + right0 / 2, spill + right0 / 2));
  const height = Math.max(d.height, bottom + below + 4) + dy;
  return { lu, lg, dy, starts, widths, width, height, results, sum };
}

/**
 * The layout for a box on screen (`w` × `h` screen pixels; none yet = the plain layout). The scale and the stretch depend on
 * each other, so they are settled here, in a fixed number of steps: the scale only ever grows, and stops once it moves less
 * than 1%. Same box, same answer, so the picture lays out once and stays. Every place for an outside result and the
 * bracket is settled, and the one that draws the picture biggest wins (the first, under the picture, on a tie).
 */
export function settleFit(d: AreaDiagram, box: { w: number; h: number } | null) {
  if (!box || box.w <= 0) return areaFit(d, 0);
  let best: { px: number; fit: ReturnType<typeof areaFit> } | null = null;
  for (const place of PLACES) {
    let px = 0, fit = areaFit(d, 0, Infinity, place);
    for (let i = 0; i < 12; i++) {
      const next = Math.max(px, fit.width / box.w, box.h > 0 ? fit.height / box.h : 0);
      if (next - px <= px * 0.01) break;
      px = next;
      fit = areaFit(d, px, box.w * px, place);
    }
    const drawn = Math.max(fit.width / box.w, box.h > 0 ? fit.height / box.h : 0);
    if (!best || drawn < best.px * 0.97) best = { px: drawn, fit };
  }
  return best!.fit;
}

/**
 * Draws an area model exactly as its diagram model says (v2 lesson spec G1-G9). Every position, size and label comes from
 * the model; this component only decides which parts are lit and which results show at the current animation state.
 * Each column and row is labelled once, outside the picture: column labels centred over their column, row labels at the
 * picture's left edge, in line with the problem. A label is lit while its part is the one being worked on.
 * Every beat changes the picture (Review #8): the second number stands whole, then splits into its strips; each strip
 * lights and fills; division writes what's left into its strip; the last beat closes with a bracket and the sum under it.
 */
const BURST = 6, QUIET = 300;

export function AreaModelDiagram({ diagram: d, timeline, at, ask }: { diagram: AreaDiagram; timeline: AnimationState[]; at: number; ask?: number; /** kept for callers; the v2 picture never turns */ turn?: boolean }) {
  const view = areaView(timeline, at);
  // practice lights the part it is asking about (no answer yet)
  const asked = ask != null ? timeline[ask] : undefined;
  // asking for the sum lights no single strip: the bracket under them all is the part asked about
  const v = { ...view, active: asked?.phase === "region" || asked?.phase === "left" ? asked.index : asked?.phase === "sum" ? null : view.active };
  // the first beat shows the second number whole; practice (asking about a strip) and division start from the strips
  const split = view.split || asked != null || !!d.find || d.cols.length < 2;
  const askSum = asked?.phase === "sum" && !view.sum;
  const lit = v.active != null ? d.regions[v.active] : undefined;
  const label = `${d.vertical.label} by ${d.horizontal.label} rectangle, split into ${d.regions
    .map(r => `${r.equation.factors[0]} by ${r.equation.factors[1]} = ${r.productLabel}`).join(" and ")}. Total ${formatNumber(d.total.value)}.`;
  // the box the picture has on screen; its scale is worked out from the box in one go (settleFit), so laying it out never
  // feeds back into the box (Review: React #185 on phones when the scale chased the stretch). Every real change of the box
  // is followed. Only a burst of changes (more than BURST inside QUIET ms: a picture sized by its own width chasing
  // itself) is held, and then the last box seen is taken once the burst is over, so a real change is never lost
  // (Review: after a second miss the say line grew and shrank, the old fixed count ran out and the picture went flat)
  const [box, setBox] = useState<{ w: number; h: number } | null>(null);
  const burst = useRef({ n: 0, t: 0, cur: null as { w: number; h: number } | null, last: null as { w: number; h: number } | null, timer: 0 as ReturnType<typeof setTimeout> | 0 });
  const onBox = useCallback((w: number, h: number) => {
    const b = burst.current, now = Date.now(), same = (o: { w: number; h: number } | null) => !!o && Math.abs(w - o.w) <= 1 && Math.abs(h - o.h) <= 1;
    if (now - b.t > QUIET) b.n = 0;
    b.t = now; b.last = { w, h };
    if (same(b.cur)) return;
    if (b.n >= BURST) {
      if (!b.timer) b.timer = setTimeout(() => { b.timer = 0; b.n = 0; const l = b.last; if (l && !(b.cur && Math.abs(l.w - b.cur.w) <= 1 && Math.abs(l.h - b.cur.h) <= 1)) { b.cur = l; setBox(l); } }, QUIET);
      return;
    }
    b.n++; b.cur = { w, h }; setBox(b.cur);
  }, []);
  useEffect(() => () => { if (burst.current.timer) clearTimeout(burst.current.timer); }, []);
  const fit = useMemo(() => settleFit(d, box), [d, box]);
  const ref = useLabelFloor(fit.width, onBox);
  const top = d.vertical.start;
  // division finds the widths: a label shows once its strip is done (spec g5-divide); "?" only beside a width already
  // found, never alone over an empty picture (Review #18)
  const found = (i: number) => !d.find || v.sum || d.regions.some(r => r.col === i && v.shown.has(r.index));
  const x0 = fit.starts[0] ?? 0, xr = (fit.starts.at(-1) ?? 0) + (fit.widths.at(-1) ?? 0);
  return (
    <svg ref={ref} className="am" viewBox={`0 0 ${fit.width} ${fit.height}`} preserveAspectRatio="xMinYMin meet" role="img" aria-label={label}
      data-split={split} data-sum={v.sum} data-find={d.find || undefined} style={{ "--w": fit.width, "--h": fit.height } as CSSProperties}>
      <g transform={`translate(0 ${fit.dy})`} fill="none">
      {d.cols.map((c, i) => {
        const text = !split ? (i === 0 ? d.horizontal.label : null) : found(i) ? c.label
          : v.active != null && d.regions[v.active]?.col === i && (asked ?? timeline[at])?.phase !== "left" && d.cols.some((_, j) => j !== i && found(j)) ? "?" : null;
        const x = !split ? (x0 + xr) / 2 : fit.starts[i]! + fit.widths[i]! / 2;
        return text == null ? null : <text key={`c${i}-${split}`} className={lit && split && lit.col === i ? "part out-top lit" : "part out-top"} data-lit={!lit || lit.col === i} x={x} y={top - fit.lg - fit.lu * 0.36} style={{ textAnchor: "middle" }}>{text}</text>;
      })}
      {d.rows.map((r, i) => (
        <text key={`r${i}`} className={lit && lit.row === i ? "part lit" : "part"} data-lit={!lit || lit.row === i} x={0} y={r.start + r.length / 2} style={{ textAnchor: "start" }}>{r.label}</text>
      ))}
      {split ? d.regions.map((r, n) => {
        const x = fit.starts[r.col]!, w = fit.widths[r.col]!, o = fit.results[n]!;
        const seats = w === r.width ? r.seats.map(l => ({ ...l, x1: l.x1 - r.x + x, x2: l.x2 - r.x + x })) : seatLines(x, r.y, w, r.height, r.part, r.equation.factors[0], 0, STRIP_SEAT_MIN);
        return (
        <g key={r.index} className={v.active === r.index ? "region lit" : "region"} style={{ "--i": r.index } as CSSProperties} data-shown={v.shown.has(r.index) || v.sum} data-active={v.active === r.index} data-left={v.left.has(r.index)} data-out={o.side !== "in" || undefined}>
          {/* one shape per part: the fill, with its outline just outside it so every seat shows whole (G1, G2) */}
          <rect className="fill edge" x={x - 1.5} y={r.y - 1.5} width={w + 3} height={r.height + 3} rx={5.5} />
          {seats.map((l, k) => <line key={k} className="seat" x1={l.x1} y1={l.y1} x2={l.x2} y2={l.y2} />)}
          {/* the part's result sits inside it, as big as the part holds (G6); too thin a part points to it from just outside */}
          {o.leader && <line className="leader" x1={o.leader[0]} y1={o.leader[1]} x2={o.leader[2]} y2={o.leader[3]} pathLength={1} />}
          <text className="product" x={o.x} y={o.y} style={{ "--fs": r1(o.size), textAnchor: o.anchor } as CSSProperties}>{r.productLabel}</text>
        </g>
        );
      }) : (
        // the second number whole, before it is split (its seats are the whole problem's)
        <g key="whole" className="region whole" style={{ "--i": 0 } as CSSProperties} data-shown={false} data-active={false}>
          <rect className="fill edge" x={x0 - 1.5} y={top - 1.5} width={xr - x0 + 3} height={d.vertical.length + 3} rx={5.5} />
          {seatLines(x0, top, xr - x0, d.vertical.length, d.horizontal.value, d.vertical.value, 0, STRIP_SEAT_MIN).map((l, k) => <line key={k} className="seat" x1={l.x1} y1={l.y1} x2={l.x2} y2={l.y2} />)}
        </g>
      )}
      {fit.sum && (
        // the last beat: a bracket closes the strips and the sum is written under it ("90 + 6 = 96", like the live site)
        <g className={askSum ? "sum lit" : "sum"} data-on={v.sum || askSum} data-active={askSum}>
          <path className="bracket" d={fit.sum.path} pathLength={1} />
          <text className="sumtext" x={r1(fit.sum.x)} y={r1(fit.sum.y)} style={{ "--fs": fit.sum.size, textAnchor: fit.sum.anchor } as CSSProperties}>{sumText(d, v.sum)}</text>
        </g>
      )}
      </g>
    </svg>
  );
}
