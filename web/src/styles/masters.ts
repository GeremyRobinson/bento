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
];

/** states any master may be in: they never make a rule a one-off */
export const STATES = ["on", "open", "opening", "go", "done", "soon", "now", "solved", "shown", "flash", "enter", "fit", "none", "dim", "hidden", "active"];
