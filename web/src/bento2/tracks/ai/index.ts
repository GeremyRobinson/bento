// The math behind AI (the capstone, code `ai`): the header of curriculum/specs/bento2/ai.md as data, and its 16 lessons.
import type { B2Track } from "../../model";
import { AI_LESSONS } from "./lessons";

export const track: B2Track = {
  code: "ai",
  pickerId: "ai",
  name: "The math behind AI",
  about: "How computers learn from examples. A line of best fit becomes a neural network, everything learns by stepping downhill on an error landscape, and the same few ideas, scaled up, run today's language models.",
  build: {
    name: "The Digit reader",
    goal: "A network you trained yourself that reads the digits you draw, says how sure it is, and has a \"not sure\" threshold so it can hold back when it's unsure. You check how well that works on scribbles.",
  },
  units: [
    { n: 1, name: "Learning is rolling downhill", adds: "The training loop: a loss, a gradient step and a learning-rate dial, eta." },
    { n: 2, name: "Neurons and networks", adds: "The network: neurons, a hidden layer with ReLU, backpropagation, and a softmax output with cross-entropy loss." },
    { n: 3, name: "Reading digits", adds: "The real thing: 8 × 8 pixels in, a 64 → 16 → 10 network (1,210 learned numbers), mini-batch training, a held-out set, a confusion grid and a pixel map." },
    { n: 4, name: "Words and attention", adds: "An optional upgrade: cut the digit into 16 patches and let the patches attend to each other, then compare it with the plain reader." },
    { n: 5, name: "Where AI is going", adds: "A scaling plot of the reader's own held-out error, a compute estimate, a goal sandbox, and calibration: a temperature and a \"not sure\" threshold." },
  ],
  projects: [
    { id: "ai-fitter", after: "b2-ai-03", name: "Line fitter", makes: "Drag in your own points, pick a learning rate, and watch the line fit itself while the loss curve drops beside it.", shelf: ["w_line", "b_line", "eta"], scene: { scene: "fitter", props: { mode: "project", project: true } } },
    { id: "ai-splitter", after: "b2-ai-07", name: "Two-color splitter", makes: "Draw dots of two colors (rings, stripes, an XOR checkerboard), train a 2 → 4 → 2 network, and watch the boundary bend round by round.", shelf: ["net_small"], scene: { scene: "tinynet", props: { project: true, pattern: "rings", hidden: 4 } } },
    { id: "ai-reader", after: "b2-ai-09", name: "Digit reader, version 1", makes: "The trained reader in your Notebook: draw a digit, see the confidence bars and the pixel map.", shelf: ["digit_reader", "acc_digits"], scene: { scene: "digits", props: { mode: "reader", project: true } } },
    { id: "ai-letters", after: "b2-ai-12", name: "Next-letter machine", makes: "Type or paste any text, train a tiny one-block letter model on it, sample at different temperatures, and read its bits per letter on the last 10%, held back from training.", shelf: ["letters_model", "bits_per_letter"], scene: { scene: "letters", props: { project: true } } },
    { id: "ai-notes", after: "b2-ai-16", name: "The build: Reader field notes", makes: "One Notebook page: the reader's scaling slope, its training compute, its calibration before and after temperature, the \"not sure\" threshold, and a loophole you found.", shelf: ["T_digits", "not_sure"], build: true, scene: { scene: "fieldnotes", props: { project: true } } },
  ],
  tools: [
    { id: "tinynet", name: "Tiny neural network", short: "Network", star: true },
    { id: "digits", name: "Digit reader", short: "Digits" },
    { id: "fitter", name: "Line fitter", short: "Fitter" },
    { id: "landscape", name: "Loss landscape", short: "Landscape" },
    { id: "etadial", name: "Learning-rate dial", short: "η dial" },
    { id: "backprop", name: "Backprop graph", short: "Backprop" },
    { id: "softmax", name: "Softmax bars", short: "Softmax" },
    { id: "words", name: "Word arrows", short: "Words" },
    { id: "attention", name: "Attention grid", short: "Attention" },
    { id: "transformer", name: "Transformer block view", short: "Blocks" },
    { id: "loglog", name: "Log-log plotter", short: "Log-log" },
    { id: "compute", name: "Compute meter", short: "Compute" },
    { id: "goals", name: "Goal sandbox", short: "Goals" },
    { id: "reliability", name: "Reliability diagram", short: "Reliability" },
  ],
  buildPieces: ["eta", "net_small", "digit_reader", "acc_digits", "alpha_digits", "C_digits", "T_digits", "not_sure"],
  lessons: AI_LESSONS,
};
