// The Bit counter (information.md), in two modes:
// shrink: a message and its compressed size side by side. "Random noise" swaps in random bits of the same length, and the
//   compressor fails to shrink them; a bias slider makes the noise predictable again (07, 12). The compressor is honest:
//   its size is the Huffman bits plus the code table it has to send (8 bits for each symbol and 4 for its length).
// count: all 2ⁿ files of n bits against every string at least k bits shorter, as areas (07's guess).
import { useMemo, useState, type ReactNode } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider, Toggle } from "../../../ui/kit";
import { entropyOfCounts, huffman, seeded } from "../maths";
import { useMessage } from "./message";

const W = 360;

/** a two-part size: the Huffman bits plus the table (each symbol in 8 bits, its code length in 4) */
export function packedSize(symbols: string[]) {
  const m = new Map<string, number>();
  for (const s of symbols) m.set(s, (m.get(s) ?? 0) + 1);
  const counts = [...m.values()];
  const body = counts.length > 1 ? huffman(counts).total : symbols.length;
  return { body, table: counts.length * 12, total: body + counts.length * 12, H: entropyOfCounts(counts.length ? counts : [1]), distinct: counts.length };
}

export function BitCounterScene({ props, marker, place }: SceneProps) {
  const [mode, setMode] = useState<"shrink" | "count">(str<string>(props, "mode", "shrink") === "count" ? "count" : "shrink");
  const pick = place !== "lesson" && <Toggle label="Counter" value={mode} onChange={setMode} options={[{ v: "shrink", label: "Shrink" }, { v: "count", label: "Count files" }]} />;
  return mode === "count" ? <Count props={props} marker={marker} pick={pick} /> : <Shrink props={props} pick={pick} />;
}

function Shrink({ props, pick }: { props: SceneProps["props"]; pick: ReactNode }) {
  const [mine] = useMessage();
  const text = flag(props, "mine") ? mine : str<string>(props, "text", "information is the resolution of uncertainty, and a message that tells you what you already knew tells you nothing at all");
  const [src, setSrc] = useState<"text" | "noise">("text");
  const [bias, setBias] = useState(0.5);
  const [seed, setSeed] = useState(1);
  const n = text.length;
  const noiseBits = useMemo(() => { const r = seeded(seed * 7919); return Array.from({ length: n * 8 }, () => (r() < bias ? 1 : 0)); }, [n, bias, seed]);
  const bytes = useMemo(() => {
    if (src === "text") return [...text];
    const out: string[] = [];
    for (let i = 0; i < n; i++) out.push(String(parseInt(noiseBits.slice(i * 8, i * 8 + 8).join(""), 2)));
    return out;
  }, [src, text, noiseBits, n]);
  const bits = useMemo(() => (src === "text" ? [...text].flatMap(c => c.charCodeAt(0).toString(2).padStart(8, "0").slice(-8).split("").map(Number)) : noiseBits), [src, text, noiseBits]);
  const size = packedSize(bytes);
  const raw = 8 * n, top = Math.max(raw, size.total);
  const bx = (b: number) => 20 + (b / top) * 320;
  const svg = (
    <svg viewBox={`0 0 ${W} 230`} className="b2pic" role="img" aria-label={`${raw} raw bits compress to ${size.total}.`}>
      {bits.slice(0, 192).map((b, i) => <rect key={i} x={20 + (i % 48) * 6.7} y={12 + Math.floor(i / 48) * 9} width="5.5" height="7" rx="1" className={`b2bar ${b ? "trav" : "track"}`} />)}
      <text x="20" y="64" className="b2t">the first bits of the {src === "text" ? "message" : "noise"}</text>
      <text x="20" y="98" className="b2t">raw</text>
      <rect x="20" y="104" width={bx(raw) - 20} height="22" rx="5" className="b2bar sky" />
      <text x={bx(raw)} y="98" textAnchor="end" className="b2t sky">{raw.toLocaleString("en-US")}</text>
      <text x="20" y="160" className="b2t">compressed: code + table</text>
      <rect x="20" y="166" width={bx(size.body) - 20} height="22" rx="5" className="b2bar amber" />
      <rect x={bx(size.body)} y="166" width={bx(size.total) - bx(size.body)} height="22" rx="5" className="b2bar amber" opacity="0.45" />
      <text x={bx(size.total)} y="160" textAnchor="end" className="b2t amber">{size.total.toLocaleString("en-US")}</text>
      <line x1={bx(raw)} y1="100" x2={bx(raw)} y2="196" className="b2mark" />
      <text x={W - 16} y="216" textAnchor="end" className={`b2t ${size.total < raw ? "sky" : "pink"}`}>{size.total < raw ? `shrank to ${Math.round((100 * size.total) / raw)}%` : "didn't shrink"}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {pick}
        <Toggle label="Source" value={src} onChange={setSrc} options={[{ v: "text", label: "Sentence" }, { v: "noise", label: "Random noise" }]} />
        {src === "noise" && <>
          <Slider label="Chance of a 1" value={bias} min={0.01} max={0.5} step={0.01} onChange={setBias} format={x => fx(x)} marks={[{ v: 0.5, label: "1/2" }, { v: 0.25, label: "1/4" }, { v: 0.1, label: "0.1" }]} />
          <button type="button" className="ctl" onClick={() => setSeed(s => s + 1)}>New noise</button>
        </>}
      </>}
      readouts={<>
        <Read label="Raw" value={`${raw.toLocaleString("en-US")} bits`} tone="sky" />
        <Read label="Compressed" value={`${size.total.toLocaleString("en-US")} bits`} tone="amber" big />
        <Read label="Different symbols" value={size.distinct} />
        <Read label="Floor, H × symbols" value={`${Math.round(size.H * n).toLocaleString("en-US")} bits`} />
      </>}
    />
  );
}

