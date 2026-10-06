import { circlePartLesson } from "../../_geometry/circle-part";
import { withEasyStart } from "../../easy-start";

export const lesson = withEasyStart(circlePartLesson("geometry.sector", {
  id: "g10-sector",
  title: "Area of a sector",
  pre: "g7-circarea",
  reference: [90, 4],
  note: "Find the area of the slice. Use 3.14 for π.",
}));
