// Every flow of the app through the UI, written against whichever lessons are rebuilt (g5-mult2 is always there).
import { act, fireEvent, screen, within } from "@testing-library/react";
import { CATALOG } from "../../curriculum/catalog";
import { lessonById } from "../../curriculum/registry";
import type { Progress } from "../../engine/mastery/progress";
import type { SessionReport } from "../../engine/session/types";
import { answerWrong, failRun, renderApp, solveRun, tap } from "./helpers";

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

    // the grade picker is the shelf: thirteen grade cards, nothing that isn't open yet
    const grades = [...document.querySelectorAll(".lshelf button.book")];
    expect(grades).toHaveLength(13);
    expect(document.querySelector(".lshelf .book.soon")).toBeNull();
    fireEvent.click(screen.getByRole("button", { name: /^5th grade:/ }));
    // a grade opens on its book: the cover, today's plan, then every chapter with its pages
    expect(screen.getByRole("heading", { level: 1, name: "5th grade" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 2, name: "Today" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: new RegExp(`Up next.*${LESSON}`) })).toBeInTheDocument();
    expect(document.querySelectorAll(".schapter")).toHaveLength(4);
    expect(everyRow()).toHaveLength(grade5.length);

    // the landing page, visited again, now offers the way back
    act(() => { location.hash = "#/welcome"; dispatchEvent(new HashChangeEvent("hashchange")); });
    tap("My lessons ›");
    expect(screen.getByRole("heading", { level: 1, name: "5th grade" })).toBeInTheDocument();
  });

  it("returning learners skip the landing page", () => {
    renderApp({ grade: 5, chosen: true });
    expect(screen.queryByText("Math that clicks.")).toBeNull();
    expect(screen.getByRole("heading", { level: 1, name: "5th grade" })).toBeInTheDocument();
  });
});

