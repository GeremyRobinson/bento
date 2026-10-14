/**
 * The master registry: every reusable piece the app is built from (design-philosophy.md, "Never build a one-off").
 * Only a master's own rules may set a corner, a gap, a fill or a button look; everything else takes them from a master
 * or the tokens (tests/styles/masters.test.ts checks this). G 2026-10-08: "it can always just make a new component that
 * can be reused and things that arent getting used can be removed".
 *
 * To add a master: give it a name, the component that renders it (if any), and its classes, root class first. Its
 * rules may then use only those classes (and the shared states below). A master nothing uses shows up in the
 * masters test's "unused" list, ready to delete.
 */
export interface Master {
  name: string;
  /** the component that renders it, from src/ (none for a CSS-only master) */
  component?: string;
  /** its classes, root first; the root is how the app is searched for uses */
  classes: string[];
}

export const MASTERS: Master[] = [
  { name: "Panel", classes: ["panel"] },
  { name: "Row", classes: ["srow", "sname", "sles", "chap", "sdot", "slist", "smeta", "chev", "badge", "tick", "stepbar", "still"] },
  { name: "Accordion", component: "components/screen/ListGroup.tsx", classes: ["sgroup", "sgroup-body", "sgroup-in", "sgroup-panel"] },
  { name: "Pill", component: "components/primitives/Pill.tsx", classes: ["ctl", "circ", "badged", "sm"] },
  { name: "Picture", component: "components/diagrams/Diagram.tsx", classes: ["viz", "viz-svg", "am", "rs"] },
  { name: "Tile", component: "components/PageTile.tsx", classes: ["tile", "mtile", "mt-text", "mtoggle", "k"] },
  { name: "BentoGrid", component: "components/BentoGrid.tsx", classes: ["bgrid", "bg-in", "bg-t", "n", "s", "t", "w", "l", "f"] },
  { name: "Screen", component: "components/screen/Screen.tsx", classes: ["screen", "split", "sdetail", "whead", "wbody", "wkick", "wpad", "wprob", "col", "more"] },
  { name: "Keypad", component: "components/practice/Keypad.tsx", classes: ["ppad", "tray", "k-go", "nosign", "ptap", "tappad", "tapnote", "choices", "choice", "phead", "pask", "pmath", "pfb"] },
  { name: "Slider", component: "components/primitives/Slider.tsx", classes: ["slider", "slider-thumb"] },
  { name: "Confirm", component: "components/Confirm.tsx", classes: ["confirm", "confirm-body", "cq", "ca", "keep", "fdim"] },
  { name: "FeatureTile", component: "components/FeatureTile.tsx", classes: ["ltile", "ldemo", "ltext", "lvis"] },
  { name: "Step row", classes: ["beat", "beats", "say", "pline", "badge"] },
  // the zoom-out: the contents, My Obento and a lesson's or test's problems, each a card on the same stage (G 2026-10-08)
  { name: "Zoom", component: "components/Contents.tsx", classes: ["zcard", "zoom", "zstage", "zbar-top", "zrooms", "zcount", "zplist", "zpgrid", "zprob", "zphead", "zpline", "zprobs", "zme", "zlevel", "zl-text", "zchap", "zgrown", "zgrade", "zfind", "battery", "badge", "ans"] },
  // "Problem x of n" with its dots: the button that zooms out to every problem
  { name: "Problem button", classes: ["pzoom", "pwhere", "pdots", "sname", "ok"] },
  // a lesson in a list: its mark, its name, its minutes
  // the grade's Contents: big pills grouped like the practice panel's Problem section (G 2026-10-08, Ring balance lab)
  { name: "Big pill list", classes: ["schapters", "big", "stag", "scheck", "contents", "screen", "slist", "shead", "srow", "chap", "sgroup", "sgroup-body", "sgroup-in", "sgroup-panel"] },
  { name: "Lesson item", classes: ["pitem", "pmark"] },
  // the nav's round buttons: back, settings, me, hint
  { name: "Nav circle", classes: ["icon", "ihint", "spent"] },
  // v2 (G 2026-10-13, model artifact): one workspace, the box of Cover tiles, the solve panel. Rules in styles/v2.css.
  { name: "Cover", component: "components/Cover.tsx", classes: ["v-cover", "v-top", "v-tx", "v-nm", "v-prog", "v-st", "v-pic", "v-picbox", "v-pq", "v-ring", "pick", "still", "next", "rev"] },
  { name: "Ring", classes: ["v-ring", "sm", "md", "lg", "t", "f"] },
  { name: "Stat", classes: ["v-stat", "v-nm", "v-st", "v-ring", "still"] },
  { name: "Card panel", classes: ["v-panel", "v-label", "v-meta", "v-why", "v-row", "v-seg", "v-lbtns", "v-go", "v-plain"] },
  { name: "Go button", classes: ["v-go"] },
  { name: "Plain button", classes: ["v-plain"] },
  { name: "Tool", classes: ["v-tool", "v-tools"] },
  { name: "Workspace", classes: ["screen", "v-work", "v-home", "v-prac", "v-done", "v-today", "v-todaypic", "v-box", "v-bh", "v-sw", "v-wide", "v-yr", "v-path", "v-pstep", "v-gbig", "v-sc", "v-result", "v-recap", "v-rp", "v-stage", "v-prob", "v-ppic", "v-pad", "v-plist", "v-lside", "v-idea", "v-wl", "v-learn", "later", "all", "pprob", "pfade"] },
  { name: "Solve panel", classes: ["v-solve", "v-keys", "v-solved", "v-ans", "q2", "v-steps", "v-lines", "v-ask", "v-say", "slip", "good", "hint", "slot", "empty", "no", "ask", "tray", "ctl", "choice", "choices", "ok"] },
  { name: "Grade ring", classes: ["ibat", "igrade", "island", "pring-track"] },
  // the UI model (Design, v57, 2026-10-14): the shell and its masters, styles/ui.css. Class names are the model's with "o-" in front
  { name: "App", classes: ["o-app", "flow", "fit", "stage"] },
  { name: "Island", component: "components/AppNav.tsx", classes: ["o-nav", "o-island", "o-place", "o-tool", "fit1", "fit2", "kfit"] },
  { name: "O panel", classes: ["o-panel", "o-in", "o-label", "o-small", "o-why", "o-head", "o-title", "o-row"] },
  { name: "O button", classes: ["o-btn", "fill", "link"] },
  { name: "O tool", classes: ["o-tool", "o-badge", "sel"] },
  { name: "O ring", component: "components/Masters.tsx", classes: ["o-ring", "m", "l", "t", "f"] },
  { name: "O marks", classes: ["o-marks"] },
  { name: "O slider", classes: ["o-sw", "thumb"] },
  { name: "O tile", classes: ["o-tile", "o-tx", "o-nm", "o-cover", "o-cpw", "o-stat", "o-wide", "o-foot", "o-st", "next", "rev", "o-prow", "o-ptrack", "o-ring", "o-marks", "sel", "o-gt", "o-gnum", "o-grades"] },
  { name: "O picture", classes: ["o-art"] },
  { name: "O motion", classes: ["o-arrive", "o-grid", "zin", "zout", "o-sw", "thumb", "o-btn", "o-tool", "o-tile"] },
  { name: "O screens", classes: ["o-state", "home", "o-today", "o-art", "o-box", "o-bh", "o-head", "o-sw", "o-grid", "o-grades", "o-tile", "o-prow", "o-marks", "o-app", "o-nav"] },
];

/** states any master may be in: they never make a rule a one-off */
export const STATES = ["on", "open", "opening", "go", "done", "soon", "now", "solved", "shown", "flash", "enter", "fit", "none", "dim", "hidden", "active"];
