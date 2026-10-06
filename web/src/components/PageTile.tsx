import type { ReactNode } from "react";

/** A switch row: its name and a line on what it does, with the switch on the right. */
export function Toggle({ label, note, on, set }: { label: string; note: string; on: boolean; set: (v: boolean) => void }) {
  return (
    <button className="mtoggle" role="switch" aria-checked={on} onClick={() => set(!on)}>
      <span className="mt-text"><b>{label}</b><small>{note}</small></span>
      <span className="switch" aria-hidden><i /></span>
    </button>
  );
}

/** One group on a page of tiles (Settings, My Bento): a small kicker, a title, then its rows. */
export function Tile({ k, title, className = "", children }: { k?: string; title: string; className?: string; children: ReactNode }) {
  return (
    <section className={`tile mtile ${className}`}>
      {k && <span className="k">{k}</span>}
      <h2>{title}</h2>
      {children}
    </section>
  );
}
