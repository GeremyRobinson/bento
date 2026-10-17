# `pre` vs depends-on: where they differ, and one source of truth

Curriculum, 2026-10-13. Read on `origin/next` 1220c68 and Design's branch `claude/ui-notes-update-adtpis`. Nothing in the code was changed.

## Where they differ

The catalog's `pre` was compared with the first id of each lesson's depends-on list (`web/src/curriculum/v2/grade*.ts`) for all 191 lessons.
- All 191 lessons have a list.
- No lesson depends on a lesson that comes later in the order.
- Only 8 lessons differ, and all are in 5th grade. Every other grade's `pre` already matches the first id of its list.

| Lesson | Catalog `pre` | Depends on (v2) | Note |
|---|---|---|---|
| g5-order Order of operations | g5-mult2 | g3-facts, g3-divfacts | `pre` replaced |
| g5-round Rounding decimals | g4-dec | g4-placevalue, g4-dec | `pre` is in the list, just not first |
| g5-multdec Multiplying decimals | g5-mult2 | g4-partial, g4-dec | `pre` replaced |
| g5-divdec Dividing by a decimal | g5-divide | g5-pow10, g3-divfacts | `pre` replaced |
| add Adding fractions | g4-fraccompare | g4-equiv, g4-likefrac, g4-factors | `pre` replaced |
| sub Subtracting fractions | g4-likefrac | add | `pre` replaced |
| g5-fracof Fraction of a number | g4-fracwhole | g3-divfacts, g4-fracwhole | `pre` is in the list, just not first |
| g5-unitdiv Dividing by a unit fraction | g5-fracof | g3-unitfrac, g3-facts | `pre` replaced |

My grade5.md said "the rest keep their `pre` as the first id". For g5-round and g5-fracof the list puts another lesson first, so that sentence was wrong for those two. The list is what's meant.

## Who reads `pre` today

- **Today's order does not use `pre`.** `upNext` (`app/today.ts:31`) walks the catalog in order and takes the first lesson not yet learned that is `ready`. `ready` and `stepBack` (`engine/mastery/skills.ts:65-92`) read the depends lists.
  - So Order of operations still comes after Multiply two-digit numbers and Long division, because that is the catalog order.
  - The depends lists only decide whether a lesson is ready, and where to step back to.
- **Step-back and "Build up first":** on `next`, `buildUpFor` (`app/curriculum.ts:41`) checks the depends list first. The `pre` fallbacks there, in `dependsOn` (`skills.ts:67`) and in `backFor` (`practice.ts:590`), never run now, because every lesson has a list.
- **Design's Today panel is the one real reader.** On Design's branch, `Home.tsx:84` does `entriesInGrade(g).find(c => c.pre === id)` and says "Order of operations needs it, so it comes first" on Multiply two-digit numbers.
  - With the depends lists that sentence isn't true: Order of operations needs one-digit facts, not two-digit multiplying.
  - This is where the two sources show different things.
- **Design's branch also has the older `buildUpFor`** (`app/curriculum.ts:40`), which does not check the depends list. When it merges, keep `next`'s version.
- **Tests:** `held-8-12.test.ts:47` and the parity deviation files check each lesson module's own `pre` against the catalog.

## Recommendation: the depends lists are the one source of truth

The depends lists are the reviewed answer to "what does this lesson build on". `pre` is a leftover from the old app's single link.

1. **Make `pre` follow the list.** Set catalog `pre` (and each lesson module's `pre`) to the first id of its depends list for the 8 lessons above. Then add one test: for every lesson, `pre === DEPENDS[id][0]` (or null when the list is empty). That way the two can never drift again. Later `pre` can be removed, or derived from DEPENDS, once the parity tests no longer pin it.
2. **Order comes from the catalog, not from `pre`.** Today keeps walking the catalog order, as it does now. The lesson sequence the model shows doesn't change, because it never depended on `pre`.
3. **Fix the "needs it" line on Design's Today panel.** Use the depends lists: find a lesson in this grade whose list includes `id`. With the lists, in 5th grade:
   - Multiply by 10, 100, 1000 is needed by Dividing by a decimal.
   - Adding fractions is needed by Subtracting fractions and by Adding and subtracting.
   - Subtracting fractions is needed by Adding and subtracting.
   - Fraction of a number is needed by Multiplying fractions.
   - Multiply two-digit numbers shows no "needs it" line, which is true: no 5th grade lesson builds on it directly.
