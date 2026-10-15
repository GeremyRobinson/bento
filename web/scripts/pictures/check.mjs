// Lesson pictures' automatic check (picture plan, G 2026-10-15): every lesson of the given picture families, many random
// problems, iPad and phone boxes, light and dark, every step. Needs the dev server (npm run dev) on PORT (default 5183).
//   node scripts/pictures/check.mjs tape [seeds=40] [lesson-id,...]
// Fails a picture that is off centre or leaves its box half empty at the end, has text under 14px on screen, has two
// labels touching, a line through text or text filling its part edge to edge, runs out of its box, or zooms more than 2x
// in one step. The page it draws in is scripts/pictures/picframe.html.
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require("playwright");

const [families = "tape", seedsArg = "40", only] = process.argv.slice(2);
const FAM = new Set(families.split(","));
const SEEDS = +seedsArg;
const PORT = process.env.PORT || 5183;
/** the picture boxes: iPad sideways (square-ish), iPad upright, the lesson's box on a 390 and a 375×667 phone, and
 *  phones' wide strips */
const BOXES = [[480, 440], [700, 300], [330, 310], [315, 210], [330, 200], [300, 150]];
const MIN_TEXT = +(process.env.MIN_TEXT ?? 13.5), MIN_FILL = +(process.env.MIN_FILL ?? 0.75), OFF_CENTRE = 0.04, MAX_STEP_ZOOM = 2.01;

const browser = await chromium.launch();
const fails = [];
let pictures = 0;
for (const scheme of ["light", "dark"]) {
  const page = await browser.newPage({ viewport: { width: 1000, height: 800 }, colorScheme: scheme, reducedMotion: "reduce" });
  await page.goto(`http://localhost:${PORT}/scripts/pictures/picframe.html`);
  await page.waitForFunction(() => window.pf);
  await page.evaluate(() => document.fonts.ready);
  const ids = only ? only.split(",") : await page.evaluate(() => pf.ids());
  for (const id of ids) {
    const first = await page.evaluate(id => pf.beats(id, 0), id);
    if (!first || !FAM.has(first.family)) continue;
    // the lesson's worked problem, then random ones (scheme 2 checks fewer: colours don't move anything)
    for (let seed = 0; seed <= (scheme === "light" ? SEEDS : Math.ceil(SEEDS / 4)); seed++) {
      const info = await page.evaluate(([id, s]) => pf.beats(id, s), [id, seed]);
      if (!info) continue;
      for (const [w, h] of BOXES) {
        pictures++;
        let prevW = 0;
        for (let at = 0; at < info.n; at++) {
          await page.evaluate(s => pf.show(s), { id, w, h, prac: false, seed, at });
          await page.waitForTimeout(at ? 30 : 120);
          const m = await page.evaluate(measure, MIN_TEXT);
          const where = `${id} seed ${seed} ${w}×${h} ${scheme} step ${at + 1}/${info.n}`;
          if (!m) { fails.push(`${where}: nothing drawn`); continue; }
          for (const t of m.small) fails.push(`${where}: text "${t.text}" is ${t.px}px`);
          for (const [a, b] of m.touching) fails.push(`${where}: "${a}" touches "${b}"`);
          for (const o of m.outside) fails.push(`${where}: "${o}" runs out of the box`);
          for (const t of m.crossed) fails.push(`${where}: a line runs through "${t}"`);
          for (const t of m.spill) fails.push(`${where}: "${t}" fills its part edge to edge`);
          if (prevW && prevW / m.vbw > MAX_STEP_ZOOM) fails.push(`${where}: zooms ${(prevW / m.vbw).toFixed(2)}x in one step`);
          prevW = m.vbw;
          if (at === info.n - 1) {
            if (m.fill < MIN_FILL) fails.push(`${where}: the finished picture fills ${Math.round(m.fill * 100)}% of the box`);
            if (m.off > OFF_CENTRE) fails.push(`${where}: off centre by ${Math.round(m.off * 100)}% of the box`);
          }
        }
      }
    }
  }
  await page.close();
}
await browser.close();
const uniq = [...new Set(fails)];
console.log(`${pictures} pictures checked, ${uniq.length} problems`);
for (const f of uniq.slice(0, 200)) console.log("  " + f);
process.exit(uniq.length ? 1 : 0);

