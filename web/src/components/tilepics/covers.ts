/**
 * Chapter covers, style B "a real thing" (G 2026-10-14: "Then I think 'B. A real thing' works best"): each chapter is
 * a thing a child knows from life (apples to count, a pizza with a slice taken, a speedometer), so the cover says what
 * the chapter is about before the lesson does. Review passed the test set (math-app/review/v2/covers-test).
 *
 * The roles are the picture system's, through tokens only (styles/picture-system.css, `.v-pic.cv`):
 * s soft part, m mid part (what counts), e an empty place (card colour), g not counted (grey), o outline only,
 * k a tick, gl the ground, f a solid deep part (a needle, a branch), mf a solid mid part (water, a speed arc),
 * dots a dotted path. Lines hold 3px on screen at any tile size (non-scaling); anything thicker is a filled shape.
 *
 * Each cover moves once as it comes in, and the move is the chapter's idea (G 22:10: the model's logic, no loops):
 * the apples come one at a time to be counted, the battery fills cell by cell, the glass fills up.
 * `d` is a part's delay in seconds; `a` its move (styles: .cv-pop, .cv-rise, .cv-drop, .cv-grow, .cv-spin, .cv-sweep).
 */

const r1 = (n: number) => Math.round(n * 10) / 10;
type Part = string;
/** an svg part with its role, move and delay */
const at = (a: string, d: number) => (a ? ` data-a="${a}" style="--d:${d}s"` : "");
const rect = (c: string, x: number, y: number, w: number, h: number, rx: number, a = "", d = 0): Part =>
  `<rect class="${c}" x="${r1(x)}" y="${r1(y)}" width="${r1(w)}" height="${r1(h)}" rx="${r1(rx)}"${at(a, d)}/>`;
const circ = (c: string, cx: number, cy: number, r: number, a = "", d = 0): Part => `<circle class="${c}" cx="${r1(cx)}" cy="${r1(cy)}" r="${r1(r)}"${at(a, d)}/>`;
const path = (c: string, dd: string, a = "", d = 0): Part => `<path class="${c}" d="${dd}"${at(a, d)}/>`;
const line = (c: string, x1: number, y1: number, x2: number, y2: number, a = "", d = 0): Part =>
  `<line class="${c}" x1="${r1(x1)}" y1="${r1(y1)}" x2="${r1(x2)}" y2="${r1(y2)}"${at(a, d)}/>`;
const poly = (c: string, pts: [number, number][], a = "", d = 0): Part => `<polygon class="${c}" points="${pts.map(p => p.map(r1).join(",")).join(" ")}"${at(a, d)}/>`;
const group = (inner: string, a = "", d = 0, extra = "") => `<g${extra}${at(a, d)}>${inner}</g>`;
const cover = (vb: string, inner: string) => `<svg class="v-pic cv" viewBox="${vb}" preserveAspectRatio="xMinYMid meet" aria-hidden="true">${inner}</svg>`;

/** A thick stroke drawn as a filled band of width w along the points (so the 3px outline rule holds at any size). */
function band(pts: [number, number][], w: number): string {
  const L: [number, number][] = [], R: [number, number][] = [];
  pts.forEach((p, i) => {
    const a = pts[Math.max(0, i - 1)]!, b = pts[Math.min(pts.length - 1, i + 1)]!;
    const dx = b[0] - a[0], dy = b[1] - a[1], n = Math.hypot(dx, dy) || 1, ox = (-dy / n) * (w / 2), oy = (dx / n) * (w / 2);
    L.push([p[0] + ox, p[1] + oy]); R.push([p[0] - ox, p[1] - oy]);
  });
  return `M${[...L, ...R.reverse()].map(p => p.map(r1).join(" ")).join(" L")} Z`;
}
/** points along a cubic Bézier */
const cubic = (p0: number[], p1: number[], p2: number[], p3: number[], n = 24): [number, number][] =>
  Array.from({ length: n + 1 }, (_, i) => {
    const t = i / n, u = 1 - t;
    return [u * u * u * p0[0]! + 3 * u * u * t * p1[0]! + 3 * u * t * t * p2[0]! + t * t * t * p3[0]!, u * u * u * p0[1]! + 3 * u * u * t * p1[1]! + 3 * u * t * t * p2[1]! + t * t * t * p3[1]!];
  });
const quad = (p0: number[], p1: number[], p2: number[], n = 24): [number, number][] =>
  Array.from({ length: n + 1 }, (_, i) => {
    const t = i / n, u = 1 - t;
    return [u * u * p0[0]! + 2 * u * t * p1[0]! + t * t * p2[0]!, u * u * p0[1]! + 2 * u * t * p1[1]! + t * t * p2[1]!];
  });
