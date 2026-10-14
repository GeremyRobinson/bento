// Every flow of the app through the UI, written against whichever lessons are rebuilt (g5-mult2 is always there).
import { act, fireEvent, screen, within } from "@testing-library/react";
import { CATALOG } from "../../curriculum/catalog";
import { lessonById } from "../../curriculum/registry";
import type { Progress } from "../../engine/mastery/progress";
import type { SessionReport } from "../../engine/session/types";
import { GRADES_VIEW, boxView } from "../../app/box";
import { entriesInGrade, isReady } from "../../app/curriculum";
import { answerCurrentStep, answerWrong, failRun, renderApp, solveRun, tap } from "./helpers";

const LESSON = "Multiply two-digit numbers";
const grade5 = CATALOG.filter(c => c.grade === 5);

describe("first launch: landing → grade → home", () => {
  it("shows the landing page, then the chosen grade's home", () => {
    renderApp({ grade: null, chosen: false });
    expect(screen.getByRole("heading", { level: 1, name: "Math that clicks." })).toBeInTheDocument();
    expect(screen.getByText("Counting to calculus, with unit tests and a check-up for every grade.")).toBeInTheDocument();

    // the hero box plays three real lesson pictures, one big and two small, each with its grade, all from different grades
    const pics = [...document.querySelectorAll(".lhbox .lhpic")];
    expect(pics).toHaveLength(3);
    expect(pics.filter(p => p.classList.contains("sm"))).toHaveLength(2);
    for (const p of pics) expect(p.querySelector(".gnum")).not.toBeNull();
    expect(pics[0]!.querySelector(".viz")).not.toBeNull();
    expect(new Set(pics.map(p => p.querySelector(".gnum")!.textContent)).size).toBe(3);
    // the feature box: eleven working tiles, the step and slip demos among them
    expect(document.querySelectorAll(".lbox .ltile")).toHaveLength(11);
    expect(document.querySelectorAll(".lbox .ldemo")).toHaveLength(2);

    // no grade switching on the landing page: Start learning is the way in, and picker D chooses the grade
    expect(document.querySelector(".lshelf")).toBeNull();
    fireEvent.click(screen.getAllByRole("button", { name: "Start learning" })[0]!);
    expect(screen.queryByRole("radio", { checked: true })).toBeNull();
    fireEvent.click(screen.getByRole("radio", { name: /^5th grade/ }));
    tap("Start 5th grade ›");
    // a grade opens on its home (v2): Today with the lesson up next, beside the grade's box of chapter covers
    expectGradeHome("5th grade");
    const today = screen.getByRole("region", { name: "Today" });
    expect(within(today).getByText("Today")).toBeInTheDocument();
    expect(within(today).getByRole("heading", { level: 2, name: LESSON })).toBeInTheDocument();
    expect(within(today).getByRole("button", { name: "Start" })).toBeInTheDocument();
    expect(chapterCovers()).toHaveLength(4);
    expect(everyRow()).toHaveLength(grade5.length);

    // the landing page, visited again, now offers the way back
    act(() => { location.hash = "#/welcome"; dispatchEvent(new HashChangeEvent("hashchange")); });
    tap("My lessons ›");
    expectGradeHome("5th grade");
  });

  it("returning learners skip the landing page", () => {
    renderApp({ grade: 5, chosen: true });
    expect(screen.queryByText("Math that clicks.")).toBeNull();
    expectGradeHome("5th grade");
  });
});

