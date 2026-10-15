import { useLayoutEffect, useRef, useState, type ReactNode } from "react";
import type { DiagramModel } from "../../explanations/schema";
import { MASTERS, type MasterShape } from "../../explanations/diagrams/scene/picture-system";
import { PictureGrid } from "./PictureGrid";

type Fit = { shape: MasterShape; w: number; h: number };
const SHAPED = ["shaped-stack", "shaped-side"] as const;

/**
 * Picks the master shape for the room a picture has: stacked screens (the picture over the solve panel) use the tallest
 * shape that fills the full width, side-by-side screens the shape that draws biggest (G 2026-10-15, with Design and Assets).
 */
export function pickShape(shapes: MasterShape[], W: number, H: number, stacked: boolean): Fit | null {
  const fits = shapes.map(shape => {
    const r = MASTERS[shape].w / MASTERS[shape].h, w = Math.min(W, H * r);
    return { shape, r, w, h: w / r };
  });
  if (!fits.length) return null;
  const full = fits.filter(f => W / f.r <= H + 0.5).sort((a, b) => a.r - b.r)[0];
  const best = stacked && full ? full : fits.sort((a, b) => b.w * b.h - a.w * a.h)[0]!;
  return { shape: best.shape, w: Math.floor(best.w), h: Math.floor(best.h) };
}

/**
 * The lesson picture's box. A picture drawn in the master shapes (Assets) gets a box of exactly its shape, with the grid
 * under it, and the layout gives the room it doesn't need to the solve panel: on stacked screens the box is full width and
 * as tall as its shape, on side-by-side screens the picture column narrows to it. Any other picture keeps the old box.
 */
export function PictureBox({ diagram, className, render, label }: { diagram: DiagramModel | undefined; className: string; render: (d: DiagramModel | undefined) => ReactNode; label?: string }) {
  const shapes = diagram?.kind === "scene" && diagram.shapes ? diagram.shapes : null;
  const ref = useRef<HTMLDivElement>(null);
  const [fit, setFit] = useState<Fit | null>(null);
  useLayoutEffect(() => {
    const art = ref.current, state = art?.closest<HTMLElement>(".o-state"), stage = art?.closest<HTMLElement>(".v-stage");
    if (!shapes || !art || !state || !stage) return;
    const keys = (Object.keys(shapes) as MasterShape[]).filter(k => shapes[k]);
    const clear = () => { state.classList.remove(...SHAPED); state.style.removeProperty("--o-pic-h"); state.style.removeProperty("--o-stage-w"); };
    const measure = () => {
      // measure the room with the layout as it is without a shape, then size the layout to the shape picked
      clear();
      const room = art.getBoundingClientRect(), st = stage.getBoundingClientRect(), solve = state.querySelector(".v-solve")?.getBoundingClientRect();
      if (!(room.width > 0 && room.height > 0)) return;
      const stacked = !!solve && solve.top >= st.bottom - 1;
      const f = pickShape(keys, room.width, room.height, stacked);
      if (!f) return;
      if (stacked) { state.style.setProperty("--o-pic-h", `${f.h}px`); state.classList.add("shaped-stack"); }
      else if (f.w < room.width - 1) { state.style.setProperty("--o-stage-w", `${Math.ceil(st.width - (room.width - f.w))}px`); state.classList.add("shaped-side"); }
      setFit(old => (old && old.shape === f.shape && old.w === f.w && old.h === f.h ? old : f));
    };
    measure();
    const ro = typeof ResizeObserver === "undefined" ? null : new ResizeObserver(measure);
    ro?.observe(state);
    return () => { ro?.disconnect(); clear(); };
  }, [shapes]);
  if (!shapes) return <div className={className} aria-label={label} role={label ? "img" : undefined}><div className="viz">{render(diagram)}</div></div>;
  const d = fit ? shapes[fit.shape] : undefined;
  return (
    <div ref={ref} className={`${className} shaped`} aria-label={label} role={label ? "img" : undefined}>
      {fit && d && <div className="o-sqbox" data-shape={fit.shape} style={{ width: fit.w, height: fit.h }}><div className="viz"><PictureGrid diagram={d} />{render(d)}</div></div>}
    </div>
  );
}
