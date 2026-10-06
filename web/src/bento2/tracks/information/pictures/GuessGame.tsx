// The Guess-the-message game (information.md, the track's main tool), in four modes:
// number: think of 1 to N; the game halves the range with "is it in the top half?" and tallies the questions (01).
// letter: guess the next letter of a hidden message; each letter's cost in bits under English letter odds (03).
// model: a model reads a message and shows its probability bars for the next letter, with the interval strip (08, 12).
// strip: the interval strip alone for a list of probabilities, zooming one letter at a time (08's Work it).
import { useMemo, useState, type ReactNode } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, Read, Scene, Slider, Toggle, useClock, useSvgDrag } from "../../../ui/kit";
import { contextModel, showSym, surprise } from "../maths";

const W = 360;
type Mode = "number" | "letter" | "model" | "strip";

export function GuessGameScene(props: SceneProps) {
  const first = str<Mode>(props.props, "mode", "number");
  const [mode, setMode] = useState<Mode>(first);
  const tool = props.place !== "lesson";
  const pick = tool && (
    <Toggle label="Game" value={mode} onChange={setMode} options={[{ v: "number", label: "Number" }, { v: "letter", label: "Letter" }, { v: "model", label: "Model" }]} />
  );
  if (mode === "letter") return <LetterGame {...props} pick={pick} />;
  if (mode === "model") return <ModelGame {...props} pick={pick} />;
  if (mode === "strip") return <StripGame {...props} />;
  return <NumberGame {...props} pick={pick} />;
}

/* ------------------------------------------------------------------ number ------------------------------------------------------------------ */

/** the questions for target t in 1..N: each one keeps [lo, hi] and says whether the answer was "yes, top half" */
function questions(N: number, t: number) {
  const out: { lo: number; hi: number; mid: number; yes: boolean }[] = [];
  let lo = 1, hi = N;
  while (lo < hi) {
    const mid = Math.floor((lo + hi) / 2), yes = t > mid;
    out.push({ lo, hi, mid, yes });
    if (yes) lo = mid + 1; else hi = mid;
  }
  return out;
}
/** the number that needs the most questions: always in the bigger half */
function worstOf(N: number) {
  let lo = 1, hi = N;
  while (lo < hi) { const mid = Math.floor((lo + hi) / 2); if (hi - mid > mid - lo + 1) lo = mid + 1; else hi = mid; }
  return lo;
}

