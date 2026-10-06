// ★ The Image compressor, the track's build (linear-algebra.md): a picture is a grid of numbers, and the SVD splits it
// into layers, each a column times a row times its σ. Modes: grid (01, the 8 × 8 pixel grid editor that becomes
// `img`), outer (06, a column times a row: the first layer), pair (12, pixel pairs to average and difference),
// layers (18, `img` rebuilt layer by layer with the error picture), plaid (the project "Plaid from layers"), and
// build (20 and the build: a photo, the k slider, the σ plot on a log scale with the cut, the storage bar and the
// energy kept).
import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider, Toggle, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import type { Mat } from "../../../tools/matrix";
import { energyKept, IMG0, layer, largestK, readImg, rebuild, rankOf, samplePhoto, storage, svd } from "../maths";
import { ink, tint } from "./plane";

type Mode = "grid" | "outer" | "pair" | "layers" | "plaid" | "build";

/** a grid of numbers as cells: brightness for 0 … max, or two colours for signed values (sky above 0, pink below) */
function Pix({ M, x, y, size, max, signed, onCell, label }: { M: Mat; x: number; y: number; size: number; max: number; signed?: boolean; onCell?: object & ((i: number, j: number) => object); label?: string }) {
  const n = M.length, m = M[0]!.length, c = size / Math.max(n, m);
  return (
    <g>
      <rect x={x - 1} y={y - 1} width={m * c + 2} height={n * c + 2} rx="3" style={{ fill: "var(--well)" }} />
      {M.map((row, i) => row.map((v, j) => {
        const o = Math.min(1, Math.abs(v) / (max || 1));
        const style = signed ? tint(v >= 0 ? "sky" : "pink", o) : { fill: "var(--text)", fillOpacity: Math.max(0, Math.min(1, v / (max || 1))) };
        return <rect key={`${i}-${j}`} x={x + j * c} y={y + i * c} width={c - 0.6} height={c - 0.6} style={style} {...(onCell ? onCell(i, j) : {})} />;
      }))}
      {label && <text x={x + (m * c) / 2} y={y + n * c + 16} textAnchor="middle" className="b2t">{label}</text>}
    </g>
  );
}

export function CompressorScene(sp: SceneProps) {
  const mode = str<Mode>(sp.props, "mode", "build");
  if (mode === "grid") return <GridView {...sp} />;
  if (mode === "outer") return <OuterView {...sp} />;
  if (mode === "pair") return <PairView {...sp} />;
  if (mode === "layers") return <LayersView {...sp} />;
  if (mode === "plaid") return <PlaidView {...sp} />;
  return <BuildView {...sp} />;
}

/* ------------------------------------------------------------ 01: the pixel grid editor ------------------------------------------------------------ */

