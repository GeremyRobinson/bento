import { useLayoutEffect, useState, type CSSProperties } from "react";
import type { SceneDiagram as Scene, SceneItem } from "../../explanations/diagrams/scene/schema";
import { useLabelFloor } from "./labelFloor";

const enterClass = (e: SceneItem["enter"]) => (e ? e.split(" ").map((w, i) => (i ? w : `a-${w}`)).join(" ") : "");

/**
 * Draws a scene exactly as its model says. A shape is drawn once the timeline reaches its beat
 * (and until its last beat); it plays its entrance when it first appears.
 */
export function SceneDiagram({ diagram: d, at, fit = false }: { diagram: Scene; at: number; fit?: boolean }) {
  const [frame, setFrame] = useState<{ d: Scene; box: Box; size: [number, number] } | null>(null);
  const vb = fit && frame?.d === d ? framed(frame.box, frame.size) : { x: 0, y: 0, w: d.width, h: d.height };
  const ref = useLabelFloor(vb.w);
  // fit: frame the finished picture (every beat drawn) instead of the builder's canvas, so it fills the room it gets
  useLayoutEffect(() => {
    const el = ref.current;
    if (!fit || !el) return;
    const box = contentBox(el, d.items);
    if (!box) return;
    const measure = () => { const r = el.getBoundingClientRect(); setFrame({ d, box, size: [r.width, r.height] }); };
    measure();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
  }, [d, fit, ref]);
  return (
    <svg ref={ref} className="viz-svg" viewBox={`${r1(vb.x)} ${r1(vb.y)} ${r1(vb.w)} ${r1(vb.h)}`} role="img" aria-label={d.alt}
      style={{ "--w": Math.round(d.width), "--h": Math.round(d.height) } as CSSProperties} data-family={d.family}>
      {dotsOnTop(d.items).map((it, i) => {
        const from = it.from ?? 0;
        if (from > at || (it.until != null && at > it.until)) return null;
        const cls = [it.cls ?? "", enterClass(it.enter)].join(" ").trim();
        const style = { "--d": `${(it.delay ?? 0).toFixed(2)}s`, ...it.vars } as CSSProperties;
        const key = `${i}-${from}`;
        switch (it.type) {
          case "rect": return <rect key={key} className={cls} style={style} x={it.x} y={it.y} width={it.w} height={it.h} rx={it.rx} />;
          case "line": return <line key={key} className={cls} style={style} x1={it.x1} y1={it.y1} x2={it.x2} y2={it.y2} pathLength={1} />;
          // a circle that is drawn in needs pathLength 1 too, or "draw" (a dash array of 1) leaves a ring of tiny dashes
          // that reads as a ridged rim; other circles keep real lengths so dashed outlines stay dashed
          case "circle": return <circle key={key} className={cls} style={style} cx={it.cx} cy={it.cy} r={it.r} {...(it.enter?.startsWith("draw") ? { pathLength: 1 } : {})} />;
          case "path": return <path key={key} className={cls} style={style} d={it.d} pathLength={1} />;
          case "polygon": return <polygon key={key} className={cls} style={style} points={it.points.map(p => p.join(",")).join(" ")} />;
          case "text": return <text key={key} className={cls} style={style} x={it.x} y={it.y}>{it.text}{it.sup && <tspan dy="-0.5em" fontSize="0.65em">{it.sup}</tspan>}</text>;
        }
      })}
    </svg>
  );
}

interface Box { x: number; y: number; w: number; h: number }
const r1 = (v: number) => Math.round(v * 10) / 10;
/** a fitted picture grows to its box, but never past this many screen pixels per drawing unit */
const MAX_ZOOM = 1.8;

/** The bounds of every shape in the scene, measured off screen with the picture's own styles (null where SVG can't measure). */
const isDot = (it: SceneItem) => it.type === "circle" && /\bdot[pa]\b/.test(it.cls ?? "");
/** Point dots draw over every line, tick and hop that meets them, in every family (G 2026-10-06: no line showing through a dot). */
export const dotsOnTop = (items: SceneItem[]): SceneItem[] => [...items.filter(i => !isDot(i)), ...items.filter(isDot)];

function contentBox(svg: SVGSVGElement, items: SceneItem[]): Box | null {
  const ns = "http://www.w3.org/2000/svg";
  const g = document.createElementNS(ns, "g") as SVGGElement;
  if (typeof g.getBBox !== "function") return null;
  g.setAttribute("visibility", "hidden");
  for (const it of items) {
    const e = document.createElementNS(ns, it.type);
    if (it.cls) e.setAttribute("class", it.cls);
    const attrs: Record<string, number | string | undefined> =
      it.type === "rect" ? { x: it.x, y: it.y, width: it.w, height: it.h } :
      it.type === "line" ? { x1: it.x1, y1: it.y1, x2: it.x2, y2: it.y2 } :
      it.type === "circle" ? { cx: it.cx, cy: it.cy, r: it.r } :
      it.type === "path" ? { d: it.d } :
      it.type === "polygon" ? { points: it.points.map(p => p.join(",")).join(" ") } :
      { x: it.x, y: it.y };
    for (const [k, v] of Object.entries(attrs)) if (v != null) e.setAttribute(k, String(v));
    if (it.type === "text") e.textContent = it.text + (it.sup ?? "");
    g.appendChild(e);
  }
  svg.appendChild(g);
  try {
    const b = g.getBBox();
    return b.width > 0 && b.height > 0 ? { x: b.x, y: b.y, w: b.width, h: b.height } : null;
  } catch {
    return null;
  } finally {
    svg.removeChild(g);
  }
}

/** The content with a little air round it, widened where filling the box would blow it up past MAX_ZOOM. */
function framed(b: Box, [W, H]: [number, number]): Box {
  const pad = Math.max(8, 0.04 * Math.max(b.w, b.h));
  const w = Math.max(b.w + 2 * pad, W / MAX_ZOOM), h = Math.max(b.h + 2 * pad, H / MAX_ZOOM);
  return { x: b.x + b.w / 2 - w / 2, y: b.y + b.h / 2 - h / 2, w, h };
}
