# Obento² Swift app: how we work here

You're working with G, who owns Obento², a maths app for kids (K-12) that shows a child why the maths works, then practises it with them every day. Talk in plain words; G isn't a programmer. Always write the name as "Obento²", never "Bento 2".

## The app
- `Obento2.swiftpm` is the app. G runs it in Swift Playgrounds on the Mac (no Xcode). After a change, tell G to press Play. If Playgrounds doesn't refresh, close and reopen the project.
- `App/` holds the screens. The whole paper is one RealityKit scene seen through one camera (`PaperScene.swift`): grid, lesson pictures and 3D lessons alike; flat is that camera straight above. Words and controls are SwiftUI on top, pinned to the paper. `Core/` holds the lesson logic and camera maths, with no drawing in it.
- Xcode is installed (`/Applications/Xcode.app`) but not selected, so prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Build and screenshot locally on the iPad simulator (`xcodegen`, then `xcodebuild` and `simctl launch … -shot <name>`) before pushing; it's much faster than waiting for GitHub.
- Test Core with `cd Packages/ObentoCore && swift test` (it links to `Obento2.swiftpm/Core`). Every lesson's maths gets tests.
- The look comes from the web prototype (the "paper canvas", v27): `reference/paper-canvas.html`. Open it in a browser and match it or beat it. The Unit cubes 3D lesson is what sold the idea.
- How every lesson is taught, drawn and animated: `LESSONS.md`. Read it before building or changing any lesson, and follow it.
- Branch `claude/project-thread-15w6ys`. `git pull` before each change and push after it; other sessions push here too. A push makes GitHub build it and save iPad screenshots in `shots/`.

- **All the lessons:** `specs/k12/` (191 K-12 lessons) and `specs/obento2/` (154 Obento² lessons) are the Curriculum specs. The live web app's lesson code (generators, answer checks) is in `web/src/curriculum/` on `main`: read it, port its maths with the same answers, and never change the web app.

## G's rules (firm)
- **The paper is the app.** Everything is drawn on the grid and uses its cells: 20 pt cells, a strong line every 5. One cube = one big square. Nothing goes off-grid, and the grid never changes or fades when a lesson opens.
- **No iOS look.** No big bright or dark buttons, no side panel, no pop-ups. Controls are cell blocks drawn on the paper. Colour lives only in the maths; red and green mean only wrong and right.
- **Never remove an animation** (G, 17 Oct): the draw-ins, the glide, the cubes rising, the bars filling, the point hopping, and every web lesson's animated picture when it's ported. A ported lesson isn't done until its picture moves step by step as the web's does.
- **Motion has a purpose.** Pieces draw themselves in. Tapping a lesson is a gentle glide (1.1 s, about 1.3x closer, never too close). No looping animations. Never remove drawing or zoom; G counts that as a step back.
- **3D lessons** open flat, lined up with the paper exactly. They tilt only when the maths rises off the paper, words stay pinned to the paper facing the child, and the view goes flat again before leaving.
- **Every problem is fresh** (from a generator), and the answer is worked out from the same numbers as the picture.
- **Icons are Phosphor**, used as drawn (they're in `Assets.xcassets`). Font: SF Pro Rounded for now (`Typeface` in `Theme.swift`).
- **G approves first.** Show G (a screenshot, or "press Play") before calling anything done. Change only what G asked for. Every change must be better than what came before.
- Bible references, if any ever come up, use the NWT and jw.org / wol.jw.org.

## What's next
- Milestone 2 (Paper proof: grid, camera, Unit cubes in 3D, Add with different bottoms flat) was approved by G on 17 Oct 2026.
- Milestone 3: every lesson is data (`Core/LessonEngine.swift`). A `LessonSpec` generates fresh numbers and works out its steps from them: words, the marking task with its checks and mistake messages, the camera, and what the picture shows. `LessonRun` plays any spec; `Lessons.all` is the catalog the map opens from, and the spec's `master` ("cubes", "bars") picks the picture master that draws it. Adding a lesson = a spec in Core with tests, a map piece, and a master if no existing one fits.
- `reference/` holds the newest approved prototype (`paper-canvas.html`, v27) and pictures; pull and read `reference/CHANGES.md` before building, and build only what G has said to build. `specs/` holds the Curriculum team's lesson specs (K-12 and the Obento² tracks).
- G decided on 17 Oct 2026: 5th grade is the 17 lessons in `specs/k12/grade5.md` (not v27's own lesson list), laid out on the map the way v27 lays out chapters; and the top bar matches v27's rounded pills (grade pill top left, lesson name centred, zoom / find / dark / profile on the right). Keep the map's "Up next" tab exactly as it is: a square tab in the chapter's colour on the frame's top-right corner (G, 17 Oct).
- Next: milestone 4, the 5th grade template (all 17 lessons, the paper map, the design system in code). Milestone 6 (launch) needs G's Apple Developer account, the font licence and G's typed go.
