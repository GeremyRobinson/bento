// The entanglement pair (quantum.md, 08 and 09): a source sends Bell pairs to two analyzers with angle dials. Run sends
// 1,000 pairs and tallies how often the two results match, against the curve cos²(a − b). Game mode is the CHSH game:
// a referee asks each side a random question, the dials follow the best quantum plan, and the wins are counted
// against the 3/4 that any plan agreed in advance can reach. Angles are on paper, like polarizers.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, path, Read, Scene, Slider, Toggle } from "../../../ui/kit";
import { stream } from "../maths";
import { shownOf, useRun } from "./parts";

const W = 360, H = 260, N = 1000;
const cos2 = (d: number) => Math.cos((d * Math.PI) / 180) ** 2;
const Q = cos2(22.5);

/** n rounds: each a match or not; in the game, also the questions and whether the round was won */
function pairs(n: number, seed: number, game: boolean, a: number, b: number) {
  const r = stream(seed);
  return Array.from({ length: n }, () => {
    const x = r() < 0.5 ? 0 : 1, y = r() < 0.5 ? 0 : 1;
    const A = game ? (x ? 45 : 0) : a, B = game ? (y ? -22.5 : 22.5) : b;
    const same = r() < cos2(A - B), alice = r() < 0.5;
    return { same, alice, bob: same ? alice : !alice, win: same !== (x === 1 && y === 1), x, y };
  });
}

