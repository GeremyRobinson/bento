/**
 * The tokens the sandbox lets Design change. The values themselves live in the real stylesheets
 * (tokens.css for the shared ones, bands.css for each grade); the sandbox reads them from the page
 * and layers its edits on top, so one change shows on every screen and every grade at once.
 */
export type TokenKind = "color" | "px" | "pct" | "num";
export interface Token { v: string; label: string; kind: TokenKind; min?: number; max?: number; step?: number; /** shown while the token is unset and the master falls back to this */ fallback?: string }

/** each grade's own color: its hue (the grade number), the three lesson steps the interface uses, and their dark-mode steps */
export const GRADE_TOKENS: Token[] = [
  { v: "--hue", label: "Grade color", kind: "color" },
  { v: "--h1", label: "Lesson step 1", kind: "color" },
  { v: "--h2", label: "Lesson step 2", kind: "color" },
  { v: "--h3", label: "Lesson step 3", kind: "color" },
  { v: "--hd1", label: "Dark step 1", kind: "color" },
  { v: "--hd2", label: "Dark step 2", kind: "color" },
  { v: "--hd3", label: "Dark step 3", kind: "color" },
  // the grade's picture palette: colorful, each lesson's picture takes one of the first three (G 2026-10-06)
  { v: "--l0", label: "Picture color 1", kind: "color" },
  { v: "--l1", label: "Picture color 2", kind: "color" },
  { v: "--l2", label: "Picture color 3", kind: "color" },
  { v: "--la", label: "Picture accent", kind: "color" },
];

/** the colors every grade shares (edited per theme) */
export const SHARED_TOKENS: Token[] = [
  { v: "--text", label: "Text", kind: "color" },
  { v: "--muted", label: "Muted text", kind: "color" },
  { v: "--page", label: "Page", kind: "color" },
  { v: "--well", label: "Panel", kind: "color" },
  { v: "--card", label: "Card", kind: "color" },
  { v: "--rule", label: "Lines", kind: "color" },
  { v: "--ok", label: "Right", kind: "color" },
  { v: "--err", label: "Wrong", kind: "color" },
  { v: "--busy", label: "Current", kind: "color" },
];

/** the shared sizes; the nested radii (card, box) follow the panel radius and padding on their own */
export const SIZE_TOKENS: Token[] = [
  { v: "--u", label: "Padding", kind: "px", min: 8, max: 32 },
  { v: "--h", label: "Button height", kind: "px", min: 32, max: 64 },
  { v: "--fs", label: "Body text", kind: "px", min: 14, max: 24 },
  { v: "--math", label: "Math size", kind: "px", min: 28, max: 72 },
  { v: "--key", label: "Keypad key", kind: "px", min: 44, max: 88 },
];

/** the Diagram master (styles/diagram-master.css): every picture in every grade draws with these */
export const DIAGRAM_TOKENS: Token[] = [
  ...([["l0", "Part 1"], ["l1", "Part 2"], ["l2", "Part 3"], ["la", "Unknown"], ["k0", "Part 1 text"], ["k1", "Part 2 text"], ["k2", "Part 3 text"], ["ka", "Unknown text"]] as const)
    .map(([k, label]) => ({ v: `--${k}`, label, kind: "color" as const })),
  ...[10, 12, 18, 20, 22, 26, 30, 35, 40, 45, 50, 55, 70].map(n => ({ v: `--d-f${n}`, label: `Fill step ${n}`, kind: "pct" as const, min: 0, max: 100 })),
  ...([["hair", "Hairline"], ["thin", "Thin line"], ["line", "Line"], ["edge", "Edge"], ["stroke", "Stroke"], ["bold", "Bold line"], ["heavy", "Heavy line"], ["numeral", "Numeral stroke"]] as const)
    .map(([k, label]) => ({ v: `--d-${k}`, label, kind: "num" as const, min: 0.5, max: 16, step: 0.25 })),
  ...([["text", "Label"], ["text-sm", "Small label"], ["text-xs", "Tiny label"], ["text-lg", "Big label"], ["text-xl", "Huge label"]] as const)
    .map(([k, label]) => ({ v: `--d-${k}`, label, kind: "px" as const, min: 9, max: 40 })),
  ...([["copper", "Copper"], ["copper-rim", "Copper rim"], ["copper-shine", "Copper shine"], ["copper-shade", "Copper shade"], ["silver", "Silver"], ["silver-rim", "Silver rim"], ["silver-art", "Silver art"], ["silver-shine", "Silver shine"], ["silver-shade", "Silver shade"], ["water", "Water"], ["water-line", "Water line"]] as const).map(([k, label]) => ({ v: `--d-${k}`, label, kind: "color" as const })),
];

