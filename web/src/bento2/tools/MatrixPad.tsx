// Matrix pad: type a grid of numbers (any entry can be math: 5/4, sqrt(2), a shelf name). Multiply, add, invert, find
// the determinant and the eigenvectors; load a matrix from the Number shelf and keep a result on it.
import { useEffect, useMemo, useState } from "react";
import { CONSTANT_VALUES } from "../constants";
import { shelfNumbers, validName } from "../progress";
import { toFraction } from "../steps";
import { useB2 } from "../ui/useB2";
import { calc, showValue } from "./expr";
import { add, det, eigen, inverse, mul, transpose, type Mat } from "./matrix";

interface PadState { A: string[][]; B: string[][] }
const blank = (n: number, m: number) => Array.from({ length: n }, (_, i) => Array.from({ length: m }, (_, j) => (i === j ? "1" : "0")));
/** a number as a short fraction when it is one, else to 4 significant figures */
export const matNum = (x: number) => {
  if (Math.abs(x) < 1e-12) return "0";
  const [n, d] = toFraction(x, 200);
  if (Math.abs(n / d - x) < 1e-9) return d === 1 ? showValue(n) : `${n < 0 ? "−" : ""}${Math.abs(n)}/${d}`;
  return showValue(x, 4);
};
const fromMat = (m: Mat) => m.map(r => r.map(x => matNum(x).replace("−", "-")));

export function MatrixPad({ args }: { args?: unknown }) {
  const { b2, tool, setToolState, save } = useB2();
  const st = tool<PadState>("matrix", { A: blank(2, 2), B: blank(2, 2) });
  const [res, setRes] = useState<{ label: string; M?: Mat; text?: string; err?: string } | null>(null);
  const [name, setName] = useState("");
  const set = (p: Partial<PadState>) => setToolState("matrix", { ...st, ...p });
  // a picture sends a matrix in (the spacetime diagram's boost)
  useEffect(() => {
    // `cells`, when sent, are the exact entries as typed math (10/√(91)), so nothing is lost to rounding
    const a = args as { A?: Mat; cells?: string[][]; label?: string } | undefined;
    if (a?.A) { set({ A: a.cells ?? fromMat(a.A) }); setRes({ label: a.label ? `A is the ${a.label}` : "A loaded", M: a.A }); }
  }, [args]); // eslint-disable-line react-hooks/exhaustive-deps
  const vars = useMemo(() => ({ ...CONSTANT_VALUES, ...shelfNumbers(b2) }), [b2]);
  const read = (g: string[][]): Mat => g.map(r => r.map(c => { const v = calc(c || "0", { vars }); if (!v.ok) throw new Error(`Can't read "${c}": ${v.error}`); return v.value; }));
  const run = (label: string, f: (A: Mat, B: Mat) => Mat | string) => {
    try { const out = f(read(st.A), read(st.B)); setRes(typeof out === "string" ? { label, text: out } : { label, M: out }); }
    catch (e) { setRes({ label, err: (e as Error).message }); }
  };
  const resize = (which: "A" | "B", n: number) => set({ [which]: blank(n, n) } as Partial<PadState>);
  const matrices = Object.entries(b2.shelf).filter(([, v]) => Array.isArray(v.value) && Array.isArray((v.value as unknown[])[0]));
  const grid = (which: "A" | "B") => {
    const g = st[which];
    return (
      <div className="b2matbox">
        <div className="b2mathead">
          <b>{which}</b>
          {[2, 3].map(n => <button type="button" key={n} className="ctl" aria-pressed={g.length === n} onClick={() => resize(which, n)}>{n} × {n}</button>)}
          {matrices.map(([k, v]) => <button type="button" key={k} className="ctl" onClick={() => set({ [which]: fromMat(v.value as Mat) } as Partial<PadState>)}>{k}</button>)}
        </div>
        <div className="b2cells" style={{ gridTemplateColumns: `repeat(${g[0]!.length}, minmax(0, 1fr))` }}>
          {g.map((r, i) => r.map((c, j) => (
            <input key={`${i}-${j}`} value={c} aria-label={`${which} row ${i + 1} column ${j + 1}`} spellCheck={false} autoComplete="off"
              onChange={e => { const next = g.map(row => [...row]); next[i]![j] = e.currentTarget.value; set({ [which]: next } as Partial<PadState>); }} />
          )))}
        </div>
      </div>
    );
  };
  return (
    <div className="b2matpad">
      <div className="b2mats">{grid("A")}{grid("B")}</div>
      <div className="b2ops">
        <button type="button" className="ctl" onClick={() => run("A × B", (A, B) => mul(A, B))}>A × B</button>
        <button type="button" className="ctl" onClick={() => run("B × A", (A, B) => mul(B, A))}>B × A</button>
        <button type="button" className="ctl" onClick={() => run("A + B", (A, B) => add(A, B))}>A + B</button>
        <button type="button" className="ctl" onClick={() => run("A − B", (A, B) => add(A, B, -1))}>A − B</button>
        <button type="button" className="ctl" onClick={() => run("A⁻¹", A => inverse(A))}>A⁻¹</button>
        <button type="button" className="ctl" onClick={() => run("Aᵀ", A => transpose(A))}>Aᵀ</button>
        <button type="button" className="ctl" onClick={() => run("det A", A => matNum(det(A)))}>det A</button>
        <button type="button" className="ctl" onClick={() => run("Eigen", A => {
          const e = eigen(A);
          if (e.complex && !e.values.length) return "No real eigenvalues: A turns every arrow.";
          return e.values.map((v, i) => `λ = ${matNum(v)}, v = (${e.vectors[i]!.map(x => showValue(x, 3)).join(", ")})`).join("; ") + (e.complex ? "; the other two are complex" : "");
        })}>Eigen</button>
      </div>
      {res && (
        <div className="b2res" aria-live="polite">
          <small>{res.label}</small>
          {res.err && <p className="err">{res.err}</p>}
          {res.text && <p>{res.text}</p>}
          {res.M && <div className="b2cells out" style={{ gridTemplateColumns: `repeat(${res.M[0]!.length}, minmax(0, 1fr))` }}>{res.M.flat().map((x, i) => <b key={i}>{matNum(x)}</b>)}</div>}
          {res.M && (
            <form className="b2keep" onSubmit={e => { e.preventDefault(); if (validName(name)) { save(name, res.M!, "matrix", { note: res.label }); setName(""); } }}>
              <input value={name} onChange={e => setName(e.currentTarget.value)} placeholder="name" aria-label="Name for the result" spellCheck={false} />
              <button type="submit" className="ctl" disabled={!validName(name)}>Keep on the shelf</button>
              <button type="button" className="ctl" onClick={() => set({ A: fromMat(res.M!) })}>Use as A</button>
            </form>
          )}
        </div>
      )}
    </div>
  );
}
