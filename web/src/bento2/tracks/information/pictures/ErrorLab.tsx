// The Error-fix lab (information.md), in two modes:
// hamming: a 7-cell Hamming (7, 4) word, in a row and inside three parity circles. Tap any cell to flip it: the circles
//   holding an odd number of 1s light up, and the syndrome (lit circles 4, 2, 1 read as binary) points at the cell (11).
// repeat: a 4-bit message sent three times through a channel that flips each bit with chance f; majority vote decodes,
//   and the live failure rate settles on 3f²(1 − f) + f³ (11).
import { useMemo, useState, type ReactNode } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider, Toggle, useClock } from "../../../ui/kit";
import { capacity, hammingEncode, oddCircles, repetitionFail, seeded, syndrome } from "../maths";

const W = 360;
// each cell's place in the circles: circle 1 (top left), 2 (top right), 4 (bottom)
const SPOT: Record<number, [number, number]> = { 1: [62, 70], 2: [158, 70], 3: [110, 66], 4: [110, 168], 5: [80, 122], 6: [140, 122], 7: [110, 106] };
const CIRCLE: Record<number, [number, number]> = { 1: [86, 86], 2: [134, 86], 4: [110, 130] };
const TONE: Record<number, string> = { 1: "sky", 2: "pink", 4: "amber" };

export function ErrorLabScene({ props, place }: SceneProps) {
  const [mode, setMode] = useState<"hamming" | "repeat">(str<string>(props, "mode", "hamming") === "repeat" ? "repeat" : "hamming");
  const pick = place !== "lesson" && <Toggle label="Lab" value={mode} onChange={setMode} options={[{ v: "hamming", label: "Hamming" }, { v: "repeat", label: "Repetition" }]} />;
  return mode === "repeat" ? <Repeat props={props} pick={pick} /> : <Hamming props={props} pick={pick} />;
}

function Hamming({ props, pick }: { props: SceneProps["props"]; pick: ReactNode }) {
  const start = () => {
    const given = str<string>(props, "word", "");
    if (given) return [...given].map(Number);
    const w = hammingEncode([1, 0, 1, 1]);
    const f = num(props, "flip", 0);
    if (f) w[f - 1] = 1 - w[f - 1]!;
    return w;
  };
  const [w, setW] = useState(start);
  const [roll, setRoll] = useState(1);
  const quiet = flag(props, "quiet");
  const s = syndrome(w), lit = oddCircles(w);
  const flip = (pos: number) => setW(v => v.map((b, i) => (i === pos - 1 ? 1 - b : b)));
  const fresh = () => { const r = seeded(roll * 101); setRoll(x => x + 1); setW(hammingEncode([0, 1, 2, 3].map(() => (r() < 0.5 ? 1 : 0)))); };
  const svg = (
    <svg viewBox={`0 0 ${W} 262`} className="b2pic" role="img" aria-label={`The word ${w.join("")}. ${quiet ? "" : s ? `The syndrome is ${s}: cell ${s} is flipped.` : "The syndrome is 0: no error."}`}>
      {[1, 2, 4].map(c => {
        const on = !quiet && lit.includes(c);
        return (
          <g key={c} className={TONE[c]}>
            <circle cx={CIRCLE[c]![0]} cy={CIRCLE[c]![1]} r="62" className="b2bar" opacity={on ? 0.3 : 0.07} />
            <circle cx={CIRCLE[c]![0]} cy={CIRCLE[c]![1]} r="62" className={on ? "b2leg" : "b2ring"} fill="none" />
            <text x={c === 1 ? 40 : c === 2 ? 180 : 110} y={c === 4 ? 212 : 16} textAnchor="middle" className="b2t">check {c}</text>
          </g>
        );
      })}
      {w.map((b, i) => {
        const pos = i + 1, [x, y] = SPOT[pos]!, parity = pos === 1 || pos === 2 || pos === 4;
        return (
          <g key={pos} onClick={() => flip(pos)} style={{ cursor: "pointer" }}>
            <rect x={x - 15} y={y - 15} width="30" height="30" rx={parity ? 15 : 6} className={`b2bar ${b ? "trav" : "track"}`} />
            <text x={x} y={y + 5} textAnchor="middle" className="b2t">{b}</text>
            <rect x={x - 18} y={y - 18} width="36" height="36" className="b2hit" style={{ cursor: "pointer" }} />
          </g>
        );
      })}
      {w.map((b, i) => {
        const pos = i + 1, x = 220 + i * 19, parity = pos === 1 || pos === 2 || pos === 4;
        return (
          <g key={`r${pos}`} onClick={() => flip(pos)} style={{ cursor: "pointer" }}>
            <rect x={x} y="226" width="17" height="22" rx={parity ? 8 : 3} className={`b2bar ${b ? "trav" : "track"}`} />
            <text x={x + 8.5} y="220" textAnchor="middle" className="b2t">{pos}</text>
            {!quiet && s === pos && <rect x={x - 2} y="224" width="21" height="26" rx="4" className="b2mark amber" />}
          </g>
        );
      })}
      {!quiet && <text x="220" y="196" className="b2t amber">syndrome {s.toString(2).padStart(3, "0")} = {s}</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {pick}
        {!quiet && <button type="button" className="ctl go" disabled={!s} onClick={() => flip(s)}>Fix cell {s || "–"}</button>}
        {!quiet && <button type="button" className="ctl" onClick={fresh}>New word</button>}
      </>}
      readouts={<>
        <Read label="Word" value={w.join("")} />
        {!quiet && <Read label="Circles lit" value={lit.length ? lit.join(", ") : "none"} tone="amber" />}
        {!quiet && <Read label="Syndrome" value={s ? `cell ${s}` : "0, no error"} tone="amber" big />}
        <Read label="Data cells 3, 5, 6, 7" value={[w[2], w[4], w[5], w[6]].join("")} tone="trav" />
      </>}
    />
  );
}

