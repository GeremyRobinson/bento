import { useLayoutEffect, useRef, useState } from "react";

/**
 * The pill's own edge is its progress (G 2026-10-06): the outline fills in the grade's colour around the rounded
 * edge, always from the same point, and the rest stays the Panel line. Drawn as a stroke along the pill's own shape,
 * inside its edge, so the radius never cuts it.
 */
export function PillRing({ p }: { p: number }) {
  const ref = useRef<SVGSVGElement>(null);
  const [box, setBox] = useState<[number, number] | null>(null);
  useLayoutEffect(() => {
    const el = ref.current?.parentElement;
    if (!el) return;
    const size = () => setBox(b => (b && b[0] === el.clientWidth && b[1] === el.clientHeight ? b : [el.clientWidth, el.clientHeight]));
    size();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(size);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  const [w, h] = box ?? [0, 0];
  const s = 2, r = Math.max(0, h / 2 - s / 2);
  // one path around the pill, starting at the middle of its left end and going clockwise over the top
  const d = w > h ? `M${s / 2} ${h / 2} A${r} ${r} 0 0 1 ${h / 2} ${s / 2} H${w - h / 2} A${r} ${r} 0 0 1 ${w - h / 2} ${h - s / 2} H${h / 2} A${r} ${r} 0 0 1 ${s / 2} ${h / 2}Z` : "";
  const f = Math.min(1, Math.max(0, p));
  return (
    <svg ref={ref} className="pring" width={w} height={h} viewBox={`0 0 ${w} ${h}`} aria-hidden="true">
      {d && <path className="pring-track" d={d} pathLength={1} />}
      {d && f > 0 && <path className="pring-fill" d={d} pathLength={1} style={{ strokeDasharray: `${f} 1` }} />}
    </svg>
  );
}
