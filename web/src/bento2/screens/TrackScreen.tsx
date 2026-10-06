// A Bento² track's map, as one instance of the Screen master's split: units and lessons (with their projects) in the
// list, the picked row in the detail. Progress is abilities and how much of the build is done; nothing is scored and
// nothing is locked ("Needs" only lights the map and suggests a refresher).
import { useLayoutEffect, useRef, useState, type CSSProperties } from "react";
import { useApp } from "../../app/AppState";
import { lessonById } from "../../curriculum/registry";
import { SplitScreen } from "../../components/screen/Screen";
import { Pill } from "../../components/primitives/Pill";
import { Rich } from "../../components/primitives/MathLine";
import type { AnyB2Lesson, B2Project, B2Track } from "../model";
import { isDone } from "../progress";
import { b2LessonById, lessonNumber, lessonsInUnit, projectAfter, trackByPickerId } from "../registry";
import { sceneByName } from "../scenes";
import { openTool } from "../ui/useB2";
import { toolMeta } from "../tools/ToolShell";
import { TRACKS } from "../../app/tracks";

const phone = () => typeof matchMedia !== "undefined" && matchMedia("(max-width: 699px)").matches;

/** How much of the build is done: the build's pieces that are on the Number shelf. */
export const buildDone = (t: B2Track, shelf: Record<string, unknown>) => t.buildPieces.filter(p => p in shelf).length;

/** "b2-la-05" names its track by code, built or not (the spec's track table) */
const CODE_NAMES: Record<string, string> = { la: "Linear algebra", pr: "Probability", mv: "Multivariable", in: "Information", cs: "Computation", ai: "AI", de: "Differential equations", or: "Orbits", re: "Relativity", qu: "Quantum" };

/** A need, in words: a lesson of a Bento² track (by number and title when it's built), or a Bento lesson by its title. */
export function needLabel(id: string): { text: string; lesson?: AnyB2Lesson } {
  const l = b2LessonById(id);
  if (l) return { text: `${lessonNumber(id)} · ${l.title}`, lesson: l };
  if (id.startsWith("b2-")) return { text: `${CODE_NAMES[id.split("-")[1]!] ?? "Another track"} ${lessonNumber(id)}` };
  return { text: `From Bento: ${lessonById(id)?.title ?? id}` };
}

