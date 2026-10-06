// The Bayes box (probability.md, "New for Development"): (a) people mode, 10,000 people split by condition and test,
// positives boxed (04, the screening card project); (b) ideas mode, 1,000 tested ideas split by real or not and
// significant or not (16, 20); (c) "Test again", which makes the posterior the new prior. Each small square is one
// person or one idea, filled column by column, so every group is one block you can compare by eye.
import { useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, Toggle } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { Act, Acts, commas, K, lin } from "./parts";

const W = 360, H = 240;

/** blocks for consecutive ranges of cells laid out column by column (rows per column), as rects */
function blocks(counts: number[], rows: number, cell: number, ox: number, oy: number) {
  const out: { x: number; y: number; w: number; h: number; g: number }[] = [];
  let at = 0;
  counts.forEach((c, g) => {
    let s = at; const e = at + c; at = e;
    while (s < e) {
      const col = Math.floor(s / rows), r0 = s % rows;
      if (r0 === 0 && e - s >= rows) {
        const cols = Math.floor((e - s) / rows);
        out.push({ x: ox + col * cell, y: oy, w: cols * cell, h: rows * cell, g });
        s += cols * rows;
      } else {
        const r1 = Math.min(rows, r0 + (e - s));
        out.push({ x: ox + col * cell, y: oy + r0 * cell, w: cell, h: (r1 - r0) * cell, g });
        s += r1 - r0;
      }
    }
  });
  return out;
}
/** the outline of the first n cells (column by column) */
function outline(n: number, rows: number, cell: number, ox: number, oy: number) {
  if (n <= 0) return "";
  const full = Math.floor(n / rows), rest = n % rows;
  const x1 = ox + full * cell, y1 = oy + rest * cell;
  if (full === 0) return `M${ox},${oy} H${ox + cell} V${y1} H${ox} Z`;
  if (!rest) return `M${ox},${oy} H${x1} V${oy + rows * cell} H${ox} Z`;
  return `M${ox},${oy} H${x1 + cell} V${y1} H${x1} V${oy + rows * cell} H${ox} Z`;
}

export function BayesScene({ props, marker, place }: SceneProps) {
  const [mode, setMode] = useState<"people" | "ideas">(str<string>(props, "mode", "people") === "ideas" ? "ideas" : "people");
  const quiet = flag(props, "quiet"), project = flag(props, "project");
  const pick = place !== "lesson" && !project ? <Toggle label="Bayes box mode" value={mode} onChange={setMode} options={[{ v: "people", label: "People" }, { v: "ideas", label: "Ideas" }]} /> : null;
  return mode === "people" ? <People props={props} quiet={quiet} project={project} marker={marker} pick={pick} /> : <Ideas props={props} quiet={quiet} marker={marker} pick={pick} />;
}

type Part = { props: SceneProps["props"]; quiet: boolean; marker?: [number, number]; pick: React.ReactNode };

