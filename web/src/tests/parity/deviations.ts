/**
 * Places where a rebuilt lesson intentionally differs from the current app, with the reason.
 * Each picture family keeps its own file in ./deviations/<family>.ts exporting `deviations`.
 * Keys are `<lessonId>` → field → reason. Fields: unit, pre, show, note, story, prompt, stepNote, hint, explain, work, choices, checks, steps.
 * Every entry is reviewed; nothing goes here to make a test pass.
 */
type Deviations = Record<string, Partial<Record<string, string>>>;
const files = import.meta.glob<Deviations>("./deviations/*.ts", { eager: true, import: "deviations" });
export const DEVIATIONS: Deviations = Object.assign({}, ...Object.values(files));
