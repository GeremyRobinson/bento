import { useEffect, useRef } from "react";
import { createPortal } from "react-dom";
import { Pill } from "./primitives/Pill";

/**
 * The Confirm master: one quick question before something is lost. A small bento box (G 2026-10-06: "it can also be a
 * bento shape since the buttons don't need a lot of space"): one panel with the question across the top and the two
 * answers side by side under it as small Pills, the safe one first and filled in the grade's colour; the box's padding
 * around them keeps their round ends concentric with its corners. It comes forward from the
 * middle of the screen, never from a corner. Escape or the dim keeps going.
 */
export function Confirm({ title, body, confirm, cancel = "Keep going", onConfirm, onCancel }: {
  title: string; body?: string; confirm: string; cancel?: string; onConfirm: () => void; onCancel: () => void;
}) {
  // when it closes, focus goes back to what opened it
  const opener = useRef<Element | null>(typeof document !== "undefined" ? document.activeElement : null);
  useEffect(() => () => { const el = opener.current; if (el instanceof HTMLElement && el.isConnected) el.focus(); }, []);
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") { e.preventDefault(); onCancel(); } };
    addEventListener("keydown", onKey);
    return () => removeEventListener("keydown", onKey);
  }, [onCancel]);
  // drawn at the app's root, so no screen's own layout (a fit grid, a transform) can move it off-screen (Review v45 #1)
  const root = (typeof document !== "undefined" && (document.getElementById("app") ?? document.body)) || null;
  const box = (
    <>
      <div className="fdim" onClick={onCancel} />
      <div className="confirm" role="alertdialog" aria-modal="true" aria-label={title} aria-describedby={body ? "confirm-body" : undefined}>
        <div className="cq"><b>{title}</b>{body && <span id="confirm-body">{body}</span>}</div>
        <Pill go small className="ca keep" autoFocus onClick={onCancel}>{cancel}</Pill>
        <Pill small className="ca" onClick={onConfirm}>{confirm}</Pill>
      </div>
    </>
  );
  return root ? createPortal(box, root) : box;
}
