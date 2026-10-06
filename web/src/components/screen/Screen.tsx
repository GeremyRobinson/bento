import type { ReactNode } from "react";

/**
 * Screen (master): the frame every app screen sits in, under the island. Instances only say what differs:
 * `split` for a list beside its detail (on a phone, one at a time), `fit` for a screen that must fit without the
 * page scrolling. Only a list or a sheet may scroll inside itself (Design, handoff 5).
 */
export function SplitScreen({ list, detail, show, label }: { list: ReactNode; detail: ReactNode; show: "list" | "detail"; label: string }) {
  return (
    <div className={`screen split show-${show}`}>
      <nav className="slist" aria-label={label}>{list}</nav>
      <section className="sdetail">{detail}</section>
    </div>
  );
}

export function FitScreen({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={`screen fit${className ? ` ${className}` : ""}`}>{children}</div>;
}
