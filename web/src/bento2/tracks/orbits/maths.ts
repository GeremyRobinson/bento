// Orbits' formulas, in one place, for the pictures, the lessons and the build. Constants come from Units and constants
// (orbits.md, "Constants and rounding"); nothing is rounded here. Distances in meters and speeds in m/s unless a name
// says km.
import { AU, DAY, G0, MU_E, MU_MARS, MU_SUN, PLANET_AU, R_E, R_MARS, SIDEREAL_DAY, YEAR } from "../../constants";

export { AU, DAY, G0, MU_E, MU_MARS, MU_SUN, PLANET_AU, R_E, R_MARS, SIDEREAL_DAY, YEAR };
export const R_KM = R_E / 1000;
export const R_MARS_KM = R_MARS / 1000;

/** the pull at h km above Earth's surface, scaled from g₀ */
export const gAt = (hKm: number) => G0 * (R_KM / (R_KM + hKm)) ** 2;
/** circular speed, m/s */
export const vCirc = (mu: number, r: number) => Math.sqrt(mu / r);
/** vis-viva speed at r on an orbit of semimajor axis a (a < 0 for a hyperbola), m/s */
export const vVis = (mu: number, r: number, a: number) => Math.sqrt(mu * (2 / r - 1 / a));
export const vEsc = (mu: number, r: number) => Math.sqrt((2 * mu) / r);
/** one lap, s */
export const period = (mu: number, a: number) => 2 * Math.PI * Math.sqrt(a ** 3 / mu);
/** the radius whose circular period is T, m */
export const radiusFor = (mu: number, T: number) => Math.cbrt((mu * T * T) / (4 * Math.PI * Math.PI));
/** geostationary radius from the sidereal day, m (42,164 km) */
export const R_GEO = radiusFor(MU_E, SIDEREAL_DAY);

export type ConicKind = "circle" | "ellipse" | "parabola" | "hyperbola";
export interface Conic {
  /** semimajor axis (negative for a hyperbola, Infinity for a parabola) */
  a: number; e: number; near: number; far: number;
  /** energy per kilogram */
  eps: number; kind: ConicKind;
  /** semi-latus rectum h²/μ, and the angle of the near point */
  p: number; w: number;
  /** +1 counterclockwise */
  dir: number;
}
/** the conic through position (x, y) with velocity (vx, vy) around a body of GM μ */
export function conicOf(mu: number, x: number, y: number, vx: number, vy: number): Conic {
  const r = Math.hypot(x, y), v2 = vx * vx + vy * vy, h = x * vy - y * vx;
  const eps = v2 / 2 - mu / r;
  // the eccentricity vector: ((v² − μ/r) r − (r·v) v) / μ
  const rv = x * vx + y * vy;
  const ex = ((v2 - mu / r) * x - rv * vx) / mu, ey = ((v2 - mu / r) * y - rv * vy) / mu;
  const e = Math.hypot(ex, ey), p = (h * h) / mu;
  const a = Math.abs(eps) < 1e-12 * (mu / r) ? Infinity : -mu / (2 * eps);
  const near = p / (1 + e), far = e < 1 ? p / (1 - e) : Infinity;
  const kind: ConicKind = e < 0.005 ? "circle" : e < 0.995 ? "ellipse" : e <= 1.005 ? "parabola" : "hyperbola";
  return { a, e, near, far, eps, kind, p, w: e < 1e-9 ? Math.atan2(y, x) : Math.atan2(ey, ex), dir: h >= 0 ? 1 : -1 };
}
/** points of a conic, around the body at (0, 0), cut off at radius `rmax` */
export function conicPoints(c: Conic, rmax: number, n = 160, part: "all" | "out" | "in" = "all"): [number, number][] {
  const out: [number, number][] = [];
  const lim = c.e < 1 ? Math.PI : Math.acos(Math.max(-1, -1 / c.e)) - 1e-3;
  // "out" is the half after the near point, "in" the half before it, in the direction of motion
  const lo = part === "all" ? -lim : part === "out" ? (c.dir > 0 ? 0 : -lim) : (c.dir > 0 ? -lim : 0);
  const hi = part === "all" ? lim : part === "out" ? (c.dir > 0 ? lim : 0) : (c.dir > 0 ? 0 : lim);
  for (let k = 0; k <= n; k++) {
    const th = lo + ((hi - lo) * k) / n, r = c.p / (1 + c.e * Math.cos(th));
    if (r <= 0 || r > rmax) { if (out.length && c.e >= 1) break; continue; }
    out.push([r * Math.cos(th + c.w), r * Math.sin(th + c.w)]);
  }
  return out;
}

