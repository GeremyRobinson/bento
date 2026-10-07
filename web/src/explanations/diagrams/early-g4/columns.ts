// Column addition and subtraction (4th grade): the two numbers lined up by place, worked one column at a time.
// Addition shows each carried 1 over the next column; subtraction crosses out the digit that lends a ten
// and writes the new digits above. The thousands and up are worked together in the last beat.
import type { SceneDiagram } from "../scene/schema";
import { frame, seg, t, type Draft } from "../geo/kit";

export interface ColumnSpec {
  a: number;
  b: number;
  sign: "+" | "−";
  /** beat each of the ones, tens and hundreds columns is worked at; the thousands and up come at `rest` */
  beats: { ones: number; tens: number; hundreds: number; rest: number };
  alt: string;
}

const CW = 40, ROW = 48, COMMA = 12;
const digitsOf = (n: number) => String(n).split("").reverse().map(Number);

/** What happens in each column, ones first: the carry or the trade, and the digit written. */
export function columnWork(a: number, b: number, sign: "+" | "−") {
  const A = digitsOf(a), B = digitsOf(b), out: { top: number; bottom: number; carryIn: number; write: number; regroup: boolean }[] = [];
  let carry = 0;
  for (let i = 0; i < 3; i++) {
    const top = (A[i] ?? 0) - (sign === "−" ? carry : 0), bottom = B[i] ?? 0;
    if (sign === "+") {
      const sum = top + bottom + carry;
      out.push({ top, bottom, carryIn: carry, write: sum % 10, regroup: sum >= 10 });
      carry = sum >= 10 ? 1 : 0;
    } else {
      const regroup = top < bottom;
      out.push({ top, bottom, carryIn: carry, write: (regroup ? top + 10 : top) - bottom, regroup });
      carry = regroup ? 1 : 0;
    }
  }
  return { cols: out, carryOut: carry };
}

