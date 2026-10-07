import { useLayoutEffect, useRef, useState, type ReactNode } from "react";

/**
 * ListGroup (master): a list's chapter as an accordion (G 2026-10-07). The head row opens and closes it; the rows inside
 * sit with the head in one slightly darker panel (--surf-nest), and the panel grows open and folds shut with the
 * list highlight's speed. While it folds shut its rows stay drawn, then leave. Instances say only what differs: the head
 * (a button with aria-expanded) and the rows.
 */
export function ListGroup({ head, open, className, children }: { head: ReactNode; open: boolean; className?: string; children: ReactNode }) {
  const [keep, setKeep] = useState(open);
  // while it grows open the rows' pill stays hidden, so it fades in once the panel is still
  const [opening, setOpening] = useState(false);
  const [was, setWas] = useState(open);
  if (open !== was) { setWas(open); setOpening(open); }
  if (open && !keep) setKeep(true);
  const body = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    if (open || !keep) return;
    // nothing to wait for when the fold doesn't animate (Less motion, or no styles)
    const el = body.current, t = el ? parseFloat(getComputedStyle(el).transitionDuration) : 0;
    if (!(t > 0.02)) setKeep(false);
  }, [open, keep]);
  useLayoutEffect(() => {
    if (!opening) return;
    const el = body.current, t = el ? parseFloat(getComputedStyle(el).transitionDuration) : 0;
    if (!(t > 0.02)) setOpening(false);
  }, [opening]);
  return (
    <div className={`sgroup${open ? " open" : ""}${opening ? " opening" : ""}${className ? ` ${className}` : ""}`}>
      {head}
      <div className="sgroup-body" ref={body} inert={!open || undefined}
        onTransitionEnd={e => { if (e.target !== e.currentTarget) return; if (open) setOpening(false); else setKeep(false); }}>
        <div className="sgroup-in"><div className="sgroup-panel">{keep && children}</div></div>
      </div>
    </div>
  );
}
