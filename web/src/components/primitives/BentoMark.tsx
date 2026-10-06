/**
 * The wordmark. Its letters are separate pieces so it can cascade in one after another when it comes back
 * (G 2026-10-06), the way the diagrams' labels do; a reader hears one word.
 */
export function BentoMark({ className }: { className?: string }) {
  return (
    <span className={`bmark${className ? ` ${className}` : ""}`}>
      <span className="vh">Bento</span>
      <span aria-hidden="true">{[..."Bento"].map((l, i) => <span key={i} className="bl" style={{ "--c": i } as React.CSSProperties}>{l}</span>)}</span>
    </span>
  );
}
