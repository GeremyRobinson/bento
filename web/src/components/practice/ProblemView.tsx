import { requireLesson } from "../../curriculum/registry";
import { beats } from "../../explanations/schema";
import { Diagram } from "../diagrams/Diagram";
import { MathLine, Rich } from "../primitives/MathLine";
import { AskLine } from "../primitives/AskLine";
import { dressStatement, fillUnknown, partsLook, type PartsLook } from "../primitives/statement";
import { CounterRow } from "./CounterRow";

/** The problem's one answer, when it is a single number (the last step's only box); else null. */
function finalAnswer(lesson: ReturnType<typeof requireLesson>, problem: unknown): number | null {
  try {
    const steps = lesson.answers(problem).steps, last = steps[steps.length - 1];
    return last && last.slots.length === 1 && !last.choices ? last.slots[0]!.expected : null;
  } catch { return null; }
}

/**
 * How a problem reads: `short` when it is one line of math that fits the island on a phone (no story, no lead, not a
 * question in words), and `picture` when the lesson draws its own picture of it.
 */
export function problemShape(lessonId: string, problem: unknown, story: boolean): { short: boolean; picture: boolean } {
  const lesson = requireLesson(lessonId);
  const picture = !!lesson.picture?.(problem);
  if ((story && lesson.story) || lesson.lead?.(problem)) return { short: false, picture };
  const shown = lesson.display(problem);
  const wordy = shown.flatMap(k => (k.t === "text" ? k.v.match(/[a-z]{2,}/gi) ?? [] : [])).length >= 3;
  // a note or counters under the math need the problem's own place, not the island
  return { short: !wordy && !lesson.displayNote?.(problem) && !lesson.displayCounters?.(problem), picture };
}

/** The problem's line of math, dressed in its parts' colours, with the "?" filled once it's solved (the island's copy). */
export function ProblemLine({ lessonId, problem, solved }: { lessonId: string; problem: unknown; solved?: boolean }) {
  const lesson = requireLesson(lessonId), shown = lesson.display(problem);
  const look = ((): PartsLook => { try { return partsLook(lesson.explain(problem, lesson.answers(problem)).diagram); } catch { return "one"; } })();
  return <MathLine math={solved ? fillUnknown(dressStatement(shown, look), finalAnswer(lesson, problem)) : dressStatement(shown, look)} />;
}

/**
 * The problem as the current app shows it: the story for word problems, otherwise the math, its counters and its note.
 * `part` splits it for a screen that puts the words and the picture in different places.
 */
export function ProblemView({ lessonId, problem, story, solved, part = "all", step }: { lessonId: string; problem: unknown; story: boolean; solved?: boolean; part?: "all" | "text" | "picture"; step?: string }) {
  const lesson = requireLesson(lessonId);
  if (story && lesson.story) return part === "picture" ? null : <div className="story"><p><Rich text={lesson.story(problem).text} /></p></div>;
  const lead = lesson.lead?.(problem), shown = lesson.display(problem);
  // a question in words ("How many are in the other group?") reads as a sentence: it wraps inside the card at the
  // question size, rather than one unbreakable line at the size of an equation (G 2026-10-06, Kindergarten check-up)
  const wordy = shown.flatMap(k => (k.t === "text" ? k.v.match(/[a-z]{2,}/gi) ?? [] : [])).length >= 3;
  const note = lead ? undefined : lesson.displayNote?.(problem), counters = lesson.displayCounters?.(problem), picture = lesson.picture?.(problem, step);
  if (part === "picture") return picture ? <Diagram diagram={picture} timeline={beats(1)} at={0} fit /> : null;
  // the parts wear the colours the problem's picture gives them (statement.ts partsLook)
  const look = ((): PartsLook => { try { return partsLook(lesson.explain(problem, lesson.answers(problem)).diagram); } catch { return "one"; } })();
  return (
    <>
      {lead ? <div className="story"><p><Rich text={lead} /></p></div> : <><AskLine math={shown} /><div className={`math parts-${look}${wordy ? " words" : ""}`}><MathLine math={solved ? fillUnknown(dressStatement(shown, look), finalAnswer(lesson, problem)) : dressStatement(shown, look)} /></div></>}
      {counters && <CounterRow counters={counters} />}
      {picture && part === "all" && <div className="dotrow"><Diagram diagram={picture} timeline={beats(1)} at={0} /></div>}
      {note && <p className="note"><Rich text={note} /></p>}
    </>
  );
}
