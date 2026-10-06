// The math behind AI, units 1 and 2 (b2-ai-01 to b2-ai-07), built from curriculum/specs/bento2/ai.md block by block.
import type { B2Lesson } from "../../model";
import { fracStep, multiStep, numStep, slip, tapStep, wholeStep } from "../../make";
import { group } from "../../steps";
import { lineText, log2, num, par, round2, sigmoid } from "./maths";

/** a decimal with no trailing zeros: 1.50 → "1.5", −2.00 → "−2" */
export const dec = (x: number, places = 2) => group(x, places).replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "");
const sum = (a: number[]) => a.reduce((s, v) => s + v, 0);
const pt = (x: number, y: number) => `(${num(x)}, ${num(y)})`;
/** points as a scene prop: "0,0;1,3;2,3" */
export const ptsProp = (xs: number[], ys: number[]) => xs.map((x, i) => `${x},${ys[i]}`).join(";");

/* ------------------------------------------------------------------ unit 1 ------------------------------------------------------------------ */

interface P01 { xs: number[]; ys: number[]; w: number; b: number }

export const ai01: B2Lesson<P01> = {
  id: "b2-ai-01", track: "ai", unit: 1, title: "Loss: how wrong is a model?",
  youCan: "score any model's guesses with one number, the loss.",
  needs: ["st-lsrl"],
  tools: ["fitter", "tinynet"],
  play: { scene: "fitter", props: { mode: "drag", pts: "0,1;1,3;2,2;3,5;4,4", w: 0.5, b: 1 },
    say: "Five points and a line. Drag the line's handles, or the points: each miss is drawn as a real square, and its area is the miss squared. The bar adds up the areas." },
  guess: { scene: "fitter", props: { mode: "compare", pts: "0,1;1,0;3,4", quiet: true }, kind: "choice", options: ["Line A, through two points", "Line B, near all three"], answer: 1,
    ask: "Line A goes exactly through two points and misses the third by 3. Line B misses all three by 1. Which has the smaller loss?",
    revealProps: { mode: "compare", pts: "0,1;1,0;3,4", quiet: false },
    reveal: "Line B. A's one big miss makes a square of area 9; B's three small misses make 1 + 1 + 1 = 3." },
  nameIt: {
    say: [
      "A loss is one number that says how wrong a model is on the data.",
      "Mean squared error squares each miss, so big misses count a lot and misses can't cancel, then averages.",
      "Learning means changing the model to make this number small.",
    ],
    formula: ["MSE = (1/n) Σ (yᵢ − ŷᵢ)²", "ŷᵢ = w xᵢ + b"],
  },
  workIt: {
    reference: { xs: [0, 1, 2], ys: [0, 3, 3], w: 1, b: 1 },
    generate(rng, i) {
      const xs = i < 3 ? [0, 1, 2] : rng.shuffle([0, 1, 2, 3, 4]).slice(0, 3).sort((a, b) => a - b);
      const w = i < 3 ? 1 : rng.pick([-2, -1, 1, 2]), b = rng.int(-2, 3);
      let r: number[];
      do r = xs.map(() => rng.int(-3, 3)); while (!r.some(v => v > 0) || !r.some(v => v < 0));
      return { xs, ys: xs.map((x, k) => w * x + b + r[k]!), w, b };
    },
    show: p => `The points ${p.xs.map((x, k) => pt(x, p.ys[k]!)).join(", ")} and the line **${lineText(p.w, p.b)}**. How wrong is the line?`,
    steps(p) {
      const pred = p.xs.map(x => p.w * x + p.b), miss = p.ys.map((y, k) => y - pred[k]!), ss = sum(miss.map(m => m * m));
      return [
        multiStep("pred", "Predictions ŷ", pred, "whole", { boxes: p.xs.map(x => `at x = ${num(x)}`), ask: "Put each x into the line.",
          hint: `ŷ = ${lineText(p.w, p.b, "ŷ")} at each x.`,
          slips: [slip("used y", p.ys, "Those are the points' own y values. The prediction is what the line gives at each x.")] }),
        multiStep("miss", "Misses y − ŷ", miss, "whole", { boxes: ["1", "2", "3"], hint: "Each point's y minus the line's ŷ.",
          slips: [slip("flipped", miss.map(m => -m), "A miss is the point minus the line, y − ŷ. A point above the line has a positive miss.")] }),
        wholeStep("ss", "Sum of squares", ss, { hint: `Square each miss and add: ${miss.map(m => `${par(m)}²`).join(" + ")}.`,
          slips: [
            slip("added raw misses", sum(miss), "Misses above and below cancel when you just add them. Square each one first."),
            slip("added sizes", sum(miss.map(Math.abs)), "Square each miss rather than just dropping its sign: a miss of 3 counts 9."),
          ] }),
        fracStep("mse", "MSE", ss / 3, { hint: `Divide the total, ${ss}, by the number of points.`,
          slips: [
            slip("no average", ss, "That is the total. Divide by the number of points, 3."),
            slip("n − 1", ss / 2, "Divide by the number of points, n = 3. The n − 1 version is for estimating spread from a sample."),
          ] }),
      ];
    },
    scene: p => ({ scene: "fitter", props: { mode: "drag", pts: ptsProp(p.xs, p.ys), w: p.w, b: p.b } }),
  },
  oracle: p => {
    const yhat = p.xs.map(x => p.w * x + p.b);
    const res = p.ys.map((y, k) => y - yhat[k]!);
    const total = res.reduce((s, r) => s + r ** 2, 0);
    return [...yhat, ...res, total, total / p.xs.length];
  },
  useIt: {
    say: ["Three lines are proposed for your own points in the Line fitter. Score each one, and keep the best line's loss as `mse_line`.",
      "This is the number the training loop will shrink."],
    scene: { scene: "fitter", props: { mode: "score", pts: "0,1;1,3;2,2;3,5;4,4", save: "mse_line" } },
  },
  deeper: [
    "Why squares? If each y is the true line plus normal noise, the line with the smallest MSE is exactly the most likely line (maximum likelihood, b2-pr-09).",
    "Set the two partial derivatives of MSE to 0 and you get the normal equations XᵀX θ = Xᵀy (b2-la-11), so θ = (XᵀX)⁻¹Xᵀy in one shot when XᵀX is invertible. MSE is a convex bowl in (w, b), which is why every downhill path in b2-ai-02 ends at the same bottom.",
    "Other losses mean other noise models: absolute error goes with Laplace noise and gives the median, not the mean.",
  ],
};

