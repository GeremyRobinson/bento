# Bento² · The math behind AI (capstone, 16 lessons)

**What it is:** how computers learn from examples. A line of best fit becomes a neural network, everything learns by stepping downhill on an error landscape, and the same few ideas, scaled up, run today's language models.

**Track code:** `ai`. **Role:** capstone. **Needs:** all five spine tracks: la (linear algebra), pr (probability and statistics), mv (multivariable calculus and optimization), in (information and entropy), cs (logic, algorithms and computation). Lessons point at spine lessons by id, with the topic in brackets. "Needs" never locks anything.

**Main tool:** ★ Tiny neural network (grows into the Digit reader).

## The build: a digit reader you trained yourself

The learner ends with a working network that reads handwritten digits they draw, says how sure it is, and has a "not sure" threshold, so the reader can hold back when it's unsure (and the learner tests how well that works on scribbles). Every unit adds a part:

| Unit | What it adds to the Digit reader |
|---|---|
| 1. Learning is rolling downhill | The training loop: a loss, a gradient step and a learning-rate dial (`eta`). |
| 2. Neurons and networks | The network: neurons, a hidden layer with ReLU, backpropagation, and a softmax output with cross-entropy loss. |
| 3. Reading digits | The real thing: 8×8 pixel input, a 64 → 16 → 10 network (1,210 learned numbers), mini-batch training, a test set, a confusion grid and a "what did it look at" map. Saved as `digit_reader`. |
| 4. Words and attention | An optional upgrade: cut the digit into 16 patches and let the patches attend to each other (a tiny vision transformer). The learner compares it with the plain reader. |
| 5. Where AI is going | A scaling plot of the reader's own test error against training-set size, a compute estimate, a goal-sandbox lesson on what "good score" can hide, and calibration: a temperature `T_digits` and a "not sure" threshold, so the reader can hold back when it's unsure (the learner tests how well that works on scribbles). |

## Units

1. **Learning is rolling downhill** (b2-ai-01 to 03): loss, gradient descent, the learning rate.
2. **Neurons and networks** (b2-ai-04 to 07): the neuron, layers, backpropagation, softmax and cross-entropy.
3. **Reading digits** (b2-ai-08 to 09): pictures as vectors, training and testing the reader.
4. **Words and attention** (b2-ai-10 to 12): embeddings, attention, the transformer.
5. **Where AI is going** (b2-ai-13 to 16): scaling laws, optimization at scale, Goodhart's law in a toy world, calibration.

## Small projects

| After | Project | What the learner makes and keeps |
|---|---|---|
| b2-ai-03 | **Line fitter** | Drag in their own points (or paste data from the pr stats panel), pick a learning rate, and watch the line fit itself while the loss curve drops beside it. Saves `w_line`, `b_line`, `eta`. |
| b2-ai-07 | **Two-color splitter** | Draw dots of two colors (rings, stripes, an XOR checkerboard), train a 2 → 4 → 2 network, and watch the boundary bend round by round. Saves `net_small`. |
| b2-ai-09 | **Digit reader, version 1** (build milestone) | The trained reader in the Notebook: draw a digit, see the confidence bars and the pixel map. Saves `digit_reader`. |
| b2-ai-12 | **Next-letter machine** | Type or paste any text, train a tiny one-block character model on it, sample from it at different temperatures, and read its bits per letter on the last 10% of the text (held back from training) on the in Surprise meter. Saves `letters_model`, `bits_per_letter`. |
| b2-ai-16 | **Reader field notes** (build finished) | One Notebook page: the reader's scaling plot and fitted slope, its training compute, its calibration diagram before and after temperature, the "not sure" threshold, and one loophole the learner found in the goal sandbox. |

The gap from b2-ai-07 to b2-ai-09 is 2 lessons, shorter than the usual 3 to 5, because b2-ai-09 is a build milestone rather than a separate project.

## New for Development

Toolbox names first; "new" marks a tool or picture not in the toolbox yet.

