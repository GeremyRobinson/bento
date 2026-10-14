/** The drawing kit every tile picture uses (v2): rounded rects, lines, one svg wrapper, a bar cut into parts.
 *  Classes: (none) soft fill + deep outline, "take" = mid fill (what is taken/shaded), "rest" = grey (what is not),
 *  "frame" = outline only, "thin" = thin line, "dot" = a filled point, "brk" = a bracket/arc stroke. */
export const R = (x: number, y: number, w: number, h: number, r: number, c?: string) => `<rect${c ? ` class="${c}"` : ""} x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}"/>`;
export const L = (x1: number, y1: number, x2: number, y2: number, c?: string) => `<line${c ? ` class="${c}"` : ""} x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"/>`;
export const svg = (vb: string, inner: string) => `<svg class="v-pic" viewBox="${vb}" preserveAspectRatio="xMidYMid meet" aria-hidden="true">${inner}</svg>`;
/** n equal parts in a row; the first `take` are filled */
export function bar(x: number, y: number, w: number, h: number, n: number, take: number, gap = 6) {
  const pw = (w - gap * (n - 1)) / n;
  let o = "";
  for (let i = 0; i < n; i++) o += R(x + i * (pw + gap), y, pw, h, Math.min(8, pw / 3), i < take ? "take" : "rest");
  return o;
}
