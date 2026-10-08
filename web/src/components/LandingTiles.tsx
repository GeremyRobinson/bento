import { useEffect, useMemo, useRef, useState, type CSSProperties, type ReactElement, type ReactNode } from "react";
import { reduceMotion } from "../app/transition";
import { CATALOG } from "../curriculum/catalog";
import { GRADES, gradeOf, tintStyle } from "../curriculum/grades";
import type { Rng } from "../curriculum/generators/rng";
import { Fill, GradeNum } from "./Shelf";
import { SlipTile, SolveTile } from "./StepDemos";
import { FeatureTile, type FeatureSize } from "./FeatureTile";
import { FACT_SPRINT, REVIEW, SHOW_ME } from "../app/copy";

/**
 * The landing page's feature tiles: each one is a small working piece of the app (today's plan ticking off, a times
 * table filling in, a grade charging up) rather than a paragraph about it. They play while they're on screen.
 */

/** Ticks once a beat while the tile is on screen; without motion it sits on the finished picture. */
function useBeat(ms: number, end: number) {
  const still = reduceMotion();
  const [t, setT] = useState(still ? end : 0);
  const [seen, setSeen] = useState(false);
  const box = useRef<HTMLElement>(null);
  useEffect(() => {
    if (still || !box.current || typeof IntersectionObserver === "undefined") { setSeen(true); return; }
    const io = new IntersectionObserver(es => setSeen(es.some(e => e.isIntersecting)), { threshold: 0.3 });
    io.observe(box.current);
    return () => io.disconnect();
  }, [still]);
  useEffect(() => {
    if (still || !seen) return;
    const id = setInterval(() => setT(n => n + 1), ms);
    return () => clearInterval(id);
  }, [ms, seen, still]);
  return { t: still ? end : t, box };
}

type Size = FeatureSize;

/** each landing tile is an instance of the FeatureTile master */
function Tile({ size, tint, title, children, box, k, label }: { size: Size; tint: string; title: string; children: ReactNode; box?: React.Ref<HTMLElement>; k: number; label: ReactNode }) {
  return <FeatureTile box={box} size={size} tint={tint} k={k} title={title} label={label}>{children}</FeatureTile>;
}

interface TileProps { tint: string; k: number; rng: Rng; size: Size }

/** Today's plan: a lesson, a fact sprint and review, ticking off one by one. */
export function TodayTile({ tint, k, size }: TileProps) {
  const rows = [["Lesson", "Adding fractions"], [FACT_SPRINT, "Times tables"], [REVIEW, "4 old problems"]] as const;
  const { t, box } = useBeat(1100, 3);
  const at = t % 6; // three ticks, then a rest before it starts over
  return (
    <Tile box={box} size={size} tint={tint} k={k} title="Today" label="About ten minutes a day. One new lesson, a quick fact sprint and a few problems you missed before.">
      <ol className="ltoday">{rows.map(([kind, name], i) => (
        <li key={kind} className={i < at ? "done" : i === Math.min(at, 2) ? "now" : ""}>
          <span className="lmark">{i < at && <svg viewBox="0 0 16 16"><path d="M3.5 8.5l3 3 6-7" /></svg>}</span>
          <span><small>{kind}</small><b>{name}</b></span>
        </li>
      ))}</ol>
    </Tile>
  );
}

/**
 * A times table whose cells fill in as they're learned. It opens part-learned, most cells already tinted, so the
 * tile reads complete on its first frame (Review v43 #20); the rest then fill in, it holds full, and goes back to
 * part-learned. Without motion it sits full.
 */
export function FactsTile({ tint, k, rng, size }: TileProps) {
  const N = 6, FULL = N * N * 2, REST = 40;
  const order = useMemo(() => rng.shuffle(Array.from({ length: N * N }, (_, i) => i)), [rng]);
  const { t, box } = useBeat(160, FULL - REST);
  const step = REST + (t % (FULL - REST + 12)); // fill in, settle, then back to part-learned
  const lv = (i: number) => { const r = order.indexOf(i); return Math.max(0, Math.min(3, Math.floor((step - r) / 12))); };
  return (
    <Tile box={box} size={size} tint={tint} k={k} title="Facts by heart" label="Times tables, squares and powers. Each fact fills in once you know it. Two minutes a day.">
      <div className="lfacts" style={{ "--n": N } as CSSProperties}>
        {Array.from({ length: N * N }, (_, i) => { const a = Math.floor(i / N) + 1, b = (i % N) + 1; return (
          <span key={i} className={lv(i) >= 3 ? "k" : undefined} style={{ "--lv": lv(i) } as CSSProperties}>{a * b}</span>
        ); })}
      </div>
    </Tile>
  );
}

/** A grade's card charging up, the way progress shows everywhere in Bento. */
export function BatteryTile({ k, rng, size }: TileProps) {
  const g = useMemo(() => rng.pick(GRADES), [rng]);
  const { t, box } = useBeat(2600, 1);
  const frac = [0.25, 0.6, 0.85, 1][t % 4]!;
  return (
    <Tile box={box} size={size} tint={g.color} k={k} title="Progress you can see" label="Every grade fills up like a battery as you finish its lessons.">
      <div className="lbatt battery" style={tintStyle(g) as CSSProperties}>
        <GradeNum grade={g.grade} />
        <b>{g.subtitle}</b>
        <Fill key={t} frac={frac} />
        <span className="bcount">{Math.round(frac * 100)}% done</span>
      </div>
    </Tile>
  );
}

