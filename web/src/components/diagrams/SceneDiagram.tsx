import { useLayoutEffect, useState, type CSSProperties } from "react";
import type { SceneDiagram as Scene, SceneItem } from "../../explanations/diagrams/scene/schema";
import { useLabelFloor } from "./labelFloor";
import { layoutRect } from "../../app/transition";

const enterClass = (e: SceneItem["enter"]) => (e ? e.split(" ").map((w, i) => (i ? w : `a-${w}`)).join(" ") : "");

/**
 * Draws a scene exactly as its model says. A shape is drawn once the timeline reaches its beat
 * (and until its last beat); it plays its entrance when it first appears.
 */
export function SceneDiagram({ diagram: d, at, fit = false }: { diagram: Scene; at: number; fit?: boolean }) {
  const [frame, setFrame] = useState<{ d: Scene; box: Box; size: [number, number]; text: Record<string, number>; panel: boolean } | null>(null);
  const fitted = fit && frame?.d === d;
  const vb = fitted ? framed(frame.box, frame.size) : { x: 0, y: 0, w: d.width, h: d.height };
  const zoom = fitted ? Math.min(frame.size[0] / vb.w, frame.size[1] / vb.h) : 1;
  const ref = useLabelFloor(vb.w);
  // fit: frame the finished picture (every beat drawn) instead of the builder's canvas, so it fills the room it gets
  useLayoutEffect(() => {
    const el = ref.current;
    if (!fit || !el) return;
    const box = contentBox(el, d.items);
    if (!box) return;
    const text = textTokens(el.parentElement ?? el);
    // in the lesson's picture panel the picture takes the whole panel and frames itself inside it (the viewBox below)
    // and the room it gets is its holder's box, measured before it first fills it, so the first frame is already right
    const panel = !!el.closest(PANEL), room = panel && el.parentElement ? el.parentElement : el;
    const measure = () => { const r = layoutRect(room); if (r.width > 0 && r.height > 0) setFrame({ d, box, size: [r.width, r.height], text, panel }); };
    measure();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(measure);
    ro.observe(room);
    return () => ro.disconnect();
  }, [d, fit, ref]);
  // fit centres the finished picture once (the frame above); parts then appear where they stay, and nothing already
  // drawn moves between beats (G 19:34: "random coming from the side animations")
  return (
    <svg ref={ref} className={d.two ? "viz-svg two" : "viz-svg"} viewBox={`${r1(vb.x)} ${r1(vb.y)} ${r1(vb.w)} ${r1(vb.h)}`} role="img" aria-label={d.alt}
      style={{ "--w": Math.round(d.width), "--h": Math.round(d.height), ...(fitted ? textHold(zoom, frame.text) : {}), ...(fitted && frame.panel ? FILL : {}) } as CSSProperties} data-family={d.family}>
      {dotsOnTop(d.items).map((it, i, all) => {
        const from = it.from ?? 0;
        if (from > at || (it.until != null && at > it.until)) return null;
        const cls = [it.cls ?? "", continues(it, all) ? "" : enterClass(it.enter)].join(" ").trim();
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

/** The same shape drawn again from the very next beat (a re-cut bar's unchanged parts, a label that stays the same) just
 * stays put: replaying its entrance makes the picture blink out and rebuild (G 2026-10-08 "loading animation glitch"). */
const look = ({ from: _f, until: _u, enter: _e, delay: _d, ...rest }: SceneItem) => JSON.stringify(rest);
const continues = (it: SceneItem, all: SceneItem[]) => {
  const from = it.from ?? 0;
  if (!from || !it.enter) return false;
  const me = look(it);
  return all.some(o => o !== it && (o.from ?? 0) < from && o.until === from - 1 && look(o) === me);
};

interface Box { x: number; y: number; w: number; h: number }
const r1 = (v: number) => Math.round(v * 10) / 10;
/**
 * A fitted picture grows to its box, but never past this many screen pixels per drawing unit. Scene pictures are drawn
 * in small units (a digit card is 52), so the old cap of 1.8 left them a small island in a big panel (Review g5 #11:
 * the live site drew the same pictures 1.5 to 2 times bigger). Shapes may now grow to 3; text stops at TEXT_ZOOM.
 */
const MAX_ZOOM = 3;
/** past this zoom the picture's text stops growing with its shapes, so labels stay label-sized, never shouting */
const TEXT_ZOOM = 1.5;
/** the lesson's picture panel (Watch one, practice, the skill check): a fitted picture there fills it, held only by MAX_ZOOM */
const PANEL = ".v-ppic";
/** the whole panel: the old width rule (the drawing's own width times 1.15, 400px tall at most) kept every scene small */
const FILL = { width: "100%", height: "100%", maxWidth: "none" } as const;
/** the picture text sizes (tokens.css, diagram-master.css) that are held at TEXT_ZOOM on a big picture */
const TEXT_TOKENS = ["--pic-label", "--d-text", "--d-text-sm", "--d-text-xs", "--d-text-lg", "--d-text-xl"] as const;
/** the big digits written inside a part (a digit card, a column) keep in step with their part a little longer */
const DIGIT_ZOOM = 2.2;

/** The text tokens scaled down so they read no bigger on screen than at TEXT_ZOOM (empty when the zoom is below it). */
function textHold(zoom: number, base: Record<string, number>): Record<string, string> {
  if (!(zoom > TEXT_ZOOM)) return {};
  return Object.fromEntries(Object.entries(base).map(([name, v]) => {
    const cap = name === "--d-text-xl" ? DIGIT_ZOOM : TEXT_ZOOM;
    return [name, `${r1(v * Math.min(1, cap / zoom))}px`];
  }));
}

/** The text tokens' values where the picture sits (read off the page, so the tokens stay the one source). */
function textTokens(el: Element): Record<string, number> {
  const cs = getComputedStyle(el), out: Record<string, number> = {};
  for (const name of TEXT_TOKENS) {
    const v = parseFloat(cs.getPropertyValue(name));
    if (Number.isFinite(v) && v > 0) out[name] = v;
  }
  return out;
}

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
  // measured at the drawing's own text sizes: with the phone floor (--px) in, a small picture's labels measured huge,
  // the frame widened for them, the picture shrank and the floor grew them again (pow10 on a phone: tiny cards)
  const px = svg.style.getPropertyValue("--px");
  svg.style.setProperty("--px", "0");
  try {
    const b = g.getBBox();
    return b.width > 0 && b.height > 0 ? { x: b.x, y: b.y, w: b.width, h: b.height } : null;
  } catch {
    return null;
  } finally {
    svg.removeChild(g);
    if (px) svg.style.setProperty("--px", px); else svg.style.removeProperty("--px");
  }
}

/** The content with a little air round it, widened where filling the box would blow it up past MAX_ZOOM. */
function framed(b: Box, [W, H]: [number, number]): Box {
  const pad = Math.max(4, 0.02 * Math.max(b.w, b.h));
  const w = Math.max(b.w + 2 * pad, W / MAX_ZOOM), h = Math.max(b.h + 2 * pad, H / MAX_ZOOM);
  return { x: b.x + b.w / 2 - w / 2, y: b.y + b.h / 2 - h / 2, w, h };
}
