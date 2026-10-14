import { useRef, type ReactNode } from "react";
import { useApp } from "../app/AppState";
import { motionOff, readAloudOn, readSettings, speak, playTone, type Settings } from "../app/settings";
import { GRADES_VIEW, setBoxView } from "../app/box";
import { FIND_MY_LEVEL, SETTING } from "../app/copy";
import { gradeOf } from "../curriculum/grades";
import { placeKey } from "../engine/session/practice";
import { useOnePane } from "../app/media";
import { OSlider, OSwitch } from "../components/Masters";

/** one setting: its name on the left, its control on the right (UI model v63) */
const Row = ({ name, children }: { name: string; children: ReactNode }) => (
  <div className="o-setrow"><span className="o-nm">{name}</span>{children}</div>
);

/** an on/off setting is the switch master */
const OnOff = ({ name, on, set }: { name: string; on: boolean; set: (v: boolean) => void }) => (
  <Row name={name}><OSwitch on={on} onChange={set} label={name} /></Row>
);

/** the seven groups, in the model's order (UI model v66, layout C) */
export const GROUPS = [
  { id: "look", name: "Look and motion" },
  { id: "read", name: "Reading and sound" },
  { id: "keypad", name: "Keypad" },
  { id: "grade", name: "Grade" },
  { id: "see", name: "Seeing better" },
  { id: "backup", name: "Backup" },
  { id: "about", name: "About" },
] as const;
export type GroupId = (typeof GROUPS)[number]["id"];
const groupOf = (id: string | undefined) => GROUPS.find(g => g.id === id) ?? GROUPS[0];
export const groupName = (id: string | undefined) => groupOf(id).name;

const Chevron = () => <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 5l7 7-7 7" /></svg>;

/**
 * Settings (UI model v66, layout C, G 2026-10-14): a list of seven groups and the picked group's settings. On an iPad
 * the two sit side by side and picking a group changes the detail in place; on a phone the list fills the page and a
 * group opens as its own page, the island's back returning to the list. The page never scrolls: the list or the group
 * scrolls inside its own panel when the text is large.
 */
export function SettingsScreen() {
  const { route, go } = useApp();
  const one = useOnePane();
  const open = route.name === "settings" ? route.group : undefined;
  const g = groupOf(open);
  const prev = useRef<{ g: string; open: boolean } | null>(null);
  // how a change comes in: on a phone a group is a page, so it zooms in (and back zooms out) with the one page change;
  // on an iPad only the detail changes, and it arrives. Less motion: the plain arrive.
  const was = prev.current;
  const how = was && (was.g !== g.id || was.open !== !!open) && (!one || motionOff()) ? " o-arrive" : "";
  prev.current = { g: g.id, open: !!open };
  const pick = (id: GroupId) => {
    if (!one && id === g.id) return;
    go({ name: "settings", group: id }, one ? "fwd" : "still");
  };
  const showList = !one || !open, showGroup = !one || !!open;

  return (
    <div className={`o-state settings${one && open ? " open" : ""}`}>
      {showList && (
        <section className={`o-panel${one ? how : ""}`} aria-label="Settings">
          <h2 className="o-head o-in">Settings</h2>
          <div className="o-glist">
            {GROUPS.map(x => (
              <button key={x.id} className="o-gli" aria-current={!one && x.id === g.id ? "true" : undefined} onClick={() => pick(x.id)}>
                <span>{x.name}</span><Chevron />
              </button>
            ))}
          </div>
        </section>
      )}
      {showGroup && (
        <section className={`o-panel${how}`} aria-label={g.name} key={g.id}>
          <h2 className="o-head o-in">{g.name}</h2>
          <div className="o-setrows"><Group id={g.id} /></div>
        </section>
      )}
    </div>
  );
}

/** every group in one column, for the older nav hub (no grade chosen yet), where `leave` closes the hub first */
export function SettingsBody({ leave }: { leave?: () => void }) {
  return (
    <div className="o-state settings">
      <section className="o-panel" aria-label="Settings">
        <h2 className="o-head o-in">Settings</h2>
        <div className="o-setrows">{GROUPS.map(x => <Group key={x.id} id={x.id} leave={leave} />)}</div>
      </section>
    </div>
  );
}

/** one group's settings; every setting the app had keeps a home (Review settings-c #3) */
function Group({ id, leave }: { id: GroupId; leave?: () => void }) {
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

  switch (id) {
    case "look": return <>
      <Row name="Look"><OSlider tabs={[{ id: "auto", label: "Auto" }, { id: "light", label: "Light" }, { id: "dark", label: "Dark" }]} value={st.look} onPick={v => set({ look: v })} label="Look" /></Row>
      <Row name="Motion"><OSlider tabs={[{ id: "system", label: "Full" }, { id: "reduce", label: "Less" }]} value={st.motion} onPick={v => set({ motion: v })} label="Motion" /></Row>
    </>;
    case "read": return <>
      <Row name="Text size"><OSlider tabs={[{ id: "standard", label: "A", aria: "Small" }, { id: "large", label: "A", aria: "Medium" }, { id: "largest", label: "A", aria: "Large" }]}
        value={st.text} onPick={v => set({ text: v })} label="Text size" className="o-tsize" /></Row>
      <OnOff name={SETTING.readAloud} on={readAloudOn(st, g)} set={v => { set({ readAloud: v }); if (v) speak("Read aloud is on."); }} />
      <OnOff name={SETTING.sounds} on={st.sounds} set={v => { set({ sounds: v }); if (v) playTone("right"); }} />
    </>;
    case "keypad": return <>
      <Row name="Keypad side"><OSlider tabs={[{ id: "right", label: "Right" }, { id: "left", label: "Left", aria: "Left-handed" }]} value={st.leftHanded ? "left" : "right"} onPick={v => set({ leftHanded: v === "left" })} label="Keypad side" /></Row>
    </>;
    case "grade": return <>
      <Row name="Grade"><button className="o-btn" onClick={() => { leave?.(); setBoxView(GRADES_VIEW); go({ name: "home" }, "back"); }}>{g != null ? gradeOf(g).name : "Choose"}</button></Row>
      {g != null && <Row name={FIND_MY_LEVEL}><button className="o-btn" onClick={() => { leave?.(); startTest(placeKey(g)); }}>Start</button></Row>}
    </>;
    case "see": return <>
      <OnOff name="High contrast" on={st.contrast} set={v => set({ contrast: v })} />
      <OnOff name="Easy-to-read letters" on={st.readable} set={v => set({ readable: v })} />
      <OnOff name={SETTING.colorSafe} on={st.colorSafe} set={v => set({ colorSafe: v })} />
    </>;
    case "backup": return <>
      <Row name="Save a backup"><button className="o-btn" onClick={save}>Save</button></Row>
      <Row name="Restore a backup"><button className="o-btn" onClick={() => file.current?.click()}>Restore</button></Row>
      <p className="o-small o-snote">Everything stays on this device. No account, no ads, no data collected.</p>
      <input ref={file} type="file" accept="application/json,.json" hidden onChange={e => void load(e.target.files?.[0])} />
    </>;
    case "about": return <>
      <Row name="What Obento is"><button className="o-btn" onClick={() => { leave?.(); go({ name: "welcome" }, "back"); }}>Open</button></Row>
    </>;
  }
}