/**
 * A part that travels along a path to where it is drawn (the last point): its own keyframes, as translates from each
 * point to the end, played once. Plain transforms, so every browser plays it.
 */
function along(name: string, pts: [number, number][], secs: number, delay: number, inner: string, ease = "var(--m-ease)"): string {
  const [ex, ey] = pts[pts.length - 1]!, step = Math.max(1, Math.floor(pts.length / 12));
  const keys = pts.filter((_, i) => i % step === 0 || i === pts.length - 1)
    .map((p, i, a) => `${r1((i / (a.length - 1)) * 100)}%{transform:translate(${r1(p[0] - ex)}px,${r1(p[1] - ey)}px)}`).join("");
  return `<style>@keyframes ${name}{${keys}}@media (prefers-reduced-motion:no-preference){#app .v-pic.cv .${name}{animation:${name} ${secs}s ${ease} ${delay}s both}}</style><g class="${name}">${inner}</g>`;
}

// ---- K to 2nd grade ----------------------------------------------------------------------------------------------

const apple = (cx: number, cy: number, c: string, d: number) => group(
  path(c, `M${cx} ${cy - 14} C${cx - 6} ${cy - 20} ${cx - 22} ${cy - 18} ${cx - 22} ${cy} C${cx - 22} ${cy + 16} ${cx - 10} ${cy + 22} ${cx} ${cy + 18} C${cx + 10} ${cy + 22} ${cx + 22} ${cy + 16} ${cx + 22} ${cy} C${cx + 22} ${cy - 18} ${cx + 6} ${cy - 20} ${cx} ${cy - 14} Z`) +
  path("o", `M${cx} ${cy - 14} L${cx + 3} ${cy - 25}`) +
  path("s", `M${cx + 4} ${cy - 21} C${cx + 10} ${cy - 30} ${cx + 18} ${cy - 28} ${cx + 20} ${cy - 26} C${cx + 14} ${cy - 18} ${cx + 8} ${cy - 18} ${cx + 4} ${cy - 21} Z`),
  "drop", d);
// three apples come in one at a time: one, two, three
const COUNTING = cover("4 28 156 56", apple(28, 58, "m", 0) + apple(80, 58, "m", 0.3) + apple(132, 58, "s", 0.6));

const stick = (x: number, c: string, a = "", d = 0) => rect(c, x, 12, 7, 80, 3, a, d);
// ten sticks tied as one ten, then three loose ones join it
const PLACE_VALUE = cover("8 8 146 88",
  Array.from({ length: 10 }, (_, i) => stick(14 + i * 8, "m")).join("") + rect("s", 10, 44, 86, 14, 5, "pop", 0.2) +
  [0, 1, 2].map(i => stick(112 + i * 14, "s", "drop", 0.45 + i * 0.15)).join(""));

// the pencil slides along to lie on the ruler: how long is it?
const MEASURE = cover("6 22 148 74",
  rect("s", 8, 66, 144, 28, 5) + Array.from({ length: 8 }, (_, i) => line("k", 20 + i * 17.5, 66, 20 + i * 17.5, i % 2 ? 76 : 84)).join("") +
  group(poly("m", [[14, 26], [118, 26], [146, 40], [118, 54], [14, 54]]) + poly("s", [[118, 26], [146, 40], [118, 54]]) + poly("f", [[138, 36], [146, 40], [138, 44]]), "slide", 0.1));

// ---- 3rd and 4th grade -------------------------------------------------------------------------------------------

// a pizza cut in eighths; one slice comes away, clear of the rest, and its empty place shows (Review: fully clear)
const PIZZA = (() => {
  const cx = 56, cy = 54, R = 40, deg = (a: number) => (a * Math.PI) / 180;
  const pt = (a: number, r = R, ox = 0, oy = 0) => `${r1(cx + ox + r * Math.cos(deg(a)))} ${r1(cy + oy + r * Math.sin(deg(a)))}`;
  // the pizza less one eighth (from -45° to 0°), and that eighth on its own, moved out along its middle
  const rest = `M${cx} ${cy} L${pt(0)} A${R} ${R} 0 1 1 ${pt(-45)} Z`;
  const ox = 24 * Math.cos(deg(-22.5)), oy = 24 * Math.sin(deg(-22.5));
  const slice = `M${r1(cx + ox)} ${r1(cy + oy)} L${pt(-45, R, ox, oy)} A${R} ${R} 0 0 1 ${pt(0, R, ox, oy)} Z`;
  const cuts = [45, 90, 135, 180, 225, 270].map(a => line("o", cx, cy, cx + R * Math.cos(deg(a)), cy + R * Math.sin(deg(a)))).join("");
  const tops = ([[38, 40], [44, 74], [70, 78], [30, 60], [58, 30], [84, 66]] as const).map(([x, y]) => circ("mf", x, y, 4)).join("");
  return cover("12 4 142 92", path("e", `M${cx} ${cy} L${pt(-45)} A${R} ${R} 0 0 1 ${pt(0)} Z`) + path("s", rest) + cuts + tops +
    group(path("m", slice) + circ("s", cx + ox + 22, cy + oy - 6, 4), "", 0, ` class="cv-out" style="--dx:${r1(-ox)}px;--dy:${r1(-oy)}px"`));
})();

