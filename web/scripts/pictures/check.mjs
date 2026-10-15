// Lesson pictures' automatic check (picture plan, G 2026-10-15): every lesson of the given picture families, many random
// problems, iPad and phone boxes, light and dark, every step. Needs the dev server (npm run dev) on PORT (default 5183).
//   node scripts/pictures/check.mjs tape [seeds=40] [lesson-id,...]
// Fails a picture that is off centre or leaves its box half empty at the end, has text under 14px on screen, has two
// labels touching, runs out of its box, or zooms more than 2x in one step.
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require("playwright");

const [families = "tape", seedsArg = "40", only] = process.argv.slice(2);
const FAM = new Set(families.split(","));
const SEEDS = +seedsArg;
const PORT = process.env.PORT || 5183;
/** the picture boxes: iPad sideways (square-ish), iPad upright and phones (wide strips) */
const BOXES = [[480, 440], [700, 300], [330, 200], [300, 150]];
const MIN_TEXT = +(process.env.MIN_TEXT ?? 13.5), MIN_FILL = +(process.env.MIN_FILL ?? 0.75), OFF_CENTRE = 0.04, MAX_STEP_ZOOM = 2.01;

const browser = await chromium.launch();
const fails = [];
let pictures = 0;
for (const scheme of ["light", "dark"]) {
  const page = await browser.newPage({ viewport: { width: 1000, height: 800 }, colorScheme: scheme, reducedMotion: "reduce" });
  await page.goto(`http://localhost:${PORT}/picframe.html`);
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
  const fill = Math.max((x1 - x0) / inner.w, (y1 - y0) / inner.h);
  const off = Math.max(Math.abs((x0 + x1) / 2 - (inner.x + inner.w / 2)) / inner.w, Math.abs((y0 + y1) / 2 - (inner.y + inner.h / 2)) / inner.h);
  return { small, touching, outside, fill, off, vbw: svg.viewBox.baseVal.width };
}