function GridView({ props }: SceneProps) {
  const { b2, save } = useB2();
  const [img, setImg] = useState<Mat>(() => readImg(b2.shelf.img?.value).map(r => [...r]));
  const [brush, setBrush] = useState(9);
  const { ref, drag } = useSvgDrag();
  const S = 232, x0 = 10, y0 = 14, c = S / 8;
  const paint = (px: number, py: number) => {
    const j = Math.floor((px - x0) / c), i = Math.floor((py - y0) / c);
    if (i >= 0 && i < 8 && j >= 0 && j < 8 && img[i]![j] !== brush) setImg(g => g.map((r, a) => (a === i ? r.map((v, b) => (b === j ? brush : v)) : r)));
  };
  const avg = img[2]!.map((v, j) => (v + img[3]![j]!) / 2);
  const saved = JSON.stringify(b2.shelf.img?.value) === JSON.stringify(img);
  const svg = (
    <svg ref={ref} viewBox="0 0 360 270" className="b2pic" role="img" aria-label="An 8 by 8 picture, brightness 0 to 9. Drag across it to paint.">
      <Pix M={img} x={x0} y={y0} size={S} max={9} />
      <rect x={x0} y={y0} width={S} height={S} style={{ fill: "transparent", cursor: "crosshair" }} {...drag(paint)} />
      {[2, 3].map(i => <rect key={i} x={x0 - 3} y={y0 + i * c - 1} width={S + 6} height={c + 2} style={ink(i === 2 ? "sky" : "pink", 1.5)} />)}
      <text x={x0 + S + 10} y={y0 + 2.6 * c} className="b2t sky">row 3</text>
      <text x={x0 + S + 10} y={y0 + 3.6 * c} className="b2t pink">row 4</text>
      <Pix M={[avg]} x={x0} y={y0 + S + 12} size={S} max={9} />
      <text x={x0 + S + 10} y={y0 + S + 26} className="b2t amber">½(r₃ + r₄)</text>
    </svg>
  );
  return <Scene svg={svg}
    controls={<Slider label="Brush brightness" value={brush} min={0} max={9} step={1} onChange={setBrush} format={v => String(v)} marks={[0, 3, 6, 9].map(v => ({ v, label: String(v) }))} />}
    readouts={<>
      <Read label="Row 3" value={`(${img[2]!.join(", ")})`} tone="sky" />
      <Read label="Row 4" value={`(${img[3]!.join(", ")})`} tone="pink" />
      <Read label="½(r₃ + r₄)" value={`(${avg.map(v => fx(v, 1).replace(/\.0$/, "")).join(", ")})`} tone="amber" />
    </>}
    foot={flag(props, "save") ? <SaveRow what={<>Keep your picture as <b>img</b>: 8 rows of 8 numbers</>} saved={saved} onSave={() => save("img", img.map(r => [...r]), "b2-la-01", { note: "your 8 × 8 picture, brightness 0 to 9" })} /> : undefined} />;
}

/* ------------------------------------------------------------ 06: a column times a row ------------------------------------------------------------ */

function OuterView({ props }: SceneProps) {
  const { b2, save } = useB2();
  const [u, setU] = useState([num(props, "u0", 1), num(props, "u1", 2), num(props, "u2", 3)]);
  const [v, setV] = useState([num(props, "v0", 2), num(props, "v1", 0), num(props, "v2", 1)]);
  const P = u.map(a => v.map(b => a * b));
  const c = 46, x0 = 120, y0 = 70;
  const bump = (set: (f: (a: number[]) => number[]) => void, k: number) => set(a => a.map((x, i) => (i === k ? (x + 1) % 4 : x)));
  const cell = (x: number, y: number, val: number, tone: "sky" | "pink" | "amber", max: number, onClick?: () => void, key?: string) => (
    <g key={key} onClick={onClick} style={onClick ? { cursor: "pointer" } : undefined}>
      <rect x={x} y={y} width={c - 4} height={c - 4} rx="6" style={{ ...tint(tone, 0.1 + 0.6 * (val / max)), ...ink(tone, 1.2) }} />
      <text x={x + c / 2 - 2} y={y + c / 2 + 3} textAnchor="middle" className={`b2t ${tone}`}>{val}</text>
    </g>
  );
  const saved = JSON.stringify(b2.shelf.layer1?.value) === JSON.stringify(P);
  const svg = (
    <svg viewBox="0 0 360 250" className="b2pic" role="img" aria-label={`Column (${u.join(", ")}) times row (${v.join(", ")}) makes a 3 by 3 layer.`}>
      {u.map((x, i) => cell(40, y0 + i * c, x, "sky", 3, () => bump(setU, i), `u${i}`))}
      {v.map((x, j) => cell(x0 + j * c, 14, x, "pink", 3, () => bump(setV, j), `v${j}`))}
      {P.map((r, i) => r.map((x, j) => cell(x0 + j * c, y0 + i * c, x, "amber", 9, undefined, `p${i}${j}`)))}
      <text x={40 + c / 2} y={y0 - 10} textAnchor="middle" className="b2t sky">u</text>
      <text x={x0 - 14} y={14 + c / 2 + 3} textAnchor="end" className="b2t pink">vᵀ</text>
      <text x={x0 + 3 * c + 10} y={y0 + 1.5 * c} className="b2t">tap u or vᵀ</text>
    </svg>
  );
  return <Scene svg={svg}
    readouts={<>
      <Read label="Entry in row i, column j" value="uᵢ × vⱼ" tone="amber" />
      <Read label="Numbers to store" value="6 instead of 9" />
      <Read label="Rank" value={String(rankOf(P))} />
    </>}
    foot={flag(props, "save") ? <SaveRow what={<>Keep this layer as <b>layer1</b></>} saved={saved} onSave={() => save("layer1", P, "b2-la-06", { note: `column (${u.join(", ")}) times row (${v.join(", ")})` })} /> : undefined} />;
}

