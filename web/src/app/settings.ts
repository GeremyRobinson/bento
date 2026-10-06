// Accessibility and comfort settings. They belong to this device (saved with progress, and in backups),
// and work by setting attributes on <html> that the styles and a few behaviours read.

export interface Settings {
  /** larger text and controls, for anyone who finds the standard size small */
  text: "standard" | "large" | "largest";
  /** stronger lines and darker grey text */
  contrast: boolean;
  /** no sliding, popping or auto-playing pictures */
  motion: "system" | "reduce";
  /** blue and orange for right and wrong instead of green and red */
  colorSafe: boolean;
  /** plainer, wider letters that are easier to tell apart */
  readable: boolean;
  /** a soft tone for right and wrong answers */
  sounds: boolean;
  /** reads each step of a lesson and each problem out loud; null until chosen, which means on for kindergarten and 1st grade */
  readAloud: boolean | null;
  /** the answer pad on the left, for left-handed learners */
  leftHanded: boolean;
}

export const defaultSettings = (): Settings => ({
  text: "standard", contrast: false, motion: "system", colorSafe: false, readable: false, sounds: false, readAloud: null, leftHanded: false,
});

/** Settings from a save, with anything missing or unknown back at its default. */
export function readSettings(raw: unknown): Settings {
  const d = defaultSettings();
  if (!raw || typeof raw !== "object") return d;
  const r = raw as Partial<Record<keyof Settings, unknown>>;
  return {
    text: r.text === "large" || r.text === "largest" ? r.text : "standard",
    contrast: r.contrast === true,
    motion: r.motion === "reduce" ? "reduce" : "system",
    colorSafe: r.colorSafe === true,
    readable: r.readable === true,
    sounds: r.sounds === true,
    readAloud: typeof r.readAloud === "boolean" ? r.readAloud : null,
    leftHanded: r.leftHanded === true,
  };
}

/** Read aloud is on for early readers (kindergarten and 1st grade) until someone turns it off. */
export const readAloudOn = (s: Settings, grade: number | null | undefined): boolean => s.readAloud ?? (grade != null && grade <= 1);

/** Puts the settings on <html>, where the styles pick them up. */
export function applySettings(s: Settings): void {
  if (typeof document === "undefined") return;
  const el = document.documentElement.dataset;
  el.text = s.text;
  el.contrast = String(s.contrast);
  el.motion = s.motion;
  el.colorSafe = String(s.colorSafe);
  el.readable = String(s.readable);
  el.hand = s.leftHanded ? "left" : "right";
}

/** The device asks for less motion, or the person turned it down here. */
export const motionOff = () =>
  (typeof document !== "undefined" && document.documentElement.dataset.motion === "reduce")
  || (typeof matchMedia !== "undefined" && matchMedia("(prefers-reduced-motion: reduce)").matches);

let audio: AudioContext | null = null;
/** A short, soft tone: rising for right, low for wrong. */
export function playTone(kind: "right" | "wrong"): void {
  try {
    const Ctx = window.AudioContext ?? (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
    if (!Ctx) return;
    audio ??= new Ctx();
    const t = audio.currentTime, notes = kind === "right" ? [660, 880] : [300];
    notes.forEach((f, i) => {
      const o = audio!.createOscillator(), g = audio!.createGain();
      o.type = "sine"; o.frequency.value = f;
      g.gain.setValueAtTime(0.0001, t + i * 0.09);
      g.gain.exponentialRampToValueAtTime(0.12, t + i * 0.09 + 0.02);
      g.gain.exponentialRampToValueAtTime(0.0001, t + i * 0.09 + 0.22);
      o.connect(g).connect(audio!.destination);
      o.start(t + i * 0.09); o.stop(t + i * 0.09 + 0.25);
    });
  } catch { /* no sound on this device */ }
}

/** Reads text out loud, replacing anything still being read. */
export function speak(text: string): void {
  try {
    if (typeof speechSynthesis === "undefined" || !text) return;
    speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(text.replace(/−/g, "minus ").replace(/×/g, " times ").replace(/÷/g, " divided by "));
    u.rate = 0.95;
    speechSynthesis.speak(u);
  } catch { /* no voice on this device */ }
}
