# Obento² Swift app: how we work here

You're working with G, who owns Obento², a maths app for kids (K-12) that shows a child why the maths works, then practises it with them every day. Talk in plain words; G isn't a programmer. Always write the name as "Obento²", never "Bento 2".

## The app
- `Obento2.swiftpm` is the app. G runs it in Swift Playgrounds on the Mac (no Xcode). After a change, tell G to press Play. If Playgrounds doesn't refresh, close and reopen the project.
- `App/` holds the screens. The whole paper is one RealityKit scene seen through one camera (`PaperScene.swift`): grid, lesson pictures and 3D lessons alike; flat is that camera straight above. Words and controls are SwiftUI on top, pinned to the paper. `Core/` holds the lesson logic and camera maths, with no drawing in it.
- Xcode is installed (`/Applications/Xcode.app`) but not selected, so prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Build and screenshot locally on the iPad simulator (`xcodegen`, then `xcodebuild` and `simctl launch … -shot <name>`) before pushing; it's much faster than waiting for GitHub.
- Test Core with `cd Packages/ObentoCore && swift test` (it links to `Obento2.swiftpm/Core`). Every lesson's maths gets tests.
- The look comes from the web prototype (the "paper canvas", v27). The Unit cubes 3D lesson is what sold the idea.
- Branch `claude/project-thread-15w6ys`. `git pull` before each change and push after it; other sessions push here too. A push makes GitHub build it and save iPad screenshots in `shots/`.

## G's rules (firm)
- **The paper is the app.** Everything is drawn on the grid and uses its cells: 20 pt cells, a strong line every 5. One cube = one big square. Nothing goes off-grid, and the grid never changes or fades when a lesson opens.
- **No iOS look.** No big bright or dark buttons, no side panel, no pop-ups. Controls are cell blocks drawn on the paper. Colour lives only in the maths; red and green mean only wrong and right.
- **Motion has a purpose.** Pieces draw themselves in. Tapping a lesson is a gentle glide (1.1 s, about 1.3x closer, never too close). No looping animations. Never remove drawing or zoom; G counts that as a step back.
- **3D lessons** open flat, lined up with the paper exactly. They tilt only when the maths rises off the paper, words stay pinned to the paper facing the child, and the view goes flat again before leaving.
- **Every problem is fresh** (from a generator), and the answer is worked out from the same numbers as the picture.
- **Icons are Phosphor**, used as drawn (they're in `Assets.xcassets`). Font: SF Pro Rounded for now (`Typeface` in `Theme.swift`).
- **G approves first.** Show G (a screenshot, or "press Play") before calling anything done. Change only what G asked for. Every change must be better than what came before.
- Bible references, if any ever come up, use the NWT and jw.org / wol.jw.org.

## What's next
This is the "Paper proof": the grid, pan and zoom, the glide, and Unit cubes in 3D. Once G is happy with it, the plan's next milestones are the lesson model as data, then the picture masters.