interface P02 { set: 1 | 2; k: number; eta: number }
const p02pts = (p: P02): [[number, number], [number, number]] => (p.set === 1 ? [[1, p.k], [2, 2 * p.k]] : [[1, p.k], [3, 3 * p.k]]);
/** dL/dw for y = wx on two points: (2/2) Σ x(wx − y) */
const grad02 = (p: P02, w: number) => p02pts(p).reduce((s, [x, y]) => s + x * (w * x - y), 0);

export const ai02: B2Lesson<P02> = {
  id: "b2-ai-02", track: "ai", unit: 1, title: "Gradient descent: take a step downhill",
  youCan: "improve a model by stepping against its gradient.",
  needs: ["b2-ai-01", "g12-chain", "b2-mv-14"],
  tools: ["fitter", "landscape"],
  play: { scene: "descent", props: { k: 2, set: 1, eta: 0.1 },
    say: "Left, the data and a line through the origin, y = wx. Right, the loss over w with a ball at the current w and its slope. Press Step: the ball moves against the slope and the line swings toward the points." },
  guess: { scene: "descent", props: { k: 2, set: 1, eta: 0.1, quiet: true }, kind: "slider", min: 0, max: 3, step: 0.05, start: 2.5, answer: 1, near: 0.2, unit: "",
    format: x => `w = ${x.toFixed(2)}`,
    ask: "The ball starts at w = 0 with η = 0.1. Slide the ghost ball to where you think the first step lands.",
    revealProps: { k: 2, set: 1, eta: 0.1, steps: 4 },
    reveal: "The first step lands at w = 1. Each step after that covers half of the distance left to the bottom at w = 2." },
  nameIt: {
    say: [
      "The derivative of the loss tells you which way is uphill and how steep. Step the other way, by an amount set by the learning rate η.",
      "Repeat. That loop is how almost every AI model learns.",
    ],
    formula: ["w ← w − η · dL/dw", "dL/dw = (2/n) Σ xᵢ (w xᵢ − yᵢ) for y = wx"],
  },
  workIt: {
    reference: { set: 1, k: 2, eta: 0.1 },
    generate(rng, i) {
      const k = rng.int(1, 4);
      if (i < 3) return { set: 1, k, eta: 0.1 };
      const set = rng.pick([1, 2] as const);
      return { set, k, eta: set === 1 ? rng.pick([0.1, 0.2, 0.3]) : rng.pick([0.05, 0.1]) };
    },
    show: p => { const [[x1, y1], [x2, y2]] = p02pts(p); return `The points ${pt(x1, y1)} and ${pt(x2, y2)}, the line y = wx, starting at **w₀ = 0** with **η = ${p.eta}**.`; },
    steps(p) {
      const g0 = grad02(p, 0), w1 = -p.eta * g0, g1 = grad02(p, w1), w2 = w1 - p.eta * g1;
      const [[a, ya], [b, yb]] = p02pts(p);
      return [
        wholeStep("g0", "Gradient at w₀", g0, { ask: "dL/dw = (2/n) Σ x(wx − y), with n = 2.",
          hint: `(2/2)(${a}·(0 − ${ya}) + ${b}·(0 − ${yb})).`,
          slips: [slip("dropped the 2", g0 / 2, "The derivative of (wx − y)² is 2x(wx − y). Keep the 2, then divide by n = 2.")] }),
        numStep("w1", "w₁", w1, 2, { hint: `w₁ = 0 − ${p.eta} · (${num(g0)}).`,
          slips: [
            slip("uphill", -w1, "You stepped uphill. Subtract η times the gradient: the gradient points the way the loss rises."),
            slip("forgot η", -g0, "Scale the gradient by the learning rate before stepping."),
          ] }),
        numStep("g1", "Gradient at w₁", g1, 2, { hint: `The same sum at w = ${dec(w1)}: ${a}·(${dec(w1)} − ${ya}) + ${b}·(${dec(w1 * b)} − ${yb}).`,
          slips: [slip("dropped the 2", g1 / 2, "Keep the 2 from the square, then divide by n = 2: it cancels.")] }),
        numStep("w2", "w₂", w2, 2, { hint: `w₂ = ${dec(w1)} − ${p.eta} · (${dec(g1)}).`,
          slips: [
            slip("uphill", w1 + p.eta * g1, "You stepped uphill. Subtract η times the gradient."),
            slip("forgot η", w1 - g1, "Scale the gradient by the learning rate before stepping."),
          ] }),
      ];
    },
    scene: p => ({ scene: "descent", props: { k: p.k, set: p.set, eta: p.eta } }),
  },
  oracle: p => {
    const pts = p.set === 1 ? [[1, p.k], [2, 2 * p.k]] : [[1, p.k], [3, 3 * p.k]];
    const g = (w: number) => (2 / pts.length) * pts.reduce((s, [x, y]) => s + x! * (w * x! - y!), 0);
    const w1 = 0 - p.eta * g(0);
    return [g(0), w1, g(w1), w1 - p.eta * g(w1)];
  },
  useIt: {
    say: ["Train the Line fitter on your points with both w and b moving: two partial derivatives, one step each, and watch the loss curve fall.",
      "This loop is the engine of the build."],
    scene: { scene: "fitter", props: { mode: "train", pts: "0,1;1,3;2,2;3,5;4,4", w: -1, b: 0, eta: 0.05 } },
  },
  deeper: [
    "With many weights the update is θ ← θ − η∇L(θ) (b2-mv-14). For a convex loss with an L-Lipschitz gradient and η = 1/L, the error after t steps is at most L‖θ₀ − θ*‖²/(2t), an O(1/t) rate; with strong convexity μ it becomes geometric, shrinking by (1 − μ/L) per step.",
    "The continuous-time version dθ/dt = −∇L(θ) is gradient flow, an ODE (de), and the loss only ever goes down along it.",
  ],
};

