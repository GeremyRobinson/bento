// The Shrinker, the track's build (information.md), and the projects that assemble it. One sentence, typed once and kept
// in the tools' state, runs through every stage:
// profile: letter counts, each letter's surprise, and the entropy per letter H_msg (project after 04: H_msg, counts_msg).
// code: the Huffman tree and code table for those counts, and the shrunk size (project after 06: code_msg, Shrinker v1).
// predict: a one-letter-context model trained on the sentence; its bits per letter fall below H_msg (project after 08:
//   model_msg, Shrinker v2).
// score: the model's cross-entropy on the sentence, and on another one you type (09's Use it: xent_msg).
// pairs: I(previous; next) = H(next) − H(next | previous) for the sentence (10's Use it).
// armor: the Huffman bits in Hamming (7, 4) blocks (11's Use it: armor, Shrinker v3).
// sizes: raw, compressed and armored bars for N letters and S bits (12's guess and Work it).
// full: the whole pipe, message → counts → code → bits → armor → noise → repaired → decoded (the build: final_bpl).
import { useMemo, useState, type ReactNode } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { armor, contextModel, crossEntropyOn, letterCounts, pairInformation, seeded, showSym, shrink, surprise, unarmor } from "../maths";
import { useMessage } from "./message";

const W = 360;
type Stage = "profile" | "code" | "predict" | "score" | "pairs" | "armor" | "sizes" | "full";
const TITLES: Record<string, string> = { profile: "Your surprise profile", code: "Your first code", predict: "Predict me", full: "The build: the Shrinker" };

export function ShrinkerScene({ props, place, marker }: SceneProps) {
  const stage = str<Stage>(props, "stage", "full");
  if (stage === "sizes") return <Sizes props={props} marker={marker} />;
  return <Pipe stage={stage} place={place} />;
}

function MessageBox({ text, setText }: { text: string; setText: (t: string) => void }) {
  return (
    <label className="b2field wide full"><span>Your message</span>
      <input value={text} maxLength={400} aria-label="Your message" onChange={e => setText(e.currentTarget.value)} /></label>
  );
}

