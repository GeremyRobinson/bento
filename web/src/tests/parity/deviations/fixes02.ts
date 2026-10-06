// Curriculum fixes-02 (2026-10-06), grades 4 to 7: Part C's teaching pass. Hints point at the evidence instead of
// stating the answer, every typed step names a real slip, and `pre` links point at the lesson each one builds on.
// Answers, prompts and step labels are unchanged; a recorded wrong try that now matches a named slip gets that
// slip's message instead of "Not quite. <hint>", and the other wrong tries repeat the new hint.
// Lessons that already had an entry keep theirs in their family file (tape.ts, early.ts).
const HINT = "the hint points at where to look instead of stating the answer or just the operation (fixes-02 Part C patterns 3 and 4)";
const SHOW = "Show me starts from the new hint, or now says the result where it only repeated the hint";
const SLIPS = "new named slips (fixes-02 Part C pattern 3); a wrong try that is none of them repeats the hint";

export const deviations: Record<string, Partial<Record<string, string>>> = {
  "g4-dec": { pre: "g4-equiv: tenths become hundredths by renaming (Order 2)", checks: `${SLIPS}: "Used the tenths as they were"` },
  "g5-mult2": { pre: "g4-mult2x2: same area model, now one factor's tens and ones (Order 4)", checks: `${SLIPS}: "Added instead of multiplied", "Left out a part"` },
  "g5-pow10": { pre: "g4-dec: place value after the point (Order 4)", checks: `${SLIPS}: "Counted the 1 too", "Wrote the number"` },
  "g5-adddec": { checks: `${SLIPS}: "Forgot to carry" or "Subtracted", "Lost a whole" or "Left off the decimal part"` },
  "g5-divdec": { checks: `${SLIPS}: "Moved the point too far", "Moved the point the wrong way", "Put the point back", "Multiplied"` },
  "g5-fracof": { checks: `${SLIPS}: "Added", "Found the part not taken"` },
  "g5-round": { checks: `${SLIPS}: the digit steps name reading the wrong place and reading the place itself (and Part A2's wrong-place slip)` },
  "g5-multfrac": { hint: `${HINT}: "Top × top: 1 × 7" gave the top away`, explain: SHOW, checks: SLIPS },
  "g5-unitdiv": { hint: `${HINT}: "It takes 4 of them" gave the answer`, explain: SHOW, checks: `${SLIPS}: "Counted the cuts"` },
  "g6-eval": { hint: HINT, explain: SHOW, checks: `${SLIPS}: "Multiplied the parts"` },
  "g6-gcf": { hint: `${HINT}: the GCF hint gives a method (factors of the smaller number, biggest first)`, explain: SHOW, checks: `${SLIPS}: "Settled for 1", "Left the numbers whole", "Subtracted the factor"` },
  "g6-lcm": { hint: `${HINT}: "Check each multiple of 9" named the answer when the bigger number was it`, explain: SHOW, checks: `${SLIPS}: "Divided by the other number"` },
  "g6-mean": { checks: `${SLIPS}: "Left one out", "Wrote the total", "Missed one", "Multiplied"` },
  "g6-numline": { hint: `${HINT}: "How many steps from −4 to 0?" read the answer off the number`, explain: SHOW, checks: `${SLIPS}: "Counted the marks, not the steps"` },
  "g6-onestep": { pre: "g6-eval: the Check step puts a number in for x (Order 5)", checks: `${SLIPS}: "Wrote x again"` },
  "g6-pctwhole": { pre: "g6-pctof: finding the part comes before finding the whole (Order 5)", hint: `${HINT}: "100 ÷ 25" was the whole step`, explain: SHOW, checks: `${SLIPS}: "Subtracted"` },
  "g6-ratio": { hint: `${HINT}: "Multiply 7 by the same 8" named the factor that is the previous step's answer`, explain: SHOW, checks: SLIPS },
  "g7-addint": { pre: "g6-numline: steps on each side of 0 (Order 6)", checks: `${SLIPS}: "Subtracted the sizes", "Added the sizes"` },
  "g7-circarea": { pre: "g7-circum: the same circle, its distance around first (Order 6)", checks: "Part A6's \"Used the circumference\" and \"Squared the diameter\" slips" },
  "g7-discount": { pre: "g6-pctof (Order 6)", hint: `${HINT}: "10% of $120 is $12" was the answer when the percent was 10`, explain: SHOW, checks: `${SLIPS}: "Multiplied by the percent", "Found the new price"` },
  "g7-distribute": { pre: "g6-gcf: factoring out is distributing backwards (Order 6)", hint: `${HINT}: "Multiply 8 by x and by 8" and "8x and the number 64" said the boxes`, explain: SHOW, checks: `${SLIPS}: "Multiplied the x terms", "Lost the multiplied number", "Left out the other x terms"` },
  "g7-mulint": { pre: "g7-addint (Order 6)", checks: `${SLIPS}: "Added" or "Multiplied" on the sizes` },
  "g7-pctchange": { pre: "g7-discount (Order 6)", hint: `${HINT}: "Move the decimal point two places right" is a rule; the hint now says percent means hundredths`, explain: SHOW, checks: `${SLIPS}: "Added", "Kept the decimal", "Moved the point one place"` },
  "g7-prob": { hint: `${HINT}: "blue out of all: 7 over 12, simplified" was the answer`, explain: SHOW, checks: `${SLIPS}: "Counted every marble", "Left out the blue ones"` },
  "g7-scale": { pre: "g7-prop: a scale is a proportion (Order 6)", hint: `${HINT}: "How many groups of 1 cm are in 2 cm?" said the answer`, explain: SHOW, checks: `${SLIPS}: "Multiplied"` },
};