interface P03 { a: number; eta: number; m: number; d: number }
const ETAS: Record<number, number[]> = { 1: [0.1, 0.25, 0.5, 0.75, 1, 1.2], 2: [0.1, 0.25, 0.4, 0.5, 0.6], 5: [0.02, 0.1, 0.16, 0.2, 0.24] };
const rOf = (p: P03) => Math.round((1 - 2 * p.eta * p.a) * 100) / 100;
export const FATES = ["Creeps in from one side", "Lands in one step", "Zigzags and settles", "Bounces forever", "Blows up"];
export const fateOf = (r: number) => (r > 1e-9 ? 0 : Math.abs(r) < 1e-9 ? 1 : r > -1 + 1e-9 ? 2 : Math.abs(r + 1) < 1e-9 ? 3 : 4);
/** "2(w − 3)²", "(w + 1)²", "5w²" */
export const bowlText = (a: number, m: number) => `${a === 1 ? "" : a}${m === 0 ? "w²" : `(w ${m > 0 ? "−" : "+"} ${Math.abs(m)})²`}`;

export const ai03: B2Lesson<P03> = {
  id: "b2-ai-03", track: "ai", unit: 1, title: "The learning rate: creep, land, zigzag, blow up",
  youCan: "pick a learning rate that converges, and say why too big fails.",
  needs: ["b2-ai-02", "b2-mv-13"],
  tools: ["etadial", "landscape"],
  play: { scene: "etadial", props: { a: 2, eta: 0.1, m: 3 },
    say: "A ball on the bowl L(w) = a(w − m)². Turn the η dial and its path redraws at once: tiny steps crawling, one perfect jump, a zigzag that settles, a zigzag that flies off. Below, a long narrow valley where one η must suit both directions." },
  guess: { scene: "etadial", props: { a: 2, eta: 0.1, m: 3, quiet: true }, kind: "slider", min: 0.05, max: 1, step: 0.05, start: 0.3, answer: 0.5, near: 0.05,
    format: x => `η = ${x.toFixed(2)}`,
    ask: "The bowl has a = 2. Slide to the η where you think the ball stops settling.",
    revealProps: { a: 2, eta: 0.5, m: 3, sweep: true },
    reveal: "At η = 0.5 the factor is 1 − 2(0.5)(2) = −1: the ball bounces between the same two spots forever. Any bigger and it flies off." },
  nameIt: {
    say: [
      "On a bowl, each step multiplies your distance from the bottom by the same factor.",
      "If that factor is between −1 and 1 you settle; past −1 every step overshoots more than the last. Steeper bowls need smaller steps.",
    ],
    formula: ["For L = a(w − m)²: (w − m) ← r · (w − m)", "r = 1 − 2ηa", "Settles when 0 < η < 1/a; lands in one step at η = 1/(2a)"],
  },
  workIt: {
    reference: { a: 2, eta: 0.1, m: 3, d: 10 },
    generate(rng, i) {
      const pairs = Object.entries(ETAS).flatMap(([a, es]) => es.map(eta => ({ a: Number(a), eta })));
      const ok = i < 3 ? pairs.filter(q => 1 - 2 * q.eta * q.a > 1e-9) : pairs;
      const { a, eta } = rng.pick(ok);
      return { a, eta, m: rng.int(-3, 5), d: rng.pick([10, 20]) };
    },
    show: p => `The bowl **L(w) = ${bowlText(p.a, p.m)}**, with **η = ${p.eta}**, starting at **w₀ = ${num(p.m + p.d)}**.`,
    steps(p) {
      const r = rOf(p), fate = fateOf(r), w3 = p.m + r ** 3 * p.d;
      return [
        numStep("r", "Factor r", r, 2, { hint: `r = 1 − 2 · ${p.eta} · ${p.a}.`,
          slips: [slip("sign", 1 + 2 * p.eta * p.a, "The step subtracts: r = 1 − 2ηa, not 1 + 2ηa.")] }),
        tapStep("fate", "What happens", FATES, fate, { hint: "Look at r: between 0 and 1 creeps, 0 lands, between −1 and 0 zigzags in, −1 bounces, below −1 blows up.",
          slips: [fate === 2 && slip("blows up", 4, "A negative factor means you overshoot, but if |r| < 1 each overshoot is smaller. It zigzags in.")] }),
        numStep("w3", "w₃", w3, 2, { hint: `w₃ = m + r³(w₀ − m) = ${num(p.m)} + (${dec(r)})³ · ${p.d}.`,
          slips: [slip("3r", p.m + 3 * r * p.d, "Each step multiplies by r again: r³, not 3r.")] }),
        fracStep("limit", "The η where it stops settling", 1 / p.a, { hint: "It stops settling when r = −1: 1 − 2ηa = −1.",
          slips: [slip("half", 1 / (2 * p.a), "That η lands in one step, the best one. It stops settling at twice that, 1/a.")] }),
      ];
    },
    scene: p => ({ scene: "etadial", props: { a: p.a, eta: p.eta, m: p.m, d: p.d } }),
  },
  oracle: p => { const r = 1 - 2 * p.eta * p.a; return [r, r > 1e-9 ? 0 : Math.abs(r) < 1e-9 ? 1 : r > -1 + 1e-9 ? 2 : Math.abs(r + 1) < 1e-9 ? 3 : 4, p.m + r ** 3 * p.d, 1 / p.a]; },
  useIt: {
    say: ["In the Line fitter, find by trial the biggest η that still settles on your points, then compare it with the limit read off the bowl's curvature.",
      "Save it as `eta`. The build's training loop starts from it."],
    project: "ai-fitter",
  },
  deeper: [
    "In many dimensions the curvature is the Hessian H (b2-mv-13), and gradient descent is stable when η < 2/λ_max(H); here λ = 2a, which gives 1/a. The narrowest direction sets the speed limit, so the widest direction crawls: the number of steps grows with the condition number κ = λ_max/λ_min.",
    "Momentum (heavy ball, Nesterov) cuts that to about √κ. Real networks often train at the \"edge of stability\", where λ_max hovers near 2/η (Cohen et al. 2021), an observation that is measured but not fully explained.",
  ],
};

