// Word problems about amounts (g3-mass, g3-liters): the amounts as labeled boxes. Two boxes side by side to put
// together, one box with a part taken away, equal boxes in a row, or one long box split into equal parts.
// The unknown is a "?" until Learn's last beat writes it in.
import type { SceneDiagram } from "../scene/schema";
import { frame, t, type Draft } from "../geo/kit";

export interface StoryBoxesSpec {
  op: "+" | "−" | "×" | "÷";
  a: number;
  b: number;
  unit: string;
  /** beat the answer appears on; leave out for practice */
  answer?: number;
  alt: string;
}

const fmt = (n: number) => n.toLocaleString("en-US");

export function buildStoryBoxes(s: StoryBoxesSpec): SceneDiagram {
  const items: Draft[] = [], H = 48, W = 420, { a, b, unit } = s;
  const box = (x: number, w: number, cls: string, label: string, o: Partial<Draft> = {}) => {
    items.push({ type: "rect", x, y: 0, w, h: H, rx: 6, cls, ...o } as Draft);
    if (label) items.push(t(x + w / 2, H / 2, label, w < 60 ? "xs" : "sm", o));
  };
  const total = (label: string, x0: number, x1: number) => {
    items.push({ type: "path", segs: [{ c: "M", p: [x0, -10] }, { c: "L", p: [x0, -18] }, { c: "L", p: [x1, -18] }, { c: "L", p: [x1, -10] }], cls: "ln thin" } as Draft);
    items.push(t((x0 + x1) / 2, -36, label, "lbl"));
  };
  const ans = (v: number) => `${fmt(v)} ${unit}`;
  const shown = (v: number, x: number, y: number) => {
    if (s.answer != null) items.push(t(x, y, ans(v), "lbl acc", { from: s.answer, enter: "rise" }));
  };
  if (s.op === "+") {
    const wa = (W * a) / (a + b);
    box(0, wa, "cell c0", `${fmt(a)} ${unit}`);
    box(wa, W - wa, "cell c1", `${fmt(b)} ${unit}`);
    total("?", 0, W);
    shown(a + b, W / 2, -62);
  } else if (s.op === "−") {
    const wb = (W * b) / a;
    box(0, W - wb, "cell c0", "?");
    box(W - wb, wb, "cell c1 dash", `${fmt(b)} ${unit}`);
    total(`${fmt(a)} ${unit}`, 0, W);
    shown(a - b, (W - wb) / 2, H + 26);
  } else if (s.op === "×") {
    const w = W / a;
    for (let i = 0; i < a; i++) box(i * w, w, "cell c0", `${fmt(b)}`);
    total("?", 0, W);
    items.push(t(W / 2, H + 26, `${a} × ${fmt(b)} ${unit}`, "sm"));
    shown(a * b, W / 2, -62);
  } else {
    const w = W / b;
    for (let i = 0; i < b; i++) box(i * w, w, "cell c0 dash", "?");
    total(`${fmt(a)} ${unit}`, 0, W);
    items.push(t(W / 2, H + 26, `${b} equal parts`, "sm"));
    shown(a / b, W / 2, H + 56);
  }
  return frame("story-boxes", items, s.alt, 14, { w: 460 });
}