function People({ props, quiet, marker, pick, project }: Part & { project: boolean }) {
  const [prev, setPrev] = useState(num(props, "prev", 1));
  const [sens, setSens] = useState(num(props, "sens", 90));
  const [spec, setSpec] = useState(num(props, "spec", 90));
  const [times, setTimes] = useState(1);
  const { b2, save, note } = useB2();
  const N = 10000, have = Math.round((N * prev) / 100), healthy = N - have;
  const TP = Math.round((have * sens) / 100), FP = Math.round((healthy * (100 - spec)) / 100), FN = have - TP, TN = healthy - FP;
  const ppv = TP + FP ? TP / (TP + FP) : 0;
  const rows = 100, cell = 2.0, ox = 8, oy = 10;
  const groups = quiet ? [have, 0, 0, healthy] : [TP, FP, FN, TN];
  const fills = quiet ? [{ fill: K.pink, fillOpacity: 0.45 }, {}, {}, { fill: K.faint }] : [{ fill: K.pink }, { fill: K.amber }, { fill: K.pink, fillOpacity: 0.3 }, { fill: K.faint }];
  const bx = 290, by = lin(0, 1, 214, 22), cx = ox + 100 * cell + 6;
  const [line, setLine] = useState("");
  const sentence = line || `Of ${commas(TP + FP)} people who test positive, about ${commas(TP)} have it: ${fx(ppv * 100, 1)}%.`;
  const saved = Math.abs(((b2.shelf.ppv?.value as number) ?? NaN) - ppv) < 1e-12;
  const onSave = () => {
    save("ppv", ppv, "pr-screen", { note: `P(has it | positive) at ${fx(prev, 1)}% prevalence` });
    note({ id: "pr-screen", track: "pr", title: "A screening card", project: "pr-screen", data: { prev, sens, spec },
      lines: [`${fx(prev, 1)}% have it; the test catches ${fx(sens, 1)}% and clears ${fx(spec, 1)}% of healthy people.`, sentence] });
  };
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`10,000 people: ${commas(have)} have it.${quiet ? "" : ` ${commas(TP)} true positives and ${commas(FP)} false positives, so ${fx(ppv * 100, 1)}% of positives have it.`}`}>
      {blocks(groups, rows, cell, ox, oy).map((b, i) => <rect key={i} x={b.x} y={b.y} width={b.w} height={b.h} style={fills[b.g]} />)}
      {Array.from({ length: 9 }, (_, i) => <g key={i}>
        <line x1={ox + (i + 1) * 10 * cell} x2={ox + (i + 1) * 10 * cell} y1={oy} y2={oy + rows * cell} style={{ stroke: "var(--page)", strokeWidth: 0.6 }} />
        <line x1={ox} x2={ox + 100 * cell} y1={oy + (i + 1) * 10 * cell} y2={oy + (i + 1) * 10 * cell} style={{ stroke: "var(--page)", strokeWidth: 0.6 }} />
      </g>)}
      {!quiet && TP + FP > 0 && <path d={outline(TP + FP, rows, cell, ox, oy)} style={{ fill: "none", stroke: K.text, strokeWidth: 2 }} />}
      <text x={cx} y="120" className="b2t">of the</text>
      <text x={cx} y="138" className="b2t">positives,</text>
      <text x={cx} y="156" className="b2t">have it</text>
      <rect x={bx} y={by(1)} width="26" height={by(0) - by(1)} rx="4" style={{ fill: K.faint, fillOpacity: 0.5 }} />
      {!quiet && <rect x={bx} y={by(ppv)} width="26" height={by(0) - by(ppv)} rx="4" style={{ fill: K.pink }} />}
      {!quiet && <text x={bx + 32} y={by(ppv) + 5} className="b2t pink">{fx(ppv * 100, 1)}%</text>}
      {marker && <><line x1={bx - 6} x2={bx + 32} y1={by(marker[0] / 100)} y2={by(marker[0] / 100)} className="b2mark guess" /><text x={bx + 30} y={by(marker[0] / 100) + 18} className="b2t">guess</text></>}
      <text x={bx + 13} y={by(0) + 18} textAnchor="middle" className="b2t">0%</text>
      <text x={bx + 13} y={by(1) - 6} textAnchor="middle" className="b2t">100%</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Have it" value={prev} min={0.1} max={30} step={0.1} onChange={setPrev} format={x => `${fx(x, 1)}%`} marks={[{ v: 1, label: "1%" }, { v: 2, label: "2%" }, { v: 5, label: "5%" }, { v: 10, label: "10%" }]} />
        <Slider label="Catches (sensitivity)" value={sens} min={50} max={99.9} step={0.1} onChange={setSens} format={x => `${fx(x, 1)}%`} />
        <Slider label="Clears healthy (specificity)" value={spec} min={50} max={99.9} step={0.1} onChange={setSpec} format={x => `${fx(x, 1)}%`} />
        {!quiet && <Acts><Act onClick={() => { setPrev(Math.max(0.1, Math.min(99, Math.round(ppv * 1000) / 10))); setTimes(t => t + 1); }}>Test again{times > 1 ? ` (test ${times + 1})` : ""}</Act></Acts>}
        {pick}
      </>}
      readouts={<>
        <Read label="Have it" value={commas(have)} tone="pink" />
        {!quiet && <Read label="True positives" value={commas(TP)} tone="pink" />}
        {!quiet && <Read label="False positives" value={commas(FP)} tone="amber" />}
        {!quiet && <Read label="P(has it | positive)" value={`${fx(ppv * 100, 1)}%`} big />}
        {!quiet && <Read label="Missed" value={commas(FN)} />}
        {!quiet && <Read label="Cleared" value={commas(TN)} />}
      </>}
      foot={project && <>
        <label className="b2slider"><span className="b2sl"><span>What a positive means, in your words</span></span>
          <input type="text" value={line} placeholder={sentence} onChange={e => setLine(e.currentTarget.value)} style={{ minHeight: "36px", borderRadius: "10px", padding: "0 10px", background: "var(--well)", color: "var(--text)", border: "1px solid var(--faint)" }} /></label>
        <SaveRow what={<>Keep <b>ppv = {fx(ppv, 3)}</b> and the card in your Notebook</>} saved={saved} onSave={onSave} />
      </>}
    />
  );
}