// an egg box: two rows of six, every cup filled (Review: rows of the same number); the eggs go in row by row
const EGGS = cover("6 18 148 70", rect("s", 8, 20, 144, 66, 10) +
  [0, 1].map(r => [0, 1, 2, 3, 4, 5].map(c => `<ellipse class="m" cx="${r1(22 + c * 23.2)}" cy="${38 + r * 30}" rx="9" ry="11"${at("pop", r * 0.35 + c * 0.05)}/>`).join("")).join(""));

// a dollar and some coins: dollars and cents
const MONEY = cover("6 20 150 66", rect("m", 8, 22, 96, 56, 6) + rect("s", 16, 30, 80, 40, 4) + circ("m", 56, 50, 13) +
  ([[118, 36, 14], [140, 52, 11], [120, 70, 11]] as const).map(([x, y, r], i) => group(circ("s", x, y, r) + circ("o", x, y, r - 4), "drop", 0.2 + i * 0.15)).join(""));

// ---- 6th to 8th grade --------------------------------------------------------------------------------------------

// a battery: three of its four cells fill, one after another (three quarters)
const BATTERY = cover("10 22 140 58", rect("s", 12, 24, 122, 54, 10) + rect("s", 134, 40, 12, 22, 3) +
  [0, 1, 2, 3].map(i => rect(i < 3 ? "m" : "g", 20 + i * 28.5, 32, 23, 38, 4, i < 3 ? "grow" : "", 0.15 + i * 0.2)).join(""));

// a thermometer: the liquid falls below the long zero tick (Review: well below), and it's freezing
const THERMO = cover("50 4 98 94", rect("s", 60, 6, 22, 72, 11) + circ("m", 71, 82, 15) +
  rect("mf", 66, 58, 10, 26, 2, "shrink", 0.1) +
  [16, 28, 40, 52, 64].map((y, i) => line("k", 82, y, i === 1 ? 100 : 90, y)).join("") +
  group([0, 60, 120].map(a => { const r = (a * Math.PI) / 180; return line("k2", 128 - 16 * Math.cos(r), 46 - 16 * Math.sin(r), 128 + 16 * Math.cos(r), 46 + 16 * Math.sin(r)); }).join(""), "pop", 0.6));

// a ball rolls up a ramp of equal steps: up the same for each step across (Review: no empty paths)
const RAMP = cover("8 12 144 82", poly("s", [[10, 92], [150, 92], [150, 14]]) + path("o", "M38 92 V77 H62 V64 H86 V50 H110 V37 H134 V23") +
  along("cv-ramp", [[26, 76], [74, 50]], 0.9, 0.1, circ("m", 74, 44, 12)));

// ---- 9th to 12th grade -------------------------------------------------------------------------------------------

// a ball thrown into a hoop: its path is a parabola, the shape of a quadratic
const HOOP_ARC = quad([18, 84], [72, -24], [126, 44]);
const HOOP = cover("4 2 152 98", path("dots", `M18 84 Q72 -24 126 44`) + rect("s", 140, 10, 12, 40, 3) + rect("s", 112, 44, 30, 5, 2) +
  path("o", "M116 49 L121 66 L133 66 L138 49") + along("cv-hoop", HOOP_ARC, 1.1, 0.1, circ("m", 126, 38, 9) + path("o", "M126 29 V47 M117 38 H135"), "linear"));

// a bicycle wheel turns once
const WHEEL = cover("34 6 92 92", group(circ("s", 80, 52, 44) + circ("e", 80, 52, 34) +
  Array.from({ length: 8 }, (_, i) => { const a = (i * Math.PI) / 4; return line("k", 80, 52, 80 + 34 * Math.cos(a), 52 + 34 * Math.sin(a)); }).join("") + circ("m", 80, 52, 8), "spin", 0));

// a branch that doubles at every fork: 1, 2, 4, 8 (Review: the leaves sit inside the picture)
const BRANCH = (() => {
  let o = "";
  const tips: [number, number][] = [];
  const go = (x: number, y: number, dx: number, depth: number) => {
    if (depth === 3) { tips.push([x, y]); return; }
    for (const s of [-1, 1]) {
      const x2 = x + s * dx, y2 = y - 22;
      o += path("f", band([[x, y], [x2, y2]], 6 - depth * 1.5), "grow", 0.1 + depth * 0.25);
      go(x2, y2, dx / 2, depth + 1);
    }
  };
  o += path("f", band([[80, 98], [80, 84]], 7));
  go(80, 84, 36, 0);
  return cover("28 6 104 94", o + tips.map(([x, y]) => circ("m", x, y - 4, 6, "pop", 0.85)).join(""));
})();

