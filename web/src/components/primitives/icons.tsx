// Same strokes as the current app's icons.
export const HomeIcon = () => (
  <svg viewBox="2.5 2.5 19 19" aria-hidden="true"><path d="M4 11.2 12 4.5l8 6.7M6.5 9.5V19h4v-5h3v5h4V9.5" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" /></svg>
);
const CHEV = { left: "M14.5 6l-6 6 6 6", right: "M9.5 6l6 6-6 6", down: "M6 9.5l6 6 6-6" } as const;
export const Chevron = ({ dir }: { dir: keyof typeof CHEV }) => (
  <svg viewBox="0 0 24 24" aria-hidden="true"><path d={CHEV[dir]} fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" /></svg>
);

export const Check = () => (
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M5 12.5l4.2 4.2L19 7" /></svg>
);
/** A small padlock: what's shown stays on this device. */
export const LockIcon = ({ size = 14 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 18 18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><rect x="3.5" y="8" width="11" height="7.5" rx="2.5" /><path d="M6 8V6a3 3 0 0 1 6 0v2" /></svg>
);
/** A close cross, in the same strokes. */
export const CloseIcon = () => (
  <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" aria-hidden="true"><path d="M6.5 6.5l11 11M17.5 6.5l-11 11" /></svg>
);

/** A simple person: a head and shoulders. */
export const MeIcon = () => (
  <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="8.5" r="3.6" /><path d="M5 20c1.2-3.6 4-5.4 7-5.4s5.8 1.8 7 5.4" /></svg>
);

/** Settings: a sun (v2 model) */
export const SettingsIcon = () => (
  <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="12" cy="12" r="3" /><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1" /></svg>
);
