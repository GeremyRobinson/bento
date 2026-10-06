import { circlePartLesson } from "../../_geometry/circle-part";
import { withEasyStart } from "../../easy-start";

export const lesson = withEasyStart(circlePartLesson("geometry.arc", {
  id: "g10-arc",
  title: "Arc length",
  reference: [180, 5],
  note: "Find the length of the arc. Use 3.14 for π.",
}));
