/**
 * The smoke run: Review's manual sweep as one command. Opens the preview build (npm run build:preview first) on the
 * main routes at a phone, iPads and laptops (1024x768 to 1366x1024), each with More contrast off and on, and fails on:
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
const { motionGuard } = await import("./smoke/motion.mjs");

/** audit kinds that fail the run: anything cut off, text under an outline, and a nested surface whose corner isn't concentric */
const CLIPS = new Set(["content-cut", "spill", "viewport", "poke-clipped", "box", "mask", "ring", "scroll-cut", "outline-over", "concentric"]);
const SIZES = [{ w: 390, h: 844, scheme: "dark" }, { w: 375, h: 667, scheme: "light" }, { w: 1180, h: 820, scheme: "light" }, { w: 1366, h: 768, scheme: "dark" }, { w: 1366, h: 1024, scheme: "light" },
  { w: 1024, h: 768, scheme: "light" }, { w: 1280, h: 720, scheme: "dark" }];
/** containers meant to scroll (a long list; the book's chapters, and its plan on a short landscape screen where the
 *  picture keeps its room); anything else that scrolls inside itself is cut */
const SCROLLERS = ".fhome>.ftables, nav.slist.more, .sbento .b-chaps, .sbento .today, .sbento .tbody";
const ROUTES = ["home", "year", "today", "learn", "practice", "facts", "me", "settings", "grown-up", "welcome"];

const fails = [], notes = [];
const browser = await chromium.launch(process.env.CHROMIUM ? { executablePath: process.env.CHROMIUM } : {});
/** a 3rd-grader a few weeks in: scores (two weak), a grade check-up, a streak, and 3rd grade's nine chapters, so every
 *  tile carries its longest content */
const RETURNING = { grade: 3, chosen: true, xp: 1240, gxp: { 3: 1240 }, streak: 12, done: 9, last: new Date().toDateString(),
  lessons: { "g3-addsub": 2, "g3-round": 1, "g3-facts": 1, "g3-split": 1, "g3-divfacts": 1, "g3-mult10": 1, "g3-twostep": 1, "g3-unitfrac": 1 },
  scores: Object.fromEntries([["g3-addsub", 4], ["g3-round", 3], ["g3-facts", 1], ["g3-split", 1], ["g3-divfacts", 0], ["g3-mult10", 3], ["g3-twostep", 2], ["g3-unitfrac", 3]]
    .map(([id, l]) => [id, { last: l, best: l, pct: l * 25, date: Date.now(), mastered: l === 4 }])),
  tests: { "grade:3": { last: 3, best: 3, pct: 75, date: Date.now(), mastered: false } } };
