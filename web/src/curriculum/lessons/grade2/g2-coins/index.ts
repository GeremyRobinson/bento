// Name the coin: tell coins apart by size, color and edge, know what each is worth, and see that small can be worth more.
import { text } from "../../../schemas/math-text";
import type { AnswerModel, AnswerStep, LessonDefinition } from "../../../schemas/lesson";
import { beats, type Explanation } from "../../../../explanations/schema";
import { buildCoinPicture, COIN_INFO, coinLook } from "../../../../explanations/diagrams/early-g2/coins";
import { oneBox, wholeIn } from "../../_number-line/steps";
import { tapStep, words } from "../../gradeK/kit";
import { slips } from "../kit";

const NAMES = ["Penny", "Nickel", "Dime", "Quarter"];
const PENNY = 0, NICKEL = 1, DIME = 2, QUARTER = 3;
const cents = (v: number) => `${v} ${v === 1 ? "cent" : "cents"}`;

/** kind 0: one coin; kind 1: coin on the left, other on the right, which is worth more. side 0 heads, 1 tails */
export interface CoinProblem { kind: number; coin: number; other: number; side: number }

export function createCoin(kind: number, coin: number, other: number, side: number): CoinProblem {
  wholeIn("kind", kind, 0, 1);
  wholeIn("coin", coin, 0, 3);
  wholeIn("other", other, 0, 3);
  wholeIn("side", side, 0, 1);
  if (kind === 1 && coin === other) throw new Error("two different coins");
  return { kind, coin, other: kind === 1 ? other : coin, side };
}

/** why a picked name is wrong for this coin */
function nameSlip(coin: number, i: number): [string, string] {
  const picked = `Picked ${NAMES[i]!.toLowerCase()}`;
  if (coin === DIME && i === NICKEL) return [picked, "The dime is the smallest coin and has a bumpy edge. A nickel is bigger and smooth."];
  if (coin !== PENNY && i === PENNY) return [picked, "A penny is the copper-colored coin. This one is silver."];
  if (coin === NICKEL && i === QUARTER) return [picked, "The quarter is the biggest coin and has a bumpy edge. A nickel's edge is smooth."];
  if (coin === PENNY) return [picked, "This coin is copper-colored: that's a penny."];
  if (coin === NICKEL && i === DIME) return [picked, "A dime is smaller and has a bumpy edge. This one is smooth: a nickel."];
  if (coin === QUARTER) return [picked, `This is the biggest coin, with a bumpy edge: a quarter.`];
  return [picked, "This is the smallest coin, with a bumpy edge: a dime."];
}

function nameStep(id: string, coin: number, where: string): AnswerStep {
  const n = COIN_INFO[coin]!.name;
  return tapStep({
    id, label: where ? `Name the ${where} coin` : "Name it", question: where ? `What is the ${where} coin?` : "What coin is this?",
    prompt: [text(where ? `The ${where} coin is a ?` : "It's a ?")], choices: NAMES, right: coin,
    wrong: i => nameSlip(coin, i),
    hint: "Look at its size, its color and its edge.",
    explain: `${coinLook(coin)[0]!.toUpperCase()}${coinLook(coin).slice(1)} is a ${n}.`,
    work: [text(`a ${n}`)],
  });
}

