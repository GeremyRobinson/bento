import { APP_NAME } from "../app/copy";
import type { CSSProperties, ReactNode } from "react";
import { BentoMark } from "./primitives/BentoMark";
import { BoxMark } from "./primitives/BoxMark";

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

/** The logo as the nav's first piece: the mark and the wordmark, which always take you home (G 2026-10-08 01:10). */
export function NavMark({ onHome }: { onHome: () => void }) {
  return <button className="imark" onClick={onHome} aria-label={`${APP_NAME}, home`}><BoxMark className="ibox" size={24} label="" /><BentoMark className="iword" /></button>;
}