/* ------------------------------------------------------------ 12: pixel pairs ------------------------------------------------------------ */

function PairView(_: SceneProps) {
  const { b2 } = useB2();
  const img = readImg(b2.shelf.img?.value);
  const [pick, setPick] = useState<[number, number]>([2, 1]);
  const avg = img.map(r => [0, 1, 2, 3].map(k => (r[2 * k]! + r[2 * k + 1]!) / 2));
  const dif = img.map(r => [0, 1, 2, 3].map(k => (r[2 * k]! - r[2 * k + 1]!) / 2));
  const [i, k] = pick, a = img[i]![2 * k]!, b = img[i]![2 * k + 1]!;
  const tiny = dif.flat().filter(d => Math.abs(d) <= 1).length;
  const S = 150;
  const svg = (
    <svg viewBox="0 0 360 250" className="b2pic" role="img" aria-label="Your picture, its pair averages and its pair differences.">
      <Pix M={img} x={8} y={14} size={S} max={9} label="picture" onCell={(r, c) => ({ onClick: () => setPick([r, Math.floor(c / 2)]), style: { cursor: "pointer" } })} />
      <rect x={8 + 2 * k * (S / 8)} y={14 + i * (S / 8)} width={2 * (S / 8)} height={S / 8} style={ink("amber", 2)} />
      <Pix M={avg} x={176} y={14} size={S * 0.5 * 1.2} max={9} />
      <text x={176 + 45} y={14 + 90 + 14} textAnchor="middle" className="b2t sky">average</text>
      <Pix M={dif} x={270} y={14} size={S * 0.5 * 1.2} max={4.5} signed />
      <text x={270 + 45} y={14 + 90 + 14} textAnchor="middle" className="b2t pink">difference</text>
      <text x={176} y={150} className="b2t">tap a pair in the picture</text>
    </svg>
  );
  return <Scene svg={svg} readouts={<>
    <Read label="This pair (a, b)" value={`(${a}, ${b})`} />
    <Read label="((a + b)/2, (a − b)/2)" value={`(${fx((a + b) / 2, 1).replace(/\.0$/, "")}, ${fx((a - b) / 2, 1).replace(/\.0$/, "")})`} tone="amber" />
    <Read label="Differences of size 1 or less" value={`${tiny} of 32`} tone="pink" />
  </>} />;
}

/* ------------------------------------------------------------ 18: layers ------------------------------------------------------------ */

