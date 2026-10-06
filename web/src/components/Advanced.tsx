import { useEffect, useRef, useState } from "react";
import { TEASER_MS, TeaserPic, type TeaserId } from "./TeaserPics";


export type TrackPicId = "ai" | "orbit" | "relativity" | "quantum" | "linear" | "prob" | "hills" | "info" | "comp" | "change";

export function HorizonPic({ id }: { id: TrackPicId }) {
  switch (id) {
    case "linear": // two arrows and the parallelogram they span: a grid of numbers moving space
      return (
        <svg viewBox="0 0 200 110" aria-hidden="true">
          {[0, 1, 2, 3, 4, 5].map(i => <path key={i} className="adv-faint" d={`M${10 + i * 36} 104 L${44 + i * 36} 6`} />)}
          {[0, 1, 2, 3].map(i => <path key={`h${i}`} className="adv-faint" d={`M6 ${92 - i * 26} L194 ${80 - i * 26}`} />)}
          <path d="M70 84 L132 70 L162 22 L100 36 Z" className="adv-fill adv-grow" />
          <path d="M70 84 L132 70" className="adv-line adv-draw" />
          <path d="M70 84 L100 36" className="adv-line adv-draw" />
          <circle cx="132" cy="70" r="4" className="adv-dot" /><circle cx="100" cy="36" r="4" className="adv-dot" />
        </svg>
      );
    case "prob": // a histogram filling in under its bell curve
      return (
        <svg viewBox="0 0 200 110" aria-hidden="true">
          <line x1="14" y1="96" x2="186" y2="96" className="adv-faint" />
          {[8, 20, 42, 66, 76, 64, 40, 22, 9].map((h, i) => <rect key={i} x={26 + i * 17} y={96 - h} width="13" height={h} rx="2" className="adv-fill adv-grow" style={{ animationDelay: `${0.2 + i * 0.08}s` }} />)}
          <path d="M18 94 C 60 94, 74 16, 100 16 S 140 94, 182 94" className="adv-line adv-draw" />
        </svg>
      );
    case "hills": // a ball finding the lowest point of a landscape
      return (
        <svg viewBox="0 0 200 110" aria-hidden="true">
          <path d="M12 40 C 40 10, 60 30, 80 62 S 120 100, 142 72 S 176 30, 190 40" className="adv-line adv-draw" />
          <path d="M12 58 C 40 30, 60 48, 80 78 S 120 108, 142 88" className="adv-faint" />
          <circle r="5" className="adv-dot">
            <animateMotion dur="4s" repeatCount="indefinite" keyPoints="0;1;1" keyTimes="0;.7;1" calcMode="spline" keySplines=".5 0 .5 1;0 0 1 1" path="M30 26 C 52 22, 64 40, 80 62 S 104 86, 116 86" />
          </circle>
        </svg>
      );
    case "info": // the surprise of an event: −log p, steep for the rare, flat for the sure
      return (
        <svg viewBox="0 0 200 110" aria-hidden="true">
          <line x1="20" y1="96" x2="186" y2="96" className="adv-faint" /><line x1="20" y1="10" x2="20" y2="96" className="adv-faint" />
          <path d="M26 10 C 34 60, 60 82, 186 94" className="adv-line adv-draw" />
          {[0, 1, 2, 3, 4, 5, 6, 7].map(i => <rect key={i} x={110 + (i % 4) * 16} y={20 + Math.floor(i / 4) * 16} width="11" height="11" rx="2" className={i % 3 ? "adv-faint" : "adv-fill"} />)}
        </svg>
      );
    case "comp": // steps of an algorithm sorting bars into order
      return (
        <svg viewBox="0 0 200 110" aria-hidden="true">
          <line x1="14" y1="96" x2="186" y2="96" className="adv-faint" />
          {[22, 36, 50, 64, 78, 92].map((h, i) => <rect key={i} x={30 + i * 24} y={96 - h} width="16" height={h} rx="3" className={i === 5 ? "adv-dot adv-grow" : "adv-fill adv-grow"} style={{ animationDelay: `${0.15 + i * 0.12}s` }} />)}
        </svg>
      );
    case "change": // a quantity changing over time, and the slope that drives it
      return (
        <svg viewBox="0 0 200 110" aria-hidden="true">
          <line x1="14" y1="96" x2="186" y2="96" className="adv-faint" />
          <path d="M16 90 C 60 88, 70 30, 110 24 S 170 20, 188 20" className="adv-line adv-draw" />
          <path d="M50 92 L130 20" className="adv-faint adv-dash" />
          <circle cx="86" cy="54" r="4.5" className="adv-dot" />
        </svg>
      );
    case "ai": // a ball rolling down a loss curve: gradient descent, how a network learns
      return (
        <svg viewBox="0 0 200 110" aria-hidden="true">
          <line x1="14" y1="96" x2="186" y2="96" className="adv-faint" />
          <path d="M16 18 C 50 18, 62 92, 104 92 S 160 40, 186 30" className="adv-line adv-draw" />
          {[30, 52, 72, 92].map((x, i) => <circle key={x} cx={x + 6} cy={[24, 52, 78, 90][i]} r="2.5" className="adv-trail" style={{ animationDelay: `${0.6 + i * 0.35}s` }} />)}
          <circle r="5" className="adv-dot">
            <animateMotion dur="4s" repeatCount="indefinite" keyPoints="0;1;1" keyTimes="0;.7;1" calcMode="spline" keySplines=".5 0 .5 1;0 0 1 1" path="M16 18 C 50 18, 62 92, 104 92" />
          </circle>
        </svg>
      );
    case "orbit": // a planet on an ellipse, the sun at one focus
      return (
        <svg viewBox="0 0 200 110" aria-hidden="true">
          <ellipse cx="100" cy="55" rx="80" ry="38" className="adv-faint" />
          <circle cx="62" cy="55" r="8" className="adv-fill" />
          <circle cx="62" cy="55" r="3" className="adv-dot" />
          <circle r="4.5" className="adv-dot">
            <animateMotion dur="7s" repeatCount="indefinite" path="M180 55 A 80 38 0 1 1 20 55 A 80 38 0 1 1 180 55" />
          </circle>
        </svg>
      );
    case "relativity": // a grid of spacetime bending around a mass
      return (
        <svg viewBox="0 0 200 110" aria-hidden="true">
          {[0, 1, 2, 3, 4].map(i => <path key={`h${i}`} className="adv-faint adv-bend" style={{ animationDelay: `${i * 0.05}s` }}
            d={`M14 ${20 + i * 18} Q 100 ${20 + i * 18 + (i === 2 ? 26 : i === 1 || i === 3 ? 16 : 8)}, 186 ${20 + i * 18}`} />)}
          {[0, 1, 2, 3, 4, 5, 6].map(i => { const x = 22 + i * 26; return <path key={`v${i}`} className="adv-faint"
            d={`M${x} 14 Q ${x + (100 - x) * 0.25} 55, ${x} 96`} />; })}
          <circle cx="100" cy="62" r="9" className="adv-fill adv-mass" />
          <circle cx="100" cy="62" r="4" className="adv-dot" />
        </svg>
      );
    default: // a wave packet travelling: where a particle probably is
      return (
        <svg viewBox="0 0 200 110" aria-hidden="true">
          <line x1="10" y1="62" x2="190" y2="62" className="adv-faint" />
          <g className="adv-drift">
            <path d={wave()} className="adv-line" />
            <path d="M40 62 C 70 62, 82 28, 100 28 S 130 62, 160 62" className="adv-faint adv-dash" />
          </g>
        </svg>
      );
  }
}

/** A sine wave inside a bell-shaped envelope. */
function wave() {
  const pts: string[] = [];
  for (let x = 20; x <= 180; x += 2) {
    const env = Math.exp(-(((x - 100) / 34) ** 2));
    pts.push(`${x},${(62 - Math.sin((x - 100) / 5.2) * 32 * env).toFixed(1)}`);
  }
  return `M${pts.join(" L")}`;
}

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
      <h2 id="adv-title" aria-label="Bento squared">Bento²</h2>
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
