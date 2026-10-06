/**
 * Places where a rebuilt lesson intentionally differs from the current app, with the reason.
 * Each picture family keeps its own file in ./deviations/<family>.ts exporting `deviations`.
 * Keys are `<lessonId>` → field → reason. Fields: unit, pre, show, note, story, prompt, stepNote, hint, explain, work, choices, checks, steps,
 * plus `added:<stepId>` (a new step with no recording, left out of the step-by-step comparison) and
 * `answers:<stepId>` (an in-between step that now asks a different number; final answers are always compared).
 * Every entry is reviewed; nothing goes here to make a test pass.
 */
type Deviations = Record<string, Partial<Record<string, string>>>;
const files = import.meta.glob<Deviations>("./deviations/*.ts", { eager: true, import: "deviations" });
// A lesson listed in two files would silently lose one file's reasons, so each lesson lives in exactly one file.
const twice = Object.values(files).flatMap(Object.keys).filter((id, i, all) => all.indexOf(id) !== i);
if (twice.length) throw new Error(`deviations listed in more than one file: ${twice.join(", ")}`);
export const DEVIATIONS: Deviations = Object.assign({}, ...Object.values(files));
