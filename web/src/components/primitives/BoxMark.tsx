import { useEffect, useRef, useState } from "react";
import { motionOff } from "../../app/settings";

/**
 * The logo mark (G 2026-10-07 22:54): an outlined bento box whose compartments keep rearranging, two squares and a
 * rectangle, four squares, a rectangle with half squares, settling into each new layout with a steady rubber-band
 * stretch. Outline only, in the ink colour, like the wordmark. Four compartments always exist; a layout with fewer
 * lays two of them on the same spot, so they merge into one outline and split apart again on the next change.
 * Less motion: it holds the first layout.
 */

/** a compartment as fractions of the box's inside: left, top, right, bottom */
type Box = [number, number, number, number];
export const LAYOUTS: Box[][] = [
  // two squares over a rectangle
  [[0, 0, .5, .5], [.5, 0, 1, .5], [0, .5, 1, 1], [0, .5, 1, 1]],
  // a rectangle down the left, two squares beside it
  [[0, 0, .5, 1], [.5, 0, 1, .5], [.5, .5, 1, 1], [0, 0, .5, 1]],
  // four squares
  [[0, 0, .5, .5], [.5, 0, 1, .5], [0, .5, .5, 1], [.5, .5, 1, 1]],
  // a rectangle on top, a square and two half squares under it
  [[0, 0, 1, .5], [0, .5, .5, 1], [.5, .5, .75, 1], [.75, .5, 1, 1]],
  // a rectangle over two squares
  [[0, 0, 1, .5], [0, .5, .5, 1], [.5, .5, 1, 1], [0, 0, 1, .5]],
  // two half squares and a square over a rectangle
  [[0, 0, .25, .5], [.25, 0, .5, .5], [.5, 0, 1, .5], [0, .5, 1, 1]],
];

const VIEW = 100, PAD = 12, GAP = 7, IN = VIEW - PAD * 2;
/** a compartment's edges in the drawing, the gap split between neighbours */
function place([l, t, r, b]: Box) {
  const x0 = PAD + l * IN + (l > 0 ? GAP / 2 : 0), x1 = PAD + r * IN - (r < 1 ? GAP / 2 : 0);
  const y0 = PAD + t * IN + (t > 0 ? GAP / 2 : 0), y1 = PAD + b * IN - (b < 1 ? GAP / 2 : 0);
  return [x0, y0, x1, y1];
}

/** how long a layout holds, and the spring that carries it to the next: soft enough to overshoot and come back */
const HOLD_MS = 2600, STIFF = 90, DAMP = 9;

export function BoxMark({ className, size = 32, label = "obento" }: { className?: string; size?: number; label?: string }) {
  const [edges, setEdges] = useState(() => LAYOUTS[0]!.map(place));
  const live = useRef({ pos: LAYOUTS[0]!.map(place).flat(), vel: new Array(16).fill(0), goal: LAYOUTS[0]!.map(place).flat() });

  useEffect(() => {
    if (motionOff()) return;
    let i = 0, raf = 0, last = performance.now();
    const next = setInterval(() => { i = (i + 1) % LAYOUTS.length; live.current.goal = LAYOUTS[i]!.map(place).flat(); }, HOLD_MS);
    const tick = (now: number) => {
      const dt = Math.min(0.032, (now - last) / 1000); last = now;
      const s = live.current;
      for (let k = 0; k < 16; k++) {
        const a = -STIFF * (s.pos[k]! - s.goal[k]!) - DAMP * s.vel[k]!;
        s.vel[k]! += a * dt; s.pos[k]! += s.vel[k]! * dt;
      }
      setEdges([0, 1, 2, 3].map(j => s.pos.slice(j * 4, j * 4 + 4)));
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => { clearInterval(next); cancelAnimationFrame(raf); };
  }, []);

  return (
    <svg className={`boxmark${className ? ` ${className}` : ""}`} viewBox={`0 0 ${VIEW} ${VIEW}`} width={size} height={size} role="img" aria-label={label}>
      <rect className="bx-box" x="3" y="3" width={VIEW - 6} height={VIEW - 6} rx="22" />
      {edges.map(([x0, y0, x1, y1], j) => (
        <rect key={j} className="bx-cell" x={x0} y={y0} width={Math.max(0, x1! - x0!)} height={Math.max(0, y1! - y0!)} rx="10" />
      ))}
    </svg>
  );
}
