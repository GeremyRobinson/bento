import { requireLesson } from "../../curriculum/registry";
import { beats } from "../../explanations/schema";
import { Diagram } from "../diagrams/Diagram";
import { MathLine, Rich } from "../primitives/MathLine";
import { CounterRow } from "./CounterRow";

/** The problem as the current app shows it: the story for word problems, otherwise the math, its counters and its note. */
export function ProblemView({ lessonId, problem, story }: { lessonId: string; problem: unknown; story: boolean }) {
  const lesson = requireLesson(lessonId);
  if (story && lesson.story) return <div className="story"><p><Rich text={lesson.story(problem).text} /></p></div>;
  const lead = lesson.lead?.(problem), shown = lesson.display(problem);
  // a question in words ("How many are in the other group?") reads as a sentence: it wraps inside the card at the
  // question size, rather than one unbreakable line at the size of an equation (G 2026-10-06, Kindergarten check-up)
  const wordy = shown.filter(k => k.t === "text" && /[a-z]{2}/i.test(k.v)).length >= 3;
  const note = lead ? undefined : lesson.displayNote?.(problem), counters = lesson.displayCounters?.(problem), picture = lesson.picture?.(problem);
  return (
    <>
      {lead ? <div className="story"><p><Rich text={lead} /></p></div> : <div className={`math${wordy ? " words" : ""}`}><MathLine math={shown} /></div>}
      {counters && <CounterRow counters={counters} />}
      {picture && <div className="dotrow"><Diagram diagram={picture} timeline={beats(1)} at={0} /></div>}
      {note && <p className="note"><Rich text={note} /></p>}
    </>
  );
}
