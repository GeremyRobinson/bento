import { Fragment, useLayoutEffect, useRef, type ReactNode } from "react";
import type { Tone } from "./statement";
import { formatNumber, slotsIn, toPlainText, type MathText, type MathToken } from "../../curriculum/schemas/math-text";
import { layoutRect } from "../../app/transition";

interface Props {
  math: MathText;
  /** typed text per answer box */
  values?: Record<string, string>;
  /** the box the keypad types into */
  active?: string | null;
  onSlot?: (id: string) => void;
  className?: string;
  /** a title that may wrap: keep each group together (brackets, an operator and what follows it) and break only
   *  between sides of "=" first, then between terms or words */
  keep?: boolean;
}

/** the smallest a line may shrink to fit its card; past this it is still readable, and wrapping lines wrap instead */
const MIN_FIT = 0.5;

/** The narrowest box around the line: no ancestor's content box may be overflowed. */
function room(el: HTMLElement): number {
  let w = Infinity;
  for (let a = el.parentElement; a && a !== document.body; a = a.parentElement) {
    const cs = getComputedStyle(a);
    if (cs.display === "contents") continue;
    w = Math.min(w, a.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight));
  }
  return w;
}

/**
 * Every equation fits its card (G 2026-10-06: a 12th grade polynomial ran past both edges). A line wider than the box
 * around it is zoomed down, as a whole, until it fits; it never runs off the card or makes the page scroll sideways.
 */
function useFit(math: unknown) {
  const ref = useRef<HTMLSpanElement>(null);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el || typeof ResizeObserver === "undefined") return;
    let busy = false;
    const fit = () => {
      if (busy) return;
      busy = true;
      el.style.zoom = "";
      const need = Math.max(el.scrollWidth, layoutRect(el).width), have = room(el);
      if (need > have + 0.5 && have > 0) el.style.zoom = String(Math.max(MIN_FIT, Math.floor((have / need) * 1000) / 1000));
      requestAnimationFrame(() => { busy = false; });
    };
    fit();
    const ro = new ResizeObserver(fit);
    if (el.parentElement) ro.observe(el.parentElement);
    return () => ro.disconnect();
  }, [math]);
  return ref;
}

const REL = new Set(["=", "<", ">", "≤", "≥", "≈"]);
const SUM = new Set(["+", "−", "±"]);
const PRODUCT = new Set(["×", "÷", "·"]);
/** a "?" that stands for a number: not straight after a letter or a closing bracket, where it ends a question */
const UNKNOWN = /(?<![\p{L})\]])\?/u;
const UNKNOWN_SPLIT = /(?<![\p{L})\]])(\?)/u;
const ENDS_OP = /[+−×÷=<>≤≥≈±·(]$/;
/** how strongly a line may break before an operator: relations first, then sums, then products */
const opLevel = (o: string) => (REL.has(o) ? 3 : SUM.has(o) ? 2 : PRODUCT.has(o) ? 1 : 0);

/**
 * Where a line may wrap: before each piece, 4 = a line break, 3 = before a relation, 2 = before + or −,
 * 1 = before × or ÷ or between words, 0 = never (inside brackets, right after an operator, before "(").
 */
export function breakLevels(m: MathText): { tok: MathToken; lvl: number }[] {
  const out: { tok: MathToken; lvl: number }[] = [];
  let depth = 0, afterOp = true, afterSpace = false;
  for (const tok of m) {
    if (tok.t === "br") { out.push({ tok, lvl: 4 }); afterOp = true; afterSpace = false; continue; }
    if (tok.t === "op") {
      out.push({ tok, lvl: depth === 0 && !afterOp ? opLevel(tok.v) : 0 });
      afterOp = true; afterSpace = false; continue;
    }
    if (tok.t !== "text") {
      out.push({ tok, lvl: depth === 0 && !afterOp && afterSpace ? 1 : 0 });
      afterOp = false; afterSpace = false; continue;
    }
    // text: a break may fall at a space outside brackets
    for (const seg of tok.v.split(/(?<=\s)(?=\S)/)) {
      const word = seg.trim(), lead = /^\s/.test(seg) || afterSpace;
      const lvl = !word || depth > 0 || afterOp || !lead || word.startsWith("(") || /^[),.;:?!]/.test(word) ? 0 : Math.max(1, opLevel(word[0]!));
      out.push({ tok: { t: "text", v: seg }, lvl });
      for (const c of seg) depth = c === "(" ? depth + 1 : c === ")" ? Math.max(0, depth - 1) : depth;
      if (word) afterOp = ENDS_OP.test(word);
      afterSpace = /\s$/.test(seg);
    }
  }
  return out;
}