function Pipe({ stage, place }: { stage: Stage; place: SceneProps["place"] }) {
  const [text, setText] = useMessage();
  const msg = text.trim() ? text : "a";
  const { b2, save, note } = useB2();
  const s = useMemo(() => shrink(msg), [msg]);
  const model = useMemo(() => contextModel(msg), [msg]);
  const withCtx = model.costs(true), alone = model.costs(false);
  const ctxBpl = withCtx.reduce((a, b) => a + b, 0) / s.n;
  const huffBpl = s.huffBits / s.n;
  const [other, setOther] = useState("the dog sat on the cat");
  const [f, setF] = useState(0.02);
  const [roll, setRoll] = useState(1);
  const [at, setAt] = useState(0);
  const saveable = place !== "lesson" || ["score", "armor"].includes(stage);
  const shelfIs = (name: string, v: number) => typeof b2.shelf[name]?.value === "number" && Math.abs((b2.shelf[name]!.value as number) - v) < 1e-9;
  const counts = letterCounts(msg);

  let svg: ReactNode, readouts: ReactNode, foot: ReactNode = null, extra: ReactNode = null;

  if (stage === "profile" || stage === "pairs") {
    const k = Math.min(18, s.sym.length), slot = 330 / k, M = s.n;
    const top = Math.max(...s.counts);
    const info = pairInformation(msg);
    svg = (
      <svg viewBox={`0 0 ${W} 250`} className="b2pic" role="img" aria-label={`${s.n} symbols, ${s.sym.length} different. Entropy ${fx(s.H, 3)} bits per letter.`}>
        <text x="14" y="14" className="b2t sky">count</text>
        <text x="14" y="146" className="b2t pink">surprise, bits</text>
        <line x1="14" y1="110" x2={W - 14} y2="110" className="b2axis" />
        <line x1="14" y1="236" x2={W - 14} y2="236" className="b2axis" />
        {s.sym.slice(0, k).map((c, i) => {
          const x = 16 + i * slot, h = (s.counts[i]! / top) * 80, sp = surprise(s.counts[i]! / M);
          return (
            <g key={c}>
              <rect x={x + 2} y={110 - h} width={slot - 4} height={h} rx="3" className="b2bar sky" />
              <text x={x + slot / 2} y="126" textAnchor="middle" className="b2t">{showSym(c)}</text>
              <rect x={x + 2} y={236 - Math.min(7, sp) * 11} width={slot - 4} height={Math.min(7, sp) * 11} rx="3" className="b2bar pink" opacity="0.8" />
            </g>
          );
        })}
        <line x1="14" y1={236 - s.H * 11} x2={W - 14} y2={236 - s.H * 11} className="b2leg amber" />
        <text x={W - 14} y={236 - s.H * 11 - 6} textAnchor="end" className="b2t amber">H_msg = {fx(s.H, 2)}</text>
      </svg>
    );
    readouts = stage === "pairs" ? <>
      <Read label="H(next)" value={`${fx(info.hNext, 3)} bits`} tone="sky" />
      <Read label="H(next | previous)" value={`${fx(info.hCond, 3)} bits`} tone="pink" />
      <Read label="I(previous; next)" value={`${fx(info.info, 3)} bits`} tone="amber" big />
    </> : <>
      <Read label="Letters" value={s.n} />
      <Read label="Different" value={s.sym.length} />
      <Read label="H_msg" value={`${fx(s.H, 3)} bits per letter`} tone="amber" big />
      <Read label="Floor for the whole message" value={`${Math.ceil(s.H * s.n)} bits`} />
    </>;
    if (stage === "profile" && saveable) foot = <SaveRow what={<>Keep <b>H_msg = {fx(s.H, 3)}</b> and <b>counts_msg</b></>} saved={shelfIs("H_msg", s.H)} onSave={() => {
      save("H_msg", s.H, "in-profile", { unit: "bits per letter", note: `entropy per letter of "${msg.slice(0, 40)}"` });
      save("counts_msg", counts.counts, "in-profile", { labels: counts.sym.map(showSym), note: "letter counts of your message" });
      note({ id: "in-profile", track: "in", title: TITLES.profile!, project: "in-profile", data: { H: s.H, n: s.n },
        lines: [`"${msg.slice(0, 80)}"`, `${s.n} letters, ${s.sym.length} different. H_msg = ${fx(s.H, 3)} bits per letter.`, `Most common: ${counts.sym.slice(0, 5).map((c, i) => `${showSym(c)} ${counts.counts[i]}`).join(", ")}.`] });
    }} />;
  } else if (stage === "code") {
    // the code table, longest codes last
    const rows = s.sym.map((c, i) => ({ c, code: s.code[i]!, n: s.counts[i]! })).sort((a, b) => a.code.length - b.code.length || b.n - a.n);
    const maxL = Math.max(...s.lengths), k = rows.length;
    const colW = 330 / Math.min(k, 12);
    svg = (
      <svg viewBox={`0 0 ${W} 250`} className="b2pic" role="img" aria-label={`A Huffman code: ${s.huffBits} bits for ${s.n} letters.`}>
        {rows.slice(0, 12).map((r, i) => (
          <g key={r.c}>
            <rect x={16 + i * colW + 2} y="18" width={colW - 4} height={(r.code.length / maxL) * 120} rx="3" className="b2bar sky" opacity="0.8" />
            <text x={16 + i * colW + colW / 2} y="156" textAnchor="middle" className="b2t">{showSym(r.c)}</text>
            <text x={16 + i * colW + colW / 2} y="174" textAnchor="middle" className="b2t sky">{r.code.length}</text>
          </g>
        ))}
        <text x="16" y="194" className="b2t">code length per letter, common first</text>
        <rect x="16" y="206" width="328" height="12" rx="3" className="b2bar track" />
        <rect x="16" y="206" width={(328 * s.huffBits) / s.raw} height="12" rx="3" className="b2bar amber" />
        <text x="16" y="240" className="b2t amber">{s.huffBits} bits, against {s.raw.toLocaleString("en-US")} raw</text>
      </svg>
    );
    readouts = <>
      <Read label="Huffman" value={`${fx(huffBpl)} bits per letter`} tone="amber" big />
      <Read label="H_msg" value={fx(s.H, 3)} tone="sky" />
      <Read label="Raw" value="8 bits per letter" />
    </>;
    extra = <div className="b2codes">{rows.map(r => <span key={r.c}><b>{showSym(r.c)}</b> {r.code}</span>)}</div>;
    if (saveable) foot = <SaveRow what={<>Keep <b>code_msg</b>: {s.huffBits} bits, {fx(huffBpl)} a letter</>} saved={JSON.stringify(b2.shelf.code_msg?.value) === JSON.stringify(s.lengths)} onSave={() => {
      save("code_msg", s.lengths, "in-code", { labels: s.sym.map(showSym), unit: "bits", note: `Huffman code lengths; ${s.huffBits} bits in all` });
      note({ id: "in-code", track: "in", title: TITLES.code!, project: "in-code", data: { bits: s.huffBits, n: s.n },
        lines: [`"${msg.slice(0, 80)}"`, `${s.huffBits} bits: ${fx(huffBpl)} per letter, against H_msg ${fx(s.H, 3)} and 8 raw.`, rows.map(r => `${showSym(r.c)} ${r.code}`).join(" · ")] });
    }} />;
  } else if (stage === "predict" || stage === "score") {
    const i = Math.min(at, s.n - 1);
    const xs = model.syms, slot = Math.max(9, 330 / Math.min(xs.length, 36));
    const view = xs.slice(Math.max(0, i - 35), i + 1), off = Math.max(0, i - 35);
    const otherX = crossEntropyOn(model, other || " ");
    svg = (
      <svg viewBox={`0 0 ${W} 250`} className="b2pic" role="img" aria-label={`Bits per letter: ${fx(ctxBpl)} with context, ${fx(s.H)} without.`}>
        <text x="14" y="16" className="b2t pink">letters alone</text>
        <text x="14" y="136" className="b2t sky">after the last letter</text>
        <line x1="14" y1="110" x2={W - 14} y2="110" className="b2axis" />
        <line x1="14" y1="230" x2={W - 14} y2="230" className="b2axis" />
        {view.map((c, j) => {
          const k = off + j, x = 14 + j * slot;
          return (
            <g key={k}>
              <rect x={x + 1} y={110 - Math.min(8, alone[k]!) * 10} width={slot - 2} height={Math.min(8, alone[k]!) * 10} rx="2" className="b2bar pink" opacity="0.8" />
              <rect x={x + 1} y={230 - Math.min(8, withCtx[k]!) * 10} width={slot - 2} height={Math.min(8, withCtx[k]!) * 10} rx="2" className="b2bar sky" opacity="0.85" />
              {slot >= 12 && <text x={x + slot / 2} y="246" textAnchor="middle" className="b2t">{showSym(c)}</text>}
            </g>
          );
        })}
        <line x1="14" y1={110 - s.H * 10} x2={W - 14} y2={110 - s.H * 10} className="b2mark amber" />
        <line x1="14" y1={230 - ctxBpl * 10} x2={W - 14} y2={230 - ctxBpl * 10} className="b2leg amber" />
        <text x={W - 14} y={230 - ctxBpl * 10 - 6} textAnchor="end" className="b2t amber">{fx(ctxBpl)} a letter</text>
      </svg>
    );
    readouts = stage === "score" ? <>
      <Read label="H_msg, letters alone" value={fx(s.H, 3)} tone="pink" />
      <Read label="Cross-entropy on your message" value={`${fx(ctxBpl, 3)} bits per letter`} tone="sky" big />
      <Read label="On the other message" value={`${fx(otherX, 3)} bits per letter`} tone="amber" />
    </> : <>
      <Read label="Letters alone" value={`${fx(alone.reduce((a, b) => a + b, 0) / s.n)} bits per letter`} tone="pink" />
      <Read label="After the last letter" value={`${fx(ctxBpl)} bits per letter`} tone="sky" big />
      <Read label="H_msg" value={fx(s.H, 3)} />
    </>;
    extra = <>
      <Slider label="Read up to letter" value={i} min={0} max={Math.max(0, s.n - 1)} step={1} onChange={setAt} format={v => `${v + 1} of ${s.n}`} />
      {stage === "score" && <label className="b2field wide"><span>Another message</span><input value={other} maxLength={200} aria-label="Another message to score" onChange={e => setOther(e.currentTarget.value)} /></label>}
    </>;
    if (stage === "predict" && saveable) foot = <SaveRow what={<>Keep <b>model_msg = {fx(ctxBpl, 3)}</b> bits per letter</>} saved={shelfIs("model_msg", ctxBpl)} onSave={() => {
      save("model_msg", ctxBpl, "in-predict", { unit: "bits per letter", note: "one-letter-context model on your message" });
      note({ id: "in-predict", track: "in", title: TITLES.predict!, project: "in-predict", data: { bpl: ctxBpl },
        lines: [`"${msg.slice(0, 80)}"`, `Letters alone: ${fx(s.H, 3)} bits per letter. After the last letter: ${fx(ctxBpl, 3)}.`] });
    }} />;
    if (stage === "score") foot = <SaveRow what={<>Keep <b>xent_msg = {fx(ctxBpl, 3)}</b> bits per letter</>} saved={shelfIs("xent_msg", ctxBpl)} onSave={() =>
      save("xent_msg", ctxBpl, "b2-in-09", { unit: "bits per letter", note: "the context model's cross-entropy on your message" })} />;
  } else if (stage === "armor") {
    svg = <SizeBars rows={[["raw", s.raw, "sky"], ["Huffman", s.huffBits, "amber"], ["armored", s.armored, "trav"]]} />;
    readouts = <>
      <Read label="Blocks of 4" value={s.blocks} />
      <Read label="Armored" value={`${s.armored.toLocaleString("en-US")} bits`} tone="trav" big />
      <Read label="Rate" value="4/7" />
    </>;
    const val = [4 / 7, s.armored];
    foot = <SaveRow what={<>Keep <b>armor</b>: rate 4/7, {s.armored} bits</>} saved={JSON.stringify(b2.shelf.armor?.value) === JSON.stringify(val)} onSave={() =>
      save("armor", val, "b2-in-11", { labels: ["rate", "bits"], note: "Hamming (7, 4) around your Huffman bits" })} />;
  } else {
    // the full pipe: Huffman bits, armored, sent through noise, repaired, decoded
    const blocks = armor(s.bits);
    const r = seeded(roll * 977 + Math.round(f * 1000));
    const sent = blocks.map(b => b.map(x => (r() < f ? 1 - x : x)));
    const flips = sent.reduce((a, b, i) => a + b.filter((x, j) => x !== blocks[i]![j]).length, 0);
    const twice = sent.filter((b, i) => b.filter((x, j) => x !== blocks[i]![j]).length >= 2).length;
    const back = unarmor(sent, s.bits.length);
    const decoded = decodeWith(back.bits, s.code, s.sym);
    const ok = decoded === [...msg.toLowerCase().replace(/\s+/g, " ")].join("");
    svg = <SizeBars rows={[["raw", s.raw, "sky"], ["Huffman", s.huffBits, "amber"], ["context model", Math.ceil(withCtx.reduce((a, b) => a + b, 0)), "mint"], ["armored", s.armored, "trav"]]} />;
    readouts = <>
      <Read label="Flipped by noise" value={flips} tone="pink" />
      <Read label="Repaired" value={back.fixed} tone="sky" />
      <Read label="Blocks hit twice" value={twice} tone={twice ? "pink" : undefined} />
      <Read label="Final" value={`${fx(huffBpl)} bits per letter`} tone="amber" big />
    </>;
    extra = <>
      <Slider label="Noise: chance each bit flips" value={f} min={0} max={0.1} step={0.005} onChange={setF} format={x => fx(x, 3)} />
      <button type="button" className="ctl" onClick={() => setRoll(x => x + 1)}>Send again</button>
      <p className={`b2decoded${ok ? "" : " bad"}`} aria-live="polite"><small>Decoded</small> {decoded.slice(0, 160) || "–"}</p>
    </>;
    if (saveable) foot = <SaveRow what={<>Keep <b>final_bpl = {fx(huffBpl, 3)}</b> and the ledger in your Notebook</>} saved={shelfIs("final_bpl", huffBpl)} onSave={() => {
      save("final_bpl", huffBpl, "in-shrinker", { unit: "bits per letter", note: "your message through the Shrinker" });
      const xent = b2.shelf.xent_msg?.value;
      note({ id: "in-shrinker", track: "in", title: TITLES.full!, project: "in-shrinker", build: true, data: { n: s.n, bits: s.huffBits, armored: s.armored },
        lines: [`"${msg.slice(0, 80)}": ${s.n} letters, ${s.raw.toLocaleString("en-US")} bits raw.`,
          `H_msg ${fx(s.H, 3)}; Huffman ${s.huffBits} bits (${fx(huffBpl, 3)} a letter); context model ${fx(ctxBpl, 3)}${typeof xent === "number" ? `; xent_msg ${fx(xent, 3)}` : ""}.`,
          `Armored: ${s.armored.toLocaleString("en-US")} bits. At noise ${fx(f, 3)}: ${flips} flipped, ${back.fixed} repaired${twice ? `, ${twice} blocks lost` : ""}.`] });
    }} />;
  }

  return (
    <Scene svg={svg}
      controls={<><MessageBox text={text} setText={setText} />{extra}</>}
      readouts={readouts}
      foot={foot ?? undefined}
    />
  );
}

