// Probability's 20 lessons, b2-pr-01 to b2-pr-20, in order (units 1 and 2 in lessons1.ts, units 3 to 5 in lessons2.ts).
import type { AnyB2Lesson } from "../../model";
import { UNIT12 } from "./lessons1";
import { UNIT345 } from "./lessons2";

export * from "./lessons1";
export * from "./lessons2";
export const PR_LESSONS: AnyB2Lesson[] = [...UNIT12, ...UNIT345];
