// Counting money: start with the coins worth the most, then count on by each coin's value.
import { num, text, type MathText, type MathToken } from "../../../schemas/math-text";
import type { AnswerModel, LessonDefinition } from "../../../schemas/lesson";
import type { Rng } from "../../../generators/rng";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildCoins, COINS, type CoinValue } from "../../../../explanations/diagrams/early-g2/counting";
import { expectedOf, oneBox, restoreVia, wholeIn } from "../../_number-line/steps";
import { slips, type Slip } from "../kit";

/** How many quarters, dimes, nickels and pennies. */
export interface MoneyProblem { q: number; d: number; n: number; p: number }

const ORDER = [["q", 25], ["d", 10], ["n", 5], ["p", 1]] as const;

export function createMoney(q: number, d: number, n: number, p: number): MoneyProblem {
  wholeIn("q", q, 0, 3);
  wholeIn("d", d, 0, 5);
  wholeIn("n", n, 0, 5);
  wholeIn("p", p, 0, 5);
  const kinds = [q, d, n, p].filter(c => c > 0).length, coins = q + d + n + p, cents = 25 * q + 10 * d + 5 * n + p;
  if (kinds < 2) throw new Error("use at least two kinds of coin");
  if (coins > 9) throw new Error("at most 9 coins");
  if (cents > 99) throw new Error("the total stays under a dollar");
  return { q, d, n, p };
}

/** Early problems use two kinds of small coins; later ones bring in quarters and more kinds. */
function generate(rng: Rng, index: number): MoneyProblem {
  for (;;) {
    const pick = (lo: number, hi: number, on: boolean) => (on ? rng.int(lo, hi) : 0);
    let q = 0, d: number, n: number, p: number;
    if (index < 3) {
      const [k1, k2] = rng.shuffle(["d", "n", "p"]);
      const on = (k: string) => k === k1 || k === k2;
      d = pick(1, 4, on("d")); n = pick(1, 4, on("n")); p = pick(1, 4, on("p"));
    } else {
      q = rng.int(1, 3); d = pick(1, 3, rng.next() < 0.7); n = pick(1, 2, rng.next() < 0.6); p = pick(1, 4, rng.next() < 0.7);
    }
    try { return createMoney(q, d, n, p); } catch { /* draw again */ }
  }
}

const nameOf = (v: CoinValue, c: number) => (c === 1 ? COINS[v].name : v === 1 ? "pennies" : `${COINS[v].name}s`);

/** The kinds present, biggest first, with the running total before and after each. */
function groupsOf(pr: MoneyProblem) {
  let total = 0;
  return ORDER.filter(([k]) => pr[k] > 0).map(([k, v]) => {
    const count = pr[k], before = total;
    total += count * v;
    return { key: k, value: v as CoinValue, count, before, after: total, seq: Array.from({ length: count }, (_, i) => before + (i + 1) * v) };
  });
}

function slipsFor(v: CoinValue, c: number, before: number): (Slip | false)[] {
  const one = COINS[v].name;
  return [
    v !== 1 && [before + c, `Counted a ${one} as 1¢`, `A ${one} is worth ${v}¢, not 1¢. Count on by ${v}s.`],
    v === 5 && [before + 10 * c, "Counted a nickel as 10¢", "A nickel is 5¢. It's bigger than a dime, but worth less."],
    v === 10 && [before + 5 * c, "Counted a dime as 5¢", "A dime is 10¢, even though it's the smallest coin."],
    v === 25 && [before + 10 * c, "Counted a quarter as 10¢", "A quarter is 25¢. Count 25, 50, 75."],
    v === 1 && [before + 5 * c, "Counted a penny as 5¢", "A penny is just 1¢. Count on by ones."],
    before > 0 && [c * v, "Started over", `Keep the ${before}¢ you already counted and count on from there.`],
    [before + (c + 1) * v, "Counted one coin too many", `There ${c === 1 ? "is" : "are"} ${c} ${nameOf(v, c)}. Count one ${v} for each.`],
  ];
}

