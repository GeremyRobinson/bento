import { Pill } from "../components/primitives/Pill";
import { useRef, type CSSProperties, type ReactNode } from "react";
import { useApp } from "../app/AppState";
import { readAloudOn, readSettings, speak, playTone, type Settings } from "../app/settings";
import { gradeOf, tintStyle } from "../curriculum/grades";
import { LEVEL_XP } from "../engine/mastery/levels";
import { GradeLineup } from "../components/GradeLineup";
import { placeKey } from "../engine/session/practice";
import { gradeLevel } from "../components/primitives/Score";
import { Fill, GradeNum } from "../components/Shelf";

function Toggle({ label, note, on, set }: { label: string; note: string; on: boolean; set: (v: boolean) => void }) {
  return (
    <button className="mtoggle" role="switch" aria-checked={on} onClick={() => set(!on)}>
      <span className="mt-text"><b>{label}</b><small>{note}</small></span>
      <span className="switch" aria-hidden><i /></span>
    </button>
  );
}

function Tile({ k, title, className = "", children }: { k?: string; title: string; className?: string; children: ReactNode }) {
  return (
    <section className={`tile mtile ${className}`}>
      {k && <span className="k">{k}</span>}
      <h2>{title}</h2>
      {children}
    </section>
  );
}

/**
 * The personal hub: everything about you in one place. Your grades and levels, how you're doing, the report for
 * your grown-up, settings that make Bento easier to see and hear, and backups. Nothing leaves this device.
 */
export function Me() {
  const { progress, go, chooseGrade, setSettings, exportBackup, importBackup, startTest } = useApp();
  const st = readSettings(progress.settings);
  const set = (patch: Partial<Settings>) => setSettings(patch);
  // before a grade is chosen the hub stays neutral and asks for one; nothing assumes a grade
  const g = progress.grade, grade = g == null ? null : gradeOf(g), gxp = g == null ? 0 : progress.gxp[g] ?? 0, { lvl, into } = gradeLevel(gxp);
  const lessonsDone = Object.keys(progress.lessons).length;
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
    <>
      <div className="bme">
        <section className="tile mhero battery" style={grade ? tintStyle(grade) as CSSProperties : undefined}>
          {grade ? <>
            <Fill frac={into / LEVEL_XP} />
            {/* only grades get the big colored number; the level is words and the fill */}
            <span className="bbig"><GradeNum grade={g!} /></span>
            <div className="mh-text">
              <span className="k">Level {lvl}</span>
              <h1>Your Bento</h1>
              <p className="muted">{into} of {LEVEL_XP} XP to level {lvl + 1}</p>
            </div>
          </> : (
            <div className="mh-text">
              <h1>Your Bento</h1>
              <p className="muted">Choose your grade to start. You can change it any time.</p>
              <Pill go onClick={() => go({ name: "welcome", shelf: true }, "fwd")}>Choose your grade</Pill>
            </div>
          )}
          <div className="mstats">
            <div><b className="mono">{progress.streak}</b><span>day streak</span></div>
            <div><b className="mono">{progress.xp}</b><span>XP in all</span></div>
            <div><b className="mono">{lessonsDone}</b><span>lesson{lessonsDone === 1 ? "" : "s"} done</span></div>
          </div>
        </section>

        <Tile title="Your grades" className="mgrades">
          {g != null && <button className="tlink" onClick={() => startTest(placeKey(g))}>Find my level ›</button>}
          <GradeLineup onPick={chooseGrade} />
        </Tile>

        <Tile title="See and hear" k="Accessibility" className="macc">
          <div className="mseg" role="radiogroup" aria-label="Text size">
            <span className="mt-text"><b>Text size</b><small>Bigger words, numbers and buttons</small></span>
            <span className="seg">
              {(["standard", "large", "largest"] as const).map((v, i) => (
                <button key={v} role="radio" aria-checked={st.text === v} className={st.text === v ? "on" : ""} onClick={() => set({ text: v })}
                  aria-label={["Standard", "Large", "Largest"][i]}><span style={{ fontSize: 14 + i * 4 }}>A</span></button>
              ))}
            </span>
          </div>
          <Toggle label="High contrast" note="Darker text and stronger lines" on={st.contrast} set={v => set({ contrast: v })} />
          <Toggle label="Color-blind friendly" note="Blue and orange for right and wrong" on={st.colorSafe} set={v => set({ colorSafe: v })} />
          <Toggle label="Easy-to-read letters" note="Plainer, wider letters" on={st.readable} set={v => set({ readable: v })} />
          <Toggle label="Less motion" note="No sliding or bouncing; pictures show finished" on={st.motion === "reduce"} set={v => set({ motion: v ? "reduce" : "system" })} />
          <Toggle label="Read aloud" note="Reads each step and problem out loud" on={readAloudOn(st, progress.grade)} set={v => { set({ readAloud: v }); if (v) speak("Read aloud is on."); }} />
          <Toggle label="Sounds" note="A soft tone for right and wrong answers" on={st.sounds} set={v => { set({ sounds: v }); if (v) playTone("right"); }} />
        </Tile>

        <Tile title="For the grown-up" k="Report" className="mgrown">
          <p className="muted">Scores by grade, the exact mistakes made, hints used and every session, so you know what to work on next.</p>
          <Pill go onClick={() => go({ name: "parent" }, "fwd")}>Open the report ›</Pill>
        </Tile>

        <Tile title="Keep your progress" k="Backup" className="mbackup">
          <p className="muted">Everything stays on this device. Save a backup file to move it to another one.</p>
          <div className="actions">
            <Pill onClick={save}>Save a backup</Pill>
            <Pill onClick={() => file.current?.click()}>Restore</Pill>
          </div>
          <input ref={file} type="file" accept="application/json,.json" hidden onChange={e => void load(e.target.files?.[0])} />
        </Tile>
      </div>
    </>
  );
}
