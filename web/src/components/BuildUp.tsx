import { useApp } from "../app/AppState";
import { buildUpFor, isReady } from "../app/curriculum";
import { gradeOf } from "../curriculum/grades";

/** "Build up first": after a 0 or 1, the lesson underneath. Shown even while that lesson is being rebuilt, but only opens once it's ready. */
export function BuildUp({ lessonId }: { lessonId: string }) {
  const { go } = useApp();
  const back = buildUpFor(lessonId);
  if (!back) return null;
  const live = isReady(back.id);
  return (
    <button className="lesson t1 backup" disabled={!live} onClick={() => go({ name: "learn", lessonId: back.id }, "back")}>
      <span className="badge">↩</span><span className="name">Do this one first: {back.title}</span>
      <span className="muted">{live ? gradeOf(back.grade).name : "Coming soon"}</span>
    </button>
  );
}