export function buildColumns(s: ColumnSpec): SceneDiagram {
  const res = s.sign === "+" ? s.a + s.b : s.a - s.b;
  const n = Math.max(String(s.a).length, String(s.b).length, String(res).length);
  // column i counts from the ones (i = 0); the thousands sit a little apart, like the comma does
  const X = (i: number) => (n - 1 - i) * CW + (i < 3 && n > 3 ? COMMA : 0);
  const beatOf = (i: number) => (i === 0 ? s.beats.ones : i === 1 ? s.beats.tens : i === 2 ? s.beats.hundreds : s.beats.rest);
  const { cols } = columnWork(s.a, s.b, s.sign);
  const items: Draft[] = [];
  const yA = 0, yB = ROW, yLine = ROW + 28, yR = ROW * 2 + 12, yUp = -34;

  // the column being worked lights up
  for (const i of [0, 1, 2]) {
    if (i >= n) continue;
    const b = beatOf(i);
    items.push({ type: "rect", x: X(i) - CW / 2 + 2, y: yUp - 16, w: CW - 4, h: yR + 22 - yUp + 16, rx: 10, cls: "fillsoft", from: b, until: b, enter: "fade" } as Draft);
  }
  if (n > 3) {
    const b = s.beats.rest;
    items.push({ type: "rect", x: X(n - 1) - CW / 2 + 2, y: yUp - 16, w: X(3) - X(n - 1) + CW - 4, h: yR + 22 - yUp + 16, rx: 10, cls: "fillsoft", from: b, until: b, enter: "fade" } as Draft);
  }

  const A = digitsOf(s.a), B = digitsOf(s.b), R = digitsOf(res);
  const comma = (row: number[], y: number, cls: string, extra: Partial<Draft> = {}) => {
    if (row.length > 3) items.push(t((X(3) + X(2)) / 2 + 2, y + 10, ",", cls, extra));
  };
  A.forEach((d, i) => items.push(t(X(i), yA, String(d), "big", { enter: "fade" })));
  comma(A, yA, "big");
  B.forEach((d, i) => items.push(t(X(i), yB, String(d), "big", { enter: "fade" })));
  comma(B, yB, "big");
  items.push(t(X(n - 1) - CW, yB, s.sign, "big"));
  items.push(seg([X(n - 1) - CW * 1.5, yLine], [X(0) + CW / 2, yLine], "ax"));

  // regrouping marks above the top number
  if (s.sign === "+") {
    cols.forEach((c, i) => {
      if (!c.regroup) return;
      items.push(t(X(i + 1), yUp, "1", "sm acc", { from: beatOf(i), enter: "rise", delay: 0.5 }));
    });
  } else {
    // a digit that lends a ten is crossed out and its new value written above; the digit that borrows gets a 1 in front
    cols.forEach((c, i) => {
      if (!c.regroup) return;
      const lend = i + 1, bt = beatOf(i), lendNow = (A[lend] ?? 0) - 1;
      const lendNext = cols[lend];
      const lendUntil = lendNext?.regroup ? beatOf(lend) - 1 : undefined;
      items.push(seg([X(lend) - 11, yA + 13], [X(lend) + 11, yA - 13], "ln2", { from: bt, enter: "draw" }));
      items.push(t(X(lend), yUp, String(lendNow), "sm acc", { from: bt, enter: "rise", delay: 0.3, ...(lendUntil != null ? { until: lendUntil } : {}) }));
      if (lendNext?.regroup) items.push(t(X(lend), yUp, String(lendNow + 10), "sm acc", { from: beatOf(lend), enter: "pop" }));
      // the borrowing digit: crossed and rewritten with ten more (unless it already shows a new value above)
      const wasLent = i > 0 && cols[i - 1]!.regroup;
      if (!wasLent) {
        items.push(seg([X(i) - 11, yA + 13], [X(i) + 11, yA - 13], "ln2", { from: bt, enter: "draw", delay: 0.4 }));
        items.push(t(X(i), yUp, String(c.top + 10), "sm acc", { from: bt, enter: "rise", delay: 0.6 }));
      }
    });
  }

  // the answer, a column at a time; the thousands and up all at once
  R.forEach((d, i) => {
    if (s.sign === "−" && i === R.length - 1 && d === 0 && i > 0) return;
    items.push(t(X(i), yR, String(d), "big acc", { from: beatOf(Math.min(i, 3)), enter: "rise", delay: i < 3 ? 0.8 : 0.3 }));
  });
  if (R.length > 3) items.push(t((X(3) + X(2)) / 2 + 2, yR + 10, ",", "big acc", { from: s.beats.rest, enter: "fade" }));

  return frame("columns", items, s.alt, 14, { w: 300 });
}

/**
 * Decimal columns (Curriculum fixes-02, Part B; g5-adddec): two numbers with their points in one line, a written-in 0
 * where a number stops short of hundredths, then partial rows: the whole columns added on their own, the decimal
 * columns added on their own, and the two partials put together. Numbers come in as whole hundredths (`point` digits
 * after the point), so nothing is ever a float.
 */
export interface DecimalColumnSpec {
  /** the numbers in hundredths (12.5 → 1250) */
  a: number;
  b: number;
  /** digits each number shows after its point before padding (12.5 → 1); the rest are written-in zeros */
  shown: [number, number];
  /** digits after the point (2 for hundredths) */
  point: number;
  beats: { lineUp: number; whole: number; decimal: number; total: number };
  /** part roles for the whole partial and the decimal partial */
  parts?: [string, string];
  alt: string;
}

const DCW = 30, DROW = 44, POINT = 14;