function NumberGame({ props, marker, pick }: SceneProps & { pick: ReactNode }) {
  const [N, setN] = useState(Math.round(num(props, "N", 64)));
  const quiet = flag(props, "quiet"), worst = flag(props, "worst");
  const [t, setT] = useState(() => (worst ? worstOf(Math.round(num(props, "N", 64))) : Math.max(1, Math.round(num(props, "N", 64) * 0.37))));
  const target = Math.min(t, N);
  const qs = questions(N, target);
  const clock = useClock(!quiet, 99);
  const shown = quiet ? 0 : Math.min(qs.length, Math.floor(clock / 0.7));
  const { ref, drag } = useSvgDrag();
  const x0 = 14, x1 = W - 14, xOf = (k: number) => x0 + ((k - 1) / N) * (x1 - x0), wOf = (a: number, b: number) => ((b - a + 1) / N) * (x1 - x0);
  const rowY = (k: number) => 58 + k * 17;
  const bits = Math.log2(N), need = Math.ceil(bits);
  const setTarget = (x: number) => setT(Math.max(1, Math.min(N, Math.floor(((x - x0) / (x1 - x0)) * N) + 1)));
  const boxes = N <= 64;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} 270`} className="b2pic" role="img" aria-label={`A row of ${N} numbers. ${quiet ? "" : `The game has asked ${shown} of ${qs.length} questions.`}`}>
      <text x={x0} y="16" className="b2t">1</text>
      <text x={x1} y="16" textAnchor="end" className="b2t">{N.toLocaleString("en-US")}</text>
      {boxes
        ? Array.from({ length: N }, (_, i) => <rect key={i} x={xOf(i + 1) + 0.5} y="24" width={Math.max(1, wOf(1, 1) - 1)} height="22" rx="2" className="b2bar track" />)
        : <rect x={x0} y="24" width={x1 - x0} height="22" rx="4" className="b2bar track" />}
      {!quiet && <rect x={xOf(target)} y="22" width={Math.max(3, wOf(1, 1))} height="26" rx="2" className="b2bar amber" />}
      {!quiet && <rect x={x0} y="20" width={x1 - x0} height="30" className="b2hit" {...drag(x => setTarget(x))} />}
      {qs.slice(0, shown).map((q, k) => {
        const keep = q.yes ? [q.mid + 1, q.hi] : [q.lo, q.mid];
        return (
          <g key={k}>
            <rect x={xOf(q.lo)} y={rowY(k)} width={wOf(q.lo, q.hi)} height="11" rx="3" className="b2bar track" />
            <rect x={xOf(keep[0]!)} y={rowY(k)} width={Math.max(2, wOf(keep[0]!, keep[1]!))} height="11" rx="3" className="b2bar sky" />
            <line x1={xOf(q.mid + 1)} y1={rowY(k) - 3} x2={xOf(q.mid + 1)} y2={rowY(k) + 14} className="b2axis" />
          </g>
        );
      })}
      {marker && (() => { const k = Math.min(Math.round(marker[0]), 11), y = rowY(k - 1) + 14; return (
        <g><line x1={x0} y1={y} x2={x1} y2={y} className="b2mark guess" />
          <text x={x1} y={y - 3} textAnchor="end" className="b2t">your guess: {Math.round(marker[0])}{marker[0] > 11 ? ", further down" : ""}</text></g>); })()}
      {!quiet && shown === qs.length && <text x={xOf(target) + 4} y={rowY(qs.length) + 10} className="b2t amber">it's {target.toLocaleString("en-US")}</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {pick}
        <Slider label="N" value={Math.log2(N)} min={1} max={10} step={0.01} onChange={v => setN(Math.max(2, Math.round(2 ** v)))} format={() => N.toLocaleString("en-US")}
          marks={[{ v: 3, label: "8" }, { v: 6, label: "64" }, { v: Math.log2(100), label: "100" }, { v: Math.log2(1000), label: "1,000" }, { v: 10, label: "1,024" }]} />
        <button type="button" className="ctl" onClick={() => setT(worstOf(N))}>Hardest number</button>
      </>}
      readouts={quiet ? <Read label="N" value={N.toLocaleString("en-US")} /> : <>
        <Read label="Questions so far" value={shown} tone="sky" big />
        <Read label="log₂ N" value={`${fx(bits)} bits`} tone="amber" />
        <Read label="At most" value={`${need} ${need === 1 ? "question" : "questions"}`} />
        {qs[shown - 1] && <Read label={`Question ${shown}: top half?`} value={qs[shown - 1]!.yes ? "yes" : "no"} />}
      </>}
    />
  );
}

/* ------------------------------------------------------------------ letter ------------------------------------------------------------------ */

// English letter odds (with the space), for the cost of each letter: Lewand's frequencies, space at about 18%
const ENGLISH: Record<string, number> = {
  " ": 18.3, e: 10.2, t: 7.7, a: 6.8, o: 6.2, i: 5.7, n: 5.6, s: 5.3, h: 5.0, r: 4.9, d: 3.5, l: 3.3, c: 2.3, u: 2.3, m: 2.0, w: 1.9, f: 1.8, g: 1.6, y: 1.6,
  p: 1.6, b: 1.3, v: 0.8, k: 0.6, j: 0.1, x: 0.1, q: 0.1, z: 0.1,
};
const TOTAL = Object.values(ENGLISH).reduce((a, b) => a + b, 0);
const pEng = (c: string) => (ENGLISH[c] ?? 0.1) / TOTAL;
const KEYS = Object.keys(ENGLISH);
const HIDDEN = ["bits are answers", "the rain in spain", "a stitch in time", "less is more"];

function LetterGame({ props, pick }: SceneProps & { pick: ReactNode }) {
  const [which, setWhich] = useState(0);
  const msg = str<string>(props, "text", HIDDEN[which % HIDDEN.length]!);
  const [at, setAt] = useState(0);
  const [tries, setTries] = useState<string[]>([]);
  const [log, setLog] = useState<{ c: string; guesses: number }[]>([]);
  const done = at >= msg.length;
  const guess = (c: string) => {
    if (done || tries.includes(c)) return;
    if (c === msg[at]) { setLog(l => [...l, { c, guesses: tries.length + 1 }]); setTries([]); setAt(a => a + 1); }
    else setTries(t => [...t, c]);
  };
  const again = () => { setWhich(w => w + 1); setAt(0); setTries([]); setLog([]); };
  const bits = log.map(l => surprise(pEng(l.c)));
  const total = bits.reduce((a, b) => a + b, 0);
  const cell = Math.min(24, (W - 20) / msg.length);
  const svg = (
    <svg viewBox={`0 0 ${W} 200`} className="b2pic" role="img" aria-label={`A hidden message of ${msg.length} letters; ${at} found so far.`}>
      {[...msg].map((c, i) => {
        const x = 10 + i * cell, b = bits[i];
        return (
          <g key={i}>
            <rect x={x + 1} y="30" width={cell - 2} height="26" rx="4" className={`b2bar ${i < at ? "sky" : i === at ? "amber" : "track"}`} opacity={i < at ? 0.35 : 1} />
            {i < at && <text x={x + cell / 2} y="49" textAnchor="middle" className="b2t">{showSym(c)}</text>}
            {b != null && <rect x={x + 3} y={170 - b * 10} width={cell - 6} height={b * 10} rx="2" className="b2bar pink" />}
          </g>
        );
      })}
      <line x1="10" y1="170" x2={W - 10} y2="170" className="b2axis" />
      <text x="10" y="190" className="b2t pink">bits each letter cost</text>
      {tries.length > 0 && <text x="10" y="80" className="b2t">not: {tries.map(showSym).join(" ")}</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {pick}
        <span className="b2marks" role="group" aria-label="Guess the next letter">
          {KEYS.map(k => <button type="button" key={k} disabled={done || tries.includes(k)} onClick={() => guess(k)}>{k === " " ? "space" : k}</button>)}
        </span>
        <button type="button" className="ctl" onClick={again}>New message</button>
      </>}
      readouts={<>
        <Read label="Guesses on this letter" value={tries.length} />
        <Read label="Last letter cost" value={bits.length ? `${fx(bits[bits.length - 1]!)} bits` : "–"} tone="pink" />
        <Read label="Bits per letter so far" value={log.length ? fx(total / log.length) : "–"} tone="sky" big />
        <Read label="Flat, 27 symbols" value={`${fx(Math.log2(27))} bits`} />
      </>}
    />
  );
}

/* ------------------------------------------------------------------ model ------------------------------------------------------------------ */

const DEFAULT_TEXT = "the quick queen quit quietly";

function ModelGame({ props, pick }: SceneProps & { pick: ReactNode }) {
  const [text, setText] = useState(str<string>(props, "text", DEFAULT_TEXT));
  const [ctx, setCtx] = useState<"alone" | "after">(flag(props, "q98") || num(props, "at", -1) >= 0 ? "after" : "alone");
  const quiet = flag(props, "quiet"), q98 = flag(props, "q98") || quiet;
  const m = useMemo(() => contextModel(text || " "), [text]);
  const n = m.syms.length;
  const [at, setAt] = useState(Math.min(Math.max(0, num(props, "at", 1)), Math.max(0, n - 1)));
  const i = Math.min(at, n - 1);
  const prev = ctx === "after" && i > 0 ? m.syms[i - 1]! : null;
  let probs = m.next(prev);
  const truth = m.index(m.syms[i]!);
  // the guess's own model: after a q, an English model gives u 0.98
  const pinned = q98 && i === num(props, "at", -1);
  if (pinned) { const rest = 1 - probs[truth]!; probs = probs.map((p, j) => (j === truth ? 0.98 : rest > 0 ? (p / rest) * 0.02 : 0)); }
  const pTrue = probs[truth]!;
  const costs = m.costs(ctx === "after");
  if (pinned) costs[i] = surprise(0.98);
  const upto = costs.slice(0, i + 1).reduce((a, b) => a + b, 0);
  const allAlone = m.costs(false).reduce((a, b) => a + b, 0) / n, allAfter = m.costs(true).reduce((a, b) => a + b, 0) / n;
  const top = probs.map((p, j) => [p, j] as const).sort((a, b) => b[0] - a[0]).slice(0, 8);
  if (!top.some(x => x[1] === truth)) top[7] = [pTrue, truth];
  // the strip: [0, 1] cut by the model's probabilities, the true letter's slice lit and zoomed below
  let lo = 0;
  for (let j = 0; j < truth; j++) lo += probs[j]!;
  const sx = (v: number) => 14 + v * (W - 28);
  const svg = (
    <svg viewBox={`0 0 ${W} 270`} className="b2pic" role="img" aria-label={`After "${prev ?? "nothing"}", the model gives "${showSym(m.syms[i]!)}" a chance of ${fx(pTrue)}.`}>
      <text x="14" y="16" className="b2t">{[...text.slice(Math.max(0, i - 14), i)].join("")}<tspan className="b2t amber">{text[i] === " " ? "␣" : text[i]}</tspan></text>
      {top.map(([p, j], k) => {
        const x = 14 + k * 42, h = p * 110;
        return (
          <g key={j}>
            <rect x={x} y={140 - h} width="32" height={Math.max(1, h)} rx="3" className={`b2bar ${j === truth ? "amber" : "sky"}`} opacity={j === truth ? 1 : 0.55} />
            <text x={x + 16} y="158" textAnchor="middle" className={`b2t${j === truth ? " amber" : ""}`}>{showSym(m.sym[j]!)}</text>
          </g>
        );
      })}
      <line x1="10" y1="140" x2={W - 10} y2="140" className="b2axis" />
      {probs.map((p, j) => { let a = 0; for (let k = 0; k < j; k++) a += probs[k]!; return <rect key={j} x={sx(a)} y="180" width={Math.max(0.5, sx(a + p) - sx(a) - 0.5)} height="16" className={`b2bar ${j === truth ? "amber" : "track"}`} />; })}
      <text x="14" y="176" className="b2t">0</text>
      <text x={W - 14} y="176" textAnchor="end" className="b2t">1</text>
      <path d={`M${sx(lo)},198 L14,226 M${sx(lo + pTrue)},198 L${W - 14},226`} className="b2mark amber" />
      <rect x="14" y="226" width={W - 28} height="16" rx="3" className="b2bar amber" opacity="0.35" />
      <text x={W / 2} y="262" textAnchor="middle" className="b2t amber">{quiet ? "the slice for the next letter" : `width ${fx(pTrue, 3)}, so ${fx(costs[i]!)} bits`}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {pick}
        <Toggle label="Model" value={ctx} onChange={setCtx} options={[{ v: "alone", label: "Letters alone" }, { v: "after", label: "After the last letter" }]} />
        <Slider label="Letter" value={i} min={0} max={Math.max(0, n - 1)} step={1} onChange={setAt} format={v => `${v + 1} of ${n}`} />
        {props.place !== "lesson" && <label className="b2field wide"><span>Message</span>
          <input value={text} maxLength={120} aria-label="Message" onChange={e => { setText(e.currentTarget.value); setAt(0); }} /></label>}
      </>}
      readouts={quiet ? <Read label="After a q" value="u is next" /> : <>
        <Read label="p of what came" value={fx(pTrue, 3)} tone="amber" />
        <Read label="Its bits" value={fx(costs[i]!)} tone="amber" big />
        <Read label="Bits so far" value={fx(upto, 1)} />
        <Read label="Per letter, letters alone" value={fx(allAlone)} />
        <Read label="Per letter, after the last" value={fx(allAfter)} tone="sky" />
      </>}
    />
  );
}

/* ------------------------------------------------------------------ strip ------------------------------------------------------------------ */

function StripGame({ props }: SceneProps) {
  const ps = str<string>(props, "ps", "0.5,0.25,0.5,0.125").split(",").map(Number);
  const msg = str<string>(props, "msg", "ABAC");
  const [k, setK] = useState(ps.length);
  const sx = (v: number) => 20 + v * (W - 40);
  let width = 1;
  const rows = ps.slice(0, k).map((p, i) => {
    // each row is the previous slice blown up to the full strip; the letter's slice is p of it, placed by its letter
    const off = (["A", "B", "C", "D"].indexOf(msg[i] ?? "A") * (1 - p)) / 3;
    width *= p;
    return { p, off, w: width };
  });
  const bits = -Math.log2(width);
  const svg = (
    <svg viewBox={`0 0 ${W} 250`} className="b2pic" role="img" aria-label={`After ${k} letters the interval is ${fx(width, 5)} wide: ${fx(bits)} bits.`}>
      <rect x={sx(0)} y="10" width={sx(1) - sx(0)} height="14" rx="3" className="b2bar track" />
      <text x={sx(0)} y="38" className="b2t">0</text><text x={sx(1)} y="38" textAnchor="end" className="b2t">1</text>
      {rows.map((r, i) => {
        const y = 48 + i * 32;
        return (
          <g key={i}>
            <rect x={sx(0)} y={y} width={sx(1) - sx(0)} height="14" rx="3" className="b2bar track" />
            <rect x={sx(r.off)} y={y} width={Math.max(2, sx(r.off + r.p) - sx(r.off))} height="14" rx="3" className="b2bar amber" />
            <text x={sx(0) - 4} y={y + 12} textAnchor="end" className="b2t">{msg[i]}</text>
            <text x={sx(1)} y={y + 28} textAnchor="end" className="b2t sky">width {r.w >= 0.001 ? fx(r.w, 4) : r.w.toExponential(2)}</text>
          </g>
        );
      })}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Slider label="Letters coded" value={k} min={0} max={ps.length} step={1} onChange={setK} format={v => `${v} of ${ps.length}`} />}
      readouts={<>
        <Read label="Final width" value={width >= 0.001 ? fx(width, 4) : width.toExponential(2)} tone="sky" />
        <Read label="Its bits, log₂(1/width)" value={fx(bits)} tone="amber" big />
      </>}
    />
  );
}
