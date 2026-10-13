import type { CSSProperties } from "react";

export interface SliderOption<T extends string> { id: T; label: string; ariaLabel?: string; disabled?: boolean }

/**
 * The tap slider (G 2026-10-06): a row of choices with one thumb that glides to the one you tap. One master for every
 * either/or in Bento (Bento / Bento², All grades / Year / Chapter); instances pass their choices and nest it where
 * they need it. Every choice gets an equal share, so the thumb's slide is one share per step.
 */
export function Slider<T extends string>({ options, value, onPick, label, className }: { options: SliderOption<T>[]; value: T; onPick: (id: T) => void; label: string; className?: string }) {
  // a value that isn't one of the choices (the nav hub on Settings or My Obento) leaves the thumb resting, unlit
  const found = options.findIndex(o => o.id === value), at = Math.max(0, found);
  return (
    <div className={`slider${found < 0 ? " none" : ""}${className ? ` ${className}` : ""}`} role="group" aria-label={label} style={{ "--n": options.length, "--at": at } as CSSProperties}>
      <span className="slider-thumb" aria-hidden />
      {options.map(o => (
        <button key={o.id} aria-pressed={o.id === value} aria-label={o.ariaLabel} disabled={o.disabled} onClick={() => { if (o.id !== value) onPick(o.id); }}>{o.label}</button>
      ))}
    </div>
  );
}
