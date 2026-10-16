// Lesson pictures' frame check (not shipped): draws one lesson picture in a fixed picture box, as Design's frame gives it
import { createRoot } from "react-dom/client";
import { useState } from "react";
import "../../src/styles/index.css";
import { Diagram } from "../../src/components/diagrams/Diagram";
import { LESSONS, requireLesson } from "../../src/curriculum/registry";
import { createRng } from "../../src/curriculum/generators/rng";
import { beats, type Explanation } from "../../src/explanations/schema";
import type { DiagramModel } from "../../src/explanations/schema";

type S = { id: string; w: number; h: number; prac: boolean; seed: number; at: number; ask?: number };
const problemOf = (id: string, seed: number): unknown => { const l = requireLesson(id); return seed ? l.generate(createRng(seed), seed % 8) : l.reference; };
const exOf = (id: string, seed: number): Explanation | null => {
  const l = requireLesson(id);
  try { const p = problemOf(id, seed); return l.explain(p as never, l.answers(p as never)); } catch { return null; }
};
/** practice as the app draws it: the problem's own picture at each step (and solved), else the worked picture one step behind */
const pracStates = (id: string, seed: number): { diagram: DiagramModel; timeline: ReturnType<typeof beats>; at: number; ask?: number }[] => {
  const l = requireLesson(id);
  try {
    const p = problemOf(id, seed) as never, steps = l.answers(p).steps.map((st: { id: string }) => st.id);
    if (l.picture?.(p)) return [...steps, undefined].map(st => ({ diagram: l.picture!(p, st)!, timeline: beats(1), at: 0 })).filter(x => x.diagram);
    const ex = l.explain(p, l.answers(p)); if (!ex.diagram || ex.diagram.kind === "chain") return [];
    const last = ex.timeline.length - 1, stateOf = (sid?: string) => ex.steps.find(e => e.answerStep === sid)?.state;
    const at = (here: number, solved: boolean) => {
      if (solved) return { at: last };
      if (!ex.steps.some(e => e.answerStep)) return { at: Math.min(last, here > 0 ? ex.steps[here - 1]?.state ?? 0 : 0) };
      const done = steps.slice(0, here).map(stateOf).filter((x): x is number => x != null);
      return { at: Math.min(last, Math.max(0, ...done)), ask: stateOf(steps[here]) };
    };
    return [...steps.map((_, k) => at(k, false)), at(steps.length, true)].map(a => ({ diagram: ex.diagram!, timeline: ex.timeline, ...a }));
  } catch { return []; }
};
let set: (s: S) => void = () => {};
function App() {
  const [s, setS] = useState<S | null>(null); set = setS;
  if (!s) return null;
  const ex = exOf(s.id, s.seed), ps = s.prac ? pracStates(s.id, s.seed)[s.at] : null;
  if (s.prac ? !ps : !ex?.diagram) return <div id="none">none</div>;
  return (
    <main id="app" className="wrap t5" data-band="middle" data-grade="5">
      <div className={`screen v-work v-prac${s.prac ? "" : " v-learn"}`}>
        <div className="v-ppic" style={{ width: s.w, height: s.h, minHeight: s.h, maxHeight: s.h, padding: 10, boxSizing: "border-box", contain: "size" }}>
          <div className="viz">{ps ? <Diagram key={`${s.id}-${s.seed}-${s.w}-${s.h}-p`} diagram={ps.diagram} timeline={ps.timeline} at={ps.at} ask={ps.ask} fit />
            : <Diagram key={`${s.id}-${s.seed}-${s.w}-${s.h}-l`} diagram={ex!.diagram!} timeline={ex!.timeline} at={s.at} ask={s.ask} fit />}</div>
        </div>
      </div>
    </main>
  );
}
const w = window as unknown as Record<string, unknown>;
w.pf = {
  ids: () => LESSONS.map(l => l.id),
  beats: (id: string, seed: number) => { const ex = exOf(id, seed); return ex?.diagram ? { n: ex.timeline.length, np: pracStates(id, seed).length, kind: ex.diagram.kind, family: (ex.diagram as { family?: string }).family, picture: !!requireLesson(id).picture } : null; },
  show: (s: S) => set(s),
  problem: (id: string, seed: number) => problemOf(id, seed),
  find: (id: string, test: (p: unknown) => boolean) => { for (let k = 1; k < 20000; k++) { try { if (test(problemOf(id, k))) return k; } catch { /* next */ } } return 0; },
};
createRoot(document.getElementById("root")!).render(<App />);