for (const { w, h, scheme } of SIZES) for (const contrast of [false, true]) for (const learner of ["new", "returning"]) {
  const ctx = await browser.newContext({ viewport: { width: w, height: h }, colorScheme: scheme });
  const p = await ctx.newPage();
  const tag = `${w}x${h} ${scheme}${contrast ? " contrast" : ""} ${learner}`;
  p.on("pageerror", e => fails.push(`${tag}: page error ${e.message}`));
  await p.addInitScript(() => { let s = 42; Math.random = () => { s = (s * 16807) % 2147483647; return (s - 1) / 2147483646; }; });
  if (learner === "returning") {
    await p.addInitScript(save => { try { if (!localStorage.getItem("stepmath")) localStorage.setItem("stepmath", JSON.stringify(save)); } catch {} }, RETURNING);
    await p.goto(PAGE + "#/"); await p.locator(".pitem.now").first().waitFor({ timeout: 8000 }).catch(() => {});
  } else {
    // a learner who picked 5th grade
    await p.goto(PAGE + "#/welcome"); await p.waitForTimeout(500);
    await p.getByRole("button", { name: /Start learning/ }).first().click(); await p.waitForTimeout(400);
    await p.getByRole("radio", { name: /5th grade/ }).first().click(); await p.waitForTimeout(300);
    const go = p.locator(".gdgo button").first(); if (await go.count()) await go.click();
    await p.locator(".pitem.now").first().waitFor({ timeout: 8000 }).catch(() => {});
  }
  // today's lesson, opened the way a learner would
  await p.evaluate(() => document.querySelector(".pitem.now")?.click()); await p.waitForTimeout(500);
  const lesson = await p.evaluate(() => location.hash.startsWith("#/learn/") ? location.hash : null);
  let markAt = null;
  for (const route of ROUTES) {
    const hash = route === "home" ? "#/" : route === "year" ? "#/year" : route === "today" ? "#/year/today" : route === "learn" || route === "practice" ? lesson : "#/" + route;
    if (!hash) { fails.push(`${tag}: no lesson link on home`); continue; }
    await p.goto(PAGE + hash); await p.waitForTimeout(700);
    // practice: the lesson's own Try one
    if (route === "practice") { await p.getByRole("button", { name: /Try one/ }).first().click(); await p.waitForTimeout(900); }
    if (contrast) await p.evaluate(() => { document.documentElement.dataset.contrast = "true"; });
    await p.evaluate(() => document.getAnimations().forEach(a => { try { a.finish(); } catch {} })); await p.waitForTimeout(100);
    const at = `${tag} ${route}`;
    await p.addScriptTag({ content: AUDIT });
    const r = await p.evaluate((SCROLLERS) => {
      // a battery's fill is cut by the battery's own corners on purpose (the cards and the nav's lesson dot); only the
      // fill is exempt, so a tile that holds a battery is still checked. Inside a list meant to scroll, a row past the
      // edge is scrolled, not cut
      const flags = window.__ecAudit().flags.filter(f => !document.querySelector(`[data-ec="${f.id}"]`)?.closest(".battery>.fill,.ibat>i," + SCROLLERS));
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
      // a Panel that scrolls must draw its line as a border: scrolled rows paint over an inset outline (Review)
      for (const e of document.querySelectorAll("#app *")) {
        const s = getComputedStyle(e);
        if (/auto|scroll/.test(s.overflowY + s.overflowX) && s.outlineStyle === "solid" && parseFloat(s.outlineOffset) < 0 && shown(e) && !e.matches(":focus-visible"))
          flags.push({ kind: "outline-over", el: `${e.tagName.toLowerCase()}.${[...e.classList].join(".")} scrolls under its own outline` });
      }
      // a tile that scrolls inside itself: its last rows are cut with no sign they're there (scrollbars are hidden)
      for (const e of document.querySelectorAll("#app *")) {
        const s = getComputedStyle(e); if (!/auto|scroll/.test(s.overflowY + s.overflowX) || !shown(e) || e.matches(SCROLLERS)) continue;
        if (e.scrollHeight > e.clientHeight + 2 || e.scrollWidth > e.clientWidth + 2) flags.push({ kind: "scroll-cut", el: `${e.tagName.toLowerCase()}.${[...e.classList].join(".")} ${e.scrollHeight}/${e.clientHeight}` });
      }
      // the page never scrolls: html and body hide overflow, so measure how far any box reaches below the screen
      // (scrollHeight alone reads a few px over on a fitted lesson with nothing actually below the edge)
      const low = Math.max(0, ...[...document.querySelectorAll("#app *")].filter(shown).filter(e => !e.closest(SCROLLERS)).map(e => e.getBoundingClientRect().bottom));
      // the book's picture is the hero: on a wide screen it never shrinks to a sliver or an empty frame
      const pic = document.querySelector(".sbento .spreview");
      // (a phone keeps it too: never under the well's own 150px floor, never an empty frame)
      const picH = pic && shown(pic) ? Math.round(pic.getBoundingClientRect().height) : null;
      const picEmpty = picH != null && pic.classList.contains("empty");
      // bento tiles never overlap, and the plan's first row (Start) is fully inside Today, unscrolled
      const overlaps = [], tiles = [...document.querySelectorAll(".sbento>.bg-in>*")].filter(shown);
      for (const [i, a] of tiles.entries()) for (const b of tiles.slice(i + 1)) {
        const A = a.getBoundingClientRect(), B = b.getBoundingClientRect();
        const x = Math.min(A.right, B.right) - Math.max(A.left, B.left), y = Math.min(A.bottom, B.bottom) - Math.max(A.top, B.top);
        if (x > 1 && y > 1) overlaps.push(`${a.className} and ${b.className} by ${Math.round(Math.min(x, y))}px`);
      }
      const today = document.querySelector(".sbento .today"), first = today?.querySelector(".plan li");
      let startCut = 0;
      // (on a phone Start is pinned at Today's edge and the plan scrolls above it; the phone guard checks Start there)
      const pinned = document.querySelector(".sbento .tstart"), isPinned = pinned && getComputedStyle(pinned).display !== "none";
      if (today && first && shown(first) && !isPinned) {
        const T = today.getBoundingClientRect(), F = first.getBoundingClientRect();
        startCut = Math.round(Math.max(0, F.bottom - (T.bottom - today.clientTop) + today.scrollTop));
      }
      // a step row's number sits as far in from the pill's left end as from its top, and the step's first line is
      // centred on it (G 2026-10-07, "not aligned correctly")
      const steps = [];
      for (const e of document.querySelectorAll(".beat")) {
        const badge = e.querySelector(".badge"), first = e.querySelector(".say>:first-child");
        if (!badge || !first || !shown(badge)) continue;
        const P = (e.querySelector(":scope>button") ?? e).getBoundingClientRect(), B = badge.getBoundingClientRect(), F = first.getBoundingClientRect();
        const left = B.left - P.left, top = B.top - P.top, mid = (F.top + F.bottom) / 2 - (B.top + B.bottom) / 2;
        if (Math.abs(left - top) > 1 || (F.height <= B.height + 1 && Math.abs(mid) > 1)) steps.push(`"${e.textContent.trim().slice(0, 20)}" in ${left.toFixed(1)}/${top.toFixed(1)}, line off ${mid.toFixed(1)}`);
      }
      // a chapter's lesson panel: the same gap between rows as round its edge, so a highlighted row never touches its
      // neighbour or the panel (G 2026-10-07)
      const nests = [];
      for (const pn of document.querySelectorAll(".sgroup.open .sgroup-panel")) {
        const rows = [...pn.children].filter(shown); if (!rows.length) continue;
        const P = pn.getBoundingClientRect(), R = rows.map(r => r.getBoundingClientRect());
        const gaps = [R[0].left - P.left, P.right - R[0].right, R[0].top - P.top, P.bottom - R.at(-1).bottom, ...R.slice(1).map((r, i) => r.top - R[i].bottom)];
        if (Math.max(...gaps) - Math.min(...gaps) > 1) nests.push(gaps.map(g => g.toFixed(1)).join("/"));
        // every lesson row the same height, picked or not, each with its trailing label
        const hs = R.map(r => Math.round(r.height));
        if (Math.max(...hs) - Math.min(...hs) > 1) nests.push(`row heights ${hs.join("/")}`);
        for (const r of rows) if (!r.disabled && ![...r.children].slice(2).some(shown)) nests.push(`"${r.textContent.trim().slice(0, 20)}" has no label`);
      }
      // a chapter's name on the book home is never cut mid-word (its own line clamp only ever ends a whole line)
      // on a phone the picture stays the biggest tile and Today's pinned Start is whole (Design 2026-10-07)
      const phone = [], tday = document.querySelector(".sbento .today"), tstart = document.querySelector(".sbento .tstart");
      if (innerWidth < 700 && tday && shown(tday)) {
        const area = e => { const b = e.getBoundingClientRect(); return b.width * b.height; };
        if (pic && shown(pic) && area(pic) <= area(tday)) phone.push(`the picture (${Math.round(area(pic))}) is not bigger than Today (${Math.round(area(tday))})`);
        if (tstart) {
          const S = tstart.getBoundingClientRect(), T = tday.getBoundingClientRect();
          if (!shown(tstart) || S.top < T.top || S.bottom > T.bottom - tday.clientTop || S.bottom > innerHeight) phone.push("Today's Start is not fully visible");
        }
        // the plan shows at least one whole row, and no row runs past the plan's sides (Review Book home #2)
        const tbody = tday.querySelector(".tbody");
        if (tbody && getComputedStyle(tbody).overflowY === "auto") {
          const B = tbody.getBoundingClientRect(), rows = [...tbody.querySelectorAll(".pitem")].filter(shown).map(e => e.getBoundingClientRect());
          if (rows.length && !rows.some(r => r.top >= B.top - 0.5 && r.bottom <= B.bottom + 0.5)) phone.push("Today's plan shows no whole row");
          const side = rows.find(r => r.left < B.left - 0.5 || r.right > B.right + 0.5);
          if (side) phone.push(`a plan row runs past Today's sides by ${Math.round(Math.max(B.left - side.left, side.right - B.right))}px`);
        }
      }
      // Today comes after the two number tiles: its top is below both (Review Book home #3: DOM order alone passed)
      if (tday && shown(tday)) {
        const T = tday.getBoundingClientRect().top;
        for (const n of document.querySelectorAll(".sbento :is(.b-stats,.b-streak)"))
          if (shown(n) && T < n.getBoundingClientRect().top - 0.5) phone.push(`Today sits above the ${n.classList.contains("b-stats") ? "lessons done" : "days in a row"} tile`);
      }
      const chapCut = [...document.querySelectorAll(".bchap b")].filter(shown).filter(b => b.scrollWidth > b.clientWidth + 1).map(b => b.textContent);
      return { flags, tiny, corners, marks, picH, picEmpty, overlaps, startCut, steps, nests, chapCut, phone, scroll: Math.round(low - innerHeight) };
    }, SCROLLERS);
    for (const f of r.flags)
      (CLIPS.has(f.kind) ? fails : notes).push(`${at}: ${f.kind} ${f.el}${f.path ? " in " + f.path : ""}`);
    for (const t of r.tiny.slice(0, 5)) fails.push(`${at}: text under 11px ${t}`);
    for (const c of [...new Set(r.corners)]) fails.push(`${at}: Panel line without a corner ${c}`);
    if (r.picH != null && (r.picH < (w >= 900 ? 200 : 150) || r.picEmpty)) fails.push(`${at}: the book's picture is ${r.picEmpty ? "empty" : r.picH + "px tall"}`);
    for (const o of r.overlaps) fails.push(`${at}: tiles overlap: ${o}`);
    if (r.startCut > 1) fails.push(`${at}: the plan's first row is cut by ${r.startCut}px`);
    for (const ph of r.phone) fails.push(`${at}: ${ph}`);
    if (r.chapCut.length) fails.push(`${at}: chapter names cut mid-word: ${r.chapCut.join(", ")}`);
    for (const st of r.steps) fails.push(`${at}: step row not aligned: ${st}`);
    for (const n of r.nests) fails.push(`${at}: chapter rows uneven (gaps left/right/top/bottom/between, heights, labels): ${n}`);
    if ((route === "learn" || route === "practice") && r.scroll > 1) fails.push(`${at}: the lesson page scrolls by ${r.scroll}px`);
    if (route !== "welcome") {
      if (r.marks.length !== 1) fails.push(`${at}: ${r.marks.length} wordmarks in the nav`);
      else if (markAt && r.marks[0] !== markAt) fails.push(`${at}: wordmark moved to ${r.marks[0]} (was ${markAt})`);
      else markAt = r.marks[0];
    }
  }
  await ctx.close();
}
await motionGuard({ browser, PAGE, fails, notes });
await browser.close();
for (const n of [...new Set(notes)]) console.log("note  " + n);
for (const f of [...new Set(fails)]) console.log("FAIL  " + f);
console.log(fails.length ? `${new Set(fails).size} problems` : "smoke clean");
process.exit(fails.length ? 1 : 0);
