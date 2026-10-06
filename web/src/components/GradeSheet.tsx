import { Pill } from "./primitives/Pill";
import { useEffect, useRef } from "react";
import { useApp } from "../app/AppState";
import { GradeLineup } from "./GradeLineup";

/** "Choose your grade": the same window the header badge opens in the current app. */
export function GradeSheet() {
  const { chooseGrade, openSheet } = useApp();
  const panel = useRef<HTMLDivElement>(null);
  useEffect(() => {
    panel.current?.querySelector<HTMLButtonElement>(".gcell.on, .gcell")?.focus();
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") openSheet(false); };
    addEventListener("keydown", onKey);
    return () => removeEventListener("keydown", onKey);
  }, [openSheet]);
  return (
    <div className="sheet" onClick={e => { if (e.target === e.currentTarget) openSheet(false); }}>
      <div className="panel" role="dialog" aria-modal="true" aria-label="Choose your grade" ref={panel}>
        <div className="head"><h2>Choose your grade</h2><Pill onClick={() => openSheet(false)}>Done</Pill></div>
        <GradeLineup onPick={chooseGrade} />
      </div>
    </div>
  );
}
