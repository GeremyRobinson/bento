import { Pill } from "../components/primitives/Pill";
import { useEffect, useMemo, useRef, useState, type CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { gradeOf } from "../curriculum/grades";
import { factKey, tableById, tablesForGrade, type Fact, type FactTable } from "../engine/facts/tables";
import { FAST_MS, KNOWN, levelOf, pickSprint, sprintDoneToday, sprintTableFor, tableProgress, type SprintAnswer } from "../engine/facts/mastery";
import { readAloudOn, readSettings, speak } from "../app/settings";
import { Fill } from "../components/Shelf";
import { CHOOSE_GRADE } from "../app/copy";

const SPRINT = 20;
const fmt = (n: number) => (n < 0 ? `−${-n}` : String(n));

/**
 * Facts: the things worth knowing by heart, beside the lessons rather than inside them. Every grade gets the tables
 * that matter for it, each fact fills in as it becomes quick and sure, and a short sprint each day keeps them there.
 * Nothing is locked: lessons never wait on facts.
 */
export function Facts({ table, start = false }: { table?: string; start?: boolean }) {
  const t = table ? tableById(table) : undefined;
  return t ? <TablePage t={t} start={start} /> : <FactsHome />;
}

function FactsHome() {
  const { progress, go } = useApp();
  if (progress.grade == null) return (
    <>
      <header className="cover">
        <h1>Facts</h1>
        <p className="ysub">Know them by heart.</p>
        <p className="muted">Each grade leans on its own facts: counting on, times tables, squares, powers. Choose your grade to see yours.</p>
      </header>
      <div className="actions"><Pill go onClick={() => go({ name: "home" }, "fwd")}>{CHOOSE_GRADE}</Pill></div>
    </>
  );
  return <GradeFacts g={progress.grade} />;
}

function GradeFacts({ g }: { g: number }) {
  const { progress, go, deps } = useApp();
  const tables = [...tablesForGrade(g)].sort((a, b) => b.grades[0] - a.grades[0]), now = deps().now;
  const today = sprintTableFor(progress.facts, tables, now), done = sprintDoneToday(progress.sprints, now);
  const [sprint, setSprint] = useState<FactTable | null>(null);
  if (sprint) return <Sprint t={sprint} onDone={() => setSprint(null)} />;
  return (
    <>
      <header className="cover">
        <h1>Facts</h1>
        <p className="ysub">Know them by heart.</p>
        <p className="muted">The facts {(gradeOf(g).name.split(" · ")[0] ?? "").toLowerCase()} leans on. Each one fills in as you get it quick and sure, and comes back just before you'd forget it.</p>
      </header>
      <div className="bhome">
        {today && (
          <section className="tile today">
            <h2>Today's sprint</h2>
            <p className="sub">{done ? "Done for today. Another one never hurts." : `About 2 minutes of ${today.name.toLowerCase()}.`}</p>
            <Pill go className="fstart" onClick={() => setSprint(today)}>{done ? "Go again" : "Start"}</Pill>
          </section>
        )}
        <section className="tile b-stats battery">
          <Fill frac={allKnown(progress.facts, tables)} />
          <span className="bbig">{tables.reduce((n, t) => n + tableProgress(progress.facts, t).known, 0)}</span>
          <p><b>of {tables.reduce((n, t) => n + t.facts.length, 0)}</b> facts known</p>
        </section>
      </div>
      <div className="ftables">
        {tables.map(tb => {
          const { known, total } = tableProgress(progress.facts, tb);
          return (
            <button key={tb.id} className="panel ftable battery" onClick={() => go({ name: "facts", table: tb.id }, "fwd")}
              aria-label={`${tb.name}: ${known} of ${total} known`}>
              <Fill frac={total ? known / total : 0} />
              <h3>{tb.name}</h3>
              <span className="k">{total} facts</span>
              <p className="muted">{tb.blurb}</p>
              <span className="bcount">{known === total ? "All known" : `${known} of ${total} known`}</span>
            </button>
          );
        })}
      </div>
    </>
  );
}

const allKnown = (facts: Record<string, { s: number }>, tables: FactTable[]) => {
  const total = tables.reduce((n, t) => n + t.facts.length, 0);
  return total ? tables.reduce((n, t) => n + t.facts.filter(f => (facts[factKey(t, f)]?.s ?? 0) >= KNOWN).length, 0) / total : 0;
};

/** One table: every fact as a tile that fills as it's learned, the pattern behind them, and a sprint on just this table. */
function TablePage({ t, start }: { t: FactTable; start: boolean }) {
  const { progress, go } = useApp();
  const [sprint, setSprint] = useState(start);
  const [sel, setSel] = useState<Fact | null>(null);
  const { known, total } = tableProgress(progress.facts, t);
  if (sprint) return <Sprint t={t} onDone={() => (start ? go({ name: "home" }, "back") : setSprint(false))} />;
  const isGrid = t.rowHeads.length > 1;
  return (
    <>
      <header className="cover">
        <h1>{t.name}</h1>
        <p className="ysub">{t.blurb}</p>
        <p className="muted">{known} of {total} known. Tap any fact to see the pattern around it.</p>
        <Pill go className="fstart" onClick={() => setSprint(true)}>Practice these</Pill>
      </header>
      <section className="panel fgridwrap">
        {t.pattern === "hundred" ? <><Hundred t={t} /><Row t={t} sel={sel} setSel={setSel} /></> : isGrid ? <Grid t={t} sel={sel} setSel={setSel} /> : <Row t={t} sel={sel} setSel={setSel} />}
        <p className="fnote" aria-live="polite">{sel ? noteFor(t, sel) : t.pattern === "times" ? "Tap a fact. Its twin on the other side of the diagonal lights up too: 3 × 7 and 7 × 3 are the same fact." : t.pattern === "add" ? "Tap a fact. Every fact on the same slanted line makes the same total." : "Tap a fact to see it."}</p>
      </section>
    </>
  );
}

function noteFor(t: FactTable, f: Fact): string {
  if (t.pattern === "times") {
    const [a, b] = f.id.split("_").map(Number) as [number, number];
    return t.id === "divide"
      ? `${f.ask} = ${f.answer}, because ${a} × ${b} = ${a * b}.`
      : a === b ? `${a} × ${a} = ${a * a}: a square number, on the diagonal.` : `${a} × ${b} = ${f.answer}, and ${b} × ${a} = ${f.answer} too. Learn one, get both.`;
  }
  if (t.pattern === "add" && t.id !== "bonds10") return `${f.ask} = ${f.answer}. Every lit fact also makes ${f.answer}.`;
  return `${f.ask} = ${fmt(f.answer)}`;
}

const tileStyle = (lvl: number) => ({ "--lv": Math.min(lvl, 5) / 5 } as CSSProperties);

function Grid({ t, sel, setSel }: { t: FactTable; sel: Fact | null; setSel: (f: Fact) => void }) {
  const { progress } = useApp();
  const at = new Map(t.facts.map(f => [`${f.r},${f.c}`, f]));
  const twin = (f: Fact) => at.get(`${f.c},${f.r}`);
  const lit = (f: Fact) => {
    if (!sel) return "";
    if (f === sel) return " on";
    if (t.pattern === "times" && twin(sel) === f) return " twin";
    if (t.pattern === "add" && f.answer === sel.answer) return " twin";
    if (f.r === sel.r || f.c === sel.c) return " line";
    return "";
  };
  return (
    <div className="fgrid" role="grid" style={{ "--cols": t.colHeads.length + 1 } as CSSProperties} aria-label={t.name}>
      <span className="fh corner" aria-hidden>{t.id === "times" || t.id === "divide" ? "×" : t.id.startsWith("sub") ? "−" : t.id === "signs" ? "×" : "+"}</span>
      {t.colHeads.map(h => <span key={`c${h}`} className="fh" aria-hidden>{h}</span>)}
      {t.rowHeads.map((h, r) => (
        <div key={`r${h}`} role="row" className="frow">
          <span className="fh" aria-hidden>{h}</span>
          {t.colHeads.map((_, c) => {
            const f = at.get(`${r},${c}`);
            if (!f) return <span key={c} className="fcell empty" />;
            const lv = levelOf(progress.facts, t, f);
            return (
              <button key={c} role="gridcell" className={`fcell${lv >= KNOWN ? " known" : ""}${lit(f)}`} style={tileStyle(lv)}
                onClick={() => setSel(f)} aria-label={`${f.ask} = ${f.answer}${lv >= KNOWN ? ", known" : ""}`}>{fmt(f.answer)}</button>
            );
          })}
        </div>
      ))}
    </div>
  );
}

function Row({ t, sel, setSel }: { t: FactTable; sel: Fact | null; setSel: (f: Fact) => void }) {
  const { progress } = useApp();
  return (
    <div className="frowlist">
      {t.facts.map(f => {
        const lv = levelOf(progress.facts, t, f);
        return (
          <button key={f.id} className={`fchip${lv >= KNOWN ? " known" : ""}${sel === f ? " on" : ""}`} style={tileStyle(lv)} onClick={() => setSel(f)}
            aria-label={`${f.ask} = ${fmt(f.answer)}${lv >= KNOWN ? ", known" : ""}`}>
            <small>{f.ask}</small><b>{fmt(f.answer)}</b>
          </button>
        );
      })}
    </div>
  );
}

/** The hundred chart: pick a number to count by and every number you'd say lights up. */
function Hundred({ t }: { t: FactTable }) {
  const [by, setBy] = useState(5);
  return (
    <div className="fhundred">
      <div className="seg" role="group" aria-label="Count by">
        {[2, 3, 4, 5, 10].map(n => <button key={n} aria-pressed={by === n} onClick={() => setBy(n)}>by {n}s</button>)}
      </div>
      <div className="h100" aria-label={`Counting by ${by}s on a hundred chart`}>
        {Array.from({ length: 100 }, (_, i) => i + 1).map(n => (
          <span key={n} className={n % by === 0 ? "on" : ""} style={{ "--d": `${(n / by) * 0.02}s` } as CSSProperties}>{n}</span>
        ))}
      </div>
      <p className="muted fsmall">{t.facts.length} counts to learn: by 2s, 5s and 10s. The lit squares make a pattern: by 5s is two straight columns, by 10s is one.</p>
    </div>
  );
}

/** A quick round: up to 20 facts, answered by tapping digits. It checks itself the moment enough digits are in. */
function Sprint({ t, onDone }: { t: FactTable; onDone: () => void }) {
  const { progress, saveSprint, deps } = useApp();
  const aloud = readAloudOn(readSettings(progress.settings), progress.grade);
  const queue = useMemo(() => pickSprint(progress.facts, t, Math.min(SPRINT, t.facts.length), deps().now, deps().rng), []); // eslint-disable-line react-hooks/exhaustive-deps
  const [i, setI] = useState(0);
  const [typed, setTyped] = useState("");
  const [miss, setMiss] = useState<number | null>(null);
  const [answers, setAnswers] = useState<SprintAnswer[]>([]);
  const t0 = useRef(performance.now());
  const done = i >= queue.length, f = queue[i];
  const neg = t.facts.some(x => x.answer < 0);

  useEffect(() => { t0.current = performance.now(); if (f && aloud) speak(f.ask.replace("×", "times").replace("÷", "divided by").replace("−", "minus").replace("?", "what")); }, [i]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => { if (done && answers.length) saveSprint(t.id, answers); }, [done]); // eslint-disable-line react-hooks/exhaustive-deps

  const next = (right: boolean) => {
    const a: SprintAnswer = { key: factKey(t, f!), right, ms: performance.now() - t0.current };
    setAnswers(xs => [...xs, a]);
    setTyped(""); setMiss(null); setI(n => n + 1);
  };
  const press = (k: string) => {
    if (!f || miss != null) return;
    if (k === "back") return setTyped(s => s.slice(0, -1));
    const s = k === "−" ? (typed.startsWith("−") ? typed.slice(1) : `−${typed}`) : typed + k;
    setTyped(s);
    const want = fmt(f.answer);
    if (s === want) next(true);
    else if (s.replace("−", "").length >= want.replace("−", "").length && !(k === "−")) {
      setMiss(f.answer);
      setTimeout(() => next(false), 1400);
    }
  };
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (/^[0-9]$/.test(e.key)) press(e.key); else if (e.key === "Backspace") press("back"); else if (e.key === "-") press("−"); };
    addEventListener("keydown", onKey);
    return () => removeEventListener("keydown", onKey);
  });

  if (done) {
    const right = answers.filter(a => a.right).length, fast = answers.filter(a => a.right && a.ms <= FAST_MS).length;
    const missed = answers.filter(a => !a.right).map(a => t.facts.find(x => factKey(t, x) === a.key)!).filter(Boolean);
    return (
      <section className="panel fdone">
        <h2>{right === answers.length ? "Every one right." : `${right} of ${answers.length} right.`}</h2>
        <p className="muted">{fast} answered in under {FAST_MS / 1000} seconds. Quick and right is what fills a fact in.</p>
        {missed.length > 0 && (
          <div className="frowlist">{[...new Set(missed)].map(m => <span key={m.id} className="fchip miss"><small>{m.ask}</small><b>{fmt(m.answer)}</b></span>)}</div>
        )}
        {missed.length > 0 && <p className="muted fsmall">These come back first next time.</p>}
        <div className="actions"><Pill onClick={onDone}>Done</Pill></div>
      </section>
    );
  }
  return (
    <section className="panel split fsprint">
      <div className="col">
        <div className="card fq">
          <div className="label">{t.name} · {i + 1} of {queue.length}</div>
          <div className="fbar" aria-hidden><i style={{ width: `${(i / queue.length) * 100}%` }} /></div>
          <div className="fask" aria-live="polite">{f!.ask.includes("?") ? f!.ask : `${f!.ask} =`}</div>
          <div className={`fans${miss != null ? " miss" : ""}`} aria-label="Your answer">{miss != null ? fmt(miss) : typed || " "}</div>
          {miss != null && <p className="muted fsmall">You typed {typed}. It's {fmt(miss)}. It comes back soon.</p>}
        </div>
      </div>
      <div className="col">
        <div className="tray">
          {[1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => <button key={n} type="button" onClick={() => press(String(n))}>{n}</button>)}
          {neg ? <button type="button" aria-label="Negative" onClick={() => press("−")}>−</button> : <span />}
          <button type="button" onClick={() => press("0")}>0</button>
          <button type="button" aria-label="Erase" onClick={() => press("back")}>⌫</button>
        </div>
        <div className="actions"><Pill onClick={() => { if (answers.length) saveSprint(t.id, answers); onDone(); }}>Stop</Pill></div>
      </div>
    </section>
  );
}
