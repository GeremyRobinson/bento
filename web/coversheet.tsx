// Chapter covers test sheet (not shipped): every style B cover as the grade page draws it, in its grade's colours
import { createRoot } from "react-dom/client";
import "./src/styles/index.css";
import { COVERS } from "./src/components/tilepics/covers";
import { COVERS2 } from "./src/components/tilepics/covers2";

const q = new URLSearchParams(location.search), keys = q.get("keys")?.split("|");
const which = keys ? Object.fromEntries(Object.entries({ ...COVERS, ...COVERS2 }).filter(([k]) => keys.includes(k))) : q.get("set") === "1" ? COVERS : COVERS2;
const gname = (g: number) => (g === 0 ? "Kindergarten" : `${g}${g === 1 ? "st" : g === 2 ? "nd" : g === 3 ? "rd" : "th"} grade`);
function Sheet() {
  return (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(6, 190px)", gap: "18px 14px", padding: 24 }}>
      {Object.entries(which).map(([k, svg]) => {
        const [g, name] = k.split(":");
        return (
          <div key={k}>
            <div style={{ font: "550 12px Inter, sans-serif", color: "var(--v-muted)", margin: "0 0 5px 4px" }}>{gname(+g!)}</div>
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
