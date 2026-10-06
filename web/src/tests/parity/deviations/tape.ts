/** Intentional differences in the tape-diagram and fraction lessons, each with its reason. */
export const deviations: Record<string, Partial<Record<string, string>>> = {
  // Review v40 little things 4 (2026-10-06): hints use the live numbers, and pieces are named ("thirds", not "3ths")
  "g4-likefrac": { hint: "the tops hint names the pieces (\"Count the pieces: 2 fifths and 1 fifth.\"), and the bottom hint says \"fifths\", not \"5ths\"",
    explain: "the tops step's explanation starts from its hint", checks: "the added-the-bottoms slip says \"fifths\", not \"5ths\"; a wrong try's message repeats the step's hint" },
  "g5-improper": { hint: "\"Add the 1 extra piece\", not \"the 1 extra pieces\"", explain: "the extra step's explanation starts from its hint", checks: "a wrong try's message repeats the step's hint" },
  // Copy team rewrites-01 (2026-10-03): Bento speaks to "you", never "we"; same meaning, same checks and answers
  add: { checks: "slip messages reworded by the Copy team (\"You added b + d…\"; no \"Not quite.\" under the bold lead)" },
  sub: { checks: "slip messages reworded by the Copy team (\"You subtracted…\"; no \"Not quite.\" under the bold lead)" },
  mix: { checks: "slip messages reworded by the Copy team (\"You added…\"; no \"Not quite.\" under the bold lead)" },
  "g4-equiv": { prompt: "\"What did we multiply by?\" is now \"What was it multiplied by?\" (Copy team: no teacher \"we\")" },
  "g5-units": {
    story: "The current app told every conversion as a rope's length (\"A rope is 8 kilograms long\"). The story now fits what the unit measures: a rope for feet, yards and meters, a bag of flour for kilograms and pounds, a road trip for hours, a fish tank for gallons. Same numbers, same operation (×).",
  },
};
