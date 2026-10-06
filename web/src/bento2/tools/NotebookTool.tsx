// Notebook: every build and project you've saved, grouped by track. Open one and it comes back with your numbers.
import { useState } from "react";
import { trackByCode, projectById } from "../registry";
import { openTool, useB2 } from "../ui/useB2";

export function NotebookTool() {
  const { b2, updateB2 } = useB2();
  const [sure, setSure] = useState<string | null>(null);
  const groups = [...new Set(b2.notebook.map(n => n.track))];
  if (!b2.notebook.length) return <div className="b2note"><p className="b2empty">Projects and builds you save land here, with their numbers, so you can open them again.</p></div>;
  return (
    <div className="b2note">
      {groups.map(g => {
        const t = trackByCode(g);
        return (
          <section key={g}>
            <h3>{t?.name ?? g}</h3>
            <ul>
              {b2.notebook.filter(n => n.track === g).map(n => {
                const p = t && n.project ? projectById(t, n.project) : undefined;
                return (
                  <li key={n.id} className={n.build ? "build" : undefined}>
                    <b>{n.title}{n.build ? " · the build" : ""}</b>
                    <small>{new Date(n.at).toLocaleDateString("en-US", { month: "short", day: "numeric" })}</small>
                    {n.lines.map((l, i) => <p key={i}>{l}</p>)}
                    <span className="b2shact">
                      {p && <button type="button" className="ctl" onClick={() => openTool(p.scene.scene, { props: { ...p.scene.props, ...n.data, project: true }, title: p.name })}>Open</button>}
                      <button type="button" className="ctl" onClick={() => { if (sure === n.id) { updateB2(b => ({ ...b, notebook: b.notebook.filter(x => x.id !== n.id) })); setSure(null); } else setSure(n.id); }}>{sure === n.id ? "Remove it" : "Remove"}</button>
                    </span>
                  </li>
                );
              })}
            </ul>
          </section>
        );
      })}
    </div>
  );
}
