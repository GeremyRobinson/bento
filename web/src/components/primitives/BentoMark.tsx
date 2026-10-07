import type { CSSProperties } from "react";

/**
 * The wordmark: text logo 1, "Bento, tightened" (G 2026-10-06). Its letters are separate pieces so it can cascade
 * in one after another when it comes back, the way the diagrams' labels do; a reader hears one word. Squared, it is
 * Bento² with a real superscript 2 (Inter's ² sits too low and light).
 */
export function BentoMark({ className, squared }: { className?: string; squared?: boolean }) {
  const letters = [..."Obento"];
  return (
    <span className={`bmark${className ? ` ${className}` : ""}`}>
      <span className="vh">{squared ? "Obento squared" : "Obento"}</span>
      <span aria-hidden="true">
        {letters.map((l, i) => <span key={i} className="bl" style={{ "--c": i } as CSSProperties}>{l}</span>)}
        {squared && <sup className="bl" style={{ "--c": letters.length } as CSSProperties}>2</sup>}
      </span>
    </span>
  );
}
