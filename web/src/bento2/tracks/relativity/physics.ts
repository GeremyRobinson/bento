// Relativity's formulas, in one place, for the pictures, the lessons and the build. Constants come from Units and
// constants (relativity.md, "Constants and rounding"); nothing is rounded here.
import { C, DAY, MU_E, R_E } from "../../constants";

export const gammaOf = (b: number) => 1 / Math.sqrt(1 - b * b);
/** a boost along x, acting on (ct, x) */
export const boost = (b: number): number[][] => { const g = gammaOf(b); return [[g, -b * g], [-b * g, g]]; };
export const applyBoost = (b: number, ct: number, x: number): [number, number] => { const g = gammaOf(b); return [g * (ct - b * x), g * (x - b * ct)]; };
export const addSpeeds = (u: number, v: number) => (u + v) / (1 + u * v);
export const rapidity = (b: number) => Math.atanh(b);

/** c in km/s and km per μs and m per ns */
export const C_KMS = C / 1000;
export const C_KM_US = C / 1e9;
export const C_M_NS = C / 1e9;

/** the fraction of each second a clock moving at v km/s loses, v²/2c² */
export const slowFraction = (vKms: number) => (vKms * vKms) / (2 * C_KMS * C_KMS);
/** μs lost per day at v km/s */
export const lossPerDayUs = (vKms: number) => slowFraction(vKms) * DAY * 1e6;
/** ns gained per day by a clock h meters higher near the ground */
export const heightGainNs = (h: number, g = 9.81) => ((g * h) / (C * C)) * DAY * 1e9;
/** K = GM/(c²R) per day in μs: the most a ground clock could gain by climbing out of Earth's gravity, 60.1 μs */
export const K_US = (MU_E / (C * C * R_E)) * DAY * 1e6;
/** μs gained per day by gravity at radius r km, against the ground */
export const gravityGainUs = (rKm: number) => K_US * (1 - (R_E / 1000) / rKm);
/** circular orbit speed at radius r km, in km/s */
export const orbitSpeedKms = (rKm: number) => Math.sqrt(MU_E / (rKm * 1000)) / 1000;
/** the speed part of a circular orbit's drift: K R/(2r) */
export const speedLossUs = (rKm: number) => (K_US * (R_E / 1000)) / (2 * rKm);
/** the net drift of a satellite clock at radius r km, μs per day (positive: ahead of the ground) */
export const netDriftUs = (rKm: number) => K_US * (1 - (1.5 * (R_E / 1000)) / rKm);
/** the radius where the two effects cancel, 1.5 R⊕ */
export const CANCEL_KM = 1.5 * (R_E / 1000);
/** μs of clock error → km of map error */
export const mapErrorKm = (us: number) => us * C_KM_US;
/** the factory frequency: 10.23 MHz slowed by the net fraction */
export const factoryMHz = (netUs: number) => 10.23 * (1 - (netUs * 1e-6) / DAY);

/** Pythagorean speeds: β = a/c with γ = c/b, so every answer is a fraction. */
export const TRIPLES: [number, number, number][] = [[3, 4, 5], [4, 3, 5], [5, 12, 13], [12, 5, 13], [8, 15, 17], [15, 8, 17], [7, 24, 25], [24, 7, 25], [20, 21, 29], [21, 20, 29]];
/** γ − 1 without losing digits at small speeds: β² / (√(1 − β²)(1 + √(1 − β²))) */
export const gammaMinus1 = (b: number) => { const r = Math.sqrt(1 - b * b); return (b * b) / (r * (1 + r)); };
