// The Bento² foundation every track builds on: the step checker (rounding rule, fractions, slips), the Number shelf
// and the rest of the per-device progress, the expression engine behind the calculator and grapher, the matrix pad's
// maths, and the registry and its flag.
import { describe, expect, it } from "vitest";
import { checkB2Step, formatAnswer, group, liveSlips, parseTyped, toFraction, toleranceOf } from "../../bento2/steps";
import { fracStep, multiStep, numStep, slip, tapStep, unitFor, wholeStep } from "../../bento2/make";
import {
  emptyB2, isDone, markDone, readB2, readShelf, recordGuess, recordSlip, recordSolved, renameShelf, saveNote, setTool,
  shelfNumbers, shelve, unshelve, validName,
} from "../../bento2/progress";
import { calc, namesIn, parse, showValue } from "../../bento2/tools/expr";
import { det, eigen, identity, inverse, mul, solve, transpose } from "../../bento2/tools/matrix";
import { B2_TRACKS, b2LessonById, isOpen, lessonNumber, trackByCode, trackByPickerId, trackOfLesson } from "../../bento2/registry";
import { B2_TRACKS_LIVE, isTrackLive } from "../../bento2/flags";
import { TRACKS } from "../../app/tracks";
import { migrateProgress } from "../../persistence/migrations";
import { emptyProgress } from "../../engine/mastery/progress";
import { STAGES, STAGE_NAMES } from "../../bento2/model";
import { shelfText } from "../../bento2/tools/ShelfTool";

describe("typed answers and the rounding rule", () => {
  it("reads what a learner types", () => {
    expect(parseTyped("5/4")).toBe(1.25);
    expect(parseTyped("−3")).toBe(-3);
    expect(parseTyped("1,234.5")).toBe(1234.5);
    expect(parseTyped("-12/5")).toBe(-2.4);
    expect(parseTyped(".5")).toBe(0.5);
    for (const s of ["", "−", "/", ".", "3/0", "1.2.3", "abc", null, undefined]) expect(parseTyped(s)).toBeNull();
  });
  it("one unit of the last stated place; fractions and wholes exactly", () => {
    expect(toleranceOf(2)).toBeCloseTo(0.010001, 8);
    expect(toleranceOf(0)).toBeCloseTo(1.0001, 6);
    expect(toleranceOf("fraction")).toBe(1e-6);
    const s = numStep("t", "Light time", 0.0674, 3, { hint: "d / c", slips: [] });
    expect(checkB2Step(s, ["0.067"]).ok).toBe(true);
    expect(checkB2Step(s, ["0.068"]).ok).toBe(true);
    expect(checkB2Step(s, ["0.066"]).ok).toBe(false);
    const w = wholeStep("n", "Count", 12, { hint: "count", slips: [] });
    expect(checkB2Step(w, ["12"]).ok).toBe(true);
    expect(checkB2Step(w, ["12.4"]).ok).toBe(false);
    const f = fracStep("f", "Speed", 1.25, { hint: "add", slips: [] });
    expect(checkB2Step(f, ["5/4"]).ok).toBe(true);
    expect(checkB2Step(f, ["1.25"]).ok).toBe(true);
    expect(checkB2Step(f, ["6/5"]).ok).toBe(false);
  });
  it("names a slip, falls back to the hint, and asks softly for an empty box", () => {
    const s = numStep("t", "Light time", 2, 1, { hint: "Divide d by c.", slips: [slip("c over d", 0.5, "Time is distance over speed.")] });
    expect(checkB2Step(s, ["0.5"])).toMatchObject({ ok: false, kind: "c over d", message: "Time is distance over speed." });
    expect(checkB2Step(s, ["7"])).toMatchObject({ ok: false, generic: true, message: "Not quite. Divide d by c." });
    expect(checkB2Step(s, [""])).toMatchObject({ ok: false, soft: true });
    const m = multiStep("p", "Point", [3, 4], "whole", { boxes: ["ct′", "x′"], hint: "boost", slips: [slip("swapped", [4, 3], "Swapped.")] });
    expect(checkB2Step(m, ["3", "4"]).ok).toBe(true);
    expect(checkB2Step(m, ["4", "3"])).toMatchObject({ kind: "swapped" });
    expect(checkB2Step(m, ["3", ""])).toMatchObject({ soft: true, message: "Fill in every box." });
    const t = tapStep("w", "Which", ["less", "more"], 1, { hint: "think", slips: [] });
    expect(checkB2Step(t, [1]).ok).toBe(true);
    expect(checkB2Step(t, [0]).ok).toBe(false);
  });
  it("drops slips that equal the answer, and repeats", () => {
    const s = liveSlips(numStep("x", "X", 2, 1, { hint: "h", slips: [slip("same", 2, "a"), slip("one", 3, "b"), slip("two", 3, "c"), slip("nan", NaN, "d")] }));
    expect(s.slips.map(x => x.kind)).toEqual(["one"]);
  });
  it("writes answers the way the step asks for them", () => {
    expect(toFraction(1.25)).toEqual([5, 4]);
    expect(toFraction(-2 / 3)).toEqual([-2, 3]);
    expect(formatAnswer(1.25, "fraction")).toBe("5/4");
    expect(formatAnswer(-3, "fraction")).toBe("−3");
    expect(formatAnswer(9556.7, "whole")).toBe("9,557");
    expect(formatAnswer(67.4321, 1)).toBe("67.4");
    expect(group(-0.004, 2)).toBe("0.00");
    expect(unitFor(1, "years")).toBe("year");
    expect(unitFor(2, "years")).toBe("years");
    expect(unitFor(1, "km")).toBe("km");
  });
  it("the loop is five stages, named the spec's way", () => {
    expect(STAGES.map(s => STAGE_NAMES[s])).toEqual(["Play", "Guess", "Name it", "Work it", "Use it"]);
  });
});

