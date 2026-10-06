import { useEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { reduceMotion } from "../app/transition";
import type { Rng } from "../curriculum/generators/rng";
import { gradeOf, inkOf, tintStyle } from "../curriculum/grades";
import { frac, num, op, sup, text, type MathText } from "../curriculum/schemas/math-text";
import { MathLine } from "./primitives/MathLine";

/** A worked problem: each row is a move on the left and what it gives on the right. */
export interface SolveDemo { kind: string; grade: number; q: MathText; rows: { work: MathText; ans: MathText }[] }
/** A wrong answer, what went wrong, and the right one. */
export interface SlipDemo { kind: string; grade: number; q: MathText; wrong: MathText; why: string; detail: string; right: MathText }

const x = text("x");
const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : a);
const ones = (rng: Rng, lo = 1) => rng.int(lo, 9);

export const SOLVES: ((rng: Rng) => SolveDemo)[] = [
  rng => {
    const a = rng.int(2, 8) * 10 + ones(rng), t = rng.int(1, 4) * 10, o = ones(rng), b = t + o;
    return { kind: "multiply", grade: 5, q: [num(a), op("×"), num(b)], rows: [
      { work: [num(a), op("×"), num(t)], ans: [num(a * t)] },
      { work: [num(a), op("×"), num(o)], ans: [num(a * o)] },
      { work: [num(a * t), op("+"), num(a * o)], ans: [num(a * b)] },
    ] };
  },
  rng => {
    const a = rng.int(2, 9), v = rng.int(2, 12), b = rng.int(2, 20), c = a * v + b;
    return { kind: "equation", grade: 7, q: [num(a), x, op("+"), num(b), op("="), num(c)], rows: [
      { work: [text(`Take ${b} from both sides`)], ans: [num(a), x, op("="), num(c - b)] },
      { work: [text(`Divide both sides by ${a}`)], ans: [x, op("="), num(v)] },
      { work: [text("Check "), num(a), op("×"), num(v), op("+"), num(b)], ans: [num(c), text(" ✓")] },
    ] };
  },
  rng => {
    const [d1, d2] = rng.pick([[2, 3], [3, 4], [2, 5], [4, 5], [3, 5], [4, 6], [3, 8], [6, 8]] as const);
    const n1 = rng.int(1, d1 - 1), n2 = rng.int(1, d2 - 1), L = d1 * d2 / gcd(d1, d2), s = n1 * L / d1 + n2 * L / d2, g = gcd(s, L);
    const rows: SolveDemo["rows"] = [
      { work: [text("Make the bottoms match")], ans: [frac(n1 * L / d1, L), op("+"), frac(n2 * L / d2, L)] },
      { work: [text("Add the tops")], ans: [frac(s, L)] },
    ];
    if (g > 1) rows.push({ work: [text(`Divide top and bottom by ${g}`)], ans: [frac(s / g, L / g)] });
    return { kind: "fractions", grade: 5, q: [frac(n1, d1), op("+"), frac(n2, d2)], rows };
  },
  rng => {
    const k = rng.int(2, 6), m = rng.int(1, 9), j = rng.int(2, 7);
    return { kind: "distribute", grade: 8, q: [num(k), text("("), x, op("+"), num(m), text(")"), op("+"), num(j), x], rows: [
      { work: [text(`Share the ${k}`)], ans: [num(k), x, op("+"), num(k * m), op("+"), num(j), x] },
      { work: [text("Put the x's together")], ans: [num(k + j), x, op("+"), num(k * m)] },
    ] };
  },
  rng => {
    const [a, b, c] = rng.pick([[3, 4, 5], [6, 8, 10], [5, 12, 13], [8, 15, 17], [9, 12, 15]] as const);
    return { kind: "pythagoras", grade: 8, q: [text(`Legs ${a} and ${b}`)], rows: [
      { work: [num(a), sup(2), op("+"), num(b), sup(2)], ans: [num(a * a), op("+"), num(b * b)] },
      { work: [text("Add")], ans: [text("c"), sup(2), op("="), num(c * c)] },
      { work: [text(`Which number times itself is ${c * c}?`)], ans: [text("c"), op("="), num(c)] },
    ] };
  },
  rng => {
    const p = rng.int(2, 5), q = rng.int(2, 5);
    return { kind: "powers", grade: 8, q: [x, sup(p), op("·"), x, sup(q)], rows: [
      { work: [text("Same base, so add the powers")], ans: [x, sup([num(p), op("+"), num(q)])] },
      { work: [text("That's")], ans: [x, sup(p + q)] },
      { work: [text("Try x = 2")], ans: [num(2), sup(p + q), op("="), num(2 ** (p + q))] },
    ] };
  },
];

