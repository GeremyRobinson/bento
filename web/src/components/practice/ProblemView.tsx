import { requireLesson } from "../../curriculum/registry";
import { beats } from "../../explanations/schema";
import { Diagram } from "../diagrams/Diagram";
import { MathLine, Rich } from "../primitives/MathLine";
import { AskLine } from "../primitives/AskLine";
import { dressStatement, partsLook, type PartsLook } from "../primitives/statement";
import { CounterRow } from "./CounterRow";

/** The problem as the current app shows it: the story for word problems, otherwise the math, its counters and its note. */
export function ProblemView({ lessonId, problem, story }: { lessonId: string; problem: unknown; story: boolean }) {
  const lesson = requireLesson(lessonId);
  if (story && lesson.story) return <div className="story"><p><Rich text={lesson.story(problem).text} /></p></div>;
  const lead = lesson.lead?.(problem);
  const note = lead ? undefined : lesson.displayNote?.(problem), counters = lesson.displayCounters?.(problem), picture = lesson.picture?.(problem);
  // the parts wear the colours the problem's picture gives them (statement.ts partsLook)
  const look = ((): PartsLook => { try { return partsLook(lesson.explain(problem, lesson.answers(problem)).diagram); } catch { return "one"; } })();
  return (
    <>
      {lead ? <div className="story"><p><Rich text={lead} /></p></div> : <><AskLine math={lesson.display(problem)} /><div className={`math parts-${look}`}><MathLine math={dressStatement(lesson.display(problem), look)} /></div></>}
      {counters && <CounterRow counters={counters} />}
      {picture && <div className="dotrow"><Diagram diagram={picture} timeline={beats(1)} at={0} /></div>}
      {note && <p className="note"><Rich text={note} /></p>}
    </>
  );
}