describe("the Number shelf and progress, per device", () => {
  it("keeps values by name, readable by later lessons and tools", () => {
    let b = emptyB2();
    b = shelve(b, "c_light", { value: 299792458, unit: "m/s", from: "b2-re-01" }, 1);
    b = shelve(b, "twin", { value: [10, 6], labels: ["home", "traveler"], unit: "years", from: "re-twin" }, 2);
    b = shelve(b, "L", { value: [[1.25, -0.75], [-0.75, 1.25]], from: "matrix" }, 3);
    expect(readShelf(b, "c_light")).toBe(299792458);
    expect(shelfNumbers(b)).toEqual({ c_light: 299792458 });
    expect(shelfText(b.shelf.c_light!)).toBe("299,792,458 m/s");
    expect(shelfText(b.shelf.twin!)).toBe("home 10, traveler 6 years");
    // the calculator reads shelf names
    expect(calc("c_light / 1000", { vars: shelfNumbers(b) })).toEqual({ ok: true, value: 299792.458 });
    b = renameShelf(b, "L", "boost");
    expect(readShelf(b, "L")).toBeUndefined();
    expect(readShelf(b, "boost")).toEqual([[1.25, -0.75], [-0.75, 1.25]]);
    expect(renameShelf(b, "boost", "2bad")).toBe(b);
    b = unshelve(b, "twin");
    expect(Object.keys(b.shelf).sort()).toEqual(["boost", "c_light"]);
    expect(() => shelve(b, "no spaces", { value: 1, from: "x" }, 4)).toThrow();
    for (const n of ["gamma", "sr_drift", "v2", "A"]) expect(validName(n)).toBe(true);
    for (const n of ["", "2v", "a b", "a-b", "x".repeat(25)]) expect(validName(n)).toBe(false);
  });
  it("records guesses, slips, solved problems and abilities; nothing is a score", () => {
    let b = emptyB2();
    b = recordGuess(b, "b2-re-01", false, 1);
    b = recordSlip(b, "b2-re-01", "c over d", 2);
    b = recordSlip(b, "b2-re-01", "c over d", 3);
    b = recordSolved(b, "b2-re-01", 4);
    expect(isDone(b, "b2-re-01")).toBe(false);
    b = markDone(b, "b2-re-01", 5);
    expect(b.lessons["b2-re-01"]).toEqual({ done: true, solved: 1, slips: { "c over d": 2 }, guesses: [false], at: 5 });
    expect(Object.keys(b.lessons["b2-re-01"]!).sort()).toEqual(["at", "done", "guesses", "slips", "solved"]);
  });
  it("one Notebook entry per project, newest first; tools keep their state", () => {
    let b = emptyB2();
    b = saveNote(b, { id: "re-twin", track: "re", title: "Twin trip", project: "re-twin", data: { D: 4 }, lines: ["a"] }, 1);
    b = saveNote(b, { id: "re-gps", track: "re", title: "GPS checker", project: "re-gps", data: {}, lines: ["b"], build: true }, 2);
    b = saveNote(b, { id: "re-twin", track: "re", title: "Twin trip", project: "re-twin", data: { D: 8 }, lines: ["c"] }, 3);
    expect(b.notebook.map(n => [n.id, n.at])).toEqual([["re-twin", 3], ["re-gps", 2]]);
    b = setTool(b, "calc", { deg: true });
    expect(b.tools.calc).toEqual({ deg: true });
  });
  it("reads any saved shape, and survives the save's migration and backups", () => {
    expect(readB2(undefined)).toEqual(emptyB2());
    expect(readB2({ shelf: [], notebook: {}, lessons: null })).toEqual(emptyB2());
    const b = shelve(emptyB2(), "gamma", { value: 1.25, from: "re-lightclock" }, 1);
    const p = migrateProgress(JSON.parse(JSON.stringify({ ...emptyProgress(), b2: b })));
    expect(readB2(p.b2).shelf.gamma?.value).toBe(1.25);
  });
});