export function PairScene({ props, marker }: SceneProps) {
  const [a, setA] = useState(num(props, "a", 0));
  const [b, setB] = useState(num(props, "b", 30));
  const [mode, setMode] = useState<"match" | "game">(flag(props, "game") ? "game" : "match");
  const quiet = flag(props, "quiet");
  const run = useRun(4, flag(props, "run"));
  const game = mode === "game";
  const list = useMemo(() => pairs(N, 900 + run.runs, game, a, b), [run.runs, game, a, b]);
  const shown = run.runs ? shownOf(run.k, N) : 0;
  const done = list.slice(0, shown);
  const matches = done.filter(p => p.same).length, wins = done.filter(p => p.win).length;
  const last = done.at(-1);
  const dd = Math.abs(a - b) % 180, d = dd > 90 ? 180 - dd : dd, P = cos2(a - b);
  const hide = quiet && !run.runs;
  // the dials: in the game the referee's question sets them
  const dA = game && last ? (last.x ? 45 : 0) : a, dB = game && last ? (last.y ? -22.5 : 22.5) : b;
  const dial = (x: number, ang: number, lit: boolean | undefined, name: string, tone: string) => {
    const t = (ang * Math.PI) / 180;
    return (
      <g className={tone}>
        <circle cx={x} cy="66" r="28" className="b2ring" />
        <line x1={x - 26 * Math.sin(t)} y1={66 - 26 * Math.cos(t)} x2={x + 26 * Math.sin(t)} y2={66 + 26 * Math.cos(t)} className="b2leg" />
        {lit !== undefined && <circle cx={x} cy="66" r="8" className={lit ? "b2dot" : "b2bar track"} />}
        <text x={x} y="118" textAnchor="middle" className="b2t">{name} {fx(ang, ang % 1 ? 1 : 0)}°</text>
      </g>
    );
  };
  // pairs in flight: a few dots spreading from the source while the run plays
  const flying = run.runs && !run.done ? [0, 0.33, 0.66].map(o => ((run.k * 12 + o) % 1)) : [];
  const px = (dd: number) => 40 + (dd / 90) * 300, py = (p: number) => 240 - p * 84;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic pair" role="img"
      aria-label={game ? `The CHSH game: ${wins} wins in ${shown} rounds.` : `Analyzers at ${a}° and ${b}°.${hide ? "" : ` They match with chance ${fx(P, 3)}.`}${shown ? ` ${matches} matches in ${shown} pairs.` : ""}`}>
      <circle cx="180" cy="66" r="9" className="b2pulse" />
      <text x="180" y="40" textAnchor="middle" className="b2t amber">Bell pairs</text>
      {flying.map((f, i) => <g key={i}><circle cx={180 - f * 120} cy="66" r="4" className="b2dot sky" /><circle cx={180 + f * 120} cy="66" r="4" className="b2dot pink" /></g>)}
      {dial(46, dA, last?.alice, "Alice", "sky")}
      {dial(314, dB, last?.bob, "Bob", "pink")}
      {!game ? <g>
        <line x1="40" y1="240" x2="340" y2="240" className="b2axis" />
        <line x1="40" y1="156" x2="340" y2="156" className="b2grid" />
        <text x="36" y="160" textAnchor="end" className="b2t">1</text>
        <text x="36" y="244" textAnchor="end" className="b2t">0</text>
        <text x="340" y="256" textAnchor="end" className="b2t">90°</text>
        <text x="44" y="256" className="b2t">a − b: 0°</text>
        {!hide && <path d={path(Array.from({ length: 91 }, (_, i) => [px(i), py(cos2(i))]))} className="b2curve amber" />}
        <line x1={px(d)} y1="150" x2={px(d)} y2="240" className="b2mark" />
        {marker && <line x1="40" y1={py(marker[0])} x2="340" y2={py(marker[0])} className="b2mark guess" />}
        {shown > 0 && <circle cx={px(d)} cy={py(matches / shown)} r="6" className="b2dot sky" />}
      </g> : <g>
        <rect x="60" y="150" width="240" height="26" rx="8" className="b2bar track" />
        <rect x="60" y="150" width={shown ? (240 * wins) / shown : 0} height="26" rx="8" className="b2bar sky" />
        <line x1={60 + 240 * 0.75} y1="140" x2={60 + 240 * 0.75} y2="186" className="b2mark" />
        <line x1={60 + 240 * Q} y1="140" x2={60 + 240 * Q} y2="186" className="b2mark amber" />
        <text x={60 + 240 * 0.75 - 4} y="204" textAnchor="end" className="b2t">plan: 3/4</text>
        <text x={60 + 240 * Q + 4} y="222" className="b2t amber">0.854</text>
        <text x="60" y="140" className="b2t">win rate</text>
      </g>}
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        {!game && <Slider label="Alice's dial a" value={a} min={0} max={180} step={5} onChange={setA} format={v => `${v}°`} />}
        {!game && <Slider label="Bob's dial b" value={b} min={0} max={180} step={5} onChange={setB} format={v => `${v}°`} marks={[0, 30, 45, 90].map(v => ({ v, label: `${v}°` }))} />}
        <Toggle label="Mode" value={mode} onChange={setMode} options={[{ v: "match", label: "Match" }, { v: "game", label: "Game" }]} />
        {!quiet && <button type="button" className="ctl go" onClick={run.run}>{game ? "Play 1,000" : "Run 1,000"}</button>}
      </>}
      readouts={game ? <>
        <Read label="Wins so far" value={shown ? `${wins.toLocaleString("en-US")} of ${shown.toLocaleString("en-US")}` : "none yet"} tone="sky" big />
        <Read label="Win rate" value={shown ? fx(wins / shown, 3) : "?"} tone="sky" />
        <Read label="Entangled, in theory" value={fx(Q, 3)} tone="amber" />
        <Read label="Best plan in advance" value="0.750" minor />
      </> : <>
        <Read label="a − b" value={`${fx(a - b, 0)}°`} minor />
        <Read label={hide ? "P(same)" : "P(same) = cos²(a − b)"} value={hide ? "?" : fx(P, 3)} tone="amber" />
        {shown > 0 && <Read label="Matches" value={`${matches.toLocaleString("en-US")} of ${shown.toLocaleString("en-US")}`} tone="sky" big />}
      </>}
    />
  );
}