/** reads Huffman bits back into letters */
function decodeWith(bits: string, code: string[], sym: string[]) {
  let out = "", cur = "";
  for (const b of bits) { cur += b; const k = code.indexOf(cur); if (k >= 0) { out += sym[k]; cur = ""; } if (cur.length > 24) { out += "?"; cur = ""; } }
  return out;
}

function SizeBars({ rows, hideLast, marker }: { rows: [string, number, string][]; hideLast?: boolean; marker?: number }) {
  const top = Math.max(...rows.map(r => r[1]), marker ?? 0);
  const bw = (b: number) => (b / top) * 300;
  return (
    <svg viewBox={`0 0 ${W} ${30 + rows.length * 52}`} className="b2pic" role="img" aria-label={rows.map(r => `${r[0]} ${r[1]} bits`).join(", ")}>
      {rows.map(([label, bits, tone], i) => {
        const y = 24 + i * 52, hid = hideLast && i === rows.length - 1;
        return (
          <g key={label}>
            <text x="20" y={y} className="b2t">{label}</text>
            <rect x="20" y={y + 6} width="300" height="22" rx="5" className="b2bar track" />
            {!hid && <rect x="20" y={y + 6} width={Math.max(2, bw(bits))} height="22" rx="5" className={`b2bar ${tone}`} />}
            <text x={W - 16} y={y} textAnchor="end" className={`b2t ${tone}`}>{hid ? "?" : bits.toLocaleString("en-US")}</text>
          </g>
        );
      })}
      {marker != null && <g><line x1={20 + bw(marker)} y1={24 + (rows.length - 1) * 52} x2={20 + bw(marker)} y2={24 + (rows.length - 1) * 52 + 34} className="b2mark guess" /></g>}
    </svg>
  );
}

function Sizes({ props, marker }: { props: SceneProps["props"]; marker?: [number, number] }) {
  const [N, setN] = useState(num(props, "N", 400));
  const [S, setS] = useState(num(props, "S", 900));
  const quiet = flag(props, "quiet");
  const arm = Math.ceil(S / 4) * 7;
  return (
    <Scene svg={<SizeBars rows={[["raw, 8 a letter", 8 * N, "sky"], ["compressed", S, "amber"], ["armored", arm, "trav"]]} hideLast={quiet} marker={marker?.[0]} />}
      controls={<>
        <Slider label="Letters N" value={N} min={50} max={1000} step={50} onChange={setN} format={v => String(v)} />
        <Slider label="Compressed S" value={S} min={100} max={4000} step={4} onChange={setS} format={v => `${v} bits`} />
      </>}
      readouts={<>
        <Read label="Bits per letter" value={fx(S / N)} tone="amber" />
        <Read label="Ratio" value={fx((8 * N) / S)} />
        {!quiet && <Read label="Armored" value={`${arm.toLocaleString("en-US")} bits`} tone="trav" big />}
      </>}
    />
  );
}
