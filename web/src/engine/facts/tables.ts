// Facts: the small things worth knowing by heart, kept separate from lessons, like the character tables beside a
// language course. Each table is a grid of facts (or one row of them); every fact has one whole-number answer, so a
// sprint can check it straight from the keypad. Tables are made from code, never typed in, so they can't be wrong.

export interface Fact {
  /** stable inside its table: progress is saved by `${table}:${id}` */
  id: string;
  /** what's asked, e.g. "7 × 8" */
  ask: string;
  answer: number;
  /** where it sits in the table's grid (row and column from 0) */
  r: number;
  c: number;
}

export type Pattern = "times" | "add" | "hundred" | "none";

export interface FactTable {
  id: string;
  name: string;
  /** one line on what's in it */
  blurb: string;
  /** grades it belongs to */
  grades: [number, number];
  /** headings for the grid's rows and columns; a list table has one row */
  rowHeads: string[];
  colHeads: string[];
  facts: Fact[];
  /** the interactive pattern view this table offers */
  pattern: Pattern;
}

const range = (a: number, b: number) => Array.from({ length: b - a + 1 }, (_, i) => a + i);

function grid(id: string, name: string, blurb: string, grades: [number, number], rows: number[], cols: number[],
  make: (a: number, b: number) => { ask: string; answer: number } | null, pattern: Pattern): FactTable {
  const facts: Fact[] = [];
  rows.forEach((a, r) => cols.forEach((b, c) => {
    const f = make(a, b);
    if (f) facts.push({ id: `${a}_${b}`, r, c, ...f });
  }));
  return { id, name, blurb, grades, rowHeads: rows.map(String), colHeads: cols.map(String), facts, pattern };
}

function list(id: string, name: string, blurb: string, grades: [number, number], items: { key: string; head: string; ask: string; answer: number }[], pattern: Pattern = "none"): FactTable {
  return {
    id, name, blurb, grades, rowHeads: [""], colHeads: items.map(i => i.head), pattern,
    facts: items.map((i, c) => ({ id: i.key, ask: i.ask, answer: i.answer, r: 0, c })),
  };
}

export const TABLES: FactTable[] = [
  list("bonds10", "Make 10", "Pairs that make 10. Every bigger sum uses these.", [0, 2],
    range(0, 10).map(a => ({ key: String(a), head: String(a), ask: `${a} + ? = 10`, answer: 10 - a })), "add"),
  grid("add10", "Adding to 10", "Every sum up to 10.", [0, 1], range(0, 10), range(0, 10),
    (a, b) => (a + b <= 10 ? { ask: `${a} + ${b}`, answer: a + b } : null), "add"),
  grid("add20", "Adding to 20", "Every sum of two numbers up to 10.", [1, 3], range(1, 10), range(1, 10),
    (a, b) => ({ ask: `${a} + ${b}`, answer: a + b }), "add"),
  grid("sub20", "Taking away within 20", "The other side of every adding fact.", [1, 3], range(2, 20), range(1, 10),
    (a, b) => (b < a && a - b <= 10 ? { ask: `${a} − ${b}`, answer: a - b } : null), "none"),
  list("skip", "Counting by 2s, 5s and 10s", "The counts that make telling time, money and times tables easy.", [1, 3], [
    ...range(1, 10).map(k => ({ key: `2x${k}`, head: `${2 * k}`, ask: `2, 4, 6 … the ${ordinal(k)} number?`, answer: 2 * k })),
    ...range(1, 10).map(k => ({ key: `5x${k}`, head: `${5 * k}`, ask: `5, 10, 15 … the ${ordinal(k)} number?`, answer: 5 * k })),
    ...range(1, 10).map(k => ({ key: `10x${k}`, head: `${10 * k}`, ask: `10, 20, 30 … the ${ordinal(k)} number?`, answer: 10 * k })),
  ], "hundred"),
  grid("times", "Times tables", "Every times fact to 12 × 12. Half of them are the other half turned around.", [3, 8], range(1, 12), range(1, 12),
    (a, b) => ({ ask: `${a} × ${b}`, answer: a * b }), "times"),
  grid("divide", "Division facts", "Each times fact, read backward.", [3, 8], range(1, 12), range(1, 12),
    (a, b) => ({ ask: `${a * b} ÷ ${a}`, answer: b }), "times"),
  list("squares", "Squares", "A number times itself, from 1² to 20².", [5, 12],
    range(1, 20).map(n => ({ key: String(n), head: `${n}²`, ask: `${n}²`, answer: n * n }))),
  list("roots", "Square roots", "The squares, read backward.", [6, 12],
    range(1, 20).map(n => ({ key: String(n), head: `√${n * n}`, ask: `√${n * n}`, answer: n }))),
  list("cubes", "Cubes", "A number times itself three times, from 1³ to 10³.", [7, 12],
    range(1, 10).map(n => ({ key: String(n), head: `${n}³`, ask: `${n}³`, answer: n ** 3 }))),
  grid("signs", "Positive and negative", "Same signs make a positive. Different signs make a negative.", [6, 9], [-3, -2, 2, 3], [-6, -5, -4, 4, 5, 6],
    (a, b) => ({ ask: `${neg(a)} × ${neg(b)}`, answer: a * b }), "none"),
  list("pow2", "Powers of 2", "Doubling, from 2⁰ to 2¹². The numbers computers count in.", [8, 12],
    range(0, 12).map(n => ({ key: String(n), head: `2${sup(n)}`, ask: `2${sup(n)}`, answer: 2 ** n }))),
  list("pow10", "Powers of 10", "Each one is a 1 with that many zeros.", [5, 12],
    range(0, 6).map(n => ({ key: String(n), head: `10${sup(n)}`, ask: `10${sup(n)}`, answer: 10 ** n }))),
  list("logs", "Logs", "A log asks: what power? log₂ 8 = 3, because 2³ = 8.", [10, 12], [
    ...range(1, 10).map(n => ({ key: `2_${n}`, head: `log₂ ${2 ** n}`, ask: `log₂ ${2 ** n}`, answer: n })),
    ...range(1, 6).map(n => ({ key: `10_${n}`, head: `log ${10 ** n}`, ask: `log ${10 ** n}`, answer: n })),
  ]),
];

function ordinal(n: number): string {
  return ["", "1st", "2nd", "3rd"][n] ?? `${n}th`;
}
function neg(n: number): string {
  return n < 0 ? `(−${-n})` : String(n);
}
function sup(n: number): string {
  return String(n).split("").map(d => "⁰¹²³⁴⁵⁶⁷⁸⁹"[Number(d)]).join("");
}

export const tableById = (id: string) => TABLES.find(t => t.id === id);
export const tablesForGrade = (g: number) => TABLES.filter(t => g >= t.grades[0] && g <= t.grades[1]);
export const factKey = (t: FactTable, f: Fact) => `${t.id}:${f.id}`;
