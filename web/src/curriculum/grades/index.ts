import type { GradeNumber } from "../schemas/lesson";

export type Band = "little" | "kid" | "middle" | "high";

export interface GradeDefinition {
  grade: GradeNumber;
  /** short label on the grade circle */
  short: string;
  name: string;
  subtitle: string;
  color: string;
}

// Same names, colours and subtitles as the current app.
export const GRADES: GradeDefinition[] = [
  { grade: 0, short: "K", name: "Kindergarten", subtitle: "Counting and adding", color: "#c65d26" },
  { grade: 1, short: "1", name: "1st grade", subtitle: "Tens and ones", color: "#8c69cd" },
  { grade: 2, short: "2", name: "2nd grade", subtitle: "Adding with regrouping", color: "#bd5693" },
  { grade: 3, short: "3", name: "3rd grade", subtitle: "Multiplying", color: "#009b8e" },
  { grade: 4, short: "4", name: "4th grade", subtitle: "Division, fractions and decimals", color: "#2784d5" },
  { grade: 5, short: "5", name: "5th grade", subtitle: "Fractions and decimals", color: "#b05baa" },
  { grade: 6, short: "6", name: "6th grade", subtitle: "Ratios and equations", color: "#009b72" },
  { grade: 7, short: "7", name: "7th grade", subtitle: "Proportions and integers", color: "#567ad9" },
  { grade: 8, short: "8", name: "8th grade", subtitle: "Functions and right triangles", color: "#0093bb" },
  { grade: 9, short: "9", name: "9th grade · Algebra 1", subtitle: "Algebra 1", color: "#a061be" },
  { grade: 10, short: "10", name: "10th grade · Geometry", subtitle: "Geometry", color: "#0098a6" },
  { grade: 11, short: "11", name: "11th grade · Algebra 2", subtitle: "Algebra 2", color: "#7471d6" },
  { grade: 12, short: "12", name: "12th grade", subtitle: "Precalculus and calculus", color: "#008ccb" },
];

export const bandOf = (g: number): Band => (g <= 2 ? "little" : g <= 5 ? "kid" : g <= 8 ? "middle" : "high");
/** A grade by number. Never a stand-in for "no grade chosen": out-of-range numbers clamp to K or 12th. */
export const gradeOf = (g: number): GradeDefinition => GRADES[Math.max(0, Math.min(GRADES.length - 1, Math.round(g) || 0))]!;

const lum = (hex: string) => {
  const [r, g, b] = [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16) / 255).map(c => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r! + 0.7152 * g! + 0.0722 * b!;
};
/**
 * A color darkened just enough to carry text, or sit behind white text: 4.5:1 or better on white and on the color's own
 * soft tint (13% over white), where chips and selected rows put it.
 */
export function inkOf(hex: string): string {
  const ch = [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16));
  const toHex = (cs: number[]) => "#" + cs.map(c => Math.round(c).toString(16).padStart(2, "0")).join("");
  const soft = lum(toHex(ch.map(c => c * 0.13 + 255 * 0.87)));
  for (let p = 1; p > 0.3; p -= 0.01) {
    const out = toHex(ch.map(c => c * p)), l = lum(out) + 0.05;
    if (1.05 / l >= 4.5 && (soft + 0.05) / l >= 4.5) return out;
  }
  return "#1b1d22";
}
/** Inline style for something drawn in another grade's colour: its bright tint and its ink. */
export const tintStyle = (g: GradeDefinition) => ({ "--tint": g.color, "--ink": inkOf(g.color) });

/** Bento's product lines: grades grouped the way people think about school, each with its own canvas. */
export interface Line {
  id: "early" | "core" | "middle" | "high" | "ap";
  name: string;
  /** one line about what the line is for */
  tagline: string;
  grades: GradeNumber[];
  color: string;
  /** not open yet: shown in the lineup so people know it's coming */
  soon?: string[];
}

export const LINES: Line[] = [
  { id: "early", name: "Bento Early", tagline: "Count, touch and play. Kindergarten to 2nd grade.", grades: [0, 1, 2], color: "#f59e0b" },
  { id: "core", name: "Bento Core", tagline: "Multiply, divide, fractions and decimals. 3rd to 5th grade.", grades: [3, 4, 5], color: "#3b82f6" },
  { id: "middle", name: "Bento Middle", tagline: "Ratios, integers, equations and functions. 6th to 8th grade.", grades: [6, 7, 8], color: "#0f766e" },
  { id: "high", name: "Bento High", tagline: "Algebra, geometry, precalculus and calculus. 9th to 12th grade.", grades: [9, 10, 11, 12], color: "#7c3aed" },
  // Bento² (Bento squared): the pro side, past 12th grade's precalculus and calculus, toward the math behind AI, space and physics
  { id: "ap", name: "Bento²", tagline: "Bento, maxed out. Past calculus, to the math behind AI, space and physics.", grades: [], color: "#111827",
    soon: ["Linear algebra", "Multivariable calculus", "Probability", "Differential equations"] },
];

export const lineOf = (g: number): Line => LINES.find(l => l.grades.includes(g as GradeNumber)) ?? LINES[1]!;
