// The pieces a grade's v2 file (v2/grade<N>.ts) writes its skill checks with. A lesson's own skill check comes from
// Curriculum (curriculum/specs/v2/grade<N>.md, each signed off by Review).
// An item is the lesson's own generate(rng, i), redrawn (up to 50 tries) until `where` holds; when it never does, the
// last draw stands, or `fix` turns it into one that fits. `story` asks it as the lesson's story, and goes last. The
// items are shuffled unless the recipe says `inOrder`. A lesson with no recipe gets the engine's default check.
/* eslint-disable @typescript-eslint/no-explicit-any */
export interface CheckItem {
  i: number;
  where?: (p: any) => boolean;
  /** when `where` never held: make the last draw fit (it must still be a valid problem), or null when it can't */
  fix?: (p: any) => any;
  story?: true;
}
export interface CheckRecipe { items: CheckItem[]; inOrder?: true }

export const WHERE_TRIES = 50;

export const gcd = (a: number, b: number): number => (b ? gcd(b, a % b) : Math.abs(a));
/** decimal digits written in x */
export const places = (x: number) => (String(x).split(".")[1] ?? "").length;

export const i = (n: number, more: Omit<CheckItem, "i"> = {}): CheckItem => ({ i: n, ...more });
