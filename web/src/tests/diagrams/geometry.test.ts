// The geometry and data picture families: shapes follow the problem's values, and on every problem `generate`
// can make, at every beat, labels stay on the canvas and never sit on top of each other.
import { lessonById } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";
import type { SceneDiagram, SceneItem } from "../../explanations/diagrams/scene/schema";
import { textBox } from "../../explanations/diagrams/geo/kit";
import { buildRightTriangle, triangleCorners } from "../../explanations/diagrams/right-triangle/build";
import { buildAngle } from "../../explanations/diagrams/angle/build";
import { buildTriangleAngles } from "../../explanations/diagrams/triangle-angles/build";
import { buildSimilar } from "../../explanations/diagrams/similar/build";
import { buildCylinder } from "../../explanations/diagrams/cylinder/build";
import { buildMeanBars, buildMedianBars } from "../../explanations/diagrams/bars/build";
import { buildPolygonSplit } from "../../explanations/diagrams/polygon-split/build";
import { buildMarbleBag } from "../../explanations/diagrams/marbles/build";

const FAMILY = ["g8-cyl", "g8-cone", "g7-prob", "g11-comb", "g6-mean", "g9-median", "g8-tri", "g10-exterior", "g10-similar", "g8-pyth", "g8-leg",
  "g10-special", "g10-trig", "g4-angles", "g7-angles", "g7-circum", "g7-circarea", "g10-sector", "g10-arc", "g12-rad", "g12-deg", "g12-unit", "g10-polygon"];

const shownAt = (i: SceneItem, b: number) => (i.from ?? 0) <= b && (i.until == null || b <= i.until);
const near = (a: number, b: number, tol = 1) => Math.abs(a - b) <= tol;
/** End points of each command in a path the families write (M, L, Q, A, Z). */
const pathPoints = (d: string): number[][] =>
  [...d.matchAll(/([MLQA])([^MLQAZ]*)/g)].map(m => { const n = m[2]!.trim().split(/\s+/).map(Number); return n.slice(-2); });

describe.each(FAMILY)("%s pictures", id => {
  const lesson = lessonById(id)!;
  const rng = createRng(20261002);
  const problems = [lesson.reference, ...Array.from({ length: 150 }, (_, i) => lesson.generate(rng, i))];

  it("keep every label on the canvas and apart from the others, at every beat", () => {
    for (const p of problems) {
      const ex = lesson.explain(p, lesson.answers(p));
      const d = ex.diagram as SceneDiagram;
      expect(d.kind).toBe("scene");
      for (let b = 0; b < ex.timeline.length; b++) {
        // the box drawn here is a tablet's: a phone's short-box stand-ins (.shortonly) never show beside what they replace
        const texts = d.items.filter(i => i.type === "text" && shownAt(i, b) && !/\bshortonly\b/.test(i.cls ?? "")) as Extract<SceneItem, { type: "text" }>[];
        const boxes = texts.map(t => ({ t: t.text, ...textBox(t) }));
        for (const x of boxes) {
          expect(x.x0, `${id} ${JSON.stringify(p)} "${x.t}" left`).toBeGreaterThanOrEqual(0);
          expect(x.y0, `${id} "${x.t}" top`).toBeGreaterThanOrEqual(0);
          expect(x.x1, `${id} "${x.t}" right`).toBeLessThanOrEqual(d.width);
          expect(x.y1, `${id} "${x.t}" bottom`).toBeLessThanOrEqual(d.height);
        }
        for (let i = 0; i < boxes.length; i++) for (let j = i + 1; j < boxes.length; j++) {
          const A = boxes[i]!, B = boxes[j]!;
          const overlap = Math.min(A.x1, B.x1) - Math.max(A.x0, B.x0) > 1 && Math.min(A.y1, B.y1) - Math.max(A.y0, B.y0) > 1;
          expect(overlap, `${id} ${JSON.stringify(p)} beat ${b}: "${A.t}" overlaps "${B.t}"`).toBe(false);
        }
        // shapes stay on the canvas too
        for (const it of d.items.filter(i => shownAt(i, b) && i.type !== "text")) {
          const pts = it.type === "path" ? pathPoints(it.d) : it.type === "polygon" ? it.points : it.type === "line" ? [[it.x1, it.y1], [it.x2, it.y2]] : it.type === "rect" ? [[it.x, it.y], [it.x + it.w, it.y + it.h]] : it.type === "circle" ? [[it.cx - it.r, it.cy - it.r], [it.cx + it.r, it.cy + it.r]] : [];
          for (const [x, y] of pts) {
            expect(x! >= -0.5 && x! <= d.width + 0.5 && y! >= -0.5 && y! <= d.height + 0.5, `${id} ${it.cls} point ${x},${y}`).toBe(true);
          }
        }
      }
    }
  });
});

