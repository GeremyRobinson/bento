import { APP_NAME } from "../app/copy";
import type { CSSProperties, ReactNode } from "react";
import { BentoMark } from "./primitives/BentoMark";

/**
 * The nav master (G 2026-10-06: "the nav needs to be a component that all pages use but it changes"). One frame at the
 * top of every screen, the landing page included: the wordmark on the left, where you are in the middle, your
 * buttons on the right. Pages only fill the slots; the frame, its height and its place never change.
 */
export function Nav({ left, center, right, guest, style }: { left?: ReactNode; center?: ReactNode; right?: ReactNode; guest?: boolean; style?: CSSProperties }) {
  return (
    <div className={`itop${guest ? " guest" : ""}`} style={style}>
      <div className="icorner left">{left}</div>
      {center ?? <span />}
      <div className="icorner right">{right}</div>
    </div>
  );
}

/** The wordmark as the nav's first piece: plain "Bento" that always takes you home. */
export function NavMark({ onHome }: { onHome: () => void }) {
  return <button className="imark" onClick={onHome} aria-label={`${APP_NAME}, home`}><BentoMark className="iword" /></button>;
}
