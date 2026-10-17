# Bento² lesson specs · format and rules

The Curriculum team started this on 2026-10-06, after G said "Bento2 you can begin lessons". Review checks these specs, and Review's approval counts as G's. Development builds from them.

Sources:
- the Bento² plan, a Claude Doc at https://claude.ai/code/artifact/01d3d8d5-3b72-4df2-947d-e428bbff5f22;
- the Research team's toolbox at `math-app/bento2/research/toolbox.md`.

The 10 tracks were approved by G on 2026-10-06.

## Track order

The spine comes first, then the capstone, then the branches.

| # | File | Track | Role | Needs | Lessons |
|---|---|---|---|---|---|
| 1 | `linear-algebra.md` | Linear algebra | Spine | 12th grade | about 20 |
| 2 | `probability.md` | Probability and statistics | Spine | 12th grade (AP Stats helps) | about 20 |
| 3 | `multivariable.md` | Multivariable calculus and optimization | Spine | AP Calculus | about 20 |
| 4 | `information.md` | Information and entropy | Spine | Probability | about 12 |
| 5 | `computation.md` | Logic, algorithms and computation | Spine | 12th grade | about 15 |
| 6 | `ai.md` | The math behind AI | Capstone | all five spine tracks | about 15 |
| 7 | `diffeq.md` | Differential equations | Branch | Multivariable | about 15 |
| 8 | `orbits.md` | Orbits and spaceflight | Branch | Differential equations | about 12 |
| 9 | `relativity.md` | Relativity | Branch | Linear algebra | about 12 |
| 10 | `quantum.md` | Quantum and quantum computing | Branch | Linear algebra, probability, computation | about 12 |

## What is different from regular Bento

These rules come from the plan, which G approved on 2026-10-03:
- **No grades, scores, tests, check-ups or 0-4 levels on screen.** Progress shows as abilities ("You can turn a picture into a matrix") and as how much of the track's build is done. Bento still tracks mastery quietly, so steps can shrink and old ideas can come back for a refresh.
- **Every lesson is one loop:** Play, Guess, Name it, Work it, Use it.
- **Every track ends in a build** that is assembled piece by piece. Every 3 to 5 lessons, there is a small project: a one-screen thing the learner makes and keeps.
- **The learner chooses** (G, 2026-10-05). Lessons can be taken in any order. "Needs" only lights the map and suggests a refresher; it never locks anything. Each lesson has a **Deeper** layer the learner can open for more rigor or a harder idea. The plain path never requires it. A track may also end with one whole Deeper lesson (for example de-15, chaos): it sits off the build's path on the map and is never needed to finish the build.
- **Everything is live.** Every picture is drawn from numbers the learner can drag. There are no still images of ideas.
- **No taglines.** "Super intelligence" is the internal focus only (G, 2026-10-06), so it never appears in lesson text.
- **Voice.** Direct and grown-up, speaking to the learner, not like a teacher. US English, sentence case, no em-dashes. Use the `count()` and `aOrAn()` helpers, never print a coefficient of 1, and never print "+ −".

## The always-there tools

Every lesson can use these: scientific calculator, Grapher 2D, Grapher 3D, Matrix pad, Number shelf, Units and constants, Scratch paper, and Notebook. A lesson names the tool it opens. Values the learner makes go on the Number shelf under the name the spec gives, so later lessons and the build can reuse them.

## Lesson block format

```
### <id> · <title>
- **You can:** the ability line shown when the lesson is done.
- **Needs:** lesson ids (soft; used for the map and for refreshers).
- **Tool:** the toolbox tool(s) this lesson opens, ★ for the track's main tool.
- **Play:** the live picture, what the learner drags, and what changes. One or two sentences.
- **Guess:** the prediction question, drawn from the live numbers, and how the reveal shows the answer. Bento records whether the guess was right, but never shows that as a score.
- **Name it:** the idea in 1 to 3 learner-facing sentences, then the formula.
- **Work it:** the problem generator with ranges, then the steps (label, what is typed or tapped) and slips with their messages. Early problems (index < 3) use small, friendly numbers.
- **Oracle:** a one-line independent check of the answer, for the test.
- **Use it:** the small real task, and what it adds to the build or project (with a Number shelf name if it saves something).
- **Deeper:** the optional layer: a proof sketch, a generalization or a harder case.
```

**Ids:** `b2-<track>-<nn>`, where track is `la`, `pr`, `mv`, `in`, `cs`, `ai`, `de`, `or`, `re` or `qu`.

Every track file opens with the track's build, its units, its small projects, and a list of new tools or pictures that Development has to make.
