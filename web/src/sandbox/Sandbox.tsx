import { useEffect, useMemo, useState } from "react";
import { useApp } from "../app/AppState";
import { tintOf } from "../app/tint";
import { bandOf, GRADES, gradeOf } from "../curriculum/grades";
import { lessonById, lessonsInGrade, unitsOf } from "../curriculum/registry";
import { createRng, randomSeed } from "../curriculum/generators/rng";
import { Diagram } from "../components/diagrams/Diagram";
import { firstExample } from "../screens/Learn";
import type { AnyLesson } from "../curriculum/schemas/lesson";
import type { Explanation } from "../explanations/schema";
import { BAND_NAMES, DIAGRAM_TOKENS, PILL_TOKENS, SURFACE_TOKENS, emptyOverrides, GRADE_TOKENS, handoffCss, MASTER, MASTER_GRADE, overrideCss, overridesOf, readGrade, SHARED_TOKENS, SIZE_TOKENS, toHex, type Overrides, type Token } from "./tokens";
import { get, set, useSb } from "./store";
import "./sandbox.css";

/** A fresh problem's explanation for a lesson that draws a picture, or null when none of the tries draw one. */
function pictureOf(lesson: AnyLesson, seed: number): Explanation | null {
  const rng = createRng(seed);
  for (let i = 0; i < 4; i++) {
    try { const p = firstExample(lesson, rng), ex = lesson.explain(p, lesson.answers(p)); if (ex.diagram) return ex; } catch { /* next try */ }
  }
  return null;
}

/** The lesson a grade's tile shows: a random one that draws a picture. */
function pickLesson(g: number, seed: number): { lesson: AnyLesson; ex: Explanation } | null {
  const ls = lessonsInGrade(g), rng = createRng(seed + g * 7919);
  const order = ls.map(l => [rng.next(), l] as const).sort((a, b) => a[0] - b[0]).map(x => x[1]);
  for (const lesson of order.slice(0, 12)) { const ex = pictureOf(lesson, seed + g); if (ex) return { lesson, ex }; }
  return null;
}

/**
 * The sandbox board (#/sandbox): every grade as one tile built from the real pieces (a lesson's live picture,
 * the step dots, the Check button, the grade number), so a token change shows across K-12 at once.
 */
export function SandboxBoard() {
  const { go } = useApp();
  const { seed, grade, mode, o } = useSb();
  const tiles = useMemo(() => GRADES.map(d => ({ g: d.grade, pick: pickLesson(d.grade, seed) })), [seed]);
  // the master shows a 5th grade picture, the way every grade draws before it brings its own colors
  const masterPick = useMemo(() => pickLesson(5, seed + 1), [seed]);
  useEffect(() => { if (!get().open) set({ open: true }); }, []);
  // what each instance overrides, read back from the page after the edits land
  const [over, setOver] = useState<Record<number, number>>({});
  useEffect(() => { const t = setTimeout(() => setOver(Object.fromEntries(GRADES.map(d => [d.grade, overridesOf(String(d.grade)).size]))), 0); return () => clearTimeout(t); }, [o]);
  const tile = (key: string, dataGrade: string, band: string, tint: number, num: string, name: string, sub: string, note: string, pick: { lesson: AnyLesson; ex: Explanation } | null, focus: boolean, onClick: () => void) => (
    <section key={key} className={`wrap t${tint} sbt${focus ? " focus" : ""}${dataGrade === MASTER_GRADE ? " master" : ""}`} data-grade={dataGrade} data-band={band}>
      <button className="panel sbt-in" onClick={onClick}>
        <div className="sbt-head">
          <span className="sbt-num">{num}</span>
          <span className="sbt-name"><b>{name}</b><small className="muted">{sub}</small></span>
        </div>
        <div className="card sbt-pic">
          {pick?.ex.diagram ? <Diagram diagram={pick.ex.diagram} timeline={pick.ex.timeline} at={pick.ex.timeline.length - 1} /> : <p className="muted">No picture</p>}
        </div>
        <div className="sbt-row">
          <span className="steps"><span className="dot ok" /><span className="dot ok" /><span className="dot busy" /><span className="dot" /></span>
          <span className="ctl go">Check</span>
        </div>
        <div className="sbt-sw">{["c0", "c1", "c2", "acc"].map(c => <i key={c} style={{ background: `var(--${c})` }} title={c} />)}<span className="sbt-ink">Aa</span></div>
        <div className="sbt-note muted">{note}</div>
      </button>
    </section>
  );
  return (
    <div className="sbboard">
      <header className="sbhead">
        <h1>Sandbox</h1>
        <p className="muted">One Grade component, thirteen instances. Each grade passes only its colors, its band look, its name and its lessons; everything else comes from the master. Tap the master to edit it, or a grade to open its lesson.</p>
      </header>
      <div className="sbgrid">
        {tile("master", MASTER_GRADE, "kid", 0, "G", "Grade (master)", "Every grade below is an instance of this", "Edit it and all 13 follow, except what a grade overrides", masterPick, mode === "master", () => set({ mode: "master" }))}
        {tiles.map(({ g, pick }) => tile(String(g), String(g), bandOf(g), pick ? tintOf(pick.lesson) : 0, gradeOf(g).short, gradeOf(g).name, pick?.lesson.title ?? "No picture yet",
          `Overrides ${over[g] ?? "…"} of ${GRADE_TOKENS.length} colors · ${BAND_NAMES[bandOf(g)]} · ${lessonsInGrade(g).length} lessons`,
          pick, mode === "grade" && g === grade, () => { set({ grade: g, mode: "grade" }); if (pick) go({ name: "learn", lessonId: pick.lesson.id }, "fwd"); }))}
      </div>
    </div>
  );
}