/** A page shrinking back into its chapter, then the year: the book zoom. */
export function BookTile({ tint, k, size }: TileProps) {
  const { t, box } = useBeat(1500, 1);
  const zoom = t % 4; // 0 page, 1 chapter, 2 year, 3 back to the page
  return (
    <Tile box={box} size={size} tint={tint} k={k} title="Obento is a book" label="Pinch a page to zoom out to its chapter, then the year, then every grade.">
      <div className={`lbook z${zoom === 3 ? 0 : zoom}`}>
        {Array.from({ length: 9 }, (_, i) => <span key={i} className={i === 4 ? "page" : ""} />)}
      </div>
    </Tile>
  );
}

/** The grown-up page: which mistakes keep coming up. */
export function ReportTile({ tint, k, size }: TileProps) {
  const rows = [["Added the bottoms", 5], ["Dropped a carry", 3], ["Multiply comes first", 1]] as const;
  const { t, box } = useBeat(3200, 1);
  return (
    <Tile box={box} size={size} tint={tint} k={k} title="A report for your grown-up" label="Scores, time and the exact mistakes, so you both know what to work on next.">
      <div className="lreport" key={t}>{rows.map(([name, n], i) => (
        <div key={name}><span>{name}</span><i style={{ "--w": n / 5, "--d": i } as CSSProperties} /><b>{n}×</b></div>
      ))}</div>
    </Tile>
  );
}

/** Help that steps back: hints fade as you get stronger. */
export function HelpTile({ tint, k, size }: TileProps) {
  const { t, box } = useBeat(1300, 3);
  const at = t % 5;
  return (
    <Tile box={box} size={size} tint={tint} k={k} title="Help that steps back" label="Hints fade as you get stronger, until it's just you.">
      <div className="lhelp">{[SHOW_ME, "Hint", "Just you"].map((s, i) => (
        <span key={s} className={i === Math.min(at, 2) ? "on" : i < Math.min(at, 2) ? "gone" : ""}>{s}</span>
      ))}</div>
    </Tile>
  );
}

/**
 * Review: yesterday's slips come back today. The stack of three is there from the first frame (Review v43 #20);
 * each beat the cards step forward and only the card joining at the back rises in.
 */
export function ReviewTile({ tint, k, rng, size }: TileProps) {
  const cards = useMemo(() => rng.shuffle(["3/4 + 1/8", "48 × 6", "2x + 5 = 17", "7²", "0.6 × 0.4", "−3 × −8"]), [rng]);
  const { t, box } = useBeat(1800, 0);
  return (
    <Tile box={box} size={size} tint={tint} k={k} title="Review that sticks" label="Problems you missed come back until you've got them.">
      <div className="lreview">{[0, 1, 2].map(i => (
        <span key={(t + i) % cards.length} className={[i ? "" : "top", t && i === 2 ? "new" : ""].join(" ").trim() || undefined} style={{ "--j": i } as CSSProperties}>{cards[(t + i) % cards.length]}</span>
      ))}</div>
    </Tile>
  );
}

/** Every grade, counted up. */
export function CountTile({ tint, k, size }: TileProps) {
  const total = CATALOG.length;
  const { t, box } = useBeat(40, 30);
  const n = Math.round(total * Math.min(1, t / 30));
  return (
    <Tile box={box} size={size} tint={tint} k={k} title="K through 12" label="Counting to calculus, with unit tests and a check-up for every grade.">
      <div className="lcount"><b>{n}</b><span>lessons</span></div>
    </Tile>
  );
}

/** Privacy, said plainly. */
export function PrivateTile({ tint, k, size }: TileProps) {
  return (
    <Tile size={size} tint={tint} k={k} title="Yours alone" label="The first chapter of every grade is free. No ads, and nothing leaves this device.">
      <div className="lprivate"><svg viewBox="0 0 48 48"><rect x="10" y="21" width="28" height="20" rx="6" /><path d="M16 21v-5a8 8 0 0116 0v5" /><circle cx="24" cy="31" r="2.5" /></svg></div>
    </Tile>
  );
}

type Feature = { el: (p: TileProps) => ReactElement; size: Size };
const F = {
  today: { el: TodayTile, size: "wide" }, facts: { el: FactsTile, size: "tall" }, battery: { el: BatteryTile, size: "one" },
  book: { el: BookTile, size: "one" }, report: { el: ReportTile, size: "wide" }, help: { el: HelpTile, size: "one" },
  review: { el: ReviewTile, size: "one" }, count: { el: CountTile, size: "one" }, private: { el: PrivateTile, size: "one" },
  steps: { el: SolveTile, size: "wide" }, slips: { el: SlipTile, size: "wide" },
} satisfies Record<string, Feature>;

/**
 * Orders that pack four columns by four rows with no gaps (and two columns on phones), so whichever is drawn
 * the box stays a clean rectangle. Bento is variety: a different arrangement each visit.
 */
const ORDERS: (keyof typeof F)[][] = [
  ["steps", "facts", "battery", "today", "slips", "book", "help", "review", "report", "count", "private"],
  ["facts", "slips", "report", "count", "help", "steps", "book", "battery", "today", "review", "private"],
  ["battery", "today", "facts", "review", "steps", "help", "book", "slips", "count", "report", "private"],
];

/** The whole feature box, freshly arranged and coloured on every visit. */
export function FeatureBox({ rng }: { rng: Rng }) {
  const { order, tints } = useMemo(() => {
    const order = rng.pick(ORDERS);
    const tints = rng.shuffle(GRADES.map(g => gradeOf(g.grade).color));
    return { order, tints };
  }, [rng]);
  return (
    <section className="lbox">{order.map((id, k) => {
      const f = F[id], El = f.el;
      return <El key={id} tint={tints[k % tints.length]!} k={k} rng={rng} size={f.size} />;
    })}</section>
  );
}
