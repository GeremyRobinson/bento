// The always-there tools shell. The island's Tools button opens the list (a floating stack, like quick settings);
// a tool opens as a floating panel beside the lesson (on a phone, over it). One tool panel at a time; it reopens with
// the numbers it was left with. Pictures and other tools open a tool by sending "b2:tool" (ui/useB2.ts, openTool).
import { useEffect, useRef, useState, type ComponentType, type CSSProperties } from "react";
import { reduceMotion } from "../../app/transition";
import type { B2ToolMeta, B2Track } from "../model";
import { sceneByName } from "../scenes";
import { Calculator } from "./Calculator";
import { Grapher2D } from "./Grapher2D";
import { Grapher3D } from "./Grapher3D";
import { MatrixPad } from "./MatrixPad";
import { ShelfTool } from "./ShelfTool";
import { UnitsTool } from "./UnitsTool";
import { Scratch } from "./Scratch";
import { NotebookTool } from "./NotebookTool";

/** the eight always-there tools (toolbox.md), in the toolbox's order */
export const CORE_TOOLS: (B2ToolMeta & { C: ComponentType<{ args?: unknown }> })[] = [
  { id: "calc", name: "Scientific calculator", short: "Calculator", C: Calculator },
  { id: "graph2d", name: "Grapher 2D", short: "Grapher", C: Grapher2D },
  { id: "graph3d", name: "Grapher 3D", short: "3D", C: Grapher3D },
  { id: "matrix", name: "Matrix pad", short: "Matrix", C: MatrixPad },
  { id: "shelf", name: "Number shelf", short: "Shelf", C: ShelfTool },
  { id: "units", name: "Units and constants", short: "Units", C: UnitsTool },
  { id: "scratch", name: "Scratch paper", short: "Scratch", C: Scratch },
  { id: "notebook", name: "Notebook", short: "Notebook", C: NotebookTool },
];

/** a tool's name and kind: core, or one of the track's own (its picture) */
export function toolMeta(id: string, track?: B2Track): B2ToolMeta | undefined {
  return CORE_TOOLS.find(t => t.id === id) ?? track?.tools.find(t => t.id === id);
}

interface Open { id: string; args?: unknown; n: number }
const later = (f: () => void) => { const t = setTimeout(f, reduceMotion() ? 0 : 240); return () => clearTimeout(t); };

export function ToolShell({ track }: { track?: B2Track }) {
  const [menu, setMenu] = useState<"open" | "closing" | null>(null);
  const [panel, setPanel] = useState<Open | null>(null);
  const [closing, setClosing] = useState(false);
  const [full, setFull] = useState(false);
  const isOpen = useRef(false);
  isOpen.current = !!panel;
  useEffect(() => {
    let n = 0;
    const onTool = (e: Event) => {
      const d = (e as CustomEvent<{ id: string; args?: unknown }>).detail;
      setMenu(m => (m ? "closing" : m)); setClosing(false);
      setPanel({ id: d.id, args: d.args, n: ++n });
    };
    const onMenu = () => setMenu(m => (m === "open" ? "closing" : "open"));
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") { setMenu(m => (m ? "closing" : m)); if (isOpen.current) setClosing(true); } };
    // quick settings and Me are stacks too; only one stack is ever open
    const onPanel = (e: Event) => { if ((e as CustomEvent).detail === "settings") setMenu(m => (m === "open" ? "closing" : m)); };
    addEventListener("b2:tool", onTool); addEventListener("b2:tools", onMenu); addEventListener("keydown", onKey); addEventListener("bento:panel", onPanel);
    return () => { removeEventListener("b2:tool", onTool); removeEventListener("b2:tools", onMenu); removeEventListener("keydown", onKey); removeEventListener("bento:panel", onPanel); };
  }, []);
  useEffect(() => { dispatchEvent(new CustomEvent("b2:toolsopen", { detail: menu === "open" })); if (menu === "closing") return later(() => setMenu(null)); }, [menu]);
  useEffect(() => { if (closing) return later(() => { setPanel(null); setClosing(false); }); }, [closing]);

  const all: B2ToolMeta[] = [...(track ? [...track.tools].sort((a, b) => Number(!!b.star) - Number(!!a.star)) : []), ...CORE_TOOLS];
  const meta = panel ? toolMeta(panel.id, track) ?? { id: panel.id, name: (panel.args as { title?: string } | undefined)?.title ?? panel.id, short: panel.id } : null;
  const Core = panel ? CORE_TOOLS.find(t => t.id === panel.id)?.C : undefined;
  const Pic = panel && !Core ? sceneByName(panel.id) : undefined;
  const picProps = (panel?.args as { props?: Record<string, number | string | boolean> } | undefined)?.props ?? {};
  const title = (panel?.args as { title?: string } | undefined)?.title ?? meta?.name;

  return (
    <>
      {menu && (
        <>
          <div className={`fdim${menu === "closing" ? " out" : ""}`} onClick={() => setMenu("closing")} />
          <div className={`fstack qset b2menu${menu === "closing" ? " out" : ""}`} role="dialog" aria-label="Tools" style={{ "--n": all.length + 1 } as CSSProperties}>
            <span className="flbl" style={{ "--i": 0 } as CSSProperties}>Tools</span>
            {all.map((t, i) => (
              <button key={t.id} className="fpill" style={{ "--i": i + 1 } as CSSProperties} onClick={() => dispatchEvent(new CustomEvent("b2:tool", { detail: { id: t.id } }))}>
                {t.name}{t.star ? " ★" : ""}
              </button>
            ))}
          </div>
        </>
      )}
      {panel && meta && (
        <>
          <div className={`fdim b2tooldim${closing ? " out" : ""}`} onClick={() => setClosing(true)} />
          <div className={`fstack b2tool${full ? " full" : ""}${closing ? " out" : ""}`} role="dialog" aria-label={title} style={{ "--n": 2 } as CSSProperties}>
            <div className="b2toolcard" style={{ "--i": 0 } as CSSProperties}>
              <header>
                <b>{title}{meta.star ? " ★" : ""}</b>
                <button type="button" className="ctl" onClick={() => setFull(f => !f)} aria-pressed={full}>{full ? "Smaller" : "Bigger"}</button>
                <button type="button" className="ctl circ" onClick={() => setClosing(true)} aria-label={`Close ${title}`}>×</button>
              </header>
              <div className="b2toolbody" key={panel.n}>
                {Core ? <Core args={panel.args} /> : Pic ? <Pic props={picProps} place={picProps.project ? "project" : "tool"} /> : <p className="b2empty">This tool isn't built yet.</p>}
              </div>
            </div>
          </div>
        </>
      )}
    </>
  );
}
