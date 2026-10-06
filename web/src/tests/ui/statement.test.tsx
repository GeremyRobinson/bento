// The problem's line as the notes preview shows it (Review v40 "little things" 10-13): parts in their picture colours,
// the unknown as a dashed "?" box, "What is x?" over a one-letter equation, and the steps' numbers coloured to match.
import { render } from "@testing-library/react";
import { MathLine, Rich } from "../../components/primitives/MathLine";
import { askOf, dressStatement, fillUnknown, partsLook, toneMath, tonesOf } from "../../components/primitives/statement";
import { ProblemView } from "../../components/practice/ProblemView";
import { lessonById } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import { frac, num, op, slot, text, toPlainText, type MathText } from "../../curriculum/schemas/math-text";

const kinds = (m: MathText) => m.map(t => (t.t === "part" ? `p${t.k}` : t.t === "op" ? t.v : t.t === "text" ? t.v : t.t));

describe("the statement's parts and unknown", () => {
  it("marks a + b and a × b as the first and second part and boxes the unknown", () => {
    expect(kinds(dressStatement([num(16), op("+"), num(2)]))).toEqual(["p0", "+", "p1", "=", "?"]);
    expect(kinds(dressStatement([frac(1, 2), op("×"), frac(3, 4), op("="), text("?")]))).toEqual(["p0", "×", "p1", "=", "?"]);
    expect(toPlainText(dressStatement([num(16), op("+"), num(2)]))).toBe("16 + 2 = ?");
  });

  it("leaves the colours off where the two numbers are not two parts", () => {
    // the first number of a − b is the whole; × 10 moves a point; an area model colours its boxes, not its factors
    expect(kinds(dressStatement([num(9), op("−"), num(4)]))).toEqual(["num", "−", "num", "=", "?"]);
    expect(kinds(dressStatement([num(2.5), op("×"), num(100)]))).toEqual(["num", "×", "num", "=", "?"]);
    expect(kinds(dressStatement([num(24), op("×"), num(17)], "fixed"))).toEqual(["num", "×", "num", "=", "?"]);
    // longer lines and lines with words or letters stay exactly as written
    const long: MathText = [num(3), op("×"), num(6), op("="), num(3), op("×"), num(5), op("+"), num(3)];
    expect(dressStatement(long)).toBe(long);
    const eq: MathText = [num(2), text("x"), op("+"), num(5), op("="), num(11)];
    expect(dressStatement(eq)).toBe(eq);
  });

  it("draws the parts in their colour classes and the unknown as a dashed box, not a question's own mark", () => {
    const { container } = render(<MathLine math={dressStatement([num(7), op("+"), num(5)])} />);
    expect(container.querySelector(".pt.p0")!.textContent).toBe("7");
    expect(container.querySelector(".pt.p1")!.textContent).toBe("5");
    expect(container.querySelectorAll(".unk")).toHaveLength(1);
    const q = render(<MathLine math={[text("How many dots?")]} />).container;
    expect(q.querySelector(".unk")).toBeNull();
    const two = render(<MathLine math={[num(19), text(" ? "), num(26)]} />).container;
    expect(two.querySelectorAll(".unk")).toHaveLength(1);
  });

  it("an empty answer box is marked empty, so it takes the unknown's dashed look", () => {
    const { container } = render(<MathLine math={[num(3), op("+"), num(4), op("="), slot("x")]} values={{}} onSlot={() => {}} />);
    expect(container.querySelector(".slot")!.classList.contains("empty")).toBe(true);
    const filled = render(<MathLine math={[slot("x")]} values={{ x: "7" }} onSlot={() => {}} />).container;
    expect(filled.querySelector(".slot")!.classList.contains("empty")).toBe(false);
  });

  it("colours the same numbers in a step's math and words, whole numbers only", () => {
    const tones = tonesOf(dressStatement([num(16), op("+"), num(2)]));
    expect(tones).toEqual([{ s: "16", k: 0 }, { s: "2", k: 1 }]);
    expect(kinds(toneMath([num(16), op("+"), num(2), op("="), num(18)], tones))).toEqual(["p0", "+", "p1", "=", "num"]);
    const { container } = render(<Rich text="Start at **16**, hop 2 times: 17, 18. Not 160, 1.6, 2.5 or 12." tones={tones} />);
    expect([...container.querySelectorAll(".tone")].map(e => `${e.className}:${e.textContent}`)).toEqual(["tone p0:16", "tone p1:2"]);
    // the same number twice can't say which part it is: no colours at all
    expect(tonesOf(dressStatement([num(3), op("+"), num(3)]))).toEqual([]);
  });

  it("takes how the parts are coloured from the problem's picture", () => {
    const look = (id: string) => { const l = lessonById(id)!, p = l.generate(createRng(1), 0); return partsLook(l.explain(p, l.answers(p)).diagram); };
    expect(look("g1-add20")).toBe("one"); // a number line in one colour
    expect(look("add")).toBe("two"); // a tape with a second-part bar
    expect(look("g1-addtens")).toBe("fixed"); // place-value blocks in the fixed part colours
  });

  it("Practice shows the dressed statement", () => {
    const l = lessonById("g1-add20")!;
    const { container } = render(<ProblemView lessonId="g1-add20" problem={l.restore({ a: 12, b: 3 })} story={false} />);
    expect(container.querySelector(".math.parts-one .pt.p0")!.textContent).toBe("12");
    expect(container.querySelector(".math .unk")).not.toBeNull();
  });
});

describe("the question over an equation", () => {
  it("asks for the one letter of an equation", () => {
    expect(askOf([text("x"), op("+"), num(2), op("="), num(14)])).toBe("What is x?");
    expect(askOf([frac(1, 2), op("="), frac("x", 16)])).toBe("What is x?");
  });
  it("says nothing when the letter is given, squared, a name, or one of two", () => {
    expect(askOf([text("m"), op("="), num(-6)])).toBeNull();
    expect(askOf([text("x²"), op("+"), num(2), text("x"), op("="), num(0)])).toBeNull();
    expect(askOf([text("f(x)"), op("="), num(2), text("x")])).toBeNull();
    expect(askOf([text("y"), op("="), num(2), text("x")])).toBeNull();
    expect(askOf([num(2), text("x"), op("+"), num(5)])).toBeNull();
  });
});

describe("the solved problem's unknown", () => {
  it("fills the ? after = with the answer, and leaves other shapes alone", () => {
    const m: MathText = [num(48), op("+"), num(27), op("="), text("?")];
    expect(fillUnknown(m, 75).at(-1)).toMatchObject({ t: "answer", v: 75 });
    expect(fillUnknown(m, null)).toBe(m);
    const q: MathText = [text("How many dots?")];
    expect(fillUnknown(q, 5)).toBe(q);
  });
});