function Count({ props, marker, pick }: { props: SceneProps["props"]; marker?: [number, number]; pick: ReactNode }) {
  const [n, setN] = useState(Math.round(num(props, "n", 20)));
  const [k, setK] = useState(Math.round(num(props, "k", 8)));
  const quiet = flag(props, "quiet");
  const kk = Math.min(k, n - 1);
  const files = 2 ** n, shorter = 2 ** (n - kk + 1) - 1, share = shorter / files;
  // the files fill a 320 × 140 block; the strings at least k shorter fill a strip of the same height
  const w = Math.max(1.5, share * 320);
  const svg = (
    <svg viewBox={`0 0 ${W} 230`} className="b2pic" role="img" aria-label={`${files} files of ${n} bits; strings at least ${kk} bits shorter number ${shorter}${quiet ? "" : `, a share of ${fx(share * 100, 2)}%`}.`}>
      <rect x="20" y="30" width="320" height="140" rx="6" className="b2bar sky" opacity="0.25" />
      <text x="20" y="22" className="b2t sky">all 2{sup(n)} files of {n} bits</text>
      {n <= 9 && Array.from({ length: files }, (_, i) => {
        const cols = 2 ** Math.ceil(n / 2), rows = files / cols, cw = 320 / cols, ch = 140 / rows;
        return <rect key={i} x={20 + (i % cols) * cw + 0.5} y={30 + Math.floor(i / cols) * ch + 0.5} width={Math.max(0.5, cw - 1)} height={Math.max(0.5, ch - 1)} className="b2grid strong" fill="none" />;
      })}
      {!quiet && <rect x="20" y="30" width={w} height="140" rx="2" className="b2bar amber" />}
      {!quiet && <text x={Math.min(W - 20, 26 + w)} y="194" textAnchor={w > 250 ? "end" : "start"} className="b2t amber">shorter by {kk}+: {fx(share * 100, share < 0.01 ? 2 : 1)}%</text>}
      {marker && <g><rect x="20" y="30" width={Math.max(1, (marker[0] / 100) * 320)} height="140" className="b2mark guess" /><text x={Math.min(W - 60, 24 + (marker[0] / 100) * 320)} y="214" className="b2t">your guess</text></g>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>{pick}
        <Slider label="File length n" value={n} min={3} max={24} step={1} onChange={setN} format={v => `${v} bits`} />
        <Slider label="Shrink by k" value={kk} min={1} max={Math.min(10, n - 1)} step={1} onChange={setK} format={v => `${v} bits`} />
      </>}
      readouts={<>
        <Read label="Files" value={files.toLocaleString("en-US")} tone="sky" />
        {!quiet && <Read label={`Strings of ${n - kk} bits or fewer`} value={shorter.toLocaleString("en-US")} tone="amber" />}
        {!quiet && <Read label="Share that can shrink that much" value={`under 1/${(2 ** (kk - 1)).toLocaleString("en-US")}`} big />}
      </>}
    />
  );
}
const SUP: Record<string, string> = { "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹" };
const sup = (x: number) => String(x).replace(/./g, d => SUP[d] ?? d);
