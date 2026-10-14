// Chapter covers test sheet (not shipped): every style B cover as the grade page draws it, in its grade's colours
import { createRoot } from "react-dom/client";
import "./src/styles/index.css";
import { COVERS } from "./src/components/tilepics/covers";
import { COVERS2 } from "./src/components/tilepics/covers2";
import { PHOS, HAND, KEEP } from "./coversheet-phos";
import { ICONS } from "./coversheet-icons";

const q = new URLSearchParams(location.search), keys = q.get("keys")?.split("|");
const src = q.get("src"), FEW = { ...KEEP, "1:Place value": HAND["1:Place value"]!, "10:Circles": HAND["10:Circles"]!, "11:Probability": HAND["11:Probability"]!, "3:Fractions": PHOS["3:Fractions"]!, "7:Probability": PHOS["7:Probability"]!, "6:Expressions and equations": PHOS["6:Expressions and equations"]! };
const which = src === "icons" ? Object.fromEntries(Object.entries({ ...ICONS, "0:Counting": KEEP["0:Counting"]!, "3:Multiplication and division": KEEP["3:Multiplication and division"]!, "12:Integrals": KEEP["12:Integrals"]!, "1:Place value": HAND["1:Place value"]!, "2:Place value": HAND["1:Place value"]!, "3:Place value": HAND["1:Place value"]!, "10:Circles": HAND["10:Circles"]!, "11:Probability": HAND["11:Probability"]! }).sort(([a], [b]) => +a.split(":")[0]! - +b.split(":")[0]! || a.localeCompare(b))) : src === "few" ? FEW : src === "keep" ? KEEP : src === "phos" ? PHOS : src === "hand" ? HAND : keys ? Object.fromEntries(Object.entries({ ...COVERS, ...COVERS2 }).filter(([k]) => keys.includes(k))) : q.get("set") === "1" ? COVERS : COVERS2;
const gname = (g: number) => (g === 0 ? "Kindergarten" : `${g}${g === 1 ? "st" : g === 2 ? "nd" : g === 3 ? "rd" : "th"} grade`);
function Sheet() {
  return (
    <div style={{ display: "grid", gridTemplateColumns: `repeat(${q.get("cols") ?? 6}, 190px)`, gap: "18px 14px", padding: 24 }}>
      {Object.entries(which).map(([k, svg]) => {
        const [g, name] = k.split(":");
        return (
          <div key={k}>
            <div style={{ font: "550 12px Inter, sans-serif", color: "var(--v-muted)", margin: "0 0 5px 4px" }}>{gname(+g!)}</div>
            <div className="v-cover" data-grade={g} style={{ width: 190, height: 170 }}>
              <span className="v-top"><span className="v-picbox" style={src ? { color: "var(--pic-deep)", display: "grid", placeItems: "start center", paddingTop: 10, height: "100%" } : undefined} dangerouslySetInnerHTML={{ __html: src ? svg.replace("<svg ", '<svg width="84" height="84" ') : svg }} /></span>
              <span className="v-tx"><span className="v-nm">{name}</span></span>
            </div>
          </div>
        );
      })}
    </div>
  );
}
createRoot(document.getElementById("app")!).render(<Sheet />);
