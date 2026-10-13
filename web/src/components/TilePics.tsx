/**
 * Tile pictures (v2, G 2026-10-13): a simple, still version of the picture a lesson uses, drawn with one set of rules
 * (3px outline, rounded corners, the picture palette: soft fill, mid for what's taken, grey for what isn't). A chapter
 * shows the picture of the lesson its others build on. 5th grade first; a lesson without one shows its tile without.
 */
const R = (x: number, y: number, w: number, h: number, r: number, c?: string) => `<rect${c ? ` class="${c}"` : ""} x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}"/>`;
const L = (x1: number, y1: number, x2: number, y2: number, c?: string) => `<line${c ? ` class="${c}"` : ""} x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"/>`;
const svg = (vb: string, inner: string) => `<svg class="v-pic" viewBox="${vb}" preserveAspectRatio="xMinYMid meet" aria-hidden="true">${inner}</svg>`;
/** n equal parts in a row; the first `take` are filled */
function bar(x: number, y: number, w: number, h: number, n: number, take: number, gap = 6) {
  const pw = (w - gap * (n - 1)) / n;
  let o = "";
  for (let i = 0; i < n; i++) o += R(x + i * (pw + gap), y, pw, h, Math.min(8, pw / 3), i < take ? "take" : "rest");
  return o;
}
const tenths = [1, 2, 3, 4, 5, 6, 7, 8, 9].map(k => L(2 + k * 9.2, 2, 2 + k * 9.2, 94, "thin")).join("");

// area model: one rectangle split into tens and ones both ways
const AREA = svg("0 0 130 96", R(2, 2, 84, 66, 10) + R(92, 2, 36, 66, 10) + R(2, 74, 84, 20, 8) + R(92, 74, 36, 20, 8));
// equal groups: a bar cut into equal groups, one group taken
const GROUPS = svg("0 0 156 96", `<g transform="translate(0 26)">${R(2, 2, 46, 40, 10, "take")}${R(55, 2, 46, 40, 10, "rest")}${R(108, 2, 46, 40, 10, "rest")}${L(4, 54, 46, 54)}${L(4, 48, 4, 54)}${L(46, 48, 46, 54)}</g>`);
// tenths: a whole cut into 10 strips, some shaded
const TENTHS = svg("0 0 96 96", R(2, 2, 92, 92, 8, "frame") + tenths + R(2, 2, 27.6, 92, 8));
// a box built from cubes
const CUBES = svg("0 0 112 92", `<polygon points="2,34 78,34 108,4 32,4"/><polygon points="78,34 108,4 108,58 78,88"/>${R(2, 34, 76, 54, 2)}${L(27.3, 34, 27.3, 88)}${L(52.7, 34, 52.7, 88)}${L(2, 61, 78, 61)}${L(27.3, 34, 57.3, 4)}${L(52.7, 34, 82.7, 4)}${L(17, 19, 93, 19)}${L(93, 19, 93, 73)}${L(78, 61, 108, 31)}`);
const tick = (k: number) => { const x = 6 + k * 14.8; return L(x, k % 10 ? 52 : 44, x, k % 10 ? 68 : 76, k % 10 ? "thin" : undefined); };

const LESSON: Record<string, string> = {
  "g5-mult2": AREA,
  // sharing into equal groups, a little left over
  "g5-divide": svg("0 0 150 96", bar(2, 14, 118, 68, 4, 4) + R(126, 58, 22, 24, 6, "rest")),
  // brackets first: what's inside them is worked out before the rest
  "g5-order": svg("0 0 170 96", `<path class="brk" d="M14 10 Q2 48 14 86"/><path class="brk" d="M100 10 Q112 48 100 86"/>${R(20, 26, 34, 44, 8, "take")}${R(62, 26, 34, 44, 8, "take")}${R(126, 26, 40, 44, 8)}`),
  // two quarters joined
  add: svg("0 0 156 96", bar(2, 8, 152, 34, 4, 1) + bar(2, 54, 152, 34, 4, 3)),
  // a fifth taken back
  sub: svg("0 0 156 96", `<g transform="translate(0 26)">${bar(2, 2, 152, 40, 5, 3)}${L(97, 4, 121, 40)}</g>`),
  // same-size parts first, then add or take away
  mix: svg("0 0 156 96", bar(2, 8, 152, 34, 3, 2) + bar(2, 54, 152, 34, 6, 4)),
  // two wholes and a quarter
  "g5-improper": svg("0 0 156 96", bar(2, 2, 152, 26, 4, 4, 4) + bar(2, 35, 152, 26, 4, 4, 4) + bar(2, 68, 152, 26, 4, 1, 4)),
  "g5-fracof": GROUPS,
  // a fraction of a fraction: where the two shadings cross
  "g5-multfrac": svg("0 0 96 96", R(2, 2, 92, 92, 8, "rest") + R(2, 2, 92, 61, 8) + R(2, 2, 46, 61, 8, "take") + L(48, 2, 48, 94, "thin") + L(2, 63, 94, 63, "thin") + L(2, 33, 94, 33, "thin")),
  // how many thirds fit in 2 wholes
  "g5-unitdiv": svg("0 0 156 96", bar(2, 14, 74, 68, 3, 3, 4) + bar(80, 14, 74, 68, 3, 3, 4)),
  // hundreds, tens and ones: each 10 times the next
  "g5-pow10": svg("0 0 150 96", R(2, 2, 92, 92, 8) + R(104, 2, 14, 92, 4) + R(128, 80, 14, 14, 4)),
  // a number line with the nearest tenth marked
  "g5-round": svg("0 0 160 96", L(6, 60, 154, 60) + [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(tick).join("") + `<circle class="dot" cx="${6 + 7 * 14.8}" cy="60" r="8"/><path class="brk" d="M${6 + 7 * 14.8} 40 Q${6 + 8.5 * 14.8} 20 ${6 + 10 * 14.8} 36"/>`),
  // tenths added: some shaded, more joining them
  "g5-adddec": svg("0 0 96 96", R(2, 2, 92, 92, 8, "frame") + tenths + R(2, 2, 27.6, 92, 8) + R(29.6, 2, 36.8, 92, 4, "take")),
  "g5-multdec": TENTHS,
  // a strip shared into equal parts
  "g5-divdec": svg("0 0 156 96", `<g transform="translate(0 28)">${bar(2, 2, 152, 36, 5, 0, 4)}</g>${L(2, 82, 154, 82, "thin")}${L(2, 76, 2, 88, "thin")}${L(154, 76, 154, 88, "thin")}`),
  "g5-volume": CUBES,
  // one big unit is the same as four small ones
  "g5-units": svg("0 0 156 96", R(2, 8, 152, 34, 10) + bar(2, 54, 152, 34, 4, 0)),
};

const CHAPTER: Record<string, string> = {
  "5:Whole numbers": AREA, "5:Fractions": GROUPS, "5:Decimals": TENTHS, "5:Measurement": CUBES,
};

export const lessonPic = (id: string): string | undefined => LESSON[id];
export const chapterPic = (grade: number, unit: string): string | undefined => CHAPTER[`${grade}:${unit}`];

/** the picture as a tile's top: a still svg, or nothing when this lesson's picture isn't drawn yet */
export function TilePic({ svg: s }: { svg?: string }) {
  return s ? <span className="v-picbox" dangerouslySetInnerHTML={{ __html: s }} /> : null;
}
