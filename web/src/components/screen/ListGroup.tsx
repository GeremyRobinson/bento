import { useLayoutEffect, useRef, useState, type ReactNode } from "react";

/**
 * ListGroup (master): a list's chapter as an accordion (G 2026-10-07). The head row opens and closes it; the rows inside
 * sit in a slightly darker panel nested under the head (--surf-nest), and the panel grows open and folds shut with the
 * list highlight's speed. While it folds shut its rows stay drawn, then leave. Instances say only what differs: the head
 * (a button with aria-expanded) and the rows.
 */
export function ListGroup({ head, open, className, children }: { head: ReactNode; open: boolean; className?: string; children: ReactNode }) {
  const [keep, setKeep] = useState(open);
  if (open && !keep) setKeep(true);
  const body = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    if (open || !keep) return;
    // nothing to wait for when the fold doesn't animate (Less motion, or no styles)
    const el = body.current, t = el ? parseFloat(getComputedStyle(el).transitionDuration) : 0;
    if (!(t > 0.02)) setKeep(false);
  }, [open, keep]);
  return (
    <div className={`sgroup${open ? " open" : ""}${className ? ` ${className}` : ""}`}>
      {head}
      <div className="sgroup-body" ref={body} inert={!open || undefined}
        onTransitionEnd={e => { if (e.target === e.currentTarget && !open) setKeep(false); }}>
        <div className="sgroup-in"><div className="sgroup-panel">{keep && children}</div></div>
      </div>
    </div>
  );
}

/**
 * The list's picked-row highlight (master, `.sknob` as the list's first child): it glides to the row you pick inside the
 * same group, and when the pick moves to another group it fades across instead of sliding past the rows that are opening
 * and closing. While a group opens or closes it rides with its row. Returns the knob's ref and `place`, for a list that
 * has to settle it again by hand.
 */
export function useListKnob() {
  const knob = useRef<HTMLSpanElement>(null), placed = useRef(false), group = useRef<Element | null>(null);
  const place = (follow = false) => {
    const el = knob.current, list = el?.parentElement, row = list?.querySelector<HTMLElement>(".srow.on");
    if (!el || !list) return;
    if (!row) { el.style.opacity = "0"; placed.current = false; return; }
    const at = row.closest(".sgroup");
    const jump = follow || !placed.current || at !== group.current;
    if (jump) el.style.transition = "none";
    // measured from the list itself: rows inside a nested panel (or mid-motion) aren't offset from the list
    const L = list.getBoundingClientRect(), r = row.getBoundingClientRect();
    // a row in a group that's still opening shows only the part that's out
    const B = row.closest(".sgroup-body")?.getBoundingClientRect();
    const top = B ? Math.max(r.top, B.top) : r.top, bottom = B ? Math.max(top, Math.min(r.bottom, B.bottom)) : r.bottom;
    el.style.transform = `translate(${r.left - L.left - list.clientLeft}px,${top - L.top - list.clientTop + list.scrollTop}px)`;
    el.style.width = `${r.width}px`;
    el.style.height = `${bottom - top}px`;
    if (jump && !follow && placed.current) {
      // to another group: fade across
      el.style.opacity = "0"; void el.offsetHeight; el.style.transition = ""; el.style.opacity = "1";
    } else {
      el.style.opacity = "1";
      if (jump) { void el.offsetHeight; el.style.transition = ""; }
    }
    group.current = at; placed.current = true;
  };
  useLayoutEffect(() => place());
  // while a group grows or folds, the rows under it move: the highlight moves with its row
  useLayoutEffect(() => {
    const list = knob.current?.parentElement;
    if (!list) return;
    let frame = 0, until = 0;
    const tick = () => { place(true); frame = performance.now() < until ? requestAnimationFrame(tick) : 0; };
    const start = (e: Event) => {
      if (!(e.target as Element).classList?.contains("sgroup-body")) return;
      until = performance.now() + 700;
      if (!frame) frame = requestAnimationFrame(tick);
    };
    const end = (e: Event) => { if ((e.target as Element).classList?.contains("sgroup-body")) { until = 0; place(true); } };
    list.addEventListener("transitionrun", start);
    list.addEventListener("transitionend", end);
    return () => { list.removeEventListener("transitionrun", start); list.removeEventListener("transitionend", end); if (frame) cancelAnimationFrame(frame); };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps
  return { knob, place, placed };
}
