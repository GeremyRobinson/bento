import { Pill } from "./primitives/Pill";
import { Slider } from "./primitives/Slider";
import { useEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { doneCount, isReady, testKey, testReady, unitsInGrade, type Entry } from "../app/curriculum";
import { upNext } from "../app/today";
import { gradeOf } from "../curriculum/grades";
import type { Rng } from "../curriculum/generators/rng";
import { lastScore } from "../engine/mastery/progress";
import { showcasePicture } from "../screens/Welcome";
import { PlayingDiagram } from "./diagrams/PlayingDiagram";
import { ScoreChip } from "./primitives/Score";
import { Fill, Shelf } from "./Shelf";
import { CONTENTS, lessonCount, NO_UNIT, THIS_YEAR, YOUR_BENTO } from "../app/copy";
import { MeHub } from "../screens/Me";
import { MeIcon, SettingsIcon } from "./primitives/icons";
import { SettingsBody } from "../screens/Settings";

/**
 * Where the hub is: zoomed out to one chapter's pages, the whole year, or every grade on the shelf; or on you (My
 * Obento) or Settings (G 2026-10-08: the nav is the hub for options, like the Dynamic Island).
 */
export type Level = "chapter" | "year" | "shelf" | "me" | "settings";
const LEVELS: Level[] = ["chapter", "year", "shelf"];
const NAMES: Record<Level, string> = { chapter: "Chapter", year: "Year", shelf: "All grades", me: YOUR_BENTO, settings: "Settings" };
const zoomed = (l: Level) => LEVELS.includes(l);

/** A chapter's picture, from a fresh problem of its first lesson that has one: finished at rest, a tap plays it. */
export function ChapterPic({ entries, rng }: { entries: Entry[]; rng: Rng }) {
  const ex = useMemo(() => {
    for (const c of entries) { const pic = isReady(c.id) ? showcasePicture(c.id, rng) : null; if (pic) return pic; }
    return null;
  }, [entries, rng]);
  const [replay, setReplay] = useState(0);
  return ex ? <div className="cpic" onClick={() => setReplay(r => r + 1)}><PlayingDiagram ex={ex} replay={replay} autoplay={false} /></div> : null;
}

/**
 * The contents: the book zoomed out. Pinch closed (or tap a level) to step out from the chapter you're in, to the
 * year, to every grade; pinch open or tap a chapter to step back in. Whatever you tap opens right there.
 */
export function Contents({ grade, lessonId, level: first, close, leave = close, closing }: { grade: number; lessonId?: string; level: Level; close: () => void;
  /** closes because a page is opening from here: no close animation, the page change carries it */ leave?: () => void; closing?: boolean }) {
  const { progress, go, chooseGrade, startTest, deps } = useApp();
  const rng = useMemo(() => deps().rng, []); // eslint-disable-line react-hooks/exhaustive-deps
  const units = unitsInGrade(grade);
  const here = lessonId ? units.find(u => u.entries.some(c => c.id === lessonId)) : undefined;
  const next = upNext(progress, grade);
  const [chapter, setChapter] = useState(here?.name ?? units.find(u => u.entries.some(c => c.id === next?.entry.id))?.name ?? units[0]?.name);
  const [level, setLevel] = useState<Level>(first);
  // which way the last step went, so the new level grows in from the old one (out) or comes forward (in)
  const [way, setWay] = useState<"out" | "in" | "">("");
  // All grades is the outermost level, inside the contents (Review nav #5): the slider's thumb lands there, never out
  const to = (l: Level) => { if (l === level) return; setWay(!zoomed(l) || !zoomed(level) ? "" : LEVELS.indexOf(l) > LEVELS.indexOf(level) ? "out" : "in"); setLevel(l); };
  const box = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = box.current!;
    el.querySelector<HTMLElement>(".zlevels>button[aria-pressed=true]")?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") close();
      else if (!zoomed(level)) return;
      else if (e.key === "-" || e.key === "_") to(LEVELS[Math.min(2, LEVELS.indexOf(level) + 1)]!);
      else if (e.key === "=" || e.key === "+") to(LEVELS[Math.max(0, LEVELS.indexOf(level) - 1)]!);
    };
    // pinch closed to zoom out, open to zoom in; past the chapter, opening closes the contents onto the page
    let d0 = 0;
    const dist = (t: TouchList) => Math.hypot(t[0]!.clientX - t[1]!.clientX, t[0]!.clientY - t[1]!.clientY);
    const onStart = (e: TouchEvent) => { d0 = e.touches.length === 2 ? dist(e.touches) : 0; };
    const onMove = (e: TouchEvent) => {
      if (!d0 || e.touches.length !== 2 || !zoomed(level)) return;
      e.preventDefault();
      const r = dist(e.touches) / d0;
      if (r < 0.7) { d0 = 0; to(LEVELS[Math.min(2, LEVELS.indexOf(level) + 1)]!); }
      else if (r > 1.4) { d0 = 0; if (level === "chapter") close(); else to(LEVELS[LEVELS.indexOf(level) - 1]!); }
    };
    // a trackpad pinch arrives as a wheel with ctrl held
    let acc = 0;
    const onWheel = (e: WheelEvent) => {
      if (!e.ctrlKey || !zoomed(level)) return;
      e.preventDefault();
      acc += e.deltaY;
      if (acc > 40) { acc = 0; to(LEVELS[Math.min(2, LEVELS.indexOf(level) + 1)]!); }
      else if (acc < -40) { acc = 0; if (level === "chapter") close(); else to(LEVELS[LEVELS.indexOf(level) - 1]!); }
    };
    addEventListener("keydown", onKey);
    el.addEventListener("touchstart", onStart, { passive: true });
    el.addEventListener("touchmove", onMove, { passive: false });
    el.addEventListener("wheel", onWheel, { passive: false });
    return () => { removeEventListener("keydown", onKey); el.removeEventListener("touchstart", onStart); el.removeEventListener("touchmove", onMove); el.removeEventListener("wheel", onWheel); };
  });

  const open = (c: Entry) => { leave(); go({ name: "learn", lessonId: c.id }, "fwd"); };
  const unit = units.find(u => u.name === chapter) ?? units[0];
  const g = gradeOf(grade);

  let body;
  if (level === "chapter" && unit) {
    const k = units.indexOf(unit), tk = testKey(grade, unit.name), t = progress.tests[tk];
    body = (
      <section className="zchapter">
        <ChapterPic key={unit.name} entries={unit.entries} rng={rng} />
        <div className="zctext">
          <span className="k">{units.length > 1 ? `Chapter ${k + 1} of ${units.length}` : THIS_YEAR} · {g.name}</span>
          <h2>{unit.name === NO_UNIT ? g.name : unit.name}</h2>
          <ol className="zpages">{unit.entries.map((c, i) => {
            const s = lastScore(progress, c.id), live = isReady(c.id), on = c.id === lessonId;
            return (
              <li key={c.id}>
                <button className={on ? "on" : ""} disabled={!live} onClick={() => open(c)} aria-current={on ? "page" : undefined}>
                  <span className="pn">{i + 1}</span><span className="name">{c.title}</span>
                  {s != null ? <ScoreChip n={s} /> : on ? <span className="dot busy" aria-label="you're here" /> : c === next?.entry ? <span className="muted">Up next</span> : live ? null : <span className="muted">soon</span>}
                </button>
              </li>
            );
          })}</ol>
          {testReady(grade, unit.name) && units.length > 1 && (
            <Pill onClick={() => { leave(); startTest(tk); }}>{t && <ScoreChip n={t.last} />}{unit.name} test</Pill>
          )}
        </div>
      </section>
    );
  } else if (level === "year") {
    body = (
      <section className="zyear">
        <header><span className="k">{g.subtitle}</span><h2>{g.name}</h2>
          <Pill go onClick={() => { leave(); go({ name: "home" }, "back"); }}>Open the year ›</Pill></header>
        <div className="zch" style={{ "--cols": units.length <= 4 ? units.length : Math.ceil(units.length / 2) } as CSSProperties}>{units.map((u, k) => {
          const done = doneCount(progress, u.entries), on = u.name === here?.name;
          return (
            <button key={u.name} className={`zcard battery${on ? " on" : ""}`} style={{ "--i": k } as CSSProperties} onClick={() => { setChapter(u.name); to("chapter"); }}>
              <span className="k">{units.length > 1 ? `Chapter ${k + 1}` : THIS_YEAR}</span>
              <b>{u.name === NO_UNIT ? g.name : u.name}</b>
              <Fill frac={u.entries.length ? done / u.entries.length : 0} />
              <span className="bcount">{lessonCount(done, u.entries.length)}</span>
            </button>
          );
        })}</div>
      </section>
    );
  } else if (level === "me") {
    body = <MeHub leave={leave} toGrades={() => to("shelf")} />;
  } else if (level === "settings") {
    body = <SettingsBody leave={leave} />;
  } else {
    body = (
      <section className="zshelf">
        <Shelf current={grade} onPick={n => { leave(); chooseGrade(n); }} />
        <button className="tlink" onClick={() => { leave(); go({ name: "welcome" }, "back"); }}>About Obento ›</button>
      </section>
    );
  }

  return (
    <div className={`zoom${closing ? " closing" : ""}`} ref={box} role="dialog" aria-modal="true" aria-label={zoomed(level) ? CONTENTS : NAMES[level]} onClick={e => { if (e.target === e.currentTarget) close(); }}>
      <div className="zbar-top">
        {/* no wordmark inside the app (G 2026-10-08), the hub's bar included */}
        <span />
        {/* widest to narrowest, left to right (G 2026-10-06); a tap slider, the same master as Bento / Bento² */}
        <Slider className="zlevels" label="Zoom" value={level as "chapter" | "year" | "shelf"} onPick={to}
          options={[...LEVELS].reverse().map(l => ({ id: l, label: NAMES[l], disabled: l === "chapter" && !unit }))} />
        {/* the hub's other rooms sit where the nav keeps them: the gear and the person, filled when you're there */}
        <span className="zrooms">
          <button className={`icon${level === "settings" ? " on" : ""}`} aria-pressed={level === "settings"} aria-label="Settings" onClick={() => to("settings")}><SettingsIcon /></button>
          <button className={`icon${level === "me" ? " on" : ""}`} aria-pressed={level === "me"} aria-label={YOUR_BENTO} onClick={() => to("me")}><MeIcon /></button>
          <Pill className="zclose" onClick={close}>Done</Pill>
        </span>
      </div>
      <div className={`zstage ${way}`} key={level + (level === "chapter" ? chapter : "")}>{body}</div>
      {zoomed(level) && <p className="zhint muted">Pinch to zoom in and out</p>}
    </div>
  );
}