const SCREENS = ["Board", "Landing", "Home", "Lesson", "Practice", "Me"] as const;
type ScreenName = (typeof SCREENS)[number];

/** The floating sandbox panel: which screen, grade and lesson to look at, light or dark, and the tokens. */
export function Sandbox() {
  const app = useApp();
  const { route, progress, go, chooseGrade, startLesson } = app;
  const sb = useSb();
  const [copy, setCopy] = useState(false);

  // the theme the sandbox shows; the app itself has no switch, so this lives only here
  useEffect(() => { document.documentElement.dataset.theme = sb.theme; }, [sb.theme]);
  // the edits, layered over the real stylesheets
  useEffect(() => {
    let el = document.getElementById("sb-tokens") as HTMLStyleElement | null;
    if (!el) { el = document.createElement("style"); el.id = "sb-tokens"; document.head.appendChild(el); }
    el.textContent = overrideCss(sb.o);
  }, [sb.o]);
  // the grade follows the lesson on screen
  const shownLesson = route.name === "learn" ? lessonById(route.lessonId) : undefined;
  useEffect(() => { if (shownLesson && shownLesson.grade !== get().grade) set({ grade: shownLesson.grade }); }, [shownLesson]);

  const g = sb.grade;
  const lessonId = shownLesson?.grade === g ? shownLesson.id : lessonsInGrade(g)[0]?.id;
  const screen: ScreenName = route.name === "sandbox" ? "Board" : route.name === "welcome" ? "Landing" : route.name === "home" ? "Home"
    : route.name === "learn" ? "Lesson" : route.name === "practice" || route.name === "results" ? "Practice" : route.name === "me" ? "Me" : "Board";

  const show = (s: ScreenName, grade = g, id = lessonId) => {
    const first = lessonsInGrade(grade)[0]?.id;
    const lid = id && lessonById(id)?.grade === grade ? id : first;
    switch (s) {
      case "Board": go({ name: "sandbox" }); break;
      case "Landing": go({ name: "welcome" }); break;
      case "Home": if (progress.grade !== grade || route.name !== "home") chooseGrade(grade); break;
      case "Lesson": if (lid) go({ name: "learn", lessonId: lid }); break;
      case "Practice": if (lid) startLesson(lid); break;
      case "Me": if (progress.grade !== grade) chooseGrade(grade); go({ name: "me" }); break;
    }
  };
  const pickGrade = (n: number) => { set({ grade: n }); if (screen !== "Board" && screen !== "Landing") show(screen, n, undefined); };

  // current values, read from the page (stylesheets plus edits) for the focused grade and theme
  const master = sb.mode === "master";
  const [values, setValues] = useState<Record<string, string>>({});
  const [masterValues, setMasterValues] = useState<Record<string, string>>({});
  const [over, setOver] = useState<Set<string>>(new Set());
  useEffect(() => {
    if (!sb.open) return;
    const root = getComputedStyle(document.documentElement), out = readGrade(String(g));
    for (const t of SHARED_TOKENS) out[t.v] = root.getPropertyValue(t.v).trim();
    setValues(out); setMasterValues(readGrade(MASTER_GRADE)); setOver(overridesOf(String(g)));
  }, [sb.open, g, sb.theme, sb.o, sb.mode]);

  type Scope = "master" | "grade" | "shared" | "sizes";
  const edit = (scope: Scope, v: string, val: string | null) => {
    const o: Overrides = { master: { ...sb.o.master }, shared: { light: { ...sb.o.shared.light }, dark: { ...sb.o.shared.dark } }, sizes: { ...sb.o.sizes }, grades: { ...sb.o.grades, [g]: { ...sb.o.grades[g] } } };
    const bag = scope === "master" ? o.master : scope === "grade" ? o.grades[g]! : scope === "shared" ? o.shared[sb.theme] : o.sizes;
    if (val == null) delete bag[v]; else bag[v] = val;
    set({ o });
  };
  const bagOf = (scope: Scope) => (scope === "master" ? sb.o.master ?? {} : scope === "grade" ? sb.o.grades[g] ?? {} : scope === "shared" ? sb.o.shared[sb.theme] : sb.o.sizes);
  const changed = (scope: Scope, v: string) => v in bagOf(scope);
  const resetToMaster = () => edit2(Object.fromEntries(GRADE_TOKENS.filter(t => over.has(t.v)).map(t => [t.v, MASTER])));
  const edit2 = (vals: Record<string, string>) => set({ o: { ...sb.o, grades: { ...sb.o.grades, [g]: { ...sb.o.grades[g], ...vals } } } });

  if (!sb.open) return <button className="sbtoggle" onClick={() => set({ open: true })}>Sandbox</button>;

  const row = (scope: Scope, t: Token) => {
    const cur = (scope === "master" ? masterValues : values)[t.v] ?? "";
    const overrides = scope === "grade" && over.has(t.v);
    return (
      <label key={t.v} className={`sbtok${changed(scope, t.v) ? " on" : ""}`}>
        <span className="sbtok-name">{t.label}<small>{scope === "grade" ? (overrides ? "overrides master" : "from master") : scope === "master" ? `--master-${t.v.slice(2)}` : t.v}</small></span>
        {t.kind === "color"
          ? <input type="color" value={toHex(cur) ?? "#000000"} onChange={e => edit(scope, t.v, e.target.value)} />
          : <input type="range" min={t.min} max={t.max} step={t.step ?? 1} value={parseFloat(cur) || t.min} onChange={e => edit(scope, t.v, `${e.target.value}${t.kind === "px" ? "px" : t.kind === "pct" ? "%" : ""}`)} />}
        <span className="sbtok-val">{t.kind === "color" ? toHex(cur) ?? cur : (isNaN(parseFloat(cur)) ? cur : `${parseFloat(cur)}${t.kind === "pct" ? "%" : ""}`)}</span>
        {overrides ? <button className="sbx" title="Reset to master" onClick={e => { e.preventDefault(); edit(scope, t.v, MASTER); }} aria-label={`Reset ${t.label} to master`}>↺</button>
          : changed(scope, t.v) ? <button className="sbx" onClick={e => { e.preventDefault(); edit(scope, t.v, null); }} aria-label={`Undo ${t.label}`}>×</button> : <span className="sbx" />}
      </label>
    );
  };

  return (
    <aside className="sbpanel" aria-label="Design sandbox">
      <div className="sbbar"><b>Sandbox</b><button className="sbpill" onClick={() => set({ open: false })}>Hide</button></div>

      <div className="sbsec"><h3>Screen</h3>
        <div className="sbpills">{SCREENS.map(s => <button key={s} className={`sbpill${s === screen ? " on" : ""}`} onClick={() => show(s)}>{s}</button>)}</div>
      </div>

      <div className="sbsec"><h3>Grade</h3>
        <div className="sbgrades">{GRADES.map(d => (
          <button key={d.grade} className={`sbgrade${d.grade === g ? " on" : ""}`} style={{ ["--gc" as string]: d.color }} onClick={() => pickGrade(d.grade)} aria-label={d.name}>{d.short}</button>
        ))}</div>
      </div>

      <div className="sbsec"><h3>Lesson</h3>
        <select value={lessonId ?? ""} onChange={e => show(screen === "Practice" ? "Practice" : "Lesson", g, e.target.value)}>
          {unitsOf(g).map(u => <optgroup key={u.name} label={u.name}>{u.lessons.map(l => <option key={l.id} value={l.id}>{l.title}</option>)}</optgroup>)}
        </select>
        <div className="sbpills">
          <button className="sbpill" onClick={() => set({ seed: randomSeed() })}>New problems</button>
        </div>
      </div>

      <div className="sbsec"><h3>Look</h3>
        <div className="sbpills">{(["light", "dark"] as const).map(t => <button key={t} className={`sbpill${sb.theme === t ? " on" : ""}`} onClick={() => set({ theme: t })}>{t === "light" ? "Light" : "Dark"}</button>)}</div>
      </div>

      <div className="sbsec"><h3>Editing</h3>
        <div className="sbpills">
          <button className={`sbpill${master ? " on" : ""}`} onClick={() => set({ mode: "master" })}>Grade (master)</button>
          <button className={`sbpill${master ? "" : " on"}`} onClick={() => set({ mode: "grade" })}>{gradeOf(g).name}</button>
        </div>
        <p className="sbnote">{master ? "Changes here reach all 13 grades, except colors a grade overrides."
          : `An instance of Grade: ${BAND_NAMES[bandOf(g)]}, ${lessonsInGrade(g).length} lessons, and it overrides ${over.size} of ${GRADE_TOKENS.length} master colors.`}</p>
      </div>

      {master ? <>
        <div className="sbsec"><h3>Master colors</h3>{GRADE_TOKENS.map(t => row("master", t))}</div>
        <div className="sbsec"><h3>Shared colors · {sb.theme}</h3>{SHARED_TOKENS.map(t => row("shared", t))}</div>
        <div className="sbsec"><h3>Sizes</h3>{SIZE_TOKENS.map(t => row("sizes", t))}</div>
        <div className="sbsec"><h3>Surface (master)</h3><p className="sbnote">Every panel, card and tile; inner corners follow the outer one.</p>{SURFACE_TOKENS.map(t => row(t.kind === "color" ? "shared" : "sizes", t))}</div>
        <div className="sbsec"><h3>Pill (master)</h3><p className="sbnote">Every button on every screen.</p>{PILL_TOKENS.map(t => row("sizes", t))}</div>
        <div className="sbsec"><h3>Diagram (master)</h3><p className="sbnote">Every picture in every grade draws with these.</p>{DIAGRAM_TOKENS.map(t => row("sizes", t))}</div>
      </> : <>
        <div className="sbsec"><h3>{gradeOf(g).name} overrides</h3>{GRADE_TOKENS.map(t => row("grade", t))}
          <div className="sbpills"><button className="sbpill" disabled={!over.size} onClick={resetToMaster}>Reset all to master</button></div>
        </div>
      </>}

      <div className="sbsec">
        <div className="sbpills">
          <button className="sbpill" onClick={() => setCopy(c => !c)}>{copy ? "Hide changes" : "Show changes as CSS"}</button>
          <button className="sbpill" onClick={() => set({ o: emptyOverrides() })}>Reset all</button>
        </div>
        {copy && <textarea className="sbcss" readOnly value={handoffCss(sb.o)} onFocus={e => e.currentTarget.select()} />}
      </div>
    </aside>
  );
}
