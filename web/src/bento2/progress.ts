// What Bento² keeps on this device, inside the regular save (Progress.b2), so backups and storage carry it with no
// new store. No scores: what a learner sees is abilities and how much of each build is done. The quiet record
// (guesses, slips) is for Bento's own use: steps can shrink and old ideas come back for a refresh.
import type { ShelfValue } from "./model";

export interface ShelfItem {
  value: ShelfValue;
  unit?: string;
  /** names for a list's entries ("home", "traveler") */
  labels?: string[];
  /** where it came from: a lesson id, a project id or a tool */
  from: string;
  note?: string;
  at: number;
}

export interface NotebookEntry {
  id: string;
  /** the track code, or "tools" */
  track: string;
  title: string;
  /** the project or build it came from; the Notebook reopens it with these numbers */
  project?: string;
  /** the numbers the picture was showing when saved */
  data: Record<string, number>;
  /** a few lines written out, so the entry reads on its own */
  lines: string[];
  build?: boolean;
  at: number;
}

export interface B2LessonRecord {
  /** reached Use it (the lesson is done; its ability shows) */
  done: boolean;
  /** problems worked through to the end */
  solved: number;
  /** slip kind → times; quiet */
  slips: Record<string, number>;
  /** guesses: right or not, newest last (kept to 10); quiet, never shown as a score */
  guesses: boolean[];
  at: number;
}

export interface B2Progress {
  lessons: Record<string, B2LessonRecord>;
  shelf: Record<string, ShelfItem>;
  notebook: NotebookEntry[];
  /** each tool's own numbers, so a tool reopens as it was left */
  tools: Record<string, unknown>;
}

export const emptyB2 = (): B2Progress => ({ lessons: {}, shelf: {}, notebook: [], tools: {} });

const isObj = (x: unknown): x is Record<string, unknown> => !!x && typeof x === "object" && !Array.isArray(x);

/** Reads whatever is saved (or nothing) into the current shape. */
export function readB2(raw: unknown): B2Progress {
  if (!isObj(raw)) return emptyB2();
  return {
    lessons: isObj(raw.lessons) ? (raw.lessons as B2Progress["lessons"]) : {},
    shelf: isObj(raw.shelf) ? (raw.shelf as B2Progress["shelf"]) : {},
    notebook: Array.isArray(raw.notebook) ? (raw.notebook as NotebookEntry[]) : [],
    tools: isObj(raw.tools) ? raw.tools : {},
  };
}

const rec = (b: B2Progress, id: string): B2LessonRecord => b.lessons[id] ?? { done: false, solved: 0, slips: {}, guesses: [], at: 0 };
const withRec = (b: B2Progress, id: string, f: (r: B2LessonRecord) => B2LessonRecord): B2Progress => ({ ...b, lessons: { ...b.lessons, [id]: f(rec(b, id)) } });

export const recordGuess = (b: B2Progress, id: string, right: boolean, now: number) =>
  withRec(b, id, r => ({ ...r, guesses: [...r.guesses, right].slice(-10), at: now }));
export const recordSlip = (b: B2Progress, id: string, kind: string, now: number) =>
  withRec(b, id, r => ({ ...r, slips: { ...r.slips, [kind]: (r.slips[kind] ?? 0) + 1 }, at: now }));
export const recordSolved = (b: B2Progress, id: string, now: number) => withRec(b, id, r => ({ ...r, solved: r.solved + 1, at: now }));
export const markDone = (b: B2Progress, id: string, now: number) => withRec(b, id, r => ({ ...r, done: true, at: now }));
export const isDone = (b: B2Progress, id: string) => !!b.lessons[id]?.done;

/** Number shelf names: a letter first, then letters, digits or _ ("gamma", "sr_drift", "v2"). */
export const validName = (name: string) => /^[A-Za-z][A-Za-z0-9_]{0,23}$/.test(name);

/** Puts a value on the shelf under a name, replacing an older value of that name. */
export function shelve(b: B2Progress, name: string, item: Omit<ShelfItem, "at">, now: number): B2Progress {
  if (!validName(name)) throw new Error(`not a shelf name: ${name}`);
  return { ...b, shelf: { ...b.shelf, [name]: { ...item, at: now } } };
}
export const unshelve = (b: B2Progress, name: string): B2Progress => {
  const shelf = { ...b.shelf };
  delete shelf[name];
  return { ...b, shelf };
};
export function renameShelf(b: B2Progress, from: string, to: string): B2Progress {
  const it = b.shelf[from];
  if (!it || !validName(to) || from === to) return b;
  const rest = unshelve(b, from);
  return { ...rest, shelf: { ...rest.shelf, [to]: it } };
}
/** The shelf's numbers by name (plain numbers only), for the calculator, the grapher and later lessons. */
export const shelfNumbers = (b: B2Progress): Record<string, number> =>
  Object.fromEntries(Object.entries(b.shelf).flatMap(([k, v]) => (typeof v.value === "number" ? [[k, v.value]] : [])));
export const readShelf = (b: B2Progress, name: string): ShelfValue | undefined => b.shelf[name]?.value;

/** Saves (or replaces) a Notebook entry; a project keeps one entry, updated each time it's saved. */
export function saveNote(b: B2Progress, e: Omit<NotebookEntry, "at">, now: number): B2Progress {
  const rest = b.notebook.filter(n => n.id !== e.id);
  return { ...b, notebook: [{ ...e, at: now }, ...rest].slice(0, 200) };
}

export const setTool = (b: B2Progress, tool: string, state: unknown): B2Progress => ({ ...b, tools: { ...b.tools, [tool]: state } });
