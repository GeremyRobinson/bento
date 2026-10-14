// Chapter covers test sheet (not shipped): every icon cover as the grade page draws it, in its grade's colours
import { createRoot } from "react-dom/client";
import "./src/styles/index.css";
import { ICON_COVERS } from "./src/components/tilepics/icon-covers";
import { PACK } from "./pairsheet";
const packIcon = (b: string) => `<svg class="cvi" viewBox="0 0 256 256" preserveAspectRatio="xMinYMin meet" fill="currentColor" aria-hidden="true"><g>${b}</g></svg>`;

const q = new URLSearchParams(location.search), keys = q.get("keys")?.split("|");
const which = q.has("pairs") ? Object.fromEntries(Object.keys(PACK).flatMap(k => [[k + "|Ours", ICON_COVERS[k]!], [k + "|Pack", packIcon(PACK[k]!)]])) : keys ? Object.fromEntries(Object.entries(ICON_COVERS).filter(([k]) => keys.includes(k))) : ICON_COVERS;
const gname = (g: number) => (g === 0 ? "Kindergarten" : `${g}${g === 1 ? "st" : g === 2 ? "nd" : g === 3 ? "rd" : "th"} grade`);
function Sheet() {
  return (
    <div style={{ display: "grid", gridTemplateColumns: `repeat(${q.get("cols") ?? 5}, 190px)`, gap: "18px 14px", padding: 24, alignContent: "start" }}>
      {Object.entries(which).map(([k, svg]) => {
        const [g, rest] = k.split(":"), [name, tag] = rest!.split("|");
        return (
          <div key={k}>
            <div style={{ font: "550 12px Inter, sans-serif", color: "var(--v-muted)", margin: "0 0 5px 4px" }}>{gname(+g!)}{tag ? ` · ${tag === "Ours" ? "ours" : "from the pack"}` : ""}</div>
            <div className="v-cover" data-grade={g} style={{ width: 190, height: 170 }}>
              <span className="v-top"><span className="v-picbox" dangerouslySetInnerHTML={{ __html: svg }} /></span>
              <span className="v-tx"><span className="v-nm">{name}</span></span>
            </div>
          </div>
        );
      })}
    </div>
  );
}
createRoot(document.getElementById("app")!).render(<Sheet />);