/** in the page: what the picture shows on screen */
function measure(MIN) {
  const box = document.querySelector(".v-ppic"), svg = box?.querySelector("svg.viz-svg");
  if (!box || !svg) return null;
  const B = box.getBoundingClientRect(), pad = 10;
  const inner = { x: B.x + pad, y: B.y + pad, w: B.width - 2 * pad, h: B.height - 2 * pad };
  const shown = [...svg.querySelectorAll("rect,line,circle,path,polygon,text")].filter(e => {
    if (e.closest("defs") || e.closest(".pic-grid")) return false;
    const cs = getComputedStyle(e);
    if (cs.display === "none" || cs.visibility === "hidden" || +cs.opacity === 0) return false;
    const r = e.getBoundingClientRect();
    return r.width > 0 || r.height > 0;
  });
  if (!shown.length) return null;
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  const outside = [];
  for (const e of shown) {
    const r = e.getBoundingClientRect();
    x0 = Math.min(x0, r.left); y0 = Math.min(y0, r.top); x1 = Math.max(x1, r.right); y1 = Math.max(y1, r.bottom);
    if (r.left < B.left - 1 || r.top < B.top - 1 || r.right > B.right + 1 || r.bottom > B.bottom + 1) outside.push(e.textContent || e.tagName);
  }
  const texts = shown.filter(e => e.tagName === "text").map(e => {
    const r = e.getBoundingClientRect(), cs = getComputedStyle(e);
    // on-screen size: the font size in drawing units times the drawing's scale
    const ctm = e.getScreenCTM(), px = parseFloat(cs.fontSize) * (ctm ? Math.hypot(ctm.a, ctm.b) : 1);
    return { text: e.textContent, px: Math.round(px * 10) / 10, r };
  });
  const small = texts.filter(t => t.px < MIN).map(({ text, px }) => ({ text, px }));
  const touching = [];
  for (let i = 0; i < texts.length; i++) for (let j = i + 1; j < texts.length; j++) {
    const a = texts[i].r, b = texts[j].r;
    // glyph boxes carry line spacing: shrink each by 15% of its height before testing
    const ia = a.height * 0.15, ib = b.height * 0.15;
    const w = Math.min(a.right, b.right) - Math.max(a.left, b.left), h = Math.min(a.bottom - ia, b.bottom - ib) - Math.max(a.top + ia, b.top + ib);
    if (w > 1 && h > 1) touching.push([texts[i].text, texts[j].text]);
  }
  // a line (a guide, a knife cut, a leader) never runs through text (Review 31ee827: g6-pctwhole's guide through "100%")
  const crossed = [];
  for (const l of shown.filter(e => e.tagName === "line")) {
    const r = l.getBoundingClientRect();
    for (const t of texts) {
      const a = t.r, ia = a.height * 0.15;
      if (Math.min(r.right, a.right) - Math.max(r.left, a.left) > 0.5 && Math.min(r.bottom, a.bottom - ia) - Math.max(r.top, a.top + ia) > 0.5) crossed.push(t.text);
    }
  }
  // text sitting in a part stays inside it (Review 31ee827: the chips' "10"s filled them edge to edge on phones)
  const spill = [];
  const parts = shown.filter(e => e.tagName === "rect").map(e => e.getBoundingClientRect());
  for (const t of texts) {
    const a = t.r, cx = (a.left + a.right) / 2, cy = (a.top + a.bottom) / 2, ia = a.height * 0.15;
    const p = parts.filter(r => cx > r.left && cx < r.right && cy > r.top && cy < r.bottom).sort((x, y) => x.width * x.height - y.width * y.height)[0];
    if (p && (a.left < p.left + 2 || a.right > p.right - 2 || a.top + ia < p.top || a.bottom - ia > p.bottom)) spill.push(t.text);
  }
  const fill = Math.max((x1 - x0) / inner.w, (y1 - y0) / inner.h);
  const off = Math.max(Math.abs((x0 + x1) / 2 - (inner.x + inner.w / 2)) / inner.w, Math.abs((y0 + y1) / 2 - (inner.y + inner.h / 2)) / inner.h);
  return { small, touching, outside, crossed, spill, fill, off, vbw: svg.viewBox.baseVal.width };
}