/** a Hohmann transfer between circles r₁ and r₂ */
export function hohmann(mu: number, r1: number, r2: number) {
  const at = (r1 + r2) / 2, v1 = vCirc(mu, r1), v2 = vCirc(mu, r2), vp = vVis(mu, r1, at), va = vVis(mu, r2, at);
  const dv1 = vp - v1, dv2 = v2 - va;
  return { at, v1, v2, vp, va, dv1, dv2, total: Math.abs(dv1) + Math.abs(dv2), coast: Math.PI * Math.sqrt(at ** 3 / mu) };
}

/** a launch window from Earth (1 AU) to a planet at r₂ AU: years, degrees */
export function windowTo(r2: number) {
  const at = (1 + r2) / 2, t = 0.5 * at ** 1.5, T2 = r2 ** 1.5;
  return { at, t, days: t * 365.25, T2, phi: 180 - (360 * t) / T2, S: 1 / Math.abs(1 - 1 / T2) };
}

/** the burn from a circle at r that leaves with v∞ (or, run backward, the capture into it), m/s */
export const escapeBurn = (mu: number, r: number, vinf: number) => Math.sqrt(vinf * vinf + (2 * mu) / r) - vCirc(mu, r);

export const veOf = (isp: number) => isp * G0;
export const rocketDv = (ve: number, ratio: number) => ve * Math.log(ratio);
export const propFraction = (dv: number, ve: number) => 1 - Math.exp(-dv / ve);

/** the whole Mars plan from the parking altitude, the Mars orbit altitude (km) and I_sp (s): km/s, days, degrees, % */
export function marsPlan(h1: number, h2: number, isp: number) {
  const r1 = AU, r2 = PLANET_AU.Mars * AU, sun = hohmann(MU_SUN, r1, r2);
  const vinf1 = sun.dv1, vinf2 = sun.dv2;
  const rp = (R_KM + h1) * 1000, rm = (R_MARS_KM + h2) * 1000;
  const dep = escapeBurn(MU_E, rp, vinf1), cap = escapeBurn(MU_MARS, rm, vinf2);
  const days = sun.coast / DAY, Tm = period(MU_SUN, r2) / DAY, phi = 180 - (360 * days) / Tm;
  const ve = veOf(isp), total = dep + cap;
  return {
    vinf1: vinf1 / 1000, vinf2: vinf2 / 1000, days, phi, dep: dep / 1000, cap: cap / 1000, total: total / 1000,
    frac: 100 * propFraction(total, ve), ve: ve / 1000, vLEO: vCirc(MU_E, rp) / 1000, h1, h2, isp,
  };
}

/* ---- the time engine: one step of Euler or symplectic Euler, toy or real units ---- */
export interface State { x: number; y: number; vx: number; vy: number }
export type Method = "euler" | "symplectic";
export function step(s: State, h: number, mu: number, m: Method): State {
  const r3 = Math.hypot(s.x, s.y) ** 3, ax = (-mu * s.x) / r3, ay = (-mu * s.y) / r3;
  if (m === "euler") return { x: s.x + h * s.vx, y: s.y + h * s.vy, vx: s.vx + h * ax, vy: s.vy + h * ay };
  const vx = s.vx + h * ax, vy = s.vy + h * ay;
  return { x: s.x + h * vx, y: s.y + h * vy, vx, vy };
}
export const energy = (s: State, mu: number) => (s.vx * s.vx + s.vy * s.vy) / 2 - mu / Math.hypot(s.x, s.y);

