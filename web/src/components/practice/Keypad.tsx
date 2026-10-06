import type { ReactNode } from "react";
import type { Band } from "../../curriculum/grades";
import { Pill } from "../primitives/Pill";

/**
 * The Keypad master: the keypad docked under the hero (practice-spec §1): on a wide screen two rows with Check tall on the right, in
 * portrait and on a phone four columns (1 2 3 ⌫ / 4 5 6 − / 7 8 9 . / 0 Check). Once the problem is solved the number
 * keys fade and go inert, and Check becomes the one next move.
 */
export function Keypad({ band, onKey, go, tap, solved }: { band: Band; onKey: (k: string) => void; go?: { label: string; run: () => void }; tap?: ReactNode; solved: boolean }) {
  const key = (k: string, label: string = k, cls = "", aria?: string) =>
    <button key={k} type="button" data-key={k} className={`k-${cls || k}`} aria-label={aria} disabled={solved} onClick={() => onKey(k)}>{label}</button>;
  return (
    <div className={`ppad${tap ? " ptap" : ""}${solved ? " done" : ""}`}>
      {tap ?? (
        <div className={`tray${band === "little" ? " nosign" : ""}`}>
          {[1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map(d => key(String(d), String(d), `d${d}`))}
          {band !== "little" && key(".", ".", "dot", "Decimal point")}
          {band !== "little" && key("−", "−", "neg", "Negative")}
          {key("back", "⌫", "back", "Erase")}
          {key("next", "⇥", "next", "Next box")}
          {go && <Pill go className="k-go" onClick={go.run}>{go.label}</Pill>}
        </div>
      )}
      {tap && go && <Pill go className="k-go" onClick={go.run}>{go.label}</Pill>}
    </div>
  );
}