/* ------------------------------------------------------------------ unit 2 ------------------------------------------------------------------ */

interface P04 { w1: number; w2: number; b: number; x1: number; x2: number }
const z04 = (p: P04) => p.w1 * p.x1 + p.w2 * p.x2 + p.b;
const SIDES = ["Orange (σ > 0.5)", "Blue (σ < 0.5)", "On the line (σ = 0.5)"];

export const ai04: B2Lesson<P04> = {
  id: "b2-ai-04", track: "ai", unit: 2, title: "The neuron: weigh, add, squash",
  youCan: "compute what a single neuron outputs and draw the line it splits along.",
  needs: ["b2-ai-02", "b2-la-03", "c-transcend"],
  tools: ["tinynet"],
  play: { scene: "neuron", props: { w1: 1, w2: 1, b: 0 },
    say: "Dots of two colors and one neuron with two weights and a bias. The plane shades by the neuron's output, from 0 (blue) to 1 (orange), and the 0.5 line is drawn. Drag the weights and the line turns; drag the bias and it slides." },
  guess: { scene: "neuron", props: { w1: 1, w2: -0.5, b: 0.5 }, kind: "choice", options: ["It moves", "It turns", "It stays put"], answer: 2,
    ask: "Double both weights and the bias. What does the dividing line do?",
    revealProps: { w1: 1, w2: -0.5, b: 0.5, doubled: true },
    reveal: "It stays put: 2(w₁x₁ + w₂x₂ + b) = 0 is the same line. The shading gets sharper, so the neuron is more sure on each side." },
  nameIt: {
    say: [
      "A neuron takes a weighted sum of its inputs plus a bias, then squashes it to a number between 0 and 1.",
      "It says \"orange\" when the sum is positive. So one neuron can only split the plane with a straight line.",
    ],
    formula: ["z = w₁x₁ + w₂x₂ + b", "σ(z) = 1 / (1 + e^(−z))", "The boundary: w₁x₁ + w₂x₂ + b = 0"],
  },
  workIt: {
    reference: { w1: 2, w2: -1, b: 1, x1: 1, x2: 2 },
    generate(rng, i) {
      for (;;) {
        const p = { w1: rng.pick([-2, -1, 1, 2]), w2: rng.pick([-2, -1, 1, 2]), b: rng.int(-2, 2), x1: rng.int(-2, 2), x2: rng.int(-2, 2) };
        const z = z04(p);
        if (i < 3 ? z >= 0 && z <= 2 : z >= -2 && z <= 2) return p;
      }
    },
    show: p => `Weights **w = (${num(p.w1)}, ${num(p.w2)})**, bias **b = ${num(p.b)}**, and the point **(${num(p.x1)}, ${num(p.x2)})**.`,
    steps(p) {
      const z = z04(p), side = z > 0 ? 0 : z < 0 ? 1 : 2, s = round2(sigmoid(z));
      return [
        wholeStep("z", "z", z, { hint: `z = ${num(p.w1)}·${par(p.x1)} + ${par(p.w2)}·${par(p.x2)} + ${par(p.b)}.`,
          slips: [p.b !== 0 && slip("forgot the bias", z - p.b, "Add the bias b after the weighted sum.")] }),
        tapStep("side", "Which side", SIDES, side, { hint: "Orange when z > 0, blue when z < 0, on the line when z = 0.",
          slips: [
            side === 1 && slip("sign", 0, `z = ${num(z)} is negative, so σ(z) is below 0.5: blue.`),
            side === 0 && slip("sign", 1, `z = ${num(z)} is positive, so σ(z) is above 0.5: orange.`),
          ] }),
        numStep("s", "σ(z)", s, 2, { hint: "σ(−2) = 0.12, σ(−1) = 0.27, σ(0) = 0.5, σ(1) = 0.73, σ(2) = 0.88.",
          slips: [slip("that's z", z, "That is z. The neuron's output is σ(z), squeezed between 0 and 1.")] }),
        fracStep("cross", "Where the line crosses the x₂-axis", -p.b / p.w2, { ask: "On the x₂-axis, x₁ = 0.", hint: "Solve w₂x₂ + b = 0 for x₂.",
          slips: [slip("sign", p.b / p.w2, "On the axis x₁ = 0, so w₂x₂ + b = 0 and x₂ = −b/w₂.")] }),
      ];
    },
    scene: p => ({ scene: "neuron", props: { w1: p.w1, w2: p.w2, b: p.b, px: p.x1, py: p.x2 } }),
  },
  oracle: p => { const z = p.w1 * p.x1 + p.w2 * p.x2 + p.b; return [z, z > 0 ? 0 : z < 0 ? 1 : 2, Math.round(100 / (1 + Math.exp(-z))) / 100, -p.b / p.w2]; },
  useIt: {
    say: ["Hand-tune one neuron to split the two colors, then press Train (gradient descent on the log loss) and watch it finish the job.",
      "Its weights go to the Number shelf as `neuron_w`."],
    scene: { scene: "neuron", props: { w1: -0.5, w2: 1, b: 0, train: true } },
  },
  deeper: [
    "σ′(z) = σ(z)(1 − σ(z)), which is why the sigmoid's gradient fades when it is very sure. Training one sigmoid neuron with loss −[y ln p + (1 − y) ln(1 − p)] is logistic regression; z is the log-odds ln(p/(1 − p)) (b2-pr-04).",
    "The perceptron convergence theorem: if a line with margin γ separates data inside a ball of radius R, the perceptron rule makes at most (R/γ)² mistakes. No single neuron can do XOR, which is the door to the next lesson.",
  ],
};

