import { useRef, useState, type ReactNode } from "react";
import { useApp } from "../app/AppState";
import { readAloudOn, readSettings, speak, playTone, type Settings } from "../app/settings";
import { GRADES_VIEW, setBoxView } from "../app/box";
import { FIND_MY_LEVEL, SETTING } from "../app/copy";
import { gradeOf } from "../curriculum/grades";
import { placeKey } from "../engine/session/practice";
import { OSlider } from "../components/Masters";
import { SETTING_ICONS, type SettingIcon } from "../components/tilepics/setting-icons";
import type { SettingsPage } from "../app/routes";

/** preview and dev builds carry the design sandbox; About is its way in (never on the live site) */
const SANDBOX = import.meta.env.MODE === "preview" || import.meta.env.MODE === "development";

/** what the island says on a Settings tile's own page */
export const SETTINGS_PAGE_NAME: Record<SettingsPage, string> = { level: FIND_MY_LEVEL, backup: "Backup", about: "About" };

const Icon = ({ name }: { name: SettingIcon }) => (
  <svg className="o-sic" viewBox="0 0 256 256" fill="currentColor" aria-hidden="true" dangerouslySetInnerHTML={{ __html: SETTING_ICONS[name] }} />
);

/** a setting's tile (the chapter tile's master): its icon, its name and what it is now. An on/off tile is a switch */
function STile({ icon, name, value, on, sw, label, onClick }: { icon: SettingIcon; name: ReactNode; value: string; on?: boolean; sw?: boolean; label?: string; onClick: () => void }) {
  return (
    <button className={`o-tile o-cover o-stile${on ? " sel" : ""}`} onClick={onClick} aria-label={label}
      {...(sw ? { role: "switch", "aria-checked": !!on } : {})}>
      <span className="o-cpw"><Icon name={icon} /></span>
      <span className="o-tx"><span className="o-nm">{name}</span><span className={`o-sv${on ? " on" : ""}`}>{value}</span></span>
    </button>
  );
}

/** a three-choice setting: a wide tile that holds the word slider, so every choice shows and takes one tap */
const WTile = ({ icon, name, children }: { icon: SettingIcon; name: string; children: ReactNode }) => (
  <div className="o-tile o-cover o-stile o-wide"><span className="o-cpw"><Icon name={icon} /></span><span className="o-tx"><span className="o-nm">{name}</span>{children}</span></div>
);

/** one row of a Settings page: its name, then its control or its note */
const Row = ({ name, children }: { name: string; children: ReactNode }) => (
  <div className="o-setrow"><span className="o-nm">{name}</span>{children}</div>
);

/**
 * Settings (UI model v67.1, Settings B, G 2026-10-14 18:01): every setting is a tile, the same master as the chapter
 * tiles. On is the word "On" and the outline. Look and Text size are wide tiles with the word slider; two-choice tiles
 * step on a tap; Find my level, Backup and About open their own page (no pop-ups); Grade opens the grade picker. On an
 * iPad a small lesson sits beside the tiles so you can see what each setting does; on a phone the whole app is the preview.
 */
export function SettingsScreen() {
  const { route } = useApp();
  const page = route.name === "settings" ? route.page : undefined;
  return (
    <div className="o-state settings">
      <Preview />
      <section className="o-panel o-sets" aria-label={page ? SETTINGS_PAGE_NAME[page] : "Settings"}>
        {page ? <SubPage page={page} /> : <Tiles />}
      </section>
    </div>
  );
}

/** the tiles alone, inside the old nav hub (before a grade is picked), where `leave` closes the hub first */
export function SettingsBody({ leave }: { leave?: () => void }) {
  return <section className="o-panel o-sets" aria-label="Settings"><Tiles leave={leave} /></section>;
}

function Tiles({ leave }: { leave?: () => void }) {
  const { progress, go: goTo, setSettings } = useApp();
  const go: typeof goTo = (...a) => { leave?.(); goTo(...a); };
  const st = readSettings(progress.settings);
  const set = (patch: Partial<Settings>) => setSettings(patch);
  const g = progress.grade;
  const onOff = (on: boolean) => (on ? "On" : "Off");
  const motion = st.motion === "reduce" ? "Less" : "Full", motionNext = st.motion === "reduce" ? "Full" : "Less";
  const side = st.leftHanded ? "Left" : "Right", sideNext = st.leftHanded ? "Right" : "Left";
  const read = readAloudOn(st, g);
  return <>
    <h2 className="o-head o-in o-shead">Settings</h2>
    <div className="o-sgrid">
      <WTile icon="circle-half" name="Look">
        <OSlider tabs={[{ id: "auto", label: "Auto" }, { id: "light", label: "Light" }, { id: "dark", label: "Dark" }]} value={st.look} onPick={v => set({ look: v })} label="Look" />
      </WTile>
      <WTile icon="text-aa" name="Text size">
        <OSlider tabs={[{ id: "small", label: "Small" }, { id: "standard", label: "Medium" }, { id: "large", label: "Large" }]} value={st.text} onPick={v => set({ text: v })} label="Text size" />
      </WTile>
      <STile icon="eye" name="High contrast" value={onOff(st.contrast)} on={st.contrast} sw onClick={() => set({ contrast: !st.contrast })} />
      <STile icon="text-t" name="Easy letters" value={onOff(st.readable)} on={st.readable} sw onClick={() => set({ readable: !st.readable })} />
      <STile icon="palette" name="Colour-blind" value={onOff(st.colorSafe)} on={st.colorSafe} sw onClick={() => set({ colorSafe: !st.colorSafe })} />
      <STile icon="speaker-high" name={SETTING.readAloud} value={onOff(read)} on={read} sw onClick={() => { set({ readAloud: !read }); if (!read) speak("Read aloud is on."); }} />
      <STile icon="music-notes" name={SETTING.sounds} value={onOff(st.sounds)} on={st.sounds} sw onClick={() => { set({ sounds: !st.sounds }); if (!st.sounds) playTone("right"); }} />
      <STile icon="sparkle" name="Motion" value={motion} label={`Motion: ${motion}. Tap for ${motionNext}`} onClick={() => set({ motion: st.motion === "reduce" ? "system" : "reduce" })} />
      {/* phones say "Keypad"; the iPad has room for "Keypad side" (G 2026-10-14) */}
      <STile icon="dots-nine" name={<>Keypad<span className="o-nsx"> side</span></>} value={side} label={`Keypad side: ${side}. Tap for ${sideNext}`} onClick={() => set({ leftHanded: !st.leftHanded })} />
      <STile icon="graduation-cap" name="Grade" value={g != null ? gradeOf(g).name : "Choose"} onClick={() => { setBoxView(GRADES_VIEW); go({ name: "home" }, "back"); }} />
      {g != null && <STile icon="target" name={FIND_MY_LEVEL} value="Start a check" onClick={() => go({ name: "settings", page: "level" }, "fwd")} />}
      <STile icon="cloud-arrow-up" name="Backup" value="Save, restore" onClick={() => go({ name: "settings", page: "backup" }, "fwd")} />
      <STile icon="info" name="About" value="What it is" onClick={() => go({ name: "settings", page: "about" }, "fwd")} />
    </div>
  </>;
}

