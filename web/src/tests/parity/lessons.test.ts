// Parity: every rebuilt lesson, on the exact problems the current app made, shows the same problem, the same steps,
// the same answers, hints, explanations and worked lines, and gives the same verdict and message for every recorded try.
import { CATALOG } from "../../curriculum/catalog";
import { lessonById } from "../../curriculum/registry";
import { checkAnswerStep } from "../../engine/evaluation/steps";
import { DEVIATIONS } from "./deviations";
import { legacyRich, legacyText, squash } from "./legacy-text";

interface Check { v: Record<string, number | null>; ok: boolean; soft: boolean; kind: string | null; msg: string | null; generic: boolean }
interface Step { label: string; ask: string; note: string; answer: Record<string, number | null>; hint: string; explain: string; work: string; choices: string[] | null; ids: string[]; checks: Check[] }
interface Case { i: number; p: unknown; showMath: string; showNote: string; story: { op: string; text: string } | null; steps: Step[] }
interface Fixture { meta: { id: string; grade: number; unit: string; title: string; pre: string | null; story: boolean; final: number[] }; cases: Case[] }

const fixtures = import.meta.glob<Fixture>("../fixtures/legacy/*.json", { eager: true, import: "default" });
const byId = new Map(Object.entries(fixtures).filter(([k]) => !k.endsWith("_catalog.json")).map(([, f]) => [f.meta.id, f]));

const pending = CATALOG.filter(c => !lessonById(c.id));
if (pending.length) describe("lessons still to rebuild", () => {
  for (const c of pending) it.todo(c.id);
});
it("rebuilds every lesson of the current app", () => expect(pending.map(c => c.id)).toEqual([]));

// lessons the current app never had (the K–4 full years) have no recording; tests/curriculum/new-lessons.test.ts covers them
describe.each(CATALOG.filter(c => lessonById(c.id) && byId.has(c.id)).map(c => c.id))("%s matches the current app", id => {
  const lesson = lessonById(id)!, fx = byId.get(id)!, dev = DEVIATIONS[id] ?? {};
  const skip = (field: string) => !!dev[field];

  it("has the same place in the curriculum", () => {
    expect({ grade: lesson.grade, unit: skip("unit") ? fx.meta.unit : lesson.unit, title: lesson.title, pre: skip("pre") ? fx.meta.pre : lesson.pre ?? null, story: !!lesson.story })
      .toEqual({ grade: fx.meta.grade, unit: fx.meta.unit, title: fx.meta.title, pre: fx.meta.pre, story: fx.meta.story });
    expect(lesson.answers(lesson.reference).finalParts).toEqual(fx.meta.final);
  });

  describe.each(fx.cases.map(c => [c.i, c] as const))("problem %i", (_i, c) => {
    const p = lesson.restore(c.p);
    it("restores the current app's saved problem", () => expect(p).not.toBeNull());
    if (p == null) return;
    const model = lesson.answers(p);

    it("shows the same problem", () => {
      if (!skip("show")) expect(squash(legacyText(lesson.display(p)))).toBe(squash(c.showMath));
      if (!skip("note")) expect(squash(legacyRich(lesson.displayNote?.(p) ?? ""))).toBe(squash(c.showNote));
      if (c.story && !skip("story")) {
        const s = lesson.story!(p);
        expect(s.op).toBe(c.story.op);
        expect(squash(legacyRich(s.text))).toBe(squash(c.story.text));
      }
    });

    // with a reviewed "steps" deviation (a step added, removed or renamed), each recorded step is matched to the step with
    // its label, or else to the step in its place
    const counterpart = (k: number) => (skip("steps") ? model.steps.find(s => s.label === c.steps[k]!.label) ?? model.steps[k] : model.steps[k]);
    it("has the same steps", () => {
      if (!skip("steps")) expect(model.steps.map(s => s.label)).toEqual(c.steps.map(s => s.label));
      c.steps.forEach((o, k) => {
        const s = counterpart(k);
        if (!s) return;
        const ctx = `step ${k + 1} (${o.label})`;
        if (!skip("prompt")) expect(squash((s.question ? legacyRich(s.question) : "") + legacyText(s.prompt)), ctx).toBe(squash(o.ask));
        if (!skip("stepNote")) expect(squash(legacyRich(s.note ?? "")), ctx).toBe(squash(o.note));
        expect(Object.fromEntries(s.slots.map(x => [x.id, x.expected])), ctx).toEqual(o.choices ? { c: o.answer.c } : o.answer);
        if (!skip("hint")) expect(squash(legacyRich(s.hint)), ctx).toBe(squash(o.hint));
        if (!skip("explain")) expect(squash(legacyRich(s.explain)), ctx).toBe(squash(o.explain));
        if (!skip("work")) expect(squash(legacyText(s.work)), ctx).toBe(squash(o.work));
        if (!skip("choices")) expect(s.choices ?? null, ctx).toEqual(o.choices);
      });
    });

    it("judges every recorded try the same way", () => {
      if (skip("checks")) return;
      c.steps.forEach((o, k) => {
        const s = counterpart(k);
        if (!s) return;
        for (const t of o.checks) {
          const r = checkAnswerStep(s, t.v);
          const got = { ok: r.ok, soft: !r.ok && !!r.soft, kind: !r.ok && !r.soft ? r.kind : null, msg: r.ok ? null : squash(legacyRich(r.message)), generic: !r.ok && !r.soft ? r.generic : false };
          const want = { ok: t.ok, soft: t.soft, kind: t.soft ? null : t.kind, msg: t.msg == null ? null : squash(t.msg), generic: t.generic };
          expect(got, `step ${k + 1} (${o.label}) typed ${JSON.stringify(t.v)}`).toEqual(want);
        }
      });
    });
  });
});