1. ★ **Tiny neural network** (toolbox). Needs: dots the learner draws, a 2-input network with up to 2 hidden layers of up to 8 neurons, ReLU or sigmoid, softmax output, a live decision boundary redrawn every training round, a play/step/pause control, and a fixed random seed so a run can be replayed exactly.
2. **Digit reader** (toolbox). Needs: an 8×8 drawing pad (finger strokes downsampled to 64 gray levels 0 to 1), a bundled set of labeled digits at 8×8 with at least 3,000 training images plus a separate test set (Development is choosing: the UCI handwritten digits, 5,620 images with 3,823 for training and 1,797 for testing, if its license checks out, with a credit line; otherwise digits drawn by a program, described as such; b2-ai-13 needs the 3,000 training images either way), the pad's downsampling matched to the dataset's preprocessing, in-browser training of a 64 → 16 → 10 network with mini-batch SGD, confidence bars for the 10 digits, a 10×10 confusion grid, and a pixel map (the gradient of the chosen digit's score with respect to each pixel). A fixed-seed overfitting preset (100 training images, a large hidden layer), verified to show the test loss turning up. Optional patch-attention mode for unit 4. Training must finish in seconds on a phone (about 2 × 10⁸ arithmetic steps, see b2-ai-14).
3. **Line fitter** (toolbox). Draggable points, a line with `w` and `b`, squares drawn on each residual, and a loss-over-time graph beside it.
4. **Loss landscape** (toolbox). Shares the mv **Surface explorer**: the loss over (w, b) as a 3D surface with contours, and the model as a ball. Clicking a spot on the surface sets the line in the Line fitter, and the other way round.
5. **Learning-rate dial** (toolbox). A dial for η that redraws the path of the ball on a 1D parabola and on the 2D contours: creep, land, zigzag, blow up.
6. **Word arrows** (toolbox). A small embedding table (about 50 words in 2D for the plain path, and a 3D view), projected from real word vectors (GloVe, Public Domain Dedication and License; or word2vec, Apache-2.0) and labeled on screen as a projection, arrow arithmetic on the Vector board (la), and a nearest-word finder with cosine similarity.
7. **Backprop graph** (new). A computation graph on the cs **Algorithm stage**: nodes for each operation, a forward sweep that writes values on the wires (blue), and a backward sweep that writes gradients (orange), one node at a time. Includes a finite-difference check button.
8. **Softmax bars** (new). Sliders for 2 to 10 scores (logits), live probability bars, a temperature slider, and the in **Surprise meter** showing −log₂ of the correct answer's probability.
9. **Attention grid** (new). Tokens along both sides, a heatmap of attention weights, the query and key arrows for a chosen token (Vector board), and a "mask the future" switch. Also used for the patch-attention view of a digit.
10. **Transformer block view** (new). A live stack: embedding, attention, add, MLP, add, repeated L times, with parameter counts on each box that update as d, L and the vocabulary size change.
11. **Log-log plotter** (new, named in the toolbox's "Where AI is going"). Plots (x, y) on log axes, fits a line by dragging or by least squares, shows the slope and lets the learner extend the line past the data, with a shaded "no data here" zone.
12. **Compute meter** (new). C = 6ND with scientific-notation inputs, converted to seconds, hours and days at a chosen speed.
13. **Goal sandbox** (new, named in the toolbox). A grid world with a cleaning robot, a reward the learner writes from parts ("+1 per tile the camera sees as clean", "−1 per move"), an optimizer whose strength is a slider (how many plans it tries), and two meters side by side: the reward it gets and the true goal.
14. **Reliability diagram** (new). Bins of confidence against accuracy with a diagonal "perfect" line, gap bars, an ECE readout, a temperature slider, and a "not sure" threshold with a coverage readout.

Shared tools used here: Matrix pad, Vector board (la), Simulator (pr), Surface explorer (mv), Surprise meter (in), Algorithm stage and Growth race (cs).

---

## Unit 1 · Learning is rolling downhill

### b2-ai-01 · Loss: how wrong is a model?
- **You can:** score any model's guesses with one number, the loss.
- **Needs:** st-lsrl (least-squares line).
- **Tool:** ★ Tiny neural network (line mode), Line fitter.
- **Play:** Five points and a line y = wx + b. Drag the line, or the points, and each point's miss (residual) is drawn as a real square whose area is the miss squared. The total area shows as a bar.
- **Guess:** Two lines are shown, one passing exactly through two points and missing the third by 3, one missing all three by 1 (misses 1, −1, 1). Pick the one with the smaller loss. The reveal draws both sets of squares and stacks their areas: 9 against 3.
- **Name it:** A loss is one number that says how wrong a model is on the data. Mean squared error squares each miss so big misses count a lot and misses can't cancel, then averages. Learning means changing the model to make this number small.
  MSE = (1/n) Σ (yᵢ − ŷᵢ)², where ŷᵢ = w xᵢ + b.
- **Work it:** 3 points with xᵢ ∈ {0, 1, 2, 3, 4} (distinct), the line's w ∈ {−2, −1, 1, 2} and b ∈ {−2, …, 3}, and yᵢ chosen so each residual is in −3 to 3, with at least one positive and one negative residual. Index < 3: x = 0, 1, 2 and w = 1. Lines render with the shared helpers (no coefficient 1, no plus sign before a minus sign). Example: points (0, 0), (1, 3), (2, 3), line y = x + 1.
  1. **Predictions** three boxes: 1, 2, 3.
  2. **Misses y − ŷ** three boxes: −1, 1, 0.
  3. **Sum of squares**: 2.
  4. **MSE** (fraction): 2/3.
  Slips: typed 0 at step 3 (added raw misses) "Misses above and below cancel when you just add them. Square each one first." · typed 2 at step 4 "That is the total. Divide by the number of points, 3." · typed 1 at step 4 (divided by n − 1) "Divide by the number of points, n = 3. The n − 1 version is for estimating spread from a sample."
- **Oracle:** `frac(sum((y - (w*x + b))**2), n)`
- **Use it:** Score three lines someone proposes for the learner's own data in the Line fitter; save the best line's loss as `mse_line`. This is the number the training loop will shrink.
- **Deeper:** Why squares? If each y is the true line plus normal noise, the line with the smallest MSE is exactly the most likely line (maximum likelihood, b2-pr-09). Set the two partial derivatives of MSE to 0 and you get the normal equations XᵀX θ = Xᵀy (b2-la-11), so θ = (XᵀX)⁻¹Xᵀy in one shot when XᵀX is invertible. MSE is a convex bowl in (w, b), which is why every downhill path in b2-ai-02 ends at the same bottom. Other losses mean other noise models: absolute error goes with Laplace noise and gives the median, not the mean.

### b2-ai-02 · Gradient descent: take a step downhill
- **You can:** improve a model by stepping against its gradient.
- **Needs:** b2-ai-01; g12-chain; b2-mv-14 (gradient descent).
- **Tool:** ★ Tiny neural network (line mode), Loss landscape, Line fitter.
- **Play:** Left, the data and a line through the origin, y = wx. Right, the loss as a curve over w with a ball at the current w and a tangent arrow. Press "step" and the ball moves against the slope while the line swings toward the points.
- **Guess:** Before the first step, drag a ghost ball to where you think it lands. The reveal shows the real step; repeated steps show it covering half the remaining distance each time (for the default learning rate).
- **Name it:** The derivative of the loss tells you which way is uphill and how steep. Step the other way, by an amount set by the learning rate η. Repeat. That loop is how almost every AI model learns.
  w ← w − η · dL/dw, with dL/dw = (2/n) Σ xᵢ (w xᵢ − yᵢ) for y = wx.
- **Work it:** Two points on a line through the origin, start w₀ = 0. Sets: points (1, k), (2, 2k) with η ∈ {0.1, 0.2, 0.3}, or points (1, k), (3, 3k) with η ∈ {0.05, 0.1}; k ∈ {1, 2, 3, 4}. Then dL/dw = 5(w − k) for the first set and 10(w − k) for the second. Index < 3: first set, η = 0.1. Example: (1, 2), (2, 4), η = 0.1.
  1. **Gradient at w₀** (integer): (2/2)(1·(0 − 2) + 2·(0 − 4)) = −10.
  2. **w₁** (decimal): 0 − 0.1·(−10) = 1.
  3. **Gradient at w₁**: (1·(1 − 2) + 2·(2 − 4)) = −5.
  4. **w₂**: 1 − 0.1·(−5) = 1.5.
  (Answers in general: η = 0.1 gives w₁ = 0.5k, w₂ = 0.75k; η = 0.2 gives w₁ = k at once; η = 0.3 overshoots to w₁ = 1.5k, then w₂ = 0.75k; the second set with η = 0.05 halves the gap, with η = 0.1 lands at once.)
  Slips: w₁ = −1 (added the gradient) "You stepped uphill. Subtract η times the gradient: the gradient points the way the loss rises." · w₁ = 10 (forgot η) "Scale the gradient by the learning rate before stepping." · gradient −5 at step 1 (dropped the 2 from the square, or averaged it away) "The derivative of (wx − y)² is 2x(wx − y). Keep the 2, then divide by n = 2."
- **Oracle:** `w1 = w0 - eta * (2/n) * sum(x*(w0*x - y))`, repeated for w₂.
- **Use it:** Train the Line fitter on the learner's points with both w and b moving (two partial derivatives, one step each) and watch the loss curve fall. This loop is the engine of the build.
- **Deeper:** With many weights the update is θ ← θ − η∇L(θ) (b2-mv-14). For a convex loss with an L-Lipschitz gradient and η = 1/L, the error after t steps is at most L‖θ₀ − θ*‖²/(2t), an O(1/t) rate; with strong convexity μ it becomes geometric, shrinking by (1 − μ/L) per step. The continuous-time version dθ/dt = −∇L(θ) is gradient flow, an ODE (de), and the loss only ever goes down along it.

### b2-ai-03 · The learning rate: creep, land, zigzag, blow up
- **You can:** pick a learning rate that converges, and say why too big fails.
- **Needs:** b2-ai-02; b2-mv-13 (second derivative, curvature).
- **Tool:** Learning-rate dial, Loss landscape.
- **Play:** A ball on the bowl L(w) = a(w − m)². Turn the η dial and the ball's path redraws instantly: tiny steps crawling, one perfect jump, a zigzag that settles, a zigzag that flies off. A second panel shows a long, narrow 2D valley where one η must work for both directions.
- **Guess:** For a = 2, drag a marker on the η dial to the η where you think it stops settling. The reveal sweeps η upward and the path flips from settling to exploding at η = 0.5.
- **Name it:** On a bowl, each step multiplies your distance from the bottom by the same factor. If that factor is between −1 and 1 you settle; past −1 every step overshoots more than the last. Steeper bowls need smaller steps.
  For L = a(w − m)²: (w − m) ← r · (w − m), with r = 1 − 2ηa. It settles when 0 < η < 1/a, lands in one step at η = 1/(2a).
- **Work it:** a ∈ {1, 2, 5}; η from a list giving clean r: a = 1 with η ∈ {0.1, 0.25, 0.5, 0.75, 1, 1.2}; a = 2 with η ∈ {0.1, 0.25, 0.4, 0.5, 0.6}; a = 5 with η ∈ {0.02, 0.1, 0.16, 0.2, 0.24}. m ∈ {−3, …, 5}, w₀ = m + d with d ∈ {10, 20}. Index < 3: r positive. Example: a = 2, η = 0.1, m = 3, w₀ = 13.
  1. **Factor r** (decimal): 1 − 2(0.1)(2) = 0.6.
  2. **What happens** tap: creeps in from one side / lands in one step / zigzags and settles / bounces forever / blows up. Answer: creeps in from one side.
  3. **w₃** (decimal): 3 + 0.6³·10 = 5.16.
  4. **The η where it stops settling** (fraction): 1/a = 1/2 (at this η it bounces forever; any larger blows up).
  Slips: r = 1.4 (sign) "The step subtracts: r = 1 − 2ηa, not 1 + 2ηa." · tapped "blows up" when −1 < r < 0 "A negative factor means you overshoot, but if |r| < 1 each overshoot is smaller. It zigzags in." · step 4 typed 1/(2a) "That η lands in one step, the best one. It stops settling at twice that, 1/a." · w₃ = 3 + 0.6·3·10 "Each step multiplies by r again: r³, not 3r."
- **Oracle:** `r = 1 - 2*eta*a; w3 = m + r**3 * (w0 - m)`
- **Use it:** In the Line fitter, find by trial the biggest η that still settles on the learner's data, then compare it with 1/a read off the bowl's curvature. Save it as `eta`; the build's training loop starts from it.
- **Deeper:** In many dimensions the curvature is the Hessian H (b2-mv-13), and gradient descent is stable when η < 2/λ_max(H) (here λ = 2a, which gives 1/a). The narrowest direction sets the speed limit, so the widest direction crawls: the number of steps grows with the condition number κ = λ_max/λ_min. Momentum (heavy ball, Nesterov) cuts that to about √κ. Real networks often train at the "edge of stability", where λ_max hovers near 2/η (Cohen et al. 2021), an observation that is measured but not fully explained.

**Project A · Line fitter** (see Small projects).

---

## Unit 2 · Neurons and networks

### b2-ai-04 · The neuron: weigh, add, squash
- **You can:** compute what a single neuron outputs and draw the line it splits along.
- **Needs:** b2-ai-02; b2-la-03 (dot product); c-transcend (eˣ).
- **Tool:** ★ Tiny neural network (one neuron).
- **Play:** Dots of two colors in the plane and one neuron with two weights and a bias as sliders. The plane shades by the neuron's output from 0 (blue) to 1 (orange), and the 0.5 line is drawn. Drag the weights and the line turns; drag the bias and it slides.
- **Guess:** Double both weights and the bias. Does the dividing line move, turn, or stay put? Pick one. The reveal: it stays, but the shading gets sharper (the neuron gets more confident).
- **Name it:** A neuron takes a weighted sum of its inputs plus a bias, then squashes it to a number between 0 and 1. It says "orange" when the sum is positive. So one neuron can only split the plane with a straight line.
  z = w₁x₁ + w₂x₂ + b, output σ(z) = 1/(1 + e^(−z)). The boundary is w₁x₁ + w₂x₂ + b = 0.
- **Work it:** w₁, w₂ ∈ {−2, −1, 1, 2}, b ∈ {−2, …, 2}, point (x₁, x₂) with integer coordinates in −2 to 2, chosen so z ∈ {−2, −1, 0, 1, 2}. Index < 3: z ∈ {0, 1, 2}. Expressions render with the shared helpers (no coefficient 1, no plus sign before a minus sign). Example: w = (2, −1), b = 1, point (1, 2).
  1. **z** (integer): 2·1 + (−1)·2 + 1 = 1.
  2. **Which side** tap orange (σ > 0.5) / blue / on the line: orange.
  3. **σ(z)** (2 decimals): 0.73. (Table: σ(−2) = 0.12, σ(−1) = 0.27, σ(0) = 0.5, σ(1) = 0.73, σ(2) = 0.88.)
  4. **Where the line crosses the x₂-axis** (fraction): −b/w₂ = 1.
  Slips: z = 0 (forgot the bias) "Add the bias b after the weighted sum." · typed 1 at step 3 "That is z. The neuron's output is σ(z), squeezed between 0 and 1." · step 4 typed b/w₂ "On the axis x₁ = 0, so w₂x₂ + b = 0 and x₂ = −b/w₂."
- **Oracle:** `z = w1*x1 + w2*x2 + b; round(1/(1 + exp(-z)), 2)`
- **Use it:** Hand-tune one neuron to split a two-color data set the learner draws, then press train (gradient descent from b2-ai-02 on the log loss) and watch it finish the job. The best weights go to the Number shelf as `neuron_w`.
- **Deeper:** σ′(z) = σ(z)(1 − σ(z)), which is why the sigmoid's gradient fades when it is very sure. Training one sigmoid neuron with loss −[y ln p + (1 − y) ln(1 − p)] is logistic regression; z is the log-odds ln(p/(1 − p)) (b2-pr-04). The perceptron convergence theorem: if a line with margin γ separates data inside a ball of radius R, the perceptron rule makes at most (R/γ)² mistakes. No single neuron can do XOR, which is the door to the next lesson.

### b2-ai-05 · Layers: why one bend is not enough
- **You can:** run a small network forward by hand: matrix, bias, ReLU, output.
- **Needs:** b2-ai-04; b2-la-05 (matrix times vector).
- **Tool:** ★ Tiny neural network (2 → 2 → 1), Matrix pad.
- **Play:** The XOR pattern: orange at (1, 0) and (0, 1), blue at (0, 0) and (1, 1). A network with two hidden ReLU neurons shows each hidden neuron's fold line, and the output surface in 3D as a creased sheet. Drag any weight and watch the creases move until the four corners split.
- **Guess:** Can a single neuron, no hidden layer, split XOR? Pick yes or no. The reveal lets the learner try for 20 seconds with the one-neuron sliders, then shows why no line works: any line with both orange corners on one side has a blue corner there too.
- **Name it:** A layer is a matrix times the input, plus biases, then a bend. ReLU keeps positives and turns negatives into 0. Stacking layers lets the network fold the plane, so it can split patterns no single line can. Without the bend, two layers collapse into one matrix.
  h = ReLU(W x + b), y = v · h + c, with ReLU(z) = max(0, z) applied to each entry.
- **Work it:** W a 2×2 matrix with entries in −2 to 2, b ∈ {−2, …, 2}², x ∈ {−2, …, 2}², v ∈ {−2, …, 3}² (no zero entry), c ∈ {−2, …, 2}; chosen so exactly one hidden pre-activation is negative half of the time. Index < 3: x has entries 0 or 1, all of W nonnegative. Expressions render with the shared helpers (no coefficient 1, no plus sign before a minus sign); substituted values like 1·4 + 3·0 − 1 are fine. Example: W = [[1, 2], [−1, 1]], b = (0, −1), x = (2, 1), v = (1, 3), c = −1.
  1. **W x + b** two boxes: (1·2 + 2·1 + 0, −1·2 + 1·1 − 1) = (4, −2).
  2. **h = ReLU(…)** two boxes: (4, 0).
  3. **y** (integer): 1·4 + 3·0 − 1 = 3.
  Also, once per lesson, a tap: "Check the XOR net h₁ = ReLU(x₁ + x₂), h₂ = ReLU(x₁ + x₂ − 1), y = h₁ − 2h₂ at (1, 1)": 0.
  Slips: y = −3 (skipped ReLU) "ReLU turns the −2 into 0 before the output layer sees it." · step 1 gave (1, 4) (used the columns of W as rows) "Each hidden neuron uses one row of W: row 1 is (1, 2), so 1·2 + 2·1 + 0 = 4." · applied ReLU then added b "The bias goes in before the bend: ReLU(Wx + b)."
- **Oracle:** `h = [max(0, row·x + bi) for row, bi in zip(W, b)]; y = v·h + c`
- **Use it:** Build the XOR net by hand on the board, then let training find its own (often different) weights. Save the hand-built one as `xor_net`.
- **Deeper:** Universal approximation (Cybenko 1989, Hornik 1991; for ReLU, Leshno et al. 1993): one hidden layer with enough neurons can approximate any continuous function on a closed box as closely as you like. It says nothing about how many neurons or whether training finds them. A ReLU network is piecewise linear, and depth can create exponentially many linear pieces from the same number of neurons; there are functions a deep narrow net computes that need exponentially wide shallow nets (depth separation, Telgarsky 2016).

### b2-ai-06 · Backpropagation: the chain rule, run backwards
- **You can:** compute every weight's gradient in a small network with one backward pass.
- **Needs:** b2-ai-05; g12-chain; b2-mv-04 (multivariable chain rule); b2-cs-10 helps (graphs).
- **Tool:** Backprop graph (new, on the Algorithm stage), ★ Tiny neural network.
- **Play:** The network y = w₂ · ReLU(w₁x) with loss L = ½(y − t)², drawn as a chain of boxes. Press "forward" and values flow left to right in blue; press "backward" and gradients flow right to left in orange, each box multiplying by its local derivative. Nudge w₁ by a hair and watch L change by gradient × nudge.
- **Guess:** If w₁x is negative, how much does nudging w₁ change the loss? Pick: a lot / a little / not at all. The reveal: not at all, because the ReLU is flat there and passes back 0 (a "dead" neuron for this input).
- **Name it:** Backpropagation is the chain rule done in a smart order. Go forward once to get every value, then go backward once, multiplying local derivatives, and you get the gradient for every weight at about the cost of two forward passes. That's what makes training millions of weights possible.
  a = w₁x, h = ReLU(a), y = w₂h, L = ½(y − t)².
  ∂L/∂y = y − t, ∂L/∂w₂ = (y − t)·h, ∂L/∂h = (y − t)·w₂, ∂L/∂a = ∂L/∂h · [a > 0], ∂L/∂w₁ = ∂L/∂a · x.
- **Work it:** x ∈ {1, 2, 3}, w₁ ∈ {−1, 1, 2}, w₂ ∈ {−2, −1, 1, 2, 3}, t ∈ {−3, …, 6} with t ≠ y. About one problem in four has a ≤ 0. Index < 3: a > 0. Example: x = 2, w₁ = 1, w₂ = 3, t = 4.
  1. **Forward: y** (integer): a = 2, h = 2, y = 6.
  2. **L** (decimal): ½(6 − 4)² = 2.
  3. **∂L/∂y**: 2.
  4. **∂L/∂w₂**: 2 · 2 = 4.
  5. **∂L/∂w₁**: 2 · 3 · 1 · 2 = 12.
  Slips: step 5 = 6 (stopped at ∂L/∂a) "One more link: a = w₁x, so ∂a/∂w₁ = x, not w₁. Multiply by x = 2." · nonzero step 5 when a ≤ 0 "ReLU is flat for negative inputs, so it passes back 0. The gradient for w₁ is 0 here." · step 2 = 4 (dropped the ½) "L = ½(y − t)², so half of 4 is 2."
- **Oracle:** central difference `(L(w1 + 1e-5) - L(w1 - 1e-5)) / 2e-5` rounds to the answer (independent of the backward pass).
- **Use it:** Turn on gradient labels in the Tiny neural network and step the Two-color splitter's training one round at a time, reading the gradients on each wire. The build's training loop now uses backprop for every layer.
- **Deeper:** This is reverse-mode automatic differentiation: on a computation graph (a DAG, cs) visited in reverse topological order, the gradient of one output with respect to all n inputs costs a small constant times one evaluation (the cheap gradient principle; Baur and Strassen 1983 for arithmetic circuits). Forward mode costs one pass per input instead, so it wins only when inputs are few and outputs many. Products of many local derivatives explain vanishing and exploding gradients in deep nets, and why residual connections (b2-ai-12) help: they add an identity path whose derivative is 1.

### b2-ai-07 · Softmax and cross-entropy: scores into chances
- **You can:** turn a network's scores into probabilities and measure its surprise at the right answer.
- **Needs:** b2-ai-06; b2-in-09 (cross-entropy, bits); b2-in-03 (entropy of a distribution).
- **Tool:** Softmax bars (new), Surprise meter (in).
- **Play:** Three sliders for a network's scores (logits) for cat, dog and fox, and three probability bars that always add to 1. The Surprise meter shows −log₂ of the right answer's bar. Slide a wrong score up and watch the surprise climb; add the same number to all three and nothing changes.
- **Guess:** All three scores are equal. Drag the surprise needle to your guess in bits. The reveal: each bar is 1/3, so the surprise is log₂ 3 ≈ 1.58 bits.
- **Name it:** Softmax turns any list of scores into chances: raise e to each score and divide by the total. Cross-entropy is the surprise at the right answer, −log of its chance. A classifier learns by making that surprise small, and its gradient is simple: the chance it gave, minus 1 for the right class and minus 0 for the others.
  pᵢ = e^(zᵢ) / Σⱼ e^(zⱼ), loss = −log₂ p_correct (bits; training code uses ln, nats), ∂loss/∂zᵢ = pᵢ − yᵢ (in nats).
- **Work it:** Three integer scores in −1 to 4, correct class given. Index < 3: two scores equal. Calculator allowed; answers to 2 decimals, accepted within ±0.01. Example: z = (3, 1, 1), correct = class 1.
  1. **Subtract the largest score** three boxes: (0, −2, −2) (same softmax, smaller numbers).
  2. **p for the correct class** (2 decimals): 1/(1 + 2e^(−2)) = 0.79.
  3. **Surprise in bits** (2 decimals): −log₂ 0.787 = 0.35.
  4. **Gradient on the correct score, p − 1** (2 decimals): −0.21.
  Slips: p = 0.6 (divided scores without e) "Softmax uses e to the score: e³ vs e¹, not 3 vs 1." · surprise negative "log of a number below 1 is negative, so the minus sign makes surprise positive." · step 4 typed 0.79 "For the right class the gradient is p − 1. It is negative, so the step pushes that score up."
- **Oracle:** `p = exp(z[c]) / sum(exp(zi) for zi in z); round(-log2(p), 2)`
- **Use it:** Swap the Two-color splitter's output to softmax with cross-entropy and train; read the falling bits on the Surprise meter. This is the reader's output layer.
- **Deeper:** Softmax is the gradient of log-sum-exp, a smooth version of max; dividing scores by a temperature T sharpens (T < 1) or flattens (T > 1) it. Cross-entropy H(y, p) = H(y) + KL(y‖p) (b2-in-09), so minimizing it minimizes the KL divergence to the truth, and it equals maximum likelihood (b2-pr-09). Log loss is a strictly proper scoring rule: it is minimized in expectation only by reporting your true beliefs, which sets up calibration in b2-ai-16.

**Project B · Two-color splitter** (see Small projects).

---

## Unit 3 · Reading digits

### b2-ai-08 · Pictures as vectors: building the reader
- **You can:** turn a picture into a vector and count what a network has to learn.
- **Needs:** b2-ai-05; b2-ai-07; b2-la-01 (vectors); b2-la-05 (matrix times vector).
- **Tool:** ★ Digit reader (untrained), Matrix pad.
- **Play:** Draw a digit on the 8×8 pad and watch it become 64 numbers from 0 to 1, laid out as a grid and then as one long column. The network diagram 64 → 16 → 10 lights each hidden neuron by how strongly the picture matches its weights, shown as its own 8×8 tile.
- **Guess:** Drag a slider to guess how many numbers this 64 → 16 → 10 network learns. The reveal fills the count box by box: 1,024 + 16 + 160 + 10 = 1,210.
- **Name it:** To a network, a picture is just a vector: one number per pixel. Each hidden neuron takes a dot product of the picture with its own weight picture, so it acts like a template detector. Every weight and bias is a number that training will set.
  For s × s pixels, h hidden neurons and 10 digits: parameters = s²·h + h + h·10 + 10.
- **Work it:** s ∈ {8, 12, 16, 28}, h ∈ {10, 16, 20, 32}. Index < 3: s = 8. Example: s = 8, h = 16.
  1. **Inputs** s²: 64.
  2. **Layer 1 weights** s²·h: 1,024.
  3. **Layer 1 biases** h: 16.
  4. **Layer 2 weights and biases** 10h + 10: 170.
  5. **Total**: 1,210. (Check: s = 28, h = 32 gives 25,450.)
  Slips: total 1,184 (no biases) "Each neuron also has a bias: add h + 10." · step 1 typed 8 "The picture has 8 rows of 8 pixels: s² = 64 inputs." · total 90 (counted neurons) "Count the connections, not the neurons. Each of the 64 inputs connects to each of the 16 neurons."
- **Oracle:** `s*s*h + h + h*10 + 10`
- **Use it:** Set up the build's network in the Digit reader: choose h (default 16), see its count, and save the untrained net as `digit_reader`. Draw a digit: its guesses are random for now.
- **Deeper:** A first-layer weight row reshaped to 8×8 is literally a picture, and after training it looks like a blurry stroke detector. Convolution shares one small filter across every position: a 3×3 layer with c filters on a one-channel image has 9c + c parameters regardless of image size, and shifting the input shifts the output (translation equivariance). For MNIST-sized 28×28 images, the gap between 25,450 and a few hundred parameters is one reason convolutional nets won image tasks before transformers.

### b2-ai-09 · Training and testing the reader
- **You can:** train a network in mini-batches and judge it on data it has never seen.
- **Needs:** b2-ai-08; b2-ai-03; b2-pr-01 (sampling, random samples); st-sampdist.
- **Tool:** ★ Digit reader (training), Simulator (pr) for shuffling batches.
- **Play:** Drag the training-set size (100 up to the full training set) and the hidden size h, and the run replays from a fixed seed: two curves redraw live, error on the training images and on the held-out test images, with the test loss (cross-entropy) as a dashed line. Below, a 10×10 confusion grid fills in, and drawing a digit shows its confidence bars and a pixel map of what the network looked at.
- **Guess:** Drag the training-set size down to 100 with a large reader. Place a point on the graph where you think the test loss stops falling. The reveal runs the fixed-seed preset: the training error keeps falling toward 0; watch whether the test loss turns up (overfitting) or the test error just flattens.
- **Name it:** Real training uses a small random batch of examples for each step, which is cheaper and noisier than using them all. One pass through all the training images is an epoch. The only fair test is on images the network never trained on, and the confusion grid shows which digits it mixes up.
  Steps per epoch = N / B, total steps = E · N / B, accuracy = (sum of the diagonal) / (total).
- **Work it:** Part 1: N ∈ {600, 1200, 1500, 1800}, B ∈ {20, 30, 50, 60, 100} dividing N, E ∈ {5, 10, 20}. Part 2: a 3-digit confusion grid (rows = true, columns = predicted) with row totals 50 and diagonals from 38 to 49, and a unique largest off-diagonal cell. Index < 3: B = 50 or 100. Example: N = 1,500, B = 50, E = 10; grid for digits 1, 7, 9: true 1 → (48, 2, 0), true 7 → (6, 40, 4), true 9 → (0, 3, 47).
  1. **Steps per epoch**: 30.
  2. **Total steps**: 300.
  3. **Test accuracy** (percent, 1 decimal): 135/150 = 90.0.
  4. **Most common mistake** tap: "a 7 read as 1".
  Slips: step 2 = 30 "That's one epoch. Multiply by E = 10 epochs." · step 3 used one row "Accuracy uses the whole grid: all correct (the diagonal) over all 150 images." · tapped "a 1 read as 7" "Rows are the true digit. The 6 sits in row 7, column 1: a 7 read as 1."
- **Oracle:** `N // B`, `E * N // B`, `100 * trace(G) / G.sum()`, and the argmax off the diagonal.
- **Use it:** Train the build for real on the bundled digits, read its test accuracy, and find its most confused pair in the full 10×10 grid. Draw that pair yourself and look at the pixel maps. Saves `digit_reader` (trained) and `acc_digits`. **Build milestone: Digit reader, version 1.**
- **Deeper:** The pixel map is the gradient of the chosen digit's score with respect to each input pixel (a saliency map), one backward pass to the inputs instead of the weights. The mini-batch gradient is an unbiased estimate of the full gradient with variance shrinking like 1/B. Classical theory says test error ≈ train error plus a complexity term (VC dimension, Rademacher bounds), but those bounds are vacuous for large networks, which fit even random labels (Zhang et al. 2017) yet generalize on real ones. "Double descent" (Belkin et al. 2019): test error can fall again as models grow past the point where they fit the training set exactly. Why big networks generalize is an open research question.

---

## Unit 4 · Words and attention

### b2-ai-10 · Embeddings: words as arrows
- **You can:** measure how similar two embedded words are and do arrow arithmetic on meanings.
- **Needs:** b2-la-03 (dot product, length, angle); b2-ai-08.
- **Tool:** Word arrows, Vector board (la).
- **Play:** About 50 words as arrows in 2D. Tap two words and the angle between them shows with its cosine. Drag "king", subtract "man", add "woman", and see where the tip lands and which word is nearest.
- **Guess:** Pick which word lies closest in angle to "cat": "dog", "car" or "kitten" (the arrows are hidden; the map is a flattened projection of real word vectors, so its angles are only roughly the real ones). The reveal draws the arrows and the cosines. The answer is computed from the shipped map, which Development keeps only if the winner beats the runner-up by at least 0.1 in cosine.
- **Name it:** A model stores each word as a list of numbers, an embedding, learned so that words used in similar places end up pointing in similar directions. Similarity is the cosine of the angle between arrows, and some relations show up as consistent offsets you can add and subtract.
  cos θ = (u · v) / (|u| |v|). Embedding lookup: a one-hot vector times the embedding matrix picks one row.
- **Work it:** Part 1: u, v from {(3, 4), (4, 3), (−3, 4), (−4, 3), (0, 5), (5, 0), (5, 12), (12, 5), (6, 8), (8, 6)}, so lengths are whole numbers. Part 2: three word vectors with entries 0 to 8 whose result king − man + woman also has entries 0 to 8, and three candidates: exactly one within distance 1 of the result, the others at least 2 away. Index < 3: lengths both 5. Example: u = (3, 4), v = (4, 3); king (5, 6), man (4, 1), woman (4, 3), candidates queen (5, 7), prince (6, 5), girl (2, 4).
  1. **u · v**: 24.
  2. **|u| and |v|** two boxes: 5, 5.
  3. **cos θ** (fraction or 2 decimals): 24/25 = 0.96.
  4. **king − man + woman** two boxes: (5, 8).
  5. **Nearest word** tap: queen.
  Slips: step 3 typed 24 "Divide by both lengths so only the angle counts: 24/(5·5)." · step 4 gave (13, 10) (added man) "Subtract man, then add woman: (5 − 4 + 4, 6 − 1 + 3)." · tapped prince "Measure distance to (5, 8): queen is 1 away, prince is √10 ≈ 3.16."
- **Oracle:** `dot(u, v) / (norm(u) * norm(v))`; `argmin(norm(c - (k - m + w)) for c in candidates)`
- **Use it:** Find one offset that works in the Word arrows map (a country to its capital, a verb to its past tense) and one that doesn't; save the working offset as `offset_word`. Reading the map honestly matters: the famous analogies work less cleanly than the headlines say, especially once the input words are allowed as answers.
- **Deeper:** Skip-gram with negative sampling (word2vec) implicitly factorizes a matrix of shifted pointwise mutual information, PMI(w, c) − log k (Levy and Goldberg 2014), linking embeddings to the SVD (b2-la-17) and to mutual information (b2-in-10). Embedding tables hold vocabulary × d numbers, often the largest single piece of a small language model. In a transformer each token's vector changes layer by layer with context, so "bank" ends up in different places in "river bank" and "bank loan".

### b2-ai-11 · Attention: each word looks up the others
- **You can:** compute an attention output: scores, softmax weights, weighted average.
- **Needs:** b2-ai-10; b2-ai-07; b2-la-03 (dot product).
- **Tool:** Attention grid (new), Softmax bars, Vector board.
- **Play:** A short sentence, "the cat sat because it was tired", with each word's query and key arrows. Tap "it" and watch the heatmap row light up across the other words; drag the query arrow and the weights shift live. The output is drawn as a blend of the value arrows.
- **Guess:** Before revealing the row for "it", tap the word you think it attends to most. The reveal lights the row; in this trained toy model, "cat" gets the largest weight.
- **Name it:** Attention lets every position ask a question (query) and compare it with every position's label (key). The match scores go through softmax to become weights, and the answer is the weighted average of the positions' contents (values). Scaling by √d keeps the scores from getting huge as vectors get longer.
  sᵢ = (q · kᵢ)/√d, wᵢ = softmax(s)ᵢ, output = Σ wᵢ vᵢ. In matrix form: softmax(QKᵀ/√d) V.
- **Work it:** d = 4 (so √d = 2), q and three keys with entries in {−1, 0, 1, 2}, chosen so raw dot products are in 0 to 4; scalar values vᵢ ∈ {0, …, 12}. Index < 3: two of the scores equal. Answers to 2 decimals; output accepted within ±0.2 (weights rounded to 2 decimals can shift it by up to 0.005 × 36 = 0.18). Example: q = (1, 0, 1, 0), k₁ = (1, 0, 1, 0), k₂ = (0, 1, 0, 1), k₃ = (1, 1, 0, 0), v = (10, 0, 4).
  1. **Raw dot products** three boxes: (2, 0, 1).
  2. **Scaled scores** three boxes: (1, 0, 0.5).
  3. **Weight on position 1** (2 decimals): e¹/(e¹ + e⁰ + e^0.5) = 0.51.
  4. **Output** (2 decimals): 0.506·10 + 0.186·0 + 0.307·4 = 6.29.
  Slips: step 2 left unscaled "Divide by √d = 2 before softmax." · output 4.67 (plain average) "Attention is a weighted average: the weights come from softmax of the scores, not 1/3 each." · step 3 = 2/3 (used scores as weights) "Scores become weights through softmax: e to each score, over the total."
- **Oracle:** `w = softmax([dot(q, k)/2 for k in K]); round(sum(wi*vi for wi, vi in zip(w, v)), 2)`
- **Use it:** Turn on patch mode in the Digit reader: the 8×8 digit is cut into 16 patches of 2×2, and the Attention grid shows which patches each patch attends to. Train it and compare its test accuracy with `acc_digits`; save as `acc_patches`. (With this little data the plain reader often wins, and that's a real finding.)
- **Deeper:** Why √d: if q and k have independent entries with mean 0 and variance 1, q · k has variance d, so dividing by √d keeps scores near unit size and softmax out of its flat, saturated zone. Self-attention treats its inputs as a set (permutation equivariant), so position must be added (sinusoidal or rotary encodings). Causal masking sets future scores to −∞. Cost is about n²d for n tokens, quadratic in length (b2-cs-08, Growth race), which drives research on linear and sparse attention. Attention can be read as a kernel smoother (Nadaraya-Watson regression with a learned kernel).

### b2-ai-12 · The transformer: stack, add, predict the next word
- **You can:** describe a transformer block and count its parameters.
- **Needs:** b2-ai-11; b2-ai-07; b2-in-08 (bits per symbol).
- **Tool:** Transformer block view (new), Attention grid, Surprise meter (in).
- **Play:** A live stack of blocks: attention, add, a small two-layer network (MLP), add, repeated L times, with a parameter count on every box. Drag d (width) and L (depth) and watch the counts grow; type a prompt and see the next-token bars at the top, with a temperature slider.
- **Guess:** Double the width d. Does one block's parameter count double, triple or quadruple? Pick one. The reveal redraws the boxes: each block holds 12d², so it exactly quadruples (the embeddings V·d only double, so the total grows a little less).
- **Name it:** A transformer repeats one block: attention mixes information between positions, then a small network processes each position, and each result is added back onto its input (a residual), so information can pass straight through. It is trained to predict the next token, scored by cross-entropy.
  Per block: attention 4d² (query, key, value, output matrices) + MLP 8d² (d → 4d → d) = 12d². Total ≈ 12Ld² + V·d (embeddings), ignoring biases and norms. Perplexity = 2^(bits per token).
- **Work it:** L ∈ {1, 2, 4, 6}, d ∈ {16, 32, 64, 128}, V ∈ {50, 100, 256}; and bits per token ∈ {1, 2, 3, 4, 5}. Index < 3: L = 1 or 2, d = 16 or 32. Example: L = 2, d = 64, V = 100, 3 bits per token.
  1. **Attention per block** 4d²: 16,384.
  2. **MLP per block** 8d²: 32,768.
  3. **All blocks** 12Ld²: 98,304.
  4. **Total with embeddings**: 98,304 + 6,400 = 104,704.
  5. **Perplexity** 2³: 8 ("as unsure as picking among 8 equally likely tokens").
  Slips: step 1 = 256 (4d) "Each of the four matrices is d × d, so 4d²." · step 3 forgot L "Every block has its own weights: multiply by L = 2." · step 2 = 16,384 (MLP width d) "The MLP widens to 4d: d·4d in and 4d·d out, 8d² in all."
- **Oracle:** `12*L*d*d + V*d`; `2**bits`
- **Use it:** **Project C · Next-letter machine:** train a one-block character model on text the learner types, sample from it at temperatures 0.5, 1 and 1.5, and read bits per letter on the last 10% of the text, held back from training. Save `letters_model` and `bits_per_letter`.
- **Deeper:** The count checks out at scale: GPT-2 small has L = 12, d = 768, so 12·12·768² ≈ 84.9M in the blocks, plus 50,257 × 768 ≈ 38.6M token embeddings and 1,024 × 768 ≈ 0.8M position embeddings, about 124M, matching its published size. Layer normalization rescales each vector to mean 0 and variance 1. Residual streams make the network a sum of many paths, which is why deep stacks train. Sampling at temperature T divides the logits by T; T → 0 is greedy decoding. Transformers with enough precision and steps can simulate many algorithms, while what they reliably learn to do in practice is an active research area.

**Project C · Next-letter machine** (see Small projects).

---

## Unit 5 · Where AI is going

This unit keeps two labels on screen: **measured** (fits to experiments people have run) and **open** (what nobody knows yet). Every lesson says which is which.

### b2-ai-13 · Scaling laws: straight lines on a log-log plot
- **You can:** fit a power law on a log-log plot, read its slope, and say how far the line can be trusted.
- **Needs:** pc-logs; pc-semilog; b2-ai-09; b2-mv-17 (fitting a line by least squares).
- **Tool:** Log-log plotter (new), ★ Digit reader.
- **Play:** Points for test error against training-set size, on ordinary axes (a curve that flattens) and on log-log axes (nearly a straight line). Drag a line through the log-log points, read its slope, and extend it into the shaded "no data here" zone.
- **Guess:** The reader has been trained on 100, 300 and 1,000 images. Place a point for where its error will be at 3,000. The reveal trains it and plots the real point, showing how far it falls from the line. (The bundled set has at least 3,000 training images, so this run is real.)
- **Name it:** In many measured cases, a model's error falls like a power of its size, data or compute. A power law is a straight line on log-log axes, and its slope says how much better each tenfold increase makes things. These are fits to experiments, not laws of nature: they hold over the range measured, and there is usually a floor of error that never goes away.
  E = a · N^(−α), so log E = log a − α log N. Slope = (log E₂ − log E₁)/(log N₂ − log N₁) = −α.
- **Work it:** N₁ = 10^p with p ∈ {3, 4, 5, 6}, N₂ = 10^(p + k) with k ∈ {1, 2}, E₁ ∈ {0.8, 0.64, 0.48, 0.32}, E₂ = E₁ · r with r ∈ {1/2, 1/4}. Index < 3: r = 1/2. Example: E = 0.32 at 10⁴ images, 0.16 at 10⁶.
  1. **Slope** (2 decimals): log(0.5)/2 = −0.15.
  2. **Inside the measured range?** tap yes / no: is 10^(p + 2k) between N₁ and N₂? No (10⁸ is past 10⁶).
  3. **If the line kept going: error at 10^(p + 2k)** (2 decimals), two more steps along the line: E₁ · r² = 0.08 (at 10⁸ in the example).
  4. **Data multiplier to halve the error** tap 10 / √10 ≈ 3.16 / 100 / 1,000: 100.
  (Slopes in general: r = 1/2, k = 1 gives −0.30; r = 1/2, k = 2 gives −0.15; r = 1/4, k = 1 gives −0.60; r = 1/4, k = 2 gives −0.30.)
  Slips: slope −0.08 (subtracted errors, not logs) "On log-log axes the rise is log E₂ − log E₁ = log(1/2), not E₂ − E₁." · slope −0.30 for k = 2 "The run is 2 decades, from 10⁴ to 10⁶: divide by 2." · step 2 tapped yes "The data stops at N₂ = 10^(p + k). 10^(p + 2k) is in the shaded zone, so the line is only a guess there." · step 3 = 0 or 0.00 (extended the ordinary-axes line) "If the line kept going it would never reach 0: each further 10^k× more data multiplies the error by r again, to E₁ · r² (in the example, 100× more halves it, to 0.08). Whether real data follows it that far is the open part." (The slip text is built from k, r and E₁.)
- **Oracle:** `(log10(E2) - log10(E1)) / k`; `p + k < p + 2k` (so "no"); `E1 * r**2`
- **Use it:** Train the build on 100, 300, 1,000 and 3,000 images (and the full training set, if it is larger), plot test error on the Log-log plotter, fit the slope, and save `alpha_digits`. Then mark where the line would have to go for 0 error and note that it never gets there.
- **Deeper:** Measured: Kaplan et al. (2020) fit language-model test loss as power laws in parameters, data and compute with exponents near 0.076, 0.095 and 0.050 over several orders of magnitude; Hoffmann et al. (2022, "Chinchilla") fit L(N, D) = E + A/N^α + B/D^β and found compute-optimal training uses roughly 20 tokens per parameter. Minimizing L subject to C ≈ 6ND (a Lagrange problem, b2-mv-15) gives N_opt ∝ C^(β/(α + β)). Open: why power laws appear at all (one proposal ties α to the intrinsic dimension of the data, Sharma and Kaplan 2020), whether they continue, and how a smooth fall in loss turns into specific new abilities.

### b2-ai-14 · Optimization at scale: the same step, a billion times
- **You can:** estimate the compute a training run needs and explain why big models use small noisy batches.
- **Needs:** b2-ai-09; b2-ai-03; b2-mv-14 (gradient descent); b2-pr-01 (variance of a mean); b2-cs-08 (growth of running time).
- **Tool:** Compute meter (new), Loss landscape, Simulator (pr).
- **Play:** The loss-landscape ball, but each step uses a random batch: the arrow wobbles. Drag the batch size and watch the wobble shrink; switch the optimizer between plain SGD, momentum and Adam and race them down a long narrow valley.
- **Guess:** Batch size goes from 4 to 16. Drag the wobble bar to how big you think it gets. The reveal: half as big, not a quarter, because noise shrinks like 1/√B.
- **Name it:** Giant models learn with the same downhill step as your line fitter, just with billions of weights and noisy mini-batches. The cost of training is easy to estimate: about 6 arithmetic operations per parameter per training token (2 for the forward pass, about 4 for backprop). Smarter optimizers like Adam give each weight its own step size from the history of its gradients.
  C ≈ 6 N D floating-point operations (FLOPs), time = C / speed. Batch noise ∝ 1/√B.
- **Work it:** N = m · 10^a with m ∈ {1, 2, 5}, a ∈ {6, …, 9}; D = n · 10^b with n ∈ {1, 2, 5}, b ∈ {8, …, 11}; speed 10^s FLOP/s with s ∈ {14, 15, 16}; chosen so the time is a whole number of minutes (seconds divisible by 60). Index < 3: m = n = 1. Example: N = 10⁸, D = 2 × 10⁹, speed 10¹⁵ FLOP/s.
  1. **C, the number in front** (scientific notation, two boxes: 1.2 and exponent): 1.2 × 10¹⁸.
  2. **Seconds**: 1,200.
  3. **Minutes**: 20.
  4. **Tokens per parameter** D/N: 20.
  Slips: C = 2 × 10¹⁷ (forgot the 6) "Each parameter costs about 6 operations per token: 2 forward, 4 backward." · exponent 72 (multiplied exponents) "Multiplying powers of ten adds exponents: 10⁸ · 10⁹ = 10¹⁷." · C = 4 × 10¹⁷ (forward only, 2ND) "Training also runs backward, about twice the forward cost again: 6ND."
- **Oracle:** `6 * N * D`; `6 * N * D / speed`
- **Use it:** Estimate the build's own training compute: 6 × 1,210 parameters × 3,000 training images × 10 epochs ≈ 2.2 × 10⁸ FLOPs (each image counts as one example). At a phone's peak of about 10¹² FLOP/s that's about a fifth of a millisecond. In the browser it takes a few seconds, because real code rarely gets near peak. Save `C_digits`, then compare it with a published large run on the Compute meter's log scale.
- **Deeper:** Adam: m ← β₁m + (1 − β₁)g, v ← β₂v + (1 − β₂)g², θ ← θ − η m̂/(√v̂ + ε), with bias corrections m̂ = m/(1 − β₁ᵗ), v̂ = v/(1 − β₂ᵗ). Up to a critical batch size, doubling B lets you double η and halve the steps (the gradient noise scale, McCandlish et al. 2018); past it, bigger batches waste compute. In high dimensions most critical points are saddles rather than bad minima (Dauphin et al. 2014). Measured: SGD on overparameterized nets reliably reaches near-zero training loss. Open: a full theory of why the solutions it finds generalize (implicit bias of SGD).

### b2-ai-15 · Goodhart's law: optimize the score, miss the point
- **You can:** show in a toy world how pushing hard on a stand-in score can drift away from the real goal, and compute how much a high score should be trusted.
- **Needs:** b2-ai-14; b2-pr-08 (correlation and the best prediction); b2-pr-17 (conditional expectation, regression to the mean); b2-in-09 (KL divergence) for Deeper.
- **Tool:** Goal sandbox (new), Simulator (pr), drawing normal true values and normal noise.
- **Play:** A cleaning robot in a grid world. The learner writes its reward ("+1 for each tile the camera sees as clean") and drags "how hard it optimizes" (how many plans it tries). Two meters run side by side: reward and true cleanliness. Turn the optimizer up and watch it find a loophole, such as pushing dirt under the rug or parking with the camera facing a clean wall.
- **Guess:** The optimizer goes from trying 10 plans to 10,000. Pick what the true-cleanliness meter does: keeps rising / levels off / rises then falls. The reveal runs it with the learner's reward. With the camera reward it rises, then falls once loophole plans win; with a reward that counts actual dirt removed, it keeps rising. A switch shows both.
- **Name it:** Goodhart's law: when a measure becomes a target, it stops being a good measure. Any score is a stand-in for what you actually want, and the harder you search for a high score, the more likely the winner got there through the score's errors instead of the goal. Even with honest random errors, the top scorer's true value is usually lower than its score.
  If true value and noise are independent and normal, both with mean 0 and spreads σ_T² and σ_N², and proxy = true + noise: expected true value given proxy x = x · σ_T²/(σ_T² + σ_N²). Without normality, this is still the best straight-line estimate of the true value.
- **Work it:** Part 1: five plans A to E with (proxy, true) integer pairs from 1 to 10, where the top proxy plan is not the top true plan and both the highest proxy and the highest true value are unique. Part 2: (σ_T², σ_N²) from {(1, 1), (3, 1), (4, 1), (9, 1), (1, 3), (2, 3)}, proxy x ∈ {4, …, 20}. Index < 3: σ_N² = 1. Example: A (6, 5), B (9, 3), C (7, 7), D (4, 4), E (8, 6); σ_T² = 4, σ_N² = 1, x = 10.
  1. **Plan the optimizer picks** tap: B.
  2. **Its true value**: 3.
  3. **Gap to the best true plan** (C, 7): 4.
  4. **Shrink factor** σ_T²/(σ_T² + σ_N²) (decimal): 0.8.
  5. **Expected true value at proxy 10**: 8.
  Slips: tapped C at step 1 "The optimizer only sees the proxy. It picks the highest proxy, B, even though C is better." · step 4 = 0.25 or 0.2 (used noise on top) "Trust the score by the share of its spread that is real: σ_T² over the total, 4/5." · step 5 = 10 "A high score is partly luck. Expect the true value to be pulled back toward the average: 0.8 × 10."
- **Oracle:** `max(plans, key=proxy)`; `x * sT2 / (sT2 + sN2)`
- **Use it:** In the Goal sandbox, find one loophole in the default reward and then rewrite the reward to close it. Note that the new reward may open a different loophole. Save the loophole description to the Reader field notes. Then look at the build: the reader was trained on test-set accuracy as the target, so ask what that number misses (it never saw a "not a digit" scribble).
- **Deeper:** Manheim and Garrabrant (2018) split Goodhart into regressional (the shrinkage above), extremal (the link between proxy and goal breaks in regions never seen), causal and adversarial cases; the "optimizer's curse" (Smith and Winkler 2006) is the decision-theory version. With heavy-tailed proxy errors, extreme optimization can make the expected true value fall back toward no better than average, not just lag (Kwa et al. 2024, "catastrophic Goodhart"). A common fix is to optimize reward minus a penalty for moving away from a trusted starting behavior: maximize E[r] − β·KL(π‖π₀), whose solution is π ∝ π₀ · e^(r/β) (b2-in-09). For best-of-n sampling, the commonly used KL = ln n − (n − 1)/n from the start is an upper bound (Beirami et al. 2024). Measured: reward hacking appears in real reinforcement-learning systems (a boat-racing agent looping for points instead of finishing, 2016), and Gao, Schulman and Hilton (2022) measured a learned reward rising while a trusted "gold" reward rose then fell as optimization pushed further. Open: how to specify goals that stay good under strong optimization, and how to check that a powerful system is pursuing the intended goal.

### b2-ai-16 · Calibration: knowing what you don't know
- **You can:** check whether a model's confidence matches how often it's right, fix it with a temperature, and set when it should say "not sure".
- **Needs:** b2-ai-07; b2-ai-09; b2-pr-01 (relative frequency); b2-pr-04 (conditional probability); b2-in-09 (proper scoring, log loss).
- **Tool:** Reliability diagram (new), ★ Digit reader, Softmax bars.
- **Play:** The reader's test predictions sorted into confidence bins: bars show how often it was right in each bin against a diagonal "perfect" line. Drag the temperature T and the bars slide toward or away from the diagonal; drag the "not sure" threshold and watch coverage (how often it answers) trade against accuracy on the answers it gives.
- **Guess:** When the reader says it is 95% sure, place a point for how often you think it is actually right. The reveal fills that bin from the test set and shows how many test images are in it. Whatever it shows is this reader's real answer.
- **Name it:** A calibrated model's 80% means right 80% of the time. You check it by grouping predictions by confidence and comparing each group's average confidence with its accuracy. Dividing the scores by a temperature T > 1 cools an overconfident model without changing its top answer.
  ECE = Σ_bins (n_b / N) · |accuracy_b − confidence_b|. Temperature: p = softmax(z / T).
- **Work it:** Three bins with average confidences from {0.55, 0.6, 0.7, 0.75, 0.8, 0.9, 0.95}, counts summing to N ∈ {100, 200, 400}, correct counts chosen so each accuracy is a two-decimal number, ECE is exact, and every nonzero gap has the same sign. Answers exact decimals. Index < 3: one bin perfectly calibrated. Example: N = 200; bin 1 confidence 0.6, 40 predictions, 24 right; bin 2 confidence 0.8, 100 predictions, 70 right; bin 3 confidence 0.95, 60 predictions, 48 right.
  1. **Accuracy in each bin** three boxes: 0.6, 0.7, 0.8.
  2. **Gaps** three boxes: 0, 0.1, 0.15.
  3. **ECE** (exact decimal): (40·0 + 100·0.1 + 60·0.15)/200 = 19/200 = 0.095.
  4. **Over- or underconfident** tap: overconfident (confidence above accuracy).
  5. **To fix it, T should be** tap: greater than 1 / less than 1 / exactly 1: greater than 1.
  Slips: step 3 = 0.083 (plain average of gaps) "Weight each gap by how many predictions are in its bin: bin 2 holds half of them." · step 4 underconfident "It says 95% and is right 80% of the time: it claims more than it delivers, so it's overconfident." · step 5 less than 1 "Dividing scores by T < 1 makes them bigger and the model even surer. Use T > 1 to soften."
- **Oracle:** `sum(n_b * abs(c_b / n_b - conf_b) for each bin) / N`
- **Use it:** Calibrate the build: fit T on held-out digits to minimize log loss, save `T_digits`, and set a "not sure" threshold so the reader answers only when its top probability clears it. Record coverage and accuracy at that threshold, then draw a scribble that isn't a digit and see whether it says "not sure". **Build finished:** the Reader field notes page collects the scaling plot, `C_digits`, the loophole, and the before-and-after reliability diagrams.
- **Deeper:** Strictly proper scoring rules (log loss, Brier score) are optimized in expectation only by honest probabilities, and the Brier score splits into reliability − resolution + uncertainty (Murphy 1973): a forecaster can be perfectly calibrated and still useless (always predicting the base rate). Guo et al. (2017) measured that large modern deep networks are often overconfident (older, small networks such as LeNet were fairly well calibrated) and that a single temperature fixes much of it on in-distribution data. Conformal prediction turns any model into prediction sets that contain the true label with probability at least 1 − α, assuming only that test and calibration data are exchangeable. Measured: large language models' stated confidence is reasonably calibrated on some multiple-choice tasks (Kadavath et al. 2022). Open: calibration under distribution shift, and whether a model can reliably tell when a question is outside anything it has learned.

**Project D · Reader field notes** (see Small projects). The build is complete.
