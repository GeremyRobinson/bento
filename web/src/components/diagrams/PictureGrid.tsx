import type { DiagramModel } from "../../explanations/schema";
import { SQUARE } from "../../explanations/diagrams/scene/picture-system";

/**
 * The master square's grid, drawn by the picture box behind a picture made in the square (G 2026-10-14 23:00: "show the
 * grid in the app, it'll help visually"). It uses the picture's own viewBox and fit, so its lines sit exactly under the
 * picture's cells at every size. Pictures not yet made in the square get no grid.
 */
export function PictureGrid({ diagram }: { diagram: DiagramModel | undefined }) {
  if (!diagram || diagram.kind !== "scene" || !diagram.square) return null;
  const { width: w, height: h } = diagram, c = SQUARE.cell;
  return (
    <svg className="o-sqgrid" viewBox={`0 0 ${w} ${h}`} aria-hidden="true">
      <defs><pattern id="o-sqcell" width={c} height={c} patternUnits="userSpaceOnUse"><path d={`M ${c} 0 V ${c} H 0`} /></pattern></defs>
      <rect className="cells" width={w} height={h} fill="url(#o-sqcell)" />
      <rect className="edge" width={w} height={h} />
    </svg>
  );
}