function Repeat({ props, pick }: { props: SceneProps["props"]; pick: ReactNode }) {
  const given = str<string>(props, "copies", "");
  const [f, setF] = useState(0.1);
  const msg = [1, 0, 1, 1];
  const t = Math.max(0, useClock(!given, 30));
  const sends = given ? 1 : Math.max(1, Math.floor(t * 4));
  // every send flips each bit of each copy with chance f, from a stream that restarts when f changes
  const runs = useMemo(() => {
    const r = seeded(Math.round(f * 1000) + 3);
    return Array.from({ length: 400 }, () => [0, 1, 2].map(() => msg.map(b => (r() < f ? 1 - b : b))));
  }, [f]); // eslint-disable-line react-hooks/exhaustive-deps
  const copies = given ? given.split(",").map(c => [...c].map(Number)) : runs[(sends - 1) % 400]!;
  const maj = [0, 1, 2, 3].map(k => (copies.filter(c => c[k] === 1).length >= 2 ? 1 : 0));
  const upto = runs.slice(0, Math.min(400, sends));
  const bad = upto.reduce((a, c) => a + [0, 1, 2, 3].filter(k => (c.filter(x => x[k] === 1).length >= 2 ? 1 : 0) !== msg[k]).length, 0);
  const rate = bad / (4 * upto.length);
  const svg = (
    <svg viewBox={`0 0 ${W} 230`} className="b2pic" role="img" aria-label={`Three copies of a 4-bit message; the majority reads ${maj.join("")}.`}>
      {copies.map((c, r) => c.map((b, k) => {
        const flipped = !given && b !== msg[k];
        return (
          <g key={`${r}-${k}`}>
            <rect x={110 + k * 40} y={20 + r * 40} width="32" height="32" rx="6" className={`b2bar ${b ? "trav" : "track"}`} />
            {flipped && <rect x={108 + k * 40} y={18 + r * 40} width="36" height="36" rx="8" className="b2mark pink" />}
            <text x={126 + k * 40} y={41 + r * 40} textAnchor="middle" className="b2t">{b}</text>
          </g>
        );
      }))}
      {[0, 1, 2].map(r => <text key={r} x="100" y={41 + r * 40} textAnchor="end" className="b2t">copy {r + 1}</text>)}
      <line x1="106" y1="142" x2="270" y2="142" className="b2axis" />
      {maj.map((b, k) => (
        <g key={k}>
          <rect x={110 + k * 40} y="152" width="32" height="32" rx="6" className={`b2bar ${b ? "amber" : "track"}`} />
          <text x={126 + k * 40} y="173" textAnchor="middle" className="b2t">{b}</text>
        </g>
      ))}
      <text x="100" y="173" textAnchor="end" className="b2t amber">majority</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>{pick}{!given && <Slider label="Noise f" value={f} min={0} max={0.5} step={0.01} onChange={setF} format={x => fx(x)} marks={[{ v: 0.1, label: "0.1" }, { v: 0.2, label: "0.2" }, { v: 0.25, label: "1/4" }]} />}</>}
      readouts={given ? <Read label="Decoded" value={maj.join("")} tone="amber" big /> : <>
        <Read label="Sends" value={upto.length} />
        <Read label="Bits wrong after the vote" value={fx(rate, 3)} tone="pink" />
        <Read label="Predicted, 3f²(1 − f) + f³" value={fx(repetitionFail(f), 3)} tone="amber" big />
        <Read label="Capacity, 1 − H(f)" value={`${fx(capacity(f), 3)} bits per bit`} />
        <Read label="Rates" value="repetition 1/3, Hamming 4/7" />
      </>}
    />
  );
}