// a roller coaster: up, down, up; the car climbs to the top (Review: every post ends on the track)
const COASTER = (() => {
  const segs = [cubic([6, 30], [30, 30], [34, 84], [58, 84]), cubic([58, 84], [82, 84], [84, 20], [108, 20]), cubic([108, 20], [130, 20], [134, 64], [154, 64])];
  const pts = segs.flatMap((s, i) => (i ? s.slice(1) : s));
  const yAt = (x: number) => { for (let i = 1; i < pts.length; i++) if (pts[i]![0] >= x) { const [a, b] = [pts[i - 1]!, pts[i]!]; return a[1] + ((b[1] - a[1]) * (x - a[0])) / (b[0] - a[0]); } return pts[pts.length - 1]![1]; };
  const posts = [16, 40, 64, 88, 112, 136].map(x => line("k", x, 96, x, yAt(x) + 3)).join("");
  // the car rides from the start up to the top of the hill
  const ride = pts.filter(p => p[0] <= 108).map(p => [p[0], p[1] - 9] as [number, number]);
  return cover("2 4 156 94", posts + line("gl", 4, 96, 156, 96) + path("m", band(pts, 6)) +
    along("cv-coaster", ride, 1.4, 0.1, rect("m", 95, 4, 26, 13, 4) + circ("s", 101, 18, 3) + circ("s", 115, 18, 3), "ease-in-out"));
})();

// a speedometer: the needle swings up to how fast, right now
const SPEED = (() => {
  const cx = 80, cy = 86, P = (a: number, r: number) => `${r1(cx + r * Math.cos(a))} ${r1(cy + r * Math.sin(a))}`;
  const ticks = Array.from({ length: 9 }, (_, i) => { const a = Math.PI + (i * Math.PI) / 8, r2 = i % 2 ? 50 : 46; return line("k", cx + 56 * Math.cos(a), cy + 56 * Math.sin(a), cx + r2 * Math.cos(a), cy + r2 * Math.sin(a)); }).join("");
  const a0 = Math.PI, a1 = Math.PI + 1.86;
  const arc = `M${P(a0, 60)} A60 60 0 0 1 ${P(a1, 60)} L${P(a1, 54)} A54 54 0 0 0 ${P(a0, 54)} Z`;
  return cover("12 18 136 78", path("s", `M14 86 A66 66 0 0 1 146 86 Z`) + path("mf", arc, "grow", 0.1) + ticks +
    `<g transform="rotate(37 ${cx} ${cy})"><g data-a="sweep" style="--d:0.1s;transform-origin:${cx}px ${cy}px">${poly("f", [[cx - 3, cy], [cx + 3, cy], [cx + 1, cy - 50], [cx - 1, cy - 50]])}</g></g>` + circ("m", cx, cy, 8));
})();

// a glass fills from a tap, a little at a time
const GLASS = cover("36 2 112 96", rect("mf", 77, 14, 6, 42, 3, "pour", 0) + path("mf", "M45 56 L115 56 L108 96 L52 96 Z", "fill", 0.1) +
  path("o", "M38 22 L122 22 L108 96 L52 96 Z") + line("o", 44, 56, 116, 56, "fill", 0.1) + path("s", "M74 4 H146 V14 H86 V17 H74 Z"));

// a road that gets closer and closer to one point on the horizon
const ROAD = cover("2 22 156 78", rect("s", 4, 30, 152, 68, 6) + poly("e", [[34, 98], [126, 98], [81, 30], [79, 30]]) + line("gl", 4, 30, 156, 30) +
  ([[92, 78], [68, 58], [51, 45], [41, 38], [35.5, 34]] as const).map(([a, b], i) => line("o", 80, a, 80, b, "rise", 0.1 + i * 0.12)).join("") + circ("m", 80, 30, 5, "pop", 0.75));

export const COVERS: Record<string, string> = {
  "0:Counting": COUNTING,
  "1:Place value": PLACE_VALUE,
  "2:Measurement and data": MEASURE,
  "3:Fractions": PIZZA,
  "3:Multiplication and division": EGGS,
  "4:Decimals": MONEY,
  "6:Ratios and percents": BATTERY,
  "7:Integers": THERMO,
  "8:Functions and slope": RAMP,
  "9:Polynomials and quadratics": HOOP,
  "10:Circles": WHEEL,
  "11:Exponents and logs": BRANCH,
  "11:Polynomials": COASTER,
  "12:Derivatives": SPEED,
  "12:Integrals": GLASS,
  "12:Limits": ROAD,
};
