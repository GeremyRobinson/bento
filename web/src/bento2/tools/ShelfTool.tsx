// Number shelf: the values you've saved, by name. Every tool reads them (type the name), and later lessons and the
// build read them too. Rename, remove, or add one from any line of math.
import { useState } from "react";
import { CONSTANT_VALUES } from "../constants";
import { renameShelf, shelfNumbers, unshelve, validName, type ShelfItem } from "../progress";
import { b2LessonById, projectById, B2_TRACKS } from "../registry";
import { openTool, useB2 } from "../ui/useB2";
import { calc, showValue } from "./expr";
import { matNum } from "./MatrixPad";

/** a shelf value as one line */
export function shelfText(it: ShelfItem): string {
  const v = it.value;
  if (typeof v === "number") return `${showValue(v, 6)}${it.unit ? ` ${it.unit}` : ""}`;
  if (Array.isArray(v[0])) return `[${(v as number[][]).map(r => r.map(matNum).join(", ")).join("; ")}]`;
  return (v as number[]).map((x, i) => `${it.labels?.[i] ? `${it.labels[i]} ` : ""}${showValue(x, 5)}`).join(", ") + (it.unit ? ` ${it.unit}` : "");
}
/** where a value came from, in words */
export function fromText(from: string): string {
  const l = b2LessonById(from);
  if (l) return `${l.id.split("-")[2]} · ${l.title}`;
  for (const t of B2_TRACKS) { const p = projectById(t, from); if (p) return p.name; }
  return from === "calculator" ? "Calculator" : from === "matrix" ? "Matrix pad" : from === "shelf" ? "Typed in" : from;
}

export function ShelfTool() {
  const { b2, updateB2, save } = useB2();
  const [editing, setEditing] = useState<string | null>(null);
  const [to, setTo] = useState("");
  const [sure, setSure] = useState<string | null>(null);
  const [name, setName] = useState(""), [expr, setExpr] = useState("");
  const items = Object.entries(b2.shelf).sort((a, b) => b[1].at - a[1].at);
  const r = expr ? calc(expr, { vars: { ...CONSTANT_VALUES, ...shelfNumbers(b2) } }) : null;
  return (
    <div className="b2shelf">
      {items.length === 0 && <p className="b2empty">Nothing here yet. Lessons save values like <b>c</b> and <b>gamma</b> as you reach Use it, and you can keep any answer.</p>}
      <ul>
        {items.map(([k, it]) => (
          <li key={k}>
            <div className="b2shrow">
              {editing === k
                ? <form onSubmit={e => { e.preventDefault(); if (validName(to)) { updateB2(b => renameShelf(b, k, to)); setEditing(null); } }}>
                  <input autoFocus value={to} onChange={e => setTo(e.currentTarget.value)} aria-label={`New name for ${k}`} spellCheck={false} />
                  <button type="submit" className="ctl" disabled={!validName(to)}>Rename</button>
                </form>
                : <b className="b2shname">{k}</b>}
              <span className="b2shval">{shelfText(it)}</span>
            </div>
            <small>{fromText(it.from)}{it.note ? ` · ${it.note}` : ""}</small>
            <span className="b2shact">
              {typeof it.value === "number" && <button type="button" className="ctl" onClick={() => openTool("calc", { insert: k })}>Use</button>}
              {Array.isArray(it.value) && Array.isArray(it.value[0]) && <button type="button" className="ctl" onClick={() => openTool("matrix", { A: it.value, label: k })}>Open in Matrix pad</button>}
              <button type="button" className="ctl" onClick={() => { setEditing(k); setTo(k); }}>Rename</button>
              <button type="button" className="ctl" onClick={() => { if (sure === k) { updateB2(b => unshelve(b, k)); setSure(null); } else setSure(k); }}>{sure === k ? "Remove it" : "Remove"}</button>
            </span>
          </li>
        ))}
      </ul>
      <form className="b2keep" onSubmit={e => { e.preventDefault(); if (validName(name) && r?.ok) { save(name, r.value, "shelf", { note: expr }); setName(""); setExpr(""); } }}>
        <input value={name} onChange={e => setName(e.currentTarget.value)} placeholder="name" aria-label="New value's name" spellCheck={false} />
        <input value={expr} onChange={e => setExpr(e.currentTarget.value)} placeholder="value, like 0.6 c" aria-label="New value" spellCheck={false} />
        <button type="submit" className="ctl" disabled={!validName(name) || !r?.ok}>Add</button>
        {r && !r.ok && <small className="err">{r.error}</small>}
      </form>
    </div>
  );
}
