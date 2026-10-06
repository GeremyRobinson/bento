// Probability and statistics (track 2, code `pr`): the header of curriculum/specs/bento2/probability.md as data, and
// its 20 lessons.
import type { B2Track } from "../../model";
import { PR_LESSONS } from "./lessons";

export const track: B2Track = {
  code: "pr",
  pickerId: "prob",
  name: "Probability and statistics",
  about: "The math of chance and data: how likely things are, how to tell a real effect from luck, and how sure you can be from a sample.",
  build: {
    name: "The Luck detector",
    goal: "One screen that takes an experiment (two versions of something, and what happened) and gives an honest verdict: how big the effect is, how sure you can be, and how likely it is to be luck. Feed it made-up experiments with a hidden truth and see, run after run, how often its calls hold up.",
  },
  units: [
    { n: 1, name: "Chance machines", adds: "The null world: a simulator that replays the experiment with no real effect, the 1/√n rule for how noisy any average is, and the Bayes box for base rates." },
    { n: 2, name: "Shapes of chance", adds: "The yardsticks: Poisson for rare counts, the normal curve for sums and averages, and correlation for paired measures." },
    { n: 3, name: "Learning from data", adds: "The estimate with error bars: the best-fit value, its bias and spread, a bootstrap interval and a Bayesian posterior." },
    { n: 4, name: "Luck or real?", adds: "The verdict engine: an exact shuffle test, a power check before running, a correction for many looks, and the chance the effect is real." },
    { n: 5, name: "Traps and the verdict", adds: "The alarms and the final bench: regression to the mean, confounding and streaks, then the full pipeline on an A/B test." },
  ],
  projects: [
    { id: "pr-screen", after: "b2-pr-04", name: "A screening card", makes: "Pick a made-up condition, set how rare it is and how good the test is: the Bayes box draws 10,000 people, and you write what a positive really means.", shelf: ["ppv"], scene: { scene: "bayes", props: { project: true, prev: 1, sens: 90, spec: 95 } } },
    { id: "pr-sum", after: "b2-pr-08", name: "The sum machine", makes: "Draw any shape of chance, add n copies, and watch the total turn into a bell. The card reports the mean, the SD and the 1-in-100 cutoff.", shelf: ["zSum"], scene: { scene: "clt", props: { project: true, shape: "twohump", n: 10 } } },
    { id: "pr-errbars", after: "b2-pr-12", name: "Honest error bars", makes: "One made-up data set, three answers side by side: the maximum likelihood estimate, a bootstrap interval and a Bayesian credible interval.", shelf: ["bootSE", "postMean"], scene: { scene: "errbars", props: { project: true } } },
    { id: "pr-court", after: "b2-pr-16", name: "Loaded-coin court", makes: "A coin is accused of being loaded. Set the plan, run it, and return a verdict with a p-value, a Bayes factor and the chance it's loaded. Then the truth comes out.", shelf: [], scene: { scene: "court", props: { project: true } } },
    { id: "pr-luck", after: "b2-pr-20", name: "The build: the Luck detector", makes: "Plan, run, test, correct, estimate and weigh, on any two-version experiment, with the truth revealed and the detector's own calls checked.", shelf: ["luckDetector"], build: true, scene: { scene: "bench", props: { project: true } } },
  ],
  tools: [
    { id: "sim", name: "Simulator", short: "Simulator", star: true },
    { id: "bayes", name: "Bayes box", short: "Bayes" },
    { id: "dens", name: "Distribution lab", short: "Densities" },
    { id: "clt", name: "Sample machine", short: "Samples" },
    { id: "cloud", name: "Joint cloud", short: "Cloud" },
    { id: "spin", name: "Two spinners", short: "Spinners" },
    { id: "like", name: "Likelihood viewer", short: "Likelihood" },
    { id: "varest", name: "Variance estimates", short: "n − 1" },
    { id: "boot", name: "Bootstrap", short: "Bootstrap" },
    { id: "beta", name: "Beta updater", short: "Beta" },
    { id: "shuffle", name: "Shuffle bench", short: "Shuffle" },
    { id: "power", name: "Power bells", short: "Power" },
    { id: "retest", name: "Retest pair", short: "Retest" },
    { id: "simpson", name: "Simpson table", short: "Simpson" },
    { id: "bench", name: "Luck detector", short: "Detector" },
  ],
  buildPieces: ["mcN", "pairs", "varAvg", "ppv", "lambda", "halfLife", "zSum", "rho", "lamHat", "mse", "bootSE", "postMean", "pPerm", "nNeeded", "fdrCut", "fdrField", "rtmShrink", "adjRate", "piA", "luckDetector"],
  lessons: PR_LESSONS,
};
