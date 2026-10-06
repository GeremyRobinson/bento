// The Goal sandbox (15): a cleaning robot in a 5 × 5 room. The optimizer tries n random plans of 24 moves and keeps
// the one with the highest reward; drag n and watch two meters, the reward it got and how clean the room really is.
// The reward is built from parts you switch on and off. The default, "+1 for each tile the camera sees as clean", has a
// loophole (turn the camera to the wall) that a strong enough optimizer finds. The sweep plots both meters, averaged
// over 12 rooms, against n. The rug tile (top left) hides dirt swept under it from the camera, but not from the truth.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { bestOf, DEFAULT_REWARD, OPT_STEPS, rewardOf, ROOM, roomPlans, RUG, sweep, trueClean, type RewardParts } from "../maths";
import { Btn, lin } from "./common";

const PARTS: { k: keyof RewardParts; label: string }[] = [
  { k: "seen", label: "+1 per tile seen clean" },
  { k: "bin", label: "+3 per dirt in the bin" },
  { k: "turn", label: "−30 for turning the camera" },
  { k: "rug", label: "−5 per dirt under the rug" },
];
const partsText = (p: RewardParts) => PARTS.filter(x => p[x.k]).map(x => x.label).join(", ") || "nothing";
const maxReward = (p: RewardParts) => (p.seen ? 25 : 0) + (p.bin ? 36 : 0);

export function GoalsScene({ props }: SceneProps) {
  const quiet = flag(props, "quiet"), saving = flag(props, "save");
  const start = Math.max(0, OPT_STEPS.indexOf(num(props, "n", 30)));
  const [k, setK] = useState(start);
  const [parts, setParts] = useState<RewardParts>(DEFAULT_REWARD);
  const [showSweep, setShowSweep] = useState(flag(props, "sweep"));
  const n = OPT_STEPS[k]!, plans = roomPlans(17);
  const best = useMemo(() => bestOf(plans, n, parts), [plans, n, parts]);
  const sw = useMemo(() => (showSweep && !quiet ? sweep(parts) : null), [showSweep, quiet, parts]);
  const reward = rewardOf(best, parts), clean = trueClean(best), top = Math.max(1, maxReward(parts));
  const { note, b2 } = useB2();
  const W = 360, H = 260, T = 34, x0 = 16, y0 = 30;
  const tile = (i: number) => ({ x: x0 + (i % ROOM) * T, y: y0 + Math.floor(i / ROOM) * T });
  const end = best.path.at(-1)!;
  const mY = lin(0, 1, 200, 40);
  const loophole = best.wall ? "it turned the camera to the wall" : best.underRug ? `it swept ${best.underRug} dirt under the rug` : null;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={`Best of ${n} plans: reward ${reward}, room really ${Math.round(clean * 100)}% clean${loophole ? `; ${loophole}` : ""}.`}>
      <text x={x0} y="20" className="b2t">best of {n.toLocaleString("en-US")} plans</text>
      {Array.from({ length: ROOM * ROOM }, (_, i) => { const t = tile(i); return <rect key={i} x={t.x} y={t.y} width={T} height={T} className={`aitile${i === RUG ? " rug" : ""}`} />; })}
      <text x={tile(RUG).x + T / 2} y={tile(RUG).y + T - 5} textAnchor="middle" className="b2t">rug{best.underRug ? ` ${best.underRug}` : ""}</text>
      {best.dirt.map((d, i) => d ? <circle key={i} cx={tile(i).x + T / 2} cy={tile(i).y + T / 2} r="6" className="aidirt" /> : null)}
      <path d={path(best.path.map(i => [tile(i).x + T / 2, tile(i).y + T / 2]))} className="b2curve sky" fill="none" strokeWidth="1.5" opacity="0.5" />
      <circle cx={tile(end).x + T / 2} cy={tile(end).y + T / 2} r="9" className="airobot" />
      {/* the camera, on the wall above the room: it looks in, or at the wall */}
      <text x={x0 + (ROOM * T) / 2} y={y0 + ROOM * T + 18} textAnchor="middle" className={`b2t${best.wall ? " pink" : ""}`}>{best.wall ? "camera: at the wall" : "camera: on the room"}</text>
      {/* the two meters */}
      {!sw ? <g>
        {[{ x: 214, v: Math.max(0, reward) / top, cls: "amber", name: "reward", val: String(reward) }, { x: 286, v: clean, cls: "mint", name: "clean", val: `${Math.round(clean * 100)}%` }].map(m => <g key={m.name}>
          <rect x={m.x} y="40" width="40" height="160" rx="6" className="b2bar track" />
          <rect x={m.x} y={mY(m.v)} width="40" height={200 - mY(m.v)} rx="6" className={`b2bar ${m.cls}`} />
          <text x={m.x + 20} y="218" textAnchor="middle" className={`b2t ${m.cls}`}>{m.name}</text>
          <text x={m.x + 20} y={mY(m.v) - 6} textAnchor="middle" className={`b2t ${m.cls}`}>{m.val}</text>
        </g>)}
      </g> : <Sweep sw={sw} n={n} top={top} />}
    </svg>
  );
  const saved = b2.notebook.some(e => e.id === "ai-loophole" && e.lines[0]?.includes(partsText(parts)));
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Plans the optimizer tries" value={k} min={0} max={OPT_STEPS.length - 1} step={1} onChange={setK} format={i => OPT_STEPS[i]!.toLocaleString("en-US")} />
        <span className="aiparts" role="group" aria-label="Reward parts">
          {PARTS.map(p => <button key={p.k} type="button" className={`ctl${parts[p.k] ? " go" : ""}`} aria-pressed={parts[p.k]} onClick={() => setParts(q => ({ ...q, [p.k]: !q[p.k] }))}>{p.label}</button>)}
        </span>
        {!quiet && <Btn on={showSweep} onClick={() => setShowSweep(s => !s)}>{showSweep ? "Back to the meters" : "Sweep every n"}</Btn>}
      </>}
      readouts={<>
        <Read label="Reward" value={String(reward)} tone="amber" />
        <Read label="Really clean" value={`${Math.round(clean * 100)}%`} tone="mint" big />
        {!quiet && <Read label="How it won" value={loophole ?? "by cleaning"} tone={loophole ? "pink" : undefined} />}
      </>}
      foot={saving && loophole ? <SaveRow what={<>Keep this loophole for the Reader field notes: {loophole}</>} saved={saved}
        onSave={() => note({ id: "ai-loophole", track: "ai", title: "A loophole in the robot's reward", data: { n, reward, clean: Math.round(clean * 100) },
          lines: [`Reward: ${partsText(parts)}.`, `Trying ${n.toLocaleString("en-US")} plans, the winner scored ${reward}, but ${loophole}: the room was really ${Math.round(clean * 100)}% clean.`] })} /> : undefined}
    />
  );
}

