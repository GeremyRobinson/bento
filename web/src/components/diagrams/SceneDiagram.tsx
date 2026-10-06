import type { CSSProperties } from "react";
import type { SceneDiagram as Scene, SceneItem } from "../../explanations/diagrams/scene/schema";
import { useLabelFloor } from "./labelFloor";

const enterClass = (e: SceneItem["enter"]) => (e ? e.split(" ").map((w, i) => (i ? w : `a-${w}`)).join(" ") : "");

/**
 * Draws a scene exactly as its model says. A shape is drawn once the timeline reaches its beat
 * (and until its last beat); it plays its entrance when it first appears.
 */
export function SceneDiagram({ diagram: d, at }: { diagram: Scene; at: number }) {
  const ref = useLabelFloor(d.width);
  return (
    <svg ref={ref} className="viz-svg" viewBox={`0 0 ${d.width} ${d.height}`} role="img" aria-label={d.alt}
      style={{ "--w": Math.round(d.width), "--h": Math.round(d.height) } as CSSProperties} data-family={d.family}>
      {d.items.map((it, i) => {
        const from = it.from ?? 0;
        if (from > at || (it.until != null && at > it.until)) return null;
        const cls = [it.cls ?? "", enterClass(it.enter)].join(" ").trim();
        const style = { "--d": `${(it.delay ?? 0).toFixed(2)}s`, ...it.vars } as CSSProperties;
        const key = `${i}-${from}`;
        switch (it.type) {
          case "rect": return <rect key={key} className={cls} style={style} x={it.x} y={it.y} width={it.w} height={it.h} rx={it.rx} />;
          case "line": return <line key={key} className={cls} style={style} x1={it.x1} y1={it.y1} x2={it.x2} y2={it.y2} pathLength={1} />;
          // a circle that is drawn in needs pathLength 1 too, or "draw" (a dash array of 1) leaves a ring of tiny dashes
          // that reads as a ridged rim; other circles keep real lengths so dashed outlines stay dashed
          case "circle": return <circle key={key} className={cls} style={style} cx={it.cx} cy={it.cy} r={it.r} {...(it.enter?.startsWith("draw") ? { pathLength: 1 } : {})} />;
          case "path": return <path key={key} className={cls} style={style} d={it.d} pathLength={1} />;
          case "polygon": return <polygon key={key} className={cls} style={style} points={it.points.map(p => p.join(",")).join(" ")} />;
          case "text": return <text key={key} className={cls} style={style} x={it.x} y={it.y}>{it.text}{it.sup && <tspan dy="-0.5em" fontSize="0.65em">{it.sup}</tspan>}</text>;
        }
      })}
    </svg>
  );
}
