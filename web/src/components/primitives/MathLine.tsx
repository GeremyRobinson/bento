import type { ReactNode } from "react";
import { formatNumber, slotsIn, toPlainText, type MathText, type MathToken } from "../../curriculum/schemas/math-text";

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

const REL = new Set(["=", "<", ">", "≤", "≥", "≈"]);
const SUM = new Set(["+", "−", "±"]);
const PRODUCT = new Set(["×", "÷", "·"]);
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
  // a written space next to an operator would double the operator's own spacing ("area  = ?")
  const tidy = (m: MathText): MathText => m.map((tok, i) => {
    if (tok.t !== "text") return tok;
    let v = tok.v;
    if (m[i + 1]?.t === "op") v = v.trimEnd();
    if (m[i - 1]?.t === "op") v = v.trimStart();
    return v === tok.v || !v ? tok : { t: "text", v };
  });
  const render = (m: MathText): ReactNode[] => tidy(m).map((tok, i) => token(tok, i));
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
      case "text": return <span key={i} className={tok.v === "(" ? "t lp" : tok.v === ")" ? "t rp" : "t"}>{tok.v}</span>;
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
      case "br": return <span key={i} className="br" />;
      case "slot": {
        const v = values[tok.id] ?? "", on = active === tok.id, cls = `slot${tok.small ? " small" : ""}${on ? " active" : ""}`;
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
    <span className={`mline ${className}`.trim()} data-plain={toPlainText(math, "blank")}>
      {onSlot ? render(math) : <><span aria-hidden="true" className="mline-in">{keep ? grouped(math) : render(math)}</span><span className="visually-hidden">{toPlainText(math, "blank")}</span></>}
    </span>
  );
}

/** Short message text: `**bold**` becomes bold, everything else stays as typed. */
export function Rich({ text }: { text: string }) {
  const parts = text.split(/\*\*(.+?)\*\*/g);
  return <>{parts.map((p, i) => (i % 2 ? <b key={i}>{p}</b> : p))}</>;
}
