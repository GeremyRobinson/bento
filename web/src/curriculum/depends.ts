// What each lesson builds on, from Curriculum (v2-backend-plan.md, "From Curriculum"). A lesson listed here uses this
// list (it may name lessons from earlier grades; an empty list means it starts fresh); the first id is the main
// build-up. A lesson not listed falls back to the one build-up lesson the catalog names (`pre`). The skill model reads
// it to step back after a low check. 5th grade: curriculum/specs/v2/grade5.md, signed off by Review 2026-10-13.
export const DEPENDS: Record<string, string[]> = {
  "g5-mult2": ["g4-mult2x2", "g3-mult10"],
  "g5-divide": ["g4-divide", "g3-mult10"],
  "g5-order": ["g3-facts", "g3-divfacts"],
  "g5-pow10": ["g4-dec", "g4-placevalue"],
  "g5-round": ["g4-placevalue", "g4-dec"],
  "g5-adddec": ["g4-dec", "g4-addsub"],
  "g5-multdec": ["g4-partial", "g4-dec"],
  "g5-divdec": ["g5-pow10", "g3-divfacts"],
  "g5-improper": ["g4-mixed"],
  add: ["g4-equiv", "g4-likefrac", "g4-factors"],
  sub: ["add"],
  mix: ["add", "sub"],
  "g5-fracof": ["g3-divfacts", "g4-fracwhole"],
  "g5-multfrac": ["g5-fracof", "g4-equiv"],
  "g5-unitdiv": ["g3-unitfrac", "g3-facts"],
  "g5-volume": ["g4-area", "g4-partial"],
  "g5-units": ["g4-convert", "g4-partial"],
};
