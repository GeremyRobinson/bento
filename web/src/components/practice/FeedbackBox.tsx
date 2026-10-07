import { Rich } from "../primitives/MathLine";
import type { Feedback } from "../../engine/session/types";

const DOT = { good: "ok", bad: "err", hint: "busy" } as const;

/** Bento's own little celebration: a burst of short rays (bigger for a whole problem done), in place of an emoji. */
const Burst = ({ big }: { big?: boolean }) => (
  <svg className={`pop${big ? " big" : ""}`} viewBox="0 0 24 24" width={big ? 22 : 18} height={big ? 22 : 18} aria-hidden="true" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round">
    {Array.from({ length: big ? 8 : 6 }, (_, i) => { const a = (i / (big ? 8 : 6)) * Math.PI * 2; return <line key={i} x1={12 + Math.cos(a) * 5} y1={12 + Math.sin(a) * 5} x2={12 + Math.cos(a) * 10} y2={12 + Math.sin(a) * 10} />; })}
  </svg>
);

/**
 * Feedback has its own line under the equation (Design, practice picture-first §2): its height is kept even while it's
 * empty, so it never floats over the answer and nothing below it jumps. Wrong, right and solved land here (Practice
 * keeps the light bulb's hints for the hint stack). A solved problem says "Solved." with the lesson's last idea in its numbers.
 */
export function FeedbackBox({ fb, idea, solved }: { fb: Feedback | null; idea?: string; solved?: boolean }) {
  const shown = fb, on = !!shown || !!solved;
  const strong = solved ? "Solved." : shown?.strong, text = solved ? idea ?? shown?.text : shown?.text;
  return (
    <div className={`pfb${on ? ` fb-${solved ? "good solved" : shown!.type}` : ""}`} role="status" aria-live="polite">
      {on && <>
        <span className={`dot ${solved ? "ok" : DOT[shown!.type]}`} />
        <span className="pfbt">
          {shown?.pop === "big" && <><Burst big /> </>}
          {shown?.pop === "star" && <><Burst /> </>}
          {strong && <strong><Rich text={strong} /></strong>}{strong && text ? " " : ""}{text && <Rich text={text} />}
          {!solved && shown?.lines?.map((l, i) => <span key={i}> <Rich text={l} /></span>)}
        </span>
      </>}
    </div>
  );
}
