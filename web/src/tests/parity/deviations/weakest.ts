// Curriculum fixes-02 (2026-10-06), "Weakest lessons": the 11 lessons rewritten to Curriculum's drafts in
// fixes-02-teaching.md (Teaching-quality pass, grades 4 to 7). Each keeps its step ids; a step the draft adds
// has no recording and is listed as `added:<id>`. Where a draft changes what an in-between step asks, it is listed
// as `answers:<id>`; final answers are always compared. (g4-lineplot is new in the rebuild and has no recording.)
const SLIPS = "new named slips from the fixes-02 draft; a wrong try that is none of them repeats the new hint";

export const deviations: Record<string, Partial<Record<string, string>>> = {
  "g6-divide": {
    story: "K–12 lesson check (Review 2026-10-07): the ribbon story asks how many times the piece fits, since the answer is often a fraction of a bow",
    pre: "g5-unitdiv: \"how many 1/4 fit in 3?\" is the meaning dividing builds on (fixes-02 draft)",
    "added:size": "a first tap step, \"Will more than one c/d fit in a/b?\", so the learner sizes the answer before any rule",
    hint: "the flip hint says why: how many c/d fit in one whole; the multiply hint no longer names the bottom (it was the answer when c = 1)",
    checks: "a wrong try that names no slip repeats the new hint",
  },
  "g5-multdec": {
    hint: "the hints point at counting the places in both numbers and at what the answer counts, instead of stating 1 + 1 (fixes-02 draft)",
    explain: "Show me says the result where it only repeated the hint",
    checks: `${SLIPS}: "Added instead of multiplied", "Counted one number", and the point slips use number sense ("too big: 0.3 is less than 1")`,
  },
  "g5-order": {
    "added:first": "a first tap step, \"Which part do you work out first?\", where the left-to-right slip can really happen (fixes-02 draft)",
    hint: "the hints say why each part is next instead of repeating the label (\"Now add.\")",
    explain: "Show me says the result where it only repeated the hint",
    checks: SLIPS,
  },
  "g6-expo": {
    "added:count": "a first step, \"how many 2s are multiplied together?\", for what an exponent means (fixes-02 draft)",
    prompt: "the add step shows the whole expression aⁿ + b × c, so the add-before-multiply slip can happen there",
    work: "the add step's worked line is the whole expression with its answer",
    hint: "the hints say why × comes next and what is left, instead of \"Multiply before adding.\" and \"Add last.\"",
    explain: "Show me says the result where it only repeated the hint",
    checks: `${SLIPS}: "Added before multiplying", "Multiplied the base by the exponent", "Added instead of multiplied"`,
  },
  "g6-trap": {
    hint: "the hints follow the two-copies parallelogram from the idea instead of naming the operation",
    explain: "Show me says the result where it only repeated the hint",
    checks: `${SLIPS}: "Multiplied the bases", "Added the height"`,
  },
  "g7-prop": {
    pre: "g6-ratio: equal ratios by scaling (fixes-02 draft)",
    "answers:cross": "step \"cross\" now finds one part (b·k ÷ b = k) instead of the cross product, so the learner practises the scale the picture shows; x is unchanged",
    steps: "the steps are \"One part\" and \"Build x\"; cross multiplying stays as the check in the last beat",
    prompt: "one part = b·k ÷ b, then x = a × k",
    hint: "the hints follow the one-part method",
    explain: "Show me follows the one-part method",
    work: "the worked lines are the one-part method's",
    checks: `${SLIPS}: "Added instead of scaled", "Added the part"`,
  },
  "g5-units": {
    story: "The current app told every conversion as a rope's length (\"A rope is 8 kilograms long\"). The story now fits what the unit measures: a rope for feet, yards and meters, a bag of flour for kilograms and pounds, a road trip for hours, a fish tank for gallons. Same numbers, same operation (×).",
    pre: "g4-convert: grade 5 adds the other direction and halves (fixes-02 draft)",
    "added:more": "a tap step, \"Will the answer be more or fewer … than n?\", before multiplying or dividing (fixes-02 draft)",
    hint: "\"1 kilogram is 1000 grams.\" gave the answer; the hint is g4-convert's \"Think of one kilogram. How many grams fit in it?\", and the multiply hint says why",
    explain: "Show me says the result",
    checks: `${SLIPS}: g4-convert's mix-ups ("Used 10", "Mixed up a day" …) and "Divided instead of multiplied"`,
  },
  "g4-angles": {
    unit: "\"Lines and shapes\", right after g4-lines, which first says what an angle is (fixes-02 Order 1)",
    pre: "g4-lines (fixes-02 Order 1)",
    prompt: "the missing part is asked as a° + [ ]° = T°, so the step doesn't hand over the operation (fixes-02 draft)",
    hint: "\"Is it a square corner or a straight line?\": the old whole hint stated both answers",
    explain: "Show me says the result where it only repeated the hint",
    work: "the worked line is a° + b° = T°",
    checks: `${SLIPS}: "Used the wrong whole", "Added"`,
  },
  "g7-subint": {
    pre: "g7-addint: adding the opposite needs adding integers (fixes-02 draft)",
    hint: "\"Add the two numbers.\" is now \"Start at a and move |b| right/left.\"",
    explain: "Show me says where the move lands",
    checks: `${SLIPS}: "Wrong sign"`,
  },
  "g6-pctof": {
    checks: `${SLIPS}: "Multiplied by the percent", "Found what's left"`,
  },
};