/** both meters, averaged over 12 rooms, against how many plans the optimizer tries (a log scale) */
function Sweep({ sw, n, top }: { sw: { n: number; reward: number; clean: number }[]; n: number; top: number }) {
  const X = lin(0, 4, 214, 346), Y = lin(0, 1, 200, 40);
  return <g>
    <line x1="214" y1="200" x2="346" y2="200" className="b2axis" />
    <line x1="214" y1="200" x2="214" y2="40" className="b2axis" />
    {[0, 4].map(e => <text key={e} x={X(e)} y="216" textAnchor={e ? "end" : "start"} className="b2t">{e ? "10,000" : "1"}</text>)}
    <text x="346" y="232" textAnchor="end" className="b2t">plans tried</text>
    <line x1={X(Math.log10(n))} y1="40" x2={X(Math.log10(n))} y2="200" className="aidiag" />
    <path d={path(sw.map(p => [X(Math.log10(p.n)), Y(Math.max(0, p.reward) / top)]))} className="b2curve amber" fill="none" />
    <path d={path(sw.map(p => [X(Math.log10(p.n)), Y(p.clean)]))} className="b2curve mint" fill="none" />
    <text x="218" y="34" className="b2t amber">reward</text>
    <text x="290" y="34" className="b2t mint">clean</text>
    <text x="218" y={Y(sw.at(-1)!.clean) + (sw.at(-1)!.clean > 0.5 ? 16 : -6)} className="b2t mint">{fx(sw.at(-1)!.clean * 100, 0)}%</text>
  </g>;
}
