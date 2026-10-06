import { useEffect, type CSSProperties } from "react";
import { createPortal } from "react-dom";

/**
 * One quick question before something is lost (G 2026-10-06: a way out of anything started). It is the quick-settings
 * master: a light dim and a short column of floating pills, the safe choice first. Escape or the dim keeps going.
 */
export function ConfirmStack({ title, body, confirm, cancel = "Keep going", onConfirm, onCancel }: {
  title: string; body?: string; confirm: string; cancel?: string; onConfirm: () => void; onCancel: () => void;
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") onCancel(); };
    addEventListener("keydown", onKey);
    return () => removeEventListener("keydown", onKey);
  }, [onCancel]);
  // drawn at the app's root, so no screen's own layout (a fit grid, a transform) can move it off-screen (Review v45 #1)
  const root = (typeof document !== "undefined" && (document.getElementById("app") ?? document.body)) || null;
  const stack = (
    <>
      <div className="fdim" onClick={onCancel} />
      <div className="fstack fconfirm" role="alertdialog" aria-label={title} style={{ "--n": 4 } as CSSProperties}>
        <span className="fpill fcq" style={{ "--i": 0 } as CSSProperties}><b>{title}</b>{body && <span>{body}</span>}</span>
        <button className="fpill" autoFocus onClick={onCancel} style={{ "--i": 1 } as CSSProperties}>{cancel}</button>
        <button className="fpill fquit" onClick={onConfirm} style={{ "--i": 2 } as CSSProperties}>{confirm}</button>
      </div>
    </>
  );
  return root ? createPortal(stack, root) : stack;
}