/** Sun units: AU and years, where μ☉ = 4π² */
export const MU_AU = 4 * Math.PI * Math.PI;
/** the Mars transfer flown with symplectic Euler at a step of h hours: the worst energy error over the flight, as a fraction */
export function transferDrift(hHours: number): number {
  const h = hHours / 24 / 365.25, at = (1 + PLANET_AU.Mars) / 2, tEnd = 0.5 * at ** 1.5;
  let s: State = { x: 1, y: 0, vx: 0, vy: Math.sqrt(MU_AU * (2 - 1 / at)) };
  const e0 = energy(s, MU_AU);
  let worst = 0;
  for (let t = 0; t < tEnd; t += h) {
    s = step(s, h, MU_AU, "symplectic");
    worst = Math.max(worst, Math.abs(energy(s, MU_AU) - e0) / Math.abs(e0));
  }
  return worst;
}
/** the largest whole number of hours that keeps the transfer's energy within 0.1% */
export function bestStepHours(): number {
  let best = 1;
  for (let h = 1; h <= 48; h++) if (transferDrift(h) <= 0.001) best = h;
  return best;
}

/**
 * Where a body launched from (x, y) with velocity (vx, vy) is after time t, on its conic (Kepler's equation, solved by
 * Newton's method). Works for ellipses and hyperbolas; an exact parabola is nudged a hair faster. Returns null for a
 * straight fall (no sideways speed).
 */
export function propagator(mu: number, x: number, y: number, vx: number, vy: number) {
  let c = conicOf(mu, x, y, vx, vy);
  if (Math.abs(c.e - 1) < 2e-4) { vx *= 1.0004; vy *= 1.0004; c = conicOf(mu, x, y, vx, vy); }
  if (Math.abs(x * vy - y * vx) < 1e-12 * Math.hypot(x, y) * Math.hypot(vx, vy) || !Number.isFinite(c.a)) return null;
  const { e, a, w, dir } = c, nu0 = dir * (Math.atan2(y, x) - w);
  const at = (nu: number, r: number) => ({ x: r * Math.cos(w + dir * nu), y: r * Math.sin(w + dir * nu), r });
  if (e < 1) {
    const n = Math.sqrt(mu / a ** 3), E0 = 2 * Math.atan(Math.sqrt((1 - e) / (1 + e)) * Math.tan(nu0 / 2)), M0 = E0 - e * Math.sin(E0);
    return { conic: c, period: (2 * Math.PI) / n, pos(t: number) {
      const M = M0 + n * t;
      let E = M;
      for (let k = 0; k < 30; k++) { const d = (E - e * Math.sin(E) - M) / (1 - e * Math.cos(E)); E -= d; if (Math.abs(d) < 1e-12) break; }
      return at(2 * Math.atan2(Math.sqrt(1 + e) * Math.sin(E / 2), Math.sqrt(1 - e) * Math.cos(E / 2)), a * (1 - e * Math.cos(E)));
    } };
  }
  const n = Math.sqrt(mu / (-a) ** 3), F0 = 2 * Math.atanh(Math.sqrt((e - 1) / (e + 1)) * Math.tan(nu0 / 2)), M0 = e * Math.sinh(F0) - F0;
  return { conic: c, period: Infinity, pos(t: number) {
    const M = M0 + n * t;
    let F = Math.asinh(M / e);
    for (let k = 0; k < 50; k++) { const d = (e * Math.sinh(F) - F - M) / (e * Math.cosh(F) - 1); F -= d; if (Math.abs(d) < 1e-12) break; }
    return at(2 * Math.atan(Math.sqrt((e + 1) / (e - 1)) * Math.tanh(F / 2)), a * (1 - e * Math.cosh(F)));
  } };
}