/** the Pill master: every button in the app */
export const PILL_TOKENS: Token[] = [
  { v: "--pill-h", label: "Height", kind: "px", min: 32, max: 72 },
  { v: "--pill-pad", label: "Side padding", kind: "px", min: 8, max: 40 },
  { v: "--pill-radius", label: "Corner", kind: "px", min: 0, max: 36 },
  { v: "--pill-weight", label: "Weight", kind: "num", min: 400, max: 700, step: 50 },
  { v: "--pill-press", label: "Press squeeze", kind: "num", min: 0.8, max: 1, step: 0.01 },
  { v: "--pill-lift", label: "Hover brighten", kind: "num", min: 1, max: 1.3, step: 0.01 },
];

/** the Surface master: every panel, card and tile */
export const SURFACE_TOKENS: Token[] = [
  { v: "--r-panel", label: "Panel corner", kind: "px", min: 8, max: 56 },
  { v: "--nest", label: "Nesting gap", kind: "px", min: 2, max: 20 },
  { v: "--surf-1", label: "Level 1 (panel)", kind: "color", fallback: "--well" },
  { v: "--surf-2", label: "Level 2 (card)", kind: "color", fallback: "--card" },
];

export type Theme = "light" | "dark";
export interface Overrides {
  /** the Grade (master) colors every grade starts from, keyed by the grade token they feed (--l0 → --master-l0) */
  master: Record<string, string>;
  shared: Record<Theme, Record<string, string>>;
  sizes: Record<string, string>;
  grades: Record<string, Record<string, string>>;
}
/** an instance token set to this follows the master again */
export const MASTER = "@master";
export const masterVar = (v: string) => `--master-${v.slice(2)}`;
const inst = (v: string) => (v === MASTER ? "" : v);
const resolve = (vals: Record<string, string>) => Object.fromEntries(Object.entries(vals).map(([k, v]) => [k, inst(v) || `var(${masterVar(k)})`]));
const masterVals = (o: Overrides) => Object.fromEntries(Object.entries(o.master ?? {}).map(([k, v]) => [masterVar(k), v]));

export const emptyOverrides = (): Overrides => ({ master: {}, shared: { light: {}, dark: {} }, sizes: {}, grades: {} });

const block = (sel: string, vals: Record<string, string>) => {
  const body = Object.entries(vals).map(([k, v]) => `${k}:${v}`).join(";");
  return body ? `${sel}{${body}}\n` : "";
};

/** The CSS that applies the edits. Doubled selectors outrank the stylesheets' own rules, phone sizes included. */
export function overrideCss(o: Overrides): string {
  let css = block(".wrap.wrap", masterVals(o)) + block(':root:root[data-theme="light"]', o.shared.light) + block(':root:root[data-theme="dark"]', o.shared.dark) + block(".wrap.wrap", o.sizes);
  for (const [g, vals] of Object.entries(o.grades)) css += block(`.wrap.wrap[data-grade="${g}"]`, resolve(vals));
  return css;
}

