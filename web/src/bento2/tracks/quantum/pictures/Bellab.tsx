// Bell pair lab (quantum.md, the project after 09): H on the top qubit, then CNOT, with an optional Z on the top and X
// on the bottom before the CNOT. The four choices make the four Bell states; each has its own matching pattern at
// equal dials. Play 100 rounds of the CHSH game with the one you pick (Bob turns his dial or his answer to suit it).
// Saves `bell`, the state's four amplitudes.
import { useMemo, useState } from "react";
import { flag, num, type SceneProps } from "../../../scenes";
import { fx, Read, SaveRow, Scene, Toggle } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { cnot, LABELS2, stream } from "../maths";
import { shownOf, useRun } from "./parts";

const W = 360, H = 260, ROUNDS = 100;
const r = Math.SQRT1_2;
const STATES: Record<string, { name: string; same: boolean; fix: string; pSame: (A: number, B: number) => number }> = {
  "00": { name: "Φ⁺ = (00 + 11)/√2", same: true, fix: "none needed", pSame: (A, B) => Math.cos(A - B) ** 2 },
  "10": { name: "Φ⁻ = (00 − 11)/√2", same: true, fix: "Bob turns his dial the other way", pSame: (A, B) => Math.cos(A + B) ** 2 },
  "01": { name: "Ψ⁺ = (01 + 10)/√2", same: false, fix: "Bob turns his dial the other way and flips his answer", pSame: (A, B) => Math.sin(A + B) ** 2 },
  "11": { name: "Ψ⁻ = (01 − 10)/√2", same: false, fix: "Bob flips his answer", pSame: (A, B) => Math.sin(A - B) ** 2 },
};

