import type { CSSProperties, ReactNode, Ref } from "react";
import { inkOf } from "../curriculum/grades";

export type FeatureSize = "one" | "wide" | "tall";

/**
 * The FeatureTile master: one landing-page box. A small working piece of the app on top, its name and one line under
 * it, in the colour it's given. Every feature tile and demo tile on the landing page is an instance of this.
 */
export function FeatureTile({ size = "one", tint, k, title, label, box, onTap, extra, live, children }: {
  size?: FeatureSize; tint: string; k: number; title: string; label: ReactNode; box?: Ref<HTMLElement>;
  /** a demo that plays another example when tapped */ onTap?: () => void; extra?: ReactNode; live?: boolean; children: ReactNode;
}) {
  return (
    <article ref={box} className={`ltile ${size}${onTap ? " ldemo" : ""}`} onClick={onTap} aria-live={live ? "polite" : undefined}
      style={{ "--tint": tint, "--ink": inkOf(tint), "--i": k } as CSSProperties}>
      <div className="lvis" aria-hidden={onTap ? undefined : true}>{children}{extra}</div>
      <div className="ltext"><h3>{title}</h3><p>{label}</p></div>
    </article>
  );
}