export function TrackScreen({ trackId, pick: routePick }: { trackId: string; pick?: string }) {
  const { b2, go } = useApp();
  const track = trackByPickerId(trackId)!;
  const [pick, setPick] = useState<string | null>(routePick ?? null);
  const done = track.lessons.filter(l => isDone(b2, l.id));
  const pieces = buildDone(track, b2.shelf);
  const knob = useRef<HTMLSpanElement>(null), placed = useRef(false);
  useLayoutEffect(() => {
    const el = knob.current, row = el?.parentElement?.querySelector<HTMLElement>(".srow.on");
    if (!el) return;
    if (!row || phone()) { el.style.opacity = "0"; return; }
    if (!placed.current) el.style.transition = "none";
    el.style.opacity = "1";
    const list = el.parentElement!;
    el.style.transform = `translateY(${row.getBoundingClientRect().top - list.getBoundingClientRect().top + list.scrollTop}px)`;
    el.style.height = `${row.offsetHeight}px`;
    if (!placed.current) { void el.offsetHeight; el.style.transition = ""; placed.current = true; }
  });
  const choose = (id: string) => setPick(p => (p === id && phone() ? null : id));
  const open = (l: AnyB2Lesson) => go({ name: "b2lesson", track: trackId, lessonId: l.id }, "fwd");

  const lessonDetail = (l: AnyB2Lesson, inline = false) => {
    const unit = track.units.find(u => u.n === l.unit)!, Play = sceneByName(l.play.scene), was = isDone(b2, l.id);
    return (
      <div className={`b2detail${inline ? " inline" : ""}`} key={l.id}>
        <div className="b2dtext">
          {!inline && <small className="b2kick">Unit {unit.n} · {unit.name} · {lessonNumber(l.id)}</small>}
          {!inline && <h2>{l.title}</h2>}
          <p className={was ? "b2can on" : "b2can"}>{was ? "You can" : "When you're done, you can"} {l.youCan}</p>
          {l.needs.length > 0 && (
            <div className="b2chips" aria-label="Helps first">
              <small>Helps first</small>
              {l.needs.map(n => {
                const nd = needLabel(n), mine = nd.lesson && nd.lesson.track === track.code, text = nd.text;
                return mine
                  ? <button type="button" key={n} className={`b2chip${isDone(b2, n) ? " done" : ""}`} onClick={() => choose(n)}>{isDone(b2, n) ? "✓ " : ""}{text}</button>
                  : <span key={n} className="b2chip muted">{text}</span>;
              })}
            </div>
          )}
          <div className="b2chips" aria-label="Tools">
            <small>Tools</small>
            {l.tools.map(t => { const m = toolMeta(t, track); return <button type="button" key={t} className="b2chip" onClick={() => openTool(t)}>{m?.name ?? t}{m?.star ? " ★" : ""}</button>; })}
          </div>
        </div>
        {!inline && Play && <figure className="b2well"><Play props={l.play.props ?? {}} place="tool" /></figure>}
        <div className="b2go">
          <Pill go onClick={() => open(l)}>{was ? "Open again" : "Start"} {lessonNumber(l.id)} ›</Pill>
          {inline && <small>Unit {unit.n} · {unit.name}</small>}
        </div>
      </div>
    );
  };

  const projectDetail = (p: B2Project, inline = false) => {
    const Pic = sceneByName(p.scene.scene), after = b2LessonById(p.after);
    const have = p.shelf.filter(s => s in b2.shelf);
    return (
      <div className={`b2detail${inline ? " inline" : ""}`} key={p.id}>
        <div className="b2dtext">
          {!inline && <small className="b2kick">{p.build ? "The build" : "Small project"} · after {lessonNumber(p.after)} {after?.title}</small>}
          {!inline && <h2>{p.name}</h2>}
          <p><Rich text={p.makes} /></p>
          <p className="b2small">{p.shelf.length ? <>Saves {p.shelf.map(s => `\`${s}\``).join(" and ")} to your Number shelf{have.length ? ` (${have.length === p.shelf.length ? "saved" : `${have.join(", ")} saved`})` : ""}.</> : "Saves to your Notebook."}</p>
        </div>
        {Pic && <figure className="b2well proj"><Pic props={p.scene.props ?? {}} place="project" /></figure>}
      </div>
    );
  };

  const overview = (
    <div className="b2detail" key="overview">
      <div className="b2dtext">
        <small className="b2kick">The build</small>
        <h2>{track.build.name}</h2>
        <p>{track.build.goal}</p>
        <div className="b2pieces" aria-label={`The build: ${pieces} of ${track.buildPieces.length} pieces`}>
          {track.buildPieces.map(p => <span key={p} className={p in b2.shelf ? "on" : undefined}>{p}</span>)}
        </div>
        {done.length > 0
          ? <ul className="b2abil" aria-label="Your abilities">{done.map(l => <li key={l.id}>You can {l.youCan}</li>)}</ul>
          : <p className="b2small">Every lesson you finish adds an ability here, and its piece to the build. Take them in any order.</p>}
      </div>
      {(() => { const star = track.tools.find(t => t.star), Pic = star && sceneByName(star.id); return Pic ? <figure className="b2well"><Pic props={{}} place="tool" /></figure> : null; })()}
      <div className="b2go">
        {(() => { const next = track.lessons.find(l => !isDone(b2, l.id)) ?? track.lessons[0]!; return <Pill go onClick={() => open(next)}>{done.length ? "Next" : "Start"}: {lessonNumber(next.id)} {next.title} ›</Pill>; })()}
      </div>
    </div>
  );

  let row = 0;
  const list = (
    <>
      <span className="sknob" ref={knob} aria-hidden />
      <header className="shead b2head">
        <small className="b2kick">Bento² · Track {TRACKS.findIndex(t => t.id === trackId) + 1} · {TRACKS.find(t => t.id === trackId)?.part === "spine" ? "The spine" : "A branch"}</small>
        <h1>{track.name}</h1>
        <button type="button" className={`b2buildbar${pick == null ? " on" : ""}`} onClick={() => setPick(null)} style={{ "--p": pieces / track.buildPieces.length } as CSSProperties}>
          <span><b>{track.build.name}</b><small>{pieces} of {track.buildPieces.length} pieces · {done.length} {done.length === 1 ? "ability" : "abilities"}</small></span>
          <i aria-hidden />
        </button>
      </header>
      {track.units.map(u => (
        <div key={u.n} className="b2unit">
          <span className="slbl" style={{ "--i": row++ } as CSSProperties}>{u.n} · {u.name}</span>
          {lessonsInUnit(track, u.n).map(l => {
            const on = pick === l.id, d = isDone(b2, l.id), proj = projectAfter(track, l.id);
            return (
              <div key={l.id}>
                <div className="gitem" style={{ "--i": row++ } as CSSProperties}>
                  <button className={`srow b2row${on ? " on" : ""}`} aria-current={on ? "true" : undefined} onClick={() => choose(l.id)}>
                    <span className={`b2num${d ? " done" : ""}`}>{d ? "✓" : lessonNumber(l.id)}</span>
                    <span className="sname"><b>{l.title}</b></span>
                  </button>
                  {on && phone() && <div className="gopen">{lessonDetail(l, true)}</div>}
                </div>
                {proj && (
                  <div className="gitem" style={{ "--i": row++ } as CSSProperties}>
                    <button className={`srow b2row proj${pick === proj.id ? " on" : ""}`} aria-current={pick === proj.id ? "true" : undefined} onClick={() => choose(proj.id)}>
                      <span className={`b2num proj${proj.shelf.every(s => s in b2.shelf) ? " done" : ""}`} aria-hidden>{proj.build ? "★" : "◆"}</span>
                      <span className="sname"><b>{proj.name}</b></span>
                      <small>{proj.build ? "Build" : "Project"}</small>
                    </button>
                    {pick === proj.id && phone() && <div className="gopen">{projectDetail(proj, true)}</div>}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      ))}
    </>
  );

  const picked = pick ? track.lessons.find(l => l.id === pick) : undefined;
  const pickedProject = pick ? track.projects.find(p => p.id === pick) : undefined;
  const detail = picked ? lessonDetail(picked) : pickedProject ? projectDetail(pickedProject) : overview;
  return <SplitScreen className="b2trk" list={list} detail={detail} show="list" label={`${track.name}: lessons`} />;
}