function answers(p: CoinProblem): AnswerModel {
  if (p.kind === 0) {
    const c = COIN_INFO[p.coin]!, v = c.value;
    return {
      steps: [
        nameStep("name", p.coin, ""),
        oneBox({
          id: "value", label: "Its value", question: `How many cents is a ${c.name}?`,
          prompt: s => [text(`A ${c.name} is `), s, text(" ¢")], ans: v,
          wrong: slips(v, [
            p.coin === DIME && [5, "Went by size", "A dime is small but worth 10 cents."],
            p.coin === NICKEL && [1, "Worth 1 cent?", "A nickel is worth 5 pennies: 5 cents."],
            ...COIN_INFO.filter((_, i) => i !== p.coin).map(o => [o.value, `Gave a ${o.name}'s value`, `That's what a ${o.name} is worth. A ${c.name} is worth ${cents(v)}.`] as [number, string, string]),
          ]),
          hint: "Penny 1, nickel 5, dime 10, quarter 25.",
          explain: `A ${c.name} is worth ${cents(v)}.`,
        }),
      ],
      finalParts: [-1],
    };
  }
  const a = COIN_INFO[p.coin]!, b = COIN_INFO[p.other]!, right = a.value > b.value ? 0 : 1, win = right ? b : a, lose = right ? a : b;
  const fooled = win.mm < lose.mm;
  return {
    steps: [
      nameStep("left", p.coin, "left"),
      nameStep("right", p.other, "right"),
      tapStep({
        id: "more", label: "Worth more", question: "Which is worth more?",
        prompt: [text(`A ${a.name} or a ${b.name}?`)], choices: ["Left", "Right"], right,
        wrong: () => fooled
          ? ["Went by size", `The ${lose.name} is bigger, but the ${win.name} is worth more: ${win.value} cents to ${lose.value}.`]
          : ["Picked the smaller value", `A ${lose.name} is worth ${cents(lose.value)} and a ${win.name} ${cents(win.value)}. The ${win.name} is worth more.`],
        hint: "Think of what each coin is worth, not how big it is.",
        explain: `A ${win.name} is worth ${cents(win.value)}, a ${lose.name} ${cents(lose.value)}. The ${win.name} is worth more.`,
        work: [text(`The ${win.name}: ${win.value}¢ > ${lose.value}¢`)],
      }),
    ],
    finalParts: [-1],
  };
}

const coinsOf = (p: CoinProblem) => (p.kind === 0 ? [p.coin] : [p.coin, p.other]);
const alt = (p: CoinProblem) => (p.kind === 0 ? `${coinLook(p.coin)[0]!.toUpperCase()}${coinLook(p.coin).slice(1)}.` : `Two coins. Left: ${coinLook(p.coin)}. Right: ${coinLook(p.other)}.`);

function explain(p: CoinProblem, model: AnswerModel): Explanation {
  const state: Record<string, number> = { name: 1, left: 1, right: 1, value: 2, more: 2 };
  return {
    heading: "Coins",
    idea: ["Each coin has its own size, color and edge, and a bigger coin isn't always worth more."],
    statement: words(p.kind === 0 ? "What coin is this?" : "Which is worth more?"),
    diagram: buildCoinPicture({ coins: coinsOf(p), side: p.side, beats: { edge: 1, value: 2 },
      alt: `${alt(p)} Then ${coinsOf(p).map(c => `the ${COIN_INFO[c]!.name} is worth ${cents(COIN_INFO[c]!.value)}`).join(" and ")}.` }),
    caption: p.kind === 0 ? `A ${COIN_INFO[p.coin]!.name} is worth ${cents(COIN_INFO[p.coin]!.value)}.` : `${model.steps.at(-1)!.explain}`,
    timeline: beats(3),
    steps: [
      { id: "look", narration: "Look at the size, the color and the edge.", math: words("Look closely."), state: 0 },
      ...model.steps.map(s => ({ id: s.id, narration: s.explain, math: s.work ?? [text(cents(s.slots[0]!.expected as number))], state: state[s.id]!, answerStep: s.id, result: s.slots[0]!.expected! })),
    ],
  };
}

export const lesson: LessonDefinition<CoinProblem> = {
  id: "g2-coins",
  grade: 2,
  unit: "Measurement and data",
  title: "Name the coin",
  reference: createCoin(1, DIME, NICKEL, 0),
  generate: (rng, index) => {
    const side = rng.int(0, 1);
    if (index < 3 || index % 3 !== 2) return createCoin(0, (index * 3 + 1) % 4, 0, side);
    // half the pairs set the small dime against a bigger coin worth less
    const [a, b] = rng.int(0, 1) ? [DIME, rng.pick([PENNY, NICKEL])] : rng.shuffle([0, 1, 2, 3]).slice(0, 2) as [number, number];
    return rng.int(0, 1) ? createCoin(1, a!, b!, side) : createCoin(1, b!, a!, side);
  },
  restore: raw => {
    const r = raw as Partial<CoinProblem> | null;
    if (!r || typeof r !== "object") return null;
    try { return createCoin(r.kind as number, r.coin as number, r.other as number, r.side as number); } catch { return null; }
  },
  display: p => words(p.kind === 0 ? "What coin is this?" : "Which coin is worth more?"),
  picture: p => buildCoinPicture({ coins: coinsOf(p), side: p.side, alt: alt(p) }),
  answers,
  explain,
};