/** Renders MathText. Numbers are formatted in one place; answer boxes become buttons when `onSlot` is given. */
export function MathLine({ math, values = {}, active = null, onSlot, className = "", keep = false }: Props) {
  const fitRef = useFit(math);
  // a written space next to an operator would double the operator's own spacing ("area  = ?")
  const tidy = (m: MathText): MathText => m.map((tok, i) => {
    if (tok.t !== "text") return tok;
    let v = tok.v;
    if (m[i + 1]?.t === "op") v = v.trimEnd();
    if (m[i - 1]?.t === "op") v = v.trimStart();
    return v === tok.v || !v ? tok : { t: "text", v };
  });
  // a sub straight before a sup (the bounds of ∫₀²) stack in one column, lower bound under the upper
  const render = (raw: MathText): ReactNode[] => { const m = tidy(raw); return m.flatMap((tok, i): ReactNode[] => {
    const next = m[i + 1], prev = m[i - 1];
    if (tok.t === "sup" && prev?.t === "sub") return [];
    if (tok.t === "sub" && next?.t === "sup") return [<span key={i} className="lims"><sup>{render(next.v)}</sup><sub>{render(tok.v)}</sub></span>];
    return [token(tok, i)];
  }); };
  // keep: each side of a relation wraps as a whole; only a side too wide for the line wraps, at its + and −, then × and ÷
  const grouped = (m: MathText): ReactNode[] => {
    type Piece = { tok: MathToken; lvl: number };
    const split = (ps: Piece[], lvl: number) =>
      ps.reduce<Piece[][]>((out, p) => { if (!out.length || p.lvl >= lvl) out.push([]); out[out.length - 1]!.push(p); return out; }, []);
    const nest = (ps: Piece[], lvl: number, key: string): ReactNode => {
      if (lvl === 0) return <span key={key} className="mk w">{ps.map((p, i) => token(p.tok, i))}</span>;
      const parts = split(ps, lvl);
      return parts.length === 1 ? nest(ps, lvl - 1, key) : <span key={key} className="mk">{parts.map((c, i) => nest(c, lvl - 1, `${key}.${i}`))}</span>;
    };
    return split(breakLevels(tidy(m)), 4).flatMap((line, i) => {
      const ps = line[0]?.tok.t === "br" ? line.slice(1) : line;
      return [...(i ? [<span key={`br${i}`} className="br" />] : []), ...(ps.length ? [nest(ps, 3, String(i))] : [])];
    });
  };
  const token = (tok: MathToken, i: number): ReactNode => {
    switch (tok.t) {
      case "text": {
        const cls = tok.v === "(" ? "t lp" : tok.v === ")" ? "t rp" : "t";
        // the unknown: a "?" standing for a number (not a question's own mark, "How many dots?") is a dashed box
        if (!UNKNOWN.test(tok.v)) return <span key={i} className={cls}>{tok.v}</span>;
        return <span key={i} className={cls}>{tok.v.split(UNKNOWN_SPLIT).map((p, k) => (k % 2 ? <span key={k} className="unk">?</span> : p))}</span>;
      }
      case "num": return <span key={i} className="n">{formatNumber(tok.v)}</span>;
      case "op": return <span key={i} className="o">{tok.v}</span>;
      case "answer": return <b key={i} className="ans">{formatNumber(tok.v)}</b>;
      case "frac": {
        const boxes = slotsIn(tok.n).length + slotsIn(tok.d).length > 0;
        return <span key={i} className={`fr${boxes ? " slots" : ""}`}><span>{render(tok.n)}</span><span>{render(tok.d)}</span></span>;
      }
      case "sup": return <sup key={i}>{render(tok.v)}</sup>;
      case "sub": return <sub key={i}>{render(tok.v)}</sub>;
      case "sqrt": return <span key={i} className="sqrt">√<span className="rad">{render(tok.v)}</span></span>;
      case "mark": return <mark key={i}>{render(tok.v)}</mark>;
      case "muted": return <span key={i} className="muted">{render(tok.v)}</span>;
      case "bold": return <b key={i}>{render(tok.v)}</b>;
      case "part": return <span key={i} className={`pt p${tok.k}`}>{render(tok.v)}</span>;
      case "br": return <span key={i} className="br" />;
      case "slot": {
        const v = values[tok.id] ?? "", on = active === tok.id, cls = `slot${tok.small ? " small" : ""}${on ? " active" : ""}${v ? "" : " empty"}`;
        return onSlot ? (
          <button key={i} type="button" className={cls} aria-pressed={on} data-slot={tok.id}
            aria-label={`Answer box${v ? `, ${v}` : ", empty"}`} onClick={() => onSlot(tok.id)}>
            {v}{on && <span className="caret" aria-hidden="true" />}
          </button>
        ) : <span key={i} className={cls}>{v}</span>;
      }
    }
  };
  return (
    // interactive lines keep their boxes reachable; read-only lines are read out as plain text
    <span ref={fitRef} className={`mline ${className}`.trim()} data-plain={toPlainText(math, "blank")}>
      {onSlot ? render(math) : <><span aria-hidden="true" className="mline-in">{keep ? grouped(math) : render(math)}</span><span className="visually-hidden">{toPlainText(math, "blank")}</span></>}
    </span>
  );
}

/** Short message text: `**bold**` becomes bold, everything else stays as typed. With `tones`, each part's number
 *  ("16", "1/2") wears that part's colour, as it does in the statement and the picture. */
export function Rich({ text, tones }: { text: string; tones?: Tone[] }) {
  const parts = text.split(/\*\*(.+?)\*\*/g);
  const tone = (s: string): ReactNode => {
    if (!tones?.length) return s;
    const esc = (x: string) => x.replace(/[.*+?^${}()|[\]\\/]/g, "\\$&");
    // the whole number only: not the 6 in 16 or 6.5, not the 3 in −3 or 3/4
    const re = new RegExp(`(?<![\\d.,/−-]|\\d[.,])(${tones.map(t => esc(t.s)).join("|")})(?!\\d|[.,/]\\d)`, "g");
    return s.split(re).map((p, k) => {
      const hit = k % 2 ? tones.find(t => t.s === p) : undefined;
      return hit ? <span key={k} className={`tone p${hit.k}`}>{p}</span> : p;
    });
  };
  return <>{parts.map((p, i) => (i % 2 ? <b key={i}>{tone(p)}</b> : <Fragment key={i}>{tone(p)}</Fragment>))}</>;
}
