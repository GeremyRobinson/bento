// Pieces several quantum pictures share: a run of shots that plays out over a few seconds (Less motion jumps to the
// end), shot bars against their predicted chances, and amplitudes written the way the lessons write them.
import { useEffect, useState } from "react";
import { reduceMotion } from "../../../../app/transition";
import { fx } from "../../../ui/kit";
import { formatAnswer, toFraction } from "../../../steps";

/** A run that plays for `dur` seconds after run() is called; `k` goes 0 → 1. With Less motion it ends at once. */
export function useRun(dur: number, auto = false) {
  const [n, setN] = useState(auto ? 1 : 0);
  const [t, setT] = useState(0);
  useEffect(() => {
    if (!n) return;
    if (reduceMotion()) { setT(dur); return; }
    let raf = 0;
    const t0 = performance.now();
    const tick = (now: number) => { const e = (now - t0) / 1000; setT(Math.min(dur, e)); if (e < dur) raf = requestAnimationFrame(tick); };
    setT(0);
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [n, dur]);
  return { runs: n, k: n ? t / dur : 0, done: n > 0 && t >= dur, run: () => setN(x => x + 1) };
}

/** shots shown so far: slow at first, so the first few dots read one at a time, then the pile fills in */
export const shownOf = (k: number, n: number) => Math.round(n * k ** 2);

/** an amplitude as a short fraction (3/5), over √2 (7/5/√2 → "7/5√2"), or to 2 places */
export function amp(x: number): string {
  if (Math.abs(x) < 1e-9) return "0";
  const nice = (v: number) => { const [p, q] = toFraction(v); return Math.abs(p / q - v) < 1e-9 && q <= 100 ? formatAnswer(v, "fraction") : null; };
  const a = nice(x);
  if (a) return a;
  const b = nice(x * Math.SQRT2);
  if (b) return b === "1" ? "1/√2" : b === "−1" ? "−1/√2" : `${b}/√2`.replace(/^(−?\d+)\/(\d+)\/√2$/, "$1/($2√2)");
  return fx(x, 2);
}
/** a complex amplitude: "0.71", "0.5i", "0.5 − 0.5i" */
export function ampC(re: number, im: number): string {
  if (Math.abs(im) < 1e-9) return amp(re);
  const i = Math.abs(im), is = `${Math.abs(i - 1) < 1e-9 ? "" : amp(i)}i`;
  if (Math.abs(re) < 1e-9) return `${im < 0 ? "−" : ""}${is}`;
  return `${amp(re)} ${im < 0 ? "−" : "+"} ${is}`;
}

/** colour classes for outcomes: one qubit (0, 1) and two qubits (00, 01, 10, 11) */
export const TONE1 = ["sky", "pink"];
export const TONE2 = ["sky", "mint", "amber", "trav"];

/**
 * Bars for counts out of n shots, each against a dashed line at its predicted chance. Drawn in a box at (x, y) of
 * size w × h; `hideP` keeps the predictions back (a guess). Labels go under the bars.
 */
export function ShotBars({ x, y, w, h, labels, ps, counts, n, tones, hideP, guess }: {
  x: number; y: number; w: number; h: number; labels: string[]; ps: number[]; counts: number[]; n: number; tones: string[]; hideP?: boolean; guess?: number;
}) {
  const k = labels.length, gap = 8, bw = (w - gap * (k - 1)) / k;
  return (
    <g>
      <line x1={x - 4} y1={y + h} x2={x + w + 4} y2={y + h} className="b2axis" />
      {labels.map((l, i) => {
        const bx = x + i * (bw + gap), c = n ? counts[i]! / n : 0;
        return (
          <g key={l} className={tones[i]}>
            <rect x={bx} y={y} width={bw} height={h} rx="4" className="b2bar track" />
            <rect x={bx} y={y + h - c * h} width={bw} height={Math.max(0, c * h)} rx="4" className="b2bar" />
            {!hideP && <line x1={bx - 3} y1={y + h - ps[i]! * h} x2={bx + bw + 3} y2={y + h - ps[i]! * h} className="b2mark" />}
            <text x={bx + bw / 2} y={y + h + 17} textAnchor="middle" className="b2t">{l}</text>
          </g>
        );
      })}
      {guess != null && <line x1={x - 6} y1={y + h - guess * h} x2={x + w + 6} y2={y + h - guess * h} className="b2mark guess" />}
    </g>
  );
}
