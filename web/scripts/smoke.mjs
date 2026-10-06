/**
 * The smoke run: Review's manual sweep as one command. Opens the preview build (npm run build:preview first) on the
 * main routes at a phone in dark and a big iPad in light, each with More contrast off and on, and fails on:
 * anything cut off or spilling (Review's edge audit, scripts/smoke/audit.js), text under 11px, a lesson page that
 * scrolls, a Panel line without its corner, or the nav's wordmark missing, doubled or moving between pages.
 *   node scripts/smoke.mjs            (playwright from node_modules or NODE_PATH)
 */
import { createRequire } from "node:module";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const here = fileURLToPath(new URL(".", import.meta.url));
const AUDIT = readFileSync(here + "smoke/audit.js", "utf8");
const PAGE = "file://" + fileURLToPath(new URL("../dist-preview/index.html", import.meta.url));

/** audit kinds that mean something is cut off; the corner checks (concentric, outline-over) are reported, not failed */
const CLIPS = new Set(["content-cut", "spill", "viewport", "poke-clipped", "box", "mask"]);
/** a battery's fill (the cards' and the nav's lesson dot) is cut by its own rounded corners on purpose */
const CLIP_BY_DESIGN = /(battery > span\.fill|span\.ibat > i)$/;
const SIZES = [{ w: 390, h: 844, scheme: "dark" }, { w: 1366, h: 1024, scheme: "light" }];
const ROUTES = ["home", "year", "learn", "facts", "me", "settings", "grown-up", "welcome"];

const fails = [], notes = [];
const browser = await chromium.launch(process.env.CHROMIUM ? { executablePath: process.env.CHROMIUM } : {});
for (const { w, h, scheme } of SIZES) for (const contrast of [false, true]) {
  const ctx = await browser.newContext({ viewport: { width: w, height: h }, colorScheme: scheme });
  const p = await ctx.newPage();
  const tag = `${w} ${scheme}${contrast ? " contrast" : ""}`;
  p.on("pageerror", e => fails.push(`${tag}: page error ${e.message}`));
  await p.addInitScript(() => { let s = 42; Math.random = () => { s = (s * 16807) % 2147483647; return (s - 1) / 2147483646; }; });
  // a learner who picked 5th grade
  await p.goto(PAGE + "#/welcome"); await p.waitForTimeout(500);
  await p.getByRole("button", { name: /Start learning/ }).first().click(); await p.waitForTimeout(400);
  await p.getByRole("radio", { name: /5th grade/ }).first().click(); await p.waitForTimeout(300);
  const go = p.locator(".gdgo button").first(); if (await go.count()) await go.click();
  await p.waitForTimeout(800);
  // today's lesson, opened the way a learner would
  await p.evaluate(() => document.querySelector(".pitem.now")?.click()); await p.waitForTimeout(500);
  const lesson = await p.evaluate(() => location.hash.startsWith("#/learn/") ? location.hash : null);
  let markAt = null;
  for (const route of ROUTES) {
    const hash = route === "home" ? "#/" : route === "year" ? "#/year" : route === "learn" ? lesson : "#/" + route;
    if (!hash) { fails.push(`${tag}: no lesson link on home`); continue; }
    await p.goto(PAGE + hash); await p.waitForTimeout(700);
    if (contrast) await p.evaluate(() => { document.documentElement.dataset.contrast = "true"; });
    await p.evaluate(() => document.getAnimations().forEach(a => a.finish())); await p.waitForTimeout(100);
    const at = `${tag} ${route}`;
    await p.addScriptTag({ content: AUDIT });
    const r = await p.evaluate(() => {
      const flags = window.__ecAudit().flags;
      const shown = e => { const s = getComputedStyle(e); const b = e.getBoundingClientRect(); return s.visibility !== "hidden" && +s.opacity > 0 && b.width > 0 && b.height > 0; };
      const tiny = [];
      const walk = document.createTreeWalker(document.getElementById("app") ?? document.body, NodeFilter.SHOW_TEXT);
      for (let n; (n = walk.nextNode());) {
        const e = n.parentElement; if (!e || !n.textContent.trim() || !shown(e) || e.closest("svg,.vh,.visually-hidden,[aria-hidden=true]")) continue;
        const fs = parseFloat(getComputedStyle(e).fontSize); if (fs < 11) tiny.push(`${e.tagName.toLowerCase()}.${e.className} "${n.textContent.trim().slice(0, 20)}" ${fs}px`);
      }
      const corners = [...document.querySelectorAll("#app *")].filter(e => {
        const s = getComputedStyle(e); return s.outlineStyle === "solid" && parseFloat(s.outlineOffset) < 0 && shown(e) && !e.matches(":focus-visible");
      }).filter(e => parseFloat(getComputedStyle(e).borderTopLeftRadius) === 0).map(e => `${e.tagName.toLowerCase()}.${e.className}`);
      const marks = [...document.querySelectorAll(".itop .imark")].filter(shown).map(e => { const b = e.getBoundingClientRect(); return `${Math.round(b.x)},${Math.round(b.y)}`; });
      return { flags, tiny, corners, marks, scroll: document.documentElement.scrollHeight - innerHeight };
    });
    for (const f of r.flags.filter(f => !CLIP_BY_DESIGN.test(f.path ?? f.el)))
      (CLIPS.has(f.kind) ? fails : notes).push(`${at}: ${f.kind} ${f.el}${f.path ? " in " + f.path : ""}`);
    for (const t of r.tiny.slice(0, 5)) fails.push(`${at}: text under 11px ${t}`);
    for (const c of [...new Set(r.corners)]) fails.push(`${at}: Panel line without a corner ${c}`);
    if (route === "learn" && r.scroll > 1) fails.push(`${at}: the lesson page scrolls by ${r.scroll}px`);
    if (route !== "welcome") {
      if (r.marks.length !== 1) fails.push(`${at}: ${r.marks.length} wordmarks in the nav`);
      else if (markAt && r.marks[0] !== markAt) fails.push(`${at}: wordmark moved to ${r.marks[0]} (was ${markAt})`);
      else markAt = r.marks[0];
    }
  }
  await ctx.close();
}
await browser.close();
for (const n of [...new Set(notes)]) console.log("note  " + n);
for (const f of [...new Set(fails)]) console.log("FAIL  " + f);
console.log(fails.length ? `${new Set(fails).size} problems` : "smoke clean");
process.exit(fails.length ? 1 : 0);
