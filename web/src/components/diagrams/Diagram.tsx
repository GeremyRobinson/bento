import type { AnimationState, DiagramModel } from "../../explanations/schema";
import { AreaModelDiagram } from "./AreaModelDiagram";
import { ChainDiagram } from "./ChainDiagram";
import { SceneDiagram } from "./SceneDiagram";

/** Picks the renderer for a diagram model. */
export function Diagram({ diagram, timeline, at, fit = false }: { diagram: DiagramModel; timeline: AnimationState[]; at: number; /** scene pictures fill their box */ fit?: boolean }) {
  switch (diagram.kind) {
    case "areaModel": return <AreaModelDiagram diagram={diagram} timeline={timeline} at={at} />;
    case "scene": return <SceneDiagram diagram={diagram} at={at} fit={fit} />;
    case "chain": return <ChainDiagram diagram={diagram} at={at} />;
  }
}
