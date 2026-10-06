// Information and entropy (track 4, code `in`): the header of curriculum/specs/bento2/information.md as data, and its
// 12 lessons.
import type { B2Track } from "../../model";
import { INFORMATION_LESSONS } from "./lessons";

export const track: B2Track = {
  code: "in",
  pickerId: "info",
  name: "Information and entropy",
  about: "The math of surprise. It measures how much a message really tells you, which is why files compress, codes fix their own errors, and a model learns by being less surprised by the right answer.",
  build: {
    name: "The Shrinker",
    goal: "A code that shrinks your own message: it measures it, builds a code for it, predicts it, scores its own predictions in bits, and wraps the result so it survives noise.",
  },
  units: [
    { n: 1, name: "Surprise", adds: "The target line: letter counts and the message's entropy per letter, H_msg, the floor no letter-by-letter code can beat." },
    { n: 2, name: "Codes that shrink", adds: "The coder: a Huffman code from the counts, then a context model that predicts each letter from the one before, and an ideal coder that spends log₂(1/p) bits per letter." },
    { n: 3, name: "Learning and noise", adds: "The scorer and the armor: cross-entropy in bits per letter, and a Hamming (7, 4) wrapper that lets the shrunk file survive flipped bits." },
  ],
  projects: [
    { id: "in-profile", after: "b2-in-04", name: "Your surprise profile", makes: "Type a sentence: its letters counted, each letter's surprise as a bar, and its entropy per letter.", shelf: ["H_msg", "counts_msg"], scene: { scene: "in-shrinker", props: { stage: "profile" } } },
    { id: "in-code", after: "b2-in-06", name: "Your first code", makes: "The Huffman tree for your sentence, its code table, and the shrunk size next to 8 bits per letter. Shrinker v1.", shelf: ["code_msg"], scene: { scene: "in-shrinker", props: { stage: "code" } } },
    { id: "in-predict", after: "b2-in-08", name: "Predict me", makes: "A one-letter-context model trained on your sentence. Play the guessing game against it and watch its bits per letter fall below H_msg. Shrinker v2.", shelf: ["model_msg"], scene: { scene: "in-shrinker", props: { stage: "predict" } } },
    { id: "in-shrinker", after: "b2-in-12", name: "The build: the Shrinker", makes: "Your message in, measured, modeled, coded, armored, sent through noise, and decoded back out with flipped bits repaired.", shelf: ["final_bpl"], build: true, scene: { scene: "in-shrinker", props: { stage: "full" } } },
  ],
  tools: [
    { id: "in-guess", name: "Guess-the-message game", short: "Guess", star: true },
    { id: "in-surprise", name: "Surprise meter", short: "Surprise" },
    { id: "in-codes", name: "Code builder", short: "Codes" },
    { id: "in-bits", name: "Bit counter", short: "Bits" },
    { id: "in-errorlab", name: "Error-fix lab", short: "Errors" },
    { id: "in-shrinker", name: "The Shrinker", short: "Shrinker" },
  ],
  buildPieces: ["bits_flat", "H_msg", "code_msg", "model_msg", "xent_msg", "armor", "final_bpl"],
  lessons: INFORMATION_LESSONS,
};
