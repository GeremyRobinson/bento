# The new UI: the paper-canvas prototype

`paper-canvas.html` is the web mockup G approved as the direction for Obento² (version 27, 2026-10-17). Open it in a browser:
- The grades K-5 open the kids' paper.
- `?v=uc` opens the 3D Unit cubes lesson straight away.

It's the reference for how everything should look and move. The Swift app should match it or beat it, never fall short of it.

The font file (ABC Areal) is deliberately not here, because its licence doesn't allow it on a public server, so the page falls back to the system font. The Swift app uses SF Pro Rounded until G buys the licence.

The PNGs are the 3D lesson's steps: flat on the paper → cover the floor → tilt → layers → phone → back to flat.

## How updates arrive
Every new preview from the Obento² Lead lands here: `paper-canvas.html` is replaced with the newest version, and a line is added to `CHANGES.md` saying what's new and which version G approved. G's web link always shows the same newest version. Pull, read `CHANGES.md`, and build only what G has said to build.