interface P05 { W: number[][]; b: number[]; x: number[]; v: number[]; c: number; xor: boolean }
const pre05 = (p: P05) => p.W.map((row, j) => row[0]! * p.x[0]! + row[1]! * p.x[1]! + p.b[j]!);

export const ai05: B2Lesson<P05> = {
  id: "b2-ai-05", track: "ai", unit: 2, title: "Layers: why one bend is not enough",
  youCan: "run a small network forward by hand: matrix, bias, ReLU, output.",
  needs: ["b2-ai-04", "b2-la-05"],
  tools: ["tinynet", "matrix"],
  play: { scene: "layers", props: { b2: 0 },
    say: "The XOR pattern: orange at (1, 0) and (0, 1), blue at (0, 0) and (1, 1). Two hidden ReLU neurons each fold the plane along a line. Drag the second neuron's bias and its weight in the output until the four corners split." },
  guess: { scene: "layers", props: { single: true, quiet: true }, kind: "choice", options: ["Yes", "No"], answer: 1,
    ask: "Can a single neuron, with no hidden layer, split XOR?",
    revealProps: { single: true, why: true },
    reveal: "No. Try the one-neuron sliders: any line with both orange corners on one side has a blue corner there too, because the midpoint of the orange pair is also the midpoint of the blue pair." },
  nameIt: {
    say: [
      "A layer is a matrix times the input, plus biases, then a bend. ReLU keeps positives and turns negatives into 0.",
      "Stacking layers lets the network fold the plane, so it can split patterns no single line can. Without the bend, two layers collapse into one matrix.",
    ],
    formula: ["h = ReLU(W x + b)", "y = v · h + c", "ReLU(z) = max(0, z), entry by entry"],
  },
  workIt: {
    reference: { W: [[1, 2], [-1, 1]], b: [0, -1], x: [2, 1], v: [1, 3], c: -1, xor: false },
    generate(rng, i) {
      const oneNeg = i >= 3 && rng.next() < 0.5;
      for (;;) {
        const W = i < 3 ? [[rng.int(0, 2), rng.int(0, 2)], [rng.int(0, 2), rng.int(0, 2)]] : [[rng.int(-2, 2), rng.int(-2, 2)], [rng.int(-2, 2), rng.int(-2, 2)]];
        const p: P05 = { W, b: [rng.int(-2, 2), rng.int(-2, 2)], x: i < 3 ? [rng.int(0, 1), rng.int(0, 1)] : [rng.int(-2, 2), rng.int(-2, 2)],
          v: [rng.pick([-2, -1, 1, 2, 3]), rng.pick([-2, -1, 1, 2, 3])], c: rng.int(-2, 2), xor: i === 0 };
        const pre = pre05(p), neg = pre.filter(z => z < 0).length;
        if (i < 3 ? pre.some(z => z !== 0) : oneNeg ? neg === 1 : neg === 0 && pre.some(z => z > 0)) return p;
      }
    },
    show: p => `W has rows **(${p.W[0]!.map(num).join(", ")})** and **(${p.W[1]!.map(num).join(", ")})**, b = (${p.b.map(num).join(", ")}), x = (${p.x.map(num).join(", ")}), v = (${p.v.map(num).join(", ")}), c = ${num(p.c)}.`,
    steps(p) {
      const pre = pre05(p), h = pre.map(z => Math.max(0, z)), y = p.v[0]! * h[0]! + p.v[1]! * h[1]! + p.c;
      const cols = [0, 1].map(j => p.W[0]![j]! * p.x[0]! + p.W[1]![j]! * p.x[1]! + p.b[j]!);
      const negs = pre.filter(z => z < 0);
      const r0 = p.W[0]!;
      const steps = [
        multiStep("pre", "W x + b", pre, "whole", { boxes: ["neuron 1", "neuron 2"], hint: "Each neuron takes one row of W, dotted with x, plus its bias.",
          slips: [slip("columns", cols, `Each hidden neuron uses one row of W: row 1 is (${r0.map(num).join(", ")}), so ${num(r0[0]!)}·${par(p.x[0]!)} + ${par(r0[1]!)}·${par(p.x[1]!)} + ${par(p.b[0]!)} = ${num(pre[0]!)}.`)] }),
        multiStep("h", "h = ReLU(…)", h, "whole", { boxes: ["h₁", "h₂"], hint: "Keep positives; a negative becomes 0.",
          slips: [
            slip("bias after", pre.map((z, j) => Math.max(0, z - p.b[j]!) + p.b[j]!), "The bias goes in before the bend: ReLU(Wx + b)."),
            slip("no bend", pre, "ReLU keeps positives and turns negatives into 0."),
          ] }),
        wholeStep("y", "y", y, { hint: `y = ${num(p.v[0]!)}·${h[0]} + ${par(p.v[1]!)}·${h[1]} + ${par(p.c)}.`,
          slips: [negs.length > 0 && slip("skipped ReLU", p.v[0]! * pre[0]! + p.v[1]! * pre[1]! + p.c, `ReLU turns the ${negs.map(num).join(" and the ")} into 0 before the output layer sees it.`)] }),
      ];
      if (p.xor) steps.push(tapStep("xor", "Check the XOR net at (1, 1)", ["0", "1", "2"], 0, {
        ask: "h₁ = ReLU(x₁ + x₂), h₂ = ReLU(x₁ + x₂ − 1), y = h₁ − 2h₂.", hint: "h₁ = 2 and h₂ = 1 at (1, 1).",
        slips: [slip("forgot h₂", 2, "h₂ = ReLU(1 + 1 − 1) = 1 is on too, so y = 2 − 2·1 = 0.")] }));
      return steps;
    },
    scene: () => ({ scene: "layers", props: { b2: -1 } }),
  },
  oracle: p => {
    const h = p.W.map((row, j) => Math.max(0, row[0]! * p.x[0]! + row[1]! * p.x[1]! + p.b[j]!));
    const pre = p.W.map((row, j) => row[0]! * p.x[0]! + row[1]! * p.x[1]! + p.b[j]!);
    return [...pre, ...h, p.v[0]! * h[0]! + p.v[1]! * h[1]! + p.c, ...(p.xor ? [0] : [])];
  },
  useIt: {
    say: ["Build the XOR net by hand, then let training find its own weights: often different ones that work just as well.",
      "Save the hand-built one as `xor_net`."],
    scene: { scene: "layers", props: { b2: 0, save: true } },
  },
  deeper: [
    "Universal approximation (Cybenko 1989, Hornik 1991; for ReLU, Leshno et al. 1993): one hidden layer with enough neurons can approximate any continuous function on a closed box as closely as you like. It says nothing about how many neurons or whether training finds them.",
    "A ReLU network is piecewise linear, and depth can create exponentially many linear pieces from the same number of neurons; there are functions a deep narrow net computes that need exponentially wide shallow nets (depth separation, Telgarsky 2016).",
  ],
};

