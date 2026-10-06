// The math behind AI, units 3 to 5 (b2-ai-08 to b2-ai-16), built from curriculum/specs/bento2/ai.md block by block.
import type { B2Lesson } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { group } from "../../steps";
import { aOrAn, cap } from "../../../curriculum/text";
import { num, sci, sciText, softmax, ten } from "./maths";
import { SCALING_ERR, TOP_BIN, readerParams } from "./digits";
import { dec } from "./lessons-a";

const g = (x: number) => group(x);
const aNum = (n: number) => `${aOrAn(n)} ${n}`;

/* ------------------------------------------------------------------ unit 3 ------------------------------------------------------------------ */

interface P08 { s: number; h: number }

export const ai08: B2Lesson<P08> = {
  id: "b2-ai-08", track: "ai", unit: 3, title: "Pictures as vectors: building the reader",
  youCan: "turn a picture into a vector and count what a network has to learn.",
  needs: ["b2-ai-05", "b2-ai-07", "b2-la-01", "b2-la-05"],
  tools: ["digits", "matrix"],
  play: { scene: "digits", props: { mode: "vector" },
    say: "Draw a digit on the 8 × 8 pad and watch it become 64 numbers from 0 to 1, laid out as a grid and then as one long column. Each of the 16 hidden neurons lights up by how well the picture matches its own weight picture." },
  guess: { scene: "digits", props: { mode: "count", quiet: true }, kind: "slider", min: 0, max: 3000, step: 10, start: 200, answer: 1210, near: 150,
    format: x => g(x),
    ask: "How many numbers does this 64 → 16 → 10 network learn? Slide to your guess.",
    revealProps: { mode: "count" },
    reveal: "1,024 + 16 + 160 + 10 = 1,210: a weight for every connection, and a bias for every neuron." },
  nameIt: {
    say: [
      "To a network, a picture is just a vector: one number per pixel.",
      "Each hidden neuron takes a dot product of the picture with its own weight picture, so it acts like a template detector. Every weight and bias is a number that training will set.",
    ],
    formula: ["For s × s pixels, h hidden neurons and 10 digits:", "parameters = s²·h + h + h·10 + 10"],
  },
  workIt: {
    reference: { s: 8, h: 16 },
    generate: (rng, i) => ({ s: i < 3 ? 8 : rng.pick([8, 12, 16, 28]), h: rng.pick([10, 16, 20, 32]) }),
    show: p => `Pictures of **${p.s} × ${p.s}** pixels, **${p.h}** hidden neurons, and 10 digits out.`,
    steps(p) {
      const s2 = p.s * p.s;
      return [
        wholeStep("in", "Inputs s²", s2, { hint: `${p.s} rows of ${p.s} pixels.`,
          slips: [slip("one row", p.s, `The picture has ${p.s} rows of ${p.s} pixels: s² = ${s2} inputs.`)] }),
        wholeStep("w1", "Layer 1 weights s²·h", s2 * p.h, { hint: `Each of the ${s2} inputs connects to each of the ${p.h} neurons.`,
          slips: [slip("added", s2 + p.h, "Count the connections: every input meets every hidden neuron, so multiply.")] }),
        wholeStep("b1", "Layer 1 biases h", p.h, { hint: "One bias per hidden neuron.",
          slips: [slip("per input", s2, "One bias per hidden neuron, not one per input.")] }),
        wholeStep("out", "Layer 2 weights and biases 10h + 10", 10 * p.h + 10, { hint: `${p.h} × 10 weights, plus a bias for each of the 10 outputs.`,
          slips: [slip("no biases", 10 * p.h, "Each output neuron also has a bias: add 10.")] }),
        wholeStep("total", "Total", s2 * p.h + p.h + 10 * p.h + 10, { hint: "Add the four counts.",
          slips: [
            slip("no biases", s2 * p.h + 10 * p.h, `Each neuron also has a bias: add h + 10 = ${p.h + 10}.`),
            slip("counted neurons", s2 + p.h + 10, `Count the connections, not the neurons. Each of the ${s2} inputs connects to each of the ${p.h} neurons.`),
          ] }),
      ];
    },
    scene: p => ({ scene: "digits", props: { mode: "count", h: p.h, s: p.s } }),
  },
  oracle: p => [p.s * p.s, p.s * p.s * p.h, p.h, p.h * 10 + 10, p.s * p.s * p.h + p.h + p.h * 10 + 10],
  useIt: {
    say: ["Set up the build's network in the Digit reader: choose h (16 to start), see its count, and save the untrained net as `digit_reader`.",
      "Draw a digit. Its guesses are random for now."],
    scene: { scene: "digits", props: { mode: "setup" } },
  },
  deeper: [
    "A first-layer weight row reshaped to 8 × 8 is literally a picture, and after training it looks like a blurry stroke detector.",
    "Convolution shares one small filter across every position: a 3 × 3 layer with c filters on a one-channel image has 9c + c parameters regardless of image size, and shifting the input shifts the output (translation equivariance).",
    "For MNIST-sized 28 × 28 images, the gap between 25,450 and a few hundred parameters is one reason convolutional nets won image tasks before transformers.",
  ],
};

interface P09 { N: number; B: number; E: number; d: number[]; G: number[][]; opts: [number, number][]; right: number }
const mistake = (d: number[], [i, j]: [number, number]) => `${cap(aNum(d[i]!))} read as ${d[j]}`;