describe("no grade until one is chosen", () => {
  for (const hash of ["#/", "#/year"]) it(`${hash} opens the landing page, with no grade switching on it`, () => {
    renderApp({ grade: null, chosen: false }, {}, hash);
    expect(screen.getByRole("heading", { level: 1, name: "Math that clicks." })).toBeInTheDocument();
    expect(document.querySelector(".lshelf")).toBeNull();
    expect(document.querySelector("#app")!.getAttribute("data-grade")).toBe("none");
  });
  it("#/learn/no-such-lesson asks which grade, with nothing picked", () => {
    renderApp({ grade: null, chosen: false }, {}, "#/learn/no-such-lesson");
    expect(screen.getByRole("heading", { level: 1, name: "Which grade are you in?" })).toBeInTheDocument();
    expect(screen.getAllByRole("radio")).toHaveLength(13);
    expect(screen.queryByRole("radio", { checked: true })).toBeNull();
    expect(document.querySelector("#app")!.getAttribute("data-grade")).toBe("none");
  });
  it("the grade question shows a picked grade, then starts it", () => {
    renderApp({ grade: null, chosen: false }, {}, "#/learn/no-such-lesson");
    fireEvent.click(screen.getByRole("radio", { name: /^3rd grade/ }));
    expect(screen.getByRole("radio", { name: /^3rd grade/ })).toHaveAttribute("aria-checked", "true");
    expect(screen.getByRole("heading", { level: 2, name: /^Multiplying/ })).toBeInTheDocument();
    tap("Start 3rd grade ›");
    expectGradeHome("3rd grade");
  });
  it("the Bento / Bento² switch swaps the grades for the ten tracks, all coming later", () => {
    renderApp({ grade: null, chosen: false }, {}, "#/learn/no-such-lesson");
    expect(screen.getByRole("button", { name: "Obento" })).toHaveAttribute("aria-pressed", "true");
    fireEvent.click(screen.getByRole("button", { name: "Obento squared" }));
    expect(screen.getByRole("heading", { level: 1, name: "Where do you want to go?" })).toBeInTheDocument();
    expect(document.documentElement.dataset.side).toBe("b2");
    expect(screen.getAllByRole("radio")).toHaveLength(10);
    expect(screen.getAllByText("Coming later")).toHaveLength(10);
    fireEvent.click(screen.getByRole("radio", { name: "Linear algebra" }));
    expect(screen.getByRole("heading", { level: 2, name: "Linear algebra" })).toBeInTheDocument();
    tap("Tell me when it's ready");
    expect(screen.getByRole("button", { name: /We'll tell you/ })).toHaveAttribute("aria-pressed", "true");
    // no lesson can start from Bento² yet
    expect(screen.queryByRole("button", { name: /^Start/ })).toBeNull();
    fireEvent.click(screen.getByRole("button", { name: "Obento" }));
    expect(screen.getByRole("heading", { level: 1, name: "Which grade are you in?" })).toBeInTheDocument();
    expect(document.documentElement.dataset.side).toBeUndefined();
    expect(screen.getAllByRole("radio")).toHaveLength(13);
  });
  it("the hub and facts stay neutral and ask for a grade", () => {
    for (const hash of ["#/me", "#/facts"]) {
      const { unmount } = renderApp({ grade: null, chosen: false }, {}, hash);
      expect(document.querySelector("#app")!.getAttribute("data-grade")).toBe("none");
      expect(screen.queryByText(/5th grade/)).toBeNull();
      fireEvent.click(screen.getAllByRole("button", { name: "Choose your grade" })[0]!);
      expect(screen.getByRole("heading", { name: "Which grade are you in?" })).toBeInTheDocument();
      unmount();
    }
  });
});

/** the grade's home (UI model v57): the box beside Today is that grade's, and the island names it */
function expectGradeHome(name: string) {
  expect(screen.getByRole("region", { name: new RegExp(`^${name}( ·[^,]*)? box$`) })).toBeInTheDocument();
  expect(document.querySelector(".o-island")).toHaveTextContent(name);
}
/** the box: the grade's chapters and lessons, or every grade */
const box = () => screen.getByRole("region", { name: / box$|^Every grade$/ });
const today = () => screen.getByRole("region", { name: "Today" });
/** the chapter cover tiles in the box */
const chapterCovers = () => within(box()).getAllByRole("button", { name: /, \d+ of \d+ lessons? done$/ });
/** the box's Lessons / Test / Grade slider */
const view = (name: "Lessons" | "Test" | "Grade") => fireEvent.click(within(box()).getByRole("tab", { name }));
/** back out of a chapter (or every grade) to every chapter's cover: the island's back */
function allChapters() {
  if (boxView() != null) tap("Back");
}
/** opens a chapter's cover in the box */
function openChapter(unit: string) {
  allChapters();
  view("Lessons");
  fireEvent.click(within(box()).getByRole("button", { name: new RegExp(`^${unit}, \\d+ of \\d+ lessons? done$`) }));
}
/** Today's one button: Start (the lesson), Practise (done before) or Carry on (a run left part way) */
const goToday = () => fireEvent.click(within(today()).getByRole("button", { name: /^(Start|Practise|Carry on)$/ }));
/** from home into the lesson up next, past its worked example, into practice */
function startPractice() { goToday(); tap("Try one"); }
/** Changing grade has one way (UI model v57): the island's grid swaps the box for every grade, then a grade. */
function pickGrade(name: string) {
  allChapters();
  tap("Every grade");
  fireEvent.click(within(screen.getByRole("region", { name: "Every grade" })).getByRole("button", { name: new RegExp(`^${name}( ·[^,]*)?, `) }));
}

describe("home", () => {
  it("lists every lesson of the grade, with unit tests, the check-up and the grown-up page", () => {
    renderApp();
    const rows = everyRow();
    expect(rows).toHaveLength(grade5.length);
    grade5.forEach((c, i) => {
      expect(rows[i]!.name).toBe(c.title);
      expect(rows[i]!.disabled).toBe(!lessonById(c.id));
    });
    // a chapter's Test view offers its unit test when the chapter has a rebuilt lesson
    for (const u of [...new Set(grade5.map(c => c.unit))]) {
      if (!grade5.some(c => c.unit === u && lessonById(c.id))) continue;
      openChapter(u);
      view("Test");
      expect(within(box()).getByRole("button", { name: new RegExp(`^${u} test, `) })).toBeInTheDocument();
    }
    // the grade's check-up sits in the whole box's Test view
    allChapters();
    view("Test");
    expect(within(box()).getByRole("button", { name: "5th grade test, not taken yet" })).toBeInTheDocument();
    // the grown-up page lives in My Obento; every setting and the backup live on the Settings page
    expect(screen.getByRole("button", { name: "Me" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Settings" })).toBeInTheDocument();
    // no review until two lessons are scored
    expect(screen.queryByText("Today's review")).toBeNull();
  });

  it("tapping a lesson in the box puts it in Today, so the child can always choose", () => {
    renderApp();
    const other = grade5.find(c => c.unit === "Whole numbers" && c.title !== LESSON && lessonById(c.id))!;
    openChapter("Whole numbers");
    fireEvent.click(within(box()).getByRole("button", { name: new RegExp(`^${other.title}, `) }));
    expect(within(today()).getByRole("heading", { level: 2, name: other.title })).toBeInTheDocument();
    expect(within(today()).getByRole("button", { name: "Start" })).toBeEnabled();
    goToday();
    expect(document.querySelector(".o-island")).toHaveTextContent(other.title);
  });

  it("shows the whole year for 2nd grade, and switches grades from the island's ring", () => {
    renderApp();
    pickGrade("2nd grade");
    expectGradeHome("2nd grade");
    expect(document.querySelector("main")!.dataset.band).toBe("little");
    const titles = everyRow().map(r => r.name);
    for (const c of CATALOG.filter(c => c.grade === 2)) expect(titles).toContain(c.title);
    // 9th grade takes the plain look
    pickGrade("9th grade");
    expectGradeHome("9th grade");
    expect(document.querySelector("main")!.dataset.band).toBe("high");
  });

  it("keeps going with a run left mid-lesson", () => {
    renderApp();
    startPractice();
    tap("Back");
    // the unfinished lesson waits in Today as "Carry on"; each grade's Today keeps showing its own lesson
    expect(within(today()).getByText("In progress")).toBeInTheDocument();
    expect(within(today()).getByRole("heading", { level: 2, name: LESSON })).toBeInTheDocument();
    expect(today()).toHaveTextContent("Problem 1 of 6");
    pickGrade("Kindergarten");
    expect(within(today()).queryByText("In progress")).toBeNull();
    expect(within(today()).queryByRole("heading", { name: LESSON })).toBeNull();
    pickGrade("5th grade");
    fireEvent.click(within(today()).getByRole("button", { name: "Carry on" }));
    expect(screen.getByRole("button", { name: "Check" })).toBeInTheDocument();
  });

  it("leaving a run never asks: the work is kept to carry on later, and finishing it clears it (v2: no quit confirm)", () => {
    renderApp();
    startPractice();
    answerCurrentStep();
    const where = document.querySelector(".v-steps .n")!.textContent;
    tap("Back");
    expect(screen.queryByRole("alertdialog")).toBeNull();
    expectGradeHome("5th grade");
    // carrying on comes back to the same step, with the work done so far
    fireEvent.click(within(today()).getByRole("button", { name: "Carry on" }));
    expect(document.querySelector(".v-steps .n")).toHaveTextContent(where!);
    solveRun();
    tap("Back to your box");
    expect(within(today()).queryByText("In progress")).toBeNull();
    expect(within(today()).queryByRole("button", { name: "Carry on" })).toBeNull();
  });

  it("Escape closes only what's on top: the problem list, then the page steps back to the box, keeping the run (Review)", () => {
    renderApp();
    startPractice();
    const esc = () => act(() => { dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", cancelable: true })); });
    fireEvent.click(screen.getByRole("button", { name: "Problems" }));
    expect(document.querySelector(".v-plist")).not.toBeNull();
    esc();
    expect(document.querySelector(".v-plist")).toBeNull();
    expect(screen.getByRole("button", { name: "Check" })).toBeInTheDocument();
    // with nothing on top, Escape is the island's <: back to the box, the run waiting in Today
    esc();
    expectGradeHome("5th grade");
    expect(within(today()).getByRole("button", { name: "Carry on" })).toBeInTheDocument();
  });

  it("zooms out from a lesson to its chapter, the year and every grade, and opens whatever is tapped", () => {
    renderApp();
    goToday();
    expect(document.querySelector(".o-island")).toHaveTextContent("Watch one · then try");
    tap("Back");
    // the chapter: its lessons, with this one picked
    openChapter("Whole numbers");
    expect(box().querySelector(".o-cover.sel")).toHaveTextContent(LESSON);
    // the year: a cover per chapter; tapping one opens it
    allChapters();
    expect(chapterCovers()).toHaveLength(4);
    fireEvent.click(chapterCovers()[1]!);
    expect(boxView()).not.toBeNull();
    expect(screen.getByRole("button", { name: "Back" })).toBeInTheDocument();
    // every grade is the outermost level, from the island's ring; tapping one opens its home
    allChapters();
    tap("Every grade");
    expect(boxView()).toBe(GRADES_VIEW);
    expect(document.querySelector(".o-island")).toHaveTextContent("Every grade");
    const every = screen.getByRole("region", { name: "Every grade" });
    expect(within(every).getAllByRole("button")).toHaveLength(13);
    fireEvent.click(within(every).getByRole("button", { name: /^7th grade,/ }));
    expect(screen.queryByRole("region", { name: "Every grade" })).toBeNull();
    expectGradeHome("7th grade");
  });
});

describe("unit test and check-up", () => {
  it("runs a unit test with no hints, then offers it again and shows its score on home", () => {
    renderApp();
    openChapter("Whole numbers");
    view("Test");
    fireEvent.click(within(box()).getByRole("button", { name: "Whole numbers test, not taken yet" }));
    // a picked test waits in Today, like a lesson; Start begins it
    fireEvent.click(within(today()).getByRole("button", { name: "Start" }));
    expect(screen.getByText("Whole numbers test: no hints, one try per step")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /^Hint/ })).toBeNull();
    // a test goes in its own order: no problem list to pick from
    expect(screen.queryByRole("button", { name: "Problems" })).toBeNull();
    expect(screen.getByRole("button", { name: "Back" })).toBeInTheDocument();
    expect(solveRun()).toBeGreaterThanOrEqual(6);
    expect(document.querySelector(".o-island")).toHaveTextContent("Whole numbers test");
    expect(screen.getByText(/^\d+ of \d+ problems had every step right\./)).toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 2, name: "4 of 4: you’ve got it." })).toBeInTheDocument();
    tap("Take it again");
    expect(screen.getByText("Whole numbers test: no hints, one try per step")).toBeInTheDocument();
    tap("Back");
    openChapter("Whole numbers");
    view("Test");
    expect(within(box()).getByRole("button", { name: "Whole numbers test, last try 4 of 4" })).toBeInTheDocument();
  });

  it("runs the grade check-up and records it", () => {
    renderApp();
    startCheckup();
    expect(screen.getByText("5th grade check-up: no hints, one try per step")).toBeInTheDocument();
    solveRun();
    expect(document.querySelector(".o-island")).toHaveTextContent("5th grade check-up");
    tap("Back to your box");
    // the check-up's score shows on its tile in the box's Test view
    view("Test");
    expect(within(box()).getByRole("button", { name: "5th grade test, last try 4 of 4" })).toHaveTextContent("4/4");
  }, 60000);

  it("zooms out to every problem of a practice and does them in the order picked (v2: the Problems tool)", () => {
    renderApp();
    startPractice();
    fireEvent.click(screen.getByRole("button", { name: "Problems" }));
    const stage = screen.getByRole("region", { name: "Problem" });
    expect(within(stage).getAllByRole("button", { name: /^Problem \d+, / })).toHaveLength(6);
    fireEvent.click(within(stage).getByRole("button", { name: "Problem 3, To do" }));
    expect(document.querySelector(".v-plist")).toBeNull();
    expect(document.querySelector(".o-island")).toHaveTextContent("Problem 3 of 6");
  });

  it("a wrong answer in a test shows the answer and moves on", () => {
    renderApp();
    startCheckup();
    answerWrong();
    expect(screen.getByRole("status")).toHaveTextContent(/Not this time\. It\u2019s /);
  });

  it("a test problem with a wrong answer is never marked solved or green (G 2026-10-08)", () => {
    renderApp();
    startCheckup();
    for (let i = 0; i < 12 && !document.querySelector(".v-prac.solved"); i++) answerWrong();
    expect(document.querySelector(".v-prac.solved")).not.toBeNull();
    const say = screen.getByRole("status");
    expect(say).not.toHaveClass("good");
    // the say line names the miss (the answer given, or "Not this time."), never as right
    expect(say).toHaveTextContent("Not this time.");
    expect(say).not.toHaveTextContent("Solved.");
    expect(say).not.toHaveTextContent("Correct.");
    expect(document.querySelector(".v-steps .n")).toHaveTextContent("Done");
    expect(document.querySelector(".v-ask .ask.ok")).toBeNull();
    // no step of it gets a tick: every line was given, not worked out
    expect(document.querySelectorAll(".v-lines li:not(.shown)")).toHaveLength(0);
  });
});

/** the grade check-up, from the whole box's Test view */
function startCheckup() {
  allChapters();
  view("Test");
  fireEvent.click(within(box()).getByRole("button", { name: /^5th grade test, / }));
  fireEvent.click(within(today()).getByRole("button", { name: "Start" }));
}

/** every lesson tile of the grade's box, opening each chapter's cover in turn */
function everyRow(): { name: string; disabled: boolean }[] {
  const out: { name: string; disabled: boolean }[] = [];
  allChapters();
  view("Lessons");
  const count = chapterCovers().length;
  for (let i = 0; i < count; i++) {
    fireEvent.click(chapterCovers()[i]!);
    for (const t of box().querySelectorAll<HTMLButtonElement>(".o-cover")) out.push({ name: t.querySelector(".o-nm")!.textContent!, disabled: t.disabled });
    allChapters();
  }
  return out;
}

/** picks a lesson in the box, opening its chapter first, so Today shows it */
function openRow(title: string) {
  openChapter(CATALOG.find(c => c.grade === 5 && c.title === title)!.unit);
  fireEvent.click(within(box()).getByRole("button", { name: new RegExp(`^${title}, `) }));
}

const scored = (level: 0 | 1 | 2 | 3 | 4, date: number) => ({ last: level, best: level, pct: level / 4, date, mastered: false });

describe("report, grown-up page and back to basics", () => {
  it("after practice comes the skill check; done lists it problem by problem, and goes back to the lesson in Today (v2 model)", () => {
    renderApp();
    startPractice();
    solveRun();
    const done = screen.getByRole("region", { name: "Done" });
    expect(within(done).getByRole("heading", { level: 2, name: "4 of 4 on your own: you\u2019ve got it." })).toBeInTheDocument();
    expect(within(done).getByText("Your skill check")).toBeInTheDocument();
    expect(done.querySelectorAll(".v-rp")).toHaveLength(4);
    for (const row of done.querySelectorAll(".v-rp")) expect(row.textContent).toMatch(/^\d+ × \d+ = \d+\u2713Right$/);
    // no grown-up report here (it stays on the grown-up page) and no Practice again
    expect(within(done).queryByRole("heading", { name: "What you did" })).toBeNull();
    expect(within(done).queryByRole("button", { name: "Practice again" })).toBeNull();
    tap("Back to your box");
    expect(within(today()).getByRole("heading", { level: 2, name: LESSON })).toBeInTheDocument();
    expect(within(today()).getByRole("button", { name: "Practise" })).toBeInTheDocument();
    expect(box().querySelector(".o-cover.sel")).toHaveTextContent(LESSON);
  }, 60000);

  it("shows the mistake they keep making, where help was used and scores by chapter (model v63)", () => {
    const t = Date.UTC(2026, 9, 1, 15);
    const progress: Partial<Progress> = {
      grade: 5, chosen: true, xp: 120, done: 2,
      lessons: { "g5-mult2": 1, add: 1 },
      scores: { "g5-mult2": scored(1, t), add: scored(2, t) },
      tests: { "grade:5": scored(3, t) },
      checks: { "g5-mult2": { last: 1, best: 1, date: t, due: t + 864e5, passes: 0 } },
      log: [
        { key: "g5-mult2", mode: "practice", title: LESSON, date: t, level: 1, total: 9, hints: 2, shown: 1, cats: { "Lost the place value": 3 }, rushed: 1 },
        { key: "grade:5", mode: "test", title: "5th grade check-up", date: t, level: 3, total: 12, hints: 0, shown: 0, cats: {}, rushed: 0 },
      ],
    };
    const report: SessionReport = {
      key: "g5-mult2", mode: "practice", title: LESSON, date: t, ms: 300000, total: 9, extra: 1, clean: 3, hints: 2, shown: 1, pct: 0.3, level: 1, xp: 90,
      probs: [{ lessonId: "g5-mult2", problem: { a: 47, b: 36 }, work: [], hints: 1, wrong: 2, shown: 1, ms: 60000 }],
      mistakes: [{ n: 1, step: 1, label: "Multiply by the tens", lessonId: "g5-mult2", typed: "141", want: "1410", kind: "Lost the place value", cat: "concept", msg: "The tens digit stands for 30, so add a zero.", rushed: true }],
    };
    renderApp(progress, { "g5-mult2": report });
    // the grown-up page opens from My Obento, which the person button goes straight to (v2)
    fireEvent.click(screen.getByRole("button", { name: "Me" }));
    tap(/^For the grown-up/);
    // the three questions; Where can I help opens on the mistake, wrong beside right, with the lesson's own words on it
    fireEvent.click(screen.getByRole("button", { name: /^Where can I help\? 1 thing/ }));
    const mistakes = within(screen.getByRole("region", { name: "Mistakes they keep making" }));
    expect(mistakes.getByText(`${LESSON} · most often`)).toBeInTheDocument();
    expect(mistakes.getByText("141")).toBeInTheDocument();
    expect(mistakes.getByText("1410")).toBeInTheDocument();
    expect(mistakes.getByText(/^Lost the place value: Multiply by the tens: The tens digit stands for 30, so add a zero\. 1 of 1 problem\.$/)).toBeInTheDocument();
    expect(within(screen.getByRole("region", { name: "Hints and checks" })).getByText("2 hints")).toBeInTheDocument();
    // scores by chapter in words, on the sticking question
    fireEvent.click(screen.getByRole("tab", { name: /^Is it sticking, / }));
    expect(screen.getAllByText("Beginning · 1 of 4").length).toBeGreaterThan(0);
  });

  it("suggests building up first after a low score, in the lesson and on the results", () => {
    renderApp({ grade: 5, chosen: true, scores: { "g5-mult2": scored(1, Date.UTC(2026, 9, 1)) }, lessons: { "g5-mult2": 1 }, done: 1 });
    // Today says why it's back, and Practise goes straight to practice; the lesson itself still offers the build-up
    openRow(LESSON);
    expect(today()).toHaveTextContent("Your last skill check scored 1 of 4.");
    act(() => { location.hash = "#/learn/g5-mult2"; dispatchEvent(new HashChangeEvent("hashchange")); });
    const pre = CATALOG.find(c => c.id === CATALOG.find(l => l.id === "g5-mult2")!.pre)!;
    expect(screen.getByRole("button", { name: new RegExp(`Build up first: ${pre.title}`) })).toBeInTheDocument();
    tap("Try one");
    failRun();
    expect(screen.getByRole("heading", { level: 2, name: /^[01] of 4 on your own: / })).toBeInTheDocument();
    const build = screen.getByRole("button", { name: new RegExp(`Build up first: ${pre.title}`) });
    expect((build as HTMLButtonElement).disabled).toBe(!lessonById(pre.id));
    // the done screen offers only the way back (v2 model): Today brings the lesson back for another go
    expect(screen.queryByRole("button", { name: "Practice again" })).toBeNull();
    expect(screen.getByRole("button", { name: "Back to your box" })).toBeInTheDocument();
  }, 60000);
});

describe("My Obento", () => {
  // Me (model v63): three shelves only. One learned rule everywhere: the last check was 3 or 4 and it isn't due back
  it("the person button opens Me's three shelves, sorted by the learned rule (v2: no hub)", () => {
    const [a, b, c] = entriesInGrade(5).filter(e => isReady(e.id));
    const t = Date.UTC(2026, 9, 2, 15), day = 864e5;
    const check = (last: number, passes: number) => ({ last, best: last, date: t - day, due: t + 5 * day, passes });
    renderApp({ grade: 5, chosen: true, checks: { [a!.id]: check(1, 0), [b!.id]: check(3, 1), [c!.id]: check(4, 4) } } as Partial<Progress>);
    fireEvent.click(screen.getByRole("button", { name: "Me" }));
    expect(screen.queryByRole("dialog")).toBeNull();
    expect(screen.getByRole("button", { name: "Me" })).toHaveAttribute("aria-current", "page");
    expect(document.querySelector(".o-island")).toHaveTextContent("Me");
    const shelf = (name: string) => within(screen.getByRole("region", { name }));
    expect(shelf("Go over").getByRole("button", { name: `${a!.title}, Last check 1 of 4` })).toBeInTheDocument();
    expect(shelf("Getting stronger").getByRole("button", { name: `${b!.title}, Next check in 5 days` })).toBeInTheDocument();
    expect(shelf("Stuck").getByRole("button", { name: `${c!.title}, Stuck for good` })).toBeInTheDocument();
    expect(shelf("Go over").getByRole("button", { name: `Go over: ${a!.title}` })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /^For the grown-up/ })).toBeInTheDocument();
    expect(screen.queryByRole("tablist", { name: "Look" })).toBeNull();
    // no wordmark inside the app (G 2026-10-08)
    expect(screen.queryByRole("button", { name: "Obento, home" })).toBeNull();
    // the island's < goes back to the box
    tap("Back");
    expectGradeHome("5th grade");
  });
});

describe("Settings", () => {
  it("the gear goes straight to the Settings page: Look, Motion and Grade, then every other setting and the backup (v63)", () => {
    renderApp({ grade: 5, chosen: true });
    fireEvent.click(screen.getByRole("button", { name: "Settings" }));
    expect(screen.queryByRole("dialog")).toBeNull();
    expect(document.querySelector(".o-island")).toHaveTextContent("Settings");
    const pick = (group: string, name: string) => fireEvent.click(within(screen.getByRole("tablist", { name: group })).getByRole("tab", { name }));
    pick("Look", "Dark");
    expect(document.documentElement.dataset.theme).toBe("dark");
    pick("Look", "Auto");
    expect(document.documentElement.dataset.theme).toBeUndefined();
    pick("Motion", "Less");
    expect(document.documentElement.dataset.motion).toBe("reduce");
    pick("High contrast", "On");
    expect(document.documentElement.dataset.contrast).toBe("true");
    pick("Keypad", "Left-handed");
    expect(document.documentElement.dataset.hand).toBe("left");
    pick("Text size", "Largest");
    expect(document.documentElement.dataset.text).toBe("largest");
    expect(screen.getByRole("button", { name: "Save a backup" })).toBeInTheDocument();
    // Grade opens the grade picker on the box
    tap("5th grade");
    expect(boxView()).toBe(GRADES_VIEW);
  });
  it("moves between Settings and My Obento from the corner buttons, and the island's < goes back to the box (v2)", () => {
    renderApp({ grade: 5, chosen: true });
    fireEvent.click(screen.getByRole("button", { name: "Settings" }));
    expect(screen.getByRole("tablist", { name: "High contrast" })).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Me" }));
    expect(screen.getByRole("button", { name: "Me" })).toHaveAttribute("aria-current", "page");
    expect(screen.queryByRole("tablist", { name: "High contrast" })).toBeNull();
    tap("Back");
    expectGradeHome("5th grade");
  });
});

describe("find my level", () => {
  it("runs a short placement from Settings and offers the grade to start in", () => {
    renderApp({ grade: 5, chosen: true });
    fireEvent.click(screen.getByRole("button", { name: "Settings" }));
    tap("Start");
    solveRun();
    expect(screen.getByRole("heading", { level: 1, name: /^Start in .+ grade\.$/ })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /^Start .+ grade ›$/ })).toBeInTheDocument();
  });
});

describe("the website from inside the app", () => {
  it("Settings has About Bento, which opens the landing page", () => {
    renderApp();
    fireEvent.click(screen.getByRole("button", { name: "Settings" }));
    tap("What Obento is");
    expect(screen.getByRole("heading", { level: 1, name: "Math that clicks." })).toBeInTheDocument();
    // Start learning goes into the app and its grade picker, even with a grade chosen
    fireEvent.click(screen.getAllByRole("button", { name: "Start learning" })[0]!);
    expect(screen.getByRole("heading", { name: "Which grade are you in?" })).toBeInTheDocument();
  });
});
