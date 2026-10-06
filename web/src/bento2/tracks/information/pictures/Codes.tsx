// The Code builder (information.md), in two modes:
// free: type codewords for four letters; each is a leaf on a binary tree and a share 2^(−ℓ) of the strip under it.
//   A codeword that starts another makes the reader stall on a fork; lengths that don't fit run out of room (05).
// huffman: letter tiles with counts; "merge" joins the two lightest under a node with their total until one tree is
//   left, while the message's bit strip shortens with each merge (06, and the Shrinker's coder).
import { useMemo, useState, type ReactElement, type ReactNode } from "react";
import { flag, str, type SceneProps } from "../../../scenes";
import { Read, Scene, Toggle, useClock } from "../../../ui/kit";
import { kraft, prefixClash, prefixDecode } from "../maths";

const W = 360;
const LET = "ABCDEFGH";
const TONES = ["sky", "pink", "amber", "mint", "trav", "sky", "pink", "amber"];
type Mode = "free" | "huffman";

export function CodesScene(props: SceneProps) {
  const [mode, setMode] = useState<Mode>(str<Mode>(props.props, "mode", "free"));
  const pick = props.place !== "lesson" && (
    <Toggle label="Builder" value={mode} onChange={setMode} options={[{ v: "free", label: "Free" }, { v: "huffman", label: "Huffman" }]} />
  );
  return mode === "huffman" ? <Huffman {...props} pick={pick} /> : <Free {...props} pick={pick} />;
}

/* ------------------------------------------------------------------ free ------------------------------------------------------------------ */

/** places lengths as codewords, shortest first, each at the next free spot of its depth; null when the tree is full */
function place(lens: number[]): (string | null)[] {
  const order = lens.map((l, i) => [l, i] as const).sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  const out: (string | null)[] = lens.map(() => null);
  let at = 0; // the next free point on [0, 1), in 1/1024ths
  for (const [l, i] of order) {
    const step = 1024 >> l;
    const start = Math.ceil(at / step) * step;
    if (start + step > 1024) continue;
    out[i] = (start / step).toString(2).padStart(l, "0");
    at = start + step;
  }
  return out;
}
const clean = (s: string) => s.replace(/[^01]/g, "").slice(0, 5);

function Free({ props, pick }: SceneProps & { pick: ReactNode }) {
  const lensProp = str<string>(props, "lens", "");
  const lens = lensProp ? lensProp.split(",").map(Number) : null;
  const quiet = flag(props, "quiet"), placing = flag(props, "place");
  const [code, setCode] = useState<string[]>(() => (lens ? place(lens).map(c => c ?? "") : str<string>(props, "code", "0,10,110,111").split(",")));
  const [bits, setBits] = useState(str<string>(props, "bits", "0110100111"));
  const shown = lens && (quiet || placing) ? place(lens) : code.map(c => c || null);
  const live = shown.map(c => c ?? "");
  const lengths = lens && (quiet || placing) ? lens : code.map(c => c.length).filter(l => l > 0);
  const K = kraft(lengths);
  const clash = prefixClash(live.filter(Boolean));
  const D = Math.max(3, Math.min(5, ...lengths.map(l => l || 1)));
  const xOf = (d: number, i: number) => 20 + ((i + 0.5) * 320) / 2 ** d, yOf = (d: number) => 22 + d * (170 / D);
  const decoded = !clash ? prefixDecode(bits, live) : null;
  const nodes: ReactElement[] = [];
  for (let d = 1; d <= D; d++) for (let i = 0; i < 2 ** d; i++)
    nodes.push(<line key={`${d}-${i}`} x1={xOf(d - 1, i >> 1)} y1={yOf(d - 1)} x2={xOf(d, i)} y2={yOf(d)} className="b2grid strong" />);
  const svg = (
    <svg viewBox={`0 0 ${W} 262`} className="b2pic" role="img" aria-label={`A binary tree with ${shown.filter(Boolean).length} codewords placed. Kraft sum ${K.toFixed(3)}.`}>
      {nodes}
      <circle cx={xOf(0, 0)} cy={yOf(0)} r="5" className="b2dot" />
      {!(quiet && lens) && shown.map((c, k) => {
        if (!c) return null;
        const v = parseInt(c, 2), l = c.length, tone = TONES[k]!;
        const pts = Array.from({ length: l + 1 }, (_, d) => [xOf(d, v >> (l - d)), yOf(d)] as [number, number]);
        const lo = (v / 2 ** l) * 320 + 20, w = 320 / 2 ** l;
        return (
          <g key={k} className={tone}>
            <path d={pts.map(([x, y], i) => `${i ? "L" : "M"}${x},${y}`).join(" ")} className="b2curve" />
            <circle cx={pts[l]![0]} cy={pts[l]![1]} r="11" className="b2dot" />
            <text x={pts[l]![0]} y={pts[l]![1] + 4} textAnchor="middle" className="b2t" style={{ fill: "var(--page)", stroke: "none" }}>{LET[k]}</text>
            <rect x={lo + 1} y={222} width={Math.max(1, w - 2)} height="16" rx="3" className="b2bar" opacity="0.8" />
          </g>
        );
      })}
      <rect x="20" y="222" width="320" height="16" rx="3" className="b2mark" />
      <text x="20" y="256" className="b2t">the strip: each leaf's share of the tree</text>
      {clash && <text x={W - 16} y="256" textAnchor="end" className="b2t pink">a fork</text>}
      {lens && placing && shown.some(c => !c) && <text x={W - 16} y="256" textAnchor="end" className="b2t pink">no room left</text>}
    </svg>
  );
  const tool = props.place !== "lesson" || !lens;
  return (
    <Scene svg={svg}
      controls={<>
        {pick}
        {tool && !quiet && code.map((c, k) => (
          <label key={k} className="b2field"><span>{LET[k]}</span>
            <input inputMode="numeric" value={c} aria-label={`Codeword for ${LET[k]}`} onChange={e => { const v = clean(e.currentTarget.value); setCode(cs => cs.map((x, j) => (j === k ? v : x))); }} /></label>
        ))}
        {tool && !quiet && <label className="b2field wide"><span>Bits to read</span><input inputMode="numeric" value={bits} aria-label="Bits to read" onChange={e => setBits(e.currentTarget.value.replace(/[^01]/g, "").slice(0, 24))} /></label>}
      </>}
      readouts={<>
        <Read label="Lengths" value={lengths.join(", ") || "–"} />
        {!quiet && <Read label="Kraft sum" value={kraftText(lengths)} tone={K > 1 ? "pink" : "sky"} big />}
        {!quiet && !lens && <Read label="Reads as" value={clash ? `stalls: ${live.filter(Boolean)[clash[0]]} starts ${live.filter(Boolean)[clash[1]]}` : decoded ? decoded.map(i => LET[i]).join(" ") : "a codeword is cut off"} tone="amber" />}
      </>}
    />
  );
}
const kraftText = (ls: number[]) => {
  if (!ls.length) return "0";
  const D = Math.max(...ls), n = ls.reduce((a, l) => a + 2 ** (D - l), 0);
  let a = n, b = 2 ** D;
  while (a % 2 === 0 && b > 1) { a /= 2; b /= 2; }
  return b === 1 ? String(a) : `${a}/${b}`;
};

