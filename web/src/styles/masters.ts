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
  // the nav's round buttons: back, settings, me, hint
  { name: "Nav circle", classes: ["icon", "ihint", "spent"] },
  // v2 (G 2026-10-13, model artifact): one workspace, the box of Cover tiles, the solve panel. Rules in styles/v2.css.
  { name: "Workspace", classes: ["v-prac", "v-done", "v-result", "v-recap", "v-rp", "v-ptile", "v-stage", "v-prob", "v-ppic", "v-pad", "v-plist", "v-lside", "v-idea", "v-wl", "v-learn", "later", "all", "pprob", "pfade", "v-lbtns"] },
  { name: "Solve panel", classes: ["v-solve", "v-keys", "v-solved", "v-ans", "q2", "q", "note", "n", "v-meta", "v-q", "v-kp", "v-tools", "v-steps", "v-lines", "v-ask", "v-say", "slip", "good", "hint", "slot", "empty", "no", "ask", "tray", "ctl", "choice", "choices", "ok", "given", "active", "shown", "ppad", "k-go", "solved", "mline", "mk"] },
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
  { name: "O tile", classes: ["o-tile", "o-tx", "o-nm", "o-cover", "o-cpw", "o-stat", "o-wide", "o-foot", "o-st", "next", "rev", "o-ring", "o-marks", "sel", "o-gt", "o-gnum", "o-grades"] },
  { name: "O picture", classes: ["o-art"] },
  { name: "O settings", classes: ["settings", "o-setrows", "o-setrow", "o-tsize", "o-snote"] },
  // v66 (G 2026-10-14, Settings layout C): the list of groups, the picked one outlined like a picked tile
  { name: "O group list", classes: ["o-gli", "o-glist"] },
  // v66: one switch for every on/off (Review settings-c: off 3:1 or more on the card, role=switch)
  { name: "O switch", component: "components/Masters.tsx", classes: ["o-tg"] },
  { name: "O report", classes: ["report", "open", "o-qcard", "o-ansbig", "o-bignum", "o-qpic", "two", "o-short", "o-long", "o-repd", "o-rsec", "o-cols2", "o-cols3", "o-rows", "o-line2", "o-wbars", "sm", "o-wb", "o-wlab", "cur", "o-inline"] },
  { name: "O motion", classes: ["o-arrive", "o-grid", "zin", "zout", "o-sw", "thumb", "o-btn", "o-tool", "o-tile"] },
  { name: "O me", classes: ["o-shelfp", "o-shh", "o-shelf", "o-count", "fill", "o-lrow", "o-cpw", "o-tx", "o-tile", "o-lk", "o-gulink", "o-why"] },
  { name: "O chips", classes: ["v-chips", "right", "wrong", "mk"] },
  { name: "O screens", classes: ["o-state", "home", "o-today", "short", "o-art", "o-box", "o-bh", "o-head", "o-sw", "o-grid", "o-grades", "o-tile", "o-marks", "o-app", "o-nav", "o-gyear", "o-gnow", "o-gch", "o-grows", "o-grow", "o-big", "o-tx", "o-nm", "o-st", "o-wide", "o-label", "o-plain"] },
];

/** states any master may be in: they never make a rule a one-off */
export const STATES = ["on", "open", "opening", "go", "done", "soon", "now", "solved", "shown", "flash", "enter", "fit", "none", "dim", "hidden", "active"];
