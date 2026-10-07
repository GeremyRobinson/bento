/**
 * THE MOTION GUARD (G 2026-10-07: "switching grades has stutter and hesitation", then "saw this area when coming into a
 * grade": a frame with the tiles half-faded and blurred). Every page change a learner makes, tapped on a touch screen
 * with the CPU slowed 4x (an older iPad), sampled every frame. Fails on: an error; a view transition (the page change is
 * the contents switcher's stage now, never a snapshot cross-fade); the contents, or anything blurred, still drawn over
 * the page once a page change from it has begun; a tile or page piece still changing size after the change starts (a
 * half-drawn layout); a page change that never plays; and a frame that holds the screen too long. Adapted from Review's
 * page-switch guard (review/page-switch-jank/motion-guard.mjs).
 */
const BUDGET = { frame: 400 }; // 4x-throttled milliseconds
const SIZES = [{ w: 1366, h: 1024 }, { w: 390, h: 844 }];
const SAVE = { grade: 5, chosen: true, xp: 1240, gxp: { 5: 1240 }, streak: 12, done: 9, last: new Date().toDateString(), lessons: {}, scores: {}, tests: {} };

export async function motionGuard({ browser, PAGE, fails, notes }) {
  for (const { w, h } of SIZES) {
    const ctx = await browser.newContext({ viewport: { width: w, height: h }, hasTouch: true });
    const p = await ctx.newPage();
    const errs = [];
    p.on("console", m => { if (m.type() === "error" && !/favicon|Failed to load resource/.test(m.text())) errs.push(m.text().slice(0, 160)); });
    p.on("pageerror", e => errs.push(e.message.slice(0, 160)));
    await p.addInitScript(save => {
      let s = 42; Math.random = () => { s = (s * 16807) % 2147483647; return (s - 1) / 2147483646; };
      try { if (!localStorage.getItem("stepmath")) localStorage.setItem("stepmath", JSON.stringify(save)); } catch {}
      window.__vt = 0;
      if (Document.prototype.startViewTransition) {
        const start = Document.prototype.startViewTransition;
        Document.prototype.startViewTransition = function (cb) { window.__vt++; return start.call(this, cb); };
      }
    }, SAVE);
    await p.goto(PAGE + "#/"); await p.waitForTimeout(1200);
    const cdp = await ctx.newCDPSession(p);
    await cdp.send("Emulation.setCPUThrottlingRate", { rate: 4 });
    const tap = l => async () => { await l.first().tap(); };
    const lesson = async () => { const c = p.locator(".pitem.now").first(); if (await c.isVisible()) await c.tap(); else await p.evaluate(() => { location.hash = "#/learn/g5-mult2"; }); };
    const level = name => tap(p.locator(".zlevels button", { hasText: name }));
    const open = tap(p.locator(".iplace"));
    // [name, act, a page change? (the contents' own opening and zoom levels are not)]
    const shelf = re => [["open the contents", open, false], ["All grades", level("All grades"), false], [`pick ${re.source.replace(/\W/g, "")}`, tap(p.getByRole("button", { name: re })), true]];
    const steps = [
      ...shelf(/^3rd grade:/), ...shelf(/^1st grade:/), ...shelf(/^10th grade/), ...shelf(/^5th grade:/),
      ["open the contents", open, false], ["Chapter", level("Chapter"), false], ["Year", level("Year"), false], ["Done", tap(p.locator(".zclose")), false],
      ["open the contents", open, false], ["All grades", level("All grades"), false], ["About Bento (landing)", tap(p.getByRole("button", { name: /About Bento/ })), true],
      ["browser back from the landing", () => p.goBack({ waitUntil: "commit" }), true],
      ["My Bento", tap(p.locator(".ime")), true], ["Back", tap(p.locator(".iback")), true],
      ["open a lesson", lesson, true], ["Back from the lesson", tap(p.locator(".iback")), true],
    ];
    for (const [name, act, page] of steps) {
      const at = `motion ${w}x${h} ${name}`;
      await p.evaluate(() => {
        // everything the old page drew is marked: once the new page starts, none of it may still be on screen (G
        // 2026-10-07: "the purple line", the last grade's colour left across the top of the new grade's book)
        for (const e of document.querySelectorAll("#app *")) if (!e.closest(".itop")) e.setAttribute("data-was", "");
        window.__vt = 0;
        const f = window.__frames = [], t0 = performance.now();
        const look = () => {
          const shown = e => { const s = getComputedStyle(e); return s.display !== "none" && s.visibility !== "hidden" && +s.opacity > 0.02; };
          // anything blurred that covers a good part of the screen (a small decorative blur, like the landing's Advanced teaser, is fine)
          const big = e => { const b = e.getBoundingClientRect(); return b.width * b.height > innerWidth * innerHeight * 0.25; };
          const blur = [...document.querySelectorAll("#app *, #app")].filter(e => /blur/.test(getComputedStyle(e).backdropFilter + getComputedStyle(e).filter) && shown(e) && big(e)).map(e => e.className.toString().split(" ")[0]);
          // the page's pieces keep their width and the book's tiles their size (a page may still grow below the fold)
          const sizes = [...[...document.querySelectorAll("#app>:not(.itop)")].map(e => `${e.className.toString().split(" ")[0]}:${e.offsetWidth}`),
            ...[...document.querySelectorAll(".bg-in>.bg-t")].map(e => `${e.className.toString().split(" ")[0]}:${e.offsetWidth}x${e.offsetHeight}`)].join(" ");
          const was = [...document.querySelectorAll("#app [data-was]")].filter(e => shown(e) && !e.closest(".zoom") && e.getClientRects().length).length;
          f.push({ t: performance.now() - t0, was, zoom: !!document.querySelector(".zoom"), blur, sizes, stage: !!document.querySelector("#app>.stage"), hash: location.hash });
          if (performance.now() - t0 < 1600) requestAnimationFrame(look);
        };
        requestAnimationFrame(look);
      });
      try { await act(); } catch (e) { fails.push(`${at}: could not ${e.message.split("\n")[0]}`); continue; }
      await p.waitForTimeout(2000);
      const r = await p.evaluate(() => ({ f: window.__frames, vt: window.__vt }));
      for (const e of errs.splice(0)) fails.push(`${at}: console ${e}`);
      if (r.vt) fails.push(`${at}: ${r.vt} view transition(s); the page change is the stage`);
      const f = r.f, gaps = f.map((x, i) => (i ? x.t - f[i - 1].t : 0)), worst = Math.round(Math.max(0, ...gaps));
      const worstAt = Math.round(f[gaps.indexOf(Math.max(0, ...gaps))]?.t ?? 0);
      // the budget holds from the tap until the change has played (its 500ms and a beat); work after that is the page's own
      const s0 = f.findIndex(x => x.stage), until = (s0 < 0 ? 0 : f[s0].t) + 700;
      const during = Math.round(Math.max(0, ...gaps.filter((g, i) => f[i].t <= until)));
      if (during > BUDGET.frame) fails.push(`${at}: one frame held the screen ${during}ms while the page changed (budget ${BUDGET.frame})`);
      if (page) {
        // from the first frame of the new page on: nothing over it, nothing blurred, nothing resizing
        const first = f.findIndex(x => x.stage), last = f[f.length - 1];
        if (first < 0) { fails.push(`${at}: the page change never played`); continue; }
        const after = f.slice(first);
        if (after.some(x => x.zoom)) fails.push(`${at}: the contents still drawn over the new page`);
        const old = after.find(x => x.was > 0);
        if (old) fails.push(`${at}: ${old.was} pieces of the old page still drawn ${Math.round(old.t - after[0].t)}ms into the new one`);
        const blurred = [...new Set(after.flatMap(x => x.blur))];
        if (blurred.length) fails.push(`${at}: blurred over the new page: ${blurred.join(", ")}`);
        // (a scrollbar arriving as a long page grows below the fold may narrow it by its own width; nothing more)
        const same = (a, b) => { const A = a.split(" "), B = b.split(" "); return A.length === B.length && A.every((x, i) => {
          const [n, v] = x.split(":"), [m, u] = B[i].split(":"); if (n !== m) return false;
          return v.includes("x") ? v === u : Math.abs(+v - +u) <= 20; }); };
        const moving = after.find(x => x.hash === last.hash && !same(x.sizes, last.sizes));
        if (moving) fails.push(`${at}: the page's layout still changing ${Math.round(moving.t - after[0].t)}ms into the change (${moving.sizes} → ${last.sizes})`);
        notes.push(`${at}: worst frame ${worst}ms, ending ${worstAt}ms after the tap`);
      }
    }
    await ctx.close();
  }
}
