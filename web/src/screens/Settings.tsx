import { useRef, type ReactNode } from "react";
import { useApp } from "../app/AppState";
import { readAloudOn, readSettings, speak, playTone, type Settings } from "../app/settings";
import { GRADES_VIEW, setBoxView } from "../app/box";
import { FIND_MY_LEVEL, SETTING } from "../app/copy";
import { gradeOf } from "../curriculum/grades";
import { placeKey } from "../engine/session/practice";
import { OSlider } from "../components/Masters";

/** preview and dev builds carry the design sandbox; Settings is its way in */
const SANDBOX = import.meta.env.MODE === "preview" || import.meta.env.MODE === "development";

/** one setting: its name on the left, its control on the right (UI model v63) */
const Row = ({ name, children }: { name: string; children: ReactNode }) => (
  <div className="o-setrow"><span className="o-nm">{name}</span>{children}</div>
);

const OFF_ON = [{ id: "off", label: "Off" }, { id: "on", label: "On" }] as const;
/** an on/off setting is the slider master with two stops */
const OnOff = ({ name, on, set }: { name: string; on: boolean; set: (v: boolean) => void }) => (
  <Row name={name}><OSlider tabs={[...OFF_ON]} value={on ? "on" : "off"} onPick={v => set(v === "on")} label={name} /></Row>
);

/**
 * Settings (UI model v63): one panel of Look, Motion and Grade, each a name and its control; Grade opens the grade
 * picker. The settings the model doesn't show yet (text size, contrast, read aloud, the keypad, backups) keep their
 * place in a second panel of the same rows, so nothing a child or grown-up relies on goes away.
 */
export function SettingsScreen() { return <SettingsBody />; }

/** the settings themselves: on the Settings page, and inside the old nav hub, where `leave` closes the hub first */
export function SettingsBody({ leave }: { leave?: () => void }) {
  const { progress, go, setSettings, exportBackup, importBackup, startTest } = useApp();
  const st = readSettings(progress.settings);
  const set = (patch: Partial<Settings>) => setSettings(patch);
  const file = useRef<HTMLInputElement>(null);
  const g = progress.grade;
  const save = () => {
    const url = URL.createObjectURL(new Blob([exportBackup()], { type: "application/json" }));
    const a = Object.assign(document.createElement("a"), { href: url, download: `obento-backup-${new Date().toISOString().slice(0, 10)}.json` });
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  };
  const load = async (f: File | undefined) => {
    if (!f) return;
    try { await importBackup(await f.text()); } catch (e) { alert((e as Error).message); }
    if (file.current) file.current.value = "";
  };

  return (
    <div className="o-state settings">
      <section className="o-panel" aria-label="Settings">
        <h2 className="o-head o-in">Settings</h2>
        <div className="o-setrows">
          <Row name="Look"><OSlider tabs={[{ id: "auto", label: "Auto" }, { id: "light", label: "Light" }, { id: "dark", label: "Dark" }]} value={st.look} onPick={v => set({ look: v })} label="Look" /></Row>
          <Row name="Motion"><OSlider tabs={[{ id: "system", label: "Full" }, { id: "reduce", label: "Less" }]} value={st.motion} onPick={v => set({ motion: v })} label="Motion" /></Row>
          <Row name="Grade"><button className="o-btn" onClick={() => { leave?.(); setBoxView(GRADES_VIEW); go({ name: "home" }, "back"); }}>{g != null ? gradeOf(g).name : "Choose"}</button></Row>
        </div>
      </section>

      <section className="o-panel" aria-label="More settings">
        <h2 className="o-head o-in">More settings</h2>
        <div className="o-setrows">
          <Row name="Text size"><OSlider tabs={[{ id: "standard", label: "A", aria: "Standard" }, { id: "large", label: "A", aria: "Large" }, { id: "largest", label: "A", aria: "Largest" }]}
            value={st.text} onPick={v => set({ text: v })} label="Text size" className="o-tsize" /></Row>
          <OnOff name="High contrast" on={st.contrast} set={v => set({ contrast: v })} />
          <OnOff name={SETTING.colorSafe} on={st.colorSafe} set={v => set({ colorSafe: v })} />
          <OnOff name="Easy-to-read letters" on={st.readable} set={v => set({ readable: v })} />
          <OnOff name={SETTING.readAloud} on={readAloudOn(st, g)} set={v => { set({ readAloud: v }); if (v) speak("Read aloud is on."); }} />
          <OnOff name={SETTING.sounds} on={st.sounds} set={v => { set({ sounds: v }); if (v) playTone("right"); }} />
          <Row name="Keypad"><OSlider tabs={[{ id: "right", label: "Right" }, { id: "left", label: "Left", aria: "Left-handed" }]} value={st.leftHanded ? "left" : "right"} onPick={v => set({ leftHanded: v === "left" })} label="Keypad" /></Row>
          {g != null && <Row name={FIND_MY_LEVEL}><button className="o-btn" onClick={() => { leave?.(); startTest(placeKey(g)); }}>Start</button></Row>}
          <Row name="Backup"><button className="o-btn" onClick={save} aria-label="Save a backup">Save</button></Row>
          <Row name="Restore a backup"><button className="o-btn" onClick={() => file.current?.click()}>Restore</button></Row>
          <Row name="What Obento is"><button className="o-btn" onClick={() => { leave?.(); go({ name: "welcome" }, "back"); }} aria-label="What Obento is">Open</button></Row>
          {SANDBOX && <Row name="Sandbox"><button className="o-btn" onClick={() => { leave?.(); dispatchEvent(new Event("bento:sandbox")); }} aria-label="Sandbox">Open</button></Row>}
        </div>
        <p className="o-why">Everything stays on this device. No account, no ads, no data collected.</p>
        <input ref={file} type="file" accept="application/json,.json" hidden onChange={e => void load(e.target.files?.[0])} />
      </section>
    </div>
  );
}
