import { useState, type ReactNode } from "react";
import { useApp } from "../app/AppState";
import type { Dir } from "../app/transition";
import { Slider } from "../components/primitives/Slider";
import { Pill } from "../components/primitives/Pill";
import { Tile, Toggle } from "../components/PageTile";
import { Nav, NavMark } from "../components/Nav";

/** Where a piece is: being built, waiting on Review, or live. G sees work here before Review signs it off. */
type Status = "building" | "review" | "next" | "live";
const STATUS: Record<Status, string> = { building: "In progress", review: "In review", next: "Up next", live: "Live" };

/** One piece on the board: its name, where it is, what it nests in, and a working instance. */
function Piece({ name, status, chunk, nests, children }: { name: string; status: Status; chunk: string; nests: string; children: ReactNode }) {
  return (
    <section className={`sbpiece is-${status}`}>
      <header><b>{name}</b><span className="sbstatus">{STATUS[status]}</span></header>
      <small className="muted">{chunk} · {nests}</small>
      <div className="sbpiece-demo">{children}</div>
    </section>
  );
}

/**
 * The work in progress (G 2026-10-06: "shouldn't I be able to see live what's being worked on?"): each new piece as a
 * live instance, marked with where it is, so it can be tried here before Review signs it off and it goes live.
 */
export function Pieces() {
  const { go } = useApp();
  const [lvl, setLvl] = useState<"chapter" | "year" | "all">("chapter");
  const [side, setSide] = useState<"a" | "b">("a");
  const [sw, setSw] = useState(true);
  const move = (dir: Dir) => go({ name: "sandbox" }, dir);
  return (
    <section className="sbpieces" aria-label="Pieces in progress">
      <header className="sbhead">
        <h2>Pieces in progress</h2>
        <p className="muted">Each piece is built and checked on its own, then nests into the bigger ones. These are the real components, so they work here the way they will in the app.</p>
      </header>
      <div className="sbpgrid">
        <Piece name="Motion" status="review" chunk="Chunks 1 and 6" nests="every page change">
          <div className="sbpills">
            <Pill onClick={() => move("fwd")}>Deeper</Pill><Pill onClick={() => move("back")}>Back</Pill>
            <Pill onClick={() => move("next")}>Next</Pill><Pill onClick={() => move("prev")}>Previous</Pill>
          </div>
          <small className="muted">One curve, 500ms in and 450ms out. Tap to play the page change on this board.</small>
        </Piece>
        <Piece name="Slider" status="review" chunk="Chunk 2" nests="Contents, Which grade">
          <Slider label="Zoom" value={lvl} onPick={setLvl} options={[{ id: "chapter", label: "Chapter" }, { id: "year", label: "Year" }, { id: "all", label: "All grades" }]} />
          <Slider label="Side" value={side} onPick={setSide} options={[{ id: "a", label: "Grades" }, { id: "b", label: "Find my level" }]} />
        </Piece>
        <Piece name="Toggle and Tile" status="review" chunk="Chunk 3" nests="Settings, My Bento">
          <Tile k="Example" title="A tile">
            <Toggle label="A switch" note="What it changes, in one line." on={sw} set={setSw} />
          </Tile>
        </Piece>
        <Piece name="Settings page" status="review" chunk="Chunk 3" nests="Tile, Toggle, Pill">
          <Pill go onClick={() => go({ name: "settings" }, "fwd")}>Open Settings ›</Pill>
        </Piece>
        <Piece name="My Bento page" status="review" chunk="Chunk 4" nests="Tile, Fill, Grade number, Pill">
          <Pill go onClick={() => go({ name: "me" }, "fwd")}>Open My Bento ›</Pill>
        </Piece>
        <Piece name="Nav" status="review" chunk="Chunk 5" nests="every page">
          <div className="sbnav"><Nav left={<NavMark onHome={() => {}} />} center={<span className="sbnav-mid">The page's own middle</span>} right={<span className="sbnav-mid">Its buttons</span>} /></div>
        </Piece>
        <Piece name="Back and Escape" status="review" chunk="Chunk 7" nests="Nav, Contents">
          <small className="muted">The back arrow and Escape step up without adding history. Open a lesson, then try back, Escape and the browser's back.</small>
        </Piece>
        <Piece name="All grades in Contents" status="review" chunk="Chunk 8" nests="Contents, Slider, Shelf">
          <small className="muted">All grades is now the outer level of Contents and the one way to change grade. My Bento's Switch grade opens it too.</small>
        </Piece>
        <Piece name="Keypad master" status="building" chunk="After chunk 8" nests="Practice">
          <small className="muted">Practice's keypad moves onto one Keypad master, with the left-handed layout inside it.</small>
        </Piece>
        <Piece name="Design's motion system" status="next" chunk="7 small chunks" nests="everything that moves">
          <small className="muted">Tokens, page zoom direction, overlays without blur, slider thumb, one press rule, answer motion, Less motion as a fade.</small>
        </Piece>
      </div>
    </section>
  );
}
