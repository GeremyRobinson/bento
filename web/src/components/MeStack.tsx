import { useEffect, type CSSProperties, type ReactNode } from "react";
import { useApp } from "../app/AppState";
import { doneCount, entriesInGrade, testKey, unitsInGrade } from "../app/curriculum";
import { readSettings, type Settings } from "../app/settings";
import { upNext } from "../app/today";
import { gradeOf } from "../curriculum/grades";
import { LEVELS } from "../engine/mastery/levels";
import { GROWN_UP, NO_UNIT, SETTING } from "../app/copy";

const LockIcon = () => (
  <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden><rect x="5" y="10.5" width="14" height="9.5" rx="2.5" /><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5" /></svg>
);

/** A chapter's 0-4 score as a four-cell battery, the same fill the book uses. */
function ChapterBattery({ score }: { score: number }) {
  return <span className="cbat" aria-hidden>{[0, 1, 2, 3].map(i => <i key={i} className={i < score ? "on" : ""} />)}</span>;
}

/**
 * Me (Design's RedesignMe spec, G 2026-10-06): not a page but a floating stack over whatever screen is open, under the
 * Me circle. Your grade, your progress, the current chapter, the settings that matter and the access switches, then
 * the grown-up page. Everything stays on this device. The full Me page (backup, every setting) is one pill away.
 */
export function MeStack({ close, closing }: { close: () => void; closing: boolean }) {
  const { progress, setSettings, go, openSheet } = useApp();
  const s = readSettings(progress.settings), g = progress.grade ?? 0, d = gradeOf(g);
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") close(); };
    addEventListener("keydown", onKey);
    return () => removeEventListener("keydown", onKey);
  }, [close]);

  const all = entriesInGrade(g), done = doneCount(progress, all);
  const chapters = unitsInGrade(g).filter(u => u.name !== NO_UNIT);
  const next = upNext(progress, g)?.entry;
  const ci = Math.max(0, chapters.findIndex(u => u.name === (next?.unit || NO_UNIT)));
  const chapter = chapters[ci];
  const score = chapter ? progress.tests[testKey(g, chapter.name)]?.best ?? 0 : 0;

  let i = 0;
  const at = () => ({ "--i": i++ }) as CSSProperties;
  const toggle = (label: string, on: boolean, flip: Partial<Settings>) => (
    <button key={label} className="fpill toggle" role="switch" aria-checked={on} onClick={() => setSettings(flip)} style={at()}>
      {label}<span className="sw" />
    </button>
  );
  const row = (...kids: ReactNode[]) => <div className="frow">{kids}</div>;
  const leave = (f: () => void) => () => { close(); f(); };
  const stat = (n: string, unit: string) => <><b>{n}</b><span className="funit">{unit}</span></>;

  return (
    <>
      <div className={`fdim fblur${closing ? " out" : ""}`} onClick={close} />
      <div className={`fstack qset mset${closing ? " out" : ""}`} role="dialog" aria-label="Me" style={{ "--n": 16 } as CSSProperties}>
        <span className="flbl" style={at()}>Your grade</span>
        {row(
          <span key="g" className="fpill fgrade" style={at()}><b className="gn">{d.name.split(" ")[0]}</b>{g ? "grade" : null}</span>,
          <button key="sw" className="fpill" onClick={leave(() => openSheet(true))} style={at()}>Switch grade</button>,
        )}
        <span className="flbl" style={at()}>Your progress</span>
        {row(
          <span key="l" className="fpill" style={at()}>{stat(`${done} of ${all.length}`, "lessons")}</span>,
          <span key="s" className="fpill" style={at()}>{stat(`${progress.streak}-day`, "streak")}</span>,
          <span key="x" className="fpill" style={at()}>{stat(progress.xp.toLocaleString("en-US"), "XP")}</span>,
        )}
        {row(
          <span key="r" className="fpill rew" style={at()}><span className="ftag">Placeholder</span>Rewards</span>,
          chapter && (
            <span key="c" className="fpill fchap" style={at()} aria-label={`Chapter ${ci + 1}, ${score} of 4, ${LEVELS[score]}`}>
              Chapter {ci + 1}<ChapterBattery score={score} /><span className="funit">{score} of 4</span>
            </span>
          ),
        )}
        <span className="flbl" style={at()}>Settings</span>
        {row(
          toggle(SETTING.sounds, s.sounds, { sounds: !s.sounds }),
          toggle(SETTING.motion, s.motion === "reduce", { motion: s.motion === "reduce" ? "system" : "reduce" }),
        )}
        <span className="flbl" style={at()}>Make it work for you</span>
        {row(
          toggle("Bigger text", s.text !== "standard", { text: s.text === "standard" ? "large" : "standard" }),
          toggle("High contrast", s.contrast, { contrast: !s.contrast }),
        )}
        {row(
          toggle(SETTING.colorSafe, s.colorSafe, { colorSafe: !s.colorSafe }),
          toggle("Left-handed keypad", s.leftHanded, { leftHanded: !s.leftHanded }),
        )}
        <div className="frow fgap">
          <button className="fpill" onClick={leave(() => go({ name: "parent" }, "fwd"))} style={at()}>{GROWN_UP} ›</button>
          <button className="fpill" onClick={leave(() => go({ name: "me" }, "fwd"))} style={at()}>All settings and backup ›</button>
        </div>
        <span className="fpill fnote" style={at()}><LockIcon />On this device. No account, no data collected.</span>
      </div>
    </>
  );
}
