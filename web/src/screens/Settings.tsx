import { useRef } from "react";
import { Pill } from "../components/primitives/Pill";
import { LockIcon } from "../components/primitives/icons";
import { Tile, Toggle } from "../components/PageTile";
import { useApp } from "../app/AppState";
import { readAloudOn, readSettings, speak, playTone, type Settings } from "../app/settings";
import { SETTING } from "../app/copy";

/** preview and dev builds carry the design sandbox; Settings is its way in */
const SANDBOX = import.meta.env.MODE === "preview" || import.meta.env.MODE === "development";

/**
 * Settings: every setting in one place, and only here (G 2026-10-06). The gear opens this page; there is no pop-over
 * version. Seeing and hearing, motion and sound, the keypad, backups, and what Bento is. Nothing leaves this device.
 */
export function SettingsScreen() {
  const { progress, go, setSettings, exportBackup, importBackup } = useApp();
  const st = readSettings(progress.settings);
  const set = (patch: Partial<Settings>) => setSettings(patch);
  const file = useRef<HTMLInputElement>(null);
  const save = () => {
    const url = URL.createObjectURL(new Blob([exportBackup()], { type: "application/json" }));
    const a = Object.assign(document.createElement("a"), { href: url, download: `bento-backup-${new Date().toISOString().slice(0, 10)}.json` });
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  };
  const load = async (f: File | undefined) => {
    if (!f) return;
    try { await importBackup(await f.text()); } catch (e) { alert((e as Error).message); }
    if (file.current) file.current.value = "";
  };

  return (
    <div className="bset">
      <Tile title="See it" k="Accessibility" className="ssee">
        <div className="mseg" role="radiogroup" aria-label="Text size">
          <span className="mt-text"><b>Text size</b><small>Bigger words, numbers and buttons</small></span>
          <span className="seg">
            {(["standard", "large", "largest"] as const).map((v, i) => (
              <button key={v} role="radio" aria-checked={st.text === v} className={st.text === v ? "on" : ""} onClick={() => set({ text: v })}
                aria-label={["Standard", "Large", "Largest"][i]}><span className={`tsize${i}`}>A</span></button>
            ))}
          </span>
        </div>
        <Toggle label="High contrast" note="Darker text and stronger lines" on={st.contrast} set={v => set({ contrast: v })} />
        <Toggle label={SETTING.colorSafe} note="Blue and orange for right and wrong" on={st.colorSafe} set={v => set({ colorSafe: v })} />
        <Toggle label="Easy-to-read letters" note="Plainer, wider letters" on={st.readable} set={v => set({ readable: v })} />
      </Tile>

      <Tile title="Hear it and feel it" k="Motion and sound" className="shear">
        <Toggle label={SETTING.readAloud} note="Reads each step and problem out loud" on={readAloudOn(st, progress.grade)} set={v => { set({ readAloud: v }); if (v) speak("Read aloud is on."); }} />
        <Toggle label={SETTING.sounds} note="A soft tone for right and wrong answers" on={st.sounds} set={v => { set({ sounds: v }); if (v) playTone("right"); }} />
        <Toggle label={SETTING.motion} note="No sliding or zooming; pictures show finished" on={st.motion === "reduce"} set={v => set({ motion: v ? "reduce" : "system" })} />
      </Tile>

      <Tile title="Keypad" k="Hands" className="skeys">
        <Toggle label="Left-handed keypad" note="Puts the number keys on the left" on={st.leftHanded} set={v => set({ leftHanded: v })} />
      </Tile>

      <Tile title="Keep your progress" k="Backup" className="sback">
        <p className="muted">Everything stays on this device. Save a backup file to move it to another one.</p>
        <div className="actions">
          <Pill onClick={save}>Save a backup</Pill>
          <Pill onClick={() => file.current?.click()}>Restore</Pill>
        </div>
        <input ref={file} type="file" accept="application/json,.json" hidden onChange={e => void load(e.target.files?.[0])} />
      </Tile>

      <Tile title="About Bento" k="Bento" className="sabout">
        <p className="snote"><LockIcon />On this device. No account, no ads, no data collected.</p>
        <div className="actions">
          <Pill onClick={() => go({ name: "welcome" }, "back")}>What Bento is ›</Pill>
          {SANDBOX && <Pill onClick={() => dispatchEvent(new Event("bento:sandbox"))}>Sandbox ›</Pill>}
        </div>
      </Tile>
    </div>
  );
}
