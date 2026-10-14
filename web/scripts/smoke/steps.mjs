/**
 * THE STEP WALK (Review's 5th grade full pass, 2026-10-13, blocker 1: on a phone the keypad and Check went off the
 * bottom of the screen at a fraction lesson's last step, so the child couldn't answer). On every phone size, every
 * lesson's practice is walked like a child would: the first three problems (the third is the story problem), every step
 * answered right from the app's own step model. Before each answer the step's Check button (or, on a tap step, every
 * choice) must sit inside the screen and be the thing a tap there would hit. Adapted from Review's walk.mjs.
 *
 * Runs on the dev server (it reads the live session and imports the step model from /src):
 *   npm run smoke:steps            every lesson
 *   npm run smoke:steps -- 5 g4-mixed   5th grade and one more lesson
 */
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const web = fileURLToPath(new URL("../..", import.meta.url));

export const PHONES = [{ w: 390, h: 844, scheme: "dark" }, { w: 375, h: 667, scheme: "light" }, { w: 360, h: 780, scheme: "dark" }];
const PROBLEMS = 3;

/** the current step's answer, from the live session (React state) and the app's own step model */
const want = p => p.evaluate(async () => {
  const P = await import("/src/engine/session/practice.ts"), E = await import("/src/engine/evaluation/steps.ts");
  const rootEl = document.getElementById("root") ?? document.getElementById("app");
  const k = Object.keys(rootEl).find(x => x.startsWith("__reactContainer"));
  const isSession = x => x && typeof x === "object" && Array.isArray(x.items) && "step" in x && "mode" in x;
  const container = rootEl[k], found = [], st = [container.stateNode?.current ?? container], seen = new Set(); // the committed tree, not its alternate
  for (let guard = 0; st.length && guard < 200000; guard++) {
    const f = st.pop(); if (!f || seen.has(f)) continue; seen.add(f);
    for (let h = f.memoizedState, c = 0; h && typeof h === "object" && c < 400; h = h.next, c++) {
      const v = h.memoizedState; for (const x of [v, v?.run, v?.progress?.run]) if (isSession(x)) found.push(x);
    }
    const pv = f.memoizedProps?.value; if (pv && typeof pv === "object") for (const x of [...Object.values(pv), pv.progress?.run]) if (isSession(x)) found.push(x);
    if (f.child) st.push(f.child); if (f.sibling) st.push(f.sibling);
  }
  // stale copies linger in memoized state: the live session is the one furthest along
  const far = x => x.i * 1000 + x.step * 10 + (x.solved ? 5 : 0);
  const sess = found.sort((a, b) => far(b) - far(a))[0];
  if (!sess) return { none: "no session" };
  if (sess.solved) return { solved: true, i: sess.i };
  if (sess.pick) return { pick: sess.pick.right, i: sess.i };
  const step = P.currentStep(sess); if (!step) return { none: "no step" };
  if (step.choices) return { choice: step.choices[Object.values(E.expectedValues(step))[0]], label: step.label, i: sess.i };
  return { slots: E.expectedValues(step), label: step.label, i: sess.i };
});

/** where a control sits: inside the screen, and the element a tap at its middle would land on */
const reach = (p, sel) => p.evaluate(sel => [...document.querySelectorAll(sel)].filter(e => e.getClientRects().length).map(e => {
  const r = e.getBoundingClientRect(), x = r.left + r.width / 2, y = r.top + r.height / 2;
  const inside = r.top >= 0 && r.left >= 0 && r.bottom <= innerHeight + 0.5 && r.right <= innerWidth + 0.5;
  const hit = inside ? document.elementFromPoint(x, y) : null;
  return { text: (e.textContent ?? "").trim().slice(0, 20), bottom: Math.round(r.bottom), inside, onTop: !!hit && (hit === e || e.contains(hit)) };
}), sel);

