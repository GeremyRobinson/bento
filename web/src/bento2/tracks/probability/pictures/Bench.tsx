// The build: the Luck detector bench (probability.md, "New for Development"). One strip, plan → run → test → correct →
// estimate → weigh, on a made-up A/B test whose hidden truth is sometimes "no effect". Alarms flag the traps (picked
// for being extreme, assignment not random, stopped early). "Reveal the truth" shows what was real, and "Run 100"
// checks the detector's own calls: each call is a dot in the column of how sure it was, green if it held up and red if
// not. It reads the earlier pieces from the Number shelf when they're there.
import { useMemo, useState } from "react";
import { flag, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { gauss, Phi, PhiInv, seeded } from "../maths";
import { Act, Acts, commas, K, WrapToggle } from "./parts";

const W = 360, H = 240, BASE = 0.1;

interface Run { real: boolean; d: number; se: number; z: number; clears: boolean; chance: number; lo: number; hi: number; p: number }
function runOne(seed: number, n: number, m: number, r: number, lift: number): Run {
  const g = seeded(seed), real = g.next() < r, diff = real ? lift : 0;
  const pA = BASE + gauss(g) * Math.sqrt((BASE * (1 - BASE)) / n), pB = BASE + diff + gauss(g) * Math.sqrt(((BASE + diff) * (1 - BASE - diff)) / n);
  const se = Math.sqrt((pA * (1 - pA)) / n + (pB * (1 - pB)) / n), d = pB - pA, z = d / se;
  const cut = PhiInv(1 - 0.025 / m), clears = z > cut;
  const sePlan = Math.sqrt((2 * BASE * (1 - BASE)) / n), pw = 1 - Phi(cut - lift / sePlan), a = 0.05 / m;
  const chance = clears ? (r * pw) / (r * pw + (1 - r) * a) : (r * (1 - pw)) / (r * (1 - pw) + (1 - r) * (1 - a));
  return { real, d, se, z, clears, chance, lo: d - 1.96 * se, hi: d + 1.96 * se, p: 2 * (1 - Phi(Math.abs(z))) };
}

export function BenchScene({ props }: SceneProps) {
  const project = flag(props, "project");
  const [n, setN] = useState(4000);
  const [m, setM] = useState<"1" | "2" | "5" | "10">("1");
  const [r, setR] = useState<"10" | "20" | "50">("20");
  const [lift, setLift] = useState(1);
  const [exp, setExp] = useState(1);
  const [shown, setShown] = useState(false);
  const [calls, setCalls] = useState<{ chance: number; held: boolean }[]>([]);
  const [alarms, setAlarms] = useState({ extreme: false, notRandom: false, peeked: false });
  const [line, setLine] = useState("");
  const { b2, save, note } = useB2();
  const M = Number(m), R = Number(r) / 100, L = lift / 100;
  const run = useMemo(() => runOne(exp * 7919 + 3, n, M, R, L), [exp, n, M, R, L]);
  const cut = PhiInv(1 - 0.025 / M), pw = 1 - Phi(cut - L / Math.sqrt((2 * BASE * (1 - BASE)) / n));
  const verdict = `${run.clears ? "B beats A" : "No clear winner"}: d = ${fx(run.d * 100, 2)} points (${fx(run.lo * 100, 2)} to ${fx(run.hi * 100, 2)}), z = ${fx(run.z)}, chance it's real ${fx(run.chance * 100, 0)}%.`;
  const held = (x: Run) => (x.chance > 0.5) === x.real;
  const reveal = () => { if (!shown) { setShown(true); setCalls(c => [...c, { chance: run.chance, held: held(run) }]); } };
  const runMany = () => {
    const more = Array.from({ length: 100 }, (_, i) => runOne((exp + 1000 + calls.length + i) * 104729, n, M, R, L));
    setCalls(c => [...c, ...more.map(x => ({ chance: x.chance, held: held(x) }))]);
  };
  const stages: [string, string, string][] = [
    ["plan", `n ${n >= 1000 ? `${fx(n / 1000, n % 1000 ? 1 : 0)}k` : n}`, `power ${fx(pw * 100, 0)}%`],
    ["run", `${fx(run.d * 100, 1)} pts`, `SE ${fx(run.se * 100, 2)}`],
    ["test", `z ${fx(run.z, 2)}`, `p ${run.p < 0.001 ? "< 0.001" : fx(run.p, 3)}`],
    ["correct", `bar ${fx(cut, 2)}`, run.clears ? "clears" : "doesn't"],
    ["estimate", `±${fx(1.96 * run.se * 100, 2)}`, "95%"],
    ["weigh", `${fx(run.chance * 100, 0)}%`, "real"],
  ];
  const bins = [0, 1, 2, 3, 4].map(b => calls.filter(c => Math.min(4, Math.floor(c.chance * 5)) === b));
  const warn = [alarms.extreme && "Picked for being extreme: expect regression to the mean (b2-pr-17).",
    alarms.notRandom && "Assignment wasn't random: compare within groups and adjust (b2-pr-18).",
    alarms.peeked && "Stopped when it looked good: peeking inflates false alarms (b2-pr-15)."].filter(Boolean) as string[];
  const shelf = (k: string) => b2.shelf[k]?.value;
  const piece: [number, number, number] = [n, M, Number(r)];
  const saved = JSON.stringify(b2.shelf.luckDetector?.value) === JSON.stringify(piece);
  const onSave = () => {
    save("luckDetector", piece, "pr-luck", { labels: ["n per version", "metrics", "% of ideas real"], note: "the Luck detector's plan" });
    note({ id: "pr-luck", track: "pr", title: "The build: the Luck detector", project: "pr-luck", build: true, data: { n, m: M, r: Number(r), lift },
      lines: [`Plan: ${commas(n)} per version, ${M === 1 ? "one metric" : `${M} metrics`}, ${r}% of ideas real, power ${fx(pw * 100, 0)}% for +${fx(lift, 1)} points.`,
        `Experiment ${exp}: ${verdict}${shown ? ` The truth: ${run.real ? "a real effect" : "no effect"}.` : ""}`,
        ...(line ? [`Your verdict: ${line}`] : []), ...warn,
        ...bins.map((b, i) => (b.length ? `Calls at ${i * 20} to ${i * 20 + 20}% sure: ${b.filter(c => c.held).length} held up, ${b.filter(c => !c.held).length} didn't.` : "")).filter(Boolean)] });
  };
  const bw = 112, bh = 54, gap = 4, sx = (W - 3 * bw - 2 * gap) / 2;
  const at = (i: number) => [sx + (i % 3) * (bw + gap), 4 + Math.floor(i / 3) * (bh + gap)] as const;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Experiment ${exp}. ${verdict}${shown ? ` Truth: ${run.real ? "real" : "no effect"}.` : ""}`}>
      {stages.map(([name, v1, v2], i) => {
        const [x, y] = at(i);
        return (
          <g key={name}>
            <rect x={x} y={y} width={bw} height={bh} rx="8" style={{ fill: K.text, fillOpacity: 0.05, stroke: i === 5 ? K.pink : K.line }} />
            <text x={x + 8} y={y + 16} className="b2t">{i + 1} {name}</text>
            <text x={x + 8} y={y + 32} className={`b2t ${["sky", "sky", "amber", "amber", "mint", "pink"][i]}`}>{v1}</text>
            <text x={x + 8} y={y + 48} className="b2t">{v2}</text>
          </g>
        );
      })}
      {shown && <text x={W / 2} y="128" textAnchor="middle" className="b2t" style={{ fill: held(run) ? K.right : K.wrong }}>truth: {run.real ? "a real effect" : "no effect"}, so the call {held(run) ? "held up" : "missed"}</text>}
      {[0, 1, 2, 3, 4].map(b => (
        <g key={b}>
          {bins[b]!.slice(0, 42).map((c, j) => <circle key={j} cx={22 + b * 70 + (j % 6) * 8} cy={H - 26 - Math.floor(j / 6) * 8} r="3.2" style={{ fill: c.held ? K.right : K.wrong }} />)}
          <text x={22 + b * 70 + 20} y={H - 6} textAnchor="middle" className="b2t">{b * 20}–{b * 20 + 20}</text>
        </g>
      ))}
      {calls.length > 0 && !shown && <text x={W / 2} y="128" textAnchor="middle" className="b2t">calls by % sure: green held up, red didn't</text>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Plan: n per version" value={n} min={500} max={20000} step={500} onChange={setN} format={commas}
          marks={typeof shelf("nNeeded") === "number" ? [{ v: Math.min(20000, Math.max(500, Math.round((shelf("nNeeded") as number) / 500) * 500)), label: "your nNeeded" }] : undefined} />
        <Slider label="A real effect is" value={lift} min={0.5} max={3} step={0.1} onChange={setLift} format={x => `+${fx(x, 1)} points`} />
        <WrapToggle label="Metrics checked" value={m} onChange={setM} options={(["1", "2", "5", "10"] as const).map(v => ({ v, label: v === "1" ? "1 metric" : `${v} metrics` }))} />
        <WrapToggle label="Ideas that are real" value={r} onChange={setR} options={(["10", "20", "50"] as const).map(v => ({ v, label: `${v}% real` }))} />
        <Acts>
          <Act onClick={() => { setExp(e => e + 1); setShown(false); }}>Run an experiment</Act>
          <Act onClick={reveal}>Reveal the truth</Act>
          <Act onClick={runMany}>Run 100</Act>
          <Act on={alarms.extreme} onClick={() => setAlarms(a => ({ ...a, extreme: !a.extreme }))}>Picked extremes?</Act>
          <Act on={alarms.notRandom} onClick={() => setAlarms(a => ({ ...a, notRandom: !a.notRandom }))}>Not random?</Act>
          <Act on={alarms.peeked} onClick={() => setAlarms(a => ({ ...a, peeked: !a.peeked }))}>Peeked?</Act>
        </Acts>
      </>}
      readouts={<>
        <Read label="Verdict" value={run.clears ? "B beats A" : "no clear winner"} tone={run.clears ? "amber" : undefined} big />
        <Read label="Effect, 95% interval" value={`${fx(run.d * 100, 2)} (${fx(run.lo * 100, 2)} to ${fx(run.hi * 100, 2)}) points`} />
        <Read label="Chance it's real" value={`${fx(run.chance * 100, 0)}%`} tone="pink" />
        {warn.map(w => <Read key={w} label="Alarm" value={w} />)}
        {typeof shelf("fdrField") === "number" && <Read label="fdrField, your shelf" value={`${fx((shelf("fdrField") as number) * 100, 1)}% of hits false`} />}
      </>}
      foot={project && <>
        <label className="b2slider"><span className="b2sl"><span>Your one-line verdict</span></span>
          <input type="text" value={line} placeholder={verdict} onChange={e => setLine(e.currentTarget.value)} style={{ minHeight: "36px", borderRadius: "10px", padding: "0 10px", background: "var(--well)", color: "var(--text)", border: "1px solid var(--faint)" }} /></label>
        <SaveRow what={<>Keep <b>luckDetector</b> and this bench in your Notebook</>} saved={saved} onSave={onSave} />
      </>}
    />
  );
}