describe("no grade until one is chosen", () => {
  for (const hash of ["#/", "#/year"]) it(`${hash} opens the landing page's grade shelf`, () => {
    renderApp({ grade: null, chosen: false }, {}, hash);
    expect(screen.getByRole("heading", { name: "Every grade, K to 12th." })).toBeInTheDocument();
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
    expect(screen.getByRole("heading", { level: 1, name: "3rd grade" })).toBeInTheDocument();
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

describe("home", () => {
  it("lists every lesson of the grade, with unit tests, the check-up and the grown-up page", () => {
    renderApp();
    const rows = everyRow();
    expect(rows).toHaveLength(grade5.length);
    grade5.forEach((c, i) => {
      expect(rows[i]!.textContent).toContain(c.title);
      expect(rows[i]!.disabled).toBe(!lessonById(c.id));
    });
    // a lesson's detail offers its chapter's unit test when the chapter has a rebuilt lesson
    for (const u of [...new Set(grade5.map(c => c.unit))]) {
      const c = grade5.find(c => c.unit === u && lessonById(c.id));
      if (!c) continue;
      openRow(c.title);
      expect(screen.getByRole("heading", { level: 2, name: c.title })).toBeInTheDocument();
      expect(screen.getByRole("button", { name: new RegExp(`${u} test`) })).toBeInTheDocument();
    }
    expect(screen.getByRole("button", { name: "Grade check-up" })).toBeInTheDocument();
    // the grown-up page, accessibility and backups live in the personal hub
    expect(screen.getByRole("button", { name: /^Me:/ })).toBeInTheDocument();
    // no review until two lessons are scored
    expect(screen.queryByText("Today's review")).toBeNull();
  });

  it("shows the whole year for 2nd grade, and switches grades from the sheet", () => {
    renderApp();
    fireEvent.click(screen.getByRole("button", { name: "Change grade" }));
    const sheet = screen.getByRole("dialog", { name: "Choose your grade" });
    fireEvent.click(within(sheet).getByRole("button", { name: /2nd/ }));
    expect(screen.queryByRole("dialog")).toBeNull();
    expect(screen.getByRole("heading", { level: 1, name: "2nd grade" })).toBeInTheDocument();
    expect(document.querySelector("main")!.dataset.band).toBe("little");
    expect(screen.queryByText("Coming soon")).toBeNull();
    const titles = everyRow().map(r => r.textContent!);
    for (const c of CATALOG.filter(c => c.grade === 2)) expect(titles.some(t => t.includes(c.title))).toBe(true);
    // 9th grade takes the plain look
    fireEvent.click(screen.getByRole("button", { name: "Change grade" }));
    fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: /9th/ }));
    expect(screen.queryByText("Coming soon")).toBeNull();
    expect(document.querySelector("main")!.dataset.band).toBe("high");
  });

  it("keeps going with a run left mid-lesson", () => {
    renderApp();
    fireEvent.click(screen.getByRole("button", { name: new RegExp(`Up next.*${LESSON}`) }));
    tap("Show all"); tap("Your turn ›");
    tap(`Back to ${LESSON}`);
    // the unfinished lesson waits beside the island; each grade's plan keeps showing its own next lesson
    const resume = screen.getByRole("button", { name: new RegExp(`Resume ${LESSON}, 5th grade, problem 1 of 8`) });
    expect(resume).toHaveTextContent(`5Resume${LESSON}1/8`);
    tap("Back to contents");
    fireEvent.click(screen.getByRole("button", { name: "Change grade" }));
    fireEvent.click(within(screen.getByRole("dialog")).getByRole("button", { name: /Kindergarten/ }));
    expect(screen.queryByRole("button", { name: new RegExp(`Up next.*${LESSON}`) })).toBeNull();
    fireEvent.click(screen.getByRole("button", { name: /^Resume / }));
    expect(screen.getByRole("button", { name: "Check" })).toBeInTheDocument();
  });

  it("zooms out from a lesson to its chapter, the year and every grade, and opens whatever is tapped", () => {
    renderApp();
    fireEvent.click(screen.getByRole("button", { name: new RegExp(`Up next.*${LESSON}`) }));
    expect(document.querySelector(".island")).toHaveTextContent(`Whole numbers · 1 of`);
    fireEvent.click(screen.getByRole("button", { name: /^Contents/ }));
    const book = screen.getByRole("dialog", { name: "Contents" });
    // the chapter: its pages, with this one marked
    expect(within(book).getByRole("heading", { level: 2, name: "Whole numbers" })).toBeInTheDocument();
    expect(within(book).getByRole("button", { current: "page" })).toHaveTextContent(LESSON);
    // the year: a card per chapter
    fireEvent.click(within(book).getByRole("button", { name: "Year" }));
    expect(book.querySelectorAll(".zcard")).toHaveLength(4);
    fireEvent.click(book.querySelectorAll(".zcard")[1]!);
    expect(within(book).getByRole("button", { name: "Chapter" })).toHaveAttribute("aria-pressed", "true");
    // every grade, then into another grade's book
    fireEvent.click(within(book).getByRole("button", { name: "All grades" }));
    expect(book.querySelectorAll("button.book")).toHaveLength(13);
    fireEvent.click(within(book).getByRole("button", { name: /^7th grade:/ }));
    expect(screen.queryByRole("dialog")).toBeNull();
    expect(screen.getByRole("heading", { level: 1, name: "7th grade" })).toBeInTheDocument();
  });
});

describe("unit test and check-up", () => {
  it("runs a unit test with no hints, then offers it again and shows its score on home", () => {
    renderApp();
    openRow(LESSON);
    tap("Whole numbers test");
    expect(screen.getByText("Whole numbers test: no hints, one try per step")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /Hints?$/ })).toBeNull();
    expect(screen.getByRole("button", { name: "Quit" })).toBeInTheDocument();
    expect(solveRun()).toBeGreaterThanOrEqual(6);
    expect(document.querySelector(".island")).toHaveTextContent("Whole numbers test");
    expect(screen.getByText("All steps right")).toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 2, name: "Advanced" })).toBeInTheDocument();
    tap("Take it again");
    expect(screen.getByText("Whole numbers test: no hints, one try per step")).toBeInTheDocument();
    tap("Quit");
    openRow(LESSON);
    expect(screen.getByRole("button", { name: /Whole numbers test/ }).querySelector(".score b")!.textContent).toBe("4");
  });

  it("runs the grade check-up and records it", () => {
    renderApp();
    tap("Grade check-up");
    expect(screen.getByText("5th grade check-up: no hints, one try per step")).toBeInTheDocument();
    solveRun();
    expect(document.querySelector(".island")).toHaveTextContent("5th grade check-up");
    tap("All lessons");
    expect(document.querySelector(".gtline .score b")!.textContent).toBe("4");
  });

  it("a wrong answer in a test shows the answer and moves on", () => {
    renderApp();
    tap("Grade check-up");
    answerWrong();
    expect(screen.getByRole("status")).toHaveTextContent(/Not this time\. The answer was/);
  });
});

