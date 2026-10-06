// The Attention toy (11): "the cat sat because it was tired", each word with a hand-set 2D query and key. The grid
// shows every word's softmax weights over the others (brighter = more weight); tap a word to light its row. On the
// right, the keys as arrows and the chosen word's query as a handle you drag: the row's weights follow live, because
// each score is q · k / √d. "Hide the future" lets each word look only at itself and the words before it.
import { useEffect, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { ArrowHead, fx, Read, Scene, Toggle, useSvgDrag } from "../../../ui/kit";
import { attentionRow, KEYS, QUERIES, SENTENCE } from "../maths";
import { lin } from "./common";

/** where each key's word sits beside its tip, so the close ones don't collide: [dx, dy, anchor] */
const LABEL: [number, number, "start" | "middle" | "end"][] = [[6, 4, "start"], [0, 18, "middle"], [6, 4, "start"], [-6, -8, "start"], [6, 4, "start"], [6, 4, "start"], [6, 14, "start"]];

export function AttentionScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet");
  const [at, setAt] = useState(num(props, "at", 4));
  const [q, setQ] = useState<[number, number]>(QUERIES[num(props, "at", 4)]!);
  const [mask, setMask] = useState<"all" | "past">("all");
  const { ref, drag } = useSvgDrag();
  useEffect(() => { setQ(QUERIES[at]!); }, [at]);
  const n = SENTENCE.length, upto = (i: number) => (mask === "past" ? i + 1 : n);
  const rows = SENTENCE.map((_, i) => attentionRow(i === at ? q : QUERIES[i]!, upto(i)));
  const row = rows[at]!, top = row.indexOf(Math.max(...row));
  const W = 360, H = 260, c = 18, gx = 80, gy = 74;
  const px = lin(-1.2, 2.5, 222, 352), py = lin(-1.2, 1.8, 250, 70), ux = lin(222, 352, -1.2, 2.5), uy = lin(250, 70, -1.2, 1.8);
  const hidden = (i: number) => quiet && i === at;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={quiet ? `Attention weights for every word except "${SENTENCE[at]}", whose row is hidden.` : `"${SENTENCE[at]}" puts the most weight on "${SENTENCE[top]}": ${fx(row[top]!)}.`}>
      {SENTENCE.map((w, j) => <text key={`c${w}`} x={gx + j * c + c / 2} y={gy - 6} transform={`rotate(-50 ${gx + j * c + c / 2} ${gy - 6})`} className={`b2t${j === top && !quiet ? " amber" : ""}`}>{w}</text>)}
      {SENTENCE.map((w, i) => <g key={`r${w}`} onClick={() => setAt(i)} style={{ cursor: "pointer" }}>
        <text x={gx - 6} y={gy + i * c + c / 2 + 4} textAnchor="end" className={`b2t${i === at ? " sky" : ""}`}>{w}</text>
        {rows[i]!.map((v, j) => <rect key={j} x={gx + j * c} y={gy + i * c} width={c} height={c} className="aicell"
          fill={hidden(i) ? "var(--well)" : i === at ? "var(--b2-amber)" : "var(--text)"} fillOpacity={hidden(i) ? 1 : j >= upto(i) ? 0 : 0.08 + v * (i === at ? 0.92 : 0.6)} />)}
        {hidden(i) && <text x={gx + (n * c) / 2} y={gy + i * c + c / 2 + 4} textAnchor="middle" className="b2t">?</text>}
      </g>)}
      <rect x={gx} y={gy + at * c} width={n * c} height={c} fill="none" stroke="var(--b2-sky)" strokeWidth="2" />
      <text x="8" y={gy + n * c + 20} className="b2t">brighter: "{SENTENCE[at]}" looks more</text>
      {/* the arrows: keys, and the chosen word's query */}
      <line x1={px(-1.2)} y1={py(0)} x2={px(2.5)} y2={py(0)} className="b2grid" />
      <line x1={px(0)} y1={py(-1.2)} x2={px(0)} y2={py(1.8)} className="b2grid" />
      {KEYS.map((k, j) => j < upto(at) && <g key={j}>
        <line x1={px(0)} y1={py(0)} x2={px(k[0])} y2={py(k[1])} className="aiwire" opacity={quiet ? 0.6 : 0.4 + row[j]!} />
        <circle cx={px(k[0])} cy={py(k[1])} r="3" className="b2dot" />
        <text x={px(k[0]) + LABEL[j]![0]} y={py(k[1]) + LABEL[j]![1]} textAnchor={LABEL[j]![2]} className="b2t">{SENTENCE[j]}</text>
      </g>)}
      {!quiet && <g>
        <line x1={px(0)} y1={py(0)} x2={px(q[0])} y2={py(q[1])} className="b2curve sky" strokeWidth="2.5" />
        <ArrowHead x1={px(0)} y1={py(0)} x2={px(q[0])} y2={py(q[1])} className="b2bar sky" />
        <circle cx={px(q[0])} cy={py(q[1])} r="6" className="b2handle" />
        <circle cx={px(q[0])} cy={py(q[1])} r="18" className="b2hit" {...drag((x, y) => setQ([Math.max(-1.2, Math.min(2.5, ux(x))), Math.max(-1.2, Math.min(1.8, uy(y)))]))} />
      </g>}
      <text x="8" y="252" className="b2t">dots: keys · <tspan className="b2t sky">blue: query of "{SENTENCE[at]}"</tspan></text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Toggle label="Look at" value={mask} onChange={setMask} options={[{ v: "all", label: "Every word" }, { v: "past", label: "Hide the future" }]} />}
      readouts={quiet ? <Read label="Word" value={`"${SENTENCE[at]}"`} tone="sky" /> : <>
        <Read label="Word" value={`"${SENTENCE[at]}"`} tone="sky" />
        <Read label="Looks most at" value={`"${SENTENCE[top]}"`} tone="amber" big />
        <Read label="Its weight" value={fx(row[top]!)} />
      </>}
    />
  );
}