/* ------------------------------------------------------------------ Huffman ------------------------------------------------------------------ */

interface HNode { id: number; w: number; kids?: [number, number]; at: number; leaf?: number }
/** the merges in order, lightest first (ties by age, then position), as a node list */
function merges(counts: number[]): HNode[] {
  const nodes: HNode[] = counts.map((w, i) => ({ id: i, w, at: -1, leaf: i }));
  let roots = nodes.map(n => n.id);
  let step = 0;
  while (roots.length > 1) {
    const sorted = [...roots].sort((a, b) => nodes[a]!.w - nodes[b]!.w || a - b);
    const [a, b] = [sorted[0]!, sorted[1]!];
    const id = nodes.length;
    nodes.push({ id, w: nodes[a]!.w + nodes[b]!.w, kids: [a, b], at: step++ });
    roots = [...roots.filter(r => r !== a && r !== b), id];
  }
  return nodes;
}

function Huffman({ props, marker, pick }: SceneProps & { pick: ReactNode }) {
  const [countsText, setCountsText] = useState(str<string>(props, "counts", "8,4,2,2"));
  const counts = countsText.split(/[,\s]+/).map(Number).filter(x => Number.isFinite(x) && x > 0).slice(0, 8);
  const k = Math.max(1, counts.length);
  const nodes = useMemo(() => merges(counts.length ? counts : [1]), [countsText]); // eslint-disable-line react-hooks/exhaustive-deps
  const quiet = flag(props, "quiet"), auto = flag(props, "auto");
  const [m, setM] = useState(0);
  const t = Math.max(0, useClock(auto, 99));
  const done = auto ? Math.min(k - 1, Math.floor(t / 0.9)) : quiet ? 0 : Math.min(m, k - 1);
  const live = nodes.filter(n => n.leaf != null || n.at < done);
  const isRoot = (id: number) => !live.some(n => n.kids?.includes(id));
  const roots = live.filter(n => isRoot(n.id));
  const depthIn = (id: number, d = 0, out: Record<number, number> = {}): Record<number, number> => {
    const n = nodes[id]!;
    if (n.leaf != null) out[n.leaf] = d; else if (n.at < done) n.kids!.forEach(c => depthIn(c, d + 1, out));
    else out[-1] = 0;
    return out;
  };
  const depth: Record<number, number> = {};
  for (const r of roots) Object.assign(depth, depthIn(r.id));
  const M = counts.reduce((a, b) => a + b, 0);
  const prefix = Math.ceil(Math.log2(Math.max(1, roots.length)));
  const bits = counts.reduce((a, c, i) => a + c * ((depth[i] ?? 0) + prefix), 0);
  const plain = Math.ceil(Math.log2(k)) * M;
  // layout: leaves in the final tree's order along the bench; each node above its children, higher for later merges
  const order: number[] = [];
  const walk = (id: number) => { const n = nodes[id]!; if (n.leaf != null) order.push(n.leaf); else n.kids!.forEach(walk); };
  walk(nodes.length - 1);
  const slot = 320 / k, X: Record<number, number> = {}, Y: Record<number, number> = {};
  order.forEach((leaf, i) => { X[leaf] = 20 + (i + 0.5) * slot; Y[leaf] = 176; });
  for (const n of nodes) if (n.kids) { X[n.id] = (X[n.kids[0]]! + X[n.kids[1]]!) / 2; Y[n.id] = 176 - ((n.at + 1) * 150) / Math.max(1, k - 1); }
  const next = [...roots].sort((a, b) => a.w - b.w || a.id - b.id).slice(0, 2).map(n => n.id);
  const codeOf = (leaf: number) => {
    let s = "", id = leaf;
    for (;;) { const parent = live.find(n => n.kids?.includes(id)); if (!parent) break; s = (parent.kids![0] === id ? "0" : "1") + s; id = parent.id; }
    return s;
  };
  const sx = (b: number) => 20 + (b / Math.max(plain, bits)) * 320;
  const svg = (
    <svg viewBox={`0 0 ${W} 262`} className="b2pic" role="img" aria-label={`${done} of ${k - 1} merges done. The message takes ${quiet ? "?" : bits} bits.`}>
      {live.filter(n => n.kids).map(n => (
        <g key={n.id}>
          {n.kids!.map(c => <path key={c} d={`M${X[n.id]},${Y[n.id]} L${X[c]},${Y[c]}`} className="b2curve" />)}
        </g>
      ))}
      {live.filter(n => n.kids).map(n => (
        <g key={`n${n.id}`}>
          <circle cx={X[n.id]} cy={Y[n.id]} r="13" className={`b2dot ${isRoot(n.id) ? "sky" : ""}`} opacity={isRoot(n.id) ? 1 : 0.6} />
          <text x={X[n.id]} y={Y[n.id]! + 4} textAnchor="middle" className="b2t" style={{ fill: "var(--page)", stroke: "none" }}>{n.w}</text>
        </g>
      ))}
      {counts.map((c, i) => (
        <g key={i} className={TONES[i]}>
          <rect x={X[i]! - Math.min(17, slot / 2 - 2)} y="162" width={Math.min(34, slot - 4)} height="30" rx="6" className="b2bar" opacity={next.includes(i) && !quiet && done < k - 1 ? 1 : 0.75} />
          <text x={X[i]} y="182" textAnchor="middle" className="b2t" style={{ fill: "var(--page)", stroke: "none" }}>{LET[i]}</text>
          <text x={X[i]} y="208" textAnchor="middle" className="b2t">{c}</text>
          {done === k - 1 && !quiet && <text x={X[i]} y="154" textAnchor="middle" className="b2t">{codeOf(i)}</text>}
        </g>
      ))}
      {!quiet && done < k - 1 && next.map(id => <circle key={id} cx={X[id]} cy={(Y[id] ?? 176) + (nodes[id]!.leaf != null ? 1 : 0)} r="22" className="b2mark amber" />)}
      <rect x="20" y="226" width={sx(plain) - 20} height="14" rx="3" className="b2bar track" />
      {!quiet && <rect x="20" y="226" width={sx(bits) - 20} height="14" rx="3" className="b2bar amber" />}
      <text x="20" y="256" className="b2t">plain {plain}</text>
      {!quiet && <text x={sx(bits)} y="256" textAnchor="end" className="b2t amber">now {bits}</text>}
      {marker && <g><line x1={sx(marker[0])} y1="220" x2={sx(marker[0])} y2="246" className="b2mark guess" /><text x={sx(marker[0])} y="216" textAnchor="middle" className="b2t">you</text></g>}
    </svg>
  );
  const tool = props.place !== "lesson";
  return (
    <Scene svg={svg}
      controls={<>
        {pick}
        {!auto && !quiet && <>
          <button type="button" className="ctl go" disabled={done >= k - 1} onClick={() => setM(done + 1)}>Merge the two lightest</button>
          <button type="button" className="ctl" disabled={done === 0} onClick={() => setM(done - 1)}>Undo</button>
        </>}
        {tool && <label className="b2field wide"><span>Counts</span><input value={countsText} aria-label="Letter counts" onChange={e => { setCountsText(e.currentTarget.value.replace(/[^\d,\s]/g, "")); setM(0); }} /></label>}
      </>}
      readouts={<>
        <Read label="Letters in the message" value={M} />
        <Read label="Merges" value={`${done} of ${k - 1}`} />
        {!quiet && <Read label="Bits now" value={bits} tone="amber" big />}
        {!quiet && <Read label="Per letter" value={(bits / M).toFixed(2)} />}
      </>}
    />
  );
}
