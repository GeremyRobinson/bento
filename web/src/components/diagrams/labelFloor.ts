import { useLayoutEffect, useRef } from "react";

/**
 * Keeps picture labels readable when an SVG shrinks (phones): sets `--px`, the drawing's units per screen pixel,
 * so the CSS can hold every label at 12px or more on screen (Design handoff 3).
 */
export function useLabelFloor<T extends SVGSVGElement>(width: number) {
  const ref = useRef<T>(null);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    // a picture held by its height (a fixed slot) draws smaller than its width says, so take whichever side binds
    const set = () => {
      const r = el.getBoundingClientRect(), vb = el.viewBox?.baseVal;
      if (r.width <= 0) return;
      const px = Math.max(width / r.width, vb && vb.height > 0 && r.height > 0 ? vb.height / r.height : 0);
      el.style.setProperty("--px", px.toFixed(3));
    };
    set();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(set);
    ro.observe(el);
    return () => ro.disconnect();
  }, [width]);
  return ref;
}
