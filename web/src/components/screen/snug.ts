import { useLayoutEffect, type RefObject } from "react";

/**
 * The lesson's picture panel hugs its picture (G 2026-10-06: a big empty band under the rectangle on a phone). When
 * the diagram is limited by the panel's width, the panel gives back the height the picture can't use, so the page
 * keeps the space instead of the inside of the panel. A picture limited by height already fills it and is left alone.
 */
export function useSnugHero(hero: RefObject<HTMLElement | null>, key: unknown) {
  useLayoutEffect(() => {
    const el = hero.current;
    if (!el || typeof ResizeObserver === "undefined") return;
    const fit = () => {
      el.classList.remove("snug");
      const pic = el.querySelector<HTMLElement>(".lpic:not(.flow)"), svg = pic?.querySelector<SVGSVGElement>(":scope>.viz>svg");
      const vb = svg?.viewBox?.baseVal;
      if (!pic || !vb?.width || !vb.height) return;
      const room = pic.clientHeight, want = pic.clientWidth * vb.height / vb.width;
      if (room - want < 24) return;
      el.style.setProperty("--snug-h", `${Math.round(el.offsetHeight - (room - want))}px`);
      el.classList.add("snug");
    };
    fit();
    const ro = new ResizeObserver(fit);
    if (el.parentElement) ro.observe(el.parentElement);
    return () => { ro.disconnect(); el.classList.remove("snug"); };
  }, [hero, key]);
}
