import type { CSSProperties, ReactNode } from "react";

/**
 * The UI model's small masters (Design, v57): the ring, the progress marks and the slider. Every screen draws these
 * the same way; only their size or their count changes. Styles in styles/ui.css.
 */

/** Ring: one drawing at three sizes (20 on a tile's foot, 42 in the island, 94 on a stat tile) */
export function ORing({ p, label, size }: { p: number; label?: ReactNode; size?: "m" | "l" }) {
  const f = Math.max(0, Math.min(1, p));
  return (
    <span className={`o-ring${size ? ` ${size}` : ""}`} aria-hidden="true">
      <svg viewBox="0 0 40 40"><circle className="t" cx="20" cy="20" r="18" pathLength={1} />
        {f > 0 && <circle className="f" cx="20" cy="20" r="18" pathLength={1} strokeDasharray={`${f} 1`} />}</svg>
      {label != null && <b>{label}</b>}
    </span>
  );
}

/** Progress marks: `on` done (light), the one at `now` solid and twice as long, the rest still to come (grey) */
export function Marks({ n, on, now = -1 }: { n: number; on: number; now?: number }) {
  return (
    <span className="o-marks" aria-hidden="true">
      {Array.from({ length: n }, (_, i) => <i key={i} className={i < on ? "on" : i === now ? "now" : undefined} />)}
    </span>
  );
}

export interface Tab<T extends string> { id: T; label: ReactNode; aria?: string }

/** Slider: Lessons / Test / Grade and the like. The thumb is the selected look and glides at change speed. */
export function OSlider<T extends string>({ tabs, value, onPick, label, className }: { tabs: Tab<T>[]; value: T; onPick: (id: T) => void; label: string; className?: string }) {
  const i = Math.max(0, tabs.findIndex(t => t.id === value));
  return (
    <div className={`o-sw${className ? ` ${className}` : ""}`} role="tablist" aria-label={label} style={{ "--n": tabs.length, "--i": i } as CSSProperties}>
      <span className="thumb" aria-hidden="true" />
      {tabs.map(t => (
        <button key={t.id} role="tab" aria-selected={t.id === value} aria-label={t.aria} onClick={() => { if (t.id !== value) onPick(t.id); }}>{t.label}</button>
      ))}
    </div>
  );
}

/** the round grid that opens Every grade (the island's first button on the box's top) */
export const GridIcon = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
    {[3.5, 9.75, 16].flatMap(y => [3.5, 9.75, 16].map(x => <rect key={`${x}-${y}`} x={x} y={y} width="4.5" height="4.5" rx="1.2" />))}
  </svg>
);

/** back: one chevron */
export const BackIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M15 5l-7 7 7 7" /></svg>
);

/** the person (Me) */
export const PersonIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="12" cy="8" r="4" /><path d="M4 21a8 8 0 0 1 16 0" /></svg>
);

/** Settings: the sun */
export const SunIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="12" cy="12" r="3" /><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1" /></svg>
);