function LayersView({ props, marker }: SceneProps) {
  const { b2 } = useB2();
  const img = flag(props, "fixed") ? IMG0 : readImg(b2.shelf.img?.value);
  const d = useMemo(() => svd(img), [img]);
  const [k, setK] = useState(num(props, "k", 1));
  const quiet = flag(props, "quiet") || flag(props, "hide");
  const A = rebuild(d, k), E = img.map((r, i) => r.map((v, j) => v - A[i]![j]!));
  const kept = energyKept(d.s, k);
  const S = 116;
  const strip = [0, 1, 2, 3].map(t => layer(d, t));
  const svg = (
    <svg viewBox="0 0 360 270" className="b2pic" role="img" aria-label={quiet ? `A picture rebuilt from ${k} ${k === 1 ? "layer" : "layers"}.` : `Your picture rebuilt from ${k} layers, keeping ${fx(kept * 100, 1)} percent of its energy.`}>
      <Pix M={img} x={6} y={10} size={S} max={9} label="picture" />
      <Pix M={A} x={122} y={10} size={S} max={9} label={k === 1 ? "1 layer" : `${k} layers`} />
      <Pix M={E} x={238} y={10} size={S} max={4} signed label="what's left" />
      {strip.map((L, t) => <Pix key={t} M={L} x={8 + t * 88} y={160} size={64} max={Math.max(1, ...L.flat().map(Math.abs))} signed label={`layer ${t + 1}`} />)}
      {strip.map((_, t) => t < k && <rect key={`o${t}`} x={6 + t * 88} y={158} width={68} height={68} rx="4" style={ink("amber", 2)} />)}
      {marker && <g>
        <rect x={122} y={248} width={232} height="10" rx="5" className="b2bar track" />
        <line x1={122 + 232 * (marker[0] / 100)} y1={243} x2={122 + 232 * (marker[0] / 100)} y2={262} className="b2mark" style={{ strokeWidth: 3 }} />
        {!quiet && <rect x={122} y={248} width={232 * kept} height="10" rx="5" style={tint("amber", 0.9)} />}
      </g>}
    </svg>
  );
  return <Scene svg={svg}
    controls={<Slider label="Layers kept, k" value={k} min={1} max={8} step={1} onChange={setK} format={v => String(v)} />}
    readouts={<>
      {!quiet && <Read label="σ's" value={d.s.slice(0, 5).map(s => fx(s, 1)).join(", ") + ", …"} />}
      {!quiet && <Read label="Energy kept" value={`${fx(kept * 100, 1)}%`} tone="amber" />}
      {!quiet && <Read label="Error, √(dropped σ²)" value={fx(Math.sqrt(d.s.slice(k).reduce((s, x) => s + x * x, 0)), 2)} tone="pink" />}
    </>} />;
}

/* ------------------------------------------------------------ the plaid project ------------------------------------------------------------ */

const PLAID0 = [
  { u: [1, 1, 0, 0, 1, 1], v: [2, 2, 0, 0, 2, 2] },
  { u: [0, 1, 1, 1, 1, 0], v: [0, 1, 1, 1, 1, 0] },
  { u: [3, 0, 0, 0, 0, 3], v: [0, 0, 1, 1, 0, 0] },
];
function PlaidView({ props, place }: SceneProps) {
  const project = flag(props, "project") || place === "project";
  const { b2, save, note } = useB2();
  const [L, setL] = useState(PLAID0.map(l => ({ u: [...l.u], v: [...l.v] })));
  const [count, setCount] = useState(2);
  const bump = (t: number, part: "u" | "v", i: number) => setL(ls => ls.map((l, a) => (a === t ? { ...l, [part]: l[part].map((x, b) => (b === i ? (x + 1) % 4 : x)) } : l)));
  const M = Array.from({ length: 6 }, (_, i) => Array.from({ length: 6 }, (_, j) => L.slice(0, count).reduce((s, l) => s + l.u[i]! * l.v[j]!, 0)));
  const max = Math.max(1, ...M.flat());
  const rank = rankOf(M);
  const c = 15;
  const svg = (
    <svg viewBox="0 0 360 270" className="b2pic" role="img" aria-label={`A 6 by 6 plaid from ${count} layers, rank ${rank}.`}>
      {L.slice(0, count).map((l, t) => {
        const x = 8 + t * 116, y = 8;
        return <g key={t}>
          {l.u.map((v, i) => <rect key={`u${i}`} x={x} y={y + 20 + i * c} width={c - 2} height={c - 2} rx="2" style={{ ...tint("sky", 0.12 + 0.28 * v), cursor: "pointer" }} onClick={() => bump(t, "u", i)} />)}
          {l.v.map((v, j) => <rect key={`v${j}`} x={x + 18 + j * c} y={y} width={c - 2} height={c - 2} rx="2" style={{ ...tint("pink", 0.12 + 0.28 * v), cursor: "pointer" }} onClick={() => bump(t, "v", j)} />)}
          <Pix M={l.u.map(a => l.v.map(b => a * b))} x={x + 18} y={y + 20} size={6 * c - 2} max={9} />
          <text x={x + 18 + 3 * c} y={y + 20 + 6 * c + 16} textAnchor="middle" className="b2t">layer {t + 1}</text>
        </g>;
      })}
      <Pix M={M} x={110} y={150} size={108} max={max} />
      <text x={110 + 54} y={150 + 108 + 14} textAnchor="middle" className="b2t amber">the sum</text>
      <text x={10} y={170} className="b2t">tap the sky and</text>
      <text x={10} y={188} className="b2t">pink squares</text>
    </svg>
  );
  const saved = JSON.stringify(b2.shelf.plaid?.value) === JSON.stringify(M);
  return <Scene svg={svg}
    controls={<Toggle label="Layers" value={String(count)} onChange={v => setCount(Number(v))} options={[{ v: "1", label: "1 layer" }, { v: "2", label: "2 layers" }, { v: "3", label: "3 layers" }]} />}
    readouts={<>
      <Read label="Rank of the sum" value={String(rank)} tone="amber" />
      <Read label="Storage, k(6 + 6 + 1)" value={`${storage(count, 6, 6)} of 36`} tone="sky" />
    </>}
    foot={project ? <SaveRow what={<>Keep the plaid as <b>plaid</b> (rank {rank})</>} saved={saved} onSave={() => {
      save("plaid", M, "la-plaid", { note: `${count} layers, rank ${rank}, ${storage(count, 6, 6)} numbers instead of 36` });
      note({ id: "la-plaid", track: "la", title: "Plaid from layers", project: "la-plaid", data: { layers: count, rank },
        lines: [`A 6 × 6 plaid from ${count === 1 ? "1 layer" : `${count} layers`}: rank ${rank}.`, `It costs ${storage(count, 6, 6)} numbers instead of 36.`] });
    }} /> : undefined} />;
}