export function buildDecimalColumns(s: DecimalColumnSpec): SceneDiagram {
  const P = s.point, unit = 10 ** P, sum = s.a + s.b;
  const W = Math.floor(s.a / unit) + Math.floor(s.b / unit), D = (s.a % unit) + (s.b % unit);
  const [pw, pd] = s.parts ?? ["p0", "p1"];
  const wholeLen = (v: number) => String(Math.floor(v / unit)).length;
  const nW = Math.max(wholeLen(s.a), wholeLen(s.b), wholeLen(sum), String(W).length);
  // place i counts from the last decimal digit (i = 0); the point sits between place P − 1 and P
  const X = (i: number) => (nW + P - 1 - i) * DCW + (i < P ? POINT : 0);
  const xPoint = X(P) + DCW / 2 + POINT / 2;
  const digit = (v: number, i: number) => Math.floor(v / 10 ** i) % 10;
  const yA = 0, yB = DROW, yL1 = DROW + 26, yW = DROW * 2 + 14, yD = yW + DROW, yL2 = yD + 26, yR = yD + DROW + 12;
  const items: Draft[] = [];
  const { lineUp, whole, decimal, total } = s.beats;
  const band = (i0: number, i1: number, part: string, b: number) =>
    items.push({ type: "rect", x: X(i1) - DCW / 2, y: yA - 22, w: X(i0) - X(i1) + DCW, h: yR - yA + 44, rx: 10, cls: `fillsoft ${part}`, from: b, until: b, enter: "fade" } as Draft);
  // the column groups light up in turn: the whole columns, then the decimal columns
  band(P, P + nW - 1, pw, whole);
  band(0, P - 1, pd, decimal);
  // the point line through every row
  items.push(seg([xPoint, yA - 20], [xPoint, yR + 20], "wire", { from: lineUp, enter: "draw" }));

  const row = (v: number, y: number, cls: string, extra: Partial<Draft>, opts: { pad?: number; whole?: boolean; decimals?: boolean; lead?: boolean } = {}) => {
    const lenW = wholeLen(v);
    for (let i = 0; i < P + lenW; i++) {
      const isDec = i < P;
      if (isDec && opts.decimals === false) continue;
      if (!isDec && opts.whole === false) continue;
      const padded = opts.pad != null && isDec && i < P - opts.pad;
      items.push(t(X(i), y, String(digit(v, i)), padded ? "lbl big acc" : cls, padded ? { from: lineUp, enter: "pop", delay: 0.6 + 0.2 * (P - 1 - i) } : extra));
    }
    if (opts.decimals !== false) items.push(t(xPoint, y + 6, ".", cls, extra));
  };
  row(s.a, yA, "lbl big pw", { enter: "fade" }, { pad: s.shown[0] });
  row(s.b, yB, "lbl big pw", { enter: "fade" }, { pad: s.shown[1] });
  items.push(t(X(P + nW - 1) - DCW, yB, "+", "lbl big pw"));
  items.push(seg([X(P + nW - 1) - DCW * 1.5, yL1], [X(0) + DCW / 2, yL1], "ax"));
  // the partials: the whole parts' sum under the whole columns, the decimal parts' sum under the decimal columns
  row(W * unit, yW, `lbl big ${pw}`, { from: whole, enter: "rise", delay: 0.4 }, { decimals: false });
  for (let i = 0; i < P; i++) items.push(t(X(i), yD, String(digit(D, i)), `lbl big ${pd}`, { from: decimal, enter: "rise", delay: 0.4 + 0.15 * (P - 1 - i) }));
  items.push(t(xPoint, yD + 6, ".", `lbl big ${pd}`, { from: decimal, enter: "rise", delay: 0.4 }));
  const carry = Math.floor(D / unit);
  // the decimal sum's whole part sits left of the point: 0, or a 1 that has crossed over into the ones
  items.push(t(X(P), yD, String(carry), carry ? "lbl big acc" : `lbl big ${pd}`, { from: decimal, enter: carry ? "pop" : "rise", delay: carry ? 1 : 0.4 }));
  if (carry) {
    items.push({ type: "rect", x: X(P) - 15, y: yD - 17, w: 30, h: 34, rx: 10, cls: "xring", from: decimal, until: decimal, enter: "pop", delay: 1.2 } as Draft);
  }
  items.push(t(X(P + nW - 1) - DCW, yD, "+", "lbl big pw", { from: total, enter: "fade" }));
  // the two partials add into the answer
  items.push(seg([X(P + nW - 1) - DCW * 1.5, yL2], [X(0) + DCW / 2, yL2], "ax", { from: total, enter: "draw" }));
  row(sum, yR, "lbl big acc", { from: total, enter: "rise", delay: 0.5 });
  return frame("columns", items, s.alt, 14, { w: 260 });
}