export const ai09: B2Lesson<P09> = {
  id: "b2-ai-09", track: "ai", unit: 3, title: "Training and testing the reader",
  youCan: "train a network in mini-batches and judge it on data it has never seen.",
  needs: ["b2-ai-08", "b2-ai-03", "b2-pr-01", "st-sampdist"],
  tools: ["digits"],
  play: { scene: "digits", props: { mode: "train" },
    say: "Drag the training-set size and the hidden size, and the run replays from a fixed seed: the error on the training digits and on held-out digits redraw as it trains, with the held-out loss dashed. Below, the confusion grid fills in." },
  guess: { scene: "digits", props: { mode: "train", preset: "overfit", quiet: true }, kind: "choice", options: ["Keeps falling", "Flattens out", "Turns back up"], answer: 2,
    ask: "A large reader trains on only 100 digits, pass after pass. The training error heads for 0. What does the held-out loss do?",
    revealProps: { mode: "train", preset: "overfit" },
    reveal: "It falls for the first few passes, then turns back up: the reader memorizes its 100 digits and gets surer of its wrong answers on new ones. That is overfitting. The held-out error just stalls." },
  nameIt: {
    say: [
      "Real training uses a small random batch of examples for each step, which is cheaper and noisier than using them all. One pass through all the training images is an epoch.",
      "The only fair check is on images the network never trained on, and the confusion grid shows which digits it mixes up.",
    ],
    formula: ["Steps per epoch = N / B", "Total steps = E · N / B", "Accuracy = (sum of the diagonal) / (total)"],
  },
  workIt: {
    reference: { N: 1500, B: 50, E: 10, d: [1, 7, 9], G: [[48, 2, 0], [6, 40, 4], [0, 3, 47]], opts: [[1, 0], [0, 1], [1, 2], [2, 1]], right: 0 },
    generate(rng, i) {
      const N = rng.pick([600, 1200, 1500, 1800]), B = i < 3 ? rng.pick([50, 100]) : rng.pick([20, 30, 50, 60, 100]), E = rng.pick([5, 10, 20]);
      const d = rng.shuffle([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]).slice(0, 3).sort((a, b) => a - b);
      for (;;) {
        const G = [0, 1, 2].map(r => {
          const diag = rng.int(38, 49), off = rng.int(0, 50 - diag);
          const row = [0, 0, 0], others = [0, 1, 2].filter(c => c !== r);
          row[r] = diag; row[others[0]!] = off; row[others[1]!] = 50 - diag - off;
          return row;
        });
        const cells = [0, 1, 2].flatMap(r => [0, 1, 2].filter(c => c !== r).map(c => [r, c] as [number, number]));
        const top = Math.max(...cells.map(([r, c]) => G[r]![c]!));
        const best = cells.filter(([r, c]) => G[r]![c] === top);
        if (best.length !== 1) continue;
        const [r, c] = best[0]!;
        const rest = rng.shuffle(cells.filter(([a, b]) => !(a === r && b === c) && !(a === c && b === r))).slice(0, 2);
        const opts = rng.shuffle([[r, c], [c, r], ...rest] as [number, number][]);
        return { N, B, E, d, G, opts, right: opts.findIndex(([a, b]) => a === r && b === c) };
      }
    },
    show: p => `**${g(p.N)}** training images, batches of **${p.B}**, **${p.E}** epochs. Then 150 held-out images of ${p.d[0]}, ${p.d[1]} and ${p.d[2]}, in the grid: rows are the true digit, columns what the reader said.`,
    steps(p) {
      const trace = p.G[0]![0]! + p.G[1]![1]! + p.G[2]![2]!, [r, c] = p.opts[p.right]!;
      const flip = p.opts.findIndex(([a, b]) => a === c && b === r);
      return [
        wholeStep("spe", "Steps per epoch", p.N / p.B, { hint: `${g(p.N)} images, ${p.B} per step.`,
          slips: [slip("one per image", p.N, `Each step uses a whole batch of ${p.B} images, so there are N / B steps.`)] }),
        wholeStep("steps", "Total steps", (p.E * p.N) / p.B, { hint: `${p.N / p.B} steps a pass, ${p.E} passes.`,
          slips: [slip("one epoch", p.N / p.B, `That's one epoch. Multiply by E = ${p.E} epochs.`)] }),
        numStep("acc", "Held-out accuracy", (100 * trace) / 150, 1, { unit: "%", hint: `The diagonal, ${p.G[0]![0]} + ${p.G[1]![1]} + ${p.G[2]![2]}, over all 150.`,
          slips: [0, 1, 2].map(k => slip("one row", (100 * p.G[k]![k]!) / 50, "Accuracy uses the whole grid: all correct (the diagonal) over all 150 images.")) }),
        tapStep("worst", "Most common mistake", p.opts.map(o => mistake(p.d, o)), p.right, { hint: "Find the biggest number off the diagonal. Its row is the true digit.",
          slips: [slip("rows and columns", flip, `Rows are the true digit. The ${p.G[r]![c]} sits in row ${p.d[r]}, column ${p.d[c]}: ${aNum(p.d[r]!)} read as ${p.d[c]}.`)] }),
      ];
    },
    scene: p => ({ scene: "confusion", props: { d: p.d.join(","), g: p.G.map(row => row.join(",")).join(";") } }),
  },
  oracle: p => {
    const tr = p.G.reduce((s, row, k) => s + row[k]!, 0), tot = p.G.flat().reduce((a, b) => a + b, 0);
    let best = [0, 1], bv = -1;
    p.G.forEach((row, a) => row.forEach((v, b) => { if (a !== b && v > bv) { bv = v; best = [a, b]; } }));
    return [Math.floor(p.N / p.B), Math.floor((p.E * p.N) / p.B), (100 * tr) / tot, p.opts.findIndex(([a, b]) => a === best[0] && b === best[1])];
  },
  useIt: {
    say: ["Train the build for real on the bundled digits, read its held-out accuracy, and find its most confused pair in the full 10 × 10 grid. Draw that pair yourself and look at the pixel maps.",
      "Save `digit_reader` (trained) and `acc_digits`. This is the build's first milestone: the Digit reader, version 1."],
    project: "ai-reader",
  },
  deeper: [
    "The pixel map is the gradient of the chosen digit's score with respect to each input pixel (a saliency map): one backward pass to the inputs instead of the weights. The mini-batch gradient is an unbiased estimate of the full gradient, with variance shrinking like 1/B.",
    "Classical theory says held-out error ≈ train error plus a complexity term (VC dimension, Rademacher bounds), but those bounds are vacuous for large networks, which fit even random labels (Zhang et al. 2017) yet generalize on real ones.",
    "\"Double descent\" (Belkin et al. 2019): held-out error can fall again as models grow past the point where they fit the training set exactly. Why big networks generalize is an open research question.",
  ],
};

/* ------------------------------------------------------------------ unit 4 ------------------------------------------------------------------ */

const FIVES: [number, number][] = [[3, 4], [4, 3], [-3, 4], [-4, 3], [0, 5], [5, 0]];
const VECS: [number, number][] = [...FIVES, [5, 12], [12, 5], [6, 8], [8, 6]];
const ANALOGIES = [["king", "man", "woman", "queen", "prince", "girl"], ["paris", "france", "italy", "rome", "milan", "spain"], ["walked", "walk", "swim", "swam", "swimming", "ran"], ["uncle", "man", "woman", "aunt", "nephew", "girl"]];
interface P10 { u: number[]; v: number[]; words: string[]; k: number[]; m: number[]; w: number[]; cands: { name: string; at: number[] }[] }
const vec = (a: number[]) => `(${a.map(num).join(", ")})`;
const res10 = (p: P10) => [p.k[0]! - p.m[0]! + p.w[0]!, p.k[1]! - p.m[1]! + p.w[1]!];
const d2 = (a: number[], b: number[]) => (a[0]! - b[0]!) ** 2 + (a[1]! - b[1]!) ** 2;
const distText = (sq: number) => (Number.isInteger(Math.sqrt(sq)) ? String(Math.sqrt(sq)) : `√${sq} ≈ ${Math.sqrt(sq).toFixed(2)}`);

