import { useSyncExternalStore } from "react";

/** the model's one-pane width (UI model v66, `max-width:600px`): a list and its detail take turns instead of sitting side by side */
const ONE_PANE = "(max-width: 600px)";

const query = () => (typeof matchMedia === "undefined" ? null : matchMedia(ONE_PANE));
export const isOnePane = () => !!query()?.matches;

/** true while the window is one pane wide; follows the window as it turns or resizes */
export function useOnePane(): boolean {
  return useSyncExternalStore(f => {
    const q = query();
    q?.addEventListener("change", f);
    return () => q?.removeEventListener("change", f);
  }, isOnePane, () => false);
}
