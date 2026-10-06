import { Pill } from "./primitives/Pill";
import { useEffect, useRef, useState } from "react";
import { useApp } from "../app/AppState";
import { GradeLineup } from "./GradeLineup";

/** "Choose your grade": the same window the header badge opens in the current app. */
export function GradeSheet() {
  const { chooseGrade, openSheet } = useApp();
  const panel = useRef<HTMLDivElement>(null);
  // a soft fade at the bottom says there is more below, until the last grade is in view (Review v39 item 11)
  const [more, setMore] = useState(false);
  const check = () => { const p = panel.current; if (p) setMore(p.scrollHeight - p.scrollTop - p.clientHeight > 4); };
  useEffect(() => { check(); addEventListener("resize", check); return () => removeEventListener("resize", check); }, []);
  useEffect(() => {
    panel.current?.querySelector<HTMLButtonElement>(".gcell.on, .gcell")?.focus();
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") openSheet(false); };
    addEventListener("keydown", onKey);
    return () => removeEventListener("keydown", onKey);
  }, [openSheet]);
  return (
    <div className="sheet" onClick={e => { if (e.target === e.currentTarget) openSheet(false); }}>
      <div className={`panel${more ? " more" : ""}`} role="dialog" aria-modal="true" aria-label="Choose your grade" ref={panel} onScroll={check}>
        <div className="head"><h2>Choose your grade</h2><Pill onClick={() => openSheet(false)}>Done</Pill></div>
        <GradeLineup onPick={chooseGrade} />
      </div>
    </div>
  );
}