export const ai10: B2Lesson<P10> = {
  id: "b2-ai-10", track: "ai", unit: 4, title: "Embeddings: words as arrows",
  youCan: "measure how similar two embedded words are and do arrow arithmetic on meanings.",
  needs: ["b2-la-03", "b2-ai-08"],
  tools: ["words"],
  play: { scene: "words", props: {},
    say: "About 50 words as arrows. Tap two words to see the angle between them and its cosine. Then take king, subtract man, add woman, and see where the tip lands and which word is nearest." },
  guess: { scene: "words", props: { quiet: true }, kind: "choice", options: ["dog", "car", "kitten"], answer: 2,
    ask: "Which word lies closest in angle to \"cat\"? The arrows are hidden for now.",
    revealProps: { pair: "cat,kitten", show: "dog,car" },
    reveal: "Kitten: its cosine with cat is 1.00, dog's is 0.88 and car's is −0.44. This map is a small hand-made one laid out like real word vectors, so its angles are only a sketch of real ones." },
  nameIt: {
    say: [
      "A model stores each word as a list of numbers, an embedding, learned so that words used in similar places end up pointing in similar directions.",
      "Similarity is the cosine of the angle between arrows, and some relations show up as consistent offsets you can add and subtract.",
    ],
    formula: ["cos θ = (u · v) / (|u| |v|)", "Embedding lookup: a one-hot vector times the embedding matrix picks one row"],
  },
  workIt: {
    reference: { u: [3, 4], v: [4, 3], words: ANALOGIES[0]!, k: [5, 6], m: [4, 1], w: [4, 3], cands: [{ name: "queen", at: [5, 7] }, { name: "prince", at: [6, 5] }, { name: "girl", at: [2, 4] }] },
    generate(rng, i) {
      const list = i < 3 ? FIVES : VECS;
      const u = rng.pick(list);
      let v: [number, number];
      do v = rng.pick(list); while (v === u);
      const words = rng.pick(ANALOGIES);
      for (;;) {
        const k = [rng.int(0, 8), rng.int(0, 8)], m = [rng.int(0, 8), rng.int(0, 8)], w = [rng.int(0, 8), rng.int(0, 8)];
        const r = [k[0]! - m[0]! + w[0]!, k[1]! - m[1]! + w[1]!];
        if (r.some(x => x < 0 || x > 8) || (m[0] === w[0] && m[1] === w[1])) continue;
        const off = rng.pick([[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]);
        const near = [r[0]! + off[0]!, r[1]! + off[1]!];
        if (near.some(x => x < 0 || x > 8)) continue;
        const far: number[][] = [];
        for (let t = 0; t < 50 && far.length < 2; t++) {
          const c = [rng.int(0, 8), rng.int(0, 8)];
          if (d2(c, r) >= 4 && !far.some(f => f[0] === c[0] && f[1] === c[1])) far.push(c);
        }
        if (far.length < 2) continue;
        const cands = rng.shuffle([{ name: words[3]!, at: near }, { name: words[4]!, at: far[0]! }, { name: words[5]!, at: far[1]! }]);
        return { u: [...u], v: [...v], words, k, m, w, cands };
      }
    },
    show: p => `u = ${vec(p.u)} and v = ${vec(p.v)}. Then on a word map: ${p.words[0]} ${vec(p.k)}, ${p.words[1]} ${vec(p.m)}, ${p.words[2]} ${vec(p.w)}, and ${p.cands.map(c => `${c.name} ${vec(c.at)}`).join(", ")}.`,
    steps(p) {
      const dot = p.u[0]! * p.v[0]! + p.u[1]! * p.v[1]!, lu = Math.hypot(p.u[0]!, p.u[1]!), lv = Math.hypot(p.v[0]!, p.v[1]!), r = res10(p);
      const dist = p.cands.map(c => d2(c.at, r)), right = dist.indexOf(Math.min(...dist));
      const order = [...dist.keys()].sort((a, b) => dist[a]! - dist[b]!), second = order[1]!;
      const [K, M, W] = p.words;
      return [
        wholeStep("dot", "u · v", dot, { hint: `${num(p.u[0]!)}·${num(p.v[0]!)} + ${num(p.u[1]!)}·${num(p.v[1]!)}.`,
          slips: [slip("crossed", p.u[0]! * p.v[1]! + p.u[1]! * p.v[0]!, "Multiply matching entries, first with first and second with second, then add.")] }),
        multiStep("len", "|u| and |v|", [lu, lv], "whole", { boxes: ["|u|", "|v|"], hint: "Length is the square root of the sum of the squares.",
          slips: [slip("no root", [lu * lu, lv * lv], `Take the square root: |u| = √(${num(p.u[0]!)}² + ${num(p.u[1]!)}²) = ${lu}.`)] }),
        numStep("cos", "cos θ", dot / (lu * lv), 2, { ask: "A fraction or 2 decimals.", hint: `${num(dot)} / (${lu} · ${lv}).`,
          slips: [slip("no lengths", dot, `Divide by both lengths so only the angle counts: ${num(dot)}/(${lu}·${lv}).`)] }),
        multiStep("arith", `${K} − ${M} + ${W}`, r, "whole", { boxes: ["first", "second"], hint: `Entry by entry: ${p.k[0]} − ${p.m[0]} + ${p.w[0]}, and ${p.k[1]} − ${p.m[1]} + ${p.w[1]}.`,
          slips: [slip("added", [p.k[0]! + p.m[0]! + p.w[0]!, p.k[1]! + p.m[1]! + p.w[1]!], `Subtract ${M}, then add ${W}: (${p.k[0]} − ${p.m[0]} + ${p.w[0]}, ${p.k[1]} − ${p.m[1]} + ${p.w[1]}).`)] }),
        tapStep("near", "Nearest word", p.cands.map(c => c.name), right, { hint: `Measure each word's distance to ${vec(r)}.`,
          slips: [slip("not nearest", second, `Measure distance to ${vec(r)}: ${p.cands[right]!.name} is ${dist[right] === 0 ? "right on it" : `${distText(dist[right]!)} away`}, ${p.cands[second]!.name} is ${distText(dist[second]!)}.`)] }),
      ];
    },
    scene: p => ({ scene: "words", props: { u: p.u.join(","), v: p.v.join(",") } }),
  },
  oracle: p => {
    const r = [p.k[0]! - p.m[0]! + p.w[0]!, p.k[1]! - p.m[1]! + p.w[1]!];
    const ds = p.cands.map(c => Math.hypot(c.at[0]! - r[0]!, c.at[1]! - r[1]!));
    return [p.u[0]! * p.v[0]! + p.u[1]! * p.v[1]!, Math.hypot(p.u[0]!, p.u[1]!), Math.hypot(p.v[0]!, p.v[1]!),
      (p.u[0]! * p.v[0]! + p.u[1]! * p.v[1]!) / (Math.hypot(p.u[0]!, p.u[1]!) * Math.hypot(p.v[0]!, p.v[1]!)), ...r, ds.indexOf(Math.min(...ds))];
  },
  useIt: {
    say: ["Find one offset that works in the Word arrows map (a country to its capital, a verb to its past tense) and one that doesn't. Save the working offset as `offset_word`.",
      "Read the map honestly: the famous analogies work less cleanly than the headlines say, especially once the input words are allowed as answers."],
    scene: { scene: "words", props: { save: true } },
  },
  deeper: [
    "Skip-gram with negative sampling (word2vec) implicitly factorizes a matrix of shifted pointwise mutual information, PMI(w, c) − log k (Levy and Goldberg 2014), linking embeddings to the SVD (b2-la-17) and to mutual information (b2-in-10).",
    "Embedding tables hold vocabulary × d numbers, often the largest single piece of a small language model. In a transformer each token's vector changes layer by layer with context, so \"bank\" ends up in different places in \"river bank\" and \"bank loan\".",
  ],
};

interface P11 { q: number[]; K: number[][]; v: number[] }
const dots11 = (p: P11) => p.K.map(k => k.reduce((s, x, j) => s + x * p.q[j]!, 0));

export const ai11: B2Lesson<P11> = {
  id: "b2-ai-11", track: "ai", unit: 4, title: "Attention: each word looks up the others",
  youCan: "compute an attention output: scores, softmax weights, weighted average.",
  needs: ["b2-ai-10", "b2-ai-07", "b2-la-03"],
  tools: ["attention", "softmax"],
  play: { scene: "attention", props: { at: 1 },
    say: "A short sentence, \"the cat sat because it was tired\", with each word's query and key arrows. Tap a word and its row of the grid lights up across the others; drag its query arrow and the weights shift live." },
  guess: { scene: "attention", props: { at: 4, quiet: true }, kind: "choice", options: ["the", "cat", "sat", "because", "was", "tired"], answer: 1,
    ask: "Before the row for \"it\" lights up, which word do you think it attends to most?",
    revealProps: { at: 4 },
    reveal: "\"cat\", with the largest weight in the row. In this toy the arrows are set by hand; a trained model learns arrows that do the same job." },
  nameIt: {
    say: [
      "Attention lets every position ask a question (query) and compare it with every position's label (key).",
      "The match scores go through softmax to become weights, and the answer is the weighted average of the positions' contents (values). Scaling by √d keeps the scores from getting huge as vectors get longer.",
    ],
    formula: ["sᵢ = (q · kᵢ) / √d", "wᵢ = softmax(s)ᵢ, output = Σ wᵢ vᵢ", "In matrix form: softmax(QKᵀ/√d) V"],
  },
  workIt: {
    reference: { q: [1, 0, 1, 0], K: [[1, 0, 1, 0], [0, 1, 0, 1], [1, 1, 0, 0]], v: [10, 0, 4] },
    generate(rng, i) {
      const e = () => rng.pick([-1, 0, 1, 2]);
      for (;;) {
        const q = [e(), e(), e(), e()], K = [0, 1, 2].map(() => [e(), e(), e(), e()]);
        const p = { q, K, v: [rng.int(0, 12), rng.int(0, 12), rng.int(0, 12)] };
        const d = dots11(p);
        if (d.some(x => x < 0 || x > 4)) continue;
        const pairs = Number(d[0] === d[1]) + Number(d[1] === d[2]) + Number(d[0] === d[2]);
        if (i < 3 ? pairs === 1 : pairs < 3) return p;
      }
    },
    show: p => `d = 4, so √d = 2. Query **q = ${vec(p.q)}**; keys k₁ = ${vec(p.K[0]!)}, k₂ = ${vec(p.K[1]!)}, k₃ = ${vec(p.K[2]!)}; values **v = ${vec(p.v)}**.`,
    steps(p) {
      const d = dots11(p), s = d.map(x => x / 2), w = softmax(s), out = w.reduce((t, x, k) => t + x * p.v[k]!, 0);
      const ws = s.reduce((a, b) => a + b, 0), avg = (p.v[0]! + p.v[1]! + p.v[2]!) / 3, raw = softmax(d).reduce((t, x, k) => t + x * p.v[k]!, 0);
      return [
        multiStep("dots", "Raw dot products", d, "whole", { boxes: ["q · k₁", "q · k₂", "q · k₃"], hint: "Multiply matching entries and add, for each key." }),
        multiStep("scaled", "Scaled scores", s, 1, { boxes: ["s₁", "s₂", "s₃"], hint: "Divide each by √d = 2.",
          slips: [slip("unscaled", d, "Divide by √d = 2 before softmax."), slip("by d", d.map(x => x / 4), "Divide by √d = 2, not by d = 4.")] }),
        numStep("w1", "Weight on position 1", w[0]!, 2, { hint: `e^${dec(s[0]!, 1)} over e^${dec(s[0]!, 1)} + e^${dec(s[1]!, 1)} + e^${dec(s[2]!, 1)}.`,
          slips: [ws > 0 && slip("scores as weights", s[0]! / ws, "Scores become weights through softmax: e to each score, over the total.")] }),
        numStep("out", "Output", out, 1, { ask: "To 1 decimal: rounding the weights first can move it a little.", hint: "Each value times its weight, added up.",
          slips: [
            Math.abs(avg - out) > 0.25 && slip("plain average", avg, "Attention is a weighted average: the weights come from softmax of the scores, not 1/3 each."),
            Math.abs(raw - out) > 0.25 && Math.abs(raw - avg) > 0.25 && slip("unscaled", raw, "Divide the scores by √d = 2 before softmax."),
          ] }),
      ];
    },
    scene: () => ({ scene: "attention", props: { at: 4 } }),
  },
  oracle: p => {
    const d = p.K.map(k => k[0]! * p.q[0]! + k[1]! * p.q[1]! + k[2]! * p.q[2]! + k[3]! * p.q[3]!);
    const e = d.map(x => Math.exp(x / 2)), t = e.reduce((a, b) => a + b, 0), w = e.map(x => x / t);
    return [...d, ...d.map(x => x / 2), w[0]!, w[0]! * p.v[0]! + w[1]! * p.v[1]! + w[2]! * p.v[2]!];
  },
  useIt: {
    say: ["Turn on patch mode in the Digit reader: the 8 × 8 digit is cut into 16 patches of 2 × 2, and the grid shows which patches each patch attends to. Train it and compare its held-out accuracy with `acc_digits`; save it as `acc_patches`.",
      "With this little data the plain reader often wins, and that's a real finding."],
    scene: { scene: "digits", props: { mode: "patches" } },
  },
  deeper: [
    "Why √d: if q and k have independent entries with mean 0 and variance 1, q · k has variance d, so dividing by √d keeps scores near unit size and softmax out of its flat, saturated zone.",
    "Self-attention treats its inputs as a set (permutation equivariant), so position must be added (sinusoidal or rotary encodings). Causal masking sets future scores to −∞. Cost is about n²d for n tokens, quadratic in length (b2-cs-08, Growth race), which drives research on linear and sparse attention.",
    "Attention can be read as a kernel smoother: Nadaraya-Watson regression with a learned kernel.",
  ],
};

interface P12 { L: number; d: number; V: number; bits: number }

export const ai12: B2Lesson<P12> = {
  id: "b2-ai-12", track: "ai", unit: 4, title: "The transformer: stack, add, predict the next word",
  youCan: "describe a transformer block and count its parameters.",
  needs: ["b2-ai-11", "b2-ai-07", "b2-in-08"],
  tools: ["transformer", "attention"],
  play: { scene: "transformer", props: { d: 64, L: 2, V: 100 },
    say: "A live stack of blocks: attention, add, a small two-layer network (MLP), add, repeated L times, with a parameter count on every box. Drag the width d and the depth L and watch the counts grow. Type a prompt to see next-letter bars at the top, with a temperature slider." },
  guess: { scene: "transformer", props: { d: 32, L: 2, V: 100, quiet: true }, kind: "choice", options: ["Doubles", "Triples", "Quadruples"], answer: 2,
    ask: "Double the width d. What happens to one block's parameter count?",
    revealProps: { d: 64, L: 2, V: 100, compare: 32 },
    reveal: "Each block holds 12d², so it exactly quadruples. The embeddings, V·d, only double, so the total grows a little less." },
  nameIt: {
    say: [
      "A transformer repeats one block: attention mixes information between positions, then a small network processes each position, and each result is added back onto its input (a residual), so information can pass straight through.",
      "It is trained to predict the next token, scored by cross-entropy.",
    ],
    formula: ["Per block: attention 4d² + MLP 8d² (d → 4d → d) = 12d²", "Total ≈ 12Ld² + V·d (embeddings), ignoring biases and norms", "Perplexity = 2^(bits per token)"],
  },
  workIt: {
    reference: { L: 2, d: 64, V: 100, bits: 3 },
    generate: (rng, i) => ({ L: i < 3 ? rng.pick([1, 2]) : rng.pick([1, 2, 4, 6]), d: i < 3 ? rng.pick([16, 32]) : rng.pick([16, 32, 64, 128]), V: rng.pick([50, 100, 256]), bits: rng.int(1, 5) }),
    show: p => `L = ${p.L} ${p.L === 1 ? "block" : "blocks"}, width d = ${p.d}, a vocabulary of V = ${p.V} tokens, and a model that scores ${p.bits} ${p.bits === 1 ? "bit" : "bits"} per token.`,
    steps(p) {
      const d2 = p.d * p.d;
      return [
        wholeStep("att", "Attention per block, 4d²", 4 * d2, { hint: `Four matrices, each ${p.d} × ${p.d}.`,
          slips: [slip("4d", 4 * p.d, "Each of the four matrices is d × d, so 4d².")] }),
        wholeStep("mlp", "MLP per block, 8d²", 8 * d2, { hint: `d · 4d in and 4d · d out.`,
          slips: [slip("one layer", 4 * d2, "The MLP widens to 4d: d·4d in and 4d·d out, 8d² in all.")] }),
        wholeStep("blocks", "All blocks, 12Ld²", 12 * p.L * d2, { hint: `${g(12 * d2)} per block, ${p.L} ${p.L === 1 ? "block" : "blocks"}.`,
          slips: [p.L > 1 && slip("forgot L", 12 * d2, `Every block has its own weights: multiply by L = ${p.L}.`)] }),
        wholeStep("total", "Total with embeddings", 12 * p.L * d2 + p.V * p.d, { hint: `Add V·d = ${p.V} · ${p.d}.`,
          slips: [slip("V·d²", 12 * p.L * d2 + p.V * d2, "The embedding table has one row of d numbers per token: V·d.")] }),
        wholeStep("ppl", "Perplexity", 2 ** p.bits, { hint: `2 to the power ${p.bits}.`,
          slips: [p.bits !== 2 && slip("2 × bits", 2 * p.bits, `Perplexity is 2 to the power of the bits: 2^${p.bits}, not 2 × ${p.bits}.`)] }),
      ];
    },
    scene: p => ({ scene: "transformer", props: { d: p.d, L: p.L, V: p.V } }),
  },
  oracle: p => [4 * p.d * p.d, 8 * p.d * p.d, 12 * p.L * p.d * p.d, 12 * p.L * p.d * p.d + p.V * p.d, 2 ** p.bits],
  useIt: {
    say: ["The Next-letter machine: train a one-block letter model on text you type, sample from it at temperatures 0.5, 1 and 1.5, and read its bits per letter on the last 10% of the text, held back from training.",
      "A perplexity of 8 means \"as unsure as picking among 8 equally likely letters\". Save `letters_model` and `bits_per_letter`."],
    project: "ai-letters",
  },
  deeper: [
    "The count checks out at scale: GPT-2 small has L = 12, d = 768, so 12·12·768² ≈ 84.9M in the blocks, plus 50,257 × 768 ≈ 38.6M token embeddings and 1,024 × 768 ≈ 0.8M position embeddings, about 124M, matching its published size.",
    "Layer normalization rescales each vector to mean 0 and variance 1. Residual streams make the network a sum of many paths, which is why deep stacks train. Sampling at temperature T divides the logits by T; T → 0 is greedy decoding.",
    "Transformers with enough precision and steps can simulate many algorithms, while what they reliably learn to do in practice is an active research area.",
  ],
};

/* ------------------------------------------------------------------ unit 5 ------------------------------------------------------------------ */

interface P13 { p: number; k: number; E1: number; r: number }
const rText = (r: number) => (r === 0.5 ? "1/2" : "1/4");
const halvingChoice = (q: P13) => { const decades = q.k / Math.log2(1 / q.r); return decades === 0.5 ? 1 : decades === 1 ? 0 : decades === 2 ? 2 : 3; };
export const HALVE = ["10", "√10 ≈ 3.16", "100", "1,000"];

export const ai13: B2Lesson<P13> = {
  id: "b2-ai-13", track: "ai", unit: 5, title: "Scaling laws: straight lines on a log-log plot",
  youCan: "fit a power law on a log-log plot, read its slope, and say how far the line can be trusted.",
  needs: ["pc-logs", "pc-semilog", "b2-ai-09", "b2-mv-17"],
  tools: ["loglog", "digits"],
  play: { scene: "loglog", props: { mode: "demo" },
    say: "Points for held-out error against training-set size, on ordinary axes (a curve that flattens) and on log-log axes (nearly a straight line). Drag the line's ends through the log-log points, read its slope, and extend it into the shaded \"no data here\" zone." },
  guess: { scene: "loglog", props: { mode: "reader", upto: 3, quiet: true }, kind: "slider", min: 0, max: 20, step: 0.5, start: 12, answer: SCALING_ERR[3]! * 100, near: 1.5, unit: "%",
    format: x => x.toFixed(1),
    ask: "The reader has been trained on 100, 300 and 1,000 digits. What will its held-out error be at 3,000? Slide to your guess.",
    revealProps: { mode: "reader", upto: 4 },
    reveal: `The real run lands at ${(SCALING_ERR[3]! * 100).toFixed(1)}%. Measured: it sits close to the line through the first three. Open: whether it keeps following that line far past the data.` },
  nameIt: {
    say: [
      "Measured: in many cases a model's error falls like a power of its size, data or compute. A power law is a straight line on log-log axes, and its slope says how much better each tenfold increase makes things.",
      "These are fits to experiments, not laws of nature: they hold over the range measured, and there is usually a floor of error that never goes away.",
    ],
    formula: ["E = a · N^(−α), so log E = log a − α log N", "Slope = (log E₂ − log E₁) / (log N₂ − log N₁) = −α"],
  },
  workIt: {
    reference: { p: 4, k: 2, E1: 0.32, r: 0.5 },
    generate: (rng, i) => ({ p: rng.int(3, 6), k: rng.pick([1, 2]), E1: rng.pick([0.8, 0.64, 0.48, 0.32]), r: i < 3 ? 0.5 : rng.pick([0.5, 0.25]) }),
    show: q => `Held-out error **${dec(q.E1)}** at **${ten(q.p)}** images and **${dec(q.E1 * q.r)}** at **${ten(q.p + q.k)}**.`,
    steps(q) {
      const slope = Math.log10(q.r) / q.k, far = q.E1 * q.r * q.r, times = q.k === 1 ? "10" : "100";
      return [
        numStep("slope", "Slope", slope, 2, { ask: "Use log base 10 on both axes.", hint: `(log ${dec(q.E1 * q.r)} − log ${dec(q.E1)}) / (${q.p + q.k} − ${q.p}).`,
          slips: [
            slip("no logs", (q.E1 * q.r - q.E1) / q.k, `On log-log axes the rise is log E₂ − log E₁ = log(${rText(q.r)}), not E₂ − E₁.`),
            q.k === 2 && slip("one decade", Math.log10(q.r), `The run is 2 decades, from ${ten(q.p)} to ${ten(q.p + 2)}: divide by 2.`),
          ] }),
        tapStep("inside", "Inside the measured range?", ["Yes", "No"], 1, { ask: `Is ${ten(q.p + 2 * q.k)} between ${ten(q.p)} and ${ten(q.p + q.k)}?`, hint: "Where does the data stop?",
          slips: [slip("yes", 0, `The data stops at N₂ = ${ten(q.p + q.k)}. ${ten(q.p + 2 * q.k)} is in the shaded zone, so the line is only a guess there.`)] }),
        numStep("far", `If the line kept going: error at ${ten(q.p + 2 * q.k)}`, far, 2, { hint: `Another ${times} times more data multiplies the error by ${rText(q.r)} again.`,
          slips: [slip("hits 0", 0, `If the line kept going it would never reach 0: each further ${times} times more data multiplies the error by ${rText(q.r)} again, to ${dec(q.E1)} · (${rText(q.r)})² = ${dec(far)}. Whether real data follows it that far is the open part.`)] }),
        tapStep("halve", "Data multiplier to halve the error", HALVE, halvingChoice(q), { hint: `Each ${times} times more data multiplies the error by ${rText(q.r)}.` }),
      ];
    },
    scene: q => ({ scene: "loglog", props: { mode: "problem", p: q.p, k: q.k, E1: q.E1, r: q.r } }),
  },
  oracle: q => {
    const half = q.k / (Math.log(1 / q.r) / Math.log(2));
    return [(Math.log10(q.E1 * q.r) - Math.log10(q.E1)) / q.k, q.p + q.k < q.p + 2 * q.k ? 1 : 0, q.E1 * q.r ** 2, [1, 0.5, 2, 3].indexOf(half)];
  },
  useIt: {
    say: ["Train the build on 100, 300, 1,000 and 3,000 digits, plot held-out error on the Log-log plotter, fit the slope, and save `alpha_digits`.",
      "Then mark where the line would have to go for 0 error, and notice that it never gets there."],
    scene: { scene: "loglog", props: { mode: "reader", upto: 4, save: true } },
  },
  deeper: [
    "Measured: Kaplan et al. (2020) fit language-model held-out loss as power laws in parameters, data and compute with exponents near 0.076, 0.095 and 0.050 over several orders of magnitude; Hoffmann et al. (2022, \"Chinchilla\") fit L(N, D) = E + A/N^α + B/D^β and found compute-optimal training uses roughly 20 tokens per parameter.",
    "Minimizing L subject to C ≈ 6ND (a Lagrange problem, b2-mv-15) gives N_opt ∝ C^(β/(α + β)).",
    "Open: why power laws appear at all (one proposal ties α to the intrinsic dimension of the data, Sharma and Kaplan 2020), whether they continue, and how a smooth fall in loss turns into specific new abilities.",
  ],
};

interface P14 { m: number; a: number; n: number; b: number; s: number }
const secs14 = (p: P14) => 6 * p.m * p.n * 10 ** (p.a + p.b - p.s);

export const ai14: B2Lesson<P14> = {
  id: "b2-ai-14", track: "ai", unit: 5, title: "Optimization at scale: the same step, a billion times",
  youCan: "estimate the compute a training run needs and explain why big models use small noisy batches.",
  needs: ["b2-ai-09", "b2-ai-03", "b2-mv-14", "b2-pr-01", "b2-cs-08"],
  tools: ["compute", "landscape"],
  play: { scene: "batch", props: { B: 4 },
    say: "The loss-landscape ball, but each step uses a random batch, so the arrow wobbles. Drag the batch size and watch the wobble shrink; switch between plain SGD, momentum and Adam and race them down a long narrow valley." },
  guess: { scene: "batch", props: { B: 4, quiet: true }, kind: "slider", min: 0.1, max: 1, step: 0.05, start: 0.8, answer: 0.5, near: 0.08,
    format: x => `${x.toFixed(2)} as big`,
    ask: "The batch size goes from 4 to 16. How big does the wobble get, compared with now?",
    revealProps: { B: 16, compare: 4 },
    reveal: "Half as big, not a quarter: batch noise shrinks like 1/√B, and √16 / √4 = 2." },
  nameIt: {
    say: [
      "Giant models learn with the same downhill step as your line fitter, just with billions of weights and noisy mini-batches.",
      "The cost of training is easy to estimate: about 6 arithmetic operations per parameter per training token (2 for the forward pass, about 4 for backprop). Smarter optimizers like Adam give each weight its own step size from the history of its gradients.",
    ],
    formula: ["C ≈ 6 N D floating-point operations (FLOPs)", "time = C / speed", "Batch noise ∝ 1/√B"],
  },
  workIt: {
    reference: { m: 1, a: 8, n: 2, b: 9, s: 15 },
    generate(rng, i) {
      for (;;) {
        const p = { m: i < 3 ? 1 : rng.pick([1, 2, 5]), a: rng.int(6, 9), n: i < 3 ? 1 : rng.pick([1, 2, 5]), b: rng.int(8, 11), s: rng.pick([14, 15, 16]) };
        const e = p.a + p.b - p.s, base = 6 * p.m * p.n;
        if (e < 0 && base % 10 ** -e !== 0) continue;
        const sec = secs14(p);
        if (Math.round(sec) % 60 !== 0 || sec / 60 > 1e8 || sec < 60) continue;
        if (p.n * 10 ** p.b < p.m * 10 ** p.a) continue;
        return p;
      }
    },
    show: p => `N = ${sciText(p.m, p.a)} parameters, D = ${sciText(p.n, p.b)} training tokens, on a computer doing ${ten(p.s)} FLOP/s.`,
    steps(p) {
      const [cm, ce] = sci(6 * p.m * p.n * 10 ** (p.a + p.b)), sec = Math.round(secs14(p));
      const [fm, fe] = sci(p.m * p.n * 10 ** (p.a + p.b)), [hm, he] = sci(2 * p.m * p.n * 10 ** (p.a + p.b));
      return [
        multiStep("C", "C = 6ND", [cm, ce], 1, { boxes: ["number in front", "power of ten"], ask: "In scientific notation.", done: `C = ${sciText(cm, ce)} FLOPs`,
          hint: `6 × ${p.m} × ${p.n} in front; add the powers of ten, ${p.a} + ${p.b}.`,
          slips: [
            slip("forgot the 6", [fm, fe], "Each parameter costs about 6 operations per token: 2 forward, 4 backward."),
            slip("multiplied exponents", [cm, p.a * p.b], `Multiplying powers of ten adds exponents: ${ten(p.a)} · ${ten(p.b)} = ${ten(p.a + p.b)}.`),
            slip("forward only", [hm, he], "Training also runs backward, about twice the forward cost again: 6ND."),
          ] }),
        wholeStep("sec", "Seconds", sec, { hint: `C / ${ten(p.s)}.` }),
        wholeStep("min", "Minutes", sec / 60, { hint: "60 seconds a minute.",
          slips: [slip("times 60", sec * 60, "A minute is 60 seconds, so divide by 60.")] }),
        fracStep("tpp", "Tokens per parameter D/N", (p.n * 10 ** p.b) / (p.m * 10 ** p.a), { hint: `${sciText(p.n, p.b)} / ${sciText(p.m, p.a)}.`,
          slips: [slip("N/D", (p.m * 10 ** p.a) / (p.n * 10 ** p.b), "Tokens per parameter is D over N.")] }),
      ];
    },
    scene: p => ({ scene: "compute", props: { m: p.m, a: p.a, n: p.n, b: p.b, s: p.s } }),
  },
  oracle: p => {
    const C = 6 * p.m * 10 ** p.a * p.n * 10 ** p.b, e = Math.floor(Math.log10(C) + 1e-9);
    return [Math.round((C / 10 ** e) * 10) / 10, e, C / 10 ** p.s, C / 10 ** p.s / 60, (p.n * 10 ** p.b) / (p.m * 10 ** p.a)];
  },
  useIt: {
    say: ["Estimate the build's own training compute: 6 × 1,210 parameters × 3,000 training digits × 20 passes ≈ 4.4 × 10⁸ FLOPs, counting each digit as one example. At a phone's peak of about 10¹² FLOP/s that's under a millisecond; in the browser it takes a second or so, because real code rarely gets near peak.",
      "Save `C_digits`, then set it beside a published large run on the Compute meter's log scale."],
    saves: { name: "C_digits", value: () => 6 * readerParams(16) * 3000 * 20, unit: "FLOPs", note: "6 × parameters × digits × passes for the build's reader" },
    scene: { scene: "compute", props: { m: 4.4, a: 0, n: 1, b: 8, s: 12, build: true } },
  },
  deeper: [
    "Adam: m ← β₁m + (1 − β₁)g, v ← β₂v + (1 − β₂)g², θ ← θ − η m̂/(√v̂ + ε), with bias corrections m̂ = m/(1 − β₁ᵗ), v̂ = v/(1 − β₂ᵗ).",
    "Up to a critical batch size, doubling B lets you double η and halve the steps (the gradient noise scale, McCandlish et al. 2018); past it, bigger batches waste compute. In high dimensions most critical points are saddles rather than bad minima (Dauphin et al. 2014).",
    "Measured: SGD on overparameterized nets reliably reaches near-zero training loss. Open: a full theory of why the solutions it finds generalize (implicit bias of SGD).",
  ],
};

interface P15 { plans: [number, number][]; sT2: number; sN2: number; x: number }
const NAMES = ["A", "B", "C", "D", "E"];
const argmax = (a: number[]) => a.indexOf(Math.max(...a));

export const ai15: B2Lesson<P15> = {
  id: "b2-ai-15", track: "ai", unit: 5, title: "Goodhart's law: optimize the score, miss the point",
  youCan: "show in a toy world how pushing hard on a stand-in score can drift away from the real goal, and compute how much a high score should be trusted.",
  needs: ["b2-ai-14", "b2-pr-08", "b2-pr-17", "b2-in-09"],
  tools: ["goals"],
  play: { scene: "goals", props: { n: 30 },
    say: "A cleaning robot in a 5 × 5 room. Its reward is \"+1 for each tile the camera sees as clean\". Drag how hard it optimizes (how many plans it tries) and watch the two meters: the reward it gets and how clean the room really is." },
  guess: { scene: "goals", props: { n: 10, quiet: true }, kind: "choice", options: ["Keeps rising", "Levels off", "Rises then falls"], answer: 2,
    ask: "The optimizer goes from trying 10 plans to 10,000. What does the true-cleanliness meter do?",
    revealProps: { n: 10000, sweep: true },
    reveal: "With the camera reward it rises, then falls once a loophole plan wins: turn the camera to the wall and every tile \"looks\" clean. Flip the reward to count dirt in the bin and it keeps rising." },
  nameIt: {
    say: [
      "Goodhart's law: when a measure becomes a target, it stops being a good measure.",
      "Any score is a stand-in for what you actually want, and the harder you search for a high score, the more likely the winner got there through the score's errors instead of the goal. Even with honest random errors, the top scorer's true value is usually lower than its score.",
    ],
    formula: ["proxy = true + noise, independent and normal, spreads σ_T² and σ_N²", "Expected true value given proxy x = x · σ_T² / (σ_T² + σ_N²)", "Without normality, this is still the best straight-line estimate"],
  },
  workIt: {
    reference: { plans: [[6, 5], [9, 3], [7, 7], [4, 4], [8, 6]], sT2: 4, sN2: 1, x: 10 },
    generate(rng, i) {
      const SIG: [number, number][] = [[1, 1], [3, 1], [4, 1], [9, 1], [1, 3], [2, 3]];
      const [sT2, sN2] = rng.pick(i < 3 ? SIG.filter(s => s[1] === 1) : SIG);
      for (;;) {
        const plans = NAMES.map(() => [rng.int(1, 10), rng.int(1, 10)] as [number, number]);
        const px = plans.map(q => q[0]), tr = plans.map(q => q[1]);
        if (px.filter(v => v === Math.max(...px)).length !== 1 || tr.filter(v => v === Math.max(...tr)).length !== 1) continue;
        if (argmax(px) === argmax(tr)) continue;
        return { plans, sT2, sN2, x: rng.int(4, 20) };
      }
    },
    show: p => `Five plans as (proxy, true): ${p.plans.map((q, k) => `${NAMES[k]} (${q[0]}, ${q[1]})`).join(", ")}. Then a score with σ_T² = ${p.sT2} and σ_N² = ${p.sN2} reads **${p.x}**.`,
    steps(p) {
      const px = p.plans.map(q => q[0]), tr = p.plans.map(q => q[1]), pick = argmax(px), best = argmax(tr);
      const shrink = p.sT2 / (p.sT2 + p.sN2);
      return [
        tapStep("pick", "Plan the optimizer picks", NAMES, pick, { hint: "It only sees the first number.",
          slips: [slip("picked the true best", best, `The optimizer only sees the proxy. It picks the highest proxy, ${NAMES[pick]}, even though ${NAMES[best]} is better.`)] }),
        wholeStep("true", "Its true value", tr[pick]!, { hint: `Plan ${NAMES[pick]}'s second number.`,
          slips: [slip("proxy", px[pick]!, "That's its score. Its true value is the second number.")] }),
        wholeStep("gap", `Gap to the best true plan (${NAMES[best]}, ${tr[best]})`, tr[best]! - tr[pick]!, { hint: `${tr[best]} − ${tr[pick]}.` }),
        numStep("shrink", "Shrink factor σ_T² / (σ_T² + σ_N²)", shrink, 2, { hint: `${p.sT2} / (${p.sT2} + ${p.sN2}).`,
          slips: [
            slip("noise share", p.sN2 / (p.sT2 + p.sN2), `Trust the score by the share of its spread that is real: σ_T² over the total, ${p.sT2}/${p.sT2 + p.sN2}.`),
            slip("noise share", p.sN2 / p.sT2, `Trust the score by the share of its spread that is real: σ_T² over the total, ${p.sT2}/${p.sT2 + p.sN2}.`),
          ] }),
        numStep("expect", `Expected true value at proxy ${p.x}`, p.x * shrink, 2, { hint: `${dec(shrink)} × ${p.x}.`,
          slips: [slip("took the score", p.x, `A high score is partly luck. Expect the true value to be pulled back toward the average: ${dec(shrink)} × ${p.x}.`)] }),
      ];
    },
    scene: () => ({ scene: "goals", props: { n: 100 } }),
  },
  oracle: p => {
    let pick = 0, best = 0;
    p.plans.forEach((q, k) => { if (q[0] > p.plans[pick]![0]) pick = k; if (q[1] > p.plans[best]![1]) best = k; });
    return [pick, p.plans[pick]![1], p.plans[best]![1] - p.plans[pick]![1], p.sT2 / (p.sT2 + p.sN2), (p.x * p.sT2) / (p.sT2 + p.sN2)];
  },
  useIt: {
    say: ["In the Goal sandbox, find one loophole in the default reward, then rewrite the reward to close it. The new reward may open a different loophole. Keep the loophole you found for the Reader field notes.",
      "Then look at the build: the reader was trained with held-out accuracy as its target, so ask what that number misses. It never saw a scribble that isn't a digit."],
    scene: { scene: "goals", props: { n: 3000, save: true } },
  },
  deeper: [
    "Manheim and Garrabrant (2018) split Goodhart into regressional (the shrinkage above), extremal (the link between proxy and goal breaks in regions never seen), causal and adversarial cases; the \"optimizer's curse\" (Smith and Winkler 2006) is the decision-theory version. With heavy-tailed proxy errors, extreme optimization can make the expected true value fall back toward no better than average, not just lag (Kwa et al. 2024, \"catastrophic Goodhart\").",
    "A common fix is to optimize reward minus a penalty for moving away from a trusted starting behavior: maximize E[r] − β·KL(π‖π₀), whose solution is π ∝ π₀ · e^(r/β) (b2-in-09). For best-of-n sampling, the commonly used KL = ln n − (n − 1)/n from the start is an upper bound (Beirami et al. 2024).",
    "Measured: reward hacking appears in real reinforcement-learning systems (a boat-racing agent looping for points instead of finishing, 2016), and Gao, Schulman and Hilton (2022) measured a learned reward rising while a trusted \"gold\" reward rose then fell. Open: how to specify goals that stay good under strong optimization, and how to check that a powerful system is pursuing the intended goal.",
  ],
};

interface Bin16 { conf: number; n: number; k: number }
interface P16 { N: number; bins: Bin16[] }
const CONFS = [0.55, 0.6, 0.7, 0.75, 0.8, 0.9, 0.95];
const ece16 = (p: P16) => p.bins.reduce((s, b) => s + b.n * Math.abs(b.k / b.n - b.conf), 0) / p.N;

export const ai16: B2Lesson<P16> = {
  id: "b2-ai-16", track: "ai", unit: 5, title: "Calibration: knowing what you don't know",
  youCan: "check whether a model's confidence matches how often it's right, fix it with a temperature, and set when it should say \"not sure\".",
  needs: ["b2-ai-07", "b2-ai-09", "b2-pr-01", "b2-pr-04", "b2-in-09"],
  tools: ["reliability", "digits", "softmax"],
  play: { scene: "reliability", props: { T: 1.6 },
    say: "The reader's held-out predictions sorted into confidence bins: bars show how often it was right in each bin, against a diagonal \"perfect\" line. Drag the temperature T and the bars slide along; drag the \"not sure\" threshold and watch coverage trade against accuracy." },
  guess: { scene: "reliability", props: { quiet: true }, kind: "slider", min: 50, max: 100, step: 0.5, start: 80, answer: (100 * TOP_BIN[1]) / TOP_BIN[0], near: 3, unit: "%",
    format: x => x.toFixed(1),
    ask: "When the reader says it is at least 90% sure, how often do you think it is actually right?",
    revealProps: { focus: true },
    reveal: `${((100 * TOP_BIN[1]) / TOP_BIN[0]).toFixed(1)}% of the ${g(TOP_BIN[0])} held-out digits in that bin. That is this reader's real answer: at the top it is a little underconfident, and it is overconfident lower down.` },
  nameIt: {
    say: [
      "A calibrated model's 80% means right 80% of the time. You check it by grouping predictions by confidence and comparing each group's average confidence with its accuracy.",
      "Dividing the scores by a temperature T > 1 cools an overconfident model without changing its top answer.",
    ],
    formula: ["ECE = Σ_bins (n_b / N) · |accuracy_b − confidence_b|", "Temperature: p = softmax(z / T)"],
  },
  workIt: {
    reference: { N: 200, bins: [{ conf: 0.6, n: 40, k: 24 }, { conf: 0.8, n: 100, k: 70 }, { conf: 0.95, n: 60, k: 48 }] },
    generate(rng, i) {
      for (;;) {
        const N = rng.pick([100, 200, 400]);
        const confs = rng.shuffle(CONFS).slice(0, 3).sort((a, b) => a - b);
        const n1 = 20 * rng.int(1, N / 20 - 2), n2 = 20 * rng.int(1, N / 20 - n1 / 20 - 1), n3 = N - n1 - n2;
        if (n3 < 20) continue;
        const sign = rng.pick([-1, 1]), perfect = i < 3 ? rng.int(0, 2) : -1;
        const bins = confs.map((conf, k) => {
          const gap = k === perfect ? 0 : 0.05 * rng.int(0, 4), n = [n1, n2, n3][k]!;
          const acc = Math.round((conf - sign * gap) * 100) / 100;
          return { conf, n, k: Math.round(acc * n) };
        });
        if (bins.some(b => b.k < 0 || b.k > b.n || Math.abs((b.k / b.n) * 100 - Math.round((b.k / b.n) * 100)) > 1e-9)) continue;
        const e = ece16({ N, bins });
        if (e < 1e-9 || Math.abs(e * 1000 - Math.round(e * 1000)) > 1e-6) continue;
        return { N, bins };
      }
    },
    show: p => `${g(p.N)} predictions in three bins: ${p.bins.map(b => `confidence ${dec(b.conf)} with ${b.n} predictions, ${b.k} right`).join("; ")}.`,
    steps(p) {
      const acc = p.bins.map(b => b.k / b.n), gap = p.bins.map((b, k) => Math.abs(acc[k]! - b.conf)), over = p.bins.some((b, k) => b.conf > acc[k]! + 1e-9);
      return [
        multiStep("acc", "Accuracy in each bin", acc, 2, { boxes: ["bin 1", "bin 2", "bin 3"], hint: "Right over count, bin by bin.",
          slips: [slip("confidence", p.bins.map(b => b.conf), "That's the confidence it claimed. Accuracy is how many were right over how many it made.")] }),
        multiStep("gap", "Gaps", gap, 2, { boxes: ["bin 1", "bin 2", "bin 3"], hint: "|accuracy − confidence| for each bin.",
          slips: [slip("signed", acc.map((a, k) => a - p.bins[k]!.conf), "A gap is a size: |accuracy − confidence|, never negative.")] }),
        numStep("ece", "ECE", ece16(p), 3, { hint: `(${p.bins.map((b, k) => `${b.n}·${dec(gap[k]!)}`).join(" + ")}) / ${g(p.N)}.`,
          slips: [slip("plain average", gap.reduce((a, b) => a + b, 0) / 3, `Weight each gap by how many predictions are in its bin, out of all ${g(p.N)}.`)] }),
        tapStep("which", "Over- or underconfident", ["Overconfident", "Underconfident"], over ? 0 : 1, { hint: "Is the confidence above the accuracy, or below?",
          slips: [over
            ? slip("under", 1, "It claims more than it delivers: confidence is above accuracy, so it's overconfident.")
            : slip("over", 0, "It delivers more than it claims: accuracy is above confidence, so it's underconfident.")] }),
        tapStep("T", "To fix it, T should be", ["Greater than 1", "Less than 1", "Exactly 1"], over ? 0 : 1, { hint: "T > 1 softens the chances; T < 1 sharpens them.",
          slips: [over
            ? slip("sharpened", 1, "Dividing scores by T < 1 makes them bigger and the model even surer. Use T > 1 to soften.")
            : slip("softened", 0, "Dividing scores by T > 1 makes the model less sure, and it's already too shy. Use T < 1 to sharpen.")] }),
      ];
    },
    scene: () => ({ scene: "reliability", props: {} }),
  },
  oracle: p => {
    const acc = p.bins.map(b => b.k / b.n), gaps = p.bins.map((b, k) => Math.abs(acc[k]! - b.conf));
    const over = p.bins.reduce((s, b, k) => s + (b.conf - acc[k]!), 0) > 0;
    return [...acc, ...gaps, p.bins.reduce((s, b, k) => s + b.n * gaps[k]!, 0) / p.N, over ? 0 : 1, over ? 0 : 1];
  },
  useIt: {
    say: ["Calibrate the build: fit T on held-out digits to make the log loss smallest, save `T_digits`, and set a \"not sure\" threshold so the reader answers only when its top chance clears it. Then draw a scribble that isn't a digit and see whether it says \"not sure\".",
      "The build is finished: the Reader field notes collect the scaling plot, `C_digits`, your loophole, and the before-and-after reliability diagrams."],
    project: "ai-notes",
  },
  deeper: [
    "Strictly proper scoring rules (log loss, Brier score) are optimized in expectation only by honest probabilities, and the Brier score splits into reliability − resolution + uncertainty (Murphy 1973): a forecaster can be perfectly calibrated and still useless, always predicting the base rate.",
    "Guo et al. (2017) measured that large modern deep networks are often overconfident (older, small networks such as LeNet were fairly well calibrated) and that a single temperature fixes much of it on in-distribution data. Conformal prediction turns any model into prediction sets that contain the true label with probability at least 1 − α, assuming only that new data and calibration data are exchangeable.",
    "Measured: large language models' stated confidence is reasonably calibrated on some multiple-choice tasks (Kadavath et al. 2022). Open: calibration under distribution shift, and whether a model can reliably tell when a question is outside anything it has learned.",
  ],
};

