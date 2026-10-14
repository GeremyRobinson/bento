import { useLayoutEffect, useState, type CSSProperties } from "react";
import type { SceneDiagram as Scene, SceneItem } from "../../explanations/diagrams/scene/schema";
import { useLabelFloor } from "./labelFloor";
import { layoutRect } from "../../app/transition";

const enterClass = (e: SceneItem["enter"]) => (e ? e.split(" ").map((w, i) => (i ? w : `a-${w}`)).join(" ") : "");

/**
 * Draws a scene exactly as its model says. A shape is drawn once the timeline reaches its beat
 * (and until its last beat); it plays its entrance when it first appears.
 */
export function SceneDiagram({ diagram: given, at, fit = false }: { diagram: Scene; at: number; fit?: boolean }) {
  // a picture with other arrangements draws the one that is biggest in its box (picked when the box is measured)
  const [picked, setPicked] = useState(0);
  const d = (fit && picked && given.layouts?.[picked - 1]) || given;
  const [frame, setFrame] = useState<{ d: Scene; box: Box; size: [number, number]; text: Record<string, number>; panel: boolean } | null>(null);
  const fitted = fit && frame?.d === d;
  const vb = fitted ? framed(frame.box, frame.size) : { x: 0, y: 0, w: d.width, h: d.height };
  const zoom = fitted ? Math.min(frame.size[0] / vb.w, frame.size[1] / vb.h) : 1;
  const ref = useLabelFloor(vb.w, undefined, vb.h);
  // fit: frame the finished picture (every beat drawn) instead of the builder's canvas, so it fills the room it gets
  useLayoutEffect(() => {
    const el = ref.current;
    if (!fit || !el) return;
    const text = textTokens(el.parentElement ?? el);
    // in the lesson's picture panel the picture takes the whole panel and frames itself inside it (the viewBox below)
    // and the room it gets is its holder's box, measured before it first fills it, so the first frame is already right
    const panel = !!el.closest(PANEL), room = panel && el.parentElement ? el.parentElement : el;
    const measure = () => {
      const r = layoutRect(room);
      if (!(r.width > 0 && r.height > 0)) return;
      const best = biggest(given, r.width, r.height);
      if (best !== picked) { setPicked(best); return; }
      // the box's height goes to the picture's CSS before it is measured (see BOX_H), so a picture that lays itself
      // out more compactly in a short box is framed as it draws there
      el.style.setProperty("--box-h", String(Math.round(r.height)));
      const box0 = contentBox(el, d.items, 0);
      if (box0) setFrame({ d, box: floorBox(el, d.items, box0, [r.width, r.height], d.grow ?? GROW), size: [r.width, r.height], text, panel });
    };
    measure();
    // the frame is the text measured at its own size, so text measured in the fallback font (a cold first load, before
    // Inter is in) frames the picture too wide and it stays that way: measure again once the fonts are in
    // (Review 4746e11: polyd framed 667.8 wide on a first load, 374.5 after)
    let alive = true;
    const again = () => { if (alive) measure(); };
    const fonts = typeof document !== "undefined" ? document.fonts : undefined;
    fonts?.ready.then(again);
    fonts?.addEventListener?.("loadingdone", again);
    const ro = typeof ResizeObserver === "undefined" ? null : new ResizeObserver(measure);
    ro?.observe(room);
    return () => { alive = false; fonts?.removeEventListener?.("loadingdone", again); ro?.disconnect(); };
  }, [d, given, picked, fit, ref]);
  // fit centres the finished picture once (the frame above); parts then appear where they stay, and nothing already
  // drawn moves between beats (G 19:34: "random coming from the side animations")
  return (
    <svg ref={ref} className={d.two ? "viz-svg two" : "viz-svg"} viewBox={`${r1(vb.x)} ${r1(vb.y)} ${r1(vb.w)} ${r1(vb.h)}`} role="img" aria-label={d.alt}
      style={{ "--w": Math.round(d.width), "--h": Math.round(d.height), ...(fitted ? { [BOX_H]: Math.round(frame.size[1]) } : {}), ...(fitted ? textHold(zoom, frame.text) : {}), ...(fitted && frame.panel ? FILL : {}) } as CSSProperties} data-family={d.family}>
      {/* a second amount is the same colour in stripes (style guide rule 5) */}
      {d.two && <defs><pattern id="pic-stripe" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect className="stripe-bg" width="8" height="8" /><rect className="stripe" width="3.5" height="8" /></pattern></defs>}
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
/** boxes this tall or less are short (phones; the same line as --short in the picture CSS) */
const SHORT_BOX = 300;

/** Of a picture and its other arrangements, the one that covers most of a w × h box (0: the picture itself, k: its k-th
 *  other layout), keeping the first one unless another is clearly bigger, so a box near the turning point doesn't flip */
function biggest(d: Scene, w: number, h: number): number {
  // a short box (a phone) holds its text at the label floor, which needs the room beside the bars: it keeps the first one
  if (h <= SHORT_BOX) return 0;
  const scale = (s: Scene) => Math.min(w / s.width, h / s.height) ** 2 * s.width * s.height;
  let best = 0;
  (d.layouts ?? []).forEach((o, i) => { if (scale(o) > scale(best ? d.layouts![best - 1]! : d) * 1.08) best = i + 1; });
  return best;
}
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

/**
 * The frame for a small box: when the picture draws smaller than its own size, its text is held at the phone floor (--px)
 * and takes more of the drawing, so the frame is measured again with the text at that size until it settles. The text
 * keeps its screen size and the shapes get the room that is left, so no label is ever cut by the box's edge
 * (Review g5 re-walk blocker 2). A few rounds settle it; the frame never shrinks below the plain one.
 */
function floorBox(svg: SVGSVGElement, items: SceneItem[], box0: Box, size: [number, number], grow: number): Box {
  let box = box0;
  for (let k = 0; k < 6; k++) {
    const f = framed(box, size), zoom = Math.min(size[0] / f.w, size[1] / f.h);
    if (zoom >= 1) return box;
    const next = contentBox(svg, items, 1 / zoom);
    if (!next) return box;
    // text that alone outgrows the box (a column of big digits in a short strip) would chase its own growth and shrink
    // the shapes to nothing, so the frame never grows past GROW times the plain one: past that the text overlaps a
    // little instead of the picture vanishing
    const grown = cap(union(box0, next), box0, grow);
    if (Math.abs(grown.w - box.w) < 0.5 && Math.abs(grown.h - box.h) < 0.5) return grown;
    box = grown;
  }
  return box;
}
const GROW = 1.5;
/**
 * The fitted box's height in screen px, as the CSS number --box-h (unset outside a fitted picture). A picture whose
 * working is a tall stack reads it through --short (styles/picture-system.css: 1 in a phone's short box, else 0) to
 * draw the stack as one line that each step rewrites, since five rows can't stand in a 160px box at the label floor.
 * It is the box's size, not the zoom, so the choice is the same however the frame settles.
 */
const BOX_H = "--box-h";
const cap = (b: Box, b0: Box, grow: number): Box => {
  const w = Math.min(b.w, b0.w * grow), h = Math.min(b.h, b0.h * grow);
  // keep the plain frame centred in the capped one, but never show empty room on a side the text didn't grow into
  // (labels that hang down grow the picture downwards only)
  const fit = (c: number, lo: number, hi: number) => Math.min(Math.max(c, lo), hi);
  return {
    x: b.w > w ? fit(b0.x - (w - b0.w) / 2, b.x, b.x + b.w - w) : b.x,
    y: b.h > h ? fit(b0.y - (h - b0.h) / 2, b.y, b.y + b.h - h) : b.y,
    w, h,
  };
};
const union = (a: Box, b: Box): Box => {
  const x = Math.min(a.x, b.x), y = Math.min(a.y, b.y);
  return { x, y, w: Math.max(a.x + a.w, b.x + b.w) - x, h: Math.max(a.y + a.h, b.y + b.h) - y };
};

function contentBox(svg: SVGSVGElement, items: SceneItem[], atPx: number): Box | null {
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
    // its own style too (a line moved down by the rows above it, growDown), so it is measured where it is drawn
    if (it.vars) for (const [k, v] of Object.entries(it.vars)) e.style.setProperty(k.replace(/[A-Z]/g, m => `-${m.toLowerCase()}`), String(v));
    g.appendChild(e);
  }
  svg.appendChild(g);
  // measured at the text size asked for (atPx: 0 is the drawing's own sizes; floorBox asks for the phone floor at the
  // zoom it will draw at, and settles in a few rounds instead of chasing its own growth)
  const px = svg.style.getPropertyValue("--px");
  svg.style.setProperty("--px", String(atPx));
  try {
    // each part where it is drawn: its own CSS move (a label spread off its row on a phone, spreadRows) is not in a
    // group's bounding box, so it is added here
    let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
    for (const e of Array.from(g.children) as SVGGraphicsElement[]) {
      const cs = getComputedStyle(e);
      if (cs.display === "none") continue;
      // a part that is gone in this box (.shortgo in a phone's short box) takes no room
      if (+cs.fillOpacity === 0 && (+cs.strokeOpacity === 0 || cs.stroke === "none")) continue;
      const b = e.getBBox();
      if (!(b.width > 0 || b.height > 0)) continue;
      const m = cs.transform && cs.transform !== "none" ? new DOMMatrix(cs.transform) : null;
      // and its own translate (a line moved into the first line's place in a short box, shortUp)
      const [tx = 0, ty = 0] = cs.translate && cs.translate !== "none" ? cs.translate.split(" ").map(v => parseFloat(v) || 0) : [];
      const dx = (m?.e ?? 0) + tx, dy = (m?.f ?? 0) + ty;
      x0 = Math.min(x0, b.x + dx); y0 = Math.min(y0, b.y + dy); x1 = Math.max(x1, b.x + b.width + dx); y1 = Math.max(y1, b.y + b.height + dy);
    }
    return x1 > x0 && y1 > y0 ? { x: x0, y: y0, w: x1 - x0, h: y1 - y0 } : null;
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
