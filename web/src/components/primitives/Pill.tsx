import type { ButtonHTMLAttributes, HTMLAttributes } from "react";

/**
 * Pill (master): the one button every screen uses. An instance only says what differs: `go` for the main action
 * (filled with the grade's ink), `circ` for a round icon button, `badged` when it leads with a score chip, `small` for
 * the short size (40px) used inside a box, like Confirm's answers.
 * How every pill looks lives in the --pill-* tokens (styles/components.css).
 */
export function Pill({ go, circ, badged, small, className, ...rest }: ButtonHTMLAttributes<HTMLButtonElement> & { go?: boolean; circ?: boolean; badged?: boolean; small?: boolean }) {
  const cls = ["ctl", go && "go", circ && "circ", badged && "badged", small && "sm", className].filter(Boolean).join(" ");
  return <button className={cls} {...rest} />;
}

/** A pill that only shows something (a Start label inside a tappable row, a counter): the same master, not a button. */
export function PillLabel({ go, badged, className, ...rest }: HTMLAttributes<HTMLSpanElement> & { go?: boolean; badged?: boolean }) {
  return <span className={["ctl", go && "go", badged && "badged", className].filter(Boolean).join(" ")} {...rest} />;
}
