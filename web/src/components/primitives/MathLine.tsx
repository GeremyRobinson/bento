import { Fragment, useLayoutEffect, useRef, type ReactNode, type RefObject } from "react";
import type { Tone } from "./statement";
import { formatNumber, slotsIn, toPlainText, type MathText, type MathToken } from "../../curriculum/schemas/math-text";
import { layoutRect, reduceMotion } from "../../app/transition";

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
/** a line with answer boxes stays on one line while it still reads at this size or more; past it, it wraps by sides */
const ONE_LINE = 0.35;

function useFit(math: unknown, oneLine = false) {
  const ref = useRef<HTMLSpanElement>(null);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el || typeof ResizeObserver === "undefined") return;
    let busy = false;
    const fit = () => {
      if (busy) return;
      busy = true;
      el.style.zoom = "";
      if (oneLine) {
        // try it on one line first (G 2026-10-08: "× 10" fell away from its box); a little smaller beats a broken line
        el.classList.add("one");
        el.style.maxWidth = "none"; el.style.width = "max-content";
        const one = Math.max(el.scrollWidth, layoutRect(el).width), room1 = room(el);
        el.style.maxWidth = ""; el.style.width = "";
        if (room1 > 0 && room1 / one >= ONE_LINE) {
          if (one > room1 + 0.5) el.style.zoom = String(Math.floor((room1 / one) * 1000) / 1000);
          requestAnimationFrame(() => { busy = false; });
          return;
        }
        el.classList.remove("one");
      }
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

/** the pictures an answer in the problem line waits for: the picture beside it on the same stage */
const PICTURES = ".viz-svg, .am";
/** the stage that holds the problem line and its picture together (Watch one, practice, the skill check) */
const STAGE = ".v-stage";

/**
 * The answer beat (Review g5 #6): the answer lands in the problem line only once the picture has shown why. When an
 * answer token first appears, every part of the picture still entering (the last beat's hops, counts, new cards) is
 * measured off the page's running animations, and the answer's own entrance waits until the last of them has landed.
 * One rule for every lesson: the picture's last beat decides, never the steps' timeline. Returns the wait in ms.
 */
export function pictureSettlesIn(stage: Element): number {
  let wait = 0;
  for (const pic of stage.querySelectorAll(PICTURES)) {
    if (typeof (pic as Element & { getAnimations?: unknown }).getAnimations !== "function") continue;
    for (const a of pic.getAnimations({ subtree: true })) {
      // the picture's own whole-picture bounce (solved) is the celebration the answer lands with, not a part entering
      if (a.effect && "target" in a.effect && a.effect.target === pic) continue;
      const t = a.effect?.getComputedTiming();
      if (!t || a.playState === "finished" || t.endTime == null || !Number.isFinite(Number(t.endTime))) continue;
      wait = Math.max(wait, Number(t.endTime) - Number(a.currentTime ?? 0));
    }
  }
  return Math.max(0, Math.round(wait));
}

/** a CSS time ("650ms", ".65s") in ms; 0 when it isn't one */
const cssMs = (v: string) => { const n = parseFloat(v); return !Number.isFinite(n) ? 0 : /ms\s*$/.test(v) ? n : /s\s*$/.test(v) ? n * 1000 : 0; };

/** Holds each answer token that has just appeared until the picture beside it settles (pictureSettlesIn). */
function useAnswerBeat(ref: RefObject<HTMLSpanElement | null>) {
  const seen = useRef(new WeakSet<Element>());
  useLayoutEffect(() => {
    const el = ref.current, stage = el?.closest(STAGE);
    if (!el) return;
    const fresh = [...el.querySelectorAll<HTMLElement>(".ans")].filter(a => !seen.current.has(a));
    if (!fresh.length) return;
    fresh.forEach(a => seen.current.add(a));
    // read after the commit: the picture's new beat is in the page by now, so its entrances are already running
    // and never sooner than one picture beat (--m-grow) after the picture's last beat starts, for a last beat whose
    // parts change without an entrance the page can measure (the area model's bracket, then its sum)
    if (!stage || reduceMotion() || !stage.querySelector(PICTURES)) return;
    const wait = Math.max(pictureSettlesIn(stage), cssMs(getComputedStyle(stage).getPropertyValue("--m-grow")));
    if (wait <= 0) return;
    fresh.forEach(a => {
      a.style.animationDelay = `${wait}ms`;
      // the "=" that the answer completes waits with it, so the line never hangs on a bare "=" (the solved line's "?"
      // was hidden until now)
      const eq = a.previousElementSibling as HTMLElement | null;
      if (eq?.classList.contains("o") && eq.textContent === "=") eq.style.animation = `ansIn var(--dur-420) var(--m-ease) ${wait}ms both`;
    });
  });
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
  const fitRef = useFit(math, !!onSlot);
  useAnswerBeat(fitRef);
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
  // keep (and every line with answer boxes, G 2026-10-08): each side of a relation wraps as a whole; only a side too wide for the line wraps, at its + and −, then × and ÷
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
      {onSlot ? grouped(math) : <><span aria-hidden="true" className="mline-in">{keep ? grouped(math) : render(math)}</span><span className="visually-hidden">{toPlainText(math, "blank")}</span></>}
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