/* ------------------------------------------------------------ 20: the build ------------------------------------------------------------ */

/** a picture as an image, through a canvas (grayscale, or three channels); null where there is no canvas */
function toURL(ch: Mat[], lo = 0, hi = 1): string | null {
  if (typeof document === "undefined") return null;
  const m = ch[0]!.length, n = ch[0]![0]!.length;
  const cv = document.createElement("canvas");
  cv.width = n; cv.height = m;
  let ctx: CanvasRenderingContext2D | null = null;
  try { ctx = cv.getContext("2d"); } catch { ctx = null; }
  if (!ctx) return null;
  const im = ctx.createImageData(n, m);
  for (let i = 0; i < m; i++) for (let j = 0; j < n; j++) {
    const at = 4 * (i * n + j);
    for (let c = 0; c < 3; c++) { const v = ch[ch.length === 3 ? c : 0]![i]![j]!; im.data[at + c] = Math.max(0, Math.min(255, Math.round(((v - lo) / (hi - lo)) * 255))); }
    im.data[at + 3] = 255;
  }
  ctx.putImageData(im, 0, 0);
  return cv.toDataURL();
}

/** a photo file, shrunk to at most `max` pixels a side, as three channels 0 … 1 */
async function loadPhoto(file: File, max = 96): Promise<Mat[] | null> {
  const url = URL.createObjectURL(file);
  try {
    const img = new Image();
    await new Promise((ok, no) => { img.onload = ok; img.onerror = no; img.src = url; });
    const s = Math.min(1, max / Math.max(img.width, img.height));
    const n = Math.max(8, Math.round(img.width * s)), m = Math.max(8, Math.round(img.height * s));
    const cv = document.createElement("canvas");
    cv.width = n; cv.height = m;
    const ctx = cv.getContext("2d");
    if (!ctx) return null;
    ctx.drawImage(img, 0, 0, n, m);
    const d = ctx.getImageData(0, 0, n, m).data;
    return [0, 1, 2].map(c => Array.from({ length: m }, (_, i) => Array.from({ length: n }, (_, j) => d[4 * (i * n + j) + c]! / 255)));
  } catch { return null; } finally { URL.revokeObjectURL(url); }
}