function SubPage({ page }: { page: SettingsPage }) {
  const { progress, exportBackup, importBackup, startTest, go } = useApp();
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
  const head = <h2 className="o-head o-in">{SETTINGS_PAGE_NAME[page]}</h2>;
  if (page === "backup") return <>
    {head}
    <div className="o-setrows">
      <Row name="Save a backup"><button className="o-btn o-sb" onClick={save}>Save</button></Row>
      <Row name="Restore a backup"><button className="o-btn o-sb" onClick={() => file.current?.click()}>Restore</button></Row>
    </div>
    <p className="o-small o-in">A backup is one file with every lesson, check and setting. Everything stays on this device. No account, no ads, no data collected.</p>
    <input ref={file} type="file" accept="application/json,.json" hidden onChange={e => void load(e.target.files?.[0])} />
  </>;
  if (page === "level") return <>
    {head}
    <p className="o-in">A short check finds where you are. About 12 problems and 10 minutes, with no hints. You can stop at any time.</p>
    <div className="o-setrows">
      <Row name={FIND_MY_LEVEL}><button className="o-btn o-sb fill" disabled={g == null} onClick={() => { if (g != null) startTest(placeKey(g)); }}>Start</button></Row>
    </div>
  </>;
  return <>
    {head}
    <p className="o-in">Obento shows you why the maths works, then practises it with you every day until it sticks.</p>
    <div className="o-setrows">
      <Row name="See it"><span className="o-small">A picture shows why</span></Row>
      <Row name="Do it"><span className="o-small">You practise with steps</span></Row>
      <Row name="Keep it"><span className="o-small">Short checks bring it back</span></Row>
      {/* the website from inside the app (kept from v63; the model's own "This model" row never ships) */}
      <Row name="The website"><button className="o-btn o-sb" onClick={() => go({ name: "welcome" }, "back")} aria-label="What Obento is">Open</button></Row>
      {SANDBOX && <Row name="Sandbox (preview only)"><button className="o-btn o-sb" onClick={() => { go({ name: "home" }, "back"); dispatchEvent(new Event("bento:sandbox")); }}>Open</button></Row>}
    </div>
  </>;
}

const KEYS = ["7", "8", "9", "4", "5", "6", "1", "2", "3", "0", ".", "⌫"];

/**
 * The preview (iPad only): a real lesson, small. Its keypad types, so a child can try an answer and see the text size,
 * look, letters, colour-blind and keypad side change. Phones have no room for it: there the whole app changes at once.
 */
function Preview() {
  const [ans, setAns] = useState("");
  const key = (k: string) => setAns(a => (k === "⌫" ? a.slice(0, -1) : (a + k).slice(0, 6)));
  return (
    <section className="o-panel o-spv" aria-label="Try it">
      <span className="o-label o-in">Try it</span>
      <h2 className="o-head o-in">How lessons look to you</h2>
      <div className="o-pv">
        <div className="o-pvq"><span className="o-pvprob">¾ + ⅛ = ?</span><span className="o-small">Add the fractions. Try the keypad.</span></div>
        <svg className="o-pvpic" viewBox="0 0 340 168" preserveAspectRatio="xMidYMid meet" aria-hidden="true">
          <defs><pattern id="o-cbh" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="3" height="8" /></pattern></defs>
          {Array.from({ length: 8 }, (_, i) => (
            <rect key={i} className={i < 6 ? "pa" : i < 7 ? "pb" : "pc"} x={2 + (i % 4) * 86} y={2 + Math.floor(i / 4) * 86} width="78" height="78" rx="12" />
          ))}
          <rect className="pbh" x="174" y="88" width="78" height="78" rx="12" />
        </svg>
        <div className="o-pvw">
          <div className="o-pva" aria-live="polite"><span className="v">{ans}</span></div>
          <div className="o-pvk">
            {KEYS.map(k => <button key={k} className="o-key" onClick={() => key(k)} aria-label={k === "⌫" ? "Delete" : undefined}>{k}</button>)}
          </div>
        </div>
      </div>
    </section>
  );
}
