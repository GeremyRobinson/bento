import { BentoMark } from "./primitives/BentoMark";
import { useEffect, useRef, useState } from "react";
import { TEASER_MS, TeaserPic, type TeaserId } from "./TeaserPics";

/** The teaser: five subjects and a hint of more (G: "4 to 6 with more to find, we want to whet the palate"). */
const TEASER: { id: TeaserId; title: string; math: string; size?: string }[] = [
  { id: "linear", title: "Linear algebra", math: "Arrows and grids that move pictures", size: "big" },
  { id: "orbit", title: "Orbits and spaceflight", math: "How gravity steers spacecraft" },
  { id: "quantum", title: "Quantum", math: "The rules of the very small" },
  { id: "ai", title: "The math behind AI", math: "How computers learn", size: "wide" },
  { id: "prob", title: "Probability and statistics", math: "Chance, data and how sure to be", size: "wide" },
];
const TOOLS = ["Calculator", "Grapher", "3D grapher", "Matrix pad", "Units", "Scratch paper"];

/** Bento² on the landing page: the pro side of Bento, introduced on its own dark canvas. One picture plays at a time. */
export function Advanced() {
  const box = useRef<HTMLElement>(null);
  const [turn, setTurn] = useState({ i: -1, n: 0 });
  useEffect(() => {
    const el = box.current;
    if (!el) return;
    let t: ReturnType<typeof setTimeout> | undefined, i = -1;
    // one picture plays at a time; the next starts a beat after the last one finishes
    const step = () => { i = (i + 1) % TEASER.length; setTurn(s => ({ i, n: s.n + 1 })); t = setTimeout(step, TEASER_MS[TEASER[i]!.id] + 900); };
    const start = () => { el.classList.add("in"); t = setTimeout(step, 600); };
    if (typeof IntersectionObserver === "undefined") { start(); return () => clearTimeout(t); }
    const io = new IntersectionObserver(es => { if (es.some(e => e.isIntersecting)) { start(); io.disconnect(); } }, { threshold: 0, rootMargin: "0px 0px 200px 0px" });
    io.observe(el);
    return () => { io.disconnect(); clearTimeout(t); };
  }, []);
  return (
    <section className="ladv" ref={box} aria-labelledby="adv-title">
      <h2 id="adv-title"><BentoMark className="advmark" squared /></h2>
      <p className="adv-tag">Bento, maxed out.</p>
      <p>Where 12th grade ends, the box opens up: the math that moves pictures, steers spacecraft and teaches computers to learn. A full set of tools comes with it.</p>
      <div className="adv-tease">
        {TEASER.map((h, k) => (
          <article key={h.id} className={`adv-course ${h.size ?? ""}${turn.i === k ? " on" : ""}`}>
            <div className="adv-pic" key={turn.i === k ? turn.n : 0}><TeaserPic id={h.id} play={turn.i === k} /></div>
            <h3>{h.title}</h3>
            <span>{h.math}</span>
          </article>
        ))}
        <article className="adv-course more" aria-label="More subjects to find inside">
          <div className="adv-ghost" aria-hidden="true"><TeaserPic id="info" play={false} /><TeaserPic id="relativity" play={false} /><TeaserPic id="change" play={false} /></div>
          <h3>And more to find</h3>
          <span>More subjects open up inside.</span>
        </article>
      </div>
      <div className="adv-tools"><small>In the box</small>{TOOLS.map(t => <span key={t}>{t}</span>)}</div>
      <div className="adv-foot"><span className="adv-soon">Part of the membership</span><small>Coming later</small></div>
    </section>
  );
}