describe("the expression engine (calculator and grapher)", () => {
  const v = (s: string, env = {}) => { const r = calc(s, env); if (!r.ok) throw new Error(r.error); return r.value; };
  it("follows the order of operations, with implicit multiplication", () => {
    expect(v("2 + 3 × 4")).toBe(14);
    expect(v("2^3^2")).toBe(512);
    expect(v("−2^2")).toBe(-4);
    expect(v("(1 + 2)(3 + 4)")).toBe(21);
    expect(v("2pi")).toBeCloseTo(2 * Math.PI, 12);
    expect(v("5!")).toBe(120);
    expect(v("nCr(5, 2)")).toBe(10);
    expect(v("sqrt(1 − 0.6^2)")).toBeCloseTo(0.8, 12);
    expect(v("3 × 10^8")).toBe(3e8);
  });
  it("radians by default, degrees when asked", () => {
    expect(v("sin(pi / 2)")).toBeCloseTo(1, 12);
    expect(v("sin(90)", { degrees: true })).toBeCloseTo(1, 12);
  });
  it("names come from the shelf; unknown names and bad input say what's wrong", () => {
    expect(v("gamma × 2", { vars: { gamma: 1.25 } })).toBe(2.5);
    expect(namesIn(parse("gamma × beta + sin(x)")).sort()).toEqual(["beta", "gamma", "x"]);
    for (const s of ["2 +", "foo + 1", "(1 + 2", "1 / 0"]) expect(calc(s).ok).toBe(false);
    expect(calc("eval(1)").ok).toBe(false);
  });
  it("shows values in Bento's way", () => {
    expect(showValue(299792458)).toBe("299,792,458");
    expect(showValue(-0.5)).toBe("−0.5");
    expect(showValue(6.674e-11)).toBe("6.674 × 10⁻¹¹");
    expect(showValue(1 / 3, 4)).toBe("0.3333");
  });
});

describe("the matrix pad's maths", () => {
  const L = [[1.25, -0.75], [-0.75, 1.25]];
  it("multiplies, inverts and solves", () => {
    expect(mul(L, inverse(L)).flat().map(x => +x.toFixed(12))).toEqual(identity(2).flat());
    expect(det(L)).toBeCloseTo(1, 12);
    expect(det([[2, 0, 1], [1, 3, 2], [1, 1, 2]])).toBeCloseTo(6, 12);
    expect(transpose([[1, 2, 3]])).toEqual([[1], [2], [3]]);
    expect(solve([[2, 1], [1, 3]], [3, 5]).map(x => +x.toFixed(12))).toEqual([0.8, 1.4]);
  });
  it("finds eigenvalues of a boost: e^±rapidity, along the light lines", () => {
    const e = eigen(L);
    expect(e.complex).toBe(false);
    expect(e.values.map(x => +x.toFixed(9)).sort()).toEqual([0.5, 2]);
    for (const vec of e.vectors) expect(Math.abs(Math.abs(vec[0]!) - Math.abs(vec[1]!))).toBeLessThan(1e-9);
    const s = eigen([[2, 0, 0], [0, 3, 4], [0, 4, 9]]);
    expect(s.values.map(x => +x.toFixed(9)).sort((a, b) => a - b)).toEqual([1, 2, 11]);
  });
});

describe("the registry and B2_TRACKS_LIVE", () => {
  it("finds tracks and lessons; picker ids match picker D's tracks", () => {
    expect(trackByPickerId("relativity")?.code).toBe("re");
    expect(trackByCode("re")?.lessons).toHaveLength(12);
    expect(b2LessonById("b2-re-05")?.track).toBe("re");
    expect(trackOfLesson("b2-re-05")?.name).toBe("Relativity");
    expect(lessonNumber("b2-re-05")).toBe("05");
    const pickerIds = TRACKS.map(t => t.id as string);
    for (const t of B2_TRACKS) expect(pickerIds).toContain(t.pickerId);
    for (const id of B2_TRACKS_LIVE) expect(pickerIds).toContain(id);
  });
  it("a track opens only when it has lessons and the flag lists it", () => {
    expect(isTrackLive("relativity")).toBe(true);
    expect(isOpen("relativity")).toBe(true);
    expect(isOpen("nope")).toBe(false);
  });
});