function BuildView({ props, place, marker }: SceneProps) {
  const project = flag(props, "project") || place === "project";
  const quiet = flag(props, "quiet") || flag(props, "hide");
  const { b2, save, note } = useB2();
  const [src, setSrc] = useState<"photo" | "img" | "mine">("photo");
  const [mine, setMine] = useState<Mat[] | null>(null);
  const [color, setColor] = useState(false);
  const file = useRef<HTMLInputElement>(null);
  const size = num(props, "size", 100);
  const chans: Mat[] = useMemo(() => {
    if (src === "img") return [readImg(b2.shelf.img?.value).map(r => r.map(v => v / 9))];
    if (src === "mine" && mine) return color ? mine : [mine[0]!.map((r, i) => r.map((_, j) => 0.3 * mine[0]![i]![j]! + 0.59 * mine[1]![i]![j]! + 0.11 * mine[2]![i]![j]!))];
    return [samplePhoto(size, size)];
  }, [src, mine, color, size, b2.shelf.img?.value]);
  const dec = useMemo(() => chans.map(c => svd(c)), [chans]);
  const m = chans[0]!.length, n = chans[0]![0]!.length, kMax = Math.min(m, n);
  const [k, setK] = useState(num(props, "k", 10));
  const kk = Math.min(k, kMax);
  const rebuilt = useMemo(() => dec.map(d => rebuild(d, kk)), [dec, kk]);
  const err = rebuilt.map((R, c) => R.map((r, i) => r.map((v, j) => Math.abs(chans[c]![i]![j]! - v))));
  const sig = dec[0]!.s;
  const energy = dec.reduce((s, d) => s + energyKept(d.s, kk), 0) / dec.length;
  const store = storage(kk, m, n) * chans.length, orig = m * n * chans.length;
  const share = store / orig;
  const [urls, setUrls] = useState<(string | null)[]>([null, null, null]);
  useEffect(() => { setUrls([toURL(chans), toURL(rebuilt), toURL(err, 0, 0.35)]); }, [chans, rebuilt]); // eslint-disable-line react-hooks/exhaustive-deps

  // the σ plot on a log scale, with the cut after σₖ
  const N = Math.min(60, sig.length), px = 44, py = 152, pw = 306, ph = 50;
  const lmax = Math.log10(sig[0]! || 1), lmin = Math.log10(Math.max(1e-3, sig[N - 1]! || 1e-3));
  const sx = (i: number) => px + (i / Math.max(1, N - 1)) * pw;
  const sy = (s: number) => py + ph - ((Math.log10(Math.max(1e-3, s)) - lmin) / (lmax - lmin || 1)) * ph;
  const S = 112;
  const pic = (u: string | null, x: number, label: string, M?: Mat, err?: boolean) => (
    <g>
      {u ? <image href={u} x={x} y={6} width={S} height={S} preserveAspectRatio="none" style={{ imageRendering: "pixelated" }} /> : M ? <Pix M={M} x={x} y={6} size={S} max={err ? 0.35 : 1} /> : <rect x={x} y={6} width={S} height={S} style={{ fill: "var(--well)" }} />}
      <text x={x + S / 2} y={S + 22} textAnchor="middle" className="b2t">{label}</text>
    </g>
  );
  const barY = 236, barW = 344, barX = 8;
  const svg = (
    <svg viewBox="0 0 360 256" className="b2pic" role="img" aria-label={quiet ? `A ${m} by ${n} picture kept with ${kk} layers.` : `A ${m} by ${n} picture kept with ${kk} layers: ${fx(share * 100, 1)} percent of the numbers, ${fx(energy * 100, 1)} percent of the energy.`}>
      {pic(urls[0]!, 6, "original", src === "img" ? chans[0] : undefined)}
      {pic(urls[1]!, 124, kk === 1 ? "1 layer" : `${kk} layers`, src === "img" ? rebuilt[0] : undefined)}
      {!quiet && pic(urls[2]!, 242, "what's lost", src === "img" ? err[0] : undefined, true)}
      {!quiet && <>
        <text x={8} y={py + 14} className="b2t">σ</text>
        <text x={8} y={py + 32} className="b2t">log</text>
        {sig.slice(0, N).map((s, i) => <circle key={i} cx={sx(i)} cy={sy(s)} r="2.4" className={`b2dot ${i < kk ? "amber" : "trav"}`} />)}
        {kk < N && <line x1={sx(kk - 0.5)} y1={py - 4} x2={sx(kk - 0.5)} y2={py + ph + 4} style={ink("amber", 1.5, "4 3")} />}
      </>}
      <rect x={barX} y={barY} width={barW} height="12" rx="6" className="b2bar track" />
      {!quiet && <rect x={barX} y={barY} width={Math.min(1, share) * barW} height="12" rx="6" style={tint(share < 1 ? "sky" : "pink", 0.9)} />}
      {marker && <line x1={barX + Math.min(1, marker[0] / 100) * barW} y1={barY - 6} x2={barX + Math.min(1, marker[0] / 100) * barW} y2={barY + 18} className="b2mark" style={{ strokeWidth: 3 }} />}
      <text x={barX} y={barY - 7} className="b2t sky">{quiet ? "size against the original" : `stores ${store.toLocaleString("en-US")} of ${orig.toLocaleString("en-US")} numbers`}</text>
    </svg>
  );
  const sigma = sig.slice(0, Math.min(kk, 50)).map(s => Math.round(s * 1000) / 1000);
  const saved = (b2.shelf.k?.value as number | undefined) === kk && JSON.stringify(b2.shelf.sigma?.value) === JSON.stringify(sigma);
  const controls: ReactNode = <>
    <Slider label="Layers kept, k" value={kk} min={1} max={kMax} step={1} onChange={setK} format={v => String(v)} marks={[1, 5, 10, 20].filter(v => v <= kMax).map(v => ({ v, label: String(v) }))} />
    <Toggle label="Picture" value={src} onChange={v => { if (v === "mine" && !mine) file.current?.click(); else setSrc(v); }} options={[{ v: "photo", label: "Sample photo" }, { v: "img", label: "Your img" }, { v: "mine", label: mine ? "Your photo" : "Load a photo" }]} />
    {src === "mine" && mine && <Toggle label="Channels" value={color ? "color" : "gray"} onChange={v => setColor(v === "color")} options={[{ v: "gray", label: "Gray" }, { v: "color", label: "Color, per channel" }]} />}
    <input ref={file} type="file" accept="image/*" hidden onChange={async e => { const f = e.currentTarget.files?.[0]; if (!f) return; const ch = await loadPhoto(f); if (ch) { setMine(ch); setSrc("mine"); setK(k2 => Math.min(k2, Math.min(ch[0]!.length, ch[0]![0]!.length))); } }} />
  </>;
  return <Scene svg={svg} controls={controls}
    readouts={quiet ? <Read label="Picture" value={`${m} × ${n}`} /> : <>
      <Read label="Picture" value={`${m} × ${n}${chans.length === 3 ? " × 3" : ""}`} />
      <Read label="Size kept" value={`${fx(share * 100, 1)}%`} tone={share < 1 ? "sky" : "pink"} />
      <Read label="Energy kept" value={`${fx(energy * 100, 1)}%`} tone="amber" />
      <Read label="Saves space while k ≤" value={String(largestK(m, n))} />
    </>}
    foot={project ? <SaveRow what={<>Keep <b>k</b> = {kk} and <b>sigma</b>: {fx(share * 100, 1)}% of the size, {fx(energy * 100, 1)}% of the energy</>} saved={saved} onSave={() => {
      save("k", kk, "la-build", { note: `${m} × ${n}${chans.length === 3 ? " in color" : ""}, ${fx(share * 100, 1)}% of the size` });
      save("sigma", sigma, "la-build", { note: `the first ${sigma.length} singular values` });
      note({ id: "la-build", track: "la", title: "The build: image compressor", project: "la-build", build: true, data: { k: kk, m, n, energy, share },
        lines: [`A ${m} × ${n} ${src === "mine" ? "photo of yours" : src === "img" ? "picture (your img)" : "sample photo"}${chans.length === 3 ? ", per channel" : ""}, kept with k = ${kk}.`,
          `Stores ${store.toLocaleString("en-US")} numbers instead of ${orig.toLocaleString("en-US")}: ${fx(share * 100, 1)}% of the size.`,
          `Energy kept: ${fx(energy * 100, 1)}%. σ₁ = ${fx(sig[0]!, 2)}.`] });
    }} /> : undefined} />;
}
