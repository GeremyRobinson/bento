// The Race card (computation.md, cs-08's project): pick three algorithms you've run and race them at n = 10, 1,000 and
// 1,000,000. Each cell is a step count, drawn as a bar on a log scale, with its time at a billion steps per second.
import { useState } from "react";
import type { SceneProps } from "../../../scenes";
import { Read, SaveRow, Scene } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { group } from "../../../steps";
import { human } from "../common";

const W = 360;
const NS = [10, 1000, 1000000];
const ceilLog = (n: number) => Math.ceil(Math.log2(n));
export const ALGOS = [
  { id: "linear", name: "Linear search", steps: (n: number) => n },
  { id: "binary", name: "Binary search", steps: (n: number) => Math.floor(Math.log2(n)) + 1 },
  { id: "bubble", name: "Bubble sort", steps: (n: number) => (n * (n - 1)) / 2 },
  { id: "merge", name: "Merge sort", steps: (n: number) => n * ceilLog(n) - 2 ** ceilLog(n) + 1 },
];

export function RaceScene({ place }: SceneProps) {
  const [picked, setPicked] = useState(["binary", "bubble", "merge"]);
  const { b2, save, note } = useB2();
  const algos = ALGOS.filter(a => picked.includes(a.id));
  const toggle = (id: string) => setPicked(p => (p.includes(id) ? p.filter(x => x !== id) : p.length >= 3 ? [...p.slice(1), id] : [...p, id]));
  const colX = (j: number) => 112 + j * 82, bar = (s: number) => (Math.log10(Math.max(1, s)) / 12) * 74;
  const svg = (
    <svg viewBox={`0 0 ${W} 210`} className="b2pic" role="img" aria-label={`A race card: ${algos.map(a => a.name).join(", ")} at n = 10, 1,000 and 1,000,000.`}>
      {NS.map((n, j) => <text key={n} x={colX(j) + 37} y="18" textAnchor="middle" className="b2t">n = {n >= 1e6 ? "1M" : group(n)}</text>)}
      {algos.map((a, i) => (
        <g key={a.id}>
          <text x="8" y={52 + i * 58} className="b2t">{a.name}</text>
          {NS.map((n, j) => {
            const s = a.steps(n), slow = s / 1e9 > 60;
            return (
              <g key={n}>
                <rect x={colX(j)} y={34 + i * 58} width="74" height="16" rx="4" className="b2bar track" />
                <rect x={colX(j)} y={34 + i * 58} width={Math.max(2, bar(s))} height="16" rx="4" className={`b2bar ${slow ? "trav" : "sky"}`} />
                <text x={colX(j)} y={66 + i * 58} className="b2t">{s >= 1e9 ? `${(s / 1e9).toFixed(0)} billion` : group(s)}</text>
                <text x={colX(j)} y={80 + i * 58} className={`b2t ${slow ? "trav" : ""}`}>{human(s / 1e9)}</text>
              </g>
            );
          })}
        </g>
      ))}
    </svg>
  );
  const value = algos.map(a => NS.map(a.steps));
  const saved = JSON.stringify(b2.shelf.race_card?.value) === JSON.stringify(value);
  return (
    <Scene svg={svg}
      controls={<span className="cspick" role="group" aria-label="Pick three algorithms"><small>Race</small>
        {ALGOS.map(a => <button type="button" key={a.id} aria-pressed={picked.includes(a.id)} onClick={() => toggle(a.id)}>{a.name}</button>)}</span>}
      readouts={<>
        {algos.map(a => <Read key={a.id} label={`${a.name} at a million`} value={human(a.steps(1e6) / 1e9)} tone={a.steps(1e6) / 1e9 > 60 ? "trav" : "sky"} />)}
      </>}
      foot={place !== "lesson" && algos.length === 3 && <SaveRow what={<>Keep <b>race_card</b>: {algos.map(a => a.name.toLowerCase()).join(", ")}</>} saved={saved} onSave={() => {
        save("race_card", value, "cs-race", { labels: algos.map(a => a.name), note: "steps at n = 10, 1,000 and 1,000,000" });
        note({ id: "cs-race", track: "cs", title: "Race card", project: "cs-race", data: Object.fromEntries(algos.map(a => [a.id, a.steps(1e6)])),
          lines: algos.map(a => `${a.name}: ${NS.map(n => `${group(a.steps(n))} at ${group(n)}`).join(", ")}; ${human(a.steps(1e6) / 1e9)} at a million.`) });
      }} />}
    />
  );
}
