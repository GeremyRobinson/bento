// Word arrows (10): about 50 words as arrows from the origin on a small hand-made map. Tap two words for the angle
// between them and its cosine; tap a third for arrow arithmetic, first − second + third, with the nearest word that
// isn't one of the three. Preset buttons load the famous analogies, including one that fails. With u and v given
// (Work it), it draws just those two arrows on a grid, so the learner's numbers are the picture.
import { useState } from "react";
import { flag, str, type SceneProps, type SceneValues } from "../../../scenes";
import { ArrowHead, fx, Read, SaveRow, Scene } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { cosine, nearestWord, wordVec, WORDS } from "../maths";
import { Btn, Btns, lin } from "./common";

const GROUPS: [string, number, number][] = [["animals", 6.2, 4.6], ["people", -2.6, 9.4], ["places", -7.4, 3.0], ["travel", -1.6, -8.6], ["doing", 4.6, -6.6], ["food", 8.4, 1.6]];
const PRESETS: string[][] = [["king", "man", "woman"], ["paris", "france", "italy"], ["walked", "walk", "swim"], ["tokyo", "japan", "france"]];
const parse = (s: string) => s.split(",").map(Number);

function Arrow({ x1, y1, x2, y2, cls, dash }: { x1: number; y1: number; x2: number; y2: number; cls: string; dash?: boolean }) {
  return <g>
    <line x1={x1} y1={y1} x2={x2} y2={y2} className={`b2curve ${cls}`} strokeWidth="2.5" strokeDasharray={dash ? "5 4" : undefined} />
    <ArrowHead x1={x1} y1={y1} x2={x2} y2={y2} className={`b2bar ${cls}`} />
  </g>;
}

/** the angle arc between two arrows from (cx, cy) */
function Arc({ cx, cy, a, b, r }: { cx: number; cy: number; a: number[]; b: number[]; r: number }) {
  const t1 = Math.atan2(-a[1]!, a[0]!), t2 = Math.atan2(-b[1]!, b[0]!);
  let d = t2 - t1;
  while (d > Math.PI) d -= 2 * Math.PI;
  while (d < -Math.PI) d += 2 * Math.PI;
  const p = (t: number) => `${cx + r * Math.cos(t)},${cy + r * Math.sin(t)}`;
  return <path d={`M${p(t1)} A${r},${r} 0 0 ${d > 0 ? 1 : 0} ${p(t1 + d)}`} className="b2curve mint" fill="none" strokeWidth="2" />;
}

export function WordsScene({ props }: SceneProps) {
  if (str(props, "u", "")) return <PairView u={parse(str(props, "u", "3,4"))} v={parse(str(props, "v", "4,3"))} />;
  return <MapView props={props} />;
}

