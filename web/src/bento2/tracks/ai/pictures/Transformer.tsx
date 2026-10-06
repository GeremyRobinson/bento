// The Transformer stack (12): on the left, the stack itself: embeddings at the bottom (V·d numbers), then L blocks of
// attention, add, MLP, add, with each box's parameter count. On the right, one block to scale: every d × d matrix is
// a square whose area is d², four for attention and eight for the MLP, so doubling d visibly quadruples the block.
// The Next letter view runs the one-block letter model on the start paragraph: type a prompt, read the bars.
import { useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider, Toggle } from "../../../ui/kit";
import { group } from "../../../steps";
import { letterProbs, START_TEXT } from "../letters";
import { useLetterModel } from "./Letters";

const SHOWN = 6;

export function TransformerScene({ props, place }: SceneProps) {
  const quiet = flag(props, "quiet"), compare = num(props, "compare", 0);
  const [d, setD] = useState(num(props, "d", 64));
  const [L, setL] = useState(num(props, "L", 2));
  const [V, setV] = useState(num(props, "V", 100));
  const [view, setView] = useState<"count" | "next">("count");
  const block = 12 * d * d, total = L * block + V * d;
  const W = 360, H = 260;
  if (view === "next" && !quiet) return <NextView back={() => setView("count")} />;
  // the stack, schematic
  const top = 34, bottom = 214, rowH = Math.min(30, (bottom - top - 34) / Math.min(L, SHOWN));
  const s = (dd: number) => dd * 0.29;
  const sq = (x0: number, y0: number, cols: number, side: number, cls: string, dash?: boolean) =>
    Array.from({ length: cols * 2 }, (_, i) => <rect key={i} x={x0 + (i % cols) * side} y={y0 + Math.floor(i / cols) * side} width={side} height={side}
      className={dash ? "aidiag" : `b2bar ${cls}`} fill={dash ? "none" : undefined} opacity={dash ? 1 : 0.75} stroke={dash ? undefined : "var(--page)"} strokeWidth={dash ? undefined : 0.75} />);
  const side = s(d), cs = compare ? s(compare) : 0;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={quiet ? `A stack of ${L} transformer blocks with width ${d}.` : `${L} blocks of width ${d}: ${group(block)} numbers per block, ${group(total)} in all.`}>
      <rect x="16" y={bottom} width="150" height="26" rx="6" className="aibox" />
      <text x="91" y={bottom + 17} textAnchor="middle" className="b2t">{quiet ? "V·d" : `V·d = ${group(V * d)}`}</text>
      <text x="91" y={bottom + 40} textAnchor="middle" className="b2t">embeddings</text>
      {Array.from({ length: Math.min(L, SHOWN) }, (_, k) => {
        const y = bottom - 10 - (k + 1) * rowH;
        return <g key={k}>
          <rect x="16" y={y} width="68" height={rowH - 6} rx="5" className="aibox on sky" />
          <text x="50" y={y + rowH / 2 + 1} textAnchor="middle" className="b2t sky">{quiet || rowH < 22 ? "attention" : group(4 * d * d)}</text>
          <text x="91" y={y + rowH / 2 + 1} textAnchor="middle" className="b2t">⊕</text>
          <rect x="98" y={y} width="68" height={rowH - 6} rx="5" className="aibox on amber" />
          <text x="132" y={y + rowH / 2 + 1} textAnchor="middle" className="b2t amber">{quiet || rowH < 22 ? "MLP" : group(8 * d * d)}</text>
        </g>;
      })}
      {L > SHOWN && <text x="91" y={bottom - 16 - SHOWN * rowH} textAnchor="middle" className="b2t">… {L} blocks in all</text>}
      <text x="91" y={top - 14} textAnchor="middle" className="b2t">next-token scores</text>
      <line x1="91" y1={top - 8} x2="91" y2={bottom - 10 - Math.min(L, SHOWN) * rowH - 2} className="aiwire" />
      {/* one block, to scale */}
      <text x="190" y="22" className="b2t">one block, d = {d}</text>
      {sq(190, 34, 2, side, "sky")}
      {sq(190, 50 + 2 * Math.max(side, cs), 4, side, "amber")}
      {compare > 0 && <>{sq(190, 34, 2, cs, "", true)}{sq(190, 50 + 2 * Math.max(side, cs), 4, cs, "", true)}</>}
      <text x={196 + 2 * Math.max(side, cs)} y={40 + side} className="b2t sky">attention</text>
      <text x="190" y={64 + 2 * Math.max(side, cs) + 2 * Math.max(side, cs)} className="b2t amber">MLP</text>
      <text x="190" y="248" className="b2t">{compare > 0 ? `dashed: d = ${compare}` : "each square: d × d"}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Width d" value={d} min={16} max={128} step={16} onChange={setD} marks={[{ v: 32, label: "32" }, { v: 64, label: "64" }, { v: 128, label: "128" }]} />
        <Slider label="Blocks L" value={L} min={1} max={12} step={1} onChange={setL} />
        {place !== "lesson" && <Slider label="Vocabulary V" value={V} min={50} max={300} step={50} onChange={setV} />}
        <Toggle label="View" value={view} onChange={setView} options={[{ v: "count", label: "Counts" }, { v: "next", label: "Next letter" }]} />
      </>}
      readouts={quiet ? <Read label="Width d" value={String(d)} /> : <>
        <Read label="One block, 12d²" value={group(block)} tone="amber" big />
        {compare > 0 && <Read label={`At d = ${compare}`} value={`${group(12 * compare * compare)}, so × ${fx(block / (12 * compare * compare), 0)}`} />}
        <Read label="Total, 12Ld² + V·d" value={group(total)} minor />
      </>}
    />
  );
}

