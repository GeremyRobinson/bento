// Coins without values (design/pictures-k4.md §3, g2-coins): true relative sizes, copper or silver, a smooth or ridged
// rim and the same original art on every coin (a star for heads, two leaves for tails), so only size, color and edge
// tell coins apart. Nothing on a coin names it or prints its value.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, M, L, Z, type Draft, type Pt, type Seg } from "../geo/kit";

export const COIN_INFO = [
  { name: "penny", value: 1, mm: 19.05, copper: true, ridged: false },
  { name: "nickel", value: 5, mm: 21.21, copper: false, ridged: false },
  { name: "dime", value: 10, mm: 17.91, copper: false, ridged: true },
  { name: "quarter", value: 25, mm: 24.26, copper: false, ridged: true },
] as const;

/** what you can see of a coin, never its name: for alt text */
export function coinLook(coin: number): string {
  const c = COIN_INFO[coin]!;
  const size = ["small", "medium", "tiny", "big"][coin]!;
  return `a ${size} ${c.copper ? "copper-colored" : "silver"} coin with a ${c.ridged ? "bumpy" : "smooth"} edge`;
}

const PX = 4;
type Timing = { from?: number; until?: number; enter?: Draft["enter"]; delay?: number };

function star(c: Pt, r: number): Seg[] {
  const pts = Array.from({ length: 10 }, (_, i): Pt => {
    const a = -Math.PI / 2 + (Math.PI * i) / 5, rr = i % 2 ? r * 0.42 : r;
    return [c[0] + rr * Math.cos(a), c[1] + rr * Math.sin(a)];
  });
  return [M(pts[0]!), ...pts.slice(1).map(L), Z];
}

/** a leaf from its stem at c, pointing at angle a (radians), length len */
function leaf(c: Pt, a: number, len: number): Seg[] {
  const tip: Pt = [c[0] + len * Math.cos(a), c[1] + len * Math.sin(a)], n: Pt = [-Math.sin(a), Math.cos(a)], w = len * 0.32;
  const m = (k: number): Pt => [(c[0] + tip[0]) / 2 + n[0] * w * k, (c[1] + tip[1]) / 2 + n[1] * w * k];
  return [M(c), { c: "Q", q: m(1), p: tip }, { c: "Q", q: m(-1), p: c }, Z];
}

/** one coin centered at c; side 0 heads (a star), 1 tails (two leaves) */
export function coinShape(coin: number, c: Pt, side: number, o: Timing = {}): Draft[] {
  const info = COIN_INFO[coin]!, r = (info.mm * PX) / 2, metal = info.copper ? "cu" : "ag", items: Draft[] = [];
  items.push({ type: "circle", cx: c[0], cy: c[1], r, cls: `coin ${metal}`, ...o } as Draft);
  if (info.ridged) {
    const segs: Seg[] = [];
    for (let i = 0; i < 60; i++) {
      const a = (2 * Math.PI * i) / 60, u: Pt = [Math.cos(a), Math.sin(a)];
      segs.push(M([c[0] + u[0] * (r - 1.5), c[1] + u[1] * (r - 1.5)]), L([c[0] + u[0] * (r - 4.5), c[1] + u[1] * (r - 4.5)]));
    }
    items.push({ type: "path", segs, cls: `coin-ridge ${metal}`, ...o } as Draft);
  }
  items.push({ type: "circle", cx: c[0], cy: c[1], r: r * 0.72, cls: `coin-art ${metal}`, ...o } as Draft);
  if (side === 0) items.push({ type: "path", segs: star(c, r * 0.42), cls: `coin-art ${metal}`, ...o } as Draft);
  else {
    const base: Pt = [c[0], c[1] + r * 0.36];
    items.push({ type: "path", segs: leaf(base, -Math.PI / 2 - 0.5, r * 0.62), cls: `coin-art ${metal}`, ...o } as Draft);
    items.push({ type: "path", segs: leaf(base, -Math.PI / 2 + 0.5, r * 0.62), cls: `coin-art ${metal}`, ...o } as Draft);
  }
  return items;
}

export interface CoinPictureSpec {
  /** one coin, or two side by side (left, right) */
  coins: number[];
  side: number;
  /** beats: the edge traced; each coin's value written under it (and the bigger value marked) */
  beats?: { edge: number; value: number };
  alt: string;
}

export function buildCoinPicture(s: CoinPictureSpec): SceneDiagram {
  if (s.coins.length < 1 || s.coins.length > 2 || s.coins.some(c => !COIN_INFO[c])) throw new Error("coins: one or two coins");
  const items: Draft[] = [], b = s.beats;
  const rs = s.coins.map(c => (COIN_INFO[c]!.mm * PX) / 2), big = Math.max(...rs);
  const gap = 1.5 * 2 * big, xs = s.coins.map((_, i) => i * gap);
  const vals: number[] = s.coins.map(c => COIN_INFO[c]!.value), best = vals.indexOf(Math.max(...vals));
  s.coins.forEach((coin, i) => {
    // one baseline: every coin sits on the same line
    const c: Pt = [xs[i]!, big - rs[i]!];
    items.push(...coinShape(coin, c, (s.side + i) % 2));
    if (s.coins.length === 2) items.push(t(c[0], big + 26, i ? "Right" : "Left", "sm"));
    if (b) {
      items.push({ type: "circle", cx: c[0], cy: c[1], r: rs[i]! + 5, cls: "ring", from: b.edge, until: b.edge, enter: "draw", delay: 0.4 * i } as Draft);
      items.push(t(c[0], -big - 22, COIN_INFO[coin]!.ridged ? "bumpy edge" : "smooth edge", "sm", { from: b.edge, until: b.edge, enter: "rise", delay: 0.4 * i + 0.3 }));
      const one = s.coins.length === 1 || i === best;
      items.push(t(c[0], big + (s.coins.length === 2 ? 58 : 34), `${vals[i]} ${vals[i] === 1 ? "cent" : "cents"}`, one ? "lbl acc" : "lbl", { from: b.value, enter: "rise", delay: 0.3 * i }));
    }
  });
  return frame("coins", items, s.alt, 14, { w: 260 });
}