function PairView({ u, v }: { u: number[]; v: number[] }) {
  // a square grid that holds both arrows and the origin
  const all = [...u, ...v, 0], lo = Math.min(...all) - 1, size = Math.max(5, Math.max(...all) + 1 - lo);
  const W = 360, H = 260, sx = lin(lo, lo + size, 70, 290), sy = lin(lo, lo + size, 240, 20);
  const ticks = Array.from({ length: size + 1 }, (_, k) => lo + k);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Two arrows from the origin: u to (${u.join(", ")}) and v to (${v.join(", ")}), with the angle between them marked.`}>
      {ticks.map(k => <g key={k}>
        <line x1={sx(k)} y1={sy(lo)} x2={sx(k)} y2={sy(lo + size)} className="b2grid" />
        <line x1={sx(lo)} y1={sy(k)} x2={sx(lo + size)} y2={sy(k)} className="b2grid" />
      </g>)}
      <line x1={sx(lo)} y1={sy(0)} x2={sx(lo + size)} y2={sy(0)} className="b2axis" />
      <line x1={sx(0)} y1={sy(lo)} x2={sx(0)} y2={sy(lo + size)} className="b2axis" />
      <Arc cx={sx(0)} cy={sy(0)} a={u} b={v} r={34} />
      <Arrow x1={sx(0)} y1={sy(0)} x2={sx(u[0]!)} y2={sy(u[1]!)} cls="sky" />
      <Arrow x1={sx(0)} y1={sy(0)} x2={sx(v[0]!)} y2={sy(v[1]!)} cls="amber" />
      <text x={sx(u[0]!) + (u[0]! < 0 ? -6 : 6)} y={sy(u[1]!) - 6} textAnchor={u[0]! < 0 ? "end" : "start"} className="b2t sky">u ({u.join(", ")})</text>
      <text x={sx(v[0]!) + (v[0]! < 0 ? -6 : 6)} y={sy(v[1]!) + 14} textAnchor={v[0]! < 0 ? "end" : "start"} className="b2t amber">v ({v.join(", ")})</text>
      <text x={sx(0) + 40} y={sy(0) - 8} className="b2t mint">θ</text>
    </svg>
  );
  return <Scene svg={svg} readouts={<><Read label="u" value={`(${u.join(", ")})`} tone="sky" /><Read label="v" value={`(${v.join(", ")})`} tone="amber" /></>} />;
}

function MapView({ props }: { props: SceneValues }) {
  const quiet = flag(props, "quiet"), saving = flag(props, "save");
  const [picked, setPicked] = useState<string[]>(() => str(props, "pair", "").split(",").filter(Boolean));
  const show = str(props, "show", "").split(",").filter(Boolean);
  const { b2, save } = useB2();
  const W = 360, H = 260, cx = 180, cy = 130, k = 12;
  const X = (x: number) => cx + x * k, Y = (y: number) => cy - y * k;
  const tap = (w: string) => setPicked(p => (p.includes(w) ? p.filter(q => q !== w) : p.length >= 3 ? [w] : [...p, w]));
  const vec = picked.map(wordVec);
  const pairCos = picked.length === 2 ? cosine(vec[0]!, vec[1]!) : null;
  const tip: [number, number] | null = picked.length === 3 ? [vec[0]![0] - vec[1]![0] + vec[2]![0], vec[0]![1] - vec[1]![1] + vec[2]![1]] : null;
  const near = tip ? nearestWord(tip, picked) : null;
  const visible = quiet ? ["cat"] : WORDS.map(w => w[0]);
  const labelled = new Set([...picked, ...show, ...(near ? [near] : []), ...(quiet ? ["cat"] : [])]);
  const cls = (w: string) => (picked[0] === w ? "sky" : picked[1] === w ? "amber" : picked[2] === w ? "mint" : w === near ? "pink" : "");
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={quiet ? "The word cat as an arrow; the other words are hidden." : picked.length === 2 ? `${picked[0]} and ${picked[1]}: cosine ${fx(pairCos!)}.` : tip ? `${picked[0]} − ${picked[1]} + ${picked[2]} lands nearest ${near}.` : "About 50 words as dots on a hand-made map; tap words to compare them."}>
      <line x1={X(-10)} y1={cy} x2={X(10)} y2={cy} className="b2grid" />
      <line x1={cx} y1={Y(-10)} x2={cx} y2={Y(10)} className="b2grid" />
      {!quiet && GROUPS.map(([g, x, y]) => <text key={g} x={X(x)} y={Y(y)} textAnchor="middle" className="b2t" opacity="0.55">{g}</text>)}
      {show.map(w => { const v = wordVec(w); return <g key={w}><Arrow x1={cx} y1={cy} x2={X(v[0])} y2={Y(v[1])} cls="" dash />
        <text x={X(v[0])} y={Y(v[1]) + 16} textAnchor="middle" className="b2t">{fx(cosine(v, wordVec(picked[0] ?? "cat")))}</text></g>; })}
      {picked.length === 2 && <Arc cx={cx} cy={cy} a={vec[0]!} b={vec[1]!} r={40} />}
      {picked.length <= 2 && picked.map((w, i) => { const v = vec[i]!; return <Arrow key={w} x1={cx} y1={cy} x2={X(v[0])} y2={Y(v[1])} cls={i ? "amber" : "sky"} />; })}
      {quiet && (() => { const v = wordVec("cat"); return <Arrow x1={cx} y1={cy} x2={X(v[0])} y2={Y(v[1])} cls="sky" />; })()}
      {tip && (() => {
        const [a, b] = vec as [[number, number], [number, number]];
        const m: [number, number] = [a[0] - b[0], a[1] - b[1]];
        return <g>
          <Arrow x1={cx} y1={cy} x2={X(a[0])} y2={Y(a[1])} cls="sky" />
          <Arrow x1={X(a[0])} y1={Y(a[1])} x2={X(m[0])} y2={Y(m[1])} cls="amber" dash />
          <Arrow x1={X(m[0])} y1={Y(m[1])} x2={X(tip[0])} y2={Y(tip[1])} cls="mint" dash />
          <circle cx={X(tip[0])} cy={Y(tip[1])} r="5" className="b2dot trav" />
          <text x={X(tip[0])} y={Y(tip[1]) - 9} textAnchor="middle" className="b2t">tip</text>
        </g>;
      })()}
      {WORDS.filter(w => visible.includes(w[0])).map(([w, x, y]) => <g key={w}>
        <circle cx={X(x)} cy={Y(y)} r={labelled.has(w) ? 4.5 : 3} className={`b2dot ${cls(w)}`} opacity={cls(w) ? 1 : 0.45} />
        {labelled.has(w) && <text x={X(x) + (x < 0 ? -7 : 7)} y={Y(y) - 6} textAnchor={x < 0 ? "end" : "start"} className={`b2t ${cls(w)}`}>{w}</text>}
        {!quiet && <circle cx={X(x)} cy={Y(y)} r="9" className="b2hit" onClick={() => tap(w)} style={{ cursor: "pointer" }}><title>{w}</title></circle>}
      </g>)}
    </svg>
  );
  const off = picked.length === 3 ? [vec[0]![0] - vec[1]![0], vec[0]![1] - vec[1]![1]].map(v => Math.round(v * 100) / 100) : null;
  const saved = !!off && Array.isArray(b2.shelf.offset_word?.value) && (b2.shelf.offset_word.value as number[]).every((v, i) => v === off[i]);
  return (
    <Scene svg={svg}
      controls={<>
        <Btns>
          {PRESETS.map(p => <Btn key={p.join()} on={picked.join() === p.join()} onClick={() => setPicked(p)}>{`${p[0]} − ${p[1]} + ${p[2]}`}</Btn>)}
          <Btn onClick={() => setPicked([])}>Clear</Btn>
        </Btns>
        <p className="ainote">A small hand-made map, laid out the way real word vectors behave. It is not taken from a trained model. Tap two words to compare them, a third for arithmetic.</p>
      </>}
      readouts={quiet ? <Read label="Shown" value="cat" tone="sky" /> : <>
        <Read label="Picked" value={picked.length ? picked.join(picked.length === 3 ? ", " : " and ") : "tap a word"} />
        {pairCos != null && <Read label="cos θ" value={fx(pairCos)} tone="mint" big />}
        {pairCos != null && <Read label="Angle" value={`${Math.round((Math.acos(Math.max(-1, Math.min(1, pairCos))) * 180) / Math.PI)}°`} />}
        {near && <Read label={`${picked[0]} − ${picked[1]} + ${picked[2]}`} value={`nearest: ${near}`} tone="pink" big />}
      </>}
      foot={saving && off ? <SaveRow what={<>Keep the offset {picked[0]} − {picked[1]} = ({off.map(v => fx(v)).join(", ")}) as <b>offset_word</b></>} saved={saved}
        onSave={() => save("offset_word", off, "b2-ai-10", { labels: ["across", "up"], note: `${picked[0]} − ${picked[1]}; added to ${picked[2]} it lands nearest ${near}` })} /> : undefined}
    />
  );
}