export function BellabScene({ props }: SceneProps) {
  const [z, setZ] = useState<"no" | "yes">(num(props, "z", 0) === 1 ? "yes" : "no");
  const [x, setX] = useState<"no" | "yes">(num(props, "x", 0) === 1 ? "yes" : "no");
  const project = flag(props, "project");
  const run = useRun(3);
  const { b2, save, note } = useB2();
  const key = `${z === "yes" ? 1 : 0}${x === "yes" ? 1 : 0}`, st = STATES[key]!;
  // H on top: (1, 0, 1, 0)/√2; Z on top flips the 1 half; X on the bottom swaps each pair; then CNOT
  let v = [r, 0, r, 0];
  if (z === "yes") v = [v[0]!, v[1]!, -v[2]!, -v[3]!];
  if (x === "yes") v = [v[1]!, v[0]!, v[3]!, v[2]!];
  v = cnot(v).map(a => (Object.is(a, -0) ? 0 : a));
  const rounds = useMemo(() => {
    const rr = stream(4000 + run.runs);
    const flipDial = key === "10" || key === "01", flipAns = !st.same;
    return Array.from({ length: ROUNDS }, () => {
      const qx = rr() < 0.5 ? 0 : 1, qy = rr() < 0.5 ? 0 : 1;
      const A = (qx ? 45 : 0) * (Math.PI / 180), B0 = (qy ? -22.5 : 22.5) * (Math.PI / 180), B = flipDial ? -B0 : B0;
      const same = rr() < st.pSame(A, B), answeredSame = flipAns ? !same : same;
      return answeredSame !== (qx === 1 && qy === 1);
    });
  }, [run.runs, key]); // eslint-disable-line react-hooks/exhaustive-deps
  const shown = run.runs ? shownOf(run.k, ROUNDS) : 0, wins = rounds.slice(0, shown).filter(Boolean).length;
  const gate = (gx: number, gy: number, label: string, on: boolean) => (
    <g opacity={on ? 1 : 0.25}>
      <rect x={gx - 15} y={gy - 15} width="30" height="30" rx="7" className="b2bar track" />
      <text x={gx} y={gy + 5} textAnchor="middle" className="b2t">{label}</text>
    </g>
  );
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic bellab" role="img" aria-label={`The Bell state ${st.name}. At equal dials the two results are always ${st.same ? "the same" : "different"}.${shown ? ` ${wins} wins in ${shown} rounds.` : ""}`}>
      <line x1="20" y1="40" x2="250" y2="40" className="b2axis" />
      <line x1="20" y1="90" x2="250" y2="90" className="b2axis" />
      <text x="14" y="44" textAnchor="end" className="b2t">0</text>
      <text x="14" y="94" textAnchor="end" className="b2t">0</text>
      {gate(60, 40, "H", true)}
      {gate(110, 40, "Z", z === "yes")}
      {gate(110, 90, "X", x === "yes")}
      <line x1="170" y1="40" x2="170" y2="100" className="b2axis" />
      <circle cx="170" cy="40" r="6" className="b2dot" />
      <circle cx="170" cy="90" r="11" className="b2ring" />
      <line x1="159" y1="90" x2="181" y2="90" className="b2axis" /><line x1="170" y1="79" x2="170" y2="101" className="b2axis" />
      {v.map((a, k) => (
        <g key={k} className={a > 0 ? "amber" : a < 0 ? "trav" : undefined}>
          <rect x={30 + k * 76} y="128" width="64" height="58" rx="8" className="b2bar track" />
          {a !== 0 && <rect x={30 + k * 76} y="128" width="64" height="58" rx="8" className="b2bar" opacity="0.35" />}
          <text x={62 + k * 76} y="150" textAnchor="middle" className="b2t">{LABELS2[k]}</text>
          <text x={62 + k * 76} y="174" textAnchor="middle" className="b2t">{a === 0 ? "0" : a > 0 ? "1" : "−1"}</text>
        </g>
      ))}
      <text x="30" y="206" className="b2t">amplitudes in units of 1/√2</text>
      <rect x="30" y="220" width="292" height="18" rx="6" className="b2bar track" />
      <rect x="30" y="220" width={shown ? (292 * wins) / shown : 0} height="18" rx="6" className="b2bar sky" />
      <line x1={30 + 292 * 0.75} y1="214" x2={30 + 292 * 0.75} y2="244" className="b2mark" />
      <text x={30 + 292 * 0.75} y="257" textAnchor="middle" className="b2t">3/4</text>
    </svg>
  );
  const saved = JSON.stringify(b2.shelf.bell?.value) === JSON.stringify(v);
  const onSave = () => {
    save("bell", v, "qu-bell", { labels: LABELS2, note: st.name });
    note({ id: "qu-bell", track: "qu", title: "Bell pair lab", project: "qu-bell", data: { z: z === "yes" ? 1 : 0, x: x === "yes" ? 1 : 0 },
      lines: [`H on top${z === "yes" ? ", Z on top" : ""}${x === "yes" ? ", X on the bottom" : ""}, then CNOT: ${st.name}.`,
        `At equal dials the results are always ${st.same ? "the same" : "different"}.`,
        ...(run.done ? [`CHSH game: ${wins} wins in ${ROUNDS} rounds, against at most 75 for any plan agreed in advance.`] : [])] });
  };
  return (
    <Scene svg={svg}
      controls={<>
        <Toggle label="Z on the top qubit" value={z} onChange={setZ} options={[{ v: "no", label: "No Z" }, { v: "yes", label: "Z on top" }]} />
        <Toggle label="X on the bottom qubit" value={x} onChange={setX} options={[{ v: "no", label: "No X" }, { v: "yes", label: "X on the bottom" }]} />
        <button type="button" className="ctl go" onClick={run.run}>Play 100 rounds</button>
      </>}
      readouts={<>
        <Read label="Bell state" value={st.name} tone="amber" />
        <Read label="At equal dials" value={st.same ? "always the same" : "always different"} />
        <Read label="Bob's adjustment for the game" value={st.fix} />
        {shown > 0 && <Read label="Wins" value={`${wins} of ${shown}${run.done ? `, ${fx(wins / ROUNDS, 2)}` : ""}`} tone="sky" big />}
      </>}
      foot={project ? <SaveRow what={<>Keep <b>bell</b> = {st.name}</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
