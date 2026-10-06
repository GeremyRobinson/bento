// Scientific calculator: everything on a TI-84's main keys (trig, logs, powers, factorials, combinations, degrees or
// radians) and a history you can tap to reuse. Shelf names and constants' names work in any line.
import { useEffect, useMemo, useRef, useState } from "react";
import { CONSTANT_VALUES } from "../constants";
import { shelfNumbers, validName } from "../progress";
import { useB2 } from "../ui/useB2";
import { calc, showValue } from "./expr";

interface CalcState { history: { expr: string; value: number }[]; deg: boolean }
const KEYS: { k: string; label?: string; aria?: string; cls?: string }[][] = [
  [{ k: "sin(" , label: "sin" }, { k: "cos(", label: "cos" }, { k: "tan(", label: "tan" }, { k: "ln(", label: "ln" }, { k: "log(", label: "log" }],
  [{ k: "sqrt(", label: "√" }, { k: "^", label: "xʸ" }, { k: "(" }, { k: ")" }, { k: "!", label: "n!" }],
  [{ k: "7" }, { k: "8" }, { k: "9" }, { k: "÷", aria: "Divide" }, { k: "back", label: "⌫", aria: "Erase", cls: "fn" }],
  [{ k: "4" }, { k: "5" }, { k: "6" }, { k: "×", aria: "Times" }, { k: "clear", label: "AC", aria: "Clear", cls: "fn" }],
  [{ k: "1" }, { k: "2" }, { k: "3" }, { k: "−", aria: "Minus" }, { k: "Ans", cls: "fn" }],
  [{ k: "0" }, { k: "." , aria: "Point" }, { k: "π" }, { k: "+", aria: "Plus" }, { k: "=", aria: "Equals", cls: "eq" }],
];

export function Calculator({ args }: { args?: unknown }) {
  const { b2, tool, setToolState, save } = useB2();
  const state = tool<CalcState>("calc", { history: [], deg: false });
  const [line, setLine] = useState("");
  const [out, setOut] = useState<{ ok: boolean; text: string } | null>(null);
  const [name, setName] = useState("");
  const input = useRef<HTMLInputElement>(null);
  const vars = useMemo(() => ({ ...CONSTANT_VALUES, ...shelfNumbers(b2), ...(state.history[0] ? { Ans: state.history[0].value } : {}) }), [b2, state.history]);
  // another tool can drop a name in (the Number shelf's "Use", a constant's "Insert")
  useEffect(() => { const a = args as { insert?: string } | undefined; if (a?.insert) setLine(l => l + a.insert); }, [args]);
  // with a keyboard and a mouse the line takes typing at once; on a touch screen the keys below do, without the phone keyboard
  useEffect(() => { if (typeof matchMedia !== "undefined" && matchMedia("(pointer: fine)").matches) input.current?.focus({ preventScroll: true }); }, []);

  const run = () => {
    if (!line.trim()) return;
    const r = calc(line, { vars, degrees: state.deg });
    if (r.ok) {
      setOut({ ok: true, text: showValue(r.value) });
      setToolState("calc", { ...state, history: [{ expr: line, value: r.value }, ...state.history].slice(0, 20) });
    } else setOut({ ok: false, text: r.error });
  };
  const press = (k: string) => {
    if (k === "=") return run();
    if (k === "back") return setLine(l => l.slice(0, -1));
    if (k === "clear") { setLine(""); setOut(null); return; }
    setLine(l => l + k);
    input.current?.focus({ preventScroll: true });
  };
  const last = state.history[0];
  const names = [...Object.keys(shelfNumbers(b2)), ...Object.keys(CONSTANT_VALUES)];
  return (
    <div className="b2calc">
      <div className="b2disp">
        <input ref={input} value={line} onChange={e => setLine(e.currentTarget.value)} onKeyDown={e => { if (e.key === "Enter") { e.preventDefault(); run(); } }}
          aria-label="Calculation" placeholder="Type or tap: 0.6 × c" spellCheck={false} autoComplete="off" inputMode="text" />
        <output className={out && !out.ok ? "err" : undefined} aria-live="polite">{out ? (out.ok ? `= ${out.text}` : out.text) : last ? `Ans = ${showValue(last.value)}` : " "}</output>
      </div>
      <div className="b2calcrow">
        <button type="button" className="ctl" aria-pressed={state.deg} onClick={() => setToolState("calc", { ...state, deg: !state.deg })}>{state.deg ? "Degrees" : "Radians"}</button>
        <button type="button" className="ctl" onClick={() => press("nCr(")}>nCr</button>
        <button type="button" className="ctl" onClick={() => press("e")}>e</button>
        <button type="button" className="ctl" onClick={() => press("×10^")}>×10ⁿ</button>
      </div>
      <div className="b2keys">
        {KEYS.flat().map(k => <button type="button" key={k.k} className={k.cls} aria-label={k.aria} onClick={() => press(k.k)}>{k.label ?? k.k}</button>)}
      </div>
      <div className="b2names" aria-label="Names you can use">
        {names.map(n => <button type="button" key={n} onClick={() => press(n)}>{n}</button>)}
      </div>
      {last && (
        <form className="b2keep" onSubmit={e => { e.preventDefault(); if (validName(name)) { save(name, last.value, "calculator", { note: last.expr }); setName(""); } }}>
          <input value={name} onChange={e => setName(e.currentTarget.value)} placeholder="name" aria-label="Name for the last answer" spellCheck={false} />
          <button type="submit" className="ctl" disabled={!validName(name)}>Keep Ans on the shelf</button>
        </form>
      )}
      {state.history.length > 0 && (
        <ol className="b2hist" aria-label="History">
          {state.history.map((h, i) => (
            <li key={i}><button type="button" onClick={() => setLine(h.expr)}><span>{h.expr}</span><b>{showValue(h.value)}</b></button></li>
          ))}
        </ol>
      )}
    </div>
  );
}
