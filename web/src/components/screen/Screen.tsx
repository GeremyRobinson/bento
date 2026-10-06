import { useLayoutEffect, useRef, useState, type ReactNode } from "react";

/**
 * Screen (master): the frame every app screen sits in, under the island. Instances only say what differs:
 * `split` for a list beside its detail (on a phone, one at a time), `fit` for a screen that must fit without the
 * page scrolling. Only a list or a sheet may scroll inside itself (Design, handoff 5).
 */
export function SplitScreen({ list, detail, show, label, className, detailLabel }: { list: ReactNode; detail: ReactNode; show: "list" | "detail"; label: string; className?: string; /** id of the detail's heading */ detailLabel?: string }) {
  // a list taller than its pane fades out at the bottom while more waits below (Review v39 item 12)
  const nav = useRef<HTMLElement>(null);
  const [more, setMore] = useState(false);
  const check = () => { const n = nav.current; if (n) setMore(n.scrollHeight - n.scrollTop - n.clientHeight > 4); };
  useLayoutEffect(() => {
    check();
    if (typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(check);
    if (nav.current) { ro.observe(nav.current); for (const c of nav.current.children) ro.observe(c); }
    return () => ro.disconnect();
  });
  return (
    <div className={`screen split show-${show}${className ? ` ${className}` : ""}`}>
      <nav className={`slist${more ? " more" : ""}`} aria-label={label} ref={nav} onScroll={check}>{list}</nav>
      <section className="sdetail" aria-labelledby={detailLabel}>{detail}</section>
    </div>
  );
}

export function FitScreen({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={`screen fit${className ? ` ${className}` : ""}`}>{children}</div>;
}
