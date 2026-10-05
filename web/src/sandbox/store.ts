import { useSyncExternalStore } from "react";
import { randomSeed } from "../curriculum/generators/rng";
import { emptyOverrides, type Overrides, type Theme } from "./tokens";

/* ---- one small store the board and the panel share, kept for the visit (and the next one) on this device ---- */
const KEY = "bento-sandbox";
interface SbState { open: boolean; grade: number; theme: Theme; seed: number; o: Overrides }
const load = (): SbState => {
  const base: SbState = { open: false, grade: 5, theme: "light", seed: randomSeed(), o: emptyOverrides() };
  try { const s = JSON.parse(localStorage.getItem(KEY) ?? "null"); return s ? { ...base, ...s, seed: base.seed, open: false } : base; } catch { return base; }
};
let state: SbState | null = null;
const subs = new Set<() => void>();
export const get = () => (state ??= load());
export function set(patch: Partial<SbState>) {
  state = { ...get(), ...patch };
  try { const { open: _o, seed: _s, ...keep } = state; localStorage.setItem(KEY, JSON.stringify(keep)); } catch { /* private window: edits last for the visit */ }
  subs.forEach(f => f());
}
/** changes when "New problems" is tapped, so the screen on show starts over with fresh numbers */
export const useSandboxSeed = (on: boolean) => useSyncExternalStore(f => { subs.add(f); return () => subs.delete(f); }, () => (on ? get().seed : 0), () => 0);
export const useSb = () => useSyncExternalStore(f => { subs.add(f); return () => subs.delete(f); }, get, get);

