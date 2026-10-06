// The small-speed curve (Grapher 2D, relativity.md): γ against β with its parabola 1 + β²/2 overlaid, and a zoom to
// everyday speeds. Zoomed, both axes go logarithmic (γ − 1 against β), so a speed of 0.25 km/s and one of 0.99c
// sit on one picture, and the two curves lie on top of each other until near light speed. With `day` (re-09's
// reveal) a day clock runs a whole day at 10⁴ times speed and counts what the moving clock has lost so far.
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle, useClock, useFollowProp, useSvgDrag } from "../../../ui/kit";
import { showValue } from "../../../tools/expr";
import { C_KMS, gammaMinus1, gammaOf } from "../physics";

const W = 360, H = 250, L = 48, R = 344, T = 14, B = 214;
/** the day clock's pace: a day of 86,400 s in 8.64 s */
const DAY_PACE = 1e4;

export function SmallSpeedScene({ props }: SceneProps) {
  const [zoom, setZoom] = useState(flag(props, "zoom"));
  const [beta, setBeta] = useState(num(props, "beta", 0.3));
  useFollowProp(props, num(props, "beta", 0.3), beta, setBeta);
  const quiet = flag(props, "quiet"), day = flag(props, "day") && !quiet;
  // with less motion the clock shows the whole day at once
  const t = useClock(day, 86400 / DAY_PACE);
  const { ref, drag } = useSvgDrag();
  const g1 = gammaMinus1(beta), par = (beta * beta) / 2, vk = beta * C_KMS;
  // what the moving clock loses per day: the fraction 1 − 1/γ = (γ − 1)/γ of 86,400 s (v²/2c² only at low speed)
  const lossUs = (g1 / (1 + g1)) * 86400e6;
  const hours = Math.min(24, (t * DAY_PACE) / 3600), lostSoFar = lossUs * (hours / 24);
  const lossText = (us: number) => (us >= 1e6 ? `${showValue(us / 1e6, 3)} s` : `${showValue(us, 3)} μs`);
  // plain: β 0…0.98, γ 1…4. Zoomed: log β from 10⁻⁷ to 1, log(γ − 1) from 10⁻¹⁴ to 10
  const X = zoom ? (b: number) => L + ((Math.log10(b) + 7) / 7) * (R - L) : (b: number) => L + (b / 0.98) * (R - L);
  const Yg = zoom ? (y: number) => B - ((Math.log10(Math.max(y, 1e-15)) + 14) / 15) * (B - T) : (y: number) => B - ((y - 1) / 3) * (B - T);
  const curve = (f: (b: number) => number) => {
    const pts: [number, number][] = [];
    for (let i = 0; i <= 160; i++) {
      const b = zoom ? 10 ** (-7 + (7 * i) / 160) * 0.999 : (0.98 * i) / 160;
      const y = f(b);
      if (Number.isFinite(y)) pts.push([X(b), Math.max(T - 40, Yg(y))]);
    }
    return path(pts);
  };
  const fromX = (px: number) => zoom ? 10 ** (((px - L) / (R - L)) * 7 - 7) : ((px - L) / (R - L)) * 0.98;
  const set = (b: number) => setBeta(Math.min(0.98, Math.max(zoom ? 1e-7 : 0, b)));
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic ss" role="img" aria-label={`γ against β with the parabola 1 + β²/2. At ${showValue(vk, 4)} km/s, γ − 1 is ${showValue(g1, 3)}.`}>
      <defs><clipPath id="ssclip"><rect x={L} y={T} width={R - L} height={B - T} /></clipPath></defs>
      <line x1={L} y1={B} x2={R} y2={B} className="b2axis" />
      <line x1={L} y1={T} x2={L} y2={B} className="b2axis" />
      {(zoom ? [-6, -4, -2, 0] : [0.25, 0.5, 0.75]).map(v => (
        <g key={v}>
          <line x1={X(zoom ? 10 ** v : v)} y1={T} x2={X(zoom ? 10 ** v : v)} y2={B} className="b2grid" />
          <text x={X(zoom ? 10 ** v * 0.999 : v)} y={B + 16} textAnchor="middle" className="b2t">{zoom ? (v === 0 ? "1" : `10${String(v).replace("-", "⁻").replace(/\d/g, d => "⁰¹²³⁴⁵⁶⁷⁸⁹"[+d]!)}`) : v}</text>
        </g>
      ))}
      <text x={R} y={B + 32} textAnchor="end" className="b2t">β</text>
      <text x={L + 6} y={T + 14} className="b2t">{zoom ? "γ − 1 (log)" : "γ"}</text>
      <g clipPath="url(#ssclip)">
        <path d={curve(b => (zoom ? b * b / 2 : 1 + b * b / 2))} className="b2curve pink" />
        <path d={curve(b => (zoom ? gammaMinus1(b) : gammaOf(b)))} className="b2curve sky" />
      </g>
      <line x1={X(beta)} y1={T} x2={X(beta)} y2={B} className="b2mark amber" />
      <circle cx={X(beta)} cy={B} r="9" className="b2handle" />
      <rect x={L} y={B - 16} width={R - L} height="40" className="b2hit" {...drag(x => set(fromX(x)))} />
      <text x={R - 4} y={T + 14} textAnchor="end" className="b2t sky">{zoom ? "γ − 1" : "γ"}</text>
      <text x={R - 4} y={T + 32} textAnchor="end" className="b2t pink">{zoom ? "β²/2" : "1 + β²/2"}</text>
      {day && (() => {
        // the day clock: one turn of the hand is a day; it stops at 24 h
        const cx = L + 36, cy = T + 60, rr = 24, a = (hours / 24) * 2 * Math.PI;
        return <g aria-hidden="true">
          <circle cx={cx} cy={cy} r={rr} className="b2clock amber" />
          <line x1={cx} y1={cy} x2={cx + rr * 0.8 * Math.sin(a)} y2={cy - rr * 0.8 * Math.cos(a)} className="b2curve amber" />
          <text x={cx + rr + 8} y={cy - 4} className="b2t">{Math.floor(hours)} h of a day</text>
          <text x={cx + rr + 8} y={cy + 14} className="b2t amber">clock behind {lossText(lostSoFar)}</text>
        </g>;
      })()}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {zoom
          ? <Slider label="Speed" value={Math.log10(beta)} min={-7} max={Math.log10(0.98)} step={0.01} onChange={x => set(10 ** x)} format={x => `${showValue(10 ** x * C_KMS, 3)} km/s`} />
          : <Slider label="Speed β" value={beta} min={0} max={0.98} step={0.005} onChange={set} format={x => `${fx(x, 3)}c`} />}
        <Toggle label="Zoom" value={zoom ? "z" : "p"} onChange={v => { setZoom(v === "z"); if (v === "p" && beta < 0.01) setBeta(0.3); }} options={[{ v: "p", label: "Up to c" }, { v: "z", label: "Everyday speeds" }]} />
      </>}
      readouts={<>
        <Read label="v" value={`${showValue(vk, 4)} km/s`} />
        {!quiet && <Read label="γ − 1" value={showValue(g1, 4)} tone="sky" />}
        {!quiet && <Read label="β²/2" value={showValue(par, 4)} tone="pink" />}
        {!quiet && <Read label="Clock loses per day" value={lossText(lossUs)} tone="amber" />}
      </>}
    />
  );
}
SmallSpeedScene.liveReveal = true;
