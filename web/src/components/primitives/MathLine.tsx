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
}

/** Renders MathText. Numbers are formatted in one place; answer boxes become buttons when `onSlot` is given. */
export function MathLine({ math, values = {}, active = null, onSlot, className = "" }: Props) {
  // a sub straight before a sup (the bounds of ∫₀²) stack in one column, lower bound under the upper
  const render = (m: MathText): ReactNode[] => m.flatMap((tok, i): ReactNode[] => {
    const next = m[i + 1], prev = m[i - 1];
    if (tok.t === "sup" && prev?.t === "sub") return [];
    if (tok.t === "sub" && next?.t === "sup") return [<span key={i} className="lims"><sup>{render(next.v)}</sup><sub>{render(tok.v)}</sub></span>];
    return [token(tok, i)];
  });
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
      {onSlot ? render(math) : <><span aria-hidden="true" className="mline-in">{render(math)}</span><span className="visually-hidden">{toPlainText(math, "blank")}</span></>}
    </span>
  );
}

/** Short message text: `**bold**` becomes bold, everything else stays as typed. */
export function Rich({ text }: { text: string }) {
  const parts = text.split(/\*\*(.+?)\*\*/g);
  return <>{parts.map((p, i) => (i % 2 ? <b key={i}>{p}</b> : p))}</>;
}
