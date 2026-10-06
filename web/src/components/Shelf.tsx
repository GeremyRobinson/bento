import type { CSSProperties } from "react";
import { useApp } from "../app/AppState";
import { doneCount, entriesInGrade } from "../app/curriculum";
import { GRADES, inkOf, LINES, tintStyle } from "../curriculum/grades";
import { lessonCount } from "../app/copy";

/** Progress as a fill: the box fills from the bottom in its colour, like a battery charging. frac is 0–1. */
export const Fill = ({ frac }: { frac: number }) => <span className="fill" aria-hidden style={{ "--p": Math.max(0, Math.min(1, frac)) } as CSSProperties} />;

/** "3rd", "12th": a grade's number with its ending, the way every grade is named on a card. */
export function GradeNum({ grade }: { grade: number }) {
  const d = GRADES[grade]!;
  // always the grade's own color, whatever lesson shade or grade it sits in (Review v35 item 6)
  return <span className="gnum" aria-hidden style={{ "--gn": inkOf(d.color), "--gn-d": d.color } as CSSProperties}>{d.short}{grade > 0 && <small>{["", "st", "nd", "rd"][grade] ?? "th"}</small>}</span>;
}

/**
 * Every grade as a card, grouped by Bento's lines: the grade's number in its colour, what the year covers, and
 * how much is done as a fill. The same shelf in the contents, the grade picker and the personal hub. Bento² stays off
 * the shelf until every grade is complete (Design, 2026-10-03): its cards read as "2nd grade". The landing teases it.
 */
export function Shelf({ current, onPick }: { current: number | null; onPick: (grade: number) => void }) {
  const { progress } = useApp();
  return (
    <div className="shelf">
      {LINES.filter(l => l.grades.length).map(line => (
        <div key={line.id} className="sline">
          <span className="k">{line.name}</span>
          <div className={`sbooks n${line.grades.length}`}>
            {line.grades.map(n => {
              const d = GRADES[n]!, list = entriesInGrade(n), done = doneCount(progress, list);
              return (
                <button key={n} className={`book gcell battery${n === current ? " on" : ""}`} style={tintStyle(d) as CSSProperties}
                  onClick={() => onPick(n)} aria-label={`${d.name}: ${done} of ${list.length} lessons done`}>
                  <GradeNum grade={n} />
                  <b>{d.subtitle}</b>
                  <Fill frac={list.length ? done / list.length : 0} />
                  <span className="bcount">{lessonCount(done, list.length)}</span>
                </button>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}