export const SLIPS: ((rng: Rng) => SlipDemo)[] = [
  rng => {
    const d = rng.int(3, 9), o = rng.int(Math.ceil(10 / d), 9), t = rng.int(2, 8) * 10, a = t + o;
    const wrong = t * d + (o * d) % 10;
    return { kind: "carry", grade: 4, q: [num(a), op("×"), num(d)], wrong: [num(wrong)], right: [num(a * d)], why: "You dropped a carry.",
      detail: `${o} × ${d} is ${o * d}, so the ${Math.floor(o * d / 10)} carries over. ${t} × ${d} = ${t * d}, plus ${o * d} makes ${a * d}.` };
  },
  rng => {
    const [d1, d2] = rng.pick([[2, 3], [3, 4], [2, 5], [4, 5], [3, 5]] as const);
    const n1 = rng.int(1, d1 - 1), n2 = rng.int(1, d2 - 1), L = d1 * d2, s = n1 * d2 + n2 * d1, g = gcd(s, L);
    return { kind: "fractions", grade: 5, q: [frac(n1, d1), op("+"), frac(n2, d2)], wrong: [frac(n1 + n2, d1 + d2)], right: [frac(s / g, L / g)],
      why: "You added the bottoms.", detail: `Only the tops add. Make the bottoms match first: ${n1 * d2}/${L} + ${n2 * d1}/${L} = ${s}/${L}${g > 1 ? `, which is ${s / g}/${L / g}` : ""}.` };
  },
  rng => {
    const a = rng.int(2, 9), b = rng.int(2, 9), c = rng.int(2, 9);
    return { kind: "order", grade: 6, q: [num(a), op("+"), num(b), op("×"), num(c)], wrong: [num((a + b) * c)], right: [num(a + b * c)],
      why: "Multiply before you add.", detail: `${b} × ${c} = ${b * c}, then ${a} + ${b * c} = ${a + b * c}.` };
  },
  rng => {
    const a = rng.int(2, 9), b = rng.int(2, 9);
    return { kind: "negatives", grade: 7, q: [num(-a), op("×"), num(-b)], wrong: [num(-a * b)], right: [num(a * b)],
      why: "Two negatives make a positive.", detail: `${a} × ${b} = ${a * b}, and a negative times a negative is positive, so it's ${a * b}.` };
  },
  rng => {
    const b = rng.int(2, 12), c = rng.int(b + 1, 20);
    return { kind: "undo", grade: 6, q: [x, op("−"), num(b), op("="), num(c)], wrong: [x, op("="), num(c - b)], right: [x, op("="), num(c + b)],
      why: "Undo a minus with a plus.", detail: `To undo taking away ${b}, add ${b} to both sides: x = ${c} + ${b} = ${c + b}.` };
  },
  rng => {
    const a = rng.int(3, 12);
    return { kind: "square", grade: 6, q: [num(a), sup(2)], wrong: [num(2 * a)], right: [num(a * a)],
      why: "Squaring isn't doubling.", detail: `${a}² means ${a} × ${a}, which is ${a * a}.` };
  },
];

/**
 * Steps a demo through its beats while it's on screen, then moves on to a fresh one of a different kind. The first
 * demo opens finished, so the tile reads complete on its first frame (Review v43 #20); later ones start at beat
 * `from`. `rest` is true while that opening picture is showing, so nothing in it plays an entrance.
 */
