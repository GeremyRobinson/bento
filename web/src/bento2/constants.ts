// Units and constants: the values every Bento² lesson computes with, under one name each. The names are what the
// calculator, the grapher and the Matrix pad read (c, mu_E, R_E …). Values come from the track specs' "Constants and
// rounding" sections; tracks that share a constant (relativity and orbits) share this one entry.

export interface Constant {
  /** what you type: c, mu_E, R_E */
  id: string;
  /** how it's written: c, μ⊕, R⊕ */
  symbol: string;
  name: string;
  /** in SI units */
  value: number;
  unit: string;
  /** how the spec says to show it */
  shown: string;
  /** other ways of writing it, from the spec */
  also?: string[];
  exact?: boolean;
}

export const C = 299792458;
export const MU_E = 3.986e14;
export const R_E = 6.371e6;
export const G0 = 9.81;
export const R_GPS = 26.571e6;
export const DAY = 86400;
export const TAU_MU = 2.2e-6;

export const CONSTANTS: Constant[] = [
  { id: "c", symbol: "c", name: "Speed of light", value: C, unit: "m/s", shown: "299,792 km/s", also: ["0.2998 m per nanosecond", "0.2998 km per microsecond"], exact: true },
  { id: "mu_E", symbol: "μ⊕", name: "Earth's GM", value: MU_E, unit: "m³/s²", shown: "3.986 × 10¹⁴ m³/s²" },
  { id: "R_E", symbol: "R⊕", name: "Earth's mean radius", value: R_E, unit: "m", shown: "6371 km" },
  { id: "g0", symbol: "g₀", name: "Surface gravity", value: G0, unit: "m/s²", shown: "9.81 m/s²" },
  { id: "r_GPS", symbol: "r", name: "GPS orbit radius", value: R_GPS, unit: "m", shown: "26,571 km", also: ["altitude 20,200 km, circular"] },
  { id: "day", symbol: "day", name: "One day", value: DAY, unit: "s", shown: "86,400 s", exact: true },
  { id: "tau_mu", symbol: "τ_μ", name: "Muon mean life", value: TAU_MU, unit: "s", shown: "2.2 μs" },
  { id: "G", symbol: "G", name: "Gravitational constant", value: 6.674e-11, unit: "m³/(kg s²)", shown: "6.674 × 10⁻¹¹ m³/(kg s²)" },
  { id: "M_E", symbol: "M⊕", name: "Earth's mass", value: 5.972e24, unit: "kg", shown: "5.972 × 10²⁴ kg" },
  { id: "h", symbol: "h", name: "Planck's constant", value: 6.62607015e-34, unit: "J s", shown: "6.626 × 10⁻³⁴ J s", exact: true },
];

export const constantById = (id: string) => CONSTANTS.find(k => k.id === id);
/** every constant's value by its typed name, for the expression reader */
export const CONSTANT_VALUES: Record<string, number> = Object.fromEntries(CONSTANTS.map(k => [k.id, k.value]));

/** Units the converter knows, by kind, each as a factor to the SI unit. "c" as a speed is a fraction of light speed. */
export const UNITS: Record<string, { id: string; name: string; si: number }[]> = {
  length: [
    { id: "m", name: "m", si: 1 }, { id: "km", name: "km", si: 1e3 }, { id: "ls", name: "light-seconds", si: C },
    { id: "lns", name: "light-nanoseconds", si: C * 1e-9 }, { id: "ly", name: "light-years", si: C * 365.25 * DAY }, { id: "RE", name: "Earth radii", si: R_E },
  ],
  time: [
    { id: "ns", name: "ns", si: 1e-9 }, { id: "us", name: "μs", si: 1e-6 }, { id: "ms", name: "ms", si: 1e-3 }, { id: "s", name: "s", si: 1 },
    { id: "h", name: "hours", si: 3600 }, { id: "d", name: "days", si: DAY }, { id: "y", name: "years", si: 365.25 * DAY },
  ],
  speed: [
    { id: "ms", name: "m/s", si: 1 }, { id: "kms", name: "km/s", si: 1e3 }, { id: "kmh", name: "km/h", si: 1 / 3.6 }, { id: "c", name: "× c", si: C },
  ],
};

/** value in unit `from` → unit `to`, both of one kind */
export function convert(kind: string, value: number, from: string, to: string): number {
  const list = UNITS[kind] ?? [];
  const a = list.find(u => u.id === from), b = list.find(u => u.id === to);
  if (!a || !b) return NaN;
  return (value * a.si) / b.si;
}
