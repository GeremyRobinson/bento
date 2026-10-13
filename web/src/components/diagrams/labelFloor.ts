import { useLayoutEffect, useRef } from "react";
import { layoutRect } from "../../app/transition";

/**
 * Keeps picture labels readable when an SVG shrinks (phones): sets `--px`, the drawing's units per screen pixel,
 * so the CSS can hold every label at 12px or more on screen (Design handoff 3).
 */
export function useLabelFloor<T extends SVGSVGElement>(width: number, onPx?: (px: number, room: number) => void) {
  const ref = useRef<T>(null);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    // a picture held by its height (a fixed slot) draws smaller than its width says, so take whichever side binds
    const set = () => {
      const r = layoutRect(el), vb = el.viewBox?.baseVal;
      if (r.width <= 0) return;
      const px = Math.max(width / r.width, vb && vb.height > 0 && r.height > 0 ? vb.height / r.height : 0);
      el.style.setProperty("--px", px.toFixed(3));
      // room: how many units wide the picture could be at this scale before its width binds
      onPx?.(px, r.width * px);
    };
    set();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(set);
    ro.observe(el);
    return () => ro.disconnect();
  }, [width, onPx]);
  return ref;
}