interface P06 { x: number; w1: number; w2: number; t: number }
const fwd06 = (p: P06, w1 = p.w1) => { const a = w1 * p.x, h = Math.max(0, a), y = p.w2 * h; return { a, h, y, L: 0.5 * (y - p.t) ** 2 }; };

export const ai06: B2Lesson<P06> = {
  id: "b2-ai-06", track: "ai", unit: 2, title: "Backpropagation: the chain rule, run backwards",
  youCan: "compute every weight's gradient in a small network with one backward pass.",
  needs: ["b2-ai-05", "g12-chain", "b2-mv-04", "b2-cs-10"],
  tools: ["backprop", "tinynet"],
  play: { scene: "backprop", props: { x: 2, w1: 1, w2: 3, t: 4 },
    say: "The network y = w₂ · ReLU(w₁x) with loss L = ½(y − t)², as a chain of boxes. Press Forward and values flow left to right; press Backward and gradients flow right to left, each box multiplying by its own local slope. Nudge w₁ and L changes by gradient × nudge." },
  guess: { scene: "backprop", props: { x: 2, w1: -1, w2: 3, t: 4, quiet: true }, kind: "choice", options: ["A lot", "A little", "Not at all"], answer: 2,
    ask: "Here w₁x is negative. How much does nudging w₁ change the loss?",
    revealProps: { x: 2, w1: -1, w2: 3, t: 4, back: true },
    reveal: "Not at all. ReLU is flat for negative inputs, so it passes back 0: for this input the neuron is \"dead\"." },
  nameIt: {
    say: [
      "Backpropagation is the chain rule done in a smart order. Go forward once to get every value, then backward once, multiplying local derivatives.",
      "That gives the gradient for every weight at about the cost of two forward passes, which is what makes training millions of weights possible.",
    ],
    formula: ["a = w₁x, h = ReLU(a), y = w₂h, L = ½(y − t)²", "∂L/∂y = y − t, ∂L/∂w₂ = (y − t)·h", "∂L/∂h = (y − t)·w₂, ∂L/∂a = ∂L/∂h · [a > 0], ∂L/∂w₁ = ∂L/∂a · x"],
  },
  workIt: {
    reference: { x: 2, w1: 1, w2: 3, t: 4 },
    generate(rng, i) {
      for (;;) {
        const x = rng.pick([1, 2, 3]), w1 = i < 3 ? rng.pick([1, 2]) : rng.next() < 0.25 ? -1 : rng.pick([1, 2]);
        const p = { x, w1, w2: rng.pick([-2, -1, 1, 2, 3]), t: rng.int(-3, 6) };
        if (fwd06(p).y !== p.t) return p;
      }
    },
    show: p => `x = ${p.x}, w₁ = ${num(p.w1)}, w₂ = ${num(p.w2)}, target t = ${num(p.t)}. The network is y = w₂ · ReLU(w₁x) and L = ½(y − t)².`,
    steps(p) {
      const { a, h, y, L } = fwd06(p), dy = y - p.t, dw2 = dy * h, dw1 = a > 0 ? dy * p.w2 * p.x : 0;
      return [
        wholeStep("y", "Forward: y", y, { hint: `a = ${num(p.w1)}·${p.x} = ${num(a)}, h = ReLU(a) = ${h}, y = ${num(p.w2)}·${h}.`,
          slips: [a < 0 && slip("no ReLU", p.w2 * a, `ReLU turns a = ${num(a)} into 0, so y = 0.`)] }),
        numStep("L", "L", L, 1, { hint: `L = ½(${num(y)} − ${par(p.t)})².`,
          slips: [slip("dropped the ½", dy * dy, `L = ½(y − t)², so half of ${dy * dy} is ${dec(L, 1)}.`)] }),
        wholeStep("dy", "∂L/∂y", dy, { hint: "∂L/∂y = y − t.", slips: [slip("t − y", -dy, "The derivative of ½(y − t)² with respect to y is y − t.")] }),
        wholeStep("dw2", "∂L/∂w₂", dw2, { hint: `∂L/∂w₂ = (y − t) · h = ${num(dy)} · ${h}.`,
          slips: [h !== p.w2 && slip("used w₂", dy * p.w2, "∂y/∂w₂ is h, the value coming into w₂, not w₂ itself.")] }),
        wholeStep("dw1", "∂L/∂w₁", dw1, { hint: a > 0 ? `∂L/∂w₁ = (y − t) · w₂ · 1 · x = ${num(dy)} · ${par(p.w2)} · ${p.x}.` : "Is ReLU passing anything back here?",
          slips: a > 0
            ? [slip("stopped at ∂L/∂a", dy * p.w2, `One more link: a = w₁x, so ∂a/∂w₁ = x, not w₁. Multiply by x = ${p.x}.`),
              slip("used w₁", dy * p.w2 * p.w1, `One more link: a = w₁x, so ∂a/∂w₁ = x, not w₁. Multiply by x = ${p.x}.`)]
            : [slip("through ReLU", dy * p.w2 * p.x, "ReLU is flat for negative inputs, so it passes back 0. The gradient for w₁ is 0 here."),
              slip("through ReLU", dy * p.w2, "ReLU is flat for negative inputs, so it passes back 0. The gradient for w₁ is 0 here.")] }),
      ];
    },
    scene: p => ({ scene: "backprop", props: { x: p.x, w1: p.w1, w2: p.w2, t: p.t } }),
  },
  oracle: p => {
    const Lf = (w1: number) => 0.5 * (p.w2 * Math.max(0, w1 * p.x) - p.t) ** 2;
    const h = Math.max(0, p.w1 * p.x), y = p.w2 * h;
    return [y, Lf(p.w1), y - p.t, (y - p.t) * h, Math.round((Lf(p.w1 + 1e-5) - Lf(p.w1 - 1e-5)) / 2e-5)];
  },
  useIt: {
    say: ["Turn on gradient labels in the Tiny neural network and step the splitter's training one round at a time, reading the gradient on each wire.",
      "The build's training loop now uses backprop for every layer."],
    scene: { scene: "tinynet", props: { grads: true, pattern: "blobs", hidden: 2 } },
  },
  deeper: [
    "This is reverse-mode automatic differentiation: on a computation graph (a DAG, cs) visited in reverse topological order, the gradient of one output with respect to all n inputs costs a small constant times one evaluation (the cheap gradient principle; Baur and Strassen 1983 for arithmetic circuits). Forward mode costs one pass per input instead, so it wins only when inputs are few and outputs many.",
    "Products of many local derivatives explain vanishing and exploding gradients in deep nets, and why residual connections (b2-ai-12) help: they add an identity path whose derivative is 1.",
  ],
};

