import type { ButtonHTMLAttributes, ReactNode } from "react";

/**
 * Ring (master, v2): the one progress mark. A track and the grade colour going round from the top. The island's ring,
 * a cover tile's small ring and a stat tile's big ring are the same drawing; only the size differs.
 */
export function Ring({ p, label, size = "sm" }: { p: number; label?: ReactNode; size?: "sm" | "md" | "lg" }) {
  const f = Math.max(0, Math.min(1, p));
  return (
    <span className={`v-ring ${size}`} aria-hidden="true">
      <svg viewBox="0 0 40 40"><circle className="t" cx="20" cy="20" r="18" pathLength={1} />
        {f > 0 && <circle className="f" cx="20" cy="20" r="18" pathLength={1} strokeDasharray={`${f} 1`} />}</svg>
      {label != null && <b>{label}</b>}
    </span>
  );
}

/**
 * Cover tile (master, v2): a chapter, a lesson or a problem. Its picture (or the problem, big) on top, its name, then a
 * small ring and one word at the foot. Every tile in the box is this one, all the same size.
 */
export function Cover({ pic, name, p, word, tone, pick, className, ...rest }: ButtonHTMLAttributes<HTMLButtonElement> & {
  pic?: ReactNode; name?: ReactNode; p: number; word: ReactNode; tone?: "next" | "rev"; pick?: boolean;
}) {
  return (
    <button className={["v-cover", pick && "pick", className].filter(Boolean).join(" ")} {...rest}>
      <span className="v-top">{pic}</span>
      <span className="v-tx">
        {name != null && <span className="v-nm">{name}</span>}
        <span className="v-prog"><Ring p={p} /><span className={`v-st${tone ? ` ${tone}` : ""}`}>{word}</span></span>
      </span>
    </button>
  );
}

/** Stat tile (master, v2): a big ring with its number, a name and one line. A test, or how the year is going. */
export function Stat({ p, big, name, line, onClick, label }: { p: number; big: ReactNode; name: string; line: string; onClick?: () => void; label?: string }) {
  const inner = <><Ring p={p} label={big} size="lg" /><span className="v-nm">{name}</span><span className="v-st">{line}</span></>;
  return onClick ? <button className="v-stat" onClick={onClick} aria-label={label}>{inner}</button> : <div className="v-stat still">{inner}</div>;
}
