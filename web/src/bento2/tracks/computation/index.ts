// Logic, algorithms and computation (track 5, code `cs`): the header of curriculum/specs/bento2/computation.md as data,
// and its 15 lessons.
import type { B2Track } from "../../model";
import { UNIT1 } from "./lessons1";
import { UNIT2 } from "./lessons2";
import { UNIT3 } from "./lessons3";

export const track: B2Track = {
  code: "cs",
  pickerId: "comp",
  name: "Logic, algorithms and computation",
  about: "The math of step-by-step thinking. True and false, recipes a machine can follow, how fast problems get hard as they grow, and the things no computer can ever solve.",
  build: {
    name: "The machine room",
    goal: "A working 4-bit chip made of gates, a race league of algorithms timed on the same inputs, and a map of where computing hits a wall. At the end the chip runs an algorithm: multiplication by shift-and-add.",
  },
  units: [
    { n: 1, name: "Logic and circuits", adds: "The chip. Truth tables become gates, gates become a half adder, then a full adder, then a 4-bit adder (adder4) built on the Logic gate board." },
    { n: 2, name: "Algorithms and growth", adds: "The race league. Search, sorting and path-finding run on the Algorithm stage with step counters, raced at n = 10, 1,000 and 1,000,000 items (race_card)." },
    { n: 3, name: "Hard and impossible", adds: "The wall, and the finale. Brute force against exponential growth, P vs NP, a Turing machine, the halting problem, then adder4 plus an algorithm becomes a multiplier (mult4)." },
  ],
  projects: [
    { id: "cs-adder", after: "b2-cs-05", name: "Your adder chip", makes: "A 4-bit ripple-carry adder built from your own full adders. Type two numbers from 0 to 15 and watch the carries ripple.", shelf: ["adder4"], scene: { scene: "cs-gates", props: { mode: "adder", a: 11, b: 6 } } },
    { id: "cs-race", after: "b2-cs-08", name: "Race card", makes: "Three algorithms you've run, raced at n = 10, 1,000 and 1,000,000: each step count and its time at a billion steps per second.", shelf: ["race_card"], scene: { scene: "cs-race" } },
    { id: "cs-puzzle", after: "b2-cs-12", name: "A puzzle that's easy to check", makes: "A subset-sum puzzle with a hidden answer: anyone can check a solution in seconds, but a blind search tries up to 2ⁿ subsets.", shelf: ["puzzle"], scene: { scene: "cs-stage", props: { mode: "subset", puzzle: true } } },
    { id: "cs-room", after: "b2-cs-15", name: "The build: the machine room", makes: "adder4 driven by a shift-and-add program with an 8-bit register [A | Q]: it multiplies two 4-bit numbers, with the gate count, the step count and the 8-bit answer.", shelf: ["mult4"], build: true, scene: { scene: "cs-mult" } },
  ],
  tools: [
    { id: "cs-stage", name: "Algorithm stage", short: "Stage", star: true },
    { id: "cs-truth", name: "Truth table panel", short: "Truth" },
    { id: "cs-proof", name: "Proof steps", short: "Proof" },
    { id: "cs-gates", name: "Logic gate board", short: "Gates" },
    { id: "cs-growth", name: "Growth race", short: "Growth" },
    { id: "cs-graph", name: "Graph explorer", short: "Graph" },
    { id: "cs-hanoi", name: "Tower of Hanoi", short: "Hanoi" },
    { id: "cs-machine", name: "Machine builder", short: "Machine" },
    { id: "cs-diagonal", name: "Diagonal table", short: "Diagonal" },
    { id: "cs-race", name: "Race card", short: "Race" },
    { id: "cs-mult", name: "The machine room", short: "Room" },
  ],
  buildPieces: ["xor", "adder4", "race_card", "puzzle", "mult4"],
  lessons: [...UNIT1, ...UNIT2, ...UNIT3],
};
