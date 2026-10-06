// The parts every Bento² picture is made of: a live SVG over its sliders and readouts, dragging in picture
// coordinates, a clock for pictures that play, and the save row a project ends with. Pictures are drawn from numbers
// the learner can drag; nothing here is a still image.
import { useEffect, useRef, useState, type ReactNode, type PointerEvent as RPointerEvent } from "react";
import { reduceMotion } from "../../app/transition";

/** A picture's frame: the SVG fills what's left, sliders and readouts sit under it in HTML (so their words stay ≥ 12px). */
export function Scene({ svg, controls, readouts, className, foot }: { svg: ReactNode; controls?: ReactNode; readouts?: ReactNode; className?: string; foot?: ReactNode }) {
  return (
    <div className={`b2scene${className ? ` ${className}` : ""}`}>
      <div className="b2svg">{svg}</div>
      {controls && <div className="b2ctl">{controls}</div>}
      {readouts && <div className="b2read">{readouts}</div>}
      {foot}
    </div>
  );
}

/** A labelled slider. `marks` are friendly values the thumb can snap to by tapping them. */
export function Slider({ label, value, min, max, step, onChange, format, marks, disabled }: {
  label: string; value: number; min: number; max: number; step: number; onChange: (v: number) => void;
  format?: (v: number) => string; marks?: { v: number; label: string }[]; disabled?: boolean;
}) {
  const shown = format ? format(value) : String(value);
  return (
    <label className="b2slider">
      <span className="b2sl"><span>{label}</span><b>{shown}</b></span>
      <input type="range" min={min} max={max} step={step} value={value} disabled={disabled} aria-valuetext={shown}
        onChange={e => onChange(Number(e.currentTarget.value))} />
      {marks && (
        <span className="b2marks">
          {marks.map(m => (
            <button type="button" key={m.label} disabled={disabled} className={Math.abs(m.v - value) < step / 2 ? "on" : undefined}
              onClick={e => { e.preventDefault(); onChange(m.v); }}>{m.label}</button>
          ))}
        </span>
      )}
    </label>
  );
}

/** A readout: a name and its live value. `tone` colours the value like its part of the picture. */
export function Read({ label, value, tone, big }: { label: ReactNode; value: ReactNode; tone?: string; big?: boolean }) {
  return <span className={`b2r${big ? " big" : ""}`}><small>{label}</small><b className={tone ? `tone-${tone}` : undefined}>{value}</b></span>;
}

/** A two-way switch inside a picture ("Lab view" / "Muon's view"). */
export function Toggle<T extends string>({ value, options, onChange, label }: { value: T; options: { v: T; label: string }[]; onChange: (v: T) => void; label: string }) {
  return (
    <span className="b2toggle" role="group" aria-label={label}>
      {options.map(o => <button type="button" key={o.v} aria-pressed={o.v === value} onClick={() => onChange(o.v)}>{o.label}</button>)}
    </span>
  );
}

/** Pointer positions in the SVG's own coordinates, for dragging points of the picture. */
export function useSvgDrag() {
  const ref = useRef<SVGSVGElement>(null);
  const toSvg = (cx: number, cy: number): { x: number; y: number } | null => {
    const svg = ref.current;
    const m = svg?.getScreenCTM?.();
    if (!svg || !m || !svg.createSVGPoint) return null;
    const pt = svg.createSVGPoint();
    pt.x = cx; pt.y = cy;
    const p = pt.matrixTransform(m.inverse());
    return { x: p.x, y: p.y };
  };
  /** handlers for a draggable piece: it follows the finger until it lifts */
  const drag = (onMove: (x: number, y: number) => void) => ({
    onPointerDown: (e: RPointerEvent<SVGElement>) => {
      e.preventDefault();
      (e.currentTarget as Element).setPointerCapture?.(e.pointerId);
      const p = toSvg(e.clientX, e.clientY);
      if (p) onMove(p.x, p.y);
    },
    onPointerMove: (e: RPointerEvent<SVGElement>) => {
      if (!(e.currentTarget as Element).hasPointerCapture?.(e.pointerId)) return;
      const p = toSvg(e.clientX, e.clientY);
      if (p) onMove(p.x, p.y);
    },
  });
  return { ref, drag };
}

/**
 * Seconds since the picture started playing, every frame. With Less motion (or not playing) it holds `still`, so the
 * picture shows its finished state and loses nothing.
 */
export function useClock(play: boolean, still: number): number {
  const [t, setT] = useState(still);
  const off = reduceMotion();
  useEffect(() => {
    if (!play || off) { setT(still); return; }
    let raf = 0;
    const t0 = performance.now();
    const tick = (now: number) => { setT((now - t0) / 1000); raf = requestAnimationFrame(tick); };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [play, off, still]);
  return t;
}

/** A value that eases toward its target (a reveal sweeping a line up). Less motion jumps straight there. */
export function useTween(target: number, ms = 1400): number {
  const [v, setV] = useState(target);
  const from = useRef(target);
  useEffect(() => {
    if (reduceMotion()) { setV(target); from.current = target; return; }
    const a = from.current, t0 = performance.now();
    let raf = 0;
    const step = (now: number) => {
      const k = Math.min(1, (now - t0) / ms), e = k < 0.5 ? 4 * k ** 3 : 1 - (-2 * k + 2) ** 3 / 2;
      const x = a + (target - a) * e;
      setV(x); from.current = x;
      if (k < 1) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [target, ms]);
  return v;
}

/** Numbers as pictures show them: a real minus sign, a fixed number of places. */
export const fx = (x: number, places = 2) => (x < 0 && Math.abs(x) >= 0.5 * 10 ** -places ? "−" : "") + Math.abs(x).toFixed(places);

/** SVG path through points */
export const path = (pts: [number, number][]) => pts.map(([x, y], i) => `${i ? "L" : "M"}${x.toFixed(1)},${y.toFixed(1)}`).join(" ");

/** An arrow head at (x2, y2) pointing away from (x1, y1). */
export function ArrowHead({ x1, y1, x2, y2, className }: { x1: number; y1: number; x2: number; y2: number; className?: string }) {
  const a = Math.atan2(y2 - y1, x2 - x1), h = 8;
  const hx = x2 - h * Math.cos(a), hy = y2 - h * Math.sin(a);
  return <path className={className} d={`M${x2},${y2} L${hx - 4 * Math.sin(a)},${hy + 4 * Math.cos(a)} L${hx + 4 * Math.sin(a)},${hy - 4 * Math.cos(a)} Z`} />;
}

/** The row a project ends with: what it saves, and the button that keeps it (on the shelf and in the Notebook). */
export function SaveRow({ what, saved, onSave }: { what: ReactNode; saved: boolean; onSave: () => void }) {
  return (
    <div className="b2save">
      <span>{what}</span>
      <button type="button" className={`ctl${saved ? "" : " go"}`} onClick={onSave} aria-pressed={saved}>{saved ? "Saved ✓" : "Save"}</button>
    </div>
  );
}
