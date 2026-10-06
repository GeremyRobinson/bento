// Units and constants: every constant the lessons compute with, by the name you type, and a converter.
import { useState } from "react";
import { CONSTANTS, convert, UNITS } from "../constants";
import { openTool } from "../ui/useB2";
import { calc, showValue } from "./expr";

export function UnitsTool() {
  const [kind, setKind] = useState("length");
  const [val, setVal] = useState("1");
  const [from, setFrom] = useState("lns"), [to, setTo] = useState("m");
  const list = UNITS[kind]!;
  const n = calc(val);
  const out = n.ok ? convert(kind, n.value, from, to) : NaN;
  const pick = (k: string) => { setKind(k); setFrom(UNITS[k]![0]!.id); setTo(UNITS[k]![1]!.id); };
  return (
    <div className="b2units">
      <ul className="b2consts">
        {CONSTANTS.map(k => (
          <li key={k.id}>
            <span className="b2csym">{k.symbol}</span>
            <span className="b2cname"><b>{k.name}</b><small>{k.shown}{k.also ? ` · ${k.also.join(" · ")}` : ""}{k.exact ? " · exact" : ""}</small></span>
            <button type="button" className="ctl" onClick={() => openTool("calc", { insert: k.id })} aria-label={`Use ${k.name} in the calculator`}>{k.id}</button>
          </li>
        ))}
      </ul>
      <div className="b2conv">
        <span className="b2toggle" role="group" aria-label="Kind of unit">
          {Object.keys(UNITS).map(k => <button type="button" key={k} aria-pressed={k === kind} onClick={() => pick(k)}>{k === "length" ? "Length" : k === "time" ? "Time" : "Speed"}</button>)}
        </span>
        <div className="b2convrow">
          <input value={val} onChange={e => setVal(e.currentTarget.value)} aria-label="Value to convert" inputMode="decimal" spellCheck={false} />
          <select value={from} onChange={e => setFrom(e.currentTarget.value)} aria-label="From">{list.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}</select>
          <span aria-hidden>→</span>
          <select value={to} onChange={e => setTo(e.currentTarget.value)} aria-label="To">{list.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}</select>
        </div>
        <output aria-live="polite">{n.ok ? `${showValue(n.value, 6)} ${list.find(u => u.id === from)!.name} = ${showValue(out, 6)} ${list.find(u => u.id === to)!.name}` : n.error}</output>
      </div>
    </div>
  );
}