function NextView({ back }: { back: () => void }) {
  const [prompt, setPrompt] = useState("the cat s");
  const [T, setT] = useState(1);
  const { model, passes } = useLetterModel(START_TEXT, true, 16);
  const ready = passes.length >= 16;
  const p = letterProbs(model, prompt, T);
  const order = [...p.keys()].sort((a, b) => p[b]! - p[a]!).slice(0, 8);
  const W = 360, H = 260, bw = 38;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`After "${prompt}", the most likely next letters: ${order.slice(0, 3).map(k => `"${model.vocab[k]}" ${fx(p[k]!)}`).join(", ")}.`}>
      <text x="16" y="22" className="b2t">{ready ? `next letter after "${prompt.slice(-12)}"` : `learning the start paragraph: pass ${passes.length} of 16`}</text>
      <line x1="20" y1="220" x2="340" y2="220" className="b2axis" />
      {order.map((k, i) => <g key={k}>
        <rect x={24 + i * bw} y={220 - p[k]! * 180} width={bw - 8} height={Math.max(1, p[k]! * 180)} rx="3" className={`b2bar ${i ? "sky" : "amber"}`} opacity={ready ? 1 : 0.4} />
        <text x={24 + i * bw + (bw - 8) / 2} y={214 - p[k]! * 180} textAnchor="middle" className="b2t">{fx(p[k]!)}</text>
        <text x={24 + i * bw + (bw - 8) / 2} y="240" textAnchor="middle" className="b2t">{model.vocab[k] === " " ? "space" : model.vocab[k]}</text>
      </g>)}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <input className="aitext" style={{ minHeight: 0 }} value={prompt} aria-label="Prompt" onChange={e => setPrompt(e.currentTarget.value.toLowerCase())} />
        <Slider label="Temperature T" value={T} min={0.25} max={2} step={0.05} onChange={setT} format={v => v.toFixed(2)} marks={[{ v: 0.5, label: "0.5" }, { v: 1, label: "1" }, { v: 1.5, label: "1.5" }]} />
        <Toggle label="View" value="next" onChange={v => v === "count" && back()} options={[{ v: "count", label: "Counts" }, { v: "next", label: "Next letter" }]} />
      </>}
      readouts={<>
        <Read label="Model" value="one block, d = 16" />
        <Read label="Most likely" value={model.vocab[order[0]!] === " " ? "space" : `"${model.vocab[order[0]!]}"`} tone="amber" big />
      </>}
    />
  );
}
