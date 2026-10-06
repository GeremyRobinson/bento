// The Truth table panel (computation.md, cs-01 and cs-02): type a statement in p, q, r, s; flip the switches and each
// setting you try fills one row of the table. With a second (and third) statement the rows where they disagree glow.
// Quiet (a Guess before Lock in): the other statements' columns stay hidden, and nothing counts rows for you.
import { useMemo, useState } from "react";
import { flag, str, type SceneProps } from "../../../scenes";
import { Read, Scene } from "../../../ui/kit";
import { evaluate, Or, parse, rows, varsOf, type Ex } from "../maths";

const W = 360;
const tf = (b: boolean) => (b ? "T" : "F");

function useExpr(start: string) {
  const [text, setText] = useState(start);
  const [last, setLast] = useState<Ex>(() => parse(start) ?? parse("p")!);
  const ok = parse(text);
  const set = (t: string) => { setText(t); const e = parse(t); if (e) setLast(e); };
  return { text, set, e: ok ?? last, bad: !ok };
}

export function TruthTableScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), blank = flag(props, "blank");
  const e1 = useExpr(str<string>(props, "expr", "(p ∨ q) ∧ ¬r"));
  const e2 = useExpr(str<string>(props, "expr2", ""));
  const e3 = useExpr(str<string>(props, "expr3", ""));
  const exprs = [e1, ...(str<string>(props, "expr2", "") ? [e2] : []), ...(str<string>(props, "expr3", "") ? [e3] : [])];
  const vars = varsOf(exprs.map(x => x.e).reduce((a, b) => Or(a, b)));
  const all = rows(vars);
  const [env, setEnv] = useState<Record<string, boolean>>(() => Object.fromEntries(["p", "q", "r", "s"].map(v => [v, true])));
  const [tried, setTried] = useState<Set<number>>(() => new Set(flag(props, "fill") ? all.map((_, i) => i) : [0]));
  const [fillAll, setFillAll] = useState(flag(props, "fill"));
  const here = all.findIndex(r => vars.every(v => r[v] === env[v]));
  const seen = (i: number) => !blank && (fillAll || tried.has(i));
  const flip = (v: string) => {
    const next = { ...env, [v]: !env[v] };
    setEnv(next);
    const i = all.findIndex(r => vars.every(x => r[x] === next[x]));
    setTried(s => new Set(s).add(i));
  };
  const pickRow = (i: number) => { setEnv(e => ({ ...e, ...all[i]! })); setTried(s => new Set(s).add(i)); };
  const outs = useMemo(() => all.map(r => exprs.map(x => evaluate(x.e, r))), [all, exprs]);
  const hidden = (k: number) => quiet && k > 0;
  const differs = (i: number, k: number) => k > 0 && outs[i]![k] !== outs[i]![0];
  const glowRow = (i: number) => exprs.length === 2 && !quiet && seen(i) && differs(i, 1);

  // the table: up to 8 rows a block; 16 rows sit in two blocks side by side
  const n = all.length, blocks = n > 8 ? 2 : 1, per = n / blocks, cols = vars.length + exprs.length;
  const colW = Math.min(blocks > 1 ? 30 : 40, (W - 24 - (blocks - 1) * 16) / blocks / cols), blockW = cols * colW;
  const legend = legendText(props);
  const legendH = (exprs.length > 1 ? exprs.length * 17 : 17) + (legend ? 17 : 0);
  const top = 50 + legendH + 18, rowH = Math.min(17, (300 - top) / per);
  const H = top + per * rowH + 8;
  const bx = (b: number) => 12 + b * (blockW + 16);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A truth table with ${n} rows for ${exprs.map(x => x.text).join(" and ")}.`}>
      {vars.map((v, i) => (
        <g key={v} onClick={() => flip(v)} style={{ cursor: "pointer" }}>
          <circle cx={26 + i * 42} cy="24" r="15" className={`b2bar ${env[v] ? "amber" : "track"}`} />
          <circle cx={26 + i * 42} cy="24" r="15" className="b2ring" />
          <text x={26 + i * 42} y="29" textAnchor="middle" className="b2t">{v}={tf(env[v]!)}</text>
          <rect x={8 + i * 42} y="6" width="36" height="36" className="b2hit" style={{ cursor: "pointer" }} />
        </g>
      ))}
      {exprs.map((x, k) => {
        const on = evaluate(x.e, env), cx = W - 26 - (exprs.length - 1 - k) * 40;
        return (
          <g key={k}>
            <circle cx={cx} cy="24" r="15" className={`b2bar ${hidden(k) || blank ? "unknown" : on ? "amber" : "track"}`} />
            <circle cx={cx} cy="24" r="15" className="b2ring amber" />
            <text x={cx} y="29" textAnchor="middle" className="b2t">{hidden(k) || blank ? (exprs.length > 1 ? `${k + 1}: ?` : "?") : exprs.length > 1 ? `${k + 1}: ${tf(on)}` : tf(on)}</text>
          </g>
        );
      })}
      {exprs.length > 1
        ? exprs.map((x, k) => <text key={k} x="12" y={62 + k * 17} className={`b2t ${k ? "sky" : "amber"}`}>{k + 1}: {x.text}</text>)
        : <text x="12" y="62" className="b2t amber">{e1.text}</text>}
      {legend && <text x="12" y={62 + exprs.length * 17} className="b2t">{legend}</text>}
      {Array.from({ length: blocks }, (_, b) => (
        <g key={b}>
          {vars.map((v, c) => <text key={v} x={bx(b) + c * colW + colW / 2} y={top - 6} textAnchor="middle" className="b2t">{v}</text>)}
          {exprs.map((_, k) => <text key={k} x={bx(b) + (vars.length + k) * colW + colW / 2} y={top - 6} textAnchor="middle" className="b2t amber">{exprs.length > 1 ? k + 1 : "out"}</text>)}
          <line x1={bx(b)} y1={top - 2} x2={bx(b) + blockW} y2={top - 2} className="b2axis" />
          <line x1={bx(b) + vars.length * colW} y1={top - 16} x2={bx(b) + vars.length * colW} y2={top + per * rowH} className="b2grid strong" />
        </g>
      ))}
      {all.map((r, i) => {
        const b = Math.floor(i / per), y = top + (i % per) * rowH, x = bx(b);
        return (
          <g key={i} onClick={() => pickRow(i)} style={{ cursor: "pointer" }}>
            {glowRow(i) && <rect x={x} y={y} width={blockW} height={rowH - 1} rx="3" className="b2bar amber" opacity="0.3" />}
            {i === here && <rect x={x - 2} y={y - 1} width={blockW + 4} height={rowH + 1} rx="4" className="b2mark sky" />}
            {vars.map((v, c) => <text key={v} x={x + c * colW + colW / 2} y={y + rowH * 0.72} textAnchor="middle" className="b2t">{tf(r[v]!)}</text>)}
            {exprs.map((_, k) => {
              const cx = x + (vars.length + k) * colW;
              const show = seen(i) && !hidden(k);
              return (
                <g key={k}>
                  {show && exprs.length > 2 && differs(i, k) && <rect x={cx + 2} y={y} width={colW - 4} height={rowH - 1} rx="3" className="b2bar amber" opacity="0.35" />}
                  <text x={cx + colW / 2} y={y + rowH * 0.72} textAnchor="middle" className={`b2t ${show && outs[i]![k] ? "amber" : ""}`}>{show ? tf(outs[i]![k]!) : hidden(k) ? "?" : "·"}</text>
                </g>
              );
            })}
            <rect x={x} y={y} width={blockW} height={rowH} className="b2hit" style={{ cursor: "pointer" }} />
          </g>
        );
      })}
    </svg>
  );
  const filled = all.every((_, i) => seen(i));
  const trueRows = outs.filter(o => o[0]).length;
  const diff = (k: number) => outs.filter(o => o[k] !== o[0]).length;
  return (
    <Scene svg={svg}
      controls={<>
        {!quiet && !blank && <label className={`csfield${e1.bad ? " bad" : ""}`}><span>{exprs.length > 1 ? "1" : "Statement"}</span>
          <input value={e1.text} aria-label="First statement" onChange={e => e1.set(e.currentTarget.value)} /></label>}
        {!quiet && !blank && exprs.length === 2 && <label className={`csfield${e2.bad ? " bad" : ""}`}><span>2</span>
          <input value={e2.text} aria-label="Second statement" onChange={e => e2.set(e.currentTarget.value)} /></label>}
        {!quiet && !blank && !fillAll && <button type="button" className="ctl" onClick={() => setFillAll(true)}>Fill every row</button>}
      </>}
      readouts={<>
        <Read label="Rows" value={`2${vars.length === 2 ? "²" : vars.length === 3 ? "³" : vars.length === 4 ? "⁴" : ""} = ${n}`} />
        {!blank && <Read label="Rows tried" value={fillAll ? n : tried.size} />}
        {!quiet && filled && <Read label={exprs.length > 1 ? "1 is true on" : "True on"} value={`${trueRows} of ${n}`} tone="amber" big={exprs.length === 1} />}
        {!quiet && filled && exprs.slice(1).map((_, j) => <Read key={j} label={`${j + 2} differs from 1 on`} value={`${diff(j + 1)} ${diff(j + 1) === 1 ? "row" : "rows"}`} tone="sky" big />)}
      </>}
    />
  );
}
const legendText = (p: SceneProps["props"]) => str<string>(p, "legend", "");
