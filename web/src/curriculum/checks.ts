// Every lesson's own skill check, gathered from the grades' v2 files (v2/grade<N>.ts; how a recipe reads is in
// check-kit.ts). A lesson with no recipe gets the engine's default check (engine/session/practice.ts checkItems).
import type { CheckRecipe } from "./check-kit";
import * as g0 from "./v2/grade0";
import * as g1 from "./v2/grade1";
import * as g2 from "./v2/grade2";
import * as g3 from "./v2/grade3";
import * as g4 from "./v2/grade4";
import * as g5 from "./v2/grade5";

export { WHERE_TRIES, type CheckItem, type CheckRecipe } from "./check-kit";

export const GRADES_V2 = [g0, g1, g2, g3, g4, g5];
export const CHECKS: Record<string, CheckRecipe> = Object.assign({}, ...GRADES_V2.map(g => g.checks));
