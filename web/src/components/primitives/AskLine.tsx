import { askOf } from "./statement";
import type { MathText } from "../../curriculum/schemas/math-text";

/** The short question over an equation ("What is x?"), when the equation's own letters say what it asks; else nothing. */
export function AskLine({ math }: { math: MathText }) {
  const ask = askOf(math);
  return ask ? <p className="askline">{ask}</p> : null;
}
