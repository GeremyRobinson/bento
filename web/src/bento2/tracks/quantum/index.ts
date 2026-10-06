// Quantum (track 10, code `qu`): the header of curriculum/specs/bento2/quantum.md as data, and its 12 lessons.
import type { B2Track } from "../../model";
import { QUANTUM_LESSONS } from "./lessons";

export const track: B2Track = {
  code: "qu",
  pickerId: "quantum",
  name: "Quantum",
  about: "The rules for the very small, where outcomes are chances, chances come from arrows that can cancel, and a qubit can be a blend of 0 and 1. It is the math behind lasers, chips and quantum computers.",
  build: {
    name: "A two-qubit search, run by hand",
    goal: "Build Grover's search on two qubits gate by gate, write the four amplitudes after every gate by hand, and find the marked item out of four with probability 1, using one question where a classical search can need three.",
  },
  units: [
    { n: 1, name: "Chances from arrows", adds: "How to read the answer: amplitudes are arrows, they add and cancel, and a chance is a squared length." },
    { n: 2, name: "One qubit", adds: "The gates H, X, Z and phase as 2×2 matrices, and the H, phase, H trick that turns a phase into a chance." },
    { n: 3, name: "Two qubits", adds: "The board: four amplitudes, the tensor product, CNOT and entanglement." },
    { n: 4, name: "Quantum computing", adds: "The algorithm: a sign-flip oracle, Deutsch–Jozsa, Grover's flip and reflect, and the two-qubit search run by hand." },
  ],
  projects: [
    { id: "qu-coin", after: "b2-qu-03", name: "Your quantum coin", makes: "Pick two complex amplitudes: Bento scales them, predicts the chance of 0, and runs 1,000 shots so you watch the bars settle onto your prediction.", shelf: ["psi"], scene: { scene: "coin", props: { project: true, a0: 1, a1: 1, b0: 2, b1: 0 } } },
    { id: "qu-dial", after: "b2-qu-06", name: "Dial a chance", makes: "Pick a chance of 0, set the phase in H, phase, H to hit it, and check it over 1,000 shots.", shelf: ["dial"], scene: { scene: "hph", props: { project: true, phi: 90, target: 0.25 } } },
    { id: "qu-bell", after: "b2-qu-09", name: "Bell pair lab", makes: "Make all four Bell states from H and CNOT, plus X and Z, read each one's matching pattern, and play the matching game with your favorite.", shelf: ["bell"], scene: { scene: "bellab", props: { project: true } } },
    { id: "qu-search", after: "b2-qu-12", name: "The build: two-qubit search", makes: "Hide an item, type the state after every gate of Grover's circuit, and find the item with certainty in 1,000 shots out of 1,000.", shelf: ["grover"], build: true, scene: { scene: "search", props: { project: true, m: 1 } } },
  ],
  tools: [
    { id: "sphere", name: "Qubit sphere", short: "Sphere", star: true },
    { id: "arrows", name: "Amplitude arrows", short: "Arrows" },
    { id: "slit", name: "Double-slit lab", short: "Slits" },
    { id: "coin", name: "Quantum coin", short: "Coin" },
    { id: "circuit", name: "Circuit board", short: "Circuit" },
    { id: "hph", name: "H, phase, H", short: "Phase" },
    { id: "grid", name: "Product grid", short: "Grid" },
    { id: "pair", name: "Entanglement pair", short: "Pairs" },
    { id: "dj", name: "Oracle box", short: "Oracle" },
    { id: "mean", name: "Reflect about the mean", short: "Grover" },
    { id: "search", name: "Two-qubit search", short: "Search" },
  ],
  buildPieces: ["psi", "dial", "bell", "grover"],
  lessons: QUANTUM_LESSONS,
};