describe("geometry follows the values", () => {
  it("a right triangle keeps its legs' ratio and its right angle", () => {
    for (const [a, b] of [[5, 12], [12, 5], [7, 24], [3, 4], [1, Math.sqrt(3)]] as const) {
      const [A, B, C] = triangleCorners(buildRightTriangle({ a, b, alt: "t", squares: { a: { from: 0, top: [], area: "", areaFrom: 0 } } }));
      const across = Math.hypot(B![0] - A![0], B![1] - A![1]), up = Math.hypot(C![0] - A![0], C![1] - A![1]);
      expect(near(up / across, a / b, 0.01)).toBe(true);
      expect(near(A![1], B![1], 0.1) && near(A![0], C![0], 0.1)).toBe(true);
    }
  });

  it("a right triangle's squares have the sides' lengths", () => {
    const d = buildRightTriangle({ a: 5, b: 12, alt: "t", squares: { a: { from: 0, top: [], area: "25", areaFrom: 0 }, b: { from: 0, top: [], area: "144", areaFrom: 0 }, c: { from: 0, top: [], area: "169", areaFrom: 0 } } });
    const sides = d.items.filter(i => i.type === "path" && /cell|sq/.test(i.cls ?? "")).map(i => {
      const pts = pathPoints((i as { d: string }).d);
      return Math.hypot(pts[1]![0]! - pts[0]![0]!, pts[1]![1]! - pts[0]![1]!);
    });
    expect(near(sides[0]! / sides[1]!, 5 / 12, 0.01)).toBe(true);
    expect(near(sides[2]! / sides[1]!, 13 / 12, 0.01)).toBe(true);
  });

  it("an angle is drawn at its size", () => {
    const d = buildAngle({ total: 180, part: 70, wholeBeat: 1, missingBeat: 2, wholeNote: "", alt: "a" });
    const arm = d.items.find(i => i.type === "path" && i.cls === "ln" && !(i as { d: string }).d.includes("A"))!;
    const [p, q] = pathPoints((arm as { d: string }).d);
    expect(near((Math.atan2(p![1]! - q![1]!, q![0]! - p![0]!) * 180) / Math.PI, 70, 0.5)).toBe(true);
  });

  it("a triangle's corners have the given angles", () => {
    const d = buildTriangleAngles({ left: 100, right: 30, labels: { left: [], right: [], top: [] }, alt: "t" });
    const [P1, P2, P3] = pathPoints((d.items[0] as { d: string }).d) as [number, number][];
    const ang = (v: [number, number], p: [number, number], q: [number, number]) => {
      const a1 = Math.atan2(p[1] - v[1], p[0] - v[0]), a2 = Math.atan2(q[1] - v[1], q[0] - v[0]);
      let x = Math.abs(a1 - a2) * 180 / Math.PI; if (x > 180) x = 360 - x; return x;
    };
    expect(near(ang(P1!, P2!, P3!), 100, 0.5)).toBe(true);
    expect(near(ang(P2!, P1!, P3!), 30, 0.5)).toBe(true);
  });

  it("similar triangles are k times apart", () => {
    const d = buildSimilar({ a: 4, b: 6, k: 2.5, bigA: "10", bigB: "15", factorBeat: 1, missingBeat: 2, factorNote: "", missingNote: "", alt: "s" });
    const [small, big] = d.items.filter(i => i.type === "path").map(i => pathPoints((i as { d: string }).d));
    expect(near((big![1]![0]! - big![0]![0]!) / (small![1]![0]! - small![0]![0]!), 2.5, 0.02)).toBe(true);
  });

  it("a cylinder is as wide and tall as its radius and height say", () => {
    for (const [r, h] of [[1, 10], [6, 2], [3, 4]] as const) {
      const d = buildCylinder({ cone: false, r, h, notes: [], baseBeat: 1, fillBeat: 2, alt: "c" });
      const side = d.items.find(i => i.type === "path" && i.cls === "ln" && (i as { d: string }).d.split("M").length === 3)!;
      const [p0, p1, p2] = pathPoints((side as { d: string }).d);
      expect(near(Math.abs(p1![1]! - p0![1]!) / Math.abs(p2![0]! - p0![0]!), h / (2 * r), 0.02)).toBe(true);
    }
  });

  it("bars are as tall as their values, and level out to the mean", () => {
    const d = buildMeanBars({ values: [4, 6, 8], mean: 6, sumBeat: 1, countBeat: 2, shareBeat: 3, sumNote: "", countNote: "", shareNote: "", alt: "m" });
    const bars = d.items.filter(i => i.type === "rect") as Extract<SceneItem, { type: "rect" }>[];
    const before = bars.filter(b => b.until === 2).map(b => b.h), after = bars.filter(b => b.from === 3).map(b => b.h);
    expect(near(before[0]! / before[2]!, 4 / 8, 0.01)).toBe(true);
    expect(after.every(h => near(h, (before[2]! * 6) / 8, 0.2))).toBe(true);
    const m = buildMedianBars({ values: [7, 2, 9], countBeat: 1, sortBeat: 2, medianBeat: 3, countNote: "", spotNote: "", medianNote: "", alt: "m" });
    const sortedBars = (m.items.filter(i => i.type === "rect" && i.from === 2) as Extract<SceneItem, { type: "rect" }>[]).sort((a, b) => a.x - b.x).map(b => b.h);
    expect(sortedBars[0]! < sortedBars[1]! && sortedBars[1]! < sortedBars[2]!).toBe(true);
  });

  it("a polygon makes n − 2 triangles and a bag shows every marble", () => {
    for (const n of [5, 12, 20]) {
      const d = buildPolygonSplit({ n, trianglesBeat: 1, angleBeat: 3, notes: [], angleText: "x", alt: "p" });
      expect(d.items.filter(i => (i.cls ?? "").startsWith("tri")).length).toBe(n - 2);
    }
    const bag = buildMarbleBag({ groups: [{ n: 3, cls: "red", name: "red" }, { n: 8, cls: "blue", name: "blue" }], want: 0, wantBeat: 1, allBeat: 2, chanceBeat: 3, wantNote: "", allNote: "", chanceNote: "", alt: "b" });
    expect(bag.items.filter(i => i.type === "circle" && !(i.cls ?? "").includes("ring")).length).toBe(11);
  });
});
