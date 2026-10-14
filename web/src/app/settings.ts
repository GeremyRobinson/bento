// Accessibility and comfort settings. They belong to this device (saved with progress, and in backups),
// and work by setting attributes on <html> that the styles and a few behaviours read.

export interface Settings {
  /** light, dark, or follow the device (UI model v63: Look) */
  look: "auto" | "light" | "dark";
  /** text size (UI model v67.1): small, medium ("standard") or large; it moves the body and small text steps app-wide */
  text: "small" | "standard" | "large";
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
  look: "auto", text: "standard", contrast: false, motion: "system", colorSafe: false, readable: false, sounds: false, readAloud: null, leftHanded: false,
});

/** Settings from a save, with anything missing or unknown back at its default. */
export function readSettings(raw: unknown): Settings {
  const d = defaultSettings();
  if (!raw || typeof raw !== "object") return d;
  const r = raw as Partial<Record<keyof Settings, unknown>>;
  return {
    look: r.look === "light" || r.look === "dark" ? r.look : "auto",
    // "largest" came from the old three sizes; it is the new Large
    text: r.text === "small" ? "small" : r.text === "large" || r.text === "largest" ? "large" : "standard",
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
  if (s.look === "auto") delete el.theme; else el.theme = s.look;
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

const SUP: Record<string, string> = { "⁰": "0", "¹": "1", "²": "2", "³": "3", "⁴": "4", "⁵": "5", "⁶": "6", "⁷": "7", "⁸": "8", "⁹": "9", "⁻": "minus ", "ⁿ": "n", "ˣ": "x" };
const SUB: Record<string, string> = { "₀": "0", "₁": "1", "₂": "2", "₃": "3", "₄": "4", "₅": "5", "₆": "6", "₇": "7", "₈": "8", "₉": "9", "ₙ": "n" };
const SUPS = `[${Object.keys(SUP).join("")}]+`, SUBS = `[${Object.keys(SUB).join("")}]+`;
const map = (s: string, m: Record<string, string>) => [...s].map(c => m[c] ?? c).join("");

/**
 * The words a symbol is said as (Copy rewrites-05, G 2026-10-14): fractions are "3 over 4", not "3 slash 4" or a date;
 * powers, roots, subscripts, primes and trig names are said the way a teacher says them. The text on screen is unchanged.
 */
export function spoken(text: string): string {
  return text
    .replace(/d\/dx/g, " the derivative with respect to x of ")
    .replace(new RegExp(`log(${SUBS})`, "g"), (_, b: string) => `log base ${map(b, SUB)} of `)
    .replace(new RegExp(`([A-Za-z])(${SUBS})`, "g"), (_, a: string, b: string) => `${a} sub ${map(b, SUB)}`)
    // ⁻¹ after a function's name is its inverse, never a power: "f inverse", "sine inverse"
    .replace(/\b(sin|cos|tan|[fgh])⁻¹/g, (_, f: string) => `${({ sin: "sine", cos: "cosine", tan: "tangent" } as Record<string, string>)[f] ?? f} inverse`)
    .replace(/²/g, " squared").replace(/³/g, " cubed")
    .replace(new RegExp(SUPS, "g"), b => ` to the power ${map(b, SUP)}`)
    .replace(/\^\(?(-?[\w.]+)\)?/g, " to the power $1")
    .replace(/′\(/g, " prime of (").replace(/′/g, " prime")
    .replace(/√/g, "the square root of ")
    .replace(/π/g, "pi").replace(/°/g, " degrees")
    .replace(/\b(sin|cos|tan)\b/g, w => ({ sin: "sine", cos: "cosine", tan: "tangent" })[w]!)
    .replace(/(\d[\d.,]*|[a-z])\s*\/\s*(\d[\d.,]*|[a-z])/gi, "$1 over $2")
    .replace(/−/g, " minus ").replace(/×/g, " times ").replace(/÷/g, " divided by ")
    .replace(/\s{2,}/g, " ").trim();
}

/** what a part of the page says out loud: its words, without the drawn copy that a screen reader skips (aria-hidden) */
export function spokenOf(el: Element | null): string {
  if (!el) return "";
  const c = el.cloneNode(true) as Element;
  c.querySelectorAll('[aria-hidden="true"]').forEach(n => n.remove());
  return c.textContent ?? "";
}

/** Reads text out loud, replacing anything still being read. */
export function speak(text: string): void {
  try {
    if (typeof speechSynthesis === "undefined" || !text) return;
    speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(spoken(text));
    u.rate = 0.95;
    speechSynthesis.speak(u);
  } catch { /* no voice on this device */ }
}
