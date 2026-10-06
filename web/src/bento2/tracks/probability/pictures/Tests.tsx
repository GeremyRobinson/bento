// Luck or real? The Shuffle bench (13): deal the labels again, once, many times, or list every split, and each split's
// gap drops onto a dot plot beside the real one. Power bells (14): "no effect" and "real effect" curves with the
// cutoff, the power shaded, and power against n. Loaded-coin court (project 4): plan, flip, weigh, then the truth.
import { useMemo, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { binomPmf, Phi, normalPdf, seeded } from "../maths";
import { Act, Acts, commas, K, lin } from "./parts";

const W = 360, H = 240;

/* ---------------- the shuffle bench ---------------- */
const meanOf = (xs: number[]) => xs.reduce((a, b) => a + b, 0) / xs.length;
export function ShuffleScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet");
  const T0 = str(props, "t", "10,15,18").split(",").map(Number), C0 = str(props, "c", "5,8,12").split(",").map(Number);
  const vals = [...T0, ...C0].sort((a, b) => a - b), nT = T0.length;
  const obs = meanOf(T0) - meanOf(C0);
  const splits = useMemo(() => {
    const out: number[] = [];
    for (let m = 0; m < 1 << vals.length; m++) {
      const t = vals.filter((_, i) => (m >> i) & 1);
      if (t.length !== nT) continue;
      out.push(meanOf(t) - meanOf(vals.filter((_, i) => !((m >> i) & 1))));
    }
    return out.sort((a, b) => a - b);
  }, [vals.join(","), nT]); // eslint-disable-line react-hooks/exhaustive-deps
  const [all, setAll] = useState(flag(props, "all"));
  const [seed, setSeed] = useState(1);
  const [count, setCount] = useState(0);
  const draws = useMemo(() => {
    const r = seeded(seed + 5);
    return Array.from({ length: 2000 }, () => { const s = r.shuffle(vals); const t = s.slice(0, nT); return { t, gap: meanOf(t) - meanOf(s.slice(nT)) }; });
  }, [seed, vals.join(",")]); // eslint-disable-line react-hooks/exhaustive-deps
  const shown = all ? splits : draws.slice(0, count).map(d => d.gap);
  const lastT = !all && count ? draws[count - 1]!.t : T0;
  const ext = shown.filter(g => g >= obs - 1e-9).length;
  const lo = splits[0]!, hi = splits[splits.length - 1]!, X = lin(lo - 0.5, hi + 0.5, 20, W - 12);
  const cw = (W - 20) / vals.length;
  const step = (hi - lo) / 28 || 1, stack = new Map<number, number>(), dot = all ? 5 : 3.2;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Treated beat control by ${fx(obs)}. ${all ? `${ext} of the ${splits.length} splits` : `${ext} of ${shown.length} shuffles`} do at least as well.`}>
      {vals.map((v, i) => {
        const tr = lastT.includes(v);
        return (
          <g key={i}>
            <rect x={10 + i * cw + 3} y="10" width={cw - 6} height="32" rx="9" style={{ fill: tr ? K.pink : K.sky, fillOpacity: 0.28, stroke: tr ? K.pink : K.sky }} />
            <text x={10 + i * cw + cw / 2} y="31" textAnchor="middle" className="b2t" style={{ fill: K.text }}>{v}</text>
          </g>
        );
      })}
      <text x="12" y="62" className="b2t pink">treated</text>
      <text x="80" y="62" className="b2t sky">control</text>
      {shown.map((g, i) => {
        const b = Math.round((g - lo) / step), c = stack.get(b) ?? 0; stack.set(b, c + 1);
        const y = H - 30 - c * (dot * 2 + 1);
        return y > 76 ? <circle key={i} cx={X(lo + b * step)} cy={y} r={dot} style={{ fill: g >= obs - 1e-9 ? K.amber : K.muted, fillOpacity: 0.9 }} /> : null;
      })}
      <line x1={X(lo - 0.5)} x2={X(hi + 0.5)} y1={H - 24} y2={H - 24} className="b2axis" />
      <line x1={X(obs)} x2={X(obs)} y1="78" y2={H - 18} style={{ stroke: K.amber, strokeWidth: 2 }} />
      <text x={X(obs) - 4} y="90" textAnchor="end" className="b2t amber">real gap {fx(obs)}</text>
      <text x={X(0)} y={H - 6} textAnchor="middle" className="b2t">0</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<Acts>
        <Act onClick={() => { setAll(false); setCount(c => Math.min(2000, c + 1)); }}>Shuffle</Act>
        <Act onClick={() => { setAll(false); setCount(c => Math.min(2000, c + 100)); }}>×100</Act>
        <Act on={all} onClick={() => setAll(v => !v)}>List every split</Act>
        <Act onClick={() => { setAll(false); setCount(0); setSeed(s => s + 1); }}>Clear</Act>
      </Acts>}
      readouts={<>
        <Read label="Real gap" value={fx(obs)} tone="amber" />
        <Read label={all ? "Splits" : "Shuffles"} value={commas(shown.length)} />
        {!quiet && shown.length > 0 && <Read label="At least as extreme" value={all ? `${ext} of ${splits.length}` : `${fx((100 * ext) / shown.length, 1)}%`} tone="amber" big />}
      </>}
    />
  );
}

/* ---------------- power bells ---------------- */
export function PowerScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet");
  const [delta, setDelta] = useState(num(props, "delta", 5.6));
  const [sigma, setSigma] = useState(num(props, "sigma", 20));
  const [n, setN] = useState(num(props, "n", 100));
  const se = sigma / Math.sqrt(n), shift = delta / se, power = 1 - Phi(1.96 - shift);
  const R = Math.max(delta, 0.5 * se, 0.5);
  const X = lin(-1.6 * R, 2.6 * R, 14, W - 12), base = H - 22;
  const peak = normalPdf(0) / se, yTop = Math.max(peak, normalPdf(0) / (R / 1.2));
  const Y = (d: number) => base - (d / yTop) * 150;
  const xs = Array.from({ length: 241 }, (_, i) => -1.6 * R + (4.2 * R * i) / 240);
  const bell = (mu: number) => xs.map(x => [X(x), Y(normalPdf((x - mu) / se) / se)] as [number, number]);
  const cut = 1.96 * se;
  const tail = (mu: number): [number, number][] => [[X(cut), base], ...xs.filter(x => x >= cut).map(x => [X(x), Y(normalPdf((x - mu) / se) / se)] as [number, number]), [X(2.6 * R), base]];
  const ns = Array.from({ length: 60 }, (_, i) => Math.round(4 * 250 ** (i / 59)));
  const PX = lin(Math.log(4), Math.log(1000), W - 128, W - 14), PY = lin(0, 1, 74, 16);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`SE ${fx(se)}, the effect is ${fx(shift)} standard errors.${quiet ? "" : ` Power ${fx(power * 100, 1)}%.`}`}>
      <path d={`${path(tail(delta))} Z`} style={{ fill: K.sky, fillOpacity: 0.35 }} />
      <path d={`${path(tail(0))} Z`} style={{ fill: K.pink, fillOpacity: 0.5 }} />
      <path d={path(bell(0))} style={{ fill: "none", stroke: K.pink, strokeWidth: 2 }} />
      <path d={path(bell(delta))} style={{ fill: "none", stroke: K.sky, strokeWidth: 2 }} />
      <line x1={X(cut)} x2={X(cut)} y1={base} y2={Math.max(20, Y(peak) - 6)} style={{ stroke: K.amber, strokeWidth: 2 }} />
      <text x={X(cut) + 4} y={base - 6} className="b2t amber">cutoff</text>
      <text x={X(0)} y={Math.max(16, Y(peak) - 6)} textAnchor="middle" className="b2t pink">no effect</text>
      <text x={X(delta)} y={Math.max(16, Y(peak) - 6) + (Math.abs(X(delta) - X(0)) < 70 ? 16 : 0)} textAnchor="middle" className="b2t sky">real effect</text>
      <line x1={X(-1.6 * R)} x2={X(2.6 * R)} y1={base} y2={base} className="b2axis" />
      <text x={X(0)} y={H - 6} textAnchor="middle" className="b2t">0</text>
      <text x={X(delta)} y={H - 6} textAnchor="middle" className="b2t">δ</text>
      {!quiet && <g>
        <rect x={W - 136} y="6" width="128" height="80" rx="8" style={{ fill: "var(--page)", fillOpacity: 0.85, stroke: K.line }} />
        <path d={path(ns.map(m => [PX(Math.log(m)), PY(1 - Phi(1.96 - delta / (sigma / Math.sqrt(m))))]))} style={{ fill: "none", stroke: K.sky, strokeWidth: 1.8 }} />
        <circle cx={PX(Math.log(Math.min(1000, Math.max(4, n))))} cy={PY(power)} r="4" style={{ fill: K.sky }} />
        <text x={W - 128} y="84" className="b2t">power vs n</text>
      </g>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Effect δ" value={delta} min={0} max={20} step={0.05} onChange={setDelta} format={x => fx(x)} />
        <Slider label="SD σ" value={sigma} min={1} max={40} step={1} onChange={setSigma} />
        <Slider label="n" value={n} min={4} max={1000} step={1} onChange={setN} marks={[{ v: 100, label: "100" }, { v: 400, label: "400" }]} />
      </>}
      readouts={<>
        <Read label="SE = σ/√n" value={fx(se)} />
        <Read label="Shift = δ/SE" value={fx(shift)} />
        {!quiet && <Read label="Power" value={`${fx(power * 100, 1)}%`} tone="sky" big />}
        <Read label="False alarms, each side" value="2.5%" tone="pink" />
        {!quiet && <Read label="n for 80%" value={delta > 0 ? commas(Math.ceil(7.84 * (sigma / delta) ** 2 - 1e-9)) : "none"} />}
      </>}
    />
  );
}

/* ---------------- loaded-coin court (project 4) ---------------- */
export function CourtScene({ props }: SceneProps) {
  const project = flag(props, "project");
  const [prior, setPrior] = useState(20);
  const [n, setN] = useState(40);
  const [caseNo, setCaseNo] = useState(1);
  const [ran, setRan] = useState(false);
  const [shown, setShown] = useState(false);
  const [record, setRecord] = useState<{ call: boolean; truth: boolean }[]>([]);
  const { note } = useB2();
  const [kept, setKept] = useState(0);
  const { loaded, flips } = useMemo(() => {
    const r = seeded(caseNo * 97 + 13), loaded = r.next() < prior / 100;
    return { loaded, flips: Array.from({ length: 200 }, () => r.next() < (loaded ? 0.75 : 0.5)) };
  }, [caseNo]); // eslint-disable-line react-hooks/exhaustive-deps
  const used = flips.slice(0, n), k = used.filter(Boolean).length;
  let pv = 0; for (let j = k; j <= n; j++) pv += binomPmf(j, n, 0.5);
  const logBF = k * Math.log(1.5) + (n - k) * Math.log(0.5), odds = (prior / (100 - prior)) * Math.exp(logBF), post = odds / (1 + odds);
  const call = post > 0.5;
  const reveal = () => { if (!ran || shown) return; setShown(true); setRecord(rs => [...rs, { call, truth: loaded }]); };
  const next = () => { setCaseNo(c => c + 1); setRan(false); setShown(false); };
  const onSave = () => { setKept(caseNo); note({ id: "pr-court", track: "pr", title: "Loaded-coin court", project: "pr-court", data: { prior, n },
    lines: [`Plan: ${n} flips, prior chance loaded ${prior}%.`, `Case ${caseNo}: ${k} heads. p = ${fx(pv, 4)}, Bayes factor ${fx(Math.exp(logBF), 2)}, chance loaded ${fx(post * 100, 1)}%.`,
      `Verdict: ${call ? "loaded" : "fair"}.${shown ? ` Truth: ${loaded ? "loaded" : "fair"}.` : ""}`, `Calls that held up: ${record.filter(r => r.call === r.truth).length} of ${record.length}.`] }); };
  const cols = 20, cell = 15;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={ran ? `${k} heads in ${n} flips. Chance it's loaded: ${fx(post * 100, 1)}%.` : `Plan ${n} flips, then run them.`}>
      {used.map((f, i) => <circle key={i} cx={20 + (i % cols) * cell + 2} cy={18 + Math.floor(i / cols) * cell} r="5.2" style={ran ? { fill: f ? K.amber : K.faint } : { fill: "none", stroke: K.faint }} />)}
      {ran && <text x="12" y={H - 52} className="b2t amber">{k} heads in {n}</text>}
      {record.map((r, i) => <circle key={i} cx={20 + (i % 24) * 13} cy={H - 30 + Math.floor(i / 24) * 13} r="5" style={{ fill: r.call === r.truth ? K.right : K.wrong }} />)}
      {record.length > 0 && <text x="12" y={H - 6} className="b2t">past verdicts: green held up, red didn't</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Prior chance it's loaded" value={prior} min={5} max={95} step={5} onChange={setPrior} format={x => `${x}%`} />
        <Slider label="Plan: flips" value={n} min={10} max={200} step={10} onChange={v => { setN(v); setRan(false); setShown(false); }} />
        <Acts>
          <Act onClick={() => setRan(true)}>Run the flips</Act>
          <Act onClick={reveal}>Reveal the truth</Act>
          <Act onClick={next}>Next coin</Act>
        </Acts>
      </>}
      readouts={ran ? <>
        <Read label="p-value, P(X ≥ k | fair)" value={fx(pv, 4)} tone="amber" />
        <Read label="Bayes factor, loaded over fair" value={Math.exp(logBF) > 1e4 ? Math.exp(logBF).toExponential(1) : fx(Math.exp(logBF), 2)} />
        <Read label="Chance it's loaded" value={`${fx(post * 100, 1)}%`} tone="pink" big />
        <Read label="Verdict" value={call ? "loaded" : "fair"} />
        {shown && <Read label="The truth" value={loaded ? "loaded" : "fair"} tone={loaded ? "amber" : "sky"} />}
      </> : <Read label="Case" value={caseNo} />}
      foot={project && ran && <SaveRow what={<>Keep this case, {fx(post * 100, 1)}% loaded, and your record in the Notebook: Luck detector v2</>} saved={kept === caseNo} onSave={onSave} />}
    />
  );
}