export async function stepWalk({ browser, base, lessons, fails, notes }) {
  let walked = 0;
  for (const { w, h, scheme } of PHONES) {
    const ctx = await browser.newContext({ viewport: { width: w, height: h }, colorScheme: scheme, reducedMotion: "reduce" });
    for (const { id, grade } of lessons) {
      const p = await ctx.newPage(), tag = `steps ${w}x${h} ${id}`;
      p.on("pageerror", e => fails.push(`${tag}: page error ${e.message.slice(0, 160)}`));
      await p.addInitScript(g => {
        let s = 42; Math.random = () => { s = (s * 16807) % 2147483647; return (s - 1) / 2147483646; };
        try { localStorage.clear(); localStorage.setItem("stepmath", JSON.stringify({ grade: g, chosen: true })); indexedDB.deleteDatabase("bento"); } catch {}
      }, grade);
      await p.goto(`${base}#/learn/${id}`); await p.waitForTimeout(600);
      const tryOne = p.getByRole("button", { name: /Try one/ }).first();
      if (!(await tryOne.count())) { notes.push(`${tag}: no Try one (lesson not open)`); await p.close(); continue; }
      await tryOne.click(); await p.waitForTimeout(500);
      let steps = 0, stuck = "", done = 0;
      const next = p.getByRole("button", { name: /^Next/ }).first();
      for (let n = 0; n < 40 && !stuck; n++) {
        // a solved problem shows Next (the page is the truth here: the session read can lag a render behind)
        if (await next.isVisible().catch(() => false)) {
          if (++done >= PROBLEMS) break;
          await next.click(); await p.waitForTimeout(400); continue;
        }
        // read the step until it agrees with the page (a keypad step has Check, a tap step only choices)
        let wnt = await want(p);
        for (let r = 0; r < 8 && !wnt.none && !wnt.solved; r++) {
          const keys = await p.locator(".k-go").first().isVisible().catch(() => false);
          if (keys === !!wnt.slots) break;
          await p.waitForTimeout(300); wnt = await want(p);
        }
        if (wnt.none) { stuck = wnt.none; break; }
        if (wnt.solved) { await p.waitForTimeout(300); continue; }
        const at = `${tag} problem ${done + 1} ${wnt.label ?? "pick"}`;
        if (wnt.slots) {
          const go = await reach(p, ".k-go");
          if (!go.length) fails.push(`${at}: no Check button`);
          for (const g of go) if (!g.inside || !g.onTop) fails.push(`${at}: Check ${g.inside ? "is covered" : `is off the screen (bottom ${g.bottom} of ${h})`}`);
          for (const [slot, v] of Object.entries(wnt.slots)) {
            const box = p.locator(`[data-slot="${slot}"]`).first();
            if (await box.count()) await box.click({ timeout: 1500 }).catch(() => {});
            for (let e = 0; e < 8; e++) if (!(await p.locator('[data-key="back"]').first().click({ timeout: 200 }).then(() => true, () => false))) break;
            for (const ch of String(v)) await p.locator(`[data-key="${ch === "-" ? "−" : ch}"]`).first().click({ timeout: 1500 }).catch(() => { stuck ||= `key "${ch}" can't be tapped`; });
          }
          if (stuck) break;
          await p.locator(".k-go").first().click({ timeout: 1500 }).catch(() => { stuck = "Check can't be tapped"; });
        } else {
          const pickText = wnt.choice ?? wnt.pick;
          const all = await reach(p, ".choice");
          for (const c of all) if (!c.inside || !c.onTop) fails.push(`${at}: choice "${c.text}" ${c.inside ? "is covered" : `is off the screen (bottom ${c.bottom} of ${h})`}`);
          await p.locator(".choice").filter({ hasText: pickText }).first().click({ timeout: 1500 }).catch(() => { stuck = `choice "${pickText}" can't be tapped`; });
        }
        steps++; await p.waitForTimeout(350);
      }
      if (stuck) fails.push(`${tag}: walk stopped after ${steps} steps (${stuck})`);
      if (stuck && process.env.STEPS_SHOTS) await p.screenshot({ path: `${process.env.STEPS_SHOTS}/${w}x${h}-${id}.png` });
      walked += steps;
      await p.close();
    }
    await ctx.close();
  }
  notes.push(`steps walked: ${walked}`);
}

// run on its own: start the dev server, walk, report
if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  const { createServer } = await import(require.resolve("vite"));
  const server = await createServer({ root: web, mode: "preview", logLevel: "error", server: { port: 0 } });
  await server.listen();
  const base = server.resolvedUrls.local[0];
  const { LESSONS } = await server.ssrLoadModule("/src/curriculum/registry.ts");
  const args = process.argv.slice(2);
  const lessons = LESSONS.filter(l => !args.length || args.some(a => a === l.id || a === String(l.grade))).map(l => ({ id: l.id, grade: l.grade }));
  const browser = await chromium.launch(), fails = [], notes = [];
  await stepWalk({ browser, base, lessons, fails, notes });
  await browser.close(); await server.close();
  for (const n of notes) console.log("note ", n);
  for (const f of fails) console.log("FAIL ", f);
  console.log(fails.length ? `${fails.length} problems (${lessons.length} lessons, ${PHONES.length} phone sizes)` : `step walk clean (${lessons.length} lessons, ${PHONES.length} phone sizes)`);
  process.exit(fails.length ? 1 : 0);
}
