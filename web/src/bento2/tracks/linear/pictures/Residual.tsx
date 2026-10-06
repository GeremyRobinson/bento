// Residual squares (linear-algebra.md, "New pictures"): data points and a line; each point's miss drawn as a square,
// and the total area is the error. The Guess draws your line through the data's center; the reveal adds the
// least-squares line and both totals. It is also the project "Line through the noise": type 4 to 8 points of your own,
// fit them, and keep `fit`.
import { useEffect, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, Toggle, useSvgDrag, useTween } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { Grid, ink, plane, tint } from "./plane";

const DATA: Record<string, { label: string; x: string; y: string; pts: [number, number][] }> = {
  lesson: { label: "These points", x: "x", y: "y", pts: [[0, 1], [1, 3], [2, 2], [3, 5]] },
  battery: { label: "Phone battery", x: "minutes ÷ 10", y: "battery ÷ 10", pts: [[0, 9.8], [1, 9.1], [2, 8.5], [3, 7.6], [4, 7.1], [5, 6.2]] },
  plant: { label: "Plant height", x: "days", y: "cm", pts: [[1, 2], [2, 2.5], [3, 3.5], [4, 3.8], [5, 5], [6, 5.4]] },
};

/** the least-squares line through points, by the centered sums */
export function lsq(pts: [number, number][]): { m: number; c: number } {
  const n = pts.length, mx = pts.reduce((s, p) => s + p[0], 0) / n, my = pts.reduce((s, p) => s + p[1], 0) / n;
  const sxx = pts.reduce((s, p) => s + (p[0] - mx) ** 2, 0), sxy = pts.reduce((s, p) => s + (p[0] - mx) * (p[1] - my), 0);
  const m = sxx ? sxy / sxx : 0;
  return { m, c: my - m * mx };
}
const area = (pts: [number, number][], m: number, c: number) => pts.reduce((s, [x, y]) => s + (y - (m * x + c)) ** 2, 0);

