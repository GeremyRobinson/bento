// Differential equations (track 7, code `de`): the header of curriculum/specs/bento2/diffeq.md as data, and its 15
// lessons.
import type { B2Track } from "../../model";
import { DE_LESSONS } from "./lessons";

export const track: B2Track = {
  code: "de",
  pickerId: "change",
  name: "Differential equations",
  about: "The math of change over time. Write down how fast something changes right now, and the equation tells you its whole future: a swinging pendulum, a fish stock, predators and prey, an epidemic.",
  build: {
    name: "Two living models",
    goal: "A swinging pendulum and a population, running side by side in the flow sandbox, each with its own phase portrait, graph against time and live sliders, both stepped by the stepper you chose.",
  },
  units: [
    { n: 1, name: "One equation, read without solving", adds: "The population's one-variable core: logistic growth with an Allee threshold, a harvest dial with its tipping point, and the stepper every later model runs on." },
    { n: 2, name: "Linear systems", adds: "The phase-plane engine: any 2×2 system x′ = Ax, with eigen-lines, spirals and a trace–determinant readout." },
    { n: 3, name: "Oscillators", adds: "The pendulum itself: length, friction and a once-per-swing push, with the period and damping on the model card." },
    { n: 4, name: "Nonlinear worlds", adds: "The full pendulum portrait with its separatrix, predators and prey, and the population turned into an epidemic. Chaos is the optional ending." },
  ],
  projects: [
    { id: "de-fishery", after: "b2-de-04", name: "Fishery dial", makes: "A logistic fish stock with a harvest dial: the phase line, the bifurcation strip and a time graph. Set the largest harvest that keeps a safety margin above the collapse threshold.", shelf: ["H_safe"], scene: { scene: "harvest", props: { project: true, r: 1, K: 100, H: 15 } } },
    { id: "de-gallery", after: "b2-de-08", name: "Phase portrait gallery", makes: "Four tiles, a saddle, a node, a spiral and a center. Set a matrix in each so its dot lands in the right region of the trace–determinant map.", shelf: ["A_saddle", "A_node", "A_spiral", "A_center"], scene: { scene: "gallery", props: { project: true } } },
    { id: "de-clock", after: "b2-de-11", name: "Pendulum clock", makes: "A seconds pendulum from `L_pend` with a little friction and a once-per-swing push sized so the swing holds steady. The card shows the length, the period and the drift per day.", shelf: ["A_drive"], scene: { scene: "clock", props: { project: true } } },
    { id: "de-outbreak", after: "b2-de-14", name: "Outbreak planner", makes: "An SIR town with sliders for contact rate and infectious days. Set a vaccination fraction and see R₀, the herd-immunity line and the peak.", shelf: ["R0", "vax_needed"], scene: { scene: "sir", props: { project: true, beta: 0.3, D: 7, vax: 0 } } },
    { id: "de-models", after: "b2-de-14", name: "The build: two living models", makes: "Your pendulum and your population side by side, each with its phase portrait, its graph against time and live sliders, stepped by your own stepper.", shelf: ["L_pend", "R0"], build: true, scene: { scene: "models", props: { project: true } } },
  ],
  tools: [
    { id: "flow", name: "Slope field and flow sandbox", short: "Flow", star: true },
    { id: "plane", name: "Phase plane", short: "Plane" },
    { id: "steppers", name: "Step-by-step solver", short: "Steppers" },
    { id: "harvest", name: "Bifurcation strip", short: "Harvest" },
    { id: "tdmap", name: "Trace–determinant map", short: "T–D map" },
    { id: "spring", name: "Spring lab", short: "Spring" },
    { id: "pendulum", name: "Pendulum lab", short: "Pendulum" },
    { id: "resonance", name: "Resonance curve", short: "Resonance" },
    { id: "nonlinear", name: "Nonlinear phase plane", short: "Nonlinear" },
    { id: "species", name: "Two-species world", short: "Species" },
    { id: "sir", name: "Epidemic model (SIR)", short: "SIR" },
    { id: "chaos", name: "Chaos panel", short: "Chaos" },
    { id: "models", name: "Two living models", short: "Models" },
  ],
  buildPieces: ["allee_A", "K_fish", "stepper", "H_safe", "A_pend", "A_saddle", "A_node", "A_spiral", "A_center", "zeta", "L_pend", "T_pend", "A_drive", "R0", "vax_needed"],
  lessons: DE_LESSONS,
};
