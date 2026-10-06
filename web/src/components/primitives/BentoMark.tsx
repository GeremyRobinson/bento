/** The Bento wordmark: one master for every place the name stands as the logo (the island, the contents bar). */
export function BentoMark({ className }: { className?: string }) {
  return <span className={`bmark${className ? ` ${className}` : ""}`}>Bento</span>;
}
