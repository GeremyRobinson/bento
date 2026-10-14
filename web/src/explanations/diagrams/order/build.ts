// Order of operations as one row of tiles (v2 spec g5-order): every number in its own tile, the signs between them, the
// parentheses drawn round what they hold. Each beat lights the group worked next, then that group becomes one tile
// holding its value, as wide as what it replaced, so nothing already drawn moves (G: no parts coming from the side).
import type { SceneDiagram } from "../scene/schema";
import { frame, path, t, M, type Draft } from "../geo/kit";
import { rect } from "../early-g2/kit";

/** one thing in the row as written: a number, a sign, or a parenthesis */
export type OrderToken = { n: number } | { op: string } | { paren: "(" | ")" };
/** a group worked out on one step: the tokens it covers (first and last, inclusive) and the value it becomes */
export interface OrderGroup { from: number; to: number; value: number }

export interface OrderTilesSpec {
  tokens: OrderToken[];
  /** the groups in the order they are worked out; the last covers the whole row */
  groups: OrderGroup[];
  alt: string;
}

const H = 96, GAP = 20, OP = 40, PAREN = 22, RING = 8, DIGIT = 26;
const tileW = (n: number) => Math.max(80, String(n).length * DIGIT + 44);

/**
 * Beat 0: the row as written, nothing lit. Beat k (1 to groups.length): groups before k−1 are tiles with their values,
 * group k−1 is lit (its tiles mid, a ring round it). The beat after the last group: one tile, the answer.
 */
export function buildOrderTiles(s: OrderTilesSpec): SceneDiagram {
  const { tokens, groups } = s;
  const xs: number[] = [], ws: number[] = [];
  let x = 0;
  tokens.forEach(tk => {
    const w = "n" in tk ? tileW(tk.n) : "op" in tk ? OP : PAREN;
    xs.push(x); ws.push(w); x += w + GAP;
  });
  const span = (g: { from: number; to: number }) => ({ x0: xs[g.from]!, x1: xs[g.to]! + ws[g.to]! });
  const items: Draft[] = [];
  for (let b = 0; b <= groups.length; b++) {
    const on = { from: b, until: b, enter: "fade" as const };
    // worked out by this beat: the groups before the lit one, outermost only (a later group holds the earlier ones)
    const done = groups.slice(0, Math.max(0, b - 1)).filter((g, i, all) => !all.some((o, j) => j > i && o.from <= g.from && o.to >= g.to));
    const lit = b >= 1 ? groups[b - 1] : undefined;
    const inLit = (i: number) => !!lit && i >= lit.from && i <= lit.to;
    for (let i = 0; i < tokens.length; i++) {
      const g = done.find(o => i >= o.from && i <= o.to);
      if (g) {
        // a group worked out: one tile with its value, as wide as what it replaced
        if (i === g.from) {
          const { x0, x1 } = span(g);
          items.push(rect(x0, 0, x1 - x0, H, "xchip", on, 14));
          items.push(t((x0 + x1) / 2, H / 2, String(g.value), "big lbl onmid", on));
        }
        continue;
      }
      const tk = tokens[i]!, cx = xs[i]! + ws[i]! / 2;
      if ("n" in tk) {
        items.push(rect(xs[i]!, 0, ws[i]!, H, inLit(i) ? "xchip" : "xbox", on, 14));
        items.push(t(cx, H / 2, String(tk.n), inLit(i) ? "big lbl onmid" : "big lbl pw", on));
      } else if ("op" in tk) {
        items.push(t(cx, H / 2, tk.op, "big lbl pw", on));
      } else {
        // a parenthesis: a curve the height of the tiles, bowing away from what it holds
        const open = tk.paren === "(", tip = xs[i]! + (open ? ws[i]! : 0), bow = xs[i]! + (open ? 0 : ws[i]!);
        items.push(path([M([tip, 2]), { c: "Q", q: [2 * bow - tip, H / 2], p: [tip, H - 2] }], "ln2", on));
      }
    }
    if (lit) { const { x0, x1 } = span(lit); items.push(rect(x0 - RING, -RING, x1 - x0 + 2 * RING, H + 2 * RING, "xring", on, 14 + RING)); }
  }
  // the last beat: the whole row is one number
  const all = span({ from: 0, to: tokens.length - 1 }), answer = groups[groups.length - 1]!.value;
  items.push(rect(all.x0, 0, all.x1 - all.x0, H, "xchip", { from: groups.length + 1, enter: "fade" }, 14));
  items.push(t((all.x0 + all.x1) / 2, H / 2, String(answer), "big lbl onmid", { from: groups.length + 1, enter: "fade" }));
  return frame("order-tiles", items, s.alt, 14);
}