function useDemo<T extends { kind: string }>(make: ((rng: Rng) => T)[], rng: Rng, beats: (d: T) => number, from = 0) {
  const order = useMemo(() => rng.shuffle(make.map((_, i) => i)), [make, rng]);
  const [n, setN] = useState(0);
  const demo = useMemo(() => make[order[n % order.length]!]!(rng), [n, make, order, rng]);
  const last = beats(demo), still = reduceMotion();
  const [at, setAt] = useState(Infinity);
  const [seen, setSeen] = useState(false);
  const box = useRef<HTMLElement>(null);
  useEffect(() => {
    if (still || !box.current || typeof IntersectionObserver === "undefined") { setSeen(true); return; }
    const io = new IntersectionObserver(es => setSeen(es.some(e => e.isIntersecting)), { threshold: 0.4 });
    io.observe(box.current);
    return () => io.disconnect();
  }, [still]);
  useEffect(() => {
    if (still || !seen) return;
    const t = setTimeout(() => (at >= last ? (setN(k => k + 1), setAt(from)) : setAt(a => a + 1)), at >= last ? 4200 : at === 0 ? 700 : 1000);
    return () => clearTimeout(t);
  }, [at, from, last, seen, still]);
  const another = () => { setN(k => k + 1); setAt(still ? Infinity : from); };
  return { demo, at: Math.min(at, last), box, another, key: n, rest: n === 0 };
}

function Chip({ grade }: { grade: number }) {
  const g = gradeOf(grade);
  return <span className="lchip" style={tintStyle(g) as CSSProperties}>{g.name.split(" · ")[0]}</span>;
}

interface DemoTileProps { tint: string; k: number; rng: Rng }

/** A wide feature-box tile around a demo: the demo on top, the feature's name and line underneath. */
function DemoTile({ box, tint, k, title, label, another, children }: DemoTileProps & { box: React.Ref<HTMLElement>; title: string; label: string; another: () => void; children: React.ReactNode }) {
  return (
    <article ref={box} className="ltile wide ldemo" onClick={another} aria-live="polite" style={{ "--tint": tint, "--ink": inkOf(tint), "--i": k } as CSSProperties}>
      <div className="lvis">{children}<span className="lnew">Tap for another</span></div>
      <div className="ltext"><h3>{title}</h3><p>{label}</p></div>
    </article>
  );
}

/** "One step at a time": a random worked problem whose named steps fill in one by one. */
export function SolveTile({ tint, k, rng }: DemoTileProps) {
  const { demo, at, box, another, key, rest } = useDemo(SOLVES, rng, d => d.rows.length);
  return (
    <DemoTile box={box} tint={tint} k={k} rng={rng} another={another} title="One step at a time" label="Every problem splits into named steps, checked as you go.">
      <div className={`lsteps${rest ? " rest" : ""}`} key={key} style={tintStyle(gradeOf(demo.grade)) as CSSProperties}>
        <div className="q a-rise"><MathLine math={demo.q} /><Chip grade={demo.grade} /></div>
        {demo.rows.map((r, i) => (
          <div key={i} className={`${i === demo.rows.length - 1 ? "sum " : ""}${i < at ? "on" : "off"}`}>
            <span><MathLine math={r.work} /></span><b><MathLine math={r.ans} /></b>
          </div>
        ))}
      </div>
    </DemoTile>
  );
}

/** "Slips, explained": a random wrong answer, then exactly what went wrong and the fix. */
export function SlipTile({ tint, k, rng }: DemoTileProps) {
  // a fresh slip arrives with its wrong answer showing; the why and the fix wait faintly underneath, then light up
  const { demo, at, box, another, key, rest } = useDemo(SLIPS, rng, () => 3, 1);
  return (
    <DemoTile box={box} tint={tint} k={k} rng={rng} another={another} title="Slips, explained" label="Get it wrong and Bento tells you exactly where, and why.">
      <div className={`lmiss${rest ? " rest" : ""}`} key={key}>
        <div className="q a-rise"><MathLine math={demo.q} /><Chip grade={demo.grade} /></div>
        <div className={`bad ${at >= 1 ? "on" : "off"}${at >= 2 ? " shook" : ""}`}><span>Your answer</span><b><MathLine math={demo.wrong} /></b></div>
        <p className={at >= 2 ? "on" : "off"}><b>{demo.why}</b> {demo.detail}</p>
        <div className={`good ${at >= 3 ? "on" : "off"}`}><span>Fixed</span><b><MathLine math={demo.right} /></b></div>
      </div>
    </DemoTile>
  );
}