/** every lesson row of the grade's list, opening each chapter in turn */
function everyRow(): HTMLButtonElement[] {
  const out: HTMLButtonElement[] = [];
  const count = document.querySelectorAll(".schapter").length;
  for (let i = 0; i < count; i++) {
    const ch = document.querySelectorAll(".schapter")[i]!;
    const head = ch.querySelector<HTMLButtonElement>(".srow.chap")!;
    if (head.getAttribute("aria-expanded") !== "true") fireEvent.click(head);
    out.push(...document.querySelectorAll(".schapter")[i]!.querySelectorAll<HTMLButtonElement>(".srow.sles"));
  }
  return out;
}

/** picks a lesson in the list, opening its chapter first */
function openRow(title: string) {
  const find = () => [...document.querySelectorAll<HTMLButtonElement>(".srow.sles")].find(r => r.textContent!.includes(title));
  for (const head of document.querySelectorAll<HTMLButtonElement>(".srow.chap")) {
    if (find()) break;
    if (head.getAttribute("aria-expanded") !== "true") fireEvent.click(head);
  }
  fireEvent.click(find()!);
}

const scored = (level: 0 | 1 | 2 | 3 | 4, date: number) => ({ last: level, best: level, pct: level / 4, date, mastered: false });

describe("report, grown-up page and back to basics", () => {
  it("opens the last report from the lesson, and goes back to it", () => {
    renderApp();
    fireEvent.click(screen.getByRole("button", { name: new RegExp(`Up next.*${LESSON}`) }));
    tap("Show all"); tap("Your turn ›");
    solveRun();
    tap("All lessons");
    openRow(LESSON);
    tap(/^Start lesson/);
    fireEvent.click(screen.getByRole("button", { name: /Last time: Advanced/ }));
    expect(screen.getByRole("heading", { level: 2, name: "What you did" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 2, name: "For the grown-up" })).toBeInTheDocument();
    expect(screen.getByText(/Practiced/)).toHaveTextContent(`Practiced ${LESSON}.`);
    tap(`Back to ${LESSON}`);
    expect(screen.getByRole("button", { name: "Show all" })).toBeInTheDocument();
  });

  it("shows scores by grade, mistake patterns, what needs practice and recent sessions", () => {
    const t = Date.UTC(2026, 9, 1, 15);
    const progress: Partial<Progress> = {
      grade: 5, chosen: true, xp: 120, done: 2,
      lessons: { "g5-mult2": 1, add: 1 },
      scores: { "g5-mult2": scored(1, t), add: scored(2, t) },
      tests: { "grade:5": scored(3, t) },
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
    fireEvent.click(screen.getByRole("button", { name: /^Me:/ }));
    tap("Open the report ›");
    for (const h of ["Scores by grade", "Mistake patterns", "Needs more practice", "Recent sessions"]) {
      expect(screen.getByRole("heading", { level: 2, name: h })).toBeInTheDocument();
    }
    expect(screen.getByText("Lesson average 1.5 of 4 · check-up 3: Proficient")).toBeInTheDocument();
    expect(screen.getByText("Lost the place value")).toBeInTheDocument();
    expect(screen.getByText("Multiply by the tens: The tens digit stands for 30, so add a zero.")).toBeInTheDocument();
    expect(screen.getByText("2 hints used, 1 quick retry that looked like guessing.")).toBeInTheDocument();
    // needs more practice lists both scored lessons; the one not rebuilt yet can't be opened
    const needs = screen.getByRole("heading", { name: "Needs more practice" }).closest("section")!;
    expect(within(needs).getAllByRole("button")).toHaveLength(2);
    // a session without a saved report can't be opened; one with a report opens it, and Back returns to the lesson
    const recent = within(screen.getByRole("heading", { name: "Recent sessions" }).closest("section")!).getAllByRole("button");
    expect(recent[1]).toBeDisabled();
    fireEvent.click(recent[0]!);
    expect(screen.getByText(/Typed/)).toHaveTextContent("Typed 141, answer 1410. Lost the place value (quick retry).");
    tap(`Back to ${LESSON}`);
    expect(screen.getByRole("button", { name: "Show all" })).toBeInTheDocument();
  });

  it("suggests building up first after a low score, in the lesson and on the results", () => {
    renderApp({ grade: 5, chosen: true, scores: { "g5-mult2": scored(1, Date.UTC(2026, 9, 1)) }, lessons: { "g5-mult2": 1 }, done: 1 });
    openRow(LESSON);
    tap(/^Start lesson/);
    const pre = CATALOG.find(c => c.id === "g4-partial")!;
    expect(screen.getByRole("button", { name: new RegExp(`Build up first: ${pre.title}`) })).toBeInTheDocument();
    tap("Show all"); tap("Your turn ›");
    failRun();
    expect(screen.getByRole("heading", { level: 2, name: "Not yet" })).toBeInTheDocument();
    const build = screen.getByRole("button", { name: new RegExp(`Build up first: ${pre.title}`) });
    expect((build as HTMLButtonElement).disabled).toBe(!lessonById(pre.id));
    expect(screen.getByRole("button", { name: "Practice again" })).toBeInTheDocument();
  }, 60000);
});

describe("the personal hub", () => {
  it("shows progress and grades, and its settings land on the page", () => {
    renderApp({ grade: 5, chosen: true, xp: 40, streak: 3 });
    fireEvent.click(screen.getByRole("button", { name: "Me: 3 day streak, 40 XP" }));
    expect(screen.getByRole("heading", { level: 1, name: "Your Bento" })).toBeInTheDocument();
    expect(document.querySelectorAll(".mgrades .gcell")).toHaveLength(13);
    fireEvent.click(screen.getByRole("switch", { name: /High contrast/ }));
    expect(screen.getByRole("switch", { name: /High contrast/ })).toHaveAttribute("aria-checked", "true");
    expect(document.documentElement.dataset.contrast).toBe("true");
    fireEvent.click(screen.getByRole("radio", { name: "Largest" }));
    expect(document.documentElement.dataset.text).toBe("largest");
    fireEvent.click(screen.getByRole("switch", { name: /Less motion/ }));
    expect(document.documentElement.dataset.motion).toBe("reduce");
  });
});

describe("find my level", () => {
  it("runs a short placement from a new grade's home and offers the grade to start in", () => {
    renderApp({ grade: 5, chosen: true });
    tap("Not sure this is your grade? Find my level ›");
    solveRun();
    expect(screen.getByRole("heading", { level: 1, name: /^Start in .+ grade\.$/ })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /^Start .+ grade ›$/ })).toBeInTheDocument();
  });
});