/** The same edits written the way the stylesheets write them, for Design to hand off. */
export function handoffCss(o: Overrides): string {
  const lines = (vals: Record<string, string>) => Object.entries(vals).map(([k, v]) => `${k}:${v}`).join(";");
  let out = "";
  if (Object.keys(o.master ?? {}).length) out += `/* bands.css, Grade (master): reaches every grade that doesn't override it */\n.wrap{${lines(masterVals(o))}}\n`;
  if (Object.keys(o.shared.light).length) out += `/* tokens.css, :root */\n:root{${lines(o.shared.light)}}\n`;
  if (Object.keys(o.shared.dark).length) out += `/* tokens.css, dark */\n:root[data-theme="dark"]{${lines(o.shared.dark)}}\n`;
  const pick = (f: (k: string) => boolean) => Object.fromEntries(Object.entries(o.sizes).filter(([k]) => f(k)));
  const dia = pick(k => k.startsWith("--d-")), pill = pick(k => k.startsWith("--pill-")), surf = pick(k => k === "--nest" || k === "--r-panel"), sz = pick(k => !k.startsWith("--d-") && !k.startsWith("--pill-") && k !== "--nest" && k !== "--r-panel");
  if (Object.keys(sz).length) out += `/* bands.css, sizes */\n.wrap{${lines(sz)}}\n`;
  if (Object.keys(surf).length) out += `/* components.css, Surface (master) */\n.wrap{${lines(surf)}}\n`;
  if (Object.keys(pill).length) out += `/* components.css, Pill (master) */\n.wrap{${lines(pill)}}\n`;
  if (Object.keys(dia).length) out += `/* diagram-master.css */\n.wrap{${lines(dia)}}\n`;
  const gs = Object.entries(o.grades).filter(([, v]) => Object.keys(v).length);
  if (gs.length) out += "/* bands.css, grade instances: var(--master-…) means delete that override so the grade follows the master */\n" + gs.map(([g, v]) => `.wrap[data-grade="${g}"]{${lines(resolve(v))}}`).join("\n") + "\n";
  return out || "No changes yet.";
}

let probe: CanvasRenderingContext2D | null | undefined;
/** Any CSS color as #rrggbb for a color input, or null when the browser can't say. */
export function toHex(css: string): string | null {
  const v = css.trim();
  if (/^#[0-9a-f]{6}$/i.test(v)) return v.toLowerCase();
  if (/^#[0-9a-f]{3}$/i.test(v)) return "#" + [...v.slice(1)].map(c => c + c).join("").toLowerCase();
  try {
    if (probe === undefined) probe = document.createElement("canvas").getContext("2d");
    if (!probe) return null;
    probe.fillStyle = "#000000";
    probe.fillStyle = v;
    const out = String(probe.fillStyle);
    return /^#[0-9a-f]{6}$/i.test(out) ? out : null;
  } catch { return null; }
}

/** "Grade (master)" in the sandbox: a probe grade no instance line matches, so it shows the master as is */
export const MASTER_GRADE = "master";
export const BAND_NAMES = { little: "K–2 look", kid: "3–5 look", middle: "6–8 look", high: "9–12 look" } as const;

/** The grade tokens as the page has them right now for one grade (or the master). */
export function readGrade(grade: string): Record<string, string> {
  const probe = document.createElement("div");
  probe.className = "wrap"; probe.dataset.grade = grade; probe.style.display = "none";
  document.body.appendChild(probe);
  const cs = getComputedStyle(probe), out: Record<string, string> = {};
  for (const t of [...GRADE_TOKENS, ...SIZE_TOKENS, ...DIAGRAM_TOKENS, ...PILL_TOKENS, ...SURFACE_TOKENS]) out[t.v] = cs.getPropertyValue(t.v).trim() || (t.fallback ? cs.getPropertyValue(t.fallback).trim() : "");
  probe.remove();
  return out;
}

/** Which grade tokens an instance overrides: the ones whose value differs from the master's. */
export function overridesOf(grade: string): Set<string> {
  const m = readGrade(MASTER_GRADE), g = readGrade(grade), out = new Set<string>();
  for (const t of GRADE_TOKENS) if ((toHex(g[t.v]!) ?? g[t.v]) !== (toHex(m[t.v]!) ?? m[t.v])) out.add(t.v);
  return out;
}
