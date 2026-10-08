# Bento design: Layered Glass Bento

**Easy to use, easy to understand, good-looking where it counts. Function makes the design.**

The style is **Layered Glass Bento** (G 2026-10-07): bento tiles on a grid, and inside them layers of tinted glass, each one step deeper. Bento is one thing. Every page is built from the same few pieces, and they look and behave the same everywhere.
The model for all of it is the **lesson overview panel** (Contents): if a page doesn't look like it belongs next to
that panel, it isn't finished.

## The pieces

There are five pieces. Everything on every page is one of them, or several of them nested.

| Piece | What it is | Master |
|---|---|---|
| **Panel** | A box that holds things. | `--pane-plain`, `--r-panel` |
| **Row** | One line you read or tap: a lesson, a step, a setting. | `.srow` |
| **Accordion** | A row that opens to show more rows. | `ListGroup` |
| **Pill** | A button. | `Pill` |
| **Picture** | The math, drawn. | `Diagram` |

New UI is built by putting these pieces together. When a piece can't do something, change its master so every page gets it. Never build a one-off.

## Three rules

**1. One gap.** Things inside a panel sit `--nest` (8px) apart, and the same 8px in from its edge.

**2. Corners nest from the inside out.** The smallest shape keeps its full round. Each shape around it is that round plus 8px.
- A 44px row has a 22px corner.
- The panel around it is 30px.
- The panel around that is 38px.
Every corner then follows the one inside it.
- Every main panel on every page, at every size, has that same corner: 46px (`--r-panel`), the Contents list's own.
- Main panels sit 16px (`--screen-gap`) apart, the same as their distance from the screen edge.

**3. The glass ladder.** Each layer is one step deeper in the grade's own colour (`--g1` to `--g4`). Going in means going deeper, and hovering lifts one step. The row you're on is one step deeper than its neighbours. There are no shadows; outlines and fills only.

## Colour

- **The app's look:** one colour, the grade's own hue, on the ladder.
- **Pictures:** their own colours, never used for the app's look.
- **Answers:** green means right. Anything else is calm, never red alarm.
- A grade is shown as its number in its colour.

## Type

- Inter in three weights: 400 to read, 550 for labels, 650 for titles.
- Sentence case everywhere.

## Motion

- **One speed for everything:** the motion tokens (`--m-*`).
- **One page change:** a cross-fade.
- **Accordions:** open and fold with the `ListGroup` motion.
- **Closing:** faster than opening.
- **Pictures:** show the math. Pieces appear where they belong (in a stack or a grid) and never fly in from the side.
- Every animation ends on a still. Less motion is a 200ms fade.

## Layout

- Lessons never scroll the page. The picture is the hero and gets the room that's left.
- A picture turns to fit its tile, except a story's picture, which keeps the story's rows.
- One layout per page at every size; a phone stacks what a wide screen puts side by side.

## Before calling something done

1. Does it use only the five pieces?
2. Do the gaps, corners and ladder match the lesson overview panel?
3. Would a six-year-old know what to do, and would a grown-up want to try it?
