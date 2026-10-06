// Bento²'s saved data from inside a picture, a tool or a screen: the Number shelf, the Notebook, the tools' own numbers.
import { useCallback } from "react";
import { useApp } from "../../app/AppState";
import type { ShelfValue } from "../model";
import { saveNote, setTool, shelve, type NotebookEntry, type ShelfItem } from "../progress";

export function useB2() {
  const { b2, updateB2, now } = useApp();
  const save = useCallback((name: string, value: ShelfValue, from: string, extra: Partial<Omit<ShelfItem, "value" | "from" | "at">> = {}) =>
    updateB2(b => shelve(b, name, { value, from, ...extra }, now())), [updateB2, now]);
  const note = useCallback((e: Omit<NotebookEntry, "at">) => updateB2(b => saveNote(b, e, now())), [updateB2, now]);
  const tool = useCallback(<T,>(id: string, fallback: T): T => (b2.tools[id] as T | undefined) ?? fallback, [b2.tools]);
  const setToolState = useCallback((id: string, state: unknown) => updateB2(b => setTool(b, id, state)), [updateB2]);
  return { b2, save, note, tool, setToolState, updateB2, now };
}

/** Asks the tools shell to open a tool, optionally with numbers to load (a boost for the Matrix pad). */
export const openTool = (id: string, args?: unknown) => dispatchEvent(new CustomEvent("b2:tool", { detail: { id, args } }));
