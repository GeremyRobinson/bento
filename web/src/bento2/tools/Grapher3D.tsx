// Grapher 3D: a surface z = f(x, y), turned with one finger, with a slider for any letter. Points and arrows in space
// are the next piece (the seam: Surface3D's `points`).
import { useMemo } from "react";
import { CONSTANT_VALUES } from "../constants";
import { shelfNumbers } from "../progress";
import { useB2 } from "../ui/useB2";
import { fx, Slider } from "../ui/kit";
import { Surface3D } from "../ui/Surface3D";
import { evaluate, namesIn, parse, type Node } from "./expr";

interface G3State { expr: string; vars: Record<string, number> }

export function Grapher3D() {
  const { b2, tool, setToolState } = useB2();
  const st = tool<G3State>("graph3d", { expr: "sin(x) cos(y)", vars: {} });
  const known = useMemo(() => ({ ...CONSTANT_VALUES, ...shelfNumbers(b2) }), [b2]);
  let tree: Node | null = null, err = "";
  try { tree = parse(st.expr.replace(/^\s*z\s*=\s*/, "")); } catch (e) { err = (e as Error).message; }
  const free = tree ? namesIn(tree).filter(n => n !== "x" && n !== "y" && !(n in known)) : [];
  const f = (x: number, y: number) => { try { return tree ? evaluate(tree, { vars: { ...known, ...st.vars, x, y } }) : NaN; } catch { return NaN; } };
  return (
    <div className="b2graph">
      <label className="b2fx tone-sky">
        <span>z =</span>
        <input value={st.expr} onChange={e => setToolState("graph3d", { ...st, expr: e.currentTarget.value })} aria-label="Surface: z =" spellCheck={false} autoComplete="off" />
        {err && <small className="err">{err}</small>}
      </label>
      <div className="b2svg"><Surface3D f={f} domain={3} zscale={0.6} zclip={6} label={`The surface z = ${st.expr}.`} /></div>
      {free.map(n => <Slider key={n} label={n} value={st.vars[n] ?? 1} min={-5} max={5} step={0.1} onChange={v => setToolState("graph3d", { ...st, vars: { ...st.vars, [n]: v } })} format={v => fx(v, 1)} />)}
    </div>
  );
}
