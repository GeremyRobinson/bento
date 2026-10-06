/** Intentional differences in the tape-diagram and fraction lessons, each with its reason. */
export const deviations: Record<string, Partial<Record<string, string>>> = {
  // Review v40 little things 4 (2026-10-06): hints use the live numbers, and pieces are named ("thirds", not "3ths")
  "g4-likefrac": { hint: "the tops hint names the pieces (\"Count the pieces: 2 fifths and 1 fifth.\"), and the bottom hint says \"fifths\", not \"5ths\"",
    explain: "the tops step's explanation starts from its hint", checks: "the added-the-bottoms slip says \"fifths\", not \"5ths\"; a wrong try's message repeats the step's hint",
    story: "when a + c is more than one whole, Ana's share comes from \"another pizza the same size\": one pizza can't hold 4/5 + 2/5 (Curriculum fixes-02, read-this-first item 1, 2026-10-06)",
    // Curriculum fixes-02 Part C, 2026-10-06: the bottom hint no longer says the bottom ("What size are the pieces?"), its Show me says why; a new "Multiplied the tops" slip
  },
  "g5-improper": { hint: "\"Add the 1 extra piece\", not \"the 1 extra pieces\"; (Curriculum fixes-02 Part C, 2026-10-06) the wholes hint asks how many pieces are in one whole, and the fraction hint no longer states the answer",
    explain: "the extra step's explanation starts from its hint; the fraction step's Show me names the pieces and the answer", checks: "a wrong try's message repeats the step's hint; new \"Added the whole number\" slip (Curriculum fixes-02 Part C, 2026-10-06)", pre: "g4-mixed: counting wholes as pieces is the mixed-number skill it builds on (Curriculum fixes-02 Part C, 2026-10-06, Order 3)" },
  // Copy team rewrites-01 (2026-10-03): Bento speaks to "you", never "we"; same meaning, same checks and answers
  add: { checks: "slip messages reworded by the Copy team (\"You added b + d…\"; no \"Not quite.\" under the bold lead)",
    hint: "the LCD hint no longer lists the multiples (it often listed the answer), and the add hint no longer says the bottom (Curriculum fixes-02 Part C, 2026-10-06: hints don't give the answer)",
    pre: "g4-fraccompare: its \"A bottom for both\" step is this lesson's first step (Curriculum fixes-02 Part C, 2026-10-06, Order 3)" },
  sub: { checks: "slip messages reworded by the Copy team (\"You subtracted…\"; no \"Not quite.\" under the bold lead)",
    hint: "the LCD hint no longer lists the multiples, and the subtract hint no longer says the bottom (Curriculum fixes-02 Part C, 2026-10-06: hints don't give the answer)" },
  mix: { checks: "slip messages reworded by the Copy team (\"You added…\"; no \"Not quite.\" under the bold lead)",
    hint: "the LCD hint no longer lists the multiples, and the add and subtract hints no longer say the bottom (Curriculum fixes-02 Part C, 2026-10-06: hints don't give the answer)" },
  "g4-equiv": { prompt: "\"What did we multiply by?\" is now \"What was it multiplied by?\" (Copy team: no teacher \"we\")",
    hint: "the top hint is \"Whatever the bottom was multiplied by, multiply the top by the same number.\": \"× 5\" gave the answer when the top was 1 (Curriculum fixes-02 Part C, 2026-10-06)",
    explain: "Show me starts from the new hint", checks: "a wrong try's message repeats the new hint" },
  "g5-units": {
    story: "The current app told every conversion as a rope's length (\"A rope is 8 kilograms long\"). The story now fits what the unit measures: a rope for feet, yards and meters, a bag of flour for kilograms and pounds, a road trip for hours, a fish tank for gallons. Same numbers, same operation (×).",
  },
};
