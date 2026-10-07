/**
 * A picture made of shapes, for every diagram family except the area model.
 * Family builders (number line, coordinate plane, tape, balance, ...) compute every shape from the problem;
 * the renderer draws exactly these shapes and decides nothing.
 *
 * `cls` uses the picture styles the current app already has (see styles/components.css, `.viz-svg ...`):
 * ax, ax thin, dash, grid, tk, ln, ln2, ln thin, ln faint, hl, hlline, fill, fillsoft, dotp, dota, hole, sq, sq big,
 * cell c0/c1/c2, seg, seg on, seg cut, cf top/left/right, wire, bar, fulcrum, beam, tile x/n, marble red/blue/ring/c0/c1/c2,
 * tri c0/c1/c2, shadeA, shadeB, both, pie, arcline, arcline thin. Text: sm, xs, big, lbl, lbl big, acc, onlbl, end, start.
 */
export type Enter = "draw" | "draw slow" | "pop" | "growx" | "growy" | "fade" | "rise" | "sweep" | "grow" | "level" | "slide" | "flash" | "swing" | "fold";

interface Base {
  cls?: string;
  /** timeline beat this shape appears at (default 0: shown from the start) */
  from?: number;
  /** last beat it is shown at (it fades out after) */
  until?: number;
  /** how it comes in when its beat arrives */
  enter?: Enter;
  /** extra delay in seconds within its beat, so shapes in one beat can stagger */
  delay?: number;
  /** CSS custom properties some styles read, e.g. { "--f": 0.25 } for pie slices or { "--from": 0.4 } for level */
  vars?: Record<string, number | string>;
}

export type SceneItem =
  | (Base & { type: "rect"; x: number; y: number; w: number; h: number; rx?: number })
  | (Base & { type: "line"; x1: number; y1: number; x2: number; y2: number })
  | (Base & { type: "circle"; cx: number; cy: number; r: number })
  /** paths get pathLength 1 so "draw" can trace them */
  | (Base & { type: "path"; d: string })
  | (Base & { type: "polygon"; points: [number, number][] })
  | (Base & { type: "text"; x: number; y: number; text: string; /** superscript after the text, e.g. "2" in x² */ sup?: string });

export interface SceneDiagram {
  kind: "scene";
  /** which family built it, for tests and styling */
  family: string;
  width: number;
  height: number;
  items: SceneItem[];
  /** what the picture shows, for screen readers */
  alt: string;
}