function Ideas({ props, quiet, marker, pick }: Part) {
  const [real, setReal] = useState(num(props, "real", 10));
  const [power, setPower] = useState(num(props, "power", 80));
  const [alpha, setAlpha] = useState(num(props, "alpha", 5));
  const N = 1000, R = Math.round((N * real) / 100), hits = Math.round((R * power) / 100), F = Math.round(((N - R) * alpha) / 100);
  const share = hits + F ? F / (hits + F) : 0;
  const rows = 25, cell = 5.0, ox = 8, oy = 10;
  const groups = quiet ? [R, 0, 0, N - R] : [hits, F, R - hits, N - R - F];
  const fills = quiet ? [{ fill: K.pink, fillOpacity: 0.45 }, {}, {}, { fill: K.faint }] : [{ fill: K.pink }, { fill: K.amber }, { fill: K.pink, fillOpacity: 0.3 }, { fill: K.faint }];
  const bx = 290, by = lin(0, 1, 214, 22), gx = ox + 40 * cell;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`1,000 tested ideas, ${commas(R)} real.${quiet ? "" : ` ${commas(hits)} real hits and ${commas(F)} false hits: ${fx(share * 100, 1)}% of hits are false.`}`}>
      {blocks(groups, rows, cell, ox, oy).map((b, i) => <rect key={i} x={b.x} y={b.y} width={b.w} height={b.h} style={fills[b.g]} />)}
      {Array.from({ length: 39 }, (_, i) => <line key={i} x1={ox + (i + 1) * cell} x2={ox + (i + 1) * cell} y1={oy} y2={oy + rows * cell} style={{ stroke: "var(--page)", strokeWidth: 0.8 }} />)}
      {Array.from({ length: 24 }, (_, i) => <line key={i} x1={ox} x2={gx} y1={oy + (i + 1) * cell} y2={oy + (i + 1) * cell} style={{ stroke: "var(--page)", strokeWidth: 0.8 }} />)}
      {!quiet && hits + F > 0 && <path d={outline(hits + F, rows, cell, ox, oy)} style={{ fill: "none", stroke: K.text, strokeWidth: 2 }} />}
      <text x={gx + 6} y="120" className="b2t">hits that</text>
      <text x={gx + 6} y="138" className="b2t">are false</text>
      <rect x={bx} y={by(1)} width="26" height={by(0) - by(1)} rx="4" style={{ fill: K.faint, fillOpacity: 0.5 }} />
      {!quiet && <rect x={bx} y={by(share)} width="26" height={by(0) - by(share)} rx="4" style={{ fill: K.amber }} />}
      {!quiet && <text x={bx + 32} y={by(share) + 5} className="b2t amber">{fx(share * 100, 1)}%</text>}
      {marker && <><line x1={bx - 6} x2={bx + 32} y1={by(marker[0] / 100)} y2={by(marker[0] / 100)} className="b2mark guess" /><text x={bx + 30} y={by(marker[0] / 100) + 18} className="b2t">guess</text></>}
      <text x={bx + 13} y={by(0) + 18} textAnchor="middle" className="b2t">0%</text>
      <text x={bx + 13} y={by(1) - 6} textAnchor="middle" className="b2t">100%</text>
      <text x={ox} y={oy + rows * cell + 22} className="b2t pink">real</text>
      <text x={ox + 48} y={oy + rows * cell + 22} className="b2t amber">{quiet ? "" : "false hit"}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Really true" value={real} min={1} max={90} step={1} onChange={setReal} format={x => `${x}%`} marks={[{ v: 10, label: "10%" }, { v: 20, label: "20%" }, { v: 50, label: "50%" }]} />
        <Slider label="Power" value={power} min={5} max={99} step={1} onChange={setPower} format={x => `${x}%`} />
        <Slider label="α" value={alpha} min={0.5} max={20} step={0.5} onChange={setAlpha} format={x => `${fx(x, 1)}%`} />
        {pick}
      </>}
      readouts={<>
        <Read label="Real ideas" value={commas(R)} tone="pink" />
        {!quiet && <Read label="Real hits" value={commas(hits)} tone="pink" />}
        {!quiet && <Read label="False hits" value={commas(F)} tone="amber" />}
        {!quiet && <Read label="Hits that are false" value={`${fx(share * 100, 1)}%`} big />}
      </>}
    />
  );
}
