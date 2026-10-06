// Hash routes, so the app works from any folder on GitHub Pages and offline.
export type Route =
  /** the landing page */
  | { name: "welcome" }
  /** the grade's book: a list beside its detail; `pick` is the row the detail shows ("today" or a lesson id) */
  | { name: "home"; pick?: string }
  | { name: "learn"; lessonId: string }
  | { name: "practice" }
  | { name: "results" }
  | { name: "report"; key: string }
  /** the grown-up page; `pick` is the mistake pattern the detail shows (on a phone, the detail on its own) */
  | { name: "parent"; pick?: string }
  /** the personal hub: grades, progress, the grown-up page, accessibility and backups */
  | { name: "me" }
  /** the facts tables: all of them for the grade, or one table */
  | { name: "facts"; table?: string; start?: boolean }
  /** the design sandbox: every grade side by side with live token controls (preview and dev builds only) */
  | { name: "sandbox" }
  /** a Bento² track's map (`track` is its picker id, "relativity"); `pick` is the lesson or project the detail shows */
  | { name: "b2track"; track: string; pick?: string }
  /** a Bento² lesson: Play, Guess, Name it, Work it, Use it */
  | { name: "b2lesson"; track: string; lessonId: string };

const decode = (s: string) => { try { return decodeURIComponent(s); } catch { return s; } };

export function parseRoute(hash: string): Route {
  const parts = hash.replace(/^#\/?/, "").split("/").filter(Boolean).map(decode);
  switch (parts[0]) {
    case "welcome": return { name: "welcome" };
    case "year": return parts[1] ? { name: "home", pick: parts[1] } : { name: "home" };
    case "learn": return parts[1] ? { name: "learn", lessonId: parts[1] } : { name: "home" };
    case "practice": return { name: "practice" };
    case "results": return { name: "results" };
    case "report": return parts[1] ? { name: "report", key: parts[1] } : { name: "home" };
    case "grown-up": return parts[1] ? { name: "parent", pick: parts[1] } : { name: "parent" };
    case "me": return { name: "me" };
    case "facts": return parts[1] ? { name: "facts", table: parts[1], ...(parts[2] === "go" ? { start: true } : {}) } : { name: "facts" };
    case "b2": return !parts[1] ? { name: "home" } : parts[2] === "pick" && parts[3] ? { name: "b2track", track: parts[1], pick: parts[3] }
      : parts[2] ? { name: "b2lesson", track: parts[1], lessonId: parts[2] } : { name: "b2track", track: parts[1] };
    case "sandbox": return import.meta.env.MODE === "preview" || import.meta.env.MODE === "development" ? { name: "sandbox" } : { name: "home" };
    default: return { name: "home" };
  }
}

export function routeHash(r: Route): string {
  switch (r.name) {
    case "welcome": return "#/welcome";
    case "home": return r.pick ? `#/year/${encodeURIComponent(r.pick)}` : "#/";
    case "learn": return `#/learn/${encodeURIComponent(r.lessonId)}`;
    case "practice": return "#/practice";
    case "results": return "#/results";
    case "report": return `#/report/${encodeURIComponent(r.key)}`;
    case "parent": return r.pick ? `#/grown-up/${encodeURIComponent(r.pick)}` : "#/grown-up";
    case "me": return "#/me";
    case "sandbox": return "#/sandbox";
    case "b2track": return `#/b2/${encodeURIComponent(r.track)}${r.pick ? `/pick/${encodeURIComponent(r.pick)}` : ""}`;
    case "b2lesson": return `#/b2/${encodeURIComponent(r.track)}/${encodeURIComponent(r.lessonId)}`;
    case "facts": return r.table ? `#/facts/${encodeURIComponent(r.table)}${r.start ? "/go" : ""}` : "#/facts";
  }
}

/** Screens that take the chosen grade's look rather than a lesson's (the current app's "home" group). */
export const isB2 = (r: Route) => r.name === "b2track" || r.name === "b2lesson";

export const isTopLevel = (r: Route) => r.name === "welcome" || r.name === "home" || r.name === "parent" || r.name === "me";
