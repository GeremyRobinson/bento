import { num, op } from "../../../schemas/math-text";
import type { AnswerModel } from "../../../schemas/lesson";
import { call, f, ns, P } from "../../_plane/kit";
import type { FuncProblem } from "./problem";

export function funcAnswers({ a, b, x }: FuncProblem): AnswerModel {
  return {
    steps: [
      ns({ id: "ax", label: "Multiply", prompt: s => [...P(a), op("×"), ...P(x), op("="), ...s], ans: a * x, hint: `f(${f(x)}) means x is ${f(x)} this time. Put it in for x and multiply.`,
      wrong: [[-a * x, "Sign slip", `${a < 0 ? "Negative" : "Positive"} times ${x < 0 ? "negative" : "positive"} is ${a * x < 0 ? "negative" : "positive"}.`], [a + x, "Added instead of multiplied", `The rule multiplies x by ${f(a)}.`]] }),
      ns({ id: "value", label: "Add the number", prompt: s => [...call("f", x), op("="), num(a * x), op("+"), ...P(b), op("="), ...s], ans: a * x + b, hint: "The rule adds the number on its own last. Add it to what you just found.",
      wrong: [[a * x - b, "Sign slip", `The rule has ${b < 0 ? "− " + f(-b) : "+ " + f(b)}: keep its sign.`]] }),
    ],
    finalParts: [-1],
  };
}