function answers(pr: MoneyProblem): AnswerModel {
  const groups = groupsOf(pr);
  return {
    steps: groups.map((g, i) => {
      const name = nameOf(g.value, g.count), lead: MathToken[] = g.before ? [num(g.before), text("¢ and ")] : [];
      return oneBox({
        id: g.key, label: i === 0 ? `Count the ${nameOf(g.value, 2)}` : `Count on the ${nameOf(g.value, 2)}`,
        question: i === 0 ? `Each ${COINS[g.value].name} is ${g.value}¢.` : `Start at ${g.before}¢. Each ${COINS[g.value].name} adds ${g.value}¢.`,
        prompt: s => [...lead, num(g.count), text(` ${name} = `), s, text("¢")], ans: g.after,
        wrong: slips(g.after, slipsFor(g.value, g.count, g.before)),
        hint: `${g.before ? `Start at ${g.before} and count` : "Count"} by ${g.value}s, one count for each coin${g.seq.length > 2 ? `: ${g.seq.slice(0, 2).join(", ")}, and on` : ""}.`,
        explain: `${g.before ? `Start at ${g.before}, then ` : ""}${g.seq.join(", ")}. That's ${g.after}¢.`,
      });
    }),
    finalParts: [-1],
  };
}

function listCoins(pr: MoneyProblem): MathText {
  const gs = groupsOf(pr);
  return gs.flatMap((g, i) => [
    ...(i === 0 ? [] : [text(i === gs.length - 1 ? " and " : ", ")]),
    num(g.count), text(` ${nameOf(g.value, g.count)}`),
  ]);
}

function explain(pr: MoneyProblem, model: AnswerModel): Explanation {
  const groups = groupsOf(pr), last = groups.length;
  const total = expectedOf(model, groups[last - 1]!.key);
  return {
    heading: "Count on by coin",
    idea: ["Counting the coins worth the most first means fewer, easier steps."],
    statement: listCoins(pr),
    diagram: buildCoins({
      groups: groups.map((g, i) => ({ value: g.value, count: g.count, beat: i + 1 })),
      total: `${total}¢ in all`, totalBeat: last,
      alt: `Coins in a row: ${groups.map(g => `${g.count} ${nameOf(g.value, g.count)}`).join(", ")}. Counting on: ${groups.flatMap(g => g.seq).join(", ")}. ${total}¢ in all.`,
    }),
    caption: `Quarters are 25¢, dimes 10¢, nickels 5¢ and pennies 1¢.`,
    timeline: beats(last + 1),
    steps: groups.map((g, i) => {
      const after = expectedOf(model, g.key);
      return {
        id: g.key,
        narration: `${g.before ? `From ${g.before}¢, count on` : "Count"} the ${nameOf(g.value, g.count)} by ${g.value}s: ${g.seq.join(", ")}.`,
        math: [...(g.before ? [num(g.before), text("¢ + ")] : []), num(g.count * g.value), text("¢ = "), num(after), text("¢")],
        state: i + 1, answerStep: g.key, result: after,
      };
    }),
  };
}

export const lesson: LessonDefinition<MoneyProblem> = {
  id: "g2-money",
  grade: 2,
  unit: "Measurement and data",
  title: "Counting money",
  pre: "g2-coins",
  reference: createMoney(2, 1, 1, 3),
  generate,
  restore: raw => restoreVia(raw, ["q", "d", "n", "p"] as const, v => createMoney(v.q, v.d, v.n, v.p)),
  display: listCoins,
  displayNote: () => "How much money is this?",
  picture: pr => buildCoins({
    groups: groupsOf(pr).map(g => ({ value: g.value, count: g.count, beat: 0 })), total: "", totalBeat: 0, bare: true,
    alt: `Coins: ${groupsOf(pr).map(g => `${g.count} ${nameOf(g.value, g.count)}`).join(", ")}.`,
  }),
  answers,
  explain,
};
