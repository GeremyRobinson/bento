/**
 * The coordinate plane family: what a lesson asks to be drawn, in the problem's own coordinates.
 * The builder (./build.ts) turns this into a scene: it picks the window from these values, scales, draws the grid,
 * axes and tick labels, and places every label where it does not cover a point, a line or another label.
 */
export type Pt = readonly [number, number];

/** Where a label prefers to sit around its anchor; the placer tries these first, then the rest. */
export type Side = "n" | "s" | "e" | "w" | "ne" | "nw" | "se" | "sw" | "c";

interface Timing {
  /** beat it appears at (default 0) */
  from?: number;
  /** last beat it is shown at */
  until?: number;
  /** stagger within its beat, seconds */
  delay?: number;
}

/** A label attached to an item. `acc` draws it in the accent colour; `optional` labels are left out when there is no free room. */
export interface PlaneLabel {
  text: string;
  acc?: boolean;
  /** a part's color for the label (0 blue, 1 orange, 2 violet), matching the part it names (handoff-6) */
  part?: 0 | 1 | 2;
  prefer?: Side[];
  optional?: boolean;
  /** beat the label appears at, when later than its item */
  from?: number;
  /** keep out of the axes' tick-number bands, for a point sitting on or beside an axis */
  clearAxes?: boolean;
}

export type PlaneItem =
  /** a dot; `cls` dotp (main colour), dota (accent) or hole (open circle) */
  | (Timing & { kind: "point"; at: Pt; cls?: "dotp" | "dota" | "hole"; label?: PlaneLabel; small?: boolean })
  /** a straight piece between two points; `arrow` puts a head at b */
  | (Timing & { kind: "segment"; a: Pt; b: Pt; cls?: string; arrow?: boolean; label?: PlaneLabel; slow?: boolean })
  /** the line y = m·x + b across the whole window, or x = `x` when vertical */
  | (Timing & { kind: "line"; m: number; b: number; cls?: string; label?: PlaneLabel; labelX?: number })
  | (Timing & { kind: "vline"; x: number; cls?: string; label?: PlaneLabel; labelY?: number })
  /** the graph of f between x0 and x1, cut where it leaves the window */
  | (Timing & { kind: "curve"; f: (x: number) => number; x0?: number; x1?: number; cls?: string; label?: PlaneLabel; labelX?: number })
  | (Timing & { kind: "circle"; c: Pt; r: number; cls?: string })
  /** the region between f and the x-axis from a to b */
  | (Timing & { kind: "area"; f: (x: number) => number; a: number; b: number; label?: PlaneLabel; labelAt?: Pt })
  /** a label on its own, near a point of the plane */
  | (Timing & { kind: "label"; at: Pt; label: PlaneLabel })
  /** a small square marking a right angle at `at` between directions u and v */
  | (Timing & { kind: "rightAngle"; at: Pt; u: Pt; v: Pt })
  /** an arc at `at` from direction u to direction v (the smaller turn) */
  | (Timing & { kind: "angle"; at: Pt; u: Pt; v: Pt; cls?: string; label?: PlaneLabel });

export interface PlaneSpec {
  items: PlaneItem[];
  /** points the window must show besides the items' own (lines and curves have none of their own) */
  fit?: Pt[];
  /** a fixed window instead of the computed one */
  window?: { x: [number, number]; y: [number, number] };
  /** one scale for both axes, so circles stay round and right angles stay square */
  equal?: boolean;
  /** what the picture shows, for screen readers */
  alt: string;
}