interface P07 { z: number[]; c: number }
export const CLASSES = ["cat", "dog", "fox"];
const p07 = (q: P07) => { const m = Math.max(...q.z), e = q.z.map(v => Math.exp(v - m)); return e[q.c]! / e.reduce((a, b) => a + b, 0); };

export const ai07: B2Lesson<P07> = {
  id: "b2-ai-07", track: "ai", unit: 2, title: "Softmax and cross-entropy: scores into chances",
  youCan: "turn a network's scores into probabilities and measure its surprise at the right answer.",
  needs: ["b2-ai-06", "b2-in-09", "b2-in-03"],
  tools: ["softmax", "tinynet"],
  play: { scene: "softmax", props: { z0: 2, z1: 1, z2: 0, c: 0 },
    say: "Three sliders for a network's scores for cat, dog and fox, and three chance bars that always add to 1. The surprise meter shows −log₂ of the right answer's chance. Slide a wrong score up and the surprise climbs; add the same amount to all three and nothing changes." },
  guess: { scene: "softmax", props: { z0: 1, z1: 1, z2: 1, c: 0, quiet: true }, kind: "slider", min: 0, max: 3, step: 0.05, start: 0.5, answer: Math.log2(3), near: 0.15,
    format: x => `${x.toFixed(2)} bits`,
    ask: "All three scores are equal. Slide the surprise needle to your guess, in bits.",
    revealProps: { z0: 1, z1: 1, z2: 1, c: 0 },
    reveal: "Each bar is 1/3, so the surprise is log₂ 3 ≈ 1.58 bits." },
  nameIt: {
    say: [
      "Softmax turns any list of scores into chances: raise e to each score and divide by the total.",
      "Cross-entropy is the surprise at the right answer, −log of its chance. A classifier learns by making that surprise small.",
      "Its gradient is simple: the chance it gave, minus 1 for the right class and minus 0 for the others.",
    ],
    formula: ["pᵢ = e^(zᵢ) / Σⱼ e^(zⱼ)", "loss = −log₂ p_correct (bits; training code uses ln, nats)", "∂loss/∂zᵢ = pᵢ − yᵢ (in nats)"],
  },
  workIt: {
    reference: { z: [3, 1, 1], c: 0 },
    generate(rng, i) {
      if (i < 3) {
        const a = rng.int(-1, 4);
        let b: number;
        do b = rng.int(-1, 4); while (b === a);
        const odd = rng.int(0, 2), z = [0, 1, 2].map(k => (k === odd ? a : b));
        return { z, c: rng.int(0, 2) };
      }
      return { z: [rng.int(-1, 4), rng.int(-1, 4), rng.int(-1, 4)], c: rng.int(0, 2) };
    },
    show: p => `Scores **cat ${num(p.z[0]!)}, dog ${num(p.z[1]!)}, fox ${num(p.z[2]!)}**. The right answer is **${CLASSES[p.c]}**. Use the calculator; answers to 2 places.`,
    steps(p) {
      const m = Math.max(...p.z), lo = Math.min(...p.z), pc = p07(p), tot = p.z.reduce((a, b) => a + b, 0);
      const zc = p.z[p.c]!;
      return [
        multiStep("shift", "Subtract the largest score", p.z.map(v => v - m), "whole", { boxes: CLASSES, ask: "Same softmax, smaller numbers.",
          hint: `Take ${num(m)} from each score.`,
          slips: [lo !== m && slip("smallest", p.z.map(v => v - lo), "Subtract the largest score, so the biggest becomes 0 and every e to a power stays at most 1.")] }),
        numStep("p", `p for ${CLASSES[p.c]}`, pc, 2, { hint: `e to the ${CLASSES[p.c]} score over the sum of e to each score.`,
          slips: [tot > 0 && zc >= 0 && slip("no e", zc / tot, "Softmax uses e to each score, not the scores themselves: e³ against e¹, not 3 against 1.")] }),
        numStep("bits", "Surprise in bits", -log2(pc), 2, { hint: `−log₂ ${dec(pc, 3)}.`,
          slips: [
            slip("negative", log2(pc), "The log of a number below 1 is negative, so the minus sign makes surprise positive."),
            slip("nats", -Math.log(pc), "That is in nats, with ln. For bits use log₂: divide by ln 2."),
          ] }),
        numStep("grad", "Gradient on the right score, p − 1", pc - 1, 2, { hint: `p − 1 = ${dec(pc, 3)} − 1.`,
          slips: [
            slip("p", pc, "For the right class the gradient is p − 1. It is negative, so the step pushes that score up."),
            slip("1 − p", 1 - pc, "It is p − 1, not 1 − p: negative, so a step against it pushes that score up."),
          ] }),
      ];
    },
    scene: p => ({ scene: "softmax", props: { z0: p.z[0]!, z1: p.z[1]!, z2: p.z[2]!, c: p.c } }),
  },
  oracle: p => {
    const pr = Math.exp(p.z[p.c]!) / p.z.reduce((s, v) => s + Math.exp(v), 0), m = Math.max(...p.z);
    return [...p.z.map(v => v - m), pr, -Math.log2(pr), pr - 1];
  },
  useIt: {
    say: ["Switch the splitter's output to softmax with cross-entropy and train; read the falling bits on the surprise meter.",
      "This is the reader's output layer. Then make the two-color splitter your own."],
    project: "ai-splitter",
  },
  deeper: [
    "Softmax is the gradient of log-sum-exp, a smooth version of max; dividing scores by a temperature T sharpens (T < 1) or flattens (T > 1) it.",
    "Cross-entropy H(y, p) = H(y) + KL(y‖p) (b2-in-09), so minimizing it minimizes the KL divergence to the truth, and it equals maximum likelihood (b2-pr-09).",
    "Log loss is a strictly proper scoring rule: it is minimized in expectation only by reporting your true beliefs, which sets up calibration in b2-ai-16.",
  ],
};
