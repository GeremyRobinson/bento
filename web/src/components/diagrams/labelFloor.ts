import { useLayoutEffect, useRef } from "react";
import { layoutRect } from "../../app/transition";

/**
 * Keeps picture labels readable when an SVG shrinks (phones): sets `--px`, the drawing's units per screen pixel,
 * so the CSS can hold every label at 12px or more on screen (Design handoff 3).
 * `height` is the drawing's height: a frame that only grows taller (a short box's labels) changes the scale too, so it
 * sets --px again (Review 1c74c20: text read 13.4px in a 280×123 box when it was left from the frame before) */
export function useLabelFloor<T extends SVGSVGElement>(width: number, onBox?: (w: number, h: number) => void, height?: number) {
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
      // the box on screen, for a picture that lays itself out from it (the area model settles its own scale from this)
      onBox?.(r.width, r.height);
    };
    set();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(set);
    ro.observe(el);
    return () => ro.disconnect();
  }, [width, onBox, height]);
  return ref;
}