export function ResidualScene({ props, place, marker }: SceneProps) {
  const project = flag(props, "project") || place === "project";
  const quiet = flag(props, "quiet") || flag(props, "hide");
  const [set, setSet] = useState<string>(str(props, "set", project ? "battery" : "lesson"));
  const [pts, setPts] = useState<[number, number][]>(() => {
    const xs = str<string>(props, "xs", ""), ys = str<string>(props, "ys", "");
    if (xs && ys) { const a = xs.split(",").map(Number), b = ys.split(",").map(Number); return a.map((x, i) => [x, b[i]!] as [number, number]); }
    return DATA[set]!.pts.map(q => [...q] as [number, number]);
  });
  const best = lsq(pts);
  const mx = pts.reduce((s, q) => s + q[0], 0) / pts.length, my = pts.reduce((s, q) => s + q[1], 0) / pts.length;
  const [m, setM] = useState(num(props, "m", Math.round((best.m + 0.6) * 4) / 4));
  const [c, setC] = useState(num(props, "c", Math.round((my - (best.m + 0.6) * mx) * 4) / 4));
  const { ref, drag } = useSvgDrag();
  const { b2, save, note } = useB2();
  // the Guess: your slope, through the center of the data
  const guessM = marker ? marker[0] : null;
  const lineM = guessM ?? m, lineC = guessM != null ? my - guessM * mx : c;
  const showBest = flag(props, "best") || project;
  const [g, setG] = useState(0);
  const tb = useTween(g, 1200);
  useEffect(() => { if (flag(props, "best")) setG(1); }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const xs = pts.map(q => q[0]), ys = pts.map(q => q[1]);
  const x0 = Math.min(0, ...xs) - 1, x1 = Math.max(...xs) + 1.5;
  const y0 = Math.min(0, ...ys) - 1, y1 = Math.max(...ys) + 2;
  const p = plane(x0, x1, y0, y1, 360, 270);
  const yourArea = area(pts, lineM, lineC), bestArea = area(pts, best.m, best.c);
  const L = (mm: number, cc: number) => ({ x1: p.X(p.x0), y1: p.Y(mm * p.x0 + cc), x2: p.X(p.x1), y2: p.Y(mm * p.x1 + cc) });

  const squares = (mm: number, cc: number, tone: "sky" | "amber", o: number) => pts.map(([x, y], i) => {
    const r = y - (mm * x + cc), side = Math.abs(r);
    // the square stands on the miss, on the side away from the line's slope so squares overlap less
    const left = x + side > p.x1 - 0.2;
    return <rect key={`${tone}${i}`} x={p.X(left ? x - side : x)} y={p.Y(Math.max(y, y - r))} width={side * p.s} height={side * p.s} style={{ ...tint(tone, 0.16 * o), ...ink(tone, 1), opacity: o }} />;
  });

  const svg = (
    <svg ref={ref} viewBox="0 0 360 270" className="b2pic" role="img" aria-label={quiet ? `${pts.length} data points and your line.` : `${pts.length} data points and a line; the squares of the misses add to ${fx(yourArea, 2)}.`}>
      <Grid p={p} />
      {!quiet && squares(lineM, lineC, "sky", 1)}
      {showBest && tb > 0.02 && squares(best.m, best.c, "amber", tb)}
      <line {...L(lineM, lineC)} style={ink("sky", 2.5)} />
      {showBest && <line {...L(best.m, best.c)} style={{ ...ink("amber", 2.5, "7 4"), opacity: tb }} />}
      {pts.map(([x, y], i) => (
        <g key={i}>
          <line x1={p.X(x)} y1={p.Y(y)} x2={p.X(x)} y2={p.Y(lineM * x + lineC)} style={ink("pink", 1.5)} />
          <circle cx={p.X(x)} cy={p.Y(y)} r="5.5" className="b2dot pink" />
          {!quiet && !project && <circle cx={p.X(x)} cy={p.Y(y)} r="16" className="b2hit" {...drag((px, py) => { const [, Y] = p.back(px, py); setPts(ps => ps.map((q, j) => (j === i ? [q[0], Math.round(Y * 10) / 10] : q))); })} />}
        </g>
      ))}
      <circle cx={p.X(mx)} cy={p.Y(my)} r="4" className="b2dot trav" />
    </svg>
  );
  const editor = project && (
    <div style={BOX} role="group" aria-label="Your points, x and y">
      {pts.map(([x, y], i) => (
        <span key={`${set}-${i}`} style={PT}>
          <input style={IN} inputMode="decimal" aria-label={`Point ${i + 1} x`} defaultValue={String(x)} onChange={e => { const t = e.currentTarget.value.replace("−", "-").trim(), v = Number(t); if (t && Number.isFinite(v)) setPts(ps => ps.map((q, j) => (j === i ? [v, q[1]] : q))); }} />
          <input style={IN} inputMode="decimal" aria-label={`Point ${i + 1} y`} defaultValue={String(y)} onChange={e => { const t = e.currentTarget.value.replace("−", "-").trim(), v = Number(t); if (t && Number.isFinite(v)) setPts(ps => ps.map((q, j) => (j === i ? [q[0], v] : q))); }} />
        </span>
      ))}
      <button type="button" className="ctl" disabled={pts.length >= 8} onClick={() => setPts(ps => [...ps, [ps[ps.length - 1]![0] + 1, ps[ps.length - 1]![1]]])}>Add a point</button>
      <button type="button" className="ctl" disabled={pts.length <= 4} onClick={() => setPts(ps => ps.slice(0, -1))}>Remove one</button>
    </div>
  );
  const fit = [round4(best.m), round4(best.c)];
  const saved = JSON.stringify(b2.shelf.fit?.value) === JSON.stringify(fit);
  return (
    <Scene svg={svg}
      controls={guessM == null ? <>
        {project && <Toggle label="Data" value={set} onChange={s => { setSet(s); setPts(DATA[s]!.pts.map(q => [...q] as [number, number])); }} options={[{ v: "battery", label: "Battery" }, { v: "plant", label: "Plant" }]} />}
        {!project && <Slider label="Your line's slope" value={m} min={-3} max={3} step={0.05} onChange={setM} format={v => fx(v, 2)} />}
        {!project && <Slider label="Your line's height at x = 0" value={c} min={-4} max={10} step={0.05} onChange={setC} format={v => fx(v, 2)} />}
        {editor}
      </> : undefined}
      readouts={<>
        {!project && <Read label="Your line" value={`y = ${fx(lineM, 2)}x ${lineC < 0 ? "−" : "+"} ${fx(Math.abs(lineC), 2)}`} tone="sky" />}
        {!project && !quiet && <Read label="Your squares add to" value={fx(yourArea, 2)} tone="sky" />}
        {showBest && <Read label="Least squares" value={`y = ${fx(best.m, 2)}x ${best.c < 0 ? "−" : "+"} ${fx(Math.abs(best.c), 2)}`} tone="amber" />}
        {showBest && <Read label="Its squares add to" value={fx(bestArea, 2)} tone="amber" />}
      </>}
      foot={project ? <SaveRow what={<>Keep <b>fit</b> = slope {fx(best.m, 2)}, intercept {fx(best.c, 2)}</>} saved={saved} onSave={() => {
        save("fit", fit, "la-fit", { labels: ["slope", "intercept"], note: `${pts.length} points, squared error ${fx(bestArea, 2)}` });
        note({ id: "la-fit", track: "la", title: "Line through the noise", project: "la-fit", data: { m: best.m, c: best.c, n: pts.length },
          lines: [`${pts.length} points: ${pts.map(q => `(${q[0]}, ${q[1]})`).join(", ")}.`, `Best line y = ${fx(best.m, 2)}x ${best.c < 0 ? "−" : "+"} ${fx(Math.abs(best.c), 2)}, squared error ${fx(bestArea, 2)}.`] });
      }} /> : undefined}
    />
  );
}
const round4 = (x: number) => Math.round(x * 10000) / 10000;
const BOX: React.CSSProperties = { display: "flex", flexWrap: "wrap", alignItems: "center", gap: 6 };
const PT: React.CSSProperties = { display: "inline-flex", gap: 2, padding: 2, borderRadius: "var(--r-sm)", boxShadow: "inset 0 0 0 1px var(--adv-hair)" };
const IN: React.CSSProperties = { width: 46, minHeight: 34, border: "none", borderRadius: "var(--r-sm)", background: "var(--well)", color: "var(--text)", textAlign: "center", fontSize: "var(--fz-sm)", fontVariantNumeric: "tabular-nums" };
